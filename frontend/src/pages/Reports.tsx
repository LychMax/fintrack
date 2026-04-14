import { useState } from "react";
import { useFullReport } from "@/features/reports/useReports";
import { useAuthStore } from "@/store/useAuthStore";
import { Currency, CurrencySymbol } from "@/types";
import { format, startOfMonth, endOfMonth } from "date-fns";
import { ru } from "date-fns/locale";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
} from "recharts";
import { Loader2, TrendingUp, TrendingDown, Minus, Calendar } from "lucide-react";

const COLORS_EXPENSE = [
  "#ef4444","#f97316","#f59e0b","#eab308","#84cc16",
  "#22c55e","#10b981","#14b8a6","#06b6d4","#3b82f6","#8b5cf6","#ec4899",
];
const COLORS_INCOME = [
  "#22c55e","#10b981","#14b8a6","#06b6d4","#3b82f6",
  "#6366f1","#8b5cf6","#a855f7","#ec4899","#f43f5e","#f97316","#eab308",
];

function SummaryCard({ label, value, color, icon: Icon }: any) {
  return (
    <div
      className="rounded-2xl p-4 lg:p-5 flex items-center gap-4"
      style={{
        background: "rgba(30,41,59,0.6)",
        border: "1px solid rgba(51,65,85,0.5)",
      }}
    >
      <div
        className="w-10 h-10 lg:w-12 lg:h-12 rounded-xl flex items-center justify-center flex-shrink-0"
        style={{ background: `${color}20` }}
      >
        <Icon className="w-5 h-5 lg:w-6 lg:h-6" style={{ color }} />
      </div>
      <div className="min-w-0">
        <p className="text-xs text-muted-foreground mb-1">{label}</p>
        <p className="text-lg lg:text-xl font-bold truncate" style={{ color }}>
          {value}
        </p>
      </div>
    </div>
  );
}

