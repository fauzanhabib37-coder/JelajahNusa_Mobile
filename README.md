# JelajahNusa — Flutter / Dart

Aplikasi mobile untuk mengenal budaya dan keragaman bahasa Indonesia melalui materi singkat, refleksi, dan kuis. UI mengikuti referensi sage–ivory: ilustrasi daerah, judul serif, kartu membulat, serta empat tab utama. UI dan aset disiapkan sebelum implementasi; papan rancangan dan pratinjau widget tersedia di `design/`.

## Menjalankan aplikasi

Proyek ini sudah mencakup konfigurasi Android, iOS, dan web. Pengembangan dan verifikasi memakai **Flutter 3.35.7 / Dart 3.9.2**. Gunakan versi tersebut untuk mereproduksi hasil pemeriksaan; versi Flutter lebih baru dapat digunakan dengan menjalankan kembali analisis dan pengujian.

1. Instal Flutter dan Android Studio. Untuk Android, siapkan SDK API 36, platform-tools, emulator atau ponsel dengan USB debugging. Toolchain Gradle memerlukan JDK 17. Android minimum API 24 (Android 7.0).
2. Ekstrak ZIP, lalu buka folder `JelajahNusa` yang berisi `pubspec.yaml` melalui VS Code atau Android Studio.
3. Jalankan dari terminal folder proyek:

```sh
flutter doctor
flutter doctor --android-licenses
flutter pub get
flutter devices
flutter run
```

Pilih emulator atau ponsel ketika diminta. Tidak perlu API key, database, atau server. Pada halaman pertama, pilih **Daftar**, masukkan nama, email, dan kata sandi minimal 8 karakter. Tidak ada akun contoh yang ditanam dalam aplikasi.

Untuk mencoba dari Chrome:

```sh
flutter run -d chrome
```

Flutter SDK: https://docs.flutter.dev/install

## Membuat APK

Setelah Android toolchain siap:

```sh
flutter build apk --debug
```

Hasil: `build/app/outputs/flutter-apk/app-debug.apk`. **APK belum dibangun dalam paket ini** karena lingkungan verifikasi tidak menyediakan Android SDK. Proyek telah dikompilasi untuk web; itu tidak menggantikan pengujian pada perangkat Android.

Konfigurasi release saat ini memakai kunci debug bawaan agar pengembangan lokal mudah dijalankan. Sebelum distribusi toko aplikasi, siapkan application ID milik Anda dan release signing milik Anda. Jangan memasukkan keystore atau rahasia signing ke repositori.

iOS memerlukan macOS, Xcode, dan konfigurasi signing sesuai tujuan penggunaan. Source iOS disertakan, tetapi build iOS belum diuji.

## Fitur yang tersedia

- Daftar, login, pemulihan sesi lokal, logout, dan ubah nama.
- Beranda; daftar tiga daerah; pencarian daerah/materi; filter Budaya/Bahasa.
- Bali, DI Yogyakarta, Sumatera Barat: masing-masing tiga materi, total sembilan.
- Materi, pertanyaan refleksi, sumber resmi dan tautan bacaan, bookmark, serta riwayat unik dari yang terbaru.
- Lima soal per materi, total 45 soal; jawaban dikunci sesudah diperiksa dan dilengkapi penjelasan.
- Hasil, pembahasan, pengulangan kuis, poin berdasarkan hasil terbaik, dan tiga lencana.
- Reset progres akun aktif dengan konfirmasi; akun lain tetap terpisah.
- Penyimpanan yang gagal menampilkan kesalahan dan tidak mengakui perubahan sebagai tersimpan.
- Pembacaan data rusak menyediakan coba lagi atau reset eksplisit, bukan penghapusan otomatis.

Semua materi dan aset tersedia lokal. Membuka tautan sumber membutuhkan internet dan aplikasi browser. Materi bahasa merupakan pengantar sebaran dan variasi; audio pelafalan belum tersedia. Batik dan gamelan juga berkembang di daerah lain di luar Yogyakarta. Ilustrasi bersifat dekoratif, bukan dokumentasi arsitektur atau benda budaya.

## Aturan skor dan progres

