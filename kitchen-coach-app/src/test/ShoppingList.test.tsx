import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

// vi.mock factories are hoisted above the module body, so anything they close
// over has to be created inside vi.hoisted().
const h = vi.hoisted(() => ({
  rpc: vi.fn(),
  update: vi.fn(),
  del: vi.fn(),
  toast: vi.fn(),
  storeItems: [
    { id: "s1", name: "Paneer", category: "Dairy & Eggs", emoji: "🧀", default_quantity: 400, default_unit: "g", calories_per_unit: 265, created_at: "" },
    { id: "s2", name: "Spinach", category: "Vegetables", emoji: "🥬", default_quantity: 250, default_unit: "g", calories_per_unit: 23, created_at: "" },
    { id: "s3", name: "Salt & Pepper", category: "Condiments", emoji: "🧂", default_quantity: 1, default_unit: "pcs", calories_per_unit: null, created_at: "" },
  ],
  listItems: [
    { id: "l1", user_id: "u", store_item_id: "s2", name: "Spinach", quantity: 250, unit: "g", category: "Vegetables", checked: false, created_at: "" },
  ],
}));

vi.mock("@/integrations/supabase/client", () => {
  // Mirrors PostgrestFilterBuilder: every filter returns the builder, and the
  // builder itself is thenable, so .order().order() and await both work.
  const table = (rows: unknown[]) => {
    const chain: Record<string, unknown> = {};
    const self = () => chain;
    chain.select = self;
    chain.eq = self;
    chain.order = self;
    chain.then = (ok: (v: unknown) => unknown, err?: (e: unknown) => unknown) =>
      Promise.resolve({ data: rows, error: null }).then(ok, err);
    chain.update = () => ({ eq: h.update });
    chain.delete = () => ({ eq: h.del });
    return chain;
  };
  return {
    supabase: {
      from: (name: string) =>
        table(
          name === "store_items" ? h.storeItems
          : name === "shopping_list_items" ? h.listItems
          : [],
        ),
      rpc: h.rpc,
    },
  };
});

vi.mock("@/hooks/useAuth", () => ({
  useAuth: () => ({ user: { id: "11111111-1111-1111-1111-111111111111" }, loading: false }),
}));

vi.mock("@/hooks/use-toast", () => ({ useToast: () => ({ toast: h.toast }) }));

import ShoppingList from "@/pages/ShoppingList";

describe("ShoppingList", () => {
  beforeEach(() => {
    h.rpc.mockReset().mockResolvedValue({ data: null, error: null });
    h.update.mockReset().mockResolvedValue({ error: null });
    h.del.mockReset().mockResolvedValue({ error: null });
    h.toast.mockReset();
  });

  const gotoBrowse = async (user: ReturnType<typeof userEvent.setup>) => {
    await user.click(screen.getByRole("tab", { name: /browse/i }));
    return screen.findByText("Paneer");
  };

  it("renders the saved list from the database, not local state", async () => {
    render(<ShoppingList />);
    expect(await screen.findByText("Spinach")).toBeInTheDocument();
    expect(screen.getByText("250 g")).toBeInTheDocument();
  });

  it("checking an item off persists it", async () => {
    const user = userEvent.setup();
    render(<ShoppingList />);
    await screen.findByText("Spinach");
    await user.click(screen.getByLabelText("Check off Spinach"));
    await waitFor(() => expect(h.update).toHaveBeenCalled());
  });

  it("changing quantity persists it", async () => {
    const user = userEvent.setup();
    render(<ShoppingList />);
    await screen.findByText("Spinach");
    await user.click(screen.getByLabelText("Increase quantity"));
    await waitFor(() => expect(h.update).toHaveBeenCalled());
  });

  it("removing an item persists it", async () => {
    const user = userEvent.setup();
    render(<ShoppingList />);
    await screen.findByText("Spinach");
    await user.click(screen.getByLabelText("Remove Spinach"));
    await waitFor(() => expect(h.del).toHaveBeenCalled());
  });

  it("adds a catalogue item to the list via add_to_shopping_list", async () => {
    const user = userEvent.setup();
    render(<ShoppingList />);
    await gotoBrowse(user);

    await user.click((await screen.findAllByRole("button", { name: /^Add$/ }))[0]);

    await waitFor(() =>
      expect(h.rpc).toHaveBeenCalledWith(
        "add_to_shopping_list",
        expect.objectContaining({ p_name: expect.any(String), p_quantity: expect.any(Number) }),
      ),
    );
  });

  it("saves a catalogue item for later via add_to_cart", async () => {
    const user = userEvent.setup();
    render(<ShoppingList />);
    await gotoBrowse(user);

    await user.click((await screen.findAllByRole("button", { name: /^Save$/ }))[0]);

    await waitFor(() => expect(h.rpc).toHaveBeenCalledWith("add_to_cart", expect.any(Object)));
  });

  it("filters the catalogue by search text", async () => {
    const user = userEvent.setup();
    render(<ShoppingList />);
    await gotoBrowse(user);

    await user.type(screen.getByPlaceholderText("Search items..."), "spin");

    expect(await screen.findByText("Spinach")).toBeInTheDocument();
    expect(screen.queryByText("Paneer")).not.toBeInTheDocument();
  });

  it("shows Amazon / Flipkart / Blinkit search links for the opened item", async () => {
    const user = userEvent.setup();
    render(<ShoppingList />);
    await user.click(screen.getByRole("tab", { name: /browse/i }));
    await user.click(await screen.findByText("Paneer"));

    const amazon = await screen.findByRole("link", { name: /amazon/i });
    expect(amazon).toHaveAttribute("href", "https://www.amazon.in/s?k=Paneer");
    expect(amazon).toHaveAttribute("target", "_blank");
    expect(amazon.getAttribute("rel")).toContain("noopener");

    expect(screen.getByRole("link", { name: /flipkart/i }))
      .toHaveAttribute("href", "https://www.flipkart.com/search?q=Paneer");
    expect(screen.getByRole("link", { name: /blinkit/i }))
      .toHaveAttribute("href", "https://blinkit.com/s/?q=Paneer");
  });

  it("url-encodes item names so '&' cannot break the query string", async () => {
    const user = userEvent.setup();
    render(<ShoppingList />);
    await user.click(screen.getByRole("tab", { name: /browse/i }));
    await user.click(await screen.findByText("Salt & Pepper"));

    const amazon = await screen.findByRole("link", { name: /amazon/i });
    expect(amazon).toHaveAttribute("href", "https://www.amazon.in/s?k=Salt%20%26%20Pepper");
  });
});
