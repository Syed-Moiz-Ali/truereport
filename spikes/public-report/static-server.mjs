import http from 'http';
import fs from 'fs';
import path from 'path';
import zlib from 'zlib';

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

const gzipCache = new Map();

function gzip(buf) {
  const key = buf.length + ':' + buf[0] + ':' + buf[buf.length - 1];
  if (gzipCache.has(key)) return gzipCache.get(key);
  const out = zlib.gzipSync(buf, { level: 9 });
  gzipCache.set(key, out);
  return out;
}

export function startServer(root, port) {
  const rootAbs = path.resolve(root);
  const server = http.createServer((req, res) => {
    try {
      const url = new URL(req.url, 'http://localhost');
      let rel = decodeURIComponent(url.pathname);
      if (rel.endsWith('/')) rel += 'index.html';
      let file = path.join(rootAbs, rel);
      if (!file.startsWith(rootAbs)) {
        res.writeHead(403); res.end('forbidden'); return;
      }
      if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
        file = path.join(rootAbs, 'index.html');
      }
      const buf = fs.readFileSync(file);
      const ext = path.extname(file).toLowerCase();
      const type = mime[ext] || 'application/octet-stream';
      const compressible = ['.html', '.js', '.mjs', '.css', '.json', '.wasm', '.svg'].includes(ext);
      const accept = String(req.headers['accept-encoding'] || '');
      const useGzip = compressible && accept.includes('gzip');
      const body = useGzip ? gzip(buf) : buf;
      res.writeHead(200, {
        'Content-Type': type,
        'Content-Length': body.length,
        'Cache-Control': 'no-store',
        ...(useGzip ? { 'Content-Encoding': 'gzip', 'Vary': 'Accept-Encoding' } : {}),
      });
      res.end(body);
    } catch (e) {
      console.error('static server error', req.url, e);
      res.writeHead(500); res.end('server error');
    }
  });
  return new Promise(resolve => server.listen(port, '127.0.0.1', () => resolve(server)));
}
