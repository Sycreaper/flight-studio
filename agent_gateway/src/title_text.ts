/// Pure title-text helpers shared by the runtime and tests — no I/O, no
/// SDK imports. These exist because the local Letta backend and reasoning
/// LLMs both leak fragments (`<think>…`, `<system-reminder>…`, long
/// first-line transcripts) into the conversation-summary field, which the
/// UI surfaces as the conversation title.

/// Strips reasoning blocks from raw LLM output. Reasoning models (GLM &co)
/// prefix their chat-completions answer with `<think>…</think>` — sometimes
/// unclosed when truncated. Empty string when nothing but thinking came
/// back (the caller falls back to the user's first question).
export function stripThinking(raw: string): string {
    return raw
        .replace(
            /<(system-reminder|task-notification|env-reminder)[^>]*>[\s\S]*?<\/\1>/gi,
            "",
        )
        .replace(/<think(?:ing)?>[\s\S]*?<\/think(?:ing)?>/gi, "")
        .replace(/<think(?:ing)?>[\s\S]*$/i, "");
}

/// Normalizes stripped LLM output into a title: no wrapper quotes, first
/// line only, trimmed. Empty when nothing usable remains.
export function cleanTitleText(raw: string): string {
    return (
        stripThinking(raw)
            .replace(/["'「」『』]/g, "")
            .trim()
            .split("\n")[0]
            ?.trim() ?? ""
    );
}

/// Heuristic for auto-summary junk in the summary field: the backend
/// repeats the assistant's first line — `<think>` fragments, reasoning
/// text, or a long unbroken sentence. Real titles are short, single-line.
export function looksAutoSummary(summary: string): boolean {
    return (
        summary.includes("<think") ||
        summary.includes("</think") ||
        summary.includes("<system-reminder") ||
        summary.includes("\n") ||
        summary.length > 40
    );
}

/// Clips a single-line string to [max] characters with an ellipsis.
export function clipText(s: string, max: number): string {
    return s.length > max ? `${s.slice(0, max)}…` : s;
}
