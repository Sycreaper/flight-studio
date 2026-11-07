/// Tool policy v4 — classification (skill / MCP read / MCP write /
/// computer command), level behaviour, env parsing, MCP-qualified name
/// matching.
import assert from "node:assert/strict";
import {test} from "node:test";

import {
    DEFAULT_GRANTED_LEVEL,
    evaluateToolCall,
    grantedLevelFromEnv,
} from "../src/safety_policy_guard.js";

const ALL_LEVELS = [0, 1, 2, 3] as const;

test("skills are silently allowed at every level (no card, no record)", () => {
    for (const granted of ALL_LEVELS) {
        const d = evaluateToolCall("Skill", granted);
        assert.equal(d.allowed, true);
        assert.equal(d.silent, true);
        assert.equal(d.autoAllowed, false);
        assert.equal(d.requiresApproval, false);
    }
});

test("L0 asks for EVERY MCP request (manual confirmation)", () => {
    const read = evaluateToolCall("get_airport_data", 0);
    assert.equal(read.allowed, true);
    assert.equal(read.requiresApproval, true);
    assert.equal(read.autoAllowed, false);

    const write = evaluateToolCall("send_sim_command", 0);
    assert.equal(write.allowed, true);
    assert.equal(write.requiresApproval, true);
    assert.equal(write.autoAllowed, false);
});

test("L1+ auto-allows every data read (app + simulator data)", () => {
    const reads = [
        "get_airport_data",
        "charts_read",
        "weather_read",
        "search_navdata",
        "search_manual",
        "get_sim_state",
        "propose_action_plan",
        "render_map",
    ];
    for (const tool of reads) {
        for (const granted of [1, 2, 3] as const) {
            const d = evaluateToolCall(tool, granted);
            assert.equal(d.allowed, true, tool);
            assert.equal(d.autoAllowed, true, `${tool}@L${granted}`);
            assert.equal(d.requiresApproval, false, `${tool}@L${granted}`);
        }
    }
});

test("MCP-qualified names match by suffix", () => {
    const d = evaluateToolCall("mcp__flightstudio-core__get_airport_data", 1);
    assert.equal(d.allowed, true);
    assert.equal(d.autoAllowed, true);
    const qualifiedWrite = evaluateToolCall(
        "mcp__flightstudio-core__send_sim_command",
        3,
    );
    assert.equal(qualifiedWrite.allowed, true);
    assert.equal(qualifiedWrite.requiresApproval, true);
});

test("write tools need the manual card at every level — never auto-run", () => {
    for (const tool of ["send_sim_command", "set_com_frequency"]) {
        for (const granted of ALL_LEVELS) {
            const d = evaluateToolCall(tool, granted);
            assert.equal(d.allowed, true, `${tool}@L${granted}`);
            assert.equal(d.requiresApproval, true, `${tool}@L${granted}`);
            assert.equal(d.autoAllowed, false, `${tool}@L${granted}`);
        }
    }
});

test("bash-style commands are denied at every level, without a record", () => {
    for (const tool of ["Bash", "exec_command", "write_stdin"]) {
        for (const granted of ALL_LEVELS) {
            const d = evaluateToolCall(tool, granted);
            assert.equal(d.allowed, false, `${tool}@L${granted}`);
            assert.equal(d.requiresApproval, false, `${tool}@L${granted}`);
            assert.equal(d.silent, false, `${tool}@L${granted}`);
        }
    }
});

test("other harness tools (Read, Edit, Task, …) ask for manual approval at every level", () => {
    for (const tool of ["Read", "Edit", "Write", "Task", "mystery_tool"]) {
        for (const granted of ALL_LEVELS) {
            const d = evaluateToolCall(tool, granted);
            assert.equal(d.allowed, true, `${tool}@L${granted}`);
            assert.equal(d.requiresApproval, true, `${tool}@L${granted}`);
            assert.equal(d.autoAllowed, false, `${tool}@L${granted}`);
        }
    }
});

test("unregistered MCP tools surface for MANUAL approval", () => {
    for (const granted of ALL_LEVELS) {
        const d = evaluateToolCall("mcp__other-server__custom_tool", granted);
        assert.equal(d.allowed, true);
        assert.equal(d.requiresApproval, true);
        assert.equal(d.autoAllowed, false);
    }
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
