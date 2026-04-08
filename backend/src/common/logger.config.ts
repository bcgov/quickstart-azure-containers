import { LoggerService } from "@nestjs/common";
import { WinstonModule } from "nest-winston";
import * as winston from "winston";

import {
  createConsoleLoggerFormat,
  getWinstonLogLevel,
} from "./logging.policy";

const loggerLevel = getWinstonLogLevel();

export const customLogger: LoggerService = WinstonModule.createLogger({
  level: loggerLevel,
  defaultMeta: {
    component: "backend",
  },
  transports: [
    new winston.transports.Console({
      level: loggerLevel,
      format: createConsoleLoggerFormat(),
    }),
  ],
  exitOnError: false,
});
