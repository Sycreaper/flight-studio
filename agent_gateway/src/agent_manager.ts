/// The single 飞行助理 agent — split from letta_runtime.ts. Ensures the
/// agent exists (list-then-create through the official management API)
/// and wraps actions with "not found" recovery.

import {type LettaAgentClient} from "@letta-ai/letta-agent-sdk";

export const DEFAULT_AGENT_NAME = "飞行助理";

const AGENT_PERSONA =
    "You are FlightStudio's flight copilot. Explain-first: ground every " +
    "answer in provided navdata, weather or manual excerpts; never invent " +
    "data; simulator write actions always require explicit human approval. " +
    "Answer in the user's language.";

/// Ensures the single flight-assistant agent exists; returns its id.
/// The agent is managed internally — no external switching exists.
export async function ensureAgent(
    client: LettaAgentClient,
): Promise<string | null> {
    let agents: Array<{ id?: string; name?: string }> = [];
    try {
        // Official management API (client.agents.list). A plain
        // `client.listAgents` does not exist — calling it silently
        // created a fresh agent on every gateway start.
        const listed = await client.agents.list();
        agents = listed.map((a) => ({id: a.id, name: a.name}));
    } catch {
        // Listing failed — fall through to create.
    }
    const found = agents.find(
        (a) => a.name === DEFAULT_AGENT_NAME && a.id != null,
    );
    if (found?.id) {
        return found.id;
    }
    const created = await client.createAgent({
        name: DEFAULT_AGENT_NAME,
        persona: AGENT_PERSONA,
    });
    return typeof created === "string" ? created : String(created ?? "");
}

/// Runs [action] with the agent id; on a "not found" failure (stale
/// agent id from a previous app-server lifetime) re-resolves the agent
/// once and retries.
export async function withAgentRecovery<T>(
    deps: {
        client(): LettaAgentClient | null;
        agentId(): string | null;
        setAgentId(id: string | null): void;
        ensureAgent(): Promise<string | null>;
    },
    action: (agentId: string) => Promise<T>,
): Promise<T> {
    try {
        return await action(deps.agentId()!);
    } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        if (!message.includes("not found")) throw err;
        deps.setAgentId(null);
        const id = await deps.ensureAgent();
        deps.setAgentId(id);
        if (id == null) throw err;
        return await action(id);
    }
}
