/// Letta runtime facade — the ONLY file the rest of the gateway sees.
///
/// The implementation is split across focused modules (see the layout
/// below); this facade wires them together and exposes the typed API
/// the outside world already used when it was a monolith:
/// GatewayEvent, agent CRUD, conversation CRUD, memory update, abort.
/// If SDK method names drift between versions, adjust the
/// implementation modules alone — external imports never change.
///
/// Layout:
/// - letta_app_server.ts — local app-server subprocess + protocol socket
///   + SDK client construction (backends: local/cloud/remote).
/// - agent_manager.ts — the single 飞行助理 agent (ensure + recovery).
/// - turn_runner.ts — live turn (resumeSession, strict approvals, MCP
///   mount) + abort.
/// - turn_stream.ts — pure stream-message → event mapping.
/// - approval_bridge.ts — canUseTool semantics over the L0–L3 ladder.
/// - provider_push.ts — BYOK connect_provider + model-handle resolution.
/// - conversations.ts — official conversation CRUD + title self-healing.
/// - memory_updater.ts + memory_guard.ts — guarded memory-block updates.
/// - mcp_mount.ts — FlightStudio Core MCP server env mapping.
import {LettaAgentClient} from "@letta-ai/letta-agent-sdk";
import {type AppServerClient} from "@letta-ai/letta-code/app-server-client";
import {EventEmitter} from "node:events";
import {type ChildProcess} from "node:child_process";

import {ensureAgent, withAgentRecovery} from "./agent_manager.js";
import {ApprovalBridge, type ApprovalPort} from "./approval_bridge.js";
import {Conversations} from "./conversations.js";
import {
    AppServerSocket,
    createLettaClient,
    startLocalAppServer,
} from "./letta_app_server.js";
import {log} from "./logger.js";
import {MemoryUpdater} from "./memory_updater.js";
import {buildMcpServers} from "./mcp_mount.js";
import {type LlmProxy} from "./llm_proxy.js";
import {
    connectProvider,
    listConnectProviders,
    resolveByokHandle,
} from "./provider_push.js";
import {type Backend, type GatewayStatus} from "./runtime_types.js";
import {TurnRunner} from "./turn_runner.js";

export type {GatewayEvent} from "./event_types.js";
export type {Backend, GatewayStatus} from "./runtime_types.js";

export class LettaRuntime extends EventEmitter {
    private client: LettaAgentClient | null = null;
    private agentId: string | null = null;
    private lettaState: "ok" | "starting" | "error" = "starting";
    private lettaError: string | null = null;
    private currentModel: string | null = null;
    /** Last successful provider push — powers title summarization. */
    private lastProvider: {baseUrl: string; apiKey: string; model: string} | null =
        null;

    // Local app-server ownership.
    private serverProcess: ChildProcess | null = null;
    private serverUrl: string | null = null;
    private socket = new AppServerSocket();
    private llmProxy: LlmProxy | null = null;

    // Wired collaborators (constructed lazily — they read this runtime's
    // state through the accessor methods below).
    private wiredApprovals: ApprovalPort | null = null;
    private readonly approvalBridge: ApprovalBridge;
    private readonly conversationsStore: Conversations;
    private readonly memoryUpdater: MemoryUpdater;
    private readonly turns: TurnRunner;

    constructor() {
        super();
        this.approvalBridge = new ApprovalBridge({
            turnAiLevel: () => this.turns.liveAiLevel,
            activeConversationId: () => this.turns.liveConversationId,
            approvals: () => this.wiredApprovals,
            emit: (event) => this.emitEvent(event),
        });
        this.conversationsStore = new Conversations({
            client: () => this.client,
            agentId: () => this.agentId,
            providerSocket: () => this.providerSocket(),
            emit: (event) => this.emitEvent(event),
        });
        this.memoryUpdater = new MemoryUpdater({
            client: () => this.client,
            agentId: () => this.agentId,
        });
        this.turns = new TurnRunner({
            client: () => this.client,
            agentId: () => this.agentId,
            ensureAgent: () => this.ensureDefaultAgent(),
            setAgentId: (id: string | null) => {
                this.agentId = id;
            },
            approvals: () => this.wiredApprovals,
            turnAiLevel: () => this.turns.liveAiLevel,
            setTurnAiLevel: () => {},
            conversations: () => this.conversationsStore,
            lastProvider: () => this.lastProvider,
            emit: (event) => this.emitEvent(event),
            canUseTool: (toolName, toolInput) =>
                this.approvalBridge.handleToolApproval(toolName, toolInput),
        });
    }

    get status(): GatewayStatus {
        return {
            gateway: "ok",
            letta: this.lettaState,
            backend: this.backend,
            agentReady: this.agentId != null,
            agentId: this.agentId,
            lettaError: this.lettaError,
            providerConfigured: this.currentModel != null,
            model: this.currentModel,
        };
    }

