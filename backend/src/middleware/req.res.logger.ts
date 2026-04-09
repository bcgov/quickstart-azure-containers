import { Injectable, NestMiddleware } from "@nestjs/common";
import { Request, Response, NextFunction } from "express";

import {
  emitOperationalConsoleLog,
  shouldEmitHttpAccessLog,
} from "../common/logging.policy";

@Injectable()
export class HTTPLoggerMiddleware implements NestMiddleware {
  use(request: Request, response: Response, next: NextFunction): void {
    const { method, originalUrl } = request;
    const startedAt = process.hrtime.bigint();

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
      const clientIp = request.ip || request.get("x-forwarded-for") || "-";

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

    next();
  }
}
