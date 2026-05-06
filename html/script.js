const TABS_VISIBLE = 4;
const STEPPER_KINDS = ['engine', 'transmission', 'brakes', 'suspension', 'armor', 'turbo'];

let nuiStrings = {};
let intlLocale = 'en-US';

function tr(key) {
    const v = nuiStrings[key];
    return v != null && v !== '' ? v : key;
}

function locFormat(tpl, ...args) {
    let n = 0;
    return tpl.replace(/%[sd]/g, () => {
        const v = args[n++];
        return v != null ? String(v) : '';
    });
}

function applyDataLoc(root) {
    if (!root) return;
    root.querySelectorAll('[data-loc]').forEach((el) => {
        const k = el.getAttribute('data-loc');
        if (k && nuiStrings[k] != null && nuiStrings[k] !== '') el.textContent = nuiStrings[k];
    });
    root.querySelectorAll('[data-placeholder-loc]').forEach((el) => {
        const k = el.getAttribute('data-placeholder-loc');
        if (k && nuiStrings[k] != null) el.setAttribute('placeholder', nuiStrings[k]);
    });
}

function fmt(n) {
    return (Number(n) || 0).toLocaleString(intlLocale);
}

const state = {
    categories: [],
    activeCategory: 0,
    tabOffset: 0,
    groups: [],
    cart: {},
    currency: '$',
    colorTarget: 'primary',
    colors: { primary: { h: 0, s: 0, v: 0 }, secondary: { h: 0, s: 0, v: 0 } },
    stepperMeta: { engine: null, transmission: null, brakes: null, suspension: null, armor: null, turbo: null },
    stepperLevels: { engine: -1, transmission: -1, brakes: -1, suspension: -1, armor: -1, turbo: -1 },
    infoText: null
};

const els = {
    app: document.getElementById('app'),
    tabs: document.getElementById('tabs'),
    catPrev: document.getElementById('catPrev'),
    catNext: document.getElementById('catNext'),
    infoBanner: document.getElementById('infoBanner'),
    infoTitle: document.getElementById('infoTitle'),
    infoSubtitle: document.getElementById('infoSubtitle'),
    optionsList: document.getElementById('optionsList'),
    totalPrice: document.getElementById('totalPrice'),
    buyBtn: document.getElementById('buyBtn'),
    svBox: document.getElementById('svBox'),
    svPointer: document.getElementById('svPointer'),
    hueSlider: document.getElementById('hueSlider'),
    huePointer: document.getElementById('huePointer'),
    materialGrid: document.getElementById('materialGrid')
};

const metaKey = m => JSON.stringify(m);

const DEV_NUI = typeof window !== 'undefined' && new URLSearchParams(window.location.search).get('dev') === '1';
if (DEV_NUI) {
    window.GetParentResourceName = () => 'sp_tuning';
}

function devMockOpenPayload() {
    return {
        action: 'open',
        categories: [
            { id: 'aerials', label: 'AERIALS' },
            { id: 'air_filter', label: 'AIR FILTER' },
            { id: 'paint', label: 'PAINT' },
            { id: 'wheels', label: 'WHEELS' }
        ],
        currency: '$',
        infoText: {
            title: 'Browser preview ( ?dev=1 )',
            subtitle: 'NUI callbacks are logged in the console, not sent to the game.'
        },
        localeTag: 'en-US',
        strings: {},
        stepperMeta: {
            engine: { modType: 11, max: 3, current: -1, prices: [12000, 22000, 38000, 60000] },
            transmission: { modType: 13, max: 2, current: 0, prices: [8000, 16000, 28000] },
            brakes: { modType: 12, max: 2, current: -1, prices: [5000, 10000, 18000] },
            suspension: { modType: 15, max: 3, current: -1, prices: [4000, 8000, 14000, 22000] },
            armor: { modType: 16, max: 4, current: -1, prices: [4500, 9000, 15000, 22000, 32000] },
            turbo: { kind: 'toggle', modType: 18, current: false, price: 18000 }
        }
    };
}

function devMockGroups(categoryId) {
    return [{
        title: (categoryId || 'mods').toString().toUpperCase(),
        options: [
            { label: 'STOCK', price: 0, current: true, meta: { kind: 'mod', id: 1, modType: 0, index: -1 } },
            { label: 'OPTION A', price: 500, current: false, meta: { kind: 'mod', id: 2, modType: 0, index: 0 } },
            { label: 'OPTION B', price: 1200, current: false, meta: { kind: 'mod', id: 3, modType: 0, index: 1 } }
        ]
    }];
}

