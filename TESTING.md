# Manual Test Checklist

Run these on the Android emulator after completing the setup in the README
(Firebase configured, Firestore rules deployed, and the **Storage Emulator
running**: see README setup step 4). Automated tests are covered separately
by `flutter test`.

**Test accounts to prepare**

| Account | How to create it |
| --- | --- |
| Student A | Sign up in the app |
| Student B | Sign up in the app (used to check privacy) |
| Staff | Sign up in the app, then in the Firebase console change `users/{uid}.role` to `"staff"` |

---

## 1. Authentication

- [ ] App opens on the splash screen, then shows **Login** when signed out.
- [ ] Login with empty fields shows "Email is required" and "Password is required".
- [ ] Invalid email (e.g. `jane@`) shows "Enter a valid email address".
- [ ] Password shorter than 6 characters shows the minimum-length error.
- [ ] Wrong password shows "Incorrect email or password." in a snackbar.
- [ ] The eye icon toggles password visibility.
- [ ] **Sign Up** with empty fields shows required errors for name, email,
      department, password and confirm password.
- [ ] Mismatched passwords show "Passwords do not match".
- [ ] Signing up with an email that's already registered shows "An account already exists with this email."
- [ ] Successful sign-up lands on the **student Home** screen.
- [ ] In Firestore, the new `users/{uid}` doc has `role: "student"`.
- [ ] **Forgot password?** with a valid email shows the confirmation card and
      a reset email arrives (check spam).
- [ ] Logging out from **Profile** returns to Login; the back button does not
      return to the app.
- [ ] Closing and reopening the app while signed in goes straight to Home.

## 2. Student: home, navigation and profile

- [ ] Home shows "Hello, {first name} 👋" and "Help make our campus safer".
- [ ] The purple gradient banner's **Report an Issue** button opens the report form.
- [ ] Bottom nav: Home, Reports, centre **+** button, Profile all work.
- [ ] Profile shows avatar initial, name, email, department and a **Student** badge.

## 3. Submitting a report without a photo

- [ ] Tapping **Submit Report** on an empty form shows: "Please select a
      category", "Title is required", the description-length error and
      "Please select a location".
- [ ] Selecting a category fills that tile purple and clears its error.
- [ ] Title field stops at 60 characters (counter shows `60/60`).
- [ ] Description under 10 characters is rejected.
- [ ] Fill everything (no photo) and submit: the button shows a spinner and is
      disabled, then the **Report Details** screen opens for the new report.
- [ ] Details show status **Submitted** (amber), the location, the date and
      your name; the timeline has Submitted ✓ with a timestamp.
- [ ] Back returns to where you started; the report is in **Recent Reports**
      and the Summary counts went up.

## 4. Submitting a report with a photo

- [ ] Tap the dashed **Add a photo** box → **Take a photo** (emulator camera) works.
- [ ] Tap again → **Choose from gallery** works.
- [ ] The preview appears; the **×** button removes it.
- [ ] Submit with a photo: "Uploading photo…" appears under the button.
- [ ] Details show the photo at the top and in full under **Photo**.
- [ ] In the Emulator UI (<http://127.0.0.1:9191> → Storage),
      `incident_photos/{incidentId}.jpg` exists, and the Firestore doc's
      `imageUrl` starts with `http://10.0.2.2:9199/`.
- [ ] Stop the emulator with Ctrl+C, restart it with the same command
      (`--import=./emulator-data`), and the photo still loads.

## 5. Search and filter (My Reports and Staff Dashboard)

Create at least three reports with different titles, categories, locations
and statuses first.

- [ ] My Reports header card shows Total / In Progress / Resolved counts.
- [ ] Searching by a word from a **title** narrows the list.
- [ ] Searching by a word from a **description** narrows the list.
- [ ] Searching by a **location** (e.g. "library") narrows the list.
- [ ] Search is case-insensitive; the **×** clears it.
- [ ] Status chips All / Submitted / In Progress / Resolved filter correctly.
- [ ] The filter (tune) button → pick a category: the button turns purple and a
      removable category chip appears; removing it resets the filter.
- [ ] A search with no matches shows "No matching reports".
- [ ] A brand-new student sees the "No reports yet" empty state.
- [ ] A loading spinner shows briefly when the list first opens.

## 6. Student blocked from status updates

- [ ] As a student, Incident Details shows **no** "Update Status" section.
- [ ] Students cannot reach staff screens: the student UI never links to
      `/staff`, and the router sends any student who lands on a staff route
      back to `/home` (covered by `test/unit/router_redirect_test.dart`).
- [ ] Rules check (Firebase console → Firestore → Rules → **Rules Playground**):
      an authenticated **student** `update` on `incidents/{id}` changing
      `status` is **denied**.
- [ ] Rules Playground: a student `update` on their own `users/{uid}` that
      changes `role` to `"staff"` is **denied**.
- [ ] Privacy: Student B does not see Student A's reports in My Reports.

## 7. Staff status update

- [ ] Sign in as the Staff account: you land on the **Staff Dashboard**
      (Dashboard + Profile tabs only) with the **Staff** badge on Profile.
- [ ] Dashboard counts (Total / Submitted / In Progress / Resolved) cover
      **all** students' reports, and each card shows the reporter's name.
- [ ] Search and filters behave the same as in section 5.
- [ ] Open a Submitted report → **Update Status** section → **Mark as In Progress**.
- [ ] A confirmation dialog appears; **Cancel** changes nothing.
- [ ] **Confirm**: the snackbar says "Status updated to In Progress", the badge
      turns blue-purple and the timeline shows In Progress ✓ with a timestamp
      and "by {staff name}".
- [ ] **Mark as Resolved** → confirm: badge turns green; the section now says
      "This report has been resolved." with no button.
- [ ] In Firestore, `statusHistory` has three entries with
      `changedBy`/`changedByName` for the staff member.
- [ ] **Live update:** with the student signed in on a second emulator (or after
      re-login), the student's Details/Home reflect the new status without
      refreshing.
