"""Traje (chaqueta abierta con solapas, camisa con cuello, corbata, pantalón, zapatos), abrigo largo y polo."""
import numpy as np
import mh_loft as L

NA = 64


def _orientar(pos, tri, centro):
    n = np.cross(pos[tri[:, 1]] - pos[tri[:, 0]], pos[tri[:, 2]] - pos[tri[:, 0]])
    c = pos[tri].mean(1) - centro
    if np.sum(np.einsum('ij,ij->i', n, c)) < 0: tri = tri[:, ::-1]
    return tri


def _rejilla(F, cerrado, centro_fn):
    pos, tri, uv = L.malla_rejilla(F, cerrado)
    return pos, _orientar(pos, tri, centro_fn(pos)), uv


def _cent_tronco(pos): return np.array([0, pos[:, 1].mean(), pos[:, 2].mean()])


def _ab_frente(ys, y_b, y_vt, abajo, v_top, v_bot=0.10):
    a = np.where(ys >= y_b, v_bot + (v_top - v_bot) * np.clip((ys - y_b) / (y_vt - y_b), 0, 1),
                 v_bot + (abajo - v_bot) * np.clip((y_b - ys) / max(y_b - ys.min(), 1e-6), 0, 1))
    return a


def cuello_r(M):
    R, c = M.perfil(M.bv & (M.C.cab > 0.5) & (M.C.head < 0.6), M.yn + 0.01, NA, 0.012)
    return L.suav_circ(R, 4), c[1]


def solapas(ys, Rs, cz, a0, y_b, y_vt, ancho_max, relieve=0.005):
    """Tiras de solapa a ambos lados de la abertura, apoyadas sobre la chaqueta con relieve."""
    partes = []
    sel = (ys >= y_b - 0.005) & (ys <= y_vt + 0.015)
    yy = ys[sel]; RR = Rs[sel]; cc = cz[sel]; aa = a0[sel]
    s = np.clip((yy - y_b) / (y_vt - y_b), 0, 1)
    w = 0.018 + (ancho_max - 0.018) * np.clip(s / 0.75, 0, 1)
    w = np.where(s > 0.82, w * (1 - (s - 0.82) / 0.18 * 0.55), w)
    for lado in (1, -1):
        filas = []
        for i in range(len(yy)):
            th0 = aa[i]; r0 = L.radio(RR[i], np.array([th0]))[0]
            th1 = th0 + w[i] / r0
            ths = np.linspace(th0, th1, 5)
            r = L.radio(RR[i], ths) + np.array([0.0015, relieve, relieve * 1.1, relieve, 0.0008])
            filas.append(np.stack([lado * r * np.sin(ths), np.full(5, yy[i]), cc[i] + r * np.cos(ths)], 1))
        F = np.array(filas)
        partes.append(_rejilla(F, False, _cent_tronco))
    return L.unir(*partes)


def camisa(M, abierta=False):
    yn = M.yn; ys = np.linspace(M.yp - 0.06, yn + 0.004, 40)
    Rs, cz = L.anillos_tronco(M, M.tronco, ys, NA, 0.005)
    cuerpo = _rejilla(L.loft_tronco(ys, Rs, cz, 0.0), True, _cent_tronco)
    Rn, czn = cuello_r(M)
    yc = np.linspace(yn + 0.004, yn + (0.035 if not abierta else 0.02), 5)
    abre = 0.16 if not abierta else 0.55
    F = []
    for i, y in enumerate(yc):
        th = np.linspace(abre, 2 * np.pi - abre, NA + 1); th = np.where(th > np.pi, th - 2 * np.pi, th)
        r = L.radio(Rn, th) + 0.007 + 0.004 * i / 4
        F.append(np.stack([r * np.sin(th), np.full(len(th), y), czn + r * np.cos(th)], 1))
    cuello = _rejilla(np.array(F), False, _cent_tronco)
    puntas = []
    for lado in (1, -1):
        r0 = L.radio(Rn, np.array([abre]))[0] + 0.011
        top = np.array([lado * r0 * np.sin(abre), yc[-1], czn + r0 * np.cos(abre)])
        atr = np.array([lado * (r0 + 0.004) * np.sin(abre + 0.6), yc[-1], czn + (r0 + 0.004) * np.cos(abre + 0.6)])
        Rf = L.radio(Rs[-6], np.array([0.38]))[0] + 0.004
        pun = np.array([lado * Rf * np.sin(0.38), yn - 0.035, cz[-6] + Rf * np.cos(0.38)])
        P = np.array([top, atr, pun]); puntas.append((P, np.array([[0, 1, 2]] if lado > 0 else [[0, 2, 1]]), np.zeros((3, 2))))
    return {'Camisa': L.unir(cuerpo, cuello, *puntas)}, (ys, Rs, cz)


