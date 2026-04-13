import { useState } from "react";
import { useProfile, useUpdateProfile, useChangePassword } from "@/features/profile/useProfile";
import { useAuthStore } from "@/store/useAuthStore";
import { Currency, CurrencyLabel } from "@/types";
import {
  User, Mail, Lock, Wallet, Save, Eye, EyeOff, Check, Loader2,
  AlertCircle, ShieldCheck,
} from "lucide-react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { useNavigate } from "react-router-dom";

const profileSchema = z.object({
  username: z.string().min(3, "Минимум 3 символа").max(50).optional().or(z.literal("")),
  email: z.string().email("Некорректный email").optional().or(z.literal("")),
});

const passwordSchema = z.object({
  oldPassword: z.string().min(1, "Введите текущий пароль"),
  newPassword: z.string().min(6, "Минимум 6 символов"),
  confirmPassword: z.string().min(1, "Подтвердите пароль"),
}).refine((d) => d.newPassword === d.confirmPassword, {
  message: "Пароли не совпадают",
  path: ["confirmPassword"],
});

type ProfileForm = z.infer<typeof profileSchema>;
type PasswordForm = z.infer<typeof passwordSchema>;

function Section({ title, icon: Icon, children }: { title: string; icon: any; children: React.ReactNode }) {
  return (
    <div className="rounded-2xl p-6" style={{ background: "rgba(30,41,59,0.6)", border: "1px solid rgba(51,65,85,0.5)" }}>
      <div className="flex items-center gap-3 mb-6">
        <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: "rgba(236,72,153,0.15)" }}>
          <Icon className="w-4 h-4 text-primary" />
        </div>
        <h2 className="text-lg font-semibold text-foreground">{title}</h2>
      </div>
      {children}
    </div>
  );
}

function SuccessToast({ message, onClose }: { message: string; onClose: () => void }) {
  return (
    <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 px-5 py-3 rounded-xl shadow-2xl"
      style={{ background: "#1e293b", border: "1px solid rgba(34,197,94,0.4)" }}>
      <Check className="w-4 h-4 text-green-400" />
      <p className="text-sm text-foreground font-medium">{message}</p>
      <button onClick={onClose} className="text-muted-foreground hover:text-foreground ml-2 text-xs">✕</button>
    </div>
  );
}

