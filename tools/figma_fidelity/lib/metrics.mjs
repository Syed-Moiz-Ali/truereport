/**
 * Image metrics for the F1 fidelity harness.
 *
 * All functions take { width, height, data: Uint8ClampedArray RGBA }.
 * SSIM uses an 11x11 Gaussian window (sigma 1.5) on sRGB luminance.
 * Delta-E is CIEDE2000 computed through sRGB -> linear -> XYZ D65 -> Lab.
 */

function clamp(v, lo, hi) {
  return v < lo ? lo : v > hi ? hi : v;
}

export function toLuminance(image) {
  const n = image.width * image.height;
  const out = new Float64Array(n);
  for (let i = 0; i < n; i += 1) {
    const p = i * 4;
    out[i] = 0.2126 * image.data[p] + 0.7152 * image.data[p + 1] + 0.0722 * image.data[p + 2];
  }
  return out;
}

function gaussianKernel(radius, sigma) {
  const kernel = new Float64Array(radius * 2 + 1);
  let sum = 0;
  for (let i = -radius; i <= radius; i += 1) {
    const value = Math.exp(-(i * i) / (2 * sigma * sigma));
    kernel[i + radius] = value;
    sum += value;
  }
  for (let i = 0; i < kernel.length; i += 1) kernel[i] /= sum;
  return kernel;
}

function blurSeparable(src, width, height, kernel) {
  const radius = (kernel.length - 1) / 2;
  const tmp = new Float64Array(src.length);
  const out = new Float64Array(src.length);
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      let sum = 0;
      for (let k = -radius; k <= radius; k += 1) {
        const sx = clamp(x + k, 0, width - 1);
        sum += src[y * width + sx] * kernel[k + radius];
      }
      tmp[y * width + x] = sum;
    }
  }
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      let sum = 0;
      for (let k = -radius; k <= radius; k += 1) {
        const sy = clamp(y + k, 0, height - 1);
        sum += tmp[sy * width + x] * kernel[k + radius];
      }
      out[y * width + x] = sum;
    }
  }
  return out;
}

export function ssim(ref, render, tileSize = 64) {
  if (ref.width !== render.width || ref.height !== render.height) {
    throw new Error('SSIM requires equal image sizes');
  }
  const width = ref.width;
  const height = ref.height;
  const a = toLuminance(ref);
  const b = toLuminance(render);
  const kernel = gaussianKernel(5, 1.5);

  const aa = new Float64Array(a.length);
  const bb = new Float64Array(a.length);
  const ab = new Float64Array(a.length);
  for (let i = 0; i < a.length; i += 1) {
    aa[i] = a[i] * a[i];
    bb[i] = b[i] * b[i];
    ab[i] = a[i] * b[i];
  }

  const muA = blurSeparable(a, width, height, kernel);
  const muB = blurSeparable(b, width, height, kernel);
  const sigmaAA = blurSeparable(aa, width, height, kernel);
  const sigmaBB = blurSeparable(bb, width, height, kernel);
  const sigmaAB = blurSeparable(ab, width, height, kernel);

  const c1 = (0.01 * 255) ** 2;
  const c2 = (0.03 * 255) ** 2;
  const map = new Float64Array(a.length);
  for (let i = 0; i < a.length; i += 1) {
    const va = sigmaAA[i] - muA[i] * muA[i];
    const vb = sigmaBB[i] - muB[i] * muB[i];
    const cov = sigmaAB[i] - muA[i] * muB[i];
    const numerator = (2 * muA[i] * muB[i] + c1) * (2 * cov + c2);
    const denominator = (muA[i] ** 2 + muB[i] ** 2 + c1) * (va + vb + c2);
    map[i] = denominator === 0 ? 1 : numerator / denominator;
  }

  let sum = 0;
  for (let i = 0; i < map.length; i += 1) sum += map[i];
  const global = sum / map.length;

  const tiles = [];
  for (let y = 0; y < height; y += tileSize) {
    for (let x = 0; x < width; x += tileSize) {
      const x1 = Math.min(width, x + tileSize);
      const y1 = Math.min(height, y + tileSize);
      let tileSum = 0;
      for (let ty = y; ty < y1; ty += 1) {
        for (let tx = x; tx < x1; tx += 1) tileSum += map[ty * width + tx];
      }
      tiles.push({
        x,
        y,
        width: x1 - x,
        height: y1 - y,
        ssim: tileSum / ((x1 - x) * (y1 - y)),
      });
    }
  }
  const minTile = tiles.reduce((m, t) => Math.min(m, t.ssim), 1);
  return { global, tiles, minTile };
}

