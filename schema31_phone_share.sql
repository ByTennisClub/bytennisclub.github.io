-- 31단계: 회원 간 전화번호 공개 (관리 탭에서 켬/끔, 기본 끔)
-- 켜면 승인된 회원(게스트 제외)끼리 서로 번호를 볼 수 있음. 게스트는 남의 번호를 못 보고, 게스트 번호는 관리자만
-- schema30 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
insert into club_settings (key, value) values ('phone_share', 'off') on conflict (key) do nothing;   -- 회원 간 전화번호 공개 (on/off)
create or replace function phone_shared() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select value = 'on' from club_settings where key = 'phone_share'), false);
$$;
drop policy if exists "private read" on profile_private;
create policy "private read" on profile_private for select using (
  id = auth.uid() or is_admin()
  or (phone_shared() and is_approved() and not is_guest()      -- 공개가 켜져 있으면 승인된 회원끼리
      and exists (select 1 from profiles p where p.id = profile_private.id and not p.is_guest))   -- 게스트 번호는 관리자만
);
