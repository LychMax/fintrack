import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import api from "@/lib/api";
import { TransactionDto, TransactionCreateDto, PageResponse, TransactionType } from "@/types";

interface TransactionFilters {
  page?: number;
  size?: number;
  from?: string;
  to?: string;
  type?: TransactionType | "";
  categoryId?: number | null;
}

export const useTransactions = (filters: TransactionFilters = {}) => {
  const { page = 0, size = 20, from, to, type, categoryId } = filters;

  const hasFilters = from || to || type || categoryId;

  return useQuery<PageResponse<TransactionDto>>({
    queryKey: ["transactions", page, size, from, to, type, categoryId],
    queryFn: async () => {
      if (hasFilters) {
        const params: Record<string, any> = { page, size, sort: "date,desc" };
        if (from) params.from = from;
        if (to) params.to = to;
        if (type) params.type = type;
        if (categoryId) params.categoryId = categoryId;
        const r = await api.get("/transactions/filtered", { params });
        return r.data;
      } else {
        const r = await api.get("/transactions", {
          params: { page, size, sort: "date,desc" },
        });
        return r.data;
      }
    },
  });
};

export const useAllTransactions = () =>
  useQuery<TransactionDto[]>({
    queryKey: ["transactions-all"],
    queryFn: () =>
      api
        .get("/transactions", { params: { page: 0, size: 1000, sort: "date,desc" } })
        .then((r) => r.data.content || r.data),
  });

export const useCreateTransaction = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: TransactionCreateDto) =>
      api.post("/transactions", data).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["transactions"] });
      qc.invalidateQueries({ queryKey: ["transactions-all"] });
      qc.invalidateQueries({ queryKey: ["budget-statuses"] });
    },
  });
};

export const useUpdateTransaction = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: TransactionCreateDto }) =>
      api.put(`/transactions/${id}`, data).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["transactions"] });
      qc.invalidateQueries({ queryKey: ["transactions-all"] });
      qc.invalidateQueries({ queryKey: ["budget-statuses"] });
    },
  });
};

export const useDeleteTransaction = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => api.delete(`/transactions/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["transactions"] });
      qc.invalidateQueries({ queryKey: ["transactions-all"] });
      qc.invalidateQueries({ queryKey: ["budget-statuses"] });
    },
  });
};