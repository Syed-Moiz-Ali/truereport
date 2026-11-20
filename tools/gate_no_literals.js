#!/usr/bin/env node
/*
 * Gate: no user-visible English copy in app/package lib code.
 *
 * The product ships English from the backend catalogs only. This gate scans
 * Dart string literals (not comments, not generated code, not tests) and fails
 * when a literal looks like human copy instead of code, data or a key.
 *
 * Run from the repo root:
 *   node tools/gate_no_literals.js
 */
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const scanRoots = [
  'client/apps/platform_admin_app/lib',
  'client/apps/workshop_admin_app/lib',
  'client/apps/technician_app/lib',
  'client/packages/auth/lib',
  'client/packages/design_system/lib',
  'client/packages/reference_data/lib',
  'client/packages/domain/lib',
  'client/packages/core/lib',
  'client/packages/api_client/lib',
  'client/packages/offline_sync/lib',
];

const skipFile = /\/preview\/|\/test\/|\/tool\/|\/generated\/|\/l10n\/gen\/|\.g\.dart$/;
const skipWholeFile =
  /(^|\/)(figma_spec|fonts|signin_example|offline_store|offline_database|auth_repository|reference_repository)\.dart$|(^|\/)l10n\/gen\//;

const SQL_START =
  /^(SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|PRAGMA|BEGIN|COMMIT|DROP|WITH)\b/i;
const URL_LIKE = /^(https?:|www\.|mailto:|tel:)/i;
const PATH_LIKE =
  /^(\.{0,2}\/|assets\/|package:|dart:)|\.(dart|png|svg|jpe?g|webp|json|ya?ml|ttf|otf|sql|html|css)$/i;
const CODE_LIKE =
  /^[a-z][A-Za-z0-9]*(\.[A-Za-z0-9]+)*$|^[A-Z][A-Z0-9_]*$|^[a-z0-9]+(_[a-z0-9]+)+$/;
