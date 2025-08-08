import { ApiProperty } from "@nestjs/swagger";

export class CodingDto {
  @ApiProperty({
    description: "The unique identifier of the coding",
    example: 1,
  })
  id: number;

  @ApiProperty({
    description: "The code value",
    example: "PROC001",
  })
  code: string;

  @ApiProperty({
    description: "The code system identifier",
    example: "ICD-10-CA",
  })
  code_system: string;

  @ApiProperty({
    description: "The version this coding belongs to",
    example: "v1.0.0",
  })
  version_id: string;

  @ApiProperty({
    description: "When the coding was created",
    example: "2024-01-01T00:00:00.000Z",
  })
  created_at: Date;

  @ApiProperty({
    description: "When the coding was last updated",
    example: "2024-01-01T00:00:00.000Z",
  })
  updated_at: Date;

  @ApiProperty({
    description: "User who created the coding",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;

  @ApiProperty({
    description: "User who last updated the coding",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}

export class CreateCodingDto {
  @ApiProperty({
    description: "The code value",
    example: "PROC001",
  })
  code: string;

  @ApiProperty({
    description: "The code system identifier",
    example: "ICD-10-CA",
  })
  code_system: string;

  @ApiProperty({
    description: "The version this coding belongs to",
    example: "v1.0.0",
  })
  version_id: string;

  @ApiProperty({
    description: "User who created the coding",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;
}

export class UpdateCodingDto {
  @ApiProperty({
    description: "The code value",
    required: false,
    example: "PROC001",
  })
  code?: string;

  @ApiProperty({
    description: "The code system identifier",
    required: false,
    example: "ICD-10-CA",
  })
  code_system?: string;

  @ApiProperty({
    description: "The version this coding belongs to",
    required: false,
    example: "v1.0.0",
  })
  version_id?: string;

  @ApiProperty({
    description: "User who updated the coding",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}
