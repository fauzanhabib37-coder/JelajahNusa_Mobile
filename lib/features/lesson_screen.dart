import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart' show goToAuth;
import '../core/app_state.dart';
import '../data/catalog.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../ui/transitions.dart';
import 'quiz_screen.dart';

final _openingLesson = Expando<bool>();

Future<void> openLesson(
  BuildContext context,
  AppState state,
  Lesson lesson, {
  VoidCallback? onSignIn,
}) async {
  if (!context.mounted || _openingLesson[state] == true) return;

  // Guest quota check
  if (!state.canOpenLesson(lesson.id)) {
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 40, color: Nusa.green),
              const SizedBox(height: 16),
              Text(
                'Batas jelajah tamu tercapai',
                style: Nusa.heading(22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Kamu telah menjelajahi 5 materi sebagai tamu. '
                'Buat akun gratis untuk melanjutkan perjalanan belajarmu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Nusa.muted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.pop(c);
                  if (onSignIn != null) {
                    onSignIn();
                  } else {
                    goToAuth(context, state);
                  }
                },
                child: const Text('Masuk / Buat Akun'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
    return;
  }

  _openingLesson[state] = true;
  try {
    // Navigate immediately: persistence must never open a delayed route after a tab switch.
    final route = Navigator.push<void>(
      context,
      FadeSlidePageRoute(
        page: LessonScreen(state: state, lesson: lesson),
      ),
    );
    // Record guest lesson asynchronously (non-blocking)
    if (state.isGuest) {
      state.recordGuestLesson(lesson.id).ignore();
    }
    try {
      if (state.isSignedIn) {
        await state.visit(lesson.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    await route;
  } finally {
    _openingLesson[state] = false;
  }
}

class LessonScreen extends StatelessWidget {
  final AppState state;
  final Lesson lesson;
  const LessonScreen({super.key, required this.state, required this.lesson});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) {
      final r = state.catalog.region(lesson.regionId),
          saved = state.isSignedIn && state.bookmarks.contains(lesson.id);
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                'Materi ${lesson.category.toLowerCase()}',
                trailing: RoundIcon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  label: saved ? 'Hapus dari koleksi' : 'Simpan materi',
                  onTap: state.isGuest
                      ? () => _showBookmarkAuthDialog(context, state, lesson.id)
                      : () => perform(
                            context,
                            () => state.toggleBookmark(lesson.id),
                          ),
                ),
              ),
              Expanded(
                child: PageBody(
                  children: [
                    Text(
                      '${r.name.toUpperCase()} / ${lesson.category.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Nusa.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(lesson.title, style: Nusa.heading(29)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 15, color: Nusa.muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${lesson.minutes} menit baca & refleksi',
                            style: const TextStyle(
                              color: Nusa.muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (state.isSignedIn && state.completed(lesson.id))
                          const Icon(
                            Icons.check_circle_outline,
                            color: Nusa.green,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Art(r.image, height: 190, width: double.infinity),
                    const SizedBox(height: 5),
                    Text(
                      'Ilustrasi dekoratif ${r.name}; bukan dokumentasi objek.',
                      style: const TextStyle(fontSize: 9, color: Nusa.muted),
                    ),
                    const SizedBox(height: 20),
                    Text(lesson.subtitle, style: Nusa.heading(22)),
                    const SizedBox(height: 18),
                    for (final section in lesson.sections) ...[
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.body,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Nusa.muted,
                          height: 1.85,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                    HintBox(title: 'Pikirkan sejenak', body: lesson.reflection),
                    const SizedBox(height: 14),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 18),
                      title: const Text(
                        'Sumber & catatan materi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Nusa.green,
                        ),
                      ),
                      children: [
                        for (final source in lesson.sources)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  source.publisher,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Nusa.muted,
                                  ),
                                ),
                                Text(
                                  source.title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _openSource(context, source.url),
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text('Buka sumber'),
                                ),
                                SelectableText(
                                  source.url,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Nusa.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Text(
                          'Materi pengantar. Ilustrasi tidak digunakan untuk mengidentifikasi rincian benda budaya. Materi bahasa belum menyediakan audio pelafalan.',
                          style: TextStyle(fontSize: 11, color: Nusa.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('start_quiz'),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              QuizScreen(state: state, lesson: lesson),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(child: Text('Uji pemahaman')),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '5 soal · hasil terbaik menjadi poinmu',
                      style: TextStyle(fontSize: 10, color: Nusa.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  Future<void> _showBookmarkAuthDialog(
    BuildContext context,
    AppState state,
    String lessonId,
  ) async {
    final wantsAuth = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Simpan ke Koleksi', style: Nusa.heading(20)),
        content: const Text(
          'Menyimpan materi membutuhkan akun penjelajah. '
          'Masuk atau buat akun untuk menyimpan materi favoritmu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Nanti saja'),
          ),
          FilledButton(
            key: const Key('bookmark_auth_confirm'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Masuk / Buat Akun'),
          ),
        ],
      ),
    );
    if (wantsAuth == true && context.mounted) {
      await goToAuth(context, state);
      if (context.mounted && state.isSignedIn) {
        await perform(context, () => state.toggleBookmark(lessonId));
      }
    }
  }

  Future<void> _openSource(BuildContext context, String url) async {
    try {
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError('unavailable');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sumber belum dapat dibuka. Tautan dapat disalin pada panel ini.',
            ),
          ),
        );
      }
    }
  }
}
