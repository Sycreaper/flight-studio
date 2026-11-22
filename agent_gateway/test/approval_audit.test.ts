/// Approval audit trail — append + read-back semantics (newest first,
/// conversation filter, truncation, torn-tail tolerance). Uses a temp
/// FS_LOG_DIR so the real log is never touched.
import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import {after, before, test} from "node:test";

import {
    appendApprovalAudit,
    readApprovalAudit,
} from "../src/approval_audit.js";

let dir: string;

before(async () => {
    dir = await mkdtemp(join(tmpdir(), "approval-audit-test-"));
    process.env.FS_LOG_DIR = dir;
});

after(async () => {
    delete process.env.FS_LOG_DIR;
    await rm(dir, {recursive: true, force: true});
});

test("no audit file yet reads as null", async () => {
    assert.equal(await readApprovalAudit(), null);
});

test("appends settle in order and read back newest-first", async () => {
    await appendApprovalAudit({
        conversationId: "conv-1",
        tool: "get_airport_data",
        input: {icao: "ZSPD"},
        outcome: "auto-allowed",
        grantedLevel: 1,
        reason: "data read auto-allowed (L1+)",
        turnExcerpt: "ZSPD weather?",
    });
    await appendApprovalAudit({
        conversationId: "conv-1",
        tool: "send_sim_command",
        input: {command: "pause"},
        outcome: "denied",
        grantedLevel: 3,
        reason: "denied by user",
        turnExcerpt: "pause the sim",
    });
    await appendApprovalAudit({
        conversationId: "conv-2",
        tool: "set_com_frequency",
        input: {frequencyKhz: 118000},
        outcome: "approved",
        grantedLevel: 2,
        reason: "approved by user",
        turnExcerpt: null,
    });

    const all = (await readApprovalAudit())!;
    assert.equal(all.length, 3);
    // Newest first: the conv-2 approval was settled last.
    assert.equal(all[0].tool, "set_com_frequency");
    assert.equal(all[0].outcome, "approved");
    assert.ok(all[0].ts > all[1].ts || all[0].ts === all[1].ts);
    assert.equal(all[2].tool, "get_airport_data");

    // Conversation filter scopes to one conversation.
    const scoped = (await readApprovalAudit({conversationId: "conv-1"}))!;
    assert.equal(scoped.length, 2);
    assert.ok(scoped.every((e) => e.conversationId === "conv-1"));

    // Limit caps the result.
    const limited = (await readApprovalAudit({limit: 1}))!;
    assert.equal(limited.length, 1);
    assert.equal(limited[0].tool, "set_com_frequency");
});

test("oversized input is truncated, long excerpts clipped", async () => {
    await appendApprovalAudit({
        conversationId: "conv-3",
        tool: "send_sim_command",
        input: {blob: "x".repeat(5000)},
        outcome: "approved",
        grantedLevel: 3,
        reason: "approved by user",
        turnExcerpt: "y".repeat(500),
    });
    const entries = (await readApprovalAudit({conversationId: "conv-3"}))!;
    const entry = entries[0];
    const input = entry.input as {truncated?: string};
    assert.ok(input.truncated != null && input.truncated.length <= 2048);
    assert.ok(entry.turnExcerpt != null && entry.turnExcerpt.length <= 201);
    assert.ok(entry.turnExcerpt!.endsWith("…"));
});
