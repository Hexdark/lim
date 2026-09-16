-- Apply once using the SQL Editor in your own Supabase project.
begin;

create table public.couples (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);
create table public.couple_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  couple_id uuid not null references public.couples(id) on delete cascade,
  role text not null check (role in ('writer', 'reader')),
  unique (couple_id, role)
);
create table public.check_ins (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  author_id uuid not null references auth.users(id),
  mood smallint not null check (mood between 1 and 5),
  phase text not null check (phase in ('unknown', 'menstruation', 'follicular', 'ovulation', 'luteal')),
  note text not null default '' check (char_length(note) <= 1500),
  photo_path text,
  created_at timestamptz not null default now(),
  check (photo_path is null or photo_path = couple_id::text || '/' || author_id::text || '/' || id::text || '.jpg')
);
create index check_ins_couple_date on public.check_ins(couple_id, created_at desc);

alter table public.couples enable row level security;
alter table public.couple_members enable row level security;
alter table public.check_ins enable row level security;

-- No client may create a couple, change a role or invite another account.
revoke all on public.couples, public.couple_members, public.check_ins from anon, authenticated;
grant select on public.couple_members to authenticated;
grant select, insert, delete on public.check_ins to authenticated;

create policy "Read own membership" on public.couple_members for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Read own couple entries" on public.check_ins for select to authenticated
  using (exists (
    select 1 from public.couple_members m
    where m.user_id = (select auth.uid()) and m.couple_id = check_ins.couple_id
  ));
create policy "Writer inserts own entries" on public.check_ins for insert to authenticated
  with check (author_id = (select auth.uid()) and exists (
    select 1 from public.couple_members m
    where m.user_id = (select auth.uid()) and m.couple_id = check_ins.couple_id and m.role = 'writer'
  ));
create policy "Writer deletes own entries" on public.check_ins for delete to authenticated
  using (author_id = (select auth.uid()) and exists (
    select 1 from public.couple_members m
    where m.user_id = (select auth.uid()) and m.couple_id = check_ins.couple_id and m.role = 'writer'
  ));

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 2097152, array['image/jpeg']);

create policy "Read photos of own couple" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and exists (
    select 1 from public.couple_members m
    where m.user_id = (select auth.uid()) and m.couple_id::text = (storage.foldername(name))[1]
  ));
create policy "Writer uploads own photos" on storage.objects for insert to authenticated
  with check (
    bucket_id = 'photos'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and exists (
      select 1 from public.couple_members m
      where m.user_id = (select auth.uid()) and m.role = 'writer'
      and m.couple_id::text = (storage.foldername(name))[1]
    )
  );
create policy "Writer deletes own photos" on storage.objects for delete to authenticated
  using (
    bucket_id = 'photos'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and exists (
      select 1 from public.couple_members m
      where m.user_id = (select auth.uid()) and m.role = 'writer'
      and m.couple_id::text = (storage.foldername(name))[1]
    )
  );

alter publication supabase_realtime add table public.check_ins;
commit;
