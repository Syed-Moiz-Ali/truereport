import fs from 'node:fs';

const file = process.argv[2];
if (!file) {
  console.error('usage: node wire-report-css.mjs <report.css>');
  process.exit(2);
}
let css = fs.readFileSync(file, 'utf8');
if (!css.includes('@import url("tokens.g.css");')) {
  css = '@import url("tokens.g.css");\n\n' + css;
}

function removeBlock(source, startMarker) {
  const start = source.indexOf(startMarker);
  if (start < 0) return source;
  const brace = source.indexOf('{', start);
  if (brace < 0) return source;
  let depth = 0;
  for (let i = brace; i < source.length; i += 1) {
    if (source[i] === '{') depth += 1;
    else if (source[i] === '}') {
      depth -= 1;
      if (depth === 0) {
        return source.slice(0, start) + source.slice(i + 1);
      }
    }
  }
  return source;
}

css = removeBlock(css, ':root {');
css = removeBlock(css, '@media (prefers-color-scheme: dark) {');
fs.writeFileSync(file, css, 'utf8');
console.log('wired', file);
