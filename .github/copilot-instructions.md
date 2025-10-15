<!--
Guidance for AI coding agents working on the Bill-Generator Flutter app.
Keep this file short, actionable and focused on patterns discoverable in the repo.
-->

# Copilot instructions for bill_generator

Quick orientation
- This is a Flutter app (Dart 3.8+, see `pubspec.yaml`). Entry point: `lib/main.dart`.
- High-level modules live under `lib/`: `models/`, `services/`, `screens/`, `theme/`, `utils/`, and `widgets/`.

What the app does (one line)
- Manage consumers, meter readings and bills; generate per-bill and summary PDFs; backup/restore via zip.

Important files and services to read first
- `README.md` — comprehensive project overview, workflows and domain rules (use as canonical source).
- `lib/main.dart` — app bootstrap and `SettingsProvider` usage (theme & settings loaded before UI).
- `lib/services/database_service.dart` — singletons and DB schema (consumers, meter_readings, bills). Read for data flows and FK behavior.
- `lib/services/pdf_service.dart` — PDF generation (how images, adjustments and totals appear). Examples of filename patterns: `bill_<id>.pdf`, `bills_summary_<consumerId>.pdf`.
- `lib/services/backup_service.dart` — backup zip layout and restore mapping (expects `billing.db`, `meter_images/`, `bills/`).
- `lib/services/image_service.dart` — image storage conventions (stable per-consumer filenames like `meter_<consumerId>.jpg`).

Key architecture & patterns
- Singletons & provider: `DatabaseService.instance` is used widely. `SettingsProvider` is a ChangeNotifier created in `main.dart`.
- Persistence: SQLite (`sqflite`) for relational data; `adjustments` are JSON-encoded inside `bills` for historical immutability.
- Files: app documents dir used to store `bills/` PDFs and `meter_images/`; backup packs whole DB + those directories.
- PDF behavior: PDFs are overwritten per bill/consumer (not versioned). When regenerating, code writes to `bills/` and uses filenames above.

Developer workflows & commands (what to run)
- Install deps: `flutter pub get` (root of repo).
- Run: `flutter run` (or open in IDE). Main screen is Consumers list.
- Analyze: `flutter analyze` (standard lints are enabled via `analysis_options.yaml`).
- Android build: `flutter build apk --release`.

Project-specific conventions
- Naming: consumer images use `meter_<consumerId>.jpg` (see `ImageService`). PDFs use `bill_<id>.pdf` and `bills_summary_<consumerId>.pdf` (see `PdfService`).
- DB schema is created on first open in `DatabaseService` — changes to schema must preserve migrations; the code uses simple CREATE TABLE if-not-exists approach.
- Adjustments: stored as immutable JSON in the `bills` table — when editing billing logic, update both `DatabaseService.createBill` and `models/bill.dart` consistency.

Integration points & external deps
- Native permissions: camera/gallery (iOS Info.plist keys and AndroidManifest entries required for `image_picker`).
- Packages used (see `pubspec.yaml`): `sqflite`, `pdf`, `pdfx`, `image_picker`, `share_plus`, `file_picker`, `archive`, `shared_preferences`, `provider`, `intl`.
- Backup/restore uses `archive` to zip/unzip DB + directories; restores expect exact filenames — preserve mapping.

When making changes, check these places together
- If you change billing calculations: update `DatabaseService.createBill`, `models/bill.dart`, and `lib/services/pdf_service.dart` (PDF presentation).
- If you change image filename conventions: update `ImageService`, `PdfService` image embedding logic, and `BackupService` include/restore rules.
- If you change Settings shape: update `lib/services/settings_service.dart`, `main.dart` provider initialization, and any `utils/format.dart` usage of currency/tax.

Examples (copyable snippets / traces)
- Stable image path pattern: `${docs.path}/meter_<consumerId>.jpg` (see `lib/services/image_service.dart`).
- Bill PDF file path: `${docs.path}/bills/bill_<bill.id>.pdf` (see `lib/services/pdf_service.dart`).

Testing & validation notes
- There are no unit tests in the repo root. Prefer small focused tests for logic changes (billing math) if adding tests.
- Manual validation: generate a bill with images, verify generated PDF contains expected lines (consumer name, consumption, adjustments).

Edge cases observed in code
- Current reading must be >= previous reading; the UI enforces numeric validation but DB assumes callers validate.
- Adjustments may be empty; PDF generation branches on `bill.adjustments.isNotEmpty`.

If unsure, follow the README first
- The `README.md` is the authoritative containing domain rules and typical flows — reference it when deciding expected behavior.

Questions for the maintainer
- Do you want PDFs versioned (avoid overwrites) or is overwrite behavior intentional?
- Any planned DB migrations strategy beyond recreate-on-first-run?

If something in the codebase contradicts the README, prefer the code and flag the mismatch in PR description.
