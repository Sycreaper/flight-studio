/// Conversation management — split from letta_runtime.ts. Talks to the
/// official Letta API through the SDK client the owner provides, plus
/// the raw `conversation_messages_list` protocol for history. Owns the
/// title self-healing (the local backend's auto-summary overwrites the
/// official `summary` field with the assistant's first line at
/// unpredictable times).

import {type LettaAgentClient} from "@letta-ai/letta-agent-sdk";
import {type AppServerClient} from "@letta-ai/letta-code/app-server-client";

import {log} from "./logger.js";
import {cleanTitleText, clipText, looksAutoSummary} from "./title_text.js";
import {stripInjectedWrappers} from "./turn_stream.js";

export interface ConversationRow {
    id: string;
    title: string | null;
    lastMessageAt: string | null;
}

export interface HistoryMessage {
    role: "user" | "assistant";
    content: string;
}

/// State the conversation logic needs from its owner (LettaRuntime):
/// the SDK client, the app-server socket factory, and the event sink.
export interface ConversationDeps {
    client(): LettaAgentClient | null;
    agentId(): string | null;
    providerSocket(): Promise<AppServerClient>;
    emit(event: Record<string, unknown>): void;
}

export class Conversations {
    /// Title this gateway wrote per conversation id. Guards against the
    /// local backend's OWN auto-summary (which parrots the assistant's
    /// first line and may land at ANY time — even after our write, e.g.
    /// when the next resumeSession bootstraps): every turn re-verifies
    /// and restores our title when it was overwritten.
    private readonly titledConversations = new Map<string, string>();

    constructor(private readonly deps: ConversationDeps) {}

    /// Remembers OUR title for a conversation (idempotent).
    rememberTitle(conversationId: string, title: string): void {
        this.titledConversations.set(conversationId, title);
    }

    /// The title we wrote for [conversationId], when any.
    knownTitle(conversationId: string): string | undefined {
        return this.titledConversations.get(conversationId);
    }

    /// One conversation of the flight-assistant agent as the drawer sees
    /// it. The official Conversation model has no `name`; the title
    /// lives in `summary` — a field the local backend ALSO writes itself
    /// (an auto-summary that parrots the assistant's first line and can
    /// land at any time, even after our write). This list therefore
    /// SELF-HEALS on every read:
    /// - a title we wrote that was clobbered → restored;
    /// - a legacy/auto title (long or `规定了`-prefixed) we never wrote →
    ///   rebuilt from the conversation's first user message;
    /// - short single-line titles are adopted as ours.
    async list(): Promise<ConversationRow[]> {
        const client = this.deps.client();
        const agentId = this.deps.agentId();
        if (client == null || agentId == null) return [];
        try {
            const all = await client.conversations.list({
                agentId,
            });
            const out: ConversationRow[] = [];
            for (const c of all) {
                if (c.archived === true || c.agent_id !== agentId) continue;
                const summary = c.summary?.trim() ?? "";
                const known = this.titledConversations.get(c.id);
                let title: string | null = null;
                if (known != null) {
                    // We titled this conversation before.
                    title = known;
                    if (summary !== known) {
                        log.info(
                            "conversations",
                            `self-heal: restoring title of ${c.id}`,
                        );
                        await client.conversations
                            .update(c.id, {summary: known})
                            .catch(() => undefined);
                    }
                } else if (summary.length > 0 && !looksAutoSummary(summary)) {
                    // Short single-line title (ours, from a previous
                    // gateway run) — adopt it so the guard protects it too.
                    this.titledConversations.set(c.id, summary);
                    title = summary;
                } else {
                    // No title, or the backend's auto-summary junk.
                    title = await this.rebuildTitleFromFirstQuestion(c.id);
                }
                out.push({
                    id: c.id,
                    title,
                    lastMessageAt: c.last_message_at ?? c.created_at ?? null,
                });
            }
            return out.sort((a, b) =>
                (b.lastMessageAt ?? "").localeCompare(a.lastMessageAt ?? ""),
            );
        } catch (err) {
            log.warn(
                "conversations", "list failed:",
                err instanceof Error ? err.message : String(err),
            );
            return [];
        }
    }

