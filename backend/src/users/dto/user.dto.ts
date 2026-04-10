import { ApiProperty } from "@nestjs/swagger";

/**
 * Represents the user shape exposed by the API.
 */
export class UserDto {
  @ApiProperty({
    description: "The ID of the user",
    // default: '9999',
  })
  id: number;

  @ApiProperty({
    description: "The name of the user",
    // default: 'username',
  })
  name: string;

  @ApiProperty({
    description: "The contact email of the user",
    default: "",
  })
  email: string;
}
