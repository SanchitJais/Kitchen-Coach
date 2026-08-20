import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { supabase } from "@/integrations/supabase/client";
import type { Tables } from "@/integrations/supabase/types";
import { useAuth } from "@/hooks/useAuth";
import { Package, Utensils, BookOpen, AlertTriangle } from "lucide-react";
import { Link } from "react-router-dom";
import { format, addDays, isBefore } from "date-fns";

export default function Dashboard() {
  const { user } = useAuth();
  const [stats, setStats] = useState({ ingredients: 0, meals: 0, cookable: 0, expiring: 0 });
  const [expiringItems, setExpiringItems] = useState<Tables<"ingredients">[]>([]);

  useEffect(() => {
    if (!user) return;
    const load = async () => {
      const [ing, meals, cookable] = await Promise.all([
        supabase.from("ingredients").select("*").eq("user_id", user.id),
        supabase.from("meal_logs").select("*").eq("user_id", user.id),
        // Recipes fully cookable from current stock — the point of the app,
        // so it earns a tile ahead of a raw recipe count.
        supabase.rpc("available_recipes", { p_user_id: user.id }),
      ]);

      const ingredients = ing.data || [];
      const threeDays = addDays(new Date(), 3);
      const expiring = ingredients.filter(
        (i) => i.expiration_date && isBefore(new Date(i.expiration_date), threeDays)
      );

      setStats({
        ingredients: ingredients.length,
        meals: (meals.data || []).length,
        cookable: (cookable.data || []).length,
        expiring: expiring.length,
      });
      setExpiringItems(expiring.slice(0, 5));
    };
    load();
  }, [user]);

  const cards = [
    { label: "Ingredients", value: stats.ingredients, icon: Package, color: "text-primary", to: "/ingredients" },
    { label: "Meals Logged", value: stats.meals, icon: Utensils, color: "text-accent", to: "/meal-logs" },
    { label: "Can Cook Now", value: stats.cookable, icon: BookOpen, color: "text-success", to: "/recipes" },
    { label: "Expiring Soon", value: stats.expiring, icon: AlertTriangle, color: "text-destructive", to: "/ingredients" },
  ];

  if (!user) {
    return (
      <div className="container py-20 text-center">
        <h1 className="text-3xl font-bold mb-4">Dashboard</h1>
        <p className="text-muted-foreground mb-6">Please sign in to view your dashboard.</p>
        <Link to="/auth" className="text-primary font-medium hover:underline">Sign In</Link>
      </div>
    );
  }

  return (
    <div className="container py-8 space-y-8">
      <div>
        <h1 className="text-3xl font-bold">Dashboard</h1>
        <p className="text-muted-foreground">Welcome back! Here's your kitchen overview.</p>
      </div>

      <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {cards.map((c) => (
          <Link key={c.label} to={c.to}>
            <Card className="hover:shadow-md transition-shadow">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">{c.label}</CardTitle>
                <c.icon className={`h-5 w-5 ${c.color}`} />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold">{c.value}</div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      {expiringItems.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <AlertTriangle className="h-5 w-5 text-destructive" /> Expiring Soon
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {expiringItems.map((item) => (
                <div key={item.id} className="flex items-center justify-between py-2 border-b last:border-0">
                  <span className="font-medium">{item.name}</span>
                  <span className="text-sm text-destructive">
                    {item.expiration_date ? format(new Date(item.expiration_date), "MMM d, yyyy") : "No date"}
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
