import { MiddlewareConsumer, Module, RequestMethod } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { TerminusModule } from "@nestjs/terminus";
import "dotenv/config";
import { PrismaService } from "src/prisma.service";

import { AppController } from "./app.controller";
import { AppService } from "./app.service";
import { HealthController } from "./health.controller";
import { MetricsController } from "./metrics.controller";
import { HTTPLoggerMiddleware } from "./middleware/req.res.logger";
import { UsersModule } from "./users/users.module";
import { UsersService } from "./users/users.service";

/**
 * Configures the top-level NestJS module for the backend service.
 */
@Module({
  imports: [ConfigModule.forRoot(), TerminusModule, UsersModule],
  controllers: [AppController, MetricsController, HealthController],
  providers: [AppService, PrismaService, UsersService],
})
export class AppModule {
  // let's add a middleware on all routes
  /**
   * Registers request logging middleware for application routes while excluding
   * health and metrics endpoints from routine access logging.
   *
   * @param consumer Middleware consumer used to bind the HTTP logger.
   */
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(HTTPLoggerMiddleware)
      .exclude(
        { path: "metrics", method: RequestMethod.ALL },
        { path: "health", method: RequestMethod.ALL },
      )
      .forRoutes("{*path}");
  }
}
