package by.fintrack.repository;

import by.fintrack.entity.Transaction;
import by.fintrack.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface TransactionRepository extends JpaRepository<Transaction, Long>, JpaSpecificationExecutor<Transaction> {

    Page<Transaction> findByUser(User user, Pageable pageable);

    @Query("SELECT t FROM Transaction t JOIN FETCH t.category WHERE t.user.id = :userId")
    List<Transaction> findAllForCategorySummary(@Param("userId") Long userId);

    @Query("SELECT t FROM Transaction t JOIN FETCH t.category " +
            "WHERE t.user.id = :userId " +
            "AND t.date >= :from AND t.date <= :to")
    List<Transaction> findAllForCategorySummaryWithDates(
            @Param("userId") Long userId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);
}