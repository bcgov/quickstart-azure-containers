import type { TestingModule } from "@nestjs/testing";
import { Test } from "@nestjs/testing";
import { PiesService } from "./pies.service";
import { PrismaService } from "../prisma.service";

describe("PiesService", () => {
  let service: PiesService;
  let prisma: PrismaService;

  const mockSystem = {
    id: "HEALTH_SYSTEM_BC",
    created_at: new Date("2024-01-01T00:00:00.000Z"),
    updated_at: new Date("2024-01-01T00:00:00.000Z"),
    created_by: "admin@example.com",
    updated_by: "admin@example.com",
  };

  const mockTransaction = {
    id: "123e4567-e89b-12d3-a456-426614174000",
    created_at: new Date("2024-01-01T00:00:00.000Z"),
    updated_at: new Date("2024-01-01T00:00:00.000Z"),
    created_by: "admin@example.com",
    updated_by: "admin@example.com",
  };

  const mockVersion = {
    id: "v1.0.0",
    created_at: new Date("2024-01-01T00:00:00.000Z"),
    updated_at: new Date("2024-01-01T00:00:00.000Z"),
    created_by: "admin@example.com",
    updated_by: "admin@example.com",
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PiesService,
        {
          provide: PrismaService,
          useValue: {
            system: {
              create: vi.fn(),
              findMany: vi.fn(),
              findUnique: vi.fn(),
              update: vi.fn(),
              delete: vi.fn(),
            },
            transaction: {
              create: vi.fn(),
              findMany: vi.fn(),
              findUnique: vi.fn(),
              update: vi.fn(),
              delete: vi.fn(),
            },
            version: {
              create: vi.fn(),
              findMany: vi.fn(),
              findUnique: vi.fn(),
              update: vi.fn(),
              delete: vi.fn(),
            },
            coding: {
              create: vi.fn(),
              findMany: vi.fn(),
              findUnique: vi.fn(),
              update: vi.fn(),
              delete: vi.fn(),
            },
            record_kind: {
              create: vi.fn(),
              findMany: vi.fn(),
              findUnique: vi.fn(),
              update: vi.fn(),
              delete: vi.fn(),
            },
            system_record: {
              create: vi.fn(),
              findMany: vi.fn(),
              findUnique: vi.fn(),
              update: vi.fn(),
              delete: vi.fn(),
            },
            process_event: {
              create: vi.fn(),
              findMany: vi.fn(),
              findUnique: vi.fn(),
              update: vi.fn(),
              delete: vi.fn(),
            },
            record_linkage: {
              create: vi.fn(),
              findMany: vi.fn(),
              findUnique: vi.fn(),
              update: vi.fn(),
              delete: vi.fn(),
            },
          },
        },
      ],
    }).compile();

    service = module.get<PiesService>(PiesService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  describe("System operations", () => {
    it("should create a system", async () => {
      const createSystemDto = {
        id: "HEALTH_SYSTEM_BC",
        created_by: "admin@example.com",
      };

      vi.spyOn(prisma.system, "create").mockResolvedValue(mockSystem);

      const result = await service.createSystem(createSystemDto);

      expect(prisma.system.create).toHaveBeenCalledWith({
        data: createSystemDto,
      });
      expect(result).toEqual(mockSystem);
    });

    it("should find all systems", async () => {
      vi.spyOn(prisma.system, "findMany").mockResolvedValue([mockSystem]);

      const result = await service.findAllSystems();

      expect(prisma.system.findMany).toHaveBeenCalled();
      expect(result).toEqual([mockSystem]);
    });

    it("should find one system", async () => {
      vi.spyOn(prisma.system, "findUnique").mockResolvedValue(mockSystem);

      const result = await service.findOneSystem("HEALTH_SYSTEM_BC");

      expect(prisma.system.findUnique).toHaveBeenCalledWith({
        where: { id: "HEALTH_SYSTEM_BC" },
      });
      expect(result).toEqual(mockSystem);
    });
  });

  describe("Transaction operations", () => {
    it("should create a transaction", async () => {
      const createTransactionDto = {
        id: "123e4567-e89b-12d3-a456-426614174000",
        created_by: "admin@example.com",
      };

      vi.spyOn(prisma.transaction, "create").mockResolvedValue(mockTransaction);

      const result = await service.createTransaction(createTransactionDto);

      expect(prisma.transaction.create).toHaveBeenCalledWith({
        data: createTransactionDto,
      });
      expect(result).toEqual(mockTransaction);
    });
  });

  describe("Version operations", () => {
    it("should create a version", async () => {
      const createVersionDto = {
        id: "v1.0.0",
        created_by: "admin@example.com",
      };

      vi.spyOn(prisma.version, "create").mockResolvedValue(mockVersion);

      const result = await service.createVersion(createVersionDto);

      expect(prisma.version.create).toHaveBeenCalledWith({
        data: createVersionDto,
      });
      expect(result).toEqual(mockVersion);
    });
  });
});
