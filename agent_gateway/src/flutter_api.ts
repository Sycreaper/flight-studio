import type {FastifyInstance} from "fastify";
import type {ApprovalController, SessionController} from "./session_controller.js";
import type {GatewayEvent, LettaRuntime} from "./letta_runtime.js";
import {log} from "./logger.js";

/// Registers the Flutter-facing API surface:
///
///   GET  /health                          — liveness + Letta status
///   GET  /agent/status                    — gateway/Letta/agent status
///   POST /agent/provider                  — vault push (BYOK credential)
///   POST /agent/message   {text, conversationId?} — start one user turn
///   GET  /agent/events/{sessionId}        — SSE event stream
///   POST /agent/stop/{sessionId}          — abort the running turn
///   POST /agent/approval/{id} {approve}   — resolve an approval request
///   GET  /agent/approvals                 — pending approvals
///   GET  /agent/conversations             — conversations of 飞行助理
///   POST /agent/conversations             — create a conversation
///   DELETE /agent/conversations/{id}      — delete (archive) a conversation
///   GET  /agent/history?conversationId=   — conversation history
///   POST /agent/memory/update {blockLabel, value}
///
/// One Letta agent (飞行助理) backs every conversation; there is no agent
/// CRUD surface anymore.
export function registerFlutterApi(
    app: FastifyInstance,
    runtime: LettaRuntime,
    session: SessionController,
    approvals: ApprovalController,
    subscribe: (listener: (event: unknown) => void) => () => void,
) {
    app.get("/health", async () => ({...runtime.status}));

    app.get("/agent/status", async () => ({...runtime.status}));

    /// Vault push: lends one OpenAI-compatible credential (from the Flutter
    /// key vault) to the Letta runtime and switches the agent's model.
    /// FlightStudio remains the credential owner; the gateway never persists
    /// it anywhere except Letta's own BYOK store.
    app.post<{
        Body: { apiKey?: string; baseUrl?: string; model?: string; reasoningEffort?: string; providerName?: string };
    }>("/agent/provider", async (request, reply) => {
        const {apiKey, baseUrl, model, reasoningEffort, providerName} = request.body ?? {};
        if (!apiKey || !baseUrl || !model) {
            return reply.code(400).send({
                error: "apiKey, baseUrl and model are required",
            });
        }
        try {
            await runtime.configureProvider({
                apiKey,
                baseUrl,
                model,
                ...(reasoningEffort ? {reasoningEffort} : {}),
                ...(providerName ? {providerName} : {}),
            });
            return {configured: true, model};
        } catch (err) {
            log.error(
                "flutter-api", "provider push failed:",
                err instanceof Error ? err.stack ?? err.message : String(err),
            );
            return reply.code(502).send({
                error: err instanceof Error ? err.message : String(err),
            });
        }
    });

    app.post<{
        Body: { text?: string; conversationId?: string };
    }>("/agent/message", async (request, reply) => {
            const text = (request.body?.text ?? "").trim();
            if (!text) return reply.code(400).send({error: "text is required"});
            const conversationId = request.body?.conversationId?.trim() || undefined;
            const result = await runtime.runTurn(text, conversationId);
            if (!result.accepted) return reply.code(409).send(result);
            return {accepted: true};
        },
    );

    app.get<{ Params: { sessionId: string } }>(
        "/agent/events/:sessionId",
        async (request, reply) => {
            reply.raw.writeHead(200, {
                "Content-Type": "text/event-stream",
                "Cache-Control": "no-cache",
                Connection: "keep-alive",
            });
            reply.raw.write(`event: status\ndata: ${JSON.stringify(runtime.status)}\n\n`);

            const unsubscribe = subscribe((ev: unknown) => {
                const e = ev as GatewayEvent;
                reply.raw.write(`event: ${e.type}\ndata: ${JSON.stringify(e)}\n\n`);
            });

            // Comment heartbeat keeps proxies from closing the stream.
            const heartbeat = setInterval(
                () => reply.raw.write(": ping\n\n"),
                15_000,
            );

            request.raw.on("close", () => {
                clearInterval(heartbeat);
                unsubscribe();
                reply.raw.end();
            });
        },
    );

    app.post<{ Params: { sessionId: string } }>(
        "/agent/stop/:sessionId",
        async () => {
            runtime.stopTurn();
            return {stopped: true};
        },
    );

    app.get("/agent/approvals", async () => ({
        approvals: approvals.list(),
    }));

    app.post<{ Params: { approvalId: string }; Body: { approve?: boolean } }>(
        "/agent/approval/:approvalId",
        async (request, reply) => {
            const resolved = approvals.resolve(
                request.params.approvalId,
                request.body?.approve === true,
            );
            if (resolved == null) {
                return reply.code(404).send({error: "no such pending approval"});
            }
            return resolved;
        },
    );

    /// Conversations of the flight assistant (official Letta API).
    app.get("/agent/conversations", async () => ({
        conversations: await runtime.listConversations(),
    }));

    app.post("/agent/conversations", async (_request, reply) => {
        const id = await runtime.createConversation();
        if (id == null) {
            return reply.code(503).send({error: "Letta runtime not ready"});
        }
        return reply.code(201).send({id});
    });

    app.delete<{ Params: { conversationId: string } }>(
        "/agent/conversations/:conversationId",
        async (request) => {
            await runtime.deleteConversation(request.params.conversationId);
            return {deleted: request.params.conversationId};
        },
    );

    /// Conversation history (official Letta API — the app never records
    /// chat itself).
    app.get<{ Querystring: { conversationId?: string } }>(
        "/agent/history",
        async (request) => ({
            messages: await runtime.listHistory(
                request.query?.conversationId?.trim() || undefined,
            ),
        }),
    );

    app.post<{
        Body: { blockLabel?: string; value?: string };
    }>("/agent/memory/update", async (request, reply) => {
        const blockLabel = request.body?.blockLabel;
        const value = request.body?.value;
        if (!blockLabel || value == null) {
            return reply.code(400).send({error: "blockLabel and value are required"});
        }
        await runtime.updateMemory(blockLabel, value);
        return {updated: blockLabel};
    });

    app.get("/models", async () => {
        const result = await runtime.listModels();
        return result;
    });

    app.post<{ Body: { model?: string; reasoningEffort?: string } }>(
        "/agent/model",
        async (request, reply) => {
            const model = request.body?.model;
            if (!model) return reply.code(400).send({error: "model is required"});
            await runtime.updateModel(model, request.body?.reasoningEffort);
            return {model, reasoningEffort: request.body?.reasoningEffort ?? null};
        },
    );

    app.post("/agent/abort", async () => {
        runtime.abortTurn();
        return {aborted: true};
    });
}
