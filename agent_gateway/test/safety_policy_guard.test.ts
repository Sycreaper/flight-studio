/// Safety-policy ladder L0–L5 — grant math, unknown tools, env parsing,
/// MCP-qualified name matching.
import assert from "node:assert/strict";
import {test} from "node:test";

import {
    DEFAULT_GRANTED_LEVEL,
    evaluateToolCall,
    grantedLevelFromEnv,
} from "../src/safety_policy_guard.js";

test("L1 aeronautical tools are within the default grant but STILL need approval", () => {
    for (const tool of ["get_airport_data", "charts_read", "weather_read"]) {
        const d = evaluateToolCall(tool, 1);
        assert.equal(d.allowed, true, tool);
        assert.equal(d.level, 1, tool);
        assert.equal(d.requiresApproval, true, `${tool} must require approval`);
    }
});

test("MCP-qualified names match by suffix", () => {
    const d = evaluateToolCall("mcp__flightstudio-core__get_airport_data", 1);
    assert.equal(d.allowed, true);
    assert.equal(d.level, 1);
    assert.equal(d.requiresApproval, true);
});

test("tools above the granted level are denied outright", () => {
    const denied = evaluateToolCall("get_sim_state", 1);
    assert.equal(denied.allowed, false);
    assert.equal(denied.level, 2);
    assert.match(denied.reason, /requires level L2, granted is L1/);

    const simCmd = evaluateToolCall("send_sim_command", 2);
    assert.equal(simCmd.allowed, false);
    assert.equal(simCmd.level, 3);
});

test("L3 grants everything registered; every call needs approval", () => {
    for (const tool of ["send_sim_command", "set_com_frequency", "get_airport_data"]) {
        const d = evaluateToolCall(tool, 3);
        assert.equal(d.allowed, true, tool);
        assert.equal(d.requiresApproval, true, tool);
    }
});

test("unregistered tools (e.g. harness command tools) surface for MANUAL approval", () => {
    const d = evaluateToolCall("Bash");
    assert.equal(d.allowed, true);
    assert.equal(d.level, null);
    assert.equal(d.requiresApproval, true);
    assert.match(d.reason, /manual approval/);
});

test("L0 grants nothing registered but unregistered tools still ask", () => {
    const denied = evaluateToolCall("get_airport_data", 0);
    assert.equal(denied.allowed, false);
    assert.equal(denied.level, 1);
    const ask = evaluateToolCall("Bash", 0);
    assert.equal(ask.allowed, true);
    assert.equal(ask.requiresApproval, true);
});

test("grantedLevelFromEnv parses and clamps to 0–3", () => {
    assert.equal(grantedLevelFromEnv({}), DEFAULT_GRANTED_LEVEL);
    assert.equal(DEFAULT_GRANTED_LEVEL, 1);
    assert.equal(grantedLevelFromEnv({FLIGHTSTUDIO_AI_LEVEL: "3"}), 3);
    assert.equal(grantedLevelFromEnv({FLIGHTSTUDIO_AI_LEVEL: "0"}), 0);
    // L4/L5 no longer exist — clamped back to the default.
    assert.equal(grantedLevelFromEnv({FLIGHTSTUDIO_AI_LEVEL: "5"}), 1);
    assert.equal(grantedLevelFromEnv({FLIGHTSTUDIO_AI_LEVEL: "junk"}), 1);
});
