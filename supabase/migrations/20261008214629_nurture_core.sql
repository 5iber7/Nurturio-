create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table public.accounts (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  deleting boolean not null default false
);
create table public.player_profiles (
  id uuid primary key,
  owner_id uuid not null references public.accounts(id) on delete cascade,
  alias text not null default 'Curious Explorer' check (length(alias) between 1 and 40),
  created_at timestamptz not null default now()
);
create index profiles_owner_idx on public.player_profiles(owner_id);
create table public.progress_snapshots (
  profile_id uuid primary key references public.player_profiles(id) on delete cascade,
  revision bigint not null default 0,
  payload jsonb not null check (jsonb_typeof(payload)='object' and octet_length(payload::text)<262144),
  updated_at timestamptz not null default now()
);
create table public.reward_ledger (
  profile_id uuid not null references public.player_profiles(id) on delete cascade,
  quest_id text not null check (quest_id ~ '^(honey|olive|chicken|garden)-[1-8]$'),
  xp integer not null default 30 check (xp=30),
  coins integer not null default 10 check (coins=10),
  created_at timestamptz not null default now(),
  primary key (profile_id,quest_id)
);
create table public.collection_items (
  profile_id uuid not null references public.player_profiles(id) on delete cascade,
  item_id text not null check (item_id in ('flower-path','sunny-sign','garden-bench')),
  cost integer not null check (cost in (30,50,80)),
  primary key (profile_id,item_id)
);
create table public.sync_operations (
  profile_id uuid not null references public.player_profiles(id) on delete cascade,
  operation_id text not null check (length(operation_id) between 1 and 80),
  result jsonb not null,
  created_at timestamptz not null default now(),
  primary key (profile_id,operation_id)
);
create table public.profile_permissions (
  profile_id uuid primary key references public.player_profiles(id) on delete cascade,
  ai_enabled boolean not null default false,
  consent_version text,
  revoked_at timestamptz
);
create table public.consent_records (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  policy_version text not null,
  state text not null check (state in ('pending','verified','revoked')),
  recorded_at timestamptz not null default now()
);
create table public.scan_history (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.player_profiles(id) on delete cascade,
  result jsonb not null check (octet_length(result::text)<32768),
  created_at timestamptz not null default now()
);
create table public.content_versions (
  version text primary key,
  manifest jsonb not null,
  published_at timestamptz not null default now()
);
create table private.ai_usage_buckets (
  account_id uuid not null references public.accounts(id) on delete cascade,
  bucket_date date not null,
  calls integer not null default 0 check (calls between 0 and 50),
  primary key(account_id,bucket_date)
);
create table private.deletion_jobs (
  account_id uuid primary key references public.accounts(id) on delete cascade,
  status text not null default 'pending',
  requested_at timestamptz not null default now()
);

do $$ declare tab text; begin
  foreach tab in array array['accounts','player_profiles','progress_snapshots','reward_ledger','collection_items','sync_operations','profile_permissions','consent_records','scan_history','content_versions'] loop
    execute format('alter table public.%I enable row level security',tab);
    execute format('revoke all on public.%I from anon,authenticated',tab);
  end loop;
end $$;
alter table private.ai_usage_buckets enable row level security;
alter table private.deletion_jobs enable row level security;
grant select on public.accounts,public.player_profiles,public.progress_snapshots,public.reward_ledger,public.collection_items,public.profile_permissions,public.consent_records,public.scan_history to authenticated;
grant select on public.content_versions to anon,authenticated;
create policy account_read on public.accounts for select to authenticated using(id=(select auth.uid()));
create policy profiles_read on public.player_profiles for select to authenticated using(owner_id=(select auth.uid()) and exists(select 1 from public.accounts a where a.id=owner_id and not a.deleting));
create policy progress_read on public.progress_snapshots for select to authenticated using(exists(select 1 from public.player_profiles p where p.id=profile_id and p.owner_id=(select auth.uid())));
create policy rewards_read on public.reward_ledger for select to authenticated using(exists(select 1 from public.player_profiles p where p.id=profile_id and p.owner_id=(select auth.uid())));
create policy collection_read on public.collection_items for select to authenticated using(exists(select 1 from public.player_profiles p where p.id=profile_id and p.owner_id=(select auth.uid())));
create policy permission_read on public.profile_permissions for select to authenticated using(exists(select 1 from public.player_profiles p where p.id=profile_id and p.owner_id=(select auth.uid())));
create policy consent_read on public.consent_records for select to authenticated using(account_id=(select auth.uid()));
create policy scan_read on public.scan_history for select to authenticated using(exists(select 1 from public.player_profiles p where p.id=profile_id and p.owner_id=(select auth.uid())));
create policy published_content on public.content_versions for select to anon,authenticated using(true);

