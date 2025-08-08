import { ApiProperty } from "@nestjs/swagger";

export class SystemDto {
  @ApiProperty({
    description: "The unique identifier of the system",
    example: "HEALTH_SYSTEM_BC",
  })
  id: string;

  @ApiProperty({
    description: "When the system record was created",
    example: "2024-01-01T00:00:00.000Z",
  })
  created_at: Date;

  @ApiProperty({
    description: "When the system record was last updated",
    example: "2024-01-01T00:00:00.000Z",
  })
  updated_at: Date;

  @ApiProperty({
    description: "User who created the system record",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;

  @ApiProperty({
    description: "User who last updated the system record",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}

export class CreateSystemDto {
  @ApiProperty({
    description: "The unique identifier of the system",
    example: "HEALTH_SYSTEM_BC",
  })
  id: string;

  @ApiProperty({
    description: "User who created the system record",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;
}

export class UpdateSystemDto {
  @ApiProperty({
    description: "User who updated the system record",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}
