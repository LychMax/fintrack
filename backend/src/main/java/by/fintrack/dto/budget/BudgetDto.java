package by.fintrack.dto.budget;

import by.fintrack.entity.Budget.PeriodType;
import by.fintrack.entity.Currency;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class BudgetDto {

    private Long id;

    private Long categoryId;

    private String categoryName;

    private BigDecimal amount;

    private PeriodType periodType;

    private Currency currency;
}