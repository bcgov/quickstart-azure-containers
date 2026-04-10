import promBundle from "express-prom-bundle";
import * as prom from "prom-client";

/**
 * Prometheus registry that stores process and HTTP metrics for the backend.
 */
const register = new prom.Registry();

prom.collectDefaultMetrics({ register });

/**
 * Express middleware that captures HTTP metrics and exposes them through the registry.
 */
const metricsMiddleware = promBundle({
  includeMethod: true,
  includePath: true,
  metricsPath: "/prom-metrics",
  promRegistry: register,
});
export { metricsMiddleware, register };
