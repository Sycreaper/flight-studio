/// Tool-approval bridge — split from letta_runtime.ts. Implements the
/// official canUseTool callback semantics on top of the tool policy
/// (safety_policy_guard.ts) and the approval controller:
///
/// - bash-style command tools (Bash, exec_command, write_stdin) are
///   denied outright at every level, without any record;
/// - skills run silently — no card, no record;
/// - auto-allowed MCP data reads (L1+) run immediately but emit an
///   `approval_auto` record card inline in the transcript;
/// - every other call — L0 turns, MCP write tools, unregistered MCP
///   tools, other harness tools (Read, Edit, Task, …) — requires the
///   manual in-chat approval card;
/// - MCP calls denied by policy still emit an `approval_auto` record
///   card marked denied: EVERY MCP call leaves a card in the transcript;
/// - when no approval controller is wired, manual confirmation is
///   DENIED (fail-closed) — an unwired approval path must never fall
///   back to auto-allowing tools.
///
/// A permission card that nobody answers blocks the turn for
/// [ApprovalTimeoutMs] (timeout → deny).

import {
    evaluateToolCall,
    grantedLevelFromEnv,
    isMcpQualified,
    type SafetyLevel,
} from "./safety_policy_guard.js";
import {log} from "./logger.js";

/// A permission card that nobody answers blocks the turn this long.
export const ApprovalTimeoutMs = 300_000;

export interface ApprovalPort {
    createApproval: (tool: string, input: unknown) => { id: string };
    waitForResolution: (id: string, timeoutMs: number) => Promise<boolean>;
}

export interface ApprovalBridgeDeps {
    /// AI access level (L0–L3) requested for the live turn; null = the
    /// FLIGHTSTUDIO_AI_LEVEL environment default.
    turnAiLevel(): number | null;
    /// Conversation the live turn runs in (null = agent default);
    /// approval events are tagged with it so Flutter routes the card.
    activeConversationId(): string | null;
    approvals(): ApprovalPort | null;
    emit(event: Record<string, unknown>): void;
}

export class ApprovalBridge {
    private autoSeq = 0;

    constructor(private readonly deps: ApprovalBridgeDeps) {}

    /// Official canUseTool bridge: emit `approval_request` on SSE, wait
    /// for the Flutter card (or timeout → deny). Unknown/hanging
    /// requests never auto-allow.
    async handleToolApproval(
        toolName: string,
        toolInput: Record<string, unknown>,
    ): Promise<{ behavior: "allow" | "deny"; message: string }> {
        const granted = (this.deps.turnAiLevel() != null
            ? (this.deps.turnAiLevel() as SafetyLevel)
            : grantedLevelFromEnv());
        const guard = evaluateToolCall(toolName, granted);
        if (!guard.allowed) {
            log.warn(
                "approval", "denied by safety policy:", guard.reason,
            );
            // EVERY MCP call is recorded — even a policy denial surfaces
            // as an already-resolved (denied) card in the transcript.
            // Bash-style command denials stay unrecorded.
            if (isMcpQualified(toolName)) {
                const conversationId = this.deps.activeConversationId();
                this.deps.emit({
                    type: "approval_auto",
                    id: `auto_${Date.now()}_${++this.autoSeq}`,
                    tool: toolName,
                    input: toolInput,
                    denied: true,
                    ...(conversationId != null ? {conversationId} : {}),
                });
            }
            return {behavior: "deny", message: guard.reason};
        }
        // Skills run silently — no card, no record.
        if (guard.silent) {
            log.info("approval", "skill allowed:", toolName);
            return {
                behavior: "allow",
                message: "skill usage — always allowed",
            };
        }
        // Auto-allowed data reads (L1+) still RECORD the call: an
        // `approval_auto` event renders an inline, already-resolved card
        // in the transcript at the tool-call position.
        if (guard.autoAllowed) {
            const conversationId = this.deps.activeConversationId();
            this.deps.emit({
                type: "approval_auto",
                id: `auto_${Date.now()}_${++this.autoSeq}`,
                tool: toolName,
                input: toolInput,
                ...(conversationId != null ? {conversationId} : {}),
            });
            log.info("approval", "auto-allowed tool:", toolName);
            return {
                behavior: "allow",
                message: "auto-allowed (L1+ data read)",
            };
        }
        const approvals = this.deps.approvals();
        if (approvals == null) {
            log.warn(
                "approval",
                "no approval controller wired — failing closed for tool:",
                toolName,
            );
            return {
                behavior: "deny",
                message: "no approval UI available — tool call denied " +
                    "(fail-closed)",
            };
        }
        const req = approvals.createApproval(toolName, toolInput);
        log.info("approval", "request", req.id, "tool:", toolName);
        const conversationId = this.deps.activeConversationId();
        this.deps.emit({
            type: "approval_request",
            id: req.id,
            tool: toolName,
            input: toolInput,
            ...(conversationId != null ? {conversationId} : {}),
        });
        this.deps.emit({
            type: "phase",
            phase: "waitingApproval",
            detail: toolName,
        });
        const approved = await approvals.waitForResolution(
            req.id,
            ApprovalTimeoutMs,
        );
        log.info("approval", "resolved", req.id, "→", approved ? "allow" : "deny");
        this.deps.emit({
            type: "approval_resolved",
            id: req.id,
            approved,
            ...(conversationId != null ? {conversationId} : {}),
        });
        return approved
            ? {behavior: "allow", message: "approved by user"}
            : {behavior: "deny", message: "denied by user"};
    }
}
