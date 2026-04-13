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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("BudgetServiceImpl")
class BudgetServiceImplTest {

    @Mock BudgetRepository budgetRepository;
    @Mock CategoryRepository categoryRepository;
    @Mock TransactionRepository transactionRepository;
    @Mock UserServiceImpl userService;
    @Spy  ExchangeRateServiceImpl exchangeRateServiceImpl = new ExchangeRateServiceImpl();

    @InjectMocks
    BudgetServiceImpl budgetService;

    private User user;
    private Category category;
    private Budget budget;

    @BeforeEach
    void setUp() {
        user = User.builder()
                .id(1L)
                .username("alice")
                .email("alice@test.com")
                .mainCurrency(Currency.BYN)
                .build();

        category = Category.builder()
                .id(10L)
                .name("Продукты")
                .user(user)
                .build();

        budget = Budget.builder()
                .id(100L)
                .user(user)
                .category(category)
                .amount(new BigDecimal("500"))
                .periodType(PeriodType.MONTHLY)
                .currency(Currency.BYN)
                .build();
    }

    // ── getStatusForCurrentUser ────────────────────────────────────────────────

    @Test
    @DisplayName("buildStatus: 0 трат → процент 0%, nearLimit=false, exceeded=false")
    void buildStatus_noTransactions_zeroPercent() {
        when(userService.getCurrentUser()).thenReturn(user);
        when(budgetRepository.findByUser(user)).thenReturn(List.of(budget));
        when(transactionRepository.findAllForCategorySummaryWithDates(
                anyLong(), any(LocalDateTime.class), any(LocalDateTime.class)))
                .thenReturn(List.of());

        List<BudgetStatusDto> statuses = budgetService.getStatusForCurrentUser();

        assertThat(statuses).hasSize(1);
        BudgetStatusDto s = statuses.get(0);
        assertThat(s.getPercentUsed()).isEqualTo(0.0);
        assertThat(s.isNearLimit()).isFalse();
        assertThat(s.isExceeded()).isFalse();
        assertThat(s.getRemainingAmount()).isEqualByComparingTo(new BigDecimal("500.00"));
    }

    @Test
    @DisplayName("buildStatus: потрачено 80% → nearLimit=true, exceeded=false")
    void buildStatus_80percentSpent_nearLimit() {
        Transaction tx = buildTransaction(new BigDecimal("400"), TransactionType.EXPENSE);
        when(userService.getCurrentUser()).thenReturn(user);
        when(budgetRepository.findByUser(user)).thenReturn(List.of(budget));
        when(transactionRepository.findAllForCategorySummaryWithDates(anyLong(), any(), any()))
                .thenReturn(List.of(tx));

        List<BudgetStatusDto> statuses = budgetService.getStatusForCurrentUser();
        BudgetStatusDto s = statuses.get(0);

        assertThat(s.getPercentUsed()).isEqualTo(80.0);
        assertThat(s.isNearLimit()).isTrue();
        assertThat(s.isExceeded()).isFalse();
    }

    @Test
    @DisplayName("buildStatus: потрачено 120% → exceeded=true")
    void buildStatus_120percentSpent_exceeded() {
        Transaction tx = buildTransaction(new BigDecimal("600"), TransactionType.EXPENSE);
        when(userService.getCurrentUser()).thenReturn(user);
        when(budgetRepository.findByUser(user)).thenReturn(List.of(budget));
        when(transactionRepository.findAllForCategorySummaryWithDates(anyLong(), any(), any()))
                .thenReturn(List.of(tx));

        List<BudgetStatusDto> statuses = budgetService.getStatusForCurrentUser();
        BudgetStatusDto s = statuses.get(0);

        assertThat(s.isExceeded()).isTrue();
        assertThat(s.getRemainingAmount().doubleValue()).isNegative();
    }

