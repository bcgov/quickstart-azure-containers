import {
  AzureMonitorOpenTelemetryOptions,
  useAzureMonitor,
} from "@azure/monitor-opentelemetry";
import { resourceFromAttributes } from "@opentelemetry/resources";

/**
 * Initialize Azure Monitor OpenTelemetry
 * This should be called before any other modules are imported
 */
export function initializeTelemetry(): void {
  // Get the connection string from environment variables
  const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;

  console.log("=== TELEMETRY INITIALIZATION ===");
  console.log("Connection String Present:", !!connectionString);
  console.log("Connection String Length:", connectionString?.length || 0);
  console.log("Environment:", process.env.NODE_ENV);

  if (!connectionString) {
    console.warn(
      "APPLICATIONINSIGHTS_CONNECTION_STRING environment variable is not set. Telemetry will not be enabled.",
    );
    return;
  }

  try {
    const resource = resourceFromAttributes({
      ["SERVICE_NAME"]: "qs-azure-nest-api",
      ["SERVICE_VERSION"]: "1.0.0",
      ["DEPLOYMENT_ENVIRONMENT"]: process.env.NODE_ENV || "development",
    });

    // Initialize Azure Monitor with OpenTelemetry
    const options: AzureMonitorOpenTelemetryOptions = {
      azureMonitorExporterOptions: {
        connectionString: connectionString,
      },
      resource: resource,
      samplingRatio: 1.0, // Ensure 100% sampling for troubleshooting
      instrumentationOptions: {
        // Instrumentations generating traces
        azureSdk: { enabled: true },
        http: { enabled: true },
        postgreSql: { enabled: true },
        // Instrumentations generating logs
        winston: { enabled: true },
      },
      enableLiveMetrics: true,
      enableStandardMetrics: true,
      enablePerformanceCounters: true,
    };

    useAzureMonitor(options);

    console.log("Azure Monitor OpenTelemetry initialized successfully");
    console.log("Sampling Ratio:", options.samplingRatio);
    console.log("Live Metrics Enabled:", options.enableLiveMetrics);
    console.log("Standard Metrics Enabled:", options.enableStandardMetrics);
    console.log("===============================");
  } catch (error) {
    console.error("Failed to initialize Azure Monitor OpenTelemetry:", error);
    console.error("Error details:", error.message);
    console.error("Stack trace:", error.stack);
  }
}