function post(path, data) {
    if (DEV_NUI) {
        if (path === 'requestCategory') {
            const id = data && data.categoryId;
            setTimeout(() => {
                window.dispatchEvent(new MessageEvent('message', {
                    data: { action: 'setGroups', groups: devMockGroups(id) }
                }));
            }, 0);
        } else {
            console.debug('[sp_tuning dev]', path, data);
        }
        return Promise.resolve();
    }
    return fetch(`https://${GetParentResourceName()}/${path}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

function cartTotal() {
    return Object.values(state.cart).reduce((acc, it) => acc + (it.price || 0), 0);
}

function renderTotal() {
    els.totalPrice.textContent = `${fmt(cartTotal())} ${state.currency}`;
}

function clampOffset() {
    const maxOffset = Math.max(0, state.categories.length - TABS_VISIBLE);
    if (state.tabOffset < 0) state.tabOffset = 0;
    if (state.tabOffset > maxOffset) state.tabOffset = maxOffset;
}

function scrollActiveTabIntoView() {
    const active = els.tabs.querySelector('.tab.active');
    if (!active) return;
    active.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
}

function renderTabs() {
    els.tabs.innerHTML = '';
    clampOffset();
    const slice = state.categories.slice(state.tabOffset, state.tabOffset + TABS_VISIBLE);
    slice.forEach((c, i) => {
        const idx = state.tabOffset + i;
        const b = document.createElement('button');
        b.className = 'tab' + (idx === state.activeCategory ? ' active' : '');
        b.textContent = c.label;
        b.addEventListener('click', () => selectCategory(idx));
        els.tabs.appendChild(b);
    });
    requestAnimationFrame(() => scrollActiveTabIntoView());
}

function selectCategory(idx) {
    const len = state.categories.length;
    if (!len) return;
    state.activeCategory = ((idx % len) + len) % len;
    if (state.activeCategory < state.tabOffset) {
        state.tabOffset = state.activeCategory;
    } else if (state.activeCategory >= state.tabOffset + TABS_VISIBLE) {
        state.tabOffset = state.activeCategory - TABS_VISIBLE + 1;
    }
    renderTabs();
    post('requestCategory', { categoryId: state.categories[state.activeCategory].id });
}

els.catPrev.addEventListener('click', () => selectCategory(state.activeCategory - 1));
els.catNext.addEventListener('click', () => selectCategory(state.activeCategory + 1));

function renderOptions() {
    els.optionsList.innerHTML = '';
    if (!state.groups.length) {
        const p = document.createElement('div');
        p.className = 'empty-state';
        p.textContent = tr('options_empty');
        els.optionsList.appendChild(p);
        return;
    }

    state.groups.forEach(group => {
        const head = document.createElement('div');
        head.className = 'option-group-title';
        head.textContent = group.title;
        els.optionsList.appendChild(head);

        group.options.forEach(opt => {
            const key = metaKey(opt.meta);
            const row = document.createElement('div');
            row.className = 'option';
            if (state.cart[key]) {
                row.classList.add('active');
            } else if (opt.current && !hasGroupInCart(group)) {
                row.classList.add('active');
            }

            const name = document.createElement('span');
            name.className = 'opt-name';
            name.textContent = opt.label;
            const price = document.createElement('span');
            price.className = 'opt-price';
            price.textContent = opt.price > 0 ? `${fmt(opt.price)} ${state.currency}` : tr('price_free');

            row.appendChild(name);
            row.appendChild(price);

            row.addEventListener('click', () => onSelectOption(group, opt));
            els.optionsList.appendChild(row);
        });
    });
}

function hasGroupInCart(group) {
    return group.options.some(o => state.cart[metaKey(o.meta)]);
}

function onSelectOption(group, opt) {
    group.options.forEach(o => {
        delete state.cart[metaKey(o.meta)];
    });

    if (!opt.current) {
        state.cart[metaKey(opt.meta)] = {
            meta: opt.meta,
            price: opt.price,
            label: opt.label
        };
    }

    post('preview', { meta: opt.meta });
    renderOptions();
    renderTotal();
}

els.materialGrid.querySelectorAll('.pill').forEach(btn => {
    btn.addEventListener('click', () => {
        els.materialGrid.querySelectorAll('.pill').forEach(p => p.classList.remove('active'));
        btn.classList.add('active');
        post('material', { material: parseInt(btn.dataset.mat, 10) });
    });
});

function hsvToRgb(h, s, v) {
    let c = v * s;
    let x = c * (1 - Math.abs((h / 60) % 2 - 1));
    let m = v - c;
    let r = 0, g = 0, b = 0;
    if (h < 60) { r = c; g = x; }
    else if (h < 120) { r = x; g = c; }
    else if (h < 180) { g = c; b = x; }
    else if (h < 240) { g = x; b = c; }
    else if (h < 300) { r = x; b = c; }
    else { r = c; b = x; }
    return [Math.round((r + m) * 255), Math.round((g + m) * 255), Math.round((b + m) * 255)];
}

function updateSvGradient() {
    const hsv = state.colors[state.colorTarget];
    const [r, g, b] = hsvToRgb(hsv.h, 1, 1);
    els.svBox.style.background =
        'linear-gradient(to top, #000, transparent), ' +
        `linear-gradient(to right, #fff, rgb(${r}, ${g}, ${b}))`;
}

function updatePointers() {
    const hsv = state.colors[state.colorTarget];
    const rect = els.svBox.getBoundingClientRect();
    els.svPointer.style.left = `${hsv.s * 100}%`;
    els.svPointer.style.top = `${(1 - hsv.v) * 100}%`;
    els.huePointer.style.left = `${(hsv.h / 360) * 100}%`;
}

function sendColor() {
    const hsv = state.colors[state.colorTarget];
    const [r, g, b] = hsvToRgb(hsv.h, hsv.s, hsv.v);
    post('customColor', { target: state.colorTarget, r, g, b });
    if (typeof syncColorInputs === 'function') syncColorInputs();
}

function bindColorTargets() {
    document.getElementById('colorPrimary').addEventListener('click', () => {
        state.colorTarget = 'primary';
        document.getElementById('colorPrimary').classList.add('active');
        document.getElementById('colorSecondary').classList.remove('active');
        updateSvGradient(); updatePointers();
    });
    document.getElementById('colorSecondary').addEventListener('click', () => {
        state.colorTarget = 'secondary';
        document.getElementById('colorSecondary').classList.add('active');
        document.getElementById('colorPrimary').classList.remove('active');
        updateSvGradient(); updatePointers();
    });
}

function bindSvBox() {
    let dragging = false;
    const handle = (e) => {
        const rect = els.svBox.getBoundingClientRect();
        const x = Math.max(0, Math.min(rect.width, e.clientX - rect.left));
        const y = Math.max(0, Math.min(rect.height, e.clientY - rect.top));
        const hsv = state.colors[state.colorTarget];
        hsv.s = x / rect.width;
        hsv.v = 1 - y / rect.height;
        updatePointers();
        sendColor();
    };
    els.svBox.addEventListener('mousedown', e => { dragging = true; handle(e); });
    window.addEventListener('mousemove', e => { if (dragging) handle(e); });
    window.addEventListener('mouseup', () => { dragging = false; });
}

function bindHue() {
    let dragging = false;
    const handle = (e) => {
        const rect = els.hueSlider.getBoundingClientRect();
        const x = Math.max(0, Math.min(rect.width, e.clientX - rect.left));
        const hsv = state.colors[state.colorTarget];
        hsv.h = (x / rect.width) * 360;
        updateSvGradient();
        updatePointers();
        sendColor();
    };
    els.hueSlider.addEventListener('mousedown', e => { dragging = true; handle(e); });
    window.addEventListener('mousemove', e => { if (dragging) handle(e); });
    window.addEventListener('mouseup', () => { dragging = false; });
}

const hexInput = document.getElementById('hexInput');
const rInput = document.getElementById('rInput');
const gInput = document.getElementById('gInput');
const bInput = document.getElementById('bInput');

function rgbToHsv(r, g, b) {
    r /= 255; g /= 255; b /= 255;
    const max = Math.max(r, g, b), min = Math.min(r, g, b);
    const d = max - min;
    let h = 0;
    const s = max === 0 ? 0 : d / max;
    const v = max;
    if (d !== 0) {
        if (max === r) h = ((g - b) / d) % 6;
        else if (max === g) h = (b - r) / d + 2;
        else h = (r - g) / d + 4;
        h *= 60;
        if (h < 0) h += 360;
    }
    return { h, s, v };
}

function currentRgb() {
    const hsv = state.colors[state.colorTarget];
    return hsvToRgb(hsv.h, hsv.s, hsv.v);
}

function toHex(n) { return n.toString(16).padStart(2, '0'); }

function syncColorInputs() {
    const [r, g, b] = currentRgb();
    if (hexInput) hexInput.value = `#${toHex(r)}${toHex(g)}${toHex(b)}`.toUpperCase();
    if (rInput) rInput.value = r;
    if (gInput) gInput.value = g;
    if (bInput) bInput.value = b;
}

function applyRgb(r, g, b) {
    r = Math.max(0, Math.min(255, r | 0));
    g = Math.max(0, Math.min(255, g | 0));
    b = Math.max(0, Math.min(255, b | 0));
    const hsv = rgbToHsv(r, g, b);
    state.colors[state.colorTarget] = hsv;
    updateSvGradient();
    updatePointers();
    syncColorInputs();
    sendColor();
}

if (hexInput) {
    hexInput.addEventListener('change', () => {
        let v = hexInput.value.trim().replace(/^#/, '');
        if (v.length === 3) v = v.split('').map(c => c + c).join('');
        if (!/^[0-9a-fA-F]{6}$/.test(v)) { syncColorInputs(); return; }
        const r = parseInt(v.slice(0, 2), 16);
        const g = parseInt(v.slice(2, 4), 16);
        const b = parseInt(v.slice(4, 6), 16);
        applyRgb(r, g, b);
    });
}

[rInput, gInput, bInput].forEach(inp => {
    if (!inp) return;
    inp.addEventListener('change', () => {
        applyRgb(parseInt(rInput.value, 10) || 0, parseInt(gInput.value, 10) || 0, parseInt(bInput.value, 10) || 0);
    });
});

bindColorTargets();
bindSvBox();
bindHue();
syncColorInputs();

const STEPPER_CART_PREFIX = '__stepper_';

function stepperCartKey(kind) {
    return STEPPER_CART_PREFIX + kind;
}

function priceForStepperLevel(kind, level) {
    const meta = state.stepperMeta[kind];
    if (!meta || level < 0) return 0;
    if (kind === 'turbo') return meta.price || 0;
    const prices = meta.prices || [];
    if (level < prices.length) return prices[level];
    return prices[prices.length - 1] || 0;
}

function stepperMaxFor(kind) {
    const meta = state.stepperMeta[kind];
    if (!meta) return -1;
    if (kind === 'turbo') return 0;
    return typeof meta.max === 'number' ? meta.max : -1;
}

function stepperInitialLevel(kind) {
    const meta = state.stepperMeta[kind];
    if (!meta) return -1;
    if (kind === 'turbo') {
        return meta.current === true || meta.current === 1 ? 0 : -1;
    }
    return typeof meta.current === 'number' ? meta.current : -1;
}

function setStepperLevel(kind, level) {
    const meta = state.stepperMeta[kind];
    if (!meta) return;
    const max = stepperMaxFor(kind);
    if (level > max) level = max;
    if (level < -1) level = -1;
    state.stepperLevels[kind] = level;

    const key = stepperCartKey(kind);
    const initial = stepperInitialLevel(kind);
    if (level !== initial) {
        const metaPayload = { kind: 'stepperMod', stepperKind: kind };
        if (kind === 'turbo') {
            metaPayload.state = level >= 0;
        } else {
            metaPayload.level = level;
        }
        state.cart[key] = {
            meta: metaPayload,
            price: priceForStepperLevel(kind, level),
            label: `${kind} lvl ${level + 1}`
        };
    } else {
        delete state.cart[key];
    }

    renderStepper(kind);
    renderTotal();
    if (kind === 'turbo') {
        post('stepperPreview', { kind, state: level >= 0 });
    } else {
        post('stepperPreview', { kind, level });
    }
}

document.querySelectorAll('.step-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const kind = btn.dataset.step;
        const dir = parseInt(btn.dataset.dir, 10);
        setStepperLevel(kind, state.stepperLevels[kind] + dir);
    });
});

