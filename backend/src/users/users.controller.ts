import {
  Controller,
  Get,
  Post,
  Body,
  Put,
  Param,
  Delete,
  Query,
  HttpException,
} from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";

import { CreateUserDto } from "./dto/create-user.dto";
import { UpdateUserDto } from "./dto/update-user.dto";
import { UserDto } from "./dto/user.dto";
import { UsersService } from "./users.service";

/**
 * Handles CRUD and search operations for user resources.
 */
@ApiTags("users")
@Controller({ path: "users", version: "1" })
export class UsersController {
  /**
   * Creates the controller with the user domain service.
   *
   * @param usersService Service that manages user persistence and queries.
   */
  constructor(private readonly usersService: UsersService) {}

  /**
   * Creates a new user record.
   *
   * @param createUserDto User details to persist.
   * @returns The newly created user.
   */
  @Post()
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  /**
   * Returns every stored user without pagination.
   *
   * @returns All persisted users.
   */
  @Get()
  findAll(): Promise<UserDto[]> {
    return this.usersService.findAll();
  }

  /**
   * Searches users using paginated, JSON-encoded sort and filter criteria.
   *
   * @param page Requested page number.
   * @param limit Maximum number of items per page.
   * @param sort JSON-encoded sort clauses.
   * @param filter JSON-encoded filter descriptors.
   * @returns Paginated users and result metadata.
   */
  @Get("search") // it must be ahead of the below Get(":id") to avoid conflict
  async searchUsers(
    @Query("page") page: number,
    @Query("limit") limit: number,
    @Query("sort") sort: string, // JSON string to store sort key and sort value, ex: {name: "ASC"}
    @Query("filter") filter: string, // JSON array for key, operation and value, ex: [{key: "name", operation: "like", value: "Peter"}]
  ) {
    if (isNaN(page) || isNaN(limit)) {
      throw new HttpException("Invalid query parameters", 400);
    }
    return this.usersService.searchUsers(page, limit, sort, filter);
  }

  /**
   * Retrieves a single user by identifier.
   *
   * @param id Identifier of the user to load.
   * @returns Matching user details.
   */
  @Get(":id")
  async findOne(@Param("id") id: string) {
    const user = await this.usersService.findOne(+id);
    if (!user) {
      throw new HttpException("User not found.", 404);
    }
    return user;
  }

  /**
   * Updates an existing user.
   *
   * @param id Identifier of the user to update.
   * @param updateUserDto Replacement user values.
   * @returns The updated user.
   */
  @Put(":id")
  update(@Param("id") id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(+id, updateUserDto);
  }

  /**
   * Deletes a user.
   *
   * @param id Identifier of the user to delete.
   * @returns Deletion status payload.
   */
  @Delete(":id")
  remove(@Param("id") id: string) {
    return this.usersService.remove(+id);
  }
}
