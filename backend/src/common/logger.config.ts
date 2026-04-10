import { LoggerService } from "@nestjs/common";
import { WinstonModule } from "nest-winston";
import * as winston from "winston";

import {
  createApplicationLoggerFormat,
  getWinstonLogLevel,
} from "./logging.policy";

const loggerLevel = getWinstonLogLevel();

/**
 * Shared Nest-compatible Winston logger used for application log events.
 */
export const applicationLogger: LoggerService = WinstonModule.createLogger({
  level: loggerLevel,
  defaultMeta: {
    component: "backend",
  },
  transports: [
    new winston.transports.Console({
      level: loggerLevel,
      format: createApplicationLoggerFormat(),
    }),
  ],
  exitOnError: false,
});
