import { useState } from "react";
import {
  useCategories,
  useCreateCategory,
  useUpdateCategory,
  useDeleteCategory,
} from "@/features/categories/useCategories";
import { CategoryDto } from "@/types";
import { Plus, Edit, Trash2, X, Loader2, Tag, Check } from "lucide-react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";

const schema = z.object({
  name: z.string().min(1, "Введите название").max(100, "Не более 100 символов"),
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

function avatarColor(name: string): string {
  const colors = ["#EC4899","#A855F7","#6366F1","#3B82F6","#10B981","#F59E0B","#EF4444","#06B6D4"];
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return colors[Math.abs(hash) % colors.length];
}

export default function Categories() {
  const { data: categories = [], isLoading } = useCategories();
  const create = useCreateCategory();
  const update = useUpdateCategory();
  const del = useDeleteCategory();

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<CategoryDto | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null);
  const [serverError, setServerError] = useState("");

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({ resolver: zodResolver(schema) });

  const openCreate = () => {
    setEditing(null);
    reset({ name: "" });
    setServerError("");
    setModalOpen(true);
  };

  const openEdit = (cat: CategoryDto) => {
    setEditing(cat);
    setValue("name", cat.name);
    setServerError("");
    setModalOpen(true);
  };

  const onSubmit = async (data: FormData) => {
    setServerError("");
    try {
      if (editing) {
        await update.mutateAsync({ id: editing.id, data });
      } else {
        await create.mutateAsync(data);
      }
      setModalOpen(false);
      reset();
    } catch (e: any) {
      setServerError(e?.response?.data?.message || "Ошибка сохранения");
    }
  };

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Категории</h1>
          <p className="text-muted-foreground mt-1">{categories.length} категорий</p>
        </div>
        <button onClick={openCreate}
          className="flex items-center gap-2 px-5 py-2.5 rounded-xl font-semibold text-white text-sm transition-all hover:opacity-90 active:scale-[0.98]"
          style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)", boxShadow: "0 4px 15px rgba(236,72,153,0.3)" }}>
          <Plus className="w-4 h-4" /> Добавить категорию
        </button>
      </div>

      {/* Grid */}
      {isLoading ? (
        <div className="flex items-center justify-center py-32">
          <Loader2 className="w-10 h-10 animate-spin text-primary" />
        </div>
      ) : categories.length === 0 ? (
        <div className="text-center py-24 rounded-2xl" style={{ background: "rgba(30,41,59,0.4)", border: "1px dashed rgba(51,65,85,0.6)" }}>
          <Tag className="w-16 h-16 text-muted-foreground mx-auto mb-4 opacity-40" />
          <h3 className="text-xl font-semibold text-foreground mb-2">Нет категорий</h3>
          <p className="text-muted-foreground text-sm mb-6">Добавьте первую категорию для организации транзакций</p>
          <button onClick={openCreate}
            className="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-semibold text-white transition-all hover:opacity-90"
            style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)" }}>
            <Plus className="w-4 h-4" /> Создать категорию
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {categories.map((cat) => {
            const color = avatarColor(cat.name);
            return (
              <div key={cat.id}
                className="rounded-2xl p-5 flex items-center gap-4 group transition-all hover:border-primary/30"
                style={{ background: "rgba(30,41,59,0.6)", border: "1px solid rgba(51,65,85,0.5)" }}>
                <div className="w-11 h-11 rounded-xl flex items-center justify-center text-white text-lg font-bold flex-shrink-0 transition-transform group-hover:scale-110"
                  style={{ background: `${color}25`, border: `1px solid ${color}40` }}>
                  <span style={{ color }}>{cat.name.charAt(0).toUpperCase()}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-foreground truncate">{cat.name}</p>
                </div>
                <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => openEdit(cat)}
                    className="p-1.5 rounded-lg text-muted-foreground hover:text-foreground hover:bg-white/10 transition-all">
                    <Edit className="w-3.5 h-3.5" />
                  </button>
                  <button onClick={() => setDeleteConfirm(cat.id)}
                    className="p-1.5 rounded-lg text-muted-foreground hover:text-red-400 hover:bg-red-500/10 transition-all">
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Modal */}
      <Modal open={modalOpen} onClose={() => setModalOpen(false)}>
        <h2 className="text-xl font-bold text-foreground mb-5">
          {editing ? "Редактировать категорию" : "Новая категория"}
        </h2>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">Название</label>
            <input {...register("name")} placeholder="Еда, Транспорт, Зарплата..."
              className="w-full px-4 py-2.5 rounded-xl text-foreground placeholder-slate-500 outline-none focus:ring-2 focus:ring-primary/50 text-sm"
              style={{ background: "rgba(15,23,42,0.8)", border: "1px solid rgba(51,65,85,0.8)" }} />
            {errors.name && <p className="text-red-400 text-xs mt-1">{errors.name.message}</p>}
          </div>
          {serverError && (
            <div className="px-4 py-3 rounded-xl text-red-400 text-sm" style={{ background: "rgba(239,68,68,0.1)", border: "1px solid rgba(239,68,68,0.2)" }}>
              {serverError}
            </div>
          )}
          <button type="submit" disabled={isSubmitting}
            className="w-full py-3 rounded-xl font-semibold text-white flex items-center justify-center gap-2 transition-all hover:opacity-90 disabled:opacity-60"
            style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)" }}>
            {isSubmitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Check className="w-4 h-4" />}
            {editing ? "Сохранить" : "Добавить"}
          </button>
        </form>
      </Modal>

      {/* Delete confirm */}
      <Modal open={deleteConfirm !== null} onClose={() => setDeleteConfirm(null)}>
        <h2 className="text-xl font-bold text-foreground mb-3">Удалить категорию?</h2>
        <p className="text-muted-foreground mb-6">Вместе с категорией будут удалены все связанные транзакции.</p>
        <div className="flex gap-3">
          <button onClick={() => setDeleteConfirm(null)}
            className="flex-1 py-2.5 rounded-xl text-sm font-medium text-muted-foreground transition-colors"
            style={{ background: "rgba(51,65,85,0.4)", border: "1px solid rgba(51,65,85,0.6)" }}>
            Отмена
          </button>
          <button onClick={async () => {
            if (deleteConfirm !== null) {
              await del.mutateAsync(deleteConfirm);
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