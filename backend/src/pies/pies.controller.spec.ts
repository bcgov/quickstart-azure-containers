import type { TestingModule } from "@nestjs/testing";
import { Test } from "@nestjs/testing";
import { PiesController } from "./pies.controller";
import { PiesService } from "./pies.service";
import { HttpException } from "@nestjs/common";

describe("PiesController", () => {
  let controller: PiesController;
  let service: PiesService;

  const mockSystem = {
    id: "HEALTH_SYSTEM_BC",
    created_at: new Date("2024-01-01T00:00:00.000Z"),
    updated_at: new Date("2024-01-01T00:00:00.000Z"),
    created_by: "admin@example.com",
    updated_by: "admin@example.com",
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PiesController],
      providers: [
        {
          provide: PiesService,
          useValue: {
            createSystem: vi.fn(),
            findAllSystems: vi.fn(),
            findOneSystem: vi.fn(),
            updateSystem: vi.fn(),
            removeSystem: vi.fn(),
            createTransaction: vi.fn(),
            findAllTransactions: vi.fn(),
            findOneTransaction: vi.fn(),
            updateTransaction: vi.fn(),
            removeTransaction: vi.fn(),
            createVersion: vi.fn(),
            findAllVersions: vi.fn(),
            findOneVersion: vi.fn(),
            updateVersion: vi.fn(),
            removeVersion: vi.fn(),
            createCoding: vi.fn(),
            findAllCodings: vi.fn(),
            findOneCoding: vi.fn(),
            updateCoding: vi.fn(),
            removeCoding: vi.fn(),
            createRecordKind: vi.fn(),
            findAllRecordKinds: vi.fn(),
            findOneRecordKind: vi.fn(),
            updateRecordKind: vi.fn(),
            removeRecordKind: vi.fn(),
            createSystemRecord: vi.fn(),
            findAllSystemRecords: vi.fn(),
            findOneSystemRecord: vi.fn(),
            updateSystemRecord: vi.fn(),
            removeSystemRecord: vi.fn(),
            createProcessEvent: vi.fn(),
            findAllProcessEvents: vi.fn(),
            findOneProcessEvent: vi.fn(),
            updateProcessEvent: vi.fn(),
            removeProcessEvent: vi.fn(),
            createRecordLinkage: vi.fn(),
            findAllRecordLinkages: vi.fn(),
            findOneRecordLinkage: vi.fn(),
            updateRecordLinkage: vi.fn(),
            removeRecordLinkage: vi.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<PiesController>(PiesController);
    service = module.get<PiesService>(PiesService);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });

  describe("System operations", () => {
    it("should create a system", async () => {
      const createSystemDto = {
        id: "HEALTH_SYSTEM_BC",
        created_by: "admin@example.com",
      };

      vi.spyOn(service, "createSystem").mockResolvedValue(mockSystem);

      const result = await controller.createSystem(createSystemDto);

      expect(service.createSystem).toHaveBeenCalledWith(createSystemDto);
      expect(result).toEqual(mockSystem);
    });

    it("should get all systems", async () => {
      vi.spyOn(service, "findAllSystems").mockResolvedValue([mockSystem]);

      const result = await controller.findAllSystems();

      expect(service.findAllSystems).toHaveBeenCalled();
      expect(result).toEqual([mockSystem]);
    });

    it("should get one system", async () => {
      vi.spyOn(service, "findOneSystem").mockResolvedValue(mockSystem);

      const result = await controller.findOneSystem("HEALTH_SYSTEM_BC");

      expect(service.findOneSystem).toHaveBeenCalledWith("HEALTH_SYSTEM_BC");
      expect(result).toEqual(mockSystem);
    });

    it("should throw an exception when system is not found", async () => {
      vi.spyOn(service, "findOneSystem").mockResolvedValue(null);

      await expect(controller.findOneSystem("NON_EXISTENT")).rejects.toThrow(
        new HttpException("System not found.", 404),
      );
    });
  });
});
