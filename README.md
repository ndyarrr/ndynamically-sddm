# Ndynamically SDDM - Panduan Penggunaan & Konfigurasi

**Ndynamically SDDM** adalah tema Login Screen yang dinamis. Tema ini secara acak akan memutar video `.mp4` atau menampilkan gambar latar belakang dari direktori pilihan Anda, serta mengekstrak warna aksen dari wallpaper tersebut untuk mewarnai tombol dan teks secara otomatis.
*Tema ini mendukung systemd secara out-of-the-box, serta sistem init lain (OpenRC, Runit, dsb) secara opsional.*

---

## Fitur Unggulan

1. **Sinkronisasi Warna Aksen Dinamis(Experimental)**: Menggunakan algoritma cerdas `palettegen` (k-means clustering) dari `ffmpeg` untuk mendeteksi 6 warna paling dominan dan kontras dari wallpaper Anda secara akurat.
2. **Keterbacaan Kontras Otomatis (Experimental)**: Teks jam, tanggal, nama user, dan tombol-tombol akan otomatis menyesuaikan kecerahannya (menjadi lebih gelap di wallpaper terang, dan lebih terang di wallpaper gelap) agar selalu mudah dibaca di latar belakang apa pun.
3. **Panel Kontrol Atas (Top Island Panel)**:
   * **Mode Selector**: Mengganti mode wallpaper (Hybrid, Video, Image, Stay).
   * **Session Selector**: Mengganti sesi desktop Anda (Hyprland, Plasma, GNOME, dll.) cukup dengan sekali klik.
   * **Power Menu**: Menu dropdown untuk Sleep, Shutdown, dan Reboot dengan tampilan modern.
4. **Auto-Watcher Systemd Path (Experimental)**: Secara otomatis memantau folder wallpaper Anda. Setiap kali Anda menambah, mengubah, atau menghapus file wallpaper, sistem akan langsung mengekstrak warna aksen baru tanpa perlu konfigurasi manual.
5. **Kemudahan Ganti Folder**: Anda dapat mengubah direktori wallpaper kapan saja dengan satu perintah mudah tanpa perlu menginstal ulang tema.
6. **Random Wallpaper**: Anda dapat mengatur mode wallpaper secara random atau tetap menggunakan 1 wallpaper 
   1. image = random selection of image wallpapers only (png, jpg, jpeg, webp)
   2. video = random selection of video wallpapers only (mp4, gif)
   3. hybrid = combines random videos and images
   4. stay = ensures the wallpaper remains set after a reboot or shutdown

**Konfigurasi mode tersedia di theme.conf dan berada di ui sddm**

---

## Persyaratan Sistem

Pastikan paket-paket berikut sudah terpasang di sistem Linux Anda sebelum menginstal:
* **sddm** (Tentu saja, sebagai display manager)
* **ffmpeg** (Wajib untuk mengekstrak warna aksen dari video/gambar)
* **qt5-compat** / **qt6-5compat** (Untuk fungsionalitas visual QML)
* **bash**
* **systemd** (Opsional, untuk auto-sync otomatis via systemd path)
* **inotify-tools** (Opsional, jika menggunakan sistem non-systemd dan ingin auto-sync otomatis via `ndynamically-sddm-watcher`)

---

## Panduan Instalasi

1. Buka terminal di dalam folder tema `ndynamically-sddm`.
2. Jalankan skrip installer menggunakan perintah:
   ```bash
   sudo ./install.sh
   ```
3. Installer akan menanyakan direktori penyimpanan wallpaper Anda. 
   * Anda bisa menekan **Enter** untuk menggunakan folder default (`~/Wallpapers`).
   * Atau ketik path lengkap folder kustom Anda (misal: `/home/username/Pictures/MyWallpapers`).
4. Selesai! SDDM Anda kini telah dikonfigurasi menggunakan tema **Ndynamically SDDM**.

---

## Cara Menggunakan & Konfigurasi

### 1. Menambahkan Wallpaper Baru (Auto-Sync)
Anda cukup menyalin berkas video (**`.mp4`**, **`.gif`**) atau gambar (**`.png`**, **`.jpg`**, **`.jpeg`**, **`.webp`**) baru ke dalam direktori wallpaper yang telah Anda daftarkan.

* **Untuk Pengguna systemd**:
  * Systemd watcher akan mendeteksi perubahan tersebut secara otomatis.
  * Setelah jeda aman 5 detik (untuk memastikan file selesai disalin), warna aksen baru akan otomatis diekstrak di latar belakang.
* **Untuk Pengguna Non-systemd (OpenRC, Runit, dsb)**:
  * Anda bisa menjalankan sinkronisasi warna secara manual dengan perintah:
    ```bash
    sudo ndynamically-sddm-sync
    ```
  * Atau, Anda bisa menggunakan pemantau otomatis latar belakang dengan menjalankan skrip watcher bawaan (memerlukan `inotify-tools`):
    ```bash
    ndynamically-sddm-watcher &
    ```
    *(Sangat disarankan untuk memasukkan perintah `ndynamically-sddm-watcher &` ke autostart desktop environment Anda seperti `.xprofile`, `.xinitrc`, atau konfigurasi GUI).*

### 2. Mengganti Direktori Wallpaper
Jika Anda memindahkan folder wallpaper atau ingin menggunakan direktori lain, cukup jalankan perintah:
```bash
sudo ndynamically-sddm-sync --set-dir /path/ke/direktori/baru
```
*Script ini akan otomatis mengupdate konfigurasi tampilan QML, mengatur ulang perizinan SDDM agar tidak terjadi blank screen, dan secara otomatis mendeteksi apakah perlu memperbarui unit systemd watcher ke folder baru tersebut.*

### 3. Menguji Coba Tema Secara Lokal
Anda dapat melihat tampilan login screen tanpa perlu logout menggunakan perintah pengujian SDDM:
```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/ndynamically-sddm
```
Saya rasa ini tidak bekerja karena masalah di qt6 solisi mencoba hanya menginstallnya

---


*Tema ini dibuat untuk memberikan pengalaman login Linux yang mulus, dinamis.* 🚀
