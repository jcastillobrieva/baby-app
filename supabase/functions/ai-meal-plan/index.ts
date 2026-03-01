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

    const { babyId, weekStart, preferences } = await req.json();
    if (!babyId) {
      return new Response(
        JSON.stringify({ error: "babyId is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const context = await buildBabyContext(babyId);
    const systemPrompt = formatContextAsSystemPrompt(
      context,
      "nutricionista pediátrico especializado en alimentación complementaria (BLW y tradicional)",
    );

    const userMessage = `Genera un plan de comidas para la próxima semana (empezando ${weekStart || "el próximo lunes"}).

REGLAS:
- Solo usar alimentos del catálogo con status "approved"
- Puedes sugerir 1-2 alimentos nuevos del status "untried" para introducir gradualmente (uno cada 3 días)
- NUNCA incluir alimentos con status "avoid"
- Respetar las preferencias del bebé (los que "loves" incluirlos más, los que "dislikes" evitar o preparar diferente)
- Incluir variedad de categorías: frutas, verduras, proteínas, granos
- Adaptar texturas y cantidades a la edad del bebé
${preferences ? `\nPreferencias adicionales de los padres: ${preferences}` : ""}

FORMATO DE RESPUESTA (JSON):
{
  "plan": [
    {
      "day": 0,
      "dayName": "Domingo",
      "meals": [
        {"mealType": "breakfast", "foodName": "...", "preparation": "...", "amount": "...", "notes": "..."},
        {"mealType": "lunch", "foodName": "...", "preparation": "...", "amount": "...", "notes": "..."},
        {"mealType": "dinner", "foodName": "...", "preparation": "...", "amount": "...", "notes": "..."}
      ]
    }
  ],
  "newFoodsToIntroduce": [
    {"foodName": "...", "suggestedDay": "...", "reason": "..."}
  ],
  "tips": "..."
}`;

    const response = await chatWithClaude(
      systemPrompt,
      [{ role: "user", content: userMessage }],
      "claude-haiku-4-5-20251001",
      4096,
    );

    // Try to parse the JSON from Claude's response
    let parsedPlan;
    try {
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        parsedPlan = JSON.parse(jsonMatch[0]);
      }
    } catch {
      // If parsing fails, return raw content
      parsedPlan = null;
    }

    return new Response(
      JSON.stringify({
        plan: parsedPlan,
        rawContent: response.content,
        usage: response.usage,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("ai-meal-plan error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
