import 'package:avahanaa/models/vehicle_model.dart';
import 'package:avahanaa/theme/app_theme.dart';
import 'package:avahanaa/widgets/hero_header.dart';
import 'package:avahanaa/widgets/qr_visual.dart';
import 'package:avahanaa/widgets/ui_kit.dart';
import 'package:avahanaa/widgets/vehicle_panel.dart';
import 'package:flutter/material.dart';
import 'package:avahanaa/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The design system requires every surface to survive 320dp width and heavy
/// system font scaling — `qr_code_screen` and `profile_screen` have both
/// regressed on this before. These tests pump the shared components at the
/// worst case and fail if the framework reports an overflow.

/// Narrowest phone width the app targets.
const Size kNarrowPhone = Size(320, 640);

Future<void> pumpAtScale(
  WidgetTester tester,
  Widget child, {
  double textScale = 1.0,
  Size size = kNarrowPhone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        theme: AvahanaaTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump(Duration(seconds: 1));
}

void expectNoOverflow(WidgetTester tester) {
  expect(
    tester.takeException(),
    isNull,
    reason: 'a layout overflowed at this width or text scale',
  );
}

void main() {
  // 1.6 is the ceiling main.dart clamps system scaling to; 2.0 is tested too
  // so the components stay safe if that clamp is ever raised.
  for (final scale in <double>[1.0, 1.3, 1.6, 2.0]) {
    group('at ${scale}x text scale on a 320dp screen', () {
      testWidgets('PlateBadge renders a long registration number', (
        tester,
      ) async {
        await pumpAtScale(
          tester,
          PlateBadge(plate: 'KA01AB1234'),
          textScale: scale,
        );
        expectNoOverflow(tester);
        expect(find.text('KA01AB1234'), findsOneWidget);
      });

      testWidgets('three AppStatTiles fit side by side', (tester) async {
        await pumpAtScale(
          tester,
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppStatTile(
                    icon: Icons.mark_email_unread_rounded,
                    value: '128',
                    label: 'Unread alerts',
                  ),
                ),
                Expanded(
                  child: AppStatTile(
                    icon: Icons.directions_car_rounded,
                    value: '4',
                    label: 'Vehicles',
                  ),
                ),
                Expanded(
                  child: AppStatTile(
                    icon: Icons.verified_user_rounded,
                    value: 'On',
                    label: 'Protection',
                  ),
                ),
              ],
            ),
          ),
          textScale: scale,
        );
        expectNoOverflow(tester);
      });

      testWidgets('AppListRow handles a long title and subtitle', (
        tester,
      ) async {
        await pumpAtScale(
          tester,
          AppCard(
            padding: EdgeInsets.zero,
            child: AppListRow(
              icon: Icons.policy_rounded,
              title: 'Legal and privacy documents',
              subtitle:
                  'Privacy policy, terms of service, and how long we keep '
                  'your alert history',
            ),
          ),
          textScale: scale,
        );
        expectNoOverflow(tester);
      });

      testWidgets('NumberedStep wraps long guidance', (tester) async {
        await pumpAtScale(
          tester,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NumberedStep(
                  number: '1',
                  title: 'Print the sticker on white paper',
                  detail:
                      'Do not scale it down — the code needs its white '
                      'margin to stay scannable through glass.',
                ),
                NumberedStep(
                  number: '2',
                  title: 'Fix it inside the windshield',
                  detail: 'Driver-side corner, facing out.',
                  isLast: true,
                ),
              ],
            ),
          ),
          textScale: scale,
        );
        expectNoOverflow(tester);
      });

      testWidgets('StatusPill row stays inside the card', (tester) async {
        await pumpAtScale(
          tester,
          AppCard(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                StatusPill(
                  label: 'QR ACTIVE',
                  color: AppColors.success,
                  icon: Icons.qr_code_rounded,
                ),
                StatusPill(
                  label: 'PRIMARY',
                  color: AppColors.primary,
                  icon: Icons.star_rounded,
                ),
              ],
            ),
          ),
          textScale: scale,
        );
        expectNoOverflow(tester);
      });

      testWidgets('the vehicle carousel survives a full fleet', (tester) async {
        await pumpAtScale(
          tester,
          HeroSurface(
            child: VehicleCarousel(
              vehicles: _fleet,
              selected: _fleet.first,
              isLive: true,
              onSelect: (_) {},
            ),
          ),
          textScale: scale,
        );
        expectNoOverflow(tester);
        expect(find.text('Vehicle 1 of 3'), findsOneWidget);
      });

      testWidgets('a single vehicle renders without the position rail', (
        tester,
      ) async {
        await pumpAtScale(
          tester,
          HeroSurface(
            child: VehicleCarousel(
              vehicles: <VehicleModel>[_fleet.first],
              selected: _fleet.first,
              isLive: false,
              onSelect: (_) {},
            ),
          ),
          textScale: scale,
        );
        expectNoOverflow(tester);
        expect(find.textContaining('Vehicle 1 of'), findsNothing);
      });

      testWidgets('the QR panel fits with all three actions', (tester) async {
        await pumpAtScale(
          tester,
          QrShowcasePanel(
            data: 'https://avahanaa.com/n/qr-abc123def456',
            isActive: true,
            plate: 'KA01AB1234',
            descriptor: 'White Maruti Swift Dzire VXi',
            codeSize: 150,
            actions: [
              QrPanelAction(
                icon: Icons.print_rounded,
                label: 'Print',
                onPressed: () {},
              ),
              QrPanelAction(
                icon: Icons.link_rounded,
                label: 'Copy link',
                onPressed: () {},
              ),
              QrPanelAction(
                icon: Icons.auto_awesome_rounded,
                label: 'Design',
                onPressed: () {},
              ),
            ],
          ),
          textScale: scale,
        );
        expectNoOverflow(tester);
        expect(find.text('LIVE'), findsOneWidget);
      });

      testWidgets('AppEmptyState fits with an action button', (tester) async {
        await pumpAtScale(
          tester,
          SizedBox(
            height: 560,
            child: AppEmptyState(
              icon: Icons.shield_moon_rounded,
              title: 'Nothing to worry about',
              message:
                  'No one has needed to reach you about your vehicle. When '
                  'someone scans your code, the alert lands here.',
              action: ElevatedButton(
                onPressed: () {},
                child: const Text('Go to Profile'),
              ),
            ),
          ),
          textScale: scale,
        );
        expectNoOverflow(tester);
      });
    });
  }

  group('PlateBadge', () {
    testWidgets('uppercases the plate and hides when empty', (tester) async {
      await pumpAtScale(tester, const PlateBadge(plate: ' ka01ab1234 '));
      expect(find.text('KA01AB1234'), findsOneWidget);

      await pumpAtScale(tester, const PlateBadge(plate: '   '));
      expect(find.byType(Text), findsNothing);
    });
  });

  group('showAppSnackBar', () {
    testWidgets('renders one snackbar per call', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: AvahanaaTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppSnackBar(
                  ScaffoldMessenger.of(context),
                  'Vehicle saved',
                  kind: AppSnackKind.success,
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Vehicle saved'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

/// Three vehicles with awkward values: a long descriptor, an empty one, and a
/// plate that is missing entirely.
final List<VehicleModel> _fleet = <VehicleModel>[
  VehicleModel(
    id: 'v1',
    userId: 'u1',
    color: 'Pearl White',
    carModel: 'Maruti Suzuki Swift Dzire VXi',
    licensePlate: 'KA01AB1234',
  ),
  VehicleModel(id: 'v2', userId: 'u1', licensePlate: 'KA05MN9012'),
  VehicleModel(id: 'v3', userId: 'u1', color: 'Black', carModel: 'Thar'),
];
