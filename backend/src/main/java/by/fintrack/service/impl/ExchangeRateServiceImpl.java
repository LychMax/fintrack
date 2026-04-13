package by.fintrack.service.impl;

import by.fintrack.entity.Currency;
import by.fintrack.service.ExchangeRateService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

@Service
public class ExchangeRateServiceImpl implements ExchangeRateService {

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private final Map<Currency, BigDecimal> ratesToBYN = new HashMap<>();
    private long lastUpdateTime = 0;

    public ExchangeRateServiceImpl() {
        ratesToBYN.put(Currency.BYN, BigDecimal.ONE);
        ratesToBYN.put(Currency.USD, new BigDecimal("3.25"));
        ratesToBYN.put(Currency.EUR, new BigDecimal("3.55"));
        ratesToBYN.put(Currency.RUB, new BigDecimal("0.038"));
    }

    private void updateRates() {
        long currentTime = System.currentTimeMillis();
        if (currentTime - lastUpdateTime < 60 * 60 * 1000) {
            return;
        }

        try {
            String url = "https://api.nbrb.by/exrates/rates?periodicity=0";
            String response = restTemplate.getForObject(url, String.class);

            JsonNode root = objectMapper.readTree(response);

            ratesToBYN.put(Currency.BYN, BigDecimal.ONE);

            for (JsonNode node : root) {
                String curAbbreviation = node.get("Cur_Abbreviation").asText();
                int scale = node.get("Cur_Scale").asInt();
                BigDecimal rate = node.get("Cur_OfficialRate").decimalValue();

                BigDecimal ratePerOne = rate.divide(BigDecimal.valueOf(scale), 6, RoundingMode.HALF_UP);

                switch (curAbbreviation.toUpperCase()) {
                    case "USD" -> ratesToBYN.put(Currency.USD, ratePerOne);
                    case "EUR" -> ratesToBYN.put(Currency.EUR, ratePerOne);
                    case "RUB" -> ratesToBYN.put(Currency.RUB, ratePerOne);
                }
            }

            lastUpdateTime = currentTime;
            System.out.println("Курсы валют успешно обновлены с НБ РБ (" + LocalDate.now() + ")");

        } catch (Exception e) {
            System.err.println("Не удалось обновить курсы с НБ РБ: " + e.getMessage());
        }
    }

    @Override
    public BigDecimal convert(BigDecimal amount, Currency from, Currency to) {
        if (from == to || amount == null) {
            return amount != null ? amount : BigDecimal.ZERO;
        }

        updateRates();

        BigDecimal rateFrom = ratesToBYN.getOrDefault(from, BigDecimal.ONE);
        BigDecimal rateTo = ratesToBYN.getOrDefault(to, BigDecimal.ONE);

        return amount.multiply(rateFrom)
                .divide(rateTo, 6, RoundingMode.HALF_UP)
                .setScale(2, RoundingMode.HALF_UP);
    }

    @Override
    public BigDecimal convertToMainCurrency(BigDecimal amount, Currency transactionCurrency, Currency mainCurrency) {
        return convert(amount, transactionCurrency, mainCurrency);
    }
}