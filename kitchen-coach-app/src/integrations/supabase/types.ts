export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.15"
  }
  public: {
    Tables: {
      cart_items: {
        Row: {
          category: string | null
          created_at: string
          id: string
          name: string
          quantity: number
          store_item_id: string | null
          unit: string
          user_id: string
        }
        Insert: {
          category?: string | null
          created_at?: string
          id?: string
          name: string
          quantity?: number
          store_item_id?: string | null
          unit?: string
          user_id: string
        }
        Update: {
          category?: string | null
          created_at?: string
          id?: string
          name?: string
          quantity?: number
          store_item_id?: string | null
          unit?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "cart_items_store_item_id_fkey"
            columns: ["store_item_id"]
            isOneToOne: false
            referencedRelation: "store_items"
            referencedColumns: ["id"]
          },
        ]
      }
      ingredients: {
        Row: {
          calories_per_unit: number | null
          created_at: string
          expiration_date: string | null
          id: string
          location: string | null
          name: string
          quantity: number
          unit: string
          user_id: string
        }
        Insert: {
          calories_per_unit?: number | null
          created_at?: string
          expiration_date?: string | null
          id?: string
          location?: string | null
          name: string
          quantity?: number
          unit?: string
          user_id: string
        }
        Update: {
          calories_per_unit?: number | null
          created_at?: string
          expiration_date?: string | null
          id?: string
          location?: string | null
          name?: string
          quantity?: number
          unit?: string
          user_id?: string
        }
        Relationships: []
      }
      meal_logs: {
        Row: {
          consumed_date: string
          created_at: string
          id: string
          rating: number | null
          recipe_id: string | null
          user_id: string
        }
        Insert: {
          consumed_date?: string
          created_at?: string
          id?: string
          rating?: number | null
          recipe_id?: string | null
          user_id: string
        }
        Update: {
          consumed_date?: string
          created_at?: string
          id?: string
          rating?: number | null
          recipe_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "meal_logs_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipe_details_view"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_logs_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          dietary_preferences: string | null
          id: string
          name: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          dietary_preferences?: string | null
          id?: string
          name?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          dietary_preferences?: string | null
          id?: string
          name?: string | null
          user_id?: string
        }
        Relationships: []
      }
      recipe_ingredients: {
        Row: {
          id: string
          ingredient_name: string
          quantity: string | null
          recipe_id: string
        }
        Insert: {
          id?: string
          ingredient_name: string
          quantity?: string | null
          recipe_id: string
        }
        Update: {
          id?: string
          ingredient_name?: string
          quantity?: string | null
          recipe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recipe_ingredients_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipe_details_view"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recipe_ingredients_recipe_id_fkey"
            columns: ["recipe_id"]
            isOneToOne: false
            referencedRelation: "recipes"
            referencedColumns: ["id"]
          },
        ]
      }
      recipes: {
        Row: {
          created_at: string
          difficulty_level: string | null
          id: string
          instructions: string | null
          name: string
          prep_time: number | null
        }
        Insert: {
          created_at?: string
          difficulty_level?: string | null
          id?: string
          instructions?: string | null
          name: string
          prep_time?: number | null
        }
        Update: {
          created_at?: string
          difficulty_level?: string | null
          id?: string
          instructions?: string | null
          name?: string
          prep_time?: number | null
        }
        Relationships: []
      }
      shopping_list_items: {
        Row: {
          category: string | null
          checked: boolean
          created_at: string
          id: string
          name: string
          quantity: number
          store_item_id: string | null
          unit: string
          user_id: string
        }
        Insert: {
          category?: string | null
          checked?: boolean
          created_at?: string
          id?: string
          name: string
          quantity?: number
          store_item_id?: string | null
          unit?: string
          user_id: string
        }
        Update: {
          category?: string | null
          checked?: boolean
          created_at?: string
          id?: string
          name?: string
          quantity?: number
          store_item_id?: string | null
          unit?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "shopping_list_items_store_item_id_fkey"
            columns: ["store_item_id"]
            isOneToOne: false
            referencedRelation: "store_items"
            referencedColumns: ["id"]
          },
        ]
      }
      store_items: {
        Row: {
          calories_per_unit: number | null
          category: string
          created_at: string
          default_quantity: number
          default_unit: string
          emoji: string | null
          id: string
          name: string
        }
        Insert: {
          calories_per_unit?: number | null
          category: string
          created_at?: string
          default_quantity?: number
          default_unit?: string
          emoji?: string | null
          id?: string
          name: string
        }
        Update: {
          calories_per_unit?: number | null
          category?: string
          created_at?: string
          default_quantity?: number
          default_unit?: string
          emoji?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
    }
    Views: {
      expiring_ingredients_view: {
        Row: {
          expiration_date: string | null
          id: string | null
          location: string | null
          name: string | null
          quantity: number | null
          unit: string | null
          user_id: string | null
        }
        Insert: {
          expiration_date?: string | null
          id?: string | null
          location?: string | null
          name?: string | null
          quantity?: number | null
          unit?: string | null
          user_id?: string | null
        }
        Update: {
          expiration_date?: string | null
          id?: string | null
          location?: string | null
          name?: string | null
          quantity?: number | null
          unit?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      recipe_details_view: {
        Row: {
          difficulty_level: string | null
          id: string | null
          ingredient_count: number | null
          ingredients_summary: string | null
          instructions: string | null
          name: string | null
          prep_time: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      add_missing_to_shopping_list: {
        Args: { p_recipe_id: string; p_user_id: string }
        Returns: number
      }
      add_to_cart: {
        Args: {
          p_category?: string
          p_name: string
          p_quantity?: number
          p_store_item_id?: string
          p_unit?: string
          p_user_id: string
        }
        Returns: {
          category: string | null
          created_at: string
          id: string
          name: string
          quantity: number
          store_item_id: string | null
          unit: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "cart_items"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      add_to_shopping_list: {
        Args: {
          p_category?: string
          p_name: string
          p_quantity?: number
          p_store_item_id?: string
          p_unit?: string
          p_user_id: string
        }
        Returns: {
          category: string | null
          checked: boolean
          created_at: string
          id: string
          name: string
          quantity: number
          store_item_id: string | null
          unit: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "shopping_list_items"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      available_recipes: {
        Args: { p_user_id: string }
        Returns: {
          created_at: string
          difficulty_level: string | null
          id: string
          instructions: string | null
          name: string
          prep_time: number | null
        }[]
        SetofOptions: {
          from: "*"
          to: "recipes"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      move_cart_item_to_list: {
        Args: { p_cart_item_id: string }
        Returns: {
          category: string | null
          checked: boolean
          created_at: string
          id: string
          name: string
          quantity: number
          store_item_id: string | null
          unit: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "shopping_list_items"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      recipe_match_summary: {
        Args: { p_user_id: string }
        Returns: {
          difficulty_level: string
          have_count: number
          id: string
          instructions: string
          match_pct: number
          missing_count: number
          missing_ingredients: string[]
          name: string
          prep_time: number
          total_ingredients: number
        }[]
      }
      suggested_store_items: {
        Args: { p_user_id: string }
        Returns: {
          calories_per_unit: number | null
          category: string
          created_at: string
          default_quantity: number
          default_unit: string
          emoji: string | null
          id: string
          name: string
        }[]
        SetofOptions: {
          from: "*"
          to: "store_items"
          isOneToOne: false
          isSetofReturn: true
        }
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
