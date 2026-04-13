package by.fintrack.service;

import by.fintrack.entity.Currency;

import java.math.BigDecimal;

public interface ExchangeRateService {

    BigDecimal convert(BigDecimal amount, Currency from, Currency to);

    BigDecimal convertToMainCurrency(BigDecimal amount, Currency transactionCurrency, Currency mainCurrency);
}
