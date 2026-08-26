---
description: Scaffold a new screen matching this codebase's conventions
argument-hint: [screen name and purpose]
---

Create a new screen for: $ARGUMENTS

Match the existing conventions exactly — read `lib/screens/notifications_screen.dart`
as the reference before writing anything.

Requirements:

- `StatefulWidget` only if it needs local state; otherwise `StatelessWidget`.
  No state-management package.
- Data comes from `FirestoreService` streams via `StreamBuilder`. The screen
  must never touch `FirebaseFirestore.instance` directly. If the data it needs
  has no service method, add one to `FirestoreService`.
- Handle all four stream states: waiting, error, empty, and data. The empty
  state needs real copy, not a blank box.
- Catch `String` throws from service writes and surface them via `SnackBar`.
- Use the theme from `main.dart`. Palette: `#2563EB` primary, `#10B981` success,
  `#DC2626` alert, `#F9FAFB` background, `#1F2937` text, `#E5E7EB` borders.
- Add `AdMobBanner` at the bottom only if this is a main browsing tab — never on
  an alert or acknowledgement flow.
- Verify the layout at 320dp width and 2.0x text scale.

Wire up navigation from wherever it should be reachable, then run
`flutter analyze`.
