"""Fase 3: zonas de cuerpo ocultables, cabeza con atlas propio, pelo con línea por textura, ropa con volumen."""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from mh_base import normales
from mh_recursos import hexrgb, lin
import mh_tex as T


def centro_cabeza(C):
    return np.array([0.0, C.ey, C.ez - 0.085])


def pieza(C, tv, tt, pos_full, modo, extra=None):
    """Malla de piezas sobre caras del cuerpo. modo 'atlas' (UV MakeHuman) o 'esfera' (UV propia de cabeza)."""
    if modo == 'atlas':
        uvc = C.m['VT'][tt] * [1, -1] + [0, 1]
    else:
        uvc = T.uv_esferico(C.m['V'], centro_cabeza(C), tv)
    vid, uv, tri = T.partir_esquinas(tv, uvc)
    p = pos_full[vid]
    return {'pos': p, 'nrm': normales(p, tri), 'tri': tri, 'uv': uv, 'joints': C.top4[vid],
            'weights': C.tw[vid], 'morfos': C.morfos_de(vid)}, vid


def caras_sel(C, sel):
    m = sel[C.tv].all(1); return C.tv[m], C.tt[m]


# ---------------- máscaras de zonas (las comparten ropa y cuerpo) ----------------
def mascaras(C):
    m = C.m; V = m['V']; P = m['NPOS']
    yp = P['pelvis'][1]; yn = P['neck_01'][1]; ypie = P['foot_l'][1]; manox = abs(P['hand_l'][0])
    resto = 1 - C.cab - C.manos - C.pie - C.gem
    fuera = np.setdiff1d(np.arange(len(V)), C.body_v)
    z = {}
    def lim(s): s = s.copy(); s[fuera] = False; return s
    for est, hem, cue in (('traje', yp - 0.11, 0.03), ('chandal', yp - 0.05, 0.045)):
        cuello = (C.cab > 0.5) & (C.head < 0.5) & (V[:, 1] < yn + cue)
        z[est + '_arriba'] = lim(((resto > 0.5) & (V[:, 1] > hem) & (np.abs(V[:, 0]) < manox - 0.03)) | cuello)
        z[est + '_cuello'] = cuello
    z['piernas'] = lim((C.muslo + C.gem + m['W'][:, m['bi']['pelvis']] > 0.5) & (V[:, 1] < yp + 0.07)
                       & (V[:, 1] > ypie + 0.04) & (C.pie < 0.3))
    z['pies'] = lim((C.pie > 0.3) | ((C.gem > 0.3) & (V[:, 1] < ypie + 0.06)))
    return z


def cuerpo(C, z):
    """Zonas: Cabeza (atlas propio), Visible (cuello, manos), Torso, Piernas, Pies (ocultables)."""
    V = C.m['V']
    cub_arriba = z['chandal_arriba'] & ~z['chandal_cuello']
    brazo = np.abs(V[:, 0]) > abs(C.m['NPOS']['clavicle_l'][0]) + 0.09
    usado = np.zeros(len(C.tv), bool); zonas = {}
    for nombre, sel in (('Torso', cub_arriba & ~brazo), ('Brazos', cub_arriba & brazo), ('Piernas', z['piernas']),
                        ('Pies', z['pies'])):
        m = sel[C.tv].all(1) & ~usado; usado |= m; zonas[nombre] = m
    cab = (C.cab[C.tv] > 0.5).all(1) & ~usado; usado |= cab
    zonas['Visible'] = ~usado
    out = {}
    for nombre, m in zonas.items():
        out['Cuerpo_' + nombre] = pieza(C, C.tv[m], C.tt[m], V, 'atlas')[0]
    out['Cuerpo_Cabeza'], vid_cab = pieza(C, C.tv[cab], C.tt[cab], V, 'esfera')
    return out, vid_cab


BARBA = 1.0


