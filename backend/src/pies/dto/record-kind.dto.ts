import { ApiProperty } from "@nestjs/swagger";

export class RecordKindDto {
  @ApiProperty({
    description: "The unique identifier of the record kind",
    example: 1,
  })
  id: number;

  @ApiProperty({
    description: "The kind of record",
    example: "Patient",
  })
  kind: string;

  @ApiProperty({
    description: "The version this record kind belongs to",
    example: "v1.0.0",
  })
  version_id: string;

  @ApiProperty({
    description: "When the record kind was created",
    example: "2024-01-01T00:00:00.000Z",
  })
  created_at: Date;

  @ApiProperty({
    description: "When the record kind was last updated",
    example: "2024-01-01T00:00:00.000Z",
  })
  updated_at: Date;

  @ApiProperty({
    description: "User who created the record kind",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;

  @ApiProperty({
    description: "User who last updated the record kind",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}

export class CreateRecordKindDto {
  @ApiProperty({
    description: "The kind of record",
    example: "Patient",
  })
  kind: string;

  @ApiProperty({
    description: "The version this record kind belongs to",
    example: "v1.0.0",
  })
  version_id: string;

  @ApiProperty({
    description: "User who created the record kind",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;
}

export class UpdateRecordKindDto {
  @ApiProperty({
    description: "The kind of record",
    required: false,
    example: "Patient",
  })
  kind?: string;

  @ApiProperty({
    description: "The version this record kind belongs to",
    required: false,
    example: "v1.0.0",
  })
  version_id?: string;

  @ApiProperty({
    description: "User who updated the record kind",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}
