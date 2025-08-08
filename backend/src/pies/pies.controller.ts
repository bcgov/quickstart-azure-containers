import {
  Controller,
  Get,
  Post,
  Body,
  Put,
  Param,
  Delete,
  HttpException,
} from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import { PiesService } from "./pies.service";
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

@ApiTags("pies")
@Controller({ path: "pies", version: "1" })
export class PiesController {
  constructor(private readonly piesService: PiesService) {}

  // System endpoints
  @Post("systems")
  createSystem(@Body() createSystemDto: CreateSystemDto): Promise<SystemDto> {
    return this.piesService.createSystem(createSystemDto);
  }

  @Get("systems")
  findAllSystems(): Promise<SystemDto[]> {
    return this.piesService.findAllSystems();
  }

  @Get("systems/:id")
  async findOneSystem(@Param("id") id: string): Promise<SystemDto> {
    const system = await this.piesService.findOneSystem(id);
    if (!system) {
      throw new HttpException("System not found.", 404);
    }
    return system;
  }

  @Put("systems/:id")
  updateSystem(
    @Param("id") id: string,
    @Body() updateSystemDto: UpdateSystemDto,
  ): Promise<SystemDto> {
    return this.piesService.updateSystem(id, updateSystemDto);
  }

  @Delete("systems/:id")
  removeSystem(@Param("id") id: string) {
    return this.piesService.removeSystem(id);
  }

  // Transaction endpoints
  @Post("transactions")
  createTransaction(
    @Body() createTransactionDto: CreateTransactionDto,
  ): Promise<TransactionDto> {
    return this.piesService.createTransaction(createTransactionDto);
  }

  @Get("transactions")
  findAllTransactions(): Promise<TransactionDto[]> {
    return this.piesService.findAllTransactions();
  }

  @Get("transactions/:id")
  async findOneTransaction(@Param("id") id: string): Promise<TransactionDto> {
    const transaction = await this.piesService.findOneTransaction(id);
    if (!transaction) {
      throw new HttpException("Transaction not found.", 404);
    }
    return transaction;
  }

  @Put("transactions/:id")
  updateTransaction(
    @Param("id") id: string,
    @Body() updateTransactionDto: UpdateTransactionDto,
  ): Promise<TransactionDto> {
    return this.piesService.updateTransaction(id, updateTransactionDto);
  }

  @Delete("transactions/:id")
  removeTransaction(@Param("id") id: string) {
    return this.piesService.removeTransaction(id);
  }

  // Version endpoints
  @Post("versions")
  createVersion(
    @Body() createVersionDto: CreateVersionDto,
  ): Promise<VersionDto> {
    return this.piesService.createVersion(createVersionDto);
  }

  @Get("versions")
  findAllVersions(): Promise<VersionDto[]> {
    return this.piesService.findAllVersions();
  }

  @Get("versions/:id")
  async findOneVersion(@Param("id") id: string): Promise<VersionDto> {
    const version = await this.piesService.findOneVersion(id);
    if (!version) {
      throw new HttpException("Version not found.", 404);
    }
    return version;
  }

  @Put("versions/:id")
  updateVersion(
    @Param("id") id: string,
    @Body() updateVersionDto: UpdateVersionDto,
  ): Promise<VersionDto> {
    return this.piesService.updateVersion(id, updateVersionDto);
  }

  @Delete("versions/:id")
  removeVersion(@Param("id") id: string) {
    return this.piesService.removeVersion(id);
  }

  // Coding endpoints
  @Post("codings")
  createCoding(@Body() createCodingDto: CreateCodingDto): Promise<CodingDto> {
    return this.piesService.createCoding(createCodingDto);
  }

  @Get("codings")
  findAllCodings(): Promise<CodingDto[]> {
    return this.piesService.findAllCodings();
  }

  @Get("codings/:id")
  async findOneCoding(@Param("id") id: string): Promise<CodingDto> {
    const coding = await this.piesService.findOneCoding(+id);
    if (!coding) {
      throw new HttpException("Coding not found.", 404);
    }
    return coding;
  }

  @Put("codings/:id")
  updateCoding(
    @Param("id") id: string,
    @Body() updateCodingDto: UpdateCodingDto,
  ): Promise<CodingDto> {
    return this.piesService.updateCoding(+id, updateCodingDto);
  }

  @Delete("codings/:id")
  removeCoding(@Param("id") id: string) {
    return this.piesService.removeCoding(+id);
  }

  // Record Kind endpoints
  @Post("record-kinds")
  createRecordKind(
    @Body() createRecordKindDto: CreateRecordKindDto,
  ): Promise<RecordKindDto> {
    return this.piesService.createRecordKind(createRecordKindDto);
  }

