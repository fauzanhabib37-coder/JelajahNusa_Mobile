import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/catalog.dart';
import 'local_store.dart';
import 'password_hasher.dart';

class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

class AppState extends ChangeNotifier {
  final LocalStore store;
  final Catalog catalog;
  final PasswordHasher hasher;
  Map<String, dynamic> _snapshot = {
    'version': 2,
    'guest': {'seenLessons': <String>[]},
    'accounts': <String, dynamic>{},
    'session': null,
  };
  Future<void> _tail = Future<void>.value();
  String? loadError;
  bool ready = false;
  AppState(this.store, this.catalog, {PasswordHasher? hasher})
    : hasher = hasher ?? PasswordHasher();
  Map<String, dynamic> get _accounts =>
      _snapshot['accounts'] as Map<String, dynamic>;
  String? get _session => _snapshot['session'] as String?;
  bool get isSignedIn =>
      ready &&
      loadError == null &&
      _session != null &&
      _accounts.containsKey(_session);

  /// Guest mode: app is ready, no error, and not signed in.
  bool get isGuest => ready && loadError == null && !isSignedIn;

  Map<String, dynamic>? get _account =>
      isSignedIn ? _accounts[_session] as Map<String, dynamic> : null;
  Map<String, dynamic> get _progress =>
      (_account?['progress'] as Map<String, dynamic>?) ?? _emptyProgress();
  String get name => _account?['name'] as String? ?? '';
  String get email => _session ?? '';
  Map<String, int> get best => Map<String, int>.unmodifiable(
    Map<String, int>.from(_progress['best'] as Map),
  );
  List<String> get bookmarks =>
      List<String>.unmodifiable(_progress['bookmarks'] as List);
  List<String> get history =>
      List<String>.unmodifiable(_progress['history'] as List);
  int get points => best.values.fold(0, (sum, n) => sum + n * 10);
  int get completedCount => best.length;
  bool completed(String id) => best.containsKey(id);
  int completedIn(String regionId) =>
      catalog.forRegion(regionId).where((l) => completed(l.id)).length;
  List<String> get badges => [
    if (completedCount > 0) 'langkah_pertama',
    if (catalog.regions.any(
      (r) => completedIn(r.id) == catalog.forRegion(r.id).length,
    ))
      'penjelajah',
    if (catalog.regions.every((r) => completedIn(r.id) > 0)) 'lintas_daerah',
  ];
  static Map<String, dynamic> _emptyProgress() => {
    'best': <String, dynamic>{},
    'bookmarks': <String>[],
    'history': <String>[],
  };

  // ── Guest tracking ─────────────────────────────────────────────────────────
  static const guestLimit = 5;

  Map<String, dynamic> get _guest =>
      _snapshot['guest'] as Map<String, dynamic>? ?? {'seenLessons': <String>[]};

  List<String> get guestSeenLessons =>
      List<String>.unmodifiable((_guest['seenLessons'] as List).cast<String>());

  int get guestLessonCount => guestSeenLessons.length;

  /// Returns true if the user can open [id]:
  /// - signed-in users can always open any lesson
  /// - guests can open if already seen OR count < guestLimit
  bool canOpenLesson(String id) {
    if (isSignedIn) return true;
    if (guestSeenLessons.contains(id)) return true;
    return guestLessonCount < guestLimit;
  }

  /// Records that a guest opened [id]. No-op if already recorded or signed in.
  Future<void> recordGuestLesson(String id) async {
    if (isSignedIn) return;
    if (guestSeenLessons.contains(id)) return;
    await _edit<void>((draft) {
      final guestMap = draft['guest'] as Map<String, dynamic>;
      final seen = (guestMap['seenLessons'] as List).cast<String>();
      if (!seen.contains(id)) seen.add(id);
    });
  }

  Future<void> initialize() async {
    try {
      final raw = await store.read();
      if (raw != null) {
        final parsed = jsonDecode(raw);
        final wasV1 = parsed is Map && parsed['version'] == 1;
        _validate(parsed);
        _snapshot = parsed as Map<String, dynamic>;
        if (wasV1) {
          try {
            await store.write(jsonEncode(_snapshot));
          } catch (_) {
            // Non-fatal write failure during migration
          }
        }
      }
      loadError = null;
    } catch (_) {
      loadError =
          'Data lokal belum dapat dibaca. Coba muat ulang. Data tidak dihapus otomatis.';
    }
    ready = true;
    notifyListeners();
  }

