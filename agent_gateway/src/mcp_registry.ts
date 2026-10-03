/// FlightStudio gateway tools the Letta agent may call: airport charts
/// (ChartFox) and live weather (aviationweather.gov). These are plain async
/// functions here — the wiring into the SDK's client-tool / MCP surface lives
/// in letta_runtime.ts.

export interface FlightStudioTool {
    name: string;
    description: string;
    parameters: Record<string, string>;
    execute: (args: Record<string, string>) => Promise<string>;
}

const CHARTFOX_TOKEN = process.env.CHARTFOX_TOKEN ?? "";

async function fetchText(url: string, headers?: Record<string, string>) {
    const res = await fetch(url, {headers});
    if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
    return res.text();
}

/// Charts for one ICAO via ChartFox v2 (public data; token optional).
async function chartsRead(args: Record<string, string>): Promise<string> {
    const icao = (args.icao ?? "").toUpperCase();
    if (!/^[A-Z0-9]{2,6}$/.test(icao)) return `Invalid ICAO: ${icao}`;
    try {
        const text = await fetchText(
            `https://api.chartfox.org/v2/airport/${icao}`,
            CHARTFOX_TOKEN ? {Authorization: `Bearer ${CHARTFOX_TOKEN}`} : undefined,
        );
        const data = JSON.parse(text) as {
            groups?: Array<{
                group?: string;
                charts?: Array<{ name?: string; url?: string }>;
            }>;
        };
        const lines: string[] = [];
        for (const g of data.groups ?? []) {
            for (const c of g.charts ?? []) {
                lines.push(`[${g.group ?? "?"}] ${c.name ?? "chart"} — ${c.url ?? ""}`);
            }
        }
        return lines.length
            ? `Charts for ${icao}:\n${lines.join("\n")}`
            : `No charts found for ${icao}`;
    } catch (err) {
        return `ChartFox request failed: ${
            err instanceof Error ? err.message : String(err)
        }`;
    }
}

/// Current METAR + TAF raw text for one ICAO (aviationweather.gov).
async function weatherRead(args: Record<string, string>): Promise<string> {
    const icao = (args.icao ?? "").toUpperCase();
    if (!/^[A-Z0-9]{4}$/.test(icao)) return `Invalid ICAO: ${icao}`;
    try {
        const metar = await fetchText(
            `https://aviationweather.gov/api/data/metar?ids=${icao}&format=raw`,
        );
        let taf = "";
        try {
            taf = await fetchText(
                `https://aviationweather.gov/api/data/taf?ids=${icao}&format=raw`,
            );
        } catch {
            taf = "(TAF unavailable)";
        }
        return `METAR ${icao}:\n${metar.trim()}\n\nTAF ${icao}:\n${taf.trim()}`;
    } catch (err) {
        return `Weather request failed: ${
            err instanceof Error ? err.message : String(err)
        }`;
    }
}

export const flightStudioTools: FlightStudioTool[] = [
    {
        name: "charts_read",
        description:
            "List available airport charts (ground/taxi/departure/arrival/approach) " +
            "for one ICAO via ChartFox. Use when the pilot asks for 航图/charts.",
        parameters: {icao: "string"},
        execute: chartsRead,
    },
    {
        name: "weather_read",
        description:
            "Fetch the current METAR and TAF raw reports for one ICAO. Use for " +
            "天气/weather questions about a specific airport.",
        parameters: {icao: "string"},
        execute: weatherRead,
    },
];

export {chartsRead, weatherRead};
