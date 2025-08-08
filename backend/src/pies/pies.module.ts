import { Module } from "@nestjs/common";
import { PiesService } from "./pies.service";
import { PiesController } from "./pies.controller";
import { PrismaService } from "../prisma.service";

@Module({
  controllers: [PiesController],
  providers: [PiesService, PrismaService],
})
export class PiesModule {}
