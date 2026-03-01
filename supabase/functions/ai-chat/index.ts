import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import {
  buildBabyContext,
  formatContextAsSystemPrompt,
} from "../shared/context-builder.ts";
import { chatWithClaude, type ChatMessage } from "../shared/claude-client.ts";

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
    // Authenticate user
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

    const { babyId, conversationId, message } = await req.json();
    if (!babyId || !message) {
      return new Response(
        JSON.stringify({ error: "babyId and message are required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Build baby context
    const context = await buildBabyContext(babyId);
    const systemPrompt = formatContextAsSystemPrompt(
      context,
      "nutricionista pediátrico y asesor de desarrollo infantil",
    );

    // Get conversation history if exists
    let messages: ChatMessage[] = [];
    if (conversationId) {
      const { data: history } = await supabase
        .from("ai_messages")
        .select("role, content")
        .eq("conversation_id", conversationId)
        .order("created_at", { ascending: true });

      if (history) {
        messages = history.map((m) => ({
          role: m.role as "user" | "assistant",
          content: m.content,
        }));
      }
    }

    // Add current message
    messages.push({ role: "user", content: message });

    // Call Claude
    const response = await chatWithClaude(
      systemPrompt,
      messages,
      "claude-haiku-4-5-20251001",
      2048,
    );

    // Create or use conversation
    let convId = conversationId;
    if (!convId) {
      const { data: conv } = await supabase
        .from("ai_conversations")
        .insert({
          baby_id: babyId,
          title: message.substring(0, 100),
          type: "chat",
          created_by: user.id,
        })
        .select("id")
        .single();
      convId = conv?.id;
    }

    // Save messages
    if (convId) {
      await supabase.from("ai_messages").insert([
        { conversation_id: convId, role: "user", content: message },
        {
          conversation_id: convId,
          role: "assistant",
          content: response.content,
        },
      ]);
    }

    return new Response(
      JSON.stringify({
        conversationId: convId,
        message: response.content,
        usage: response.usage,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("ai-chat error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
