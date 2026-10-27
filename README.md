# 🍯 Honeyyyb — Smart Personal Finance, Relationship Budgeting & P2P Ledger

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Kotlin](https://img.shields.io/badge/Kotlin-Android_Native-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white)](https://kotlinlang.org)
[![UI Style](https://img.shields.io/badge/UI_Style-Neo--Brutalism-FFE600?style=for-the-badge&logoColor=black)](#-neo-brutalist-design-system)
[![License](https://img.shields.io/badge/License-MIT-2ECC71?style=for-the-badge)](LICENSE)
[![Build & Test](https://img.shields.io/badge/Tests-Passing-brightgreen?style=for-the-badge)](#-test-suite--quality-assurance)

> **Honeyyyb** is a next-generation, offline-first personal finance application combining automated payment tracking, peer-to-peer debt ledgers, relationship/couple milestone budgeting, and **Honey AI** — an interactive, bilingual (Tamil & English) voice-enabled companion.

---

## 👨‍💻 Creator & Author

- **Author**: **Surya Prakash T**
- **Education**: **B.Tech Artificial Intelligence and Machine Learning (AI & ML)**
- **Contact**: `suryaprakashdeveloperai@gmail.com`
- **Role**: System Architect & Mobile Developer

---

## 🌟 Key Features

### ⚡ 1. Real-Time Payment Auto-Detection
- Native Android `NotificationListenerService` (`HoneyNotificationListenerService.kt`) detects push notifications in real time.
- Filters transactions from major UPI and banking apps: **Google Pay**, **PhonePe**, **Paytm**, **CRED**, **BHIM**, **HDFC**, **ICICI**, **SBI**, **Axis**, **Kotak**, and **Truecaller Pay**.
- Extracts paid/received amounts, beneficiary/payer names, and automatically logs transactions without requiring user intervention.

### 💬 2. Honey AI & Sweet Voice Companion
- **Bilingual Personality**: Warm, empathetic companion speaking in **Tamil & English** (e.g., *"Vanakkam sweetheart! En kooda casually pesalaam illa budget pathi check pannalaam!"*).
- **Free-Floating Draggable Bubble**: Snapchat My AI-inspired draggable avatar on the edge of the screen, accessible across all views.
- **Natural Voice Synthesis**: Native Android `TextToSpeech` engine with caring, sweet female pitch audio alerts upon transaction detection.
- **Financial Health Scoring**: Calculates an automated monthly financial health rating (0–100 score), identifies spending leaks, and computes safe daily spend limits.

### 👥 3. People Tracker & P2P Ledger
- Automatically groups and calculates net balances across contacts (`netBalance = totalReceived - totalSent`).
- **Clear Debt Status**: High-contrast badges visually distinguish who owes money from who is owed.
- **1-Tap Settlement**: Instantly record balanced settlements.
- **WhatsApp Reminder Integration**: One-click generation of formatted WhatsApp settlement reminders.

### 📨 4. 4-Month Automated SMS Banking Scanner
- Deep regex engine parses Indian bank alerts, UPI transactions, card debits, and salary credits.
- Scans inbox starting from 4 months prior with intelligent timestamp deduplication.
- Supports **Truecaller Smart SMS** tags and various merchant name extraction heuristics.

### 📄 5. PDF & Statement Importer
- Powered by `syncfusion_flutter_pdf` to extract and parse monthly Google Pay, PhonePe, and bank statements directly from PDF files.
- Includes password-protected PDF support and fallback manual statement paste tokenization.

### 📊 6. Neo-Brutalist Analytics & Milestone Goals
- Interactive visual expense graphs powered by `fl_chart`.
- Dedicated **Romance & Couple Budgeting** category to track date nights, gifts, and special celebrations.
- Savings goals with progress visualization (e.g., Anniversary Dinner, Vacation Fund).

### 🔒 7. 100% Privacy & Local-First Architecture
- All parsing (SMS, notifications, PDFs) executes **entirely on-device**.
- Zero cloud trackers or external analytics dependencies.
- Full offline persistence via `shared_preferences` with JSON backup and restore capabilities.

---

## 🎨 Neo-Brutalist Design System

Honeyyyb implements a bold, high-contrast **Neo-Brutalism** aesthetic:
- **Primary Color Palette**:
  - 🟡 Honey Yellow (`#FFE600`) — Primary Brand
  - 🔴 Spider Red (`#FF3366`) — Alerts & Debit Highlights
  - 🔵 Neon Teal (`#00F0FF`) — Accents & Analytics
  - 🟣 Electric Purple (`#A855F7`) — People Tracker & P2P
  - 🟢 Mint Green (`#2ECC71`) — Income & Positive Balance
  - 🍦 Cream Background (`#FFFBEB`) — Soft Contrast Foundation
- **Visual Tokens**:
  - `3.0px` solid black borders (`#000000`).
  - Hard `Offset(4, 4)` flat drop-shadows with zero blur radius.
  - Tactile 3D pressable buttons with animated elevation feedback.
- **Typography**:
  - **Headings & Digits**: *Space Grotesk* (Bold & Black weights).
  - **Body & Captions**: *Plus Jakarta Sans* (Medium & Semi-bold weights).

---

## 🏗️ Architecture & Technology Stack

```mermaid
graph TD
    UI[Flutter Neo-Brutalist UI] --> Provider[FinanceProvider - ChangeNotifier]
    Provider --> Storage[SharedPreferences - JSON Persistence]
    Provider --> Parsers[Parsing Engine]
    
    subgraph "Native Android Bridge (Kotlin)"
        MainActivity[MainActivity.kt]
        NotifService[HoneyNotificationListenerService.kt]
        TTS[Android TextToSpeech Engine]
        SMS[Android SMS ContentResolver]
        PDFPicker[Native Storage File Picker]
    end

    Parsers --> SMSParser[SmsParserService]
    Parsers --> NotifParser[NotificationParserService]
    Parsers --> PDFParser[PdfStatementParserService - Syncfusion]
    
    NotifService -->|EventChannel| Provider
    SMS -->|MethodChannel| SMSParser
    TTS <--|MethodChannel| VoiceService[VoiceAssistantService]
    PDFPicker -->|MethodChannel| PDFParser
```

### Module Overview

| Directory | Description |
| :--- | :--- |
| `lib/models/` | Data classes: `TransactionModel`, `BudgetModel`, `GoalModel`, `PersonLedger`. |
| `lib/providers/` | `FinanceProvider`: central reactive store for financial state, filters, and persistence. |
| `lib/screens/` | 12 full-featured screens (Dashboard, People, Analytics, History, Settings, Importers, etc.). |
| `lib/services/` | Parsing engines (SMS, PDF, Notifications), AI Advisor, Voice Assistant, and PDF/CSV exporter. |
| `lib/theme/` | Neo-Brutalism theme tokens (`NeoColors`, `NeoTheme`). |
| `lib/widgets/` | Custom UI components: tactile buttons, cards, badges, banners, logos, and draggable AI avatar. |
| `android/` | Native Kotlin implementation for Notification Listener, SMS Querying, and TextToSpeech. |

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.12.0` (Recommended: Flutter 3.24+ / 3.44+)
- **Dart SDK**: `^3.12.2`
- **Android Studio** with Android SDK API 34+
- **Java Development Kit**: JDK 17 or JDK 21

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/<your-username>/honeyyyb.git
   cd honeyyyb
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup**:
   ```bash
   flutter doctor
   ```

4. **Run on an Android device or emulator**:
   ```bash
   flutter run
   ```

---

## 📱 Android Permissions Setup

Honeyyyb requires the following permissions for automated tracking:

| Permission | Purpose |
| :--- | :--- |
| `READ_SMS` | Scans bank transaction SMS and imports up to 4 months of financial history. |
| `BIND_NOTIFICATION_LISTENER_SERVICE` | Enables real-time listening of UPI and banking payment notifications. |
| `READ_EXTERNAL_STORAGE` | Allows selecting and parsing PDF bank statements. |

> **Note**: To enable real-time notification detection on Android, navigate to:
> **Settings ➔ Notification Access ➔ Toggle ON Honeyyyb**.

---

## 🧪 Test Suite & Quality Assurance

Honeyyyb contains comprehensive unit and widget tests covering all major engines:
- `sms_parser_test.dart`: Validates UPI debits, credits, Truecaller Smart SMS, and salary slips.
- `pdf_parser_test.dart`: Validates PDF tokenization and multi-line parsing.
- `complete_features_test.dart`: Comprehensive verification of statement generation, CSV exports, and ledger arithmetic.
- `snapchat_ai_test.dart`: Tests for draggable Honey AI avatar, chat thread, and quick-action chips.
- `voice_and_notification_test.dart`: Tests for live notification ingestion and voice synthesis formatting.

Run all tests:
```bash
flutter test
```

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

## 💖 Acknowledgements & Dedication

Designed and built with passion by **Surya Prakash T** (**B.Tech AI & ML**). Dedicated to crafting delightful, intelligent, and private software that simplifies everyday finance.
