import { useCallback, useEffect, useMemo, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import type { Tables } from "@/integrations/supabase/types";
import { useAuth } from "@/hooks/useAuth";
import { useToast } from "@/hooks/use-toast";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { Clock, ChefHat, Check, ListPlus, Sparkles } from "lucide-react";

type RecipeMatch = {
  id: string;
  name: string;
  instructions: string | null;
  prep_time: number | null;
  difficulty_level: string | null;
  total_ingredients: number;
  have_count: number;
  missing_count: number;
  missing_ingredients: string[];
  match_pct: number;
};

type Filter = "ready" | "almost" | "all";

const FILTERS: { key: Filter; label: string }[] = [
  { key: "ready", label: "Can cook now" },
  { key: "almost", label: "Almost there" },
  { key: "all", label: "All recipes" },
];

export default function Recipes() {
  const { user } = useAuth();
  const { toast } = useToast();

  const [matches, setMatches] = useState<RecipeMatch[]>([]);
  const [ingredients, setIngredients] = useState<Record<string, Tables<"recipe_ingredients">[]>>({});
  const [filter, setFilter] = useState<Filter>("ready");
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async () => {
    const [m, ri] = await Promise.all([
      supabase.rpc("recipe_match_summary", { p_user_id: user.id }),
      supabase.from("recipe_ingredients").select("*"),
    ]);

    setMatches((m.data as RecipeMatch[]) ?? []);

    const grouped: Record<string, Tables<"recipe_ingredients">[]> = {};
    (ri.data ?? []).forEach((row) => {
      (grouped[row.recipe_id] ??= []).push(row);
    });
    setIngredients(grouped);
    setLoading(false);
  }, [user.id]);

  useEffect(() => { load(); }, [load]);

  // A recipe with no ingredient rows can't be judged — don't claim it's cookable.
  const ready  = useMemo(() => matches.filter((r) => r.total_ingredients > 0 && r.missing_count === 0), [matches]);
  const almost = useMemo(() => matches.filter((r) => r.missing_count > 0 && r.missing_count <= 2), [matches]);

  const shown = filter === "ready" ? ready : filter === "almost" ? almost : matches;

  const addMissing = async (recipe: RecipeMatch) => {
    setBusy(recipe.id);
    const { data, error } = await supabase.rpc("add_missing_to_shopping_list", {
      p_user_id: user.id,
      p_recipe_id: recipe.id,
    });
    setBusy(null);
    if (error) return toast({ title: "Couldn't add", description: error.message, variant: "destructive" });
    toast({
      title: `${data} item${data === 1 ? "" : "s"} added to your shopping list`,
      description: recipe.missing_ingredients.join(", "),
    });
  };

  const difficultyColor = (d: string | null) => {
    switch (d?.toLowerCase()) {
      case "easy":   return "bg-success/10 text-success border-success/20";
      case "medium": return "bg-accent/10 text-accent border-accent/20";
      case "hard":   return "bg-destructive/10 text-destructive border-destructive/20";
      default:       return "";
    }
  };

  return (
    <div className="container py-8 space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Recipes</h1>
        <p className="text-muted-foreground">
          Matched against what's actually in your kitchen right now.
        </p>
      </div>

      {!loading && (
        <Card className="bg-primary/5 border-primary/20">
          <CardContent className="flex items-center gap-3 py-4">
            <Sparkles className="h-5 w-5 text-primary shrink-0" />
            <p className="text-sm">
              You can cook <strong>{ready.length}</strong> recipe{ready.length === 1 ? "" : "s"} right now
              {almost.length > 0 && (
                <> — and <strong>{almost.length}</strong> more with a couple of extra items.</>
              )}
            </p>
          </CardContent>
        </Card>
      )}

      <div className="flex flex-wrap gap-2">
        {FILTERS.map((f) => {
          const count = f.key === "ready" ? ready.length : f.key === "almost" ? almost.length : matches.length;
          return (
            <button
              key={f.key}
              onClick={() => setFilter(f.key)}
              className={`px-3 py-1.5 rounded-full text-sm font-medium border transition-colors ${
                filter === f.key
                  ? "bg-primary text-primary-foreground border-primary"
                  : "bg-background text-muted-foreground hover:text-foreground hover:bg-muted"
              }`}
            >
              {f.label} ({count})
            </button>
          );
        })}
      </div>

      {loading ? (
        <p className="text-sm text-muted-foreground">Loading…</p>
      ) : shown.length === 0 ? (
        <Card className="py-16 text-center">
          <ChefHat className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
          <p className="text-muted-foreground">
            {filter === "ready"
              ? "Nothing you can make from your current stock yet."
              : filter === "almost"
                ? "No recipes are within a couple of items."
                : "No recipes available yet."}
          </p>
        </Card>
      ) : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {shown.map((r) => {
            const missing = new Set(r.missing_ingredients.map((n) => n.toLowerCase()));
            const canCook = r.total_ingredients > 0 && r.missing_count === 0;
            return (
              <Card key={r.id} className={`flex flex-col hover:shadow-md transition-shadow ${canCook ? "border-success/40" : ""}`}>
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between gap-2">
                    <CardTitle className="text-lg">{r.name}</CardTitle>
                    {r.difficulty_level && (
                      <Badge variant="outline" className={difficultyColor(r.difficulty_level)}>
                        {r.difficulty_level}
                      </Badge>
                    )}
                  </div>
                  {r.prep_time && (
                    <p className="text-sm text-muted-foreground flex items-center gap-1">
                      <Clock className="h-3.5 w-3.5" /> {r.prep_time} min
                    </p>
                  )}
                </CardHeader>

                <CardContent className="space-y-3 flex-1 flex flex-col">
                  {r.total_ingredients === 0 ? (
                    <p className="text-xs text-muted-foreground italic">No ingredients listed yet.</p>
                  ) : (
                    <>
                      <div className="space-y-1.5">
                        <div className="flex items-center justify-between text-xs">
                          <span className={canCook ? "text-success font-medium flex items-center gap-1" : "text-muted-foreground"}>
                            {canCook && <Check className="h-3.5 w-3.5" />}
                            {canCook ? "You have everything" : `${r.have_count} of ${r.total_ingredients} ingredients`}
                          </span>
                          <span className="text-muted-foreground tabular-nums">{r.match_pct}%</span>
                        </div>
                        <Progress value={r.match_pct} className="h-1.5" />
                      </div>

                      {ingredients[r.id] && (
                        <div className="flex flex-wrap gap-1">
                          {ingredients[r.id].map((ri) => {
                            const have = !missing.has(ri.ingredient_name.toLowerCase());
                            return (
                              <Badge
                                key={ri.id}
                                variant="secondary"
                                className={`text-xs font-normal ${
                                  have
                                    ? "bg-success/10 text-success hover:bg-success/10"
                                    : "bg-muted text-muted-foreground line-through"
                                }`}
                              >
                                {ri.ingredient_name}
                              </Badge>
                            );
                          })}
                        </div>
                      )}
                    </>
                  )}

                  {r.instructions && (
                    <p className="text-sm text-muted-foreground line-clamp-3">{r.instructions}</p>
                  )}

                  {r.missing_count > 0 && (
                    <Button
                      variant="outline"
                      size="sm"
                      className="mt-auto w-full"
                      disabled={busy === r.id}
                      onClick={() => addMissing(r)}
                    >
                      <ListPlus className="h-4 w-4 mr-1.5" />
                      {busy === r.id
                        ? "Adding…"
                        : `Add ${r.missing_count} missing item${r.missing_count === 1 ? "" : "s"}`}
                    </Button>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
