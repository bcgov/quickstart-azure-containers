import { applicationLogger } from "./logger.config";

describe("applicationLogger", () => {
  it("should be defined", () => {
    expect(applicationLogger).toBeDefined();
  });

  it("should log a message", () => {
    const spy = vi.spyOn(applicationLogger, "verbose");
    applicationLogger.verbose("Test message");
    expect(spy).toHaveBeenCalledWith("Test message");
    spy.mockRestore();
  });
});
