package by.fintrack.dto.report;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Setter
@Getter
public class CategorySummaryDto {

    private String categoryName;

    private BigDecimal totalExpense;

    private BigDecimal totalIncome;

    private BigDecimal net;

    public CategorySummaryDto() {
        this.totalExpense = BigDecimal.ZERO;
        this.totalIncome = BigDecimal.ZERO;
        this.net = BigDecimal.ZERO;
    }

    public CategorySummaryDto(String categoryName, BigDecimal totalExpense, BigDecimal totalIncome, BigDecimal net) {
        this.categoryName = categoryName;
        this.totalExpense = totalExpense;
        this.totalIncome = totalIncome;
        this.net = net;
    }


    @Override
    public String toString() {
        return "CategorySummaryDto{" +
                "categoryName='" + categoryName + '\'' +
                ", totalExpense=" + totalExpense +
                ", totalIncome=" + totalIncome +
                ", net=" + net +
                '}';
    }
}