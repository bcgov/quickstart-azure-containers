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

@Module({
  imports: [ConfigModule.forRoot(), TerminusModule, UsersModule],
  controllers: [AppController, MetricsController, HealthController],
  providers: [AppService, PrismaService, UsersService],
})
export class AppModule {
  // let's add a middleware on all routes
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
