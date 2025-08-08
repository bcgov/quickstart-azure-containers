import { ApiProperty } from "@nestjs/swagger";

export class RecordLinkageDto {
  @ApiProperty({
    description: "The unique identifier of the record linkage",
    example: 1,
  })
  id: number;

  @ApiProperty({
    description: "The transaction identifier",
    example: "123e4567-e89b-12d3-a456-426614174000",
  })
  transaction_id: string;

  @ApiProperty({
    description: "The source system record identifier",
    example: 1,
  })
  system_record_id: number;

  @ApiProperty({
    description: "The linked system record identifier",
    example: 2,
  })
  linked_system_record_id: number;

  @ApiProperty({
    description: "When the record linkage was created",
    example: "2024-01-01T00:00:00.000Z",
  })
  created_at: Date;

  @ApiProperty({
    description: "When the record linkage was last updated",
    example: "2024-01-01T00:00:00.000Z",
  })
  updated_at: Date;

  @ApiProperty({
    description: "User who created the record linkage",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;

  @ApiProperty({
    description: "User who last updated the record linkage",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}

export class CreateRecordLinkageDto {
  @ApiProperty({
    description: "The transaction identifier",
    example: "123e4567-e89b-12d3-a456-426614174000",
  })
  transaction_id: string;

  @ApiProperty({
    description: "The source system record identifier",
    example: 1,
  })
  system_record_id: number;

  @ApiProperty({
    description: "The linked system record identifier",
    example: 2,
  })
  linked_system_record_id: number;

  @ApiProperty({
    description: "User who created the record linkage",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;
}

export class UpdateRecordLinkageDto {
  @ApiProperty({
    description: "The transaction identifier",
    required: false,
    example: "123e4567-e89b-12d3-a456-426614174000",
  })
  transaction_id?: string;

  @ApiProperty({
    description: "The source system record identifier",
    required: false,
    example: 1,
  })
  system_record_id?: number;

  @ApiProperty({
    description: "The linked system record identifier",
    required: false,
    example: 2,
  })
  linked_system_record_id?: number;

  @ApiProperty({
    description: "User who updated the record linkage",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}
