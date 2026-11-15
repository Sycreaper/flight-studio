import Fastify from "fastify";
import {LettaRuntime} from "./letta_runtime.js";
import {ApprovalController, SessionController} from "./session_controller.js";
import {registerFlutterApi} from "./flutter_api.js";
import {LlmProxy} from "./llm_proxy.js";
import {log} from "./logger.js";

const port = Number(process.env.GATEWAY_PORT ?? 8787);

/// Shared-secret gate: when FLIGHTSTUDIO_GATEWAY_TOKEN is set (the Flutter
/// app always sets it when spawning the gateway), EVERY route requires
/// `Authorization: Bearer <token>` — a local process that guesses the port
/// cannot drive the copilot, read conversations or answer approvals.
/// Without the variable (manual `npm run start:dev`) the gateway serves
/// unauthenticated with a loud warning — developer mode only.
const authToken = process.env.FLIGHTSTUDIO_GATEWAY_TOKEN?.trim() || null;

const runtime = new LettaRuntime();
const session = new SessionController(runtime);
const approvals = new ApprovalController(session);

const app = Fastify({logger: {level: "warn"}});

if (authToken) {
    app.addHook("onRequest", async (request, reply) => {
        // The llm-proxy routes are called by the Letta app-server subprocess,
        // which does not know the gateway token — they are gated by their own
        // unguessable per-target path tokens instead.
        if (request.url.startsWith("/llm-proxy/")) return;
        const header = request.headers.authorization;
        if (header === `Bearer ${authToken}`) return;
        return reply.code(401).send({error: "unauthorized"});
    });
} else {
    log.warn(
        "gateway",
        "FLIGHTSTUDIO_GATEWAY_TOKEN not set — serving UNAUTHENTICATED. " +
            "Fine for local development; the Flutter app always sets it.",
    );
}

// Local reverse proxy for OpenAI-compatible providers whose real base URL
// does not follow the /v1 convention (e.g. bigmodel /api/paas/v4).
const llmProxy = new LlmProxy(port);
llmProxy.registerFastify(app);
runtime.attachLlmProxy(llmProxy);

// Bridge the official canUseTool callback to the Flutter permission card
// (approval_request SSE + POST /agent/approval/{id}).
runtime.attachApprovals(session);

// Fan gateway events out to every connected SSE client.
const listeners = new Set<(event: unknown) => void>();
runtime.events.on("event", (event) => {
    for (const listener of listeners) listener(event);
});

registerFlutterApi(app, runtime, session, approvals, (listener) => {
    listeners.add(listener);
    return () => listeners.delete(listener);
});

// Boot the Letta runtime in the background — /health + /agent/status
// report progress while it starts. (FlightStudio Core tools are mounted
// per-session in runTurn via mcpServers.)
void runtime.initialize();

const start = async () => {
    try {
        await app.listen({port, host: "127.0.0.1"});
        log.info("gateway", `listening on http://127.0.0.1:${port}`);
    } catch (err) {
        app.log.error(err);
        process.exit(1);
    }
};

for (const signal of ["SIGINT", "SIGTERM"] as const) {
    process.on(signal, () => {
        log.info("gateway", `${signal} received — shutting down`);
        void app.close().then(() => process.exit(0));
    });
}

void start();
