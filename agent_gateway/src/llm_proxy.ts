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
///
/// Hardening: registry tokens are unguessable random UUIDs (the proxy path
/// is exempt from gateway Bearer auth because the Letta app-server
/// subprocess calls it without knowing the gateway token); only http(s)
/// upstreams may be registered; upstream redirects are refused (a
/// redirected request would carry the Authorization header to an
/// unregistered host); streamed responses are size-capped so a runaway
/// upstream cannot fill the disk.
import {randomUUID} from "node:crypto";
import type {FastifyInstance} from "fastify";

import {log} from "./logger.js";

export interface ProxyTarget {
    baseUrl: string;
    apiKey: string;
}

/// Responses larger than this are cut off with a 502.
const MAX_RESPONSE_BYTES = 64 * 1024 * 1024;

export class LlmProxy {
    private targets = new Map<string, ProxyTarget>();

    constructor(private readonly port: number) {
    }

    /** Validates the upstream URL scheme and registers (or refreshes) a
     *  provider mapping; returns the proxy URL to store as the provider's
     *  base URL. Throws on non-http(s) upstreams. */
    register(target: ProxyTarget): string {
        let parsed: URL;
        try {
            parsed = new URL(target.baseUrl);
        } catch {
            throw new Error(`invalid upstream base URL: ${target.baseUrl}`);
        }
        if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
            throw new Error(
                `refusing non-http(s) upstream: ${parsed.protocol}`,
            );
        }
        const token = randomUUID();
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
            let upstream: URL;
            try {
                upstream = new URL(
                    `${target.baseUrl.replace(/\/+$/, "")}/${wildcard}`,
                );
            } catch {
                return reply.code(502).send({error: "invalid upstream URL"});
            }
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
                    // Never follow redirects — the Authorization header must
                    // not leak to a host the user did not register.
                    redirect: "error",
                    ...(body != null ? {body} : {}),
                });
                const contentType =
                    res.headers.get("content-type") ?? "application/json";
                reply.header("content-type", contentType);
                reply.code(res.status);
                if (res.body == null) {
                    return reply.send();
                }
                // Stream through (SSE chat streams must not be buffered) with
                // a size cap: a runaway upstream gets cut off at the limit.
                const {Readable} = await import("node:stream");
                const web = res.body as unknown as AsyncIterable<Uint8Array>;
                const capped = new Readable({read() {}});
                let seen = 0;
                (async () => {
                    try {
                        for await (const chunk of web) {
                            seen += (chunk as Uint8Array).byteLength;
                            if (seen > MAX_RESPONSE_BYTES) {
                                capped.destroy(
                                    new Error("upstream response exceeded size limit"),
                                );
                                return;
                            }
                            if (!capped.push(chunk as Buffer)) return;
                        }
                        capped.push(null);
                    } catch (err) {
                        log.warn(
                            "llm-proxy",
                            "response aborted:",
                            err instanceof Error ? err.message : String(err),
                        );
                        capped.destroy(err instanceof Error
                            ? err
                            : new Error(String(err)));
                    }
                })();
                return reply.send(capped);
            } catch (err) {
                return reply.code(502).send({
                    error:
                        err instanceof Error ? err.message : "proxy upstream failed",
                });
            }
        });
    }
}
