/// FlightStudio Core MCP server mounting — split from letta_runtime.ts.
/// Session-scoped MCP servers for resumeSession; pure environment
/// mapping, unit-tested in letta_runtime.test.ts.

export interface McpServerSpec {
    type: "stdio";
    command: string;
    args: string[];
    env: Record<string, string>;
    cwd: string;
}

/** Builds the FlightStudio Core MCP server config for resumeSession.
 *  The app's Dart stdio server (`dart run
 *  bin/mcp_flightstudio_core.dart`) exposes the L0–L3-gated
 *  FlightStudio toolset (airport dossier, charts, weather) with
 *  per-call audit logging. Returns undefined when the project root is
 *  unknown (release layout) — the agent then runs tool-less. */
export function buildMcpServers():
    | Record<string, McpServerSpec>
    | undefined {
    const cwd = process.env.FLIGHTSTUDIO_PROJECT_ROOT?.trim();
    if (!cwd) return undefined;
    const command =
        process.env.FLIGHTSTUDIO_DART_CMD?.trim() || "dart";
    const env: Record<string, string> = {};
    const db = process.env.FLIGHTSTUDIO_NAVDATA_DB?.trim();
    if (db) env.FLIGHTSTUDIO_NAVDATA_DB = db;
    return {
        "flightstudio-core": {
            type: "stdio",
            command,
            args: ["run", "bin/mcp_flightstudio_core.dart"],
            env,
            cwd,
        },
    };
}
