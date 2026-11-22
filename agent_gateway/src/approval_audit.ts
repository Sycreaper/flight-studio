/// Approval audit trail — the append-only JSONL log of every tool-permission
/// decision the gateway settles, on behalf of a user or by policy.
///
/// Rationale: Letta's local backend provably persists NO approval records
/// (its conversation store holds only session/message entries; verified
/// against ~/.letta/lc-local-backend and the official history API), so this
/// file is the single source of truth for "who allowed what, when, in which
/// conversation". One JSON object per line, newest appended last:
///
/// {"ts":"…Z","conversationId":"local-conv-1","tool":"get_airport_data",
///  "input":{"icao":"ZSPD"},"outcome":"approved","grantedLevel":1,
///  "reason":"approved by user","turnExcerpt":"ZSPD 的天气？"}
///
/// Lives next to the gateway logs (`FS_LOG_DIR/approval-audit.jsonl`).
import {appendFile, readFile} from "node:fs/promises";
import {existsSync} from "node:fs";
import {tmpdir} from "node:os";
import {join} from "node:path";

import {log} from "./logger.js";

export type ApprovalOutcome =
    | "approved" // user pressed Allow on the manual card
    | "denied" // user pressed Deny on the manual card
    | "denied-timeout" // nobody answered the card within 300 s
    | "auto-allowed" // L1+ registered data read (record card, no prompt)
    | "policy-denied" // safety ladder refused (bash, level cap, …)
    | "silent-allowed" // skill usage — always allowed, never prompted
    | "fail-closed"; // no approval controller wired → denied

export interface ApprovalAuditRecord {
    ts: string;
    conversationId: string | null;
    tool: string;
    input: unknown;
    outcome: ApprovalOutcome;
    grantedLevel: number;
    reason: string;
    /// Excerpt of the user text that triggered the turn (context anchor —
    /// enough to find the exchange in the official conversation history).
    turnExcerpt: string | null;
}

/// Input objects larger than this are truncated to a placeholder.
const MAX_INPUT_JSON = 2048;
/// Excerpt cap for the turn text.
const MAX_EXCERPT = 200;

function auditPath(): string {
    const dir =
        process.env.FS_LOG_DIR?.trim() ||
        join(tmpdir(), "flightstudio-logs");
    return join(dir, "approval-audit.jsonl");
}

/// Appends one decision. Best-effort: a failing audit write is logged and
/// swallowed — it must never break the tool call it is auditing.
export async function appendApprovalAudit(
    record: Omit<ApprovalAuditRecord, "ts">,
): Promise<void> {
    try {
        const inputJson = JSON.stringify(record.input ?? {});
        const entry: ApprovalAuditRecord = {
            ...record,
            ts: new Date().toISOString(),
            input: inputJson.length > MAX_INPUT_JSON
                ? {truncated: inputJson.slice(0, MAX_INPUT_JSON)}
                : record.input,
            turnExcerpt: record.turnExcerpt == null
                ? null
                : (record.turnExcerpt.length > MAX_EXCERPT
                    ? `${record.turnExcerpt.slice(0, MAX_EXCERPT)}…`
                    : record.turnExcerpt),
        };
        await appendFile(auditPath(), `${JSON.stringify(entry)}\n`, "utf8");
    } catch (err) {
        log.warn(
            "approval-audit",
            "write failed:",
            err instanceof Error ? err.message : String(err),
        );
    }
}

/// Reads the audit trail, newest first, optionally scoped to one
/// conversation. Malformed lines are skipped. Null when no audit file
/// exists yet (no permission decision has been settled).
export async function readApprovalAudit({
    conversationId,
    limit = 500,
}: {
    conversationId?: string;
    limit?: number;
} = {}): Promise<ApprovalAuditRecord[] | null> {
    const path = auditPath();
    if (!existsSync(path)) return null;
    try {
        const text = await readFile(path, "utf8");
        const lines = text.split("\n");
        const out: ApprovalAuditRecord[] = [];
        for (let i = lines.length - 1; i >= 0 && out.length < limit; i--) {
            const line = lines[i].trim();
            if (line.length === 0) continue;
            try {
                const entry = JSON.parse(line) as ApprovalAuditRecord;
                if (
                    conversationId != null &&
                    entry.conversationId !== conversationId
                ) {
                    continue;
                }
                out.push(entry);
            } catch {
                // Torn tail line (concurrent append) — skip.
            }
        }
        return out;
    } catch (err) {
        log.warn(
            "approval-audit",
            "read failed:",
            err instanceof Error ? err.message : String(err),
        );
        return null;
    }
}
