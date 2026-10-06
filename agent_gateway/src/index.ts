import Fastify from "fastify";
import {LettaRuntime} from "./letta_runtime.js";
import {ApprovalController, SessionController} from "./session_controller.js";
import {registerFlutterApi} from "./flutter_api.js";
import {LlmProxy} from "./llm_proxy.js";
import {log} from "./logger.js";

const port = Number(process.env.GATEWAY_PORT ?? 8787);

const runtime = new LettaRuntime();
const session = new SessionController(runtime);
const approvals = new ApprovalController(session);

const app = Fastify({logger: {level: "warn"}});

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

// Boot the Letta runtime (and its client tools) in the background —
// /health + /agent/status report progress while it starts.
void runtime.initialize().then(() => runtime.registerFlightStudioToolsSafe());

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