def corbata(M, ys, Rs, cz, y_fin):
    yn = M.yn; filas = []
    yy = np.linspace(yn - 0.012, y_fin, 26)
    for y in yy:
        i = np.argmin(np.abs(ys - y)); R0 = L.radio(Rs[i], np.array([0.0]))[0]
        t = (yn - 0.012 - y) / (yn - 0.012 - y_fin); hw = 0.011 + 0.030 * min(t * 1.6, 1)
        if t > 0.96: hw *= (1 - t) / 0.04 * 0.9 + 0.1
        xs = np.array([-hw, -hw * 0.5, 0, hw * 0.5, hw]); bulto = np.array([0, 0.0022, 0.003, 0.0022, 0])
        z = cz[i] + R0 + 0.004 + bulto
        filas.append(np.stack([xs, np.full(5, y), z], 1))
    hoja = _rejilla(np.array(filas), False, lambda p: p.mean(0) - [0, 0, 0.05])
    Rn, czn = cuello_r(M); r = L.radio(Rn, np.array([0.0]))[0] + 0.012
    nudo = []
    for k, y in enumerate(np.linspace(yn - 0.016, yn + 0.022, 6)):
        hw = 0.012 + 0.006 * np.sin(np.pi * k / 5)
        th = np.linspace(-np.pi * 0.5, np.pi * 0.5, 9)
        nudo.append(np.stack([hw * np.sin(th), np.full(9, y), czn + r - 0.006 + 0.012 * np.cos(th)], 1))
    nudo = _rejilla(np.array(nudo), False, lambda p: p.mean(0) - [0, 0, 0.05])
    return {'Corbata': L.unir(hoja, nudo)}


