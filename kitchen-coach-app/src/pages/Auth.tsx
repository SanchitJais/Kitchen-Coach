import { Navigate } from "react-router-dom";

// Single-owner mode: no auth needed, redirect to dashboard.
export default function Auth() {
  return <Navigate to="/dashboard" replace />;
}