    /// Conversation history from the OFFICIAL Letta API — Flight Studio
    /// never records chat itself. Uses the raw app-server protocol
    /// (`conversation_messages_list`) with an explicit `agent_id`: the
    /// bare-spawned app-server's store otherwise resolves the default
    /// conversation to its placeholder agent ("agent-local-default") and
    /// 404s. Returns user/assistant turns only, oldest first.
    /// [conversationId] scopes the query to one conversation (default
    /// conversation when null).
    async history(conversationId?: string): Promise<HistoryMessage[]> {
        const agentId = this.deps.agentId();
        if (agentId == null) return [];
        try {
            const socket = await this.deps.providerSocket();
            const response = await socket.request(
                "conversation_messages_list",
                {
                    request_id: socket.nextRequestId("history"),
                    conversation_id: conversationId ?? "default",
                    query: {
                        order: "asc",
                        limit: 200,
                        agent_id: agentId,
                    },
                },
            );
            const result = response as unknown as {
                success?: boolean;
                messages?: unknown[];
                error?: string;
            };
            if (result.success === false) {
                log.warn(
                    "history",
                    "conversation_messages_list failed:",
                    result.error,
                );
                return [];
            }
            const out: HistoryMessage[] = [];
            for (const raw of result.messages ?? []) {
                const m = raw as Record<string, unknown>;
                const role = m.role as string;
                if (role !== "user" && role !== "assistant") continue;
                let text = "";
                const c = m.content;
                if (typeof c === "string") {
                    text = c;
                } else if (Array.isArray(c)) {
                    text = c
                        .map((b) =>
                            b != null && typeof b === "object" && "text" in b
                                ? String((b as { text?: unknown }).text ?? "")
                                : "")
                        .join("");
                }
                // Remove harness-injected wrappers the user never typed.
                text = stripInjectedWrappers(text);
                if (text.trim().length === 0) continue;
                out.push({role, content: text});
            }
            log.info("history", `loaded ${out.length} messages`);
            return out;
        } catch (err) {
            log.warn(
                "history", "error:",
                err instanceof Error ? err.message : String(err),
            );
            return [];
        }
    }

    /// Creates a new conversation owned by the flight assistant.
    async create(): Promise<string | null> {
        const client = this.deps.client();
        const agentId = this.deps.agentId();
        if (client == null || agentId == null) return null;
        try {
            const conv = await client.conversations.create({
                agentId,
            });
            log.info("conversations", "created", conv.id);
            return conv.id;
        } catch (err) {
            log.error(
                "conversations", "create failed:",
                err instanceof Error ? err.message : String(err),
            );
            return null;
        }
    }

    /// Deletes one conversation. The local app-server protocol has no
    /// hard delete, so deletion uses the official archive semantics
    /// (`update {archived: true}`); archived conversations never appear
    /// in [list] again. An actively streaming conversation is aborted
    /// first (user-confirmed behaviour) — the owner passes its own
    /// abort callback.
    async delete(id: string, abortIfActive: () => Promise<void>): Promise<void> {
        const client = this.deps.client();
        if (client == null) return;
        await abortIfActive();
        await client.conversations.update(id, {archived: true});
        log.info("conversations", "archived (deleted)", id);
    }

    /// Rebuilds a conversation's title from its first user message (the
    /// user-approved fallback) when only auto-summary junk is stored.
    /// Persists it and remembers it; returns null when the conversation
    /// has no user message yet.
    async rebuildTitleFromFirstQuestion(
        conversationId: string,
    ): Promise<string | null> {
        const client = this.deps.client();
        if (client == null) return null;
        try {
            const history = await this.history(conversationId);
            const first = history.find((m) => m.role === "user");
            if (first == null) return null;
            const title = clipText(first.content.replace(/\s+/g, " ").trim(), 24);
            if (title.length === 0) return null;
            await client.conversations.update(conversationId, {summary: title});
            this.titledConversations.set(conversationId, title);
            log.info("conversations", `rebuilt title of ${conversationId} →`, title);
            return title;
        } catch (err) {
            log.warn(
                "conversations", "title rebuild failed:",
                err instanceof Error ? err.message : String(err),
            );
            return null;
        }
    }

