/// LettaRuntime pure/static surface — loop-status → UI phase mapping.
/// (The instance surface needs a live Letta backend and is covered by the
/// end-to-end smoke tests, not CI.)
import assert from "node:assert/strict";
import {test} from "node:test";

import {LettaRuntime} from "../src/letta_runtime.js";

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
