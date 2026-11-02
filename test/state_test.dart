import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jelajah_nusa/core/app_state.dart';
import 'package:jelajah_nusa/core/local_store.dart';
import 'package:jelajah_nusa/core/password_hasher.dart';
import 'package:jelajah_nusa/data/catalog.dart';
import 'package:jelajah_nusa/core/quiz_session.dart';
import 'dart:io';

class MemoryStore implements LocalStore {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('disk full');
    this.value = value;
  }
}

void main() {
  late Catalog catalog;
  late MemoryStore store;
  late AppState state;
  setUp(() async {
    catalog = Catalog.fromJson(
      jsonDecode(File('assets/data/content.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    store = MemoryStore();
    state = AppState(store, catalog, hasher: PasswordHasher(iterations: 1000));
    await state.initialize();
  });
  Future<void> register() =>
      state.register('Nara', 'nara@example.id', 'Nusantara123');

  test('catalog has 3 regions, 9 linked lessons and 45 valid questions', () {
    expect(catalog.regions.length, 3);
    expect(catalog.lessons.length, 9);
    expect(catalog.lessons.expand((l) => l.questions).length, 45);
    expect(catalog.search('  BALI  ', 'Semua').isNotEmpty, true);
    expect(catalog.search('tidak-ada-daerah', 'Semua'), isEmpty);
    expect(catalog.search('', 'Bahasa').length, 3);
  });
  test('fresh install is signed out without example progress', () {
    expect(state.isSignedIn, false);
    expect(state.points, 0);
    expect(state.bookmarks, isEmpty);
  });
  test(
    'registration stores a salted derivation and restores session',
    () async {
      await register();
      expect(state.isSignedIn, true);
      expect(state.name, 'Nara');
      expect(store.value, isNot(contains('Nusantara123')));
      final restored = AppState(
        store,
        catalog,
        hasher: PasswordHasher(iterations: 1000),
      );
      await restored.initialize();
      expect(restored.email, 'nara@example.id');
      expect(restored.name, 'Nara');
    },
  );
  test('logout persists and wrong credentials never open an account', () async {
    await register();
    await state.logout();
    final restored = AppState(
      store,
      catalog,
      hasher: PasswordHasher(iterations: 1000),
    );
    await restored.initialize();
    expect(restored.isSignedIn, false);
    await expectLater(
      restored.login('nara@example.id', 'wrong-password'),
      throwsA(isA<AppException>()),
    );
    expect(restored.isSignedIn, false);
    await restored.login(' NARA@example.id ', 'Nusantara123');
    expect(restored.isSignedIn, true);
  });
  test('duplicate accounts and invalid names/passwords are rejected', () async {
    await expectLater(
      state.register('', 'a@b.id', 'abcdefgh'),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      state.register('Nara', 'not-email', 'abcdefgh'),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      state.register('Nara', 'a@b.id', 'short'),
      throwsA(isA<AppException>()),
    );
    await register();
    await state.logout();
    await expectLater(register(), throwsA(isA<AppException>()));
  });
  test(
    'best score prevents repeat point farming and persists zero completion',
    () async {
      await register();
      final id = catalog.lessons.first.id;
      expect(await state.finishLesson(id, 4), 40);
      expect(await state.finishLesson(id, 4), 0);
      expect(await state.finishLesson(id, 2), 0);
      expect(await state.finishLesson(id, 5), 10);
      expect(state.points, 50);
      expect(state.completedCount, 1);
      await state.finishLesson(catalog.lessons[1].id, 0);
      expect(state.completedCount, 2);
      expect(state.badges, contains('langkah_pertama'));
    },
  );
  test('each account owns separate bookmarks, history and progress', () async {
    await register();
    final id = catalog.lessons.first.id;
    await state.toggleBookmark(id);
    await state.visit(id);
    await state.finishLesson(id, 4);
    await state.logout();
    await state.register('Bima', 'bima@example.id', 'Nusantara456');
    expect(state.bookmarks, isEmpty);
    expect(state.history, isEmpty);
    expect(state.points, 0);
    await state.finishLesson(catalog.lessons.last.id, 2);
    await state.resetProgress();
    await state.logout();
    await state.login('nara@example.id', 'Nusantara123');
    expect(state.points, 40);
    expect(state.bookmarks, [id]);
    expect(state.history, [id]);
  });
  test('history is unique newest first and survives restart', () async {
    await register();
    final a = catalog.lessons[0].id, b = catalog.lessons[1].id;
    await state.visit(a);
    await state.visit(b);
    await state.visit(a);
    expect(state.history, [a, b]);
    final restored = AppState(store, catalog);
    await restored.initialize();
    expect(restored.history, [a, b]);
  });
  test('failed writes roll back changes without false saved status', () async {
    await register();
    final before = store.value;
    store.fail = true;
    await expectLater(
      state.toggleBookmark(catalog.lessons.first.id),
      throwsA(isA<AppException>()),
    );
    expect(state.bookmarks, isEmpty);
    expect(store.value, before);
  });
  test('concurrent actions serialize without losing updates', () async {
    await register();
    await Future.wait(
      catalog.lessons.take(3).map((l) => state.toggleBookmark(l.id)),
    );
    expect(state.bookmarks.length, 3);
  });
  test('corrupt storage blocks initialize without deleting data', () async {
    store.value = '{corrupt';
    final restored = AppState(store, catalog);
    await restored.initialize();
    expect(restored.loadError, isNotNull);
    expect(store.value, '{corrupt');
    await expectLater(
      restored.register('Nara', 'nara@example.id', 'abcdefgh'),
      throwsA(isA<AppException>()),
    );
  });
  test('quiz locks checked answers and counts each submission once', () {
    final q = QuizSession(catalog.lessons.first);
    expect(q.selected, isNull);
    expect(() => q.check(), throwsStateError);
    for (var i = 0; i < 5; i++) {
      q.select(q.question.answer);
      q.check();
      q.check();
      q.select((q.question.answer + 1) % 4);
      expect(q.selected, q.question.answer);
      if (i < 4) q.next();
    }
    expect(q.isFinished, true);
    expect(q.correctCount, 5);
    expect(q.score, 100);
  });
  test(
    'shared preferences adapter reads a committed snapshot after reopening',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = await SharedPrefsStore.open();
      await first.write('{"version":1}');
      final reopened = await SharedPrefsStore.open();
      expect(await reopened.read(), '{"version":1}');
    },
  );
  test('reset clears only progress while preserving current account', () async {
    await register();
    final id = catalog.lessons.first.id;
    await state.rename('Nara Nusantara');
    await state.visit(id);
    await state.toggleBookmark(id);
    await state.finishLesson(id, 5);
    await state.resetProgress();
    expect(state.isSignedIn, true);
    expect(state.name, 'Nara Nusantara');
    expect(state.points, 0);
    expect(state.completedCount, 0);
    expect(state.bookmarks, isEmpty);
    expect(state.history, isEmpty);
    expect(state.badges, isEmpty);
  });
  test(
    'badges correspond to one completed region and all three visited regions',
    () async {
      await register();
      for (final l in catalog.forRegion('bali')) {
        await state.finishLesson(l.id, 1);
      }
      expect(state.badges, containsAll(['langkah_pertama', 'penjelajah']));
      expect(state.badges, isNot(contains('lintas_daerah')));
      await state.finishLesson(catalog.forRegion('yogyakarta').first.id, 0);
      await state.finishLesson(catalog.forRegion('sumatera_barat').first.id, 0);
      expect(state.badges, contains('lintas_daerah'));
    },
  );
  test(
    'failed quiz save cannot mark a lesson complete or award points',
    () async {
      await register();
      store.fail = true;
      await expectLater(
        state.finishLesson(catalog.lessons.first.id, 5),
        throwsA(isA<AppException>()),
      );
      expect(state.completedCount, 0);
      expect(state.points, 0);
    },
  );
  test(
    'identical passwords produce different random salted credentials',
    () async {
      final hasher = PasswordHasher(iterations: 1000);
      final a = await hasher.hash('Nusantara123'),
          b = await hasher.hash('Nusantara123');
      expect(a['salt'], isNot(b['salt']));
      expect(a['hash'], isNot(b['hash']));
      expect(await hasher.verify('Nusantara123', a), true);
      expect(await hasher.verify('incorrect123', a), false);
    },
  );

  // ── Guest mode tests ──────────────────────────────────────────────────────
  test('fresh state is in guest mode (not signed in, ready, no error)',
      () async {
    expect(state.isGuest, true);
    expect(state.isSignedIn, false);
    expect(state.guestLessonCount, 0);
  });

  test('guest can open up to 5 lessons, 6th is denied', () async {
    final ids = catalog.lessons.map((l) => l.id).toList();
    // First 5 should be allowed
    for (var i = 0; i < 5; i++) {
      expect(state.canOpenLesson(ids[i]), true,
          reason: 'lesson $i should be allowed');
      await state.recordGuestLesson(ids[i]);
    }
    expect(state.guestLessonCount, 5);
    // 6th unique lesson should be denied (we only have 9, pick one not yet seen)
    final unseen = ids.firstWhere((id) => !state.guestSeenLessons.contains(id));
    expect(state.canOpenLesson(unseen), false);
  });

  test('opening same lesson again does not consume extra quota', () async {
    final id = catalog.lessons.first.id;
    await state.recordGuestLesson(id);
    await state.recordGuestLesson(id);
    expect(state.guestLessonCount, 1);
    // Already seen lesson is always allowed
    expect(state.canOpenLesson(id), true);
  });

  test('recordGuestLesson persists across app restart', () async {
    final id = catalog.lessons.first.id;
    await state.recordGuestLesson(id);
    final restored = AppState(store, catalog,
        hasher: PasswordHasher(iterations: 1000));
    await restored.initialize();
    expect(restored.guestSeenLessons, contains(id));
    expect(restored.guestLessonCount, 1);
  });

  test('v1 snapshot migrates to v2 with empty guest seenLessons', () async {
    // Write a v1 snapshot
    store.value = jsonEncode({
      'version': 1,
      'accounts': <String, dynamic>{},
      'session': null,
    });
    final migrated = AppState(store, catalog,
        hasher: PasswordHasher(iterations: 1000));
    await migrated.initialize();
    expect(migrated.loadError, isNull);
    expect(migrated.isGuest, true);
    expect(migrated.guestLessonCount, 0);
    // After migrate, store should now be v2
    final stored = jsonDecode(store.value!) as Map<String, dynamic>;
    expect(stored['version'], 2);
    expect(stored['guest'], isA<Map>());
  });

  test('signed-in user can always open any lesson regardless of count',
      () async {
    await register();
    // fill up 5 guest slots first — doesn't apply to signed-in user
    for (final l in catalog.lessons.take(5)) {
      expect(state.canOpenLesson(l.id), true);
    }
    // All 9 lessons accessible
    for (final l in catalog.lessons) {
      expect(state.canOpenLesson(l.id), true);
    }
  });
}

