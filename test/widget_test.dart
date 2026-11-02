import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jelajah_nusa/app.dart';
import 'package:jelajah_nusa/core/app_state.dart';
import 'package:jelajah_nusa/core/password_hasher.dart';
import 'package:jelajah_nusa/data/catalog.dart';
import 'package:jelajah_nusa/features/region_screen.dart';
import 'package:jelajah_nusa/features/lesson_screen.dart';
import 'package:jelajah_nusa/features/quiz_screen.dart';
import 'package:jelajah_nusa/features/result_screen.dart';
import 'package:jelajah_nusa/ui/theme.dart';
import 'state_test.dart' show MemoryStore;

Future<void> tapAndWait(WidgetTester t, Finder target) async {
  await t.ensureVisible(target);
  await t.pumpAndSettle();
  await t.runAsync(() async {
    await t.tap(target);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
  await t.pumpAndSettle();
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await t.pumpAndSettle();
}

void main() {
  late AppState state;
  testWidgets('rapid lesson opens create only one route', (t) async {
    final s = state;
    final catalog = state.catalog;
    await t.runAsync(
      () => s.register('Nara', 'nara@example.id', 'Nusantara123'),
    );
    await t.pumpWidget(
      MaterialApp(
        theme: nusaTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                openLesson(context, s, catalog.lessons.first);
                openLesson(context, s, catalog.lessons.first);
              },
              child: const Text('Open twice'),
            ),
          ),
        ),
      ),
    );
    await t.runAsync(() async {
      await t.tap(find.text('Open twice'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await t.pumpAndSettle();
    expect(find.byType(LessonScreen, skipOffstage: false), findsOneWidget);
    await tapAndWait(t, find.byTooltip('Kembali'));
    await t.pumpAndSettle();
    expect(find.text('Open twice'), findsOneWidget);
  });
  setUp(() async {
    final catalog = Catalog.fromJson(
      jsonDecode(File('assets/data/content.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    state = AppState(
      MemoryStore(),
      catalog,
      hasher: PasswordHasher(iterations: 1000),
    );
    await state.initialize();
  });
  testWidgets('register, learn, complete quiz, review, bookmark and logout', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(JelajahApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('home_signin_btn')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('auth_toggle')));
    await t.tap(find.byKey(const Key('auth_toggle')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('auth_name')), 'Nara');
    await t.enterText(find.byKey(const Key('auth_email')), 'nara@example.id');
    await t.enterText(find.byKey(const Key('auth_password')), 'Nusantara123');
    await t.ensureVisible(find.byKey(const Key('auth_submit')));
    await t.runAsync(() async {
      await t.tap(find.byKey(const Key('auth_submit')));
      for (var i = 0; i < 200 && !state.isSignedIn; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await t.pumpAndSettle();
    expect(find.text('Daerah pilihan'), findsOneWidget);
    await tapAndWait(t, find.byKey(const Key('home_bali')));
    await t.pumpAndSettle();
    final lesson = state.catalog.forRegion('bali').first;
    await t.ensureVisible(find.byKey(Key('lesson_${lesson.id}')));
    await tapAndWait(t, find.byKey(Key('lesson_${lesson.id}')));
    await t.pumpAndSettle();
    await tapAndWait(t, find.byTooltip('Simpan materi'));
    await t.pumpAndSettle();
    expect(state.bookmarks, contains(lesson.id));
    await t.ensureVisible(find.byKey(const Key('start_quiz')));
    await tapAndWait(t, find.byKey(const Key('start_quiz')));
    await t.pumpAndSettle();
    expect(
      t.widget<FilledButton>(find.byKey(const Key('quiz_action'))).onPressed,
      isNull,
    );
    for (var i = 0; i < 5; i++) {
      await t.ensureVisible(
        find.byKey(Key('answer_${lesson.questions[i].answer}')),
      );
      await tapAndWait(
        t,
        find.byKey(Key('answer_${lesson.questions[i].answer}')),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('quiz_action')));
      await tapAndWait(t, find.byKey(const Key('quiz_action')));
      await t.pumpAndSettle();
      expect(find.text('Benar, langkah yang baik!'), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('quiz_action')));
      await tapAndWait(t, find.byKey(const Key('quiz_action')));
      await t.pumpAndSettle();
    }
    expect(find.text('Hasil belajarmu'), findsOneWidget);
    expect(state.points, 50);
    expect(state.completedCount, 1);
    await t.ensureVisible(find.text('Lihat pembahasan jawaban'));
    await tapAndWait(t, find.text('Lihat pembahasan jawaban'));
    await t.pumpAndSettle();
    expect(find.text('Pembahasan kuis'), findsOneWidget);
    await tapAndWait(t, find.byTooltip('Kembali'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Lanjutkan jelajah'));
    await tapAndWait(t, find.text('Lanjutkan jelajah'));
    await t.pumpAndSettle();
    await tapAndWait(t, find.byTooltip('Kembali'));
    await t.pumpAndSettle();
    await tapAndWait(t, find.byKey(const Key('nav_profil')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Keluar akun'));
    await tapAndWait(t, find.text('Keluar akun'));
    await t.pumpAndSettle();
    await tapAndWait(t, find.byKey(const Key('confirm_action')));
    await t.pumpAndSettle();
    expect(state.isSignedIn, false);
    expect(state.isGuest, true);
    expect(find.byKey(const Key('home_signin_btn')), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  for (final width in [320.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.3, 1.5]) {
      testWidgets('responsive screens width $width text $scale', (t) async {
        t.view.physicalSize = Size(width, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        Widget scaled(Widget child) => MediaQuery(
          data: MediaQueryData(
            size: Size(width, 844),
            textScaler: TextScaler.linear(scale),
          ),
          child: child,
        );
        await t.pumpWidget(JelajahApp(state: state, wrapper: scaled));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await t.runAsync(
          () => state.register(
            'Penjelajah Nusantara',
            'nara@example.id',
            'Nusantara123',
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        for (final id in ['jelajah', 'koleksi', 'profil', 'beranda']) {
          await t.tap(find.byKey(Key('nav_$id')));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        }
        final l = state.catalog.lessons.first;
        for (final page in [
          RegionScreen(state: state, region: state.catalog.regions.first),
          LessonScreen(state: state, lesson: l),
          QuizScreen(state: state, lesson: l),
          ResultScreen(
            state: state,
            lesson: l,
            answers: l.questions.map((q) => q.answer).toList(),
            delta: 50,
          ),
        ]) {
          await t.pumpWidget(
            MaterialApp(theme: nusaTheme(), home: scaled(page)),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        }
      });
    }
  }
  testWidgets('leaving unfinished quiz asks before discarding', (t) async {
    await t.runAsync(
      () => state.register('Nara', 'nara@example.id', 'Nusantara123'),
    );
    await t.pumpWidget(
      MaterialApp(
        theme: nusaTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => QuizScreen(
                    state: state,
                    lesson: state.catalog.lessons.first,
                  ),
                ),
              ),
              child: const Text('Mulai'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Mulai'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Tutup kuis'));
    await t.pumpAndSettle();
    expect(find.text('Keluar dari kuis?'), findsOneWidget);
    await t.tap(find.text('Batal'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('quiz_action')), findsOneWidget);
    expect(state.completedCount, 0);
  });

  testWidgets('guest mode explores home, map, collection gate, and profile', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(JelajahApp(state: state));
    await t.pumpAndSettle();

    // Verifies guest state on Home
    expect(find.byKey(const Key('home_signin_btn')), findsOneWidget);
    expect(find.text('0/5 materi dijelajahi'), findsOneWidget);

    // Navigates to Koleksi (verifies gate)
    await t.tap(find.byKey(const Key('nav_koleksi')));
    await t.pumpAndSettle();
    expect(find.text('Koleksi membutuhkan akun'), findsOneWidget);
    expect(find.byKey(const Key('collection_signin_btn')), findsOneWidget);

    // Navigates to Profil (verifies guest profile)
    await t.tap(find.byKey(const Key('nav_profil')));
    await t.pumpAndSettle();
    expect(find.text('Penjelajah Tamu'), findsOneWidget);
    expect(find.text('Mode tamu · Tanpa akun'), findsOneWidget);
    expect(find.byKey(const Key('guest_create_account')), findsOneWidget);

    // Navigates to Jelajah (verifies TabBar with Daftar and Peta)
    await t.tap(find.byKey(const Key('nav_jelajah')));
    await t.pumpAndSettle();
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Peta'), findsOneWidget);

    // Switches to Peta tab
    await t.tap(find.text('Peta'));
    await t.pumpAndSettle();
    expect(find.text('Peta Nusantara'), findsOneWidget);
    expect(find.text('38 provinsi'), findsOneWidget);
  });

  testWidgets('guest quota dialog blocks 6th lesson and bookmark triggers auth dialog', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(JelajahApp(state: state));
    await t.pumpAndSettle();

    // Open first lesson as guest
    final firstLesson = state.catalog.lessons.first;
    await tapAndWait(t, find.byKey(const Key('home_bali')));
    await t.pumpAndSettle();
    await tapAndWait(t, find.byKey(Key('lesson_${firstLesson.id}')));
    await t.pumpAndSettle();

    // Verify bookmark as guest prompts auth dialog
    await tapAndWait(t, find.byTooltip('Simpan materi'));
    await t.pumpAndSettle();
    expect(find.text('Simpan ke Koleksi'), findsOneWidget);
    await tapAndWait(t, find.text('Nanti saja'));
    await t.pumpAndSettle();

    // Go back to home
    await tapAndWait(t, find.byTooltip('Kembali'));
    await t.pumpAndSettle();
    await tapAndWait(t, find.byTooltip('Kembali'));
    await t.pumpAndSettle();

    // Fill up remaining 4 slots
    await t.runAsync(() async {
      for (final l in state.catalog.lessons.skip(1).take(4)) {
        await state.recordGuestLesson(l.id);
      }
    });
    expect(state.guestLessonCount, 5);

    // Now try to open 6th unique lesson
    final sixthLesson = state.catalog.lessons[5];
    openLesson(t.element(find.byKey(const Key('nav_beranda'))), state, sixthLesson);
    await t.pumpAndSettle();

    expect(find.text('Batas jelajah tamu tercapai'), findsOneWidget);
    await t.tap(find.text('Kembali'));
    await t.pumpAndSettle();
  });
}
