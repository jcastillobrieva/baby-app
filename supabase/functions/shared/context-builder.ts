import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

export function getServiceClient(): SupabaseClient {
  return createClient(supabaseUrl, supabaseServiceKey);
}

export interface BabyContext {
  profile: string;
  recentSleep: string;
  recentFeeding: string;
  recentDiapers: string;
  foodCatalog: string;
  milestones: string;
  growthRecords: string;
}

export async function buildBabyContext(
  babyId: string,
): Promise<BabyContext> {
  const supabase = getServiceClient();
  const sevenDaysAgo = new Date(
    Date.now() - 7 * 24 * 60 * 60 * 1000,
  ).toISOString();

  // Fetch all data in parallel
  const [
    babyResult,
    sleepResult,
    feedingResult,
    solidFoodResult,
    diaperResult,
    foodCatalogResult,
    milestonesResult,
    growthResult,
  ] = await Promise.all([
    supabase.from("babies").select("*").eq("id", babyId).single(),
    supabase
      .from("sleep_sessions")
      .select("*, sleep_wakings(*)")
      .eq("baby_id", babyId)
      .gte("start_time", sevenDaysAgo)
      .order("start_time", { ascending: false }),
    supabase
      .from("feeding_logs")
      .select("*")
      .eq("baby_id", babyId)
      .gte("start_time", sevenDaysAgo)
      .order("start_time", { ascending: false }),
    supabase
      .from("solid_food_logs")
      .select("*")
      .eq("baby_id", babyId)
      .gte("eaten_at", sevenDaysAgo)
      .order("eaten_at", { ascending: false }),
    supabase
      .from("diaper_logs")
      .select("*")
      .eq("baby_id", babyId)
      .gte("changed_at", sevenDaysAgo)
      .order("changed_at", { ascending: false }),
    supabase
      .from("food_catalog")
      .select("*")
      .eq("baby_id", babyId)
      .order("food_name"),
    supabase
      .from("baby_milestones")
      .select("*, milestone_definitions(*)")
      .eq("baby_id", babyId)
      .order("created_at", { ascending: false }),
    supabase
      .from("growth_records")
      .select("*")
      .eq("baby_id", babyId)
      .order("measured_at", { ascending: false })
      .limit(5),
  ]);

  const baby = babyResult.data;
  if (!baby) throw new Error("Baby not found");

  // Calculate age
  const dob = new Date(baby.date_of_birth);
  const now = new Date();
  const ageMonths =
    (now.getFullYear() - dob.getFullYear()) * 12 +
    (now.getMonth() - dob.getMonth());
  const ageDays = Math.floor(
    (now.getTime() - dob.getTime()) / (1000 * 60 * 60 * 24),
  );

  // Build profile string
  const profile = [
    `Nombre: ${baby.first_name} ${baby.last_name || ""}`.trim(),
    `Fecha de nacimiento: ${baby.date_of_birth}`,
    `Edad: ${ageMonths} meses (${ageDays} días)`,
    `Sexo: ${baby.sex === "male" ? "Masculino" : "Femenino"}`,
    baby.birth_weight_kg
      ? `Peso al nacer: ${baby.birth_weight_kg} kg`
      : null,
    baby.birth_height_cm
      ? `Talla al nacer: ${baby.birth_height_cm} cm`
      : null,
  ]
    .filter(Boolean)
    .join("\n");

  // Build sleep summary
  const sleepSessions = sleepResult.data || [];
  const recentSleep = sleepSessions.length > 0
    ? sleepSessions
        .slice(0, 10)
        .map((s) => {
          const duration = s.end_time
            ? `${((new Date(s.end_time).getTime() - new Date(s.start_time).getTime()) / 3600000).toFixed(1)}h`
            : "en curso";
          const wakings = s.sleep_wakings?.length || 0;
          return `- ${s.type}: ${new Date(s.start_time).toLocaleDateString()} ${duration}, ${wakings} despertares`;
        })
        .join("\n")
    : "Sin registros de sueño recientes";

  // Build feeding summary
  const feedingLogs = feedingResult.data || [];
  const solidFoodLogs = solidFoodResult.data || [];
  const recentFeeding = [
    ...feedingLogs.slice(0, 10).map((f) => {
      if (f.type === "breast") {
        return `- Pecho (${f.breast_side}): ${f.duration_minutes}min - ${new Date(f.start_time).toLocaleDateString()}`;
      }
      if (f.type === "bottle") {
        return `- Biberón: ${f.amount_oz}oz - ${new Date(f.start_time).toLocaleDateString()}`;
      }
      return `- Sólidos - ${new Date(f.start_time).toLocaleDateString()}`;
    }),
    ...solidFoodLogs.slice(0, 10).map((s) => {
      return `- Sólido: ${s.food_name} (${s.preparation || "N/A"}) - Reacción: ${s.reaction} - ${new Date(s.eaten_at).toLocaleDateString()}`;
    }),
  ].join("\n") || "Sin registros de alimentación recientes";

  // Build diaper summary
  const diaperLogs = diaperResult.data || [];
  const recentDiapers = diaperLogs.length > 0
    ? `Últimos 7 días: ${diaperLogs.length} cambios (${diaperLogs.filter((d) => d.type === "wet").length} mojados, ${diaperLogs.filter((d) => d.type === "dirty").length} sucios, ${diaperLogs.filter((d) => d.type === "both").length} ambos)`
    : "Sin registros de pañales recientes";

  // Build food catalog
  const foods = foodCatalogResult.data || [];
  const foodCatalog = foods.length > 0
    ? [
        `Aprobados: ${foods.filter((f) => f.status === "approved").map((f) => `${f.food_name}${f.preference ? ` (${f.preference})` : ""}`).join(", ") || "ninguno"}`,
        `No probados: ${foods.filter((f) => f.status === "untried").map((f) => f.food_name).join(", ") || "ninguno"}`,
        `Vigilancia alergia: ${foods.filter((f) => f.status === "watch").map((f) => f.food_name).join(", ") || "ninguno"}`,
        `Evitar: ${foods.filter((f) => f.status === "avoid").map((f) => f.food_name).join(", ") || "ninguno"}`,
      ].join("\n")
    : "Catálogo de alimentos vacío";

  // Build milestones
  const babyMilestones = milestonesResult.data || [];
  const achieved = babyMilestones.filter((m) => m.achieved_at);
  const pending = babyMilestones.filter((m) => !m.achieved_at);
  const milestones = [
    `Logrados (${achieved.length}): ${achieved.slice(0, 10).map((m) => m.milestone_definitions?.title).join(", ") || "ninguno"}`,
    `Pendientes próximos: ${pending.slice(0, 5).map((m) => m.milestone_definitions?.title).join(", ") || "ninguno"}`,
  ].join("\n");

  // Build growth records
  const records = growthResult.data || [];
  const growthRecords = records.length > 0
    ? records
        .map(
          (r) =>
            `- ${r.measured_at}: Peso ${r.weight_kg || "?"}kg (P${r.weight_percentile || "?"}), Talla ${r.height_cm || "?"}cm (P${r.height_percentile || "?"}), PC ${r.head_circumference_cm || "?"}cm (P${r.head_percentile || "?"})`,
        )
        .join("\n")
    : "Sin registros de crecimiento";

  return {
    profile,
    recentSleep,
    recentFeeding,
    recentDiapers,
    foodCatalog,
    milestones,
    growthRecords,
  };
}

export function formatContextAsSystemPrompt(
  context: BabyContext,
  role: string,
): string {
  return `Eres un ${role} experto. Respondes en español.

DATOS DEL BEBÉ:
${context.profile}

SUEÑO (últimos 7 días):
${context.recentSleep}

ALIMENTACIÓN (últimos 7 días):
${context.recentFeeding}

PAÑALES (últimos 7 días):
${context.recentDiapers}

CATÁLOGO DE ALIMENTOS:
${context.foodCatalog}

HITOS DEL DESARROLLO:
${context.milestones}

CRECIMIENTO:
${context.growthRecords}

INSTRUCCIONES IMPORTANTES:
- Basa tus respuestas en los datos reales del bebé proporcionados arriba.
- Si no tienes suficiente información, pídela.
- Siempre recomienda consultar al pediatra para decisiones médicas.
- Usa un tono cálido y empático, estos son padres primerizos.
- Responde de forma concisa y práctica.`;
}
