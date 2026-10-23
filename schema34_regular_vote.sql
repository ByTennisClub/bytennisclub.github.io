-- 34단계: 정기 모임 참가/불참 투표 + 출석 정리
--  · 회원 이상은 정기 모임에 [참가] [불참] 중 하나로 투표 (모임 날짜까지 바꿀 수 있음)
--  · 참가 기록(participants)에 '불참'(absent) 상태를 하나 더 둠. 기존 기록은 그대로 참가
--  · 모임 당일부터는 주최자·관리자가 실제 온 사람에 맞춰 참가 ↔ 불참을 고칠 수 있음 (출석 통계용)
-- schema33 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

alter table participants drop constraint if exists participants_status_check;
alter table participants add constraint participants_status_check check (status in ('approved','pending','absent'));

-- 본인 투표: attend=true 참가(신청 후 승인 모임이면 대기), false 불참. 결과 상태를 돌려줌
create or replace function vote_meetup(mid uuid, attend boolean) returns text
language plpgsql security definer set search_path = public as $$
declare m meetups; me profiles; cur participants; st text; n int;
begin
  select * into me from profiles where id = auth.uid();
  if me.id is null or me.is_guest or not is_approved() then raise exception 'permission denied'; end if;
  select * into m from meetups where id = mid;
  if m.id is null then raise exception 'no meetup' using errcode = '23503'; end if;
  if m.kind <> 'regular' then raise exception 'regular only'; end if;
  if m.date < (now() at time zone 'Asia/Seoul')::date then raise exception 'past meetup'; end if;
  select * into cur from participants where meetup_id = mid and user_id = me.id;
  if attend then
    if cur.status in ('approved', 'pending') then return cur.status; end if;
    st := case when m.created_by_id = me.id or m.join_mode <> 'approve' then 'approved' else 'pending' end;
    if st = 'approved' and m.capacity is not null then
      select count(*) into n from participants where meetup_id = mid and status = 'approved';
      if n >= m.capacity then raise exception 'full'; end if;
    end if;
  else
    if cur.status = 'absent' then return 'absent'; end if;
    st := 'absent';
  end if;
  if cur.id is null then
    insert into participants (meetup_id, user_id, name) values (mid, me.id, me.name) returning * into cur;
  end if;
  update participants set status = st, created_at = now() where id = cur.id;   -- 바꾼 순서대로 명단에 보이게
  return st;
end $$;

-- 출석 정리: 모임 당일·지난 정기 모임에서 관리 권한자가 회원의 참가 ↔ 불참을 바꿈 (투표 안 한 사람도 넣을 수 있음)
create or replace function mark_attendance(mid uuid, target uuid, attend boolean) returns void
language plpgsql security definer set search_path = public as $$
declare m meetups; nm text;
begin
  if not can_manage(mid) then raise exception 'permission denied'; end if;
  select * into m from meetups where id = mid;
  if m.kind <> 'regular' then raise exception 'regular only'; end if;
  if m.date > (now() at time zone 'Asia/Seoul')::date then raise exception 'not yet'; end if;
  select name into nm from profiles where id = target;
  if nm is null then raise exception 'no member' using errcode = '23503'; end if;
  insert into participants (meetup_id, user_id, name) values (mid, target, nm)
    on conflict (meetup_id, user_id) do nothing;
  update participants set status = case when attend then 'approved' else 'absent' end
   where meetup_id = mid and user_id = target;
end $$;

revoke execute on function vote_meetup(uuid, boolean) from public, anon;
grant  execute on function vote_meetup(uuid, boolean) to authenticated;
revoke execute on function mark_attendance(uuid, uuid, boolean) from public, anon;
grant  execute on function mark_attendance(uuid, uuid, boolean) to authenticated;
