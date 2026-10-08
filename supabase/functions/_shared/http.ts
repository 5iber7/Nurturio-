import { createClient } from "@supabase/supabase-js";
export class HttpError extends Error {
  constructor(public status: number, public code: string) {
    super(code);
  }
}
export function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
    },
  });
}
export async function authenticate(req: Request, allowDeleting = false) {
  const bearer = req.headers.get("Authorization");
  if (!bearer?.startsWith("Bearer ")) throw new HttpError(401, "AUTH_REQUIRED");
  const url = Deno.env.get("SUPABASE_URL"),
    key = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
      Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !key) throw new HttpError(503, "BACKEND_UNAVAILABLE");
  const client = createClient(url, key, {
    global: { headers: { Authorization: bearer } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser(bearer.slice(7));
  if (error || !data.user) throw new HttpError(401, "AUTH_REQUIRED");
  const { data: account } = await client.from("accounts").select("deleting").eq(
    "id",
    data.user.id,
  ).maybeSingle();
  if (account?.deleting && !allowDeleting) {
    throw new HttpError(403, "DELETION_PENDING");
  }
  return { client, user: data.user, token: bearer.slice(7) };
}
export async function readBody(req: Request, max = 262144): Promise<unknown> {
  const advertised = Number(req.headers.get("content-length") ?? 0);
  if (advertised > max) throw new HttpError(413, "REQUEST_TOO_LARGE");
  if (!req.body) throw new HttpError(400, "INVALID_REQUEST");
  const reader = req.body.getReader();
  let total = 0;
  const chunks: Uint8Array[] = [];
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > max) {
        await reader.cancel();
        throw new HttpError(413, "REQUEST_TOO_LARGE");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const bytes = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  try {
    return JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    throw new HttpError(400, "INVALID_JSON");
  }
}
export function endpoint(handler: (req: Request) => Promise<Response>) {
  return async (req: Request) => {
    if (req.method === "OPTIONS") return json({}, 200);
    if (req.method !== "POST") {
      return json({ error: "METHOD_NOT_ALLOWED" }, 405);
    }
    try {
      return await handler(req);
    } catch (error) {
      if (error instanceof HttpError) {
        return json({ error: error.code }, error.status);
      }
      return json({ error: "REQUEST_FAILED" }, 400);
    }
  };
}
export function requireCloud() {
  if (Deno.env.get("CLOUD_ACCESS_APPROVED") !== "true") {
    throw new HttpError(503, "CLOUD_DISABLED");
  }
}
export function requireAI() {
  if (
    Deno.env.get("AI_DEPLOYMENT_APPROVED") !== "true" ||
    Deno.env.get("AI_PROVIDER") === "disabled"
  ) throw new HttpError(503, "AI_DISABLED");
}
