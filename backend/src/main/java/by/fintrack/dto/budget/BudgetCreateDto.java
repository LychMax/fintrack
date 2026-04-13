package by.fintrack.dto.budget;

import by.fintrack.entity.Budget.PeriodType;
import by.fintrack.entity.Currency;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class BudgetCreateDto {

    @NotNull
    private Long categoryId;

    @NotNull
    @Positive
    private BigDecimal amount;

    @NotNull
    private PeriodType periodType;

    private Currency currency = Currency.BYN;
}