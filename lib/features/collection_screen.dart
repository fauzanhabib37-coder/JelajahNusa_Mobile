import 'package:flutter/material.dart';
import '../app.dart' show goToAuth;
import '../core/app_state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'lesson_screen.dart';

class CollectionScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onExplore;
  const CollectionScreen({
    super.key,
    required this.state,
    required this.onExplore,
  });
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String tab = 'Tersimpan';
  @override
  Widget build(BuildContext context) {
    final s = widget.state;

    // Guest gate
    if (s.isGuest) {
      return Column(
        children: [
          const PageHeader('Koleksi belajarmu', back: false),
          Expanded(
            child: PageBody(
              children: [
                const SizedBox(height: 32),
                const Center(
                  child: Icon(
                    Icons.bookmark_border,
                    size: 56,
                    color: Nusa.green,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Koleksi membutuhkan akun',
                  style: Nusa.heading(24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Simpan materi favoritmu dan lacak riwayat belajar dengan membuat akun gratis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Nusa.muted),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  key: const Key('collection_signin_btn'),
                  onPressed: () => goToAuth(context, s),
                  child: const Text('Masuk / Buat Akun'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onExplore,
                  child: const Text('Jelajahi materi dulu'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final ids = tab == 'Tersimpan' ? s.bookmarks : s.history;
    return Column(
      children: [
        const PageHeader('Koleksi belajarmu', back: false),
        Expanded(
          child: PageBody(
            children: [
              Text('Cerita yang ingin', style: Nusa.heading()),
              Text('kamu kunjungi lagi.', style: Nusa.heading(28, Nusa.green)),
              const SizedBox(height: 14),
              const Text(
                'Simpan materi dan lanjutkan kapan saja.',
                style: TextStyle(fontSize: 11, color: Nusa.muted),
              ),
              const SizedBox(height: 18),
              CategoryTabs(
                labels: const ['Tersimpan', 'Riwayat'],
                selected: tab,
                onSelect: (v) => setState(() => tab = v),
              ),
              const SizedBox(height: 18),
              Text(
                '${ids.length} materi ${tab == 'Tersimpan' ? 'tersimpan' : 'dikunjungi'}',
                style: const TextStyle(color: Nusa.muted, fontSize: 11),
              ),
              const SizedBox(height: 18),
              if (ids.isEmpty)
                EmptyState(
                  title: tab == 'Tersimpan'
                      ? 'Koleksimu menunggu cerita'
                      : 'Perjalananmu dimulai di sini',
                  body: tab == 'Tersimpan'
                      ? 'Ketuk ikon simpan pada halaman materi untuk menambah koleksi.'
                      : 'Buka satu materi. Riwayat belajarmu akan tampil di sini.',
                  action: 'Mulai jelajah',
                  onAction: widget.onExplore,
                ),
              for (final id in ids)
                LessonTile(
                  lesson: s.catalog.lesson(id),
                  state: s,
                  withImage: true,
                  onTap: () => openLesson(context, s, s.catalog.lesson(id)),
                ),
              if (ids.isNotEmpty)
                const HintBox(
                  title: 'Cerita tetap dekat',
                  body:
                      'Buka materi untuk membaca kembali atau mengubah status simpan.',
                  icon: Icons.bookmark_border,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
