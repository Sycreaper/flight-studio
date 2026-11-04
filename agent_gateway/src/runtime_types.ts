/// Shared runtime types — split from letta_runtime.ts so implementation
/// modules can reference them without importing the facade (which would
/// create an import cycle).

export type Backend = "local" | "cloud" | "remote";

export interface GatewayStatus {
    gateway: "ok";
    letta: "ok" | "starting" | "error";
    backend: Backend;
    agentReady: boolean;
    agentId: string | null;
    lettaError: string | null;
    providerConfigured: boolean;
    model: string | null;
}