const SEPARATORS = /^[\s\-–—·•,.:;|/\\()[\]{}<>+*=_#%&@!?'"`~^]+$/;
const FORMAT_CALL = /(DateFormat|NumberFormat|_format|parsePattern)\s*\(/;
const LOG_CALL = /\b(debugPrint|print|_log|log\.|logger|LogInterceptor)\s*\(/;
const NON_UI_CALL =
  /(debugLabel|fontFamily|fontFamilyFallback|FontLoader|family\s*:|assert\s*\(|throw\s+(?:Unsupported|Format|State|Argument|Range|Exception)|Exception\s*\(|toString\s*\()/;
const MARKUP = /<\/?[a-z][\s\S]*>|viewBox|xmlns|<path|<svg/i;
const SQLISH =
  /\b(PRIMARY|KEY|NOT|NULL|TEXT|INTEGER|BLOB|CREATE|TABLE|SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|ORDER|BY|VALUES|ON|CONFLICT|COALESCE|SUM|INDEX|ALTER|PRAGMA|BEGIN|COMMIT|DROP|WITH)\b/;
const DIAGNOSTIC = /^\[[A-Za-z]+\]|^AppFailure\(|^code=\s|^statuses?:/;
const IDENTIFIER_SAMPLE = /^[A-Z]{2,}\s*#?\d+$/;

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    const rel = path.relative(repoRoot, full).replace(/\\/g, '/');
    if (skipFile.test(rel) || skipWholeFile.test(rel)) continue;
    if (entry.isDirectory()) walk(full, out);
    else if (entry.name.endsWith('.dart')) out.push(rel);
  }
  return out;
}

/**
 * Removes ${...} and $identifier interpolation so "pure interpolation" strings
 * are not reported. Balanced braces are respected; nested strings inside an
 * interpolation are skipped as code.
 */
function stripInterpolation(raw) {
  let out = '';
  for (let i = 0; i < raw.length; i += 1) {
    const ch = raw[i];
    if (ch !== '$') {
      out += ch;
      continue;
    }
    if (raw[i + 1] === '{') {
      let depth = 1;
      i += 2;
      while (i < raw.length && depth > 0) {
        if (raw[i] === '{') depth += 1;
        else if (raw[i] === '}') depth -= 1;
        else if (raw[i] === "'" || raw[i] === '"') {
          const quote = raw[i];
          i += 1;
          while (i < raw.length && raw[i] !== quote) {
            if (raw[i] === '\\') i += 1;
            i += 1;
          }
        }
        i += 1;
      }
      i -= 1;
      out += ' ';
      continue;
    }
    const ident = /^[A-Za-z_][A-Za-z0-9_]*/.exec(raw.slice(i + 1));
    if (ident) {
      i += ident[0].length;
      out += ' ';
    } else {
      out += ch;
    }
  }
  return out;
}

/**
 * Extracts string literals from one Dart source. Handles comments, triple
 * quotes, escapes and interpolation braces so a literal is one token.
 */
function literals(source) {
  const found = [];
  let i = 0;
  let line = 1;
  const n = source.length;

  while (i < n) {
    const ch = source[i];

    if (ch === '\n') {
      line += 1;
      i += 1;
      continue;
    }
    if (ch === '/' && source[i + 1] === '/') {
      while (i < n && source[i] !== '\n') i += 1;
      continue;
    }
    if (ch === '/' && source[i + 1] === '*') {
      i += 2;
      while (i < n && !(source[i] === '*' && source[i + 1] === '/')) {
        if (source[i] === '\n') line += 1;
        i += 1;
      }
      i += 2;
      continue;
    }
    if (ch !== "'" && ch !== '"') {
      i += 1;
      continue;
    }

    const quote = ch;
    const triple = source.startsWith(quote.repeat(3), i);
    const raw = source[i - 1] === 'r' && !/[A-Za-z0-9_]/.test(source[i - 2] || '');
    const startLine = line;
    i += triple ? 3 : 1;
    let text = '';

    while (i < n) {
      if (!raw && source[i] === '\\') {
        text += source[i];
        if (i + 1 < n) text += source[i + 1];
        if (source[i + 1] === '\n') line += 1;
        i += 2;
        continue;
      }
      if (!raw && source[i] === '$' && source[i + 1] === '{') {
        // Interpolation is code, not copy. Skip balanced braces, including
        // nested strings, so quotes inside it do not terminate the literal.
        let depth = 1;
        i += 2;
        while (i < n && depth > 0) {
          if (source[i] === '{') depth += 1;
          else if (source[i] === '}') depth -= 1;
          else if (source[i] === "'" || source[i] === '"') {
            const inner = source[i];
            i += 1;
            while (i < n && source[i] !== inner) {
              if (source[i] === '\\') i += 1;
              if (source[i] === '\n') line += 1;
              i += 1;
            }
          } else if (source[i] === '\n') {
            line += 1;
          }
          i += 1;
        }
        continue;
      }
      if (triple) {
        if (source.startsWith(quote.repeat(3), i)) {
          i += 3;
          break;
        }
      } else if (source[i] === quote) {
        i += 1;
        break;
      }
      if (source[i] === '\n') line += 1;
      text += source[i];
      i += 1;
    }

    found.push({ line: startLine, text, raw, start: i });
  }
  return found;
}

function isUserCopy(text) {
  const cleaned = stripInterpolation(text).replace(/\s+/g, ' ').trim();
  if (cleaned.length < 4) return false;
  if (!/[A-Za-z]/.test(cleaned)) return false;
  if (!/\s/.test(cleaned)) return false;
  if (SEPARATORS.test(cleaned)) return false;
  if (!/\b[A-Za-z]{3,}\b/.test(cleaned)) return false;
  if (MARKUP.test(cleaned)) return false;
  if (SQLISH.test(cleaned)) return false;
  if (DIAGNOSTIC.test(cleaned)) return false;
  if (IDENTIFIER_SAMPLE.test(cleaned)) return false;
  if (text.includes('$') && /^[a-z0-9][a-z0-9 _.\-]*$/.test(cleaned)) {
    // Operation/cache keys and ids with interpolation, not copy.
    return false;
  }
  if (SQL_START.test(cleaned)) return false;
  if (URL_LIKE.test(cleaned)) return false;
  if (PATH_LIKE.test(cleaned)) return false;
  if (CODE_LIKE.test(cleaned)) return false;
  return true;
}

function sourceLine(source, line) {
  return (source.split(/\r?\n/)[line - 1] || '').trim();
}

const hits = [];
for (const root of scanRoots) {
  const files = walk(path.join(repoRoot, root));
  for (const rel of files) {
    const source = fs.readFileSync(path.join(repoRoot, rel), 'utf8');
    if (/gate-allow:\s*literal/.test(source)) {
      // Per-line allow only; do not silence a whole file.
    }
    for (const token of literals(source)) {
      const lines = source.split(/\r?\n/);
      const lineText = lines[token.line - 1] || '';
      const context = lines
        .slice(Math.max(0, token.line - 4), token.line)
        .join(' ');
      if (/gate-allow:\s*literal/.test(lineText)) continue;
      if (NON_UI_CALL.test(context)) continue;
      if (LOG_CALL.test(lineText) || LOG_CALL.test(context)) continue;
      if (FORMAT_CALL.test(lineText) || FORMAT_CALL.test(context)) continue;
      // A literal used as an l10n key argument is code, not copy.
      if (/(l10n\.|AppLocalizations|Keys\.|UiMessageKey|remoteEnglish)/.test(lineText)) {
        continue;
      }
      if (!isUserCopy(token.text)) continue;
      hits.push({
        file: rel,
        line: token.line,
        text: stripInterpolation(token.text).replace(/\s+/g, ' ').trim(),
      });
    }
  }
}

if (hits.length === 0) {
  process.exitCode = 0;
} else {
  for (const hit of hits) {
    console.log(`${hit.file}:${hit.line}  "${hit.text}"`);
  }
  console.log('');
  console.log(
    `user-visible literals: ${hits.length}. Add a backend key (technician/workshop_admin/platform_admin catalog) and resolve it through l10n.`,
  );
  process.exitCode = 1;
}
