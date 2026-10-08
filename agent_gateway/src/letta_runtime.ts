/// Letta runtime adapter — the ONLY file that talks to the Letta Agent SDK
/// and the Letta Code app-server.
///
/// If SDK method names drift between versions, adjust this file alone; the
/// rest of the gateway only sees the typed API below (GatewayEvent,
/// agent CRUD, conversation CRUD, memory update, abort).
///
/// Local backend layout (all official surfaces):
/// - The gateway owns one Letta Code app-server subprocess
///   (`letta server --listen ws://127.0.0.1:0`, URL parsed from stdout).
/// - Provider credentials are pushed through the official app-server
///   protocol (`connect_provider`), never by writing Letta's files.
/// - The Agent SDK client reuses the same server via `appServer.url`.
///
/// Backends (env LETTA_BACKEND): "local" (default), "cloud" (LETTA_API_KEY),
/// "remote" (LETTA_REMOTE_URL). Provider push is local-only.
import {LettaAgentClient} from "@letta-ai/letta-agent-sdk";
import {type AppServerClient, createAppServerClient,} from "@letta-ai/letta-code/app-server-client";
import {EventEmitter} from "node:events";
import {createRequire} from "node:module";
import {type ChildProcess, spawn} from "node:child_process";
import {flightStudioTools} from "./mcp_registry.js";
import type {LlmProxy} from "./llm_proxy.js";
import {log} from "./logger.js";

export type {GatewayEvent} from "./event_types.js";

export type Backend = "local" | "cloud" | "remote";

export interface GatewayStatus {
    gateway: "ok";
    letta: "ok" | "starting" | "error";
    backend: Backend;
    agentReady: boolean;
    agentId: string | null;
    lettaError: string | null;
    providerConfigured: boolean;
    model: string | null;
}

const DEFAULT_AGENT_NAME = "飞行助理";
const STARTUP_TIMEOUT_MS = 60_000;
/// A permission card that nobody answers blocks the turn this long.
const ApprovalTimeoutMs = 300_000;
const LISTENING_RE = /^Listening on\s+(ws:\/\/\S+)\s*$/m;

const require = createRequire(import.meta.url);

export class LettaRuntime extends EventEmitter {
    private client: LettaAgentClient | null = null;
    private agentId: string | null = null;
    private lettaState: "ok" | "starting" | "error" = "starting";
    private lettaError: string | null = null;
    private turnActive = false;
    private currentModel: string | null = null;
    /** Conversation the live turn runs in (null = agent default). */
    private activeConversationId: string | null = null;
    /** Last successful provider push — powers title summarization. */
    private lastProvider: {baseUrl: string; apiKey: string; model: string} | null =
        null;
    /** Title this gateway wrote per conversation id. Guards against the
     * local backend's OWN auto-summary (which parrots the assistant's
     * first line and may land at ANY time — even after our write, e.g.
     * when the next resumeSession bootstraps): every turn re-verifies and
     * restores our title when it was overwritten. */
    private readonly titledConversations = new Map<string, string>();

    // Local app-server ownership.
    private serverProcess: ChildProcess | null = null;
    private serverUrl: string | null = null;
    private providerClient: AppServerClient | null = null;
    private llmProxy: LlmProxy | null = null;
    /** Live turn session (for real aborts). */
    private activeSession: {
        abort(): Promise<void>;
    } | null = null;

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

    /** Injected by index.ts at boot (provider base-URL bridge). */
    attachLlmProxy(proxy: LlmProxy): void {
        this.llmProxy = proxy;
    }

    private approvals: {
        createApproval: (tool: string, input: unknown) => { id: string };
        waitForResolution: (id: string, timeoutMs: number) => Promise<boolean>;
    } | null = null;

