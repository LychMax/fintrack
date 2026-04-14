package by.fintrack.service;

import by.fintrack.dto.profile.ChangePasswordDto;
import by.fintrack.dto.profile.UpdateProfileDto;
import by.fintrack.dto.user.UserDto;
import by.fintrack.dto.user.UserLoginDto;
import by.fintrack.dto.user.UserRegistrationDto;
import by.fintrack.entity.User;

public interface UserService {

    UserDto register(UserRegistrationDto dto);

    String login(UserLoginDto dto);

    User getCurrentUser();

    UserDto getCurrentUserDto();

    UserDto updateProfile(UpdateProfileDto dto);

    void changePassword(ChangePasswordDto dto);

    void logout();
}