    @Test
    @DisplayName("buildStatus: INCOME-транзакции игнорируются при расчёте")
    void buildStatus_incomeTransactionsIgnored() {
        Transaction income = buildTransaction(new BigDecimal("1000"), TransactionType.INCOME);
        when(userService.getCurrentUser()).thenReturn(user);
        when(budgetRepository.findByUser(user)).thenReturn(List.of(budget));
        when(transactionRepository.findAllForCategorySummaryWithDates(anyLong(), any(), any()))
                .thenReturn(List.of(income));

        List<BudgetStatusDto> statuses = budgetService.getStatusForCurrentUser();
        assertThat(statuses.get(0).getPercentUsed()).isEqualTo(0.0);
    }

    // ── createOrUpdate ─────────────────────────────────────────────────────────

    @Test
    @DisplayName("createOrUpdate: чужая категория → AccessDeniedException")
    void createOrUpdate_foreignCategory_throwsAccessDenied() {
        User anotherUser = User.builder().id(99L).username("bob").build();
        Category foreignCat = Category.builder().id(10L).user(anotherUser).build();

        BudgetCreateDto dto = new BudgetCreateDto();
        dto.setCategoryId(10L);
        dto.setAmount(new BigDecimal("300"));
        dto.setPeriodType(PeriodType.MONTHLY);

        when(userService.getCurrentUser()).thenReturn(user);
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(foreignCat));

        assertThatThrownBy(() -> budgetService.createOrUpdate(dto))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("createOrUpdate: категория не найдена → ResourceNotFoundException")
    void createOrUpdate_categoryNotFound_throwsResourceNotFound() {
        BudgetCreateDto dto = new BudgetCreateDto();
        dto.setCategoryId(999L);
        dto.setAmount(new BigDecimal("100"));
        dto.setPeriodType(PeriodType.MONTHLY);

        when(userService.getCurrentUser()).thenReturn(user);
        when(categoryRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> budgetService.createOrUpdate(dto))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("createOrUpdate: новый бюджет создаётся и сохраняется")
    void createOrUpdate_newBudget_saved() {
        BudgetCreateDto dto = new BudgetCreateDto();
        dto.setCategoryId(10L);
        dto.setAmount(new BigDecimal("300"));
        dto.setPeriodType(PeriodType.MONTHLY);
        dto.setCurrency(Currency.BYN);

        when(userService.getCurrentUser()).thenReturn(user);
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(category));
        when(budgetRepository.findByUserAndCategoryIdAndPeriodType(user, 10L, PeriodType.MONTHLY))
                .thenReturn(Optional.empty());
        when(budgetRepository.save(any(Budget.class))).thenReturn(budget);

        BudgetDto result = budgetService.createOrUpdate(dto);
        assertThat(result).isNotNull();
        verify(budgetRepository).save(any(Budget.class));
    }

    // ── delete ─────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("delete: чужой бюджет → AccessDeniedException")
    void delete_foreignBudget_throwsAccessDenied() {
        User anotherUser = User.builder().id(99L).build();
        Budget foreignBudget = Budget.builder().id(100L).user(anotherUser).build();

        when(userService.getCurrentUser()).thenReturn(user);
        when(budgetRepository.findById(100L)).thenReturn(Optional.of(foreignBudget));

        assertThatThrownBy(() -> budgetService.delete(100L))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("delete: свой бюджет → удаляется")
    void delete_ownBudget_deleted() {
        when(userService.getCurrentUser()).thenReturn(user);
        when(budgetRepository.findById(100L)).thenReturn(Optional.of(budget));

        budgetService.delete(100L);

        verify(budgetRepository).delete(budget);
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    private Transaction buildTransaction(BigDecimal amount, TransactionType type) {
        return Transaction.builder()
                .id((long) (Math.random() * 1000))
                .amount(amount)
                .type(type)
                .category(category)
                .user(user)
                .currency(Currency.BYN)
                .date(LocalDateTime.now())
                .build();
    }
}