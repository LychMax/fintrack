import { useState, useEffect } from "react";

export default function AuthToast() {
  const [visible, setVisible] = useState(false);
  const [message, setMessage] = useState("");

  useEffect(() => {
    const handler = (e: CustomEvent) => {
      setMessage(e.detail.message);
      setVisible(true);

      setTimeout(() => {
        setVisible(false);
      }, 10000);
    };

    window.addEventListener("auth-error", handler as EventListener);

    return () => {
      window.removeEventListener("auth-error", handler as EventListener);
    };
  }, []);

  if (!visible) return null;

  return (
    <div className="fixed bottom-6 right-6 z-[100] max-w-md">
      <div className="bg-slate-800 border border-red-500/50 rounded-2xl p-5 shadow-2xl flex gap-4 items-start">
        <div className="text-2xl mt-0.5">⚠️</div>
        <div>
          <p className="font-semibold text-white text-base">Сессия завершена</p>
          <p className="text-slate-300 text-sm mt-1">{message}</p>
          <p className="text-xs text-slate-500 mt-3">
            Вы были автоматически разлогинены
          </p>
        </div>
      </div>
    </div>
  );
}