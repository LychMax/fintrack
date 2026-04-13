package by.fintrack.dto.category;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CategoryCreateDto {

    @NotBlank @Size(max = 100)
    private String name;
}