# termux-miner

Script satu file untuk setup mining **VRSC** (ccminer) dan **XMR** (xmrig) di Termux Android.
Untuk eksperimen dan belajar. Hasil di HP sangat kecil.

## Cara pakai

```bash
pkg install git -y
git clone https://github.com/andi9/termux-miner.git
cd termux-miner
bash termux-miner.sh
```

Alur menu:

```
Menu mining
 1) XMR
      1) Install - Cara A: pkg install (sering gagal di Android lama)
      2) Install - Cara B: compile dari source (berhasil di Android 8)
      3) Mulai mining -> pilih RAM (hemat ~256 MB / penuh ~2,3 GB) -> pilih thread
 2) VRSC
      1) Install ccminer (unduh dari GitHub)
      2) Salin dari ccminer yang sudah ada di HP
      3) Mulai mining -> pilih thread
 3) Pengaturan wallet & worker
```

Isi alamat wallet di menu 3 (sekali saja), lalu pilih XMR atau VRSC.

## Membuat wallet dan memantau hasil

- **XMR:** unduh aplikasi **Monerujo**, buat wallet, salin alamatnya (diawali angka 4 atau 8).
- **VRSC:** unduh aplikasi **Verus Mobile**, buat wallet, salin alamatnya (diawali huruf R).
- **Pantau VRSC:** buka [luckpool.net](https://luckpool.net), tempel alamat VRSC kamu.
- **Pantau XMR:** buka [supportxmr.com](https://supportxmr.com), tempel alamat XMR kamu.
- Catat seed phrase di kertas, jangan difoto dan jangan dibagikan.

## Catatan

- Paket yang dibutuhkan (git, cmake, clang, wget, dll.) dipasang otomatis saat memilih menu Install.
- Diuji untuk Android 8, arsitektur aarch64 (64-bit).
- VRSC (VerusHash) jauh lebih cocok untuk CPU ARM daripada XMR (RandomX).
- XMR dijalankan di mode `light` karena RAM HP kecil (mode biasa butuh ~2,3 GB dan proses akan di-kill Android).
- Compile xmrig memakan 10-30 menit dan membuat HP hangat.
- Jangan jalankan XMR dan VRSC bersamaan. Mulai dari 2 thread, pantau suhu, dan jangan dibiarkan semalaman sambil dicas.
- Alamat wallet disimpan lokal di `~/.termux-miner.conf`, bukan di script.

## Lisensi

Bebas dipakai dan dibagikan. xmrig dan ccminer adalah proyek terpisah dengan lisensinya masing-masing.
