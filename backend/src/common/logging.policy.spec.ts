import {
  getHttpAccessLogMode,
  getSlowQueryLogThresholdMs,
  getWinstonLogLevel,
  shouldEmitHttpAccessLog,
  shouldEmitSlowQueryLog,
  summarizeSqlStatement,
} from "./logging.policy";

describe("logging policy", () => {
  beforeEach(() => {
    vi.unstubAllEnvs();
    vi.stubEnv("NODE_ENV", "test");
    vi.stubEnv("LOG_LEVEL", undefined);
    vi.stubEnv("HTTP_ACCESS_LOG_MODE", undefined);
    vi.stubEnv("DB_SLOW_QUERY_LOG_THRESHOLD_MS", undefined);
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("uses debug logging outside production by default", () => {
    expect(getWinstonLogLevel()).toBe("debug");
  });

  it("honours valid log level overrides", () => {
    vi.stubEnv("LOG_LEVEL", "warn");

    expect(getWinstonLogLevel()).toBe("warn");
  });

  it("defaults HTTP access logging to all outside production", () => {
    expect(getHttpAccessLogMode()).toBe("all");
    expect(shouldEmitHttpAccessLog(200)).toBe(true);
  });

  it("suppresses all HTTP access logs in off mode", () => {
    vi.stubEnv("HTTP_ACCESS_LOG_MODE", "off");

    expect(shouldEmitHttpAccessLog(200)).toBe(false);
    expect(shouldEmitHttpAccessLog(500)).toBe(false);
  });

  it("supports failures-only HTTP access logging", () => {
    vi.stubEnv("HTTP_ACCESS_LOG_MODE", "failures");

    expect(shouldEmitHttpAccessLog(200)).toBe(false);
    expect(shouldEmitHttpAccessLog(500)).toBe(true);
  });

  it("defaults slow query detection to 250ms outside production", () => {
    expect(getSlowQueryLogThresholdMs()).toBe(250);
    expect(shouldEmitSlowQueryLog(249)).toBe(false);
    expect(shouldEmitSlowQueryLog(250)).toBe(true);
  });

  it("can disable slow query logging with a negative threshold", () => {
    vi.stubEnv("DB_SLOW_QUERY_LOG_THRESHOLD_MS", "-1");

    expect(shouldEmitSlowQueryLog(5000)).toBe(false);
  });

  it("extracts the SQL verb for operational slow query logs", () => {
    expect(summarizeSqlStatement(" select * from users where id = $1")).toBe(
      "SELECT",
    );
  });

  describe("production defaults", () => {
    beforeEach(() => {
      vi.stubEnv("NODE_ENV", "production");
    });

    it("uses info logging in production by default", () => {
      expect(getWinstonLogLevel()).toBe("info");
    });

    it("defaults HTTP access logging to failures in production", () => {
      expect(getHttpAccessLogMode()).toBe("failures");
    });

    it("defaults slow query threshold to 1000ms in production", () => {
      expect(getSlowQueryLogThresholdMs()).toBe(1000);
    });
  });
});
