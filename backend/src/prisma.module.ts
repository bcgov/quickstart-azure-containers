import { Module } from "@nestjs/common";
import { PrismaService } from "src/prisma.service";

/**
 * Exposes the shared Prisma service to importing modules.
 */
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
