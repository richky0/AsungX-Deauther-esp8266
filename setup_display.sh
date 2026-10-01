#!/bin/bash
# ============================================================
# AsungX — One-shot Display & Menu Setup
# Hardware: ESP8266 generic + SSD1306 0.96" 
# ============================================================
set -e

DEAUTHER=~/Downloads/DeautherX/AsungX
TS=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=~/Downloads/DeautherX/backup_$TS

echo "============================================================"
echo "  AsungX Display Setup — $(date)"
echo "============================================================"
echo ""

# ---------- 1. BACKUP ----------
echo "[1/8] Backup file..."
mkdir -p "$BACKUP_DIR"
cd "$DEAUTHER"
for f in A_config.h DisplayUI.h DisplayUI.cpp wifi.cpp webfiles.h; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$f.bak"
    echo "  ✓ $f → $BACKUP_DIR/$f.bak"
  fi
done
echo ""

# ---------- 2. PATCH A_config.h ----------
echo "[2/8] Patch A_config.h (aktifkan display)..."
# Pastikan USE_DISPLAY aktif
if ! grep -q "^#define USE_DISPLAY" A_config.h; then
  # Cari baris yang mendefinisikan USE_DISPLAY dan uncomment
  sed -i 's|^// #define USE_DISPLAY|#define USE_DISPLAY|' A_config.h
  sed -i 's|^//#define USE_DISPLAY|#define USE_DISPLAY|' A_config.h
fi
# Pastikan SSD1306_I2C aktif (bukan yang lain)
sed -i 's|^#define SH1106_I2C|// #define SH1106_I2C|' A_config.h
sed -i 's|^// #define SSD1306_I2C|#define SSD1306_I2C|' A_config.h
grep -n "USE_DISPLAY\|SSD1306_I2C\|SH1106_I2C" A_config.h | head -5
echo ""

# ---------- 3. PATCH DisplayUI.h ----------
echo "[3/8] Patch DisplayUI.h (teks boot + deklarasi)..."
# Ubah teks boot jadi AsungX Developer
sed -i 's|const char D_INTRO_0\[\] PROGMEM = ".*";|const char D_INTRO_0[] PROGMEM = "AsungX";|' DisplayUI.h
sed -i 's|const char D_INTRO_1\[\] PROGMEM = ".*";|const char D_INTRO_1[] PROGMEM = "Developer";|' DisplayUI.h
sed -i 's|const char D_INTRO_2\[\] PROGMEM = .*;|const char D_INTRO_2[] PROGMEM = "v2.0";|' DisplayUI.h
grep -n "D_INTRO_" DisplayUI.h | head -5
echo ""

# ---------- 4. PATCH DisplayUI.cpp — tambah fungsi animasi anjing ----------
echo "[4/8] Patch DisplayUI.cpp (animasi anjing + boot)..."
# Cek apakah sudah di-patch sebelumnya
if grep -q "drawAnjingIdle" DisplayUI.cpp; then
  echo "  ⚠ Sudah pernah dipatch — skip bagian anjing"
else
  # Sisipkan fungsi animasi anjing SEBELUM baris terakhir #endif atau sebelum penutup namespace
  # Cari baris "void DisplayUI::update" sebagai anchor, sisipkan sebelum itu
  ANCHOR=$(grep -n "void DisplayUI::update" DisplayUI.cpp | head -1 | cut -d: -f1)
  if [ -n "$ANCHOR" ]; then
    # Buat file sementara berisi fungsi anjing
    cat > /tmp/anime_dog.cpp << 'DOG_EOF'

