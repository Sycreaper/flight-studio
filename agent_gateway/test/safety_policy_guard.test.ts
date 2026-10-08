/// Safety-policy ladder — every level's allow/approval decision.
import assert from "node:assert/strict";
import {test} from "node:test";

import {evaluateToolCall} from "../src/safety_policy_guard.js";

test("L0 read-only tools run without approval", () => {
    for (const tool of ["charts_read", "weather_read", "search_navdata", "search_manual"]) {
        const d = evaluateToolCall(tool);
        assert.equal(d.allowed, true, tool);
        assert.equal(d.requiresApproval, false, tool);
        assert.equal(d.level, "L0", tool);
    }
});

test("L1 observe and L2 suggest run without approval", () => {
    const l1 = evaluateToolCall("get_sim_state");
    assert.equal(l1.allowed, true);
    assert.equal(l1.requiresApproval, false);
    assert.equal(l1.level, "L1");

    const l2 = evaluateToolCall("propose_action_plan");
    assert.equal(l2.allowed, true);
    assert.equal(l2.requiresApproval, false);
    assert.equal(l2.level, "L2");
});

test("L3 sim actions require explicit user confirmation", () => {
    const d = evaluateToolCall("set_com_frequency");
    assert.equal(d.allowed, true);
    assert.equal(d.requiresApproval, true);
    assert.equal(d.level, "L3");
});

test("unregistered tools are BLOCKED", () => {
    const d = evaluateToolCall("rm_rf_everything");
    assert.equal(d.allowed, false);
    assert.equal(d.level, "BLOCKED");
    assert.match(d.reason, /not registered/);
});
