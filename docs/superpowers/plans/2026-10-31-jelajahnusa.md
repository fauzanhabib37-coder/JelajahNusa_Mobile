# JelajahNusa Implementation Plan

**Goal:** Aplikasi belajar budaya Flutter/Dart sesuai UI yang disetujui, dengan akun lokal dan progres persisten.
**Architecture:** UI -> AppState -> LocalStore; katalog konten immutable; QuizSession untuk penilaian.
**Tech Stack:** Flutter stable, Dart, shared_preferences, cryptography; font dan gambar lokal.

## Urutan pelaksanaan
- [x] Periksa desain, aset, lisensi font, dan konsep lama; lengkapi dua mockup autentikasi sebelum aplikasi.
- [x] Scaffold Android/iOS/web, salin aset terkompresi dan font, daftarkan pubspec.
- [x] Buat data sembilan materi dan 45 soal dengan sumber; validasi identitas dan indeks jawaban.
- [x] Tulis dan jalankan uji awal yang menunjukkan fungsi state/kuis belum tersedia.
- [x] Implementasikan LocalStore, AppState, QuizSession; uji akun lokal, sesi, bookmark, histori, reset, dan poin terbaik.
- [x] Implementasikan theme/widgets, autentikasi, empat tab, detail/materi, kuis/hasil/pembahasan.
- [x] Jalankan widget tests dan uji layout 320/390/430, scale 1.0/1.3/1.5; perbaiki kegagalan berdasarkan sebab.
- [x] flutter analyze; flutter test; flutter build web. Jika toolchain Android tersedia, build APK debug.
- [x] Simpan README, laporan validasi, desain UI dan manifest aset; kemas source tanpa SDK/build cache.

## Pemeriksaan inti
`flutter test test/state_test.dart`: total poin 40 -> 40 -> 50 pada skor 4/5 -> 4/5 -> 5/5; akun B tidak melihat progres A; logout lalu init tetap keluar; login A memulihkan data.
`flutter test test/widget_test.dart`: daftar/login -> Bali -> materi -> lima soal -> hasil -> profil; tombol belum aktif tanpa pilihan; pengulangan ketuk terkunci.
`flutter analyze`: tidak ada masalah.
`flutter build web --release`: menghasilkan build/web/index.html.

Pelaksanaan: seluruh tugas selesai. Build Android/iOS tidak dijalankan karena toolchain tidak tersedia; batas ini dicatat pada README dan VALIDATION.
