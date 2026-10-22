-- 29단계: 전화번호 계정 로그인 정보 동기화 함수(sync_guest_credentials)는 서버 안에서만 쓰도록 외부 직접 호출 차단
-- (닉네임·번호를 바꿀 때 트리거가 내부에서 부르는 함수. 외부에서 불러도 권한이 생기진 않지만 열어 둘 이유가 없음)
-- schema28 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
revoke execute on function sync_guest_credentials(uuid) from public, anon, authenticated;
