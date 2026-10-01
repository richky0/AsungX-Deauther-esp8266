# AsungX

<p align="center">
  <strong>AsungX</strong>
</p>

AsungX adalah firmware ESP8266 untuk pembelajaran dan pengujian keamanan Wi-Fi secara terkendali. Proyek ini menyediakan antarmuka web dan layar perangkat untuk membantu memeriksa jaringan yang Anda miliki atau yang penggunaannya telah mendapat izin.

## Penggunaan yang Bertanggung Jawab

Gunakan perangkat hanya pada jaringan dan perangkat milik sendiri atau dengan izin tertulis dari pemiliknya. Pengujian dapat mengganggu konektivitas perangkat lain. Patuhi hukum dan peraturan setempat. Pengembang tidak bertanggung jawab atas penyalahgunaan atau kerusakan yang timbul dari penggunaan perangkat lunak ini.

## Keterangan Perangkat

Firmware ini dirancang untuk perangkat dengan **layar OLED 0.96 inch**.

Pada layar OLED hanya ditampilkan:

- Animasi
- Proses tools yang sedang berjalan

Seluruh aktivitas dan pengoperasian tools **wajib dijalankan melalui web admin**. Tidak ada kontrol tools yang dapat dilakukan langsung dari perangkat selain melalui web admin.

## Persiapan

- Perangkat ESP8266 yang didukung oleh paket board DeautherX.
- Arduino IDE atau Arduino CLI.
- Kabel USB data yang sesuai dengan board.

Untuk Arduino IDE, tambahkan URL berikut pada **Preferences → Additional Boards Manager URLs**:

```text
https://raw.githubusercontent.com/BlackTechX011/arduino/main/package_BlackTechX_index.json
