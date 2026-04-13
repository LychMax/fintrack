import { create } from "zustand";
import { Currency } from "@/types";
import { jwtDecode } from "jwt-decode";

interface JwtPayload {
  sub: string;
  email?: string;
  mainCurrency?: string;
  exp?: number;
}

interface AuthState {
  token: string | null;
  username: string | null;
  email: string | null;
  mainCurrency: Currency;
  setToken: (token: string | null) => void;
  setUserInfo: (info: { username?: string; email?: string; mainCurrency?: Currency }) => void;
  isAuthenticated: () => boolean;
}

function parseToken(token: string): Partial<AuthState> {
  try {
    const payload = jwtDecode<JwtPayload>(token);
    return {
      username: payload.sub || null,
      email: payload.email || null,
      mainCurrency: (payload.mainCurrency as Currency) || Currency.BYN,
    };
  } catch {
    return {};
  }
}

const storedToken = sessionStorage.getItem("token");
const parsedFromStorage = storedToken ? parseToken(storedToken) : {};

export const useAuthStore = create<AuthState>((set, get) => ({
  token: storedToken,
  username: parsedFromStorage.username || null,
  email: parsedFromStorage.email || null,
  mainCurrency: parsedFromStorage.mainCurrency || Currency.BYN,

  setToken: (token) => {
    if (token) {
      sessionStorage.setItem("token", token);
      const parsed = parseToken(token);
      set({ token, ...parsed });
    } else {
      sessionStorage.removeItem("token");
      set({ token: null, username: null, email: null, mainCurrency: Currency.BYN });
    }
  },

  setUserInfo: (info) => {
    set((s) => ({
      username: info.username ?? s.username,
      email: info.email ?? s.email,
      mainCurrency: info.mainCurrency ?? s.mainCurrency,
    }));
  },

  isAuthenticated: () => !!get().token,
}));