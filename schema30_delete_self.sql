-- 30단계: 회원 탈퇴 (내 정보 → 회원 탈퇴). 본인 계정만, 대표는 대표를 넘긴 뒤에만
-- schema29 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
create or replace function delete_self() returns void
language plpgsql security definer set search_path = public as $$
declare r text;
begin
  if auth.uid() is null then raise exception '로그인이 필요합니다'; end if;
  select role into r from profiles where id = auth.uid();
  if r = 'owner' then raise exception '대표는 먼저 다른 관리자에게 대표를 넘긴 뒤 탈퇴할 수 있습니다'; end if;
  delete from auth.users where id = auth.uid();   -- 프로필·참가 기록은 함께 지워지고, 댓글은 작성자 없이, 만든 모임은 관리자가 넘겨받음
end $$;
revoke execute on function delete_self() from public, anon;
grant  execute on function delete_self() to authenticated;
