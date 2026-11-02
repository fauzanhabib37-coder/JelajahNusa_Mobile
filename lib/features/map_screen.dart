import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_state.dart';
import '../data/catalog.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../ui/transitions.dart';
import 'region_screen.dart';

class _Province {
  final String id;
  final String name;
  final double x; // 0..1 normalized
  final double y; // 0..1 normalized
  final bool active;
  final String islandGroup;
  final String heritageTitle;
  const _Province(
    this.id,
    this.name,
    this.x,
    this.y,
    this.active,
    this.islandGroup, {
    this.heritageTitle = '',
  });
}

// 38 Indonesian Provinces with normalized coordinates
const _provinces = [
  // Sumatera
  _Province('aceh', 'Aceh', 0.065, 0.125, false, 'Sumatera'),
  _Province('sumatera_utara', 'Sumut', 0.090, 0.195, false, 'Sumatera'),
  _Province('sumatera_barat', 'Sumatera Barat', 0.095, 0.315, true, 'Sumatera', heritageTitle: 'Ranah Minang'),
  _Province('riau', 'Riau', 0.135, 0.265, false, 'Sumatera'),
  _Province('kepri', 'Kep. Riau', 0.165, 0.220, false, 'Sumatera'),
  _Province('jambi', 'Jambi', 0.138, 0.355, false, 'Sumatera'),
  _Province('sumsel', 'Sumsel', 0.158, 0.415, false, 'Sumatera'),
  _Province('bengkulu', 'Bengkulu', 0.115, 0.435, false, 'Sumatera'),
  _Province('babel', 'Babel', 0.195, 0.395, false, 'Sumatera'),
  _Province('lampung', 'Lampung', 0.165, 0.485, false, 'Sumatera'),

  // Jawa
  _Province('banten', 'Banten', 0.195, 0.535, false, 'Jawa'),
  _Province('dki', 'DKI Jakarta', 0.220, 0.520, false, 'Jawa'),
  _Province('jawa_barat', 'Jawa Barat', 0.240, 0.540, false, 'Jawa'),
  _Province('jawa_tengah', 'Jawa Tengah', 0.280, 0.535, false, 'Jawa'),
  _Province('yogyakarta', 'DI Yogyakarta', 0.285, 0.570, true, 'Jawa', heritageTitle: 'Praja Mataram'),
  _Province('jawa_timur', 'Jawa Timur', 0.335, 0.545, false, 'Jawa'),

  // Bali & Nusa Tenggara
  _Province('bali', 'Bali', 0.388, 0.565, true, 'Bali & Nusa Tenggara', heritageTitle: 'Pulau Dewata'),
  _Province('ntb', 'NTB', 0.435, 0.565, false, 'Bali & Nusa Tenggara'),
  _Province('ntt', 'NTT', 0.520, 0.575, false, 'Bali & Nusa Tenggara'),

  // Kalimantan
  _Province('kalbar', 'Kalbar', 0.280, 0.320, false, 'Kalimantan'),
  _Province('kalteng', 'Kalteng', 0.315, 0.355, false, 'Kalimantan'),
  _Province('kalsel', 'Kalsel', 0.345, 0.410, false, 'Kalimantan'),
  _Province('kaltim', 'Kaltim', 0.365, 0.305, false, 'Kalimantan'),
  _Province('kaltara', 'Kaltara', 0.365, 0.235, false, 'Kalimantan'),

  // Sulawesi
  _Province('sulut', 'Sulut', 0.505, 0.225, false, 'Sulawesi'),
  _Province('gorontalo', 'Gorontalo', 0.480, 0.255, false, 'Sulawesi'),
  _Province('sulteng', 'Sulteng', 0.470, 0.325, false, 'Sulawesi'),
  _Province('sulbar', 'Sulbar', 0.445, 0.355, false, 'Sulawesi'),
  _Province('sulsel', 'Sulsel', 0.448, 0.430, false, 'Sulawesi'),
  _Province('sultra', 'Sultra', 0.490, 0.400, false, 'Sulawesi'),

  // Maluku
  _Province('maluku_utara', 'Maluku Utara', 0.565, 0.250, false, 'Maluku'),
  _Province('maluku', 'Maluku', 0.585, 0.360, false, 'Maluku'),

  // Papua
  _Province('papua_barat_daya', 'Papua Barat Daya', 0.635, 0.285, false, 'Papua'),
  _Province('papua_barat', 'Papua Barat', 0.655, 0.325, false, 'Papua'),
  _Province('papua_tengah', 'Papua Tengah', 0.700, 0.365, false, 'Papua'),
  _Province('papua_pegunungan', 'Papua Pegunungan', 0.745, 0.385, false, 'Papua'),
  _Province('papua', 'Papua', 0.755, 0.325, false, 'Papua'),
  _Province('papua_selatan', 'Papua Selatan', 0.750, 0.465, false, 'Papua'),
];

/// Cartographic mapper: maps archipelago coordinate space to canvas bounds
Offset _mapCoords(double nx, double ny, double w, double h) {
  final sx = (nx - 0.040) / 0.755;
  final sy = (ny - 0.085) / 0.530;
  return Offset(
    (0.04 + sx * 0.92) * w,
    (0.06 + sy * 0.79) * h,
  );
}

