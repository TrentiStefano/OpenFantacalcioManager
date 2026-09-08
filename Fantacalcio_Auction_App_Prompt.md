# Prompt: Build "Open Fantacalcio Manager" — a Flutter Auction-Draft App

Copy everything below into your coding agent as the project brief.

\---

## 1\. Project summary

Build a **cross-platform Flutter application** (macOS, Windows, Linux, iOS, Android) called **"Open Fantacalcio Manager"**. It is a lightweight, fully offline tool that helps a fantasy football (Fantacalcio, Italian Serie A) manager prepare for and run a live players auction/draft.

The app must digitize and improve on a Google Sheets workflow the user has used for years. Two real spreadsheet exports are the source of truth for data shape and workflow — study the structure described below carefully before writing any code, since it drives the entire data model and UI.

If provided, sample files will be placed in the project at `spreadsheets/Quotazioni\_Fantacalcio\_Stagione\_2026\_27.xlsx` and `spreadsheets/Asta\_Fantacalcio\_26\_27.xlsx`. Treat these as reference/fixture data only — the app must work with **any** season's file the user imports at runtime, not just these two.

\---

## 2\. Source data #1 — the master player price list ("Quotazioni")

This is the file the user imports at the start of every season. It is a **standard, well-known Fantacalcio format** published every year (currently as `.xlsx`, but the app must also accept `.csv`). Column order can shift year to year, so **map columns by header name, not by position**, using case-insensitive/trimmed matching.

|Column header|Meaning|Type|
|-|-|-|
|`Id`|Unique player id|integer|
|`R`|Role, classic mode: `P` (Portiere/GK), `D` (Difensore), `C` (Centrocampista), `A` (Attaccante)|string|
|`RM`|Role(s) in "Mantra" mode (e.g. `Por`, `E`, `M;C`, `Pc`) — multiple roles separated by `;`|string, optional|
|`Nome`|Player name|string|
|`Squadra`|Serie A club|string|
|`Qt.A`|Current classic auction quotation|number|
|`Qt.I`|Initial-of-season classic quotation|number|
|`Diff.`|`Qt.A` − `Qt.I`|number|
|`Qt.A M`|Current Mantra quotation|number|
|`Qt.I M`|Initial Mantra quotation|number|
|`Diff.M`|Mantra diff|number|
|`FVM`|Fantavalore di Mercato (classic market value ranking score)|number|
|`FVM M`|FVM for Mantra mode|number|

The workbook may contain multiple sheets (e.g. `Tutti`, `Portieri`, `Difensori`, `Centrocampisti`, `Attaccanti`, `Ceduti`) that are just role-filtered views of the same data, plus a `Ceduti` (transferred-out / no longer in Serie A) sheet. **On import, only read the "all players" sheet** (auto-detect it — usually the first sheet or the one with the most rows) and ignore the redundant filtered sheets; the app will generate its own filtered views. Players present in a `Ceduti`-style sheet should be excluded or flagged as unavailable if such a sheet exists.

\---

## 3\. Source data #2 — the working auction board ("LISTONE" / strategy sheets)

This is the *derived, editable* board the user builds from the imported list above, mirroring these original sheets:

### 3.1 `LISTONE` (master working board)

One row per player, columns:

* `Id`, `R`, `Nome`, `Squadra` — copied from the import
* **`Valore Base Asta`** (originally mislabeled "FVM" in the old sheet) — a computed number: `ROUND(% Budget × Budget Iniziale)`. This is the credit value the app suggests as a starting/target price.
* **`% Budget`** — a user-editable percentage representing what share of the total auction budget this player is "worth" to the user. This is the core planning lever of the whole app.
* **`Fascia`** (tier) — user-editable label bucketing players by importance, e.g. `TOP`, `SEMITOP`, `TERZO-SLOT`, `QUARTO-SLOT`, `SCOMMESSE`, `TITOLARI`, `ALTRI`. Make the tier list configurable but ship these as sensible defaults, per role (goalkeepers typically only use `TOP`/`SEMITOP`/`TERZO-SLOT`).
* **`⭐ Preferito`** — boolean "favorite player" star toggle.
* Derived sort keys: priority by tier (TOP=1 … ALTRI=last) then priority by role order (P, D, C, A) then `Valore Base Asta` descending. Rows are sortable/filterable in the UI; these are just default sort helpers, not literal stored columns.

