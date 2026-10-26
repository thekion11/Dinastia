"""Prendas v2: tronco por envolvente convexa con sisa real, mangas que nacen de la sisa, pantalón por perneras."""
import numpy as np
import mh_loft as L
import mh_casco as K
from mh_trajes import _orientar, _rejilla, _cent_tronco, _ab_frente, cuello_r, zapatos  # noqa: F401

NA = 72


def _malla_tronco(F, TH, ys, cerrado, agujeros):
    pos = F.reshape(-1, 3); tri = K.tri_rejilla_con_agujeros(F, TH, ys, cerrado, agujeros)
    ny, nc, _ = F.shape
    uu, vv = np.meshgrid(np.linspace(0, 1, nc), np.linspace(0, 1, ny))
    return pos, _orientar(pos, tri, _cent_tronco(pos)), np.stack([uu.reshape(-1), vv.reshape(-1)], 1)


def _tronco(M, y0, holgura, caer=True, sel=None):
    ys = np.linspace(y0, M.yn - 0.002, 76)
    Rs, cz = K.perfil_tronco(M, M.tronco if sel is None else sel, ys, NA, holgura)
    if caer: Rs = K.caida(ys, Rs, M.yaxila - 0.01)
    return ys, Rs, cz


def _mangas(M, ys, Rs, cz, sis, x1, holg, rmin):
    out = []
    for lado in (1, -1):
        tubo = L.tubo_x(M, lado, M.xh + 0.06, x1, 22, NA // 2, holg, rmin=rmin)
        F = K.manga_desde_sisa(M, lado, sis[lado], Rs, cz, ys, tubo)
        out.append(_rejilla(F, True, lambda p: p.mean(0)))
    return out


def _cuello_banda(M, y0, y1, abre0, abre1, extra, n=5):
    Rn, czn = cuello_r(M); Fc = []
    for i, y in enumerate(np.linspace(y0, y1, n)):
        t = i / (n - 1); abre = abre0 + (abre1 - abre0) * t
        th = np.linspace(abre, 2 * np.pi - abre, NA + 1); th = np.where(th > np.pi, th - 2 * np.pi, th)
        r = L.radio(Rn, th) + extra + 0.005 * t
        Fc.append(np.stack([r * np.sin(th), np.full(len(th), y), czn + r * np.cos(th)], 1))
    return _rejilla(np.array(Fc), False, _cent_tronco)


def solapas(ys, Rs, cz, a0, y_b, y_vt, ancho_max, relieve=0.005):
    partes = []; sel = (ys >= y_b - 0.005) & (ys <= y_vt + 0.015)
    yy, RR, cc, aa = ys[sel], Rs[sel], cz[sel], a0[sel]
    s = np.clip((yy - y_b) / (y_vt - y_b), 0, 1)
    w = 0.018 + (ancho_max - 0.018) * np.clip(s / 0.75, 0, 1)
    w = np.where(s > 0.82, w * (1 - (s - 0.82) / 0.18 * 0.55), w)
    for lado in (1, -1):
        filas = []
        for i in range(len(yy)):
            th0 = aa[i]; r0 = K.radio(RR[i], np.array([th0]))[0]
            ths = np.linspace(th0, th0 + w[i] / r0, 5)
            r = K.radio(RR[i], ths) + np.array([0.0015, relieve, relieve * 1.1, relieve, 0.0008])
            filas.append(np.stack([lado * r * np.sin(ths), np.full(5, yy[i]), cc[i] + r * np.cos(ths)], 1))
        partes.append(_rejilla(np.array(filas), False, _cent_tronco))
    return L.unir(*partes)


def camisa(M, abierta=False):
    yn = M.yn; ys, Rs, cz = _tronco(M, M.yp - 0.06, 0.005, caer=False)
    sis = K.sisas(M, ys, Rs, cz)
    F, TH = K.rejilla_tronco(ys, Rs, cz, 0.0, NA + 1)
    cuerpo = _malla_tronco(F, TH, ys, False, list(sis.values()))
    mangas = _mangas(M, ys, Rs, cz, sis, M.xm - 0.02, 0.006, lambda t: 0.046 - 0.008 * t)
    cuello = _cuello_banda(M, yn + 0.004, yn + (0.035 if not abierta else 0.02), 0.16 if not abierta else 0.55,
                           0.16 if not abierta else 0.6, 0.007)
    return {'Camisa': L.unir(cuerpo, cuello, *mangas)}, (ys, Rs, cz)


def corbata(M, ys, Rs, cz, y_fin):
    yn = M.yn; filas = []
    for y in np.linspace(yn - 0.012, y_fin, 26):
        i = np.argmin(np.abs(ys - y)); R0 = K.radio(Rs[i], np.array([0.0]))[0]
        t = (yn - 0.012 - y) / (yn - 0.012 - y_fin); hw = 0.011 + 0.030 * min(t * 1.6, 1)
        if t > 0.96: hw *= (1 - t) / 0.04 * 0.9 + 0.1
        xs = np.array([-hw, -hw * 0.5, 0, hw * 0.5, hw]); bulto = np.array([0, 0.0022, 0.003, 0.0022, 0])
        filas.append(np.stack([xs, np.full(5, y), cz[i] + R0 + 0.004 + bulto], 1))
    hoja = _rejilla(np.array(filas), False, lambda p: p.mean(0) - [0, 0, 0.05])
    Rn, czn = cuello_r(M); r = L.radio(Rn, np.array([0.0]))[0] + 0.012; nudo = []
    for k, y in enumerate(np.linspace(yn - 0.016, yn + 0.022, 6)):
        hw = 0.012 + 0.006 * np.sin(np.pi * k / 5); th = np.linspace(-np.pi * 0.5, np.pi * 0.5, 9)
        nudo.append(np.stack([hw * np.sin(th), np.full(9, y), czn + r - 0.006 + 0.012 * np.cos(th)], 1))
    return {'Corbata': L.unir(hoja, _rejilla(np.array(nudo), False, lambda p: p.mean(0) - [0, 0, 0.05]))}


def chaqueta(M, largo='chaqueta'):
    yn = M.yn; y_b = yn - (0.27 if largo == 'chaqueta' else 0.22); y_vt = yn - 0.035
    hem = M.yp - 0.15 if largo == 'chaqueta' else 0.52
    hol = 0.017 if largo == 'chaqueta' else 0.034
    sel = M.tronco | (M.piern if largo == 'abrigo' else False)
    ys, Rs, cz = _tronco(M, hem, hol, sel=sel)
    if largo == 'abrigo':
        for i, y in enumerate(ys):
            if y < M.ycrotch: Rs[i] += 0.03 * (M.ycrotch - y) / (M.ycrotch - hem)
    a0 = _ab_frente(ys, y_b, y_vt, 0.28 if largo == 'chaqueta' else 0.10, 0.62)
    sis = K.sisas(M, ys, Rs, cz)
    F, TH = K.rejilla_tronco(ys, Rs, cz, a0, NA + 1)
    cuerpo = _malla_tronco(F, TH, ys, False, list(sis.values()))
    c = np.array([0, F[0][:, 1].mean(), cz[0]]); canto = _rejilla(np.stack([F[0], c + (F[0] - c) * 0.975]), False, lambda p: p.mean(0))
    sol = solapas(ys, Rs, cz, a0, y_b, y_vt, 0.075 if largo == 'chaqueta' else 0.09)
    cuello = _cuello_banda(M, yn - 0.004, yn + (0.03 if largo == 'chaqueta' else 0.055), 0.62, 0.92,
                           0.018 + (0.012 if largo == 'abrigo' else 0))
    extra = 0.012 if largo == 'abrigo' else 0
    mangas = _mangas(M, ys, Rs, cz, sis, M.xm - 0.035, 0.014 + extra, lambda t: 0.050 - 0.008 * t + extra)
    botones = []
    for yb in ([y_b, y_b - 0.09] if largo == 'chaqueta' else [y_b, y_b - 0.11, y_b - 0.22]):
        i = np.argmin(np.abs(ys - yb)); th = a0[i] + 0.03; r = K.radio(Rs[i], np.array([th]))[0]
        botones.append(L.disco(np.array([r * np.sin(th), yb, cz[i] + r * np.cos(th)]),
                               np.array([np.sin(th), 0, np.cos(th)]), 0.0075 if largo == 'chaqueta' else 0.010))
    n = 'Chaqueta' if largo == 'chaqueta' else 'Abrigo'
    return {n: L.unir(cuerpo, canto, cuello, *mangas), n + '_solapa': sol, n + '_botones': L.unir(*botones)}


def pantalon(M, holgura=0.012):
    ys = np.linspace(M.ypie + 0.03, M.yp + 0.065, 60); knee = M.P['calf_l'][1] + 0.03; partes = []
    for lado in (1, -1):
        F = K.perneras(M, lado, ys, 40, holgura, knee)
        c0 = F[0].mean(0); F[0] = c0 + (F[0] - c0) * 1.05
        partes.append(_rejilla(F, True, lambda p: p.mean(0)))
    return {'Pantalon': L.unir(*partes)}


def polo(M):
    yn = M.yn; ys, Rs, cz = _tronco(M, M.yp - 0.075, 0.014)
    sis = K.sisas(M, ys, Rs, cz)
    F, TH = K.rejilla_tronco(ys, Rs, cz, 0.0, NA + 1)
    cuerpo = _malla_tronco(F, TH, ys, False, list(sis.values()))
    cuello = _cuello_banda(M, yn + 0.002, yn + 0.026, 0.14, 0.14, 0.008, 4)
    mangas = []
    for lado in (1, -1):
        tubo = L.tubo_x(M, lado, M.xh + 0.06, M.xh + 0.17, 8, NA // 2, 0.014, rmin=lambda t: 0.058 - 0.004 * t)
        mangas.append(_rejilla(K.manga_desde_sisa(M, lado, sis[lado], Rs, cz, ys, tubo), True, lambda p: p.mean(0)))
    botones = []
    for yb in (yn - 0.03, yn - 0.06, yn - 0.09):
        i = np.argmin(np.abs(ys - yb)); r = K.radio(Rs[i], np.array([0.0]))[0]
        botones.append(L.disco(np.array([0, yb, cz[i] + r]), np.array([0, 0, 1.0]), 0.0055))
    i = np.argmin(np.abs(ys - (yn - 0.10))); th = 0.42; r = K.radio(Rs[i], np.array([th]))[0]
    escudo = L.disco(np.array([r * np.sin(th), yn - 0.10, cz[i] + r * np.cos(th)]),
                     np.array([np.sin(th), 0, np.cos(th)]), 0.022, 0.0015, 16)
    return {'Polo': L.unir(cuerpo, cuello, *mangas), 'Polo_botones': L.unir(*botones), 'Polo_escudo': escudo}
