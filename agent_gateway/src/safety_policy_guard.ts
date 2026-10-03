/// Safety policy v1 — level ladder from the architecture doc (§8).
///
/// L0 Explain  — read-only tools (charts, weather, navdata)
/// L1 Observe  — read simulator state
/// L2 Suggest  — generate suggestions / action plans
/// L3 Confirm  — execute low-risk sim actions after user approval
/// L4 Automate — restricted flows (future, default off)
/// BLOCKED     — never allowed (VATSIM comms, critical flight controls)

export type SafetyLevel = "L0" | "L1" | "L2" | "L3" | "L4" | "BLOCKED";

const TOOL_LEVELS: Record<string, SafetyLevel> = {
    charts_read: "L0",
    weather_read: "L0",
    search_navdata: "L0",
    search_manual: "L0",
    get_sim_state: "L1",
    propose_action_plan: "L2",
    set_com_frequency: "L3",
};

export interface GuardDecision {
    allowed: boolean;
    level: SafetyLevel;
    requiresApproval: boolean;
    reason: string;
}

export function evaluateToolCall(tool: string): GuardDecision {
    const level = TOOL_LEVELS[tool];
    if (level == null) {
        return {
            allowed: false,
            level: "BLOCKED",
            requiresApproval: false,
            reason: `tool "${tool}" is not registered with the safety policy`,
        };
    }
    if (level === "L0" || level === "L1") {
        return {allowed: true, level, requiresApproval: false, reason: "read-only"};
    }
    if (level === "L2") {
        return {
            allowed: true,
            level,
            requiresApproval: false,
            reason: "suggestion only (no execution)",
        };
    }
    if (level === "L3") {
        return {
            allowed: true,
            level,
            requiresApproval: true,
            reason: "requires explicit user confirmation",
        };
    }
    return {
        allowed: false,
        level,
        requiresApproval: false,
        reason: `${level} is not enabled in this build`,
    };
}
