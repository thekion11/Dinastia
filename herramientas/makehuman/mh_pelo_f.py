"""Peinados largos/recogidos por geometría: media melena con capas y raya, coleta, moño."""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import mh_loft as L
import mh_tex as T
from mh_piezas import centro_cabeza


def _sel_cabeza(C):
    V = C.m['V']; s = np.zeros(len(V), bool); s[C.body_v] = True; return s & (C.head > 0.5)


def _perfil_cabeza(C, y, na, Rprev):
    V = C.m['V']; hc = centro_cabeza(C); sel = _sel_cabeza(C)
    m = sel & (np.abs(V[:, 1] - y) < 0.01); p = V[m]
    if len(p) < 6: return Rprev
    ang = np.arctan2(p[:, 0], p[:, 2] - hc[2]); r = np.hypot(p[:, 0], p[:, 2] - hc[2])
    b = ((ang + np.pi) / (2 * np.pi) * na).astype(int) % na
    R = np.zeros(na); np.maximum.at(R, b, r); return L.suav_circ(L._rellenar_circ(R), 4)


def textura_mechones(tam=512, largo=(20, 60), puntas=True, seed=3):
    rng = np.random.default_rng(seed)
    vet = Image.new('L', (tam, tam), 140); dr = ImageDraw.Draw(vet)
    for _ in range(12000):
        x = rng.uniform(0, tam); y = rng.uniform(-40, tam); Ln = rng.uniform(*largo)
        dr.line([(x, y), (x + rng.normal(0, 2.5), y + Ln)], fill=int(rng.uniform(60, 255)), width=1)
    lum = np.asarray(vet.filter(ImageFilter.GaussianBlur(0.6)), float)
    vv = np.linspace(0, 1, tam)[:, None]
    if puntas:
        pun = 0.78 + 0.2 * rng.random((1, tam)) ** 0.6
        pun = np.convolve(np.pad(pun[0], 3, mode='wrap'), np.ones(7) / 7, 'valid')[None]
        alfa = vv < pun
    else:
        alfa = np.ones((tam, tam), bool)
    return T.png(Image.fromarray(np.stack([lum, alfa * 255.0], 2).astype(np.uint8), 'LA'))


def _cerrar(F, hc):
    pos, tri, uv = L.malla_rejilla(F, False)
    n = np.cross(pos[tri[:, 1]] - pos[tri[:, 0]], pos[tri[:, 2]] - pos[tri[:, 0]])
    if np.sum(np.einsum('ij,ij->i', n, pos[tri].mean(1) - hc)) < 0: tri = tri[:, ::-1]
    return pos, tri, uv


def capa(C, ybot, hol0, hol1, raya=0.25, vol=0.010, frente_y=0.045, flare=0.05, na=72):
    """Una capa de melena: anillos desde la coronilla hasta ybot, abierta por delante bajo la frente.
    La abertura es asimétrica (raya al lado): un lado del flequillo baja más que el otro."""
    V = C.m['V']; ey = C.ey; hc = centro_cabeza(C); sel = _sel_cabeza(C)
    ytop = V[sel, 1].max(); ys = np.concatenate([[ytop + 0.012, ytop + 0.006], np.linspace(ytop - 0.004, ybot, 40)])
    F = []; R = _perfil_cabeza(C, ytop - 0.004, na, None); Rear = None
    for i, y in enumerate(ys):
        R = _perfil_cabeza(C, y, na, R)
        Rr = R * ({0: 0.02, 1: 0.55}.get(i, 1))
        if y < ey + 0.01:
            if Rear is None: Rear = R.copy()
            t = (ey + 0.01 - y) / max(ey + 0.01 - ybot, 1e-6)
            Rr = np.maximum(R, Rear * (1 + flare * t - 0.06 * t * t))
        alto = np.clip((y - ey) / (ytop - ey), 0, 1)
        hol = hol0 + (hol1 - hol0) * (1 - alto) + vol * np.sin(np.pi * np.clip(alto * 1.3, 0, 1))
        # abertura: lado izq. (x>0) abre a partir de frente_y, lado der. baja como flequillo ladeado
        aL = 0.95 * T.suave01(-(y - (ey + frente_y)), 0.0, 0.03)
        aR = 0.95 * T.suave01(-(y - (ey + frente_y - raya * 0.09)), 0.0, 0.03)
        th = np.linspace(aL, 2 * np.pi - aR, na + 1); th = np.where(th > np.pi, th - 2 * np.pi, th)
        r = L.radio(Rr + hol, th)
        F.append(np.stack([r * np.sin(th), np.full(na + 1, y), hc[2] + r * np.cos(th)], 1))
    pos, tri, uv = _cerrar(np.array(F), hc)
    return L.pieza(C, pos, tri, uv * [5, 1], sel=sel)


