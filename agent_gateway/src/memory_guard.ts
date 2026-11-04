/// Guards for /agent/memory/update — pure logic, unit-tested separately
/// (test/memory_guard.test.ts). The memory blocks are plain text visible
/// to every future turn; these guards keep them from becoming a dumping
/// ground for credentials or runaway payloads.

/// The only memory blocks /agent/memory/update may touch. The flight
/// assistant's four blocks; anything else is rejected.
export const MEMORY_BLOCK_ALLOWLIST = new Set([
    "user_profile",
    "aircraft_preferences",
    "learning_history",
    "safety_preferences",
]);

/// Memory values are plain text shown to every future turn — cap them so
/// a runaway update cannot bloat the agent or smuggle in huge payloads.
export const MEMORY_VALUE_MAX_CHARS = 4_000;

/// Detects obvious credential shapes (Laravel Sanctum PATs, OpenAI-style
/// `sk-` keys, bearer tokens, `key=value` assignments) so they never get
/// persisted into readable memory blocks. Returns a short label of the
/// matched shape, or null when the value looks benign.
export function detectSecretLike(value: string): string | null {
    const patterns: Array<[string, RegExp]> = [
        ["bearer token", /\bBearer\s+[A-Za-z0-9\-._~+/]+=*/i],
        ["sanctum PAT", /\b\d{1,10}\|[A-Za-z0-9]{30,64}\b/],
        ["api key", /\bsk-[A-Za-z0-9]{20,}\b/],
        ["api key", /\b[A-Za-z0-9]{32,45}\b(?![\w.])/],
        ["key assignment", /\b(api[_-]?key|token|secret|password)\b\s*[:=]\s*\S+/i],
    ];
    for (const [label, re] of patterns) {
        if (re.test(value)) return label;
    }
    return null;
}

/// Validates a memory-block update; throws Error with a human-readable
/// reason when rejected (allow-list miss, value too long, or a
/// credential-shaped value).
export function guardMemoryUpdate(blockLabel: string, value: string): void {
    if (!MEMORY_BLOCK_ALLOWLIST.has(blockLabel)) {
        throw new Error(`memory block not allowed: ${blockLabel}`);
    }
    if (value.length > MEMORY_VALUE_MAX_CHARS) {
        throw new Error(
            `memory value too long (${value.length} > ` +
                `${MEMORY_VALUE_MAX_CHARS} chars)`,
        );
    }
    const secret = detectSecretLike(value);
    if (secret != null) {
        throw new Error(
            "memory value looks like a credential — refusing to store",
        );
    }
}