export function rmseAndMae(ref, render) {
  const n = ref.width * ref.height;
  const sumSq = [0, 0, 0];
  const sumAbs = [0, 0, 0];
  for (let i = 0; i < n; i += 1) {
    const p = i * 4;
    for (let c = 0; c < 3; c += 1) {
      const d = ref.data[p + c] - render.data[p + c];
      sumSq[c] += d * d;
      sumAbs[c] += Math.abs(d);
    }
  }
  const rmse = Math.sqrt(sumSq.reduce((a, b) => a + b, 0) / (n * 3));
  const mae = sumAbs.reduce((a, b) => a + b, 0) / (n * 3);
  return {
    rmse,
    mae,
    maePerChannel: { r: sumAbs[0] / n, g: sumAbs[1] / n, b: sumAbs[2] / n },
    rmsePerChannel: {
      r: Math.sqrt(sumSq[0] / n),
      g: Math.sqrt(sumSq[1] / n),
      b: Math.sqrt(sumSq[2] / n),
    },
  };
}

const SRGB_TO_LINEAR = new Float64Array(256);
for (let i = 0; i < 256; i += 1) {
  const v = i / 255;
  SRGB_TO_LINEAR[i] = v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
}

const XN = 0.95047;
const YN = 1.0;
const ZN = 1.08883;

function labFromRgb(r, g, b) {
  const rl = SRGB_TO_LINEAR[r];
  const gl = SRGB_TO_LINEAR[g];
  const bl = SRGB_TO_LINEAR[b];
  const x = (0.4124564 * rl + 0.3575761 * gl + 0.1804375 * bl) / XN;
  const y = (0.2126729 * rl + 0.7151522 * gl + 0.072175 * bl) / YN;
  const z = (0.0193339 * rl + 0.119192 * gl + 0.9503041 * bl) / ZN;
  const f = (t) => (t > 0.008856451679035631 ? Math.cbrt(t) : 7.787037037037035 * t + 16 / 116);
  const fx = f(x);
  const fy = f(y);
  const fz = f(z);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

function deg(rad) {
  return (rad * 180) / Math.PI;
}

function rad(degValue) {
  return (degValue * Math.PI) / 180;
}

function ciede2000(lab1, lab2) {
  const [L1, a1, b1] = lab1;
  const [L2, a2, b2] = lab2;
  const C1 = Math.hypot(a1, b1);
  const C2 = Math.hypot(a2, b2);
  const Cbar = (C1 + C2) / 2;
  const Cbar7 = Cbar ** 7;
  const G = 0.5 * (1 - Math.sqrt(Cbar7 / (Cbar7 + 25 ** 7)));
  const a1p = (1 + G) * a1;
  const a2p = (1 + G) * a2;
  const C1p = Math.hypot(a1p, b1);
  const C2p = Math.hypot(a2p, b2);

  let h1p = C1p === 0 ? 0 : deg(Math.atan2(b1, a1p));
  if (h1p < 0) h1p += 360;
  let h2p = C2p === 0 ? 0 : deg(Math.atan2(b2, a2p));
  if (h2p < 0) h2p += 360;

  const dLp = L2 - L1;
  const dCp = C2p - C1p;
  let dhp = 0;
  if (C1p * C2p !== 0) {
    dhp = h2p - h1p;
    if (dhp > 180) dhp -= 360;
    else if (dhp < -180) dhp += 360;
  }
  const dHp = 2 * Math.sqrt(C1p * C2p) * Math.sin(rad(dhp) / 2);

  const Lbarp = (L1 + L2) / 2;
  const Cbarp = (C1p + C2p) / 2;
  let hbarp;
  if (C1p * C2p === 0) {
    hbarp = h1p + h2p;
  } else if (Math.abs(h1p - h2p) <= 180) {
    hbarp = (h1p + h2p) / 2;
  } else if (h1p + h2p < 360) {
    hbarp = (h1p + h2p + 360) / 2;
  } else {
    hbarp = (h1p + h2p - 360) / 2;
  }

  const T =
    1 -
    0.17 * Math.cos(rad(hbarp - 30)) +
    0.24 * Math.cos(rad(2 * hbarp)) +
    0.32 * Math.cos(rad(3 * hbarp + 6)) -
    0.2 * Math.cos(rad(4 * hbarp - 63));
  const dTheta = 30 * Math.exp(-(((hbarp - 275) / 25) ** 2));
  const Cbarp7 = Cbarp ** 7;
  const RC = 2 * Math.sqrt(Cbarp7 / (Cbarp7 + 25 ** 7));
  const SL = 1 + (0.015 * (Lbarp - 50) ** 2) / Math.sqrt(20 + (Lbarp - 50) ** 2);
  const SC = 1 + 0.045 * Cbarp;
  const SH = 1 + 0.015 * Cbarp * T;
  const RT = -Math.sin(rad(2 * dTheta)) * RC;

  return Math.sqrt(
    (dLp / SL) ** 2 +
      (dCp / SC) ** 2 +
      (dHp / SH) ** 2 +
      RT * (dCp / SC) * (dHp / SH),
  );
}

export function deltaE2000(ref, render) {
  if (ref.width !== render.width || ref.height !== render.height) {
    throw new Error('Delta-E requires equal image sizes');
  }
  const n = ref.width * ref.height;
  const values = new Float64Array(n);
  let sum = 0;
  let max = 0;
  let over2 = 0;
  let over5 = 0;
  let over10 = 0;
  for (let i = 0; i < n; i += 1) {
    const p = i * 4;
    const lab1 = labFromRgb(ref.data[p], ref.data[p + 1], ref.data[p + 2]);
    const lab2 = labFromRgb(render.data[p], render.data[p + 1], render.data[p + 2]);
    const dE = ciede2000(lab1, lab2);
    values[i] = dE;
    sum += dE;
    if (dE > max) max = dE;
    if (dE > 2) over2 += 1;
    if (dE > 5) over5 += 1;
    if (dE > 10) over10 += 1;
  }
  const sorted = Array.from(values).sort((a, b) => a - b);
  const percentile = (p) => sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * p))];
  return {
    mean: sum / n,
    median: percentile(0.5),
    p95: percentile(0.95),
    p99: percentile(0.99),
    max,
    percentOver2: (over2 / n) * 100,
    percentOver5: (over5 / n) * 100,
    percentOver10: (over10 / n) * 100,
    values,
  };
}

