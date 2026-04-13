package by.fintrack.service.impl;

import by.fintrack.dto.report.ReportResponse;
import by.fintrack.dto.transaction.TransactionCreateDto;
import by.fintrack.dto.transaction.TransactionDto;
import by.fintrack.entity.*;
import by.fintrack.exception.ResourceNotFoundException;
import by.fintrack.mapper.TransactionMapper;
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
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("TransactionServiceImpl")
class TransactionServiceImplTest {

    @Mock TransactionRepository transactionRepository;
    @Mock CategoryRepository categoryRepository;
    @Mock TransactionMapper transactionMapper;
    @Mock UserServiceImpl userService;
    @Spy  ExchangeRateServiceImpl exchangeRateServiceImpl = new ExchangeRateServiceImpl();

    @InjectMocks
    TransactionServiceImpl transactionService;

    private User user;
    private Category category;
    private Transaction transaction;

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
                .name("Зарплата")
                .user(user)
                .build();

        transaction = Transaction.builder()
                .id(50L)
                .amount(new BigDecimal("1000"))
                .date(LocalDateTime.now())
                .type(TransactionType.INCOME)
                .category(category)
                .user(user)
                .currency(Currency.BYN)
                .build();
    }

    // ── create ─────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("create: успешное создание транзакции")
    void create_validData_transactionSaved() {
        TransactionCreateDto dto = buildCreateDto(new BigDecimal("1000"), TransactionType.INCOME, 10L);
        TransactionDto expectedDto = new TransactionDto();

        when(userService.getCurrentUser()).thenReturn(user);
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(category));
        when(transactionMapper.toEntity(dto)).thenReturn(transaction);
        when(transactionRepository.save(any(Transaction.class))).thenReturn(transaction);
        when(transactionMapper.toDto(transaction)).thenReturn(expectedDto);

        TransactionDto result = transactionService.create(dto);

        assertThat(result).isNotNull();
        verify(transactionRepository).save(transaction);
    }

    @Test
    @DisplayName("create: чужая категория → AccessDeniedException")
    void create_foreignCategory_throwsAccessDenied() {
        User anotherUser = User.builder().id(99L).build();
        Category foreignCat = Category.builder().id(10L).user(anotherUser).build();

        TransactionCreateDto dto = buildCreateDto(new BigDecimal("100"), TransactionType.EXPENSE, 10L);

        when(userService.getCurrentUser()).thenReturn(user);
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(foreignCat));

        assertThatThrownBy(() -> transactionService.create(dto))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("create: категория не найдена → ResourceNotFoundException")
    void create_categoryNotFound_throwsException() {
        TransactionCreateDto dto = buildCreateDto(new BigDecimal("100"), TransactionType.EXPENSE, 999L);

        when(userService.getCurrentUser()).thenReturn(user);
        when(categoryRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> transactionService.create(dto))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ── delete ─────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("delete: чужая транзакция → AccessDeniedException")
    void delete_foreignTransaction_throwsAccessDenied() {
        User anotherUser = User.builder().id(99L).build();
        Transaction foreignTx = Transaction.builder().id(50L).user(anotherUser).build();

        when(userService.getCurrentUser()).thenReturn(user);
        when(transactionRepository.findById(50L)).thenReturn(Optional.of(foreignTx));

        assertThatThrownBy(() -> transactionService.delete(50L))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("delete: своя транзакция → удаляется")
    void delete_ownTransaction_deleted() {
        when(userService.getCurrentUser()).thenReturn(user);
        when(transactionRepository.findById(50L)).thenReturn(Optional.of(transaction));

        transactionService.delete(50L);

        verify(transactionRepository).delete(transaction);
    }

    // ── getFullReport ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("getFullReport: totalIncome считается корректно")
    void getFullReport_calculatesTotalIncome() {
        Transaction income1 = buildTx(new BigDecimal("1000"), TransactionType.INCOME);
        Transaction income2 = buildTx(new BigDecimal("500"),  TransactionType.INCOME);

        when(userService.getCurrentUser()).thenReturn(user);
        when(transactionRepository.findAllForCategorySummaryWithDates(anyLong(), any(), any()))
                .thenReturn(List.of(income1, income2));

        LocalDateTime from = LocalDateTime.now().minusDays(30);
        LocalDateTime to   = LocalDateTime.now();

        ReportResponse report = transactionService.getFullReport(from, to);

        assertThat(report.getTotalIncome()).isEqualByComparingTo(new BigDecimal("1500"));
        assertThat(report.getTotalExpense()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(report.getBalance()).isEqualByComparingTo(new BigDecimal("1500"));
    }

    @Test
    @DisplayName("getFullReport: totalExpense считается корректно")
    void getFullReport_calculatesTotalExpense() {
        Transaction expense = buildTx(new BigDecimal("300"), TransactionType.EXPENSE);

        when(userService.getCurrentUser()).thenReturn(user);
        when(transactionRepository.findAllForCategorySummaryWithDates(anyLong(), any(), any()))
                .thenReturn(List.of(expense));

        LocalDateTime from = LocalDateTime.now().minusDays(30);
        LocalDateTime to   = LocalDateTime.now();

        ReportResponse report = transactionService.getFullReport(from, to);

        assertThat(report.getTotalExpense()).isEqualByComparingTo(new BigDecimal("300"));
        assertThat(report.getBalance()).isEqualByComparingTo(new BigDecimal("-300"));
    }

    @Test
    @DisplayName("getFullReport: пустой период → нули")
    void getFullReport_emptyPeriod_zeros() {
        when(userService.getCurrentUser()).thenReturn(user);
        when(transactionRepository.findAllForCategorySummaryWithDates(anyLong(), any(), any()))
                .thenReturn(List.of());

        ReportResponse report = transactionService.getFullReport(
                LocalDateTime.now().minusDays(7), LocalDateTime.now());

        assertThat(report.getTotalIncome()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(report.getTotalExpense()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(report.getCategoryExpenses()).isEmpty();
    }

    @Test
    @DisplayName("getFullReport: dailySummaries сортированы по дате")
    void getFullReport_dailySummariesSortedByDate() {
        Transaction tx1 = buildTxOnDate(new BigDecimal("100"), TransactionType.EXPENSE,
                LocalDateTime.now().minusDays(2));
        Transaction tx2 = buildTxOnDate(new BigDecimal("200"), TransactionType.INCOME,
                LocalDateTime.now().minusDays(5));

        when(userService.getCurrentUser()).thenReturn(user);
        when(transactionRepository.findAllForCategorySummaryWithDates(anyLong(), any(), any()))
                .thenReturn(List.of(tx1, tx2));

        ReportResponse report = transactionService.getFullReport(
                LocalDateTime.now().minusDays(7), LocalDateTime.now());

        assertThat(report.getDailySummaries()).isSortedAccordingTo(
                (a, b) -> a.getDate().compareTo(b.getDate()));
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    private TransactionCreateDto buildCreateDto(BigDecimal amount, TransactionType type, Long catId) {
        TransactionCreateDto dto = new TransactionCreateDto();
        dto.setAmount(amount);
        dto.setType(type);
        dto.setCategoryId(catId);
        dto.setDate(LocalDateTime.now());
        dto.setCurrency(Currency.BYN);
        return dto;
    }

    private Transaction buildTx(BigDecimal amount, TransactionType type) {
        return buildTxOnDate(amount, type, LocalDateTime.now());
    }

    private Transaction buildTxOnDate(BigDecimal amount, TransactionType type, LocalDateTime date) {
        return Transaction.builder()
                .id((long) (Math.random() * 10000))
                .amount(amount)
                .type(type)
                .category(category)
                .user(user)
                .currency(Currency.BYN)
                .date(date)
                .build();
    }
}