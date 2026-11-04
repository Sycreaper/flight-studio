/// Turn stream processing — split from letta_runtime.ts. Pure event
/// mapping over the messages the SDK session stream yields: assistant
/// deltas, loop_status → phase, tool_call, reasoning, result and error.
/// The owner supplies an `emit` callback; no SDK or runtime state is
/// touched here, which keeps the messy event shapes testable in
/// isolation.

/** Coarse UI phase for an official SDK loop-status string. Extensible
 *  for MCP: custom tools surface as `tool` with the tool name in
 *  `detail`. */
export function phaseFromLoopStatus(status: string): string {
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

/** Strips harness-injected wrapper tags (<system-reminder>,
 *  <task-notification>, …) from message text. User turns that consist
 *  ENTIRELY of wrappers are dropped by the caller. */
export function stripInjectedWrappers(text: string): string {
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

/// Where each processed stream message lands. `full` accumulates the
/// assistant text; `errored` records that an error event already ended
/// the turn (so the owner must NOT emit an empty turn_done after it).
export interface StreamSink {
    emit(event: Record<string, unknown>): void;
    full: string;
    errored: boolean;
}

/** Processes ONE stream message into sink events; returns true when the
 *  turn must stop (error / result-error). Pure apart from sink mutation.
 *  Callers iterate their stream and delegate every message here. */
export function processStreamMessage(
    message: { type: string; content?: unknown },
    sink: StreamSink,
): boolean {
    // Forward every failure the SDK reports as a stream message —
    // swallowing these made failed turns look like silent hangs or
    // empty replies.
    if (message.type === "error") {
        const err = message as unknown as {
            message?: string;
            errorDetail?: string;
            errorCode?: string;
            stopReason?: string;
        };
        // Never surface an empty error — join every descriptive field,
        // fall back to the raw event.
        const text =
            [err.message, err.errorDetail, err.errorCode]
                .filter(
                    (part) => part != null && part.length > 0,
                )
                .join(" | ") ||
            `turn error (${err.stopReason ?? "unknown"})`;
        sink.errored = true;
        sink.emit({type: "error", message: text});
        return true;
    }
    if (message.type === "result") {
        const result = message as unknown as {
            result?: string;
            error?: string;
            errorCode?: string;
            success: boolean;
        };
        if (result.error != null && result.error !== "") {
            sink.errored = true;
            sink.emit({
                type: "error",
                message:
                    `${result.error}` +
                    (result.errorCode
                        ? ` (${result.errorCode})`
                        : ""),
            });
            return true;
        }
        // Final text on the result message is authoritative when no
        // assistant deltas streamed.
        if (result.result != null && sink.full.length === 0) {
            sink.full = result.result;
        }
        return false;
    }
    // Live phase forwarding: official loop_status / tool_call /
    // reasoning stream messages become coarse `status` events for the
    // UI (thinking, searching, … — extensible for MCP tools).
    if (message.type === "loop_status") {
        const status = (message as unknown as { status?: string }).status;
        sink.emit({
            type: "phase",
            phase: phaseFromLoopStatus(status ?? ""),
            raw: status,
        });
        return false;
    }
    if (message.type === "tool_call") {
        const call = message as unknown as { toolName?: string };
        sink.emit({
            type: "phase",
            phase: "tool",
            detail: call.toolName,
        });
        return false;
    }
    if (message.type === "reasoning") {
        sink.emit({type: "phase", phase: "thinking"});
        return false;
    }
    if (message.type === "assistant" && message.content) {
        const content = message.content;
        if (typeof content === "string") {
            sink.full += content;
            sink.emit({type: "delta", content});
        }
    }
    return false;
}
