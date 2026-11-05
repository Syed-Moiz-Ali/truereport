import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const cssPath = path.join(
  root,
  'server',
  'src',
  'main',
  'resources',
  'public-report',
  'tokens.g.css',
);
const templatePath = path.join(
  root,
  'server',
  'src',
  'main',
  'resources',
  'templates',
  'report',
  'print-report.html',
);

const css = fs.readFileSync(cssPath, 'utf8');
const start = css.indexOf(':root {');
if (start < 0) {
  throw new Error('tokens.g.css has no :root block');
}
let depth = 0;
let end = -1;
for (let i = css.indexOf('{', start); i < css.length; i += 1) {
  if (css[i] === '{') depth += 1;
  else if (css[i] === '}') {
    depth -= 1;
    if (depth === 0) {
      end = i + 1;
      break;
    }
  }
}
if (end < 0) {
  throw new Error('Could not find the end of the :root block');
}
const tokenRoot = css.slice(start, end);

let html = fs.readFileSync(templatePath, 'utf8');
const colorMap = {
  '#17212b': 'var(--tr-on-surface)',
  '#0b3b4a': 'var(--tr-brand-ink)',
  '#0f6b6f': 'var(--tr-secondary)',
  '#4d6670': 'var(--tr-on-surface-variant)',
  '#d5e3e6': 'var(--tr-outline-variant)',
  '#edf1f3': 'var(--tr-neutral-bg)',
  '#fbe9e7': 'var(--tr-danger-bg)',
  '#a3231f': 'var(--tr-danger)',
  '#fff4d6': 'var(--tr-warning-bg)',
  '#8a5a00': 'var(--tr-warning)',
  '#f7dada': 'var(--tr-critical-bg)',
  '#7f1d1d': 'var(--tr-critical)',
  '#e6f3ec': 'var(--tr-success-bg)',
  '#1f6b45': 'var(--tr-success)',
  '#f1f5f5': 'var(--tr-surface-low)',
  '#eaf0f0': 'var(--tr-surface-high)',
  '#ffffff': 'var(--tr-surface-lowest)',
  '#fff': 'var(--tr-surface-lowest)',
};
for (const [hex, variable] of Object.entries(colorMap)) {
  html = html.replace(new RegExp(hex, 'gi'), variable);
}

const begin = '<!-- TOKENS:BEGIN -->';
const finish = '<!-- TOKENS:END -->';
const block = `${begin}\n  <style>\n${tokenRoot}\n  </style>\n  ${finish}`;
if (html.includes(begin) && html.includes(finish)) {
  const before = html.slice(0, html.indexOf(begin));
  const after = html.slice(html.indexOf(finish) + finish.length);
  html = before + block + after;
} else {
  const marker = '  <style>\n    @page';
  const index = html.indexOf(marker);
  if (index < 0) {
    throw new Error('Could not find the print style block');
  }
  html = html.slice(0, index) + `  ${block}\n` + html.slice(index);
}
const check = process.argv.includes('--check');
if (check) {
  const current = fs.readFileSync(templatePath, 'utf8');
  if (current !== html) {
    console.error('stale:', templatePath);
    process.exitCode = 1;
  } else {
    console.log('print tokens are up to date');
  }
} else {
  fs.writeFileSync(templatePath, html, 'utf8');
  console.log('wired', templatePath);
}
