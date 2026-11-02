# JelajahNusa — spesifikasi implementasi

Dasar: UI dan aset yang telah disetujui pada percakapan sebelumnya, ditambah login/logout. Target pertama Android; source Flutter/Dart juga menyediakan iOS dan web. Data lokal, tanpa server atau sinkronisasi. Akun terpisah pada satu perangkat; kata sandi disimpan sebagai derivasi PBKDF2-HMAC-SHA256 dengan salt acak, bukan teks biasa. Sesi lokal bukan identitas daring terverifikasi.

## Desain sebelum implementasi
Delapan layar dan empat ilustrasi tersedia pada paket Design_Kit. Dua layar autentikasi dilengkapi sebelum penulisan aplikasi. Warna #426B50, latar #F8F9F5, tinta #23372C; font DejaVu lokal beralias NusaSans/NusaSerif. Asset asli yang telah dibuat dipakai kembali, tidak diambil dari crop screenshot. Seluruh UI memakai scroll dan area sentuh minimum 48.

## Ruang lingkup
Beranda, pencarian daerah/materi, kategori Budaya/Bahasa, detail daerah, materi bersumber, bookmark, riwayat, kuis lima soal, umpan balik, hasil, pembahasan, profil, ubah nama, lencana, reset progres akun aktif, login, daftar, logout. Tiga daerah Bali, DI Yogyakarta, Sumatera Barat; dua materi budaya dan satu pengantar bahasa per daerah. Tidak ada audio pelafalan tanpa media autentik.

## Aturan
Materi selesai ketika kuis selesai, sekalipun skor nol. Skor benar/5*100; poin 10 per jawaban benar. Total poin adalah jumlah nilai terbaik setiap materi; ulang skor sama atau lebih rendah menambah nol. Keluar kuis yang belum selesai memerlukan konfirmasi. Riwayat unik terbaru di depan. Reset hanya akun aktif; akun dan sesi tetap. Logout membersihkan navigasi terlindungi dan tidak menghapus progres. Instalasi baru bernilai nol.

## Arsitektur
Data JSON immutable divalidasi ContentRepository. AppState ChangeNotifier memegang sesi dan data aktif; LocalStore abstrak membungkus SharedPreferences, sehingga persistensi dapat diuji. QuizSession murni mengunci jawaban dan menghitung skor. Widget hanya mengatur presentasi dan interaksi. Satu snapshot JSON versioned menyimpan akun, sesi, progres; gagal tulis mengembalikan state sebelumnya dan menampilkan kesalahan. Data rusak ditangani sebagai error yang membutuhkan pilihan eksplisit, bukan reset diam-diam.

## Penerimaan
flutter analyze bersih; unit test autentikasi/persistensi/isolasi/poin/kuis; widget test login, kuis, bookmark, reset, logout dan layout lebar 320/390/430 serta text scaling 1.0/1.3/1.5. flutter build web sebagai bukti kompilasi; APK hanya diklaim jika Android toolchain tersedia dan build benar-benar berhasil. README berbahasa Indonesia berisi setup/run/build dan batas lokal. Ilustrasi dekoratif tidak dianggap dokumentasi budaya.
