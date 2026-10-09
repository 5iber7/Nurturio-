insert into public.content_versions(version,manifest)
values('1.0.0','{"topics":["honey","olive","chicken","garden"],"quests":32,"plants":8}')
on conflict(version) do nothing;