def textura_cabeza(C, pz, vid, mult_v, tam=2048, maquillaje=False):
    V = C.m['V']
    if maquillaje:
        mult_v = mult_v.copy()
        for lado, (c, r) in C.ojos.items():
            for cen, s_, col, k in ((c + [0, 0.008, 0.002], 0.009, [0.80, 0.72, 0.80], 0.45),
                                    (c + [lado * 0.014, -0.034, 0], 0.016, [1.0, 0.78, 0.78], 0.40),
                                    (c + [lado * 0.006, 0.001, 0.004], 0.004, [0.55, 0.45, 0.45], 0.35)):
                g = np.exp(-np.sum((V - cen) ** 2, 1) / (2 * s_ * s_))[:, None] * k
                mult_v = mult_v * (1 - g) + g * np.array(col)
    lab = C.m['mascaras']['labios']; lab = lab / lab.max()
    barba = ((V[:, 1] < C.ey - 0.04) & (V[:, 1] > C.ey - 0.11) & (V[:, 2] > C.ez - 0.07)).astype(float) * BARBA
    barba = C.suavizar(barba, 10)
    vals = np.concatenate([mult_v[vid], lab[vid, None], barba[vid, None]], 1)
    img, _ = T.raster(pz['uv'], pz['tri'], vals, tam)
    col = img[..., :3]
    labio = T.suave01(img[..., 3], 0.12, 0.45)[..., None]
    lc = np.array([0.72, 0.38, 0.42]) if maquillaje else np.array([0.80, 0.55, 0.54])
    col = col * (1 - labio * (0.75 if maquillaje else 0.6)) + labio * (0.75 if maquillaje else 0.6) * lc
    poro = T.ruido(tam, 1, 0.035) + T.ruido(tam, 3, 0.025) + T.ruido(tam, 64, 0.04)
    col = col * (1 + poro[..., None])
    pelillo = (T.RNG.random((tam, tam)) < 0.10) * img[..., 4]
    col = col * (1 - 0.18 * pelillo[..., None])
    return T.jpg(col * 250)


# ---------------- pelo ----------------
def campo_pelo(C, corte):
    """Distancia con signo (m) a la línea del pelo; > 0 es pelo."""
    V = C.m['V']; ey, ez = C.ey, C.ez; ax = np.abs(V[:, 0])
    s = T.suave01(V[:, 2], ez - 0.11, ez - 0.035)
    frente = ey + 0.052 + 0.010 * (ax / 0.05) ** 2
    if corte == 'entradas':
        frente = ey + 0.063 + 0.015 * T.suave01(ax, 0.008, 0.05)
    if corte == 'rapado':
        frente = frente + 0.004
    umbral = (ey - 0.075) * (1 - s) + frente * s
    d = V[:, 1] - umbral
    ancho = np.abs(V[C.head > 0.5, 0]).max()
    for lado in (1, -1):
        oreja = np.array([lado * (ancho - 0.01), ey - 0.012, ez - 0.085])
        d = np.minimum(d, np.linalg.norm((V - oreja) * [0.6, 1, 1], axis=1) - 0.034)
    return d


