# SP Tuning

FiveM vehicle tuning resource with a cart-based NUI (body, paint, wheels, performance, lights, plates, extras), orbit camera, localized strings, and an optional mechanic boss dashboard backed by job / organisation (**society**) money **through Qbox**.

**Resource name:** `sp_tuning`  

**Framework:** [Qbox](https://github.com/Qbox-project/qbx_core) (`qbx_core`) for jobs, duty, player balances, and (when configured for your server) **organisation account** reads and transfers. Payments use standard Qbox player money APIs.

Boss menu balances and tuning **society cuts** are not tied to any one banking script: you plug in **your** accounting system by editing **`qbx_core`** (see [Connecting organisation / society money](#connecting-organisation--society-money)).

---

## Features

- **Tuning UI** — Categories, live preview, cart checkout, custom primary/secondary RGB, material presets, right-panel steppers (engine, transmission, brakes, suspension, armor, turbo).
- **Access control** — Restrict tuning to configured job(s) and optionally on-duty only.
- **Zones & blips** — Sphere zones at configurable locations; optional map blips.
- **Camera** — Rotate (click-drag outside panels), zoom (scroll wheel outside panels).
- **Locales** — English (`en`) and German (`de`), driven by `Config.Locale` and files under `locales/`. UI strings are sent to NUI from Lua; notifications and generator labels use the same packs.
- **Boss menu** — For `job.isboss` on the configured job: view organisation balance, recent tuning revenue, withdraw to the player. Uses **`qbx_core`** exports you wire to your economy ([Connecting organisation / society money](#connecting-organisation--society-money)).
- **Payments** — Bank, cash, or `cash_or_bank` via `Config.PaymentAccount`. Optional share of each sale to the organisation account (`Config.BossMenu.societyCut`).

---

## Dependencies

| Resource | Required | Role |
|----------|----------|------|
| **ox_lib** | Yes | Zones, callbacks, notify, text UI |
| **qbx_core** | Yes for normal use | Jobs, duty, player data, `RemoveMoney`; organisation money only after [Connecting organisation / society money](#connecting-organisation--society-money) |

If `TuningAccess.enabled` is `false`, anyone can open tuning (no job check). Purchases still need `qbx_core` for player debits.

---

## Installation

1. Copy the `sp_tuning` folder into your server `resources` directory (for example `resources/[custom]/sp_tuning`).
2. Wire **organisation / society money** in `qbx_core` (required if you use the boss menu or `societyCut`): [Connecting organisation / society money](#connecting-organisation--society-money).
3. In `server.cfg` (or your starter list), include dependencies you actually use, for example:

   ```cfg
   ensure ox_lib
   ensure qbx_core
   # ensure your_banking_or_management   # if your society hooks call into another resource
   ensure sp_tuning
   ```

   Start any resource your `qbx_core` society functions call into **before** `sp_tuning` if those exports must be available at runtime.

4. Edit `shared/config.lua` — locations, jobs, `Config.BossMenu.societyAccount` (must match the account id your banking uses), prices, locale, payment account.
5. Restart the resource or the server.

---

## Connecting organisation / society money

`sp_tuning` does **not** import a specific banking resource. It expects **`qbx_core`** to expose three server exports that you implement to match **your** stack:

| Export | Used for |
|--------|----------|
| `GetSocietyAccount(accountName)` | Boss UI balance; must return a **number** (balance), or a falsy value if unknown (UI treats as 0). |
| `AddSocietyMoney(accountName, amount)` | Depositing the tuning **society cut** after a purchase; must return **`true`** on success. |
| `RemoveSocietyMoney(accountName, amount)` | Boss **withdraw** from the org account; must return **`true`** on success. |

**Account id:** Set `Config.BossMenu.societyAccount` in `sp_tuning/shared/config.lua` to the same string your banking uses (often the **job name**, e.g. `mechanic`).

### 1. Implement hooks in `qbx_core/config/server.lua`

In your Qbox install, open **`qbx_core/config/server.lua`**. You will see (or add) three functions next to the other server callbacks. Their **names and signatures** matter; the **bodies** are yours.

Point each at **your** resource’s exports or your own SQL. Names and parameters differ per script—use that script’s server documentation.

```lua
-- Example shape only — replace with real calls to YOUR banking / management resource.
getSocietyAccount = function(accountName)
    -- return balance as number, or false/nil if missing
end,

addSocietyMoney = function(accountName, amount)
    -- credit the organisation account; return true on success
end,

removeSocietyMoney = function(accountName, amount)
    -- debit the organisation account; return true on success
end,
```

Use `pcall` if the external export might throw. Return **`false`** (or let the export return false) on failure so tuning can log and skip crediting the org without breaking the player charge.

If your stock `server.lua` only defines **read** and **subtract** (common for paycheck-from-society), you still need **`addSocietyMoney`** for tuning revenue—add it alongside the others.

### 2. Register the matching `qbx_core` exports

`sp_tuning` calls **`exports.qbx_core:GetSocietyAccount`**, **`AddSocietyMoney`**, **`RemoveSocietyMoney`**. Your `qbx_core` must register those names (some forks ship this; if not, add near the end of **`qbx_core/server/functions.lua`**):

```lua
local societyCfg = require 'config.server'

function GetSocietyAccount(accountName)
    return societyCfg.getSocietyAccount(accountName)
end
exports('GetSocietyAccount', GetSocietyAccount)

function AddSocietyMoney(accountName, amount)
    return societyCfg.addSocietyMoney(accountName, amount)
end
exports('AddSocietyMoney', AddSocietyMoney)

function RemoveSocietyMoney(accountName, amount)
    return societyCfg.removeSocietyMoney(accountName, amount)
end
exports('RemoveSocietyMoney', RemoveSocietyMoney)
```

Restart `qbx_core` after edits.

### 3. Align `sp_tuning` server code

Your **`sp_tuning/server/main.lua`** should call **`exports.qbx_core`** for those three operations (not a hard-coded banking resource). If you still see direct `exports['Some-Banking']` calls, replace them with the `qbx_core` exports so all servers can use the same README steps.

---

## Adding a language

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
| `Config.BossMenu` | Job, organisation account id (`societyAccount`), society cut %, withdraw target, command, optional coords |
| `Config.Locations` | Triggers, radius, blip, labels |
| `Config.Categories` | Tab IDs and labels |
| `Config.Prices` | GTA mod-type prices |
| `Config.StepperPrices` | Right-panel performance pricing |
| `Config.Camera` | Orbit distances and height |

Recent boss transactions are kept in-memory on the server session (with caps); the **live** balance comes from **`GetSocietyAccount`** as you implemented it in `qbx_core`.

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

Player debits may be tagged `sp-tuning` in money logs depending on framework.

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

Use it however you want: resell it, bundle it with paid packs, rework it for clients, or run it on your server—the author does not mind.