-- A narrowly scoped privileged implementation is required because clients cannot
-- write authoritative ledgers directly. Caller ownership is checked explicitly.
create function private.apply_snapshot(p_profile uuid,p_operation text,p_payload jsonb,p_base_revision bigint)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  actor uuid:=auth.uid(); old_payload jsonb; old_revision bigint; merged jsonb;
  done jsonb; decor jsonb; cards jsonb; reward_count integer; spend integer; q text; step integer; world text;
  existing_result jsonb;
begin
  if actor is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if length(p_operation) not between 1 and 80 or octet_length(p_payload::text)>262144 or p_payload->>'schemaVersion'<>'1' then raise exception 'Invalid snapshot'; end if;
  if exists(select 1 from public.accounts where id=actor and deleting) then raise exception 'Account deletion pending' using errcode='42501'; end if;
  insert into public.accounts(id) values(actor) on conflict do nothing;
  insert into public.player_profiles(id,owner_id) values(p_profile,actor) on conflict do nothing;
  perform 1 from public.player_profiles where id=p_profile and owner_id=actor for update;
  if not found then raise exception 'Profile access denied' using errcode='42501'; end if;
  select result into existing_result from public.sync_operations where profile_id=p_profile and operation_id=p_operation;
  if found then return existing_result; end if;
  select payload,revision into old_payload,old_revision from public.progress_snapshots where profile_id=p_profile;
  old_payload:=coalesce(old_payload,'{"completed":[],"decorations":[],"processes":[],"actions":{},"settings":{}}'::jsonb); old_revision:=coalesce(old_revision,0);
  if jsonb_typeof(p_payload->'completed')<>'array' or jsonb_array_length(p_payload->'completed')>32 then raise exception 'Invalid completions'; end if;
  select coalesce(jsonb_agg(value order by value),'[]'::jsonb) into done from (select distinct value from jsonb_array_elements_text((old_payload->'completed')||(p_payload->'completed'))) d;
  for q in select jsonb_array_elements_text(done) loop
    if q !~ '^(honey|olive|chicken|garden)-[1-8]$' then raise exception 'Unknown quest'; end if;
    world:=split_part(q,'-',1); step:=split_part(q,'-',2)::integer;
    if step>1 and not (done ? (world||'-'||(step-1)::text)) then raise exception 'Missing prerequisite'; end if;
  end loop;
  select coalesce(jsonb_agg(value order by value),'[]'::jsonb) into decor from (select distinct value from jsonb_array_elements_text(coalesce(old_payload->'decorations','[]')||coalesce(p_payload->'decorations','[]'))) d;
  spend:=0;
  for q in select jsonb_array_elements_text(decor) loop
    if q not in ('flower-path','sunny-sign','garden-bench') then raise exception 'Unknown decoration'; end if;
    spend:=spend+case q when 'flower-path' then 30 when 'sunny-sign' then 50 else 80 end;
  end loop;
  reward_count:=jsonb_array_length(done);
  select coalesce(jsonb_agg(value order by value),'[]'::jsonb) into cards from (select distinct value from jsonb_array_elements_text(coalesce(old_payload->'plantCards','[]')||coalesce(p_payload->'plantCards','[]'))) d;
  for q in select jsonb_array_elements_text(cards) loop
    if q not in ('tomato','sunflower','mint','carrot','strawberry','marigold','lettuce','basil') then raise exception 'Unknown plant'; end if;
  end loop;
  if spend>reward_count*10 then raise exception 'Insufficient coins' using errcode='P0001'; end if;
  merged:=jsonb_build_object('schemaVersion',1,'profileId',p_profile,'completed',done,'decorations',decor,'xp',reward_count*30,'coins',reward_count*10-spend,
    'settings',case when p_base_revision=old_revision then coalesce(p_payload->'settings','{}') else coalesce(old_payload->'settings','{}') end,
    'processes',case when p_base_revision=old_revision then coalesce(p_payload->'processes','[]') else coalesce(old_payload->'processes','[]') end,
    'actions',case when p_base_revision=old_revision then coalesce(p_payload->'actions','{}') else coalesce(old_payload->'actions','{}') end,
    'plantCards',cards,'beds',case when p_base_revision=old_revision then coalesce(p_payload->'beds','{}') else coalesce(old_payload->'beds','{}') end);
  insert into public.progress_snapshots(profile_id,revision,payload) values(p_profile,old_revision+1,merged)
    on conflict(profile_id) do update set revision=excluded.revision,payload=excluded.payload,updated_at=now();
  insert into public.reward_ledger(profile_id,quest_id) select p_profile,jsonb_array_elements_text(done) on conflict do nothing;
  insert into public.collection_items(profile_id,item_id,cost) select p_profile,value,case value when 'flower-path' then 30 when 'sunny-sign' then 50 else 80 end from jsonb_array_elements_text(decor) on conflict do nothing;
  existing_result:=jsonb_build_object('revision',old_revision+1,'snapshot',merged,'conflict',p_base_revision<>old_revision);
  insert into public.sync_operations(profile_id,operation_id,result) values(p_profile,p_operation,existing_result);
  return existing_result;
