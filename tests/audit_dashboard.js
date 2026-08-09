#!/usr/bin/env node
/**
 * audit_dashboard.js — Playwright UI audit for the Godot Model Bench dashboard.
 *
 * Renders results/dashboard.html at multiple viewports and programmatically
 * checks for visualization defects that escape casual review:
 *   - text nodes overflowing the SVG viewBox (clipped / cut-off labels)
 *   - oversized text (font px too big for its container, or chart text > body text)
 *   - horizontally overflowing page (invisible content / scroll)
 *   - overlapping SVG text elements (colliding value labels)
 *   - console errors / failed resource loads
 *
 * Usage:
 *   node tests/audit_dashboard.js [--port 8000] [--viewport 1440x900] [--out tests/audit-output] [--serve results]
 *
 * Exit code 0 = no findings, 1 = findings (visual only), 2 = hard failure (JS/load).
 * Screenshots are written to <out>/shots/ for vision review.
 */
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const RESULTS_DIR = path.resolve(ROOT, 'results');
const args = process.argv.slice(2);
const getArg = (flag, dflt) => { const i = args.indexOf(flag); return i >= 0 ? args[i + 1] : dflt; };
const PORT = parseInt(getArg('--port', '8123'), 10);
const OUT = path.resolve(ROOT, getArg('--out', 'tests/audit-output'));
const VIEWPORTS = [{ w: 1440, h: 900 }, { w: 1024, h: 768 }, { w: 1280, h: 800 }];
const BODY_FONT_PX = 13; // body.css font-size (px) — chart text should not dwarf it

const findings = [];
const addFinding = (sev, viewport, msg, detail = '') => {
  const vps = typeof viewport === 'object' ? `${viewport.w}x${viewport.h}` : String(viewport);
  findings.push({ sev, viewport: vps, msg, detail });
};

/** True if the first SVG text bbox extends beyond the SVG layer bounds. */
function textOverflowsSVG(svg) {
  const svgRect = svg.getBoundingClientRect();
  const textEls = svg.querySelectorAll('text');
  const out = [];
  for (const t of textEls) {
    const r = t.getBoundingClientRect();
    if (r.width === 0 && r.height === 0) continue; // hidden/empty
    // clip horizontally (labels cut off at left/right edge)
    if (r.left < svgRect.left - 1 || r.right > svgRect.right + 1) {
      out.push({ text: (t.textContent || '').trim().slice(0, 40), clip: 'h' });
    }
    // clip vertically (top/bottom)
    if (r.top < svgRect.top - 1 || r.bottom > svgRect.bottom + 1) {
      out.push({ text: (t.textContent || '').trim().slice(0, 40), clip: 'v' });
    }
  }
  return out;
}

/** Detect two SVG <text> nodes whose bounding boxes overlap substantially. */
function overlappingText(svg) {
  const textEls = [...svg.querySelectorAll('text')].filter(t => {
    const r = t.getBoundingClientRect();
    return r.width > 0 && r.height > 0;
  });
  const cols = [];
  for (let i = 0; i < textEls.length; i++) {
    const a = textEls[i].getBoundingClientRect();
    for (let j = i + 1; j < textEls.length; j++) {
      const b = textEls[j].getBoundingClientRect();
      const ix = Math.max(0, Math.min(a.right, b.right) - Math.max(a.left, b.left));
      const iy = Math.max(0, Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top));
      if (ix <= 0 || iy <= 0) continue;
      const area = ix * iy;
      const minArea = Math.min(a.width * a.height, b.width * b.height);
      if (minArea > 0 && area / minArea > 0.35) {
        cols.push({
          a: (textEls[i].textContent || '').trim().slice(0, 30),
          b: (textEls[j].textContent || '').trim().slice(0, 30),
        });
      }
    }
  }
  return cols;
}

