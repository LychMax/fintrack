package by.fintrack.service.impl;

import by.fintrack.dto.profile.ChangePasswordDto;
import by.fintrack.dto.profile.UpdateProfileDto;
import by.fintrack.dto.user.UserDto;
import by.fintrack.dto.user.UserLoginDto;
import by.fintrack.dto.user.UserRegistrationDto;
import by.fintrack.entity.Currency;
import by.fintrack.entity.User;
import by.fintrack.mapper.UserMapper;
import by.fintrack.repository.UserRepository;
import by.fintrack.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("UserServiceImpl")
class UserServiceImplTest {

    @Mock UserRepository userRepository;
    @Mock UserMapper userMapper;
    @Mock PasswordEncoder passwordEncoder;
    @Mock AuthenticationManager authenticationManager;
    @Mock JwtTokenProvider tokenProvider;
    @Mock DefaultCategoryServiceImpl defaultCategoryServiceImpl;

    @InjectMocks
    UserServiceImpl userService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(1L)
                .username("testuser")
                .email("test@example.com")
                .password("encoded_password")
                .mainCurrency(Currency.BYN)
                .build();
    }

    // ── register ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("register: успешная регистрация создаёт пользователя и дефолтные категории")
    void register_success_createsUserAndDefaultCategories() {
        UserRegistrationDto dto = new UserRegistrationDto();
        dto.setUsername("newuser");
        dto.setEmail("new@example.com");
        dto.setPassword("password123");

        when(userRepository.findByUsername("newuser")).thenReturn(Optional.empty());
        when(userRepository.existsByEmail("new@example.com")).thenReturn(false);
        when(userMapper.toEntity(dto)).thenReturn(testUser);
        when(passwordEncoder.encode(anyString())).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenReturn(testUser);
        when(userMapper.toDto(testUser)).thenReturn(new UserDto());

        userService.register(dto);

        verify(userRepository).save(any(User.class));
        verify(defaultCategoryServiceImpl).createDefaultCategoriesForUser(any(User.class));
    }

    @Test
    @DisplayName("register: дубль username → IllegalArgumentException")
    void register_duplicateUsername_throwsException() {
        UserRegistrationDto dto = new UserRegistrationDto();
        dto.setUsername("testuser");
        dto.setEmail("other@example.com");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));

        assertThatThrownBy(() -> userService.register(dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("именем");
    }

    @Test
    @DisplayName("register: дубль email → IllegalArgumentException")
    void register_duplicateEmail_throwsException() {
        UserRegistrationDto dto = new UserRegistrationDto();
        dto.setUsername("uniqueuser");
        dto.setEmail("test@example.com");

        when(userRepository.findByUsername("uniqueuser")).thenReturn(Optional.empty());
        when(userRepository.existsByEmail("test@example.com")).thenReturn(true);

        assertThatThrownBy(() -> userService.register(dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("email");
    }

    // ── login ──────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("login: верные данные → возвращает JWT токен")
    void login_validCredentials_returnsToken() {
        UserLoginDto dto = new UserLoginDto();
        dto.setLogin("testuser");
        dto.setPassword("password");

        Authentication auth = mock(Authentication.class);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class))).thenReturn(auth);
        when(tokenProvider.generateToken(auth)).thenReturn("jwt.token.here");

        String token = userService.login(dto);

        assertThat(token).isEqualTo("jwt.token.here");
    }

    @Test
    @DisplayName("login: пользователь не найден → BadCredentialsException")
    void login_userNotFound_throwsBadCredentials() {
        UserLoginDto dto = new UserLoginDto();
        dto.setLogin("ghost");
        dto.setPassword("any");

        when(userRepository.findByUsername("ghost")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("ghost")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.login(dto))
                .isInstanceOf(BadCredentialsException.class);
    }

    @Test
    @DisplayName("login: поиск по email тоже работает")
    void login_byEmail_success() {
        UserLoginDto dto = new UserLoginDto();
        dto.setLogin("test@example.com");
        dto.setPassword("password");

        Authentication auth = mock(Authentication.class);
        when(userRepository.findByUsername("test@example.com")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(testUser));
        when(authenticationManager.authenticate(any())).thenReturn(auth);
        when(tokenProvider.generateToken(auth)).thenReturn("token");

        String result = userService.login(dto);
        assertThat(result).isEqualTo("token");
    }

    // ── changePassword ─────────────────────────────────────────────────────────

    @Test
    @DisplayName("changePassword: неверный текущий пароль → BadCredentialsException")
    void changePassword_wrongOldPassword_throwsException() {
        ChangePasswordDto dto = new ChangePasswordDto();
        dto.setOldPassword("wrongpass");
        dto.setNewPassword("newpass123");

        // Мокируем getCurrentUser через SecurityContext — проще через spy или рефлексию.
        // Используем реальный вызов через shim с doReturn.
        UserServiceImpl spy = spy(userService);
        doReturn(testUser).when(spy).getCurrentUser();

        when(passwordEncoder.matches("wrongpass", "encoded_password")).thenReturn(false);

        assertThatThrownBy(() -> spy.changePassword(dto))
                .isInstanceOf(BadCredentialsException.class)
                .hasMessageContaining("пароль");
    }

    @Test
    @DisplayName("changePassword: верный пароль → пароль обновляется")
    void changePassword_correctOldPassword_updatesPassword() {
        ChangePasswordDto dto = new ChangePasswordDto();
        dto.setOldPassword("correct");
        dto.setNewPassword("newpass123");

        UserServiceImpl spy = spy(userService);
        doReturn(testUser).when(spy).getCurrentUser();

        when(passwordEncoder.matches("correct", "encoded_password")).thenReturn(true);
        when(passwordEncoder.encode("newpass123")).thenReturn("new_encoded");
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        spy.changePassword(dto);

        verify(userRepository).save(argThat(u -> "new_encoded".equals(u.getPassword())));
    }

    // ── updateProfile ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("updateProfile: смена валюты → возвращает новый токен в dto")
    void updateProfile_currencyChange_returnsNewToken() {
        UpdateProfileDto dto = new UpdateProfileDto();
        dto.setMainCurrency(Currency.USD);

        UserServiceImpl spy = spy(userService);
        doReturn(testUser).when(spy).getCurrentUser();

        when(userRepository.save(any(User.class))).thenReturn(testUser);
        when(tokenProvider.generateToken(testUser)).thenReturn("new.token");

        UserDto userDto = new UserDto();
        when(userMapper.toDto(testUser)).thenReturn(userDto);

        UserDto result = spy.updateProfile(dto);

        assertThat(result.getToken()).isEqualTo("new.token");
    }

    @Test
    @DisplayName("updateProfile: смена username на уже существующий → IllegalArgumentException")
    void updateProfile_duplicateUsername_throwsException() {
        UpdateProfileDto dto = new UpdateProfileDto();
        dto.setUsername("takenuser");

        UserServiceImpl spy = spy(userService);
        doReturn(testUser).when(spy).getCurrentUser();

        when(userRepository.existsByUsername("takenuser")).thenReturn(true);

        assertThatThrownBy(() -> spy.updateProfile(dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("логином");
    }
}