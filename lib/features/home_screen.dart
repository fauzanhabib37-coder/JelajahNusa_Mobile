import 'package:flutter/material.dart';
import '../app.dart' show goToAuth;
import '../core/app_state.dart';
import '../data/catalog.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'lesson_screen.dart';
import 'region_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState state;
  final ValueChanged<String> onExplore;
  final VoidCallback onProfile;
  const HomeScreen({
    super.key,
    required this.state,
    required this.onExplore,
    required this.onProfile,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    // For guest mode, show first unfinished lesson from catalog
    final Lesson next;
    if (s.isSignedIn) {
      final pending = s.history.where((id) => !s.completed(id));
      next = pending.isNotEmpty
          ? s.catalog.lesson(pending.first)
          : s.catalog.lessons.firstWhere(
              (l) => !s.completed(l.id),
              orElse: () => s.catalog.lessons.first,
            );
    } else {
      next = s.catalog.lessons.first;
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Positioned.fill(
                child: const Art(
                  'assets/illustrations/hero_nusantara.webp',
                  radius: 0,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Nusa.bg.withValues(alpha: 0.28),
                        Nusa.bg.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Brand(),
                        const SizedBox(width: 8),
                        if (s.isSignedIn)
                          IconButton(
                            tooltip: 'Buka profil',
                            onPressed: widget.onProfile,
                            style: IconButton.styleFrom(
                              backgroundColor: Nusa.soft,
                            ),
                            icon: Text(
                              s.name.isEmpty
                                  ? 'N'
                                  : String.fromCharCode(
                                      s.name.runes.first,
                                    ).toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'NusaSerif',
                                fontSize: 22,
                                color: Nusa.green,
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: OutlinedButton(
                              key: const Key('home_signin_btn'),
                              onPressed: () => goToAuth(context, s),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Nusa.green,
                                side: const BorderSide(color: Nusa.green),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(0, 36),
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text(
                                'Masuk / Buat Akun',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    Text('Kenali budaya,', style: Nusa.heading(28)),
                    Text(
                      'jelajahi\nNusantara.',
                      style: Nusa.heading(28, Nusa.green),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Satu daerah, satu cerita baru.',
                      style: TextStyle(fontSize: 11, color: Nusa.ink),
                    ),
                    const SizedBox(height: 35),
                    TextField(
                      controller: search,
                      onSubmitted: widget.onExplore,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Mau belajar budaya apa?',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: IconButton(
                          tooltip: 'Cari daerah atau materi',
                          onPressed: () => widget.onExplore(search.text),
                          icon: const Icon(
                            Icons.arrow_circle_right,
                            color: Nusa.green,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Guest banner (shown below the hero section)
          if (s.isGuest) _GuestBanner(state: s, context: context),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(
                  'Daerah pilihan',
                  action: 'Lihat semua',
                  onAction: () => widget.onExplore(''),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < s.catalog.regions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _regionCard(context, s.catalog.regions[i]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                SectionTitle(
                  s.isSignedIn && s.completedCount == s.catalog.lessons.length
                      ? 'Semua cerita terjelajahi'
                      : 'Mulai belajarmu',
                ),
                const SizedBox(height: 14),
                LessonTile(
                  lesson: next,
                  state: s,
                  withImage: true,
                  onTap: () => openLesson(
                    context,
                    s,
                    next,
                    onSignIn: () => goToAuth(context, s),
                  ),
                ),
                HintBox(
                  title: s.isSignedIn && s.completedCount == 0
                      ? 'Langkah kecil, wawasan baru'
                      : s.isSignedIn
                      ? 'Jejak perjalananmu'
                      : 'Jelajahi sebagai tamu',
                  body: s.isSignedIn && s.completedCount == 0
                      ? 'Pilih satu daerah. Baca ceritanya, lalu uji pemahamanmu.'
                      : s.isSignedIn
                      ? '${s.completedCount} dari ${s.catalog.lessons.length} materi selesai. Terus temukan cerita baru.'
                      : 'Kamu bisa membaca hingga 5 materi tanpa akun. Buat akun untuk menyimpan progresmu.',
                  icon: Icons.explore_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _regionCard(BuildContext context, Region r) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: Key('home_${r.id}'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => RegionScreen(state: widget.state, region: r),
        ),
      ),
      child: AspectRatio(
        aspectRatio: 0.62,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Art(r.image, radius: 0),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xDD1B3023)],
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 8,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.id == 'yogyakarta'
                        ? 'Yogyakarta'
                        : r.id == 'sumatera_barat'
                        ? 'Sumbar'
                        : r.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    r.id == 'bali'
                        ? 'Seni & tradisi'
                        : r.id == 'yogyakarta'
                        ? 'Budaya Jawa'
                        : 'Minangkabau',
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Lightweight banner shown to guest users below the hero section.
class _GuestBanner extends StatelessWidget {
  final AppState state;
  final BuildContext context;
  const _GuestBanner({required this.state, required this.context});
  @override
  Widget build(BuildContext _) => Container(
    margin: const EdgeInsets.fromLTRB(24, 0, 24, 4),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Nusa.soft,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Nusa.green.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        const Icon(Icons.explore_outlined, size: 20, color: Nusa.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.guestLessonCount}/${AppState.guestLimit} materi dijelajahi',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Nusa.green,
                ),
              ),
              const Text(
                'Masuk untuk akses penuh & simpan progres',
                style: TextStyle(fontSize: 10, color: Nusa.muted),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => goToAuth(context, state),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            textStyle: const TextStyle(fontSize: 11),
          ),
          child: const Text('Masuk'),
        ),
      ],
    ),
  );
}
