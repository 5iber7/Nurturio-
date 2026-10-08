import { endpoint,authenticate,json,requireCloud,HttpError } from '../_shared/http.ts';
export const handler=endpoint(async(req)=>{requireCloud();const {client,user}=await authenticate(req);
  const {data:profiles,error}=await client.from('player_profiles').select('id,alias,created_at').eq('owner_id',user.id);if(error)throw new HttpError(500,'EXPORT_FAILED');
  const ids=profiles?.map(p=>p.id)??[];
  const {data:progress,error:progressError}=await client.from('progress_snapshots').select('*').in('profile_id',ids);if(progressError)throw new HttpError(500,'EXPORT_FAILED');
  return json({exportVersion:1,exportedAt:new Date().toISOString(),profiles,progress});
});
if(import.meta.main)Deno.serve(handler);
