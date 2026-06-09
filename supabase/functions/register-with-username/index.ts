import { createClient } from "jsr:@supabase/supabase-js@2";

type RegisterPayload = {
  username?: string;
  password?: string;
  companyName?: string;
  ceoName?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function normalizeUsername(username: string): string {
  return username
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function buildSyntheticAuthEmail(username: string): string {
  return `${normalizeUsername(username)}@skyward.sachiel.id`;
}

function resolveServiceRoleKey(): string | null {
  const explicitServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (explicitServiceRoleKey) {
    return explicitServiceRoleKey;
  }

  const bundledSecretKeys = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (!bundledSecretKeys) {
    return null;
  }

  try {
    const parsed = JSON.parse(bundledSecretKeys) as Record<string, string>;
    const firstSecretKey = Object.values(parsed).find((value) => !!value);
    return firstSecretKey ?? null;
  } catch {
    return null;
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse(405, {
      success: false,
      message: "Method not allowed.",
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = resolveServiceRoleKey();

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(500, {
      success: false,
      message: "Supabase server credentials are not configured for this function.",
    });
  }

  let payload: RegisterPayload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse(400, {
      success: false,
      message: "Invalid JSON payload.",
    });
  }

  const username = normalizeUsername(payload.username ?? "");
  const password = payload.password?.trim() ?? "";
  const companyName = payload.companyName?.trim() ?? "";
  const ceoName = payload.ceoName?.trim() ?? "";

  if (!username || username.length < 4) {
    return jsonResponse(400, {
      success: false,
      message: "Username must be at least 4 characters.",
    });
  }

  if (!password || password.length < 6) {
    return jsonResponse(400, {
      success: false,
      message: "Password must be at least 6 characters.",
    });
  }

  if (!companyName) {
    return jsonResponse(400, {
      success: false,
      message: "Company name is required.",
    });
  }

  if (!ceoName) {
    return jsonResponse(400, {
      success: false,
      message: "CEO name is required.",
    });
  }

  const authEmail = buildSyntheticAuthEmail(username);
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const { data, error } = await supabase.auth.admin.createUser({
    email: authEmail,
    password,
    email_confirm: true,
    user_metadata: {
      username,
      company_name: companyName,
      ceo_name: ceoName,
    },
  });

  if (error) {
    const status = /already|registered|exists/i.test(error.message) ? 409 : 400;
    return jsonResponse(status, {
      success: false,
      message: error.message,
    });
  }

  return jsonResponse(200, {
    success: true,
    auth_user_id: data.user?.id ?? null,
    username,
    auth_email: authEmail,
  });
});
