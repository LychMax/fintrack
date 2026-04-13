package by.fintrack.repository;

import by.fintrack.entity.Budget;
import by.fintrack.entity.Budget.PeriodType;
import by.fintrack.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BudgetRepository extends JpaRepository<Budget, Long> {

    List<Budget> findByUser(User user);

    Optional<Budget> findByUserAndCategoryIdAndPeriodType(User user, Long categoryId, PeriodType periodType);

    boolean existsByUserAndCategoryIdAndPeriodType(User user, Long categoryId, PeriodType periodType);
}