function renderStepper(kind) {
    const el = document.getElementById(`${kind}Value`);
    if (!el) return;
    const meta = state.stepperMeta[kind];
    const lvl = state.stepperLevels[kind];
    const max = stepperMaxFor(kind);

    if (!meta || max < 0) {
        el.textContent = kind === 'turbo' ? tr('turbo_no') : tr('stepper_na');
        return;
    }

    if (kind === 'turbo') {
        if (lvl < 0) {
            el.textContent = tr('turbo_no');
        } else {
            el.textContent = locFormat(tr('turbo_yes_fmt'), fmt(priceForStepperLevel(kind, 0)), state.currency);
        }
        return;
    }

    if (lvl < 0) {
        el.textContent = tr('stock');
    } else {
        const price = priceForStepperLevel(kind, lvl);
        el.textContent = locFormat(tr('stepper_level_fmt'), lvl + 1, fmt(price), state.currency);
    }
}

els.buyBtn.addEventListener('click', () => {
    const cartPayload = Object.values(state.cart).map(it => ({ meta: it.meta, price: it.price }));
    post('buy', { cart: cartPayload, total: cartTotal() });
});

document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;
    if (document.body.dataset.activeNui === 'boss') return;
    post('close', {});
});

const leftPanelEl = document.getElementById('leftPanel');
const rightPanelEl = document.getElementById('rightPanel');