export function diffBoxes(ref, render, deltaEValues, options = {}) {
  const threshold = options.threshold ?? 5;
  const minArea = options.minArea ?? 16;
  const maxBoxes = options.maxBoxes ?? 20;
  const width = ref.width;
  const height = ref.height;
  const mask = new Uint8Array(width * height);
  for (let i = 0; i < mask.length; i += 1) mask[i] = deltaEValues[i] > threshold ? 1 : 0;

  const visited = new Uint8Array(width * height);
  const boxes = [];
  const queue = new Int32Array(width * height);
  for (let start = 0; start < mask.length; start += 1) {
    if (!mask[start] || visited[start]) continue;
    let head = 0;
    let tail = 0;
    queue[tail] = start;
    tail += 1;
    visited[start] = 1;
    let minX = width;
    let minY = height;
    let maxX = 0;
    let maxY = 0;
    let area = 0;
    while (head < tail) {
      const idx = queue[head];
      head += 1;
      const x = idx % width;
      const y = (idx - x) / width;
      area += 1;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      if (x > 0) {
        const ni = idx - 1;
        if (mask[ni] && !visited[ni]) {
          visited[ni] = 1;
          queue[tail] = ni;
          tail += 1;
        }
      }
      if (x < width - 1) {
        const ni = idx + 1;
        if (mask[ni] && !visited[ni]) {
          visited[ni] = 1;
          queue[tail] = ni;
          tail += 1;
        }
      }
      if (y > 0) {
        const ni = idx - width;
        if (mask[ni] && !visited[ni]) {
          visited[ni] = 1;
          queue[tail] = ni;
          tail += 1;
        }
      }
      if (y < height - 1) {
        const ni = idx + width;
        if (mask[ni] && !visited[ni]) {
          visited[ni] = 1;
          queue[tail] = ni;
          tail += 1;
        }
      }
    }
    if (area >= minArea) {
      boxes.push({
        x: minX,
        y: minY,
        width: maxX - minX + 1,
        height: maxY - minY + 1,
        area,
      });
    }
  }
  boxes.sort((a, b) => b.area - a.area);
  return boxes.slice(0, maxBoxes);
}

export function makeDiffImage(render, deltaEValues, scale = 2) {
  const width = render.width;
  const height = render.height;
  const out = new Uint8ClampedArray(width * height * 4);
  for (let i = 0; i < width * height; i += 1) {
    const p = i * 4;
    const gray = 0.2126 * render.data[p] + 0.7152 * render.data[p + 1] + 0.0722 * render.data[p + 2];
    const base = 255 - (255 - gray) * 0.22;
    const dE = deltaEValues[i];
    const alpha = clamp(dE / (10 * scale), 0, 1);
    out[p] = base * (1 - alpha) + 220 * alpha;
    out[p + 1] = base * (1 - alpha) + 30 * alpha;
    out[p + 2] = base * (1 - alpha) + 30 * alpha;
    out[p + 3] = 255;
  }
  return { width, height, data: out };
}
