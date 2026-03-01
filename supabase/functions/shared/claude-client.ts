import Anthropic from "npm:@anthropic-ai/sdk@0.39.0";

const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
if (!anthropicApiKey) {
  throw new Error("ANTHROPIC_API_KEY environment variable is required");
}

const client = new Anthropic({ apiKey: anthropicApiKey });

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

export interface ClaudeResponse {
  content: string;
  usage: {
    input_tokens: number;
    output_tokens: number;
  };
}

export async function chatWithClaude(
  systemPrompt: string,
  messages: ChatMessage[],
  model: string = "claude-haiku-4-5-20251001",
  maxTokens: number = 2048,
): Promise<ClaudeResponse> {
  const response = await client.messages.create({
    model,
    max_tokens: maxTokens,
    system: systemPrompt,
    messages,
  });

  const textBlock = response.content.find((block) => block.type === "text");
  if (!textBlock || textBlock.type !== "text") {
    throw new Error("No text content in Claude response");
  }

  return {
    content: textBlock.text,
    usage: {
      input_tokens: response.usage.input_tokens,
      output_tokens: response.usage.output_tokens,
    },
  };
}

export { client };
