#!/bin/bash
set -e
DEAUTHER=~/Downloads/DeautherX/AsungX
TS=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=~/Downloads/DeautherX/backup_$TS

echo "============================================================"
echo "  AsungX Display Setup v2 — $(date)"
echo "============================================================"
echo ""

# ---------- 1. BACKUP ----------
echo "[1/7] Backup..."
mkdir -p "$BACKUP_DIR"
cd "$DEAUTHER"
for f in A_config.h DisplayUI.h DisplayUI.cpp wifi.cpp; do
  [ -f "$f" ] && cp "$f" "$BACKUP_DIR/$f.bak" && echo "  ✓ $f"
done
echo ""

# ---------- 2. PATCH DisplayUI.cpp — hapus blok lama (kalau ada) + tambah fixed ----------
echo "[2/7] Patch DisplayUI.cpp..."

# Kalau sudah ada blok animasi lama, hapus dulu (biar tidak dobel)
if grep -q "drawAnjingIdle" DisplayUI.cpp; then
  echo "  ⚠ Ada blok animasi lama — hapus dulu"
  # Hapus dari "// ANIMASI ANJING KARTUN" sampai sebelum "void DisplayUI::update"
  awk '
    /^\/\/ =+$/ && /ANIMASI ANJING/ { skip=1 }
    /^void DisplayUI::update/ { skip=0 }
    !skip { print }
  ' DisplayUI.cpp > /tmp/DisplayUI_clean.cpp
  mv /tmp/DisplayUI_clean.cpp DisplayUI.cpp
fi

# Sisipkan fungsi animasi baru SEBELUM "void DisplayUI::update"
ANCHOR=$(grep -n "void DisplayUI::update" DisplayUI.cpp | head -1 | cut -d: -f1)
if [ -z "$ANCHOR" ]; then
  echo "  ✗ Anchor tidak ditemukan — abort"
  exit 1
fi

cat > /tmp/anime_dog_v2.cpp << 'DOG_EOF'

// ============================================================
// ANIMASI ANJING KARTUN — AsungX
// ============================================================
void DisplayUI::drawAnjingIdle(uint8_t frame) {
    if (!display.isReady()) return;
    display.clear();
    int cx = 64, cy = 32;
    bool blink = (frame == 3 || frame == 7);
    bool earUp = (frame % 4 < 2);
    bool tailL = (frame % 2 == 0);

    display.drawCircle(cx, cy, 18);

    if (earUp) {
        display.drawLine(cx-12, cy-14, cx-18, cy-26);
        display.drawLine(cx-18, cy-26, cx-8, cy-16);
    } else {
        display.drawLine(cx-12, cy-14, cx-20, cy-18);
        display.drawLine(cx-20, cy-18, cx-8, cy-16);
    }
    if (earUp) {
        display.drawLine(cx+12, cy-14, cx+18, cy-26);
        display.drawLine(cx+18, cy-26, cx+8, cy-16);
    } else {
        display.drawLine(cx+12, cy-14, cx+20, cy-18);
        display.drawLine(cx+20, cy-18, cx+8, cy-16);
    }

    if (blink) {
        display.drawLine(cx-8, cy-3, cx-4, cy-3);
        display.drawLine(cx+4, cy-3, cx+8, cy-3);
    } else {
        display.setPixel(cx-6, cy-3); display.setPixel(cx-5, cy-3);
        display.setPixel(cx+5, cy-3); display.setPixel(cx+6, cy-3);
    }

    display.setPixel(cx, cy+2);
    display.drawLine(cx-3, cy+5, cx, cy+7);
    display.drawLine(cx, cy+7, cx+3, cy+5);

    if (frame == 2 || frame == 6) {
        display.drawLine(cx, cy+7, cx, cy+12);
        display.drawLine(cx-1, cy+12, cx+1, cy+12);
    }

    if (tailL) {
        display.drawLine(cx+22, cy+8, cx+30, cy+2);
        display.drawLine(cx+30, cy+2, cx+34, cy+6);
    } else {
        display.drawLine(cx+22, cy+8, cx+30, cy+14);
        display.drawLine(cx+30, cy+14, cx+34, cy+10);
    }

    display.setFont(ArialMT_Plain_10);
    display.setTextAlignment(TEXT_ALIGN_CENTER);
    display.drawString(cx, 54, "AsungX");
    display.display();
}

void DisplayUI::drawBootAnim(uint8_t step) {
    if (!display.isReady()) return;
    display.clear();
    display.setFont(ArialMT_Plain_16);
    display.setTextAlignment(TEXT_ALIGN_CENTER);
    String name = "AsungX";
    String shown = name.substring(0, min(step, (uint8_t)name.length()));
    display.drawString(64, 14, shown);
    if (step >= 6) {
        display.setFont(ArialMT_Plain_10);
        display.drawString(64, 36, "Developer");
    }
    display.drawLine(14, 52, 14 + step * 12, 52);
    display.display();
}