function isOverPanel(target) {
    return leftPanelEl.contains(target) || rightPanelEl.contains(target);
}

let camDragging = false;
let lastX = 0;
let lastY = 0;

document.addEventListener('mousedown', (e) => {
    if (e.button !== 0) return;
    if (isOverPanel(e.target)) return;
    camDragging = true;
    lastX = e.clientX;
    lastY = e.clientY;
    document.body.style.cursor = 'grabbing';
});

document.addEventListener('mousemove', (e) => {
    if (!camDragging) return;
    const dx = e.clientX - lastX;
    const dy = e.clientY - lastY;
    lastX = e.clientX;
    lastY = e.clientY;
    if (dx === 0 && dy === 0) return;
    post('camRotate', { dx: dx * 0.5, dy: dy * 0.3 });
});

document.addEventListener('mouseup', () => {
    camDragging = false;
    document.body.style.cursor = '';
});

document.addEventListener('wheel', (e) => {
    if (isOverPanel(e.target)) return;
    const delta = e.deltaY > 0 ? 0.4 : -0.4;
    post('camZoom', { delta });
}, { passive: true });

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'open') {
        nuiStrings = data.strings || {};
        intlLocale = data.localeTag || 'en-US';

        state.categories = data.categories || [];
        state.currency = data.currency || '$';
        state.infoText = data.infoText || null;
        state.cart = {};
        state.activeCategory = 0;
        state.tabOffset = 0;
        state.stepperMeta = data.stepperMeta || {};
        STEPPER_KINDS.forEach(k => {
            if (!state.stepperMeta[k]) state.stepperMeta[k] = null;
            state.stepperLevels[k] = stepperInitialLevel(k);
        });

        applyDataLoc(els.app);

        if (state.infoText) {
            els.infoTitle.textContent = state.infoText.title;
            els.infoSubtitle.textContent = state.infoText.subtitle;
            els.infoBanner.style.display = 'flex';
        } else {
            els.infoBanner.style.display = 'none';
        }
        renderTabs();
        STEPPER_KINDS.forEach(renderStepper);
        syncColorInputs();
        state.groups = [];
        renderOptions();
        renderTotal();
        updateSvGradient();
        updatePointers();
        els.app.style.display = 'block';
        if (state.categories.length) selectCategory(0);
    } else if (data.action === 'close') {
        els.app.style.display = 'none';
    } else if (data.action === 'setGroups') {
        state.groups = data.groups || [];
        renderOptions();
    } else if (data.action === 'setStepper') {
        state.stepperLevels[data.kind] = data.level;
        renderStepper(data.kind);
    } else if (data.action === 'clearCart') {
        state.cart = {};
        renderOptions();
        renderTotal();
    }
});

if (DEV_NUI) {
    document.body.classList.add('dev-nui');
    setTimeout(() => {
        window.dispatchEvent(new MessageEvent('message', { data: devMockOpenPayload() }));
    }, 0);
}
