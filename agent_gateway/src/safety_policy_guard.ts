/// FlightStudio AI tool policy (v5) — how every copilot tool call is
/// classified and gated. The user picks the granted level (L0–L3) next to
/// the reasoning chip; the session runs in `strict` permission mode and
/// the canUseTool bridge routes ALL tool calls through here.
///
/// Classification:
/// - **Skills** (the harness `Skill` tool): silently allowed at every
///   level — no card, no record.
/// - **Bash-style command tools** (`Bash`, `exec_command`, `write_stdin`):
///   DENIED at every level, without any record — the copilot never
///   drives the host shell.
/// - **FlightStudio MCP read tools** (navdata, charts, weather, sim
///   state, map render, action-plan proposal): L0 → manual approval
///   card; L1+ → auto-allowed with a record card in the transcript.
/// - **FlightStudio MCP write tools** (simulator commands, COM writes):
///   manual approval card at EVERY level — writes never auto-run.
/// - **Everything else** (unregistered MCP tools, other harness tools
///   like `Read`/`Edit`/`Task`, unknown names): manual approval card at
///   every level — the user decides. Nothing is blanket-denied except
///   bash-style commands.

export type SafetyLevel = 0 | 1 | 2 | 3;

export const DEFAULT_GRANTED_LEVEL: SafetyLevel = 1;

/// Read tools touch data only; write tools act on the simulator.
export type ToolKind = "read" | "write";

/** Registered FlightStudio Core tools. Names may arrive MCP-qualified
 * (`mcp__flightstudio-core__get_airport_data`) — matched by suffix. */
const TOOL_KINDS: Array<{tool: string; kind: ToolKind}> = [
    {tool: "get_airport_data", kind: "read"},
    {tool: "charts_read", kind: "read"},
    {tool: "weather_read", kind: "read"},
    {tool: "search_navdata", kind: "read"},
    {tool: "search_manual", kind: "read"},
    {tool: "get_sim_state", kind: "read"},
    {tool: "propose_action_plan", kind: "read"},
    {tool: "render_map", kind: "read"},
    {tool: "set_com_frequency", kind: "write"},
    {tool: "send_sim_command", kind: "write"},
];

export interface GuardDecision {
    allowed: boolean;
    /** Registered tool kind; null for unclassified names. */
    kind: ToolKind | null;
    /// Manual approval card in the chat transcript.
    requiresApproval: boolean;
    /// Auto-allowed — still recorded as a (resolved) card.
    autoAllowed: boolean;
    /// Auto-allowed WITHOUT any card or record (skills only).
    silent: boolean;
    reason: string;
}

/// Parses the granted level from the environment (default L1, clamp 0–3).
export function grantedLevelFromEnv(
    env: NodeJS.ProcessEnv = process.env,
): SafetyLevel {
    const raw = Number.parseInt(env.FLIGHTSTUDIO_AI_LEVEL ?? "", 10);
    if (Number.isInteger(raw) && raw >= 0 && raw <= 3) return raw as SafetyLevel;
    return DEFAULT_GRANTED_LEVEL;
}

function kindOf(tool: string): ToolKind | null {
    const name = tool.trim().toLowerCase();
    for (const entry of TOOL_KINDS) {
        if (name === entry.tool || name.endsWith(`__${entry.tool}`)) {
            return entry.kind;
        }
    }
    return null;
}

function isSkill(tool: string): boolean {
    const name = tool.trim().toLowerCase();
    return name === "skill" || name.endsWith("__skill");
}

/// Bash-style shell-execution tools of the Letta harness.
export function isBashCommand(tool: string): boolean {
    const name = tool.trim().toLowerCase();
    return (
        name === "bash" ||
        name.endsWith("__bash") ||
        name === "exec_command" ||
        name.endsWith("__exec_command") ||
        name === "write_stdin" ||
        name.endsWith("__write_stdin")
    );
}

export function isMcpQualified(tool: string): boolean {
    return tool.trim().toLowerCase().startsWith("mcp__");
}

/// [granted] may come per-turn from the Flutter message send.
export function evaluateToolCall(
    tool: string,
    granted: SafetyLevel = grantedLevelFromEnv(),
): GuardDecision {
    // Skills always run — no card, no record.
    if (isSkill(tool)) {
        return {
            allowed: true,
            kind: null,
            requiresApproval: false,
            autoAllowed: false,
            silent: true,
            reason: "skill usage — always allowed, never recorded",
        };
    }
    // Bash-style commands are denied outright, without any record.
    if (isBashCommand(tool)) {
        return {
            allowed: false,
            kind: null,
            requiresApproval: false,
            autoAllowed: false,
            silent: false,
            reason: `bash commands ("${tool}") are denied at every level`,
        };
    }
    const kind = kindOf(tool);
    if (kind != null) {
        // L0 asks for EVERY tool call; L1+ auto-allows data reads
        // (Flight Studio app data + simulator data).
        if (kind === "read") {
            if (granted >= 1) {
                return {
                    allowed: true,
                    kind,
                    requiresApproval: false,
                    autoAllowed: true,
                    silent: false,
                    reason: "data read auto-allowed (L1+)",
                };
            }
            return {
                allowed: true,
                kind,
                requiresApproval: true,
                autoAllowed: false,
                silent: false,
                reason: "L0 — every tool call needs manual confirmation",
            };
        }
        // Write tools NEVER auto-run — manual card at every level.
        return {
            allowed: true,
            kind,
            requiresApproval: true,
            autoAllowed: false,
            silent: false,
            reason: "write tool — manual confirmation at every level",
        };
    }
    // Unregistered MCP tools and other harness tools (Read, Edit, Task,
    // …) — the user decides. Nothing is blanket-denied except bash.
    return {
        allowed: true,
        kind: null,
        requiresApproval: true,
        autoAllowed: false,
        silent: false,
        reason: isMcpQualified(tool)
            ? "unregistered MCP tool — requires manual approval"
            : "harness tool — requires manual approval",
    };
}
