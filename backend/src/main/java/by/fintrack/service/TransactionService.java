package by.fintrack.service;

import by.fintrack.dto.transaction.TransactionCreateDto;
import by.fintrack.dto.transaction.TransactionDto;
import by.fintrack.dto.report.CategorySummaryDto;
import by.fintrack.dto.report.ReportResponse;
import by.fintrack.entity.TransactionType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;

public interface TransactionService {
    Page<TransactionDto> getAllForCurrentUser(Pageable pageable);

    Page<TransactionDto> getFiltered(
            LocalDateTime fromDate,
            LocalDateTime toDate,
            TransactionType type,
            Long categoryId,
            Pageable pageable);

    List<CategorySummaryDto> getCategorySummary(LocalDateTime from, LocalDateTime to);

    TransactionDto create(TransactionCreateDto dto);

    TransactionDto update(Long id, TransactionCreateDto dto);

    ReportResponse getFullReport(LocalDateTime from, LocalDateTime to);

    void delete(Long id);
}