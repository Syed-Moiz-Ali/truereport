/**
 * Dependency-free PNG decoder/encoder for the F1 fidelity harness.
 *
 * Supports the subset produced by Figma exports and Flutter's
 * RepaintBoundary.toImage:
 *   - bit depth 8 and 16
 *   - colour types 0 (gray), 2 (RGB), 3 (palette), 4 (gray+alpha), 6 (RGBA)
 *   - non-interlaced (Adam7 is rejected with a clear error)
 *
 * Output is always 8-bit RGBA in a Uint8ClampedArray.
 */

import zlib from 'node:zlib';

const SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

function readChunks(buf) {
  let pos = 8;
  const chunks = [];
  while (pos + 12 <= buf.length) {
    const length = buf.readUInt32BE(pos);
    const type = buf.toString('ascii', pos + 4, pos + 8);
    const data = buf.subarray(pos + 8, pos + 8 + length);
    chunks.push({ type, data });
    pos += 12 + length;
    if (type === 'IEND') break;
  }
  return chunks;
}

function paeth(a, b, c) {
  const p = a + b - c;
  const pa = Math.abs(p - a);
  const pb = Math.abs(p - b);
  const pc = Math.abs(p - c);
  if (pa <= pb && pa <= pc) return a;
  if (pb <= pc) return b;
  return c;
}

function unfilter(raw, width, height, bytesPerPixel, rowBytes) {
  const out = Buffer.alloc(rowBytes * height);
  let src = 0;
  for (let y = 0; y < height; y += 1) {
    const filter = raw[src];
    src += 1;
    const rowStart = y * rowBytes;
    const prevStart = (y - 1) * rowBytes;
    for (let x = 0; x < rowBytes; x += 1) {
      const value = raw[src + x];
      const left = x >= bytesPerPixel ? out[rowStart + x - bytesPerPixel] : 0;
      const up = y > 0 ? out[prevStart + x] : 0;
      const upLeft = y > 0 && x >= bytesPerPixel ? out[prevStart + x - bytesPerPixel] : 0;
      let decoded;
      switch (filter) {
        case 0:
          decoded = value;
          break;
        case 1:
          decoded = value + left;
          break;
        case 2:
          decoded = value + up;
          break;
        case 3:
          decoded = value + Math.floor((left + up) / 2);
          break;
        case 4:
          decoded = value + paeth(left, up, upLeft);
          break;
        default:
          throw new Error(`Unsupported PNG filter type ${filter} at row ${y}`);
      }
      out[rowStart + x] = decoded & 0xff;
    }
    src += rowBytes;
  }
  return out;
}

export function decodePng(buf) {
  if (!buf.subarray(0, 8).equals(SIGNATURE)) {
    throw new Error('Not a PNG file');
  }
  const chunks = readChunks(buf);
  const ihdr = chunks.find((c) => c.type === 'IHDR')?.data;
  if (!ihdr || ihdr.length < 13) throw new Error('PNG has no valid IHDR');
  const width = ihdr.readUInt32BE(0);
  const height = ihdr.readUInt32BE(4);
  const bitDepth = ihdr[8];
  const colorType = ihdr[9];
  const interlace = ihdr[12];
  if (interlace !== 0) throw new Error('Interlaced PNG is not supported');
  if (bitDepth !== 8 && bitDepth !== 16) {
    throw new Error(`Unsupported PNG bit depth ${bitDepth}`);
  }

  const palette = chunks.find((c) => c.type === 'PLTE')?.data ?? null;
  const trns = chunks.find((c) => c.type === 'tRNS')?.data ?? null;
  const idat = Buffer.concat(chunks.filter((c) => c.type === 'IDAT').map((c) => c.data));
  const raw = zlib.inflateSync(idat);

  const sampleBytes = bitDepth / 8;
  const channelsByType = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 };
  const channels = channelsByType[colorType];
  if (!channels) throw new Error(`Unsupported PNG colour type ${colorType}`);

  const bytesPerPixel = channels * sampleBytes;
  const rowBytes = width * bytesPerPixel;
  const pixels = unfilter(raw, width, height, bytesPerPixel, rowBytes);
  const out = new Uint8ClampedArray(width * height * 4);

  const sampleAt = (base, channel) => {
    if (bitDepth === 8) return pixels[base + channel];
    return pixels[base + channel * 2];
  };

  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const base = y * rowBytes + x * bytesPerPixel;
      const dst = (y * width + x) * 4;
      let r;
      let g;
      let b;
      let a = 255;
      if (colorType === 0) {
        r = g = b = sampleAt(base, 0);
      } else if (colorType === 2) {
        r = sampleAt(base, 0);
        g = sampleAt(base, 1);
        b = sampleAt(base, 2);
      } else if (colorType === 3) {
        const index = pixels[base];
        if (!palette || index * 3 + 2 >= palette.length) {
          throw new Error('PNG palette index out of range');
        }
        r = palette[index * 3];
        g = palette[index * 3 + 1];
        b = palette[index * 3 + 2];
        if (trns && index < trns.length) a = trns[index];
      } else if (colorType === 4) {
        r = g = b = sampleAt(base, 0);
        a = sampleAt(base, 1);
      } else {
        r = sampleAt(base, 0);
        g = sampleAt(base, 1);
        b = sampleAt(base, 2);
        a = sampleAt(base, 3);
      }
      out[dst] = r;
      out[dst + 1] = g;
      out[dst + 2] = b;
      out[dst + 3] = a;
    }
  }

  return { width, height, data: out };
}

