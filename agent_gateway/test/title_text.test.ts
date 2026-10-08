/// Title-text helpers — pure logic, mirrors the real-world fragments seen
/// from GLM-class reasoning models and the local Letta backend.
import assert from "node:assert/strict";
import {test} from "node:test";

import {
    cleanTitleText,
    clipText,
    looksAutoSummary,
    stripThinking,
} from "../src/title_text.js";

test("stripThinking removes closed think blocks", () => {
    const raw =
        "<think>The user asked about simulation. I need a title.</think>模拟飞行入门";
    assert.equal(stripThinking(raw), "模拟飞行入门");
});

test("stripThinking removes unclosed think blocks (truncated stream)", () => {
    assert.equal(stripThinking("<think>unclosed thinking cut off"), "");
});

test("stripThinking removes multiple and thinking-variant tags", () => {
    assert.equal(
        stripThinking("<think>a</think><thinking>b</thinking>入门指南"),
        "入门指南",
    );
});

test("stripThinking removes harness wrapper tags", () => {
    const raw =
        '<system-reminder>housekeeping</system-reminder>标题';
    assert.equal(stripThinking(raw), "标题");
});

test("cleanTitleText strips quotes and keeps only the first line", () => {
    assert.equal(cleanTitleText('"模拟飞行基础知识"'), "模拟飞行基础知识");
    assert.equal(cleanTitleText("模拟飞行入门\nextra line"), "模拟飞行入门");
    assert.equal(cleanTitleText("  \n  "), "");
});

test("cleanTitleText handles think-block + wrapper + quotes together", () => {
    const raw =
        "<think>x</think>\n\n\"飞行基础\"";
    assert.equal(cleanTitleText(raw), "飞行基础");
});

test("looksAutoSummary flags think fragments and long transcripts", () => {
    assert.ok(looksAutoSummary("<think>The user asked…"));
    assert.ok(looksAutoSummary("fine title</think>"));
    assert.ok(looksAutoSummary("<system-reminder>…"));
    assert.ok(looksAutoSummary("multi\nline"));
    assert.ok(looksAutoSummary("x".repeat(41)));
    assert.ok(!looksAutoSummary("模拟飞行入门"));
    assert.ok(!looksAutoSummary("A 40-character title exactly. Padding…"));
});

test("clipText ellipsizes beyond the limit and passes short text", () => {
    assert.equal(clipText("abc", 5), "abc");
    assert.equal(clipText("abcdef", 5), "abcde…");
});
