/// FlightStudio AI safety ladder (v3) — how much of the app the AI copilot
/// may touch, per tool. The user picks the granted level (L0–L3) next to
/// the reasoning chip; the gateway denies registered tools above it.
///
/// EVERY tool call — at any level, registered or not (including the Letta
/// harness's own command/shell tools) — requires explicit manual approval
/// via the embedded permission card: the session runs in `strict`
/// permission mode and the canUseTool bridge gates all of them.
/// (Future: time-critical actions like a go-around may auto-run after a
/// countdown — deliberately NOT implemented yet.)
///
/// - L0 — nothing: no tools granted at all
/// - L1 — public read-only aeronautical data (airports, runways,
///        frequencies, weather, charts)
/// - L2 — app-state reads (flight plans, settings overview, telemetry)
/// - L3 — everything, including writes and simulator commands

export type SafetyLevel = 0 | 1 | 2 | 3;

export const DEFAULT_GRANTED_LEVEL: SafetyLevel = 1;

/** Tool name → required level. Names may arrive MCP-qualified
 * (`mcp__flightstudio-core__get_airport_data`) — matched by suffix. */
const TOOL_LEVELS: Array<{tool: string; level: SafetyLevel}> = [
    {tool: "get_airport_data", level: 1},
    {tool: "charts_read", level: 1},
    {tool: "weather_read", level: 1},
    {tool: "search_navdata", level: 1},
    {tool: "search_manual", level: 1},
    {tool: "get_sim_state", level: 2},
    {tool: "propose_action_plan", level: 2},
    {tool: "render_map", level: 3},
    {tool: "set_com_frequency", level: 3},
    {tool: "send_sim_command", level: 3},
];

export interface GuardDecision {
    allowed: boolean;
    /** Required level of the tool; null when unknown (unregistered tools
     *  still surface for manual approval — the human decides). */
    level: SafetyLevel | null;
    requiresApproval: boolean;
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

function levelOf(tool: string): SafetyLevel | null {
    const name = tool.trim().toLowerCase();
    for (const entry of TOOL_LEVELS) {
        if (name === entry.tool || name.endsWith(`__${entry.tool}`)) {
            return entry.level;
        }
    }
    return null;
}

/// [granted] may come per-turn from the Flutter message send. Everything
/// within (or below) the ladder goes to the manual-approval card — the
/// gateway never auto-runs a tool.
export function evaluateToolCall(
    tool: string,
    granted: SafetyLevel = grantedLevelFromEnv(),
): GuardDecision {
    const level = levelOf(tool);
    if (level == null) {
        // Unregistered tool — Letta's own command/shell tools land here.
        // The USER decides; nothing runs silently.
        return {
            allowed: true,
            level: null,
            requiresApproval: true,
            reason: "unregistered tool — requires manual approval",
        };
    }
    if (level > granted) {
        return {
            allowed: false,
            level,
            requiresApproval: false,
            reason:
                `tool "${tool}" requires level L${level}, ` +
                `granted is L${granted}`,
        };
    }
    return {
        allowed: true,
        level,
        requiresApproval: true,
        reason: `within granted level L${granted} — requires manual approval`,
    };
}
