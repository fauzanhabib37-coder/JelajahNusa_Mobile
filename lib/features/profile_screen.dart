import 'package:flutter/material.dart';
import '../app.dart' show goToAuth;
import '../core/app_state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'result_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppState state;
  const ProfileScreen({super.key, required this.state});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool busy = false;
  Future<void> action(Future<void> Function() callback) async {
    if (busy) return;
    setState(() => busy = true);
    await perform(context, callback);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    if (s.isGuest) {
      return _GuestProfilePage(
        state: s,
        onSignIn: () => goToAuth(context, s),
      );
    }
    return Column(
      children: [
        const PageHeader('Profil penjelajah', back: false),
        Expanded(
          child: PageBody(
            children: [
              const SizedBox(height: 18),
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Nusa.soft,
                  child: Text(
                    s.name.isEmpty
                        ? 'N'
                        : String.fromCharCode(s.name.runes.first).toUpperCase(),
                    style: Nusa.heading(34, Nusa.green),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.name,
                style: Nusa.heading(27),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                s.completedCount == 0
                    ? 'Penjelajah pemula'
                    : 'Penjelajah budaya',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Nusa.muted),
              ),
              Text(
                s.email,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Nusa.muted),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: busy ? null : () => _rename(context),
                  child: const Text('Ubah nama'),
                ),
              ),
              const SizedBox(height: 20),
              Stats([
                ('${s.points}', 'Total poin'),
                (
                  '${s.completedCount} / ${s.catalog.lessons.length}',
                  'Materi selesai',
                ),
                ('${s.badges.length}', 'Lencana'),
              ]),
              const SizedBox(height: 28),
              const SectionTitle('Jejak pencapaian'),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final id in [
                    'langkah_pertama',
                    'penjelajah',
                    'lintas_daerah',
                  ])
                    Expanded(child: _badge(id, s.badges.contains(id))),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Langkah Pertama: 1 materi selesai. Penjelajah: semua materi satu daerah. Lintas Daerah: belajar di ketiga daerah.',
                style: TextStyle(color: Nusa.muted, fontSize: 10),
              ),
              const SizedBox(height: 26),
              _row(
                Icons.menu_book_outlined,
                'Tentang JelajahNusa',
                () => _about(context),
              ),
              const SizedBox(height: 10),
              _row(
                Icons.restart_alt_outlined,
                'Reset progres akun',
                busy
                    ? null
                    : () async {
                        if (await confirm(
                          context,
                          title: 'Reset progres akun ini?',
                          message:
                              'Poin, lencana, materi selesai, riwayat, dan bookmark ${s.name} akan dihapus. Akun lain tidak berubah.',
                          action: 'Reset progres',
                        )) {
                          await action(s.resetProgress);
                        }
                      },
              ),
              const SizedBox(height: 10),
              _row(
                Icons.logout,
                'Keluar akun',
                busy
                    ? null
                    : () async {
                        if (await confirm(
                          context,
                          title: 'Keluar dari akun?',
                          message:
                              'Progresmu tetap tersimpan pada perangkat ini. Masuk kembali untuk melanjutkan.',
                          action: 'Keluar akun',
                        )) {
                          await action(s.logout);
                        }
                      },
              ),
              const SizedBox(height: 24),
              const Text(
                'JelajahNusa 1.0.0 · Dirawat melalui rasa ingin tahu',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Nusa.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge(String id, bool active) => Tooltip(
    message:
        '${badgeName(id)}: ${active ? 'sudah diperoleh' : 'belum diperoleh'}',
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Opacity(
            opacity: active ? 1 : 0.35,
            child: Image.asset('assets/badges/$id.png', width: 64, height: 64),
          ),
          const SizedBox(height: 10),
          Text(
            badgeName(id),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: active ? Nusa.green : Nusa.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            active ? 'Terbuka' : 'Belum',
            style: const TextStyle(fontSize: 9, color: Nusa.muted),
          ),
        ],
      ),
    ),
  );
  Widget _row(IconData icon, String text, VoidCallback? onTap) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      minVerticalPadding: 14,
      leading: Icon(icon, color: Nusa.green, size: 22),
      title: Text(text, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Nusa.green),
      onTap: onTap,
    ),
  );
  Future<void> _rename(BuildContext context) async {
    final controller = TextEditingController(text: widget.state.name);
    final form = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Nama penjelajah', style: Nusa.heading(23)),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            validator: (v) => AppState.nameError(v ?? ''),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(c, controller.text.trim());
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    // The dialog's closing animation may still use its controller; dispose after it.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (value != null && mounted) {
      await action(() => widget.state.rename(value));
    }
  }

  void _about(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(c).height * 0.8,
        child: PageBody(
          children: [
            const Brand(),
            const SizedBox(height: 20),
            Text('Tentang JelajahNusa', style: Nusa.heading(26)),
            const SizedBox(height: 14),
            const Text(
              'Belajar mengenal budaya dan keragaman bahasa Indonesia melalui cerita singkat, refleksi, dan kuis. Versi 1.0.0 memuat 3 daerah dan 9 materi pengantar.',
            ),
            const SizedBox(height: 18),
            const HintBox(
              title: 'Perjalanan pada perangkatmu',
              body:
                  'Akun dan progres disimpan lokal. Email tidak diverifikasi. Tidak ada sinkronisasi antarperangkat atau layanan pemulihan kata sandi daring.',
              icon: Icons.devices_outlined,
            ),
            const SizedBox(height: 18),
            const Text(
              'Ilustrasi bersifat dekoratif, dibuat untuk desain JelajahNusa. Font DejaVu disertakan dengan lisensinya. Audio pelafalan belum tersedia. Batik dan gamelan juga berkembang di daerah lain, bukan hanya Yogyakarta.',
            ),
            const SizedBox(height: 20),
            const SectionTitle('Sumber materi'),
            const SizedBox(height: 12),
            ...widget.state.catalog.lessons.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    ...l.sources.map(
                      (source) => SelectableText(
                        '${source.publisher} · ${source.title}\n${source.url}',
                        style: const TextStyle(fontSize: 10, color: Nusa.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Kembali belajar'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Guest profile page shown when user is not signed in.
class _GuestProfilePage extends StatelessWidget {
  final AppState state;
  final VoidCallback onSignIn;
  const _GuestProfilePage({required this.state, required this.onSignIn});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const PageHeader('Profil penjelajah', back: false),
      Expanded(
        child: PageBody(
          children: [
            const SizedBox(height: 18),
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Nusa.soft,
                child: Text(
                  'T',
                  style: Nusa.heading(34, Nusa.green),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Penjelajah Tamu',
              style: Nusa.heading(27),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            const Text(
              'Mode tamu · Tanpa akun',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Nusa.muted),
            ),
            const SizedBox(height: 20),
            Stats([
              (
                '${state.guestLessonCount}/${AppState.guestLimit}',
                'Materi dijelajahi',
              ),
              ('0', 'Total poin'),
              ('0', 'Lencana'),
            ]),
            const SizedBox(height: 28),
            const HintBox(
              title: 'Simpan progresmu',
              body:
                  'Buat akun gratis untuk menyimpan progres belajar, mendapat poin, lencana, dan mengakses semua materi tanpa batas.',
              icon: Icons.star_outline,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('guest_create_account'),
              onPressed: onSignIn,
              child: const Text('Buat Akun'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('guest_signin'),
              onPressed: onSignIn,
              child: const Text('Sudah punya akun? Masuk'),
            ),
            const SizedBox(height: 24),
            const Text(
              'JelajahNusa 1.0.0 · Dirawat melalui rasa ingin tahu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: Nusa.muted),
            ),
          ],
        ),
      ),
    ],
  );
}
