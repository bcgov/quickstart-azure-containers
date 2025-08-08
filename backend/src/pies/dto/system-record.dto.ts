import { ApiProperty } from "@nestjs/swagger";

export class SystemRecordDto {
  @ApiProperty({
    description: "The unique identifier of the system record",
    example: 1,
  })
  id: number;

  @ApiProperty({
    description: "The system identifier",
    example: "HEALTH_SYSTEM_BC",
  })
  system_id: string;

  @ApiProperty({
    description: "The record identifier within the system",
    example: "PATIENT_12345",
  })
  record_id: string;

  @ApiProperty({
    description: "The record kind identifier",
    example: 1,
  })
  record_kind_id: number;

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

export class CreateSystemRecordDto {
  @ApiProperty({
    description: "The system identifier",
    example: "HEALTH_SYSTEM_BC",
  })
  system_id: string;

  @ApiProperty({
    description: "The record identifier within the system",
    example: "PATIENT_12345",
  })
  record_id: string;

  @ApiProperty({
    description: "The record kind identifier",
    example: 1,
  })
  record_kind_id: number;

  @ApiProperty({
    description: "User who created the system record",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;
}

export class UpdateSystemRecordDto {
  @ApiProperty({
    description: "The system identifier",
    required: false,
    example: "HEALTH_SYSTEM_BC",
  })
  system_id?: string;

  @ApiProperty({
    description: "The record identifier within the system",
    required: false,
    example: "PATIENT_12345",
  })
  record_id?: string;

  @ApiProperty({
    description: "The record kind identifier",
    required: false,
    example: 1,
  })
  record_kind_id?: number;

  @ApiProperty({
    description: "User who updated the system record",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}
