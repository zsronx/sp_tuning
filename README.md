# SP Tuning

FiveM vehicle tuning resource with a cart-based NUI (body, paint, wheels, performance, lights, plates, extras), orbit camera, localized strings, and an optional mechanic boss dashboard tied to a society account.

**Resource name:** `sp_tuning`  
**Framework assumptions:** [Qbox](https://github.com/Qbox-project/qbx_core) (`qbx_core`) for job checks; payment via Qbox player money APIs.

---

## Features

- **Tuning UI** — Categories, live preview, cart checkout, custom primary/secondary RGB, material presets, right-panel steppers (engine, transmission, brakes, suspension, armor, turbo).
- **Access control** — Restrict tuning to configured job(s) and optionally on-duty only.
- **Zones & blips** — Sphere zones at configurable locations; optional map blips.
- **Camera** — Rotate (click-drag outside panels), zoom (scroll wheel outside panels).
- **Locales** — English (`en`) and German (`de`), driven by `Config.Locale` and files under `locales/`. UI strings are sent to NUI from Lua; notifications and generator labels use the same packs.
- **Boss menu** — For `job.isboss` on the configured job: view society balance (via Renewed-Banking), recent tuning revenue, withdraw to personal account. Command plus optional world zone.
- **Payments** — Bank, cash, or `cash_or_bank` via `Config.PaymentAccount`. Optional share of each sale to the society account (`Config.BossMenu.societyCut`).

---

## Dependencies

| Resource | Required | Role |
|----------|----------|------|
| **ox_lib** | Yes | Zones, callbacks, notify, text UI |
| **qbx_core** | Yes if `Config.TuningAccess.enabled` | Job / duty checks, player data, money |
| **Renewed-Banking** | Only for boss / society payouts | Society account balance, add/remove money |

If `TuningAccess.enabled` is `false`, any player can open tuning (no `qbx_core` job check).

---

## Installation

1. Copy the `sp_tuning` folder into your server `resources` directory (for example `resources/[custom]/sp_tuning`).
2. In `server.cfg` (or your starter list):

   ```cfg
   ensure ox_lib
   ensure qbx_core
   ensure Renewed-Banking
   ensure sp_tuning
   ```

   Use only what your server actually runs; Renewed-Banking is needed if you use the boss dashboard or society cut.

3. Edit `shared/config.lua` — locations, jobs, boss account name, prices, locale, payment account.
4. Restart the resource or the server.

### Adding a language

1. Copy `locales/en.lua` to a new file (for example `locales/fr.lua`).
2. Add that file under `shared_scripts` in `fxmanifest.lua`.
3. Set `Config.Locale` to match the table key (`'fr'` if you used `Locales['fr'] = { ... }`).

Follow the existing pattern in `en.lua`: top-level strings for Lua, `Nui = { ... }` for HTML labels, and `Palettes` for xenon / tint / tire-smoke names.

---

## Usage

### Mechanics

- Sit in the **driver** seat inside a tuning zone → **Open tuning** → press **E** (INPUT_CONTEXT).
- **`/tuning`** — Opens tuning if eligible (same rules as zones).
- **ESC** — Closes UI and reverts previews if you did not complete a purchase.
- **Buy** — Charges the configured account and applies the cart.

### Boss

- **`/werkstattchef`** — Default boss command (`Config.BossMenu.openCommand`); adjust in config.
- Optional **boss location** sphere: **E** when the prompt shows. Requires mechanic job with **`isboss`**.

Mouse: drag on empty screen to orbit; scroll to zoom (ignored while cursor is over the side panels).

---

## Configuration snapshot

| Option | Purpose |
|--------|---------|
| `Config.Locale` | `'en'` or `'de'` (extend via `locales/`) |
| `Config.Currency` | Symbol in UI |
| `Config.PaymentAccount` | `'bank'` \| `'cash'` \| `'cash_or_bank'` |
| `Config.TuningAccess` | Job whitelist, on-duty gate |
| `Config.BossMenu` | Job, Renewed-Banking society name, society cut %, withdraw target, command, optional coords |
| `Config.Locations` | Triggers, radius, blip, labels |
| `Config.Categories` | Tab IDs and labels |
| `Config.Prices` | GTA mod-type prices |
| `Config.StepperPrices` | Right-panel performance pricing |
| `Config.Camera` | Orbit distances and height |

Recent boss transactions are kept in-memory on the server session (with caps); balances come from Renewed-Banking.

---

## Local NUI preview

Open `html/index.html` in a browser:

- **`?dev=1`** — Mock tuning UI; NUI callbacks log to the console.
- **`?dev=1&boss=1`** — Also opens the boss dashboard with mock data.

In dev mode the resource name is stubbed as `sp_tuning`.

---

## Server callbacks

Registered with ox_lib:

- `sp_tuning:server:pay`
- `sp_tuning:server:getBossDashboard`
- `sp_tuning:server:bossWithdraw`

Player debits may be tagged `sp-tuning` in banking / money logs depending on framework.

---

## Repository layout

```
sp_tuning/
├── client/
│   ├── main.lua
│   ├── camera.lua
│   ├── mods.lua
│   └── boss.lua
├── server/
│   └── main.lua
├── shared/
│   ├── config.lua
│   └── locale.lua
├── locales/
│   ├── en.lua
│   └── de.lua
├── html/
│   ├── index.html
│   ├── style.css
│   ├── script.js
│   ├── boss.js
│   └── logo-r.png
├── fxmanifest.lua
└── README.md
```

---

## Sharing & resale

Idc if u resell it or smth else.
