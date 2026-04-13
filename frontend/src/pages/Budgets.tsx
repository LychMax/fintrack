import { useState } from "react";
import {
  useBudgetStatuses,
  useCreateOrUpdateBudget,
  useDeleteBudget,
} from "@/features/budgets/useBudgets";
import { useCategories } from "@/features/categories/useCategories";
import { Currency, CurrencyLabel, CurrencySymbol, PeriodType, BudgetStatusDto } from "@/types";
import { Plus, Trash2, Edit, AlertTriangle, CheckCircle2, X, Loader2, Wallet, Info } from "lucide-react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";

const schema = z.object({
  categoryId: z.number()
    .int("Категория должна быть целым числом")
    .positive("Выберите категорию"),

  amount: z.number()
    .positive("Сумма должна быть больше 0"),

  periodType: z.nativeEnum(PeriodType),
  currency: z.nativeEnum(Currency),
});

type FormData = z.infer<typeof schema>;

function Modal({ open, onClose, children }: { open: boolean; onClose: () => void; children: React.ReactNode }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={onClose}
      style={{ background: "rgba(0,0,0,0.7)", backdropFilter: "blur(4px)" }}>
      <div className="w-full max-w-md rounded-2xl p-6 relative" onClick={(e) => e.stopPropagation()}
        style={{ background: "#1e293b", border: "1px solid rgba(51,65,85,0.8)" }}>
        <button onClick={onClose} className="absolute top-4 right-4 text-muted-foreground hover:text-foreground">
          <X className="w-5 h-5" />
        </button>
        {children}
      </div>
    </div>
  );
}

function BudgetCard({ status, onEdit, onDelete }: { status: BudgetStatusDto; onEdit: () => void; onDelete: () => void }) {
  const pct = Math.min(status.percentUsed, 100);
  const barColor = status.exceeded ? "#ef4444" : status.nearLimit ? "#f59e0b" : "#22c55e";
  const symbol = CurrencySymbol[status.currency as Currency] || "Br";
  const periodLabel = status.periodType === PeriodType.MONTHLY ? "на месяц" : "на неделю";

  return (
    <div className="rounded-2xl p-5 transition-all hover:border-primary/30"
      style={{
        background: "rgba(30,41,59,0.6)",
        border: status.exceeded
          ? "1px solid rgba(239,68,68,0.3)"
          : status.nearLimit
          ? "1px solid rgba(245,158,11,0.3)"
          : "1px solid rgba(51,65,85,0.5)",
      }}>
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div>
          <div className="flex items-center gap-2">
            {status.exceeded && <AlertTriangle className="w-4 h-4 text-red-400 flex-shrink-0" />}
            {!status.exceeded && status.nearLimit && <AlertTriangle className="w-4 h-4 text-amber-400 flex-shrink-0" />}
            {!status.exceeded && !status.nearLimit && <CheckCircle2 className="w-4 h-4 text-green-400 flex-shrink-0" />}
            <h3 className="font-semibold text-foreground">{status.categoryName}</h3>
          </div>
          <p className="text-xs text-muted-foreground mt-0.5">{periodLabel}</p>
        </div>
        <div className="flex items-center gap-1">
          <button onClick={onEdit}
            className="p-1.5 rounded-lg text-muted-foreground hover:text-foreground hover:bg-white/10 transition-all">
            <Edit className="w-3.5 h-3.5" />
          </button>
          <button onClick={onDelete}
            className="p-1.5 rounded-lg text-muted-foreground hover:text-red-400 hover:bg-red-500/10 transition-all">
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Amounts */}
      <div className="flex items-center justify-between mb-3">
        <span className="text-sm" style={{ color: barColor }}>
          {symbol} {status.spentAmount.toLocaleString("ru-RU", { minimumFractionDigits: 2 })} / {symbol} {status.budgetAmount.toLocaleString("ru-RU", { minimumFractionDigits: 2 })}
        </span>
        <span className="text-xs font-semibold px-2 py-0.5 rounded-full" style={{ color: barColor, background: `${barColor}15` }}>
          {status.percentUsed.toFixed(1)}%
        </span>
      </div>

      {/* Progress bar */}
      <div className="h-2.5 rounded-full overflow-hidden mb-3" style={{ background: "rgba(51,65,85,0.8)" }}>
        <div className="h-full rounded-full transition-all duration-700"
          style={{ width: `${pct}%`, background: barColor }} />
      </div>

      {/* Status text */}
      <p className="text-xs" style={{ color: barColor }}>
        {status.exceeded
          ? `Превышен на ${symbol} ${(status.spentAmount - status.budgetAmount).toLocaleString("ru-RU", { minimumFractionDigits: 2 })}`
          : `Осталось ${symbol} ${status.remainingAmount.toLocaleString("ru-RU", { minimumFractionDigits: 2 })}`}
      </p>
    </div>
  );
}

