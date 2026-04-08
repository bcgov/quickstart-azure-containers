import type { AzureMonitorOpenTelemetryOptions } from "@azure/monitor-opentelemetry";
import { resourceFromAttributes } from "@opentelemetry/resources";
import { ATTR_SERVICE_NAME } from "@opentelemetry/semantic-conventions";
import { ATTR_SERVICE_INSTANCE_ID } from "@opentelemetry/semantic-conventions/incubating";

export const defaultServiceName = "quickstart-azure-containers-backend";

export function getServiceName(): string {
  return (
    process.env.OTEL_SERVICE_NAME?.trim() ||
    process.env.CONTAINER_APP_NAME?.trim() ||
    process.env.WEBSITE_SITE_NAME?.trim() ||
    defaultServiceName
  );
}

export function createAzureMonitorOptions(): AzureMonitorOpenTelemetryOptions {
  return {
    enableTraceBasedSamplingForLogs: true,
    instrumentationOptions: {
      winston: { enabled: true },
    },
    resource: resourceFromAttributes({
      [ATTR_SERVICE_NAME]: getServiceName(),
      [ATTR_SERVICE_INSTANCE_ID]:
        process.env.HOSTNAME?.trim() || process.pid.toString(),
    }),
  };
}
