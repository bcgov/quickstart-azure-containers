import type { AzureMonitorOpenTelemetryOptions } from "@azure/monitor-opentelemetry";
import { resourceFromAttributes } from "@opentelemetry/resources";
import { ATTR_SERVICE_NAME } from "@opentelemetry/semantic-conventions";
import { ATTR_SERVICE_INSTANCE_ID } from "@opentelemetry/semantic-conventions/incubating";

/**
 * Fallback logical service name for telemetry when no deployment-specific name
 * is available.
 *
 * OpenTelemetry defines `service.name` as the logical name of a service and
 * expects it to stay the same across horizontally scaled instances. Azure
 * Monitor uses this attribute, together with `service.namespace` when present,
 * to populate the Cloud Role Name shown in Application Insights.
 */
export const defaultServiceName = "quickstart-azure-containers-backend";

/**
 * Resolves the OpenTelemetry `service.name` value for this backend.
 *
 * Resolution order deliberately follows the most explicit configuration first:
 * - `OTEL_SERVICE_NAME`: standard OpenTelemetry override for `service.name`.
 * - `CONTAINER_APP_NAME`: Azure Container Apps app name.
 * - `WEBSITE_SITE_NAME`: Azure App Service site name.
 * - `defaultServiceName`: repository fallback for local or incomplete setups.
 *
 * This function returns a logical service identity, not a per-instance ID. All
 * replicas of the same backend should report the same value so Azure Monitor
 * groups their telemetry under a single Cloud Role Name.
 */
export function getServiceName(): string {
  return (
    process.env.OTEL_SERVICE_NAME?.trim() ||
    process.env.CONTAINER_APP_NAME?.trim() ||
    process.env.WEBSITE_SITE_NAME?.trim() ||
    defaultServiceName
  );
}

/**
 * Builds the Azure Monitor OpenTelemetry distro options used by
 * `useAzureMonitor()`.
 *
 * The returned object intentionally configures only the pieces this service uses
 * directly:
 * - trace-aware log sampling so logs stay aligned with trace sampling decisions
 * - Winston log instrumentation so application logs flow into Azure Monitor
 * - OpenTelemetry resource attributes that identify the service and instance in
 *   Application Insights
 *
 * Option behavior, per Azure Monitor and OpenTelemetry documentation:
 * - `enableTraceBasedSamplingForLogs`: when a log record has trace context and
 *   the related trace was not sampled, the SDK drops that log record. Logs that
 *   are not attached to a trace are not affected.
 * - `instrumentationOptions.winston.enabled`: enables the Winston
 *   instrumentation, which is opt-in in the Azure Monitor JavaScript distro.
 *   This allows Winston log events to be captured by the OpenTelemetry logger
 *   pipeline and exported to Azure Monitor.
 * - `resource`: attaches Resource attributes to every telemetry item. Azure
 *   Monitor maps `service.name` to Cloud Role Name when no
 *   `service.namespace` is provided, and maps `service.instance.id` to Cloud
 *   Role Instance.
 *
 * @returns Azure Monitor OpenTelemetry options with logging and resource
 * metadata configured for this backend.
 */
export function createAzureMonitorOptions(): AzureMonitorOpenTelemetryOptions {
  return {
    // Keep logs correlated with trace sampling so unsampled request traces do
    // not leave orphaned log entries in AppTraces.
    enableTraceBasedSamplingForLogs: true,
    instrumentationOptions: {
      // Winston instrumentation is disabled by default by the Azure Monitor JS
      // distro. Enabling it lets Nest/Winston application logs enter the OTel
      // log pipeline and be exported to Azure Monitor.
      winston: { enabled: true },
    },
    resource: resourceFromAttributes({
      // `service.name` identifies the logical service, so this should be shared
      // by every replica of the same deployment. Azure Monitor uses it as the
      // Cloud Role Name when no `service.namespace` is supplied.
      [ATTR_SERVICE_NAME]: getServiceName(),
      // `service.instance.id` identifies one running instance of that service.
      // Azure Monitor surfaces it as Cloud Role Instance. `HOSTNAME` is usually
      // a stable container or host identifier; the process id is a local
      // fallback that still distinguishes multiple processes on the same host.
      [ATTR_SERVICE_INSTANCE_ID]:
        process.env.HOSTNAME?.trim() || process.pid.toString(),
    }),
  };
}
