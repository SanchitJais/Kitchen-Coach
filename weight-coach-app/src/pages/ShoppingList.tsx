import { useCallback, useEffect, useMemo, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import type { Tables } from "@/integrations/supabase/types";
import { useAuth } from "@/hooks/useAuth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import {
  Plus, Minus, Trash2, ShoppingCart, Check, Search,
  ExternalLink, ListPlus, Bookmark, PackageOpen,
} from "lucide-react";

type StoreItem = Tables<"store_items">;
type ListItem = Tables<"shopping_list_items">;
type CartItem = Tables<"cart_items">;

// Retailer links are *search* URLs, not deep product links. Product IDs and
// prices change constantly, so a hardcoded listing would rot or 404 — a
// search query always resolves to live results for the item.
const RETAILERS: { name: string; color: string; url: (q: string) => string }[] = [
  { name: "Amazon",   color: "hover:border-[#FF9900] hover:text-[#FF9900]", url: (q) => `https://www.amazon.in/s?k=${encodeURIComponent(q)}` },
  { name: "Flipkart", color: "hover:border-[#2874F0] hover:text-[#2874F0]", url: (q) => `https://www.flipkart.com/search?q=${encodeURIComponent(q)}` },
  { name: "Blinkit",  color: "hover:border-[#F8CB46] hover:text-[#C79A00]", url: (q) => `https://blinkit.com/s/?q=${encodeURIComponent(q)}` },
];

const qtyLabel = (q: number, unit: string) =>
  `${Number.isInteger(q) ? q : q.toFixed(2).replace(/\.?0+$/, "")} ${unit}`;

