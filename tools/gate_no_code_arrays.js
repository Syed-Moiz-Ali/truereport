#!/usr/bin/env node
/*
 * Gate: no local enum/wire-code arrays in client lib code.
 *
 * A Dart list literal that holds two or more distinct uppercase wire codes
 * (`^[A-Z][A-Z0-9_]{2,}$`) is a local copy of a served taxonomy: statuses,
 * result codes, input types, evidence types, directions, and so on. Those
 * lists belong to /api/v1/reference/* and must be resolved through
 * `statusesProvider` / `enumsProvider` instead.
 *
 * Not every uppercase list is taxonomy: a behaviour switch, a mime allow-list
 * or a test fixture may legitimately need one. Add
 * `// gate-allow: codes` on the array line or the line above it, with a short
 * justification in the same comment.
 *
 * Run from the repo root:
 *   node tools/gate_no_code_arrays.js
 */
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');

const skipFile =
  /\/preview\/|\/test\/|\/tool\/|\/generated\/|\/l10n\/gen\/|\.g\.dart$|\.freezed\.dart$/;

const CODE = /^[A-Z][A-Z0-9_]{2,}$/;
const ALLOW = /gate-allow:\s*codes\b/;

/** App/package lib roots, discovered so new apps are covered automatically. */
function scanRoots() {
  const roots = [];
  for (const group of ['apps', 'packages']) {
    const base = path.join(repoRoot, 'client', group);
    if (!fs.existsSync(base)) continue;
    for (const entry of fs.readdirSync(base, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      const lib = path.join(base, entry.name, 'lib');
      if (fs.existsSync(lib)) roots.push(lib);
    }
  }
  return roots;
}

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    const rel = path.relative(repoRoot, full).replace(/\\/g, '/');
    if (skipFile.test(rel)) continue;
    if (entry.isDirectory()) walk(full, out);
    else if (entry.name.endsWith('.dart')) out.push(rel);
  }
  return out;
}

/** True when [index] starts a raw string prefix (`r'…'`, `r"…"`). */
function rawStringAt(source, index) {
  return (
    (source[index] === 'r' || source[index] === 'R') &&
    (source[index + 1] === '"' || source[index + 1] === "'")
  );
}

/**
 * Skips a Dart string starting at [index] and returns the index just past it
 * plus the decoded literal text. Handles raw strings, triple quotes and
 * `${…}` interpolation so quoted code inside interpolation does not desync.
 */
function readString(source, index) {
  let i = index;
  const raw = rawStringAt(source, i);
  if (raw) i += 1;
  const quote = source[i];
  const triple =
    source[i + 1] === quote && source[i + 2] === quote ? quote.repeat(3) : null;
  const close = triple ?? quote;
  i += close.length;
  let value = '';
  while (i < source.length) {
    if (!raw && source[i] === '\\') {
      value += source[i + 1] ?? '';
      i += 2;
      continue;
    }
    if (source.startsWith(close, i)) {
      return { end: i + close.length, value };
    }
    if (!raw && source[i] === '$' && source[i + 1] === '{') {
      const skipped = skipInterpolation(source, i + 2);
      i = skipped;
      continue;
    }
    value += source[i];
    i += 1;
  }
  return { end: i, value };
}

/** Returns the index just past the `}` closing an interpolation expression. */
function skipInterpolation(source, index) {
  let depth = 1;
  let i = index;
  while (i < source.length) {
    const ch = source[i];
    if (ch === '"' || ch === "'" || rawStringAt(source, i)) {
      i = readString(source, i).end;
      continue;
    }
    if (ch === '/' && source[i + 1] === '/') {
      while (i < source.length && source[i] !== '\n') i += 1;
      continue;
    }
    if (ch === '/' && source[i + 1] === '*') {
      i += 2;
      while (i < source.length && !(source[i] === '*' && source[i + 1] === '/')) {
        i += 1;
      }
      i += 2;
      continue;
    }
    if (ch === '{') depth += 1;
    if (ch === '}') {
      depth -= 1;
      if (depth === 0) return i + 1;
    }
    i += 1;
  }
  return i;
}

/**
 * Reads the list literal that starts at [index] (`[`) and returns its end
 * index and the string literals at bracket depth 1 within it.
 */
