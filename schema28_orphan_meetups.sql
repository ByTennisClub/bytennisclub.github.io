-- 28단계: 주최자가 삭제된 모임은 관리자가 넘겨받아 관리
-- 회원을 삭제하면 그 사람이 만든 모임의 주최자(created_by_id)가 비게 됨 → 관리자·대표가 수정·참가 승인·대진·점수를 할 수 있게
-- (모임 수정·참가 승인·대진·댓글 관리 규칙은 모두 can_manage() 를 쓰므로 이 함수만 바꾸면 됨)
-- schema27 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
create or replace function can_manage(mid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from meetups where id = mid
      and (created_by_id = auth.uid() or ((kind = 'regular' or created_by_id is null) and is_admin()))
  );
$$;
