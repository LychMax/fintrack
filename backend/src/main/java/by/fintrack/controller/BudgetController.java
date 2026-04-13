package by.fintrack.controller;

import by.fintrack.dto.budget.BudgetCreateDto;
import by.fintrack.dto.budget.BudgetDto;
import by.fintrack.dto.budget.BudgetStatusDto;
import by.fintrack.service.BudgetService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/budgets")
@RequiredArgsConstructor
public class BudgetController {

    private final BudgetService budgetService;

    @GetMapping
    public ResponseEntity<List<BudgetDto>> getAll() {
        return ResponseEntity.ok(budgetService.getAllForCurrentUser());
    }

    @GetMapping("/status")
    public ResponseEntity<List<BudgetStatusDto>> getStatus() {
        return ResponseEntity.ok(budgetService.getStatusForCurrentUser());
    }

    @PostMapping
    public ResponseEntity<BudgetDto> createOrUpdate(@Valid @RequestBody BudgetCreateDto dto) {
        return ResponseEntity.ok(budgetService.createOrUpdate(dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        budgetService.delete(id);
        return ResponseEntity.noContent().build();
    }
}