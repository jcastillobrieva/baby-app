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

    const { babyId } = await req.json();
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
    // Use Sonnet for more analytical summaries
    const systemPrompt = formatContextAsSystemPrompt(
      context,
      "pediatra y analista de datos de desarrollo infantil",
    );

    const userMessage = `Genera un resumen semanal completo del bebé basándote en todos los datos disponibles.

Incluye:
1. **Sueño**: Patrón de sueño, horas totales promedio, calidad, despertares nocturnos, tendencias
2. **Alimentación**: Resumen de lo que comió, nuevos alimentos introducidos, reacciones, variedad nutricional
3. **Pañales**: Frecuencia, patrones, cualquier anomalía
4. **Desarrollo**: Hitos recientes, observaciones sobre el desarrollo para su edad
5. **Crecimiento**: Tendencia si hay datos recientes
6. **Recomendaciones**: 3-5 acciones concretas para la próxima semana
7. **Alerta**: Cualquier cosa que se deba consultar con el pediatra

Formato: Texto con secciones claras, fácil de leer rápido. Usa bullet points.`;

    const response = await chatWithClaude(
      systemPrompt,
      [{ role: "user", content: userMessage }],
      "claude-sonnet-4-6-20250514",
      4096,
    );

    // Save as AI conversation
    const { data: conv } = await supabase
      .from("ai_conversations")
      .insert({
        baby_id: babyId,
        title: `Resumen semanal - ${new Date().toLocaleDateString("es")}`,
        type: "summary",
        created_by: user.id,
      })
      .select("id")
      .single();

    if (conv) {
      await supabase.from("ai_messages").insert({
        conversation_id: conv.id,
        role: "assistant",
        content: response.content,
      });
    }

    return new Response(
      JSON.stringify({
        summary: response.content,
        conversationId: conv?.id,
        usage: response.usage,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("ai-weekly-summary error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