def pelo(C, corte, c_pelo):
    V = C.m['V']; d = campo_pelo(C, corte)
    sel = (C.head > 0.4) & (d > -0.012); sel[np.setdiff1d(np.arange(len(V)), C.body_v)] = False
    ytop = V[C.head > 0.5, 1].max(); alto = np.clip((V[:, 1] - C.ey) / (ytop - C.ey), 0, 1)
    t = {'rapado': (0.0010, 0.0013), 'corto': (0.003, 0.0065), 'entradas': (0.003, 0.006), 'canoso': (0.003, 0.006)}[corte]
    gro = (t[0] + (t[1] - t[0]) * alto) * np.clip(d / 0.012 + 0.35, 0.12, 1) + 0.0006
    pos = V + C.N * gro[:, None]
    tv, tt = caras_sel(C, sel)
    pz, vid = pieza(C, tv, tt, pos, 'esfera')
    tam = 512
    img, _ = T.raster(pz['uv'], pz['tri'], d[vid, None], tam)
    borde = img[..., 0] + T.ruido(tam, 1, 0.0022) + T.ruido(tam, 6, 0.002)
    dens = 0.55 if corte == 'rapado' else 1.0
    alfa = (borde > 0) & (T.RNG.random((tam, tam)) < np.where(borde > 0.006, dens, 0.55 * dens))
    if corte != 'rapado': alfa = borde > (0.0015 * (T.RNG.random((tam, tam)) < 0.5))
    vet = Image.new('L', (tam, tam), 150); dr = ImageDraw.Draw(vet)
    for _ in range(22000):
        x, y = T.RNG.uniform(0, tam, 2); a = T.RNG.normal(np.pi / 2, 0.35); L = T.RNG.uniform(1.5, 4)
        dr.line([(x, y), (x + np.cos(a) * L, y + np.sin(a) * L)], fill=int(T.RNG.uniform(80, 255)), width=1)
    vet = np.asarray(vet.filter(ImageFilter.GaussianBlur(0.5)), float)
    lum = np.clip(vet / 200 * 255, 0, 255)
    if corte == 'canoso':
        lum = np.where(T.RNG.random((tam, tam)) < 0.35, lum * 0.45, lum)
    la = np.stack([lum, alfa * 255], 2).astype(np.uint8)
    return pz, T.png(Image.fromarray(la, 'LA'))


# ---------------- atlas del cuerpo con manos y uñas ----------------
DEDOS = ('thumb', 'index', 'middle', 'ring', 'pinky')


def campos_mano(C):
    """uña (0..1), lúnula (0..1) y nudillo (0..1) por vértice."""
    V = C.m['V']; P = C.m['NPOS']; n = len(V)
    una = np.zeros(n); lun = np.zeros(n); nud = np.zeros(n)
    for s in ('l', 'r'):
        for d in DEDOS:
            a = P[f'{d}_03_{s}']; b = P[f'{d}_04_leaf_{s}']; ab = b - a; L2 = ab @ ab
            t = ((V - a) @ ab) / L2; q = a + np.clip(t, 0, 1)[:, None] * ab; r = V - q
            rn = np.linalg.norm(r, axis=1) + 1e-9
            if d == 'thumb':
                dors = np.cross(ab, [0, 0, 1.0]) * (1 if s == 'l' else -1)
                dors = dors / np.linalg.norm(dors) * 0.5 + np.array([0, 0.85, 0])
            else:
                dors = np.array([0, 1.0, 0])
            dors /= np.linalg.norm(dors)
            arriba = (r @ dors) / rn
            cerca = rn < 0.012
            m = cerca & (arriba > 0.55) & (t > 0.38) & (t < 1.08)
            una = np.maximum(una, m * T.suave01(arriba, 0.55, 0.75))
            lun = np.maximum(lun, m * (1 - T.suave01(t, 0.38, 0.5)))
            for j in ('01', '02', '03'):
                k = P[f'{d}_{j}_{s}']
                g = np.exp(-np.sum((V - k) ** 2, 1) / (2 * 0.006 ** 2)) * (C.N @ dors > 0.3)
                nud = np.maximum(nud, g)
    palma = ((C.manos > 0.5) & (C.N[:, 1] < -0.4)).astype(float)
    return np.stack([una, lun, nud, palma], 1)


