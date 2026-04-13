package by.fintrack.dto.user;

import by.fintrack.entity.Currency;
import lombok.Data;

@Data
public class UserDto {

    private Long id;

    private String username;

    private String email;

    private Currency mainCurrency;

    private String token;
}