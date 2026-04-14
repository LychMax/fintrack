import { useAuthStore } from "@/store/useAuthStore";
import { useFullReport } from "@/features/reports/useReports";
import { useBudgetStatuses } from "@/features/budgets/useBudgets";
import { useTransactions } from "@/features/transactions/useTransactions";
import { Currency, CurrencySymbol, TransactionType } from "@/types";
import { format, startOfMonth, endOfMonth, endOfYear } from "date-fns";
import { ru } from "date-fns/locale";
import { Link } from "react-router-dom";
import {
  TrendingUp,
  TrendingDown,
  Wallet,
  ArrowUpRight,
  ArrowDownRight,
  AlertTriangle,
  ChevronRight,
  Plus,
  Receipt,
} from "lucide-react";

export default function Dashboard() {
  const { mainCurrency, username } = useAuthStore();
  const currency = mainCurrency as Currency;

  const mainSymbol = CurrencySymbol[currency] || "Br";
  const decimalPlaces = currency === "USD" || currency === "EUR" ? 2 : 0;

  const fmt = (amount: number = 0): string => {
    return `${mainSymbol} ${amount.toLocaleString("ru-RU", {
      minimumFractionDigits: decimalPlaces,
      maximumFractionDigits: decimalPlaces,
    })}`;
  };

  const today = new Date();
  const monthFrom = format(startOfMonth(today), "yyyy-MM-dd");
  const monthTo = format(endOfMonth(today), "yyyy-MM-dd");
  const yearTo = format(endOfYear(today), "yyyy-MM-dd");

  const { data: monthReport } = useFullReport(monthFrom, monthTo);
  const { data: allTimeReport } = useFullReport("2000-01-01", yearTo);
  const { data: budgetStatuses = [] } = useBudgetStatuses();
  const { data: recentPage } = useTransactions({ page: 0, size: 7 });
  const recentTransactions = recentPage?.content || [];

  const avatarLetter = (username || "U").charAt(0).toUpperCase();

  return (
    <div className="space-y-5 lg:space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl lg:text-3xl font-bold text-foreground">Главная</h1>
        <div className="hidden lg:flex items-center gap-3">
          <div className="w-11 h-11 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-white font-bold shadow-lg">
            {avatarLetter}
          </div>
        </div>
      </div>

      {/* Balance card */}
      <div
        className="rounded-2xl lg:rounded-3xl p-5 lg:p-8 relative overflow-hidden"
        style={{
          background:
            "linear-gradient(135deg, rgba(236,72,153,0.15) 0%, rgba(168,85,247,0.15) 100%)",
          border: "1px solid rgba(236,72,153,0.2)",
        }}
      >
        <div
          className="absolute inset-0"
          style={{
            backgroundImage:
              "radial-gradient(circle at 80% 20%, rgba(168,85,247,0.1) 0%, transparent 50%)",
          }}
        />
        <div className="relative z-10">
          <p className="text-xs lg:text-sm text-slate-400 mb-2 font-medium">
            Общий баланс (за всё время)
          </p>
          <h2 className="text-3xl lg:text-5xl font-bold text-white mb-4 lg:mb-6 break-all">
            {fmt(allTimeReport?.balance ?? 0)}
          </h2>
          <div className="flex flex-col sm:flex-row gap-4 sm:gap-8">
            <div>
              <p className="text-xs text-slate-400 mb-1 flex items-center gap-1">
                <TrendingUp className="w-3 h-3 text-green-400" /> Все доходы
              </p>
              <p className="text-lg lg:text-xl font-bold text-green-400">
                {fmt(allTimeReport?.totalIncome ?? 0)}
              </p>
            </div>
            <div>
              <p className="text-xs text-slate-400 mb-1 flex items-center gap-1">
                <TrendingDown className="w-3 h-3 text-red-400" /> Все расходы
              </p>
              <p className="text-lg lg:text-xl font-bold text-red-400">
                {fmt(allTimeReport?.totalExpense ?? 0)}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Month stats */}
      <div>
        <h2 className="text-base lg:text-lg font-semibold text-foreground mb-3 capitalize">
          Статистика за {format(today, "LLLL", { locale: ru })}
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 lg:gap-4">
          <StatCard
            title="Доход за месяц"
            value={fmt(monthReport?.totalIncome ?? 0)}
            color="#22c55e"
            icon={ArrowUpRight}
          />
          <StatCard
            title="Расход за месяц"
            value={fmt(monthReport?.totalExpense ?? 0)}
            color="#ef4444"
            icon={ArrowDownRight}
          />
          <StatCard
            title="Баланс за месяц"
            value={fmt(
              (monthReport?.totalIncome ?? 0) - (monthReport?.totalExpense ?? 0)
            )}
            color="#EC4899"
            icon={Wallet}
          />
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4 lg:gap-8">
        {/* Budgets */}
        <div
          className="rounded-2xl p-4 lg:p-6"
          style={{
            background: "rgba(30,41,59,0.6)",
            border: "1px solid rgba(51,65,85,0.5)",
          }}
        >
          <div className="flex items-center justify-between mb-4 lg:mb-5">
            <h3 className="font-semibold text-foreground">Бюджеты</h3>
            <Link
              to="/budgets"
              className="text-sm text-primary hover:text-primary/80 flex items-center gap-1 transition-colors"
            >
              Все <ChevronRight className="w-3 h-3" />
            </Link>
          </div>

          {budgetStatuses.length === 0 ? (
            <div className="text-center py-6 lg:py-8">
              <Wallet className="w-10 h-10 text-muted-foreground mx-auto mb-3 opacity-50" />
              <p className="text-muted-foreground text-sm mb-4">
                Бюджеты не установлены
              </p>
              <Link
                to="/budgets"
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-white transition-all hover:opacity-90"
                style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)" }}
              >
                <Plus className="w-4 h-4" /> Добавить бюджет
              </Link>
            </div>
          ) : (
            <div className="space-y-4">
              {budgetStatuses.slice(0, 5).map((b) => {
                const pct = Math.min(b.percentUsed, 100);
                const barColor = b.exceeded
                  ? "#ef4444"
                  : b.nearLimit
                  ? "#f59e0b"
                  : "#22c55e";
                const symbol = CurrencySymbol[b.currency as Currency] || "Br";

                return (
                  <div key={b.id}>
                    <div className="flex items-center justify-between mb-1.5">
                      <div className="flex items-center gap-2 min-w-0">
                        {b.exceeded && (
                          <AlertTriangle className="w-3.5 h-3.5 text-red-400 flex-shrink-0" />
                        )}
                        {!b.exceeded && b.nearLimit && (
                          <AlertTriangle className="w-3.5 h-3.5 text-amber-400 flex-shrink-0" />
                        )}
                        <span className="text-sm font-medium text-foreground truncate">
                          {b.categoryName}
                        </span>
                        <span className="text-xs text-muted-foreground flex-shrink-0">
                          {b.periodType === "MONTHLY" ? "/ мес." : "/ нед."}
                        </span>
                      </div>
                      <span
                        className="text-xs font-medium flex-shrink-0 ml-2"
                        style={{ color: barColor }}
                      >
                        {b.percentUsed.toFixed(0)}%
                      </span>
                    </div>
                    <div
                      className="h-2 rounded-full overflow-hidden"
                      style={{ background: "rgba(51,65,85,0.8)" }}
                    >
                      <div
                        className="h-full rounded-full transition-all duration-500"
                        style={{ width: `${pct}%`, background: barColor }}
                      />
                    </div>
                    <div className="flex justify-between mt-1">
                      <span className="text-xs text-muted-foreground">
                        {symbol} {b.spentAmount.toFixed(0)} / {symbol}{" "}
                        {b.budgetAmount.toFixed(0)}
                      </span>
                      <span className="text-xs" style={{ color: barColor }}>
                        {b.exceeded
                          ? `+${symbol} ${(b.spentAmount - b.budgetAmount).toFixed(0)}`
                          : `ост. ${symbol} ${b.remainingAmount.toFixed(0)}`}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Recent transactions */}
        <div
          className="rounded-2xl p-4 lg:p-6"
          style={{
            background: "rgba(30,41,59,0.6)",
            border: "1px solid rgba(51,65,85,0.5)",
          }}
        >
          <div className="flex items-center justify-between mb-4 lg:mb-5">
            <h3 className="font-semibold text-foreground">Последние операции</h3>
            <Link
              to="/transactions"
              className="text-sm text-primary hover:text-primary/80 flex items-center gap-1 transition-colors"
            >
              Все <ChevronRight className="w-3 h-3" />
            </Link>
          </div>

          {recentTransactions.length === 0 ? (
            <div className="text-center py-6 lg:py-8">
              <Receipt className="w-10 h-10 text-muted-foreground mx-auto mb-3 opacity-50" />
              <p className="text-muted-foreground text-sm mb-4">Нет транзакций</p>
              <Link
                to="/transactions"
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-white transition-all hover:opacity-90"
                style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)" }}
              >
                <Plus className="w-4 h-4" /> Добавить
              </Link>
            </div>
          ) : (
            <div className="space-y-3">
              {recentTransactions.map((t) => {
                const isIncome = t.type === TransactionType.INCOME;
                const color = isIncome ? "#22c55e" : "#ef4444";
                const sign = isIncome ? "+" : "-";

                return (
                  <div
                    key={t.id}
                    className="flex items-center gap-3 py-2 border-b border-border/20 last:border-0"
                  >
                    <div
                      className="w-8 h-8 lg:w-9 lg:h-9 rounded-full flex items-center justify-center flex-shrink-0"
                      style={{ background: `${color}20` }}
                    >
                      {isIncome ? (
                        <ArrowUpRight className="w-4 h-4" style={{ color }} />
                      ) : (
                        <ArrowDownRight className="w-4 h-4" style={{ color }} />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-foreground truncate">
                        {t.category.name}
                      </p>
                      {t.description && (
                        <p className="text-xs text-muted-foreground truncate">
                          {t.description}
                        </p>
                      )}
                      <p className="text-xs text-muted-foreground">
                        {format(new Date(t.date), "dd MMM", { locale: ru })}
                      </p>
                    </div>
                    <p
                      className="text-sm font-bold flex-shrink-0"
                      style={{ color }}
                    >
                      {sign} {mainSymbol}{" "}
                      {t.amount.toLocaleString("ru-RU", {
                        minimumFractionDigits: 2,
                      })}
                    </p>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function StatCard({ title, value, color, icon: Icon }: any) {
  return (
    <div
      className="rounded-2xl p-4 lg:p-6 flex flex-col gap-3 relative overflow-hidden"
      style={{
        background: "rgba(30,41,59,0.6)",
        border: "1px solid rgba(51,65,85,0.5)",
      }}
    >
      <div
        className="absolute top-0 right-0 w-32 h-32 rounded-full opacity-5"
        style={{
          background: color,
          filter: "blur(30px)",
          transform: "translate(30%, -30%)",
        }}
      />
      <div className="flex items-center justify-between">
        <span className="text-sm text-muted-foreground font-medium">{title}</span>
        <div
          className="w-9 h-9 rounded-xl flex items-center justify-center"
          style={{ background: `${color}20` }}
        >
          <Icon className="w-4 h-4" style={{ color }} />
        </div>
      </div>
      <p className="text-xl lg:text-2xl font-bold text-foreground break-all">
        {value}
      </p>
    </div>
  );
}