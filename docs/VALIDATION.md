# Hasil verifikasi — 31 Oktober 2026

Lingkungan: Linux x64, Flutter 3.35.7 (framework adc9010625), Dart 3.9.2. Paket aplikasi versi 1.0.0+1. Dependency resolution berhasil dan dikunci melalui pubspec.lock.

| Pemeriksaan | Hasil | Bukti |
|---|---|---|
| `flutter analyze` | Lulus, tidak ada masalah | `validation/flutter_analyze.log` |
| `flutter test --reporter expanded` | 29 lulus; 1 ekspor pratinjau opsional dilewati pada suite standar | `validation/flutter_test.log` |
| `flutter build web --release` | Lulus; menghasilkan `build/web/index.html` | `validation/flutter_build_web.log` |
| Ekspor widget dengan `RENDER_PREVIEWS=true` | Lulus; 10 PNG dihasilkan dari widget Flutter | `validation/flutter_preview_export.log`, `design/runtime/screens/` |
| Aset lokal | 17 berkas tidak kosong; semua PNG/WebP dapat didekode | `ASSET_MANIFEST.json` |
| Katalog | 3 daerah, 9 materi, 45 soal, ID unik, relasi benar, opsi/jawaban valid | Pengujian katalog dan `CONTENT_SOURCES.md` |

## Cakupan 17 pengujian inti

Instalasi baru tanpa progres contoh; daftar dan pemulihan sesi; penyimpanan hash bersalt; logout persisten; penolakan kredensial salah/duplikat/masukan tidak valid; nilai terbaik dan penyelesaian nilai nol; isolasi data antar akun; riwayat unik persisten; rollback ketika write gagal; serialisasi mutasi bersamaan; penanganan JSON rusak tanpa penghapusan otomatis; penguncian jawaban; adapter SharedPreferences; reset tanpa menghapus akun; syarat lencana; kegagalan simpan hasil; salt acak untuk kata sandi identik.

## Cakupan 12 pengujian widget

- Pendaftaran lewat form → Beranda → Bali → materi → bookmark → lima soal dan umpan balik → hasil → pembahasan → daerah → profil → logout.
- Regresi ketukan cepat: hanya satu route materi, satu kali kembali menuju halaman asal.
- Sembilan kombinasi lebar 320/390/430 logical pixels dan skala teks 1.0/1.3/1.5. Memeriksa login, tab utama, detail daerah, materi, kuis, dan hasil tanpa overflow.
- Keluar kuis belum selesai menampilkan konfirmasi; pembatalan mempertahankan kuis dan tidak memberi progres palsu.

## Pemeriksaan visual dan perbaikan

Pratinjau memakai font lokal, ikon, serta gambar yang dipramuat dan didekode sebelum ekspor. Angka Nara pada pratinjau merupakan data fiktif, bukan isi awal instalasi. Perbaikan ekspor WebP Sumatera Barat dilakukan dari PNG sumber karena ekspor lama berukuran nol. Pembukaan route materi diberi guard setelah review menemukan potensi duplikasi pada ketukan cepat; regresi mula-mula menunjukkan dua route dan lulus setelah perbaikan.

## Batas verifikasi

Belum melakukan build APK atau pengujian pada emulator/ponsel Android karena Android SDK tidak tersedia. Build iOS belum dijalankan karena lingkungan bukan macOS/Xcode. Build web membuktikan kompilasi target web; tidak membuktikan seluruh perilaku platform Android/iOS. Tidak ada klaim autentikasi server, sinkronisasi, atau uji efektivitas belajar. Source dan petunjuk build Android disertakan; output build dan cache tidak dimasukkan dalam ZIP source.
