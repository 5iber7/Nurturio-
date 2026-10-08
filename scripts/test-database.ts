import { PGlite } from '@electric-sql/pglite';
const db=new PGlite();
function assert(value:unknown,message:string){if(!value)throw new Error(message);}
await db.exec(`
create role anon;create role authenticated;
create schema auth;create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid; $$;
grant usage on schema auth to authenticated,anon;grant execute on function auth.uid() to authenticated,anon;
create schema storage;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid,name text,bucket_id text);
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language sql as $$ select string_to_array(name,'/'); $$;
grant usage on schema storage to authenticated;grant select,delete on storage.objects to authenticated;
insert into auth.users values('11111111-1111-4111-8111-111111111111'),('22222222-2222-4222-8222-222222222222');
`);
const migrationFiles=[];for await(const e of Deno.readDir('supabase/migrations')){if(e.name.endsWith('.sql'))migrationFiles.push(e.name);}
for(const file of migrationFiles.sort())await db.exec(await Deno.readTextFile('supabase/migrations/'+file));
await db.exec(await Deno.readTextFile('supabase/seed.sql'));
const actorA='11111111-1111-4111-8111-111111111111',actorB='22222222-2222-4222-8222-222222222222',profile='33333333-3333-4333-8333-333333333333';
await db.exec(`set role authenticated;select set_config('request.jwt.claim.sub','${actorA}',false);`);
const payload={schemaVersion:1,completed:['honey-1'],decorations:[],processes:[],actions:{},settings:{reading:'Simple'}};
async function sync(operation:string,body:unknown,revision=0){return (await db.query<{result:{revision:number;snapshot:{coins:number;completed:string[]};conflict:boolean}}>('select public.sync_snapshot($1,$2,$3::jsonb,$4) as result',[profile,operation,JSON.stringify(body),revision])).rows[0].result;}
const first=await sync('first',payload);assert(first.snapshot.coins===10,'Initial reward');
const replay=await sync('first',payload);assert(replay.revision===first.revision,'Idempotency');
const merged=await sync('second',{...payload,completed:['honey-1','honey-2']},0);assert(merged.conflict&&merged.snapshot.coins===20,'Conflict merges completions');
let denied=false;try{await sync('bad',{...payload,completed:['honey-4']});}catch{denied=true;}assert(denied,'Skipped prerequisites rejected');
denied=false;try{await sync('overspend',{...payload,decorations:['garden-bench']});}catch{denied=true;}assert(denied,'Overspend rejected');
denied=false;try{await db.exec(`update public.reward_ledger set coins=999;`);}catch{denied=true;}assert(denied,'Direct ledger mutation blocked');
await db.exec(`select set_config('request.jwt.claim.sub','${actorB}',false);`);
const visible=await db.query('select * from public.progress_snapshots');assert(visible.rows.length===0,'Cross-account read blocked');
denied=false;try{await sync('stolen',payload);}catch{denied=true;}assert(denied,'Cross-account sync blocked');
await db.exec(`select set_config('request.jwt.claim.sub','${actorA}',false);`);
const rewards=await db.query('select * from public.reward_ledger');assert(rewards.rows.length===2,'Exactly-once ledger entries');
const quota=await db.query<{allowed:boolean}>('select public.take_ai_quota(20) as allowed');assert(quota.rows[0].allowed===false,'AI permission defaults deny');
await db.exec(`reset role;update public.accounts set deleting=true where id='${actorA}';set role authenticated;select set_config('request.jwt.claim.sub','${actorA}',false);`);
denied=false;try{await sync('deleted',payload);}catch{denied=true;}assert(denied,'Deleting account cannot sync');
await db.close();console.log('PostgreSQL migration, RLS isolation, idempotency, prerequisites, currency and deletion tests passed (PGlite; Supabase Auth/Storage services stubbed).');
