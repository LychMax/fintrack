package by.fintrack.service.impl;

import by.fintrack.dto.budget.BudgetCreateDto;
import by.fintrack.dto.budget.BudgetDto;
import by.fintrack.dto.budget.BudgetStatusDto;
import by.fintrack.entity.*;
import by.fintrack.entity.Budget.PeriodType;
import by.fintrack.exception.ResourceNotFoundException;
import by.fintrack.repository.BudgetRepository;
import by.fintrack.repository.CategoryRepository;
import by.fintrack.repository.TransactionRepository;
import by.fintrack.service.BudgetService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.List;

@Service
@RequiredArgsConstructor
public class BudgetServiceImpl implements BudgetService {

    private final BudgetRepository budgetRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final UserServiceImpl userService;
    private final ExchangeRateServiceImpl exchangeRateServiceImpl;

    @Override
    @Transactional(readOnly = true)
    public List<BudgetDto> getAllForCurrentUser() {
        User user = userService.getCurrentUser();
        return budgetRepository.findByUser(user).stream()
                .map(this::toDto)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<BudgetStatusDto> getStatusForCurrentUser() {
        User user = userService.getCurrentUser();
        Currency mainCurrency = user.getMainCurrency();

        List<Budget> budgets = budgetRepository.findByUser(user);

        return budgets.stream()
                .map(budget -> buildStatus(budget, user, mainCurrency))
                .toList();
    }

    private BudgetStatusDto buildStatus(Budget budget, User user, Currency mainCurrency) {
        LocalDateTime[] range = getPeriodRange(budget.getPeriodType());

        List<Transaction> transactions = transactionRepository
                .findAllForCategorySummaryWithDates(user.getId(), range[0], range[1])
                .stream()
                .filter(t -> t.getType() == TransactionType.EXPENSE)
                .filter(t -> t.getCategory().getId().equals(budget.getCategory().getId()))
                .toList();

        BigDecimal spent = transactions.stream()
                .map(t -> exchangeRateServiceImpl.convertToMainCurrency(
                        t.getAmount(), t.getCurrency(), mainCurrency))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal budgetInMain = exchangeRateServiceImpl.convertToMainCurrency(
                budget.getAmount(), budget.getCurrency(), mainCurrency);

        BigDecimal remaining = budgetInMain.subtract(spent);

        double percent = 0;
        if (budgetInMain.compareTo(BigDecimal.ZERO) > 0) {
            percent = spent.divide(budgetInMain, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100))
                    .doubleValue();
        }

        return new BudgetStatusDto(
                budget.getId(),
                budget.getCategory().getId(),
                budget.getCategory().getName(),
                budgetInMain.setScale(2, RoundingMode.HALF_UP),
                spent.setScale(2, RoundingMode.HALF_UP),
                remaining.setScale(2, RoundingMode.HALF_UP),
                Math.round(percent * 10.0) / 10.0,
                budget.getPeriodType(),
                mainCurrency,
                percent >= 75,
                percent >= 100
        );
    }

    private LocalDateTime[] getPeriodRange(PeriodType periodType) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime start, end;

        if (periodType == PeriodType.MONTHLY) {
            start = now.with(TemporalAdjusters.firstDayOfMonth()).toLocalDate().atStartOfDay();
            end = now.with(TemporalAdjusters.lastDayOfMonth()).toLocalDate().atTime(23, 59, 59);
        } else {
            start = now.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).toLocalDate().atStartOfDay();
            end = now.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY)).toLocalDate().atTime(23, 59, 59);
        }

        return new LocalDateTime[]{start, end};
    }

    @Override
    @Transactional
    public BudgetDto createOrUpdate(BudgetCreateDto dto) {
        User user = userService.getCurrentUser();

        Category category = categoryRepository.findById(dto.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        if (!category.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("Category does not belong to user");
        }

        Budget budget = budgetRepository
                .findByUserAndCategoryIdAndPeriodType(user, dto.getCategoryId(), dto.getPeriodType())
                .orElse(Budget.builder()
                        .user(user)
                        .category(category)
                        .periodType(dto.getPeriodType())
                        .build());

        budget.setAmount(dto.getAmount());
        budget.setCurrency(dto.getCurrency() != null ? dto.getCurrency() : Currency.BYN);

        return toDto(budgetRepository.save(budget));
    }

    @Override
    @Transactional
    public void delete(Long id) {
        User user = userService.getCurrentUser();
        Budget budget = budgetRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Budget not found"));

        if (!budget.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("Budget does not belong to user");
        }

        budgetRepository.delete(budget);
    }

    private BudgetDto toDto(Budget budget) {
        BudgetDto dto = new BudgetDto();
        dto.setId(budget.getId());
        dto.setCategoryId(budget.getCategory().getId());
        dto.setCategoryName(budget.getCategory().getName());
        dto.setAmount(budget.getAmount());
        dto.setPeriodType(budget.getPeriodType());
        dto.setCurrency(budget.getCurrency());
        return dto;
    }
}