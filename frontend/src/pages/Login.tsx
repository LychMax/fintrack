import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import api from "@/lib/api";
import { useAuthStore } from "@/store/useAuthStore";
import { useNavigate, Link } from "react-router-dom";
import { Loader2, TrendingUp, Eye, EyeOff } from "lucide-react";
import { useState } from "react";

const schema = z.object({
  login: z.string().min(1, "Введите логин или email"),
  password: z.string().min(1, "Введите пароль"),
});

type FormData = z.infer<typeof schema>;

export default function Login() {
  const navigate = useNavigate();
  const setToken = useAuthStore((s) => s.setToken);
  const [showPass, setShowPass] = useState(false);
  const [serverError, setServerError] = useState("");

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({ resolver: zodResolver(schema) });

  const onSubmit = async (data: FormData) => {
    setServerError("");
    try {
      const res = await api.post("/auth/login", data);
      setToken(res.data.token);
      navigate("/");
    } catch (e: any) {
      const msg = e?.response?.data?.message || "Неверный логин или пароль";
      setServerError(msg);
    }
  };

  return (
    <div className="min-h-screen flex bg-background">
      {/* Left decorative panel */}
      <div className="hidden lg:flex lg:w-1/2 flex-col items-center justify-center relative overflow-hidden"
        style={{ background: "linear-gradient(135deg, #0f172a 0%, #1e1b4b 50%, #0f172a 100%)" }}
      >
        <div className="absolute inset-0" style={{
          backgroundImage: "radial-gradient(circle at 30% 40%, rgba(236,72,153,0.15) 0%, transparent 50%), radial-gradient(circle at 70% 60%, rgba(168,85,247,0.15) 0%, transparent 50%)"
        }} />
        <div className="relative z-10 text-center px-12">
          <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center mx-auto mb-8 shadow-2xl">
            <TrendingUp className="w-10 h-10 text-white" />
          </div>
          <h1 className="text-5xl font-bold mb-4" style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
            FinTrack
          </h1>
          <p className="text-xl text-slate-400 leading-relaxed">
            Контролируйте финансы,<br />достигайте целей
          </p>
          <div className="mt-12 grid grid-cols-3 gap-6 text-center">
            {[
              { label: "Транзакции", sub: "Учёт доходов и расходов" },
              { label: "Бюджеты", sub: "Лимиты по категориям" },
              { label: "Отчёты", sub: "Аналитика и графики" },
            ].map((f) => (
              <div key={f.label} className="p-4 rounded-2xl" style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.08)" }}>
                <p className="font-semibold text-white text-sm mb-1">{f.label}</p>
                <p className="text-xs text-slate-500">{f.sub}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right form */}
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="w-full max-w-md">
          <div className="lg:hidden flex items-center gap-3 mb-10 justify-center">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center">
              <TrendingUp className="w-5 h-5 text-white" />
            </div>
            <span className="text-2xl font-bold" style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
              FinTrack
            </span>
          </div>

          <h2 className="text-3xl font-bold text-foreground mb-2">Добро пожаловать!</h2>
          <p className="text-muted-foreground mb-8">Войдите в свой аккаунт</p>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">Логин или Email</label>
              <input
                {...register("login")}
                placeholder="Login или email@example.com"
                className="w-full px-4 py-3 rounded-xl text-foreground placeholder-slate-500 outline-none focus:ring-2 focus:ring-primary/50 transition-all"
                style={{ background: "rgba(30,41,59,0.8)", border: "1px solid rgba(51,65,85,0.8)" }}
              />
              {errors.login && <p className="text-red-400 text-sm mt-1">{errors.login.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">Пароль</label>
              <div className="relative">
                <input
                  {...register("password")}
                  type={showPass ? "text" : "password"}
                  placeholder="••••••••"
                  className="w-full px-4 py-3 pr-12 rounded-xl text-foreground placeholder-slate-500 outline-none focus:ring-2 focus:ring-primary/50 transition-all"
                  style={{ background: "rgba(30,41,59,0.8)", border: "1px solid rgba(51,65,85,0.8)" }}
                />
                <button type="button" onClick={() => setShowPass(!showPass)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-200">
                  {showPass ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
              {errors.password && <p className="text-red-400 text-sm mt-1">{errors.password.message}</p>}
            </div>

            {serverError && (
              <div className="px-4 py-3 rounded-xl text-red-400 text-sm" style={{ background: "rgba(239,68,68,0.1)", border: "1px solid rgba(239,68,68,0.2)" }}>
                {serverError}
              </div>
            )}

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full py-3 rounded-xl font-semibold text-white flex items-center justify-center gap-2 transition-all hover:opacity-90 active:scale-[0.98] disabled:opacity-60"
              style={{ background: "linear-gradient(135deg, #EC4899, #A855F7)", boxShadow: "0 4px 20px rgba(236,72,153,0.3)" }}
            >
              {isSubmitting ? <Loader2 className="w-5 h-5 animate-spin" /> : "Войти"}
            </button>
          </form>

          <p className="mt-6 text-center text-muted-foreground text-sm">
            Нет аккаунта?{" "}
            <Link to="/register" className="text-primary hover:text-primary/80 font-medium transition-colors">
              Зарегистрироваться
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}