-- First create two confirmed users in Authentication > Users.
-- Replace both UUIDs below with those users' IDs. Run once in SQL Editor.
-- These are placeholder IDs, not credentials.
do $$
declare
  writer_id uuid := '00000000-0000-0000-0000-000000000001';
  reader_id uuid := '00000000-0000-0000-0000-000000000002';
  new_couple_id uuid;
begin
  if writer_id = reader_id then raise exception 'Choose two different users'; end if;
  insert into public.couples default values returning id into new_couple_id;
  insert into public.couple_members(user_id, couple_id, role)
  values (writer_id, new_couple_id, 'writer'), (reader_id, new_couple_id, 'reader');
end $$;