  @Get("record-kinds")
  findAllRecordKinds(): Promise<RecordKindDto[]> {
    return this.piesService.findAllRecordKinds();
  }

  @Get("record-kinds/:id")
  async findOneRecordKind(@Param("id") id: string): Promise<RecordKindDto> {
    const recordKind = await this.piesService.findOneRecordKind(+id);
    if (!recordKind) {
      throw new HttpException("Record kind not found.", 404);
    }
    return recordKind;
  }

  @Put("record-kinds/:id")
  updateRecordKind(
    @Param("id") id: string,
    @Body() updateRecordKindDto: UpdateRecordKindDto,
  ): Promise<RecordKindDto> {
    return this.piesService.updateRecordKind(+id, updateRecordKindDto);
  }

  @Delete("record-kinds/:id")
  removeRecordKind(@Param("id") id: string) {
    return this.piesService.removeRecordKind(+id);
  }

  // System Record endpoints
  @Post("system-records")
  createSystemRecord(
    @Body() createSystemRecordDto: CreateSystemRecordDto,
  ): Promise<SystemRecordDto> {
    return this.piesService.createSystemRecord(createSystemRecordDto);
  }

  @Get("system-records")
  findAllSystemRecords(): Promise<SystemRecordDto[]> {
    return this.piesService.findAllSystemRecords();
  }

  @Get("system-records/:id")
  async findOneSystemRecord(@Param("id") id: string): Promise<SystemRecordDto> {
    const systemRecord = await this.piesService.findOneSystemRecord(+id);
    if (!systemRecord) {
      throw new HttpException("System record not found.", 404);
    }
    return systemRecord;
  }

  @Put("system-records/:id")
  updateSystemRecord(
    @Param("id") id: string,
    @Body() updateSystemRecordDto: UpdateSystemRecordDto,
  ): Promise<SystemRecordDto> {
    return this.piesService.updateSystemRecord(+id, updateSystemRecordDto);
  }

  @Delete("system-records/:id")
  removeSystemRecord(@Param("id") id: string) {
    return this.piesService.removeSystemRecord(+id);
  }

  // Process Event endpoints
  @Post("process-events")
  createProcessEvent(
    @Body() createProcessEventDto: CreateProcessEventDto,
  ): Promise<ProcessEventDto> {
    return this.piesService.createProcessEvent(createProcessEventDto);
  }

  @Get("process-events")
  findAllProcessEvents(): Promise<ProcessEventDto[]> {
    return this.piesService.findAllProcessEvents();
  }

  @Get("process-events/:id")
  async findOneProcessEvent(@Param("id") id: string): Promise<ProcessEventDto> {
    const processEvent = await this.piesService.findOneProcessEvent(+id);
    if (!processEvent) {
      throw new HttpException("Process event not found.", 404);
    }
    return processEvent;
  }

  @Put("process-events/:id")
  updateProcessEvent(
    @Param("id") id: string,
    @Body() updateProcessEventDto: UpdateProcessEventDto,
  ): Promise<ProcessEventDto> {
    return this.piesService.updateProcessEvent(+id, updateProcessEventDto);
  }

  @Delete("process-events/:id")
  removeProcessEvent(@Param("id") id: string) {
    return this.piesService.removeProcessEvent(+id);
  }

  // Record Linkage endpoints
  @Post("record-linkages")
  createRecordLinkage(
    @Body() createRecordLinkageDto: CreateRecordLinkageDto,
  ): Promise<RecordLinkageDto> {
    return this.piesService.createRecordLinkage(createRecordLinkageDto);
  }

  @Get("record-linkages")
  findAllRecordLinkages(): Promise<RecordLinkageDto[]> {
    return this.piesService.findAllRecordLinkages();
  }

  @Get("record-linkages/:id")
  async findOneRecordLinkage(
    @Param("id") id: string,
  ): Promise<RecordLinkageDto> {
    const recordLinkage = await this.piesService.findOneRecordLinkage(+id);
    if (!recordLinkage) {
      throw new HttpException("Record linkage not found.", 404);
    }
    return recordLinkage;
  }

  @Put("record-linkages/:id")
  updateRecordLinkage(
    @Param("id") id: string,
    @Body() updateRecordLinkageDto: UpdateRecordLinkageDto,
  ): Promise<RecordLinkageDto> {
    return this.piesService.updateRecordLinkage(+id, updateRecordLinkageDto);
  }

  @Delete("record-linkages/:id")
  removeRecordLinkage(@Param("id") id: string) {
    return this.piesService.removeRecordLinkage(+id);
  }
}
