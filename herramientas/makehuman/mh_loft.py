"""Prendas con geometría propia por «loft» de anillos medidos sobre el cuerpo (no desplazamiento del cuerpo).
Cada prenda se piel-a con los k vértices de cuerpo más cercanos (pesos y morphs promediados)."""
import numpy as np
from mh_base import normales


class Medidas:
    def __init__(self, C):
        self.C = C; m = C.m; V = m['V']; self.V = V; P = m['NPOS']; self.P = P
        bv = np.zeros(len(V), bool); bv[C.body_v] = True; self.bv = bv
        bi = m['bi']; W = m['W']
        self.brazo = sum(W[:, i] for nm, i in bi.items() if nm.split('_')[0] in
                         ('upperarm', 'lowerarm', 'hand', 'thumb', 'index', 'middle', 'ring', 'pinky'))
        self.yp = P['pelvis'][1]; self.yn = P['neck_01'][1]; self.ypie = P['foot_l'][1]
        self.xh = abs(P['upperarm_l'][0]); self.xm = abs(P['hand_l'][0])
        self.yaxila = P['upperarm_l'][1] - 0.07
        tronco = bv & (self.brazo < 0.5) & (C.head < 0.5)
        self.tronco = tronco
        piern = bv & ((C.muslo + C.gem) > 0.5)
        cr = V[bv & (np.abs(V[:, 0]) < 0.02) & (V[:, 1] < self.yp) & (V[:, 1] > 0.6)]
        self.ycrotch = cr[:, 1].min() if len(cr) else self.yp - 0.12
        self.piern = piern

    def perfil(self, sel, y, na, dy, centro_xz=None):
        """Radio máximo por ángulo (0 = frente +z) en la banda |y-yi|<dy. Devuelve (R[na], cz)."""
        V = self.V; m = sel & (np.abs(V[:, 1] - y) < dy)
        p = V[m]
        if len(p) < 6: return None, None
        cx, cz = (0.0, (p[:, 2].max() + p[:, 2].min()) / 2) if centro_xz is None else centro_xz
        ang = np.arctan2(p[:, 0] - cx, p[:, 2] - cz); r = np.hypot(p[:, 0] - cx, p[:, 2] - cz)
        b = ((ang + np.pi) / (2 * np.pi) * na).astype(int) % na
        R = np.zeros(na); np.maximum.at(R, b, r)
        R = _rellenar_circ(R)
        return R, (cx, cz)


def _rellenar_circ(R):
    n = len(R); ok = R > 0
    if ok.all(): return R
    idx = np.nonzero(ok)[0]
    x = np.arange(n); xp = np.concatenate([idx - n, idx, idx + n]); fp = np.tile(R[idx], 3)
    return np.interp(x, xp, fp)


def suav_circ(R, it=2):
    for _ in range(it): R = 0.25 * np.roll(R, 1, -1) + 0.5 * R + 0.25 * np.roll(R, -1, -1)
    return R


def radio(R, th):
    """Interpola R (na bins, ángulo -pi..pi) en ángulos th."""
    na = R.shape[-1]; f = (th + np.pi) / (2 * np.pi) * na - 0.5
    i0 = np.floor(f).astype(int); t = f - i0
    return R[..., i0 % na] * (1 - t) + R[..., (i0 + 1) % na] * t


def malla_rejilla(Pr, cerrado):
    """Pr (ny, nc, 3) -> pos, tri, uv."""
    ny, nc, _ = Pr.shape; pos = Pr.reshape(-1, 3)
    cols = nc if cerrado else nc - 1; tri = []
    for i in range(ny - 1):
        for j in range(cols):
            a = i * nc + j; b = i * nc + (j + 1) % nc; c = a + nc; d = b + nc
            tri += [[a, c, b], [b, c, d]]
    uu, vv = np.meshgrid(np.linspace(0, 1, nc), np.linspace(0, 1, ny))
    return pos, np.array(tri), np.stack([uu.reshape(-1), vv.reshape(-1)], 1)


