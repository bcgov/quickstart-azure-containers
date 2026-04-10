import { Test } from "@nestjs/testing";
import { Request, Response } from "express";

import { operationalStreamLogger } from "../common/logging.policy";
import { HTTPLoggerMiddleware } from "./req.res.logger";

describe("HTTPLoggerMiddleware", () => {
  let middleware: HTTPLoggerMiddleware;

  beforeEach(async () => {
    vi.unstubAllEnvs();
    const module = await Test.createTestingModule({
      providers: [HTTPLoggerMiddleware],
    }).compile();

    middleware = module.get<HTTPLoggerMiddleware>(HTTPLoggerMiddleware);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllEnvs();
  });

  it("emits structured access logs for successful requests when enabled", () => {
    vi.stubEnv("HTTP_ACCESS_LOG_MODE", "all");

    const request: Request = {
      method: "GET",
      originalUrl: "/test",
      get: () => "Test User Agent",
      ip: "10.0.0.1",
    } as unknown as Request;

    const response: Response = {
      statusCode: 200,
      get: () => "100",
      on: (event: string, cb: () => void) => {
        if (event === "finish") {
          cb();
        }
      },
    } as unknown as Response;

    const logSpy = vi
      .spyOn(operationalStreamLogger, "log")
      .mockImplementation(() => operationalStreamLogger);

    middleware.use(request, response, () => {});

    expect(logSpy).toHaveBeenCalledTimes(1);
    expect(logSpy).toHaveBeenCalledWith("info", expect.any(String));

    const payload = JSON.parse(String(logSpy.mock.calls[0][1])) as Record<
      string,
      unknown
    >;

    expect(payload).toMatchObject({
      event: "http_request",
      method: "GET",
      url: "/test",
      statusCode: 200,
      contentLength: "100",
      userAgent: "Test User Agent",
      clientIp: "10.0.0.1",
    });
    expect(Number(payload.durationMs)).toBeGreaterThanOrEqual(0);
  });

  it("suppresses successful requests when configured for failures only", () => {
    vi.stubEnv("HTTP_ACCESS_LOG_MODE", "failures");

    const request: Request = {
      method: "GET",
      originalUrl: "/test",
      get: () => "Test User Agent",
    } as unknown as Request;

    const response: Response = {
      statusCode: 200,
      get: () => "100",
      on: (event: string, cb: () => void) => {
        if (event === "finish") {
          cb();
        }
      },
    } as unknown as Response;

    const logSpy = vi
      .spyOn(operationalStreamLogger, "log")
      .mockImplementation(() => operationalStreamLogger);

    middleware.use(request, response, () => {});

    expect(logSpy).not.toHaveBeenCalled();
  });

  it("writes 5xx responses to stderr as operational failures", () => {
    vi.stubEnv("HTTP_ACCESS_LOG_MODE", "failures");

    const request: Request = {
      method: "GET",
      originalUrl: "/broken",
      get: () => "Test User Agent",
    } as unknown as Request;

    const response: Response = {
      statusCode: 503,
      get: () => "100",
      on: (event: string, cb: () => void) => {
        if (event === "finish") {
          cb();
        }
      },
    } as unknown as Response;

    const logSpy = vi
      .spyOn(operationalStreamLogger, "log")
      .mockImplementation(() => operationalStreamLogger);

    middleware.use(request, response, () => {});

    expect(logSpy).toHaveBeenCalledTimes(1);
    expect(logSpy).toHaveBeenCalledWith("error", expect.any(String));

    const payload = JSON.parse(String(logSpy.mock.calls[0][1])) as Record<
      string,
      unknown
    >;
    expect(payload).toMatchObject({
      event: "http_request",
      url: "/broken",
      statusCode: 503,
    });
  });
});
