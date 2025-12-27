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

const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;

if (connectionString) {
  try {
    useAzureMonitor();
    console.log("Azure Monitor OpenTelemetry initialized successfully");
  } catch (error) {
    console.error("Failed to initialize Azure Monitor OpenTelemetry:", error);
  }
} else {
  console.warn(
    "APPLICATIONINSIGHTS_CONNECTION_STRING not set. Telemetry disabled.",
  );
}
