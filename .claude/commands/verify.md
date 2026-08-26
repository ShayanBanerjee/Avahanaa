---
description: Run analyze + tests and report the real result
---

Verify the working tree is in a shippable state.

Run, in order, reporting each result before moving on:

```bash
flutter analyze
flutter test
```

Then report:

1. Exact pass/fail for each command, with the real output for any failure.
2. Whether the changes in `git diff` are covered by any test at all. Coverage in
   this repo is thin — only `test/notification_payload_test.dart` is meaningful
   — so say plainly when passing tests are weak evidence.
3. Anything in the diff that touches the FCM payload contract, the QR URL
   format, or Firestore document shape, since those cross the boundary to the
   out-of-repo backend and to already-printed stickers.

Do not claim success unless both commands exited zero.
