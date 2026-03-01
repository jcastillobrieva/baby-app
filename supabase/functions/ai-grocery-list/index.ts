import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import {
  buildBabyContext,
  formatContextAsSystemPrompt,
} from "../shared/context-builder.ts";
import { chatWithClaude } from "../shared/claude-client.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const authHeader = req.headers.get("Authorization")!;
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { babyId, mealPlanId } = await req.json();
    if (!babyId || !mealPlanId) {
      return new Response(
        JSON.stringify({ error: "babyId and mealPlanId are required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Get meal plan items
    const { data: mealPlanItems } = await supabase
      .from("meal_plan_items")
      .select("*")
      .eq("meal_plan_id", mealPlanId)
      .order("day_of_week", { ascending: true });

    if (!mealPlanItems || mealPlanItems.length === 0) {
      return new Response(
        JSON.stringify({ error: "No meal plan items found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const context = await buildBabyContext(babyId);
    const systemPrompt = formatContextAsSystemPrompt(
      context,
      "nutricionista pediátrico que ayuda con la lista de compras",
    );

    const foodList = mealPlanItems.map((item) => item.food_name).join(", ");
    const userMessage = `Basándote en el plan de comidas semanal que incluye estos alimentos: ${foodList}

Genera una lista de mercado organizada por categoría. Incluye cantidades aproximadas para un bebé para toda la semana.

FORMATO DE RESPUESTA (JSON):
{
  "categories": [
    {
      "name": "Frutas",
      "items": [
        {"name": "Banano", "quantity": "4 unidades", "notes": "maduros"}
      ]
    }
  ],
  "tips": "Consejo para almacenamiento o preparación"
}`;

    const response = await chatWithClaude(
      systemPrompt,
      [{ role: "user", content: userMessage }],
      "claude-haiku-4-5-20251001",
      2048,
    );

    let parsedList;
    try {
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        parsedList = JSON.parse(jsonMatch[0]);
      }
    } catch {
      parsedList = null;
    }

    // Save grocery list to meal plan
    if (parsedList) {
      await supabase
        .from("meal_plans")
        .update({ grocery_list: parsedList })
        .eq("id", mealPlanId);
    }

    return new Response(
      JSON.stringify({
        groceryList: parsedList,
        rawContent: response.content,
        usage: response.usage,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("ai-grocery-list error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
