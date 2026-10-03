/// Session + approval controllers. v1 runs a single default session
/// ("default"); the account system later maps sessionId ↔ Letta agent.

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

    resolveApproval(id: string, approved: boolean): ApprovalRequest | null {
        const req = this.pending.find((r) => r.id === id && !r.resolved);
        if (req == null) return null;
        req.resolved = true;
        req.approved = approved;
        return req;
    }

    pendingApprovals(): ApprovalRequest[] {
        return this.pending.filter((r) => !r.resolved);
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
