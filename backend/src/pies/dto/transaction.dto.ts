import { ApiProperty } from "@nestjs/swagger";

export class TransactionDto {
  @ApiProperty({
    description: "The unique UUID identifier of the transaction",
    example: "123e4567-e89b-12d3-a456-426614174000",
  })
  id: string;

  @ApiProperty({
    description: "When the transaction was created",
    example: "2024-01-01T00:00:00.000Z",
  })
  created_at: Date;

  @ApiProperty({
    description: "When the transaction was last updated",
    example: "2024-01-01T00:00:00.000Z",
  })
  updated_at: Date;

  @ApiProperty({
    description: "User who created the transaction",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;

  @ApiProperty({
    description: "User who last updated the transaction",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}

export class CreateTransactionDto {
  @ApiProperty({
    description: "The unique UUID identifier of the transaction",
    example: "123e4567-e89b-12d3-a456-426614174000",
  })
  id: string;

  @ApiProperty({
    description: "User who created the transaction",
    required: false,
    example: "admin@example.com",
  })
  created_by?: string;
}

export class UpdateTransactionDto {
  @ApiProperty({
    description: "User who updated the transaction",
    required: false,
    example: "admin@example.com",
  })
  updated_by?: string;
}
