import { ApiProperty } from "@nestjs/swagger";

export class VersionDto {
  @ApiProperty({
    description: "The unique identifier of the version",
    example: "v1.0.0",
  })
  id: string;

  @ApiProperty({
    description: "When the version record was created",
    example: "2024-01-01T00:00:00.000Z",
  })
  created_at: Date;

  @ApiProperty({
    description: "When the version record was last updated",
    example: "2024-01-01T00:00:00.000Z",
  })
  updated_at: Date;

  @ApiProperty({
    description: "User who created the version record",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;

  @ApiProperty({
    description: "User who last updated the version record",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}

export class CreateVersionDto {
  @ApiProperty({
    description: "The unique identifier of the version",
    example: "v1.0.0",
  })
  id: string;

  @ApiProperty({
    description: "User who created the version record",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;
}

export class UpdateVersionDto {
  @ApiProperty({
    description: "User who updated the version record",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}
