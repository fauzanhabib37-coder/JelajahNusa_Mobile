# Arsitektur dan keputusan implementasi

Aplikasi memakai pemisahan UI, state aplikasi, penyimpanan, dan katalog. `Catalog` memvalidasi relasi dan soal ketika dimuat. `QuizSession` hanya menangani pilihan, penguncian jawaban, dan perhitungan hasil. `AppState` menerapkan aturan akun/progres dan mengantrekan setiap perubahan agar operasi berdekatan tidak saling menimpa.

Setiap mutasi membuat salinan snapshot, menerapkan perubahan pada salinan, lalu menulisnya. State yang terlihat baru diganti setelah write berhasil. Kegagalan tulis mempertahankan data sebelumnya. `LocalStore` adalah antarmuka injeksi; versi produksi memakai SharedPreferences, pengujian memakai penyimpanan memori yang dapat mensimulasikan kegagalan.

Saat akun berganti atau logout, identitas MaterialApp berubah sehingga stack navigasi akun sebelumnya dibuang. Pembukaan materi dikunci selama route aktif dan navigasi dimulai segera, sehingga write riwayat yang lambat tidak memunculkan halaman terlambat setelah perpindahan tab. Kuis memakai PopScope dan dialog sebelum dibatalkan. Hasil baru dibuka setelah progres tersimpan.

Konten tetap lokal dan terpisah dari kode layar. Tidak dipasang backend, analitik eksternal, iklan, sensor, atau audio yang tidak tersedia. Profil lokal bukan batas keamanan terhadap orang yang dapat mengubah penyimpanan perangkat. Penggantian penyimpanan menjadi server harus disertai autentikasi dan otorisasi server; UI tidak cukup untuk menjamin akses.
