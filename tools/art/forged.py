import math
import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "Media", "Art")
SS = 4
GOLD_DARK = np.array([0.30, 0.18, 0.05])
GOLD_MID = np.array([0.80, 0.60, 0.24])
GOLD_LIGHT = np.array([1.00, 0.92, 0.62])
IRON_DARK = np.array([0.08, 0.075, 0.07])
IRON_LIGHT = np.array([0.42, 0.40, 0.37])


def blur(arr, radius):
    img = Image.fromarray(np.clip(arr * 255, 0, 255).astype(np.uint8), "L")
    return np.asarray(img.filter(ImageFilter.GaussianBlur(radius)), dtype=np.float32) / 255.0


def light(height, strength=4.0):
    gy, gx = np.gradient(height)
    nx, ny, nz = -gx * strength, -gy * strength, np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    nx, ny, nz = nx / length, ny / length, nz / length
    lx, ly, lz = -0.55, -0.65, 0.52
    ll = math.sqrt(lx * lx + ly * ly + lz * lz)
    diffuse = np.clip((nx * lx + ny * ly + nz * lz) / ll, 0, 1)
    hx, hy, hz = lx / ll, ly / ll, lz / ll + 1
    hl = math.sqrt(hx * hx + hy * hy + hz * hz)
    spec = np.clip((nx * hx + ny * hy + nz * hz) / hl, 0, 1) ** 24
    return diffuse, spec


def metal(height, mask, dark, mid, bright, strength=4.0, spec_amount=0.8):
    grain = np.random.default_rng(1).random(height.shape).astype(np.float32)
    height = height + blur(grain, 0.6) * 0.004
    diffuse, spec = light(height * 2.2, strength)
    t = diffuse[..., None]
    color = np.where(t < 0.5, dark + (mid - dark) * (t / 0.5), mid + (bright - mid) * ((t - 0.5) / 0.5))
    color = color + spec[..., None] * spec_amount
    rgba = np.zeros(height.shape + (4,), dtype=np.float32)
    rgba[..., :3] = np.clip(color, 0, 1)
    rgba[..., 3] = mask
    return rgba


def save(rgba, name, size):
    img = Image.fromarray(np.clip(rgba * 255, 0, 255).astype(np.uint8), "RGBA")
    if img.size != size:
        img = img.resize(size, Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print("wrote", name, size)


def mask_from(draw_fn, w, h):
    img = Image.new("L", (w, h), 0)
    draw_fn(ImageDraw.Draw(img), w, h)
    return np.asarray(img, dtype=np.float32) / 255.0


def tile_noise(size, freqs, seed):
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:size, 0:size] / size * 2 * math.pi
    out = np.zeros((size, size), dtype=np.float32)
    for f, amp in freqs:
        for _ in range(4):
            fx, fy = rng.integers(-f, f + 1, size=2)
            phase = rng.random() * 2 * math.pi
            out += amp * np.sin(fx * x + fy * y + phase)
    out -= out.min()
    return out / max(out.max(), 1e-6)


