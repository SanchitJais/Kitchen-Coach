import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import type { Tables } from "@/integrations/supabase/types";
import { useAuth } from "@/hooks/useAuth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import { Plus, Utensils, Star } from "lucide-react";
import { format } from "date-fns";
import { Link } from "react-router-dom";

export default function MealLogs() {
  const { user } = useAuth();
  const { toast } = useToast();
  const [logs, setLogs] = useState<(Tables<"meal_logs"> & { recipes: Pick<Tables<"recipes">, "name"> | null })[]>([]);
  const [recipes, setRecipes] = useState<Pick<Tables<"recipes">, "id" | "name">[]>([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ recipe_id: "", consumed_date: format(new Date(), "yyyy-MM-dd"), rating: "5" });

  const load = async () => {
    if (!user) return;
    const [logsRes, recipesRes] = await Promise.all([
      supabase.from("meal_logs").select("*, recipes(name)").eq("user_id", user.id).order("consumed_date", { ascending: false }),
      supabase.from("recipes").select("id, name"),
    ]);
    setLogs(logsRes.data || []);
    setRecipes(recipesRes.data || []);
  };

  useEffect(() => { load(); }, [user]);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    // The Select starts empty and Radix has no native required validation, so
    // guard here — otherwise an empty recipe_id reaches Postgres as "" and
    // surfaces as "invalid input syntax for type uuid".
    if (!form.recipe_id) {
      toast({ title: "Pick a recipe", description: "Select which recipe you ate.", variant: "destructive" });
      return;
    }
    const { error } = await supabase.from("meal_logs").insert({
      user_id: user.id,
      recipe_id: form.recipe_id,
      consumed_date: form.consumed_date,
      rating: parseInt(form.rating),
    });
    if (error) { toast({ title: "Error", description: error.message, variant: "destructive" }); return; }
    toast({ title: "Meal logged!" });
    setForm({ recipe_id: "", consumed_date: format(new Date(), "yyyy-MM-dd"), rating: "5" });
    setOpen(false);
    load();
  };

  if (!user) {
    return (
      <div className="container py-20 text-center">
        <h1 className="text-3xl font-bold mb-4">Meal Logs</h1>
        <p className="text-muted-foreground mb-6">Please sign in to log meals.</p>
        <Link to="/auth" className="text-primary font-medium hover:underline">Sign In</Link>
      </div>
    );
  }

  return (
    <div className="container py-8 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Meal Logs</h1>
          <p className="text-muted-foreground">Track what you eat</p>
        </div>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button><Plus className="h-4 w-4 mr-1" /> Log Meal</Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader><DialogTitle>Log a Meal</DialogTitle></DialogHeader>
            <form onSubmit={handleAdd} className="space-y-4">
              <div className="space-y-2">
                <Label>Recipe</Label>
                <Select value={form.recipe_id} onValueChange={(v) => setForm({ ...form, recipe_id: v })}>
                  <SelectTrigger><SelectValue placeholder="Select a recipe" /></SelectTrigger>
                  <SelectContent>
                    {recipes.map((r) => <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-2">
                  <Label>Date</Label>
                  <Input type="date" value={form.consumed_date} onChange={(e) => setForm({ ...form, consumed_date: e.target.value })} />
                </div>
                <div className="space-y-2">
                  <Label>Rating (1-5)</Label>
                  <Input type="number" min="1" max="5" value={form.rating} onChange={(e) => setForm({ ...form, rating: e.target.value })} />
                </div>
              </div>
              <Button type="submit" className="w-full">Log Meal</Button>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      {logs.length === 0 ? (
        <Card className="py-16 text-center">
          <Utensils className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
          <p className="text-muted-foreground">No meals logged yet.</p>
        </Card>
      ) : (
        <div className="space-y-3">
          {logs.map((log) => (
            <Card key={log.id}>
              <CardContent className="flex items-center justify-between py-4">
                <div>
                  <p className="font-medium">{log.recipes?.name || "Unknown recipe"}</p>
                  <p className="text-sm text-muted-foreground">{format(new Date(log.consumed_date), "MMMM d, yyyy")}</p>
                </div>
                {log.rating && (
                  <div className="flex items-center gap-1 text-accent">
                    <Star className="h-4 w-4 fill-current" />
                    <span className="font-medium">{log.rating}/5</span>
                  </div>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
