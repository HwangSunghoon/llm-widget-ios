# LLMWidgetMVP

개인용 Mac/iPhone LLM 위젯 MVP 구조입니다.

## 목표
- 앱에서 텍스트 + 이미지 입력
- OpenAI Responses API 호출
- 위젯용 1~3줄 요약 저장
- WidgetKit 위젯에 마지막 결과 표시

## 주의
- 이 코드는 **MVP 골격**입니다.
- 실제 Xcode 프로젝트(.xcodeproj), Signing, Entitlements, App Group 설정은 직접 추가해야 합니다.
- 개인용 가정으로 `API Key`는 Keychain에 저장하는 구조입니다.
- 배포용이라면 앱에서 직접 OpenAI API를 호출하는 구조는 권장되지 않습니다.

## 추천 Target 구성
1. iOS App
2. macOS App
3. Widget Extension (iOS)
4. Widget Extension (macOS)

## App Group 예시
`group.com.example.llmwidget`

## 필요한 설정
- Host app과 Widget extension 모두 같은 App Group 사용
- Keychain Sharing 필요 시 활성화
- Photos access 권한 추가
- macOS에서 파일 접근 권한 설정

## 흐름
1. 앱에서 텍스트 입력
2. 이미지 선택
3. OpenAI API 호출
4. 결과를 `WidgetPayload`로 변환
5. App Group 저장
6. `WidgetCenter.shared.reloadAllTimelines()` 호출
7. 위젯이 최신 요약 표시
