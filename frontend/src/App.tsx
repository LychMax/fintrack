import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import { useAuthStore } from "@/store/useAuthStore";

import Layout from "@/components/Layout";
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
  const { isAuthenticated } = useAuthStore();

  return (
    <Router>
      <Routes>
        <Route path="/login" element={!isAuthenticated() ? <Login /> : <Navigate to="/" replace />} />
        <Route path="/register" element={!isAuthenticated() ? <Register /> : <Navigate to="/" replace />} />

        <Route
          path="/*"
          element={
            isAuthenticated() ? (
              <Layout>
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/transactions" element={<Transactions />} />
                  <Route path="/reports" element={<Reports />} />
                  <Route path="/budgets" element={<Budgets />} />
                  <Route path="/categories" element={<Categories />} />
                  <Route path="/profile" element={<Profile />} />

                  <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
              </Layout>
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />
      </Routes>

      <AuthToast />
    </Router>
  );
}

export default App;