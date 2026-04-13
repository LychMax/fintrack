package by.fintrack.dto.report;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReportResponse {

    private BigDecimal totalIncome = BigDecimal.ZERO;

    private BigDecimal totalExpense = BigDecimal.ZERO;

    private BigDecimal balance = BigDecimal.ZERO;

    private List<CategorySummaryDto> categoryExpenses;

    private List<CategorySummaryDto> categoryIncomes;

    private List<DailySummaryDto> dailySummaries;
}