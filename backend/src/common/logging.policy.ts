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

type OperationalStreamLogLevel = "info" | "warn" | "error";

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

/**
 * Reads an environment variable and removes surrounding whitespace.
 *
 * @param name Name of the environment variable to inspect.
 * @returns Trimmed value when present, otherwise `undefined`.
 */
function getTrimmedEnv(name: string): string | undefined {
  const value = process.env[name]?.trim();
  return value ? value : undefined;
}

/**
 * Indicates whether the current process is running in production mode.
 *
 * @returns `true` when `NODE_ENV` is `production`.
 */
function isProduction(): boolean {
  return (process.env.NODE_ENV ?? "").trim().toLowerCase() === "production";
}

/**
 * Validates that a string is one of Winston's supported log levels.
 *
 * @param value Candidate log level value.
 * @returns Whether the provided value is a valid Winston log level.
 */
function isWinstonLogLevel(
  value: string | undefined,
): value is WinstonLogLevel {
  return (
    typeof value === "string" &&
    validWinstonLogLevels.has(value as WinstonLogLevel)
  );
}

/**
 * Validates that a string matches the supported HTTP access log modes.
 *
 * @param value Candidate HTTP access log mode.
 * @returns Whether the provided value is a supported mode.
 */
function isHttpAccessLogMode(
  value: string | undefined,
): value is HttpAccessLogMode {
  return (
    typeof value === "string" &&
    validHttpAccessLogModes.has(value as HttpAccessLogMode)
  );
}

/**
 * Resolves the effective Winston log level for application logs.
 *
 * @returns Configured log level or the environment-specific default.
 */
export function getWinstonLogLevel(): WinstonLogLevel {
  const configuredLevel = getTrimmedEnv("LOG_LEVEL")?.toLowerCase();

  if (isWinstonLogLevel(configuredLevel)) {
    return configuredLevel;
  }

  return isProduction() ? "info" : "debug";
}

/**
 * Creates the formatter used by the application logger's console transport.
 *
 * @returns JSON formatting in production and colorized text formatting locally.
 */
export function createApplicationLoggerFormat(): winston.Logform.Format {
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

/**
 * Resolves how HTTP access logs should be emitted.
 *
 * @returns Effective access log mode for the current environment.
 */
export function getHttpAccessLogMode(): HttpAccessLogMode {
  const configuredMode = getTrimmedEnv("HTTP_ACCESS_LOG_MODE")?.toLowerCase();

  if (isHttpAccessLogMode(configuredMode)) {
    return configuredMode;
  }

  return isProduction() ? "failures" : "all";
}

/**
 * Determines whether a response status code should be emitted to the access log.
 *
 * @param statusCode HTTP response status code.
 * @returns Whether the request should be logged.
 */
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

/**
 * Resolves the minimum query duration that qualifies as a slow query.
 *
 * @returns Threshold in milliseconds.
 */
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

/**
 * Determines whether a query duration should be emitted as a slow-query event.
 *
 * @param durationMs Query duration in milliseconds.
 * @returns Whether the query exceeds the configured slow-query threshold.
 */
export function shouldEmitSlowQueryLog(durationMs: number): boolean {
  const thresholdMs = getSlowQueryLogThresholdMs();
  return thresholdMs >= 0 && durationMs >= thresholdMs;
}

/**
 * Extracts the leading SQL verb from a query for compact log output.
 *
 * @param query SQL statement text.
 * @returns Uppercase operation name, or `UNKNOWN` when it cannot be inferred.
 */
export function summarizeSqlStatement(query: string): string {
  const match = query.trim().match(/^[A-Za-z]+/);
  return match?.[0].toUpperCase() ?? "UNKNOWN";
}

/**
 * Console-backed logger that writes structured operational events to stdout or stderr.
 */
export const operationalStreamLogger = winston.createLogger({
  level: "info",
  transports: [
    new winston.transports.Console({
      format: winston.format.printf(({ message }) => String(message)),
      stderrLevels: ["warn", "error"],
    }),
  ],
  exitOnError: false,
});

/**
 * Emits a structured operational event as a single JSON log line.
 *
 * @param level Severity used for the log transport.
 * @param event Stable event name describing the operational signal.
 * @param fields Additional event-specific fields to include in the payload.
 */
export function emitOperationalStreamLog(
  level: OperationalStreamLogLevel,
  event: string,
  fields: Record<string, unknown>,
): void {
  const payload = JSON.stringify({
    timestamp: new Date().toISOString(),
    event,
    ...fields,
  });

  operationalStreamLogger.log(level, payload);
}
