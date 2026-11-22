import 'dart:math';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_residente/core/ui.dart';

/// WCAG relative luminance of a color.
double _luminance(Color c) {
  double lin(double v) => v <= 0.03928
      ? v / 12.92
      : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

/// WCAG contrast ratio between two colors (1..21).
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = max(la, lb);
  final lo = min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// The 12% tint StatusChip paints behind its label.
Color _tint(Color tone, Color background) => Color.lerp(background, tone, 0.12)!;

void main() {
  group('Accessibility (Android Content_Description)', () {
    testWidgets('StatusChip is announced as a single labelled node',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusChip(label: 'En mantenimiento', color: bfWarning),
        ),
      ));

      expect(find.bySemanticsLabel('En mantenimiento'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('reserve button exposes its disabled state', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppOutlinedActionButton(
            text: 'Reservar',
            enabled: false,
            onPressed: null,
          ),
        ),
      ));

      final node = tester.getSemantics(find.byType(OutlinedButton));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'a disabled button must not advertise a tap action',
      );
      handle.dispose();
    });

    testWidgets('reserve button advertises a tap action when enabled',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppOutlinedActionButton(
            text: 'Reservar',
            enabled: true,
            onPressed: () {},
          ),
        ),
      ));

      final node = tester.getSemantics(find.byType(OutlinedButton));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'an enabled button must be actionable by TalkBack',
      );
      handle.dispose();
    });
  });

  group('Theme_Support (light/dark)', () {
    test('surfaces follow the requested brightness', () {
      expect(buildTheme().scaffoldBackgroundColor, bfSurface);
      expect(buildTheme().cardTheme.color, Colors.white);

      final dark = buildTheme(brightness: Brightness.dark);
      expect(dark.scaffoldBackgroundColor, bfSurfaceDark);
      expect(dark.cardTheme.color, bfCardDark);
      expect(dark.colorScheme.brightness, Brightness.dark);
    });

    test('bottom-sheet/card color switches with brightness', () {
      expect(bfCardColor(Brightness.light), Colors.white);
      expect(bfCardColor(Brightness.dark), bfCardDark);
    });
  });

  group('Visual_Contrast (4.5:1 for small text)', () {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final background =
          brightness == Brightness.light ? Colors.white : bfCardDark;
      final toneName = brightness == Brightness.light ? 'light' : 'dark';

      test('warning chip text meets 4.5:1 in $toneName mode', () {
        final tone = bfWarningText(brightness);
        expect(_contrast(tone, _tint(tone, background)),
            greaterThanOrEqualTo(4.5));
        expect(_contrast(tone, background), greaterThanOrEqualTo(4.5));
      });

      test('success chip text meets 4.5:1 in $toneName mode', () {
        final tone = bfSuccessText(brightness);
        expect(_contrast(tone, _tint(tone, background)),
            greaterThanOrEqualTo(4.5));
        expect(_contrast(tone, background), greaterThanOrEqualTo(4.5));
      });
    }

    test('raw warning orange stays valid for large (20 sp bold) text', () {
      expect(_contrast(bfWarning, Colors.white), greaterThanOrEqualTo(3.0));
      expect(_contrast(bfWarning, bfCardDark), greaterThanOrEqualTo(3.0));
    });
  });
}
