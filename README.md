<p align="center">
  <img src="./Assets/banner.png" alt="Ndynamically SDDM" width="100%">
</p>

<h1 align="center">
Ndynamically SDDM
</h1>

<p align="center">
A modern, dynamic and customizable SDDM theme with automatic wallpaper switching,<br>
dynamic accent color extraction and smart contrast adaptation.
</p>

<div align="center">

<a href="#installation">
<img src="https://img.shields.io/badge/INSTALLATION-black?style=for-the-badge&color=7aa2f7&labelColor=1a1b26&logo=linux&logoColor=white">
</a>

<a href="#configuration">
<img src="https://img.shields.io/badge/CONFIGURATION-black?style=for-the-badge&color=bb9af7&labelColor=1a1b26&logo=qt&logoColor=white">
</a>

<a href="https://github.com/ndyarrr/ndynamically-sddm/stargazers">
<img src="https://img.shields.io/github/stars/ndyarrr/ndynamically-sddm?style=for-the-badge&labelColor=1a1b26">
</a>

<a href="https://github.com/ndyarrr/ndynamically-sddm">
<img src="https://img.shields.io/github/repo-size/ndyarrr/ndynamically-sddm?style=for-the-badge&labelColor=1a1b26">
</a>

<a href="LICENSE">
<img src="https://img.shields.io/github/license/ndyarrr/ndynamically-sddm?style=for-the-badge&labelColor=1a1b26">
</a>

</div>

<div align="center">

<pre>

<a href="#features">Features</a> •
<a href="#installation">Installation</a> •
<a href="#configuration">Configuration</a> •
<a href="#wallpaper-modes">Wallpaper Modes</a> •
<a href="#gallery">Gallery</a> •
<a href="#faq">FAQ</a> •
<a href="#credits">Credits</a>

</pre>

</div>

<br>

<p align="center">
<img src="https://img.shields.io/badge/-WELCOME-7aa2f7?style=for-the-badge&labelColor=1a1b26" height="55">
</p>

Ndynamically SDDM is a modern login screen theme focused on **automation**, **customization**, and **beautiful visuals**.

Unlike traditional SDDM themes, Ndynamically automatically changes wallpapers, extracts beautiful accent colors from your wallpaper or video, and adapts every UI element to ensure excellent readability.

Whether you use **systemd**, **OpenRC**, **Runit**, or another init system, Ndynamically is designed to work everywhere.

> [!TIP]
> Simply place your wallpapers into one folder and let Ndynamically handle everything automatically.

<br>

<p align="center">━━━━━━━ ❖ ━━━━━━━</p>

<a id="features"></a>

<br>

<p align="center">
<img src="https://img.shields.io/badge/-FEATURES-9ece6a?style=for-the-badge&labelColor=1a1b26" height="55">
</p>

## ✨ Dynamic Accent Color *(Experimental)*

Powered by **FFmpeg palettegen**.

Instead of using a fixed accent color, Ndynamically analyzes every wallpaper and automatically extracts the most dominant colors using **k-means clustering**.

This accent color is then applied throughout the interface.

✔ Buttons

✔ Icons

✔ Login fields

✔ Highlights

✔ UI Decorations

---

## 🌗 Smart Contrast *(Experimental)*

No matter how bright or dark your wallpaper is, every important UI element remains readable.

Ndynamically automatically adjusts

- Clock
- Date
- Username
- Password field
- Buttons
- Power Menu

without any manual configuration.

---

## 🖼 Dynamic Wallpaper

Supports

- MP4
- GIF
- PNG
- JPG
- JPEG
- WEBP

Mix videos and images inside one folder and let Ndynamically randomly choose one at every login.

---

## 🎬 Smooth Wallpaper Transition

Version **1.1** introduces a brand new wallpaper transition animation.

Every wallpaper change now fades smoothly, creating a modern login experience instead of an instant image swap.

---

## 🎨 Top Island Panel

Inspired by modern desktop interfaces.

Includes

- Wallpaper Mode Selector
- Session Selector
- Power Menu
- Sleep
- Shutdown
- Reboot

Everything is accessible directly from the login screen.

---

## 🔄 Automatic Wallpaper Watcher

Forget manually syncing your wallpapers.

Whenever new wallpapers are added, removed, or modified, Ndynamically automatically refreshes its wallpaper database and updates the generated accent colors.

Supported by

- systemd Path Unit
- OpenRC
- Runit
- inotify-tools

---

## ⚡ One Command Directory Switch

Changing wallpaper directories is as easy as

```bash
sudo ndynamically-sddm-sync --set-dir /path/to/wallpapers
```

Permissions, configuration, and watcher services are automatically updated.

---

## 🌍 Universal Init Support

Unlike many SDDM themes, Ndynamically is not limited to systemd.

Officially supports

- systemd
- OpenRC
- Runit
- Any Linux distro with Bash

---

## 📦 Lightweight

No heavy background daemons.

No unnecessary services.

Only FFmpeg and a few shell scripts handle everything.

The theme remains lightweight while providing dynamic functionality.

---

## ❤️ Designed for Daily Use

Built with usability in mind.

Every feature exists to reduce manual configuration while making your login screen feel alive.