def stone_tile():
    n = 256
    base = tile_noise(n, [(2, 1.0), (5, 0.5), (11, 0.25), (23, 0.12)], 3)
    grain = np.random.default_rng(9).random((n, n)).astype(np.float32)
    grain = blur(grain, 0.8)
    seams = np.zeros((n, n), dtype=np.float32)
    row_h = 64
    for r in range(n // row_h):
        y0 = r * row_h
        seams[y0:y0 + 2, :] = 1
        offset = 0 if r % 2 == 0 else 64
        for c in range(0, n, 128):
            x = (c + offset) % n
            seams[y0:y0 + row_h, x:x + 2] = 1
    seams = blur(seams, 1.2)
    height = base * 0.5 + grain * 0.25 - seams * 0.9
    diffuse, _ = light(height, 6.0)
    tone = 0.55 + 0.45 * diffuse
    stone = np.array([0.20, 0.185, 0.165])
    color = stone[None, None, :] * tone[..., None] * (0.85 + base[..., None] * 0.3)
    color *= (1 - seams[..., None] * 0.55)
    rgba = np.ones((n, n, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(color, 0, 1)
    save(rgba, "forged_stone.tga", (n, n))


def bevel_band(mask, width):
    h = (blur(mask, width * 0.35) + blur(mask, width * 0.8) + blur(mask, width * 1.6)) / 3.0
    return h * mask


def finish(rgba, mask, edge=0.55):
    rim = np.clip(mask - blur(mask, 0.9 * SS), 0, 1)
    rgba[..., :3] *= (1 - rim[..., None] * edge)
    return rgba


def frame_gold():
    n = 128 * SS
    margin = 32 * SS
    band = 7 * SS
    boss = 22 * SS

    def draw(d, w, h):
        d.rectangle([0, 0, w - 1, h - 1], fill=255)
        d.rectangle([band, band, w - 1 - band, h - 1 - band], fill=0)
        for cx, cy in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
            sx = 1 if cx == 0 else -1
            sy = 1 if cy == 0 else -1
            x0, x1 = sorted([cx, cx + sx * boss])
            y0, y1 = sorted([cy, cy + sy * boss])
            d.rounded_rectangle([x0, y0, x1, y1], radius=4 * SS, fill=255)
            for k in range(3):
                t = (boss + 4 * SS + k * 3 * SS)
                r = (3 - k) * SS + SS
                d.ellipse([cx + sx * t - r, cy + sy * (band // 2) - r, cx + sx * t + r, cy + sy * (band // 2) + r], fill=255)
                d.ellipse([cx + sx * (band // 2) - r, cy + sy * t - r, cx + sx * (band // 2) + r, cy + sy * t + r], fill=255)
    mask = mask_from(draw, n, n)
    groove = mask_from(lambda d, w, h: d.rectangle([band // 2, band // 2, w - 1 - band // 2, h - 1 - band // 2], outline=255, width=max(1, SS // 2)), n, n)
    def gems(d, w, h):
        for cx, cy in [(boss // 2, boss // 2), (w - 1 - boss // 2, boss // 2), (boss // 2, h - 1 - boss // 2), (w - 1 - boss // 2, h - 1 - boss // 2)]:
            r = 6 * SS
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    gem = mask_from(gems, n, n)
    setting = mask_from(lambda d, w, h: [d.ellipse([cx - 8 * SS, cy - 8 * SS, cx + 8 * SS, cy + 8 * SS], outline=255, width=SS) for cx, cy in [(boss // 2, boss // 2), (w - 1 - boss // 2, boss // 2), (boss // 2, h - 1 - boss // 2), (w - 1 - boss // 2, h - 1 - boss // 2)]], n, n)
    height = bevel_band(mask, 4 * SS) - groove * 0.25 * mask + setting * 0.15
    rgba = metal(height, mask, GOLD_DARK, GOLD_MID, GOLD_LIGHT, strength=7.0)
    rgba = finish(rgba, mask)
    gem_color = np.array([0.62, 0.05, 0.07])
    gd, gs = light(bevel_band(gem, 3 * SS) * 2.5, 9.0)
    gem_rgb = gem_color * (0.25 + 0.95 * gd[..., None]) + gs[..., None] * 1.0
    rgba[..., :3] = np.where(gem[..., None] > 0.5, np.clip(gem_rgb, 0, 1), rgba[..., :3])
    shadow = blur(mask, 3 * SS) * (1 - mask)
    rgba[..., 3] = np.clip(mask + shadow * 0.7, 0, 1)
    rgba[..., :3] = np.where((mask < 0.5)[..., None], 0, rgba[..., :3])
    save(rgba, "forged_frame.tga", (128, 128))
    print("frame slice margin", margin // SS)


def slot_bezel():
    n = 64 * SS
    outer = 3 * SS
    ring = 6 * SS

    def draw(d, w, h):
        d.rounded_rectangle([0, 0, w - 1, h - 1], radius=6 * SS, fill=255)
        d.rectangle([ring, ring, w - 1 - ring, h - 1 - ring], fill=0)
    mask = mask_from(draw, n, n)
    lip = mask_from(lambda d, w, h: d.rectangle([ring - 2 * SS, ring - 2 * SS, w - ring + 2 * SS, h - ring + 2 * SS], outline=255, width=2 * SS), n, n)
    rivets = mask_from(lambda d, w, h: [d.ellipse([cx - 2 * SS, cy - 2 * SS, cx + 2 * SS, cy + 2 * SS], fill=255) for cx, cy in [(outer + SS, outer + SS), (w - outer - SS, outer + SS), (outer + SS, h - outer - SS), (w - outer - SS, h - outer - SS)]], n, n)
    height = bevel_band(mask, 3 * SS) + rivets * 0.3
    iron = finish(metal(height, mask, IRON_DARK, np.array([0.22, 0.21, 0.19]), IRON_LIGHT, strength=7.0, spec_amount=0.5), mask)
    gold = finish(metal(bevel_band(lip, SS), lip, GOLD_DARK, GOLD_MID, GOLD_LIGHT, strength=7.0), lip, 0.3)
    riv = finish(metal(bevel_band(rivets, 1.5 * SS), rivets, GOLD_DARK, GOLD_MID, GOLD_LIGHT, strength=7.0), rivets, 0.4)
    rgba = iron.copy()
    for layer in (gold, riv):
        a = layer[..., 3:4]
        rgba[..., :3] = rgba[..., :3] * (1 - a) + layer[..., :3] * a
        rgba[..., 3] = np.maximum(rgba[..., 3], layer[..., 3])
    save(rgba, "forged_bezel.tga", (64, 64))


def plaque():
    w, h = 128 * SS, 64 * SS
    rim = 4 * SS

    def draw(d, ww, hh):
        d.rounded_rectangle([0, 0, ww - 1, hh - 1], radius=8 * SS, fill=255)
    outer = mask_from(draw, w, h)
    inner = mask_from(lambda d, ww, hh: d.rounded_rectangle([rim, rim, ww - 1 - rim, hh - 1 - rim], radius=5 * SS, fill=255), w, h)
    rim_mask = np.clip(outer - inner, 0, 1)
    gold = finish(metal(bevel_band(rim_mask, 2 * SS), rim_mask, GOLD_DARK, GOLD_MID, GOLD_LIGHT, strength=7.0), rim_mask)
    stone = tile_noise(w, [(3, 1.0), (9, 0.4)], 5)[:h, :w]
    inset_shade = blur(1 - inner, 4 * SS)
    tone = 0.75 + stone * 0.25 - inset_shade * 0.5
    base = np.array([0.15, 0.13, 0.11])
    face = np.zeros((h, w, 4), dtype=np.float32)
    face[..., :3] = np.clip(base * tone[..., None], 0, 1)
    face[..., 3] = inner
    rgba = face.copy()
    a = gold[..., 3:4]
    rgba[..., :3] = rgba[..., :3] * (1 - a) + gold[..., :3] * a
    rgba[..., 3] = np.maximum(face[..., 3], gold[..., 3])
    save(rgba, "forged_plaque.tga", (128, 64))


def ring():
    n = 64 * SS
    outer = mask_from(lambda d, w, h: d.ellipse([0, 0, w - 1, h - 1], fill=255), n, n)
    inner = mask_from(lambda d, w, h: d.ellipse([7 * SS, 7 * SS, w - 1 - 7 * SS, h - 1 - 7 * SS], fill=255), n, n)
    band = np.clip(outer - inner, 0, 1)
    groove = mask_from(lambda d, w, h: d.ellipse([3 * SS, 3 * SS, w - 1 - 3 * SS, h - 1 - 3 * SS], outline=255, width=SS), n, n)
    height = bevel_band(band, 3 * SS) - groove * 0.2 * band
    rgba = finish(metal(height, band, GOLD_DARK, GOLD_MID, GOLD_LIGHT, strength=7.0), band)
    save(rgba, "forged_ring.tga", (64, 64))


def divider():
    w, h = 256 * SS, 16 * SS

    def draw(d, ww, hh):
        cy = hh // 2
        d.polygon([(0, cy), (ww // 2 - 12 * SS, cy - SS), (ww // 2 - 12 * SS, cy + SS)], fill=255)
        d.polygon([(ww, cy), (ww // 2 + 12 * SS, cy - SS), (ww // 2 + 12 * SS, cy + SS)], fill=255)
        d.polygon([(ww // 2, cy - 7 * SS), (ww // 2 + 9 * SS, cy), (ww // 2, cy + 7 * SS), (ww // 2 - 9 * SS, cy)], fill=255)
        for s in (-1, 1):
            x = ww // 2 + s * 16 * SS
            d.ellipse([x - 2 * SS, cy - 2 * SS, x + 2 * SS, cy + 2 * SS], fill=255)
    mask = mask_from(draw, w, h)
    rgba = finish(metal(bevel_band(mask, 2 * SS), mask, GOLD_DARK, GOLD_MID, GOLD_LIGHT, strength=7.0), mask, 0.3)
    save(rgba, "forged_divider.tga", (256, 16))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    stone_tile()
    frame_gold()
    slot_bezel()
    plaque()
    ring()
    divider()