// ============================================================
// ANIMASI ANJING KARTUN — 8 frame idle
// ============================================================
void DisplayUI::drawAnjingIdle(uint8_t frame) {
    if (!display || !display->isReady()) return;
    display->clear();
    int cx = 64, cy = 32;

    // Frame 0-7: variasi telinga, ekor, mata, mulut
    bool blink = (frame == 3 || frame == 7);
    bool earUp = (frame % 4 < 2);
    bool tailL = (frame % 2 == 0);

    // Kepala (lingkaran)
    display->drawCircle(cx, cy, 18);
    // Telinga kiri
    if (earUp) {
        display->drawLine(cx-12, cy-14, cx-18, cy-26);
        display->drawLine(cx-18, cy-26, cx-8, cy-16);
    } else {
        display->drawLine(cx-12, cy-14, cx-20, cy-18);
        display->drawLine(cx-20, cy-18, cx-8, cy-16);
    }
    // Telinga kanan
    if (earUp) {
        display->drawLine(cx+12, cy-14, cx+18, cy-26);
        display->drawLine(cx+18, cy-26, cx+8, cy-16);
    } else {
        display->drawLine(cx+12, cy-14, cx+20, cy-18);
        display->drawLine(cx+20, cy-18, cx+8, cy-16);
    }
    // Mata
    if (blink) {
        display->drawLine(cx-8, cy-3, cx-4, cy-3);
        display->drawLine(cx+4, cy-3, cx+8, cy-3);
    } else {
        display->setPixel(cx-6, cy-3);
        display->setPixel(cx-5, cy-3);
        display->setPixel(cx+5, cy-3);
        display->setPixel(cx+6, cy-3);
    }
    // Hidung + mulut
    display->setPixel(cx, cy+2);
    display->drawLine(cx-3, cy+5, cx, cy+7);
    display->drawLine(cx, cy+7, cx+3, cy+5);
    // Lidah (muncul di frame 2, 6)
    if (frame == 2 || frame == 6) {
        display->drawLine(cx, cy+7, cx, cy+12);
        display->drawLine(cx-1, cy+12, cx+1, cy+12);
    }
    // Ekor (goyang kiri/kanan)
    if (tailL) {
        display->drawLine(cx+22, cy+8, cx+30, cy+2);
        display->drawLine(cx+30, cy+2, cx+34, cy+6);
    } else {
        display->drawLine(cx+22, cy+8, cx+30, cy+14);
        display->drawLine(cx+30, cy+14, cx+34, cy+10);
    }
    // Teks bawah
    display->setFont(ArialMT_Plain_10);
    display->setTextAlignment(TEXT_ALIGN_CENTER);
    display->drawString(cx, 54, "AsungX");
    display->display();
}

void DisplayUI::drawBootAnim(uint8_t step) {
    if (!display || !display->isReady()) return;
    display->clear();
    display->setFont(ArialMT_Plain_16);
    display->setTextAlignment(TEXT_ALIGN_CENTER);

    // Efek ketik: "AsungX" muncul huruf per huruf (step 0-5)
    String name = "AsungX";
    String shown = name.substring(0, min(step, (uint8_t)name.length()));
    display->drawString(64, 14, shown);

    // "Developer" muncul setelah step 6
    if (step >= 6) {
        display->setFont(ArialMT_Plain_10);
        display->drawString(64, 36, "Developer");
    }
    // Garis progress bawah
    display->drawLine(14, 52, 14 + step * 12, 52);
    display->display();
}

void DisplayUI::drawAttackAnim(uint8_t frame) {
    if (!display || !display->isReady()) return;
    display->clear();
    display->setFont(ArialMT_Plain_10);
    display->setTextAlignment(TEXT_ALIGN_CENTER);
    display->drawString(64, 0, "DEAUTH ATTACK");
    // Progress bar berdenyut
    int w = 20 + (frame % 6) * 10;
    display->drawRect(14, 20, 100, 10);
    display->fillRect(14, 20, w, 10);
    // Ikon target
    display->drawCircle(64, 44, 8);
    display->drawCircle(64, 44, 4);
    display->setPixel(64, 44);
    // Frame counter
    display->drawString(64, 54, String(frame));
    display->display();
}

void DisplayUI::drawScanAnim(uint8_t frame) {
    if (!display || !display->isReady()) return;
    display->clear();
    display->setFont(ArialMT_Plain_10);
    display->setTextAlignment(TEXT_ALIGN_CENTER);
    display->drawString(64, 0, "SCANNING...");
    // Radar sweep
    int cx = 64, cy = 36;
    display->drawCircle(cx, cy, 20);
    display->drawCircle(cx, cy, 12);
    display->drawCircle(cx, cy, 4);
    // Garis sweep
    float angle = (frame % 16) * 22.5 * PI / 180.0;
    int x = cx + 20 * cos(angle);
    int y = cy + 20 * sin(angle);
    display->drawLine(cx, cy, x, y);
    display->display();
}

void DisplayUI::drawEvilTwinAnim(uint8_t frame) {
    if (!display || !display->isReady()) return;
    display->clear();
    display->setFont(ArialMT_Plain_10);
    display->setTextAlignment(TEXT_ALIGN_CENTER);
    display->drawString(64, 0, "EVIL TWIN");
    // Ikon WiFi dengan sinyal berdenyut
    int cx = 64, cy = 30;
    int r = 4 + (frame % 4) * 3;
    display->drawCircle(cx, cy, r);
    display->drawCircle(cx, cy, r + 4);
    display->drawCircle(cx, cy, r + 8);
    display->setPixel(cx, cy);
    // Teks CAPTURING berkedip
    if (frame % 2 == 0) {
        display->drawString(64, 54, "CAPTURING...");
    }
    display->display();
}
DOG_EOF
    # Sisipkan sebelum baris "void DisplayUI::update"
    head -n $((ANCHOR - 1)) DisplayUI.cpp > /tmp/DisplayUI_new.cpp
    cat /tmp/anime_dog.cpp >> /tmp/DisplayUI_new.cpp
    tail -n +$ANCHOR DisplayUI.cpp >> /tmp/DisplayUI_new.cpp
    mv /tmp/DisplayUI_new.cpp DisplayUI.cpp
    echo "  ✓ Fungsi animasi ditambahkan"
  else
    echo "  ⚠ Anchor 'void DisplayUI::update' tidak ditemukan — skip"
  fi
