-- 33단계: 모임마다 대진표 켬/끔 (주최자·관리 권한자가 모임 상세에서 바꿈)
-- 꺼진 모임은 참가자 화면에서 대진표가 안 보이고, 만들어 둔 대진·점수는 그대로 남음. 기존 모임은 모두 켬
-- 수정 권한은 기존 '모임 수정' 규칙(can_manage)을 그대로 따름
-- schema32 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
alter table meetups add column if not exists bracket boolean not null default true;
