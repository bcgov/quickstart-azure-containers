import type { OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { Injectable, Logger } from "@nestjs/common";
import { PrismaPg } from "@prisma/adapter-pg";
import { Prisma, PrismaClient } from "@prisma/client";

import {
  emitOperationalStreamLog,
  shouldEmitSlowQueryLog,
  summarizeSqlStatement,
} from "./common/logging.policy";

const DB_HOST = process.env.POSTGRES_HOST || "localhost";
const DB_USER = process.env.POSTGRES_USER || "postgres";
const DB_PWD = encodeURIComponent(process.env.POSTGRES_PASSWORD || "default"); // this needs to be encoded, if the password contains special characters it will break connection string.
const DB_PORT = process.env.POSTGRES_PORT || 5432;
const DB_NAME = process.env.POSTGRES_DATABASE || "postgres";
const DB_SCHEMA = process.env.POSTGRES_SCHEMA || "app";

/**
 * Determines whether the configured database host resolves to the local machine.
 *
 * @param host Database host name or IP address.
 * @returns Whether the host should be treated as local.
 */
const isLocalHost = (host: string) =>
  host === "localhost" ||
  host === "127.0.0.1" ||
  host === "::1" ||
  process.env.NODE_ENV === "local";

// Azure Database for PostgreSQL typically requires TLS. If sslmode isn't specified,
// Prisma may attempt a non-encrypted connection which Azure rejects.
//
// Override behaviour by setting POSTGRES_SSLMODE (e.g. "require", "disable").
/**
 * Resolves the SSL mode to use for the PostgreSQL connection string.
 *
 * @returns Explicitly configured SSL mode or an environment-specific default.
 */
const getSslMode = () => {
  const configured = (process.env.POSTGRES_SSLMODE || "").trim();
  if (configured) {
    return configured;
  }

  return isLocalHost(DB_HOST) ? "" : "require";
};

const sslMode = getSslMode();
const sslModeParam = sslMode ? `&sslmode=${encodeURIComponent(sslMode)}` : "";

const dataSourceURL = `postgresql://${DB_USER}:${DB_PWD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?schema=${DB_SCHEMA}&connection_limit=20${sslModeParam}`;
/**
 * Provides a singleton Prisma client that participates in the Nest lifecycle.
 */
@Injectable()
class PrismaService
  extends PrismaClient<Prisma.PrismaClientOptions, "query">
  implements OnModuleInit, OnModuleDestroy
{
  private logger = new Logger("PRISMA");
  private static instance: PrismaService;

  /**
   * Creates the Prisma client and reuses a singleton instance when available.
   */
  constructor() {
    if (PrismaService.instance) {
      return PrismaService.instance;
    }
    const adapter = new PrismaPg({
      connectionString: dataSourceURL,
    });
    super({
      errorFormat: "pretty",
      adapter,
      log: [
        { emit: "event", level: "query" },
        { emit: "stdout", level: "info" },
        { emit: "stdout", level: "warn" },
        { emit: "stdout", level: "error" },
      ],
    });
    PrismaService.instance = this;
  }

  /**
   * Connects to PostgreSQL and registers slow-query logging once the module starts.
   */
  async onModuleInit() {
    await this.$connect();
    this.logger.log("Connected to PostgreSQL");
    this.$on<any>("query", (e: Prisma.QueryEvent) => {
      // Skip framework and transaction-management chatter to avoid flooding
      // container logs with noise that is already visible in request/dependency telemetry.
      const excludedPatterns = [
        "COMMIT",
        "BEGIN",
        "SELECT 1",
        "DEALLOCATE ALL",
      ];
      if (
        excludedPatterns.some((pattern) =>
          e?.query?.toUpperCase().includes(pattern),
        )
      ) {
        return;
      }

      if (!shouldEmitSlowQueryLog(e.duration)) {
        return;
      }

      emitOperationalStreamLog("warn", "db_slow_query", {
        durationMs: e.duration,
        statement: summarizeSqlStatement(e.query),
        database: DB_NAME,
      });
    });
  }

  /**
   * Closes the Prisma connection pool during module shutdown.
   */
  async onModuleDestroy() {
    this.logger.log("Disconnecting from PostgreSQL");
    await this.$disconnect();
  }
}

export { PrismaService };
