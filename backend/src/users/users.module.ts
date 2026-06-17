import { Module } from "@nestjs/common";

import { PrismaModule } from "../prisma.module";

import { UsersController } from "./users.controller";
import { UsersService } from "./users.service";

/**
 * Registers the user controller and service with database access.
 */
@Module({
  controllers: [UsersController],
  providers: [UsersService],
  imports: [PrismaModule],
})
export class UsersModule {}
