import { Controller, Get } from "@nestjs/common";

import { AppService } from "./app.service";

/**
 * Exposes the root API endpoints used for basic service verification.
 */
@Controller()
export class AppController {
  /**
   * Creates the controller with the application service.
   *
   * @param appService Service that provides the default greeting response.
   */
  constructor(private readonly appService: AppService) {}

  /**
   * Returns the default greeting for the root endpoint.
   *
   * @returns Greeting text for the service root.
   */
  @Get()
  getHello(): string {
    return this.appService.getHello();
  }
}
