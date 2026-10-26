"""Anillos de prenda por envolvente convexa (la tela no se mete en las concavidades del cuerpo),
sisa de verdad (agujero elíptico en el tronco + manga que nace del borde) y pantalón por perneras."""
import numpy as np


def T_suave(x, a, b):
    t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)


def envolvente(p):
    """Envolvente convexa 2D (monotone chain), en sentido antihorario."""
    p = np.unique(np.round(p, 6), axis=0)
    if len(p) < 3: return p
    p = p[np.lexsort((p[:, 1], p[:, 0]))]
    def cruz(o, a, b): return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    inf, sup = [], []
    for q in p:
        while len(inf) >= 2 and cruz(inf[-2], inf[-1], q) <= 0: inf.pop()
        inf.append(q)
    for q in p[::-1]:
        while len(sup) >= 2 and cruz(sup[-2], sup[-1], q) <= 0: sup.pop()
        sup.append(q)
    return np.array(inf[:-1] + sup[:-1])


def radio_envolvente(h, c, th):
    """Radio desde c hasta la envolvente h en las direcciones th (ángulo 0 = +z, x = sin)."""
    d = np.stack([np.sin(th), np.cos(th)], 1)              # (na, 2) en (x, z)
    a = h - c; b = np.roll(h, -1, 0) - c                    # aristas
    e = b - a
    den = d[:, None, 0] * e[None, :, 1] - d[:, None, 1] * e[None, :, 0]
    t = (a[None, :, 0] * e[None, :, 1] - a[None, :, 1] * e[None, :, 0]) / np.where(np.abs(den) < 1e-12, 1e-12, den)
    s = (a[None, :, 0] * d[:, None, 1] - a[None, :, 1] * d[:, None, 0]) / np.where(np.abs(den) < 1e-12, 1e-12, den)
    ok = (s >= -1e-6) & (s <= 1 + 1e-6) & (t > 0)
    return np.where(ok, t, 0).max(1)


def perfil_tronco(M, sel, ys, na, holgura, dy=0.012, extra_pts=None):
    """R[y, ang] y cz por altura: envolvente convexa de cada banda, suavizada en y y sin pliegues bajo el pecho."""
    V = M.V; th = np.linspace(-np.pi, np.pi, na, endpoint=False)
    Rs, cz = [], []
    for y in ys:
        m = sel & (np.abs(V[:, 1] - y) < dy); p = V[m][:, [0, 2]]
        if extra_pts is not None: p = np.concatenate([p, extra_pts(y)]) if len(p) else extra_pts(y)
        if len(p) < 6:
            Rs.append(Rs[-1]); cz.append(cz[-1]); continue
        h = envolvente(p); c = np.array([0.0, (p[:, 1].max() + p[:, 1].min()) / 2])
        Rs.append(radio_envolvente(h, c, th)); cz.append(c[1])
    Rs = np.array(Rs); cz = np.array(cz)
    for _ in range(6): Rs[1:-1] = 0.25 * Rs[:-2] + 0.5 * Rs[1:-1] + 0.25 * Rs[2:]
    for _ in range(3): Rs = 0.25 * np.roll(Rs, 1, 1) + 0.5 * Rs + 0.25 * np.roll(Rs, -1, 1)
    cz = np.convolve(np.pad(cz, 4, mode='edge'), np.ones(9) / 9, 'valid')
    return Rs + holgura, cz


def caida(ys, Rs, desde):
    """De `desde` hacia abajo, máximo acumulado: la tela cae recta desde el pecho."""
    Rs = Rs.copy(); prev = None
    for i in np.argsort(-ys):
        if ys[i] < desde:
            if prev is not None: Rs[i] = np.maximum(Rs[i], prev * 0.994)
            prev = Rs[i].copy()
        elif ys[i] < desde + 0.05: prev = Rs[i].copy()
    for _ in range(3): Rs[1:-1] = 0.25 * Rs[:-2] + 0.5 * Rs[1:-1] + 0.25 * Rs[2:]
    return Rs


def radio(R, th):
    na = R.shape[-1]; f = (th + np.pi) / (2 * np.pi) * na
    i0 = np.floor(f).astype(int); t = f - i0
    return R[..., i0 % na] * (1 - t) + R[..., (i0 + 1) % na] * t


def rejilla_tronco(ys, Rs, cz, a0, nc):
    """Puntos (ny, nc, 3) de anillos abiertos por delante entre a0(y) y 2pi-a0(y); y su ángulo por columna."""
    F, TH = [], []
    for i, y in enumerate(ys):
        a = a0[i] if np.ndim(a0) else a0
        th = np.linspace(a, 2 * np.pi - a, nc); th = np.where(th > np.pi, th - 2 * np.pi, th)
        r = radio(Rs[i], th)
        F.append(np.stack([r * np.sin(th), np.full(nc, y), cz[i] + r * np.cos(th)], 1)); TH.append(th)
    return np.array(F), np.array(TH)


