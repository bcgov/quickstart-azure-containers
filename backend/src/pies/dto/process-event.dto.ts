import { ApiProperty } from "@nestjs/swagger";

export class ProcessEventDto {
  @ApiProperty({
    description: "The unique identifier of the process event",
    example: 1,
  })
  id: number;

  @ApiProperty({
    description: "The transaction identifier",
    example: "123e4567-e89b-12d3-a456-426614174000",
  })
  transaction_id: string;

  @ApiProperty({
    description: "The system record identifier",
    example: 1,
  })
  system_record_id: number;

  @ApiProperty({
    description: "The start date of the process event",
    example: "2024-01-01",
  })
  start_date: Date;

  @ApiProperty({
    description: "The start time of the process event",
    required: false,
    example: "09:00:00-08:00",
  })
  start_time?: Date;

  @ApiProperty({
    description: "The end date of the process event",
    required: false,
    example: "2024-01-01",
  })
  end_date?: Date;

  @ApiProperty({
    description: "The end time of the process event",
    required: false,
    example: "17:00:00-08:00",
  })
  end_time?: Date;

  @ApiProperty({
    description: "The coding identifier",
    example: 1,
  })
  coding_id: number;

  @ApiProperty({
    description: "The status of the process event",
    required: false,
    example: "completed",
  })
  status?: string;

  @ApiProperty({
    description: "The status code",
    required: false,
    example: "SUCCESS",
  })
  status_code?: string;

  @ApiProperty({
    description: "Description of the status",
    required: false,
    example: "Process completed successfully",
  })
  status_description?: string;

  @ApiProperty({
    description: "When the process event was created",
    example: "2024-01-01T00:00:00.000Z",
  })
  created_at: Date;

  @ApiProperty({
    description: "When the process event was last updated",
    example: "2024-01-01T00:00:00.000Z",
  })
  updated_at: Date;

  @ApiProperty({
    description: "User who created the process event",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;

  @ApiProperty({
    description: "User who last updated the process event",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}

export class CreateProcessEventDto {
  @ApiProperty({
    description: "The transaction identifier",
    example: "123e4567-e89b-12d3-a456-426614174000",
  })
  transaction_id: string;

  @ApiProperty({
    description: "The system record identifier",
    example: 1,
  })
  system_record_id: number;

  @ApiProperty({
    description: "The start date of the process event",
    example: "2024-01-01",
  })
  start_date: Date;

  @ApiProperty({
    description: "The start time of the process event",
    required: false,
    example: "09:00:00-08:00",
  })
  start_time?: Date;

  @ApiProperty({
    description: "The end date of the process event",
    required: false,
    example: "2024-01-01",
  })
  end_date?: Date;

  @ApiProperty({
    description: "The end time of the process event",
    required: false,
    example: "17:00:00-08:00",
  })
  end_time?: Date;

  @ApiProperty({
    description: "The coding identifier",
    example: 1,
  })
  coding_id: number;

  @ApiProperty({
    description: "The status of the process event",
    required: false,
    example: "completed",
  })
  status?: string;

  @ApiProperty({
    description: "The status code",
    required: false,
    example: "SUCCESS",
  })
  status_code?: string;

  @ApiProperty({
    description: "Description of the status",
    required: false,
    example: "Process completed successfully",
  })
  status_description?: string;

  @ApiProperty({
    description: "User who created the process event",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;
}

export class UpdateProcessEventDto {
  @ApiProperty({
    description: "The transaction identifier",
    required: false,
    example: "123e4567-e89b-12d3-a456-426614174000",
  })
  transaction_id?: string;

  @ApiProperty({
    description: "The system record identifier",
    required: false,
    example: 1,
  })
  system_record_id?: number;

  @ApiProperty({
    description: "The start date of the process event",
    required: false,
    example: "2024-01-01",
  })
  start_date?: Date;

  @ApiProperty({
    description: "The start time of the process event",
    required: false,
    example: "09:00:00-08:00",
  })
  start_time?: Date;

  @ApiProperty({
    description: "The end date of the process event",
    required: false,
    example: "2024-01-01",
  })
  end_date?: Date;

  @ApiProperty({
    description: "The end time of the process event",
    required: false,
    example: "17:00:00-08:00",
  })
  end_time?: Date;

  @ApiProperty({
    description: "The coding identifier",
    required: false,
    example: 1,
  })
  coding_id?: number;

  @ApiProperty({
    description: "The status of the process event",
    required: false,
    example: "completed",
  })
  status?: string;

  @ApiProperty({
    description: "The status code",
    required: false,
    example: "SUCCESS",
  })
  status_code?: string;

  @ApiProperty({
    description: "Description of the status",
    required: false,
    example: "Process completed successfully",
  })
  status_description?: string;

  @ApiProperty({
    description: "User who updated the process event",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}
