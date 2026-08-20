import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { ChefHat, Leaf, ShoppingCart, BarChart3, Utensils, Clock } from "lucide-react";
import { motion } from "framer-motion";

const features = [
  { icon: Leaf, title: "Smart Inventory", desc: "Track ingredients with expiry alerts to reduce waste." },
  { icon: Utensils, title: "Recipe Matching", desc: "Get recipes based on what's already in your kitchen." },
  { icon: BarChart3, title: "Meal Tracking", desc: "Log meals and monitor nutrition habits over time." },
  { icon: ShoppingCart, title: "Shopping Lists", desc: "Auto-generate lists from recipes or low-stock items." },
  { icon: Clock, title: "Expiry Alerts", desc: "Never throw away food — get warned before it expires." },
  { icon: ChefHat, title: "AI Suggestions", desc: "Personalized recipe ideas powered by AI." },
];

export default function Index() {
  return (
    <div className="flex flex-col">
      {/* Hero */}
      <section className="relative overflow-hidden py-24 md:py-36">
        <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-accent/5" />
        <div className="container relative text-center max-w-3xl mx-auto space-y-6">
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6 }}>
            <span className="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-4 py-1.5 text-sm font-medium text-primary mb-4">
              <Leaf className="h-4 w-4" /> Eat smarter, waste less
            </span>
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight text-foreground leading-tight">
              Your Personal <span className="text-primary">Kitchen Coach</span> & Meal Planner
            </h1>
            <p className="mt-4 text-lg text-muted-foreground max-w-xl mx-auto">
              Manage ingredients, discover recipes, track meals, and reduce food waste — all in one beautiful app.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-3">
              <Link to="/auth">
                <Button size="lg" className="text-base px-8">Get Started Free</Button>
              </Link>
              <Link to="/dashboard">
                <Button size="lg" variant="outline" className="text-base px-8">View Dashboard</Button>
              </Link>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 bg-muted/40">
        <div className="container max-w-5xl">
          <h2 className="text-3xl font-bold text-center mb-12">Everything You Need</h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((f, i) => (
              <motion.div
                key={f.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="bg-card rounded-xl p-6 border hover:shadow-lg transition-shadow"
              >
                <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center mb-4">
                  <f.icon className="h-5 w-5 text-primary" />
                </div>
                <h3 className="font-semibold text-lg mb-1 font-sans">{f.title}</h3>
                <p className="text-sm text-muted-foreground">{f.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20">
        <div className="container text-center max-w-2xl">
          <h2 className="text-3xl font-bold mb-4">Start Your Healthy Journey</h2>
          <p className="text-muted-foreground mb-8">Join thousands managing their kitchen smarter.</p>
          <Link to="/auth">
            <Button size="lg" className="px-10 text-base">Create Free Account</Button>
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t py-8">
        <div className="container text-center text-sm text-muted-foreground">
          © {new Date().getFullYear()} Kitchen Coach App. Built with ❤️
        </div>
      </footer>
    </div>
  );
}
