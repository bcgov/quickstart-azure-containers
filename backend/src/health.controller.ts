import { Controller, Get } from "@nestjs/common";
import {
  HealthCheckService,
  HealthCheck,
  PrismaHealthIndicator,
} from "@nestjs/terminus";
import { PrismaService } from "src/prisma.service";
import { trace, metrics } from "@opentelemetry/api";

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
    console.log("Connection String:", process.env.APPLICATIONINSIGHTS_CONNECTION_STRING ? "Set" : "Not set");
    console.log("Connection String Length:", process.env.APPLICATIONINSIGHTS_CONNECTION_STRING?.length || 0);
    console.log("Instrumentation Key:", process.env.APPLICATIONINSIGHTS_CONNECTION_STRING?.includes("eb10d1b7-99e5-4f88-a5c7-2c5562d7d886") ? "Matches" : "Does not match");
    console.log("Manual telemetry test executed");
    console.log("Timestamp:", new Date().toISOString());
    console.log("============================");

    span.end();

    return this.health.check([
      () => this.prisma.pingCheck("prisma", this.prismaService),
    ]);
  }
}