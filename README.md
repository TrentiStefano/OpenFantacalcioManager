# Open Fantacalcio Manager (OFM) ⚽

A modern, cross-platform, fully offline-first Flutter application (Windows, macOS, Linux, Android, iOS) designed to help fantasy football (*Fantacalcio*, Italian Serie A) managers prepare for and run a live players auction/draft.

It digitizes and enhances traditional Google Sheets workflows, eliminating spreadsheet formula bugs, enabling lightning-fast search during live bidding, providing instant mathematical updates, and persisting all state locally across app restarts.

---

## 🌟 Key Features

1. **Header-Based Spreadsheet Import (`.xlsx` and `.csv`)**:
   - Dynamic, case-insensitive, and trimmed column header matching (`Id`, `R`, `Nome`, `Squadra`, `Qt.A`, `Qt.I`, `Diff.`, `FVM`, etc.).
   - Automatic banner/title detection (skips metadata header banners seamlessly).
   - Reads the master "all players" sheet (e.g., `Tutti`) and automatically identifies transferred-out players from `Ceduti` sheets, marking them as unavailable.
   - Built-in **1-Click Sample Fixture Loader** (`Quotazioni_Fantacalcio_Stagione_2026_27.xlsx`) for immediate onboarding and testing.

2. **Master Strategy Board ("Listone")**:
   - **`% Budget` Planning**: The core lever. Editing a player's percentage immediately recalculates their suggested starting auction price: `Valore Base Asta = ROUND(% Budget × Budget Iniziale)`.
   - **Bulk FVM Normalization**: "Suggerisci % da FVM" bulk action automatically computes starting percentage targets distributed proportionally by role budget.
   - **Custom Tiers (`Fascia`)**: Default tiers (`TOP`, `SEMITOP`, `TERZO-SLOT`, `QUARTO-SLOT`, `TITOLARI`, `SCOMMESSE`, `ALTRI`) with role-specific constraints (e.g. goalkeepers).
   - **Favorites Star (`⭐ Preferito`)**, quick filters by role, tier, status, and favorites.

3. **Per-Role Strategy Tabs (`Portieri`, `Difensori`, `Centrocampisti`, `Attaccanti`)**:
   - Focused role boards sorted by tier priority then base value descending.
   - Inline editable **`Prezzo Obiettivo`** (maximum personal bid target) and **`Note`** (tactical remarks).

4. **Live Auction Mode ("Asta Live")**:
   - **Persistent Sticky Mini-Dashboard**: Always displays total remaining budget, spent credits, and real-time slots remaining per role with visual progress gauges.
   - **Instant Search & Autocomplete**: Quickly locate any Serie A player by name or club.
   - **Active Player Focus Card**: Highlights quotation, FVM, target price, and custom strategy notes.
   - **1-Tap Actions**:
     - **Assegna a me**: Enter hammer price; instantly deducts budget and decrements role slot.
     - **Venduto ad altri**: Marks player as taken by a rival manager at no cost.
     - **Rimetti disponibile**: 1-click undo for misclicks or cancelled bids.

5. **"La Mia Rosa" (Roster & Budget Tracker)**:
   - Clean, correct budget mathematics: **Allocato**, **Speso**, and **Residuo = Allocato − Speso**.
   - Top summary cards with animated visual progress bars.
   - Per-role allocation table.
   - Complete official roster list grouped by role, with inline hammer price editing and player release.

6. **Exporting**:
   - Generates fully formatted `.xlsx` workbooks containing both `LISTONE` (with user %, tiers, and notes) and `Squadra` (live budget status and roster table).
   - Generates `.csv` exports for lightweight offline records.

7. **Aesthetics & Internationalization**:
   - Modern Serie A sapphire blue and emerald green palette.
   - Responsive UI: `NavigationRail` sidebar on desktop/tablet, `NavigationBar` on mobile.
   - **Light and Dark Theme Modes**.
   - **Multi-language support**: Italian (default) and English.

8. **Offline-First Persistence**:
   - Powered by SQLite via `sqflite_common_ffi` (Desktop) and `sqflite` (Mobile).
   - All purchases, custom notes, tiers, and settings persist automatically across restarts.

---

## 🚀 How to Run the App on Each Platform

