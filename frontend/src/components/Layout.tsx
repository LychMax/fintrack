import { useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { useAuthStore } from "@/store/useAuthStore";
import {
  LayoutDashboard,
  Receipt,
  PieChart,
  Tag,
  Wallet,
  User,
  LogOut,
  TrendingUp,
  Menu,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Currency, CurrencySymbol } from "@/types";

const navItems = [
  { to: "/", icon: LayoutDashboard, label: "Главная" },
  { to: "/transactions", icon: Receipt, label: "Транзакции" },
  { to: "/reports", icon: PieChart, label: "Отчёты" },
  { to: "/budgets", icon: Wallet, label: "Бюджеты" },
  { to: "/categories", icon: Tag, label: "Категории" },
  { to: "/profile", icon: User, label: "Профиль" },
];

export default function Layout({ children }: { children: React.ReactNode }) {
  const navigate = useNavigate();
  const { username, mainCurrency, setToken } = useAuthStore();
  const [mobileOpen, setMobileOpen] = useState(false);

  const avatarLetter = (username || "U").charAt(0).toUpperCase();
  const symbol = CurrencySymbol[mainCurrency as Currency] || "Br";

  const handleLogout = () => {
    setToken(null);
    navigate("/login");
  };

  const SidebarInner = ({ onNavClick }: { onNavClick?: () => void }) => (
    <>
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-6 border-b border-border/30">
        <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-lg">
          <TrendingUp className="w-5 h-5 text-white" />
        </div>
        <span
          className="text-xl font-bold"
          style={{
            background: "linear-gradient(135deg, #EC4899, #A855F7)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          FinTrack
        </span>
      </div>

      {/* User info */}
      <div className="px-4 py-4 border-b border-border/30">
        <div
          className="flex items-center gap-3 px-3 py-3 rounded-xl"
          style={{ background: "rgba(236,72,153,0.08)" }}
        >
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
            {avatarLetter}
          </div>
          <div className="min-w-0">
            <p className="text-sm font-semibold text-foreground truncate">
              {username || "Пользователь"}
            </p>
            <p className="text-xs text-muted-foreground">
              {mainCurrency} {symbol}
            </p>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-4 py-4 space-y-1 overflow-y-auto">
        {navItems.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === "/"}
            onClick={onNavClick}
            className={({ isActive }) =>
              cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200",
                isActive
                  ? "text-white shadow-lg"
                  : "text-muted-foreground hover:text-foreground hover:bg-white/5"
              )
            }
            style={({ isActive }) =>
              isActive
                ? {
                    background:
                      "linear-gradient(135deg, rgba(236,72,153,0.3), rgba(168,85,247,0.3))",
                    borderLeft: "2px solid #EC4899",
                  }
                : {}
            }
          >
            {({ isActive }) => (
              <>
                <Icon
                  className={cn(
                    "w-4 h-4 flex-shrink-0",
                    isActive ? "text-primary" : ""
                  )}
                />
                {label}
              </>
            )}
          </NavLink>
        ))}
      </nav>

      {/* Logout */}
      <div className="px-4 py-4 border-t border-border/30">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-muted-foreground hover:text-red-400 hover:bg-red-500/10 w-full transition-all duration-200"
        >
          <LogOut className="w-4 h-4" />
          Выйти
        </button>
      </div>
    </>
  );

  return (
    <div className="flex min-h-screen bg-background">
      {/* Desktop sidebar */}
      <aside
        className="hidden lg:flex fixed left-0 top-0 h-full w-64 flex-col z-40 border-r border-border/40"
        style={{ background: "rgba(15,23,42,0.97)", backdropFilter: "blur(20px)" }}
      >
        <SidebarInner />
      </aside>

      {/* Mobile: backdrop overlay */}
      {mobileOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/60 lg:hidden"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Mobile: slide-in sidebar */}
      <aside
        className={cn(
          "fixed left-0 top-0 h-full w-72 flex flex-col z-50 border-r border-border/40 transition-transform duration-300 ease-in-out lg:hidden",
          mobileOpen ? "translate-x-0" : "-translate-x-full"
        )}
        style={{ background: "rgba(15,23,42,0.98)", backdropFilter: "blur(20px)" }}
      >
        <button
          onClick={() => setMobileOpen(false)}
          className="absolute top-4 right-4 p-2 rounded-lg text-muted-foreground hover:text-foreground hover:bg-white/10 transition-colors"
        >
          <X className="w-5 h-5" />
        </button>
        <SidebarInner onNavClick={() => setMobileOpen(false)} />
      </aside>

      {/* Main content */}
      <main className="flex-1 lg:ml-64 min-h-screen flex flex-col">
        {/* Mobile top bar */}
        <header
          className="lg:hidden flex items-center justify-between px-4 py-3 border-b border-border/30 sticky top-0 z-30 flex-shrink-0"
          style={{ background: "rgba(15,23,42,0.95)", backdropFilter: "blur(20px)" }}
        >
          <button
            onClick={() => setMobileOpen(true)}
            className="p-2 rounded-xl text-muted-foreground hover:text-foreground hover:bg-white/10 transition-colors"
          >
            <Menu className="w-5 h-5" />
          </button>
          <span
            className="text-base font-bold"
            style={{
              background: "linear-gradient(135deg, #EC4899, #A855F7)",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
            }}
          >
            FinTrack
          </span>
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-white text-sm font-bold">
            {avatarLetter}
          </div>
        </header>

        <div className="flex-1 p-4 lg:p-8 min-w-0">{children}</div>
      </main>
    </div>
  );
}