/** Oversized: any SVG text whose computed font-size exceeds the body font px. */
function oversizedSVGText(svg, BODY_FONT_PX) {
  const out = [];
  for (const t of svg.querySelectorAll('text')) {
    const fs = parseFloat(getComputedStyle(t).fontSize);
    if (!isNaN(fs) && fs > BODY_FONT_PX + 2) {
      out.push({ text: (t.textContent || '').trim().slice(0, 40), fs });
    }
  }
  return out;
}

/** ECharts renders to <canvas>; verify each canvas fits its container and drew content. */
async function auditECharts(page, vp) {
  const canvases = await page.$$('#heatmap-chart canvas, #radar-chart canvas');
  for (const cv of canvases) {
    const info = await cv.evaluate(c => {
      const rect = c.getBoundingClientRect();
      const parent = c.closest('.chart-half').getBoundingClientRect();
      const ctx = c.getContext('2d');
      let drew = false;
      try {
        const data = ctx.getImageData(0, 0, c.width, c.height).data;
        // Sample with stride — the top-left corner of a chart can legitimately be empty.
        const step = 8;
        for (let y = 0; y < c.height && !drew; y += step) {
          for (let x = 0; x < c.width; x += step) {
            if (data[(y * c.width + x) * 4 + 3] > 0) { drew = true; break; }
          }
        }
      } catch (e) { /* tainted canvas */ }
      return {
        w: Math.round(rect.width), h: Math.round(rect.height),
        parentW: Math.round(parent.width),
        overflow: rect.width > parent.width + 2 || rect.height > parent.height + 2,
        drew
      };
    });
    if (info.overflow) {
      addFinding('high', vp, `ECharts canvas overflows its container`,
        `${info.w}px vs container ${info.parentW}px`);
    }
    if (!info.drew) {
      addFinding('medium', vp, 'ECharts canvas appears blank (no pixels drawn)',
        `${info.w}x${info.h}`);
    }
  }
}

async function auditPage(page, vp) {
  const svgCount = await page.locator('svg').count();
  const svgs = await page.$$('svg');
  for (let i = 0; i < svgs.length; i++) {
    const svg = svgs[i];
    const id = await svg.getAttribute('id') || `svg#${i + 1}`;
    const label = await svg.evaluate(el => el.closest('.chart-container')?.querySelector('.chart-title')?.textContent || id);

    const overflow = await svg.evaluate(textOverflowsSVG);
    if (overflow.length) {
      const clipped = overflow.filter(o => o.clip === 'h').length;
      addFinding('high', vp, `${label}: ${clipped} text label(s) clipped horizontally (cut-off)`,
        overflow.filter(o => o.clip === 'h').slice(0, 6).map(o => `"${o.text}"`).join(', '));
    }

    const cols = await svg.evaluate(overlappingText);
    if (cols.length) {
      addFinding('high', vp, `${label}: ${cols.length} overlapping text pair(s)`,
        cols.slice(0, 4).map(c => `"${c.a}" × "${c.b}"`).join(' | '));
    }

    const oversized = await svg.evaluate(oversizedSVGText, BODY_FONT_PX);
    if (oversized.length) {
      addFinding('medium', vp, `${label}: ${oversized.length} text node(s) larger than body font (${BODY_FONT_PX}px)`,
        oversized.slice(0, 5).map(o => `"${o.text}" @${o.fs}px`).join(', '));
    }
  }

  await auditECharts(page, vp);

  // Whole-page horizontal overflow
  const overflowX = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1);
  if (overflowX) {
    addFinding('high', vp, 'Page has horizontal overflow (content cut off / lateral scrollbar)',
      `scrollWidth=${await page.evaluate(() => document.documentElement.scrollWidth)}px viewport=${vp.w}px`);
  }
}