Satu jawaban benar = 20 skor dan 10 poin. Materi ditandai selesai setelah kuis selesai, termasuk ketika hasilnya nol. Total poin adalah jumlah hasil terbaik setiap materi; maksimal 450 poin untuk sembilan materi.

Contoh: 4/5 → skor 80, mendapat 40 poin. Mengulang dengan 4/5 atau 2/5 → tambahan 0. Membaik ke 5/5 → tambahan 10, total materi menjadi 50 poin.

- **Langkah Pertama:** menyelesaikan satu materi.
- **Penjelajah:** menyelesaikan seluruh materi satu daerah.
- **Lintas Daerah:** menyelesaikan sedikitnya satu materi pada ketiga daerah.

## Akun dan penyimpanan

Akun lokal membantu memisahkan profil pada satu instalasi. Email berfungsi sebagai pengenal dan tidak diverifikasi. Kata sandi disimpan sebagai PBKDF2-HMAC-SHA256, 100.000 iterasi, keluaran 256 bit, dengan salt acak 16 byte per akun; bukan teks biasa. Progres dan sesi disimpan sebagai snapshot JSON berversi melalui SharedPreferences.

Ini belum merupakan autentikasi daring untuk produksi. Data lokal tidak disinkronkan, tidak dienkripsi sebagai satu berkas, dan tidak memiliki pemulihan kata sandi melalui email. Menghapus aplikasi/data browser dapat menghilangkan akun dan progres. Logout mengakhiri sesi, sedangkan reset progres mempertahankan akun. Untuk kebutuhan lintas perangkat, tambahkan backend dan autentikasi server melalui pengembangan tersendiri.

## Struktur proyek

| Lokasi | Tanggung jawab |
|---|---|
| `lib/main.dart`, `lib/app.dart` | Bootstrap, pemuatan, tema, batas sesi dan pemulihan |
| `lib/core/` | State akun, penyimpanan, hash kata sandi, sesi kuis |
| `lib/data/catalog.dart` | Model, pemuatan dan validasi katalog |
| `lib/features/` | Login, empat tab, daerah, materi, kuis, hasil dan pembahasan |
| `lib/ui/` | Token visual dan komponen bersama |
| `assets/data/content.json` | Semua materi, sumber, soal dan jawaban |
| `assets/` | Empat ilustrasi, logo, lencana dan font lokal |
| `design/` | Rancangan awal dan pratinjau hasil widget Flutter |
| `test/` | Pengujian state, navigasi, alur pengguna dan layout |
| `docs/` | Spesifikasi, sumber konten, laporan validasi dan manifest aset |

## Pemeriksaan

```sh
flutter analyze
flutter test
flutter build web --release
```

Ekspor ulang pratinjau widget (opsional):

```sh
flutter test test/render_preview_test.dart --dart-define=RENDER_PREVIEWS=true
```

Hasil pemeriksaan lingkungan ini dicatat pada `docs/VALIDATION.md`. Tangkapan widget menggunakan data fiktif untuk memperlihatkan progres; instalasi baru selalu dimulai dari nol. Pratinjau bukan hasil uji perangkat fisik.

Jika menambah materi, gunakan ID stabil, tepat lima soal dan empat opsi per soal, indeks jawaban 0–3, serta sumber HTTPS. Jalankan kembali seluruh pemeriksaan. Tinjau materi bersama pendidik dan praktisi budaya sebelum dijadikan bahan ajar resmi atau diperluas menjadi kursus bahasa.

## Aset dan lisensi

Ilustrasi digunakan kembali dari paket desain JelajahNusa yang telah disetujui. Ekspor WebP Sumatera Barat dipulihkan dari PNG sumber karena ekspor lama kosong. Tidak ada gambar yang diambil dengan memotong papan screenshot. Logo/lencana tersedia sebagai PNG dan SVG. Font DejaVu diberi alias `NusaSans` dan `NusaSerif`; ketentuan aslinya tersedia pada `assets/fonts/LICENSE.txt`. Catatan gambar dan prompt asal ada di `design/ASSET_NOTES.md` dan `design/GENERATION_PROMPTS.json`. Lisensi dependency tetap mengikuti masing-masing paket dan ditampilkan oleh mekanisme lisensi Flutter pada build.
