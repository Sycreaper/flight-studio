/// Lifecycle of the local Letta Code app-server subprocess and the shared
/// app-server protocol client — split from letta_runtime.ts. If SDK
/// method names drift between versions, adjust this module alone; the
/// facade only sees startLocalAppServer / providerSocket / createClient.
///
/// Local backend layout (all official surfaces):
/// - The gateway owns one Letta Code app-server subprocess
///   (`letta server --listen ws://127.0.0.1:0`, URL parsed from stdout).
/// - Provider credentials are pushed through the official app-server
///   protocol (`connect_provider`), never by writing Letta's files.
/// - The Agent SDK client reuses the same server via `appServer.url`.

import {LettaAgentClient} from "@letta-ai/letta-agent-sdk";
import {type AppServerClient, createAppServerClient,} from "@letta-ai/letta-code/app-server-client";
import {type ChildProcess, spawn} from "node:child_process";
import {createRequire} from "node:module";

import {type Backend} from "./runtime_types.js";

const require = createRequire(import.meta.url);

const STARTUP_TIMEOUT_MS = 60_000;
const LISTENING_RE = /^Listening on\s+(ws:\/\/\S+)\s*$/m;

/// Callbacks the owner (LettaRuntime) provides so the launcher can
/// surface state changes exactly like the pre-split monolith did.
export interface LauncherHooks {
    /// Called when the subprocess URL was captured (spawn succeeded).
    onServerStarted(process: ChildProcess, url: string): void;
    /// Called when the app-server exited — the owner flips its status
    /// to error and clears its client.
    onServerExited(): void;
}

/** Spawns the Letta Code app-server and captures its websocket URL. */
export async function startLocalAppServer(
    hooks: LauncherHooks,
): Promise<void> {
    const cliPath =
        process.env.LETTA_CLI_PATH?.trim() ||
        require.resolve("@letta-ai/letta-code");
    await new Promise<void>((resolve, reject) => {
        const child = spawn(
            process.execPath,
            [cliPath, "server", "--listen", "ws://127.0.0.1:0"],
            {stdio: ["ignore", "pipe", "pipe"], env: process.env},
        );
        let output = "";
        const timeout = setTimeout(() => {
            finish(
                new Error(
                    `app-server startup timeout. Output:\n${output.trim()}`,
                ),
            );
        }, STARTUP_TIMEOUT_MS);
        const finish = (err: Error | null, url?: string) => {
            clearTimeout(timeout);
            child.stdout?.off("data", onStdout);
            child.stderr?.off("data", onStderr);
            child.off("error", onError);
            child.off("exit", onExit);
            if (err) {
                if (child.exitCode === null) child.kill();
                reject(err);
                return;
            }
            hooks.onServerStarted(child, url!);
            // Keep draining so the pipe never fills; surface crashes.
            child.stdout?.on("data", () => {
            });
            child.stderr?.on("data", () => {
            });
            child.once("exit", () => {
                hooks.onServerExited();
            });
            resolve();
        };
        const collect = (chunk: Buffer | string) => {
            output += String(chunk);
            const match = output.match(LISTENING_RE);
            if (match?.[1]) finish(null, match[1]);
        };
        const onStdout = (chunk: Buffer | string) => collect(chunk);
        const onStderr = (chunk: Buffer | string) => collect(chunk);
        const onError = (err: Error) => finish(err);
        const onExit = (code: number | null) =>
            finish(new Error(`app-server exited early (code ${code})`));
        child.stdout?.on("data", onStdout);
        child.stderr?.on("data", onStderr);
        child.once("error", onError);
        child.once("exit", onExit);
    });
}

/// Owns the ONE shared app-server protocol client (provider commands).
/// Reconnects lazily after a disconnect.
export class AppServerSocket {
    private client: AppServerClient | null = null;
    private url: string | null = null;

    /** Remembers the subprocess URL (called on spawn success). */
    setUrl(url: string): void {
        this.url = url;
    }

    /// One shared app-server protocol client for provider commands.
    async get(): Promise<AppServerClient> {
        if (this.client) return this.client;
        if (this.url == null) {
            throw new Error("local app-server not running");
        }
        const client = createAppServerClient({url: this.url});
        await client.connect();
        this.client = client;
        client.onDisconnect(() => {
            if (this.client === client) this.client = null;
        });
        return client;
    }
}

/// Creates the SDK client for the configured backend:
/// - local: reuses the owned app-server URL;
/// - cloud: LETTA_API_KEY;
/// - remote: LETTA_REMOTE_URL (+ optional LETTA_REMOTE_TOKEN).
export function createLettaClient(
    backend: Backend,
    serverUrl: string | null,
): LettaAgentClient {
    switch (backend) {
        case "cloud": {
            const apiKey = process.env.LETTA_API_KEY;
            return new LettaAgentClient({
                backend: "cloud",
                ...(apiKey ? {apiKey} : {}),
            });
        }
        case "remote": {
            const url = process.env.LETTA_REMOTE_URL;
            if (!url)
                throw new Error("LETTA_REMOTE_URL is required for remote backend");
            const authToken = process.env.LETTA_REMOTE_TOKEN;
            return new LettaAgentClient({
                backend: "remote",
                url,
                ...(authToken ? {authToken} : {}),
            });
        }
        case "local":
        default:
            return new LettaAgentClient({
                backend: "local",
                appServer: {url: serverUrl!},
            });
    }
}