export default function ShoppingList() {
  const { user } = useAuth();
  const { toast } = useToast();

  const [catalog, setCatalog] = useState<StoreItem[]>([]);
  const [list, setList] = useState<ListItem[]>([]);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [loading, setLoading] = useState(true);

  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("All");
  const [selected, setSelected] = useState<StoreItem | null>(null);
  const [dialogQty, setDialogQty] = useState(1);
  const [customItem, setCustomItem] = useState("");

  const load = useCallback(async () => {
    const [c, l, ct] = await Promise.all([
      supabase.from("store_items").select("*").order("category").order("name"),
      supabase.from("shopping_list_items").select("*").eq("user_id", user.id).order("created_at", { ascending: false }),
      supabase.from("cart_items").select("*").eq("user_id", user.id).order("created_at", { ascending: false }),
    ]);
    setCatalog(c.data ?? []);
    setList(l.data ?? []);
    setCart(ct.data ?? []);
    setLoading(false);
  }, [user.id]);

  useEffect(() => { load(); }, [load]);

  const categories = useMemo(
    () => ["All", ...Array.from(new Set(catalog.map((i) => i.category)))],
    [catalog],
  );

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return catalog.filter(
      (i) =>
        (category === "All" || i.category === category) &&
        (!q || i.name.toLowerCase().includes(q) || i.category.toLowerCase().includes(q)),
    );
  }, [catalog, search, category]);

  const listNames = useMemo(() => new Set(list.map((i) => i.name.toLowerCase())), [list]);
  const cartNames = useMemo(() => new Set(cart.map((i) => i.name.toLowerCase())), [cart]);

  // ---- mutations -------------------------------------------------------

  const addToList = async (item: StoreItem, quantity = item.default_quantity) => {
    const { error } = await supabase.rpc("add_to_shopping_list", {
      p_user_id: user.id,
      p_name: item.name,
      p_quantity: quantity,
      p_unit: item.default_unit,
      p_category: item.category,
      p_store_item_id: item.id,
    });
    if (error) return toast({ title: "Couldn't add", description: error.message, variant: "destructive" });
    toast({ title: `${item.name} added to your list` });
    load();
  };

  const addToCart = async (item: StoreItem, quantity = item.default_quantity) => {
    const { error } = await supabase.rpc("add_to_cart", {
      p_user_id: user.id,
      p_name: item.name,
      p_quantity: quantity,
      p_unit: item.default_unit,
      p_category: item.category,
      p_store_item_id: item.id,
    });
    if (error) return toast({ title: "Couldn't save", description: error.message, variant: "destructive" });
    toast({ title: `${item.name} saved to cart` });
    load();
  };

  const addCustom = async () => {
    const name = customItem.trim();
    if (!name) return;
    const { error } = await supabase.rpc("add_to_shopping_list", {
      p_user_id: user.id,
      p_name: name,
      p_quantity: 1,
      p_unit: "pcs",
    });
    if (error) return toast({ title: "Couldn't add", description: error.message, variant: "destructive" });
    setCustomItem("");
    load();
  };

  const toggleChecked = async (item: ListItem) => {
    setList((prev) => prev.map((i) => (i.id === item.id ? { ...i, checked: !i.checked } : i)));
    const { error } = await supabase
      .from("shopping_list_items")
      .update({ checked: !item.checked })
      .eq("id", item.id);
    if (error) load(); // revert to server truth
  };

  const changeQty = async (item: ListItem, delta: number) => {
    const next = item.quantity + delta;
    if (next <= 0) return;
    setList((prev) => prev.map((i) => (i.id === item.id ? { ...i, quantity: next } : i)));
    const { error } = await supabase.from("shopping_list_items").update({ quantity: next }).eq("id", item.id);
    if (error) load();
  };

  const removeFromList = async (id: string) => {
    await supabase.from("shopping_list_items").delete().eq("id", id);
    load();
  };

  const removeFromCart = async (id: string) => {
    await supabase.from("cart_items").delete().eq("id", id);
    load();
  };

  const moveToList = async (id: string) => {
    const { error } = await supabase.rpc("move_cart_item_to_list", { p_cart_item_id: id });
    if (error) return toast({ title: "Couldn't move", description: error.message, variant: "destructive" });
    toast({ title: "Moved to shopping list" });
    load();
  };

  const clearChecked = async () => {
    await supabase.from("shopping_list_items").delete().eq("user_id", user.id).eq("checked", true);
    load();
  };

  const openItem = (item: StoreItem) => {
    setSelected(item);
    setDialogQty(item.default_quantity);
  };

  const checkedCount = list.filter((i) => i.checked).length;

  // ---- render ----------------------------------------------------------

  return (
    <div className="container py-8 space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Shopping</h1>
        <p className="text-muted-foreground">Browse items, build your list, and save things for later.</p>
      </div>

      <Tabs defaultValue="list">
        <TabsList>
          <TabsTrigger value="list" className="gap-2">
            My List {list.length > 0 && <Badge variant="secondary">{list.length}</Badge>}
          </TabsTrigger>
          <TabsTrigger value="cart" className="gap-2">
            Cart {cart.length > 0 && <Badge variant="secondary">{cart.length}</Badge>}
          </TabsTrigger>
          <TabsTrigger value="browse">Browse</TabsTrigger>
        </TabsList>

        {/* ---------------- MY LIST ---------------- */}
        <TabsContent value="list" className="space-y-4 pt-4">
          <div className="flex gap-2">
            <Input
              value={customItem}
              onChange={(e) => setCustomItem(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && addCustom()}
              placeholder="Add your own item..."
              className="flex-1"
            />
            <Button onClick={addCustom} disabled={!customItem.trim()}>
              <Plus className="h-4 w-4" />
            </Button>
          </div>

          {loading ? (
            <p className="text-muted-foreground text-sm">Loading…</p>
          ) : list.length === 0 ? (
            <Card className="py-16 text-center">
              <ShoppingCart className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">Your shopping list is empty.</p>
              <p className="text-sm text-muted-foreground mt-1">Add an item above, or pick from Browse.</p>
            </Card>
          ) : (
            <>
              <div className="space-y-2">
                {list.map((item) => (
                  <Card key={item.id}>
                    <CardContent className="flex items-center gap-3 py-3">
                      <button
                        onClick={() => toggleChecked(item)}
                        aria-label={item.checked ? `Uncheck ${item.name}` : `Check off ${item.name}`}
                        className={`h-6 w-6 shrink-0 rounded-full border-2 flex items-center justify-center transition-colors ${
                          item.checked ? "bg-primary border-primary" : "border-muted-foreground/30"
                        }`}
                      >
                        {item.checked && <Check className="h-3.5 w-3.5 text-primary-foreground" />}
                      </button>

                      <div className="flex-1 min-w-0">
                        <p className={`font-medium truncate ${item.checked ? "line-through text-muted-foreground" : ""}`}>
                          {item.name}
                        </p>
                        {item.category && (
                          <p className="text-xs text-muted-foreground">{item.category}</p>
                        )}
                      </div>

                      <div className="flex items-center gap-1 shrink-0">
                        <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => changeQty(item, -1)} aria-label="Decrease quantity">
                          <Minus className="h-3.5 w-3.5" />
                        </Button>
                        <span className="text-sm tabular-nums w-20 text-center text-muted-foreground">
                          {qtyLabel(item.quantity, item.unit)}
                        </span>
                        <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => changeQty(item, 1)} aria-label="Increase quantity">
                          <Plus className="h-3.5 w-3.5" />
                        </Button>
                      </div>

                      <button
                        onClick={() => removeFromList(item.id)}
                        aria-label={`Remove ${item.name}`}
                        className="text-muted-foreground hover:text-destructive transition-colors shrink-0"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </CardContent>
                  </Card>
                ))}
              </div>

              <div className="flex items-center justify-between pt-1">
                <p className="text-sm text-muted-foreground">
                  {checkedCount} of {list.length} picked up
                </p>
                {checkedCount > 0 && (
                  <Button variant="outline" size="sm" onClick={clearChecked}>
                    Clear picked up
                  </Button>
                )}
              </div>
            </>
          )}
        </TabsContent>

        {/* ---------------- CART ---------------- */}
        <TabsContent value="cart" className="space-y-4 pt-4">
          {loading ? (
            <p className="text-muted-foreground text-sm">Loading…</p>
          ) : cart.length === 0 ? (
            <Card className="py-16 text-center">
              <Bookmark className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">Nothing saved for later.</p>
              <p className="text-sm text-muted-foreground mt-1">
                Use “Save for later” on any item to keep it here.
              </p>
            </Card>
          ) : (
            <div className="space-y-2">
              {cart.map((item) => (
                <Card key={item.id}>
                  <CardContent className="flex items-center gap-3 py-3">
                    <Bookmark className="h-4 w-4 text-accent shrink-0" />
                    <div className="flex-1 min-w-0">
                      <p className="font-medium truncate">{item.name}</p>
                      <p className="text-xs text-muted-foreground">
                        {qtyLabel(item.quantity, item.unit)}
                        {item.category ? ` · ${item.category}` : ""}
                      </p>
                    </div>
                    <Button variant="outline" size="sm" onClick={() => moveToList(item.id)} className="shrink-0">
                      <ListPlus className="h-4 w-4 mr-1" /> Move to list
                    </Button>
                    <button
                      onClick={() => removeFromCart(item.id)}
                      aria-label={`Remove ${item.name} from cart`}
                      className="text-muted-foreground hover:text-destructive transition-colors shrink-0"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* ---------------- BROWSE ---------------- */}
        <TabsContent value="browse" className="space-y-4 pt-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search items..."
              className="pl-9"
            />
          </div>

          <div className="flex flex-wrap gap-2">
            {categories.map((c) => (
              <button
                key={c}
                onClick={() => setCategory(c)}
                className={`px-3 py-1.5 rounded-full text-sm font-medium border transition-colors ${
                  category === c
                    ? "bg-primary text-primary-foreground border-primary"
                    : "bg-background text-muted-foreground hover:text-foreground hover:bg-muted"
                }`}
              >
                {c}
              </button>
            ))}
          </div>

          {filtered.length === 0 ? (
            <Card className="py-16 text-center">
              <PackageOpen className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">No items match “{search}”.</p>
            </Card>
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {filtered.map((item) => {
                const inList = listNames.has(item.name.toLowerCase());
                const inCart = cartNames.has(item.name.toLowerCase());
                return (
                  <Card key={item.id} className="hover:shadow-md transition-shadow">
                    <CardContent className="p-4 space-y-3">
                      <button onClick={() => openItem(item)} className="w-full text-left flex items-start gap-3">
                        <span className="text-3xl leading-none shrink-0" aria-hidden>{item.emoji ?? "🛒"}</span>
                        <div className="min-w-0 flex-1">
                          <p className="font-medium truncate">{item.name}</p>
                          <p className="text-xs text-muted-foreground">
                            {qtyLabel(item.default_quantity, item.default_unit)} · {item.category}
                          </p>
                          {item.calories_per_unit != null && (
                            <p className="text-xs text-muted-foreground mt-0.5">
                              {item.calories_per_unit} cal/unit
                            </p>
                          )}
                        </div>
                      </button>

                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          variant={inList ? "secondary" : "default"}
                          className="flex-1"
                          onClick={() => addToList(item)}
                        >
                          {inList ? <Check className="h-3.5 w-3.5 mr-1" /> : <Plus className="h-3.5 w-3.5 mr-1" />}
                          {inList ? "In list" : "Add"}
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          className="flex-1"
                          onClick={() => addToCart(item)}
                        >
                          <Bookmark className={`h-3.5 w-3.5 mr-1 ${inCart ? "fill-current" : ""}`} />
                          {inCart ? "Saved" : "Save"}
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </TabsContent>
      </Tabs>

      {/* ---------------- ITEM DETAIL ---------------- */}
      <Dialog open={!!selected} onOpenChange={(o) => !o && setSelected(null)}>
        <DialogContent>
          {selected && (
            <>
              <DialogHeader>
                <DialogTitle className="flex items-center gap-3 text-xl">
                  <span className="text-3xl" aria-hidden>{selected.emoji ?? "🛒"}</span>
                  {selected.name}
                </DialogTitle>
                <DialogDescription>
                  Add it to your shopping list, save it for later, or buy it now.
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-5">
                <div className="flex flex-wrap gap-2">
                  <Badge variant="secondary">{selected.category}</Badge>
                  {selected.calories_per_unit != null && (
                    <Badge variant="outline">{selected.calories_per_unit} cal per unit</Badge>
                  )}
                </div>

                <div className="flex items-center gap-3">
                  <span className="text-sm text-muted-foreground">Quantity</span>
                  <div className="flex items-center gap-1">
                    <Button
                      variant="outline"
                      size="icon"
                      className="h-8 w-8"
                      onClick={() => setDialogQty((q) => Math.max(1, q - 1))}
                      aria-label="Decrease quantity"
                    >
                      <Minus className="h-4 w-4" />
                    </Button>
                    <span className="w-24 text-center tabular-nums font-medium">
                      {qtyLabel(dialogQty, selected.default_unit)}
                    </span>
                    <Button
                      variant="outline"
                      size="icon"
                      className="h-8 w-8"
                      onClick={() => setDialogQty((q) => q + 1)}
                      aria-label="Increase quantity"
                    >
                      <Plus className="h-4 w-4" />
                    </Button>
                  </div>
                </div>

                <div className="flex gap-2">
                  <Button
                    className="flex-1"
                    onClick={() => { addToList(selected, dialogQty); setSelected(null); }}
                  >
                    <ListPlus className="h-4 w-4 mr-1.5" /> Add to list
                  </Button>
                  <Button
                    variant="outline"
                    className="flex-1"
                    onClick={() => { addToCart(selected, dialogQty); setSelected(null); }}
                  >
                    <Bookmark className="h-4 w-4 mr-1.5" /> Save for later
                  </Button>
                </div>

                <div className="border-t pt-4">
                  <p className="text-sm font-medium mb-1">Buy now</p>
                  <p className="text-xs text-muted-foreground mb-3">
                    Opens a search for “{selected.name}” on each store — live results and current prices.
                  </p>
                  <div className="grid grid-cols-3 gap-2">
                    {RETAILERS.map((r) => (
                      <a
                        key={r.name}
                        href={r.url(selected.name)}
                        target="_blank"
                        rel="noopener noreferrer"
                        className={`flex items-center justify-center gap-1.5 rounded-md border px-3 py-2.5 text-sm font-medium transition-colors ${r.color}`}
                      >
                        {r.name}
                        <ExternalLink className="h-3.5 w-3.5" />
                      </a>
                    ))}
                  </div>
                </div>
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
