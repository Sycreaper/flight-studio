/// Turn runner — split from letta_runtime.ts. Owns the live chat turn:
/// resumeSession (strict permission mode + canUseTool bridge +
/// FlightStudio Core MCP mount), stream consumption (turn_stream.ts),
/// and post-turn title scheduling.

import {type LettaAgentClient} from "@letta-ai/letta-agent-sdk";

import {ApprovalBridge, type ApprovalPort} from "./approval_bridge.js";
import {type Conversations} from "./conversations.js";
import {buildMcpServers} from "./mcp_mount.js";
import {log} from "./logger.js";
import {phaseFromLoopStatus, processStreamMessage} from "./turn_stream.js";

export interface TurnDeps {
    client(): LettaAgentClient | null;
    agentId(): string | null;
    ensureAgent(): Promise<string | null>;
    setAgentId(id: string | null): void;
    approvals(): ApprovalPort | null;
    /// AI access level (L0–L3) requested for the live turn.
    turnAiLevel(): number | null;
    /// Sets the turn-scoped AI level BEFORE the turn starts.
    setTurnAiLevel(level: number | null): void;
    conversations(): Conversations;
    /// Last successful provider push — powers title summarization.
    lastProvider(): {baseUrl: string; apiKey: string; model: string} | null;
    emit(event: Record<string, unknown>): void;
    canUseTool(toolName: string, toolInput: Record<string, unknown>):
        Promise<{behavior: "allow" | "deny"; message: string}>;
}

export class TurnRunner {
    private turnActive = false;
    /// Conversation the live turn runs in (null = agent default).
    private activeConversationId: string | null = null;
    private turnAiLevel: number | null = null;
    /// Live turn session (for real aborts).
    private activeSession: { abort(): Promise<void> } | null = null;

    constructor(private readonly deps: TurnDeps) {}

    get isTurnActive(): boolean {
        return this.turnActive;
    }

    get liveConversationId(): string | null {
        return this.activeConversationId;
    }

    get liveAiLevel(): number | null {
        return this.turnAiLevel;
    }

    /// Maps OFFICIAL SDK loop-status strings (e.g.
    /// WAITING_FOR_API_RESPONSE, PROCESSING_API_RESPONSE) to coarse UI
    /// phases. Extensible for MCP: custom tools surface as `tool` with
    /// the tool name in `detail`.
    static phaseFromLoopStatus(status: string): string {
        return phaseFromLoopStatus(status);
    }