export default function Profile() {
  const navigate = useNavigate();
  const { username, email, mainCurrency, setToken } = useAuthStore();
  const { data: profile } = useProfile();
  const updateProfile = useUpdateProfile();
  const changePassword = useChangePassword();

  const [showOldPass, setShowOldPass] = useState(false);
  const [showNewPass, setShowNewPass] = useState(false);
  const [showConfirmPass, setShowConfirmPass] = useState(false);
  const [profileError, setProfileError] = useState("");
  const [passError, setPassError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  const displayUsername = profile?.username || username || "Пользователь";
  const displayEmail = profile?.email || email || "";
  const displayCurrency = profile?.mainCurrency || mainCurrency || Currency.BYN;
  const avatarLetter = displayUsername.charAt(0).toUpperCase();

  const profileForm = useForm<ProfileForm>({
    resolver: zodResolver(profileSchema),
    defaultValues: { username: displayUsername, email: displayEmail },
    values: { username: profile?.username || displayUsername, email: profile?.email || displayEmail },
  });

  const passwordForm = useForm<PasswordForm>({
    resolver: zodResolver(passwordSchema),
  });

  const onProfileSubmit = async (data: ProfileForm) => {
    setProfileError("");
    const payload: any = {};
    if (data.username && data.username !== displayUsername) payload.username = data.username;
    if (data.email && data.email !== displayEmail) payload.email = data.email;

    if (Object.keys(payload).length === 0) {
      setSuccessMsg("Нет изменений");
      setTimeout(() => setSuccessMsg(""), 3000);
      return;
    }

    try {
      await updateProfile.mutateAsync(payload);
      setSuccessMsg("Профиль обновлён");
      setTimeout(() => setSuccessMsg(""), 3000);
      // If username changed - need to re-login
      if (payload.username) {
        setTimeout(() => {
          setToken(null);
          navigate("/login");
        }, 2000);
      }
    } catch (e: any) {
      setProfileError(e?.response?.data?.message || "Ошибка обновления профиля");
    }
  };

  const onPasswordSubmit = async (data: PasswordForm) => {
    setPassError("");
    try {
      await changePassword.mutateAsync({ oldPassword: data.oldPassword, newPassword: data.newPassword });
      passwordForm.reset();
      setSuccessMsg("Пароль успешно изменён");
      setTimeout(() => setSuccessMsg(""), 3000);
    } catch (e: any) {
      const status = e?.response?.status;
      if (status === 400 || status === 401) {
        setPassError("Неверный текущий пароль");
      } else {
        setPassError(e?.response?.data?.message || "Ошибка смены пароля");
      }
    }
  };

  const onCurrencyChange = async (currency: Currency) => {
    if (currency === displayCurrency) return;
    try {
      await updateProfile.mutateAsync({ mainCurrency: currency });
      setSuccessMsg(`Валюта изменена на ${currency}`);
      setTimeout(() => setSuccessMsg(""), 3000);
    } catch (e: any) {
      setProfileError(e?.response?.data?.message || "Ошибка смены валюты");
    }
  };

  return (
    <div className="space-y-8 max-w-3xl">
      {/* Header / Avatar */}
      <div className="flex items-center gap-6">
        <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-white text-4xl font-bold shadow-xl">
          {avatarLetter}
        </div>
        <div>
          <h1 className="text-3xl font-bold text-foreground">{displayUsername}</h1>
          <p className="text-muted-foreground mt-1">{displayEmail}</p>
          <span className="inline-flex items-center gap-1.5 mt-2 px-3 py-1 rounded-full text-xs font-medium"
            style={{ background: "rgba(236,72,153,0.15)", color: "#EC4899", border: "1px solid rgba(236,72,153,0.3)" }}>
            <ShieldCheck className="w-3 h-3" /> Основная валюта: {displayCurrency}
          </span>
        </div>
      </div>

      {/* Edit Profile */}
      <Section title="Личные данные" icon={User}>
        <form onSubmit={profileForm.handleSubmit(onProfileSubmit)} className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block flex items-center gap-1.5">
                <User className="w-3 h-3" /> Логин
              </label>
              <input {...profileForm.register("username")} placeholder="Ваш логин"
                className="w-full px-4 py-2.5 rounded-xl text-foreground placeholder-slate-500 outline-none focus:ring-2 focus:ring-primary/50 text-sm"
                style={{ background: "rgba(15,23,42,0.8)", border: "1px solid rgba(51,65,85,0.8)" }} />
              {profileForm.formState.errors.username && (
                <p className="text-red-400 text-xs mt-1">{profileForm.formState.errors.username.message}</p>
              )}
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block flex items-center gap-1.5">
                <Mail className="w-3 h-3" /> Email
              </label>
              <input {...profileForm.register("email")} type="email" placeholder="email@example.com"
                className="w-full px-4 py-2.5 rounded-xl text-foreground placeholder-slate-500 outline-none focus:ring-2 focus:ring-primary/50 text-sm"
                style={{ background: "rgba(15,23,42,0.8)", border: "1px solid rgba(51,65,85,0.8)" }} />
              {profileForm.formState.errors.email && (
                <p className="text-red-400 text-xs mt-1">{profileForm.formState.errors.email.message}</p>
              )}
            </div>
          </div>

          {profileError && (
            <div className="flex items-center gap-2 px-4 py-3 rounded-xl text-red-400 text-sm"
              style={{ background: "rgba(239,68,68,0.1)", border: "1px solid rgba(239,68,68,0.2)" }}>
              <AlertCircle className="w-4 h-4 flex-shrink-0" /> {profileError}
            </div>
          )}

          <p className="text-xs text-amber-400/80">
            ⚠ При изменении логина потребуется повторный вход
          </p>

          <button type="submit" disabled={updateProfile.isPending}
            className="flex items-center gap-2 px-6 py-2.5 rounded-xl font-semibold text-white text-sm transition-all hover:opacity-90 disabled:opacity-60"
            style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)" }}>
            {updateProfile.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
            Сохранить
          </button>
        </form>
      </Section>

      {/* Currency */}
      <Section title="Основная валюта" icon={Wallet}>
        <p className="text-sm text-muted-foreground mb-4">
          Все суммы будут отображаться в выбранной валюте с автоматической конвертацией.
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {Object.entries(CurrencyLabel).map(([code, label]) => {
            const isSelected = code === displayCurrency;
            return (
              <button key={code} onClick={() => onCurrencyChange(code as Currency)}
                disabled={updateProfile.isPending}
                className="py-3 px-4 rounded-xl text-sm font-medium transition-all flex flex-col items-center gap-1 disabled:opacity-60"
                style={{
                  background: isSelected ? "rgba(236,72,153,0.15)" : "rgba(51,65,85,0.4)",
                  border: isSelected ? "1.5px solid rgba(236,72,153,0.5)" : "1.5px solid transparent",
                  color: isSelected ? "#EC4899" : "#64748b",
                }}>
                <span className="text-lg font-bold">{code}</span>
                <span className="text-xs opacity-70">{label.split(" ")[1]}</span>
                {isSelected && <Check className="w-3 h-3" />}
              </button>
            );
          })}
        </div>
      </Section>

      {/* Change Password */}
      <Section title="Смена пароля" icon={Lock}>
        <form onSubmit={passwordForm.handleSubmit(onPasswordSubmit)} className="space-y-4">
          {[
            { name: "oldPassword" as const, label: "Текущий пароль", show: showOldPass, toggle: () => setShowOldPass(!showOldPass) },
            { name: "newPassword" as const, label: "Новый пароль", show: showNewPass, toggle: () => setShowNewPass(!showNewPass) },
            { name: "confirmPassword" as const, label: "Подтвердите пароль", show: showConfirmPass, toggle: () => setShowConfirmPass(!showConfirmPass) },
          ].map(({ name, label, show, toggle }) => (
            <div key={name}>
              <label className="text-xs text-muted-foreground mb-1.5 block">{label}</label>
              <div className="relative">
                <input {...passwordForm.register(name)} type={show ? "text" : "password"}
                  placeholder="••••••••"
                  className="w-full px-4 py-2.5 pr-12 rounded-xl text-foreground placeholder-slate-500 outline-none focus:ring-2 focus:ring-primary/50 text-sm"
                  style={{ background: "rgba(15,23,42,0.8)", border: "1px solid rgba(51,65,85,0.8)" }} />
                <button type="button" onClick={toggle}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-200">
                  {show ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
              {passwordForm.formState.errors[name] && (
                <p className="text-red-400 text-xs mt-1">{passwordForm.formState.errors[name]?.message}</p>
              )}
            </div>
          ))}

          {passError && (
            <div className="flex items-center gap-2 px-4 py-3 rounded-xl text-red-400 text-sm"
              style={{ background: "rgba(239,68,68,0.1)", border: "1px solid rgba(239,68,68,0.2)" }}>
              <AlertCircle className="w-4 h-4 flex-shrink-0" /> {passError}
            </div>
          )}

          <p className="text-xs text-muted-foreground">Пароль должен содержать не менее 6 символов</p>

          <button type="submit" disabled={changePassword.isPending}
            className="flex items-center gap-2 px-6 py-2.5 rounded-xl font-semibold text-white text-sm transition-all hover:opacity-90 disabled:opacity-60"
            style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)" }}>
            {changePassword.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Lock className="w-4 h-4" />}
            Сменить пароль
          </button>
        </form>
      </Section>

      {/* Success toast */}
      {successMsg && <SuccessToast message={successMsg} onClose={() => setSuccessMsg("")} />}
    </div>
  );
}