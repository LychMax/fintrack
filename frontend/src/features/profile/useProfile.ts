import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import api from "@/lib/api";
import { UserDto, UpdateProfileDto, ChangePasswordDto, Currency } from "@/types";
import { useAuthStore } from "@/store/useAuthStore";

export const useProfile = () =>
  useQuery<UserDto>({
    queryKey: ["profile"],
    queryFn: () => api.get("/auth/profile").then((r) => r.data),
  });

export const useUpdateProfile = () => {
  const qc = useQueryClient();
  const setUserInfo = useAuthStore((s) => s.setUserInfo);
  const setToken = useAuthStore((s) => s.setToken);
  return useMutation({
    mutationFn: (data: UpdateProfileDto) =>
      api.put("/auth/profile", data).then((r) => r.data as UserDto),
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ["profile"] });
      if (data.token) {
        setToken(data.token);
      } else {
        setUserInfo({
          username: data.username,
          email: data.email,
          mainCurrency: data.mainCurrency as Currency,
        });
      }
      // Refresh all data after currency change
      qc.invalidateQueries({ queryKey: ["transactions"] });
      qc.invalidateQueries({ queryKey: ["budget-statuses"] });
      qc.invalidateQueries({ queryKey: ["reports"] });
      qc.invalidateQueries({ queryKey: ["category-summary"] });
    },
  });
};

export const useChangePassword = () =>
  useMutation({
    mutationFn: (data: ChangePasswordDto) =>
      api.put("/auth/profile/password", data),
  });