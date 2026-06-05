import test from "node:test";
import assert from "node:assert/strict";
import Fastify from "fastify";
import * as healthModule from "../src/routes/health";

type FastifyPluginCandidate = unknown;

function resolveHealthRoute(module: Record<string, FastifyPluginCandidate>) {
  return (
    module.default ??
    module.healthRoutes ??
    module.healthRoute ??
    module.routes
  );
}

test("GET /health returns status ok", async () => {
  const app = Fastify({ logger: false });
  const healthRoute = resolveHealthRoute(
    healthModule as Record<string, FastifyPluginCandidate>
  );

  if (typeof healthRoute !== "function") {
    throw new Error(
      "No Fastify health route plugin export found. Expected one of: default, healthRoutes, healthRoute, routes."
    );
  }

  await app.register(healthRoute);

  const response = await app.inject({
    method: "GET",
    url: "/health",
  });

  assert.equal(response.statusCode, 200);
  assert.deepEqual(JSON.parse(response.body), { status: "ok" });

  await app.close();
});