def unir(*partes):
    P, T, U = [], [], []; o = 0
    for p, t, u in partes:
        P.append(p); T.append(t + o); U.append(u); o += len(p)
    return np.concatenate(P), np.concatenate(T), np.concatenate(U)


def anillos_tronco(M, sel, ys, na, holgura, cae_bajo=None, extra=None):
    """Perfiles R[y, ang] y centro z por altura, suavizados, con caída bajo `cae_bajo` (y)."""
    Rs, cz = [], []
    for y in ys:
        R, c = M.perfil(sel, y, na, 0.012)
        if R is None: R, c = Rs[-1].copy(), (0, cz[-1])
        Rs.append(R); cz.append(c[1])
    cz = list(np.convolve(np.pad(cz, 4, mode='edge'), np.ones(9) / 9, 'valid'))
    Rs = np.array(Rs); cz = np.array(cz)
    for _ in range(10): Rs[1:-1] = 0.25 * Rs[:-2] + 0.5 * Rs[1:-1] + 0.25 * Rs[2:]
    Rs = suav_circ(Rs, 6) + holgura
    if cae_bajo is not None:
        # caída: desde el pecho hacia abajo la tela no se mete (máximo acumulado, sin pliegue bajo el pectoral)
        orden = np.argsort(-ys); prev = None
        for i in orden:
            if ys[i] < cae_bajo + 0.06:
                if prev is not None: Rs[i] = np.maximum(Rs[i], prev * 0.993)
                prev = Rs[i].copy()
        for _ in range(4): Rs[1:-1] = 0.25 * Rs[:-2] + 0.5 * Rs[1:-1] + 0.25 * Rs[2:]
    if extra is not None: Rs = extra(ys, Rs)
    return Rs, cz


def loft_tronco(ys, Rs, cz, a0):
    """Anillos abiertos por delante: el ángulo de cada anillo va de a0(y) a 2pi-a0(y) (0 = frente)."""
    nc = Rs.shape[1] + 1; filas = []
    for i, y in enumerate(ys):
        a = a0[i] if np.ndim(a0) else a0
        th = np.linspace(a, 2 * np.pi - a, nc); th = np.where(th > np.pi, th - 2 * np.pi, th)
        r = radio(Rs[i], th)
        filas.append(np.stack([r * np.sin(th), np.full(nc, y), cz[i] + r * np.cos(th)], 1))
    return np.array(filas)


def tubo_x(M, lado, x0, x1, n, na, holgura, rmin=None):
    """Manga a lo largo de x (brazos en T): anillos en el plano yz alrededor del centro del brazo."""
    V = M.V; sel = M.bv & (M.brazo > 0.4) & (np.sign(V[:, 0]) == lado)
    filas = []
    for i, x in enumerate(np.linspace(x0, x1, n)):
        m = sel & (np.abs(np.abs(V[:, 0]) - x) < 0.015); p = V[m]
        if len(p) < 6: p = prev
        prev = p
        cy, czz = (p[:, 1].max() + p[:, 1].min()) / 2, (p[:, 2].max() + p[:, 2].min()) / 2
        ang = np.arctan2(p[:, 1] - cy, p[:, 2] - czz); r = np.hypot(p[:, 1] - cy, p[:, 2] - czz)
        b = ((ang + np.pi) / (2 * np.pi) * na).astype(int) % na
        R = np.zeros(na); np.maximum.at(R, b, r); R = suav_circ(_rellenar_circ(R), 3) + holgura
        if rmin is not None: R = np.maximum(R, rmin(i / (n - 1)))
        if i < n * 0.3: R = np.minimum(R, 0.058 + holgura)
        th = np.linspace(-np.pi, np.pi, na, endpoint=False); r = radio(R, th)
        filas.append(np.stack([np.full(na, lado * x), cy + r * np.sin(th), czz + r * np.cos(th)], 1))
    F = np.array(filas)
    for _ in range(3): F[1:-1, :, 1:] = 0.25 * F[:-2, :, 1:] + 0.5 * F[1:-1, :, 1:] + 0.25 * F[2:, :, 1:]
    return F


