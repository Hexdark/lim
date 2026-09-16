-- Run after the migration, on a test project, in SQL Editor as postgres.
-- All test users/rows/extension changes roll back. No real credentials required.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);
insert into auth.users(id) values
  ('a0000000-0000-0000-0000-000000000001'),
  ('a0000000-0000-0000-0000-000000000002'),
  ('a0000000-0000-0000-0000-000000000003');
insert into public.couples(id) values
  ('b0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-000000000002');
insert into public.couple_members(user_id,couple_id,role) values
  ('a0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','writer'),
  ('a0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000001','reader'),
  ('a0000000-0000-0000-0000-000000000003','b0000000-0000-0000-0000-000000000002','writer');
insert into public.check_ins(id,couple_id,author_id,mood,phase) values
  ('c0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001',3,'unknown');
insert into storage.objects(bucket_id,name) values
  ('photos','b0000000-0000-0000-0000-000000000001/a0000000-0000-0000-0000-000000000001/c0000000-0000-0000-0000-000000000001.jpg');

set local role authenticated;
select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000001',true);
select is((select count(*) from public.check_ins),1::bigint,'writer sees own couple');
select is((select count(*) from public.couple_members),1::bigint,'membership is self only');
select lives_ok($$insert into public.check_ins(couple_id,author_id,mood,phase) values
 ('b0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001',5,'unknown')$$,'writer inserts own entry');
select throws_ok($$insert into public.check_ins(couple_id,author_id,mood,phase) values
 ('b0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000001',5,'unknown')$$,
 '42501',null,'cannot insert in another couple');
select throws_ok($$update public.couple_members set role='writer'$$,'42501',null,'cannot change own role');

select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000002',true);
select is((select count(*) from public.check_ins),2::bigint,'reader sees shared entries');
select throws_ok($$insert into public.check_ins(couple_id,author_id,mood,phase) values
 ('b0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002',5,'unknown')$$,
 '42501',null,'reader cannot insert');
delete from public.check_ins;
select is((select count(*) from public.check_ins),2::bigint,'reader cannot delete');
select is((select count(*) from storage.objects where bucket_id='photos'),1::bigint,'reader sees shared photo');

select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000003',true);
select is((select count(*) from public.check_ins),0::bigint,'other couple cannot read entries');
select is((select count(*) from storage.objects where bucket_id='photos'),0::bigint,'other couple cannot read photos');
set local role anon;
select throws_ok($$select * from public.check_ins$$,'42501',null,'anonymous access denied');
reset role;
select * from finish();
rollback;