### 3.2 Per-role strategy views (`Strat Por`, `Strat Dif`, `Strat Cen`, `Strat Att`)

Each is simply `LISTONE` filtered to one role, sorted by tier priority then value descending, with two extra **editable** fields per player that only make sense in this focused view:

* `Prezzo Obiettivo` — the target price the user personally plans to bid up to.
* `Note` — free-text notes (e.g. "backup for X", "only if under 20").

These are not separate data — they're additional fields on the same `Player` entity, just surfaced in the role-filtered screens.

### 3.3 `Squadra` (my team / auction tracker)

The live-auction bookkeeping sheet:

* **Top summary**: Budget Iniziale (total credits, e.g. 600 or the classic 500), Totale Speso, Budget Residuo, Slot Rimanenti.
* **Per-role budget table**: for each role — Slot Totali (roster size for that role, classic defaults `P=3, D=8, C=8, A=6`, total 25 — must be configurable), Acquistati (bought so far), Rimanenti (slots left), Budget Allocato (planned credits for that role), Speso (actual credits spent in that role), Residuo (Allocato − Speso).
* **Roster table**: every player the user has actually won at auction — Ruolo, Calciatore, Squadra, Valore Acquisto (final price paid). Adding/editing/removing a row here must live-update every total above.

> Note for the agent: the original spreadsheet had a labeling bug where a column called "Budget disponibile" actually summed money spent, not money available. \*\*Do not replicate that bug\*\* — implement the clean, correct version described above (Allocato / Speso / Residuo, clearly separated).

\---

## 4\. Core workflow the app must support

1. **Import** the season's Quotazioni file (`.xlsx` or `.csv`) via a file picker (must work with native file dialogs on desktop and the file/document picker on iOS/Android).
2. **Setup**: user sets Budget Iniziale (total credits) and roster slots per role (defaults pre-filled from classic Fantacalcio rules, fully editable). Optionally toggle Classic vs Mantra scoring mode (changes which FVM/quotation columns are shown and which role field, `R` vs `RM`, drives filtering).
3. **Build the strategy board**: for every imported player, the user sets `% Budget`, `Fascia`, and optionally `⭐ Preferito`, `Prezzo Obiettivo`, `Note`. As they type a `% Budget`, `Valore Base Asta` recalculates instantly. Provide a "suggest % from FVM" bulk action (normalizes FVM into a starting percentage per role) that the user can then hand-tune — this is a helpful starting point, not something to enforce.
4. **Browse strategy** in role-filtered tabs (Portieri / Difensori / Centrocampisti / Attaccanti), sorted by tier then value, editing `Prezzo Obiettivo`/`Note`/tier/favorite inline.
5. **Run the live auction**: a dedicated screen with a fast search/autocomplete over all players. Selecting a player shows a card with all their planning info (tier, base value, target price, notes, favorite) plus three actions:

   * **Assegna a me** — enter the final hammer price, add to "my roster", deduct budget, decrement that role's remaining slots.
   * **Venduto ad altri** — mark the player as gone (taken by another manager) with no cost to the user; removes them from the available pool everywhere.
   * **Rimetti disponibile** — undo, in case of a misclick.
A persistent, always-visible mini-dashboard (total budget left, slots left per role) should be visible during this screen so the user can make live bidding decisions.
6. **Track "La Mia Rosa" (my team)**: dashboard with the summary cards and per-role table from §3.3, plus the roster list grouped by role, each entry editable/removable (which reverts the budget/slot counters).
7. **Export**: let the user export the current `LISTONE` (with their %, tiers, notes) and their final roster back out to `.xlsx`/`.csv`, so they keep an offline record exactly like they used to with the Google Sheet.
8. **Persist everything locally** between app launches (see §7) so an in-progress auction survives an app restart/crash — auctions can run for hours.

\---

## 5\. Tech stack \& architecture

