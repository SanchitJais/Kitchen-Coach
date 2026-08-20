import { createContext, useContext, ReactNode } from "react";
import type { User } from "@supabase/supabase-js";

// Single-owner mode: the app is for one person. We use a fixed UUID
// matching the seeded data in the database so this owner sees their
// ingredients and meal logs without signing in.
export const OWNER_USER_ID = "11111111-1111-1111-1111-111111111111";

const OWNER_USER: User = {
  id: OWNER_USER_ID,
  aud: "authenticated",
  role: "authenticated",
  email: "owner@kitchencoach.app",
  created_at: new Date().toISOString(),
  app_metadata: {},
  user_metadata: { name: "Owner" },
} as User;

interface AuthCtx {
  user: User;
  loading: boolean;
  isGuest: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthCtx>({
  user: OWNER_USER,
  loading: false,
  isGuest: false,
  signOut: async () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  return (
    <AuthContext.Provider
      value={{ user: OWNER_USER, loading: false, isGuest: false, signOut: async () => {} }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
