package by.fintrack.entity;

public enum Currency {
    BYN("BYN", "Br"),
    USD("USD", "$"),
    EUR("EUR", "€"),
    RUB("RUB", "₽");

    public final String code;

    public final String symbol;

    Currency(String code, String symbol) {
        this.code = code;
        this.symbol = symbol;
    }

    public static Currency fromCode(String code) {
        for (Currency c : values()) {
            if (c.code.equalsIgnoreCase(code)) return c;
        }
        return BYN;
    }
}