* **Flutter** (latest stable), single codebase targeting macOS, Windows, Linux, iOS, Android. Enable all five platforms explicitly (`flutter create --platforms=...`).
* Keep it **lightweight**: minimal dependency footprint, no backend/server, no auth, fully offline-first.
* **State management**: Riverpod (preferred) or Provider — pick one and use it consistently.
* **Local persistence**: `drift` (SQLite) or `Hive`/`Isar` for the player list, league settings, and roster/purchase state. Choose whichever best fits a relational shape like this (players, purchases, settings) — `drift` is a good fit given the tabular, filterable data.
* **File parsing**: `excel` (or `syncfusion\_flutter\_xlsio` if license-free, otherwise `excel`) for `.xlsx`, `csv` package for `.csv`; `file\_picker` for cross-platform file selection.
* **Data tables/UI**: build a custom, performant sortable/filterable data table for \~500+ rows (don't rely on a naive `ListView` rebuild-everything approach) — consider `two\_dimensional\_scrollables` or a well-optimized `DataTable`/custom `SliverList` with virtualization.
* Write clean, layered architecture: `data/` (models, repositories, import/export, persistence), `domain/` (business logic: value calculations, budget math), `presentation/` (screens, widgets, state).
* Add basic widget/unit tests for the core calculations (value = round(%×budget), budget/slot totals) and the import column-mapping logic.

\---

## 6\. UI/UX requirements

* **Modern, clean, light color palette** — plenty of white/near-white background, soft neutral surfaces, one or two accent colors (e.g. a Serie-A-adjacent green or blue) used sparingly for actions/highlights, clear typography hierarchy, generous spacing, subtle shadows/rounded corners rather than heavy borders.
* Responsive layout: a navigation rail / sidebar on desktop and wide tablets, bottom navigation on phones. Tables should adapt to narrower screens (e.g. card layout on mobile, full table on desktop).
* Use color and small badges to distinguish roles (P/D/C/A) and tiers at a glance, and to show player status (available / mine / taken by others) — but keep it tasteful, not garish.
* Budget and slot usage should be visualized (progress bars/gauges), not just numbers, on the "La Mia Rosa" dashboard and the live-auction mini-dashboard.
* Favor a small number of well-organized screens/tabs (Import \& Setup, Listone, Strategie \[with role sub-tabs], Asta Live, La Mia Rosa) over deep navigation.

\---

## 7\. Non-functional requirements

* Fully **offline**: no network calls required for core functionality.
* **Fast startup and smooth scrolling** even with the full \~500-600 row Serie A player list loaded.
* Application must handle multiple languages, start with italian and english.
* Must have a light and dark theme modes.
* Data must **persist across app restarts** (in-progress auctions, imported list, all edits).
* Include a "reset / start new season" action that clears state after confirmation.
* Provide a clear README explaining how to run the app on each of the five target platforms.

\---

## 8\. Suggested deliverable structure

```
lib/
  data/
    models/            # Player, Purchase, LeagueSettings, Tier
    import/             # xlsx/csv parsers with header-based column mapping
    export/
    repositories/
    persistence/         # drift/hive setup
  domain/
    budget\_calculator.dart
    sorting\_filtering.dart
  presentation/
    import\_setup/
    listone/
    strategy/            # role-filtered sub-screens
    auction\_live/
    my\_team/
    shared/widgets/
spreadsheets/            # sample import fixtures (optional, for dev/testing)
test/
```

\---

## 9\. Acceptance criteria checklist

* \[ ] Imports a real Fantacalcio `Quotazioni` `.xlsx`/`.csv` file correctly via header-name mapping, tested against a \~500-row file.
* \[ ] `% Budget` editing instantly recalculates `Valore Base Asta` per player.
* \[ ] Tier, favorite, target price, and notes are all editable and persist.
* \[ ] Role-filtered strategy screens sort by tier priority then value, matching §3.2.
* \[ ] Live auction screen supports assign-to-me / sold-to-others / undo, with instant budget \& slot updates.
* \[ ] "La Mia Rosa" dashboard math (Allocato/Speso/Residuo per role, totals) is correct and matches manual calculation.
* \[ ] All state survives an app restart.
* \[ ] App builds and runs on macOS, Windows, Linux, iOS, and Android.
* \[ ] Export produces a re-importable `.xlsx`/`.csv` reflecting the current board and roster.
* \[ ] UI is light-themed, clean, and responsive from phone to desktop widths.

