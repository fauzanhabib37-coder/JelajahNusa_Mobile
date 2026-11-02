import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'region_screen.dart';
import 'lesson_screen.dart';
import 'map_screen.dart';

class ExploreScreen extends StatefulWidget {
  final AppState state;
  final String initialQuery;
  const ExploreScreen({super.key, required this.state, this.initialQuery = ''});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController search;
  late TabController _tabCtrl;
  String category = 'Semua';
  @override
  void initState() {
    super.initState();
    search = TextEditingController(text: widget.initialQuery);
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    search.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final matches = s.catalog.search(search.text, category);
    final regions = s.catalog.regions
        .where((r) => matches.any((l) => l.regionId == r.id))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const Brand(),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Jelajah Nusantara',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFE6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Nusa.green,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Nusa.green.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Nusa.ink,
              labelStyle: const TextStyle(
                fontFamily: 'NusaSans',
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'NusaSans',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              tabs: const [
                Tab(text: 'Daftar'),
                Tab(text: 'Peta'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // ── Daftar tab ──────────────────────────────────────────────
              PageBody(
                children: [
                  Text('Banyak daerah.', style: Nusa.heading()),
                  Text('Beragam cerita.', style: Nusa.heading(28, Nusa.green)),
                  const SizedBox(height: 12),
                  const Text(
                    'Mulai dari tempat yang membuatmu penasaran.',
                    style: TextStyle(fontSize: 11, color: Nusa.muted),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari daerah atau materi',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: () => setState(search.clear),
                              icon: const Icon(Icons.close, size: 18),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CategoryTabs(
                    selected: category,
                    onSelect: (v) => setState(() => category = v),
                  ),
                  const SizedBox(height: 18),
                  if (matches.isEmpty)
                    EmptyState(
                      title: 'Belum ada cerita yang cocok',
                      body: 'Coba kata lain atau pilih semua kategori.',
                      action: 'Hapus pencarian & filter',
                      onAction: () => setState(() {
                        search.clear();
                        category = 'Semua';
                      }),
                    ),
                  for (final r in regions) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  RegionScreen(state: s, region: r),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Art(r.image, width: 88, height: 104, radius: 16),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${s.catalog.forRegion(r.id).length} materi · ${r.tagline}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Nusa.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ProgressLine(
                                        s.isSignedIn
                                            ? s.completedIn(r.id) /
                                                s.catalog.forRegion(r.id).length
                                            : 0,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Nusa.green,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (search.text.trim().isNotEmpty || category != 'Semua')
                      ...matches
                          .where((l) => l.regionId == r.id)
                          .map(
                            (l) => LessonTile(
                              lesson: l,
                              state: s,
                              onTap: () => openLesson(context, s, l),
                            ),
                          ),
                  ],
                ],
              ),
              // ── Peta tab ────────────────────────────────────────────────
              MapScreen(state: s),
            ],
          ),
        ),
      ],
    );
  }
}
