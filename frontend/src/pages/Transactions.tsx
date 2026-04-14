import { useState } from "react";
import {
  useTransactions,
  useCreateTransaction,
  useUpdateTransaction,
  useDeleteTransaction,
} from "@/features/transactions/useTransactions";
import { useCategories } from "@/features/categories/useCategories";
import { useAuthStore } from "@/store/useAuthStore";
import {
  TransactionType,
  TransactionDto,
  TransactionCreateDto,
  Currency,
  CurrencySymbol,
  CurrencyLabel,
} from "@/types";
import { format } from "date-fns";
import { ru } from "date-fns/locale";
import {
  Plus,
  Search,
  Trash2,
  Edit,
  ChevronLeft,
  ChevronRight,
  X,
  ArrowUpRight,
  ArrowDownRight,
  Filter,
  Loader2,
  Check,
} from "lucide-react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";

const schema = z.object({
  amount: z.number().positive("Сумма должна быть больше 0"),
  date: z.string().min(1, "Укажите дату"),
  description: z.string().optional(),
  type: z.nativeEnum(TransactionType),
  categoryId: z.number().int().positive("Выберите категорию"),
  currency: z.nativeEnum(Currency),
});

type FormData = z.infer<typeof schema>;

function Modal({
  open,
  onClose,
  children,
}: {
  open: boolean;
  onClose: () => void;
  children: React.ReactNode;
}) {
  if (!open) return null;
  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4"
      onClick={onClose}
      style={{ background: "rgba(0,0,0,0.7)", backdropFilter: "blur(4px)" }}
    >
      <div
        className="w-full sm:max-w-lg rounded-t-2xl sm:rounded-2xl p-5 sm:p-6 relative max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
        style={{ background: "#1e293b", border: "1px solid rgba(51,65,85,0.8)" }}
      >
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-muted-foreground hover:text-foreground"
        >
          <X className="w-5 h-5" />
        </button>
        {children}
      </div>
    </div>
  );
}

