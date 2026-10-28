#!/data/data/com.termux/files/usr/bin/bash
# =============================================================
#  termux-miner.sh  -  Menu mining XMR & VRSC untuk Termux
#  Untuk eksperimen/belajar. Hasil di HP sangat kecil.
#  Jalankan:  bash termux-miner.sh
# =============================================================

CONF="$HOME/.termux-miner.conf"
XMRIG_DIR="$HOME/xmrig"
CCMINER_DIR="$HOME/ccminer"

XMR_POOL="pool.supportxmr.com:3333"
VRSC_POOL="stratum+tcp://ap.luckpool.net:3956"
XMR_ADDR=""
VRSC_ADDR=""
WORKER="hp1"
THREADS=2

[ -f "$CONF" ] && . "$CONF"

save_conf() {
  cat > "$CONF" <<EOF
XMR_POOL="$XMR_POOL"
VRSC_POOL="$VRSC_POOL"
XMR_ADDR="$XMR_ADDR"
VRSC_ADDR="$VRSC_ADDR"
WORKER="$WORKER"
THREADS="$THREADS"
EOF
  chmod 600 "$CONF"
}

info()  { echo -e "\n[+] $*"; }
warn()  { echo -e "\n[!] $*"; }
pause() { echo; read -rp "Tekan Enter untuk lanjut... " _; }

cek_termux() {
  if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ]; then
    echo "Script ini hanya untuk Termux."; exit 1
  fi
  [ "$(uname -m)" != "aarch64" ] && \
    warn "Arsitektur $(uname -m): script diuji untuk aarch64 (64-bit)."
}

ram_free_mb() {
  awk '/MemAvailable/ {printf "%d", $2/1024; f=1} END {if(!f) print "?"}' /proc/meminfo 2>/dev/null
}

# ---------- Wallet & pengaturan ----------
set_wallet() {
  echo
  read -rp "Alamat XMR   [${XMR_ADDR:-kosong}]: " a;  [ -n "$a" ] && XMR_ADDR="$a"
  read -rp "Alamat VRSC  [${VRSC_ADDR:-kosong}]: " a; [ -n "$a" ] && VRSC_ADDR="$a"
  read -rp "Nama worker  [$WORKER]: " a;              [ -n "$a" ] && WORKER="$a"
  read -rp "Thread bawaan [$THREADS]: " a;            [ -n "$a" ] && THREADS="$a"
  case "$XMR_ADDR" in ""|4*|8*) ;; *) warn "Alamat XMR biasanya diawali angka 4 atau 8." ;; esac
  case "$VRSC_ADDR" in ""|R*) ;; *) warn "Alamat VRSC biasanya diawali huruf R." ;; esac
  save_conf
  info "Tersimpan di $CONF"
  pause
}

tanya_thread() {
  local t
  read -rp "Jumlah thread [$THREADS] (disarankan 2): " t
  t="${t:-$THREADS}"
  case "$t" in ''|*[!0-9]*) t="$THREADS" ;; esac
  echo "$t"
}

jalankan_miner() {
  # Ctrl+C menghentikan miner saja, lalu kembali ke menu
  command -v termux-wake-lock >/dev/null && termux-wake-lock
  trap ':' INT
  "$@"
  trap - INT
  echo; info "Miner berhenti."
  pause
}

# =====================  XMR  =====================
find_xmrig_bin() {
  for b in "$XMRIG_DIR/build/xmrig-notls" "$XMRIG_DIR/build/xmrig"; do
    [ -x "$b" ] && { echo "$b"; return 0; }
  done
  command -v xmrig 2>/dev/null
}

xmr_install_pkg() {
  info "Cara A: pkg install xmrig lewat tur-repo"
  echo "(Di Android lama cara ini sering gagal. Kalau gagal, pakai Cara B.)"
  pkg install -y tur-repo && pkg update -y && pkg install -y xmrig
  if command -v xmrig >/dev/null; then
    info "xmrig terpasang: $(command -v xmrig)"
  else
    warn "Cara A gagal. Coba Cara B (compile dari source)."
  fi
  pause
}

xmr_install_compile() {
  info "Cara B: compile xmrig dari source (10-30 menit, HP akan hangat)"
  pkg update -y && pkg install -y git cmake clang make libuv openssl || { pause; return; }
  [ -d "$XMRIG_DIR" ] || git clone https://github.com/xmrig/xmrig.git "$XMRIG_DIR" || { pause; return; }
  mkdir -p "$XMRIG_DIR/build" && cd "$XMRIG_DIR/build" || { pause; return; }
  cmake .. -DWITH_HWLOC=OFF -DWITH_TLS=OFF && make -j2
  cd "$HOME" || true
  if find_xmrig_bin >/dev/null; then
    info "xmrig siap: $(find_xmrig_bin)"
  else
    warn "Compile gagal atau file xmrig tidak ditemukan."
  fi
  pause
}

