# LLM Widget iOS App

> An iOS widget-based application that delivers real-time LLM-powered summaries via quick prompts using OpenAI API.

---

## 📌 Overview (English)

This project is an iOS application with a widget extension that allows users to trigger predefined prompts and receive concise, structured responses powered by a large language model.

The widget provides a fast and intuitive interface where users can interact with LLM-generated content directly from the home screen without opening the app.

---

## 📌 개요 (Korean)

이 프로젝트는 위젯을 통해 미리 설정된 프롬프트를 실행하고,
LLM 기반의 요약된 응답을 빠르게 받아볼 수 있는 iOS 애플리케이션입니다.

사용자는 앱을 실행하지 않고도 홈 화면 위젯에서 바로
AI 기반 요약 정보를 확인할 수 있습니다.

---

## 🚀 Features

* Quick prompt buttons in widget
* Real-time LLM response generation
* OpenAI API integration
* Structured summary output (title + bullet points)
* Shared data between app and widget
* Clean SwiftUI-based UI
* Weather-style dynamic background UI

---

## 🛠 Tech Stack

* SwiftUI
* WidgetKit
* App Intents
* OpenAI API
* Shared App Group storage

---

## 🧠 Architecture

### 1. iOS App

* User input & prompt configuration
* Settings management

### 2. Widget Extension

* Displays quick prompts
* Sends requests directly to API
* Shows summarized responses

### 3. Shared Layer

* OpenAIClient
* QuickPromptStore
* WidgetStore
* SharedSettingsStore

---

## 📂 Project Structure

```text id="w4r84g"
ios-app/
ios-widget/
shared/
```

---

## ⚙️ How It Works

1. User taps a quick prompt button in the widget
2. The prompt is sent to the OpenAI API
3. The response is processed into a short summary
4. The widget displays:

   * Title
   * Up to 3 bullet points

---

## 📸 Demo

### Widget UI

(Add your widget screenshot here)

### App UI

(Add your app screenshot here)

---

## ⚠️ Notes

* API keys are NOT included in this repository
* You must provide your own OpenAI API key
* Ensure App Group is correctly configured for shared data
* Widget updates are triggered via `WidgetCenter.reloadTimelines()`

---

## 📌 Future Work

* Add more prompt customization
* Improve UI/UX animations
* Add streaming responses
* Support more data sources (news, finance, weather APIs)
* Optimize widget refresh performance

---

## 📄 License

MIT License

