// Optional artifact export: flutter test test/render_preview_test.dart --dart-define=RENDER_PREVIEWS=true
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jelajah_nusa/core/app_state.dart';
import 'package:jelajah_nusa/core/password_hasher.dart';
import 'package:jelajah_nusa/data/catalog.dart';
import 'package:jelajah_nusa/features/auth_screen.dart';
import 'package:jelajah_nusa/features/shell.dart';
import 'package:jelajah_nusa/features/region_screen.dart';
import 'package:jelajah_nusa/features/lesson_screen.dart';
import 'package:jelajah_nusa/features/quiz_screen.dart';
import 'package:jelajah_nusa/features/result_screen.dart';
import 'package:jelajah_nusa/ui/theme.dart';
import 'state_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'export actual Flutter screens with local assets',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.runAsync(() async {
        for (final item in [
          ('NusaSans', 'assets/fonts/NusaSans.ttf'),
          ('NusaSerif', 'assets/fonts/NusaSerif.ttf'),
          ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
        ]) {
          final loader = FontLoader(item.$1)..addFont(rootBundle.load(item.$2));
          await loader.load();
        }
      });
      final catalog = Catalog.fromJson(
        jsonDecode(File('assets/data/content.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final state = (await t.runAsync(() async {
        final state = AppState(
          MemoryStore(),
          catalog,
          hasher: PasswordHasher(iterations: 1000),
        );
        await state.initialize();
        await state.register('Nara', 'nara@example.id', 'Nusantara123');
        await state.finishLesson(catalog.lessons.first.id, 4);
        await state.toggleBookmark('sumbar_rumah_gadang');
        await state.toggleBookmark('yogyakarta_batik');
        await state.visit(catalog.lessons.first.id);
        return state;
      }))!;
      await t.pumpWidget(
        MaterialApp(home: Builder(builder: (context) => const SizedBox())),
      );
      final preloadContext = t.element(find.byType(SizedBox).first);
      final assetPaths = [
        ...catalog.regions.map((r) => r.image),
        'assets/illustrations/hero_nusantara.webp',
        'assets/brand/logo_compass.png',
        ...[
          'langkah_pertama',
          'penjelajah',
          'lintas_daerah',
        ].map((id) => 'assets/badges/$id.png'),
      ];
      await t.runAsync(() async {
        for (final path in assetPaths) {
          await precacheImage(
            AssetImage(path),
            preloadContext,
            onError: (error, stack) => throw StateError('Asset $path: $error'),
          );
        }
      });
      final boundaryKey = GlobalKey();
      Future<void> mount(Widget widget) async {
        await t.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: nusaTheme(),
              home: widget,
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      Future<void> shot(String name) async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await t.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('design/runtime/screens').createSync(recursive: true);
          File(
            'design/runtime/screens/$name.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
        expect(t.takeException(), isNull);
      }

      await mount(AppShell(state: state));
      await shot('01_beranda');
      await t.tap(find.byKey(const Key('nav_jelajah')));
      await t.pumpAndSettle();
      await shot('02_jelajah');
      await t.tap(find.text('Peta'));
      await t.pumpAndSettle();
      await shot('02b_peta');
      await t.tap(find.byKey(const Key('nav_koleksi')));
      await t.pumpAndSettle();
      await shot('07_koleksi');
      await t.tap(find.byKey(const Key('nav_profil')));
      await t.pumpAndSettle();
      await shot('08_profil');
      await mount(RegionScreen(state: state, region: catalog.regions.first));
      await shot('03_daerah');
      await mount(LessonScreen(state: state, lesson: catalog.lessons.first));
      await shot('04_materi');
      await mount(QuizScreen(state: state, lesson: catalog.lessons.first));
      await shot('05_kuis');
      await mount(
        ResultScreen(
          state: state,
          lesson: catalog.lessons.first,
          answers: List.generate(
            5,
            (i) => i == 4
                ? (catalog.lessons.first.questions[i].answer + 1) % 4
                : catalog.lessons.first.questions[i].answer,
          ),
          delta: 40,
          newBadges: const ['langkah_pertama'],
        ),
      );
      await shot('06_hasil');
      await mount(AuthScreen(state: state));
      await shot('09_login');
      await t.ensureVisible(find.byKey(const Key('auth_toggle')));
      await t.tap(find.byKey(const Key('auth_toggle')));
      await t.pumpAndSettle();
      await t.drag(find.byType(SingleChildScrollView), const Offset(0, 800));
      await t.pumpAndSettle();
      await shot('10_daftar');
    },
    skip: !const bool.fromEnvironment('RENDER_PREVIEWS'),
  );
}
