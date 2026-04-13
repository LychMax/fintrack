package by.fintrack.mapper;

import by.fintrack.dto.transaction.TransactionCreateDto;
import by.fintrack.dto.transaction.TransactionDto;
import by.fintrack.entity.Transaction;
import by.fintrack.entity.Currency;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class TransactionMapper {

    @Autowired
    private CategoryMapper categoryMapper;

    public Transaction toEntity(TransactionCreateDto dto) {
        return Transaction.builder()
                .amount(dto.getAmount())
                .date(dto.getDate())
                .description(dto.getDescription())
                .type(dto.getType())
                .currency(dto.getCurrency() != null ? dto.getCurrency() : Currency.BYN)
                .build();
    }

    public TransactionDto toDto(Transaction transaction) {
        TransactionDto dto = new TransactionDto();
        dto.setId(transaction.getId());
        dto.setAmount(transaction.getAmount());
        dto.setDate(transaction.getDate());
        dto.setDescription(transaction.getDescription());
        dto.setType(transaction.getType());
        dto.setCurrency(transaction.getCurrency());
        dto.setCategory(categoryMapper.toDto(transaction.getCategory()));
        return dto;
    }
}