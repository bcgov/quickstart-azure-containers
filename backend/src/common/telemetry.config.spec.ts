import { ATTR_SERVICE_NAME } from "@opentelemetry/semantic-conventions";
import { ATTR_SERVICE_INSTANCE_ID } from "@opentelemetry/semantic-conventions/incubating";

import {
  createAzureMonitorOptions,
  defaultServiceName,
  getServiceName,
} from "./telemetry.config";

describe("telemetry config", () => {
  const envKeys = [
    "OTEL_SERVICE_NAME",
    "CONTAINER_APP_NAME",
    "WEBSITE_SITE_NAME",
    "HOSTNAME",
  ] as const;

  beforeEach(() => {
    vi.unstubAllEnvs();
    for (const key of envKeys) {
      vi.stubEnv(key, undefined);
    }
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("enables winston log export", () => {
    const options = createAzureMonitorOptions();

    expect(options.enableTraceBasedSamplingForLogs).toBe(true);
    expect(options.instrumentationOptions?.winston?.enabled).toBe(true);
  });

  it("prefers configured service names before the default", () => {
    vi.stubEnv("OTEL_SERVICE_NAME", "explicit-service");
    expect(getServiceName()).toBe("explicit-service");

    vi.stubEnv("OTEL_SERVICE_NAME", undefined);
    vi.stubEnv("CONTAINER_APP_NAME", "container-app-service");
    expect(getServiceName()).toBe("container-app-service");

    vi.stubEnv("CONTAINER_APP_NAME", undefined);
    vi.stubEnv("WEBSITE_SITE_NAME", "app-service-site");
    expect(getServiceName()).toBe("app-service-site");

    vi.stubEnv("WEBSITE_SITE_NAME", undefined);
    expect(getServiceName()).toBe(defaultServiceName);
  });

  it("uses the host name for the service instance id when available", () => {
    vi.stubEnv("HOSTNAME", "replica-1");

    const options = createAzureMonitorOptions();

    expect(options.resource?.attributes[ATTR_SERVICE_NAME]).toBe(
      defaultServiceName,
    );
    expect(options.resource?.attributes[ATTR_SERVICE_INSTANCE_ID]).toBe(
      "replica-1",
    );
  });
});
