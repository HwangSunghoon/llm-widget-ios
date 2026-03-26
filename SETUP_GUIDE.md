# Xcode 설정 가이드

## 1. 프로젝트 생성
- App 템플릿으로 새 프로젝트 생성
- Interface: SwiftUI
- Language: Swift
- 이후 Target에 Widget Extension 추가

## 2. 파일 배치
이 저장소의 파일들을 각 Target에 맞게 추가합니다.

### Host App 공용 추가
- Shared 전체

### iOS App Target
- iOSApp 전체

### macOS App Target
- macOSApp 전체

### Widget Extension Target
- WidgetExtension/LLMWidget.swift
- Shared/Models/WidgetPayload.swift
- Shared/Storage/WidgetStore.swift

## 3. App Group
Signing & Capabilities에서 아래 추가:
- App Groups
- 예시: `group.com.example.llmwidget`

`WidgetStore.swift`의 suiteName도 동일하게 맞춥니다.

## 4. Photos 권한
iOS `Info.plist`에 설명 추가:
- Privacy - Photo Library Usage Description

## 5. 실행 순서
1. 앱 실행
2. OpenAI API Key 저장
3. 텍스트 입력
4. 이미지 선택
5. 위젯 요약 생성
6. 홈 화면/데스크탑에 위젯 추가

## 6. 확장 포인트
- 최근 기록 리스트 추가
- 여러 이미지 입력 지원
- App Intent로 위젯 새로고침 버튼 추가
- 대화 히스토리 저장 추가
