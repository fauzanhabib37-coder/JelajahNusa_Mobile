import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../data/catalog.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'lesson_screen.dart';

class RegionScreen extends StatefulWidget {
  final AppState state;
  final Region region;
  const RegionScreen({super.key, required this.state, required this.region});
  @override
  State<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends State<RegionScreen> {
  String category = 'Semua';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.state,
    builder: (context, _) {
      final s = widget.state, r = widget.region;
      final all = s.catalog.forRegion(r.id);
      final lessons = all.where(
        (l) => category == 'Semua' || l.category == category,
      );
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Art(
                      r.image,
                      height: 330,
                      width: double.infinity,
                      radius: 0,
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xDA193425)],
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 16,
                      child: RoundIcon(
                        Icons.chevron_left,
                        label: 'Kembali',
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, style: Nusa.heading(34, Colors.white)),
                          const SizedBox(height: 6),
                          Text(
                            r.tagline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stats([
                        ('${all.length}', 'Materi'),
                        (
                          '${all.fold<int>(0, (v, l) => v + l.minutes)} menit',
                          'Estimasi',
                        ),
                        ('+${all.length * 50}', 'Poin maks.'),
                      ]),
                      const SizedBox(height: 24),
                      Text('Kenali lebih dekat', style: Nusa.heading(23)),
                      const SizedBox(height: 10),
                      Text(
                        r.description,
                        style: const TextStyle(color: Nusa.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 18),
                      ProgressLine(s.completedIn(r.id) / all.length),
                      const SizedBox(height: 6),
                      Text(
                        '${s.completedIn(r.id)} dari ${all.length} materi selesai',
                        style: const TextStyle(color: Nusa.muted, fontSize: 10),
                      ),
                      const SizedBox(height: 14),
                      CategoryTabs(
                        selected: category,
                        onSelect: (v) => setState(() => category = v),
                      ),
                      const SizedBox(height: 16),
                      ...lessons.map(
                        (l) => LessonTile(
                          lesson: l,
                          state: s,
                          onTap: () => openLesson(context, s, l),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