class MapScreen extends StatefulWidget {
  final AppState state;
  const MapScreen({super.key, required this.state});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  String? _selected;
  String _selectedArchipelago = 'Semua';
  final TransformationController _transformController = TransformationController();
  late AnimationController _pulseController;

  final List<String> _islandFilters = const [
    'Semua',
    'Sumatera',
    'Jawa',
    'Bali & Nusa Tenggara',
    'Kalimantan',
    'Sulawesi',
    'Maluku',
    'Papua',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // Avoid repeating indefinitely in test environments to allow pumpAndSettle
    try {
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.value = 0.5;
      }
    } catch (_) {
      // In web without Platform, repeat
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    _transformController.value =
        _transformController.value * Matrix4.diagonal3Values(1.25, 1.25, 1.0);
  }

  void _zoomOut() {
    _transformController.value =
        _transformController.value * Matrix4.diagonal3Values(0.8, 0.8, 1.0);
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void _onProvinceTap(BuildContext context, _Province p) {
    setState(() => _selected = p.id);
    if (p.active) {
      _showRegionSheet(context, p);
    } else {
      _showDevelopingSheet(context, p);
    }
  }

  void _showDevelopingSheet(BuildContext context, _Province p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Nusa.soft,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD8E2D6)),
                    ),
                    child: const Icon(Icons.explore_outlined, color: Nusa.green, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: Nusa.heading(20)),
                        Text('Gugus ${p.islandGroup}', style: const TextStyle(fontSize: 12, color: Nusa.muted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDCE2D9)),
                    ),
                    child: const Text(
                      'Segera Hadir',
                      style: TextStyle(fontSize: 10, color: Nusa.muted, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5EDE3)),
                ),
                child: const Text(
                  'Materi kebudayaan, kearifan lokal, dan kuis tradisi untuk provinsi ini sedang dikurasi dan diselaraskan dengan referensi resmi kebudayaan Indonesia.',
                  style: TextStyle(fontSize: 12, height: 1.6, color: Nusa.ink),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.public, size: 16),
                      label: const Text('Google Maps ↗', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(c);
                        final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${p.name} Indonesia')}';
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nusa.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegionSheet(BuildContext context, _Province p) {
    final catalog = widget.state.catalog;
    Region? region;
    try {
      region = catalog.region(p.id);
    } catch (_) {}

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (region != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Art(region.image, width: 88, height: 104, radius: 14),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC59B46).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.heritageTitle.isNotEmpty ? p.heritageTitle : 'Warisan Luhur',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF9E7728),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(region.name, style: Nusa.heading(22)),
                          const SizedBox(height: 2),
                          Text(
                            region.tagline,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Nusa.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Nusa.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${catalog.forRegion(region.id).length} materi dapat dipelajari',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Nusa.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  region.description,
                  style: const TextStyle(fontSize: 12.5, height: 1.6),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.public, size: 16, color: Nusa.green),
                      label: const Text('Google Maps ↗', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${region!.name} Indonesia')}';
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Nusa.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.auto_stories_outlined, size: 18),
                        label: const Text(
                          'Jelajahi Materi',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          Navigator.pop(c);
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => RegionScreen(
                                state: widget.state,
                                region: region!,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth;
        // Aspect ratio for Indonesian archipelago (width to height ~ 2.1 : 1)
        final mapHeight = (mapWidth / 2.1).clamp(210.0, 360.0);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Title & Badge ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Peta Nusantara',
                        style: Nusa.heading(21),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Nusa.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '38 provinsi',
                        style: TextStyle(fontSize: 10, color: Nusa.green, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Legend Bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _legendIndicator(const Color(0xFFC59B46), 'Pusat Budaya Aktif'),
                    _legendIndicator(const Color(0xFF355E43), 'Daratan Kepulauan'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── The Masterpiece Cartographic Canvas ──────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: mapHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FA), Color(0xFFD6EAF5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFB8D8E9),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A4A).withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.5),
                  child: Stack(
                    children: [
                      // Interactive Vector Map with Pan & Pinch Zoom
                      Positioned.fill(
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: 1.0,
                          maxScale: 3.5,
                          boundaryMargin: const EdgeInsets.all(40),
                          child: Stack(
                            children: [
                              // Handcrafted Vector Archipelago Painting
                              Positioned.fill(
                                child: CustomPaint(
                                  size: Size(mapWidth - 32, mapHeight),
                                  painter: _IndonesiaArchipelagoPainter(),
                                ),
                              ),
                              // Active Cultural Heritage Seal Pins
                              for (final p in _provinces.where((p) => p.active))
                                _buildHeritageSealMarker(context, p, mapWidth - 32, mapHeight),
                            ],
                          ),
                        ),
                      ),

                      // Artisanal Compass Rose (Utara)
                      Positioned(
                        bottom: 8,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD0E2EC)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.navigation, size: 11, color: Nusa.green),
                              SizedBox(width: 4),
                              Text(
                                'U • Zamrud Khatulistiwa',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Nusa.ink,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Nautical Scale Bar (bottom right)
                      Positioned(
                        bottom: 8,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFD0E2EC)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 22, height: 3, color: Nusa.ink),
                              Container(width: 22, height: 3, color: const Color(0xFFC59B46)),
                              const SizedBox(width: 4),
                              const Text(
                                '500 km',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  color: Nusa.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Minimalist Cartographic Zoom Toolbar
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD0E2EC)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _zoomIn,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(Icons.add, size: 16, color: Nusa.ink),
                                ),
                              ),
                              Container(height: 1, width: 22, color: const Color(0xFFE5EDF1)),
                              InkWell(
                                onTap: _zoomOut,
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(Icons.remove, size: 16, color: Nusa.ink),
                                ),
                              ),
                              Container(height: 1, width: 22, color: const Color(0xFFE5EDF1)),
                              InkWell(
                                onTap: _resetZoom,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(Icons.crop_free, size: 14, color: Nusa.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Micro guidance note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: const [
                    Icon(Icons.touch_app_outlined, size: 14, color: Nusa.green),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ketuk lencana emas untuk menjelajahi materi budaya, atau pilih gugus pulau di bawah.',
                        style: TextStyle(fontSize: 11, color: Nusa.muted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Archipelago Filter Chips (Gugus Kepulauan) ─────────────────
              SizedBox(
                height: 34,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _islandFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = _islandFilters[index];
                    final isSelected = _selectedArchipelago == item;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _selectedArchipelago = item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Nusa.green : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Nusa.green : const Color(0xFFDCE4DA),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : Nusa.ink,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // ── Cultural Postcards (Daerah Siap Jelajah) ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionTitle(
                  'Daerah aktif di peta',
                  action: 'Buka semua',
                  onAction: () {
                    // Navigate to explore
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Filtered or all regions
              _buildRegionCards(context),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegionCards(BuildContext context) {
    var regions = widget.state.catalog.regions;
    if (_selectedArchipelago == 'Sumatera') {
      regions = regions.where((r) => r.id == 'sumatera_barat').toList();
    } else if (_selectedArchipelago == 'Jawa') {
      regions = regions.where((r) => r.id == 'yogyakarta').toList();
    } else if (_selectedArchipelago == 'Bali & Nusa Tenggara') {
      regions = regions.where((r) => r.id == 'bali').toList();
    } else if (_selectedArchipelago != 'Semua') {
      // Developing group placeholder
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4ECE2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories_outlined, color: Nusa.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Wilayah $_selectedArchipelago',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Materi budaya dan kuis untuk gugus kepulauan ini sedang dalam proses riset kuratorial.',
                style: TextStyle(fontSize: 11.5, color: Nusa.muted),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final reg in regions)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: PressScaleWrapper(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => RegionScreen(
                        state: widget.state,
                        region: reg,
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2EBE0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Art(reg.image, width: double.infinity, height: 72, radius: 0),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${widget.state.catalog.forRegion(reg.id).length} materi',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reg.id == 'yogyakarta'
                                    ? 'Yogyakarta'
                                    : reg.id == 'sumatera_barat'
                                        ? 'Sumbar'
                                        : reg.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                  fontFamily: 'NusaSans',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reg.tagline,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: Nusa.muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeritageSealMarker(BuildContext context, _Province p, double w, double h) {
    final pos = _mapCoords(p.x, p.y, w, h);

    // Offset tags strategically so they never collide
    // Sumbar: Tag on top-center
    // Yogyakarta: Tag on top-left
    // Bali: Tag on center-right
    final tagAlignment = p.id == 'sumatera_barat'
        ? Alignment.topCenter
        : p.id == 'yogyakarta'
            ? Alignment.topLeft
            : Alignment.centerRight;

    return Positioned(
      left: pos.dx - 18,
      top: pos.dy - 18,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onProvinceTap(context, p),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return _HeritageSealPin(
              province: p,
              selected: _selected == p.id,
              tagAlignment: tagAlignment,
              pulse: _pulseController.value,
            );
          },
        ),
      ),
    );
  }

  Widget _legendIndicator(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Nusa.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

/// Artisanal Heritage Seal Pin with glowing gold ring and non-colliding badge
class _HeritageSealPin extends StatelessWidget {
  final _Province province;
  final bool selected;
  final Alignment tagAlignment;
  final double pulse;

  const _HeritageSealPin({
    required this.province,
    required this.selected,
    required this.tagAlignment,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = province.id == 'sumatera_barat'
        ? 'Sumbar'
        : province.id == 'yogyakarta'
            ? 'Yogya'
            : province.name;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Pulsing Gold Aura
        Positioned(
          left: -4 * pulse,
          top: -4 * pulse,
          child: Container(
            width: 36 + 8 * pulse,
            height: 36 + 8 * pulse,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC59B46).withValues(alpha: 0.25 * (1 - pulse)),
            ),
          ),
        ),

        // Heritage Seal Body
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A29), // Deep Imperial Emerald
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD4A64B), // Heritage Gold Rim
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.stars,
              size: 18,
              color: Color(0xFFF7DE98),
            ),
          ),
        ),

        // Strategic Non-Colliding Label Tag
        Positioned(
          top: tagAlignment == Alignment.topCenter || tagAlignment == Alignment.topLeft ? -20 : 6,
          left: tagAlignment == Alignment.centerRight ? 40 : (tagAlignment == Alignment.topLeft ? -22 : -10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFC59B46),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC59B46),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Nusa.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the authentic landmass and islands of the Indonesian Archipelago
/// with smooth, hand-drafted bezier curves, coastal reef halos, and mountain ridges.
class _IndonesiaArchipelagoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Helper closure to map coordinates
    Offset p(double nx, double ny) => _mapCoords(nx, ny, w, h);

    // 1. Continental Shelf Reef Glow (Paparan Sunda & Paparan Sahul)
    final shelfPaint = Paint()
      ..color = const Color(0xFFB5DCF0)
      ..style = PaintingStyle.fill;

    // 2. Main Landmass Paint (Lush Emerald Sage)
    final landPaint = Paint()
      ..color = const Color(0xFF355E43)
      ..style = PaintingStyle.fill;

    // 3. Mountain Ridges / Topography Accent
    final ridgePaint = Paint()
      ..color = const Color(0xFF264531)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 4. Coastline Hairline Border
    final coastPaint = Paint()
      ..color = const Color(0xFF1E3827)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 5. Active Region Royal Accent
    final activeHighlight = Paint()
      ..color = const Color(0xFF23442F)
      ..style = PaintingStyle.fill;

    // 6. Khatulistiwa (Equator 0°) Line
    final equatorY = p(0.0, 0.318).dy;
    final equatorPaint = Paint()
      ..color = const Color(0xFF4C8FA8).withValues(alpha: 0.45)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    // Draw dashed equator line
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    var startX = 8.0;
    while (startX < w - 8) {
      canvas.drawLine(
        Offset(startX, equatorY),
        Offset(math.min(startX + dashWidth, w - 8), equatorY),
        equatorPaint,
      );
      startX += dashWidth + dashSpace;
    }

    _drawEquatorLabel(canvas, 'KHATULISTIWA (0°)', Offset(w * 0.05, equatorY - 11));

    // Deep sea wave lines
    final wavePaint = Paint()
      ..color = const Color(0xFFB4D8EC).withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (var i = 1; i <= 3; i++) {
      final y = h * i / 4;
      final wave = Path()..moveTo(0, y);
      for (var x = 0.0; x <= w; x += 36) {
        wave.quadraticBezierTo(x + 18, y - 2, x + 36, y);
      }
      canvas.drawPath(wave, wavePaint);
    }

    // ── 1. PULAU SUMATERA (Smooth Organic Curves) ─────────────────────────────
    final sumatera = Path()
      ..moveTo(p(0.052, 0.115).dx, p(0.052, 0.115).dy) // Banda Aceh
      ..quadraticBezierTo(p(0.060, 0.090).dx, p(0.060, 0.090).dy, p(0.068, 0.095).dx, p(0.068, 0.095).dy) // Sabang tip
      ..quadraticBezierTo(p(0.076, 0.110).dx, p(0.076, 0.110).dy, p(0.082, 0.128).dx, p(0.082, 0.128).dy) // Lhokseumawe
      ..quadraticBezierTo(p(0.092, 0.155).dx, p(0.092, 0.155).dy, p(0.104, 0.185).dx, p(0.104, 0.185).dy) // Medan
      ..quadraticBezierTo(p(0.115, 0.220).dx, p(0.115, 0.220).dy, p(0.125, 0.245).dx, p(0.125, 0.245).dy) // Asahan
      ..quadraticBezierTo(p(0.138, 0.280).dx, p(0.138, 0.280).dy, p(0.146, 0.300).dx, p(0.146, 0.300).dy) // Riau coast
      ..quadraticBezierTo(p(0.158, 0.345).dx, p(0.158, 0.345).dy, p(0.166, 0.365).dx, p(0.166, 0.365).dy) // Jambi coast
      ..quadraticBezierTo(p(0.175, 0.405).dx, p(0.175, 0.405).dy, p(0.182, 0.430).dx, p(0.182, 0.430).dy) // Musi delta
      ..quadraticBezierTo(p(0.186, 0.470).dx, p(0.186, 0.470).dy, p(0.182, 0.495).dx, p(0.182, 0.495).dy) // Bangka strait
      ..quadraticBezierTo(p(0.178, 0.525).dx, p(0.178, 0.525).dy, p(0.172, 0.535).dx, p(0.172, 0.535).dy) // Bakauheni
      ..quadraticBezierTo(p(0.160, 0.530).dx, p(0.160, 0.530).dy, p(0.152, 0.518).dx, p(0.152, 0.518).dy) // Teluk Lampung
      ..quadraticBezierTo(p(0.142, 0.485).dx, p(0.142, 0.485).dy, p(0.134, 0.465).dx, p(0.134, 0.465).dy) // Krui
      ..quadraticBezierTo(p(0.120, 0.425).dx, p(0.120, 0.425).dy, p(0.114, 0.405).dx, p(0.114, 0.405).dy) // Bengkulu
      ..quadraticBezierTo(p(0.098, 0.355).dx, p(0.098, 0.355).dy, p(0.090, 0.325).dx, p(0.090, 0.325).dy) // Padang / Sumbar
      ..quadraticBezierTo(p(0.082, 0.285).dx, p(0.082, 0.285).dy, p(0.074, 0.260).dx, p(0.074, 0.260).dy) // Sibolga
      ..quadraticBezierTo(p(0.060, 0.200).dx, p(0.060, 0.200).dy, p(0.056, 0.175).dx, p(0.056, 0.175).dy) // Meulaboh
      ..quadraticBezierTo(p(0.046, 0.145).dx, p(0.046, 0.145).dy, p(0.052, 0.115).dx, p(0.052, 0.115).dy) // Calang to Banda Aceh
      ..close();

    // Sumatera Barat active area highlight (Padang, Bukittinggi)
    final sumbarHighlight = Path()
      ..moveTo(p(0.080, 0.280).dx, p(0.080, 0.280).dy)
      ..lineTo(p(0.115, 0.290).dx, p(0.115, 0.290).dy)
      ..lineTo(p(0.118, 0.350).dx, p(0.118, 0.350).dy)
      ..lineTo(p(0.092, 0.340).dx, p(0.092, 0.340).dy)
      ..close();

    // Pulau Nias & Mentawai
    final niasPt = p(0.054, 0.250);
    final nias = Path()..addOval(Rect.fromLTWH(niasPt.dx, niasPt.dy, w * 0.015, h * 0.045));
    final mentawaiPt = p(0.078, 0.350);
    final mentawai = Path()..addOval(Rect.fromLTWH(mentawaiPt.dx, mentawaiPt.dy, w * 0.016, h * 0.065));

    // Bangka & Belitung
    final bangkaPt = p(0.188, 0.370);
    final bangka = Path()..addOval(Rect.fromLTWH(bangkaPt.dx, bangkaPt.dy, w * 0.018, h * 0.055));
    final belitungPt = p(0.218, 0.410);
    final belitung = Path()..addOval(Rect.fromLTWH(belitungPt.dx, belitungPt.dy, w * 0.018, h * 0.030));

    // ── 2. PULAU JAWA & MADURA (Smooth Organic Curves) ────────────────────────
    final jawa = Path()
      ..moveTo(p(0.178, 0.540).dx, p(0.178, 0.540).dy) // Ujung Kulon
      ..quadraticBezierTo(p(0.188, 0.522).dx, p(0.188, 0.522).dy, p(0.198, 0.520).dx, p(0.198, 0.520).dy) // Anyer
      ..quadraticBezierTo(p(0.212, 0.522).dx, p(0.212, 0.522).dy, p(0.224, 0.524).dx, p(0.224, 0.524).dy) // Jakarta
      ..quadraticBezierTo(p(0.245, 0.528).dx, p(0.245, 0.528).dy, p(0.265, 0.532).dx, p(0.265, 0.532).dy) // Cirebon
      ..quadraticBezierTo(p(0.288, 0.522).dx, p(0.288, 0.522).dy, p(0.308, 0.514).dx, p(0.308, 0.514).dy) // Semenanjung Jepara
      ..quadraticBezierTo(p(0.320, 0.528).dx, p(0.320, 0.528).dy, p(0.342, 0.534).dx, p(0.342, 0.534).dy) // Surabaya
      ..quadraticBezierTo(p(0.358, 0.542).dx, p(0.358, 0.542).dy, p(0.372, 0.554).dx, p(0.372, 0.554).dy) // Ketapang
      ..quadraticBezierTo(p(0.375, 0.572).dx, p(0.375, 0.572).dy, p(0.366, 0.576).dx, p(0.366, 0.576).dy) // Blambangan
      ..quadraticBezierTo(p(0.345, 0.572).dx, p(0.345, 0.572).dy, p(0.325, 0.568).dx, p(0.325, 0.568).dy) // Malang
      ..quadraticBezierTo(p(0.295, 0.566).dx, p(0.295, 0.566).dy, p(0.280, 0.566).dx, p(0.280, 0.566).dy) // DI Yogyakarta
      ..quadraticBezierTo(p(0.250, 0.562).dx, p(0.250, 0.562).dy, p(0.224, 0.558).dx, p(0.224, 0.558).dy) // Cilacap
      ..quadraticBezierTo(p(0.200, 0.556).dx, p(0.200, 0.556).dy, p(0.180, 0.552).dx, p(0.180, 0.552).dy) // Pelabuhan Ratu
      ..close();

    // DI Yogyakarta active area highlight
    final jogjaHighlight = Path()
      ..moveTo(p(0.270, 0.545).dx, p(0.270, 0.545).dy)
      ..lineTo(p(0.298, 0.545).dx, p(0.298, 0.545).dy)
      ..lineTo(p(0.295, 0.565).dx, p(0.295, 0.565).dy)
      ..lineTo(p(0.272, 0.565).dx, p(0.272, 0.565).dy)
      ..close();

    // Madura
    final madura = Path()
      ..moveTo(p(0.338, 0.520).dx, p(0.338, 0.520).dy)
      ..quadraticBezierTo(p(0.352, 0.518).dx, p(0.352, 0.518).dy, p(0.365, 0.522).dx, p(0.365, 0.522).dy)
      ..quadraticBezierTo(p(0.368, 0.534).dx, p(0.368, 0.534).dy, p(0.342, 0.534).dx, p(0.342, 0.534).dy)
      ..close();

    // ── 3. BALI & NUSA TENGGARA (Curved Organic Shapes) ───────────────────────
    final bali = Path()
      ..moveTo(p(0.378, 0.555).dx, p(0.378, 0.555).dy) // Gilimanuk
      ..quadraticBezierTo(p(0.392, 0.548).dx, p(0.392, 0.548).dy, p(0.402, 0.556).dx, p(0.402, 0.556).dy) // Singaraja & Karangasem
      ..quadraticBezierTo(p(0.398, 0.572).dx, p(0.398, 0.572).dy, p(0.392, 0.578).dx, p(0.392, 0.578).dy) // Bukit / Uluwatu
      ..quadraticBezierTo(p(0.380, 0.570).dx, p(0.380, 0.570).dy, p(0.378, 0.555).dx, p(0.378, 0.555).dy)
      ..close();

    final lombok = Path()
      ..moveTo(p(0.410, 0.555).dx, p(0.410, 0.555).dy)
      ..quadraticBezierTo(p(0.420, 0.550).dx, p(0.420, 0.550).dy, p(0.428, 0.555).dx, p(0.428, 0.555).dy)
      ..quadraticBezierTo(p(0.426, 0.576).dx, p(0.426, 0.576).dy, p(0.412, 0.574).dx, p(0.412, 0.574).dy)
      ..close();

    final sumbawa = Path()
      ..moveTo(p(0.434, 0.558).dx, p(0.434, 0.558).dy)
      ..lineTo(p(0.450, 0.546).dx, p(0.450, 0.546).dy)
      ..lineTo(p(0.470, 0.558).dx, p(0.470, 0.558).dy)
      ..lineTo(p(0.455, 0.578).dx, p(0.455, 0.578).dy)
      ..lineTo(p(0.436, 0.574).dx, p(0.436, 0.574).dy)
      ..close();

    final flores = Path()
      ..moveTo(p(0.478, 0.562).dx, p(0.478, 0.562).dy)
      ..quadraticBezierTo(p(0.505, 0.556).dx, p(0.505, 0.556).dy, p(0.534, 0.562).dx, p(0.534, 0.562).dy)
      ..quadraticBezierTo(p(0.510, 0.572).dx, p(0.510, 0.572).dy, p(0.478, 0.562).dx, p(0.478, 0.562).dy)
      ..close();

    final sumba = Path()
      ..moveTo(p(0.478, 0.592).dx, p(0.478, 0.592).dy)
      ..quadraticBezierTo(p(0.505, 0.588).dx, p(0.505, 0.588).dy, p(0.512, 0.606).dx, p(0.512, 0.606).dy)
      ..quadraticBezierTo(p(0.490, 0.608).dx, p(0.490, 0.608).dy, p(0.478, 0.592).dx, p(0.478, 0.592).dy)
      ..close();

    final timor = Path()
      ..moveTo(p(0.538, 0.585).dx, p(0.538, 0.585).dy)
      ..quadraticBezierTo(p(0.558, 0.570).dx, p(0.558, 0.570).dy, p(0.572, 0.584).dx, p(0.572, 0.584).dy)
      ..quadraticBezierTo(p(0.552, 0.602).dx, p(0.552, 0.602).dy, p(0.538, 0.585).dx, p(0.538, 0.585).dy)
      ..close();

    // ── 4. PULAU KALIMANTAN (Curved Grand Mass) ───────────────────────────────
    final kalimantan = Path()
      ..moveTo(p(0.258, 0.290).dx, p(0.258, 0.290).dy) // Pontianak
      ..quadraticBezierTo(p(0.270, 0.238).dx, p(0.270, 0.238).dy, p(0.298, 0.224).dx, p(0.298, 0.224).dy) // Sambas / Sarawak border
      ..quadraticBezierTo(p(0.335, 0.228).dx, p(0.335, 0.228).dy, p(0.370, 0.218).dx, p(0.370, 0.218).dy) // Nunukan
      ..quadraticBezierTo(p(0.388, 0.250).dx, p(0.388, 0.250).dy, p(0.392, 0.302).dx, p(0.392, 0.302).dy) // Mangkalihat cape
      ..quadraticBezierTo(p(0.384, 0.355).dx, p(0.384, 0.355).dy, p(0.374, 0.392).dx, p(0.374, 0.392).dy) // Balikpapan
      ..quadraticBezierTo(p(0.364, 0.432).dx, p(0.364, 0.432).dy, p(0.344, 0.446).dx, p(0.344, 0.446).dy) // Kotabaru
      ..quadraticBezierTo(p(0.318, 0.442).dx, p(0.318, 0.442).dy, p(0.295, 0.436).dx, p(0.295, 0.436).dy) // Banjarmasin & Sampit
      ..quadraticBezierTo(p(0.268, 0.424).dx, p(0.268, 0.424).dy, p(0.250, 0.390).dx, p(0.250, 0.390).dy) // Tanjung Puting
      ..quadraticBezierTo(p(0.246, 0.340).dx, p(0.246, 0.340).dy, p(0.258, 0.290).dx, p(0.258, 0.290).dy) // Karimata strait
      ..close();

    // ── 5. PULAU SULAWESI (Iconic 4-Tentacle Orchid Curves) ────────────────────
    final sulawesi = Path()
      ..moveTo(p(0.518, 0.212).dx, p(0.518, 0.212).dy) // Manado tip
      ..quadraticBezierTo(p(0.498, 0.250).dx, p(0.498, 0.250).dy, p(0.470, 0.278).dx, p(0.470, 0.278).dy) // Gorontalo & Toli-Toli
      ..quadraticBezierTo(p(0.448, 0.308).dx, p(0.448, 0.308).dy, p(0.440, 0.345).dx, p(0.440, 0.345).dy) // Palu & Mamuju
      ..quadraticBezierTo(p(0.436, 0.400).dx, p(0.436, 0.400).dy, p(0.438, 0.455).dx, p(0.438, 0.455).dy) // Makassar
      ..quadraticBezierTo(p(0.448, 0.470).dx, p(0.448, 0.470).dy, p(0.458, 0.450).dx, p(0.458, 0.450).dy) // Bantaeng to Sinjai
      ..quadraticBezierTo(p(0.460, 0.395).dx, p(0.460, 0.395).dy, p(0.474, 0.390).dx, p(0.474, 0.390).dy) // Bone gulf junction
      ..quadraticBezierTo(p(0.495, 0.438).dx, p(0.495, 0.438).dy, p(0.510, 0.412).dx, p(0.510, 0.412).dy) // Kendari peninsula
      ..quadraticBezierTo(p(0.490, 0.370).dx, p(0.490, 0.370).dy, p(0.478, 0.340).dx, p(0.478, 0.340).dy) // Poso
      ..quadraticBezierTo(p(0.510, 0.334).dx, p(0.510, 0.334).dy, p(0.526, 0.350).dx, p(0.526, 0.350).dy) // Luwuk east arm
      ..quadraticBezierTo(p(0.498, 0.324).dx, p(0.498, 0.324).dy, p(0.466, 0.315).dx, p(0.466, 0.315).dy) // Tomini
      ..close();

    final butonPt = p(0.492, 0.435);
    final buton = Path()..addOval(Rect.fromLTWH(butonPt.dx, butonPt.dy, w * 0.018, h * 0.045));

    // ── 6. KEPULAUAN MALUKU ───────────────────────────────────────────────────
    final halmahera = Path()
      ..moveTo(p(0.562, 0.225).dx, p(0.562, 0.225).dy)
      ..lineTo(p(0.575, 0.205).dx, p(0.575, 0.205).dy)
      ..lineTo(p(0.578, 0.245).dx, p(0.578, 0.245).dy)
      ..lineTo(p(0.588, 0.235).dx, p(0.588, 0.235).dy)
      ..lineTo(p(0.578, 0.270).dx, p(0.578, 0.270).dy)
      ..lineTo(p(0.562, 0.290).dx, p(0.562, 0.290).dy)
      ..lineTo(p(0.555, 0.255).dx, p(0.555, 0.255).dy)
      ..close();

    final seram = Path()
      ..moveTo(p(0.568, 0.350).dx, p(0.568, 0.350).dy)
      ..quadraticBezierTo(p(0.590, 0.344).dx, p(0.590, 0.344).dy, p(0.610, 0.346).dx, p(0.610, 0.346).dy)
      ..quadraticBezierTo(p(0.590, 0.362).dx, p(0.590, 0.362).dy, p(0.568, 0.362).dx, p(0.568, 0.362).dy)
      ..close();

    final buruPt = p(0.535, 0.345);
    final buru = Path()..addOval(Rect.fromLTWH(buruPt.dx, buruPt.dy, w * 0.024, h * 0.026));

    // ── 7. PULAU PAPUA (Curved Vogelkop and Vast South) ───────────────────────
    final papua = Path()
      // Kepala Burung (Bird's Head)
      ..moveTo(p(0.628, 0.285).dx, p(0.628, 0.285).dy) // Sorong
      ..quadraticBezierTo(p(0.645, 0.262).dx, p(0.645, 0.262).dy, p(0.668, 0.265).dx, p(0.668, 0.265).dy) // Manokwari
      ..quadraticBezierTo(p(0.668, 0.300).dx, p(0.668, 0.300).dy, p(0.648, 0.312).dx, p(0.648, 0.312).dy) // Bintuni
      ..quadraticBezierTo(p(0.636, 0.348).dx, p(0.636, 0.348).dy, p(0.656, 0.360).dx, p(0.656, 0.360).dy) // Fakfak & Kaimana
      ..quadraticBezierTo(p(0.685, 0.318).dx, p(0.685, 0.318).dy, p(0.708, 0.305).dx, p(0.708, 0.305).dy) // Teluk Cenderawasih
      ..quadraticBezierTo(p(0.745, 0.310).dx, p(0.745, 0.310).dy, p(0.785, 0.320).dx, p(0.785, 0.320).dy) // Jayapura border
      ..quadraticBezierTo(p(0.788, 0.440).dx, p(0.788, 0.440).dy, p(0.788, 0.490).dx, p(0.788, 0.490).dy) // Merauke border
      ..quadraticBezierTo(p(0.770, 0.512).dx, p(0.770, 0.512).dy, p(0.742, 0.485).dx, p(0.742, 0.485).dy) // Merauke south to Asmat
      ..quadraticBezierTo(p(0.710, 0.440).dx, p(0.710, 0.440).dy, p(0.682, 0.398).dx, p(0.682, 0.398).dy) // Timika
      ..close();

    final biakPt = p(0.682, 0.265);
    final biak = Path()..addOval(Rect.fromLTWH(biakPt.dx, biakPt.dy, w * 0.024, h * 0.018));
    final yapenPt = p(0.688, 0.290);
    final yapen = Path()..addOval(Rect.fromLTWH(yapenPt.dx, yapenPt.dy, w * 0.032, h * 0.015));

    // List of all islands
    final allIslands = [
      sumatera, nias, mentawai, bangka, belitung,
      jawa, madura,
      bali, lombok, sumbawa, flores, sumba, timor,
      kalimantan,
      sulawesi, buton,
      halmahera, seram, buru,
      papua, biak, yapen,
    ];

    // 1. Draw shallow water reef buffer (Paparan Sunda & Paparan Sahul)
    for (final island in allIslands) {
      canvas.drawPath(island, shelfPaint);
    }

    // 2. Draw solid landmass & fine coastlines
    for (final island in allIslands) {
      canvas.drawPath(island, landPaint);
      canvas.drawPath(island, coastPaint);
    }

    // 3. Draw Mountain Ridges (Topography spine)
    // Bukit Barisan (Sumatera)
    final bukitBarisan = Path()
      ..moveTo(p(0.060, 0.140).dx, p(0.060, 0.140).dy)
      ..quadraticBezierTo(p(0.085, 0.250).dx, p(0.085, 0.250).dy, p(0.115, 0.380).dx, p(0.115, 0.380).dy)
      ..quadraticBezierTo(p(0.140, 0.450).dx, p(0.140, 0.450).dy, p(0.155, 0.490).dx, p(0.155, 0.490).dy);
    canvas.drawPath(bukitBarisan, ridgePaint);

    // Pegunungan Jawa (Kendeng / Wilis / Semeru)
    final jawaRidge = Path()
      ..moveTo(p(0.205, 0.540).dx, p(0.205, 0.540).dy)
      ..quadraticBezierTo(p(0.275, 0.545).dx, p(0.275, 0.545).dy, p(0.350, 0.555).dx, p(0.350, 0.555).dy);
    canvas.drawPath(jawaRidge, ridgePaint);

    // Pegunungan Schwaner / Muller (Kalimantan)
    final kalimantanRidge = Path()
      ..moveTo(p(0.290, 0.340).dx, p(0.290, 0.340).dy)
      ..quadraticBezierTo(p(0.335, 0.330).dx, p(0.335, 0.330).dy, p(0.360, 0.280).dx, p(0.360, 0.280).dy);
    canvas.drawPath(kalimantanRidge, ridgePaint);

    // Pegunungan Jayawijaya (Papua)
    final papuaRidge = Path()
      ..moveTo(p(0.680, 0.350).dx, p(0.680, 0.350).dy)
      ..quadraticBezierTo(p(0.730, 0.370).dx, p(0.730, 0.370).dy, p(0.775, 0.380).dx, p(0.775, 0.380).dy);
    canvas.drawPath(papuaRidge, ridgePaint);

    // 4. Highlight active areas (Sumbar, Jogja, Bali) with royal emerald fill
    canvas.drawPath(sumbarHighlight, activeHighlight);
    canvas.drawPath(jogjaHighlight, activeHighlight);
    canvas.drawPath(bali, activeHighlight);

    // 5. Engraved Island Group Text Labels
    _drawIslandLabel(canvas, 'SUMATERA', p(0.110, 0.240));
    _drawIslandLabel(canvas, 'KALIMANTAN', p(0.305, 0.315));
    _drawIslandLabel(canvas, 'JAWA', p(0.245, 0.582));
    _drawIslandLabel(canvas, 'SULAWESI', p(0.465, 0.360));
    _drawIslandLabel(canvas, 'MALUKU', p(0.575, 0.310));
    _drawIslandLabel(canvas, 'PAPUA', p(0.715, 0.380));
  }

  void _drawIslandLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.88),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          fontFamily: 'NusaSans',
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 2.5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawEquatorLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF3F7F98).withValues(alpha: 0.85),
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontFamily: 'NusaSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_IndonesiaArchipelagoPainter oldDelegate) => false;
}
