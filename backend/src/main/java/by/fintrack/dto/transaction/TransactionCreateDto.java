package by.fintrack.dto.transaction;

import by.fintrack.entity.Currency;
import by.fintrack.entity.TransactionType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class TransactionCreateDto {

    @NotNull @Positive
    private BigDecimal amount;

    @NotNull
    private LocalDateTime date;

    @Size(max = 255)
    private String description;

    @NotNull
    private TransactionType type;

    @NotNull
    private Long categoryId;

    private Currency currency = Currency.BYN;
}