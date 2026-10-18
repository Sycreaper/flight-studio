/// LettaRuntime pure/static surface — loop-status → UI phase mapping and
/// the FlightStudio Core MCP server wiring.
/// (The instance surface needs a live Letta backend and is covered by the
/// end-to-end smoke tests, not CI.)
import assert from "node:assert/strict";
import {test} from "node:test";

import {LettaRuntime} from "../src/letta_runtime.js";

const runtime = new LettaRuntime();

test("model-related loop statuses map to thinking", () => {
    for (const s of [
        "WAITING_FOR_API_RESPONSE",
        "PROCESSING_API_RESPONSE",
        "LLM_THINKING",
    ]) {
        assert.equal(LettaRuntime.phaseFromLoopStatus(s), "thinking", s);
    }
});

test("tool/search/read/write statuses map to their phases", () => {
    assert.equal(LettaRuntime.phaseFromLoopStatus("SEARCHING_MEMORY"), "searching");
    assert.equal(LettaRuntime.phaseFromLoopStatus("RETRIEVING_CONTEXT"), "searching");
    assert.equal(LettaRuntime.phaseFromLoopStatus("READING_FILES"), "reading");
    assert.equal(LettaRuntime.phaseFromLoopStatus("WRITING_FILES"), "writing");
    assert.equal(LettaRuntime.phaseFromLoopStatus("EXECUTING_TOOL"), "tool");
    assert.equal(LettaRuntime.phaseFromLoopStatus("RUNNING_COMMAND"), "tool");
    assert.equal(LettaRuntime.phaseFromLoopStatus("WAITING_FOR_APPROVAL"), "waitingApproval");
});

test("unknown statuses fall back to working", () => {
    assert.equal(LettaRuntime.phaseFromLoopStatus(""), "working");
    assert.equal(LettaRuntime.phaseFromLoopStatus("SOMETHING_NEW"), "working");
});

test("buildMcpServers mounts flightstudio-core when the project root is known", () => {
    process.env.FLIGHTSTUDIO_PROJECT_ROOT = "D:/proj";
    process.env.FLIGHTSTUDIO_NAVDATA_DB = "D:/data/navdata.sqlite";
    try {
        const servers = runtime.buildMcpServers();
        assert.ok(servers != null);
        const core = servers!["flightstudio-core"];
        assert.equal(core.type, "stdio");
        assert.equal(core.cwd, "D:/proj");
        assert.equal(core.args[0], "run");
        assert.match(
            core.args[1] ?? "",
            /mcp_flightstudio_core\.dart$/,
        );
        assert.equal(core.env.FLIGHTSTUDIO_NAVDATA_DB, "D:/data/navdata.sqlite");
    } finally {
        delete process.env.FLIGHTSTUDIO_PROJECT_ROOT;
        delete process.env.FLIGHTSTUDIO_NAVDATA_DB;
    }
});

test("buildMcpServers is undefined without a project root", () => {
    delete process.env.FLIGHTSTUDIO_PROJECT_ROOT;
    assert.equal(runtime.buildMcpServers(), undefined);
});