def textura_atlas(C, mult, tam=2048):
    uvc = C.m['VT'][C.tt] * [1, -1] + [0, 1]
    vid, uv, tri = T.partir_esquinas(C.tv, uvc)
    vals = np.concatenate([mult, campos_mano(C)], 1)[vid]
    img, _ = T.raster(uv, tri, vals, tam)
    col = img[..., :3]; una, lun, nud, pal = [img[..., 3 + i] for i in range(4)]
    col = col * (1 + 0.06 * pal[..., None])
    col = col * (1 - 0.08 * nud[..., None])
    u = T.suave01(una, 0.3, 0.6)[..., None]
    col = col * (1 - u) + u * np.array([1.0, 0.84, 0.82]) * 1.02
    l = (T.suave01(lun, 0.3, 0.7) * T.suave01(una, 0.3, 0.6))[..., None]
    col = col * (1 - 0.5 * l) + 0.5 * l * np.array([1.0, 0.95, 0.93])
    col = col * (1 + (T.ruido(tam, 1, 0.03) + T.ruido(tam, 4, 0.02) + T.ruido(tam, 64, 0.04))[..., None])
    return T.jpg(col * 250)


def melena(C):
    """Media melena por loft de anillos alrededor de la cabeza, abierta por delante bajo la frente."""
    import mh_loft as L
    V = C.m['V']; ey = C.ey; hc = centro_cabeza(C)
    sel = np.zeros(len(V), bool); sel[C.body_v] = True; sel &= C.head > 0.5
    ytop = V[sel, 1].max()
    ys = np.linspace(ytop - 0.004, ey - 0.085, 36); na = 64; filas = []; Rear = None
    for i, y in enumerate(ys):
        m = sel & (np.abs(V[:, 1] - y) < 0.01); p = V[m]
        if len(p) >= 6:
            ang = np.arctan2(p[:, 0], p[:, 2] - hc[2]); r = np.hypot(p[:, 0], p[:, 2] - hc[2])
            b = ((ang + np.pi) / (2 * np.pi) * na).astype(int) % na
            R = np.zeros(na); np.maximum.at(R, b, r); R = L.suav_circ(L._rellenar_circ(R), 4)
        else:
            R = Rprev
        if i == 0: R = R * 0.25
        if y < ey + 0.01:
            if Rear is None: Rear = R.copy()
            R = np.maximum(R, Rear * (1 + 0.06 * (ey + 0.01 - y) / 0.1))
        Rprev = R
        hol = 0.011 + 0.004 * np.clip((ey - y) / 0.08, 0, 1)
        a0 = 0.95 * T.suave01(-(y - (ey + 0.05)), 0.0, 0.03)
        th = np.linspace(a0, 2 * np.pi - a0, na + 1); th = np.where(th > np.pi, th - 2 * np.pi, th)
        r = L.radio(R + hol, th)
        filas.append(np.stack([r * np.sin(th), np.full(na + 1, y), hc[2] + r * np.cos(th)], 1))
    F = np.array(filas)
    pos, tri, uv = L.malla_rejilla(F, False)
    n = np.cross(pos[tri[:, 1]] - pos[tri[:, 0]], pos[tri[:, 2]] - pos[tri[:, 0]])
    if np.sum(np.einsum('ij,ij->i', n, pos[tri].mean(1) - hc)) < 0: tri = tri[:, ::-1]
    pz = L.pieza(C, pos, tri, uv * [4, 1], sel=sel)
    tam = 512
    vet = Image.new('L', (tam, tam), 150); dr = ImageDraw.Draw(vet)
    for _ in range(9000):
        x = T.RNG.uniform(0, tam); y = T.RNG.uniform(0, tam); Ln = T.RNG.uniform(20, 60)
        dr.line([(x, y), (x + T.RNG.normal(0, 2), y + Ln)], fill=int(T.RNG.uniform(70, 255)), width=1)
    lum = np.asarray(vet.filter(ImageFilter.GaussianBlur(0.6)), float)
    vv = np.linspace(0, 1, tam)[:, None]
    pun = 0.80 + 0.17 * T.RNG.random((1, tam)) ** 0.7
    alfa = vv < pun
    la = np.stack([lum, alfa * 255.0], 2).astype(np.uint8)
    return pz, T.png(Image.fromarray(la, 'LA'))
