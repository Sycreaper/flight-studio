/// LLM reverse proxy — URL convention, auth injection and /v1 stripping,
/// exercised against a real local upstream over HTTP (no external network).
import assert from "node:assert/strict";
import {createServer, type Server} from "node:http";
import Fastify from "fastify";
import {after, before, test} from "node:test";

import {LlmProxy} from "../src/llm_proxy.js";

let upstream: Server;
let upstreamBase: string;
const seen: Array<{
    method: string;
    url: string;
    auth: string | undefined;
    body: string;
}> = [];

before(async () => {
    upstream = createServer((req, res) => {
        let body = "";
        req.on("data", (c) => (body += c));
        req.on("end", () => {
            seen.push({
                method: req.method ?? "",
                url: req.url ?? "",
                auth: req.headers.authorization,
                body,
            });
            res.writeHead(200, {"content-type": "application/json"});
            res.end(JSON.stringify({ok: true, path: req.url}));
        });
    });
    await new Promise<void>((resolve) => upstream.listen(0, "127.0.0.1", resolve));
    const addr = upstream.address();
    if (addr == null || typeof addr === "string") throw new Error("no port");
    upstreamBase = `http://127.0.0.1:${addr.port}`;
});

after(async () => {
    await new Promise<void>((resolve) => upstream.close(() => resolve()));
});

test("proxy forwards with auth, strips /v1 and passes the query through", async () => {
    const app = Fastify();
    const proxy = new LlmProxy(8787);
    proxy.registerFastify(app);
    const proxyUrl = proxy.register({baseUrl: upstreamBase, apiKey: "sk-test"});

    // Registered URLs end in /v1 (the harness convention).
    assert.match(proxyUrl, /\/llm-proxy\/\d+\/v1$/);

    const res = await app.inject({
        method: "POST",
        url: "/llm-proxy/1/v1/chat/completions?stream=true",
        payload: {model: "glm-4.7"},
        headers: {"content-type": "application/json"},
    });
    assert.equal(res.statusCode, 200);
    assert.equal(JSON.parse(res.body).path, "/chat/completions?stream=true");

    // Upstream received the credential, never the /v1 segment.
    const hit = seen.at(-1)!;
    assert.equal(hit.auth, "Bearer sk-test");
    assert.equal(hit.url, "/chat/completions?stream=true");
    assert.equal(JSON.parse(hit.body).model, "glm-4.7");
    await app.close();
});

test("unknown proxy tokens are rejected with 503", async () => {
    const app = Fastify();
    new LlmProxy(8787).registerFastify(app);
    const res = await app.inject({method: "GET", url: "/llm-proxy/999/v1/models"});
    assert.equal(res.statusCode, 503);
    await app.close();
});
