import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import type { Tables } from "@/integrations/supabase/types";
import { useAuth } from "@/hooks/useAuth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { Plus, Trash2, Package } from "lucide-react";
import { format, isBefore, addDays } from "date-fns";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Link } from "react-router-dom";

const units = ["g", "kg", "ml", "L", "pcs", "cups", "tbsp", "tsp"];
const locations = ["Fridge", "Freezer", "Pantry", "Counter"];

export default function Ingredients() {
  const { user } = useAuth();
  const { toast } = useToast();
  const [items, setItems] = useState<Tables<"ingredients">[]>([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ name: "", quantity: "", unit: "g", expiration_date: "", location: "Fridge" });

  const load = async () => {
    if (!user) return;
    const { data } = await supabase.from("ingredients").select("*").eq("user_id", user.id).order("expiration_date", { ascending: true });
    setItems(data || []);
  };

  useEffect(() => { load(); }, [user]);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    const { error } = await supabase.from("ingredients").insert({
      user_id: user.id,
      name: form.name,
      quantity: parseFloat(form.quantity),
      unit: form.unit,
      expiration_date: form.expiration_date || null,
      location: form.location,
    });
    if (error) { toast({ title: "Error", description: error.message, variant: "destructive" }); return; }
    toast({ title: "Ingredient added!" });
    setForm({ name: "", quantity: "", unit: "g", expiration_date: "", location: "Fridge" });
    setOpen(false);
    load();
  };

  const handleDelete = async (id: string) => {
    await supabase.from("ingredients").delete().eq("id", id);
    load();
  };

  const isExpiringSoon = (date: string | null) => {
    if (!date) return false;
    return isBefore(new Date(date), addDays(new Date(), 3));
  };

  if (!user) {
    return (
      <div className="container py-20 text-center">
        <h1 className="text-3xl font-bold mb-4">Ingredients</h1>
        <p className="text-muted-foreground mb-6">Please sign in to manage your ingredients.</p>
        <Link to="/auth" className="text-primary font-medium hover:underline">Sign In</Link>
      </div>
    );
  }

  return (
    <div className="container py-8 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Ingredients</h1>
          <p className="text-muted-foreground">Manage your kitchen inventory</p>
        </div>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button><Plus className="h-4 w-4 mr-1" /> Add Ingredient</Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader><DialogTitle>Add Ingredient</DialogTitle></DialogHeader>
            <form onSubmit={handleAdd} className="space-y-4">
              <div className="space-y-2">
                <Label>Name</Label>
                <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required placeholder="e.g. Chicken breast" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-2">
                  <Label>Quantity</Label>
                  <Input type="number" step="0.1" value={form.quantity} onChange={(e) => setForm({ ...form, quantity: e.target.value })} required />
                </div>
                <div className="space-y-2">
                  <Label>Unit</Label>
                  <Select value={form.unit} onValueChange={(v) => setForm({ ...form, unit: v })}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>{units.map((u) => <SelectItem key={u} value={u}>{u}</SelectItem>)}</SelectContent>
                  </Select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-2">
                  <Label>Expiration Date</Label>
                  <Input type="date" value={form.expiration_date} onChange={(e) => setForm({ ...form, expiration_date: e.target.value })} />
                </div>
                <div className="space-y-2">
                  <Label>Location</Label>
                  <Select value={form.location} onValueChange={(v) => setForm({ ...form, location: v })}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>{locations.map((l) => <SelectItem key={l} value={l}>{l}</SelectItem>)}</SelectContent>
                  </Select>
                </div>
              </div>
              <Button type="submit" className="w-full">Add</Button>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      {items.length === 0 ? (
        <Card className="py-16 text-center">
          <Package className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
          <p className="text-muted-foreground">No ingredients yet. Add your first one!</p>
        </Card>
      ) : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {items.map((item) => (
            <Card key={item.id} className={`relative ${isExpiringSoon(item.expiration_date) ? "border-destructive/50 bg-destructive/5" : ""}`}>
              <CardHeader className="pb-2">
                <CardTitle className="text-base flex items-center justify-between">
                  <span>{item.name}</span>
                  <button onClick={() => handleDelete(item.id)} className="text-muted-foreground hover:text-destructive transition-colors">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-1 text-sm text-muted-foreground">
                <p>{item.quantity} {item.unit} • {item.location}</p>
                {item.expiration_date && (
                  <p className={isExpiringSoon(item.expiration_date) ? "text-destructive font-medium" : ""}>
                    Expires: {format(new Date(item.expiration_date), "MMM d, yyyy")}
                  </p>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