    /// Normalizes raw LLM output into a title: strips reasoning blocks
    /// (reasoning models like GLM prefix their answer with
    /// `规定了…` — sometimes unclosed — which must never become the
    /// title), strips harness wrappers and quotes, then keeps the first
    /// line. Empty when nothing usable remains (caller falls back to the
    /// user's first question). Pure logic lives in `title_text.ts`
    /// (unit-tested there).
    titleFromLlm(raw: string): string {
        return cleanTitleText(raw);
    }

    /// Ensures a conversation carries OUR title after a turn completes:
    /// - first exchange → generate one (LLM summary via the configured
    ///   provider, falling back to the user's first question clipped) and
    ///   write it into the official `summary` field, overwriting whatever
    ///   Letta's auto-summary put there;
    /// - later exchanges → re-verify: if Letta has overwritten our title
    ///   since (its auto-summary repeats the assistant's first line and
    ///   can land late, e.g. on the next resumeSession bootstrap),
    ///   restore it.
    /// Runs in the background; failures never disturb the chat turn.
    async ensureTitle(
        conversationId: string,
        userText: string,
        assistantText: string,
        provider: {baseUrl: string; apiKey: string; model: string} | null,
    ): Promise<void> {
        const existing = this.titledConversations.get(conversationId);
        if (existing != null) {
            await this.guardTitle(conversationId, existing);
            return;
        }
        let title = "";
        try {
            if (provider != null) {
                const res = await fetch(
                    `${provider.baseUrl}/chat/completions`,
                    {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json",
                            Authorization: `Bearer ${provider.apiKey}`,
                        },
                        body: JSON.stringify({
                            model: provider.model,
                            max_tokens: 48,
                            temperature: 0.3,
                            messages: [
                                {
                                    role: "system",
                                    content:
                                        "Summarize this flight-assistant " +
                                        "conversation as a short title in the " +
                                        "user's language. Reply with ONLY the " +
                                        "title — at most 16 characters, no " +
                                        "quotes, no trailing period, no " +
                                        "reasoning and no thinking tags.",
                                },
                                {
                                    role: "user",
                                    content:
                                        `User: ${clipText(userText, 500)}\n` +
                                        `Assistant: ${clipText(assistantText, 800)}`,
                                },
                            ],
                        }),
                    },
                );
                if (res.ok) {
                    const data = (await res.json()) as {
                        choices?: Array<{ message?: { content?: string } }>;
                    };
                    title = this.titleFromLlm(
                        data.choices?.[0]?.message?.content ?? "",
                    );
                } else {
                    log.warn("title", "provider call failed:", res.status);
                }
            } else {
                log.info("title", "no provider configured — using first question");
            }
        } catch (err) {
            log.warn(
                "title", "summarize failed:",
                err instanceof Error ? err.message : String(err),
            );
        }
        // Fallback: the user's first question, clipped — always yields a
        // meaningful title even without a provider.
        if (title.length === 0) {
            title = clipText(userText.replace(/\s+/g, " ").trim(), 24);
        }
        const client = this.deps.client();
        if (client == null) return;
        try {
            await client.conversations.update(conversationId, {
                summary: title,
            });
            this.titledConversations.set(conversationId, title);
            log.info("title", `titled ${conversationId} →`, title);
            this.deps.emit({
                type: "conversation_renamed",
                conversationId,
                title,
            });
            await this.guardTitle(conversationId, title);
        } catch (err) {
            log.warn(
                "title", "write-back failed:",
                err instanceof Error ? err.message : String(err),
            );
        }
    }

    /// Re-checks (twice, a few seconds apart) that the conversation's
    /// official summary still equals OUR title; restores it when Letta's
    /// late auto-summary has overwritten it. Stops early once stable.
    private async guardTitle(
        conversationId: string,
        title: string,
    ): Promise<void> {
        const client = this.deps.client();
        if (client == null) return;
        for (const delayMs of [5_000, 15_000]) {
            await new Promise((r) => setTimeout(r, delayMs));
            if (this.deps.client() == null) return;
            try {
                const conv = await client.conversations.retrieve(conversationId);
                if (conv.summary === title) return; // Stable — done.
                log.info(
                    "title",
                    `restoring ${conversationId} (was: ${conv.summary?.slice(0, 40)})`,
                );
                await client.conversations.update(conversationId, {
                    summary: title,
                });
            } catch (err) {
                log.warn(
                    "title", "guard failed:",
                    err instanceof Error ? err.message : String(err),
                );
                return;
            }
        }
    }
}
