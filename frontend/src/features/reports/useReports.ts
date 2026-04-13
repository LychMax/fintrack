import { useQuery } from "@tanstack/react-query";
import api from "@/lib/api";
import { CategorySummaryDto, ReportResponse } from "@/types";

export const useCategorySummary = (from: string, to: string) =>
  useQuery<CategorySummaryDto[]>({
    queryKey: ["category-summary", from, to],
    queryFn: () =>
      api
        .get("/transactions/report/category-summary", {
          params: {
            from: from + "T00:00:00",
            to: to + "T23:59:59",
          },
        })
        .then((r) => r.data || []),
    enabled: !!from && !!to,
  });

export const useFullReport = (from: string, to: string) =>
  useQuery<ReportResponse>({
    queryKey: ["reports", from, to],
    queryFn: () =>
      api
        .get("/transactions/report", {
          params: {
            from: from + "T00:00:00",
            to: to + "T23:59:59",
          },
        })
        .then((r) => r.data),
    enabled: !!from && !!to,
  });