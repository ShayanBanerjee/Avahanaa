# Multi-Vehicle Support: Schema, Migration, and Code Change Plan

## Target outcome

- One user can own multiple vehicles.
- Each vehicle has its own QR identity.
- Scanning a QR resolves to one exact vehicle, then routes to owner user.
- Notifications stay grouped by user, but include vehicle context.

## Proposed Firestore schema

### 1) `users/{userId}`

Keep user/account level fields only:

```json
{
  "email": "owner@example.com",
  "phoneNumber": "+1...",
  "fcmToken": "...",
  "notificationsEnabled": true,
  "primaryVehicleId": "veh_abc123",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Notes:
- `primaryVehicleId` is optional but useful for default selection.
- Keep legacy `carDetails` and `qrCodeId` during migration window only.

### 2) `users/{userId}/vehicles/{vehicleId}`

Vehicle-scoped identity and display data:

```json
{
  "userId": "ownerUserId",
  "color": "White",
  "carModel": "Honda City",
  "licensePlate": "PB65AM0008",
  "licensePlateNormalized": "PB65AM0008",
  "assetNumber": "PB65AM0008",
  "qrCodeId": "qr_xyz789",
  "isActive": true,
  "notificationsEnabled": true,
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "migratedFromLegacy": true
}
```

Notes:
- `qrCodeId` is now vehicle-scoped.
- `notificationsEnabled` can be per-vehicle; keep user-level toggle as global master switch if needed.

### 3) `qrCodes/{qrCodeId}`

QR code document should point to both owner and vehicle:

```json
{
  "userId": "ownerUserId",
  "vehicleId": "veh_abc123",
  "isActive": true,
  "payloadVersion": "3",
  "payload": "https://avahanaa.com/index.html?page=notify&qr=qr_xyz789&v=3",
  "shareableLink": "https://...",
  "metadata": {
    "payloadVersion": "3",
    "qrCodeId": "qr_xyz789",
    "userId": "ownerUserId",
    "vehicleId": "veh_abc123",
    "contact": {
      "email": "owner@example.com",
      "phoneNumber": "+1..."
    },
    "vehicle": {
      "color": "White",
      "carModel": "Honda City",
      "licensePlate": "PB65AM0008"
    }
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 4) `notifications/{notificationId}`

Add `vehicleId` (keep existing fields):

```json
{
  "qrCodeId": "qr_xyz789",
  "userId": "ownerUserId",
  "vehicleId": "veh_abc123",
  "reason": "blocking_driveway",
  "message": "...",
  "status": "sent",
  "read": false,
  "sentAt": "timestamp",
  "readAt": null
}
```

## Rollout strategy (safe + backward compatible)

### Phase 0: Prepare app for dual-read

- Add new `VehicleModel`.
- Read vehicles subcollection when available.
- Fallback to legacy `user.carDetails` + `user.qrCodeId` when no vehicle docs exist.

### Phase 1: Dual-write

- Any vehicle edit/create updates vehicle doc.
- Also update legacy user fields for one release window (compatibility).
- QR metadata sync writes `vehicleId` in `qrCodes`.

### Phase 2: Backfill migration

Run one admin migration job:

1. Iterate `users`.
2. For each user, if legacy `carDetails`/`qrCodeId` exists and no vehicle docs:
- Create `users/{userId}/vehicles/{vehicleId}` from legacy car fields.
- Move/copy `qrCodeId` onto vehicle doc.
- Patch `qrCodes/{qrCodeId}` with `vehicleId`, `userId`, `payloadVersion=3`, refreshed metadata.
- Set `users/{userId}.primaryVehicleId` if absent.

### Phase 3: Read cutover

- UI and services use vehicle docs as primary source.
- Notify flow resolves `qrCodeId -> qrCodes doc -> vehicleId + userId`.

### Phase 4: Cleanup

- Stop writing legacy `users.carDetails` and `users.qrCodeId`.
- Remove legacy fields after monitoring period.

## Migration pseudocode (Admin SDK job)

```js
for each user in users:
  vehicles = list users/{userId}/vehicles
  legacyCar = user.carDetails
  legacyQr = user.qrCodeId

  if vehicles is empty and (legacyCar exists or legacyQr exists):
    vehicleRef = users/{userId}/vehicles/{autoId}
    write vehicleRef {
      userId, color, carModel, licensePlate, licensePlateNormalized,
      assetNumber, qrCodeId: legacyQr ?? "", isActive: true,
      notificationsEnabled: user.notificationsEnabled ?? true,
      migratedFromLegacy: true, createdAt, updatedAt
    }

    if user.primaryVehicleId missing:
      update users/{userId}.primaryVehicleId = vehicleRef.id

    if legacyQr exists:
      update qrCodes/{legacyQr} with {
        userId, vehicleId: vehicleRef.id, payloadVersion: "3", updatedAt
      }
```

Operational advice:
- Run in idempotent batches.
- Log per-user success/failure.
- Support resume checkpoint.

## App code changes needed (this repo)

## 1) Add vehicle model

Create:
- `lib/models/vehicle_model.dart`

Fields to include:
- `id`, `userId`, `color`, `carModel`, `licensePlate`, `assetNumber`, `qrCodeId`, `isActive`, `notificationsEnabled`, `createdAt`, `updatedAt`.

## 2) Update user model

File:
- `lib/models/user_model.dart`

Changes:
- Add `primaryVehicleId`.
- Keep legacy `carDetails` and `qrCodeId` as deprecated compatibility fields until cleanup.
- Add helper for backward-compat conversion to an initial vehicle object when needed.

## 3) Update QR payload builder to vehicle scope

File:
- `lib/utils/qr_payload_builder.dart`

Current issue:
- Uses `UserModel` only and injects `user.qrCodeId`.

Change to:
- `buildPayload({required UserModel user, required VehicleModel vehicle})`
- `buildMetadata({required UserModel user, required VehicleModel vehicle})`
- Query `qr` must come from `vehicle.qrCodeId`.
- Metadata must include `vehicleId`.
- Bump payload version from `2` to `3`.

## 4) Firestore service: vehicle CRUD + QR by vehicle

File:
- `lib/services/firestore_service.dart`

Add:
- `Stream<List<VehicleModel>> streamUserVehicles(String userId)`
- `Future<void> upsertVehicle(String userId, VehicleModel vehicle)`
- `Future<void> deleteVehicle(String userId, String vehicleId)`
- `Future<void> setPrimaryVehicle(String userId, String vehicleId)`
- `Future<String> ensureVehicleQrCode(UserModel user, VehicleModel vehicle)`
- `Future<void> syncVehicleQrMetadata(...)`
- `Future<void> toggleVehicleQRCodeStatus(...)`

Change:
- Notification queries remain by `userId`, but add optional `vehicleId` filter methods for per-vehicle views.

## 5) Auth service: stop seeding legacy car fields for new users

File:
- `lib/services/auth_service.dart`

Current:
- `_createUserDocument` writes `qrCodeId` and `carDetails`.

Change:
- Write only user fields + `primaryVehicleId: null`.
- After signup, create first vehicle doc from signup form data.

## 6) Signup flow: create initial vehicle document

File:
- `lib/screens/auth/signup_screen.dart`

Change:
- Keep collecting registration/color/model.
- After user creation, call new `upsertVehicle` to create initial vehicle and set primary vehicle.
- Generate QR for that vehicle, not user.

## 7) Home screen: selected vehicle QR

File:
- `lib/screens/home_screen.dart`

Change:
- Load vehicle list stream.
- Select `primaryVehicleId` (or first vehicle).
- Show QR card for selected vehicle.
- Generate/sync QR metadata using selected vehicle.

## 8) QR screen: accept vehicle + owner

File:
- `lib/screens/qr_code_screen.dart`

Change constructor:
- From `QRCodeScreen(user: user)` to `QRCodeScreen(user: user, vehicle: vehicle)`.

Change logic:
- License/model/color from `vehicle`.
- QR payload/link built from `(user, vehicle)`.

## 9) Profile screen: vehicle list instead of single car

File:
- `lib/screens/profile_screen.dart`

Change:
- Replace single “Car Details” tile with:
  - vehicle list cards,
  - add vehicle,
  - edit/delete vehicle,
  - mark primary vehicle.
- Existing edit dialog can be reused as per-vehicle editor.

## 10) Notification model includes vehicle ID

File:
- `lib/models/notification_model.dart`

Change:
- Add `vehicleId`.
- Parse/write it in `fromFirestore`, `toMap`, `copyWith`.

## 11) Delete-account flow cleans all vehicle QR docs

File:
- `lib/services/auth_service.dart`

Current:
- Deletes single `qrCodeId`.

Change:
- Enumerate `users/{userId}/vehicles` and delete each linked `qrCodes/{qrCodeId}` before deleting user.

## Backend/API changes (outside this repo)

Wherever QR scans are resolved and notifications are sent:

- Resolve with `qrCodes/{qrCodeId}`.
- Require `isActive == true`.
- Use `userId` + `vehicleId` from QR doc.
- Write notification with both IDs.
- Include vehicle details in push payload for clarity.

## Suggested Firestore indexes

- `notifications`: `(userId ASC, sentAt DESC)`
- `notifications`: `(userId ASC, read ASC)`
- `notifications`: `(userId ASC, vehicleId ASC, sentAt DESC)`
- Optional vehicle lookup/reporting: `qrCodes(vehicleId ASC)`

## Testing checklist

- New signup creates one vehicle and one QR for that vehicle.
- Add second vehicle creates distinct QR and distinct `qrCodeId`.
- Scanning each QR lands notification with correct `vehicleId`.
- Toggle one vehicle inactive only disables that vehicle QR.
- Legacy user (single `carDetails`) is auto-migrated and still functional.
- Delete account removes all user vehicles and all linked QR docs.
