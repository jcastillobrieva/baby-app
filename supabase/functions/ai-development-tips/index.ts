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

    const { babyId, category } = await req.json();
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
      "terapeuta de desarrollo infantil y estimulación temprana",
    );

    const categoryFilter = category
      ? `Enfócate en la categoría: ${category}`
      : "Cubre todas las áreas del desarrollo";

    const userMessage = `Genera recomendaciones de ejercicios y actividades de estimulación para el bebé según su edad y desarrollo actual.

${categoryFilter}

Incluye:
1. **Ejercicios recomendados**: 5-7 actividades específicas para su edad
2. **Próximos hitos**: Qué hitos debería estar trabajando según su edad
3. **Señales de alerta**: Qué vigilar (sin alarmar)
4. **Juguetes recomendados**: 3-5 juguetes apropiados para su edad
5. **Rutina de estimulación**: Rutina diaria sugerida de 15-20 minutos

Para cada ejercicio incluye:
- Nombre descriptivo
- Cómo hacerlo (paso a paso simple)
- Beneficio para el desarrollo
- Duración sugerida
- Frecuencia

Formato: Texto organizado con secciones claras.`;

    const response = await chatWithClaude(
      systemPrompt,
      [{ role: "user", content: userMessage }],
      "claude-haiku-4-5-20251001",
      4096,
    );

    return new Response(
      JSON.stringify({
        tips: response.content,
        usage: response.usage,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("ai-development-tips error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