### Prerequisites
- Install Flutter 3.47+ and Dart 3.13+: [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- Verify your environment with:
  ```bash
  flutter doctor
  ```

### 1. Windows Desktop
- **Requirements**: Visual Studio 2022 / 2026 with the "Desktop development with C++" workload installed.
- **Run Native Desktop Application**:
  ```bash
  flutter run -d windows
  ```
  *(Launches the standard native Windows desktop application with sidebar `NavigationRail`, full tables, and desktop layouts).*
- **Run with iPhone Device Preview**:
  ```bash
  flutter run -d windows --dart-define=PREVIEW=true
  ```
- **Build Release Executable**:
  ```bash
  flutter build windows
  ```
  The compiled `.exe` and assets will be generated in `build/windows/x64/runner/Release/`.

### 2. macOS Desktop
- **Requirements**: Xcode installed and CocoaPods (`sudo gem install cocoapods`).
- **Run**:
  ```bash
  flutter run -d macos
  ```
- **Build Release App**:
  ```bash
  flutter build macos
  ```

### 3. Linux Desktop
- **Requirements**: Clang, CMake, GTK development headers, and pkg-config:
  ```bash
  sudo apt-get update && sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
  ```
- **Run**:
  ```bash
  flutter run -d linux
  ```
- **Build Release Binary**:
  ```bash
  flutter build linux
  ```

### 4. Android
- **Requirements**: Android Studio with Android SDK and platform tools.
- Connect your Android device or launch an Android Virtual Device (AVD).
- **Run**:
  ```bash
  flutter run -d android
  ```
- **Build Release APK**:
  ```bash
  flutter build apk --release
  ```

### 5. iOS
- **Requirements**: macOS with Xcode installed.
- Connect an iPhone or launch an iOS Simulator.
- **Run**:
  ```bash
  flutter run -d ios
  ```
- **Build Release Bundle**:
  ```bash
  flutter build ipa
  ```

### 6. Web & Mobile Device Preview
- **Run in Chrome with iPhone Preview**:
  ```bash
  flutter run -d chrome
  ```
  *(Powered by `sqflite_common_ffi_web` SQLite WASM and `device_preview`).*
- **Run Full Web App (Without Device Frame)**:
  ```bash
  flutter run -d chrome --dart-define=PREVIEW=false
  ```
- **Build Web Release**:
  ```bash
  flutter build web
  ```

---

## 📱 Testing the iPhone & iPad UI on Windows

Even without a Mac, you can thoroughly test the touch-friendly mobile layouts, bottom navigation bar, player cards, Cupertino bottom sheets, and live auction bid steppers on Windows:

### Method A: Native Windows App vs. iPhone Frame
1. **Normal Native Windows Desktop**:
   ```bash
   flutter run -d windows
   ```
   Launches the full desktop interface.
2. **Windows with Interactive iPhone Frame**:
   ```bash
   flutter run -d windows --dart-define=PREVIEW=true
   ```
   Renders the interactive iPhone frame directly on your Windows desktop.

### Method B: Chrome with Interactive Device Preview
```bash
flutter run -d chrome
```
- Opens Google Chrome with an **iPhone 13 Pro Max** frame by default.
- Use the bottom toolbar to:
  - **Switch devices**: Switch between iPhone and **iPad** (to view the layout expand from bottom bar into `NavigationRail`).
  - **Rotate orientation**: Test portrait and landscape modes.
  - **Toggle Frame ON/OFF**: Click the gear icon or toggle to instantly switch between the phone frame and the full desktop UI without restarting.

### Method C: Test Live on Physical iPhone / iPad via Wi-Fi
1. Start the local server binding to all network interfaces:
   ```bash
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
   ```
2. Find your PC's IP address (`ipconfig` $\rightarrow$ IPv4 Address, e.g. `192.168.1.50`).
3. Open **Safari** on your iPhone or iPad connected to the same Wi-Fi and navigate to:
   `http://192.168.1.50:8080`
4. Tap **Share $\rightarrow$ "Add to Home Screen"** to test as a full-screen, standalone iOS app with native gestures!

---

## 🚀 CI/CD & Automated GitHub Releases

The repository includes a complete GitHub Actions workflow (`.github/workflows/release.yml`) for automated multi-platform installer distribution:

1. **Trigger Condition**:
   - Fires automatically when a **Major or Minor** version update is detected (e.g. `v1.1.0`, `v2.0.0`, or changes in `pubspec.yaml` where `patch == 0` or major/minor changes).
   - Patch releases (`v1.0.1`) skip the heavy multi-platform installer build.
2. **Platform Installers Generated**:
   - **Windows**: `OpenFantacalcioManager-Windows-x64-v{VERSION}.zip` containing the standalone release binary and runtime dependencies, plus Inno Setup installer script (`windows/installer.iss`).
   - **macOS**: `OpenFantacalcioManager-macOS-v{VERSION}.zip` containing the compiled `.app` bundle.
   - **Linux**: `OpenFantacalcioManager-Linux-x64-v{VERSION}.tar.gz` containing the release binary bundle.
3. **Automated Publishing**:
   - Extracts formatted release notes from `CHANGELOG.md`.
   - Creates the GitHub Release and attaches all 3 platform installer packages automatically.

---

## 🧪 Running Automated Tests

Run the full automated test suite (verifying budget math, round calculations, FVM normalizations, spreadsheet header parsing, and widget rendering):

```bash
flutter test
```

---

## 📁 Architecture Overview

```
lib/
├── main.dart                          # App entry point, desktop SQLite FFI init, theme & localization
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # Serie A palette & role colors (P/D/C/A)
│   │   └── app_tiers.dart             # Tier priority mapping & badges (TOP, SEMITOP, etc.)
│   ├── theme/app_theme.dart           # Light & Dark theme definitions
│   └── localization/                  # Italian & English translation dictionaries
├── data/
│   ├── models/                        # Player, LeagueSettings, AuctionSummary
│   ├── persistence/                   # DbProvider (cross-platform SQLite) & PlayerDao
│   ├── import/quotazioni_importer.dart# Header-based .xlsx and .csv parser
│   ├── export/spreadsheet_exporter.dart # Full .xlsx and .csv exporter
│   └── repositories/player_repository.dart
├── domain/
│   ├── budget_calculator.dart         # Valore base round(% * budget) & summary aggregation
│   ├── fvm_suggester.dart             # Proportional FVM to budget % normalization
│   └── player_filter_sort.dart        # Multi-level sorting (Tier -> Role -> Value)
└── presentation/
    ├── navigation/app_shell.dart      # Responsive desktop NavigationRail & mobile NavigationBar
    ├── providers/                     # Riverpod state notifiers (players, settings, filters, theme)
    ├── screens/
    │   ├── import_setup/              # File picker, budget parameters, and sample loader
    │   ├── listone/                   # Master working board with instant recalculations
    │   ├── strategy/                  # Role-filtered tabs with target price & notes
    │   ├── live_auction/              # Live bidding, fast search, active player card, 3 actions
    │   ├── my_team/                   # Roster and budget tracker
    │   └── settings/                  # Language & theme toggles, season reset
    └── shared/                        # RoleBadge, TierBadge, StatusBadge, StatCard, EditableBudgetCell
```
