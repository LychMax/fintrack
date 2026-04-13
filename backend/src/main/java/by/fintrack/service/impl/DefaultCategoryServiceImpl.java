package by.fintrack.service.impl;

import by.fintrack.entity.Category;
import by.fintrack.entity.User;
import by.fintrack.repository.CategoryRepository;
import by.fintrack.service.DefaultCategoryService;
import by.fintrack.util.defualtValue.DefaultCategories;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DefaultCategoryServiceImpl implements DefaultCategoryService {

    private final CategoryRepository categoryRepository;

    @Override
    @Transactional
    public void createDefaultCategoriesForUser(User user) {
        for (String name : DefaultCategories.INCOME_CATEGORIES) {
            if (!categoryRepository.existsByNameAndUser(name, user)) {
                Category category = Category.builder()
                        .name(name)
                        .user(user)
                        .build();
                categoryRepository.save(category);
            }
        }

        for (String name : DefaultCategories.EXPENSE_CATEGORIES) {
            if (!categoryRepository.existsByNameAndUser(name, user)) {
                Category category = Category.builder()
                        .name(name)
                        .user(user)
                        .build();
                categoryRepository.save(category);
            }
        }
    }
}