-- 27단계: 회칙은 로그인한 사람만, 회비(안내 글·입금 계좌)는 승인된 회원 이상(게스트 제외)만 읽기
-- 이름 표시 방식 같은 다른 설정은 지금처럼 누구나 (화면 표시에 필요)
-- schema26 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
drop policy if exists "settings read" on club_settings;
create policy "settings read" on club_settings for select using (
  case
    when key = 'rules' then auth.uid() is not null
    when key in ('dues', 'dues_account', 'dues_has_acct') then is_approved() and not is_guest()
    else true
  end
);
