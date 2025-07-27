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

  if (!connectionString) {
    console.warn(
      "APPLICATIONINSIGHTS_CONNECTION_STRING environment variable is not set. Telemetry will not be enabled.",
    );
    return;
  }

  try {
    const resource = resourceFromAttributes({
      "service.name": "qs-azure-nest-api",
    });

    // Initialize Azure Monitor with OpenTelemetry
    const options: AzureMonitorOpenTelemetryOptions = {
      azureMonitorExporterOptions: {
        connectionString: process.env.APPLICATIONINSIGHTS_CONNECTION_STRING,
      },
      resource: resource,
      samplingRatio: 1,
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

    console.info(
      "Azure Monitor OpenTelemetry initialized successfully with options : {}",
      options,
    );
  } catch (error) {
    console.error("Failed to initialize Azure Monitor OpenTelemetry:", error);
  }
}