end $$;
revoke all on function private.apply_snapshot(uuid,text,jsonb,bigint) from public,anon;
grant execute on function private.apply_snapshot(uuid,text,jsonb,bigint) to authenticated;
create function public.sync_snapshot(p_profile uuid,p_operation text,p_payload jsonb,p_base_revision bigint default 0)
returns jsonb language sql security invoker set search_path='' as $$ select private.apply_snapshot(p_profile,p_operation,p_payload,p_base_revision); $$;
revoke all on function public.sync_snapshot(uuid,text,jsonb,bigint) from public,anon;
grant execute on function public.sync_snapshot(uuid,text,jsonb,bigint) to authenticated;

create function private.take_ai_quota(p_limit integer default 20) returns boolean
language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); allowed boolean;
begin
  if actor is null or p_limit not between 1 and 50 then return false; end if;
  if not exists(select 1 from public.player_profiles p join public.profile_permissions a on a.profile_id=p.id where p.owner_id=actor and a.ai_enabled and a.revoked_at is null) then return false; end if;
  insert into private.ai_usage_buckets(account_id,bucket_date,calls) values(actor,current_date,1)
  on conflict(account_id,bucket_date) do update set calls=private.ai_usage_buckets.calls+1 where private.ai_usage_buckets.calls<p_limit returning true into allowed;
  return coalesce(allowed,false);
end $$;
revoke all on function private.take_ai_quota(integer) from public,anon;
grant execute on function private.take_ai_quota(integer) to authenticated;
create function public.take_ai_quota(p_limit integer default 20) returns boolean
language sql security invoker set search_path='' as $$ select private.take_ai_quota(p_limit); $$;
revoke all on function public.take_ai_quota(integer) from public,anon;
grant execute on function public.take_ai_quota(integer) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('private-scans','private-scans',false,4194304,array['image/jpeg']) on conflict(id) do nothing;
-- Photo persistence is disabled: no client upload policy. Future opt-in paths must
-- be authorized explicitly. Users may read/delete their own preexisting objects.
create policy own_scan_read on storage.objects for select to authenticated using(bucket_id='private-scans' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy own_scan_delete on storage.objects for delete to authenticated using(bucket_id='private-scans' and (storage.foldername(name))[1]=(select auth.uid())::text);
