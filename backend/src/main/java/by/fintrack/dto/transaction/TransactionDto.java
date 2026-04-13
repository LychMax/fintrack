package by.fintrack.dto.transaction;

import by.fintrack.dto.category.CategoryDto;
import by.fintrack.entity.Currency;
import by.fintrack.entity.TransactionType;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class TransactionDto {

    private Long id;

    private BigDecimal amount;

    private LocalDateTime date;

    private String description;

    private TransactionType type;

    private Currency currency;

    private CategoryDto category;
}