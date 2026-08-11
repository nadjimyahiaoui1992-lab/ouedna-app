import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const corsHeaders = {
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

const maxQuestionLength = 500;
const maxRequestsPerWindow = 12;
const windowSeconds = 600;

type GuidePayload = {
  question?: unknown;
  place_name?: unknown;
};

type GuideAnswer = {
  answer: string;
  suggestions: string[];
  disclaimer: string;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json({ error: "unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const openAiKey = Deno.env.get("OPENAI_API_KEY");
  const openAiModel = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";
  if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey || !openAiKey) {
    return json({ error: "server_configuration_error" }, 503);
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return json({ error: "unauthorized" }, 401);
  }

  let payload: GuidePayload;
  try {
    payload = await request.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const question = typeof payload.question === "string" ? payload.question.trim() : "";
  const placeName = typeof payload.place_name === "string" ? payload.place_name.trim() : "";
  if (!question || question.length > maxQuestionLength) {
    return json({ error: "invalid_question" }, 400);
  }
  if (containsSensitivePersonalData(question)) {
    return json({
      error: "sensitive_data_rejected",
      message: "Ne partagez pas d’adresse, de téléphone, de document d’identité ou d’autres données personnelles avec le guide.",
    }, 400);
  }

  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: permitted, error: rateLimitError } = await serviceClient.rpc(
    "consume_tour_guide_request",
    {
      p_user_id: userData.user.id,
      p_window_seconds: windowSeconds,
      p_max_requests: maxRequestsPerWindow,
    },
  );
  if (rateLimitError || permitted !== true) {
    return json({ error: "rate_limited", retry_after_seconds: windowSeconds }, 429);
  }

  const { data: places, error: placesError } = await serviceClient
    .from("places")
    .select("name,main_category,description,address,opening_hours")
    .eq("status", "منشور")
    .order("rating", { ascending: false })
    .limit(12);
  if (placesError) {
    return json({ error: "context_unavailable" }, 503);
  }

  const context = JSON.stringify(places ?? []);
  const result = await askModel({ question, placeName, context, openAiKey, openAiModel });
  return json(result, 200);
});

async function askModel({
  question,
  placeName,
  context,
  openAiKey,
  openAiModel,
}: {
  question: string;
  placeName: string;
  context: string;
  openAiKey: string;
  openAiModel: string;
}): Promise<GuideAnswer> {
  const systemPrompt = [
    "Tu es Souf Tour Guide, un assistant culturel et touristique pour El Oued, Algérie.",
    "Réponds en français clair, chaleureux et factuel. Tu peux intégrer de courtes expressions arabes seulement si cela aide la compréhension.",
    "Tu dois t’appuyer exclusivement sur le contexte de lieux publiés fourni ci-dessous. N’invente ni horaires, ni prix, ni transport, ni disponibilité.",
    "Si une information manque, indique-le explicitement et invite l’utilisateur à vérifier auprès de l’établissement ou des autorités locales.",
    "Ne fournis pas de conseils médicaux, juridiques, financiers ou de sécurité d’urgence. En cas d’urgence, demande d’appeler les services locaux compétents.",
    "Ne demande ni ne répète de données personnelles. Limite les suggestions à trois actions pratiques.",
    "Retourne uniquement un JSON valide avec les clés answer, suggestions et disclaimer.",
    `Contexte de lieux publiés: ${context}`,
  ].join("\n");

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openAiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: openAiModel,
      temperature: 0.3,
      max_tokens: 500,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: systemPrompt },
        {
          role: "user",
          content: JSON.stringify({ question, place_name: placeName || undefined }),
        },
      ],
    }),
  });
  if (!response.ok) {
    return fallbackAnswer();
  }

  try {
    const body = await response.json();
    const content = body?.choices?.[0]?.message?.content;
    const parsed = typeof content === "string" ? JSON.parse(content) : null;
    if (!parsed || typeof parsed.answer !== "string") return fallbackAnswer();
    return {
      answer: parsed.answer.slice(0, 1800),
      suggestions: Array.isArray(parsed.suggestions)
        ? parsed.suggestions.map(String).map((value) => value.slice(0, 180)).slice(0, 3)
        : [],
      disclaimer: typeof parsed.disclaimer === "string"
        ? parsed.disclaimer.slice(0, 400)
        : "Les informations peuvent évoluer ; vérifiez les conditions de visite avant votre départ.",
    };
  } catch {
    return fallbackAnswer();
  }
}

function fallbackAnswer(): GuideAnswer {
  return {
    answer: "Le guide ne peut pas générer une réponse détaillée actuellement. Vous pouvez consulter les lieux publiés dans l’application et vérifier les informations pratiques auprès des contacts locaux.",
    suggestions: ["Consultez la fiche du lieu.", "Vérifiez les horaires avant de partir."],
    disclaimer: "Les informations peuvent évoluer ; vérifiez les conditions de visite avant votre départ.",
  };
}

function containsSensitivePersonalData(value: string): boolean {
  const email = /\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b/;
  const phone = /(?:\+?\d[\s.-]?){8,}\d/;
  const identityDocument = /\b(?:passport|passeport|carte\s*d['’]?identité|id\s*number)\b/i;
  return email.test(value) || phone.test(value) || identityDocument.test(value);
}

function json(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}
