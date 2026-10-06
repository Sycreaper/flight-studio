/// Structured logger for the Agent Gateway.
///
/// Format (one line per entry):
///   2026-10-05T14:30:16.123Z [INFO ] [provider-push] message…
///
/// Writes to `<FS_LOG_DIR>/gateway-yyyy-mm-dd.log` (FS_LOG_DIR is passed
/// by the Flutter app — `<app support>/logs`, the same directory that
/// holds the app's own `app-*.log`; the two files never mix). Falls back
/// to the OS temp dir when FS_LOG_DIR is unset (manual `npm run start:dev`
/// sessions). Every line is also echoed to stdout so `start:dev` consoles
/// and crash-capture redirections still see it.
import {appendFileSync, mkdirSync} from "node:fs";
import {tmpdir} from "node:os";
import {join} from "node:path";

export type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR";

function logDir(): string {
    return process.env.FS_LOG_DIR?.trim() || join(tmpdir(), "flightstudio-logs");
}

/// Local-calendar day (matches the Flutter app's app-<date>.log naming so
/// the two files for the same session share a suffix).
function localDay(): string {
    const now = new Date();
    const mm = String(now.getMonth() + 1).padStart(2, "0");
    const dd = String(now.getDate()).padStart(2, "0");
    return `${now.getFullYear()}-${mm}-${dd}`;
}

function linePrefix(level: LogLevel): string {
    const now = new Date();
    const day = now.toISOString().slice(0, 10);
    return `${now.toISOString()} [${level.padEnd(5)}]`;
}

function serialize(part: unknown): string {
    if (typeof part === "string") return part;
    try {
        return JSON.stringify(part);
    } catch {
        return String(part);
    }
}

function write(level: LogLevel, tag: string, parts: unknown[]): void {
    const line = `${linePrefix(level)} [${tag}] ${parts.map(serialize).join(" ")}`;
    console.log(line);
    try {
        const dir = logDir();
        mkdirSync(dir, {recursive: true});
        appendFileSync(join(dir, `gateway-${localDay()}.log`), `${line}\n`, "utf8");
    } catch {
        // File logging is best-effort; stdout above always worked.
    }
}

export const log = {
    debug: (tag: string, ...parts: unknown[]) => write("DEBUG", tag, parts),
    info: (tag: string, ...parts: unknown[]) => write("INFO", tag, parts),
    warn: (tag: string, ...parts: unknown[]) => write("WARN", tag, parts),
    error: (tag: string, ...parts: unknown[]) => write("ERROR", tag, parts),
};
