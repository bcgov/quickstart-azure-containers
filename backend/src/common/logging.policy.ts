import * as winston from "winston";

type WinstonLogLevel =
  | "error"
  | "warn"
  | "info"
  | "http"
  | "verbose"
  | "debug"
  | "silly";

export type HttpAccessLogMode = "off" | "failures" | "all";

type OperationalConsoleLogLevel = "info" | "warn" | "error";

const validWinstonLogLevels = new Set<WinstonLogLevel>([
  "error",
  "warn",
  "info",
  "http",
  "verbose",
  "debug",
  "silly",
]);

const validHttpAccessLogModes = new Set<HttpAccessLogMode>([
  "off",
  "failures",
  "all",
]);

function getTrimmedEnv(name: string): string | undefined {
  const value = process.env[name]?.trim();
  return value ? value : undefined;
}

function isProduction(): boolean {
  return (process.env.NODE_ENV ?? "").trim().toLowerCase() === "production";
}

function isWinstonLogLevel(
  value: string | undefined,
): value is WinstonLogLevel {
  return (
    typeof value === "string" &&
    validWinstonLogLevels.has(value as WinstonLogLevel)
  );
}

function isHttpAccessLogMode(
  value: string | undefined,
): value is HttpAccessLogMode {
  return (
    typeof value === "string" &&
    validHttpAccessLogModes.has(value as HttpAccessLogMode)
  );
}

export function getWinstonLogLevel(): WinstonLogLevel {
  const configuredLevel = getTrimmedEnv("LOG_LEVEL")?.toLowerCase();

  if (isWinstonLogLevel(configuredLevel)) {
    return configuredLevel;
  }

  return isProduction() ? "info" : "debug";
}

export function createConsoleLoggerFormat(): winston.Logform.Format {
  if (isProduction()) {
    return winston.format.combine(
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.splat(),
      winston.format.json(),
    );
  }

  return winston.format.combine(
    winston.format.colorize({ all: true }),
    winston.format.timestamp({ format: "YYYY-MM-DD HH:mm:ss.SSS" }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.printf((info) => {
      const { context, level, message, stack, timestamp, ...meta } = info;
      const renderedContext = typeof context === "string" ? context : "Backend";
      const renderedMessage =
        typeof message === "string" ? message : JSON.stringify(message);
      const renderedStack =
        typeof stack === "string" && stack !== renderedMessage
          ? `\n${stack}`
          : "";
      const renderedMeta =
        Object.keys(meta).length > 0 ? ` ${JSON.stringify(meta)}` : "";

      return `${timestamp} [${renderedContext}] ${level}: ${renderedMessage}${renderedMeta}${renderedStack}`;
    }),
  );
}

export function getHttpAccessLogMode(): HttpAccessLogMode {
  const configuredMode = getTrimmedEnv("HTTP_ACCESS_LOG_MODE")?.toLowerCase();

  if (isHttpAccessLogMode(configuredMode)) {
    return configuredMode;
  }

  return isProduction() ? "failures" : "all";
}

export function shouldEmitHttpAccessLog(statusCode: number): boolean {
  const mode = getHttpAccessLogMode();

  if (mode === "off") {
    return false;
  }

  if (mode === "all") {
    return true;
  }

  return statusCode >= 400;
}

export function getSlowQueryLogThresholdMs(): number {
  const configuredThreshold = getTrimmedEnv("DB_SLOW_QUERY_LOG_THRESHOLD_MS");

  if (configuredThreshold) {
    const parsedThreshold = Number.parseInt(configuredThreshold, 10);

    if (!Number.isNaN(parsedThreshold)) {
      return parsedThreshold;
    }
  }

  return isProduction() ? 1000 : 250;
}

export function shouldEmitSlowQueryLog(durationMs: number): boolean {
  const thresholdMs = getSlowQueryLogThresholdMs();
  return thresholdMs >= 0 && durationMs >= thresholdMs;
}

export function summarizeSqlStatement(query: string): string {
  const match = query.trim().match(/^[A-Za-z]+/);
  return match?.[0].toUpperCase() ?? "UNKNOWN";
}

export function emitOperationalConsoleLog(
  level: OperationalConsoleLogLevel,
  event: string,
  fields: Record<string, unknown>,
): void {
  const payload = JSON.stringify({
    timestamp: new Date().toISOString(),
    event,
    ...fields,
  });

  switch (level) {
    case "error":
      console.error(payload);
      return;
    case "warn":
      console.warn(payload);
      return;
    default:
      console.info(payload);
  }
}
