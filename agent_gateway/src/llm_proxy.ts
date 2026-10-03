/// Local LLM reverse proxy.
///
/// The Letta harness appends `/v1` to every OpenAI-compatible base URL that
/// doesn't already end in `/v1` (`localEndpointOpenAIBaseURL`). Providers
/// that break the /v1 convention (bigmodel/GLM uses `/api/paas/v4`) are
/// therefore unreachable directly.
///
/// This proxy bridges the gap: the provider row stores
/// `http://127.0.0.1:{port}/llm-proxy/{token}/v1` (ends in /v1 → harness
/// uses it verbatim). Requests are forwarded to the provider's REAL base
/// URL with the path after `/v1` preserved and the Authorization header
/// injected from the registry — so the credential never depends on the
/// harness's header handling either.
import type {FastifyInstance} from "fastify";

export interface ProxyTarget {
    baseUrl: string;
    apiKey: string;
}

export class LlmProxy {
    private targets = new Map<string, ProxyTarget>();
    private nextId = 1;

    constructor(private readonly port: number) {
    }

    /** Registers (or refreshes) a provider mapping; returns the proxy URL
     *  to store as the provider's base URL. */
    register(target: ProxyTarget): string {
        const token = String(this.nextId++);
        this.targets.set(token, target);
        // Keep the registry tiny: only the latest handful matter.
        if (this.targets.size > 8) {
            const oldest = this.targets.keys().next().value;
            if (oldest !== undefined) this.targets.delete(oldest);
        }
        return `http://127.0.0.1:${this.port}/llm-proxy/${token}/v1`;
    }

    registerFastify(app: FastifyInstance): void {
        app.all("/llm-proxy/:token/*", async (request, reply) => {
            const token = (request.params as { token?: string }).token;
            const target = this.targets.get(token ?? "");
            if (!target) {
                return reply.code(503).send({error: "proxy target unknown"});
            }
            let wildcard = (request.params as Record<string, string>)["*"] ?? "";
            // The proxy URL ends in `/v1` (harness convention); strip that
            // segment so the upstream path is the provider's real one.
            if (wildcard === "v1") wildcard = "";
            else if (wildcard.startsWith("v1/")) wildcard = wildcard.slice(3);
            const upstream = new URL(
                `${target.baseUrl.replace(/\/+$/, "")}/${wildcard}`,
            );
            if (request.url.includes("?")) {
                upstream.search = request.url.slice(request.url.indexOf("?"));
            }

            const headers: Record<string, string> = {
                "Content-Type": request.headers["content-type"] ?? "application/json",
                Accept: request.headers.accept ?? "application/json",
                Authorization: `Bearer ${target.apiKey}`,
            };

            try {
                const body = request.body
                    ? JSON.stringify(request.body)
                    : undefined;
                const res = await fetch(upstream, {
                    method: request.method,
                    headers,
                    ...(body != null ? {body} : {}),
                });
                const contentType =
                    res.headers.get("content-type") ?? "application/json";
                reply.header("content-type", contentType);
                reply.code(res.status);
                if (res.body == null) {
                    return reply.send();
                }
                // Stream through (SSE chat streams must not be buffered).
                const {Readable} = await import("node:stream");
                const web = res.body as unknown as AsyncIterable<Uint8Array>;
                return reply.send(Readable.fromWeb(web as never));
            } catch (err) {
                return reply.code(502).send({
                    error:
                        err instanceof Error
                            ? err.message
                            : "proxy upstream failed",
                });
            }
        });
    }
}