function readList(source, index) {
  const literals = [];
  let depth = 0;
  let i = index;
  while (i < source.length) {
    const ch = source[i];
    if (ch === '/' && source[i + 1] === '/') {
      while (i < source.length && source[i] !== '\n') i += 1;
      continue;
    }
    if (ch === '/' && source[i + 1] === '*') {
      i += 2;
      while (i < source.length && !(source[i] === '*' && source[i + 1] === '/')) {
        i += 1;
      }
      i += 2;
      continue;
    }
    if (ch === '"' || ch === "'" || rawStringAt(source, i)) {
      const string = readString(source, i);
      if (depth === 1) literals.push(string.value);
      i = string.end;
      continue;
    }
    if (ch === '[' || ch === '(' || ch === '{') depth += 1;
    if (ch === ']' || ch === ')' || ch === '}') {
      depth -= 1;
      if (depth === 0) return { end: i, literals };
    }
    i += 1;
  }
  return { end: i, literals };
}

function isAllowed(lines, lineIndex) {
  if (ALLOW.test(lines[lineIndex] || '')) return true;
  if (lineIndex > 0 && ALLOW.test(lines[lineIndex - 1] || '')) return true;
  return false;
}

function oneLine(text) {
  const compact = text.replace(/\s+/g, ' ').trim();
  return compact.length > 150 ? `${compact.slice(0, 147)}...` : compact;
}

const hits = [];
for (const root of scanRoots()) {
  for (const rel of walk(root)) {
    const source = fs.readFileSync(path.join(repoRoot, rel), 'utf8');
    const lines = source.split(/\r?\n/);
    let lineStarts = null;
    const lineOf = (position) => {
      if (!lineStarts) {
        lineStarts = [0];
        for (let i = 0; i < source.length; i += 1) {
          if (source[i] === '\n') lineStarts.push(i + 1);
        }
      }
      let low = 0;
      let high = lineStarts.length - 1;
      while (low < high) {
        const mid = Math.ceil((low + high) / 2);
        if (lineStarts[mid] <= position) low = mid;
        else high = mid - 1;
      }
      return low;
    };

    let i = 0;
    while (i < source.length) {
      const ch = source[i];
      if (ch === '/' && source[i + 1] === '/') {
        while (i < source.length && source[i] !== '\n') i += 1;
        continue;
      }
      if (ch === '/' && source[i + 1] === '*') {
        i += 2;
        while (
          i < source.length &&
          !(source[i] === '*' && source[i + 1] === '/')
        ) {
          i += 1;
        }
        i += 2;
        continue;
      }
      if (ch === '"' || ch === "'" || rawStringAt(source, i)) {
        i = readString(source, i).end;
        continue;
      }
      if (ch !== '[') {
        i += 1;
        continue;
      }

      const lineIndex = lineOf(i);
      const line = lines[lineIndex] || '';
      // Index access (`foo[bar]`) is not a literal; a literal is introduced by
      // an operator, a comma, a bracket, `return`, or a generic `<T>[`.
      const before = source.slice(Math.max(0, i - 40), i);
      const literalContext =
        /(?:^|[=(:,;!?&|]|return|\bconst|\bfinal|\bstatic|\bvar|=>)\s*(?:<[^>]*>)?\s*$/.test(
          before,
        );
      const list = readList(source, i);
      i = list.end + 1;
      if (!literalContext || isAllowed(lines, lineIndex)) continue;

      const codes = [
        ...new Set(list.literals.filter((value) => CODE.test(value))),
      ];
      if (codes.length < 2) continue;
      hits.push({
        file: rel,
        line: lineIndex + 1,
        codes,
        text: oneLine(line),
      });
    }
  }
}

if (hits.length === 0) {
  process.exitCode = 0;
} else {
  for (const hit of hits) {
    console.log(
      `${hit.file}:${hit.line}  local code array [${hit.codes.join(', ')}]`,
    );
    console.log(`  ${hit.text}`);
  }
  console.log('');
  console.log(
    `local enum/wire-code arrays: ${hits.length}. Resolve them through ` +
      '/reference/statuses|enums, or justify with // gate-allow: codes.',
  );
  process.exitCode = 1;
}
