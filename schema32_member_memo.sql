-- 32단계: 회원 메모 (내 정보에서 본인이 쓰고, 회원 카드에 큰따옴표로 보임). 100자까지
-- 남의 메모는 바꿀 수 없음 (대표만 정리용으로 가능) → 프로필 보호 트리거에 memo 추가
-- schema31 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
alter table profiles add column if not exists memo text;
alter table profiles drop constraint if exists profiles_memo_len;
alter table profiles add constraint profiles_memo_len check (memo is null or char_length(memo) <= 100);

create or replace function protect_role() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if current_setting('app.claim_admin', true) = 'on' then return new; end if;   -- 관리자 코드 인증 등 서버 함수
  if new.role is distinct from old.role and not is_owner() then
    raise exception '대표만 역할을 바꿀 수 있습니다';
  end if;
  if (new.status is distinct from old.status or new.is_guest is distinct from old.is_guest) and not is_admin() then
    raise exception '관리자만 바꿀 수 있습니다';
  end if;
  if new.status is distinct from old.status and old.role in ('admin', 'owner') and not is_owner() then
    raise exception '관리자의 상태는 대표만 바꿀 수 있습니다';
  end if;
  if old.id <> auth.uid() and not is_owner() and (
       new.name is distinct from old.name or new.experience is distinct from old.experience
    or new.gender is distinct from old.gender or new.birth_year is distinct from old.birth_year
    or new.avatar_url is distinct from old.avatar_url or new.show_crown is distinct from old.show_crown
    or new.memo is distinct from old.memo) then
    raise exception '다른 회원의 프로필은 바꿀 수 없습니다';
  end if;
  return new;
end $$;
