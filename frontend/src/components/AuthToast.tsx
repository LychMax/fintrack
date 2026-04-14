import { useState, useEffect } from "react";

export default function AuthToast() {
  const [visible, setVisible] = useState(false);
  const [message, setMessage] = useState("");

  useEffect(() => {
    const handler = (e: Event) => {
      const customEvent = e as CustomEvent;
      setMessage(
        customEvent.detail?.message || 
        "Вы вошли в аккаунт с другого устройства"
      );
      setVisible(true);
    };

    window.addEventListener("auth-error", handler);

    return () => window.removeEventListener("auth-error", handler);
  }, []);

  if (!visible) return null;

  return (
    <div className="fixed bottom-6 right-6 z-[200] max-w-md animate-in fade-in slide-in-from-bottom-4 duration-300">
      <div className="bg-slate-900 border border-red-500/70 rounded-2xl p-6 shadow-2xl flex gap-4 items-start">
        <div className="text-3xl mt-1">⚠️</div>
        
        <div className="flex-1">
          <p className="font-semibold text-white text-base">Сессия завершена</p>
          <p className="text-slate-300 text-[15px] mt-2 leading-relaxed">
            {message}
          </p>
          <p className="text-xs text-slate-500 mt-4">
            Вы были автоматически разлогинены
          </p>
        </div>

        {/* Кнопка закрытия */}
        <button 
          onClick={() => setVisible(false)}
          className="text-slate-400 hover:text-white text-2xl leading-none mt-0.5 transition-colors"
          aria-label="Закрыть"
        >
          ×
        </button>
      </div>
    </div>
  );
}