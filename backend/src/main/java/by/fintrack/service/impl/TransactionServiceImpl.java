package by.fintrack.service.impl;

import by.fintrack.dto.transaction.TransactionCreateDto;
import by.fintrack.dto.transaction.TransactionDto;
import by.fintrack.dto.report.CategorySummaryDto;
import by.fintrack.dto.report.DailySummaryDto;
import by.fintrack.dto.report.ReportResponse;
import by.fintrack.entity.*;
import by.fintrack.entity.Currency;
import by.fintrack.exception.ResourceNotFoundException;
import by.fintrack.mapper.TransactionMapper;
import by.fintrack.repository.CategoryRepository;
import by.fintrack.repository.TransactionRepository;
import by.fintrack.service.TransactionService;
import by.fintrack.util.specification.TransactionSpecifications;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class TransactionServiceImpl implements TransactionService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionMapper transactionMapper;
    private final UserServiceImpl userService;
    private final ExchangeRateServiceImpl exchangeRateServiceImpl;

    private TransactionDto toDtoWithMainCurrency(Transaction transaction) {
        User user = userService.getCurrentUser();
        Currency mainCurrency = user.getMainCurrency();

        BigDecimal convertedAmount = exchangeRateServiceImpl.convertToMainCurrency(
                transaction.getAmount(),
                transaction.getCurrency(),
                mainCurrency);

        TransactionDto dto = transactionMapper.toDto(transaction);
        dto.setAmount(convertedAmount.setScale(2, BigDecimal.ROUND_HALF_UP));

        return dto;
    }

    @Override
    @Transactional(readOnly = true)
    public Page<TransactionDto> getAllForCurrentUser(Pageable pageable) {
        User user = userService.getCurrentUser();
        log.debug("Fetching transactions for user id={} with mainCurrency={}",
                user.getId(), user.getMainCurrency().name());

        return transactionRepository.findByUser(user, pageable)
                .map(this::toDtoWithMainCurrency);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<TransactionDto> getFiltered(
            LocalDateTime fromDate,
            LocalDateTime toDate,
            TransactionType type,
            Long categoryId,
            Pageable pageable) {

        User user = userService.getCurrentUser();

        Specification<Transaction> spec = Specification.where(TransactionSpecifications.hasUser(user));

        if (fromDate != null) spec = spec.and(TransactionSpecifications.dateAfterOrEqual(fromDate));
        if (toDate != null) spec = spec.and(TransactionSpecifications.dateBeforeOrEqual(toDate));
        if (type != null) spec = spec.and(TransactionSpecifications.hasType(type));
        if (categoryId != null) spec = spec.and(TransactionSpecifications.hasCategory(categoryId));

        return transactionRepository.findAll(spec, pageable)
                .map(this::toDtoWithMainCurrency);
    }

    @Override
    @Transactional(readOnly = true)
    public List<CategorySummaryDto> getCategorySummary(LocalDateTime from, LocalDateTime to) {
        User user = userService.getCurrentUser();
        Long userId = user.getId();

        List<Transaction> transactions = (from != null && to != null)
                ? transactionRepository.findAllForCategorySummaryWithDates(userId, from, to)
                : transactionRepository.findAllForCategorySummary(userId);

        return getLongCategorySummaryDtoMap(transactions, user.getMainCurrency())
                .values().stream()
                .sorted(Comparator.comparing(CategorySummaryDto::getNet).reversed())
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public ReportResponse getFullReport(LocalDateTime from, LocalDateTime to) {
        User user = userService.getCurrentUser();
        Currency mainCurrency = user.getMainCurrency();

        List<Transaction> transactions = transactionRepository
                .findAllForCategorySummaryWithDates(user.getId(), from, to);

        BigDecimal totalIncome = BigDecimal.ZERO;
        BigDecimal totalExpense = BigDecimal.ZERO;

        Map<Long, CategorySummaryDto> summaryMap = getLongCategorySummaryDtoMap(transactions, mainCurrency);
        Map<LocalDate, DailySummaryDto> dailyMap = new LinkedHashMap<>();

        for (Transaction t : transactions) {
            LocalDate date = t.getDate().toLocalDate();
            BigDecimal amountInMain = exchangeRateServiceImpl.convertToMainCurrency(
                    t.getAmount(), t.getCurrency(), mainCurrency);

            dailyMap.computeIfAbsent(date, d -> new DailySummaryDto(d, BigDecimal.ZERO, BigDecimal.ZERO));
            DailySummaryDto daily = dailyMap.get(date);

            if (t.getType() == TransactionType.INCOME) {
                totalIncome = totalIncome.add(amountInMain);
                daily.setIncome(daily.getIncome().add(amountInMain));
            } else {
                totalExpense = totalExpense.add(amountInMain);
                daily.setExpense(daily.getExpense().add(amountInMain));
            }
        }

        List<CategorySummaryDto> expenses = summaryMap.values().stream()
                .filter(c -> c.getTotalExpense().compareTo(BigDecimal.ZERO) > 0)
                .sorted(Comparator.comparing(CategorySummaryDto::getTotalExpense).reversed())
                .toList();

        List<CategorySummaryDto> incomes = summaryMap.values().stream()
                .filter(c -> c.getTotalIncome().compareTo(BigDecimal.ZERO) > 0)
                .sorted(Comparator.comparing(CategorySummaryDto::getTotalIncome).reversed())
                .toList();

        List<DailySummaryDto> dailySummaries = dailyMap.values().stream()
                .sorted(Comparator.comparing(DailySummaryDto::getDate))
                .toList();

        return new ReportResponse(
                totalIncome,
                totalExpense,
                totalIncome.subtract(totalExpense),
                expenses,
                incomes,
                dailySummaries
        );
    }

    private Map<Long, CategorySummaryDto> getLongCategorySummaryDtoMap(List<Transaction> transactions, Currency mainCurrency) {
        Map<Long, CategorySummaryDto> summaryMap = new LinkedHashMap<>();

        for (Transaction t : transactions) {
            Category category = t.getCategory();
            Long catId = category.getId();

            BigDecimal amountInMain = exchangeRateServiceImpl.convertToMainCurrency(
                    t.getAmount(), t.getCurrency(), mainCurrency);

            CategorySummaryDto dto = summaryMap.computeIfAbsent(catId, id ->
                    new CategorySummaryDto(category.getName(), BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO));

            if (t.getType() == TransactionType.INCOME) {
                dto.setTotalIncome(dto.getTotalIncome().add(amountInMain));
                dto.setNet(dto.getNet().add(amountInMain));
            } else {
                dto.setTotalExpense(dto.getTotalExpense().add(amountInMain));
                dto.setNet(dto.getNet().subtract(amountInMain));
            }
        }
        return summaryMap;
    }

    @Override
    @Transactional
    public TransactionDto create(TransactionCreateDto dto) {
        User user = userService.getCurrentUser();
        Category category = categoryRepository.findById(dto.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        if (!category.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("Category does not belong to user");
        }

        Transaction transaction = transactionMapper.toEntity(dto);
        transaction.setCategory(category);
        transaction.setUser(user);

        Transaction saved = transactionRepository.save(transaction);
        return toDtoWithMainCurrency(saved);
    }

    @Override
    @Transactional
    public TransactionDto update(Long id, TransactionCreateDto dto) {
        User user = userService.getCurrentUser();
        Transaction transaction = transactionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found"));

        if (!transaction.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("Transaction does not belong to user");
        }

        Category category = categoryRepository.findById(dto.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        if (!category.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("Category does not belong to user");
        }

        transaction.setAmount(dto.getAmount());
        transaction.setDate(dto.getDate());
        transaction.setDescription(dto.getDescription());
        transaction.setType(dto.getType());
        transaction.setCurrency(dto.getCurrency());
        transaction.setCategory(category);

        Transaction updated = transactionRepository.save(transaction);
        return toDtoWithMainCurrency(updated);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        User user = userService.getCurrentUser();
        Transaction transaction = transactionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found"));

        if (!transaction.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("Transaction does not belong to user");
        }
        transactionRepository.delete(transaction);
    }
}