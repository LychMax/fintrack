package by.fintrack.dto.budget;

import by.fintrack.entity.Budget.PeriodType;
import by.fintrack.entity.Currency;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BudgetStatusDto {

    private Long id;

    private Long categoryId;

    private String categoryName;

    private BigDecimal budgetAmount;

    private BigDecimal spentAmount;

    private BigDecimal remainingAmount;

    private double percentUsed;

    private PeriodType periodType;

    private Currency currency;

    private boolean nearLimit;

    private boolean exceeded;
}