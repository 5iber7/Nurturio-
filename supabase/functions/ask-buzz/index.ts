import { z } from 'zod';
import { endpoint,authenticate,json,readBody,requireAI,HttpError } from '../_shared/http.ts';
import { provider } from '../_shared/ai.ts';
import { buzzSchema } from '../_shared/contracts.ts';
import { approvedContext } from '../_shared/approved_context.ts';
const inputSchema=z.object({profileId:z.uuid(),topic:z.enum(['honey','olive','chicken','garden']),reading:z.enum(['Simple','Explorer']),question:z.string().min(1).max(500)}).strict();
export const handler=endpoint(async(req)=>{
  requireAI();const {client,user}=await authenticate(req);const input=inputSchema.parse(await readBody(req,4096));
  const {data:p}=await client.from('player_profiles').select('id').eq('id',input.profileId).eq('owner_id',user.id).maybeSingle();
  const {data:a}=await client.from('profile_permissions').select('ai_enabled,revoked_at').eq('profile_id',input.profileId).maybeSingle();
  if(!p||!a?.ai_enabled||a.revoked_at)throw new HttpError(403,'AI_NOT_ELIGIBLE');
  const {data:allowed,error}=await client.rpc('take_ai_quota',{p_limit:20});if(error||!allowed)throw new HttpError(429,'AI_RATE_LIMIT');
  const context=approvedContext[input.topic];const result=buzzSchema.parse(await provider().ask(input.question,JSON.stringify(context),input.reading));
  const allowedIds=new Set<string>(context.map(q=>q.id)),allowedSources=new Set<string>(context.flatMap(q=>q.sourceIds));
  if(result.relatedQuestIds.some(id=>!allowedIds.has(id))||result.sourceIds.some(id=>!allowedSources.has(id)))throw new HttpError(502,'AI_INVALID_OUTPUT');
  return json(result);
});
if(import.meta.main)Deno.serve(handler);
