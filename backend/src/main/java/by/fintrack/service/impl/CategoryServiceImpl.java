package by.fintrack.service.impl;

import by.fintrack.dto.category.CategoryCreateDto;
import by.fintrack.dto.category.CategoryDto;
import by.fintrack.entity.Category;
import by.fintrack.entity.User;
import by.fintrack.exception.ResourceNotFoundException;
import by.fintrack.mapper.CategoryMapper;
import by.fintrack.repository.CategoryRepository;
import by.fintrack.service.CategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoryServiceImpl implements CategoryService {

    private final CategoryRepository categoryRepository;
    private final CategoryMapper categoryMapper;
    private final UserServiceImpl userService;

    @Override
    @Transactional(readOnly = true)
    public List<CategoryDto> getAllForCurrentUser() {
        User user = userService.getCurrentUser();
        return categoryRepository.findByUser(user).stream()
                .map(categoryMapper::toDto)
                .toList();
    }

    @Override
    @Transactional
    public CategoryDto create(CategoryCreateDto dto) {
        User user = userService.getCurrentUser();
        Category category = categoryMapper.toEntity(dto);
        category.setUser(user);
        Category saved = categoryRepository.save(category);
        return categoryMapper.toDto(saved);
    }

    @Override
    @Transactional
    public CategoryDto update(Long id, CategoryCreateDto dto) {
        User user = userService.getCurrentUser();
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
        if (!category.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("Not your category");
        }
        category.setName(dto.getName());
        return categoryMapper.toDto(categoryRepository.save(category));
    }

    @Override
    @Transactional
    public void delete(Long id) {
        User user = userService.getCurrentUser();
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
        if (!category.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("Not your category");
        }
        categoryRepository.delete(category);
    }
}