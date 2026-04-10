import { Injectable } from "@nestjs/common";

/**
 * Provides basic application-level responses.
 */
@Injectable()
export class AppService {
  /**
   * Returns the default welcome message for the backend.
   *
   * @returns Static greeting text.
   */
  getHello(): string {
    return "Hello Backend!";
  }
}