export default function Transactions() {
  const { mainCurrency } = useAuthStore();
  const [page, setPage] = useState(0);
  const [filterFrom, setFilterFrom] = useState("");
  const [filterTo, setFilterTo] = useState("");
  const [filterType, setFilterType] = useState<TransactionType | "">("");
  const [filterCategoryId, setFilterCategoryId] = useState<number | null>(null);
  const [showFilters, setShowFilters] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<TransactionDto | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null);
  const [serverError, setServerError] = useState("");

  const { data: categoriesData = [] } = useCategories();
  const { data: pageData, isLoading } = useTransactions({
    page,
    size: 20,
    from: filterFrom,
    to: filterTo ? filterTo : undefined,
    type: filterType,
    categoryId: filterCategoryId,
  });

  const transactions = pageData?.content || [];
  const totalPages = pageData?.totalPages || 1;

  const create = useCreateTransaction();
  const update = useUpdateTransaction();
  const del = useDeleteTransaction();

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      type: TransactionType.EXPENSE,
      currency: mainCurrency as Currency,
      date: format(new Date(), "yyyy-MM-dd'T'HH:mm"),
    },
  });

  const watchedType = watch("type");

  const openCreate = () => {
    setEditing(null);
    reset({
      type: TransactionType.EXPENSE,
      currency: mainCurrency as Currency,
      date: format(new Date(), "yyyy-MM-dd'T'HH:mm"),
    });
    setServerError("");
    setModalOpen(true);
  };

  const openEdit = (t: TransactionDto) => {
    setEditing(t);
    reset({
      amount: t.amount,
      date: format(new Date(t.date), "yyyy-MM-dd'T'HH:mm"),
      description: t.description || "",
      type: t.type,
      categoryId: t.category.id,
      currency: t.currency || (mainCurrency as Currency),
    });
    setServerError("");
    setModalOpen(true);
  };

  const onSubmit = async (data: FormData) => {
    setServerError("");
    const payload: TransactionCreateDto = {
      ...data,
      date: new Date(data.date).toISOString(),
      description: data.description?.trim() || undefined,
    };
    try {
      if (editing) {
        await update.mutateAsync({ id: editing.id, data: payload });
      } else {
        await create.mutateAsync(payload);
      }
      setModalOpen(false);
      reset();
    } catch (e: any) {
      setServerError(e?.response?.data?.message || "Ошибка сохранения");
    }
  };

  const hasFilters = filterFrom || filterTo || filterType || filterCategoryId;

  return (
    <div className="space-y-4 lg:space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl lg:text-3xl font-bold text-foreground">
            Транзакции
          </h1>
          <p className="text-muted-foreground mt-1 text-sm">
            {pageData?.totalElements ?? 0} записей
          </p>
        </div>
        <button
          onClick={openCreate}
          className="flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl font-semibold text-white text-sm transition-all hover:opacity-90 active:scale-[0.98] w-full sm:w-auto"
          style={{
            background: "linear-gradient(135deg, #EC4899, #A855F7)",
            boxShadow: "0 4px 15px rgba(236,72,153,0.3)",
          }}
        >
          <Plus className="w-4 h-4" /> Добавить
        </button>
      </div>

      {/* Filters bar */}
      <div
        className="rounded-2xl p-3 lg:p-4"
        style={{
          background: "rgba(30,41,59,0.6)",
          border: "1px solid rgba(51,65,85,0.5)",
        }}
      >
        <div className="flex flex-wrap items-center gap-2 lg:gap-3">
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`flex items-center gap-2 px-3 lg:px-4 py-2 rounded-xl text-sm font-medium transition-all ${
              hasFilters
                ? "text-primary"
                : "text-muted-foreground hover:text-foreground"
            }`}
            style={{
              background: hasFilters
                ? "rgba(236,72,153,0.1)"
                : "rgba(51,65,85,0.4)",
              border: hasFilters
                ? "1px solid rgba(236,72,153,0.3)"
                : "1px solid transparent",
            }}
          >
            <Filter className="w-4 h-4" /> Фильтры{" "}
            {hasFilters && (
              <span className="w-2 h-2 rounded-full bg-primary" />
            )}
          </button>

          {/* Type pills */}
          <div className="flex gap-1.5 lg:gap-2">
            {[
              { v: "" as const, label: "Все" },
              { v: TransactionType.INCOME, label: "Доходы" },
              { v: TransactionType.EXPENSE, label: "Расходы" },
            ].map(({ v, label }) => (
              <button
                key={v}
                onClick={() => {
                  setFilterType(v);
                  setPage(0);
                }}
                className={`px-2.5 lg:px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                  filterType === v
                    ? "text-white"
                    : "text-muted-foreground hover:text-foreground"
                }`}
                style={{
                  background:
                    filterType === v
                      ? "rgba(236,72,153,0.2)"
                      : "rgba(51,65,85,0.4)",
                  border:
                    filterType === v
                      ? "1px solid rgba(236,72,153,0.4)"
                      : "1px solid transparent",
                }}
              >
                {label}
              </button>
            ))}
          </div>

          {hasFilters && (
            <button
              onClick={() => {
                setFilterFrom("");
                setFilterTo("");
                setFilterType("");
                setFilterCategoryId(null);
                setPage(0);
              }}
              className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs text-red-400 hover:text-red-300 transition-colors"
              style={{ background: "rgba(239,68,68,0.1)" }}
            >
              <X className="w-3 h-3" /> Сбросить
            </button>
          )}
        </div>

        {showFilters && (
          <div className="mt-4 pt-4 border-t border-border/30 grid grid-cols-1 sm:grid-cols-3 gap-3 lg:gap-4">
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">
                От даты
              </label>
              <input
                type="datetime-local"
                value={filterFrom}
                onChange={(e) => {
                  setFilterFrom(e.target.value);
                  setPage(0);
                }}
                className="w-full px-3 py-2 rounded-xl text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/50"
                style={{
                  background: "rgba(15,23,42,0.8)",
                  border: "1px solid rgba(51,65,85,0.8)",
                }}
              />
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">
                До даты
              </label>
              <input
                type="datetime-local"
                value={filterTo}
                onChange={(e) => {
                  setFilterTo(e.target.value);
                  setPage(0);
                }}
                className="w-full px-3 py-2 rounded-xl text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/50"
                style={{
                  background: "rgba(15,23,42,0.8)",
                  border: "1px solid rgba(51,65,85,0.8)",
                }}
              />
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">
                Категория
              </label>
              <select
                value={filterCategoryId ?? ""}
                onChange={(e) => {
                  setFilterCategoryId(
                    e.target.value ? Number(e.target.value) : null
                  );
                  setPage(0);
                }}
                className="w-full px-3 py-2 rounded-xl text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/50"
                style={{
                  background: "rgba(15,23,42,0.8)",
                  border: "1px solid rgba(51,65,85,0.8)",
                }}
              >
                <option value="">Все категории</option>
                {categoriesData.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
        )}
      </div>

      {/* Table / Cards */}
      <div
        className="rounded-2xl overflow-hidden"
        style={{
          background: "rgba(30,41,59,0.6)",
          border: "1px solid rgba(51,65,85,0.5)",
        }}
      >
        {isLoading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-primary" />
          </div>
        ) : transactions.length === 0 ? (
          <div className="text-center py-16">
            <Search className="w-12 h-12 text-muted-foreground mx-auto mb-4 opacity-40" />
            <p className="text-muted-foreground">Транзакции не найдены</p>
          </div>
        ) : (
          <>
            {/* Desktop: table */}
            <div className="hidden md:block overflow-x-auto">
              <table className="w-full min-w-[640px]">
                <thead>
                  <tr style={{ borderBottom: "1px solid rgba(51,65,85,0.5)" }}>
                    {["Дата", "Категория", "Описание", "Тип", "Сумма", "Валюта", ""].map(
                      (h) => (
                        <th
                          key={h}
                          className="px-5 py-4 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider"
                        >
                          {h}
                        </th>
                      )
                    )}
                  </tr>
                </thead>
                <tbody>
                  {transactions.map((t, i) => {
                    const isIncome = t.type === TransactionType.INCOME;
                    const color = isIncome ? "#22c55e" : "#ef4444";
                    const sign = isIncome ? "+" : "-";
                    const txSymbol =
                      CurrencySymbol[t.currency as Currency] || "Br";
                    return (
                      <tr
                        key={t.id}
                        className="hover:bg-white/[0.02] transition-colors"
                        style={{
                          borderBottom:
                            i < transactions.length - 1
                              ? "1px solid rgba(51,65,85,0.3)"
                              : "none",
                        }}
                      >
                        <td className="px-5 py-4 text-sm text-muted-foreground whitespace-nowrap">
                          {format(new Date(t.date), "dd MMM yyyy", { locale: ru })}
                          <div className="text-xs opacity-60">
                            {format(new Date(t.date), "HH:mm")}
                          </div>
                        </td>
                        <td className="px-5 py-4">
                          <span
                            className="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-medium"
                            style={{
                              background: "rgba(99,102,241,0.15)",
                              color: "#a5b4fc",
                            }}
                          >
                            {t.category.name}
                          </span>
                        </td>
                        <td className="px-5 py-4 text-sm text-muted-foreground max-w-[200px] truncate">
                          {t.description || (
                            <span className="opacity-30">—</span>
                          )}
                        </td>
                        <td className="px-5 py-4">
                          <span
                            className="inline-flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-lg"
                            style={{ background: `${color}15`, color }}
                          >
                            {isIncome ? (
                              <ArrowUpRight className="w-3 h-3" />
                            ) : (
                              <ArrowDownRight className="w-3 h-3" />
                            )}
                            {isIncome ? "Доход" : "Расход"}
                          </span>
                        </td>
                        <td
                          className="px-5 py-4 text-sm font-bold whitespace-nowrap"
                          style={{ color }}
                        >
                          {sign}{" "}
                          {t.amount.toLocaleString("ru-RU", {
                            minimumFractionDigits: 2,
                          })}
                        </td>
                        <td className="px-5 py-4 text-sm text-muted-foreground">
                          {t.currency} {txSymbol}
                        </td>
                        <td className="px-5 py-4">
                          <div className="flex items-center gap-1">
                            <button
                              onClick={() => openEdit(t)}
                              className="p-1.5 rounded-lg text-muted-foreground hover:text-foreground hover:bg-white/10 transition-all"
                            >
                              <Edit className="w-3.5 h-3.5" />
                            </button>
                            <button
                              onClick={() => setDeleteConfirm(t.id)}
                              className="p-1.5 rounded-lg text-muted-foreground hover:text-red-400 hover:bg-red-500/10 transition-all"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* Mobile: card list */}
            <div className="md:hidden divide-y divide-border/20">
              {transactions.map((t) => {
                const isIncome = t.type === TransactionType.INCOME;
                const color = isIncome ? "#22c55e" : "#ef4444";
                const sign = isIncome ? "+" : "-";
                return (
                  <div key={t.id} className="flex items-center gap-3 p-4">
                    <div
                      className="w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0"
                      style={{ background: `${color}20` }}
                    >
                      {isIncome ? (
                        <ArrowUpRight className="w-4 h-4" style={{ color }} />
                      ) : (
                        <ArrowDownRight className="w-4 h-4" style={{ color }} />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <span
                          className="text-xs px-2 py-0.5 rounded-md font-medium"
                          style={{
                            background: "rgba(99,102,241,0.15)",
                            color: "#a5b4fc",
                          }}
                        >
                          {t.category.name}
                        </span>
                      </div>
                      {t.description && (
                        <p className="text-xs text-muted-foreground truncate">
                          {t.description}
                        </p>
                      )}
                      <p className="text-xs text-muted-foreground mt-0.5">
                        {format(new Date(t.date), "dd MMM yyyy, HH:mm", {
                          locale: ru,
                        })}
                      </p>
                    </div>
                    <div className="flex flex-col items-end gap-1.5 flex-shrink-0">
                      <p className="text-sm font-bold" style={{ color }}>
                        {sign}{" "}
                        {t.amount.toLocaleString("ru-RU", {
                          minimumFractionDigits: 2,
                        })}
                      </p>
                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => openEdit(t)}
                          className="p-1.5 rounded-lg text-muted-foreground hover:text-foreground hover:bg-white/10 transition-all"
                        >
                          <Edit className="w-3.5 h-3.5" />
                        </button>
                        <button
                          onClick={() => setDeleteConfirm(t.id)}
                          className="p-1.5 rounded-lg text-muted-foreground hover:text-red-400 hover:bg-red-500/10 transition-all"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">
            Стр. {page + 1} из {totalPages}
          </p>
          <div className="flex gap-2">
            <button
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={page === 0}
              className="p-2 rounded-xl transition-all disabled:opacity-30 text-foreground hover:bg-white/10"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
              disabled={page >= totalPages - 1}
              className="p-2 rounded-xl transition-all disabled:opacity-30 text-foreground hover:bg-white/10"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
          </div>
        </div>
      )}

      {/* Create/Edit Modal */}
      <Modal open={modalOpen} onClose={() => setModalOpen(false)}>
        <h2 className="text-xl font-bold text-foreground mb-5">
          {editing ? "Редактировать транзакцию" : "Новая транзакция"}
        </h2>

        {/* Type toggle */}
        <div className="flex gap-2 mb-5">
          {[
            { v: TransactionType.INCOME, label: "Доход", color: "#22c55e" },
            { v: TransactionType.EXPENSE, label: "Расход", color: "#ef4444" },
          ].map(({ v, label, color }) => (
            <button
              key={v}
              type="button"
              onClick={() => setValue("type", v)}
              className="flex-1 py-2.5 rounded-xl text-sm font-semibold transition-all"
              style={{
                background:
                  watchedType === v ? `${color}20` : "rgba(51,65,85,0.4)",
                border:
                  watchedType === v
                    ? `1.5px solid ${color}60`
                    : "1.5px solid transparent",
                color: watchedType === v ? color : "#64748b",
              }}
            >
              {label}
            </button>
          ))}
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="grid grid-cols-2 gap-3 lg:gap-4">
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">
                Сумма
              </label>
              <input
                type="number"
                step="0.01"
                {...register("amount", { valueAsNumber: true })}
                placeholder="0.00"
                className="w-full px-4 py-2.5 rounded-xl text-foreground placeholder-slate-500 outline-none focus:ring-2 focus:ring-primary/50 text-sm"
                style={{
                  background: "rgba(15,23,42,0.8)",
                  border: "1px solid rgba(51,65,85,0.8)",
                }}
              />
              {errors.amount && (
                <p className="text-red-400 text-xs mt-1">
                  {errors.amount.message}
                </p>
              )}
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">
                Валюта
              </label>
              <select
                {...register("currency")}
                className="w-full px-4 py-2.5 rounded-xl text-foreground outline-none focus:ring-2 focus:ring-primary/50 text-sm"
                style={{
                  background: "rgba(15,23,42,0.8)",
                  border: "1px solid rgba(51,65,85,0.8)",
                }}
              >
                {Object.entries(CurrencyLabel).map(([k, v]) => (
                  <option key={k} value={k}>
                    {v}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">
              Дата и время
            </label>
            <input
              type="datetime-local"
              {...register("date")}
              className="w-full px-4 py-2.5 rounded-xl text-foreground outline-none focus:ring-2 focus:ring-primary/50 text-sm"
              style={{
                background: "rgba(15,23,42,0.8)",
                border: "1px solid rgba(51,65,85,0.8)",
              }}
            />
            {errors.date && (
              <p className="text-red-400 text-xs mt-1">{errors.date.message}</p>
            )}
          </div>

          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">
              Категория
            </label>
            <select
              {...register("categoryId", { valueAsNumber: true })}
              className="w-full px-4 py-2.5 rounded-xl text-foreground outline-none focus:ring-2 focus:ring-primary/50 text-sm"
              style={{
                background: "rgba(15,23,42,0.8)",
                border: "1px solid rgba(51,65,85,0.8)",
              }}
            >
              <option value="">Выберите категорию</option>
              {categoriesData.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
            {errors.categoryId && (
              <p className="text-red-400 text-xs mt-1">
                {errors.categoryId.message}
              </p>
            )}
          </div>

          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">
              Описание (необязательно)
            </label>
            <input
              {...register("description")}
              placeholder="Заметка..."
              className="w-full px-4 py-2.5 rounded-xl text-foreground placeholder-slate-500 outline-none focus:ring-2 focus:ring-primary/50 text-sm"
              style={{
                background: "rgba(15,23,42,0.8)",
                border: "1px solid rgba(51,65,85,0.8)",
              }}
            />
          </div>

          {serverError && (
            <div
              className="px-4 py-3 rounded-xl text-red-400 text-sm"
              style={{
                background: "rgba(239,68,68,0.1)",
                border: "1px solid rgba(239,68,68,0.2)",
              }}
            >
              {serverError}
            </div>
          )}

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-3 rounded-xl font-semibold text-white flex items-center justify-center gap-2 transition-all hover:opacity-90 disabled:opacity-60"
            style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)" }}
          >
            {isSubmitting ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Check className="w-4 h-4" />
            )}
            {editing ? "Сохранить изменения" : "Добавить транзакцию"}
          </button>
        </form>
      </Modal>

      {/* Delete confirm */}
      <Modal
        open={deleteConfirm !== null}
        onClose={() => setDeleteConfirm(null)}
      >
        <h2 className="text-xl font-bold text-foreground mb-3">
          Удалить транзакцию?
        </h2>
        <p className="text-muted-foreground mb-6">
          Это действие нельзя отменить.
        </p>
        <div className="flex gap-3">
          <button
            onClick={() => setDeleteConfirm(null)}
            className="flex-1 py-2.5 rounded-xl text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            style={{
              background: "rgba(51,65,85,0.4)",
              border: "1px solid rgba(51,65,85,0.6)",
            }}
          >
            Отмена
          </button>
          <button
            onClick={async () => {
              if (deleteConfirm !== null) {
                await del.mutateAsync(deleteConfirm);
                setDeleteConfirm(null);
              }
            }}
            className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-white transition-all hover:opacity-90"
            style={{ background: "rgba(239,68,68,0.8)" }}
          >
            Удалить
          </button>
        </div>
      </Modal>
    </div>
  );
}