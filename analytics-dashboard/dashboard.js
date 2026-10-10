/* CortiFree analytics dashboard.
 *
 * Every figure is fetched live from the local proxy (dashboard_server.py) which forwards
 * to Amplitude and RevenueCat. Event names below are only the *semantic keys* each page
 * looks for (with fallbacks for older names); when an event has not been received yet,
 * the card shows an explicit "no data yet" state instead of a number.
 */
(() => {
  "use strict";

  // ------------------------------------------------------------------ state
  const S = {
    preset: "30d",
    customStart: null,
    customEnd: null,
    known: new Set(),
    catalog: [],
    status: null,
    refreshToken: -1,
    token: 0,
    charts: [],
    explorer: { selected: null, search: "", prop: "", ptype: "event" },
    onboardingFlow: null,
    paywallDim: "placement",
  };

  const PAGES = {
    overview: { title: "Vue d'ensemble", render: renderOverview },
    onboarding: { title: "Onboarding", render: renderOnboarding },
    icp: { title: "Profil ICP", render: renderICP },
    monetization: { title: "Monétisation", render: renderMonetization },
    engagement: { title: "Engagement & rétention", render: renderEngagement },
    notifications: { title: "Notifications", render: renderNotifications },
    explorer: { title: "Explorateur d'événements", render: renderExplorer },
  };

  const SERIES = ["#3987e5", "#d95926", "#199e70", "#c98500", "#d55181", "#008300", "#9085e9", "#e66767"];
  const GRID = "rgba(255,255,255,0.06)";
  const TICK = "#8d8c85";

  // ------------------------------------------------------------------ utils
  const $ = (sel, root = document) => root.querySelector(sel);
  const el = (tag, attrs = {}, ...children) => {
    const node = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (v == null || v === false) continue;
      if (k === "class") node.className = v;
      else if (k === "html") node.innerHTML = v;
      else if (k.startsWith("on")) node.addEventListener(k.slice(2), v);
      else node.setAttribute(k, v === true ? "" : v);
    }
    for (const child of children.flat()) {
      if (child == null || child === false) continue;
      node.append(child instanceof Node ? child : document.createTextNode(String(child)));
    }
    return node;
  };
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const nf = new Intl.NumberFormat("fr-FR");
  const nf1 = new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 1 });
  const fmtNum = (v) => (v == null || Number.isNaN(v) ? "—" : Math.abs(v) >= 100 ? nf.format(Math.round(v)) : nf1.format(v));
  const fmtPct = (v, digits = 1) => (v == null || !Number.isFinite(v) ? "—" : `${(v * 100).toFixed(digits).replace(".", ",")} %`);
  const fmtMoney = (v, cur = "USD") => (v == null ? "—" : new Intl.NumberFormat("fr-FR", { style: "currency", currency: cur || "USD", maximumFractionDigits: v >= 100 ? 0 : 2 }).format(v));
  const fmtDur = (ms) => {
    if (ms == null || ms < 0) return "—";
    const s = ms / 1000;
    if (s < 90) return `${Math.round(s)} s`;
    if (s < 5400) return `${Math.round(s / 60)} min`;
    if (s < 172800) return `${nf1.format(s / 3600)} h`;
    return `${nf1.format(s / 86400)} j`;
  };
  const sum = (arr) => (arr || []).reduce((a, b) => a + (Number(b) || 0), 0);
  const shortDay = (iso) => { const [, m, d] = String(iso).split("-"); return d && m ? `${d}/${m}` : iso; };

  // ------------------------------------------------------------------ dates
  const ymd = (d) => `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, "0")}${String(d.getDate()).padStart(2, "0")}`;
  const isoDate = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  const addDays = (d, n) => { const x = new Date(d); x.setDate(x.getDate() + n); return x; };
  const today = () => { const d = new Date(); d.setHours(0, 0, 0, 0); return d; };
  const daysBetween = (a, b) => Math.round((b - a) / 86400000) + 1;

  function currentRange() {
    const end = today();
    let start;
    switch (S.preset) {
      case "today": start = end; break;
      case "7d": start = addDays(end, -6); break;
      case "90d": start = addDays(end, -89); break;
      case "custom": {
        const s = S.customStart ? new Date(S.customStart + "T00:00:00") : addDays(end, -29);
        const e = S.customEnd ? new Date(S.customEnd + "T00:00:00") : end;
        return { start: s <= e ? s : e, end: s <= e ? e : s, days: daysBetween(s <= e ? s : e, s <= e ? e : s) };
      }
      default: start = addDays(end, -29);
    }
    return { start, end, days: daysBetween(start, end) };
  }
  const prevRange = (r) => { const end = addDays(r.start, -1); return { start: addDays(end, -(r.days - 1)), end, days: r.days }; };
  const rp = (r) => ({ start: ymd(r.start), end: ymd(r.end) });
  const rangeLabel = (r) => r.days === 1 ? r.start.toLocaleDateString("fr-FR", { day: "numeric", month: "long" })
    : `${r.start.toLocaleDateString("fr-FR", { day: "numeric", month: "short" })} → ${r.end.toLocaleDateString("fr-FR", { day: "numeric", month: "short", year: "numeric" })} · ${r.days} jours`;

  // ------------------------------------------------------------------ api
  async function api(path, params = {}) {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries(params)) {
      if (v == null) continue;
      q.set(k, typeof v === "object" ? JSON.stringify(v) : String(v));
    }
    if (S.refreshToken === S.token) q.set("refresh", "1");
    let attempt = 0;
    for (;;) {
      const res = await fetch(`${path}?${q}`);
      let body = {};
      try { body = await res.json(); } catch (_) { /* non-JSON */ }
      if (res.ok) return body;
      if (res.status === 429 && attempt < 2) { attempt += 1; await new Promise((r) => setTimeout(r, 4000 * attempt)); continue; }
      throw new Error(body.error || `HTTP ${res.status}`);
    }
  }

  const has = (name) => name && (name.startsWith("_") || S.known.has(name));
  const available = (list) => list.filter(has);
  const firstAvailable = (list) => list.find(has) || null;
  const discovered = (prefix) => S.catalog.map((e) => e.name).filter((n) => n.startsWith(prefix));

  /** /api/series calls made in the same tick with the same range/metric are merged into one request
   *  (the server then queries Amplitude two events at a time). */
  const pendingSeries = new Map();
  function seriesBatched(events, params) {
    const key = JSON.stringify(params);
    let batch = pendingSeries.get(key);
    if (!batch) {
      batch = { specs: new Map(), promise: null };
      pendingSeries.set(key, batch);
      batch.promise = new Promise((resolve, reject) => setTimeout(() => {
        pendingSeries.delete(key);
        api("/api/series", { ...params, events: [...batch.specs.values()] }).then(resolve, reject);
      }, 0));
    }
    events.forEach((e) => batch.specs.set(JSON.stringify(e), e));
    return batch.promise;
  }

  function shapeSeries(r, events, from = 0, to) {
    const x = (r.xValues || []).slice(from, to);
    const series = x.map((_, i) => events.reduce((a, e) => a + ((r.series[e] || [])[from + i] || 0), 0));
    return { missing: false, x, series, total: sum(series), events };
  }

  /** Daily series summed over the available candidate events. */
  async function metricSeries(candidates, m, range, mode = "sum") {
    const events = mode === "first" ? [firstAvailable(candidates)].filter(Boolean) : available(candidates);
    if (!events.length) return { missing: true, candidates, x: [], series: [], total: 0, events: [] };
    const r = await seriesBatched(events, { m, ...rp(range) });
    const shaped = shapeSeries(r, events);
    // For unique users the period value is the de-duplicated count, not the sum of days.
    shaped.total = events.reduce((a, e) => a + (r.totals[e] || 0), 0);
    return shaped;
  }

  /** Current + previous period. Totals are fetched in one call over both periods and split. */
  async function metricWithPrev(candidates, m, range, mode = "sum") {
    const prev = prevRange(range);
    if (m !== "totals") return Promise.all([metricSeries(candidates, m, range, mode), metricSeries(candidates, m, prev, mode)]);
    const events = mode === "first" ? [firstAvailable(candidates)].filter(Boolean) : available(candidates);
    if (!events.length) { const miss = { missing: true, candidates, x: [], series: [], total: 0, events: [] }; return [miss, miss]; }
    const r = await seriesBatched(events, { m, start: ymd(prev.start), end: ymd(range.end) });
    const split = Math.max(0, (r.xValues || []).length - range.days);
    return [shapeSeries(r, events, split), shapeSeries(r, events, 0, split)];
  }

  // ------------------------------------------------------------------ chart helpers
  if (window.Chart) {
    Chart.defaults.color = TICK;
    Chart.defaults.font.family = getComputedStyle(document.body).fontFamily;
    Chart.defaults.font.size = 11.5;
    Chart.defaults.borderColor = GRID;
    Chart.defaults.plugins.tooltip.backgroundColor = "#2b2b29";
    Chart.defaults.plugins.tooltip.borderColor = "#3a3a37";
    Chart.defaults.plugins.tooltip.borderWidth = 1;
    Chart.defaults.plugins.tooltip.titleColor = "#f4f4f1";
    Chart.defaults.plugins.tooltip.bodyColor = "#c3c2b7";
    Chart.defaults.plugins.tooltip.padding = 10;
    Chart.defaults.plugins.tooltip.boxPadding = 4;
    Chart.defaults.plugins.legend.labels.boxWidth = 10;
    Chart.defaults.plugins.legend.labels.boxHeight = 10;
    Chart.defaults.plugins.legend.labels.useBorderRadius = true;
    Chart.defaults.plugins.legend.labels.borderRadius = 3;
  }

  function mountChart(container, config) {
    if (!window.Chart) { container.append(errorBox("Chart.js n'a pas pu être chargé (pas de connexion ?)")); return null; }
    const canvas = el("canvas");
    container.replaceChildren(canvas);
    const chart = new Chart(canvas, config);
    S.charts.push(chart);
    return chart;
  }

  function lineChart(container, labels, datasets, opts = {}) {
    const many = labels.length > 45;
    return mountChart(container, {
      type: opts.bar ? "bar" : "line",
      data: {
        labels: labels.map(opts.labelFmt || shortDay),
        datasets: datasets.map((d, i) => {
          const color = d.color || SERIES[i % SERIES.length];
          return {
            label: d.label, data: d.data,
            borderColor: color, backgroundColor: opts.bar ? color : color + "22",
            borderWidth: 2, pointRadius: labels.length <= 1 ? 4 : 0, pointHoverRadius: 4, tension: 0.25, cubicInterpolationMode: "monotone",
            fill: opts.fill && i === 0 ? "origin" : false, borderRadius: opts.bar ? 4 : 0, maxBarThickness: 28,
            stack: opts.stacked ? "s" : undefined, spanGaps: true,
          };
        }),
      },
      options: {
        maintainAspectRatio: false, animation: { duration: 250 },
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: { display: datasets.length > 1, position: "top", align: "start" },
          tooltip: { callbacks: { label: (c) => ` ${c.dataset.label} : ${opts.valueFmt ? opts.valueFmt(c.parsed.y) : fmtNum(c.parsed.y)}` } },
        },
        scales: {
          x: { grid: { display: false }, ticks: { maxRotation: 0, autoSkip: true, maxTicksLimit: many ? 10 : 14 }, stacked: !!opts.stacked },
          y: { beginAtZero: true, grid: { color: GRID }, border: { display: false }, stacked: !!opts.stacked,
               ticks: { precision: 0, callback: (v) => (opts.valueFmt ? opts.valueFmt(v) : fmtNum(v)) }, max: opts.yMax },
        },
      },
    });
  }

  function hbarChart(container, labels, datasets, opts = {}) {
    container.style.height = `${Math.max(140, labels.length * (datasets.length > 1 ? 30 : 24) + 50)}px`;
    return mountChart(container, {
      type: "bar",
      data: { labels, datasets: datasets.map((d, i) => ({ label: d.label, data: d.data, backgroundColor: d.color || SERIES[i % SERIES.length], borderRadius: 4, maxBarThickness: 18 })) },
      options: {
        indexAxis: "y", maintainAspectRatio: false, animation: { duration: 250 },
        interaction: { mode: "index", intersect: false, axis: "y" },
        plugins: { legend: { display: datasets.length > 1, position: "top", align: "start" },
          tooltip: { callbacks: { label: (c) => ` ${c.dataset.label} : ${opts.valueFmt ? opts.valueFmt(c.parsed.x) : fmtNum(c.parsed.x)}` } } },
        scales: {
          x: { beginAtZero: true, grid: { color: GRID }, border: { display: false }, ticks: { precision: 0, callback: (v) => (opts.valueFmt ? opts.valueFmt(v) : fmtNum(v)) } },
          y: { grid: { display: false }, ticks: { autoSkip: false, callback(v) { const s = this.getLabelForValue(v); return s.length > 28 ? s.slice(0, 27) + "…" : s; } } },
        },
      },
    });
  }

  function sparkline(container, data, color = SERIES[0]) {
    if (!window.Chart || !data || data.length < 2) return;
    mountChart(container, {
      type: "line",
      data: { labels: data.map((_, i) => i), datasets: [{ data, borderColor: color, backgroundColor: color + "26", fill: "origin", borderWidth: 1.6, pointRadius: 0, tension: 0.3 }] },
      options: { maintainAspectRatio: false, animation: false, plugins: { legend: { display: false }, tooltip: { enabled: false } },
        scales: { x: { display: false }, y: { display: false, beginAtZero: true } }, events: [] },
    });
  }

  // ------------------------------------------------------------------ UI blocks
  function errorBox(message, retry) {
    return el("div", { class: "error" },
      el("span", {}, "⚠︎"),
      el("span", {}, message),
      retry ? el("button", { class: "btn", onclick: retry }, "Réessayer") : null);
  }

  function emptyBox(title, events, extra) {
    return el("div", { class: "empty" },
      el("strong", {}, title || "Pas encore de données"),
      events && events.length ? el("div", { html: `En attente de ${events.map((e) => `<code>${esc(e)}</code>`).join(" ou ")} dans Amplitude.` }) : null,
      extra ? el("div", {}, extra) : null);
  }

  function skeleton(kind = "block") {
    if (kind === "kpi") return el("div", {}, el("div", { class: "skeleton sk-value" }), el("div", { class: "skeleton sk-line", style: "width:40%" }), el("div", { class: "skeleton", style: "height:34px;margin-top:8px" }));
    if (kind === "lines") return el("div", {}, [1, 2, 3, 4, 5].map((i) => el("div", { class: "skeleton sk-line", style: `width:${95 - i * 9}%` })));
    return el("div", { class: "skeleton sk-block" });
  }

  /** A card whose body is filled by an async loader; errors and empty states stay inline. */
  function card({ title, sub, cls = "", tools, load, skeletonKind = "block" }) {
    const body = el("div", { class: "card-body" }, skeleton(skeletonKind));
    const toolsNode = tools ? el("div", { class: "card-tools" }, tools) : null;
    const node = el("section", { class: `card ${cls}` },
      title ? el("div", { class: "card-head" }, el("div", {}, el("div", { class: "card-title" }, title), sub ? el("div", { class: "card-sub" }, sub) : null), toolsNode) : null,
      body);
    const token = S.token;
    const run = async () => {
      body.replaceChildren(skeleton(skeletonKind));
      try {
        await load(body, node);
      } catch (error) {
        if (token !== S.token) return;
        body.replaceChildren(errorBox(error.message || String(error), run));
      }
    };
    node._run = run;
    queueMicrotask(run);
    return node;
  }

  function deltaBadge(cur, prev, { invert = false } = {}) {
    if (cur == null || prev == null || !Number.isFinite(cur) || !Number.isFinite(prev)) return el("span", { class: "vs" }, "pas de comparaison");
    if (prev === 0) return el("span", { class: "vs" }, cur === 0 ? "= période précédente" : "nouveau vs 0");
    const change = (cur - prev) / Math.abs(prev);
    const up = change > 0.0005, down = change < -0.0005;
    const good = invert ? down : up, bad = invert ? up : down;
    return el("span", {},
      el("span", { class: `delta ${good ? "up" : bad ? "down" : ""}` }, `${up ? "▲" : down ? "▼" : "■"} ${fmtPct(Math.abs(change), 0)}`),
      el("span", { class: "vs" }, " vs préc."));
  }

  /** KPI tile: load() returns {value, prev, spark, fmt, note, missing, missingEvents, invert}. */
  function kpi(label, load, color) {
    return card({
      cls: "kpi", skeletonKind: "kpi",
      load: async (body) => {
        const r = await load();
        const fmt = r.fmt || fmtNum;
        const nodes = [el("div", { class: "kpi-label" }, label)];
        if (r.missing) {
          nodes.push(el("div", { class: "kpi-value muted" }, "—"));
          nodes.push(el("div", { class: "kpi-note", title: (r.missingEvents || []).join(", ") }, r.missingNote || `En attente : ${(r.missingEvents || []).join(" / ")}`));
          body.replaceChildren(...nodes);
          return;
        }
        nodes.push(el("div", { class: "kpi-value" }, fmt(r.value)));
        nodes.push(el("div", { class: "kpi-row" }, r.prev !== undefined ? deltaBadge(r.value, r.prev, { invert: r.invert }) : null));
        const spark = el("div", { class: "spark" });
        nodes.push(spark);
        if (r.note) nodes.push(el("div", { class: "kpi-note", title: r.note }, r.note));
        body.replaceChildren(...nodes);
        sparkline(spark, r.spark, color);
      },
    });
  }

  function legendNode(items) {
    return el("div", { class: "legend" }, items.map((it, i) => el("span", {}, el("i", { style: `background:${it.color || SERIES[i]}` }), it.label)));
  }

  function pendingList(events, label = "En attente de données :") {
    if (!events || !events.length) return null;
    return el("div", { class: "pending" }, el("span", {}, label), events.map((e) => el("span", { class: "tag muted" }, e)));
  }

  function table(headers, rows, opts = {}) {
    return el("div", { class: "table-wrap", style: opts.maxHeight ? `max-height:${opts.maxHeight}px` : null },
      el("table", { class: opts.cls || "" },
        el("thead", {}, el("tr", {}, headers.map((h) => el("th", { class: h.num ? "num" : "" }, h.label)))),
        el("tbody", {}, rows.map((row) => el("tr", {}, row.map((cell, i) => {
          const td = el("td", { class: headers[i] && headers[i].num ? "num" : "" });
          if (cell instanceof Node) td.append(cell); else td.textContent = cell == null ? "—" : cell;
          return td;
        }))))));
  }

  function barCell(value, max, text) {
    return el("div", { class: "bar-cell" }, el("span", {}, text ?? fmtNum(value)),
      el("div", { class: "mini-bar" }, el("div", { style: `width:${max ? Math.max(2, (value / max) * 100) : 0}%` })));
  }

  // ------------------------------------------------------------------ funnels
  function funnelView(steps, { labelKey = "label", countKey = "count", note, expand } = {}) {
    const base = steps.length ? steps[0][countKey] : 0;
    let worst = -1, worstDrop = 0;
    steps.forEach((s, i) => {
      if (i === 0) return;
      const prev = steps[i - 1][countKey];
      const drop = prev - s[countKey];
      if (prev > 0 && drop > worstDrop) { worstDrop = drop; worst = i; }
    });
    const rows = [el("div", { class: "f-row head" }, el("span", {}, "#"), el("span", {}, "Étape"), el("span", { class: "f-bar-h" }, ""), el("span", { class: "num" }, "Utilis."), el("span", { class: "num" }, "% début"), el("span", { class: "num f-step" }, "vs étape préc.")),
    ];
    steps.forEach((s, i) => {
      const count = s[countKey];
      const prev = i > 0 ? steps[i - 1][countKey] : null;
      const stepChange = prev ? (count - prev) / prev : null;
      const detail = expand ? el("div", { class: "f-detail", hidden: true }) : null;
      const chevron = expand ? el("span", { class: "f-chev", "aria-hidden": "true" }, "▸") : null;
      const row = el("div", { class: `f-row ${i === worst ? "worst" : ""} ${expand ? "clickable" : ""}`, title: s.title || "",
          ...(expand ? { role: "button", tabindex: "0", "aria-expanded": "false" } : {}) },
        el("span", { class: "f-idx" }, i + 1),
        el("span", { class: "f-name" }, chevron, s[labelKey], i === worst ? el("span", { class: "tag serious", style: "margin-left:6px" }, "▼ plus gros abandon") : null),
        el("div", { class: "f-bar" }, el("div", { style: `width:${base ? Math.min(100, (count / base) * 100) : 0}%` })),
        el("span", { class: "num" }, fmtNum(count)),
        el("span", { class: "num" }, base ? fmtPct(count / base, 0) : "—"),
        el("span", { class: `num f-step ${stepChange == null ? "muted" : stepChange < 0 ? "neg" : "pos"}` },
          stepChange == null ? "—" : `${stepChange > 0 ? "+" : ""}${fmtPct(stepChange, 0)}`));
      rows.push(row);
      if (expand) {
        let loaded = false;
        const toggle = () => {
          const open = detail.hidden;
          detail.hidden = !open;
          row.setAttribute("aria-expanded", String(open));
          chevron.textContent = open ? "▾" : "▸";
          if (open && !loaded) { loaded = true; expand(s, detail, i); }
        };
        row.addEventListener("click", toggle);
        row.addEventListener("keydown", (e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); toggle(); } });
        rows.push(detail);
      }
    });
    return el("div", { class: "funnel" }, rows, note ? el("div", { class: "card-sub", style: "margin-top:6px" }, note) : null);
  }

  /** Ordered funnel through /api/funnel; each step is a list of candidate events (first available wins). */
  async function amplitudeFunnel(body, stepDefs, range, n = "active") {
    const chosen = stepDefs.map((d) => ({ ...d, event: d.spec ? (has(d.spec.event_type) ? d.spec : null) : firstAvailable(d.events) }));
    const ready = chosen.filter((d) => d.event);
    const waiting = chosen.filter((d) => !d.event).map((d) => d.label + " (" + (d.events || [d.spec.event_type]).join(" / ") + ")");
    if (ready.length < 2) {
      body.replaceChildren(emptyBox("Entonnoir pas encore calculable", null, "Il faut au moins deux étapes avec des données."), pendingList(waiting) || "");
      return;
    }
    const r = await api("/api/funnel", { steps: ready.map((d) => (typeof d.event === "string" ? { event_type: d.event, label: d.label } : { ...d.event, label: d.label })), n, ...rp(range) });
    const steps = r.steps.map((s, i) => ({ ...s, title: typeof ready[i].event === "string" ? ready[i].event : ready[i].event.event_type, label: `${s.label}`, sub: ready[i].event }));
    const conv = steps.length && steps[0].count ? steps[steps.length - 1].count / steps[0].count : null;
    body.replaceChildren(
      el("div", { class: "kpi-row" }, el("span", { class: "tag good" }, `Conversion globale ${fmtPct(conv)}`),
        steps.length > 1 && steps[steps.length - 1].medianMs > 0 ? el("span", { class: "tag" }, `Délai médian dernière étape ${fmtDur(steps[steps.length - 1].medianMs)}`) : null),
      funnelView(steps.map((s, i) => ({ ...s, label: `${s.label}`, title: `${s.title}${i > 0 && s.medianMs != null ? ` · délai médian ${fmtDur(s.medianMs)}` : ""}` }))),
      pendingList(waiting, "Étapes ignorées (pas encore de données) :") || "");
  }

  // ------------------------------------------------------------------ breakdowns
  /** Merge several events grouped by one property into rows {value, [event]: total}. */
  async function mergedBreakdown(events, prop, range, { ptype = "event", m = "totals", limit = 30 } = {}) {
    const avail = available(events);
    const results = await Promise.all(avail.map((e) => api("/api/breakdown", { event: e, prop, ptype, m, limit, i: 30, ...rp(range) }).then((r) => [e, r])));
    const rows = new Map();
    let anyData = false;
    for (const [event, r] of results) {
      if (r.missing) continue;
      for (const row of r.rows) {
        anyData = anyData || row.total > 0;
        const key = row.value;
        if (!rows.has(key)) rows.set(key, { value: key });
        rows.get(key)[event] = (rows.get(key)[event] || 0) + row.total;
      }
    }
    return { rows: [...rows.values()], events: avail, missing: events.filter((e) => !has(e)), anyData };
  }

  // =================================================================== PAGES

  // ------------------------------------------------------------------ overview
  function renderOverview(root, range) {
    const prev = prevRange(range);
    const wauRange = { start: addDays(range.end, -6), end: range.end, days: 7 };
    const mauRange = { start: addDays(range.end, -29), end: range.end, days: 30 };

    const simpleKpi = (label, candidates, m = "totals", color, mode = "sum", note) => kpi(label, async () => {
      const [cur, before] = await metricWithPrev(candidates, m, range, mode);
      if (cur.missing) return { missing: true, missingEvents: candidates };
      return { value: cur.total, prev: before.total, spark: cur.series, note: note || cur.events.join(" + ") };
    }, color);

    const purchaseEvents = ["transaction_complete", "subscription_started", "subscription_purchased", "rc_initial_purchase_event", "non_recurring_purchase"];
    const trialEvents = ["trial_started", "rc_trial_started_event"];
    const miloEvents = () => has("milo_message_sent") ? ["milo_message_sent"] : discovered("milo_");

    root.append(
      el("div", { class: "section-title" }, "Acquisition & activité"),
      el("div", { class: "grid kpis" },
        kpi("Nouveaux utilisateurs", async () => {
          const [a, b] = await metricWithPrev(["_new"], "uniques", range);
          return { value: a.total, prev: b.total, spark: a.series, note: "Premier événement Amplitude" };
        }, SERIES[0]),
        simpleKpi("Installations", ["[Amplitude] Application Installed"], "totals", SERIES[2]),
        kpi("Utilisateurs actifs", async () => {
          const [a, b] = await metricWithPrev(["_active"], "uniques", range);
          return { value: a.total, prev: b.total, spark: a.series, note: "Uniques sur la période" };
        }, SERIES[0]),
        kpi("DAU moyen", async () => {
          const [a, b] = await Promise.all([api("/api/users", { m: "active", ...rp(range) }), api("/api/users", { m: "active", ...rp(prev) })]);
          const avg = (s) => (s.series.length ? sum(s.series) / s.series.length : 0);
          return { value: avg(a), prev: avg(b), spark: a.series, note: "Moyenne des actifs quotidiens" };
        }, SERIES[6]),
        kpi("WAU · MAU", async () => {
          const [w, m, d] = await Promise.all([
            metricSeries(["_active"], "uniques", wauRange), metricSeries(["_active"], "uniques", mauRange), api("/api/users", { m: "active", ...rp(mauRange) })]);
          const dau = d.series.length ? sum(d.series) / d.series.length : 0;
          return { value: w.total, fmt: (v) => `${fmtNum(v)} · ${fmtNum(m.total)}`, spark: m.series, note: `Fin au ${shortDay(isoDate(range.end))} · stickiness DAU/MAU ${fmtPct(m.total ? dau / m.total : null)}` };
        }, SERIES[6]),
        kpi("Onboarding complété", async () => {
          const [a, b] = await Promise.all([api("/api/onboarding", rp(range)), api("/api/onboarding", rp(prev))]);
          if (a.missing) return { missing: true, missingEvents: ["onboarding_screen_viewed"] };
          const rate = (o) => (o.steps && o.steps.length > 1 && o.steps[0].users ? o.steps[o.steps.length - 1].users / o.steps[0].users : null);
          if (!a.steps.length) return { missing: true, missingNote: "Aucun écran d'onboarding vu sur la période" };
          const last = a.steps[a.steps.length - 1];
          return { value: rate(a), prev: rate(b) ?? undefined, fmt: (v) => fmtPct(v, 0), note: `${a.steps[0].screen} → ${last.screen} (${a.flowLabel})` };
        }, SERIES[2]),
      ),
      el("div", { class: "section-title" }, "Monétisation"),
      el("div", { class: "grid kpis" },
        simpleKpi("Paywalls affichés", ["paywall_open", "onboarding_paywall_viewed"], "totals", SERIES[3], "first"),
        simpleKpi("Essais démarrés", trialEvents, "totals", SERIES[4]),
        simpleKpi("Achats", purchaseEvents, "totals", SERIES[2], "first"),
        kpi("MRR", async () => {
          const rc = await api("/api/revenuecat");
          if (!rc.configured) return { missing: true, missingNote: "Connecte RevenueCat (.env.local)" };
          const mrr = (rc.metrics || []).find((m) => m.id === "mrr");
          let spark = [], prevValue;
          try {
            const chart = await api("/api/revenuecat/chart", { chart: "mrr", ...rp(range) });
            spark = (chart.series[0] || []).filter((v) => v != null);
            if (spark.length > 1) prevValue = spark[0];
          } catch (_) { /* chart optional */ }
          return { value: mrr ? mrr.value : null, prev: prevValue, spark, fmt: (v) => fmtMoney(v, rc.currency), note: "RevenueCat · variation depuis le début de période" };
        }, SERIES[2]),
        kpi("Revenu (28 j)", async () => {
          const rc = await api("/api/revenuecat");
          if (rc.configured) {
            const revenue = (rc.metrics || []).find((m) => m.id === "revenue");
            return { value: revenue ? revenue.value : null, fmt: (v) => fmtMoney(v, rc.currency), note: "RevenueCat · 28 derniers jours" };
          }
          const ev = firstAvailable(["revenue_amount", "[Amplitude] Revenue"]);
          if (!ev) return { missing: true, missingNote: "Ni RevenueCat ni événement de revenu Amplitude" };
          const s = await api("/api/sums", { event: ev, prop: "$revenue", ...rp(range) });
          return { value: s.total, spark: s.series, fmt: (v) => fmtMoney(v), note: `Amplitude ${ev} · période` };
        }, SERIES[2]),
        kpi("Usage Milo", async () => {
          const evs = miloEvents();
          if (!evs.length) return { missing: true, missingEvents: ["milo_message_sent"] };
          const [a, b] = await metricWithPrev(evs, "totals", range);
          const users = await metricSeries(evs.slice(0, 1), "uniques", range);
          return { value: a.total, prev: b.total, spark: a.series, note: `${fmtNum(users.total)} utilisateurs · ${evs.length === 1 ? evs[0] : evs.length + " événements milo_*"}` };
        }, SERIES[6]),
      ),
      el("div", { class: "grid two" },
        card({ title: "Utilisateurs actifs & nouveaux", sub: "Par jour, uniques (Amplitude)", load: async (body) => {
          const [a, n] = await Promise.all([api("/api/users", { m: "active", ...rp(range) }), api("/api/users", { m: "new", ...rp(range) })]);
          const c = el("div", { class: "chart" }); body.replaceChildren(c);
          lineChart(c, a.xValues, [{ label: "Actifs", data: a.series }, { label: "Nouveaux", data: n.series }], { fill: true });
        } }),
        card({ title: "Activité clé", sub: "Événements par jour", load: async (body) => {
          const defs = [
            ["Sessions", ["session_start"]], ["Audio", ["audio_session_started"]], ["Plan complété", ["plan_item_completed"]],
            ["Paywall", ["paywall_open", "onboarding_paywall_viewed"]], ["Milo", miloEvents()],
          ];
          const data = await Promise.all(defs.map(([, evs]) => metricSeries(evs, "totals", range, "sum")));
          const sets = defs.map(([label], i) => ({ label, data: data[i].series, missing: data[i].missing, color: SERIES[i] })).filter((d) => !d.missing);
          if (!sets.length) { body.replaceChildren(emptyBox()); return; }
          const x = data.find((d) => !d.missing).x;
          const c = el("div", { class: "chart" }); body.replaceChildren(c);
          lineChart(c, x, sets);
          const waiting = defs.filter((_, i) => data[i].missing).map(([l, evs]) => `${l} (${evs.join(" / ") || "milo_*"})`);
          if (waiting.length) body.append(pendingList(waiting));
        } }),
      ),
      el("div", { class: "grid two" },
        card({ title: "Top événements", sub: "Volume de la semaine en cours (Amplitude events/list)", load: async (body, node) => {
          const draw = (rows, note) => {
            if (!rows.length) { body.replaceChildren(emptyBox("Aucun événement")); return; }
            const max = rows[0][1];
            const button = el("button", { class: "btn" }, "Calculer pour la période choisie");
            button.addEventListener("click", async () => {
              button.disabled = true; button.textContent = "Calcul… (1 requête Amplitude par paire d'événements)";
              try {
                const names = S.catalog.filter((e) => !e.hidden && (e.weekTotal || 0) >= 0).slice(0, 30).map((e) => e.name);
                const r = await api("/api/series", { events: names, m: "totals", i: 30, ...rp(range) });
                draw(Object.entries(r.totals).filter(([, v]) => v > 0).sort((a, b) => b[1] - a[1]).slice(0, 15), `Période choisie · 30 événements les plus actifs cette semaine`);
              } catch (error) { body.append(errorBox(error.message)); button.disabled = false; }
            });
            body.replaceChildren(
              el("div", { class: "kpi-row" }, el("span", { class: "card-sub" }, note), note.startsWith("Semaine") ? button : null),
              table([{ label: "Événement" }, { label: "Total", num: true }], rows.map(([n, v]) => [el("a", { href: `#explorer/${encodeURIComponent(n)}` }, n), barCell(v, max)]), { maxHeight: 360 }));
          };
          draw(S.catalog.filter((e) => (e.weekTotal || 0) > 0).slice(0, 15).map((e) => [e.name, e.weekTotal]), "Semaine en cours");
        }, skeletonKind: "lines" }),
        card({ title: "Pays & versions", sub: "Utilisateurs actifs uniques par propriété utilisateur", tools: null, load: async (body) => {
          const [country, version] = await Promise.all([
            api("/api/breakdown", { event: "_active", prop: "country", ptype: "user", m: "uniques", i: 30, limit: 8, ...rp(range) }),
            api("/api/breakdown", { event: "_active", prop: "version", ptype: "user", m: "uniques", i: 30, limit: 8, ...rp(range) }),
          ]);
          const grid = el("div", { class: "grid two" });
          for (const [title, r] of [["Pays", country], ["Version de l'app", version]]) {
            const box = el("div", {}, el("div", { class: "card-sub", style: "margin-bottom:6px" }, title));
            if (r.missing || !r.rows.length) box.append(emptyBox(r.reason || "Pas encore de données"));
            else { const max = r.rows[0].total; box.append(table([{ label: title }, { label: "Utilis.", num: true }], r.rows.map((row) => [row.value, barCell(row.total, max)]))); }
            grid.append(box);
          }
          body.replaceChildren(grid);
        }, skeletonKind: "lines" }),
      ),
    );
  }

  // ------------------------------------------------------------------ onboarding
  /** Detail under a funnel row: each quiz question with its answers, and the screen's own events. */
  async function onboardingStepDetail(screen, box, range) {
    box.replaceChildren(skeleton("lines"));
    try {
      const r = await api("/api/onboarding/step", { ...rp(range), screen });
      const parts = [];
      if (r.quiz && r.quiz.length) {
        parts.push(el("div", { class: "card-sub" }, `${r.quiz.length} questions · utilisateurs uniques`
          + (r.answersTracked === false ? " · réponses pas encore envoyées par cette version de l'app (arrivent avec la prochaine build)" : "")));
        r.quiz.forEach((q, i) => {
          const prev = i > 0 ? r.quiz[i - 1].answered : null;
          const lost = prev ? (prev - q.viewed) / prev : null;
          const maxA = Math.max(1, ...q.answers.map((a) => a.users));
          const totalA = q.answers.reduce((t, a) => t + a.users, 0);
          const answers = q.answers.length
            ? el("div", { class: "q-answers" }, ...q.answers.map((a) => el("div", { class: "q-answer" },
                el("span", { class: "q-answer-text", title: a.text }, a.text),
                el("div", { class: "f-bar" }, el("div", { style: `width:${(a.users / maxA) * 100}%` })),
                el("span", { class: "num" }, fmtNum(a.users)),
                el("span", { class: "num muted" }, totalA ? fmtPct(a.users / totalA, 0) : "—"))))
            : null;
          const details = el("details", { class: "q-item" },
            el("summary", {},
              el("span", { class: "q-num" }, `Q${q.number}`),
              el("span", { class: "q-text" }, q.text || `Question ${q.number}`),
              el("span", { class: "tag" }, `${fmtNum(q.viewed)} vus`),
              el("span", { class: "tag" }, `${fmtNum(q.answered)} répondus${q.viewed ? ` · ${fmtPct(q.answered / q.viewed, 0)}` : ""}`),
              q.avgSeconds != null ? el("span", { class: "tag" }, `${String(q.avgSeconds).replace(".", ",")} s en moyenne`) : null,
              lost != null && lost > 0 ? el("span", { class: "tag serious" }, `−${fmtPct(lost, 0)} vs Q${r.quiz[i - 1].number}`) : null),
            answers || el("div", { class: "card-sub" }, "Pas encore de réponses détaillées pour cette question."));
          parts.push(details);
        });
      }
      if (r.events.length) {
        parts.push(el("div", { class: "card-sub", style: "margin-top:8px" }, "Événements envoyés par cet écran (clic → explorateur)"));
        parts.push(table([{ label: "Événement" }, { label: "Utilisateurs", num: true }, { label: "Total", num: true }], r.events.map((e) => [
          el("a", { href: `#explorer/${encodeURIComponent(e.name)}` }, e.name), fmtNum(e.users), fmtNum(e.totals)])));
      }
      if (!parts.length) parts.push(el("div", { class: "card-sub" }, "Pas d'autre événement pour cet écran sur la période (seulement onboarding_screen_viewed)."));
      box.replaceChildren(...parts);
    } catch (error) {
      box.replaceChildren(errorBox(error.message || String(error), () => onboardingStepDetail(screen, box, range)));
    }
  }

  function renderOnboarding(root, range) {
    const flowSelect = el("select", { "aria-label": "Version du flow" });
    const funnelCard = card({
      title: "Entonnoir d'onboarding", sub: "Écrans découverts via onboarding_screen_viewed, ordonnés par step_number · utilisateurs uniques ayant vu chaque écran",
      tools: flowSelect, cls: "",
      load: async (body) => {
        const r = await api("/api/onboarding", { ...rp(range), flow: S.onboardingFlow || undefined });
        if (r.missing) { body.replaceChildren(emptyBox("Pas encore d'onboarding tracé", ["onboarding_screen_viewed"])); return; }
        if (!r.steps.length) { body.replaceChildren(emptyBox("Aucun écran vu sur cette période")); return; }
        flowSelect.replaceChildren(
          ...r.flows.map((f) => el("option", { value: f.id, selected: f.id === r.flow ? true : null }, `${f.label} · ${fmtNum(f.users)} utilis.`)),
          el("option", { value: "all", selected: r.flow === "all" ? true : null }, "Tous les flows confondus"));
        const steps = r.steps.map((s) => ({ label: s.screen, screen: s.screen, count: s.users, title: `step_number ${s.stepNumbers.join(", ")} · clique pour le détail` }));
        const first = steps[0].count, last = steps[steps.length - 1].count;
        body.replaceChildren(
          el("div", { class: "kpi-row" },
            el("span", { class: "tag good" }, `Complétion ${fmtPct(first ? last / first : null)}`),
            el("span", { class: "tag" }, `${steps.length} écrans`),
            el("span", { class: "tag" }, `${fmtNum(first)} → ${fmtNum(last)} utilisateurs`)),
          ...(r.currentScreens && r.currentScreens.length ? [el("p", { class: "muted" },
            `Onboarding actuel (code de l'app) : ${r.currentScreens.length} écrans.`
            + (r.currentMissing.length ? ` Sans données dans ce flow : ${r.currentMissing.join(", ")}.` : "")
            + (r.notInCurrent.length ? ` Écrans retirés depuis : ${r.notInCurrent.join(", ")}.` : ""))] : []),
          funnelView(steps, { expand: (step, box) => onboardingStepDetail(step.screen, box, range), note: "Clique sur un écran pour voir son détail (questions et réponses des quiz, événements envoyés). Les écrans optionnels (ex. variantes A/B) peuvent avoir moins d'utilisateurs que l'étape suivante. Par défaut : la dernière version de l'onboarding (onboarding_version). Les anciens flows, sans version, restent dans le menu." }));
      },
      skeletonKind: "lines",
    });
    flowSelect.addEventListener("change", () => { S.onboardingFlow = flowSelect.value; funnelCard._run(); dailyCard._run(); });

    const dailyCard = card({ title: "Débuts vs fins d'onboarding", sub: "Utilisateurs uniques par jour sur le premier et le dernier écran du flow", load: async (body) => {
      const r = await api("/api/onboarding", { ...rp(range), flow: S.onboardingFlow || undefined });
      if (r.missing || r.steps.length < 2) { body.replaceChildren(emptyBox(null, ["onboarding_screen_viewed"])); return; }
      const ev = r.event;
      const spec = (screen) => {
        const filters = [{ subprop_type: "event", subprop_key: "screen_name", subprop_op: "is", subprop_value: [screen] }];
        filters.push(...(r.filters || []));
        return { event_type: ev, filters };
      };
      const firstS = r.steps[0].screen, lastS = r.steps[r.steps.length - 1].screen;
      const s = await api("/api/series", { events: [{ ...spec(firstS), label: firstS }, { ...spec(lastS), label: `${lastS} ` }], m: "uniques", ...rp(range) });
      const c = el("div", { class: "chart" }); body.replaceChildren(c);
      lineChart(c, s.xValues, [{ label: `Début (${firstS})`, data: s.series[firstS] || [] }, { label: `Fin (${lastS})`, data: s.series[`${lastS} `] || [] }]);
    } });

    root.append(
      funnelCard,
      el("div", { class: "grid two" },
        card({ title: "Acquisition → paywall", sub: "Entonnoir ordonné Amplitude (utilisateurs actifs)", load: async (body) => {
          const ob = await api("/api/onboarding", { ...rp(range), flow: S.onboardingFlow || undefined });
          const screenStep = (s, label) => ({ label, spec: { event_type: ob.event, filters: [{ subprop_type: "event", subprop_key: "screen_name", subprop_op: "is", subprop_value: [s] }, ...(ob.filters || [])] } });
          const defs = [{ label: "Installation", events: ["[Amplitude] Application Installed"] }];
          if (!ob.missing && ob.steps.length > 1) defs.push(screenStep(ob.steps[0].screen, `Onboarding : ${ob.steps[0].screen}`), screenStep(ob.steps[ob.steps.length - 1].screen, `Onboarding : ${ob.steps[ob.steps.length - 1].screen}`));
          defs.push({ label: "Paywall vu", events: ["paywall_open", "onboarding_paywall_viewed"] });
          await amplitudeFunnel(body, defs, range);
        }, skeletonKind: "lines" }),
        card({ title: "Paywall → essai → payant", sub: "Entonnoir ordonné Amplitude", load: async (body) => {
          await amplitudeFunnel(body, [
            { label: "Paywall vu", events: ["paywall_open", "onboarding_paywall_viewed"] },
            { label: "Transaction démarrée", events: ["transaction_start"] },
            { label: "Essai démarré", events: ["trial_started", "rc_trial_started_event"] },
            { label: "Essai converti", events: ["trial_converted", "rc_trial_converted_event"] },
            { label: "Achat / abonnement", events: ["transaction_complete", "subscription_started", "subscription_purchased", "rc_initial_purchase_event"] },
          ], range);
        }, skeletonKind: "lines" }),
      ),
      dailyCard,
    );
  }

  // ------------------------------------------------------------------ monetization
  function renderMonetization(root, range) {
    const prev = prevRange(range);
    const txEvents = [["Démarrées", "transaction_start"], ["Complétées", "transaction_complete"], ["Échouées", "transaction_fail"], ["Abandonnées", "transaction_abandon"], ["Timeout", "transaction_timeout"], ["Restaurées", "transaction_restore"]];
    const dimSelect = el("select", { "aria-label": "Dimension" },
      ["placement", "paywall_identifier", "paywall_name", "variant_id", "experiment_id"].map((d) => el("option", { value: d, selected: d === S.paywallDim ? true : null }, d)));

    const rcCard = card({ title: "RevenueCat — vue d'ensemble", sub: "Source de vérité pour les revenus (API v2 metrics/overview)", load: async (body) => {
      const rc = await api("/api/revenuecat");
      if (!rc.configured) {
        body.replaceChildren(el("div", { class: "hint", html: `<strong>Connecte RevenueCat</strong> pour afficher MRR, abonnements actifs, essais et revenus.<br>Ajoute dans <code>analytics-dashboard/.env.local</code> :<br><code>REVENUECAT_SECRET_API_KEY=sk_…</code> (clé secrète v2, lecture charts/metrics) et <code>REVENUECAT_PROJECT_ID=proj…</code>, puis clique Actualiser.` }));
        return;
      }
      body.replaceChildren(el("div", { class: "rc-grid" }, rc.metrics.map((m) => el("div", { class: "rc-metric" },
        el("div", { class: "l" }, m.name),
        el("div", { class: "v" }, m.unit === "$" ? fmtMoney(m.value, rc.currency) : fmtNum(m.value)),
        el("div", { class: "d" }, m.description || m.period)))));
    }, skeletonKind: "lines" });

    const rcChart = (chartName, title, sub, opts = {}) => card({ title, sub, load: async (body) => {
      const r = await api("/api/revenuecat/chart", { chart: chartName, ...rp(range) });
      if (!r.configured) { body.replaceChildren(emptyBox("RevenueCat non connecté", null, "Ajoute la clé dans .env.local")); return; }
      const idx = r.measures.map((m, i) => ({ ...m, i })).filter((m) => (opts.measures ? opts.measures.includes(m.name) : m.chartable));
      if (!r.xValues.length || !idx.length) { body.replaceChildren(emptyBox()); return; }
      const unit = idx[0].unit;
      const valueFmt = unit === "$" ? (v) => fmtMoney(v, r.currency) : unit === "%" ? (v) => `${nf1.format(v)} %` : fmtNum;
      const c = el("div", { class: "chart short" }); body.replaceChildren(c);
      lineChart(c, r.xValues, idx.map((m, k) => ({ label: m.name, data: r.series[m.i], color: SERIES[(opts.colorStart || 0) + k] })), { valueFmt, bar: opts.bar, fill: !opts.bar });
      const summary = r.summary && (r.summary.total || r.summary.average);
      const fmtMeasure = (name, v) => {
        const m = r.measures.find((x) => x.name === name);
        return m && m.unit === "$" ? fmtMoney(v, r.currency) : m && m.unit === "%" ? `${nf1.format(v)} %` : fmtNum(v);
      };
      if (summary) body.append(el("div", { class: "card-sub" }, Object.entries(summary).map(([k, v]) => `${k} : ${fmtMeasure(k, v)}`).join(" · ") + (r.summary.total ? " (total)" : " (moyenne)")));
    } });

    const paywallCard = card({ title: "Paywalls par dimension", sub: "Ouvertures, fermetures et refus (Superwall)", tools: dimSelect, load: async (body) => {
      const evs = ["paywall_open", "paywall_close", "paywall_decline", "paywall_load_failed"];
      const r = await mergedBreakdown(evs, S.paywallDim, range);
      if (!r.events.length) { body.replaceChildren(emptyBox("Pas encore d'événements paywall Superwall", ["paywall_open"])); return; }
      if (!r.anyData) { body.replaceChildren(emptyBox("Aucun paywall sur la période"), pendingList(r.missing) || ""); return; }
      r.rows.sort((a, b) => (b.paywall_open || 0) - (a.paywall_open || 0));
      const labels = r.rows.map((x) => x.value);
      const c = el("div", { class: "chart" });
      body.replaceChildren(c, table([{ label: S.paywallDim }, ...r.events.map((e) => ({ label: e.replace("paywall_", ""), num: true })), { label: "Taux de refus", num: true }],
        r.rows.map((row) => [row.value, ...r.events.map((e) => fmtNum(row[e] || 0)), row.paywall_open ? fmtPct((row.paywall_decline || 0) / row.paywall_open) : "—"])), pendingList(r.missing) || "");
      hbarChart(c, labels, r.events.map((e, i) => ({ label: e, data: r.rows.map((row) => row[e] || 0), color: SERIES[i] })));
    } });
    dimSelect.addEventListener("change", () => { S.paywallDim = dimSelect.value; paywallCard._run(); });

    root.append(
      rcCard,
      el("div", { class: "grid three" },
        rcChart("revenue", "Revenu", "RevenueCat, par jour", { bar: true, colorStart: 2 }),
        rcChart("mrr", "MRR", "RevenueCat, fin de journée", { colorStart: 0 }),
        rcChart("actives", "Abonnements actifs", "RevenueCat", { colorStart: 6 }),
        rcChart("trials", "Essais actifs", "RevenueCat", { colorStart: 4 }),
        rcChart("trial_conversion_rate", "Conversion des essais", "RevenueCat · essais démarrés et convertis", { measures: ["Trial Starts", "Conversions"], bar: true, colorStart: 3 }),
        rcChart("churn", "Churn", "RevenueCat · taux de churn", { colorStart: 7 }),
      ),
      el("div", { class: "section-title" }, "Événements de l'app (Amplitude)"),
      el("div", { class: "grid kpis" },
        ...[["Paywalls ouverts", ["paywall_open", "onboarding_paywall_viewed"], "first"], ["Essais démarrés", ["trial_started", "rc_trial_started_event"], "sum"],
          ["Abonnements démarrés", ["subscription_started", "subscription_purchased", "rc_initial_purchase_event"], "first"], ["Achats uniques", ["non_recurring_purchase"], "first"],
          ["Essais convertis", ["trial_converted", "rc_trial_converted_event"], "sum"], ["Abonnements expirés", ["subscription_expired", "rc_expiration_event"], "sum"]]
          .map(([label, evs, mode], i) => kpi(label, async () => {
            const [a, b] = await metricWithPrev(evs, "totals", range, mode);
            if (a.missing) return { missing: true, missingEvents: evs };
            return { value: a.total, prev: b.total, spark: a.series, note: a.events.join(" + "), invert: label.includes("expirés") };
          }, SERIES[i])),
      ),
      el("div", { class: "grid two" },
        card({ title: "Transactions", sub: "Cycle d'achat Superwall par jour", load: async (body) => {
          const avail = txEvents.filter(([, e]) => has(e));
          if (!avail.length) { body.replaceChildren(emptyBox("Pas encore de transactions", ["transaction_start"])); return; }
          const s = await api("/api/series", { events: avail.map(([, e]) => e), m: "totals", ...rp(range) });
          const c = el("div", { class: "chart" });
          const start = s.totals.transaction_start || 0;
          body.replaceChildren(
            el("div", { class: "kpi-row", style: "flex-wrap:wrap" }, avail.map(([label, e]) => el("span", { class: "tag" }, `${label} ${fmtNum(s.totals[e] || 0)}${start && e !== "transaction_start" ? ` · ${fmtPct((s.totals[e] || 0) / start, 0)}` : ""}`))),
            c, pendingList(txEvents.filter(([, e]) => !has(e)).map(([, e]) => e)) || "");
          lineChart(c, s.xValues, avail.map(([label, e], i) => ({ label, data: s.series[e] || [], color: SERIES[i] })));
        } }),
        card({ title: "Mix produits", sub: "Achats par product_id", load: async (body) => {
          const sources = [["transaction_complete", "product_id"], ["subscription_started", "product_id"], ["trial_started", "product_id"], ["subscription_purchased", "product_id"], ["revenue_amount", "$productId"], ["[Amplitude] Revenue", "$productId"]].filter(([e]) => has(e));
          if (!sources.length) { body.replaceChildren(emptyBox("Pas encore d'achats", ["transaction_complete", "revenue_amount"])); return; }
          const results = await Promise.all(sources.map(([e, p]) => api("/api/breakdown", { event: e, prop: p, i: 30, limit: 15, ...rp(range) })));
          const products = new Map();
          results.forEach((r, k) => (r.rows || []).forEach((row) => {
            if (!products.has(row.value)) products.set(row.value, {});
            products.get(row.value)[sources[k][0]] = row.total;
          }));
          const rows = [...products.entries()].filter(([, v]) => Object.values(v).some((x) => x > 0));
          if (!rows.length) { body.replaceChildren(emptyBox("Aucun achat sur la période")); return; }
          body.replaceChildren(table([{ label: "Produit" }, ...sources.map(([e]) => ({ label: e, num: true }))], rows.map(([p, v]) => [p, ...sources.map(([e]) => fmtNum(v[e] || 0))])));
        }, skeletonKind: "lines" }),
      ),
      el("div", { class: "grid two" },
        paywallCard,
        card({ title: "Revenu tracké dans Amplitude", sub: "Somme de $revenue par événement de revenu (client + RevenueCat→Amplitude)", load: async (body) => {
          const candidates = ["revenue_amount", "[Amplitude] Revenue", ...discovered("rc_")].filter(has);
          if (!candidates.length) { body.replaceChildren(emptyBox("Pas encore d'événement de revenu", ["revenue_amount", "rc_*"], "Les événements rc_* apparaîtront quand l'intégration RevenueCat → Amplitude sera activée.")); return; }
          const sums = await Promise.all(candidates.map((e) => api("/api/sums", { event: e, prop: "$revenue", ...rp(range) }).then((r) => [e, r])));
          const sets = sums.filter(([, r]) => !r.missing && r.total);
          const ltv = await api("/api/ltv", rp(range)).catch(() => null);
          const head = ltv ? el("div", { class: "kpi-row", style: "flex-wrap:wrap" },
            el("span", { class: "tag" }, `Payeurs (cohorte) ${fmtNum(ltv.totalRevenue.paid)} / ${fmtNum(ltv.totalRevenue.count)}`),
            el("span", { class: "tag" }, `Revenu J7 ${fmtMoney(ltv.totalRevenue.r7d)}`),
            el("span", { class: "tag" }, `Revenu J30 ${fmtMoney(ltv.totalRevenue.r30d)}`),
            el("span", { class: "tag" }, `ARPU J30 ${fmtMoney(ltv.arpu.r30d)}`)) : null;
          if (!sets.length) { body.replaceChildren(head || "", emptyBox("Aucun revenu sur la période", null, `Événements surveillés : ${candidates.join(", ")}`)); return; }
          const c = el("div", { class: "chart" });
          body.replaceChildren(head || "", c);
          lineChart(c, sets[0][1].xValues, sets.map(([e, r], i) => ({ label: e, data: r.series, color: SERIES[i] })), { bar: true, valueFmt: (v) => fmtMoney(v) });
        } }),
      ),
      el("div", { class: "grid two" },
        card({ title: "Cycle de vie des abonnements", sub: "Événements RevenueCat (app et intégration rc_*)", load: async (body) => {
          const evs = ["trial_started", "trial_converted", "trial_expired", "subscription_started", "subscription_purchased", "transaction_complete", "non_recurring_purchase", "subscription_auto_renew_off", "subscription_auto_renew_on", "subscription_expired", "transaction_restore", ...discovered("rc_")];
          const avail = available(evs);
          if (!avail.length) { body.replaceChildren(emptyBox("Pas encore d'événement d'abonnement", ["trial_started", "rc_*"])); return; }
          const [cur, before] = await Promise.all([api("/api/series", { events: avail, m: "totals", i: 30, ...rp(range) }), api("/api/series", { events: avail, m: "totals", i: 30, ...rp(prev) })]);
          body.replaceChildren(table([{ label: "Événement" }, { label: "Période", num: true }, { label: "Préc.", num: true }],
            avail.map((e) => [e, fmtNum(cur.totals[e] || 0), fmtNum(before.totals[e] || 0)])), pendingList(evs.filter((e) => !has(e))) || "");
        }, skeletonKind: "lines" }),
        card({ title: "Statut d'abonnement des utilisateurs actifs", sub: "Propriétés utilisateur subscription_period_type et is_premium", load: async (body) => {
          const props = ["subscription_period_type", "is_premium", "subscription_product", "subscription_will_renew"];
          const results = await Promise.all(props.map((p) => api("/api/breakdown", { event: "_active", prop: p, ptype: "user", m: "uniques", i: 30, limit: 10, ...rp(range) })));
          const grid = el("div", { class: "grid two" });
          results.forEach((r, k) => {
            const box = el("div", {}, el("div", { class: "card-sub", style: "margin-bottom:6px" }, props[k]));
            if (r.missing || !r.rows.length) box.append(emptyBox(r.reason || "Pas encore de données"));
            else { const max = r.rows[0].total; box.append(table([{ label: "Valeur" }, { label: "Utilis.", num: true }], r.rows.map((row) => [row.value, barCell(row.total, max)]))); }
            grid.append(box);
          });
          body.replaceChildren(grid);
        }, skeletonKind: "lines" }),
      ),
    );
  }

  // ------------------------------------------------------------------ engagement
  function renderEngagement(root, range) {
    const prev = prevRange(range);
    const tiles = [
      ["Sessions", ["session_start"]], ["Séances audio", ["audio_session_started"]], ["Items du plan complétés", ["plan_item_completed"]],
      ["Pauses respiration", ["breathe_pause_shown"]], ["Messages Milo", ["milo_message_sent"]], ["Réponses Milo", ["milo_reply_received"]],
      ["Erreurs Milo", ["milo_error"]], ["Face checks", ["face_check_completed"]], ["Face checks échoués", ["face_check_failed"]],
    ];
    root.append(
      el("div", { class: "grid kpis" }, tiles.map(([label, evs], i) => kpi(label, async () => {
        const [[a, b], u] = await Promise.all([metricWithPrev(evs, "totals", range), metricSeries(evs, "uniques", range)]);
        if (a.missing) return { missing: true, missingEvents: evs };
        return { value: a.total, prev: b.total, spark: a.series, note: `${fmtNum(u.total)} utilisateurs · ${u.total ? nf1.format(a.total / u.total) : "—"} / utilis.`, invert: /Erreurs|échoués/.test(label) };
      }, SERIES[i % SERIES.length]))),
      el("div", { class: "grid two" },
        card({ title: "Rétention", sub: "Nouveaux utilisateurs de la période revenus (tout événement actif) au jour N", load: async (body) => {
          const r = await api("/api/retention", rp(range));
          if (r.missing || !r.days.length) { body.replaceChildren(emptyBox()); return; }
          const pick = (n) => r.days.find((d) => d.day === n);
          const tag = (n) => { const d = pick(n); return el("span", { class: "tag" }, `J${n} ${d && d.outof ? fmtPct(d.pct) : "n/a"}${d && d.outof ? ` (${d.count}/${d.outof})` : ""}`); };
          const days = r.days.filter((d) => d.outof > 0).slice(0, 31);
          const c = el("div", { class: "chart" });
          body.replaceChildren(el("div", { class: "kpi-row", style: "flex-wrap:wrap" }, el("span", { class: "tag good" }, `Cohorte ${fmtNum(r.cohortSize)} nouveaux`), tag(1), tag(7), tag(30)), c);
          lineChart(c, days.map((d) => `J${d.day}`), [{ label: "Retenus", data: days.map((d) => (d.pct == null ? null : d.pct * 100)) }], { labelFmt: (x) => x, valueFmt: (v) => `${nf1.format(v)} %`, fill: true, yMax: 100 });
        } }),
        card({ title: "Cohortes", sub: "% de la cohorte du jour revenue au jour N (14 premiers jours)", load: async (body) => {
          const r = await api("/api/retention", rp(range));
          const cohorts = (r.cohorts || []).filter((c) => c.size > 0).slice(0, 21);
          if (!cohorts.length) { body.replaceChildren(emptyBox("Aucune cohorte sur la période")); return; }
          const maxDay = 14;
          const headers = [{ label: "Cohorte" }, { label: "Taille", num: true }, ...Array.from({ length: maxDay + 1 }, (_, i) => ({ label: `J${i}` }))];
          const rows = cohorts.map((c) => [c.date, fmtNum(c.size), ...Array.from({ length: maxDay + 1 }, (_, i) => {
            const v = c.days[i];
            if (v == null) return el("span", { class: "muted" }, "");
            const p = v / c.size;
            return el("span", { style: `display:block;padding:2px 4px;border-radius:4px;background:rgba(57,135,229,${(0.08 + p * 0.8).toFixed(2)})` }, `${Math.round(p * 100)}%`);
          })]);
          body.replaceChildren(table(headers, rows, { cls: "cohort" }));
        }, skeletonKind: "lines" }),
      ),
      el("div", { class: "grid two" },
        card({ title: "Usage quotidien", sub: "Événements d'engagement par jour", load: async (body) => {
          const avail = tiles.filter(([, evs]) => has(evs[0])).slice(0, 8);
          if (!avail.length) { body.replaceChildren(emptyBox()); return; }
          const s = await api("/api/series", { events: avail.map(([, evs]) => evs[0]), m: "totals", ...rp(range) });
          const c = el("div", { class: "chart tall" }); body.replaceChildren(c);
          lineChart(c, s.xValues, avail.map(([label, evs], i) => ({ label, data: s.series[evs[0]] || [], color: SERIES[i] })));
        } }),
        card({ title: "Sessions par utilisateur", sub: "session_start : total / utilisateurs uniques par jour", load: async (body) => {
          if (!has("session_start")) { body.replaceChildren(emptyBox(null, ["session_start"])); return; }
          const [t, u] = await Promise.all([api("/api/series", { events: ["session_start"], m: "totals", ...rp(range) }), api("/api/series", { events: ["session_start"], m: "uniques", ...rp(range) })]);
          const tt = t.series.session_start || [], uu = u.series.session_start || [];
          const c = el("div", { class: "chart tall" }); body.replaceChildren(c);
          lineChart(c, t.xValues, [{ label: "Sessions / utilisateur", data: tt.map((v, i) => (uu[i] ? +(v / uu[i]).toFixed(2) : null)) }], { valueFmt: (v) => nf1.format(v) });
        } }),
      ),
      el("div", { class: "section-title" }, "Milo & contenus"),
      el("div", { class: "grid three" },
        breakdownCard("Messages Milo par source", "milo_message_sent", "source", range),
        breakdownCard("Erreurs Milo par type", "milo_error", "kind", range),
        breakdownCard("Dictée Milo par langue", "milo_dictation_used", "language", range),
        breakdownCard("Séances audio par contenu", "audio_session_started", null, range),
        breakdownCard("Items du plan complétés par type", "plan_item_completed", "kind", range),
        breakdownCard("Notes de séance", "session_rated", "rating", range, { sortNumeric: true }),
      ),
    );
  }

  /** Bar breakdown of one event by a property; when prop is null the first known property is used. */
  function breakdownCard(title, event, prop, range, opts = {}) {
    return card({ title, sub: `${event}${prop ? ` · ${prop}` : ""}`, load: async (body, node) => {
      if (!has(event)) { body.replaceChildren(emptyBox(null, [event])); return; }
      let property = prop;
      if (!property) {
        const props = await api("/api/event-props", { event });
        const list = props.properties || [];
        const prefer = ["content_title", "title", "content_key", "category", "kind", "type", "name"];
        property = prefer.find((p) => list.includes(p)) || list.find((p) => !/(^|_)(id|timestamp)$/.test(p)) || list[0];
        if (!property) { body.replaceChildren(emptyBox("Aucune propriété sur cet événement")); return; }
        const sub = node.querySelector(".card-sub"); if (sub) sub.textContent = `${event} · ${property}`;
      }
      const r = await api("/api/breakdown", { event, prop: property, i: 30, limit: opts.limit || 12, ...rp(range) });
      if (r.missing) { body.replaceChildren(emptyBox(r.reason)); return; }
      const rows = r.rows.filter((x) => x.total > 0);
      if (!rows.length) { body.replaceChildren(emptyBox("Aucun événement sur la période")); return; }
      if (opts.sortNumeric) rows.sort((a, b) => Number(a.value) - Number(b.value));
      const c = el("div", { class: "chart" }); body.replaceChildren(c);
      hbarChart(c, rows.map((x) => x.value), [{ label: event, data: rows.map((x) => x.total), color: opts.color }]);
    } });
  }

  // ------------------------------------------------------------------ ICP
  // Who the users are (onboarding answers as « icp_* » user properties, plus country, language,
  // device) and how each segment converts: start → paywall → trial → purchase.
  const ICP_LABELS = {
    icp_age: "Âge", icp_gender: "Genre", icp_main_reason: "Raison principale", icp_stress_reasons: "Raisons (choix multiples)",
    icp_reason_count: "Nombre de raisons", icp_stress_duration: "Depuis combien de temps", icp_symptoms: "Symptômes cochés",
    icp_symptom_count: "Nombre de symptômes", icp_primary_goal: "Objectif choisi", icp_available_minutes: "Temps dispo / jour",
    icp_global_score: "Score global", icp_stress_score: "Score stress", icp_sleep_score: "Score sommeil",
    icp_energy_score: "Score énergie", icp_focus_score: "Score concentration",
    country: "Pays", app_language: "Langue de l'app", language: "Langue de l'iPhone", device_type: "Appareil", plan_goal: "Objectif du plan",
    has_apple_watch: "Apple Watch",
  };
  const ICP_VALUES = {
    under_18: "Moins de 18 ans", "18_24": "18–24 ans (début vingtaine)", "25_34": "25–34 ans (fin vingtaine / trentaine)",
    "35_44": "35–44 ans (quarantaine)", "45_54": "45–54 ans (cinquantaine)", "55_plus": "55 ans et +",
    male: "Homme", female: "Femme", other: "Autre / non précisé",
    sleep: "Sommeil", anxiety: "Stress / anxiété", energy: "Énergie", mental: "Santé mentale", difficult: "Période difficile", habits: "Habitudes", focus: "Concentration",
    weeks: "Quelques semaines", "2_6_months": "2 à 6 mois", "6_12_months": "6 mois à 1 an", "1_year_plus": "Plus d'un an", years: "Plusieurs années",
  };
  const icpLabel = (prop) => ICP_LABELS[prop] || (prop.startsWith("icp_habit_q") ? `Habitudes — question ${prop.slice(11)}` : prop);
  const icpValue = (v) => ICP_VALUES[v] || v;

  function icpSteps() {
    // Among equivalent events (old and new names), the one with the most data recently.
    const volume = (name) => (S.catalog.find((e) => e.name === name) || {}).weekTotal || 0;
    const pick = (list) => available(list).sort((a, b) => volume(b) - volume(a))[0] || null;
    return [
      { label: "Début", event: pick(["onboarding_profile_completed", "onboarding_welcome_viewed", "onboarding_screen_viewed"]) },
      { label: "Paywall vu", event: pick(["paywall_open", "onboarding_paywall_viewed"]) },
      { label: "Essai", event: pick(["trial_started", "rc_trial_started_event"]) },
      { label: "Achat", event: pick(["transaction_complete", "subscription_started", "subscription_purchased", "rc_initial_purchase_event"]) },
    ].filter((s) => s.event);
  }

  function renderICP(root, range) {
    const steps = icpSteps();
    const stepSpecs = steps.map((s) => ({ event_type: s.event, label: s.label }));
    const waitingBox = el("div");
    const summary = card({ title: "Ton ICP en un coup d'œil", sub: "Pour chaque critère : le profil le plus fréquent, et celui qui convertit le mieux (au moins 3 personnes)", load: async (body) => {
      body.replaceChildren(skeleton("lines"));
      const results = await Promise.all(dims.map((d) => api("/api/icp", { prop: d, steps: stepSpecs, ...rp(range) }).catch(() => null)));
      const rows = [];
      results.forEach((r, i) => {
        if (!r || r.missing) return;
        const known = r.segments.filter((sg) => sg.value !== "(none)");
        if (!known.length) return;
        const last = known[0].counts.length - 1;
        const top = known[0];
        const total = known.reduce((t, sg) => t + sg.counts[0], 0);
        const ranked = known.filter((sg) => sg.counts[0] >= 3).map((sg) => ({ ...sg, conv: sg.counts[last] / sg.counts[0] }))
          .sort((a, b) => b.conv - a.conv);
        const best = ranked.length && last > 0 ? ranked[0] : null;
        rows.push([icpLabel(dims[i]), `${icpValue(top.value)} · ${fmtPct(top.counts[0] / total, 0)}`,
          best ? `${icpValue(best.value)} · ${fmtPct(best.conv, 0)} → ${r.steps[last]}` : "—"]);
      });
      body.replaceChildren(rows.length ? table([{ label: "Critère" }, { label: "Le plus fréquent" }, { label: "Convertit le mieux" }], rows)
        : emptyBox("Pas encore de profil", ["onboarding_profile_completed"], "Les réponses d'âge, genre, raisons… arrivent avec la prochaine build de l'app."));
    }, skeletonKind: "lines" });

    let dims = [];
    const grid = el("div", { class: "grid two" });
    root.append(
      el("div", { class: "card-sub", style: "margin-bottom:8px" },
        `Conversion par segment, dans l'ordre : ${steps.map((s) => `${s.label} (${s.event})`).join(" → ")}. Utilisateurs actifs, fenêtre de 30 jours.`),
      waitingBox, summary, grid);

    (async () => {
      const props = (await api("/api/user-props")).properties || [];
      const icp = props.filter((p) => p.startsWith("icp_")).sort((a, b) => {
        const order = Object.keys(ICP_LABELS);
        const ia = order.indexOf(a), ib = order.indexOf(b);
        return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib) || a.localeCompare(b, undefined, { numeric: true });
      });
      const extra = ["country", "app_language", "device_type", "plan_goal", "has_apple_watch"].filter((p) => props.includes(p));
      const expected = ["icp_age", "icp_gender", "icp_main_reason", "icp_stress_reasons", "icp_stress_duration", "icp_symptoms"];
      // Age, gender, reasons… are always shown first, waiting for data until a new build sends them.
      dims = [...expected.filter((p) => !icp.includes(p)), ...icp, ...extra]
        .sort((a, b) => { const o = Object.keys(ICP_LABELS); const ia = o.indexOf(a), ib = o.indexOf(b); return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib); });
      const notYet = expected.filter((p) => !props.includes(p));
      if (notYet.length) waitingBox.replaceChildren(el("div", { class: "card-sub", style: "margin-bottom:10px" },
        `En attente (envoyé par la prochaine build) : ${notYet.map(icpLabel).join(", ")}. En attendant : pays, langue, appareil.`));
      summary._run();
      grid.replaceChildren(...dims.map((d) => icpCard(d, stepSpecs, range)));
    })().catch((error) => waitingBox.replaceChildren(errorBox(error.message || String(error))));
  }

  function icpCard(prop, stepSpecs, range) {
    return card({ title: icpLabel(prop), sub: prop, load: async (body) => {
      const r = await api("/api/icp", { prop, steps: stepSpecs, ...rp(range) });
      if (r.missing || !r.segments.length) {
        body.replaceChildren(emptyBox("Pas encore de données", null,
          "Envoyé à la fin du quiz d'onboarding par la nouvelle build de l'app : s'affiche quelques minutes après le premier onboarding fait avec cette build."));
        return;
      }
      // « (none) »: users who never sent this property (older app versions) — shown last.
      const segments = [...r.segments.filter((sg) => sg.value !== "(none)"), ...r.segments.filter((sg) => sg.value === "(none)")];
      const total = segments.reduce((t, sg) => t + sg.counts[0], 0);
      const max = Math.max(...segments.map((sg) => sg.counts[0]));
      const headers = [{ label: "Segment" }, { label: "Utilisateurs", num: true }, ...r.steps.slice(1).map((s) => ({ label: s, num: true }))];
      const rows = segments.slice(0, 15).map((sg) => [
        el("span", { title: sg.value, class: sg.value === "(none)" ? "muted" : "" }, sg.value === "(none)" ? "Non renseigné (anciennes versions)" : icpValue(sg.value)),
        barCell(sg.counts[0], max, `${fmtNum(sg.counts[0])} · ${fmtPct(sg.counts[0] / total, 0)}`),
        ...sg.counts.slice(1).map((c) => `${fmtPct(sg.counts[0] ? c / sg.counts[0] : null, 0)} (${fmtNum(c)})`),
      ]);
      body.replaceChildren(table(headers, rows, { maxHeight: 360 }));
    }, skeletonKind: "lines" });
  }

  // ------------------------------------------------------------------ notifications
  function renderNotifications(root, range) {
    const prev = prevRange(range);
    const SCHEDULED = ["notification_scheduled"];
    const DELIVERED = ["notification_delivered", "notification_received"];
    const OPENED = ["notification_opened", "notification_clicked"];
    const tile = (label, evs, i) => kpi(label, async () => {
      const [a, b] = await metricWithPrev(evs, "totals", range);
      if (a.missing) return { missing: true, missingEvents: evs };
      return { value: a.total, prev: b.total, spark: a.series, note: a.events.join(" + ") };
    }, SERIES[i]);

    root.append(
      el("div", { class: "grid kpis" },
        tile("Programmées", SCHEDULED, 0),
        tile("Délivrées", DELIVERED, 2),
        tile("Ouvertes", OPENED, 1),
        kpi("Taux d'ouverture", async () => {
          const [[d, pd], [o, po]] = await Promise.all([metricWithPrev(DELIVERED, "totals", range), metricWithPrev(OPENED, "totals", range)]);
          if (d.missing || o.missing) return { missing: true, missingEvents: [...(d.missing ? DELIVERED : []), ...(o.missing ? OPENED : [])] };
          return { value: d.total ? o.total / d.total : null, prev: pd.total ? po.total / pd.total : undefined, fmt: (v) => fmtPct(v),
            spark: d.series.map((v, i) => (v ? (o.series[i] || 0) / v : 0)), note: "ouvertes / délivrées" };
        }, SERIES[6]),
        tile("Changements de permission", ["notification_permission_changed"], 4),
      ),
      el("div", { class: "grid two" },
        card({ title: "Tendance quotidienne", sub: "Programmées, délivrées et ouvertes", load: async (body) => {
          const sets = await Promise.all([metricSeries(SCHEDULED, "totals", range), metricSeries(DELIVERED, "totals", range), metricSeries(OPENED, "totals", range)]);
          const labels = ["Programmées", "Délivrées", "Ouvertes"];
          const ok = sets.map((s, i) => ({ ...s, label: labels[i], color: SERIES[[0, 2, 1][i]] })).filter((s) => !s.missing);
          if (!ok.length) { body.replaceChildren(emptyBox(null, ["notification_scheduled", "notification_delivered", "notification_opened"])); return; }
          const c = el("div", { class: "chart" }); body.replaceChildren(c);
          lineChart(c, ok[0].x, ok.map((s) => ({ label: s.label, data: s.series, color: s.color })));
          const waiting = sets.map((s, i) => (s.missing ? [SCHEDULED, DELIVERED, OPENED][i][0] : null)).filter(Boolean);
          if (waiting.length) body.append(pendingList(waiting));
        } }),
        card({ title: "Statut de permission", sub: "Utilisateurs actifs par propriété notification_permission", load: async (body) => {
          const r = await api("/api/breakdown", { event: "_active", prop: "notification_permission", ptype: "user", m: "uniques", i: 30, limit: 10, ...rp(range) });
          if (r.missing || !r.rows.length) {
            body.replaceChildren(emptyBox(r.reason || "Pas encore de données"));
            const alt = firstAvailable(["notification_permission_changed", "onboarding_notifications_permission_result"]);
            if (alt) {
              const props = await api("/api/event-props", { event: alt });
              const p = (props.properties || []).find((x) => /^(to|result|status|granted)$/.test(x)) || (props.properties || [])[0];
              if (p) {
                const b = await api("/api/breakdown", { event: alt, prop: p, m: "uniques", i: 30, limit: 10, ...rp(range) });
                if (!b.missing && b.rows.length) {
                  const c = el("div", { class: "chart" });
                  body.append(el("div", { class: "card-sub", style: "margin-top:10px" }, `En attendant : ${alt} par ${p} (utilisateurs uniques)`), c);
                  hbarChart(c, b.rows.map((x) => x.value), [{ label: alt, data: b.rows.map((x) => x.total) }]);
                }
              }
            }
            return;
          }
          const total = sum(r.rows.map((x) => x.total));
          const max = r.rows[0].total;
          body.replaceChildren(table([{ label: "Permission" }, { label: "Utilis.", num: true }, { label: "Part", num: true }], r.rows.map((x) => [x.value, barCell(x.total, max), fmtPct(total ? x.total / total : null)])));
        }, skeletonKind: "lines" }),
      ),
      card({ title: "Par type de notification", sub: "notification_type · taux d'ouverture = ouvertes / délivrées (les anciens événements notification_received / notification_clicked sont inclus)", load: async (body) => {
        const groups = [["Programmées", SCHEDULED], ["Délivrées", DELIVERED], ["Ouvertes", OPENED]];
        const results = await Promise.all(groups.map(([, evs]) => mergedBreakdown(evs, "notification_type", range)));
        const types = new Map();
        results.forEach((r, k) => r.rows.forEach((row) => {
          if (!types.has(row.value)) types.set(row.value, [0, 0, 0]);
          types.get(row.value)[k] += r.events.reduce((a, e) => a + (row[e] || 0), 0);
        }));
        const rows = [...types.entries()].filter(([, v]) => v.some((x) => x > 0)).sort((a, b) => b[1][1] + b[1][0] - a[1][1] - a[1][0]);
        if (!rows.length) { body.replaceChildren(emptyBox("Pas encore de notification avec notification_type", ["notification_scheduled", "notification_delivered", "notification_opened"])); return; }
        const c = el("div", { class: "chart" });
        body.replaceChildren(c, table([{ label: "Type" }, { label: "Programmées", num: true }, { label: "Délivrées", num: true }, { label: "Ouvertes", num: true }, { label: "Taux d'ouverture", num: true }],
          rows.map(([t, v]) => [t, fmtNum(v[0]), fmtNum(v[1]), fmtNum(v[2]), v[1] ? fmtPct(v[2] / v[1]) : "—"])));
        hbarChart(c, rows.map(([t]) => t), groups.map(([label], k) => ({ label, data: rows.map(([, v]) => v[k]), color: SERIES[[0, 2, 1][k]] })));
      } }),
      el("div", { class: "grid three" },
        breakdownCard("Délivrées par état de l'app", "notification_delivered", "app_state", range),
        breakdownCard("Délivrées par heure", "notification_delivered", "delivered_hour", range, { sortNumeric: true, limit: 24 }),
        breakdownCard("Ouvertes par action", "notification_opened", "action", range),
        breakdownCard("Programmées par heure de déclenchement", "notification_scheduled", "fire_hour", range, { sortNumeric: true, limit: 24 }),
        breakdownCard("Changements de permission (vers)", "notification_permission_changed", "to", range),
        breakdownCard("Programmations (anciens événements)", firstAvailable(["daily_notifications_scheduled", "reengagement_notifications_scheduled"]) || "daily_notifications_scheduled", null, range),
      ),
    );
  }

  // ------------------------------------------------------------------ explorer
  function renderExplorer(root, range, arg) {
    if (arg) S.explorer.selected = decodeURIComponent(arg);
    const search = el("input", { type: "search", placeholder: `Rechercher parmi ${S.catalog.length} événements…`, value: S.explorer.search, style: "width:100%" });
    const list = el("div", { class: "ev-list" });
    const detail = el("div", { style: "display:flex;flex-direction:column;gap:16px;min-width:0" });

    const drawList = () => {
      const q = S.explorer.search.toLowerCase();
      const items = S.catalog.filter((e) => e.name.toLowerCase().includes(q));
      const groups = new Map();
      for (const e of items) {
        const g = e.name.startsWith("[") ? "Amplitude" : e.name.includes("_") ? e.name.split("_")[0] : "autres";
        if (!groups.has(g)) groups.set(g, []);
        groups.get(g).push(e);
      }
      const nodes = [];
      [...groups.entries()].sort((a, b) => sum(b[1].map((x) => x.weekTotal)) - sum(a[1].map((x) => x.weekTotal))).forEach(([g, evs]) => {
        nodes.push(el("div", { class: "ev-group" }, `${g} · ${evs.length}`));
        evs.forEach((e) => nodes.push(el("button", { class: `ev-item ${e.name === S.explorer.selected ? "active" : ""}`, title: e.name, onclick: () => { location.hash = `#explorer/${encodeURIComponent(e.name)}`; } },
          el("span", { class: "n" }, e.name), el("span", { class: "c" }, fmtNum(e.weekTotal || 0)))));
      });
      list.replaceChildren(...(nodes.length ? nodes : [emptyBox("Aucun événement ne correspond")]));
    };
    search.addEventListener("input", () => { S.explorer.search = search.value; drawList(); });
    drawList();

    root.append(el("div", { class: "explorer" },
      el("section", { class: "card" }, el("div", { class: "card-head" }, el("div", {}, el("div", { class: "card-title" }, "Tous les événements"), el("div", { class: "card-sub" }, "Volume Amplitude de la semaine en cours"))), search, list),
      detail));

    if (!S.explorer.selected) {
      detail.append(el("section", { class: "card" }, emptyBox("Choisis un événement", null, "Graphique quotidien, utilisateurs uniques et répartition par n'importe quelle propriété.")));
      return;
    }
    const event = S.explorer.selected;
    if (!has(event)) { detail.append(el("section", { class: "card" }, emptyBox(`« ${event} » n'a pas encore été reçu par Amplitude`))); return; }

    detail.append(
      card({ title: event, sub: "Total et utilisateurs uniques par jour", load: async (body) => {
        const prev = prevRange(range);
        const [t, u, pt] = await Promise.all([
          api("/api/series", { events: [event], m: "totals", ...rp(range) }), api("/api/series", { events: [event], m: "uniques", ...rp(range) }),
          api("/api/series", { events: [event], m: "totals", ...rp(prev) })]);
        const total = t.totals[event] || 0, users = u.totals[event] || 0;
        const c = el("div", { class: "chart" });
        body.replaceChildren(el("div", { class: "kpi-row", style: "flex-wrap:wrap;gap:10px" },
          el("span", { class: "kpi-value" }, fmtNum(total)), deltaBadge(total, pt.totals[event] || 0),
          el("span", { class: "tag" }, `${fmtNum(users)} utilisateurs`), el("span", { class: "tag" }, `${users ? nf1.format(total / users) : "—"} / utilisateur`)), c);
        lineChart(c, t.xValues, [{ label: "Total", data: t.series[event] || [] }, { label: "Utilisateurs", data: u.series[event] || [] }], { fill: true });
      } }),
      propertyBreakdown(event, range),
    );
  }

  function propertyBreakdown(event, range) {
    const propSelect = el("select", { "aria-label": "Propriété" });
    const metricSelect = el("select", { "aria-label": "Mesure" }, el("option", { value: "totals" }, "Total"), el("option", { value: "uniques" }, "Utilisateurs"));
    const c = card({ title: "Répartition par propriété", sub: "Propriétés d'événement et propriétés utilisateur", tools: [propSelect, metricSelect], load: async (body) => {
      if (!propSelect.options.length) {
        const [ep, up] = await Promise.all([api("/api/event-props", { event }), api("/api/user-props")]);
        const evProps = ep.properties || [];
        propSelect.append(
          el("optgroup", { label: "Propriétés d'événement" }, evProps.map((p) => el("option", { value: `event:${p}` }, p))),
          el("optgroup", { label: "Propriétés utilisateur" }, (up.properties || []).filter((p) => !["amplitude_id", "event_id", "session_id", "user_id", "device_id", "ip_address", "location_lat", "location_lng", "server_upload_time", "_time", "first_name"].includes(p)).map((p) => el("option", { value: `user:${p}` }, p))));
        const keep = S.explorer.prop && [...propSelect.options].find((o) => o.value === S.explorer.prop);
        propSelect.value = keep ? S.explorer.prop : evProps.length ? `event:${evProps[0]}` : "user:country";
      }
      const [ptype, ...rest] = propSelect.value.split(":");
      const prop = rest.join(":");
      const r = await api("/api/breakdown", { event, prop, ptype, m: metricSelect.value, limit: 25, ...rp(range) });
      if (r.missing) { body.replaceChildren(emptyBox(r.reason)); return; }
      const rows = r.rows.filter((x) => x.total > 0);
      if (!rows.length) { body.replaceChildren(emptyBox("Aucune valeur sur la période")); return; }
      const total = sum(rows.map((x) => x.total));
      const chart = el("div", { class: "chart" });
      body.replaceChildren(chart, table([{ label: prop }, { label: metricSelect.value === "uniques" ? "Utilisateurs" : "Total", num: true }, { label: "Part", num: true }],
        rows.map((x) => [x.value, barCell(x.total, rows[0].total), fmtPct(x.total / total)])));
      const top = rows.slice(0, 6);
      lineChart(chart, r.xValues, top.map((x, i) => ({ label: x.value, data: x.series, color: SERIES[i] })));
    }, skeletonKind: "lines" });
    propSelect.addEventListener("change", () => { S.explorer.prop = propSelect.value; c._run(); });
    metricSelect.addEventListener("change", () => c._run());
    return c;
  }

  // =================================================================== shell
  function renderSources() {
    const st = S.status;
    const box = $("#sources");
    if (!st) { box.replaceChildren(); return; }
    box.replaceChildren(
      el("div", { class: "source" }, el("span", { class: `dot ${st.amplitude.ok ? "ok" : "err"}` }), `Amplitude ${st.amplitude.host || ""}`),
      el("div", { class: "source" }, el("span", { class: `dot ${st.revenuecat.configured ? "ok" : "warn"}` }), st.revenuecat.configured ? "RevenueCat connecté" : "RevenueCat non connecté"),
      el("div", { class: "source" }, el("span", { class: "dot" }), `${S.catalog.length} événements · cache ${Math.round(st.cacheTtl / 60)} min`));
  }

  let bootstrapping = null;
  function bootstrap() {
    if (!bootstrapping) bootstrapping = loadCatalog().finally(() => { bootstrapping = null; });
    return bootstrapping;
  }

  async function loadCatalog() {
    const content = $("#content");
    try {
      const [status, events] = await Promise.all([api("/api/status"), api("/api/events")]);
      S.status = status;
      S.catalog = events.events || [];
      S.known = new Set(S.catalog.map((e) => e.name));
      renderSources();
      return true;
    } catch (error) {
      content.replaceChildren(errorBox(`Impossible de joindre Amplitude : ${error.message}`, () => route()));
      return false;
    }
  }

  async function route() {
    const [pageId, arg] = (location.hash.replace(/^#/, "") || "overview").split("/");
    const page = PAGES[pageId] ? pageId : "overview";
    S.token += 1;
    S.charts.forEach((c) => c.destroy());
    S.charts = [];
    document.querySelectorAll("#nav a").forEach((a) => a.classList.toggle("active", a.dataset.page === page));
    document.querySelectorAll("#range-buttons button").forEach((b) => b.classList.toggle("active", b.dataset.preset === S.preset));
    $("#custom-range").classList.toggle("show", S.preset === "custom");
    const range = currentRange();
    $("#page-title").textContent = PAGES[page].title;
    $("#page-sub").textContent = rangeLabel(range);
    const content = $("#content");
    content.replaceChildren();
    window.scrollTo(0, 0);
    const token = S.token;
    if (!S.catalog.length && !(await bootstrap())) return;
    if (token !== S.token) return; // a newer navigation started while the catalog was loading
    PAGES[page].render(content, range, arg);
    $("#updated").textContent = `Données du ${new Date().toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}`;
  }

  function savePrefs() {
    try { localStorage.setItem("cf-dash", JSON.stringify({ preset: S.preset, customStart: S.customStart, customEnd: S.customEnd })); } catch (_) { /* private mode */ }
  }

  function init() {
    try {
      const saved = JSON.parse(localStorage.getItem("cf-dash") || "{}");
      Object.assign(S, { preset: saved.preset || S.preset, customStart: saved.customStart || null, customEnd: saved.customEnd || null });
    } catch (_) { /* ignore */ }
    const start = $("#custom-start"), end = $("#custom-end");
    start.value = S.customStart || isoDate(addDays(today(), -29));
    end.value = S.customEnd || isoDate(today());
    start.max = end.max = isoDate(today());
    document.querySelectorAll("#range-buttons button").forEach((b) => b.addEventListener("click", () => {
      S.preset = b.dataset.preset;
      if (S.preset === "custom") { S.customStart = start.value; S.customEnd = end.value; }
      savePrefs(); route();
    }));
    const onCustom = () => { S.customStart = start.value; S.customEnd = end.value; S.preset = "custom"; savePrefs(); route(); };
    start.addEventListener("change", onCustom);
    end.addEventListener("change", onCustom);
    $("#refresh").addEventListener("click", async () => {
      // Requests made by the next render (token + 1) bypass the server cache.
      S.refreshToken = S.token + 1;
      S.catalog = [];
      route();
    });
    window.addEventListener("hashchange", route);
    route();
  }

  init();
})();