    /// (or `{type:"error",message}`). One turn at a time. When
    /// [conversationId] is given the turn runs in that conversation
    /// (official resumeSession contract accepts a conversation id), and
    /// every emitted event is tagged with it so Flutter can route
    /// deltas to the right chat tab.
    async runTurn(
        text: string,
        conversationId?: string,
        aiLevel?: number,
    ): Promise<{ accepted: boolean; reason?: string }> {
        const client = this.deps.client();
        if (client == null || this.deps.agentId() == null) {
            return {
                accepted: false,
                reason: "Letta runtime not ready",
            };
        }
        if (this.turnActive) {
            // A previous run is stuck (e.g. a dead approval) — abort it
            // so this turn can proceed instead of colliding with it.
            log.info("turn", "previous run active — aborting it first");
            this.abortTurn();
            await new Promise((r) => setTimeout(r, 300));
        }
        this.turnActive = true;
        this.deps.setTurnAiLevel(aiLevel ?? null);
        this.turnAiLevel = aiLevel ?? null;
        this.activeConversationId = conversationId ?? null;
        const emitTurn = (event: Record<string, unknown>) => {
            if (this.activeConversationId != null) {
                this.deps.emit({
                    ...event,
                    conversationId: this.activeConversationId,
                });
            } else {
                this.deps.emit(event);
            }
        };
        emitTurn({type: "turn_start", role: "assistant"});

        const liveClient = client;
        void (async () => {
            const sink = {
                emit: emitTurn,
                full: "",
                errored: false,
            };
            try {
                const runStream = async (agentId: string) => {
                    const mcpServers = buildMcpServers();
                    await using session = liveClient.resumeSession(
                        conversationId ?? agentId,
                        {
                            // Strict mode: EVERY tool call — including
                            // the harness's own command tools and all
                            // FlightStudio Core MCP tools — flows to our
                            // canUseTool bridge → safety-level check →
                            // embedded permission card. Nothing runs
                            // silently.
                            permissionMode: "strict",
                            canUseTool: this.deps.approvals() != null
                                ? (toolName: string, toolInput: Record<string, unknown>) =>
                                    this.deps.canUseTool(toolName, toolInput)
                                : undefined,
                            // FlightStudio Core — the app's Dart stdio MCP
                            // server (tools run in the app's ecosystem:
                            // navdata DB reads, weather, charts; audited
                            // to mcp-audit.sqlite). Only mounted in
                            // dev-style layouts where the project root
                            // is known.
                            ...(mcpServers ? {mcpServers} : {}),
                        },
                    );
                    this.activeSession = session as never;
                    // Clear any approval left pending by a previous
                    // session (disconnect/deadlock) before sending.
                    try {
                        await (
                            session as unknown as {
                                recoverPendingApprovals?: () => Promise<unknown>;
                            }
                        ).recoverPendingApprovals?.();
                    } catch {
                        // Optional — continue when unsupported.
                    }
                    await session.send(text);
                    log.info("turn", "sent, streaming");
                    for await (const message of session.stream()) {
                        log.debug(
                            "turn", "msg type=", message.type,
                            "content=" in message
                                ? JSON.stringify(
                                    (message as { content?: unknown })
                                        .content,
                                )?.slice(0, 120)
                                : "",
                        );
                        if (processStreamMessage(message, sink)) return;
                    }
                };
                await this.withAgentRecovery(runStream);
                this.turnActive = false;
                // An error event already ended this turn — never follow
                // it with an empty turn_done (it would blank the
                // bubble).
                if (!sink.errored) {
                    emitTurn({type: "turn_done", content: sink.full});
                    // Delayed so Letta's own auto-summary (which would
                    // otherwise parrot the assistant's first line) lands
                    // FIRST — our title then overwrites it.
                    if (conversationId != null) {
                        setTimeout(
                            () =>
                                void this.deps.conversations().ensureTitle(
                                    conversationId,
                                    text,
                                    sink.full,
                                    this.deps.lastProvider(),
                                ),
                            2_000,
                        );
                    }
                }
            } catch (err) {
                this.turnActive = false;
                emitTurn({
                    type: "error",
                    message: err instanceof Error ? err.message : String(err),
                });
            } finally {
                if (this.activeConversationId === (conversationId ?? null)) {
                    this.activeConversationId = null;
                }
            }
        })();

        return {accepted: true};
    }

    /// Aborts the active turn by aborting the live session (agent state
    /// survives in ~/.letta); the next runTurn resumes a fresh session.
    abortTurn(): void {
        this.turnActive = false;
        const session = this.activeSession;
        this.activeSession = null;
        if (session != null) {
            void session.abort().catch(() => {
                // Best-effort — the run may already be finished.
            });
        }
    }

    /// Runs [action] with the agent id; on a "not found" failure
    /// (stale agent id from a previous app-server lifetime) re-resolves
    /// the agent once and retries [action].
    private async withAgentRecovery<T>(
        action: (agentId: string) => Promise<T>,
    ): Promise<T> {
        try {
            return await action(this.deps.agentId()!);
        } catch (err) {
            const message = err instanceof Error ? err.message : String(err);
            if (!message.includes("not found")) throw err;
            this.deps.setAgentId(null);
            const id = await this.deps.ensureAgent();
            this.deps.setAgentId(id);
            if (id == null) throw err;
            return await action(id);
        }
    }
}
