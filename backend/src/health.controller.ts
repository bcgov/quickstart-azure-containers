import { Controller, Get } from "@nestjs/common";
import {
  HealthCheckService,
  HealthCheck,
  PrismaHealthIndicator,
} from "@nestjs/terminus";
import { PrismaService } from "src/prisma.service";

/**
 * Publishes health information for the service and its database dependency.
 */
@Controller("health")
export class HealthController {
  /**
   * Creates the health controller with the services required for dependency checks.
   *
   * @param health Service that aggregates health indicator results.
   * @param prisma Indicator used to probe Prisma connectivity.
   * @param prismaService Prisma client instance checked by the indicator.
   */
  constructor(
    private health: HealthCheckService,
    private prisma: PrismaHealthIndicator,
    private readonly prismaService: PrismaService,
  ) {}

  /**
   * Runs the configured health checks and returns the combined status.
   *
   * @returns Aggregate health response for the API.
   */
  @Get()
  @HealthCheck()
  check() {
    console.log("Health check initiated");
    console.log("users");
    return this.health.check([
      () => this.prisma.pingCheck("prisma", this.prismaService),
    ]);
  }
}
