/**
 * OpenTelemetry Instrumentation
 *
 * CRITICAL: This file MUST be imported/required before any other application code
 * to ensure instrumentations are registered before the modules they instrument are loaded.
 *
 * For production: Use --require flag: node --require ./dist/instrumentation.js dist/main.js
 * For development: Import at the very top of main.ts before any other imports
 */

import { useAzureMonitor } from "@azure/monitor-opentelemetry";

import { createAzureMonitorOptions } from "./common/telemetry.config";

type TelemetryState = "initialized" | "disabled" | "failed";

const telemetryState = globalThis as typeof globalThis & {
  __quickstartAzureMonitorState?: TelemetryState;
};

const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;

if (telemetryState.__quickstartAzureMonitorState) {
  // Telemetry has already been initialized (or explicitly skipped) in this
  // process. Avoid double-registration when startup also uses --require.
} else if ((process.env.NODE_ENV ?? "").trim().toLowerCase() === "test") {
  telemetryState.__quickstartAzureMonitorState = "disabled";
} else if (connectionString) {
  try {
    useAzureMonitor(createAzureMonitorOptions());
    telemetryState.__quickstartAzureMonitorState = "initialized";
    console.log("Azure Monitor OpenTelemetry initialized successfully");
  } catch (error) {
    telemetryState.__quickstartAzureMonitorState = "failed";
    console.error("Failed to initialize Azure Monitor OpenTelemetry:", error);
  }
} else {
  telemetryState.__quickstartAzureMonitorState = "disabled";
  console.warn(
    "APPLICATIONINSIGHTS_CONNECTION_STRING not set. Telemetry disabled.",
  );
}
