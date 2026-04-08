import { ATTR_SERVICE_NAME } from "@opentelemetry/semantic-conventions";
import { ATTR_SERVICE_INSTANCE_ID } from "@opentelemetry/semantic-conventions/incubating";

import {
  createAzureMonitorOptions,
  defaultServiceName,
  getServiceName,
} from "./telemetry.config";

describe("telemetry config", () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
    delete process.env.OTEL_SERVICE_NAME;
    delete process.env.CONTAINER_APP_NAME;
    delete process.env.WEBSITE_SITE_NAME;
    delete process.env.HOSTNAME;
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it("enables winston log export", () => {
    const options = createAzureMonitorOptions();

    expect(options.enableTraceBasedSamplingForLogs).toBe(true);
    expect(options.instrumentationOptions?.winston?.enabled).toBe(true);
  });

  it("prefers configured service names before the default", () => {
    process.env.OTEL_SERVICE_NAME = "explicit-service";
    expect(getServiceName()).toBe("explicit-service");

    delete process.env.OTEL_SERVICE_NAME;
    process.env.CONTAINER_APP_NAME = "container-app-service";
    expect(getServiceName()).toBe("container-app-service");

    delete process.env.CONTAINER_APP_NAME;
    process.env.WEBSITE_SITE_NAME = "app-service-site";
    expect(getServiceName()).toBe("app-service-site");

    delete process.env.WEBSITE_SITE_NAME;
    expect(getServiceName()).toBe(defaultServiceName);
  });

  it("uses the host name for the service instance id when available", () => {
    process.env.HOSTNAME = "replica-1";

    const options = createAzureMonitorOptions();

    expect(options.resource?.attributes[ATTR_SERVICE_NAME]).toBe(
      defaultServiceName,
    );
    expect(options.resource?.attributes[ATTR_SERVICE_INSTANCE_ID]).toBe(
      "replica-1",
    );
  });
});