def sisas(M, ys, Rs, cz):
    """Elipse de sisa por lado en coordenadas (ángulo, y): centro, semiejes."""
    P = M.P; ytop = P['upperarm_l'][1] + 0.050; ybot = M.yaxila - 0.005
    yc = (ytop + ybot) / 2; ry = (ytop - ybot) / 2
    out = {}
    for lado in (1, -1):
        thc = lado * np.pi / 2; i = np.argmin(np.abs(ys - yc)); R = radio(Rs[i], np.array([thc]))[0]
        out[lado] = (thc, yc, 0.060 / R, ry, i)
    return out


def tri_rejilla_con_agujeros(F, TH, ys, cerrado, agujeros):
    ny, nc, _ = F.shape; tri = []
    cols = nc if cerrado else nc - 1
    for i in range(ny - 1):
        for j in range(cols):
            j2 = (j + 1) % nc
            yc_ = (ys[i] + ys[i + 1]) / 2; tc = (TH[i, j] + TH[i, j2]) / 2
            dentro = False
            for (thc, yc, rth, ry, _) in agujeros:
                dth = np.angle(np.exp(1j * (tc - thc)))
                if (dth / rth) ** 2 + ((yc_ - yc) / ry) ** 2 < 1: dentro = True
            if dentro: continue
            a = i * nc + j; b = i * nc + j2; c = a + nc; d = b + nc
            tri += [[a, c, b], [b, c, d]]
    return np.array(tri)


def manga_desde_sisa(M, lado, sisa, Rs, cz, ys, tubo, n_union=5, holg=0.004):
    """Primer anillo = borde de la sisa (algo mayor) sobre el tronco; se funde con el tubo del brazo."""
    thc, yc, rth, ry, _ = sisa; na = tubo.shape[1]
    phi = np.linspace(-np.pi, np.pi, na, endpoint=False)
    k = 1.12
    yy = yc + ry * k * np.sin(phi)
    dth = -lado * rth * k * np.cos(phi)
    th = thc + dth
    anillo = []
    for y, t in zip(yy, th):
        i = np.argmin(np.abs(ys - y)); r = radio(Rs[i], np.array([t]))[0] + holg
        anillo.append([r * np.sin(t), y, cz[i] + r * np.cos(t)])
    anillo = np.array(anillo)
    filas = [anillo]
    for s in np.linspace(0, 1, n_union + 2)[1:-1]:
        w = s * s * (3 - 2 * s); filas.append(anillo * (1 - w) + tubo[0] * w)
    return np.concatenate([np.array(filas), tubo], 0)


def perneras(M, lado, ys, na, holgura, recta_bajo):
    """Pernera por anillos de envolvente: por encima de la entrepierna incluye la costura central (x=0)."""
    V = M.V; th = np.linspace(-np.pi, np.pi, na, endpoint=False)
    sel = M.bv & (np.sign(V[:, 0]) == lado) & ((M.C.cab + M.brazo) < 0.5)
    F = []; Rk = None
    for y in ys[::-1]:
        m = sel & (np.abs(V[:, 1] - y) < 0.013); p = V[m][:, [0, 2]]
        if y > M.ycrotch:
            mm = M.bv & (np.abs(V[:, 1] - y) < 0.013) & (np.abs(V[:, 0]) < 0.03)
            zc = V[mm][:, 2] if mm.any() else p[:, 1]
            p = np.concatenate([p, [[0.0, zc.min()], [0.0, zc.max()]]])
        if len(p) < 6: F.append(F[-1]); continue
        h = envolvente(p); c = h.mean(0)
        R = radio_envolvente(h, c, th)
        for _ in range(3): R = 0.25 * np.roll(R, 1) + 0.5 * R + 0.25 * np.roll(R, -1)
        R = R + holgura
        if y < recta_bajo + 0.10:
            Rk = R if Rk is None else np.maximum(Rk * 0.996, R)
        if Rk is not None:
            w = T_suave(recta_bajo + 0.10 - y, 0.0, 0.14)
            R = R * (1 - w) + np.maximum(R, Rk) * w
        F.append(np.stack([c[0] + R * np.sin(th), np.full(na, y), c[1] + R * np.cos(th)], 1))
    F = np.array(F)[::-1].copy()
    for _ in range(4): F[1:-1, :, [0, 2]] = 0.25 * F[:-2, :, [0, 2]] + 0.5 * F[1:-1, :, [0, 2]] + 0.25 * F[2:, :, [0, 2]]
    if lado > 0: F[:, :, 0] = np.maximum(F[:, :, 0], 0.0)
    else: F[:, :, 0] = np.minimum(F[:, :, 0], 0.0)
    return F