export default function Budgets() {
  const { data: statuses = [], isLoading } = useBudgetStatuses();
  const { data: categories = [] } = useCategories();
  const createOrUpdate = useCreateOrUpdateBudget();
  const deleteBudget = useDeleteBudget();

  const [modalOpen, setModalOpen] = useState(false);
  const [editingStatus, setEditingStatus] = useState<BudgetStatusDto | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null);
  const [serverError, setServerError] = useState("");

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
      periodType: PeriodType.MONTHLY,
      currency: Currency.BYN,
    },
  });

  const watchedPeriod = watch("periodType");

  const openCreate = () => {
    setEditingStatus(null);
    reset({ periodType: PeriodType.MONTHLY, currency: Currency.BYN });
    setServerError("");
    setModalOpen(true);
  };

  const openEdit = (s: BudgetStatusDto) => {
    setEditingStatus(s);
    reset({
      categoryId: s.categoryId,
      amount: s.budgetAmount,
      periodType: s.periodType,
      currency: s.currency as Currency,
    });
    setServerError("");
    setModalOpen(true);
  };

  const onSubmit = async (data: FormData) => {
    setServerError("");
    try {
      await createOrUpdate.mutateAsync(data);
      setModalOpen(false);
      reset();
    } catch (e: any) {
      setServerError(e?.response?.data?.message || "Ошибка сохранения");
    }
  };

  const monthlyBudgets = statuses.filter((s) => s.periodType === PeriodType.MONTHLY);
  const weeklyBudgets = statuses.filter((s) => s.periodType === PeriodType.WEEKLY);
  const exceeded = statuses.filter((s) => s.exceeded).length;
  const nearLimit = statuses.filter((s) => s.nearLimit && !s.exceeded).length;

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Бюджеты</h1>
          <p className="text-muted-foreground mt-1">{statuses.length} активных бюджетов</p>
        </div>
        <button onClick={openCreate}
          className="flex items-center gap-2 px-5 py-2.5 rounded-xl font-semibold text-white text-sm transition-all hover:opacity-90 active:scale-[0.98]"
          style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)", boxShadow: "0 4px 15px rgba(236,72,153,0.3)" }}>
          <Plus className="w-4 h-4" /> Добавить бюджет
        </button>
      </div>

      {/* Info banner */}
      <div className="flex items-start gap-3 px-4 py-3 rounded-xl" style={{ background: "rgba(99,102,241,0.1)", border: "1px solid rgba(99,102,241,0.2)" }}>
        <Info className="w-4 h-4 text-indigo-400 flex-shrink-0 mt-0.5" />
        <p className="text-sm text-slate-400">
          Бюджеты автоматически сбрасываются в начале каждого периода. Все суммы конвертируются в вашу основную валюту.
        </p>
      </div>

      {/* Status summary */}
      {statuses.length > 0 && (exceeded > 0 || nearLimit > 0) && (
        <div className="grid grid-cols-2 gap-4">
          {exceeded > 0 && (
            <div className="flex items-center gap-3 px-4 py-3 rounded-xl" style={{ background: "rgba(239,68,68,0.1)", border: "1px solid rgba(239,68,68,0.2)" }}>
              <AlertTriangle className="w-5 h-5 text-red-400 flex-shrink-0" />
              <div>
                <p className="text-sm font-semibold text-red-400">{exceeded} превышен{exceeded > 1 ? "о" : ""}</p>
                <p className="text-xs text-slate-500">Лимит исчерпан</p>
              </div>
            </div>
          )}
          {nearLimit > 0 && (
            <div className="flex items-center gap-3 px-4 py-3 rounded-xl" style={{ background: "rgba(245,158,11,0.1)", border: "1px solid rgba(245,158,11,0.2)" }}>
              <AlertTriangle className="w-5 h-5 text-amber-400 flex-shrink-0" />
              <div>
                <p className="text-sm font-semibold text-amber-400">{nearLimit} близк{nearLimit > 1 ? "о" : "о"} к лимиту</p>
                <p className="text-xs text-slate-500">Использовано &gt;75%</p>
              </div>
            </div>
          )}
        </div>
      )}

      {isLoading ? (
        <div className="flex items-center justify-center py-32">
          <Loader2 className="w-10 h-10 animate-spin text-primary" />
        </div>
      ) : statuses.length === 0 ? (
        <div className="text-center py-24 rounded-2xl" style={{ background: "rgba(30,41,59,0.4)", border: "1px dashed rgba(51,65,85,0.6)" }}>
          <Wallet className="w-16 h-16 text-muted-foreground mx-auto mb-4 opacity-40" />
          <h3 className="text-xl font-semibold text-foreground mb-2">Бюджеты не установлены</h3>
          <p className="text-muted-foreground text-sm mb-6">Установите лимиты по категориям и следите за тратами</p>
          <button onClick={openCreate}
            className="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-semibold text-white transition-all hover:opacity-90"
            style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)" }}>
            <Plus className="w-4 h-4" /> Создать первый бюджет
          </button>
        </div>
      ) : (
        <div className="space-y-8">
          {monthlyBudgets.length > 0 && (
            <div>
              <h2 className="text-lg font-semibold text-foreground mb-4">Месячные бюджеты</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                {monthlyBudgets.map((s) => (
                  <BudgetCard key={s.id} status={s}
                    onEdit={() => openEdit(s)}
                    onDelete={() => setDeleteConfirm(s.id)} />
                ))}
              </div>
            </div>
          )}
          {weeklyBudgets.length > 0 && (
            <div>
              <h2 className="text-lg font-semibold text-foreground mb-4">Недельные бюджеты</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                {weeklyBudgets.map((s) => (
                  <BudgetCard key={s.id} status={s}
                    onEdit={() => openEdit(s)}
                    onDelete={() => setDeleteConfirm(s.id)} />
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Create/Edit Modal */}
      <Modal open={modalOpen} onClose={() => setModalOpen(false)}>
        <h2 className="text-xl font-bold text-foreground mb-5">
          {editingStatus ? "Редактировать бюджет" : "Новый бюджет"}
        </h2>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">Категория</label>
            <select {...register("categoryId", { valueAsNumber: true })}
              disabled={!!editingStatus}
              className="w-full px-4 py-2.5 rounded-xl text-foreground outline-none focus:ring-2 focus:ring-primary/50 text-sm disabled:opacity-60"
              style={{ background: "rgba(15,23,42,0.8)", border: "1px solid rgba(51,65,85,0.8)" }}>
              <option value="">Выберите категорию</option>
              {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
            {errors.categoryId && <p className="text-red-400 text-xs mt-1">{errors.categoryId.message}</p>}
          </div>

          {/* Period selector */}
          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">Период</label>
            <div className="flex gap-2">
              {[{ v: PeriodType.MONTHLY, label: "Месяц" }, { v: PeriodType.WEEKLY, label: "Неделя" }].map(({ v, label }) => (
                <button key={v} type="button" onClick={() => setValue("periodType", v)}
                  className="flex-1 py-2.5 rounded-xl text-sm font-medium transition-all"
                  style={{
                    background: watchedPeriod === v ? "rgba(236,72,153,0.15)" : "rgba(51,65,85,0.4)",
                    border: watchedPeriod === v ? "1.5px solid rgba(236,72,153,0.5)" : "1.5px solid transparent",
                    color: watchedPeriod === v ? "#EC4899" : "#64748b",
                  }}>
                  {label}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">Лимит</label>
              <input type="number" step="0.01" {...register("amount", { valueAsNumber: true })}
                placeholder="0.00"
                className="w-full px-4 py-2.5 rounded-xl text-foreground placeholder-slate-500 outline-none focus:ring-2 focus:ring-primary/50 text-sm"
                style={{ background: "rgba(15,23,42,0.8)", border: "1px solid rgba(51,65,85,0.8)" }} />
              {errors.amount && <p className="text-red-400 text-xs mt-1">{errors.amount.message}</p>}
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">Валюта</label>
              <select {...register("currency")}
                className="w-full px-4 py-2.5 rounded-xl text-foreground outline-none focus:ring-2 focus:ring-primary/50 text-sm"
                style={{ background: "rgba(15,23,42,0.8)", border: "1px solid rgba(51,65,85,0.8)" }}>
                {Object.entries(CurrencyLabel).map(([k, v]) => (
                  <option key={k} value={k}>{v}</option>
                ))}
              </select>
            </div>
          </div>

          {serverError && (
            <div className="px-4 py-3 rounded-xl text-red-400 text-sm" style={{ background: "rgba(239,68,68,0.1)", border: "1px solid rgba(239,68,68,0.2)" }}>
              {serverError}
            </div>
          )}

          <button type="submit" disabled={isSubmitting}
            className="w-full py-3 rounded-xl font-semibold text-white flex items-center justify-center gap-2 transition-all hover:opacity-90 disabled:opacity-60"
            style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)" }}>
            {isSubmitting ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
            {editingStatus ? "Сохранить" : "Создать бюджет"}
          </button>
        </form>
      </Modal>

      {/* Delete confirm */}
      <Modal open={deleteConfirm !== null} onClose={() => setDeleteConfirm(null)}>
        <h2 className="text-xl font-bold text-foreground mb-3">Удалить бюджет?</h2>
        <p className="text-muted-foreground mb-6">Это действие нельзя отменить.</p>
        <div className="flex gap-3">
          <button onClick={() => setDeleteConfirm(null)}
            className="flex-1 py-2.5 rounded-xl text-sm font-medium text-muted-foreground transition-colors"
            style={{ background: "rgba(51,65,85,0.4)", border: "1px solid rgba(51,65,85,0.6)" }}>
            Отмена
          </button>
          <button onClick={async () => {
            if (deleteConfirm !== null) {
              await deleteBudget.mutateAsync(deleteConfirm);
              setDeleteConfirm(null);
            }
          }}
            className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-white transition-all hover:opacity-90"
            style={{ background: "rgba(239,68,68,0.8)" }}>
            Удалить
          </button>
        </div>
      </Modal>
    </div>
  );
}