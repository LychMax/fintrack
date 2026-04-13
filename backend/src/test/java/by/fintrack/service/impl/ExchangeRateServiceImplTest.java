package by.fintrack.service.impl;

import by.fintrack.entity.Currency;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

@DisplayName("ExchangeRateServiceImpl")
class ExchangeRateServiceImplTest {

    private ExchangeRateServiceImpl service;

    @BeforeEach
    void setUp() {
        // Используем конструктор — он проставляет дефолтные курсы без HTTP-запроса
        service = new ExchangeRateServiceImpl();
    }

    @Test
    @DisplayName("BYN → BYN: должен вернуть ту же сумму")
    void convert_sameFromTo_returnsIdentity() {
        BigDecimal amount = new BigDecimal("100.00");
        BigDecimal result = service.convert(amount, Currency.BYN, Currency.BYN);
        assertThat(result).isEqualByComparingTo(amount);
    }

    @Test
    @DisplayName("null amount → должен вернуть ZERO")
    void convert_nullAmount_returnsZero() {
        BigDecimal result = service.convert(null, Currency.USD, Currency.BYN);
        assertThat(result).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    @DisplayName("USD → BYN: рассчитывается через дефолтный курс 3.25")
    void convert_usdToByn_usesDefaultRate() {
        // 10 USD * 3.25 / 1 = 32.50 BYN
        BigDecimal result = service.convert(new BigDecimal("10"), Currency.USD, Currency.BYN);
        assertThat(result).isEqualByComparingTo(new BigDecimal("32.50"));
    }

    @Test
    @DisplayName("BYN → USD: обратная конвертация через дефолтный курс")
    void convert_bynToUsd_usesDefaultRate() {
        // 32.50 BYN / 3.25 = 10.00 USD
        BigDecimal result = service.convert(new BigDecimal("32.50"), Currency.BYN, Currency.USD);
        assertThat(result).isEqualByComparingTo(new BigDecimal("10.00"));
    }

    @Test
    @DisplayName("USD → EUR: кросс-курс через BYN")
    void convert_usdToEur_crossRateViaByn() {
        // 10 USD * 3.25 / 3.55 ≈ 9.15 EUR
        BigDecimal result = service.convert(new BigDecimal("10"), Currency.USD, Currency.EUR);
        // Погрешность ±0.05 — курсы дефолтные
        assertThat(result.doubleValue()).isCloseTo(9.15, within(0.05));
    }

    @Test
    @DisplayName("convertToMainCurrency делегирует в convert")
    void convertToMainCurrency_delegatesToConvert() {
        BigDecimal amount = new BigDecimal("50");
        BigDecimal direct  = service.convert(amount, Currency.RUB, Currency.BYN);
        BigDecimal viaMain = service.convertToMainCurrency(amount, Currency.RUB, Currency.BYN);
        assertThat(viaMain).isEqualByComparingTo(direct);
    }

    @Test
    @DisplayName("Нулевая сумма конвертируется в нуль")
    void convert_zeroAmount_returnsZero() {
        BigDecimal result = service.convert(BigDecimal.ZERO, Currency.USD, Currency.EUR);
        assertThat(result).isEqualByComparingTo(BigDecimal.ZERO);
    }
}