  void _validate(dynamic value) {
    if (value is! Map<String, dynamic> ||
        value['accounts'] is! Map<String, dynamic>) {
      throw const FormatException();
    }
    final version = value['version'];
    if (version != 1 && version != 2) {
      throw const FormatException();
    }
    // Migrate v1 → v2: add guest field
    if (version == 1) {
      value['version'] = 2;
      value['guest'] = {'seenLessons': <String>[]};
    }
    // Validate guest block (v2)
    final guest = value['guest'];
    if (guest is! Map<String, dynamic>) {
      throw const FormatException();
    }
    final seenLessons = guest['seenLessons'];
    if (seenLessons is! List) {
      throw const FormatException();
    }

    final accounts = value['accounts'] as Map<String, dynamic>;
    if (value['session'] != null &&
        (value['session'] is! String ||
            !accounts.containsKey(value['session']))) {
      throw const FormatException();
    }
    for (final account in accounts.values) {
      if (account is! Map<String, dynamic> ||
          account['name'] is! String ||
          (account['name'] as String).trim().isEmpty) {
        throw const FormatException();
      }
      final c = account['credential'];
      if (c is! Map<String, dynamic> ||
          c['iterations'] is! int ||
          c['iterations'] < 1000 ||
          c['iterations'] > 1000000 ||
          base64Decode(c['salt'] as String).length != 16 ||
          base64Decode(c['hash'] as String).length != 32) {
        throw const FormatException();
      }
      final p = account['progress'];
      if (p is! Map<String, dynamic> || p['best'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      for (final field in ['bookmarks', 'history']) {
        final list = p[field];
        if (list is! List ||
            list.any((id) => id is! String || !catalog.hasLesson(id))) {
          throw const FormatException();
        }
      }
      for (final entry in (p['best'] as Map<String, dynamic>).entries) {
        if (!catalog.hasLesson(entry.key) ||
            entry.value is! int ||
            entry.value < 0 ||
            entry.value > 5) {
          throw const FormatException();
        }
      }
    }
  }

  Future<T> _edit<T>(T Function(Map<String, dynamic>) mutate) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        if (loadError != null) {
          throw const AppException(
            'Pulihkan pembacaan data sebelum melanjutkan.',
          );
        }
        final draft = jsonDecode(jsonEncode(_snapshot)) as Map<String, dynamic>;
        final result = mutate(draft);
        try {
          await store.write(jsonEncode(draft));
        } catch (_) {
          throw const AppException(
            'Perubahan belum tersimpan. Periksa ruang perangkat lalu coba lagi.',
          );
        }
        _snapshot = draft;
        notifyListeners();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  static String _email(String value) => value.trim().toLowerCase();
  static String? nameError(String value) {
    final n = value.trim();
    return n.isEmpty || n.runes.length > 40
        ? 'Nama harus berisi 1–40 karakter.'
        : null;
  }

  static String? emailError(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
      ? null
      : 'Masukkan email yang valid.';
  Future<void> register(String name, String email, String password) async {
    final e = _email(email);
    final error =
        nameError(name) ??
        emailError(e) ??
        (password.length < 8 || password.length > 128
            ? 'Kata sandi harus 8–128 karakter.'
            : null);
    if (error != null) throw AppException(error);
    if (loadError != null) {
      throw const AppException('Data lokal belum dapat dibaca.');
    }
    final credential = await hasher.hash(password);
    await _edit<void>((draft) {
      final a = draft['accounts'] as Map<String, dynamic>;
      if (a.containsKey(e)) {
        throw const AppException(
          'Email sudah terdaftar pada perangkat ini. Silakan masuk.',
        );
      }
      a[e] = {
        'name': name.trim(),
        'credential': credential,
        'progress': _emptyProgress(),
      };
      draft['session'] = e;
    });
  }

  Future<void> login(String email, String password) async {
    final e = _email(email);
    if (password.length > 128 || emailError(e) != null) {
      throw const AppException('Email atau kata sandi tidak cocok.');
    }
    if (loadError != null) {
      throw const AppException('Data lokal belum dapat dibaca.');
    }
    final a = _accounts[e] as Map<String, dynamic>?;
    if (a == null ||
        !await hasher.verify(
          password,
          a['credential'] as Map<String, dynamic>,
        )) {
      throw const AppException('Email atau kata sandi tidak cocok.');
    }
    await _edit<void>((draft) {
      draft['session'] = e;
    });
  }

  Map<String, dynamic> _active(Map<String, dynamic> draft) {
    final session = draft['session'];
    if (session == null) {
      throw const AppException('Silakan masuk terlebih dahulu.');
    }
    return (draft['accounts'] as Map<String, dynamic>)[session]
        as Map<String, dynamic>;
  }

  Map<String, dynamic> _activeProgress(Map<String, dynamic> draft) =>
      _active(draft)['progress'] as Map<String, dynamic>;
  void _requireLesson(String id) {
    if (!catalog.hasLesson(id)) {
      throw const AppException('Materi tidak tersedia.');
    }
  }

  Future<void> logout() => _edit<void>((draft) {
    draft['session'] = null;
  });
  Future<void> rename(String name) async {
    final error = nameError(name);
    if (error != null) throw AppException(error);
    await _edit<void>((draft) {
      _active(draft)['name'] = name.trim();
    });
  }

  Future<void> toggleBookmark(String id) async {
    _requireLesson(id);
    await _edit<void>((draft) {
      final b = _activeProgress(draft)['bookmarks'] as List;
      b.contains(id) ? b.remove(id) : b.add(id);
    });
  }

  Future<void> visit(String id) async {
    _requireLesson(id);
    await _edit<void>((draft) {
      final h = _activeProgress(draft)['history'] as List;
      h.remove(id);
      h.insert(0, id);
    });
  }

  Future<int> finishLesson(String id, int correct) async {
    _requireLesson(id);
    if (correct < 0 || correct > 5) {
      throw const AppException('Hasil kuis tidak valid.');
    }
    return _edit<int>((draft) {
      final b = _activeProgress(draft)['best'] as Map<String, dynamic>;
      final old = b[id] as int? ?? 0;
      final updated = correct > old ? correct : old;
      b[id] = updated;
      return (updated - old) * 10;
    });
  }

  Future<void> resetProgress() => _edit<void>((draft) {
    _active(draft)['progress'] = _emptyProgress();
  });
  Future<void> clearUnreadableStorage() async {
    final fresh = {
      'version': 2,
      'guest': {'seenLessons': <String>[]},
      'accounts': <String, dynamic>{},
      'session': null,
    };
    try {
      await store.write(jsonEncode(fresh));
    } catch (_) {
      throw const AppException('Data belum dapat direset. Coba lagi.');
    }
    _snapshot = fresh;
    loadError = null;
    notifyListeners();
  }
}
