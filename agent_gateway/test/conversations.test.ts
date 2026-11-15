/// History parsing — pure logic over the raw shapes the official Letta
/// history returns (see @letta-ai/letta-client Message types): text turns
/// with wrapper stripping, tool-call restoration in three representations,
/// approval-outcome joining by tool_call_id.
import assert from "node:assert/strict";
import {test} from "node:test";

import {parseHistoryMessages} from "../src/conversations.js";

test("text turns pass through with harness wrappers stripped", () => {
    const out = parseHistoryMessages([
        {role: "user", content: "ZSPD 的天气？"},
        {
            role: "assistant",
            content: [
                {type: "text", text: "<system-reminder>x</system-reminder>METAR…"},
            ],
        },
    ]);
    assert.deepEqual(out, [
        {role: "user", content: "ZSPD 的天气？"},
        {role: "assistant", content: "METAR…"},
    ]);
});

test("assistant tool_calls (OpenAI shape) restore after the text", () => {
    const out = parseHistoryMessages([
        {
            role: "assistant",
            content: [{type: "text", text: "查一下"}],
            tool_calls: [
                {
                    id: "call-1",
                    type: "function",
                    function: {name: "get_airport_data", arguments: "{\"icao\":\"ZSPD\"}"},
                },
            ],
        },
    ]);
    assert.deepEqual(out, [
        {role: "assistant", content: "查一下"},
        {role: "tool_call", tool: "get_airport_data", input: {icao: "ZSPD"}},
    ]);
});

test("dedicated tool_call record and ToolCall-shape tool_calls parse", () => {
    const out = parseHistoryMessages([
        {
            message_type: "tool_call_message",
            tool_call: {name: "weather_read", arguments: "{\"icao\":\"ZBAA\"}", tool_call_id: "call-2"},
        },
        {
            message_type: "tool_call_message",
            tool_calls: [{name: "charts_read", arguments: "{\"icao\":\"ZGGG\"}", tool_call_id: "call-3"}],
        },
    ]);
    assert.equal(out.length, 2);
    assert.equal(out[0].role, "tool_call");
    assert.equal(out[0].tool, "weather_read");
    assert.deepEqual(out[0].input, {icao: "ZBAA"});
    assert.equal(out[1].tool, "charts_read");
});

test("parsed tool_call content items restore with their object input", () => {
    const out = parseHistoryMessages([
        {
            role: "assistant",
            content: [
                {type: "tool_call", id: "call-4", name: "search_navdata", input: {query: "ILS ZSPD"}},
            ],
        },
    ]);
    assert.deepEqual(out, [
        {role: "tool_call", tool: "search_navdata", input: {query: "ILS ZSPD"}},
    ]);
});

test("approval rows themselves contribute nothing (no outcome restore)", () => {
    const out = parseHistoryMessages([
        {
            role: "approval",
            approvals: [
                {approve: true, tool_call_id: "call-a"},
                {approve: false, tool_call_id: "call-b", reason: "not now"},
            ],
        },
        {
            role: "assistant",
            tool_calls: [
                {id: "call-a", function: {name: "set_com_frequency", arguments: '{"frequency_khz":118000}'}},
            ],
        },
    ]);
    // Only the tool call restores — approval records carry no card data.
    assert.deepEqual(out, [
        {
            role: "tool_call",
            tool: "set_com_frequency",
            input: {frequency_khz: 118000},
        },
    ]);
});

test("tool-result rows and malformed arguments degrade gracefully", () => {
    const out = parseHistoryMessages([
        {role: "tool", tool_call_id: "call-1", content: [{type: "tool_return", content: "…"}]},
        {
            role: "assistant",
            tool_calls: [
                {id: "call-5", function: {name: "send_sim_command", arguments: "not-json{"}},
            ],
        },
    ]);
    assert.equal(out.length, 1);
    assert.deepEqual(out[0].input, {});
});

test("duplicate representations of one call collapse", () => {
    const out = parseHistoryMessages([
        {
            role: "assistant",
            tool_calls: [
                {id: "call-6", function: {name: "get_airport_data", arguments: '{"icao":"ZSPD"}'}},
            ],
            content: [
                {type: "tool_call", id: "call-6", name: "get_airport_data", input: {icao: "ZSPD"}},
            ],
        },
    ]);
    assert.equal(out.filter((e) => e.role === "tool_call").length, 1);
});
