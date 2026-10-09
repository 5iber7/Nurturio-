import { z } from "zod";
import {
  authenticate,
  endpoint,
  HttpError,
  json,
  readBody,
  requireAI,
} from "../_shared/http.ts";
import { provider } from "../_shared/ai.ts";
import { safeScan } from "../_shared/contracts.ts";
import { jpegSize } from "../_shared/jpeg.ts";
import jpeg from "jpeg-js";
const inputSchema = z.object({
  profileId: z.uuid(),
  reading: z.enum(["Simple", "Explorer"]),
  image: z.string().max(5600000),
}).strict();
export const handler = endpoint(async (req) => {
  requireAI();
  const { client, user } = await authenticate(req);
  const input = inputSchema.parse(await readBody(req, 5700000));
  const { data: p } = await client.from("player_profiles").select("id").eq(
    "id",
    input.profileId,
  ).eq("owner_id", user.id).maybeSingle();
  const { data: a } = await client.from("profile_permissions").select(
    "ai_enabled,revoked_at",
  ).eq("profile_id", input.profileId).maybeSingle();
  if (!p || !a?.ai_enabled || a.revoked_at) {
    throw new HttpError(403, "AI_NOT_ELIGIBLE");
  }
  const bytes = Uint8Array.from(atob(input.image), (c) => c.charCodeAt(0));
  if (bytes.length > 4194304) throw new HttpError(413, "IMAGE_TOO_LARGE");
  const size = jpegSize(bytes);
  if (!size || size.width > 1536 || size.height > 1536) {
    throw new HttpError(400, "INVALID_IMAGE");
  }
  let cleanImage: string;
  try {
    const decoded = jpeg.decode(bytes, {
      maxResolutionInMP: 2.4,
      maxMemoryUsageInMB: 64,
      useTArray: true,
    });
    const clean = jpeg.encode(decoded, 80).data;
    cleanImage = btoa(
      Array.from(clean, (c) => String.fromCharCode(c)).join(""),
    );
  } catch {
    throw new HttpError(400, "INVALID_IMAGE");
  }
  const { data: allowed, error } = await client.rpc("take_ai_quota", {
    p_limit: 20,
  });
  if (error || !allowed) throw new HttpError(429, "AI_RATE_LIMIT");
  return json(safeScan(await provider().identify(cleanImage, input.reading)));
});
if (import.meta.main) Deno.serve(handler);
