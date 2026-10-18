/// FlightStudio AI safety ladder (v2) — how much of the app the AI copilot
/// may touch, per tool. The gateway denies any tool whose level exceeds the
/// user's granted level (`FLIGHTSTUDIO_AI_LEVEL`, default 1).
///
/// - L0 — nothing: no tools granted at all
/// - L1 — public read-only aeronautical data (airports, runways,
///        frequencies, weather, charts)
/// - L2 — app-state reads (flight plans, settings overview, telemetry)
/// - L3 — writes behind explicit user confirmation (permission card)
/// - L4 — low-risk writes executed automatically
/// - L5 — full control, including simulator commands
///
/// Within the granted level, the SDK's `standard` permission mode still
/// routes risky tools through the canUseTool approval bridge.

export type SafetyLevel = 0 | 1 | 2 | 3 | 4 | 5;

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
    {tool: "render_map", level: 3},
    {tool: "propose_action_plan", level: 2},
    {tool: "set_com_frequency", level: 3},
    {tool: "send_sim_command", level: 5},
];

export interface GuardDecision {
    allowed: boolean;
    /** Required level of the tool; null when unknown.
     *  Unknown tools are never auto-allowed. */
    level: SafetyLevel | null;
    requiresApproval: boolean;
    reason: string;
}

/// Parses the granted level from the environment (default L1).
export function grantedLevelFromEnv(
    env: NodeJS.ProcessEnv = process.env,
): SafetyLevel {
    const raw = Number.parseInt(env.FLIGHTSTUDIO_AI_LEVEL ?? "", 10);
    if (Number.isInteger(raw) && raw >= 0 && raw <= 5) return raw as SafetyLevel;
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

export function evaluateToolCall(
    tool: string,
    granted: SafetyLevel = grantedLevelFromEnv(),
): GuardDecision {
    const level = levelOf(tool);
    if (level == null) {
        return {
            allowed: false,
            level: null,
            requiresApproval: false,
            reason: `tool "${tool}" is not registered with the safety policy`,
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
        requiresApproval: level >= 3,
        reason: level >= 3 ? "within granted level; needs confirmation" : "read-only within granted level",
    };
}
