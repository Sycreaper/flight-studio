/// Provider push (BYOK) — split from letta_runtime.ts. Resolves the
/// catalog handle for a requested model id and executes the official
/// `connect_provider` protocol command through the app-server socket.
/// Pure-ish logic (catalog matching) is kept here because it is
/// string-shaped, versioned and bug-prone — the nine-bug BYOK postmortem
/// (docs/maintainers/byok-debugging.md) lives in this code path.

import {type AppServerClient} from "@letta-ai/letta-code/app-server-client";

import {log} from "./logger.js";

/** Force-refreshes the runtime model catalog via the raw protocol (the
 *  SDK's ModelsClient may serve a stale within-TTL snapshot). */
export async function forceCatalog(
    providerSocket: () => Promise<AppServerClient>,
): Promise<{
    entries?: Array<Record<string, unknown>>;
    byokProviderAliases?: Record<string, string>;
} | null> {
    try {
        const socket = await providerSocket();
        const response = await socket.request("list_models", {
            request_id: socket.nextRequestId("models"),
            force: true,
        });
        return response as unknown as {
            entries?: Array<Record<string, unknown>>;
            byokProviderAliases?: Record<string, string>;
        };
    } catch {
        return null;
    }
}

/**
 * Finds the catalog handle for [model] under the connected OpenAI-
 * compatible provider. Discovery order:
 * 1. exact handle from the force-refreshed runtime catalog (this also
 *    triggers `localModelDiscovery`, which queries {baseUrl}/models so
 *    custom endpoints list their models);
 * 2. `openai-compatible/<model>` — the base prefix; the connected row
 *    is stored under this name, and custom models are always allowed;
 * 3. `lc-openai-compatible/<model>` — the BYOK alias (DO NOT prefer:
 *    its prefix collides with `lc-openai` in some resolver versions
 *    and misroutes to the openai provider).
 */
export async function resolveByokHandle(
    providerSocket: () => Promise<AppServerClient>,
    model: string,
): Promise<string> {
    const prefixes = ["openai-compatible", "lc-openai-compatible"];
    const catalog = await forceCatalog(providerSocket);
    if (catalog) {
        const entries = catalog.entries ?? [];
        const aliases = Object.keys(catalog.byokProviderAliases ?? {});
        const known = new Set([...prefixes, ...aliases]);
        // What did discovery actually publish under this provider?
        const discovered: string[] = [];
        for (const entry of entries) {
            const handle =
                (entry.handle as string | undefined) ??
                (entry.id as string | undefined) ?? "";
            for (const prefix of known) {
                if (handle.startsWith(`${prefix}/`)) {
                    discovered.push(handle);
                    break;
                }
            }
        }
        log.info(
            "provider-push", "discovered openai-compatible models:",
            JSON.stringify(discovered.slice(0, 30)),
        );
        const wanted = `${prefixes[0]}/${model}`;
        // Exact match first.
        const exact = discovered.find(
            (h) => h.toLowerCase() === wanted.toLowerCase(),
        );
        if (exact) return exact;
        // Model-id match on any prefix (e.g. lc-openai-compatible/<id>).
        const byId = entries
            .map(
                (e) =>
                    (e.handle as string | undefined) ??
                    (e.id as string | undefined) ??
                    "",
            )
            .find(
                (h) =>
                    h.includes("/") &&
                    h.split("/").slice(1).join("/").toLowerCase() ===
                    model.toLowerCase(),
            );
        if (byId) return byId;
        // Prefix-contains fallback (provider suffixes like -250414).
        const fuzzy = discovered.find((h) =>
            h.toLowerCase().includes(`/${model.toLowerCase()}`),
        );
        if (fuzzy) {
            log.info("provider-push", "fuzzy-matched:", fuzzy);
            return fuzzy;
        }
        // The catalog may have renamed/dropped the exact variant
        // (e.g. glm-4.7-flash → glm-4.7): match the discovered model
        // whose id is the longest prefix of the requested one.
        const wantedLower = model.toLowerCase();
        let best: string | null = null;
        for (const h of discovered) {
            const id = h.split("/").slice(1).join("/").toLowerCase();
            if (id && (wantedLower.startsWith(id) || id.startsWith(wantedLower))) {
                if (best == null || id.length > best.split("/").slice(1).join("/").length) {
                    best = h;
                }
            }
        }
        if (best) {
            log.info(
                "provider-push", "prefix-matched:",
                best,
                "(requested:",
                model + ")",
            );
            return best;
        }
    }
    return `${prefixes[0]}/${model}`;
}

/// Runs the official `connect_provider` command. Route through the
/// local LLM proxy when the real base URL breaks the /v1 convention the
/// harness enforces (bigmodel /v4, any custom path); proxy URLs end in
/// /v1 → used verbatim by the harness.
export async function connectProvider(
    providerSocket: () => Promise<AppServerClient>,
    input: {
        apiKey: string;
        baseUrl: string;
        proxyRegister?: (target: {
            baseUrl: string;
            apiKey: string;
        }) => string;
        providerName?: string;
    },
): Promise<string> {
    const diag = (...parts: unknown[]) => log.info("provider-push", ...parts);
    diag("start: baseUrl=", input.baseUrl.replace(/\/\/[^/]*@/, "//***@"),
        "model=", "(from caller)",
        "keyLen=", input.apiKey.trim().length);

    const socket = await providerSocket();
    diag("app-server socket connected");

    // Route the provider through the local proxy when its real base URL
    // breaks the /v1 convention the harness enforces (bigmodel /v4, any
    // custom path). Proxy URLs end in /v1 → used verbatim by the harness.
    let rowBaseUrl = input.baseUrl.trim().replace(/\/+$/, "");
    if (!rowBaseUrl.endsWith("/v1")) {
        if (input.proxyRegister == null) {
            throw new Error("LLM proxy unavailable on this gateway");
        }
        rowBaseUrl = input.proxyRegister({
            baseUrl: input.baseUrl.trim().replace(/\/+$/, ""),
            apiKey: input.apiKey.trim(),
        });
        diag("routed via proxy:", rowBaseUrl);
    }

    const response = await socket.request("connect_provider", {
        request_id: socket.nextRequestId("connect-provider"),
        target: "local",
        provider_id: "openai-compatible",
        fields: {
            apiKey: input.apiKey.trim(),
            baseUrl: rowBaseUrl,
        },
    });
    const result = response as unknown as {
        success?: boolean;
        error?: string;
    };
    diag("connect_provider success=", result.success, "error=", result.error);
    if (!result.success) {
        throw new Error(result.error ?? "connect_provider failed");
    }
    return rowBaseUrl;
}

/** Official provider listing — used for the configured flag. */
export async function listConnectProviders(
    providerSocket: () => Promise<AppServerClient>,
): Promise<Array<Record<string, unknown>>> {
    try {
        const socket = await providerSocket();
        const response = await socket.request("list_connect_providers", {
            request_id: socket.nextRequestId("list-providers"),
            target: "local",
        });
        const providers = (response as unknown as { providers?: unknown })
            .providers;
        return Array.isArray(providers)
            ? (providers as Array<Record<string, unknown>>)
            : [];
    } catch {
        return [];
    }
}
