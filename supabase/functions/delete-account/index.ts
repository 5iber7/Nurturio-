import { createClient } from "@supabase/supabase-js";
import {
  authenticate,
  endpoint,
  HttpError,
  json,
  readBody,
  requireCloud,
} from "../_shared/http.ts";
export const handler = endpoint(async (req) => {
  requireCloud();
  const { user, token } = await authenticate(req, true);
  const input = await readBody(req, 1024) as { confirmation?: string };
  if (input.confirmation !== "DELETE") {
    throw new HttpError(400, "CONFIRMATION_REQUIRED");
  }
  const lastSignIn = Date.parse(user.last_sign_in_at ?? "");
  if (
    !Number.isFinite(lastSignIn) || Date.now() - lastSignIn > 15 * 60 * 1000
  ) throw new HttpError(401, "REAUTHENTICATION_REQUIRED");
  const secret = Deno.env.get("SUPABASE_SECRET_KEY") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!secret) throw new HttpError(503, "DELETION_UNAVAILABLE");
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, secret, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { error: mark } = await admin.from("accounts").update({
    deleting: true,
  }).eq("id", user.id);
  if (mark) throw new HttpError(500, "DELETION_PENDING");
  const { data: objects, error: listError } = await admin.storage.from(
    "private-scans",
  ).list(user.id, { limit: 1000 });
  if (listError) throw new HttpError(500, "DELETION_PENDING");
  if (objects?.length) {
    const { error } = await admin.storage.from("private-scans").remove(
      objects.map((o) => `${user.id}/${o.name}`),
    );
    if (error) throw new HttpError(500, "DELETION_PENDING");
  }
  const { error: signOutError } = await admin.auth.admin.signOut(
    token,
    "global",
  );
  if (signOutError) throw new HttpError(500, "DELETION_PENDING");
  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) throw new HttpError(500, "DELETION_PENDING");
  return json({ deleted: true });
});
if (import.meta.main) Deno.serve(handler);
