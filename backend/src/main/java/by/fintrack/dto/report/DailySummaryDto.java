package by.fintrack.dto.report;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@AllArgsConstructor
public class DailySummaryDto {

    private LocalDate date;

    private BigDecimal income;

    private BigDecimal expense;
}