/// FlightStudio tool registry — metadata contract only (the tool bodies
/// call external APIs and are covered by live smoke tests, not CI).
import assert from "node:assert/strict";
import {test} from "node:test";

import {flightStudioTools} from "../src/mcp_registry.js";
import {evaluateToolCall} from "../src/safety_policy_guard.js";

test("every registered tool declares name, description, icao parameter", () => {
    assert.ok(flightStudioTools.length >= 2);
    for (const tool of flightStudioTools) {
        assert.ok(tool.name.length > 0);
        assert.ok(tool.description.length > 0);
        assert.ok("icao" in tool.parameters, tool.name);
        assert.equal(typeof tool.execute, "function");
    }
});

test("every FlightStudio tool is registered with the safety policy", () => {
    for (const tool of flightStudioTools) {
        const decision = evaluateToolCall(tool.name);
        assert.equal(
            decision.level,
            "L0",
            `${tool.name} must be an L0 read-only tool`,
        );
        assert.equal(decision.allowed, true, tool.name);
    }
});
