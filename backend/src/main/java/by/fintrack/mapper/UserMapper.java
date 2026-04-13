package by.fintrack.mapper;

import by.fintrack.dto.user.UserDto;
import by.fintrack.dto.user.UserRegistrationDto;
import by.fintrack.entity.Currency;
import by.fintrack.entity.User;
import org.springframework.stereotype.Component;

@Component
public class UserMapper {

    public User toEntity(UserRegistrationDto dto) {
        return User.builder()
                .username(dto.getUsername())
                .email(dto.getEmail())
                .password(dto.getPassword())
                .mainCurrency(Currency.BYN)
                .build();
    }

    public UserDto toDto(User user) {
        UserDto dto = new UserDto();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setMainCurrency(user.getMainCurrency());
        return dto;
    }
}