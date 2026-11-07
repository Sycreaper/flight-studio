/// Approval bridge — the three outcomes over the tool policy:
/// computer commands denied, skills silent, L1+ data reads recorded via
/// `approval_auto`, everything else through the manual card flow.
import assert from "node:assert/strict";
import {test} from "node:test";

import {ApprovalBridge, type ApprovalBridgeDeps} from "../src/approval_bridge.js";
import type {ApprovalPort} from "../src/approval_bridge.js";

class FakeDeps implements ApprovalBridgeDeps {
    level: number | null = 1;
    conversationId: string | null = null;
    port: ApprovalPort | null = null;
    readonly emitted: Array<Record<string, unknown>> = [];

    turnAiLevel(): number | null {
        return this.level;
    }

    activeConversationId(): string | null {
        return this.conversationId;
    }

    approvals(): ApprovalPort | null {
        return this.port;
    }

    emit(event: Record<string, unknown>): void {
        this.emitted.push(event);
    }
}

/// Approval port whose waitForResolution settles immediately.
function instantPort(approved: boolean): ApprovalPort {
    return {
        createApproval: (tool: string, _input: unknown) =>
            ({id: `approval_${tool}`}),
        waitForResolution: async () => approved,
    };
}

test("computer command tools are denied before any prompt", async () => {
    const deps = new FakeDeps();
    deps.port = instantPort(true);
    const bridge = new ApprovalBridge(deps);
    const result = await bridge.handleToolApproval("Bash", {cmd: "ls"});
    assert.equal(result.behavior, "deny");
    assert.deepEqual(deps.emitted, []);
});

test("other harness tools (Read, Edit, …) go through the manual card", async () => {
    const deps = new FakeDeps();
    deps.level = 1;
    deps.port = instantPort(true);
    const bridge = new ApprovalBridge(deps);
    const result = await bridge.handleToolApproval("Read", {path: "x.txt"});
    assert.equal(result.behavior, "allow");
    const types = deps.emitted.map((e) => e.type);
    assert.deepEqual(types, [
        "approval_request",
        "phase",
        "approval_resolved",
    ]);
});

test("skills run silently — no events at all", async () => {
    const deps = new FakeDeps();
    const bridge = new ApprovalBridge(deps);
    const result = await bridge.handleToolApproval("Skill", {name: "s"});
    assert.equal(result.behavior, "allow");
    assert.deepEqual(deps.emitted, []);
});

test("L1+ data reads emit an approval_auto record and run", async () => {
    const deps = new FakeDeps();
    deps.level = 1;
    deps.conversationId = "conv-1";
    const bridge = new ApprovalBridge(deps);
    const result = await bridge.handleToolApproval(
        "mcp__flightstudio-core__weather_read",
        {icao: "ZBAA"},
    );
    assert.equal(result.behavior, "allow");
    assert.equal(deps.emitted.length, 1);
    const event = deps.emitted[0];
    assert.equal(event.type, "approval_auto");
    assert.equal(event.tool, "mcp__flightstudio-core__weather_read");
    assert.deepEqual(event.input, {icao: "ZBAA"});
    assert.equal(event.conversationId, "conv-1");
    assert.match(event.id as string, /^auto_/);
});

test("L0 data reads go through the manual card flow", async () => {
    const deps = new FakeDeps();
    deps.level = 0;
    deps.port = instantPort(true);
    const bridge = new ApprovalBridge(deps);
    const result = await bridge.handleToolApproval("weather_read", {});
    assert.equal(result.behavior, "allow");
    const types = deps.emitted.map((e) => e.type);
    assert.deepEqual(types, [
        "approval_request",
        "phase",
        "approval_resolved",
    ]);
});

test("write tools require the manual card even at L3", async () => {
    const deps = new FakeDeps();
    deps.level = 3;
    deps.port = instantPort(false);
    const bridge = new ApprovalBridge(deps);
    const result = await bridge.handleToolApproval("send_sim_command", {});
    assert.equal(result.behavior, "deny");
    const types = deps.emitted.map((e) => e.type);
    assert.deepEqual(types, [
        "approval_request",
        "phase",
        "approval_resolved",
    ]);
});

test("manual confirmation fails closed without an approval controller", async () => {
    const deps = new FakeDeps();
    deps.level = 0;
    deps.port = null;
    const bridge = new ApprovalBridge(deps);
    const result = await bridge.handleToolApproval("get_airport_data", {});
    assert.equal(result.behavior, "deny");
    assert.match(result.message, /fail-closed/);
});