def chaqueta(M, largo='chaqueta', color_solapa=True):
    """largo 'chaqueta' (bajo a media cadera) o 'abrigo' (hasta la rodilla)."""
    yn = M.yn; y_b = yn - (0.27 if largo == 'chaqueta' else 0.22); y_vt = yn - 0.035
    hem = M.yp - 0.15 if largo == 'chaqueta' else 0.52
    hol = 0.016 if largo == 'chaqueta' else 0.034
    ys = np.linspace(hem, yn - 0.002, 70)
    sel = M.tronco | (M.piern if largo == 'abrigo' else False)
    y_pecho = M.yaxila - 0.02

    def hombros(ys, Rs):
        th = np.linspace(-np.pi, np.pi, NA, endpoint=False)
        g = np.exp(-((np.abs(th) - np.pi / 2) ** 2) / 0.12)[None] * np.exp(-((ys - (M.yaxila + 0.05)) ** 2) / 0.002)[:, None]
        return Rs + 0.006 * g
    Rs, cz = L.anillos_tronco(M, sel, ys, NA, hol, cae_bajo=y_pecho, extra=hombros)
    if largo == 'abrigo':
        for i, y in enumerate(ys):
            if y < M.ycrotch: Rs[i] += 0.03 * (M.ycrotch - y) / (M.ycrotch - hem)
    a0 = _ab_frente(ys, y_b, y_vt, 0.28 if largo == 'chaqueta' else 0.10, 0.62)
    F = L.loft_tronco(ys, Rs, cz, a0)
    cuerpo = _rejilla(F, False, _cent_tronco)
    # grosor del bajo y del borde delantero (vista desde abajo)
    canto = []
    for fila_i in (0,):
        f = F[fila_i]; c = np.array([0, f[:, 1].mean(), cz[fila_i]])
        dentro = c + (f - c) * 0.975
        canto.append(_rejilla(np.stack([f, dentro]), False, lambda p: p.mean(0)))
    sol = solapas(ys, Rs, cz, a0, y_b, y_vt, 0.075 if largo == 'chaqueta' else 0.09)
    Rn, czn = cuello_r(M)
    yc = np.linspace(yn - 0.004, yn + (0.03 if largo == 'chaqueta' else 0.055), 5)
    Fc = []
    for i, y in enumerate(yc):
        abre = 0.62 + 0.3 * i / 4
        th = np.linspace(abre, 2 * np.pi - abre, NA + 1); th = np.where(th > np.pi, th - 2 * np.pi, th)
        r = L.radio(Rn, th) + 0.018 + 0.006 * i / 4 + (0.012 if largo == 'abrigo' else 0)
        Fc.append(np.stack([r * np.sin(th), np.full(len(th), y), czn + r * np.cos(th)], 1))
    cuello = _rejilla(np.array(Fc), False, _cent_tronco)
    hol_m = 0.014 if largo == 'chaqueta' else 0.03
    mangas = []
    for lado in (1, -1):
        Fm = L.tubo_x(M, lado, M.xh - 0.012, M.xm - 0.035, 28, 32, hol_m,
                      rmin=lambda t: (0.050 - 0.008 * t) + (0.012 if largo == 'abrigo' else 0))
        mangas.append(_rejilla(Fm, True, lambda p: np.array([p[:, 0].mean(), p[:, 1].mean(), p[:, 2].mean()])))
    botones = []
    for k, yb in enumerate([y_b, y_b - 0.09] if largo == 'chaqueta' else [y_b, y_b - 0.11, y_b - 0.22]):
        i = np.argmin(np.abs(ys - yb)); th = a0[i] + 0.03; r = L.radio(Rs[i], np.array([th]))[0]
        c = np.array([r * np.sin(th), yb, cz[i] + r * np.cos(th)])
        botones.append(L.disco(c, np.array([np.sin(th), 0, np.cos(th)]), 0.0075 if largo == 'chaqueta' else 0.010))
    nombre = 'Chaqueta' if largo == 'chaqueta' else 'Abrigo'
    return {nombre: L.unir(cuerpo, *canto, cuello, *mangas), nombre + '_solapa': sol,
            nombre + '_botones': L.unir(*botones)}


def pantalon(M, holgura=0.012, recta=True):
    ys = np.linspace(M.ycrotch + 0.035, M.yp + 0.065, 14)
    Rs, cz = L.anillos_tronco(M, M.tronco | M.piern, ys, NA, holgura)
    cadera = _rejilla(L.loft_tronco(ys, Rs, cz, 0.0), True, _cent_tronco)
    piernas = []
    for lado in (1, -1):
        knee = M.P['calf_l'][1] + 0.03
        F = L.pierna(M, lado, M.ypie + 0.03, M.ycrotch + 0.07, 44, 32, holgura, knee if recta else -1)
        F[0, :, :] = F[1] + (F[0] - F[1]) * 1.0
        c0 = F[0].mean(0); F[0] = c0 + (F[0] - c0) * 1.06; F[0, :, 1] -= 0.006 * (F[0, :, 2] < c0[2])
        piernas.append(_rejilla(F, True, lambda p: np.array([p[:, 0].mean(), p[:, 1].mean(), p[:, 2].mean()])))
    return {'Pantalon': L.unir(cadera, *piernas)}


