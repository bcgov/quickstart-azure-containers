import { Controller, Get } from "@nestjs/common";
import {
  HealthCheckService,
  HealthCheck,
  PrismaHealthIndicator,
} from "@nestjs/terminus";
import { PrismaService } from "src/prisma.service";
import { trace, metrics } from "@opentelemetry/api";
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
    // Test manual tracing
    const tracer = trace.getTracer("test-tracer");
    const span = tracer.startSpan("manual-test-span");

    span.setAttributes({
      "test.timestamp": new Date().toISOString(),
      "test.user": "manual-test",
      "health.check": "manual",
    });

    span.addEvent("Manual telemetry test triggered");

    // Test manual metrics
    const meter = metrics.getMeter("test-meter");
    const counter = meter.createCounter("health_check_counter", {
      description: "Counts health check requests",
    });
    counter.add(1, { endpoint: "/api/health" });

    // Enhanced logging
    console.log("=== TELEMETRY DEBUG INFO ===");
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
    console.log("Manual telemetry test executed");
    console.log("Timestamp:", new Date().toISOString());

    // Test connectivity to Application Insights endpoint
    this.testConnectivity();

    console.log("============================");

    span.end();

    return this.health.check([
      () => this.prisma.pingCheck("prisma", this.prismaService),
    ]);
  }

  private testConnectivity() {
    const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
    if (!connectionString) return;

    // Log the Application ID for verification
    const appIdMatch = connectionString.match(/ApplicationId=([^;]+)/);
    if (appIdMatch) {
      console.log("Application ID:", appIdMatch[1]);
      console.log(
        "Use this to verify you're looking at the correct Application Insights resource",
      );
    }

    // Extract ingestion endpoint from connection string
    const ingestionMatch = connectionString.match(/IngestionEndpoint=([^;]+)/);
    if (!ingestionMatch) {
      console.log("Could not extract ingestion endpoint");
      return;
    }

    const ingestionEndpoint = ingestionMatch[1];
    console.log("Testing connectivity to:", ingestionEndpoint);

    try {
      const parsedUrl = new url.URL(ingestionEndpoint);

      // Test both the ingestion endpoint and live metrics endpoint
      const endpoints = [
        { name: "Ingestion", path: "/v2/track" },
        { name: "Live Metrics", path: "/QuickPulseService.svc" },
      ];

      endpoints.forEach((endpoint) => {
        const options = {
          hostname: parsedUrl.hostname,
          port: 443,
          path: endpoint.path,
          method: "HEAD",
          timeout: 10000,
          headers: {
            "User-Agent": "qs-azure-nest-api/1.0.0",
          },
        };

        console.log(
          `Testing ${endpoint.name} endpoint: ${parsedUrl.hostname}${endpoint.path}`,
        );

        const req = https.request(options, (res) => {
          console.log(`${endpoint.name} test - Status: ${res.statusCode}`);
          console.log(`${endpoint.name} test - Success: Can reach endpoint`);
        });

        req.on("error", (e) => {
          console.error(`${endpoint.name} test failed:`, e.message);
          console.error(`${endpoint.name} test - Network issue detected`);
        });

        req.on("timeout", () => {
          console.error(
            `${endpoint.name} test timed out - Possible firewall/network restriction`,
          );
          req.destroy();
        });

        req.end();
      });
    } catch (error) {
      console.error("Error testing connectivity:", error.message);
    }
  }
}
