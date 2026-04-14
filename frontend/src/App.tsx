import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import { useAuthStore } from "@/store/useAuthStore";

import Layout from "@/components/Layout";        // или "@/Layout" — смотри свой импорт
import Dashboard from "@/pages/Dashboard";
import Transactions from "@/pages/Transactions";
import Reports from "@/pages/Reports";
import Budgets from "@/pages/Budgets";
import Categories from "@/pages/Categories";
import Profile from "@/pages/Profile";

import Login from "@/pages/Login";
import Register from "@/pages/Register";

import AuthToast from "@/components/AuthToast";

function App() {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated());

  return (
    <Router>
      <Routes>
        {/* Публичные страницы */}
        <Route 
          path="/login" 
          element={isAuthenticated ? <Navigate to="/" replace /> : <Login />} 
        />
        <Route 
          path="/register" 
          element={isAuthenticated ? <Navigate to="/" replace /> : <Register />} 
        />

        {/* Защищённые страницы с Layout */}
        <Route
          path="/*"
          element={
            isAuthenticated ? (
              <Layout>
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/transactions" element={<Transactions />} />
                  <Route path="/reports" element={<Reports />} />
                  <Route path="/budgets" element={<Budgets />} />
                  <Route path="/categories" element={<Categories />} />
                  <Route path="/profile" element={<Profile />} />
                  
                  {/* Любые неизвестные маршруты внутри приложения → на главную */}
                  <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
              </Layout>
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />
      </Routes>

      {/* Глобальное уведомление */}
      <AuthToast />
    </Router>
  );
}

export default App;