xmr_start() {
  local bin free pil mode t
  bin="$(find_xmrig_bin)" || { warn "xmrig belum terpasang. Pilih menu Install dulu."; pause; return; }
  if [ -z "$XMR_ADDR" ]; then
    warn "Alamat XMR belum diisi."; set_wallet
    [ -z "$XMR_ADDR" ] && return
  fi

  free="$(ram_free_mb)"
  echo
  echo "RAM kosong saat ini: ~${free} MB"
  echo "Pilih penggunaan RAM:"
  echo " 1) Hemat  ~256 MB  (mode light)  - aman untuk HP RAM kecil"
  echo " 2) Penuh  ~2300 MB (mode fast)   - lebih cepat, butuh RAM kosong > 3 GB"
  read -rp "Pilih [1]: " pil
  if [ "$pil" = "2" ]; then
    mode="fast"
    if [ "$free" != "?" ] && [ "$free" -lt 3000 ]; then
      warn "RAM kosong kurang dari 3 GB. Mode penuh kemungkinan di-kill Android."
      read -rp "Tetap lanjut? (y/N): " y
      [ "$y" = "y" ] || [ "$y" = "Y" ] || return
    fi
  else
    mode="light"
  fi

  t="$(tanya_thread)"
  info "Mulai XMR: mode $mode, $t thread. Berhenti: Ctrl+C"
  jalankan_miner "$bin" --randomx-mode="$mode" \
    -o "$XMR_POOL" -u "$XMR_ADDR" -p "$WORKER" -t "$t"
}

menu_xmr() {
  while true; do
    local st="belum terpasang"
    find_xmrig_bin >/dev/null && st="terpasang"
    echo
    echo "=============== XMR (Monero) ==============="
    echo " Status xmrig: $st"
    echo " 1) Install - Cara A: pkg install (cepat, sering gagal di Android lama)"
    echo " 2) Install - Cara B: compile dari source (berhasil di Android 8)"
    echo " 3) Mulai mining XMR (pilih RAM)"
    echo " 0) Kembali"
    echo "============================================="
    read -rp "Pilih: " p
    case "$p" in
      1) xmr_install_pkg ;;
      2) xmr_install_compile ;;
      3) xmr_start ;;
      0) return ;;
      *) warn "Pilihan tidak dikenal." ;;
    esac
  done
}

# =====================  VRSC  =====================
# Cek apakah file adalah program biner (ELF), bukan zip/html/dll.
ccminer_valid() {
  [ -f "$1" ] && [ "$(head -c4 "$1" 2>/dev/null | tail -c3)" = "ELF" ]
}

vrsc_install() {
  info "Pasang ccminer (Oink70/CCminer-ARM-optimized)"
  pkg update -y && pkg install -y wget curl unzip tar || { pause; return; }
  mkdir -p "$CCMINER_DIR" && cd "$CCMINER_DIR" || { pause; return; }

  local api="https://api.github.com/repos/Oink70/CCminer-ARM-optimized/releases/latest"
  local urls url="" n i=1 u
  urls="$(curl -fsSL "$api" 2>/dev/null | grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4)"

  if [ -n "$urls" ]; then
    echo "Pilih file untuk diunduh:"
    while IFS= read -r u; do echo "  $i) $u"; i=$((i + 1)); done <<< "$urls"
    read -rp "Nomor [1]: " n
    url="$(echo "$urls" | sed -n "${n:-1}p")"
  else
    warn "Gagal membaca daftar rilis otomatis."
    read -rp "Tempel URL unduhan ccminer secara manual: " url
  fi

  if [ -z "$url" ] || ! wget -O unduhan.tmp "$url"; then
    warn "Unduh gagal."; rm -f unduhan.tmp; cd "$HOME" || true; pause; return
  fi

  case "$url" in
    *.zip)         unzip -o unduhan.tmp >/dev/null ;;
    *.tar.gz|*.tgz) tar -xzf unduhan.tmp ;;
    *)             mv -f unduhan.tmp ccminer ;;
  esac
  rm -f unduhan.tmp

  # Kalau hasil ekstrak ada di subfolder, cari file ccminer-nya
  if [ ! -f ccminer ]; then
    local f
    f="$(find . -type f -name 'ccminer*' ! -name '*.zip' ! -name '*.gz' | head -n1)"
    [ -n "$f" ] && mv -f "$f" ccminer
  fi

  chmod +x ccminer 2>/dev/null
  if ccminer_valid ccminer; then
    info "ccminer siap: $CCMINER_DIR/ccminer"
  else
    warn "File yang diunduh bukan program ccminer yang valid."
    warn "Coba pilih file lain (biasanya yang berakhiran arm64/aarch64),"
    warn "atau pakai menu 'Salin dari ccminer yang sudah ada'."
    rm -f ccminer
  fi
  cd "$HOME" || true
  pause
}

