package by.fintrack.service;

import by.fintrack.dto.category.CategoryCreateDto;
import by.fintrack.dto.category.CategoryDto;

import java.util.List;

public interface CategoryService {
    List<CategoryDto> getAllForCurrentUser();

    CategoryDto create(CategoryCreateDto dto);

    CategoryDto update(Long id, CategoryCreateDto dto);

    void delete(Long id);
}