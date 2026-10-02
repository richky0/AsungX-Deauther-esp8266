# AsungX

[![Animation Studio](https://img.shields.io/badge/Animation%20Studio-Web%20Converter-purple?logo=github)](https://github.com/richky0/AsungX-ESP8266-OLED-Studio-Generator)
[![Version](https://img.shields.io/badge/Version-v1.1.0-blue)](https://github.com/richky0/AsungX-Deauther-esp8266/releases)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> 🎬 **Web-based OLED animation converter:** [AsungX-ESP8266-OLED-Studio-Generator](https://github.com/richky0/AsungX-ESP8266-OLED-Studio-Generator)
>
> Convert video/GIF → animasi `.bin` siap upload ke firmware ini.

Firmware ESP8266 untuk pembelajaran dan pengujian keamanan Wi-Fi secara terkendali. Proyek ini menyediakan antarmuka web lengkap untuk mengontrol seluruh fitur, dengan OLED 0.96" yang menampilkan animasi dan status proses.

> ⚠️ **Gunakan hanya pada jaringan milik sendiri atau yang sudah mendapat izin tertulis.** Pengujian dapat mengganggu konektivitas perangkat lain. Patuhi hukum setempat.

---

## Daftar Isi

- [Fitur](#fitur)
- [Hardware](#hardware)
- [Instalasi](#instalasi)
- [Cara Pakai](#cara-pakai)
  - [Web Admin](#web-admin)
  - [Deauth All Adaptive](#deauth-all-adaptive)
  - [OLED Animation](#oled-animation)
- [Konverter Video ke Animasi](#konverter-video-ke-animasi)
- [Struktur Proyek](#struktur-proyek)
- [Atribusi & Lisensi](#atribusi--lisensi)

---

## Fitur

### Keamanan Wi-Fi
- **Scan AP & Station** — deteksi access point dan perangkat klien di sekitar
- **Deauth** — putuskan koneksi perangkat dari AP target
- **Deauth All** — serang semua AP yang terdeteksi (statis)
- **Deauth All Adaptive** ⭐ — auto-rescan tiap 15 detik, AP baru otomatis ke-deauth
- **Beacon Flood** — buat SSID palsu dalam jumlah banyak
- **Probe Flood** — banjiri probe request
- **Evil Twin** — portal captive untuk pengujian

### OLED Animation
- Putar animasi custom dari file `.bin` (128×64 1-bit)
- Upload via web admin
- Kontrol play/stop/loop/FPS dari web atau CLI
- Support **delta encoding** (hemat size 60-70%)

### Web Admin
- Kontrol penuh semua fitur dari browser
- Upload animasi
- File manager (SPIFFS)
- Pengaturan tersimpan otomatis

### Multi-language
- 21 bahasa termasuk Indonesia

---

## Hardware

| Komponen | Spesifikasi |
|----------|-------------|
| Board | ESP8266 (NodeMCU / Wemos D1 mini / generic) |
| Layar | OLED SSD1306 0.96" I2C (128×64) |
| Pin I2C | SDA=GPIO 4 (D2), SCL=GPIO 5 (D1) |
| Tombol (opsional) | UP=GPIO 14, DOWN=GPIO 12, A=GPIO 13, B=GPIO 16 |

**Catatan:** Layar OLED **hanya menampilkan animasi dan status**. Semua kontrol dilakukan dari **web admin**.

---

## Instalasi

### 1. Setup Arduino

Tambahkan URL berikut di **Arduino IDE → Preferences → Additional Boards Manager URLs**:
