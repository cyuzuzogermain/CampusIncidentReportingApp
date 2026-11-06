# Campus Incident Reporting App

University assignment: a Flutter Android app (Android emulator target).
Students report campus issues; staff review them and update their status.

## Scope — build only what's specified, no extra features
- **Students:** create a report with title, description, category, location and an
  optional photo, then track its status (Home, My Reports, Incident Details, Profile).
  - **Campus Reports** tab: every student's reports, read-only.
  - On someone else's report a student can mark themselves as **affected**
    (`affectedUserIds`), or unmark; no new joins once it's resolved.
  - On their own report, the reporter can **edit** it (`/incident/:id/edit`)
    or **withdraw** it (deletes the document, with a confirmation dialog),
    but only while it is still `submitted`.
- **Staff:** see all reports on a dashboard and, from Incident Details (with a
  confirmation dialog), move a report's status forward with an **optional
  comment**, or **reject** it with a **required reason**. Comments are saved on
  the `statusHistory` entry (`comment`, max 500 characters) and shown in the
  timeline. The rejection reason is also shown in a banner on the report.
- **Categories:** Facilities, Water, Electricity, Safety, Sanitation
  (`lib/core/constants/incident_category.dart`; label, icon and color per value).
- **Status flow:** Submitted → In Progress → Resolved, plus **Rejected**, which
  staff can choose from Submitted or In Progress
  (`lib/core/constants/incident_status.dart`). Firestore stores `submitted`,
  `in_progress`, `resolved` and `rejected`. Moves are one step forward
  (`IncidentStatus.next`) or a rejection (`canBeRejected`). Resolved and
  Rejected are final (`isClosed`); `IncidentStatus.flow` is the normal path
  without Rejected.
- **Locations:** a fixed list in `AppConstants.campusLocations`.

## Fixed technical decisions
- **State management:** Cubit (`flutter_bloc`) + `equatable` states. Never use
  `setState` for app-wide state. Local, ephemeral widget state (for example a
  password-visibility toggle or a text controller) is fine.
- **Backend:** Firebase Auth (email/password) and Cloud Firestore on the real
  cloud project `campus-incident-app-aedd3`. Firebase Storage (incident photos
  at `incident_photos/{incidentId}.jpg`) runs on the **Firebase Storage
  Emulator**; see "Why the Storage Emulator" below.
- **Roles:** the `role` field on `users/{uid}` is either `"student"` or `"staff"`.
  Sign-up always creates a `student`. Staff accounts are promoted by hand in the
  Firebase console; the app never lets a user choose or change their role.
- **Navigation:** `go_router` with `StatefulShellRoute` shells for each role. The
  redirect logic lives in the pure function `resolveRedirect`
  (`lib/core/router/router_redirect.dart`): unauthenticated → `/login`,
  student → `/home`, staff → `/staff`; students can never reach `/staff*`.
- **Dates:** `intl` (`DateFormatter`). **Photos:** `image_picker`.
- **Tests:** `bloc_test` + `mocktail`.
- Firebase is initialized in `lib/main.dart` with `lib/firebase_options.dart`,
  which `flutterfire configure` generates (the checked-in file is a placeholder
  that throws until you run it).

## Why the Storage Emulator
Firebase requires the Blaze plan for Storage on new projects, so photos are
stored with the official Firebase Storage Emulator, using the same
`firebase_storage` SDK and `storage.rules`. Switching to the cloud bucket only
requires turning off the emulator flag.
- Config: `lib/core/constants/storage_config.dart` (`useEmulator`,
  `emulatorHost` = `10.0.2.2`, `emulatorPort` = `9199`, bucket names).
- `main.dart` calls `useStorageEmulator` on Storage **only**. Auth and
  Firestore always hit the cloud.
- Always get Storage with `FirebaseStorage.instanceFor(bucket:
  StorageConfig.bucketUrl)`, never `FirebaseStorage.instance`, because the
  cloud project has no default bucket.
- Debug builds allow cleartext http for emulator URLs
  (`android/app/src/debug/AndroidManifest.xml`); release builds don't.
- `emulator-data/` holds the exported emulator photos. It is local only
  (git-ignored, not committed).
- Show photos through `StorageConfig.displayUrl(url)`.
- **Photo upload approach:** photos are handled as bytes (`PickedImage`),
  uploaded with `putData` and previewed with `Image.memory`. Don't use
  `File`, `Image.file` or `putFile`.

## Architecture (layered; dependencies only point downward)
```
presentation (screens/widgets) → logic (cubits) → data (repositories) → Firebase
```
- `lib/core/` — `theme/` (colors, text styles, ThemeData), `constants/`,
  `router/`, `utils/` (validators, date formatting)
- `lib/data/` — `models/` (immutable, Equatable, `fromMap`/`fromFirestore`/`toMap`),
  `repositories/` (the only layer that talks to Firebase). Every Firebase error is
  converted into an `AppException` with a user-friendly message.
- `lib/logic/cubits/` — one cubit + state per feature:
  `AuthCubit` (session + profile/role), `AuthFormCubit` (login/sign-up/reset
  submission), `ReportFormCubit`, `MyIncidentsCubit` / `AllIncidentsCubit`
  (share `IncidentListCubit`: live stream + client-side search/filters),
  `IncidentDetailsCubit`, `StatusUpdateCubit`, `IncidentActionsCubit`
  (mark affected / withdraw). `ReportFormCubit` also handles editing when
  given an `editing` incident. Cubits depend on repositories,
  never on Firebase SDKs directly.
- `lib/presentation/` — `screens/`, `widgets/`; UI reads cubit state through
  `BlocBuilder`/`BlocListener` and never calls repositories or Firebase directly.

## Security
`firestore.rules` and `storage.rules` are the real enforcement layer:
- Every signed-in user can read every incident.
- Staff (checked with `get()` on their user doc) update only `status`,
  `updatedAt` and `statusHistory`, only along an allowed transition, appending
  exactly one history entry for the new status. A rejection's entry must have
  a non-empty `comment`.
- The reporter can edit the content fields, or delete the report, only while
  it is `submitted`.
- Other students can add or remove only their own uid in `affectedUserIds`.
- Photos carry `ownerUid` metadata; only the uploader can delete one, and
  none can be overwritten (an edited photo gets a new file name).
- Users can't change their own `role`. Keep the rules in
sync with any data-model change.

## UI
Clean, light design that matches the provided mockup: light background
(`#F6F5FB`), purple primary (`#6C4CF1`) and purple gradient banner, white
rounded cards (20px radius, subtle border, no elevation), rounded 52px-tall
buttons and filled rounded inputs. Status badges: Submitted = amber,
In Progress = blue-purple, Resolved = green, Rejected = red. Take colors and styles from
`AppColors`, `AppTextStyles`, `AppDimens` and `Theme.of(context)`, not
hard-coded values.

## Commands
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `firebase emulators:start --only storage --project campus-incident-app-aedd3 --import=./emulator-data --export-on-exit=./emulator-data`
  (keep it running while using the app)
- `flutter emulators --launch Pixel_8` then `flutter run`
- `firebase deploy --only firestore:rules` (add `,storage` only once a cloud
  bucket exists on the Blaze plan)
