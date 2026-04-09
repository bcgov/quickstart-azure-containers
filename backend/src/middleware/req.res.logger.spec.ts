import { Test } from "@nestjs/testing";
import { Request, Response } from "express";

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

    const infoSpy = vi
      .spyOn(console, "info")
      .mockImplementation(() => undefined);

    middleware.use(request, response, () => {});

    expect(infoSpy).toHaveBeenCalledTimes(1);

    const payload = JSON.parse(String(infoSpy.mock.calls[0][0])) as Record<
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

    const infoSpy = vi
      .spyOn(console, "info")
      .mockImplementation(() => undefined);
    const warnSpy = vi
      .spyOn(console, "warn")
      .mockImplementation(() => undefined);
    const errorSpy = vi
      .spyOn(console, "error")
      .mockImplementation(() => undefined);

    middleware.use(request, response, () => {});

    expect(infoSpy).not.toHaveBeenCalled();
    expect(warnSpy).not.toHaveBeenCalled();
    expect(errorSpy).not.toHaveBeenCalled();
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

    const errorSpy = vi
      .spyOn(console, "error")
      .mockImplementation(() => undefined);

    middleware.use(request, response, () => {});

    expect(errorSpy).toHaveBeenCalledTimes(1);

    const payload = JSON.parse(String(errorSpy.mock.calls[0][0])) as Record<
      string,
      unknown
    >;
    expect(payload).toMatchObject({
      event: "http_request",
      url: "/broken",
      statusCode: 503,
    });
  });

  it("blocks obvious SQL injection payloads with a 400 and emits security logs", () => {
    vi.stubEnv("HTTP_ACCESS_LOG_MODE", "failures");

    const request: Request = {
      method: "GET",
      originalUrl:
        "/users/search?page=1&limit=10&filter=%27%20OR%201%3D1%20--",
      query: {
        page: "1",
        limit: "10",
        filter: "' OR 1=1 --",
      },
      params: {},
      body: undefined,
      get: () => "Test User Agent",
      ip: "10.0.0.5",
    } as unknown as Request;

    let finishHandler: (() => void) | undefined;
    const jsonSpy = vi.fn();
    const statusSpy = vi.fn().mockImplementation(() => response);
    const response: Response = {
      get: () => "-",
      on: (event: string, cb: () => void) => {
        if (event === "finish") {
          finishHandler = cb;
        }
      },
      status: statusSpy,
      json: jsonSpy,
    } as unknown as Response;

    const warnSpy = vi
      .spyOn(console, "warn")
      .mockImplementation(() => undefined);
    const errorSpy = vi
      .spyOn(console, "error")
      .mockImplementation(() => undefined);
    const next = vi.fn();

    middleware.use(request, response, next);

    expect(next).not.toHaveBeenCalled();
    expect(statusSpy).toHaveBeenCalledWith(400);
    expect(jsonSpy).toHaveBeenCalledWith({
      statusCode: 400,
      message: "Potential SQL injection payload detected",
    });
    expect(warnSpy).toHaveBeenCalledTimes(1);
    expect(errorSpy).toHaveBeenCalledTimes(1);

    const warningPayload = JSON.parse(
      String(warnSpy.mock.calls[0][0]),
    ) as Record<string, unknown>;
    const errorPayload = JSON.parse(
      String(errorSpy.mock.calls[0][0]),
    ) as Record<string, unknown>;

    expect(warningPayload).toMatchObject({
      event: "security_event",
      indicator: "SQLInjectionAttackDetected",
      message: "SQL injection attack detected",
      source: "query.filter",
    });
    expect(errorPayload).toMatchObject({
      event: "security_event_blocked",
      indicator: "SQLInjectionAttackDetected",
      message: "SQL injection attack detected",
      source: "query.filter",
    });
    expect(finishHandler).toBeDefined();
  });
});