def zapatos(M, holgura=0.006):
    V = M.V; C = M.C; out_s, out_z = [], []
    for lado in (1, -1):
        sel = M.bv & ((C.pie > 0.3) | ((C.gem > 0.3) & (V[:, 1] < M.ypie + 0.03))) & (np.sign(V[:, 0]) == lado)
        p = V[sel]; z0, z1 = p[:, 2].min() - holgura, p[:, 2].max() + holgura * 1.6
        zs = np.linspace(z0, z1, 30); filas = []; suela = []
        for k, z in enumerate(zs):
            t = k / (len(zs) - 1)
            m = np.abs(p[:, 2] - z) < 0.012; q = p[m] if m.sum() > 3 else q
            cx = (q[:, 0].max() + q[:, 0].min()) / 2; hw = (q[:, 0].max() - q[:, 0].min()) / 2 + holgura
            alto = min(q[:, 1].max() + holgura, 0.085 - 0.04 * t)
            cierre = np.sin(np.pi * np.clip(t / 0.08, 0, 1) / 2) * np.sin(np.pi * np.clip((1 - t) / 0.18, 0, 1) / 2)
            hw *= 0.35 + 0.65 * cierre; alto = 0.014 + (alto - 0.014) * (0.3 + 0.7 * cierre)
            th = np.linspace(0, np.pi, 13)
            e = 0.35
            xs = cx + hw * np.sign(np.cos(th)) * np.abs(np.cos(th)) ** e
            yy = 0.014 + (alto - 0.014) * np.abs(np.sin(th)) ** e
            filas.append(np.stack([xs, yy, np.full(13, z)], 1))
            ths = np.linspace(0, 2 * np.pi, 13)
            hs = hw * 1.04 + 0.002
            suela.append(np.stack([cx + hs * np.cos(ths), np.full(13, 0.0), np.full(13, z)], 1))
        F = np.array(filas)
        out_z.append(_rejilla(F, False, lambda pp: pp.mean(0) - [0, 0.02, 0]))
        S = np.array(suela); top = S.copy(); top[:, :, 1] = 0.015
        # suela: anillo exterior en dos alturas + tapa inferior
        Ps = np.stack([S[:, :, 0], np.full(S.shape[:2], -0.003), S[:, :, 2]], 2)
        cont = np.concatenate([Ps[:, 0], Ps[::-1, 6]], 0)
        cont_t = cont.copy(); cont_t[:, 1] = 0.016
        borde = _rejilla(np.stack([cont, cont_t]), True, lambda pp: pp.mean(0))
        base = np.concatenate([cont, [cont.mean(0)]]); n = len(cont)
        tb = np.array([[j, n, (j + 1) % n] for j in range(n)])
        tb = _orientar(base, tb, base.mean(0) + [0, 0.05, 0])
        out_s += [borde, (base, tb, np.zeros((n + 1, 2)))]
    return {'Zapatos': L.unir(*out_z), 'Suela': L.unir(*out_s)}


def polo(M):
    yn = M.yn; ys = np.linspace(M.yp - 0.075, yn + 0.002, 50)
    Rs, cz = L.anillos_tronco(M, M.tronco, ys, NA, 0.016, cae_bajo=M.yaxila - 0.04)
    cuerpo = _rejilla(L.loft_tronco(ys, Rs, cz, 0.0), True, _cent_tronco)
    Rn, czn = cuello_r(M); Fc = []
    for i, y in enumerate(np.linspace(yn + 0.002, yn + 0.026, 4)):
        th = np.linspace(0.14, 2 * np.pi - 0.14, NA + 1); th = np.where(th > np.pi, th - 2 * np.pi, th)
        r = L.radio(Rn, th) + 0.008 + 0.006 * i / 3
        Fc.append(np.stack([r * np.sin(th), np.full(len(th), y), czn + r * np.cos(th)], 1))
    cuello = _rejilla(np.array(Fc), False, _cent_tronco)
    mangas = []
    for lado in (1, -1):
        Fm = L.tubo_x(M, lado, M.xh - 0.03, M.xh + 0.17, 12, 32, 0.014, rmin=lambda t: 0.062 - 0.006 * t)
        mangas.append(_rejilla(Fm, True, lambda p: p.mean(0)))
    botones = []
    for yb in (yn - 0.03, yn - 0.06, yn - 0.09):
        i = np.argmin(np.abs(ys - yb)); r = L.radio(Rs[i], np.array([0.0]))[0]
        botones.append(L.disco(np.array([0, yb, cz[i] + r]), np.array([0, 0, 1.0]), 0.0055))
    i = np.argmin(np.abs(ys - (yn - 0.10))); th = 0.42; r = L.radio(Rs[i], np.array([th]))[0]
    escudo = L.disco(np.array([r * np.sin(th), yn - 0.10, cz[i] + r * np.cos(th)]),
                     np.array([np.sin(th), 0, np.cos(th)]), 0.022, 0.0015, 16)
    return {'Polo': L.unir(cuerpo, cuello, *mangas), 'Polo_botones': L.unir(*botones), 'Polo_escudo': escudo}
