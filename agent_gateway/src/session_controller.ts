/// Session + approval controllers. v1 runs a single default session
/// ("default") — all conversations belong to the one 飞行助理 agent and are
/// routed per-request via `conversationId`, so there is no session ↔ agent
/// mapping anymore.
//
// Approvals bridge the OFFICIAL SDK `canUseTool` callback to the Flutter
// UI: the gateway emits `approval_request` events over SSE, the app shows
// a floating permission card, and the user's choice flows back through
// POST /agent/approval/{id}. MCP tool approvals can reuse the same
// pipeline later (createApproval + waitForResolution).

import {LettaRuntime} from "./letta_runtime.js";

export interface ApprovalRequest {
    id: string;
    tool: string;
    input: unknown;
    resolved: boolean;
    approved: boolean | null;
}

export class SessionController {
    private pending: ApprovalRequest[] = [];
    private nextId = 1;
    private readonly waiters = new Map<
        string,
        (approved: boolean) => void
    >();

    constructor(private readonly runtime: LettaRuntime) {
    }

    get sessionId(): string {
        return "default";
    }

    get isTurnActive(): boolean {
        return this.runtime["turnActive"] === true;
    }

    createApproval(tool: string, input: unknown): ApprovalRequest {
        const req: ApprovalRequest = {
            id: `approval_${this.nextId++}`,
            tool,
            input,
            resolved: false,
            approved: null,
        };
        this.pending.push(req);
        return req;
    }

    /// Resolves a pending approval and wakes the waiting canUseTool
    /// callback (if any).
    resolveApproval(id: string, approved: boolean): ApprovalRequest | null {
        const req = this.pending.find((r) => r.id === id && !r.resolved);
        if (req == null) return null;
        req.resolved = true;
        req.approved = approved;
        const waiter = this.waiters.get(id);
        if (waiter != null) {
            this.waiters.delete(id);
            waiter(approved);
        }
        // Keep the list bounded: drop resolved entries older than the
        // newest 50.
        if (this.pending.length > 50) {
            this.pending = this.pending.filter((r) => !r.resolved)
                .concat(this.pending.filter((r) => r.resolved).slice(-20));
        }
        return req;
    }

    pendingApprovals(): ApprovalRequest[] {
        return this.pending.filter((r) => !r.resolved);
    }

    /// Waits until the approval is resolved or [timeoutMs] elapses
    /// (timeout → deny). Used by the canUseTool bridge.
    waitForResolution(id: string, timeoutMs: number): Promise<boolean> {
        return new Promise((resolve) => {
            let settled = false;
            const finish = (approved: boolean) => {
                if (settled) return;
                settled = true;
                this.waiters.delete(id);
                clearTimeout(timer);
                resolve(approved);
            };
            const timer = setTimeout(() => finish(false), timeoutMs);
            this.waiters.set(id, finish);
        });
    }
}

export class ApprovalController {
    constructor(private readonly session: SessionController) {
    }

    resolve(id: string, approved: boolean): ApprovalRequest | null {
        return this.session.resolveApproval(id, approved);
    }

    list(): ApprovalRequest[] {
        return this.session.pendingApprovals();
    }
}
