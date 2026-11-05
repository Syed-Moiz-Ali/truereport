/**
 * Forbidden-term lint for the F1 fidelity harness.
 *
 * The deny-list is data, not code: docs/ui/figma/fidelity/forbidden-terms.json.
 * Matching is case-insensitive by default. Terms are matched as whole words;
 * patterns are regular expressions supplied as strings.
 */

import fs from 'node:fs';

export function loadDenyList(file) {
  const json = JSON.parse(fs.readFileSync(file, 'utf8'));
  const flags = json.caseInsensitive === false ? 'gu' : 'giu';
  const terms = (json.terms ?? []).map((term) => {
    const escaped = term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\s+/g, '\\s+');
    return {
      term,
      regex: new RegExp(
        `(?<![\\p{L}\\p{N}_])${escaped}(?![\\p{L}\\p{N}_])`,
        flags,
      ),
    };
  });
  const patterns = (json.patterns ?? []).map((entry) => ({
    name: entry.name,
    regex: new RegExp(entry.pattern, flags),
  }));
  return {
    file,
    description: json.description ?? '',
    terms,
    patterns,
  };
}

function snippet(text, index, length) {
  const start = Math.max(0, index - 28);
  const end = Math.min(text.length, index + length + 28);
  return `${start > 0 ? '…' : ''}${text.slice(start, end).replace(/\s+/g, ' ')}${end < text.length ? '…' : ''}`;
}

export function lintText(text, denyList) {
  const matches = [];
  for (const entry of denyList.terms) {
    entry.regex.lastIndex = 0;
    for (const match of text.matchAll(entry.regex)) {
      matches.push({
        kind: 'term',
        id: entry.term,
        match: match[0],
        index: match.index,
        context: snippet(text, match.index, match[0].length),
      });
    }
  }
  for (const entry of denyList.patterns) {
    entry.regex.lastIndex = 0;
    for (const match of text.matchAll(entry.regex)) {
      matches.push({
        kind: 'pattern',
        id: entry.name,
        match: match[0],
        index: match.index,
        context: snippet(text, match.index, match[0].length),
      });
    }
  }
  matches.sort((a, b) => a.index - b.index);
  return matches;
}

export function lintStrings(strings, denyList) {
  const text = strings.join('\n');
  const matches = lintText(text, denyList);
  return { text, matches, pass: matches.length === 0 };
}
