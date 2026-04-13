package by.fintrack.service.impl;

import by.fintrack.dto.profile.ChangePasswordDto;
import by.fintrack.dto.profile.UpdateProfileDto;
import by.fintrack.dto.user.UserDto;
import by.fintrack.dto.user.UserLoginDto;
import by.fintrack.dto.user.UserRegistrationDto;
import by.fintrack.entity.Currency;
import by.fintrack.entity.User;
import by.fintrack.exception.ResourceNotFoundException;
import by.fintrack.mapper.UserMapper;
import by.fintrack.repository.UserRepository;
import by.fintrack.security.JwtTokenProvider;
import by.fintrack.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider tokenProvider;
    private final DefaultCategoryServiceImpl defaultCategoryServiceImpl;

    @Transactional
    public UserDto register(UserRegistrationDto dto) {
        if (userRepository.findByUsername(dto.getUsername()).isPresent()) {
            throw new IllegalArgumentException("Пользователь с таким именем уже существует");
        }
        if (userRepository.existsByEmail(dto.getEmail())) {
            throw new IllegalArgumentException("Пользователь с таким email уже существует");
        }

        User user = userMapper.toEntity(dto);
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        user.setMainCurrency(Currency.BYN);

        User savedUser = userRepository.save(user);
        defaultCategoryServiceImpl.createDefaultCategoriesForUser(savedUser);

        return userMapper.toDto(savedUser);
    }

    public String login(UserLoginDto dto) {
        User user = userRepository.findByUsername(dto.getLogin())
                .or(() -> userRepository.findByEmail(dto.getLogin()))
                .orElseThrow(() -> new BadCredentialsException("Неверный логин или пароль"));

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(user.getUsername(), dto.getPassword())
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        return tokenProvider.generateToken(authentication);
    }

    @Override
    public UserDto getCurrentUserDto() {
        User user = getCurrentUser();
        return userMapper.toDto(user);
    }

    @Override
    @Transactional
    public UserDto updateProfile(UpdateProfileDto dto) {
        User user = getCurrentUser();
        boolean currencyChanged = false;

        if (dto.getUsername() != null && !dto.getUsername().trim().isEmpty()
                && !dto.getUsername().equals(user.getUsername())) {

            if (userRepository.existsByUsername(dto.getUsername())) {
                throw new IllegalArgumentException("Пользователь с таким логином уже существует");
            }
            user.setUsername(dto.getUsername().trim());
        }

        if (dto.getEmail() != null && !dto.getEmail().trim().isEmpty()
                && !dto.getEmail().equals(user.getEmail())) {

            if (userRepository.existsByEmail(dto.getEmail())) {
                throw new IllegalArgumentException("Пользователь с таким email уже существует");
            }
            user.setEmail(dto.getEmail().trim());
        }

        if (dto.getMainCurrency() != null && dto.getMainCurrency() != user.getMainCurrency()) {
            user.setMainCurrency(dto.getMainCurrency());
            currencyChanged = true;
        }

        User saved = userRepository.save(user);
        UserDto userDto = userMapper.toDto(saved);

        if (currencyChanged) {
            String newToken = tokenProvider.generateToken(saved);
            userDto.setToken(newToken);
        }

        return userDto;
    }

    @Override
    @Transactional
    public void changePassword(ChangePasswordDto dto) {
        User user = getCurrentUser();

        if (!passwordEncoder.matches(dto.getOldPassword(), user.getPassword())) {
            throw new BadCredentialsException("Неверный текущий пароль");
        }

        user.setPassword(passwordEncoder.encode(dto.getNewPassword()));
        userRepository.save(user);
    }

    public User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }
}