"""Rasterizado en espacio UV (interpolación baricéntrica de campos por vértice) y utilidades de textura."""
import io
import numpy as np
from PIL import Image

RNG = np.random.default_rng(11)


def raster(uv, tri, vals, tam):
    """uv (n,2) en convención glTF (v hacia abajo, u puede pasar de 1 -> se envuelve); vals (n,k).
    Devuelve (tam,tam,k) float y máscara de cobertura."""
    k = vals.shape[1]; out = np.zeros((tam, tam, k)); cov = np.zeros((tam, tam), bool)
    P = uv * tam - 0.5
    for t in tri:
        a, b, c = P[t]
        x0, x1 = int(np.floor(min(a[0], b[0], c[0]))), int(np.ceil(max(a[0], b[0], c[0])))
        y0, y1 = int(np.floor(min(a[1], b[1], c[1]))), int(np.ceil(max(a[1], b[1], c[1])))
        y0 = max(y0, 0); y1 = min(y1, tam - 1)
        if y1 < y0 or x1 < x0: continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        d = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(d) < 1e-12: continue
        l1 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / d
        l2 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / d
        l3 = 1 - l1 - l2
        e = -0.6 / max(abs(d) ** 0.5, 1e-6)
        m = (l1 >= e) & (l2 >= e) & (l3 >= e)
        if not m.any(): continue
        v = l1[m, None] * vals[t[0]] + l2[m, None] * vals[t[1]] + l3[m, None] * vals[t[2]]
        xm = xs[m] % tam; ym = ys[m]
        out[ym, xm] = v; cov[ym, xm] = True
    return rellenar(out, cov), cov


def rellenar(img, cov, it=12):
    """Extiende los bordes de las islas UV para que el filtrado no traiga el fondo."""
    img = img.copy(); cov = cov.copy()
    for _ in range(it):
        s = np.zeros_like(img); n = np.zeros(cov.shape)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            s += np.roll(np.roll(img * cov[..., None], dx, 1), dy, 0)
            n += np.roll(np.roll(cov, dx, 1), dy, 0)
        nuevo = (~cov) & (n > 0)
        img[nuevo] = s[nuevo] / n[nuevo, None]; cov |= nuevo
    return img


def ruido(tam, escala, amp):
    r = RNG.normal(0, 1, (max(2, tam // escala),) * 2)
    im = Image.fromarray(((r * 40) + 128).clip(0, 255).astype(np.uint8)).resize((tam, tam), Image.BICUBIC)
    return (np.asarray(im, float) - 128) / 40 * amp


def suave01(x, a, b):
    t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)


def jpg(a):
    b = io.BytesIO(); Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).save(b, 'JPEG', quality=88); return b.getvalue()


def png(img):
    b = io.BytesIO(); img.save(b, 'PNG', optimize=True); return b.getvalue()


def uv_esferico(p, centro, idx_tri):
    """UV esférica alrededor de la cabeza: u = acimut (costura detrás), v = ángulo desde arriba.
    Devuelve (uv por esquina (m,3,2))."""
    d = p - centro
    u = np.arctan2(d[:, 0], d[:, 2]) / (2 * np.pi) + 0.5
    v = np.arccos(np.clip(d[:, 1] / np.linalg.norm(d, axis=1), -1, 1)) / np.pi
    uc = u[idx_tri].copy(); vc = v[idx_tri]
    cruza = uc.max(1) - uc.min(1) > 0.5
    uc[cruza] = np.where(uc[cruza] < 0.5, uc[cruza] + 1, uc[cruza])
    return np.stack([uc, vc], 2)


def partir_esquinas(idx_tri, uvc):
    """Vértices únicos por (vértice, uv redondeada)."""
    claves = np.concatenate([idx_tri.reshape(-1, 1).astype(float), np.round(uvc.reshape(-1, 2), 5)], 1)
    u, inv = np.unique(claves, axis=0, return_inverse=True)
    return u[:, 0].astype(int), u[:, 1:], inv.reshape(-1, 3)
