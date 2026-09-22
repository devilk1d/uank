# UANK

A cross-platform personal finance and expense tracking application built with Flutter, Riverpod, and Supabase. Features multi-currency tracking (IDR, MYR, USD), on-device OCR receipt scanning, recurring bills management, savings goals, and responsive layouts across Mobile (Android/iOS) and Desktop (Windows/macOS/Web).

---

## Features

### Multi-Currency & Real-Time Exchange Rates
- Support for IDR, MYR, USD, and global currencies with live mid-market conversion calculations.
- Cross-currency transfers with custom and automated exchange rate resolution.

### Smart OCR Receipt Scanner
- On-device text recognition using Google ML Kit.
- Automatic extraction of transaction totals and dates from receipt photos.
- Configurable OCR toggle in settings and onboarding flow.

### Financial Management & Analytics
- Multi-account and digital wallet tracking (banks, e-wallets, cash).
- Income and expense categorization with custom user categories.
- Monthly recurring bills tracker with overdue alerts and payment status indicators.
- Savings goals with visual progress bars and linked funding accounts.
- Visual breakdown charts (cash flow trends, category donut breakdown, spline charts).

### Data Tools & Spreadsheet Compatibility
- CSV / spreadsheet import and export with schema validation and real-time preview.
- Advanced transaction filtering, sorting, date-range filtering, and custom pagination.

### Desktop & Large-Screen Workspace
- Responsive split-view layout for wide viewports (1080p, 1440p, 4K).
- Full-width dynamic data grid with custom pagination.
- Mouse and trackpad drag support for account carousel and interactive navigation.

### Architecture & Security
- State Management: Flutter Riverpod with code generation.
- Backend & Auth: Supabase (PostgreSQL, Row Level Security, PKCE auth flow).
- Push Notifications: Firebase Cloud Messaging (FCM).
- Theming: Deep Obsidian Dark Mode and Light Mode with custom design system.

---

## Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart SDK `^3.13.3`)
- **State Management:** [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod)
- **Backend / Database:** [Supabase](https://supabase.com/)
- **Machine Learning / OCR:** [Google ML Kit Text Recognition](https://pub.dev/packages/google_mlkit_text_recognition)
- **Push Notifications:** [Firebase Messaging](https://firebase.google.com/)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Typography:** [Google Fonts (Plus Jakarta Sans)](https://fonts.google.com/specimen/Plus+Jakarta+Sans)

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.13.3 or higher)
- Android Studio / VS Code with Flutter extensions
- Supabase project credentials

### Environment Configuration
Create a `.env` file in the root directory:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/devilk1d/uank.git
   cd uank
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   # Mobile (Android/iOS)
   flutter run

   # Windows Desktop
   flutter run -d windows
   ```

---

## Build & Deployment

### Android APK
```bash
# Split Per-ABI Release APKs (arm64-v8a, armeabi-v7a, x86_64)
flutter build apk --release --split-per-abi

# Universal Fat APK
flutter build apk --release
```
Output location: `build/app/outputs/flutter-apk/`

### Windows Desktop Executable
```bash
flutter build windows --release
```
Output location: `build/windows/x64/runner/Release/`
