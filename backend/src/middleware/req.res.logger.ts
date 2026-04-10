import { Injectable, NestMiddleware } from "@nestjs/common";
import { Request, Response, NextFunction } from "express";

import {
  emitOperationalStreamLog,
  shouldEmitHttpAccessLog,
} from "../common/logging.policy";

/**
 * Emits structured access logs for completed HTTP requests.
 */
@Injectable()
export class HTTPLoggerMiddleware implements NestMiddleware {
  /**
   * Registers a response-finish listener and writes the request outcome to the
   * operational log stream when the configured policy allows it.
   *
   * @param request Incoming Express request.
   * @param response Outgoing Express response.
   * @param next Callback that advances execution to the next middleware.
   */
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

      emitOperationalStreamLog(
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
