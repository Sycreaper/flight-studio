/// Tool-approval bridge — split from letta_runtime.ts. Implements the
/// official canUseTool callback semantics on top of the L0–L3 safety
/// ladder (safety_policy_guard.ts) and the approval controller:
///
/// - tools above the granted level are denied outright, before any UI
///   prompt;
/// - L1 (public aeronautical, read-only) tools run WITHOUT the approval
///   card — reading public airports/charts/weather is the copilot's
///   bread and butter and a card per call adds no safety;
/// - L2/L3 and unregistered tools (harness command/shell tools) require
///   the manual in-chat approval card;
/// - when no approval controller is wired, the call is DENIED
///   (fail-closed) — an unwired approval path must never fall back to
///   auto-allowing tools.
///
/// A permission card that nobody answers blocks the turn for
/// [ApprovalTimeoutMs] (timeout → deny).

import {
    evaluateToolCall,
    grantedLevelFromEnv,
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
            return {behavior: "deny", message: guard.reason};
        }
        // L1 (public aeronautical, read-only) tools run WITHOUT the
        // approval card — reading public airports/charts/weather is the
        // copilot's bread and butter and a card per call adds no safety.
        // L2/L3 and unregistered tools (harness command/shell tools)
        // still require the manual in-chat approval card, and the audit
        // trail still records every call. Auto-allowing a
        // non-read-only level would be a bug.
        if (guard.level === 1 && granted >= 1) {
            log.info(
                "approval", "auto-allowed L1 tool:", toolName,
            );
            return {
                behavior: "allow",
                message: "auto-allowed (L1 public aeronautical data)",
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