    /// custom tools surface as `tool` with the tool name in `detail`.
    static phaseFromLoopStatus(status: string): string {
        const s = status.toLowerCase();
        // Model-related states first — they are the classic "thinking".
        if (
            s.includes("api") ||
            s.includes("model") ||
            s.includes("llm") ||
            s.includes("think") ||
            s.includes("reason")
        ) {
            return "thinking";
        }
        if (s.includes("search") || s.includes("retriev")) return "searching";
        if (s.includes("read") || s.includes("load")) return "reading";
        if (s.includes("writ") || s.includes("edit")) return "writing";
        if (s.includes("execut") || s.includes("run") || s.includes("tool"))
            return "tool";
        if (s.includes("approval")) return "waitingApproval";
        return "working";
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
                await this.startLocalAppServer();
            }
            this.client = this.createClient();
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
        approvals: {
            createApproval: (tool: string, input: unknown) => {
                id: string;
            };
            waitForResolution: (id: string, timeoutMs: number) => Promise<boolean>;
        },
    ): void {
        this.approvals = approvals;
    }

    /** Official provider listing — used for the configured flag. */
    async listConnectProviders(): Promise<
        Array<Record<string, unknown>>
    > {
        if (this.backend !== "local" || this.serverUrl == null) return [];
        try {
            const socket = await this.providerSocket();
            const response = await socket.request("list_connect_providers", {
                request_id: socket.nextRequestId("list-providers"),
                target: "local",
            });
            const providers = (response as unknown as { providers?: unknown })
                .providers;
            return Array.isArray(providers)
                ? (providers as Array<Record<string, unknown>>)
                : [];
        } catch {
            return [];
        }
    }

    async deleteAgent(agentId: string): Promise<void> {
        await (this.client as any)?.deleteAgent?.(agentId);
        if (this.agentId === agentId) this.agentId = null;
    }

    /**
     * Lends one OpenAI-compatible credential from the FlightStudio vault to
     * the local Letta backend via the official `connect_provider` protocol
     * command, then switches the agent's model to it. Cloud/remote backends
     * have no local provider store and reject this call.
     */
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

        const socket = await this.providerSocket();
        diag("app-server socket connected");

        // Route the provider through the local proxy when its real base URL
        // breaks the /v1 convention the harness enforces (bigmodel /v4, any
        // custom path). Proxy URLs end in /v1 → used verbatim by the harness.
        let rowBaseUrl = input.baseUrl.trim().replace(/\/+$/, "");
        if (!rowBaseUrl.endsWith("/v1")) {
            if (this.llmProxy == null) {
                throw new Error("LLM proxy unavailable on this gateway");
            }
            rowBaseUrl = this.llmProxy.register({
                baseUrl: input.baseUrl.trim().replace(/\/+$/, ""),
                apiKey: input.apiKey.trim(),
            });
            diag("routed via proxy:", rowBaseUrl);
        }

        const response = await socket.request("connect_provider", {
            request_id: socket.nextRequestId("connect-provider"),
            target: "local",
            provider_id: "openai-compatible",
            fields: {
                apiKey: input.apiKey.trim(),
                baseUrl: rowBaseUrl,
            },
        });
        const result = response as unknown as {
            success?: boolean;
            error?: string;
        };
        diag("connect_provider success=", result.success, "error=", result.error);
        if (!result.success) {
            throw new Error(result.error ?? "connect_provider failed");
        }

        const handle = await this.resolveByokHandle(input.model);
        diag("resolved handle=", handle);
        await this.updateModel(handle, input.reasoningEffort);
        diag("updateModel done");
        this.lastProvider = {
            baseUrl: input.baseUrl.trim().replace(/\/+$/, ""),
            apiKey: input.apiKey.trim(),
            model: input.model,
        };
    }

    /// Resolves the agent id once more after a "not found" failure (stale

    /// Aborts the running turn (user pressed stop).
    stopTurn(): void {
        this.abortTurn();
    }

    // ── Live phase (status) + tool approvals ─────────────────────────────────

    /// Maps OFFICIAL SDK loop-status strings (e.g. WAITING_FOR_API_RESPONSE,
    /// PROCESSING_API_RESPONSE) to coarse UI phases. Extensible for MCP:

    /// (or `{type:"error",message}`). One turn at a time. When [conversationId]
    /// is given the turn runs in that conversation (official resumeSession
    /// contract accepts a conversation id), and every emitted event is tagged
    /// with it so Flutter can route deltas to the right chat tab.
    async runTurn(
        text: string,
        conversationId?: string,
    ): Promise<{ accepted: boolean; reason?: string }> {
        await this.initialize();
        if (this.lettaState !== "ok" || this.client == null || this.agentId == null) {
            return {
                accepted: false,
                reason: this.lettaError ?? "Letta runtime not ready",
            };
        }
        if (this.turnActive) {
            // A previous run is stuck (e.g. a dead approval) — abort it so
            // this turn can proceed instead of colliding with it.
            log.info("turn", "previous run active — aborting it first");
            this.abortTurn();
            await new Promise((r) => setTimeout(r, 300));
        }
        this.turnActive = true;
        this.activeConversationId = conversationId ?? null;
        const emitTurn = (event: Record<string, unknown>) => {
            if (this.activeConversationId != null) {
                this.emitEvent({
                    ...event,
                    conversationId: this.activeConversationId,
                });
            } else {
                this.emitEvent(event);
            }
        };
        emitTurn({type: "turn_start", role: "assistant"});

        const client = this.client!;
        void (async () => {
            let full = "";
            let errored = false;
            try {
                const runStream = async (agentId: string) => {
                        await using session = client.resumeSession(
                            conversationId ?? agentId,
                            {
                                // Standard mode: safe tools auto-run; risky ones
                                // flow to our canUseTool bridge (official SDK
                                // callback) → Flutter permission card.
                                permissionMode: "standard",
                                canUseTool: this.approvals
                                    ? (toolName, toolInput) =>
                                        this.handleToolApproval(toolName, toolInput)
                                    : undefined,
                            },
                        );
                    this.activeSession = session as never;
                    // Clear any approval left pending by a previous session
                    // (disconnect/deadlock) before sending.
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
                        // Forward every failure the SDK reports as a stream
                        // message — swallowing these made failed turns look
                        // like silent hangs or empty replies.
                        if (message.type === "error") {
                            const err = message as unknown as {
                                message?: string;
                                errorDetail?: string;
                                errorCode?: string;
                                stopReason?: string;
                            };
                            log.error(
                                "turn", "error full:",
                                JSON.stringify(message).slice(0, 500),
                            );
                            // Never surface an empty error — join every
                            // descriptive field, fall back to the raw event.
                            const text =
                                [err.message, err.errorDetail, err.errorCode]
                                    .filter(
                                        (part) =>
                                            part != null && part.length > 0,
                                    )
                                    .join(" | ") ||
                                `turn error (${err.stopReason ?? "unknown"})`;
                            this.turnActive = false;
                            errored = true;
                            emitTurn({type: "error", message: text});
                            return;
                        }
                        if (message.type === "result") {
                            const result = message as unknown as {
                                result?: string;
                                error?: string;
                                errorCode?: string;
                                success: boolean;
                            };
                            if (result.error != null && result.error !== "") {
                                log.error(
                                    "turn", "result error:",
                                    JSON.stringify(message).slice(0, 500),
                                );
                                this.turnActive = false;
                                errored = true;
                                emitTurn({
                                    type: "error",
                                    message:
                                        `${result.error}` +
                                        (result.errorCode
                                            ? ` (${result.errorCode})`
                                            : ""),
                                });
                                return;
                            }
                            // Final text on the result message is
                            // authoritative when no assistant deltas streamed.
                            if (result.result != null && full.length === 0) {
                                full = result.result;
                            }
                            continue;
                        }
                        // Live phase forwarding: official loop_status /
                        // tool_call / reasoning stream messages become
                        // coarse `status` events for the UI (thinking,
                        // searching, … — extensible for MCP tools).
                        if (message.type === "loop_status") {
                            const status = (
                                message as unknown as { status?: string }
                            ).status;
                            emitTurn({
                                type: "phase",
                                phase: LettaRuntime.phaseFromLoopStatus(
                                    status ?? "",
                                ),
                                raw: status,
                            });
                            continue;
                        }
                        if (message.type === "tool_call") {
                            const call = message as unknown as {
                                toolName?: string;
                            };
                            emitTurn({
                                type: "phase",
                                phase: "tool",
                                detail: call.toolName,
                            });
                            continue;
                        }
                        if (message.type === "reasoning") {
                            emitTurn({type: "phase", phase: "thinking"});
                            continue;
                        }
                        if (message.type === "assistant" && message.content) {
                            full += message.content;
                            emitTurn({
                                type: "delta",
                                content: message.content,
                            });
                        }
                    }
                };
                await this.withAgentRecovery(runStream);
                this.turnActive = false;
                // An error event already ended this turn — never follow it
                // with an empty turn_done (it would blank the bubble).
                if (!errored) {
                    emitTurn({type: "turn_done", content: full});
                    // Delayed so Letta's own auto-summary (which would
                    // otherwise parrot the assistant's first line) lands
                    // FIRST — our title then overwrites it.
                    if (conversationId != null) {
                        setTimeout(
                            () =>
                                void this.ensureConversationTitle(
                                    conversationId,
                                    text,
                                    full,
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

    /// Official canUseTool bridge: emit `approval_request` on SSE, wait for
    /// the Flutter card (or timeout → deny). Unknown/hanging requests never

    /// ENTIRELY of wrappers are dropped by the caller.
    private static stripInjectedWrappers(text: string): string {
        return text
            .replace(
                /<(system-reminder|task-notification|env-reminder|context-reminder|memory-reminder)[^>]*>[\s\S]*?<\/\1>/gi,
                "",
            )
            .replace(
                /<(system-reminder|task-notification|env-reminder|context-reminder|memory-reminder)[^>]*\/>/gi,
                "",
            )
            .trim();
    }

    /// Strips harness-injected wrapper tags (<system-reminder>,
    /// <task-notification>, …) from message text. User turns that consist

    /// 404s. Returns user/assistant turns only, oldest first. [conversationId]
    /// scopes the query to one conversation (default conversation when null).
    async listHistory(
        conversationId?: string,
    ): Promise<
        Array<{ role: "user" | "assistant"; content: string }>
    > {
        await this.initialize();
        if (this.lettaState !== "ok" || this.agentId == null) return [];
        try {
            const socket = await this.providerSocket();
            const response = await socket.request(
                "conversation_messages_list",
                {
                    request_id: socket.nextRequestId("history"),
                    conversation_id: conversationId ?? "default",
                    query: {
                        order: "asc",
                        limit: 200,
                        agent_id: this.agentId,
                    },
                },
            );
            const result = response as unknown as {
                success?: boolean;
                messages?: unknown[];
                error?: string;
            };
            if (result.success === false) {
                log.warn(
                    "history",
                    "conversation_messages_list failed:",
                    result.error,
                );
                return [];
            }
            const out: Array<{ role: "user" | "assistant"; content: string }> = [];
            for (const raw of result.messages ?? []) {
                const m = raw as Record<string, unknown>;
                const role = m.role as string;
                if (role !== "user" && role !== "assistant") continue;
                let text = "";
                const c = m.content;
                if (typeof c === "string") {
                    text = c;
                } else if (Array.isArray(c)) {
                    text = c
                        .map((b) =>
                            b != null && typeof b === "object" && "text" in b
                                ? String((b as { text?: unknown }).text ?? "")
                                : "")
                        .join("");
                }
                // Remove harness-injected wrappers the user never typed.
                text = LettaRuntime.stripInjectedWrappers(text);
                if (text.trim().length === 0) continue;
                out.push({role, content: text});
            }
            log.info("history", `loaded ${out.length} messages`);
            return out;
        } catch (err) {
            log.warn(
                "history", "error:",
                err instanceof Error ? err.message : String(err),
            );
            return [];
        }
    }

    /// Conversation history from the OFFICIAL Letta API — Flight Studio
    /// never records chat itself. Uses the raw app-server protocol
    /// (`conversation_messages_list`) with an explicit `agent_id`: the
    /// bare-spawned app-server's store otherwise resolves the default
    /// conversation to its placeholder agent ("agent-local-default") and

    /// block a turn longer than [ApprovalTimeoutMs].
    private async handleToolApproval(
        toolName: string,
        toolInput: Record<string, unknown>,
    ): Promise<{ behavior: "allow" | "deny"; message: string }> {
        const approvals = this.approvals;
        if (approvals == null) {
            return {behavior: "allow", message: "auto (no approval UI)"};
        }
        const req = approvals.createApproval(toolName, toolInput);
        log.info("approval", "request", req.id, "tool:", toolName);
        this.emitEvent({
            type: "approval_request",
            id: req.id,
            tool: toolName,
            input: toolInput,
            ...(this.activeConversationId != null
                ? {conversationId: this.activeConversationId}
                : {}),
        });
        this.emitEvent({type: "phase", phase: "waitingApproval", detail: toolName});
        const approved = await approvals.waitForResolution(
            req.id,
            ApprovalTimeoutMs,
        );
        log.info("approval", "resolved", req.id, "→", approved ? "allow" : "deny");
        this.emitEvent({
            type: "approval_resolved",
            id: req.id,
            approved,
            ...(this.activeConversationId != null
                ? {conversationId: this.activeConversationId}
                : {}),
        });
        return approved
            ? {behavior: "allow", message: "approved by user"}
            : {behavior: "deny", message: "denied by user"};
    }

    // ── Provider push (official app-server protocol) ─────────────────────────

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

    /** Spawns the Letta Code app-server and captures its websocket URL. */
    private async startLocalAppServer(): Promise<void> {
        const cliPath =
            process.env.LETTA_CLI_PATH?.trim() ||
            require.resolve("@letta-ai/letta-code");
        await new Promise<void>((resolve, reject) => {
            const child = spawn(
                process.execPath,
                [cliPath, "server", "--listen", "ws://127.0.0.1:0"],
                {stdio: ["ignore", "pipe", "pipe"], env: process.env},
            );
            let output = "";
            const timeout = setTimeout(() => {
                finish(
                    new Error(
                        `app-server startup timeout. Output:\n${output.trim()}`,
                    ),
                );
            }, STARTUP_TIMEOUT_MS);
            const finish = (err: Error | null, url?: string) => {
                clearTimeout(timeout);
                child.stdout?.off("data", onStdout);
                child.stderr?.off("data", onStderr);
                child.off("error", onError);
                child.off("exit", onExit);
                if (err) {
                    if (child.exitCode === null) child.kill();
                    reject(err);
                    return;
                }
                this.serverProcess = child;
                this.serverUrl = url!;
                // Keep draining so the pipe never fills; surface crashes.
                child.stdout?.on("data", () => {
                });
                child.stderr?.on("data", () => {
                });
                child.once("exit", () => {
                    this.serverProcess = null;
                    this.serverUrl = null;
                    this.client = null;
                    this.lettaState = "error";
                    this.lettaError = "app-server exited";
                    this.emitStatus();
                });
                resolve();
            };
            const collect = (chunk: Buffer | string) => {
                output += String(chunk);
                const match = output.match(LISTENING_RE);
                if (match?.[1]) finish(null, match[1]);
            };
            const onStdout = (chunk: Buffer | string) => collect(chunk);
            const onStderr = (chunk: Buffer | string) => collect(chunk);
            const onError = (err: Error) => finish(err);
            const onExit = (code: number | null) =>
                finish(new Error(`app-server exited early (code ${code})`));
            child.stdout?.on("data", onStdout);
            child.stderr?.on("data", onStderr);
            child.once("error", onError);
            child.once("exit", onExit);
        });
    }

    /** One shared app-server protocol client for provider commands. */
    private async providerSocket(): Promise<AppServerClient> {
        if (this.providerClient) return this.providerClient;
        if (this.serverUrl == null) {
            throw new Error("local app-server not running");
        }
        const client = createAppServerClient({url: this.serverUrl});
        await client.connect();
        this.providerClient = client;
        client.onDisconnect(() => {
            if (this.providerClient === client) this.providerClient = null;
        });
        return client;
    }

    // ── Conversations (official Letta API) ────────────────────────────────────

    /// One conversation of the flight-assistant agent as the drawer sees it.
    /// The official Conversation model has no `name`; the title lives in
    /// `summary` — a field the local backend ALSO writes itself (an
    /// auto-summary that parrots the assistant's first line and can land at
    /// any time, even after our write). This list therefore SELF-HEALS on
    /// every read:
    /// - a title we wrote that was clobbered → restored;
    /// - a legacy/auto title (long or `<think>`-prefixed) we never wrote →
    ///   rebuilt from the conversation's first user message;
    /// - short single-line titles are adopted as ours.
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
        try {
            const all = await this.client.conversations.list({
                agentId: this.agentId,
            });
            const out: Array<{
                id: string;
                title: string | null;
                lastMessageAt: string | null;
            }> = [];
            for (const c of all) {
                if (c.archived === true || c.agent_id !== this.agentId) continue;
                const summary = c.summary?.trim() ?? "";
                const known = this.titledConversations.get(c.id);
                let title: string | null = null;
                if (known != null) {
                    // We titled this conversation before.
                    title = known;
                    if (summary !== known) {
                        log.info(
                            "conversations",
                            `self-heal: restoring title of ${c.id}`,
                        );
                        await this.client.conversations
                            .update(c.id, {summary: known})
                            .catch(() => undefined);
                    }
                } else if (summary.length > 0 && !this.looksAutoSummary(summary)) {
                    // Short single-line title (ours, from a previous gateway
                    // run) — adopt it so the guard protects it too.
                    this.titledConversations.set(c.id, summary);
                    title = summary;
                } else {
                    // No title, or the backend's auto-summary junk.
                    title = await this.rebuildTitleFromFirstQuestion(c.id);
                }
                out.push({
                    id: c.id,
                    title,
                    lastMessageAt: c.last_message_at ?? c.created_at ?? null,
                });
            }
            return out.sort((a, b) =>
                (b.lastMessageAt ?? "").localeCompare(a.lastMessageAt ?? ""),
            );
        } catch (err) {
            log.warn(
                "conversations", "list failed:",
                err instanceof Error ? err.message : String(err),
            );
            return [];
        }
    }

    /// Normalizes raw LLM output into a title: strips reasoning blocks
    /// (reasoning models like GLM prefix their answer with
    /// `<think>…</think>` — sometimes unclosed — which must never become
    /// the title), strips harness wrappers and quotes, then keeps the
    /// first line. Empty when nothing usable remains (caller falls back
    /// to the user's first question).
    private cleanTitleText(raw: string): string {
        return raw
            .replace(/<(system-reminder|task-notification|env-reminder)[^>]*>[\s\S]*?<\/\1>/gi, "")
            .replace(/<think(?:ing)?>[\s\S]*?<\/think(?:ing)?>/gi, "")
            .replace(/<think(?:ing)?>[\s\S]*$/i, "")
            .replace(/["'「」『』]/g, "")
            .trim()
            .split("\n")[0]
            ?.trim() ?? "";
    }

    /// Heuristic for the backend's auto-summary junk: it repeats the
    /// assistant's first line — `<think>` fragments, reasoning text, or a
    /// long unbroken sentence. Real titles are short and single-line.
    private looksAutoSummary(summary: string): boolean {
        return summary.includes("<think") ||
            summary.includes("</think") ||
            summary.includes("<system-reminder") ||
            summary.includes("\n") ||
            summary.length > 40;
    }

    /// Rebuilds a conversation's title from its first user message (the
    /// user-approved fallback) when only auto-summary junk is stored.
    /// Persists it and remembers it; returns null when the conversation has
    /// no user message yet.
    private async rebuildTitleFromFirstQuestion(
        conversationId: string,
    ): Promise<string | null> {
        const client = this.client;
        if (client == null) return null;
        try {
            const history = await this.listHistory(conversationId);
            const first = history.find((m) => m.role === "user");
            if (first == null) return null;
            const clip = (s: string, n: number) =>
                s.length > n ? `${s.slice(0, n)}…` : s;
            const title = clip(first.content.replace(/\s+/g, " ").trim(), 24);
            if (title.length === 0) return null;
            await client.conversations.update(conversationId, {summary: title});
            this.titledConversations.set(conversationId, title);
            log.info("conversations", `rebuilt title of ${conversationId} →`, title);
            return title;
        } catch (err) {
            log.warn(
                "conversations", "title rebuild failed:",
                err instanceof Error ? err.message : String(err),
            );
            return null;
        }
    }

    /// Creates a new conversation owned by the flight assistant.
    async createConversation(): Promise<string | null> {
        await this.initialize();
        if (this.lettaState !== "ok" || this.client == null || this.agentId == null) {
            return null;
        }
        try {
            const conv = await this.client.conversations.create({
                agentId: this.agentId,
            });
            log.info("conversations", "created", conv.id);
            return conv.id;
        } catch (err) {
            log.error(
                "conversations", "create failed:",
                err instanceof Error ? err.message : String(err),
            );
            return null;
        }
    }

    /// Deletes one conversation. The local app-server protocol has no hard
    /// delete, so deletion uses the official archive semantics
    /// (`update {archived: true}`); archived conversations never appear in
    /// [listConversations] again. An actively streaming conversation is
    /// aborted first (user-confirmed behaviour).
    async deleteConversation(id: string): Promise<void> {
        await this.initialize();
        if (this.client == null) return;
        if (this.activeConversationId === id) {
            this.abortTurn();
            await new Promise((r) => setTimeout(r, 200));
        }
        await this.client.conversations.update(id, {archived: true});
        log.info("conversations", "archived (deleted)", id);
    }

    /// Ensures a conversation carries OUR title after a turn completes:
    /// - first exchange → generate one (LLM summary via the configured
    ///   provider, falling back to the user's first question clipped) and
    ///   write it into the official `summary` field, overwriting whatever
    ///   Letta's auto-summary put there;
    /// - later exchanges → re-verify: if Letta has overwritten our title
    ///   since (its auto-summary repeats the assistant's first line and can
    ///   land late, e.g. on the next resumeSession bootstrap), restore it.
    /// Runs in the background; failures never disturb the chat turn.
    private async ensureConversationTitle(
        conversationId: string,
        userText: string,
        assistantText: string,
    ): Promise<void> {
        if (this.client == null) return;
        const existing = this.titledConversations.get(conversationId);
        if (existing != null) {
            await this.guardConversationTitle(conversationId, existing);
            return;
        }
        const clip = (s: string, n: number) =>
            s.length > n ? `${s.slice(0, n)}…` : s;
        let title = "";
        try {
            const provider = this.lastProvider;
            if (provider != null) {
                const res = await fetch(
                    `${provider.baseUrl}/chat/completions`,
                    {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json",
                            Authorization: `Bearer ${provider.apiKey}`,
                        },
                        body: JSON.stringify({
                            model: provider.model,
                            max_tokens: 48,
                            temperature: 0.3,
                            messages: [
                                {
                                    role: "system",
                                    content:
                                        "Summarize this flight-assistant " +
                                        "conversation as a short title in the " +
                                        "user's language. Reply with ONLY the " +
                                        "title — at most 16 characters, no " +
                                        "quotes, no trailing period, no " +
                                        "reasoning and no thinking tags.",
                                },
                                {
                                    role: "user",
                                    content:
                                        `User: ${clip(userText, 500)}\n` +
                                        `Assistant: ${clip(assistantText, 800)}`,
                                },
                            ],
                        }),
                    },
                );
                if (res.ok) {
                    const data = (await res.json()) as {
                        choices?: Array<{ message?: { content?: string } }>;
                    };
                    title = this.cleanTitleText(
                        data.choices?.[0]?.message?.content ?? "",
                    );
                } else {
                    log.warn("title", "provider call failed:", res.status);
                }
            } else {
                log.info("title", "no provider configured — using first question");
            }
        } catch (err) {
            log.warn(
                "title", "summarize failed:",
                err instanceof Error ? err.message : String(err),
            );
        }
        // Fallback: the user's first question, clipped — always yields a
        // meaningful title even without a provider.
        if (title.length === 0) {
            title = clip(
                userText.replace(/\s+/g, " ").trim(),
                24,
            );
        }
        try {
            await this.client.conversations.update(conversationId, {
                summary: title,
            });
            this.titledConversations.set(conversationId, title);
            log.info("title", `titled ${conversationId} →`, title);
            this.emitEvent({
                type: "conversation_renamed",
                conversationId,
                title,
            });
            await this.guardConversationTitle(conversationId, title);
        } catch (err) {
            log.warn(
                "title", "write-back failed:",
                err instanceof Error ? err.message : String(err),
            );
        }
    }

    /// Re-checks (twice, a few seconds apart) that the conversation's
    /// official summary still equals OUR title; restores it when Letta's
    /// late auto-summary has overwritten it. Stops early once stable.
    private async guardConversationTitle(
        conversationId: string,
        title: string,
    ): Promise<void> {
        const client = this.client;
        if (client == null) return;
        for (const delayMs of [5_000, 15_000]) {
            await new Promise((r) => setTimeout(r, delayMs));
            if (this.client == null) return;
            try {
                const conv = await client.conversations.retrieve(conversationId);
                if (conv.summary === title) return; // Stable — done.
                log.info(
                    "title",
                    `restoring ${conversationId} (was: ${conv.summary?.slice(0, 40)})`,
                );
                await client.conversations.update(conversationId, {
                    summary: title,
                });
            } catch (err) {
                log.warn(
                    "title", "guard failed:",
                    err instanceof Error ? err.message : String(err),
                );
                return;
            }
        }
    }

    private createClient(): LettaAgentClient {
        switch (this.backend) {
            case "cloud": {
                const apiKey = process.env.LETTA_API_KEY;
                return new LettaAgentClient({
                    backend: "cloud",
                    ...(apiKey ? {apiKey} : {}),
                });
            }
            case "remote": {
                const url = process.env.LETTA_REMOTE_URL;
                if (!url)
                    throw new Error("LETTA_REMOTE_URL is required for remote backend");
                const authToken = process.env.LETTA_REMOTE_TOKEN;
                return new LettaAgentClient({
                    backend: "remote",
                    url,
                    ...(authToken ? {authToken} : {}),
                });
            }
            case "local":
            default:
                return new LettaAgentClient({
                    backend: "local",
                    appServer: {url: this.serverUrl!},
                });
        }
    }

    /// The single flight-assistant agent is managed internally by
    /// [ensureDefaultAgent]; no external switching exists.

    private async ensureDefaultAgent(): Promise<void> {
        const client = this.client!;
        let agents: Array<{ id?: string; name?: string }> = [];
        try {
            // Official management API (client.agents.list). A plain
            // `client.listAgents` does not exist — calling it silently
            // created a fresh agent on every gateway start.
            const listed = await client.agents.list();
            agents = listed.map((a) => ({id: a.id, name: a.name}));
        } catch {
            // Listing failed — fall through to create.
        }
        const found = agents.find(
            (a) => a.name === DEFAULT_AGENT_NAME && a.id != null,
        );
        if (found?.id) {
            this.agentId = found.id;
            return;
        }
        const created = await client.createAgent({
            name: DEFAULT_AGENT_NAME,
            persona:
                "You are FlightStudio's flight copilot. Explain-first: ground every " +
                "answer in provided navdata, weather or manual excerpts; never invent " +
                "data; simulator write actions always require explicit human approval. " +
                "Answer in the user's language.",
        });
        this.agentId =
            typeof created === "string" ? created : String(created ?? "");
    }

    /// id from a previous app-server lifetime) and retries [action] once.
    private async withAgentRecovery<T>(
        action: (agentId: string) => Promise<T>,
    ): Promise<T> {
        try {
            return await action(this.agentId!);
        } catch (err) {
            const message = err instanceof Error ? err.message : String(err);
            if (!message.includes("not found")) throw err;
            this.agentId = null;
            await this.ensureDefaultAgent();
            if (this.agentId == null) throw err;
            return await action(this.agentId);
        }
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

    /// Switches the agent's model and/or reasoning effort. Uses a temporary
    /// session (resumed and disposed) to apply the change server-side.
    /// Reasoning effort is optional: custom BYOK models may not support

    /** Force-refreshes the runtime model catalog via the raw protocol
     * (the SDK's ModelsClient may serve a stale within-TTL snapshot). */
    private async forceCatalog(): Promise<{
        entries?: Array<Record<string, unknown>>;
        byokProviderAliases?: Record<string, string>;
    } | null> {
        try {
            const socket = await this.providerSocket();
            const response = await socket.request("list_models", {
                request_id: socket.nextRequestId("models"),
                force: true,
            });
            return response as unknown as {
                entries?: Array<Record<string, unknown>>;
                byokProviderAliases?: Record<string, string>;
            };
        } catch {
            return null;
        }
    }

    /// Aborts the active turn by aborting the live session (agent state

    /**
     * Finds the catalog handle for [model] under the connected OpenAI-
     * compatible provider. Discovery order:
     * 1. exact handle from the force-refreshed runtime catalog (this also
     *    triggers `localModelDiscovery`, which queries {baseUrl}/models so
     *    custom endpoints list their models);
     * 2. `openai-compatible/<model>` — the base prefix; the connected row
     *    is stored under this name, and custom models are always allowed;
     * 3. `lc-openai-compatible/<model>` — the BYOK alias (DO NOT prefer:
     *    its prefix collides with `lc-openai` in some resolver versions
     *    and misroutes to the openai provider).
     */
    private async resolveByokHandle(model: string): Promise<string> {
        const prefixes = ["openai-compatible", "lc-openai-compatible"];
        const catalog = await this.forceCatalog();
        if (catalog) {
            const entries = catalog.entries ?? [];
            const aliases = Object.keys(catalog.byokProviderAliases ?? {});
            const known = new Set([...prefixes, ...aliases]);
            // What did discovery actually publish under this provider?
            const discovered: string[] = [];
            for (const entry of entries) {
                const handle =
                    (entry.handle as string | undefined) ??
                    (entry.id as string | undefined) ?? "";
                for (const prefix of known) {
                    if (handle.startsWith(`${prefix}/`)) {
                        discovered.push(handle);
                        break;
                    }
                }
            }
            log.info(
                "provider-push", "discovered openai-compatible models:",
                JSON.stringify(discovered.slice(0, 30)),
            );
            const wanted = `${prefixes[0]}/${model}`;
            // Exact match first.
            const exact = discovered.find(
                (h) => h.toLowerCase() === wanted.toLowerCase(),
            );
            if (exact) return exact;
            // Model-id match on any prefix (e.g. lc-openai-compatible/<id>).
            const byId = entries
                .map(
                    (e) =>
                        (e.handle as string | undefined) ??
                        (e.id as string | undefined) ??
                        "",
                )
                .find(
                    (h) =>
                        h.includes("/") &&
                        h.split("/").slice(1).join("/").toLowerCase() ===
                        model.toLowerCase(),
                );
            if (byId) return byId;
            // Prefix-contains fallback (provider suffixes like -250414).
            const fuzzy = discovered.find((h) =>
                h.toLowerCase().includes(`/${model.toLowerCase()}`),
            );
            if (fuzzy) {
                log.info("provider-push", "fuzzy-matched:", fuzzy);
                return fuzzy;
            }
            // The catalog may have renamed/dropped the exact variant
            // (e.g. glm-4.7-flash → glm-4.7): match the discovered model
            // whose id is the longest prefix of the requested one.
            const wantedLower = model.toLowerCase();
            let best: string | null = null;
            for (const h of discovered) {
                const id = h.split("/").slice(1).join("/").toLowerCase();
                if (id && (wantedLower.startsWith(id) || id.startsWith(wantedLower))) {
                    if (best == null || id.length > best.split("/").slice(1).join("/").length) {
                        best = h;
                    }
                }
            }
            if (best) {
                log.info(
                    "provider-push", "prefix-matched:",
                    best,
                    "(requested:",
                    model + ")",
                );
                return best;
            }
        }
        return `${prefixes[0]}/${model}`;
    }

    async updateMemory(blockLabel: string, value: string): Promise<void> {
        await this.initialize();
        if (this.client == null || this.agentId == null) return;
        await (this.client as any).updateBlock?.(this.agentId, blockLabel, {
            value,
        });
    }

    // ── Memory ────────────────────────────────────────────────────────────────

    /// FlightStudio client tools (charts / weather) — registration lands when
    /// the SDK's tool-attachment API is confirmed (G4). Pure conversation
    /// works without tools.
    registerFlightStudioToolsSafe(): void {
        // Intentionally empty — charts_read / weather_read are catalogued in
        // mcp_registry.ts and will be attached at G4 via the SDK's tool API or
        // External Tools protocol.
    }

    get toolCatalog() {
        return flightStudioTools;
    }
}
