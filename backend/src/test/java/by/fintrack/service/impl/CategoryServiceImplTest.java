package by.fintrack.service.impl;

import by.fintrack.dto.category.CategoryCreateDto;
import by.fintrack.dto.category.CategoryDto;
import by.fintrack.entity.Category;
import by.fintrack.entity.User;
import by.fintrack.exception.ResourceNotFoundException;
import by.fintrack.mapper.CategoryMapper;
import by.fintrack.repository.CategoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("CategoryServiceImpl")
class CategoryServiceImplTest {

    @Mock CategoryRepository categoryRepository;
    @Mock CategoryMapper categoryMapper;
    @Mock UserServiceImpl userService;

    @InjectMocks
    CategoryServiceImpl categoryService;

    private User owner;
    private User stranger;
    private Category category;

    @BeforeEach
    void setUp() {
        owner = User.builder().id(1L).username("owner").build();
        stranger = User.builder().id(2L).username("stranger").build();
        category = Category.builder().id(10L).name("Еда").user(owner).build();
    }

    @Test
    @DisplayName("getAllForCurrentUser: возвращает только категории текущего пользователя")
    void getAllForCurrentUser_returnsMappedCategories() {
        CategoryDto dto = new CategoryDto();
        dto.setId(10L);
        dto.setName("Еда");

        when(userService.getCurrentUser()).thenReturn(owner);
        when(categoryRepository.findByUser(owner)).thenReturn(List.of(category));
        when(categoryMapper.toDto(category)).thenReturn(dto);

        List<CategoryDto> result = categoryService.getAllForCurrentUser();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Еда");
    }

    @Test
    @DisplayName("create: категория создаётся с правильным пользователем")
    void create_setsUserAndSaves() {
        CategoryCreateDto dto = new CategoryCreateDto();
        dto.setName("Транспорт");

        Category entity = Category.builder().name("Транспорт").build();
        Category saved  = Category.builder().id(11L).name("Транспорт").user(owner).build();
        CategoryDto resultDto = new CategoryDto();
        resultDto.setId(11L);

        when(userService.getCurrentUser()).thenReturn(owner);
        when(categoryMapper.toEntity(dto)).thenReturn(entity);
        when(categoryRepository.save(entity)).thenReturn(saved);
        when(categoryMapper.toDto(saved)).thenReturn(resultDto);

        CategoryDto result = categoryService.create(dto);

        assertThat(entity.getUser()).isEqualTo(owner);
        assertThat(result.getId()).isEqualTo(11L);
    }

    @Test
    @DisplayName("update: чужая категория → AccessDeniedException")
    void update_foreignCategory_throwsAccessDenied() {
        Category foreignCat = Category.builder().id(10L).name("Еда").user(stranger).build();
        CategoryCreateDto dto = new CategoryCreateDto();
        dto.setName("NewName");

        when(userService.getCurrentUser()).thenReturn(owner);
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(foreignCat));

        assertThatThrownBy(() -> categoryService.update(10L, dto))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("update: своя категория → имя обновляется")
    void update_ownCategory_updatesName() {
        CategoryCreateDto dto = new CategoryCreateDto();
        dto.setName("Рестораны");

        CategoryDto updatedDto = new CategoryDto();
        updatedDto.setName("Рестораны");

        when(userService.getCurrentUser()).thenReturn(owner);
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(category));
        when(categoryRepository.save(category)).thenReturn(category);
        when(categoryMapper.toDto(category)).thenReturn(updatedDto);

        CategoryDto result = categoryService.update(10L, dto);

        assertThat(category.getName()).isEqualTo("Рестораны");
        assertThat(result.getName()).isEqualTo("Рестораны");
    }

    @Test
    @DisplayName("delete: категория не найдена → ResourceNotFoundException")
    void delete_notFound_throwsException() {
        when(userService.getCurrentUser()).thenReturn(owner);
        when(categoryRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> categoryService.delete(999L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("delete: своя категория → удаляется")
    void delete_ownCategory_deleted() {
        when(userService.getCurrentUser()).thenReturn(owner);
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(category));

        categoryService.delete(10L);

        verify(categoryRepository).delete(category);
    }
}