async function main() {
  fs.mkdirSync(path.join(OUT, 'shots'), { recursive: true });

  // Start a static server over results/ so fetch('all_results.json') works.
  const server = http.createServer((req, res) => {
    let p = decodeURIComponent(req.url.split('?')[0]);
    if (p === '/') p = '/dashboard.html';
    const file = path.join(RESULTS_DIR, p);
    if (!file.startsWith(RESULTS_DIR) || !fs.existsSync(file)) {
      res.writeHead(404); res.end('not found'); return;
    }
    const ext = path.extname(file);
    const mime = { '.html': 'text/html', '.js': 'application/javascript', '.json': 'application/json' };
    res.writeHead(200, { 'content-type': mime[ext] || 'application/octet-stream' });
    fs.createReadStream(file).pipe(res);
  });
  await new Promise(r => server.listen(PORT, '127.0.0.1', r));
  const url = `http://127.0.0.1:${PORT}/dashboard.html`;

  const browser = await chromium.launch();
  const consoleErrors = [];
  const pageErrors = [];

  for (const vp of VIEWPORTS) {
    const page = await browser.newPage({ viewport: { width: vp.w, height: vp.h } });
    page.on('console', msg => { if (msg.type() === 'error') consoleErrors.push(`${vp.w}x${vp.h}: ${msg.text()}`); });
    page.on('pageerror', err => pageErrors.push(`${vp.w}x${vp.h}: ${err.message}`));

    await page.goto(url, { waitUntil: 'networkidle' });
    // allow D3 to render
    await page.waitForTimeout(1200);
    const svgCount = await page.locator('svg').count();
    if (svgCount === 0) {
      addFinding('critical', vp, 'No SVG charts rendered — dashboard likely failed to load data');
      await page.screenshot({ path: path.join(OUT, 'shots', `empty_${vp.w}x${vp.h}.png`), fullPage: false });
      await page.close();
      continue;
    }

    await auditPage(page, vp);
    await page.screenshot({ path: path.join(OUT, 'shots', `dashboard_${vp.w}x${vp.h}.png`), fullPage: true });

    // interaction smoke: switch metric + round, then re-audit for regressions
    await page.selectOption('#metric-select', 'cost');
    await page.waitForTimeout(600);
    await auditPage(page, `post-cost-${vp.w}x${vp.h}`);
    await page.selectOption('#metric-select', 'score');
    await page.selectOption('#round-select', '5');
    await page.waitForTimeout(600);
    await auditPage(page, `post-r5-${vp.w}x${vp.h}`);
    await page.screenshot({ path: path.join(OUT, 'shots', `r5_cost_${vp.w}x${vp.h}.png`), fullPage: true });

    await page.close();
  }

  await browser.close();
  server.close();

  // Severity ordering
  const order = { critical: 0, high: 1, medium: 2, low: 3 };
  findings.sort((a, b) => order[a.sev] - order[b.sev]);

  const consoleClean = [...new Set(consoleErrors)];
  const pageClean = [...new Set(pageErrors)];

  const lines = [];
  lines.push('# Dashboard UI Audit — Playwright');
  lines.push('');
  lines.push(`- Date: ${new Date().toISOString()}`);
  lines.push(`- Viewports: ${VIEWPORTS.map(v => `${v.w}x${v.h}`).join(', ')}`);
  lines.push(`- Screenshots: ${path.join(OUT, 'shots')}`);
  lines.push('');
  lines.push('## Findings');
  lines.push('');
  if (!findings.length) {
    lines.push('No layout/visual defects detected. ✅');
  } else {
    lines.push(`| Sev | Viewport | Container | Issue | Detail |`);
    lines.push('|---|---|---|---|---|');
    for (const f of findings) {
      lines.push(`| ${f.sev} | ${f.viewport} | — | ${f.msg} | ${f.detail.replace(/\|/g, '\\|')} |`);
    }
  }
  lines.push('');
  lines.push('## Console / JS errors');
  lines.push('');
  if (!consoleClean.length && !pageClean.length) {
    lines.push('None. ✅');
  } else {
    for (const e of consoleClean) lines.push(`- console.error: ${e}`);
    for (const e of pageClean) lines.push(`- pageerror: ${e}`);
  }

  fs.writeFileSync(path.join(OUT, 'report.md'), lines.join('\n'));
  console.log(lines.join('\n'));

  process.exit(findings.length ? 1 : (consoleClean.length || pageClean.length) ? 2 : 0);
}

main().catch(e => { console.error(e); process.exit(2); });