def pierna(M, lado, y0, y1, n, na, holgura, recta_bajo):
    V = M.V; sel = (M.piern | (M.bv & (M.C.pie > 0.2) & (V[:, 1] > M.ypie))) & (np.sign(V[:, 0]) == lado)
    filas = []; ys = np.linspace(y1, y0, n); Rk = None
    for y in ys:
        m = sel & (np.abs(V[:, 1] - y) < 0.015); p = V[m]
        if len(p) < 6: p = prev
        prev = p
        cx, czz = (p[:, 0].max() + p[:, 0].min()) / 2, (p[:, 2].max() + p[:, 2].min()) / 2
        R, _ = M.perfil(sel, y, na, 0.015, (cx, czz))
        R = Rprev if R is None else suav_circ(R, 3) + holgura
        Rprev = R
        if y < recta_bajo:
            if Rk is None: Rk = R.copy()
            R = np.maximum(R, Rk * 0.97); Rk = np.maximum(Rk * 0.995, R * 0)
            R = np.maximum(R, Rk * 0.97)
        th = np.linspace(-np.pi, np.pi, na, endpoint=False); r = radio(R, th)
        filas.append(np.stack([cx + r * np.sin(th), np.full(na, y), czz + r * np.cos(th)], 1))
    F = np.array(filas)[::-1].copy()
    for _ in range(3): F[1:-1, :, [0, 2]] = 0.25 * F[:-2, :, [0, 2]] + 0.5 * F[1:-1, :, [0, 2]] + 0.25 * F[2:, :, [0, 2]]
    return F


def disco(c, n_dir, r, h=0.002, k=10):
    n_dir = n_dir / np.linalg.norm(n_dir); a = np.cross(n_dir, [0, 1, 0])
    if np.linalg.norm(a) < 1e-6: a = np.array([1.0, 0, 0])
    a /= np.linalg.norm(a); b = np.cross(n_dir, a)
    th = np.linspace(0, 2 * np.pi, k, endpoint=False)
    anillo = c + r * (np.cos(th)[:, None] * a + np.sin(th)[:, None] * b)
    P = np.concatenate([anillo, anillo + n_dir * h, [c + n_dir * h]])
    T = []
    for j in range(k):
        j2 = (j + 1) % k; T += [[j, j2, k + j], [j2, k + j2, k + j], [k + j, k + j2, 2 * k]]
    return P, np.array(T), np.zeros((len(P), 2))


# ---------------- piel-ado ----------------
def vecinos(C, Q, k=6, sel=None):
    V = C.m['V']; base = C.body_v if sel is None else np.nonzero(sel)[0]; B = V[base]
    idx = np.zeros((len(Q), k), int); dist = np.zeros((len(Q), k))
    for s in range(0, len(Q), 1500):
        d = np.sum((Q[s:s + 1500, None, :] - B[None]) ** 2, 2)
        i = np.argpartition(d, k, 1)[:, :k]; idx[s:s + 1500] = base[i]
        dist[s:s + 1500] = np.sqrt(np.take_along_axis(d, i, 1))
    return idx, dist


def pieza(C, pos, tri, uv, sel=None, k=6, mezcla=None):
    idx, d = vecinos(C, pos, k, sel); w = 1 / (d + 0.004); w /= w.sum(1, keepdims=True)
    W = np.einsum('vk,vkb->vb', w, C.m['W'][idx])
    if mezcla is not None: W = mezcla(pos, W)
    top = np.argsort(-W, axis=1)[:, :4]; tw = np.take_along_axis(W, top, 1); tw /= tw.sum(1, keepdims=True)
    morf = {n: np.einsum('vk,vkc->vc', w, dd[idx]) for n, dd in C.m['morfos'].items()}
    for d_ in morf.values(): d_[np.abs(d_).max(1) < 2e-4] = 0
    return {'pos': pos, 'nrm': normales(pos, tri), 'tri': tri, 'uv': uv, 'joints': top, 'weights': tw, 'morfos': morf}
