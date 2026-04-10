import { PickType } from "@nestjs/swagger";

import { UserDto } from "./user.dto";

/**
 * Defines the fields accepted when creating a user.
 */
export class CreateUserDto extends PickType(UserDto, [
  "email",
  "name",
] as const) {}