vrsc_salin() {
  info "Mencari ccminer lain di HP kamu..."
  local found n i=1 f src
  found="$(find "$HOME" -type f -name 'ccminer*' 2>/dev/null | grep -v "^$CCMINER_DIR/ccminer$")"
  if [ -n "$found" ]; then
    while IFS= read -r f; do echo "  $i) $f"; i=$((i + 1)); done <<< "$found"
    read -rp "Nomor yang mau disalin (atau ketik path sendiri) [1]: " n
    case "$n" in
      ''|*[!0-9]*) src="${n:-$(echo "$found" | sed -n 1p)}" ;;
      *)           src="$(echo "$found" | sed -n "${n}p")" ;;
    esac
  else
    warn "Tidak ada ccminer lain ditemukan."
    read -rp "Ketik path ccminer secara manual (kosong = batal): " src
  fi
  [ -n "$src" ] || { pause; return; }

  if ccminer_valid "$src"; then
    mkdir -p "$CCMINER_DIR" && cp -f "$src" "$CCMINER_DIR/ccminer" && chmod +x "$CCMINER_DIR/ccminer"
    info "Tersalin ke $CCMINER_DIR/ccminer"
  else
    warn "File itu bukan program ccminer yang valid: $src"
  fi
  pause
}

vrsc_start() {
  local t
  [ -x "$CCMINER_DIR/ccminer" ] || { warn "ccminer belum terpasang. Pilih menu Install dulu."; pause; return; }
  if [ -z "$VRSC_ADDR" ]; then
    warn "Alamat VRSC belum diisi."; set_wallet
    [ -z "$VRSC_ADDR" ] && return
  fi
  t="$(tanya_thread)"
  info "Mulai VRSC: $t thread. Berhenti: Ctrl+C"
  jalankan_miner "$CCMINER_DIR/ccminer" -a verus \
    -o "$VRSC_POOL" -u "$VRSC_ADDR.$WORKER" -p x -t "$t"
}

menu_vrsc() {
  while true; do
    local st="belum terpasang"
    ccminer_valid "$CCMINER_DIR/ccminer" && st="terpasang"
    echo
    echo "=============== VRSC (Verus) ==============="
    echo " Status ccminer: $st"
    echo " 1) Install ccminer (unduh dari GitHub)"
    echo " 2) Salin dari ccminer yang sudah ada di HP"
    echo " 3) Mulai mining VRSC"
    echo " 0) Kembali"
    echo "============================================="
    read -rp "Pilih: " p
    case "$p" in
      1) vrsc_install ;;
      2) vrsc_salin ;;
      3) vrsc_start ;;
      0) return ;;
      *) warn "Pilihan tidak dikenal." ;;
    esac
  done
}

# =====================  MENU UTAMA  =====================
catatan() {
  cat <<'EOF'

  CATATAN KEAMANAN
  - Jangan jalankan XMR dan VRSC bersamaan (HP terlalu panas).
  - Mulai dari 2 thread, naikkan pelan-pelan sambil pantau suhu.
  - Jangan dibiarkan semalaman sambil dicas (baterai bisa rusak).
  - VRSC jauh lebih cocok untuk HP dibanding XMR.
  - Hasil mining di HP sangat kecil; anggap ini eksperimen belajar.
  - Jangan bagikan seed phrase wallet ke siapa pun.
EOF
  pause
}

cek_termux
while true; do
  echo
  echo "================ MENU MINING ================"
  echo " 1) XMR  (Monero)"
  echo " 2) VRSC (Verus)  - disarankan untuk HP"
  echo " 3) Pengaturan wallet & worker"
  echo " 4) Catatan keamanan"
  echo " 0) Keluar"
  echo "============================================="
  read -rp "Pilih: " p
  case "$p" in
    1) menu_xmr ;;
    2) menu_vrsc ;;
    3) set_wallet ;;
    4) catatan ;;
    0) exit 0 ;;
    *) warn "Pilihan tidak dikenal." ;;
  esac
done
