import { Controller, Get } from "@nestjs/common";
import {
  HealthCheckService,
  HealthCheck,
  PrismaHealthIndicator,
} from "@nestjs/terminus";
import { PrismaService } from "src/prisma.service";
import { trace } from "@opentelemetry/api";
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
    const tracer = trace.getTracer("test-tracer");
    const span = tracer.startSpan("manual-test-span");

    span.setAttributes({
      "test.timestamp": new Date().toISOString(),
      "test.user": "manual-test",
    });

    span.addEvent("Manual telemetry test triggered");
    span.end();

    console.log("Manual telemetry test executed");
    return this.health.check([
      () => this.prisma.pingCheck("prisma", this.prismaService),
    ]);
  }
}
