/// Memory-block updates — split from letta_runtime.ts. Thin executor
/// over the SDK's block API; the policy (allow-list, length cap,
/// secret rejection) lives in memory_guard.ts.

import {type LettaAgentClient} from "@letta-ai/letta-agent-sdk";

import {guardMemoryUpdate} from "./memory_guard.js";

export class MemoryUpdater {
    constructor(
        private readonly deps: {
            client(): LettaAgentClient | null;
            agentId(): string | null;
        },
    ) {}

    /// Updates one of the agent's memory blocks. Strictly guarded: the
    /// block label must be on the allow-list (the four
    /// flight-assistant blocks), the value is length-capped, and obvious
    /// secret shapes are rejected — the memory blocks are plain text
    /// visible to every future turn and must never become a dumping
    /// ground for credentials.
    async update(blockLabel: string, value: string): Promise<void> {
        guardMemoryUpdate(blockLabel, value);
        const client = this.deps.client();
        const agentId = this.deps.agentId();
        if (client == null || agentId == null) return;
        await (client as any).updateBlock?.(agentId, blockLabel, {
            value,
        });
    }
}
