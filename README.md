
title: Kissanai
emoji: 🌾
colorFrom: indigo
colorTo: red
sdk: docker
pinned: false
---

# 🌾 KissanAI – High-Level System Design

**Built by:** Ramsha Noshad & Urooj Sadik  

---

## 🚀 Overview

KissanAI is a **mobile-first agricultural marketplace** that connects farmers with machinery operators using an **AI-powered orchestration system**.

### Features:
- 📱 Voice + Text booking
- 🤖 AI matching, pricing & scheduling
- 📍 Live GPS tracking
- 🔐 Firebase authentication
- ☁️ FastAPI backend (Hugging Face Spaces)

---

## 🏗️ System Architecture

```mermaid
flowchart LR
    Farmer[👨‍🌾 Farmer] --> App[📱 Flutter App]
    App --> API[☁️ FastAPI Backend]
    API --> AI[🤖 AI Orchestrator]
    AI --> Gemini[🧠 Google Gemini API]
    AI --> DB[(🗄️ SQLite Database)]
    API --> Track[📍 Live Tracking]
    Track --> Operator[🚜 Operator]
````

---

## 🧠 AI Agent Distribution

| AI Agent           | Role               | Workload |
| ------------------ | ------------------ | -------- |
| 🗣️ ZabaanAI       | Voice Processing   | 20%      |
| 🤝 SmartMatch AI   | Operator Matching  | 20%      |
| 💰 FairPrice AI    | Pricing Engine     | 15%      |
| 📅 ScheduleMind AI | Scheduling         | 15%      |
| ⚙️ AgriComplex AI  | Risk Analysis      | 15%      |
| ⚖️ ResolveAI       | Dispute Resolution | 15%      |

---

## 🔄 Booking Flow

```mermaid
flowchart TD
    A[User Input Voice/Text] --> B[ZabaanAI]
    B --> C[AgriComplex AI]
    C --> D[SmartMatch AI]
    D --> E[FairPrice AI]
    E --> F[ScheduleMind AI]
    F --> G[Booking Confirmed]
    G --> H[Live Tracking Activated]
```

---

## 📊 API Usage Overview

| Module         | Usage |
| -------------- | ----- |
| Authentication | 25%   |
| Booking System | 45%   |
| Tracking       | 20%   |
| Disputes       | 10%   |

---

## 🔌 External Integrations

| Service             | Purpose                  |
| ------------------- | ------------------------ |
| Google Gemini API   | AI reasoning engine      |
| Firebase Auth       | Phone OTP authentication |
| OpenStreetMap       | Live maps                |
| Hugging Face Spaces | Backend hosting          |

---

## 🏗️ Tech Stack

```mermaid
flowchart TD
    A[Frontend] --> B[Flutter]
    A --> C[Provider]
    A --> D[Dio]

    E[Backend] --> F[FastAPI]
    E --> G[SQLite]
    E --> H[WebSockets]

    I[AI Layer] --> J[Google Gemini]
    I --> K[Antigravity Orchestrator]

    L[Auth] --> M[Firebase OTP]
```

---

## 🧠 Summary

KissanAI is an **AI-driven agricultural ecosystem** where:

* Farmers book machinery using voice/text
* AI handles matching, pricing, scheduling
* GPS tracking ensures transparency
* Firebase secures authentication
* FastAPI + Gemini power intelligence layer

---

## 👩‍💻 Authors

* Ramsha Noshad
* Urooj Sadik
