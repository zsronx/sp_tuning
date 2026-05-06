(function () {
    const DEV_NUI = typeof window !== 'undefined' && new URLSearchParams(window.location.search).get('dev') === '1';
    if (DEV_NUI) {
        window.GetParentResourceName = window.GetParentResourceName || function () { return 'sp_tuning'; };
    }

    const bossApp = document.getElementById('bossApp');
    if (!bossApp) return;

    const els = {
        balance: document.getElementById('bossBalance'),
        today: document.getElementById('bossToday'),
        week: document.getElementById('bossWeek'),
        list: document.getElementById('bossTxList'),
        withdrawInput: document.getElementById('bossWithdrawInput'),
        withdrawBtn: document.getElementById('bossWithdrawBtn'),
        closeBtn: document.getElementById('bossCloseBtn'),
    };

    let currency = '$';
    let nuiStrings = {};
    let intlLocale = 'en-US';

    function applyBossDataLoc() {
        bossApp.querySelectorAll('[data-loc]').forEach((el) => {
            const k = el.getAttribute('data-loc');
            if (k && nuiStrings[k] != null && nuiStrings[k] !== '') el.textContent = nuiStrings[k];
        });
        bossApp.querySelectorAll('[data-placeholder-loc]').forEach((el) => {
            const k = el.getAttribute('data-placeholder-loc');
            if (k && nuiStrings[k] != null) el.setAttribute('placeholder', nuiStrings[k]);
        });
    }

    const fmt = (n) => (Number(n) || 0).toLocaleString(intlLocale);

    function formatTime(ts) {
        if (!ts) return '—';
        const d = new Date(ts * 1000);
        return d.toLocaleString(intlLocale, { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
    }

    function renderDashboard(data) {
        if (!data) return;
        currency = data.currency || '$';
        if (els.balance) els.balance.textContent = `${fmt(data.balance)} ${currency}`;
        if (els.today) els.today.textContent = `${fmt(data.today)} ${currency}`;
        if (els.week) els.week.textContent = `${fmt(data.week)} ${currency}`;

        if (els.list) {
            els.list.innerHTML = '';
            const rows = data.transactions || [];
            if (!rows.length) {
                const empty = document.createElement('div');
                empty.className = 'boss-empty';
                empty.textContent = nuiStrings.boss_empty_tx || 'No tuning revenue recorded yet.';
                els.list.appendChild(empty);
            } else {
                rows.forEach((t) => {
                    const row = document.createElement('div');
                    row.className = 'boss-tx-row';
                    row.innerHTML =
                        '<span class="boss-tx-name">' +
                        (t.customer || '—') +
                        '</span>' +
                        '<span class="boss-tx-amt">+' +
                        fmt(t.amount) +
                        ' ' +
                        currency +
                        '</span>' +
                        '<span class="boss-tx-time">' +
                        formatTime(t.ts) +
                        '</span>';
                    els.list.appendChild(row);
                });
            }
        }
    }

    function showBoss() {
        document.body.dataset.activeNui = 'boss';
        bossApp.style.display = 'block';
    }

    function hideBoss() {
        document.body.dataset.activeNui = '';
        bossApp.style.display = 'none';
        if (els.withdrawInput) els.withdrawInput.value = '';
    }

    function post(path, data) {
        if (DEV_NUI && path === 'bossWithdraw') {
            console.debug('[boss dev] withdraw', data);
            return Promise.resolve({
                ok: true,
                dashboard: {
                    currency: '$',
                    balance: 42000,
                    today: 1500,
                    week: 8900,
                    transactions: [
                        { ts: Math.floor(Date.now() / 1000) - 120, amount: 500, customer: 'Max Mustermann' },
                        { ts: Math.floor(Date.now() / 1000) - 3600, amount: 1200, customer: 'Erika Beispiel' },
                    ],
                },
            });
        }
        if (DEV_NUI) {
            console.debug('[boss dev]', path, data);
            return Promise.resolve({ ok: true });
        }
        return fetch('https://' + GetParentResourceName() + '/' + path, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        })
            .then((r) => r.json())
            .catch(() => ({}));
    }

    window.addEventListener('message', (event) => {
        const msg = event.data;
        if (!msg || !msg.action) return;
        if (msg.action === 'bossOpen') {
            nuiStrings = msg.strings || {};
            intlLocale = msg.localeTag || 'en-US';
            applyBossDataLoc();
            renderDashboard(msg.data);
            showBoss();
        }
        if (msg.action === 'bossClose') {
            hideBoss();
        }
        if (msg.action === 'bossData') {
            renderDashboard(msg.data);
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key !== 'Escape') return;
        if (document.body.dataset.activeNui !== 'boss') return;
        e.preventDefault();
        hideBoss();
        post('bossClose', {});
    });

    if (els.closeBtn) {
        els.closeBtn.addEventListener('click', () => {
            hideBoss();
            post('bossClose', {});
        });
    }

    if (els.withdrawBtn && els.withdrawInput) {
        els.withdrawBtn.addEventListener('click', () => {
            const raw = els.withdrawInput.value.replace(/\./g, '').replace(',', '.').trim();
            const amount = Math.floor(parseFloat(raw) || 0);
            if (amount <= 0) return;
            post('bossWithdraw', { amount }).then((res) => {
                if (res && res.ok && res.dashboard) renderDashboard(res.dashboard);
            });
        });
    }

    if (DEV_NUI && new URLSearchParams(window.location.search).get('boss') === '1') {
        setTimeout(() => {
            window.dispatchEvent(
                new MessageEvent('message', {
                    data: {
                        action: 'bossOpen',
                        data: {
                            currency: '$',
                            balance: 125000,
                            today: 24000,
                            week: 156000,
                            transactions: [
                                { ts: Math.floor(Date.now() / 1000) - 300, amount: 8000, customer: 'Anna Schmidt' },
                                { ts: Math.floor(Date.now() / 1000) - 900, amount: 16000, customer: 'Tom Bauer' },
                            ],
                        },
                    },
                })
            );
        }, 100);
    }
})();
