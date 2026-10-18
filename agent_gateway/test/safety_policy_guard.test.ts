/// Safety-policy ladder L0–L5 — grant math, unknown tools, env parsing,
/// MCP-qualified name matching.
import assert from "node:assert/strict";
import {test} from "node:test";

import {
    DEFAULT_GRANTED_LEVEL,
    evaluateToolCall,
    grantedLevelFromEnv,
} from "../src/safety_policy_guard.js";

test("L1 aeronautical tools run at the default grant", () => {
    for (const tool of ["get_airport_data", "charts_read", "weather_read"]) {
        const d = evaluateToolCall(tool, 1);
        assert.equal(d.allowed, true, tool);
        assert.equal(d.level, 1, tool);
        assert.equal(d.requiresApproval, false, tool);
    }
});

test("MCP-qualified names match by suffix", () => {
    const d = evaluateToolCall("mcp__flightstudio-core__get_airport_data", 1);
    assert.equal(d.allowed, true);
    assert.equal(d.level, 1);
});

test("tools above the granted level are denied", () => {
    const denied = evaluateToolCall("get_sim_state", 1);
    assert.equal(denied.allowed, false);
    assert.equal(denied.level, 2);
    assert.match(denied.reason, /requires level L2, granted is L1/);

    const simCmd = evaluateToolCall("send_sim_command", 4);
    assert.equal(simCmd.allowed, false);
    assert.equal(simCmd.level, 5);
});

test("L5 grant allows everything registered; L3+ tools want confirmation", () => {
    for (const tool of ["send_sim_command", "set_com_frequency"]) {
        const d = evaluateToolCall(tool, 5);
        assert.equal(d.allowed, true, tool);
        assert.equal(d.requiresApproval, true, tool);
    }
    const l1 = evaluateToolCall("get_airport_data", 5);
    assert.equal(l1.allowed, true);
    assert.equal(l1.requiresApproval, false);
});

test("unregistered tools are never allowed", () => {
    const d = evaluateToolCall("rm_rf_everything");
    assert.equal(d.allowed, false);
    assert.equal(d.level, null);
    assert.match(d.reason, /not registered/);
});

test("grantedLevelFromEnv parses and clamps", () => {
    assert.equal(grantedLevelFromEnv({}), DEFAULT_GRANTED_LEVEL);
    assert.equal(DEFAULT_GRANTED_LEVEL, 1);
    assert.equal(grantedLevelFromEnv({FLIGHTSTUDIO_AI_LEVEL: "3"}), 3);
    assert.equal(grantedLevelFromEnv({FLIGHTSTUDIO_AI_LEVEL: "0"}), 0);
    assert.equal(grantedLevelFromEnv({FLIGHTSTUDIO_AI_LEVEL: "9"}), 1);
    assert.equal(grantedLevelFromEnv({FLIGHTSTUDIO_AI_LEVEL: "junk"}), 1);
});
