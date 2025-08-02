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
    // Create resource with detailed service information
    const resource = resourceFromAttributes({
      SERVICE_NAME: "qs-azure-nest-api",
      SERVICE_VERSION: "1.0.0",
      SERVICE_INSTANCE_ID: process.env.WEBSITE_INSTANCE_ID || "local",
      DEPLOYMENT_ENVIRONMENT: process.env.NODE_ENV || "development",
      CLOUD_PROVIDER: "azure",
      CLOUD_PLATFORM: "azure_app_service",
    });

    // Initialize Azure Monitor with explicit configuration
    const options: AzureMonitorOpenTelemetryOptions = {
      azureMonitorExporterOptions: {
        connectionString: connectionString,
        credential: undefined, // Use connection string instead of credential
        retryOptions: {
          maxRetries: 3,
          retryDelayInMs: 1000,
        },
        disableOfflineStorage: false,
        storageDirectory: "/tmp/Microsoft/AzureMonitor",
      },
      resource: resource,
      samplingRatio: 1.0, // 100% sampling for troubleshooting
      instrumentationOptions: {
        // Enable all relevant instrumentations
        azureSdk: { enabled: true },
        http: {
          enabled: true,
        },
        postgreSql: { enabled: true },
        winston: { enabled: true },
      },
      enableLiveMetrics: true,
      enableStandardMetrics: true,
      enablePerformanceCounters: true,
    };

    console.log("Initializing Azure Monitor with options:");
    console.log(options);

    useAzureMonitor(options);

    console.log("Azure Monitor OpenTelemetry initialized successfully");
    console.log("===============================");
  } catch (error) {
    console.error("Failed to initialize Azure Monitor OpenTelemetry:", error);
    console.error("Error details:", error.message);
    console.error("Stack trace:", error.stack);
  }
}
