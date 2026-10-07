/// FlightAgentEvent — the stable protocol between the gateway and Flutter.
///
/// Flutter never sees raw Letta events; the gateway normalises everything
/// into these types. If the underlying runtime (Letta, LangGraph, OpenAI
/// Agents, …) changes, only the gateway adapter changes — Flutter is
/// untouched.

export type FlightAgentEvent =
    | { type: "text_delta"; text: string }
    | { type: "thinking"; text?: string }
    | { type: "tool_started"; tool: string }
    | { type: "tool_completed"; tool: string; result?: string }
    | { type: "approval_required"; id: string; tool: string; input: unknown }
    | { type: "completed"; content: string }
    | { type: "cancelled" }
    | { type: "error"; message: string }
    | { type: "status"; letta: string; agentReady: boolean };

/// Internal gateway event (pre-normalisation) — the runtime emits these,
/// and index.ts bridges them into FlightAgentEvent for SSE. Turn-scoped
/// events carry the `conversationId` they belong to so Flutter can route
/// them to the right chat tab; `conversation_renamed` fires when the
/// auto-generated title has been written to the conversation's official
/// `summary` field.
export type GatewayEvent =
    | { type: "turn_start"; role: "assistant"; conversationId?: string }
    | { type: "delta"; content: string; conversationId?: string }
    | { type: "turn_done"; content: string; conversationId?: string }
    | { type: "phase"; phase: string; detail?: string; raw?: string; conversationId?: string }
    | { type: "error"; message: string; conversationId?: string }
    | { type: "approval_request"; id: string; tool: string; input: unknown; conversationId?: string }
    | { type: "approval_resolved"; id: string; approved: boolean; conversationId?: string }
    | { type: "conversation_renamed"; conversationId: string; title: string }
    | { type: "status"; letta: string; agentReady: boolean };
