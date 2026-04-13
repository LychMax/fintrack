package by.fintrack.service;

import by.fintrack.dto.budget.BudgetCreateDto;
import by.fintrack.dto.budget.BudgetDto;
import by.fintrack.dto.budget.BudgetStatusDto;

import java.util.List;

public interface BudgetService {

    List<BudgetDto> getAllForCurrentUser();

    List<BudgetStatusDto> getStatusForCurrentUser();

    BudgetDto createOrUpdate(BudgetCreateDto dto);

    void delete(Long id);
}