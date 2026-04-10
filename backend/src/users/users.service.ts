import { Injectable } from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "src/prisma.service";

import { CreateUserDto } from "./dto/create-user.dto";
import { UpdateUserDto } from "./dto/update-user.dto";
import { UserDto } from "./dto/user.dto";

/**
 * Implements user persistence, lookup, and query operations.
 */
@Injectable()
export class UsersService {
  /**
   * Creates the service with the shared Prisma client wrapper.
   *
   * @param prisma Database service used for user queries and mutations.
   */
  constructor(private prisma: PrismaService) {}

  /**
   * Persists a new user.
   *
   * @param user User data to insert.
   * @returns Newly created user data.
   */
  async create(user: CreateUserDto): Promise<UserDto> {
    const savedUser = await this.prisma.users.create({
      data: {
        name: user.name,
        email: user.email,
      },
    });

    return {
      id: savedUser.id.toNumber(),
      name: savedUser.name,
      email: savedUser.email,
    };
  }

  /**
   * Retrieves every user in the database.
   *
   * @returns All persisted users mapped to DTOs.
   */
  async findAll(): Promise<UserDto[]> {
    const users = await this.prisma.users.findMany();
    return users.flatMap((user) => {
      const userDto: UserDto = {
        id: user.id.toNumber(),
        name: user.name,
        email: user.email,
      };
      return userDto;
    });
  }

  /**
   * Retrieves a single user by numeric identifier.
   *
   * @param id Identifier of the user to fetch.
   * @returns The matching user DTO.
   */
  async findOne(id: number): Promise<UserDto> {
    const user = await this.prisma.users.findUnique({
      where: {
        id: new Prisma.Decimal(id),
      },
    });
    return {
      id: user.id.toNumber(),
      name: user.name,
      email: user.email,
    };
  }

  /**
   * Updates an existing user record.
   *
   * @param id Identifier of the user to update.
   * @param updateUserDto Replacement field values.
   * @returns Updated user DTO.
   */
  async update(id: number, updateUserDto: UpdateUserDto): Promise<UserDto> {
    const user = await this.prisma.users.update({
      where: {
        id: new Prisma.Decimal(id),
      },
      data: {
        name: updateUserDto.name,
        email: updateUserDto.email,
      },
    });
    return {
      id: user.id.toNumber(),
      name: user.name,
      email: user.email,
    };
  }

  /**
   * Deletes a user by identifier.
   *
   * @param id Identifier of the user to delete.
   * @returns Deletion status and an optional error message.
   */
  async remove(id: number): Promise<{ deleted: boolean; message?: string }> {
    try {
      await this.prisma.users.delete({
        where: {
          id: new Prisma.Decimal(id),
        },
      });
      return { deleted: true };
    } catch (error) {
      return {
        deleted: false,
        message: error instanceof Error ? error.message : String(error),
      };
    }
  }

  /**
   * Searches users with pagination, sorting, and filter criteria passed as JSON strings.
   *
   * @param page Requested page number.
   * @param limit Maximum number of results per page.
   * @param sort JSON-encoded Prisma order-by clauses.
   * @param filter JSON-encoded filter descriptors.
   * @returns Paginated users together with total counts.
   */
  async searchUsers(
    page: number,
    limit: number,
    sort: string, // JSON string to store sort key and sort value, ex: [{"name":"desc"},{"email":"asc"}]
    filter: string, // JSON array for key, operation and value, ex: [{"key": "name", "operation": "like", "value": "Jo"}]
  ): Promise<any> {
    page = page || 1;
    if (!limit || limit > 200) {
      limit = 10;
    }

    let sortObj = [];
    let filterObj = {};
    try {
      sortObj = JSON.parse(sort);
      filterObj = JSON.parse(filter);
    } catch {
      throw new Error("Invalid query parameters");
    }
    const users = await this.prisma.users.findMany({
      skip: (page - 1) * limit,
      take: parseInt(String(limit)),
      orderBy: sortObj,
      where: this.convertFiltersToPrismaFormat(filterObj),
    });

    const count = await this.prisma.users.count({
      orderBy: sortObj,
      where: this.convertFiltersToPrismaFormat(filterObj),
    });

    return {
      users,
      page,
      limit,
      total: count,
      totalPages: Math.ceil(count / limit),
    };
  }

  /**
   * Converts parsed filter descriptors into a Prisma-compatible where clause.
   *
   * @param filterObj Parsed filter descriptors from the request.
   * @returns Prisma where object built from the supplied filters.
   */
  public convertFiltersToPrismaFormat(filterObj): any {
    const prismaFilterObj = {};

    for (const item of filterObj) {
      if (item.operation === "like") {
        prismaFilterObj[item.key] = { contains: item.value };
      } else if (item.operation === "eq") {
        prismaFilterObj[item.key] = { equals: item.value };
      } else if (item.operation === "neq") {
        prismaFilterObj[item.key] = { not: { equals: item.value } };
      } else if (item.operation === "gt") {
        prismaFilterObj[item.key] = { gt: item.value };
      } else if (item.operation === "gte") {
        prismaFilterObj[item.key] = { gte: item.value };
      } else if (item.operation === "lt") {
        prismaFilterObj[item.key] = { lt: item.value };
      } else if (item.operation === "lte") {
        prismaFilterObj[item.key] = { lte: item.value };
      } else if (item.operation === "in") {
        prismaFilterObj[item.key] = { in: item.value };
      } else if (item.operation === "notin") {
        prismaFilterObj[item.key] = { not: { in: item.value } };
      } else if (item.operation === "isnull") {
        prismaFilterObj[item.key] = { equals: null };
      }
    }
    return prismaFilterObj;
  }
}