void DisplayUI::drawAttackAnim(uint8_t frame) {
    if (!display.isReady()) return;
    display.clear();
    display.setFont(ArialMT_Plain_10);
    display.setTextAlignment(TEXT_ALIGN_CENTER);
    display.drawString(64, 0, "DEAUTH ATTACK");
    int w = 20 + (frame % 6) * 10;
    display.drawRect(14, 20, 100, 10);
    display.fillRect(14, 20, w, 10);
    display.drawCircle(64, 44, 8);
    display.drawCircle(64, 44, 4);
    display.setPixel(64, 44);
    display.drawString(64, 54, String(frame));
    display.display();
}

void DisplayUI::drawScanAnim(uint8_t frame) {
    if (!display.isReady()) return;
    display.clear();
    display.setFont(ArialMT_Plain_10);
    display.setTextAlignment(TEXT_ALIGN_CENTER);
    display.drawString(64, 0, "SCANNING...");
    int cx = 64, cy = 36;
    display.drawCircle(cx, cy, 20);
    display.drawCircle(cx, cy, 12);
    display.drawCircle(cx, cy, 4);
    float angle = (frame % 16) * 22.5 * PI / 180.0;
    int x = cx + 20 * cos(angle);
    int y = cy + 20 * sin(angle);
    display.drawLine(cx, cy, x, y);
    display.display();
}

void DisplayUI::drawEvilTwinAnim(uint8_t frame) {
    if (!display.isReady()) return;
    display.clear();
    display.setFont(ArialMT_Plain_10);
    display.setTextAlignment(TEXT_ALIGN_CENTER);
    display.drawString(64, 0, "EVIL TWIN");
    int cx = 64, cy = 30;
    int r = 4 + (frame % 4) * 3;
    display.drawCircle(cx, cy, r);
    display.drawCircle(cx, cy, r + 4);
    display.drawCircle(cx, cy, r + 8);
    display.setPixel(cx, cy);
    if (frame % 2 == 0) {
        display.drawString(64, 54, "CAPTURING...");
    }
    display.display();
}
DOG_EOF

head -n $((ANCHOR - 1)) DisplayUI.cpp > /tmp/DisplayUI_new.cpp
cat /tmp/anime_dog_v2.cpp >> /tmp/DisplayUI_new.cpp
tail -n +$ANCHOR DisplayUI.cpp >> /tmp/DisplayUI_new.cpp
mv /tmp/DisplayUI_new.cpp DisplayUI.cpp
echo "  ✓ Fungsi animasi ditambahkan (versi fixed)"
echo ""

# ---------- 3. PATCH DisplayUI.h — deklarasi ----------
echo "[3/7] Patch DisplayUI.h..."
if ! grep -q "drawAnjingIdle" DisplayUI.h; then
  ANCHOR_H=$(grep -n "void update(" DisplayUI.h | head -1 | cut -d: -f1)
  head -n $((ANCHOR_H - 1)) DisplayUI.h > /tmp/DisplayUI_h_new.h
  cat >> /tmp/DisplayUI_h_new.h << 'H_EOF'
        // ===== Animasi AsungX =====
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
echo ""

# ---------- 4. PATCH wifi.cpp — hook ----------
echo "[4/7] Patch wifi.cpp..."
if ! grep -q '#include "DisplayUI.h"' wifi.cpp; then
  sed -i '1i #include "DisplayUI.h"' wifi.cpp
  sed -i '2i extern DisplayUI displayUI;' wifi.cpp
  echo "  ✓ Include + extern ditambahkan"
fi
echo ""

# ---------- 5. COMPILE ----------
echo "[5/7] Compile..."
cd "$DEAUTHER"
if arduino-cli compile --fqbn deauther:esp8266:generic . 2>&1 | tee /tmp/compile.log | tail -15; then
  if grep -q "Sketch uses" /tmp/compile.log; then
    echo ""
    echo "  ✓ COMPILE SUKSES"
  else
    echo "  ✗ Compile error — restore backup"
    for f in A_config.h DisplayUI.h DisplayUI.cpp wifi.cpp; do
      [ -f "$BACKUP_DIR/$f.bak" ] && cp "$BACKUP_DIR/$f.bak" "$f"
    done
    echo "  Backup restored."
    exit 1
  fi
else
  echo "  ✗ Compile GAGAL — restore backup"
  for f in A_config.h DisplayUI.h DisplayUI.cpp wifi.cpp; do
    [ -f "$BACKUP_DIR/$f.bak" ] && cp "$BACKUP_DIR/$f.bak" "$f"
  done
  echo "  Backup restored. Cek /tmp/compile.log"
  exit 1
fi
echo ""

# ---------- 6. UPLOAD ----------
echo "[6/7] Upload ke /dev/ttyUSB0..."
if [ -w /dev/ttyUSB0 ]; then
  arduino-cli upload --fqbn deauther:esp8266:generic -p /dev/ttyUSB0 . 2>&1 | tail -8
else
  echo "  ⚠ /dev/ttyUSB0 tidak writable. Jalankan:"
  echo "     sudo setfacl -m u:$USER:rw /dev/ttyUSB0"
  echo "     arduino-cli upload --fqbn deauther:esp8266:generic -p /dev/ttyUSB0 ."
fi
echo ""

# ---------- 7. DONE ----------
echo "============================================================"
echo "  SELESAI!"
echo "============================================================"
echo "  Backup  : $BACKUP_DIR"
echo "  Compile : /tmp/compile.log"
echo "============================================================"
