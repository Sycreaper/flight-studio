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
/// and index.ts bridges them into FlightAgentEvent for SSE.
export type GatewayEvent =
    | { type: "turn_start"; role: "assistant" }
    | { type: "delta"; content: string }
    | { type: "turn_done"; content: string }
    | { type: "error"; message: string }
    | { type: "approval_request"; id: string; tool: string; input: unknown }
    | { type: "status"; letta: string; agentReady: boolean };