let crcTable = null;
function crc32(buf) {
  if (!crcTable) {
    crcTable = new Uint32Array(256);
    for (let n = 0; n < 256; n += 1) {
      let c = n;
      for (let k = 0; k < 8; k += 1) {
        c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      }
      crcTable[n] = c >>> 0;
    }
  }
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i += 1) {
    crc = crcTable[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const typeBuf = Buffer.from(type, 'ascii');
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length, 0);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
  return Buffer.concat([length, typeBuf, data, crc]);
}

export function encodePng(image) {
  const { width, height, data } = image;
  const rowBytes = width * 4;
  const raw = Buffer.alloc((rowBytes + 1) * height);
  for (let y = 0; y < height; y += 1) {
    raw[y * (rowBytes + 1)] = 0;
    data.subarray(y * rowBytes, (y + 1) * rowBytes).forEach((v, i) => {
      raw[y * (rowBytes + 1) + 1 + i] = v;
    });
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;
  return Buffer.concat([
    SIGNATURE,
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

export function cropImage(image, rect) {
  const x = Math.max(0, Math.round(rect.x ?? 0));
  const y = Math.max(0, Math.round(rect.y ?? 0));
  const width = Math.min(image.width - x, Math.round(rect.width ?? image.width));
  const height = Math.min(image.height - y, Math.round(rect.height ?? image.height));
  if (width <= 0 || height <= 0) throw new Error('Crop rectangle is outside the image');
  const out = new Uint8ClampedArray(width * height * 4);
  for (let row = 0; row < height; row += 1) {
    const srcStart = ((y + row) * image.width + x) * 4;
    out.set(image.data.subarray(srcStart, srcStart + width * 4), row * width * 4);
  }
  return { width, height, data: out };
}

export function resizeBilinear(image, width, height) {
  if (image.width === width && image.height === height) {
    return { width, height, data: new Uint8ClampedArray(image.data) };
  }
  const out = new Uint8ClampedArray(width * height * 4);
  const sx = image.width / width;
  const sy = image.height / height;
  for (let y = 0; y < height; y += 1) {
    const fy = Math.max(0, (y + 0.5) * sy - 0.5);
    const y0 = Math.floor(fy);
    const y1 = Math.min(image.height - 1, y0 + 1);
    const wy = fy - y0;
    for (let x = 0; x < width; x += 1) {
      const fx = Math.max(0, (x + 0.5) * sx - 0.5);
      const x0 = Math.floor(fx);
      const x1 = Math.min(image.width - 1, x0 + 1);
      const wx = fx - x0;
      const dst = (y * width + x) * 4;
      for (let c = 0; c < 4; c += 1) {
        const p00 = image.data[(y0 * image.width + x0) * 4 + c];
        const p10 = image.data[(y0 * image.width + x1) * 4 + c];
        const p01 = image.data[(y1 * image.width + x0) * 4 + c];
        const p11 = image.data[(y1 * image.width + x1) * 4 + c];
        const top = p00 + (p10 - p00) * wx;
        const bottom = p01 + (p11 - p01) * wx;
        out[dst + c] = top + (bottom - top) * wy;
      }
    }
  }
  return { width, height, data: out };
}

export function compositeOverWhite(image) {
  const out = new Uint8ClampedArray(image.data.length);
  for (let i = 0; i < image.data.length; i += 4) {
    const a = image.data[i + 3] / 255;
    out[i] = image.data[i] * a + 255 * (1 - a);
    out[i + 1] = image.data[i + 1] * a + 255 * (1 - a);
    out[i + 2] = image.data[i + 2] * a + 255 * (1 - a);
    out[i + 3] = 255;
  }
  return { width: image.width, height: image.height, data: out };
}

export function makeImage(width, height, rgba) {
  const data = new Uint8ClampedArray(width * height * 4);
  for (let i = 0; i < width * height; i += 1) {
    data[i * 4] = rgba[0];
    data[i * 4 + 1] = rgba[1];
    data[i * 4 + 2] = rgba[2];
    data[i * 4 + 3] = rgba[3] ?? 255;
  }
  return { width, height, data };
}

export function fillRect(image, rect, rgba) {
  const x0 = Math.max(0, Math.round(rect.x));
  const y0 = Math.max(0, Math.round(rect.y));
  const x1 = Math.min(image.width, Math.round(rect.x + rect.width));
  const y1 = Math.min(image.height, Math.round(rect.y + rect.height));
  for (let y = y0; y < y1; y += 1) {
    for (let x = x0; x < x1; x += 1) {
      const i = (y * image.width + x) * 4;
      image.data[i] = rgba[0];
      image.data[i + 1] = rgba[1];
      image.data[i + 2] = rgba[2];
      image.data[i + 3] = rgba[3] ?? 255;
    }
  }
  return image;
}
