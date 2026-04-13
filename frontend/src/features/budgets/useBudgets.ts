import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import api from "@/lib/api";
import { BudgetDto, BudgetStatusDto, BudgetCreateDto } from "@/types";

export const useBudgets = () =>
  useQuery<BudgetDto[]>({
    queryKey: ["budgets"],
    queryFn: () => api.get("/budgets").then((r) => r.data),
  });

export const useBudgetStatuses = () =>
  useQuery<BudgetStatusDto[]>({
    queryKey: ["budget-statuses"],
    queryFn: () => api.get("/budgets/status").then((r) => r.data),
  });

export const useCreateOrUpdateBudget = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: BudgetCreateDto) => api.post("/budgets", data).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["budgets"] });
      qc.invalidateQueries({ queryKey: ["budget-statuses"] });
    },
  });
};

export const useDeleteBudget = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => api.delete(`/budgets/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["budgets"] });
      qc.invalidateQueries({ queryKey: ["budget-statuses"] });
    },
  });
};