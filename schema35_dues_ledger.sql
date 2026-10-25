-- 35단계: 회원 가입일 + 월별 회비 정산 (관리자가 표시·수정)
--  · profiles.joined_at: 클럽 가입일. 처음엔 앱 가입한 날로 채우고, 관리자가 회원 카드에서 고칠 수 있음 (본인은 못 바꿈)
--  · dues_payments: 회원별·월별 회비 상태. 줄이 없으면 미납, 'paid' 납부, 'exempt' 면제
--    관리자만 표시·수정, 회원은 자기 기록만 볼 수 있음
-- schema34 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

alter table profiles add column if not exists joined_at date;
update profiles set joined_at = (created_at at time zone 'Asia/Seoul')::date where joined_at is null;
alter table profiles alter column joined_at set default ((now() at time zone 'Asia/Seoul')::date);

create table if not exists dues_payments (
  user_id uuid not null references profiles(id) on delete cascade,
  month text not null check (month ~ '^\d{4}-\d{2}$'),      -- 'YYYY-MM'
  status text not null check (status in ('paid', 'exempt')),
  updated_by text,                                          -- 표시한 관리자 이름
  updated_at timestamptz not null default now(),
  primary key (user_id, month)
);
alter table dues_payments enable row level security;
drop policy if exists "dues read"  on dues_payments;
drop policy if exists "dues write" on dues_payments;
create policy "dues read"  on dues_payments for select to authenticated using (is_admin() or user_id = auth.uid());
create policy "dues write" on dues_payments for all    to authenticated using (is_admin()) with check (is_admin());

-- 프로필 보호에 가입일 추가: 관리자만 바꿈
create or replace function protect_role() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if current_setting('app.claim_admin', true) = 'on' then return new; end if;   -- 관리자 코드 인증 등 서버 함수
  if new.role is distinct from old.role and not is_owner() then
    raise exception '대표만 역할을 바꿀 수 있습니다';
  end if;
  if (new.status is distinct from old.status or new.is_guest is distinct from old.is_guest
      or new.joined_at is distinct from old.joined_at) and not is_admin() then
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
