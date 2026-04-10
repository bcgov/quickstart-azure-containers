import { Controller, Get, Res } from "@nestjs/common";
import { Response } from "express";
import { register } from "src/middleware/prom";

/**
 * Exposes Prometheus-formatted application metrics.
 */
@Controller("metrics")
export class MetricsController {
  /**
   * Writes the latest metrics snapshot to the HTTP response.
   *
   * @param res Express response used to send the metrics payload.
   */
  @Get()
  async getMetrics(@Res() res: Response) {
    const appMetrics = await register.metrics();
    res.end(appMetrics);
  }
}
