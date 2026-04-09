import { Injectable, NestMiddleware } from "@nestjs/common";
import { Request, Response, NextFunction } from "express";

import {
  emitOperationalConsoleLog,
  shouldEmitHttpAccessLog,
} from "../common/logging.policy";

type SqlInjectionMatch = {
  path: string;
  rule: string;
  valuePreview: string;
};

const sqlInjectionRules: Array<{ name: string; regex: RegExp }> = [
  {
    name: "boolean_tautology_comment",
    regex:
      /(?:'|"|`)?\s*(?:or|and)\s+(?:'[^']+'|"[^"]+"|\d+)\s*=\s*(?:'[^']+'|"[^"]+"|\d+)\s*(?:--|#|\/\*)/i,
  },
  {
    name: "union_select",
    regex: /\bunion\b[\s\S]{0,40}\bselect\b/i,
  },
  {
    name: "stacked_query",
    regex: /;\s*(?:drop|delete|truncate|insert|update|select)\b/i,
  },
  {
    name: "sql_sleep_or_benchmark",
    regex: /\b(?:sleep|benchmark)\s*\(/i,
  },
];

function decodeCandidate(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

function buildValuePreview(value: string): string {
  return value.length > 160 ? `${value.slice(0, 157)}...` : value;
}

function inspectForSqlInjection(
  value: unknown,
  path: string,
): SqlInjectionMatch | undefined {
  if (typeof value === "string") {
    const decodedValue = decodeCandidate(value);

    for (const rule of sqlInjectionRules) {
      if (rule.regex.test(decodedValue)) {
        return {
          path,
          rule: rule.name,
          valuePreview: buildValuePreview(decodedValue),
        };
      }
    }

    return undefined;
  }

  if (Array.isArray(value)) {
    for (const [index, entry] of value.entries()) {
      const match = inspectForSqlInjection(entry, `${path}[${index}]`);
      if (match) {
        return match;
      }
    }

    return undefined;
  }

  if (value && typeof value === "object") {
    for (const [key, entry] of Object.entries(value)) {
      const match = inspectForSqlInjection(entry, `${path}.${key}`);
      if (match) {
        return match;
      }
    }
  }

  return undefined;
}

@Injectable()
export class HTTPLoggerMiddleware implements NestMiddleware {
  use(request: Request, response: Response, next: NextFunction): void {
    const { method, originalUrl } = request;
    const startedAt = process.hrtime.bigint();
    const clientIp = request.ip || request.get("x-forwarded-for") || "-";

    const sqlInjectionMatch =
      inspectForSqlInjection(request.query, "query") ||
      inspectForSqlInjection(request.body, "body") ||
      inspectForSqlInjection(request.params, "params");

    response.on("finish", () => {
      const { statusCode } = response;
      if (!shouldEmitHttpAccessLog(statusCode)) {
        return;
      }

      const durationMs = Number(
        (process.hrtime.bigint() - startedAt) / 1000000n,
      );
      const contentLength = response.get("content-length") || "-";
      const userAgent = request.get("user-agent") || "-";

      emitOperationalConsoleLog(
        statusCode >= 500 ? "error" : statusCode >= 400 ? "warn" : "info",
        "http_request",
        {
          method,
          url: originalUrl,
          statusCode,
          contentLength,
          durationMs,
          userAgent,
          clientIp,
        },
      );
    });

    if (sqlInjectionMatch) {
      const securityLogFields = {
        indicator: "SQLInjectionAttackDetected",
        message: "SQL injection attack detected",
        method,
        url: originalUrl,
        clientIp,
        source: sqlInjectionMatch.path,
        detectionRule: sqlInjectionMatch.rule,
        valuePreview: sqlInjectionMatch.valuePreview,
      };

      emitOperationalConsoleLog("warn", "security_event", securityLogFields);
      emitOperationalConsoleLog(
        "error",
        "security_event_blocked",
        securityLogFields,
      );

      response.status(400).json({
        statusCode: 400,
        message: "Potential SQL injection payload detected",
      });
      return;
    }

    next();
  }
}