fi
echo ""

# ---------- 5. PATCH DisplayUI.h — deklarasi ----------
echo "[5/8] Patch DisplayUI.h (deklarasi fungsi animasi)..."
if ! grep -q "drawAnjingIdle" DisplayUI.h; then
  # Sisipkan deklarasi di dalam class DisplayUI, sebelum "void update"
  ANCHOR_H=$(grep -n "void update(" DisplayUI.h | head -1 | cut -d: -f1)
  if [ -n "$ANCHOR_H" ]; then
    head -n $((ANCHOR_H - 1)) DisplayUI.h > /tmp/DisplayUI_h_new.h
    cat >> /tmp/DisplayUI_h_new.h << 'H_EOF'
        // ===== Animasi baru (AsungX) =====
        void drawAnjingIdle(uint8_t frame);
        void drawBootAnim(uint8_t step);
        void drawAttackAnim(uint8_t frame);
        void drawScanAnim(uint8_t frame);
        void drawEvilTwinAnim(uint8_t frame);
H_EOF
    tail -n +$ANCHOR_H DisplayUI.h >> /tmp/DisplayUI_h_new.h
    mv /tmp/DisplayUI_h_new.h DisplayUI.h
    echo "  ✓ Deklarasi ditambahkan"
  fi
fi
echo ""

# ---------- 6. PATCH wifi.cpp — hook display ----------
echo "[6/8] Patch wifi.cpp (hook display saat web trigger aksi)..."
# Tambah include DisplayUI kalau belum ada
if ! grep -q '#include "DisplayUI.h"' wifi.cpp; then
  sed -i '1i #include "DisplayUI.h"' wifi.cpp
fi
# Tambah extern displayUI
if ! grep -q "extern DisplayUI displayUI" wifi.cpp; then
  sed -i '2i extern DisplayUI displayUI;' wifi.cpp
fi
echo "  ✓ Include + extern ditambahkan"
echo ""

# ---------- 7. COMPILE ----------
echo "[7/8] Compile firmware..."
cd "$DEAUTHER"
if arduino-cli compile --fqbn deauther:esp8266:generic . 2>&1 | tee /tmp/compile.log | tail -20; then
  if grep -q "Sketch uses" /tmp/compile.log; then
    echo ""
    echo "  ✓ Compile SUKSES"
  else
    echo "  ⚠ Compile selesai tapi tidak ada 'Sketch uses' — cek log"
  fi
else
  echo ""
  echo "  ✗ Compile GAGAL — restore backup"
  for f in A_config.h DisplayUI.h DisplayUI.cpp wifi.cpp webfiles.h; do
    [ -f "$BACKUP_DIR/$f.bak" ] && cp "$BACKUP_DIR/$f.bak" "$f"
  done
  echo "  Backup restored. Cek /tmp/compile.log untuk error."
  exit 1
fi
echo ""

# ---------- 8. UPLOAD ----------
echo "[8/8] Upload ke /dev/ttyUSB0..."
if [ -w /dev/ttyUSB0 ]; then
  arduino-cli upload --fqbn deauther:esp8266:generic -p /dev/ttyUSB0 . 2>&1 | tail -10
else
  echo "  ⚠ /dev/ttyUSB0 tidak writable. Coba:"
  echo "     sudo setfacl -m u:$USER:rw /dev/ttyUSB0"
  echo "     lalu jalankan: arduino-cli upload --fqbn deauther:esp8266:generic -p /dev/ttyUSB0 ."
fi

echo ""
echo "============================================================"
echo "  SELESAI!"
echo "============================================================"
echo "  Backup  : $BACKUP_DIR"
echo "  Compile : /tmp/compile.log"
echo ""
echo "  Kalau OLED belum nyala, cek:"
echo "  1. Wiring SDA=D2, SCL=D1, VCC=3.3V, GND"
echo "  2. Alamat I2C (biasanya 0x3C)"
echo "  3. Restore: cp $BACKUP_DIR/*.bak $DEAUTHER/"
echo "============================================================"