export default function Reports() {
  const { mainCurrency } = useAuthStore();
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
  const [from, setFrom] = useState(format(startOfMonth(today), "yyyy-MM-dd"));
  const [to, setTo] = useState(format(endOfMonth(today), "yyyy-MM-dd"));

  const { data: report, isLoading } = useFullReport(from, to);

  const monthName = format(today, "LLLL yyyy", { locale: ru });

  const expenseData = (report?.categoryExpenses || []).map((c) => ({
    name: c.categoryName,
    value: c.totalExpense,
  }));
  const incomeData = (report?.categoryIncomes || []).map((c) => ({
    name: c.categoryName,
    value: c.totalIncome,
  }));
  const dailyData = (report?.dailySummaries || []).map((d) => ({
    name: format(new Date(d.date), "dd.MM"),
    income: d.income,
    expense: d.expense,
  }));

  return (
    <div className="space-y-5 lg:space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl lg:text-3xl font-bold text-foreground">Отчёты</h1>
          <p className="text-muted-foreground mt-1 capitalize text-sm">{monthName}</p>
        </div>

        {/* Date range */}
        <div
          className="flex flex-col sm:flex-row sm:items-center gap-2 p-3 rounded-2xl"
          style={{
            background: "rgba(30,41,59,0.6)",
            border: "1px solid rgba(51,65,85,0.5)",
          }}
        >
          <div className="flex items-center gap-2">
            <Calendar className="w-4 h-4 text-muted-foreground flex-shrink-0" />
            <input
              type="date"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
              className="bg-transparent text-sm text-foreground outline-none w-full"
            />
          </div>
          <span className="text-muted-foreground text-sm hidden sm:block">—</span>
          <input
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            className="bg-transparent text-sm text-foreground outline-none w-full"
          />
        </div>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-32">
          <Loader2 className="w-10 h-10 animate-spin text-primary" />
        </div>
      ) : (
        <>
          {/* Summary cards */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 lg:gap-4">
            <SummaryCard
              label="Доходы за период"
              value={fmt(report?.totalIncome ?? 0)}
              color="#22c55e"
              icon={TrendingUp}
            />
            <SummaryCard
              label="Расходы за период"
              value={fmt(report?.totalExpense ?? 0)}
              color="#ef4444"
              icon={TrendingDown}
            />
            <SummaryCard
              label="Баланс за период"
              value={fmt(report?.balance ?? 0)}
              color={(report?.balance ?? 0) >= 0 ? "#22c55e" : "#ef4444"}
              icon={Minus}
            />
          </div>

          {/* Daily bar chart */}
          {dailyData.length > 0 && (
            <div
              className="rounded-2xl p-4 lg:p-6"
              style={{
                background: "rgba(30,41,59,0.6)",
                border: "1px solid rgba(51,65,85,0.5)",
              }}
            >
              <h3 className="font-semibold text-foreground mb-4 lg:mb-5">
                Динамика по дням
              </h3>
              <div className="flex gap-4 mb-4">
                <span className="flex items-center gap-2 text-xs text-muted-foreground">
                  <span
                    className="w-3 h-3 rounded-sm inline-block"
                    style={{ background: "#22c55e" }}
                  />{" "}
                  Доходы
                </span>
                <span className="flex items-center gap-2 text-xs text-muted-foreground">
                  <span
                    className="w-3 h-3 rounded-sm inline-block"
                    style={{ background: "#ef4444" }}
                  />{" "}
                  Расходы
                </span>
              </div>
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={dailyData} barSize={10} barGap={2}>
                  <CartesianGrid
                    strokeDasharray="3 3"
                    stroke="rgba(51,65,85,0.4)"
                    vertical={false}
                  />
                  <XAxis
                    dataKey="name"
                    tick={{ fill: "#64748b", fontSize: 10 }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <YAxis
                    tick={{ fill: "#64748b", fontSize: 10 }}
                    axisLine={false}
                    tickLine={false}
                    tickFormatter={(v) =>
                      `${mainSymbol}${Number(v).toLocaleString("ru-RU")}`
                    }
                    width={60}
                  />
                  <Tooltip
                    content={({ active, payload, label }) => {
                      if (!active || !payload?.length) return null;
                      return (
                        <div
                          className="px-3 py-2 rounded-xl text-sm"
                          style={{
                            background: "#1e293b",
                            border: "1px solid rgba(51,65,85,0.8)",
                          }}
                        >
                          <p className="text-muted-foreground mb-1">{label}</p>
                          {payload.map((p: any) => (
                            <p key={p.name} style={{ color: p.color }}>
                              {p.name === "income" ? "Доход" : "Расход"}:{" "}
                              {mainSymbol}{" "}
                              {Number(p.value).toLocaleString("ru-RU", {
                                minimumFractionDigits: decimalPlaces,
                              })}
                            </p>
                          ))}
                        </div>
                      );
                    }}
                    cursor={{ fill: "rgba(255,255,255,0.04)" }}
                  />
                  <Bar
                    dataKey="income"
                    name="income"
                    fill="#22c55e"
                    radius={[4, 4, 0, 0]}
                  />
                  <Bar
                    dataKey="expense"
                    name="expense"
                    fill="#ef4444"
                    radius={[4, 4, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}

          {/* Pie charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 lg:gap-6">
            {[
              {
                title: "Расходы по категориям",
                data: expenseData,
                colors: COLORS_EXPENSE,
                total: report?.totalExpense ?? 0,
                accent: "#ef4444",
              },
              {
                title: "Доходы по категориям",
                data: incomeData,
                colors: COLORS_INCOME,
                total: report?.totalIncome ?? 0,
                accent: "#22c55e",
              },
            ].map(({ title, data, colors, total, accent }) => (
              <div
                key={title}
                className="rounded-2xl p-4 lg:p-6"
                style={{
                  background: "rgba(30,41,59,0.6)",
                  border: "1px solid rgba(51,65,85,0.5)",
                }}
              >
                <h3
                  className="font-semibold text-foreground mb-4 lg:mb-5"
                  style={{ color: accent }}
                >
                  {title}
                </h3>
                {data.length === 0 ? (
                  <p className="text-center text-muted-foreground py-12 text-sm">
                    Нет данных
                  </p>
                ) : (
                  <>
                    <ResponsiveContainer width="100%" height={240}>
                      <PieChart>
                        <Pie
                          data={data}
                          dataKey="value"
                          nameKey="name"
                          cx="50%"
                          cy="50%"
                          innerRadius={50}
                          outerRadius={90}
                          paddingAngle={2}
                        >
                          {data.map((_, idx) => (
                            <Cell
                              key={idx}
                              fill={colors[idx % colors.length]}
                            />
                          ))}
                        </Pie>
                        <Tooltip
                          content={({ active, payload }) => {
                            if (!active || !payload?.length) return null;
                            return (
                              <div
                                className="px-3 py-2 rounded-xl text-sm"
                                style={{
                                  background: "#1e293b",
                                  border: "1px solid rgba(51,65,85,0.8)",
                                }}
                              >
                                <p className="text-foreground font-medium">
                                  {payload[0].name}
                                </p>
                                <p className="text-muted-foreground">
                                  {mainSymbol}{" "}
                                  {Number(payload[0].value).toLocaleString(
                                    "ru-RU",
                                    { minimumFractionDigits: decimalPlaces }
                                  )}
                                </p>
                              </div>
                            );
                          }}
                        />
                        <Legend
                          iconType="circle"
                          iconSize={8}
                          formatter={(v) => (
                            <span style={{ color: "#94a3b8", fontSize: 11 }}>
                              {v}
                            </span>
                          )}
                        />
                      </PieChart>
                    </ResponsiveContainer>

                    {/* Category table */}
                    <div className="mt-3 space-y-2">
                      {data.slice(0, 6).map((item, idx) => {
                        const pct =
                          total > 0 ? (item.value / total) * 100 : 0;
                        return (
                          <div
                            key={item.name}
                            className="flex items-center gap-2"
                          >
                            <div
                              className="w-2 h-2 rounded-full flex-shrink-0"
                              style={{
                                background: colors[idx % colors.length],
                              }}
                            />
                            <span className="text-xs text-muted-foreground flex-1 truncate">
                              {item.name}
                            </span>
                            <span className="text-xs text-muted-foreground flex-shrink-0">
                              {pct.toFixed(1)}%
                            </span>
                            <span className="text-xs font-medium text-foreground flex-shrink-0">
                              {mainSymbol}{" "}
                              {item.value.toLocaleString("ru-RU", {
                                minimumFractionDigits: decimalPlaces,
                              })}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  </>
                )}
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}