def unir_piezas(*pz):
    out = {k: [] for k in ('pos', 'nrm', 'tri', 'uv', 'joints', 'weights')}; mor = {}; o = 0
    for p in pz:
        for k in out: out[k].append(p[k] + (o if k == 'tri' else 0))
        for n, d in p['morfos'].items(): mor.setdefault(n, []).append(d)
        o += len(p['pos'])
    r = {k: np.concatenate(v) for k, v in out.items()}; r['morfos'] = {n: np.concatenate(v) for n, v in mor.items()}
    return r


def melena_capas(C):
    ey = C.ey
    interior = capa(C, ey - 0.085, 0.009, 0.012, raya=0.25, vol=0.006, flare=0.04)
    exterior = capa(C, ey - 0.045, 0.014, 0.020, raya=0.25, vol=0.010, flare=0.10)
    return unir_piezas(interior, exterior)


def _tubo_curva(C, pts, radios, na=16):
    """Tubo a lo largo de una polilínea (coleta)."""
    F = []
    for i, (p, r) in enumerate(zip(pts, radios)):
        t = pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]; t /= np.linalg.norm(t)
        a = np.cross(t, [1.0, 0, 0]); a /= np.linalg.norm(a); b = np.cross(t, a)
        th = np.linspace(0, 2 * np.pi, na + 1)
        F.append(p + r * (np.cos(th)[:, None] * a + np.sin(th)[:, None] * b))
    return np.array(F)


def coleta(C):
    hc = centro_cabeza(C); ey = C.ey; sel = _sel_cabeza(C)
    base = np.array([0, ey + 0.035, hc[2] - 0.095])
    s = np.linspace(0, 1, 18)
    pts = np.stack([np.zeros_like(s), base[1] - 0.20 * s ** 1.2, base[2] - 0.035 * np.sin(np.pi * s * 0.8) - 0.01 * s], 1)
    radios = 0.022 * (1 - 0.55 * s) + 0.006 * np.sin(np.pi * np.clip(s * 3, 0, 1))
    F = _tubo_curva(C, pts, radios)
    pos, tri, uv = L.malla_rejilla(F, False)
    pos_c = pos.mean(0)
    n = np.cross(pos[tri[:, 1]] - pos[tri[:, 0]], pos[tri[:, 2]] - pos[tri[:, 0]])
    cent = np.repeat(pts, F.shape[1], 0)[tri[:, 0]]
    if np.sum(np.einsum('ij,ij->i', n, pos[tri].mean(1) - cent)) < 0: tri = tri[:, ::-1]
    goma = _tubo_curva(C, pts[:2] + [[0, 0.004, 0.001], [0, -0.004, 0.0]], np.full(2, 0.016))
    pg, tg, ug = L.malla_rejilla(goma, False)
    return L.pieza(C, pos, tri, uv * [3, 1], sel=sel), L.pieza(C, pg, tg, ug, sel=sel)


def mono(C):
    hc = centro_cabeza(C); ey = C.ey; sel = _sel_cabeza(C)
    c = np.array([0, ey + 0.065, hc[2] - 0.085])
    nu, nv = 24, 14; u = np.linspace(0, 2 * np.pi, nu + 1); v = np.linspace(0.05, np.pi - 0.05, nv)
    U, Vv = np.meshgrid(u, v)
    r = 0.040 * (1 + 0.08 * np.sin(5 * U) * np.sin(Vv))
    x = r * np.sin(Vv) * np.cos(U) * 1.1; y = r * np.cos(Vv) * 0.85; z = r * np.sin(Vv) * np.sin(U) * 0.9
    F = np.stack([x, y, z], 2) + c
    pos, tri, uv = _cerrar(F, c)
    return L.pieza(C, pos, tri, uv * [3, 2], sel=sel)
