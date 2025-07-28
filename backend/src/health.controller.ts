import { Controller, Get } from "@nestjs/common";
import {
  HealthCheckService,
  HealthCheck,
  PrismaHealthIndicator,
} from "@nestjs/terminus";
import { PrismaService } from "src/prisma.service";
import { trace, metrics, context } from "@opentelemetry/api";
import * as https from "https";
import * as url from "url";

@Controller("health")
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private prisma: PrismaHealthIndicator,
    private readonly prismaService: PrismaService,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    // Test manual tracing with more detailed attributes
    const tracer = trace.getTracer("health-check-tracer", "1.0.0");
    const span = tracer.startSpan("health-check-operation", {
      kind: 1, // SERVER
      attributes: {
        "service.name": "qs-azure-nest-api",
        "service.version": "1.0.0",
        "test.timestamp": new Date().toISOString(),
        "test.user": "manual-test",
        "health.check": "manual",
        "operation.name": "health-check",
        "custom.event": "health-endpoint-called",
      },
    });

    // Add events to the span
    span.addEvent("Health check started");
    span.addEvent("Manual telemetry test triggered", {
      "event.timestamp": Date.now(),
      "event.source": "health-controller",
    });

    // Test manual metrics with proper dimensions
    const meter = metrics.getMeter("health-check-meter", "1.0.0");
    const counter = meter.createCounter("health_check_requests_total", {
      description: "Total number of health check requests",
      unit: "1",
    });

    const histogram = meter.createHistogram("health_check_duration_ms", {
      description: "Health check request duration in milliseconds",
      unit: "ms",
    });

    const startTime = Date.now();

    counter.add(1, {
      endpoint: "/api/health",
      method: "GET",
      service: "qs-azure-nest-api",
    });

    // Enhanced logging with OpenTelemetry context
    console.log("=== ENHANCED TELEMETRY DEBUG INFO ===");
    console.log(
      "Connection String:",
      process.env.APPLICATIONINSIGHTS_CONNECTION_STRING ? "Set" : "Not set",
    );
    console.log(
      "Connection String Length:",
      process.env.APPLICATIONINSIGHTS_CONNECTION_STRING?.length || 0,
    );
    console.log(
      "Instrumentation Key:",
      process.env.APPLICATIONINSIGHTS_CONNECTION_STRING?.includes(
        "eb10d1b7-99e5-4f88-a5c7-2c5562d7d886",
      )
        ? "Matches"
        : "Does not match",
    );

    // Log current trace context
    const activeSpan = trace.getActiveSpan();
    if (activeSpan) {
      const spanContext = activeSpan.spanContext();
      console.log("Active Span Context:");
      console.log("  Trace ID:", spanContext.traceId);
      console.log("  Span ID:", spanContext.spanId);
      console.log("  Trace Flags:", spanContext.traceFlags);
    } else {
      console.log("No active span found - this indicates a potential issue");
    }

    console.log("Manual telemetry test executed");
    console.log("Timestamp:", new Date().toISOString());

    // Test connectivity to Application Insights endpoint
    this.testDetailedConnectivity();

    // Record histogram metric
    const duration = Date.now() - startTime;
    histogram.record(duration, {
      endpoint: "/api/health",
      status: "success",
    });

    span.addEvent("Health check completed", {
      "duration.ms": duration,
    });

    console.log("=======================================");

    span.setStatus({ code: 1 }); // OK status
    span.end();

    return this.health.check([
      () => this.prisma.pingCheck("prisma", this.prismaService),
    ]);
  }

  private testDetailedConnectivity() {
    const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
    if (!connectionString) return;

    // Parse connection string components
    const components = connectionString.split(";").reduce(
      (acc, part) => {
        const [key, value] = part.split("=");
        if (key && value) acc[key] = value;
        return acc;
      },
      {} as Record<string, string>,
    );

    console.log("Connection String Components:");
    console.log("  Instrumentation Key:", components.InstrumentationKey);
    console.log("  Ingestion Endpoint:", components.IngestionEndpoint);
    console.log("  Live Endpoint:", components.LiveEndpoint);
    console.log("  Application ID:", components.ApplicationId);

    // Test specific Application Insights endpoints
    if (components.IngestionEndpoint) {
      this.testSpecificEndpoint(components.IngestionEndpoint, "Ingestion");
    }
    if (components.LiveEndpoint) {
      this.testSpecificEndpoint(components.LiveEndpoint, "Live Metrics");
    }
  }

  private testSpecificEndpoint(endpoint: string, name: string) {
    try {
      const parsedUrl = new url.URL(endpoint);

      const testPayload = JSON.stringify({
        ver: 1,
        name: "Microsoft.ApplicationInsights.Event",
        time: new Date().toISOString(),
        iKey: process.env.APPINSIGHTS_INSTRUMENTATIONKEY,
        data: {
          baseType: "EventData",
          baseData: {
            name: "ConnectivityTest",
            properties: {
              test: "true",
              timestamp: new Date().toISOString(),
            },
          },
        },
      });

      const options = {
        hostname: parsedUrl.hostname,
        port: 443,
        path: "/v2/track",
        method: "POST",
        timeout: 10000,
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(testPayload),
          "User-Agent": "qs-azure-nest-api/1.0.0",
        },
      };

      console.log(`Testing ${name} endpoint with actual telemetry data...`);

      const req = https.request(options, (res) => {
        console.log(`${name} POST test - Status: ${res.statusCode}`);
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          console.log(
            `${name} POST test - Response: ${data || "No response body"}`,
          );
          if (res.statusCode === 200) {
            console.log(
              `${name} POST test - SUCCESS: Data accepted by Application Insights`,
            );
          } else {
            console.log(`${name} POST test - WARNING: Unexpected status code`);
          }
        });
      });

      req.on("error", (e) => {
        console.error(`${name} POST test failed:`, e.message);
      });

      req.on("timeout", () => {
        console.error(`${name} POST test timed out`);
        req.destroy();
      });

      req.write(testPayload);
      req.end();
    } catch (error) {
      console.error(`Error testing ${name} endpoint:`, error.message);
    }
  }
}
