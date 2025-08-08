import { Injectable } from "@nestjs/common";
import { PrismaService } from "../prisma.service";
import { CreateSystemDto, UpdateSystemDto, SystemDto } from "./dto/system.dto";
import {
  CreateTransactionDto,
  UpdateTransactionDto,
  TransactionDto,
} from "./dto/transaction.dto";
import {
  CreateVersionDto,
  UpdateVersionDto,
  VersionDto,
} from "./dto/version.dto";
import { CreateCodingDto, UpdateCodingDto, CodingDto } from "./dto/coding.dto";
import {
  CreateRecordKindDto,
  UpdateRecordKindDto,
  RecordKindDto,
} from "./dto/record-kind.dto";
import {
  CreateSystemRecordDto,
  UpdateSystemRecordDto,
  SystemRecordDto,
} from "./dto/system-record.dto";
import {
  CreateProcessEventDto,
  UpdateProcessEventDto,
  ProcessEventDto,
} from "./dto/process-event.dto";
import {
  CreateRecordLinkageDto,
  UpdateRecordLinkageDto,
  RecordLinkageDto,
} from "./dto/record-linkage.dto";

@Injectable()
export class PiesService {
  constructor(private prisma: PrismaService) {}

  // System methods
  async createSystem(createSystemDto: CreateSystemDto): Promise<SystemDto> {
    const system = await this.prisma.system.create({
      data: createSystemDto,
    });
    return system;
  }

  async findAllSystems(): Promise<SystemDto[]> {
    return this.prisma.system.findMany();
  }

  async findOneSystem(id: string): Promise<SystemDto> {
    return this.prisma.system.findUnique({
      where: { id },
    });
  }

  async updateSystem(
    id: string,
    updateSystemDto: UpdateSystemDto,
  ): Promise<SystemDto> {
    return this.prisma.system.update({
      where: { id },
      data: updateSystemDto,
    });
  }

  async removeSystem(
    id: string,
  ): Promise<{ deleted: boolean; message?: string }> {
    try {
      await this.prisma.system.delete({
        where: { id },
      });
      return { deleted: true };
    } catch (err) {
      return { deleted: false, message: err.message };
    }
  }

  // Transaction methods
  async createTransaction(
    createTransactionDto: CreateTransactionDto,
  ): Promise<TransactionDto> {
    const transaction = await this.prisma.transaction.create({
      data: createTransactionDto,
    });
    return transaction;
  }

  async findAllTransactions(): Promise<TransactionDto[]> {
    return this.prisma.transaction.findMany();
  }

  async findOneTransaction(id: string): Promise<TransactionDto> {
    return this.prisma.transaction.findUnique({
      where: { id },
    });
  }

  async updateTransaction(
    id: string,
    updateTransactionDto: UpdateTransactionDto,
  ): Promise<TransactionDto> {
    return this.prisma.transaction.update({
      where: { id },
      data: updateTransactionDto,
    });
  }

  async removeTransaction(
    id: string,
  ): Promise<{ deleted: boolean; message?: string }> {
    try {
      await this.prisma.transaction.delete({
        where: { id },
      });
      return { deleted: true };
    } catch (err) {
      return { deleted: false, message: err.message };
    }
  }

  // Version methods
  async createVersion(createVersionDto: CreateVersionDto): Promise<VersionDto> {
    const version = await this.prisma.version.create({
      data: createVersionDto,
    });
    return version;
  }

  async findAllVersions(): Promise<VersionDto[]> {
    return this.prisma.version.findMany();
  }

  async findOneVersion(id: string): Promise<VersionDto> {
    return this.prisma.version.findUnique({
      where: { id },
    });
  }

  async updateVersion(
    id: string,
    updateVersionDto: UpdateVersionDto,
  ): Promise<VersionDto> {
    return this.prisma.version.update({
      where: { id },
      data: updateVersionDto,
    });
  }

  async removeVersion(
    id: string,
  ): Promise<{ deleted: boolean; message?: string }> {
    try {
      await this.prisma.version.delete({
        where: { id },
      });
      return { deleted: true };
    } catch (err) {
      return { deleted: false, message: err.message };
    }
  }

  // Coding methods
  async createCoding(createCodingDto: CreateCodingDto): Promise<CodingDto> {
    const coding = await this.prisma.coding.create({
      data: createCodingDto,
    });
    return coding;
  }

  async findAllCodings(): Promise<CodingDto[]> {
    return this.prisma.coding.findMany();
  }

  async findOneCoding(id: number): Promise<CodingDto> {
    return this.prisma.coding.findUnique({
      where: { id },
    });
  }

  async updateCoding(
    id: number,
    updateCodingDto: UpdateCodingDto,
  ): Promise<CodingDto> {
    return this.prisma.coding.update({
      where: { id },
      data: updateCodingDto,
    });
  }

