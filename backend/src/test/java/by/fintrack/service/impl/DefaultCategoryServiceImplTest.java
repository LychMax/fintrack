package by.fintrack.service.impl;

import by.fintrack.entity.Category;
import by.fintrack.entity.User;
import by.fintrack.repository.CategoryRepository;
import by.fintrack.util.defualtValue.DefaultCategories;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("DefaultCategoryServiceImpl")
class DefaultCategoryServiceImplTest {

    @Mock CategoryRepository categoryRepository;

    @InjectMocks
    DefaultCategoryServiceImpl defaultCategoryService;

    private User user;

    @BeforeEach
    void setUp() {
        user = User.builder().id(1L).username("alice").build();
    }

    @Test
    @DisplayName("createDefaultCategories: все дефолтные категории сохраняются")
    void createDefaultCategories_savesAllDefaults() {
        // Ни одной категории не существует
        when(categoryRepository.existsByNameAndUser(any(), eq(user))).thenReturn(false);

        defaultCategoryService.createDefaultCategoriesForUser(user);

        int expected = DefaultCategories.INCOME_CATEGORIES.size()
                + DefaultCategories.EXPENSE_CATEGORIES.size();
        verify(categoryRepository, times(expected)).save(any(Category.class));
    }

    @Test
    @DisplayName("createDefaultCategories: дубли не создаются")
    void createDefaultCategories_skipsExisting() {
        // Все уже существуют
        when(categoryRepository.existsByNameAndUser(any(), eq(user))).thenReturn(true);

        defaultCategoryService.createDefaultCategoriesForUser(user);

        verify(categoryRepository, never()).save(any(Category.class));
    }

    @Test
    @DisplayName("createDefaultCategories: сохранённые категории принадлежат пользователю")
    void createDefaultCategories_savedCategoriesHaveCorrectUser() {
        when(categoryRepository.existsByNameAndUser(any(), eq(user))).thenReturn(false);

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        when(categoryRepository.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        defaultCategoryService.createDefaultCategoriesForUser(user);

        captor.getAllValues().forEach(cat ->
                assertThat(cat.getUser()).isEqualTo(user));
    }

    @Test
    @DisplayName("createDefaultCategories: содержит дефолтные названия из констант")
    void createDefaultCategories_containsExpectedNames() {
        when(categoryRepository.existsByNameAndUser(any(), eq(user))).thenReturn(false);

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        when(categoryRepository.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        defaultCategoryService.createDefaultCategoriesForUser(user);

        List<String> savedNames = captor.getAllValues().stream()
                .map(Category::getName)
                .collect(Collectors.toList());

        assertThat(savedNames).containsAll(DefaultCategories.INCOME_CATEGORIES);
        assertThat(savedNames).containsAll(DefaultCategories.EXPENSE_CATEGORIES);
    }
}