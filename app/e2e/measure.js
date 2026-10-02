const { PNG } = require('pngjs');
const fs = require('fs');

exports.load = (p) => PNG.sync.read(fs.readFileSync(p));
exports.pixel = (png, x, y) => {
  const i = (png.width * y + x) * 4;
  return [png.data[i], png.data[i + 1], png.data[i + 2]];
};
/** Bounding box of pixels matching [pred], or null. */
exports.bbox = (png, pred, y0 = 0, y1 = png.height, x0 = 0, x1 = png.width) => {
  let minx = 1e9, miny = 1e9, maxx = -1, maxy = -1, n = 0;
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) {
    const [r, g, b] = exports.pixel(png, x, y);
    if (pred(r, g, b)) { n++; minx = Math.min(minx, x); miny = Math.min(miny, y); maxx = Math.max(maxx, x); maxy = Math.max(maxy, y); }
  }
  return n ? { x: minx, y: miny, w: maxx - minx + 1, h: maxy - miny + 1, n } : null;
};
const near = (r, g, b, t, tol) => Math.abs(r - t[0]) < tol && Math.abs(g - t[1]) < tol && Math.abs(b - t[2]) < tol;
exports.near = near;
/** Hull of the indigo corner dots (outside the bottom button area). */
exports.dots = (png) => exports.bbox(png, (r, g, b) => near(r, g, b, [63, 81, 181], 8), 0, 730);
exports.isWhite = (r, g, b) => r > 245 && g > 245 && b > 245;
