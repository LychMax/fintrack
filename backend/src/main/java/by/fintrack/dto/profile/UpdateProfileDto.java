package by.fintrack.dto.profile;

import by.fintrack.entity.Currency;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateProfileDto {

    @Size(min = 3, max = 50, message = "Логин должен быть от 3 до 50 символов")
    private String username;

    @Email(message = "Некорректный формат email")
    private String email;

    private Currency mainCurrency;
}