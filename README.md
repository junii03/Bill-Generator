# Electricity Billing App (bill_generator)

A Flutter application to manage consumers, record meter readings with images, apply adjustments & taxes, generate individual bill PDFs and aggregated summary PDFs, and securely back up / restore all billing data.

## Contents
- Key Features
- Quick Start
- Project Structure
- Data Model
- Core Services
- Bill Generation & PDFs
- Backup & Restore
- Settings & Theming
- Typical Workflows
- Error Handling & Validation
- Extensibility Ideas / Roadmap
- Troubleshooting
- Tech Stack & Requirements
- Contribution Guidelines
- License

## Key Features
1. Consumer Management
   - Add consumers with a configurable cost-per-unit (kWh).
   - Fast search & alphabetically ordered listing.
   - Update cost-per-unit implicitly when creating a new bill (auto-detect change).
   - Safe removal (cascades to meter readings & bills via foreign keys).
2. Meter Readings
   - Automatic pre-fill of the previous reading (uses last bill's current reading).
   - Previous & current reading validation (current must be >= previous).
   - kWh consumed computed and clamped at >= 0.
   - Attach meter images (camera/gallery). Images persisted per consumer with an overwrite strategy (keeps storage lean).
3. Adjustments & Tax
   - Arbitrary positive (charges) or negative (discount) adjustments with labels.
   - Optional default tax percentage auto-applied (settings-driven) if not manually added.
4. Bill Creation
   - Real-time totals preview (consumption, base, adjustments, total).
   - Generates persistent Bill entries linked to meter readings & consumers.
5. PDF Generation
   - Detailed individual bill PDF with:
     - Consumer info & usage summary.
     - Meter images (if provided).
     - Line-item breakdown (energy charge + adjustments + totals).
     - Consistent currency symbol.
   - Summary PDF for all bills of a consumer (aggregated totals & per-bill table).
6. Sharing & Export
   - Share single bill PDF or full summary PDF (Share Plus).
7. Settings
   - Currency symbol override.
   - Default tax percent (auto adjustment line).
   - Dark / light mode toggle with Provider state.
8. Backup & Restore
   - Zip archive export of: SQLite DB, meter images, bill PDFs.
   - Restore from selected .zip (overwrites existing data).
9. Persistence & Storage
   - SQLite (sqflite) relational schema.
   - Shared Preferences for lightweight settings.
   - File system for images & PDFs.
10. UI / UX
    - Material 3 theming.
    - Responsive width constraints for larger displays.
    - Accessible text sizing and contrast aware color usage.

## Quick Start
Prerequisites: Flutter SDK (>= 3.22 / Dart >= 3.8), macOS / Windows / Linux with Android/iOS tooling.

Install dependencies:
```
flutter pub get
```
Run on a device/emulator:
```
flutter run
```
Build release (Android):
```
flutter build apk --release
```
(Adjust signing / iOS build steps per platform.)

## Project Structure (Relevant)
```
lib/
  main.dart                   # App bootstrap & theming
  models/                     # Data models (Consumer, MeterReading, Bill, Adjustment)
  services/                   # Data, PDF, backup, settings & image utilities
  screens/                    # UI screens & flows
  theme/                      # Theming utilities
  utils/                      # Formatting helpers, etc.
  widgets/                    # Reusable widgets (if any)
```

## Data Model
SQLite Tables:
- consumers(id, name, cost_per_unit)
- meter_readings(id, consumer_id, previous_reading, current_reading, previous_image_path, current_image_path, reading_date)
- bills(id, consumer_id, meter_reading_id, base_amount, adjustments_total, total_amount, adjustments_json, created_at)

Relationships:
- Consumer 1:N MeterReading
- Consumer 1:N Bill
- Bill 1:1 MeterReading (linked via meter_reading_id)

Adjustments are stored JSON-encoded (adjustments_json) inside each Bill for immutability and historical integrity.

## Core Services Overview
- DatabaseService
  - Lazy init of SQLite DB.
  - CRUD for consumers, meter readings, bills.
  - Bill creation logic (computes base, adjustments, totals).
- PdfService
  - Generates individual bill & summary PDFs.
  - Embeds meter images (if present).
  - Writes PDFs to <app-docs>/bills/.
- ImageService
  - Picks images (camera/gallery) and stores per-consumer stable file (meter_<id>.jpg) or unique files.
- BackupService
  - Creates zip with DB + meter_images + bills directories.
  - Restores archive, mapping files to locations.
- SettingsProvider
  - Wraps SharedPreferences; exposes reactive currency, tax %, dark mode.

## Bill Generation & PDFs
Single Bill PDF includes:
- Header (bill ID, consumer ID, timestamp).
- Usage summary (prev, current, units consumed, cost per unit).
- Meter images (previous/current) side-by-side if available.
- Billing breakdown table: energy charge, adjustments (with per-line amounts), grand total.
- Footer note (system generated).

Summary PDF (per consumer):
- Paginated table of all bills (date, consumption, base, adjustments, total).
- Aggregated totals (base, adjustments, grand total).

## Backup & Restore
Backup Archive Contents:
- billing.db (SQLite data)
- meter_images/ (captured JPEGs)
- bills/ (generated PDF files)

Restore:
- User selects .zip; existing data files overwritten.
- App restart recommended after restore to reload state.

## Settings & Theming
- Currency symbol applied dynamically in UI & PDFs.
- Default tax percent auto-adds an adjustment line (labeled "Default Tax (%value%)") if not already present.
- Dark mode toggle persists across sessions (ThemeMode switching in main.dart).

## Typical Workflows
1. Add Consumer
   - Navigate: FAB on Consumers list.
   - Provide name + cost per unit.
2. Create Bill
   - From Consumer card menu -> New Bill.
   - Previous reading auto-filled; enter current reading.
   - Optionally capture meter images.
   - Add adjustments (e.g., Fuel Adjustment, Rebate, Late Fee).
   - Save -> navigates to Bill Detail.
3. Generate / Share PDF
   - In Bill Detail press PDF icon or bottom bar button.
   - After generation, Share using share icon.
4. View All Bills for a Consumer
   - Tap consumer card -> Bills list.
   - Long press a bill for options (PDF or delete).
   - Export summary PDF via floating mini action button.
5. Backup / Restore
   - Settings -> Create Backup (stores zip in app docs path).
   - Restore -> pick .zip; relaunch app.
6. Adjust Defaults
   - Change currency symbol or tax percent in Settings (pending Save banner appears).

## Error Handling & Validation
- Form validation for readings (must be numeric; current >= previous).
- Cost-per-unit > 0 enforced.
- Consumed kWh threshold guard (rejects extremely large inputs > 1,000,000).
- Try/catch around PDF generation, backup/restore with user-visible SnackBars.
- Safe navigation if a referenced bill or reading is missing (returns to previous screen).

## Extensibility Ideas / Roadmap
- Multi-currency formatting with locale support (intl NumberFormat).
- Tiered or slab-based tariffs (progressive rates).
- Partial payments / outstanding balance tracking.
- Cloud sync (e.g., Supabase / Firestore) optional.
- User authentication for multi-device usage.
- Export CSV / Excel of billing history.
- Automated scheduled backups to cloud storage.
- Localization (i18n) for labels & PDF strings.
- Bulk bill generation for multiple consumers in one run.

## Troubleshooting
| Issue | Cause | Resolution |
|-------|-------|-----------|
| Images not appearing in PDF | File path missing or file deleted | Re-capture images and regenerate PDF |
| Restore fails | Invalid zip or missing expected files | Ensure archive produced by app; retry backup then restore |
| Currency not updating in old PDFs | PDFs are static snapshots | Regenerate PDFs if you need updated symbol |
| Dark mode not applied | Settings not yet loaded | Wait for initial provider load (progress indicator) |

## Tech Stack & Requirements
- Flutter SDK (stable) with Material 3.
- Dart 3.8+ (as constrained in pubspec).
- Packages: sqflite, path_provider, pdf, pdfx, share_plus, image_picker, archive, file_picker, provider, shared_preferences, intl, uuid.
- Tested Platforms: Android (primary). iOS expected (ensure camera/gallery permissions added in platform configs).

### Platform Notes
Android: Update AndroidManifest for camera & storage access if needed.
iOS: Add NSCameraUsageDescription & NSPhotoLibraryUsageDescription to Info.plist.

## Contribution Guidelines
1. Fork & branch (feat/<name>, fix/<name>).
2. Run `flutter analyze` & `flutter test` (add tests if adding logic).
3. Keep PRs focused & documented (description + screenshots for UI changes).
4. Update README / CHANGELOG for user-facing features.

## License
Add your chosen license here (e.g., MIT, Apache-2.0). Replace this section with the actual license text or a link to LICENSE file.

---
Maintained with care. Contributions & feedback welcome.
