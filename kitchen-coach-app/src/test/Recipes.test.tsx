import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const h = vi.hoisted(() => ({
  rpc: vi.fn(),
  toast: vi.fn(),
  matches: [
    {
      id: "r1", name: "Lentil Soup", instructions: "Simmer.", prep_time: 40, difficulty_level: "Easy",
      total_ingredients: 3, have_count: 3, missing_count: 0, missing_ingredients: [], match_pct: 100,
    },
    {
      id: "r2", name: "Beef Stir-Fry", instructions: "Fry.", prep_time: 20, difficulty_level: "Medium",
      total_ingredients: 4, have_count: 3, missing_count: 1, missing_ingredients: ["Ground Beef"], match_pct: 75,
    },
    {
      // No ingredient rows: "nothing missing" is vacuously true, so this must
      // NOT be reported as cookable.
      id: "r3", name: "Mushroom Risotto", instructions: "Stir.", prep_time: 45, difficulty_level: "Hard",
      total_ingredients: 0, have_count: 0, missing_count: 0, missing_ingredients: [], match_pct: 0,
    },
  ],
  recipeIngredients: [
    { id: "i1", recipe_id: "r1", ingredient_name: "Lentils", quantity: "300 g" },
    { id: "i2", recipe_id: "r1", ingredient_name: "Onions", quantity: "100 g" },
    { id: "i3", recipe_id: "r1", ingredient_name: "Garlic", quantity: "8 g" },
    { id: "i4", recipe_id: "r2", ingredient_name: "Ground Beef", quantity: "250 g" },
    { id: "i5", recipe_id: "r2", ingredient_name: "Rice", quantity: "150 g" },
  ],
}));

vi.mock("@/integrations/supabase/client", () => {
  const table = (rows: unknown[]) => {
    const chain: Record<string, unknown> = {};
    const self = () => chain;
    chain.select = self;
    chain.eq = self;
    chain.order = self;
    chain.then = (ok: (v: unknown) => unknown, err?: (e: unknown) => unknown) =>
      Promise.resolve({ data: rows, error: null }).then(ok, err);
    return chain;
  };
  return {
    supabase: {
      from: (name: string) => table(name === "recipe_ingredients" ? h.recipeIngredients : []),
      rpc: h.rpc,
    },
  };
});

vi.mock("@/hooks/useAuth", () => ({
  useAuth: () => ({ user: { id: "11111111-1111-1111-1111-111111111111" }, loading: false }),
}));

vi.mock("@/hooks/use-toast", () => ({ useToast: () => ({ toast: h.toast }) }));

import Recipes from "@/pages/Recipes";

describe("Recipes — matching against inventory", () => {
  beforeEach(() => {
    h.toast.mockReset();
    h.rpc.mockReset().mockImplementation((fn: string) => {
      if (fn === "recipe_match_summary") return Promise.resolve({ data: h.matches, error: null });
      if (fn === "add_missing_to_shopping_list") return Promise.resolve({ data: 1, error: null });
      return Promise.resolve({ data: null, error: null });
    });
  });

  it("defaults to recipes cookable from current stock", async () => {
    render(<Recipes />);
    expect(await screen.findByText("Lentil Soup")).toBeInTheDocument();
    expect(screen.queryByText("Beef Stir-Fry")).not.toBeInTheDocument();
  });

  it("does not treat a recipe with zero ingredients as cookable", async () => {
    render(<Recipes />);
    await screen.findByText("Lentil Soup");
    // Mushroom Risotto has missing_count 0 but no ingredients at all.
    expect(screen.queryByText("Mushroom Risotto")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: /can cook now \(1\)/i })).toBeInTheDocument();
  });

  it("summarises how many recipes are ready", async () => {
    render(<Recipes />);
    expect(await screen.findByText(/You can cook/)).toBeInTheDocument();
    expect(screen.getByText(/more with a couple of extra items/)).toBeInTheDocument();
  });

  it("shows near-miss recipes and what they are missing", async () => {
    const user = userEvent.setup();
    render(<Recipes />);
    await screen.findByText("Lentil Soup");

    await user.click(screen.getByRole("button", { name: /almost there/i }));

    expect(await screen.findByText("Beef Stir-Fry")).toBeInTheDocument();
    expect(screen.getByText("3 of 4 ingredients")).toBeInTheDocument();
    expect(screen.getByText("75%")).toBeInTheDocument();
  });

  it("pushes the missing ingredients onto the shopping list", async () => {
    const user = userEvent.setup();
    render(<Recipes />);
    await screen.findByText("Lentil Soup");
    await user.click(screen.getByRole("button", { name: /almost there/i }));

    await user.click(await screen.findByRole("button", { name: /add 1 missing item/i }));

    await waitFor(() =>
      expect(h.rpc).toHaveBeenCalledWith("add_missing_to_shopping_list", {
        p_user_id: "11111111-1111-1111-1111-111111111111",
        p_recipe_id: "r2",
      }),
    );
    await waitFor(() =>
      expect(h.toast).toHaveBeenCalledWith(
        expect.objectContaining({ description: "Ground Beef" }),
      ),
    );
  });

  it("offers no add button when nothing is missing", async () => {
    render(<Recipes />);
    await screen.findByText("Lentil Soup");
    expect(screen.queryByRole("button", { name: /missing item/i })).not.toBeInTheDocument();
    expect(screen.getByText("You have everything")).toBeInTheDocument();
  });

  it("lists every recipe under the All filter, including ingredient-less ones", async () => {
    const user = userEvent.setup();
    render(<Recipes />);
    await screen.findByText("Lentil Soup");

    await user.click(screen.getByRole("button", { name: /all recipes/i }));

    expect(await screen.findByText("Mushroom Risotto")).toBeInTheDocument();
    expect(screen.getByText("No ingredients listed yet.")).toBeInTheDocument();
  });
});