  async removeCoding(
    id: number,
  ): Promise<{ deleted: boolean; message?: string }> {
    try {
      await this.prisma.coding.delete({
        where: { id },
      });
      return { deleted: true };
    } catch (err) {
      return { deleted: false, message: err.message };
    }
  }

  // Record Kind methods
  async createRecordKind(
    createRecordKindDto: CreateRecordKindDto,
  ): Promise<RecordKindDto> {
    const recordKind = await this.prisma.record_kind.create({
      data: createRecordKindDto,
    });
    return recordKind;
  }

  async findAllRecordKinds(): Promise<RecordKindDto[]> {
    return this.prisma.record_kind.findMany();
  }

  async findOneRecordKind(id: number): Promise<RecordKindDto> {
    return this.prisma.record_kind.findUnique({
      where: { id },
    });
  }

  async updateRecordKind(
    id: number,
    updateRecordKindDto: UpdateRecordKindDto,
  ): Promise<RecordKindDto> {
    return this.prisma.record_kind.update({
      where: { id },
      data: updateRecordKindDto,
    });
  }

  async removeRecordKind(
    id: number,
  ): Promise<{ deleted: boolean; message?: string }> {
    try {
      await this.prisma.record_kind.delete({
        where: { id },
      });
      return { deleted: true };
    } catch (err) {
      return { deleted: false, message: err.message };
    }
  }

  // System Record methods
  async createSystemRecord(
    createSystemRecordDto: CreateSystemRecordDto,
  ): Promise<SystemRecordDto> {
    const systemRecord = await this.prisma.system_record.create({
      data: createSystemRecordDto,
    });
    return systemRecord;
  }

  async findAllSystemRecords(): Promise<SystemRecordDto[]> {
    return this.prisma.system_record.findMany();
  }

  async findOneSystemRecord(id: number): Promise<SystemRecordDto> {
    return this.prisma.system_record.findUnique({
      where: { id },
    });
  }

  async updateSystemRecord(
    id: number,
    updateSystemRecordDto: UpdateSystemRecordDto,
  ): Promise<SystemRecordDto> {
    return this.prisma.system_record.update({
      where: { id },
      data: updateSystemRecordDto,
    });
  }

  async removeSystemRecord(
    id: number,
  ): Promise<{ deleted: boolean; message?: string }> {
    try {
      await this.prisma.system_record.delete({
        where: { id },
      });
      return { deleted: true };
    } catch (err) {
      return { deleted: false, message: err.message };
    }
  }

  // Process Event methods
  async createProcessEvent(
    createProcessEventDto: CreateProcessEventDto,
  ): Promise<ProcessEventDto> {
    const processEvent = await this.prisma.process_event.create({
      data: createProcessEventDto,
    });
    return processEvent;
  }

  async findAllProcessEvents(): Promise<ProcessEventDto[]> {
    return this.prisma.process_event.findMany();
  }

  async findOneProcessEvent(id: number): Promise<ProcessEventDto> {
    return this.prisma.process_event.findUnique({
      where: { id },
    });
  }

  async updateProcessEvent(
    id: number,
    updateProcessEventDto: UpdateProcessEventDto,
  ): Promise<ProcessEventDto> {
    return this.prisma.process_event.update({
      where: { id },
      data: updateProcessEventDto,
    });
  }

  async removeProcessEvent(
    id: number,
  ): Promise<{ deleted: boolean; message?: string }> {
    try {
      await this.prisma.process_event.delete({
        where: { id },
      });
      return { deleted: true };
    } catch (err) {
      return { deleted: false, message: err.message };
    }
  }

  // Record Linkage methods
  async createRecordLinkage(
    createRecordLinkageDto: CreateRecordLinkageDto,
  ): Promise<RecordLinkageDto> {
    const recordLinkage = await this.prisma.record_linkage.create({
      data: createRecordLinkageDto,
    });
    return recordLinkage;
  }

  async findAllRecordLinkages(): Promise<RecordLinkageDto[]> {
    return this.prisma.record_linkage.findMany();
  }

  async findOneRecordLinkage(id: number): Promise<RecordLinkageDto> {
    return this.prisma.record_linkage.findUnique({
      where: { id },
    });
  }

  async updateRecordLinkage(
    id: number,
    updateRecordLinkageDto: UpdateRecordLinkageDto,
  ): Promise<RecordLinkageDto> {
    return this.prisma.record_linkage.update({
      where: { id },
      data: updateRecordLinkageDto,
    });
  }

  async removeRecordLinkage(
    id: number,
  ): Promise<{ deleted: boolean; message?: string }> {
    try {
      await this.prisma.record_linkage.delete({
        where: { id },
      });
      return { deleted: true };
    } catch (err) {
      return { deleted: false, message: err.message };
    }
  }
}
