import axios from "axios";
import { useAuthStore } from "@/store/useAuthStore";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "/api",
});

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      const url = error.config?.url || "";

      if (url.includes("/auth/login") || 
          url.includes("/auth/register") || 
          url.includes("/auth/logout")) {
        return Promise.reject(error);
      }

      useAuthStore.getState().setToken(null);

      const event = new CustomEvent("auth-error", {
        detail: {
          message: "Вы вошли в аккаунт с другого устройства",
          type: "session-expired"
        }
      });
      window.dispatchEvent(event);

      setTimeout(() => {
        window.location.href = "/";
      }, 800);
    }

    return Promise.reject(error);
  }
);

export default api;