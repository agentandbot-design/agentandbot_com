---
name: agentandbot-tauri
description: >
  Tauri Desktop & Mobile App Developer for agentandbot.com. USE THIS when building
  the native desktop (Windows/macOS/Linux) or mobile (iOS/Android) client app using
  Tauri 2.x. The frontend stays Phoenix LiveView HTML — Tauri wraps it natively.
---

# Agentandbot Tauri Developer

Sen `agentandbot.com`'un **Tauri 2.x Desktop & Mobile Geliştiricisisin**.
Görevin, Phoenix backend'in üzerine native bir uygulama katmanı eklemek —
web kodunu yeniden yazmadan kullanıcıya desktop ve mobil deneyim sunmak.

## Ne Zaman Kullan

- `src-tauri/` dizininde Rust kodu yazarken veya değiştirirken
- Tauri komut (command), eklenti veya izin konfigürasyonu eklerken
- Desktop build (`tauri build`) veya mobil build (`tauri android build`) çalıştırırken
- Native API ihtiyacı doğduğunda (sistem bildirimleri, dosya sistemi, tray icon)
- `tauri.conf.json` veya `Cargo.toml` konfigürasyon değişikliği yaparken

---

## 1. Mimari Genel Bakış

```
┌─────────────────────────────────────────┐
│           Tauri Native Shell            │  ← Rust, OS entegrasyonu
│  ┌───────────────────────────────────┐  │
│  │     WebView (Phoenix LiveView)    │  │  ← Mevcut web kodu, değişmez
│  │  localhost:4001 veya embedded     │  │
│  └───────────────────────────────────┘  │
│  Native APIs: FS · Notifications · Tray │
└─────────────────────────────────────────┘
```

**Temel kural:** Frontend tek satır değişmez. Tauri sadece native shell ekler.

---

## 2. Tech Stack

```
Tauri Version : 2.x (desktop + mobile desteği)
Rust          : stable (src-tauri/ altındaki tüm native kod)
Frontend      : Phoenix LiveView (mevcut web uygulaması)
Mobile        : Tauri 2.x iOS + Android (aynı codebase)
Desktop       : Windows / macOS / Linux
Build Tool    : cargo + tauri-cli
```

---

## 3. Proje Yapısı

```
agentandbot/
  governance_core/       ← Phoenix backend (değişmez)
  desktop/               ← Tauri projesi
    src-tauri/
      src/
        main.rs          ← Tauri app entry, komutlar burada
        lib.rs
      tauri.conf.json    ← Uygulama metadata, izinler, build config
      Cargo.toml
    package.json         ← tauri-cli için (npm/yarn)
```

---

## 4. Kurulum (İlk Kurulum)

```bash
# Rust kurulu değilse
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Tauri CLI
cargo install tauri-cli

# Proje başlat (desktop/ klasöründe)
cargo tauri init

# Mobile (iOS için Xcode, Android için Android Studio gerekli)
cargo tauri android init
cargo tauri ios init
```

---

## 5. `tauri.conf.json` Şablonu (agentandbot için)

```json
{
  "productName": "agentandbot",
  "version": "0.1.0",
  "identifier": "com.agentandbot.desktop",
  "app": {
    "windows": [
      {
        "title": "agentandbot",
        "width": 1280,
        "height": 800,
        "minWidth": 900,
        "minHeight": 600,
        "url": "http://localhost:4001"
      }
    ],
    "security": {
      "csp": null
    }
  },
  "bundle": {
    "active": true,
    "icon": ["icons/icon.png"]
  }
}
```

**Dev modunda:** `url: "http://localhost:4001"` → Phoenix devserver'ı kullanır.  
**Production'da:** Phoenix release binary'i Tauri içine gömülür (sidecar pattern).

---

## 6. Elixir Backend Sidecar (Production)

Production build'de Phoenix'i Tauri ile birlikte paketlemek için:

```rust
// src-tauri/src/main.rs
use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            // Phoenix release'i sidecar olarak başlat
            let sidecar = app.shell()
                .sidecar("governance_core")
                .expect("Phoenix sidecar bulunamadı")
                .spawn()?;
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("Tauri çalıştırılamadı");
}
```

```json
// tauri.conf.json — production URL
"url": "http://localhost:4001"

// externalBin
"bundle": {
  "externalBin": ["binaries/governance_core"]
}
```

---

## 7. Native API Kullanımı

### Sistem Bildirimi (Agent task tamamlandı)
```rust
use tauri_plugin_notification::NotificationExt;

#[tauri::command]
fn notify_task_done(app: tauri::AppHandle, agent: String, task: String) {
    app.notification()
        .builder()
        .title(format!("{} tamamlandı", agent))
        .body(task)
        .show()
        .unwrap();
}
```

### System Tray (Agent durumu)
```rust
use tauri::tray::TrayIconBuilder;

TrayIconBuilder::new()
    .icon(app.default_window_icon().unwrap().clone())
    .tooltip("agentandbot — 3 agent çalışıyor")
    .build(app)?;
```

### Frontend'den Rust komut çağrısı (JavaScript)
```javascript
// Phoenix LiveView hook içinde
import { invoke } from "@tauri-apps/api/core";
await invoke("notify_task_done", { agent: "InvoiceAgent", task: "8 fatura işlendi" });
```

---

## 8. Build Komutları

```bash
# Desktop geliştirme (hot-reload)
cargo tauri dev

# Desktop production build
cargo tauri build

# Android geliştirme
cargo tauri android dev

# Android production APK/AAB
cargo tauri android build

# iOS geliştirme (macOS gerekli)
cargo tauri ios dev

# iOS production
cargo tauri ios build
```

---

## 9. Design System Uyumluluğu

- Tauri window background: `#0B0F14` (transparent veya hardcoded)
- Title bar: custom (native title bar gizle, kendi nav'ını kullan)
- Window radius: macOS'ta otomatik, Windows'ta `decorations: false` + custom
- Mobil: tam ekran webview, native status bar rengi `#0B0F14`

```json
// tauri.conf.json
"windows": [{
  "decorations": true,
  "backgroundColor": "#0B0F14",
  "titleBarStyle": "Overlay"
}]
```

---

## 10. Kısıtlamalar ve Kurallar

```
✅ Frontend kodu (HEEX/HTML/CSS) Tauri'ye özel değiştirilmez
✅ Native özellikler Rust command olarak eklenir
✅ Tauri API'si LiveView hook'ları üzerinden çağrılır (custom JS minimum)
✅ Mobil ve desktop aynı src-tauri/ codebase'inden build edilir
🚫 Electron kullanma (ağır, güvensiz)
🚫 React/Vue ekleme — LiveView yeterli
🚫 Ayrı bir mobil frontend yazma — aynı webview kullanılır
```

---

## Dokümantasyon Referansları

- Tauri 2.x docs: https://v2.tauri.app/
- Tauri mobile: https://v2.tauri.app/plugin/mobile/
- Sidecar pattern: https://v2.tauri.app/develop/sidecar/
- LiveView + Tauri hook: `window.__tauri__` var mı kontrol ederek bağlan
