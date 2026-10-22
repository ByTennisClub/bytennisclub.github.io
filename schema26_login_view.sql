-- 26단계: 모임 정보는 로그인한 사람만 보기
-- 모임·참가자·대진·댓글·회원 프로필을 로그인(가입)한 사람만 읽을 수 있게 (공유 링크로 들어와도 로그인 후 보임)
-- 공지·회칙·회비 안내 글은 지금처럼 누구나, 입금 계좌는 지금처럼 승인된 회원만
-- schema25 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
drop policy if exists "meetups read"      on meetups;
drop policy if exists "participants read" on participants;
drop policy if exists "matches read"      on matches;
drop policy if exists "comments read"     on comments;
drop policy if exists "profiles read"     on profiles;
create policy "meetups read"      on meetups      for select to authenticated using (true);
create policy "participants read" on participants for select to authenticated using (true);
create policy "matches read"      on matches      for select to authenticated using (true);
create policy "comments read"     on comments     for select to authenticated using (true);
create policy "profiles read"     on profiles     for select to authenticated using (true);