    readonly events = new EventEmitter();

    get backend(): Backend {
        const raw = (process.env.LETTA_BACKEND ?? "local") as Backend;
        return ["local", "cloud", "remote"].includes(raw) ? raw : "local";
    }

    /// Whether a turn is running — the session controller reads this
    /// (bracket access mirrors the pre-split private field access).
    get isTurnActive(): boolean {
        return this.turns.isTurnActive;
    }

    /** Injected by index.ts at boot (provider base-URL bridge). */
    attachLlmProxy(proxy: LlmProxy): void {
        this.llmProxy = proxy;
    }

    /// custom tools surface as `tool` with the tool name in `detail`.
    static phaseFromLoopStatus(status: string): string {
        return TurnRunner.phaseFromLoopStatus(status);
    }

    private emitEvent(event: Record<string, unknown>) {
        this.events.emit("event", event);
    }

    private emitStatus() {
        const s = this.status;
        this.emitEvent({
            type: "status",
            letta: s.letta,
            agentReady: s.agentReady,
        });
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    async initialize(): Promise<void> {
        if (this.client) return;
        this.lettaState = "starting";
        this.emitStatus();
        try {
            if (this.backend === "local" && this.serverUrl == null) {
                await startLocalAppServer({
                    onServerStarted: (process, url) => {
                        this.serverProcess = process;
                        this.serverUrl = url;
                        this.socket.setUrl(url);
                    },
                    onServerExited: () => {
                        this.serverProcess = null;
                        this.serverUrl = null;
                        this.client = null;
                        this.lettaState = "error";
                        this.lettaError = "app-server exited";
                        this.emitStatus();
                    },
                });
            }
            this.client = createLettaClient(this.backend, this.serverUrl);
            await this.ensureDefaultAgent();
            this.lettaState = "ok";
            this.lettaError = null;
        } catch (err) {
            this.client = null;
            this.lettaState = "error";
            this.lettaError = err instanceof Error ? err.message : String(err);
        }
        this.emitStatus();
    }

    /** Injected by index.ts at boot — bridges the official canUseTool
     *  callback to the Flutter permission card. */
    attachApprovals(
        approvals: ApprovalPort,
    ): void {
        this.wiredApprovals = approvals;
    }

    /// The single flight-assistant agent is managed internally by
    /// [ensureDefaultAgent]; no external switching exists.
    private async ensureDefaultAgent(): Promise<string | null> {
        const client = this.client!;
        const id = await ensureAgent(client);
        this.agentId = id;
        return id;
    }

    /// id from a previous app-server lifetime) and retries [action] once.
    private async withAgentRecovery<T>(
        action: (agentId: string) => Promise<T>,
    ): Promise<T> {
        return withAgentRecovery(
            {
                client: () => this.client,
                agentId: () => this.agentId,
                setAgentId: (id: string | null) => {
                    this.agentId = id;
                },
                ensureAgent: () => this.ensureDefaultAgent(),
            },
            action,
        );
    }

    private async providerSocket(): Promise<AppServerClient> {
        return this.socket.get();
    }

    // ── Provider push (official app-server protocol) ─────────────────────────

    /// Lends one OpenAI-compatible credential from the FlightStudio key
    /// store to the local Letta backend via the official
    /// `connect_provider` protocol command, then switches the agent's
    /// model to it. Cloud/remote backends have no local provider store
    /// and reject this call.
    async configureProvider(input: {
        apiKey: string;
        baseUrl: string;
        model: string;
        reasoningEffort?: string;
        providerName?: string;
    }): Promise<void> {
        if (this.backend !== "local") {
            throw new Error("provider push is only supported on the local backend");
        }
        const diag = (...parts: unknown[]) => log.info("provider-push", ...parts);
        diag("start: baseUrl=", input.baseUrl.replace(/\/\/[^/]*@/, "//***@"),
            "model=", input.model,
            "keyLen=", input.apiKey.trim().length);

        await this.initialize();
        if (this.lettaState !== "ok" || this.client == null || this.agentId == null) {
            throw new Error(
                this.lettaError ?? "Letta runtime not ready for provider push",
            );
        }
        diag("runtime ok, agent=", this.agentId);

        await connectProvider(() => this.providerSocket(), {
            apiKey: input.apiKey,
            baseUrl: input.baseUrl,
            proxyRegister: this.llmProxy
                ? (target) => this.llmProxy!.register(target)
                : undefined,
        });
        const socket = await this.providerSocket();
        diag("app-server socket connected");

        const handle = await resolveByokHandle(
            () => this.providerSocket(),
            input.model,
        );
        diag("resolved handle=", handle);
        await this.updateModel(handle, input.reasoningEffort);
        diag("updateModel done");
        this.lastProvider = {
            baseUrl: input.baseUrl.trim().replace(/\/+$/, ""),
            apiKey: input.apiKey.trim(),
            model: input.model,
        };
    }

    /** Official provider listing — used for the configured flag. */
    async listConnectProviders(): Promise<
        Array<Record<string, unknown>>
    > {
        if (this.backend !== "local" || this.serverUrl == null) return [];
        return listConnectProviders(() => this.providerSocket());
    }

    async deleteAgent(agentId: string): Promise<void> {
        await (this.client as any)?.deleteAgent?.(agentId);
        if (this.agentId === agentId) this.agentId = null;
    }

    /// Aborts the running turn (user pressed stop).
    stopTurn(): void {
        this.abortTurn();
    }

    /// Aborts the active turn by aborting the live session.
    abortTurn(): void {
        this.turns.abortTurn();
    }

    /// (or `{type:"error",message}`). One turn at a time. When
    /// [conversationId] is given the turn runs in that conversation.
    async runTurn(
        text: string,
        conversationId?: string,
        aiLevel?: number,
    ): Promise<{ accepted: boolean; reason?: string }> {
        await this.initialize();
        if (this.lettaState !== "ok" || this.client == null || this.agentId == null) {
            return {
                accepted: false,
                reason: this.lettaError ?? "Letta runtime not ready",
            };
        }
        return this.turns.runTurn(text, conversationId, aiLevel);
    }

    /// Conversation history from the OFFICIAL Letta API. [conversationId]
    /// scopes the query to one conversation (default conversation when
    /// null).
    async listHistory(
        conversationId?: string,
    ): Promise<
        Array<{ role: "user" | "assistant"; content: string }>
    > {
        await this.initialize();
        if (this.lettaState !== "ok" || this.agentId == null) return [];
        return this.conversationsStore.history(conversationId);
    }

    /// tiers, so a tier failure falls back to the model-only update.
    async updateModel(
        model: string,
        reasoningEffort?: string,
    ): Promise<void> {
        await this.initialize();
        if (this.client == null || this.agentId == null) return;
        const client = this.client!;
        await this.withAgentRecovery(async (agentId) => {
            await using session = client.resumeSession(agentId);
            if (reasoningEffort) {
                try {
                    await session.updateModel({
                        modelHandle: model,
                        reasoningEffort: reasoningEffort as never,
                    });
                    this.currentModel = model;
                    return;
                } catch {
                    // fall through: retry without the reasoning tier
                }
            }
            await session.updateModel({modelHandle: model} as never);
            this.currentModel = model;
        });
    }

    // ── Conversations (official Letta API) ────────────────────────────────────

    async listConversations(): Promise<
        Array<{
            id: string;
            title: string | null;
            lastMessageAt: string | null;
        }>
    > {
        await this.initialize();
        if (this.lettaState !== "ok" || this.client == null || this.agentId == null) {
            return [];
        }
        return this.conversationsStore.list();
    }

    /// Creates a new conversation owned by the flight assistant.
    async createConversation(): Promise<string | null> {
        await this.initialize();
        if (this.lettaState !== "ok" || this.client == null || this.agentId == null) {
            return null;
        }
        return this.conversationsStore.create();
    }

    /// Deletes one conversation. The local app-server protocol has no
    /// hard delete, so deletion uses the official archive semantics.
    async deleteConversation(id: string): Promise<void> {
        await this.initialize();
        if (this.client == null) return;
        await this.conversationsStore.delete(id, async () => {
            if (this.turns.liveConversationId === id) {
                this.abortTurn();
                await new Promise((r) => setTimeout(r, 200));
            }
        });
    }

    // ── Models & reasoning ────────────────────────────────────────────────────

    /// Lists available models from the Letta model catalog.
    async listModels(): Promise<any> {
        await this.initialize();
        if (this.client == null) return {entries: []};
        try {
            return await this.client.models.list();
        } catch (err) {
            return {
                entries: [],
                error: err instanceof Error ? err.message : String(err),
            };
        }
    }

    /// Updates one of the agent's memory blocks. Strictly guarded (see
    /// memory_guard.ts): the block label must be on the allow-list, the
    /// value is length-capped, and obvious secret shapes are rejected.
    async updateMemory(blockLabel: string, value: string): Promise<void> {
        await this.memoryUpdater.update(blockLabel, value);
    }

    // ── FlightStudio Core MCP server (Dart stdio) ────────────────────────────

    /** Session-scoped MCP servers for resumeSession. The app's Dart
     *  stdio server (`dart run bin/mcp_flightstudio_core.dart`) exposes
     *  the L0–L3-gated FlightStudio toolset (airport dossier, charts,
     *  weather) with per-call audit logging. Returns undefined when the
     *  project root is unknown (release layout) — the agent then runs
     *  tool-less. */
    buildMcpServers():
        | Record<
              string,
              {
                  type: "stdio";
                  command: string;
                  args: string[];
                  env: Record<string, string>;
                  cwd: string;
              }
          >
        | undefined {
        return buildMcpServers();
    }
}
