import {
  authenticate,
  endpoint,
  HttpError,
  json,
  readBody,
  requireCloud,
} from "../_shared/http.ts";
import { syncSchema } from "../_shared/contracts.ts";
export const handler = endpoint(async (req) => {
  requireCloud();
  const { client } = await authenticate(req);
  const input = syncSchema.parse(await readBody(req));
  const { data, error } = await client.rpc("sync_snapshot", {
    p_profile: input.profileId,
    p_operation: input.operationId,
    p_payload: input.snapshot,
    p_base_revision: input.baseRevision,
  });
  if (error) {
    throw new HttpError(
      error.code === "42501" ? 403 : 409,
      error.code === "42501" ? "ACCESS_DENIED" : "SYNC_CONFLICT",
    );
  }
  return json(data);
});
if (import.meta.main) Deno.serve(handler);
