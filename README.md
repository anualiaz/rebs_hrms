# REBS HRMS – Flutter Assignment

Offline-capable employee workspace built with Flutter, Provider, SQLite and a local HTTP mock API.

## Create / run
```bash
flutter create --org com.rebs rebs_hrms
# Copy this source into the generated project (or use this archive as the project source).
flutter pub get
node mock_api/server.js
flutter run
```
Android emulator API URL defaults to `http://10.0.2.2:3000`. For a physical device, run the Node server on the same Wi-Fi and launch with:
```bash
flutter run --dart-define=API_URL=http://YOUR_COMPUTER_LAN_IP:3000
```
The configured mock office is `9.974696, 76.487026`; update `employee` in `mock_api/server.js` to your test office. The office radius is 200 metres.

## Architecture
- `ui/`: dashboard and leave form.
- `state/`: Provider state and lifecycle.
- `data/`: HTTP API, SQLite persistence and repository/business rules.
- `models/`: typed domain models.
- `mock_api/`: repeatable Node HTTP mock server.

## Offline and idempotency decisions
Attendance events are stored in SQLite before any network request. Each event receives a UUID, used as the server idempotency key. Pending events are read oldest-first. A successful response marks the event synced; a definite 4xx response marks it rejected. A timeout/network exception leaves it pending and retries the exact same UUID, so the server must treat repeated IDs as the same operation. Check-in/check-out order is preserved by timestamp order.

The sample mock server stores event IDs in a Map and returns success for a replayed ID. For a real backend, enforce a unique constraint on employee ID + event UUID and validate daily attendance state transactionally.

## Mock scenarios
- Normal success: default server.
- Slow response/timeout: append `?scenario=slow` to endpoint URL in `HrmsApi` while testing.
- Server error: append `?scenario=error`.
- Duplicate conflict: append `?scenario=duplicate` to attendance event POST.
- Leave validation rejection: append `?scenario=leave-reject` to leave POST.
  The scenario query can be added to the relevant path in `HrmsApi` for repeatable testing.

## Android permissions
Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```
For Android 10+ background location is not required because attendance location is requested while the app is in use.

## Important production server checks
The server must repeat employee identity, office geofence, timestamp/timezone, daily check-in/out state, event ordering, duplicate/idempotency, and leave balance/date-overlap validations. Device-side checks are only UX validation and must not be trusted for payroll decisions.

## Tests
```bash
flutter test
```
The included tests cover core rule concepts and a loading widget. Expand repository tests with an in-memory SQLite database and fake HTTP client before production submission.

## Assignment scope / known limitations
- Login is intentionally excluded; one preconfigured employee is used.
- Background sync after app termination is excluded per assignment.
- Leave submission requires network connectivity.
- Configure the mock API and office coordinates for the reviewer environment.
- The demo implementation uses local device time; production must apply company timezone consistently on both client and server.
- Add a production-grade retry/backoff policy, secure employee authentication, and server-side transactional enforcement before deployment.



