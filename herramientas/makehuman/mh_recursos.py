"""Recursos propios sobre la malla MakeHuman: piel (albedo multiplicador), cejas, pestañas, pelo, ropa.
Todo generado por código; nada copiado de packs externos."""
import io
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from mh_base import caras, normales

RNG = np.random.default_rng(7)


def hexrgb(h):
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float) / 255


def lin(c):  # sRGB -> lineal (COLOR_0 y baseColorFactor son lineales)
    return np.clip(c, 0, 1) ** 2.2


def png(img):
    b = io.BytesIO(); img.save(b, 'PNG', optimize=True); return b.getvalue()


class Cuerpo:
    """Datos de consulta comunes: normales, grupos de peso, puntos de la cabeza."""
    def __init__(self, m):
        self.m = m; V = m['V']; W = m['W']; bi = m['bi']
        self.tv, self.tt = caras(m['F'], {'body'})
        self.N = normales(V, self.tv)
        def g(*pref): return sum(W[:, i] for nm, i in bi.items() if nm.startswith(pref))
        self.cab = W[:, bi['Head']] + W[:, bi['neck_01']]; self.head = W[:, bi['Head']]
        self.manos = g('hand', 'thumb', 'index', 'middle', 'ring', 'pinky')
        self.pie = g('foot', 'ball'); self.gem = g('calf'); self.muslo = g('thigh')
        self.top4 = np.argsort(-W, axis=1)[:, :4]
        tw = np.take_along_axis(W, self.top4, 1); self.tw = tw / tw.sum(1, keepdims=True)
        ojos = {}
        for lado, gname in ((1, 'helper-l-eye'), (-1, 'helper-r-eye')):
            idx = np.unique(caras(m['F'], {gname})[0]); p = V[idx]; c = p.mean(0)
            ojos[lado] = (c, float(np.linalg.norm(p - c, axis=1).max()))
        self.ojos = ojos
        self.ey = (ojos[1][0][1] + ojos[-1][0][1]) / 2; self.ez = (ojos[1][0][2] + ojos[-1][0][2]) / 2
        self.body_v = np.unique(self.tv)
        self.uv_v = np.zeros((len(V), 2))
        self.uv_v[self.tv.reshape(-1)] = m['VT'][self.tt.reshape(-1)]
        e = np.concatenate([self.tv[:, [0, 1]], self.tv[:, [1, 2]], self.tv[:, [2, 0]]])
        self.aristas = np.unique(np.sort(e, 1), axis=0)

    def suavizar(self, f, it=6):
        f = f.astype(float).copy(); a, b = self.aristas[:, 0], self.aristas[:, 1]
        deg = np.zeros(len(f)); np.add.at(deg, a, 1); np.add.at(deg, b, 1)
        for _ in range(it):
            s = np.zeros(len(f)); np.add.at(s, a, f[b]); np.add.at(s, b, f[a])
            f = np.where(deg > 0, 0.5 * f + 0.5 * s / np.maximum(deg, 1), f)
        return f

    def morfos_de(self, idx):
        return {k: d[idx] for k, d in self.m['morfos'].items()}


def cascara(C, sel, grosor, color=None, uv=False):
    """Capa desplazada por la normal sobre las caras del cuerpo cuyos 3 vértices están en `sel`."""
    tri = C.tv[sel[C.tv].all(1)]
    idx, inv = np.unique(tri, return_inverse=True); tri = inv.reshape(-1, 3)
    p = C.m['V'][idx] + C.N[idx] * grosor[idx, None]
    n = normales(p, tri)
    if color is not None: uv = True
    pieza = {'pos': p, 'nrm': n, 'tri': tri, 'joints': C.top4[idx], 'weights': C.tw[idx], 'morfos': C.morfos_de(idx)}
    if color is not None: pieza['col'] = color[idx]
    if uv: pieza['uv'] = C.uv_v[idx] * [1, -1] + [0, 1]
    return pieza


# ---------------- piel ----------------
def textura_piel(C, tam=1024, solo_mult=False):
    V = C.m['V']; mult = np.ones((len(V), 3))
    def gauss(c, s): return np.exp(-np.sum((V - c) ** 2, 1) / (2 * s * s))
    lab = C.m['mascaras']['labios']; lab = np.clip(lab / lab.max() * 2.2, 0, 1)[:, None]
    mult = mult * (1 - lab) + lab * [0.80, 0.56, 0.55]
    cara = (C.head > 0.5)[:, None]
    for lado, (c, r) in C.ojos.items():
        mejilla = gauss(c + [lado * 0.012, -0.035, 0.0], 0.018)[:, None] * cara
        mult = mult * (1 - 0.35 * mejilla) + 0.35 * mejilla * [1.0, 0.80, 0.78]
        ojera = gauss(c + [0, -0.008, 0], 0.011)[:, None] * cara
        mult = mult * (1 - 0.25 * ojera) + 0.25 * ojera * [0.82, 0.74, 0.74]
    cabeza = np.nonzero(C.head > 0.5)[0]
    nz = cabeza[np.argmax(V[cabeza, 2] - 50 * np.abs(V[cabeza, 0]))]
    nariz = gauss(V[nz], 0.012)[:, None]
    mult = mult * (1 - 0.3 * nariz) + 0.3 * nariz * [1.0, 0.84, 0.82]
    barba = ((V[:, 1] < C.ey - 0.045) & (C.head > 0.5) & (V[:, 2] > C.ez - 0.06)).astype(float)
    barba = np.clip(C.suavizar(barba, 8), 0, 1)[:, None]
    mult = mult * (1 - 0.12 * barba) + 0.12 * barba * [0.80, 0.80, 0.86]
    if solo_mult: return mult
    img = Image.new('RGB', (tam, tam), (250, 247, 245)); d = ImageDraw.Draw(img)
    uv = C.m['VT'].copy(); uv[:, 1] = 1 - uv[:, 1]
    for t3, u3 in zip(C.tv, C.tt):
        c = tuple(int(x) for x in np.clip(mult[t3].mean(0) * 250, 0, 255))
        pts = [(uv[k, 0] * tam, uv[k, 1] * tam) for k in u3]
        d.polygon(pts, fill=c, outline=c)
    img = img.filter(ImageFilter.GaussianBlur(3))
    a = np.asarray(img).astype(float)
    poros = Image.fromarray((RNG.normal(128, 40, (tam, tam))).clip(0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))
    mancha = Image.fromarray((RNG.normal(128, 50, (24, 24))).clip(0, 255).astype(np.uint8)).resize((tam, tam), Image.BICUBIC)
    a *= (1 + (np.asarray(poros, float)[..., None] - 128) / 128 * 0.06)
    a *= (1 + (np.asarray(mancha, float)[..., None] - 128) / 128 * 0.05)
    return Image.fromarray(a.clip(0, 255).astype(np.uint8))


# ---------------- pelo ----------------
def textura_pelo(tam=1024, alfa=None):
    img = Image.new('L', (tam, tam), 150); d = ImageDraw.Draw(img)
    for _ in range(60000):
        x, y = RNG.uniform(0, tam, 2); a = RNG.normal(np.pi / 2, 0.5); L = RNG.uniform(1.5, 4)
        v = int(RNG.uniform(90, 255))
        d.line([(x, y), (x + np.cos(a) * L, y + np.sin(a) * L)], fill=v, width=1)
    img = img.filter(ImageFilter.GaussianBlur(0.5))
    if alfa is None: return img.convert('RGB')
    al = Image.fromarray(((RNG.random((tam, tam)) < alfa) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))
    al = al.point(lambda v: 255 if v > 110 else 0)
    return Image.merge('RGBA', (img, img, img, al))


def pelo(C, corte):
    V = C.m['V']; ey, ez = C.ey, C.ez
    ytop = V[C.head > 0.5, 1].max()
    s = np.clip((V[:, 2] - (ez - 0.10)) / 0.08, 0, 1); s = s * s * (3 - 2 * s)
    frente = {'rapado': 0.060, 'corto': 0.055, 'entradas': 0.055, 'canoso': 0.058}[corte]
    umbral = (ey - 0.075) * (1 - s) + (ey + frente) * s
    if corte == 'entradas':
        umbral += 0.022 * np.clip((np.abs(V[:, 0]) - 0.012) / 0.04, 0, 1) * s
    ancho = np.abs(V[C.head > 0.5, 0]).max()
    oreja = (np.abs(V[:, 0]) > ancho - 0.016) & (V[:, 1] < ey + 0.025) & (V[:, 2] < ez - 0.04) & (V[:, 2] > ez - 0.12)
    sel = (C.head > 0.6) & (V[:, 1] > umbral) & ~oreja
    sel[np.setdiff1d(np.arange(len(V)), C.body_v)] = False
    suave = np.clip(C.suavizar(sel, 10) * 1.6 - 0.3, 0, 1)
    alto = np.clip((V[:, 1] - ey) / (ytop - ey), 0, 1)
    t = {'rapado': (0.0012, 0.0016), 'corto': (0.005, 0.011), 'entradas': (0.005, 0.010), 'canoso': (0.004, 0.008)}[corte]
    gro = (t[0] + (t[1] - t[0]) * alto) * (0.25 + 0.75 * suave) + 0.0006
    return cascara(C, sel, gro, uv=True)


# ---------------- cejas y pestañas ----------------
def _pegada(C, puntos_idx, pos, uv, tri):
    return {'pos': pos, 'nrm': normales(pos, tri) if len(tri) else C.N[puntos_idx], 'tri': tri, 'uv': uv,
            'joints': C.top4[puntos_idx], 'weights': C.tw[puntos_idx], 'morfos': C.morfos_de(puntos_idx)}


ANCHO_CEJA = 0.62


def cejas(C):
    V = C.m['V']; cand = np.nonzero((C.head > 0.5) & (V[:, 2] > C.ez - 0.03))[0]
    cand = np.intersect1d(cand, C.body_v)
    P, I, UV, T = [], [], [], []
    for lado, (c, r) in C.ojos.items():
        n_s = 14; base = len(P)
        for i in range(n_s):
            t = i / (n_s - 1)
            x = c[0] + lado * (-1.15 * r + 2.7 * r * t)
            y = c[1] + 1.35 * r + 0.45 * r * np.sin(np.pi * min(t * 1.25, 1.0)) - 0.25 * r * t
            d = np.abs(V[cand, 0] - x) + np.abs(V[cand, 1] - y)
            cerca = cand[d < d.min() + 0.002]
            k = cerca[np.argmax(V[cerca, 2])]
            n = C.N[k]; up = np.array([0, 1.0, 0]); up = up - n * (n @ up); up /= np.linalg.norm(up)
            w = (r * (0.95 - 0.55 * t) if t > 0.2 else r * (0.75 + t)) * ANCHO_CEJA
            ctr = V[k] + n * 0.0012
            for sgn in (-1, 1):
                P.append(ctr + up * sgn * w / 2); I.append(k); UV.append([t, 0.5 + 0.5 * sgn])
            if i:
                a = base + 2 * (i - 1)
                T += [[a, a + 2, a + 1], [a + 1, a + 2, a + 3]] if lado > 0 else [[a, a + 1, a + 2], [a + 1, a + 3, a + 2]]
    return _pegada(C, np.array(I), np.array(P), np.array(UV), np.array(T))


def textura_cejas(w=256, h=64):
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    for _ in range(1300):
        x = RNG.uniform(0, w); y = RNG.uniform(10, h - 10) if x < w * 0.8 else RNG.uniform(20, h - 20)
        ang = -0.30 - 0.45 * (x / w) + RNG.normal(0, 0.12); L = RNG.uniform(5, 10)
        v = int(RNG.uniform(140, 255))
        d.line([(x, y), (x + np.cos(ang) * L, y + np.sin(ang) * L)], fill=(v, v, v, 255), width=1)
    return img.filter(ImageFilter.GaussianBlur(0.4))


LARGO_PESTANA = 1.0


def pestanas(C):
    """Tira sobre el borde del párpado superior: por franjas de x, el vértice de piel más bajo
    que está pegado al globo ocular por encima de su centro (la malla MH no tiene agujero en el ojo)."""
    V = C.m['V']; bv = C.body_v
    P, I, UV, T = [], [], [], []
    for lado, (c, r) in C.ojos.items():
        d = np.linalg.norm(V[bv] - c, axis=1)
        cand = bv[(d < r * 1.25) & (V[bv, 2] > c[2] + 0.35 * r) & (V[bv, 1] > c[1] - 0.05 * r)]
        vs = []
        for x0 in np.linspace(-0.85 * r, 0.85 * r, 12):
            en = cand[np.abs(V[cand, 0] - c[0] - lado * x0) < 0.12 * r]
            if len(en): vs.append(en[np.argmin(V[en, 1])])
        base = len(P)
        for i, v in enumerate(vs):
            t = i / max(len(vs) - 1, 1)
            fuera = V[v] - c; fuera /= np.linalg.norm(fuera)
            dirl = fuera * 0.6 + np.array([0, 0.55, 0.5]); dirl /= np.linalg.norm(dirl)
            L = 0.0042 * LARGO_PESTANA * (0.45 + np.sin(np.pi * t))
            P += [V[v] + fuera * 0.0004, V[v] + fuera * 0.0004 + dirl * L]; I += [v, v]; UV += [[t, 1], [t, 0]]
            if i:
                a = base + 2 * (i - 1); T += [[a, a + 2, a + 1], [a + 1, a + 2, a + 3]]
    return _pegada(C, np.array(I, int), np.array(P), np.array(UV), np.array(T))


def textura_pestanas(w=256, h=32):
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    for x in np.linspace(2, w - 2, 70):
        d.line([(x, h), (x + RNG.normal(0, 2), RNG.uniform(2, 10))], fill=(255, 255, 255, 255), width=2)
    return img


# ---------------- ropa ----------------
def ropa(C, estilo, c_principal, c_detalle='f0f0ec', c_corbata='7a1f2b'):
    """Devuelve dict nombre->pieza. estilo 'traje' o 'chandal'."""
    m = C.m; V = m['V']; P = m['NPOS']
    yp = P['pelvis'][1]; yn = P['neck_01'][1]; ypie = P['foot_l'][1]
    manox = abs(P['hand_l'][0])
    cp = hexrgb(c_principal); cd = hexrgb(c_detalle)
    resto = 1 - C.cab - C.manos - C.pie - C.gem
    cuello = (C.cab > 0.5) & (C.head < 0.5) & (V[:, 1] < yn + (0.045 if estilo == 'chandal' else 0.03))
    hem = yp - (0.10 if estilo == 'traje' else 0.04)
    arriba = ((resto > 0.5) & (V[:, 1] > hem) & (np.abs(V[:, 0]) < manox - 0.03)) | cuello
    piernas = ((C.muslo + C.gem + m['W'][:, m['bi']['pelvis']] > 0.5) & (V[:, 1] < yp + 0.07)
               & (V[:, 1] > ypie + 0.04)) & (C.pie < 0.3)
    pies = (C.pie > 0.3) | ((C.gem > 0.3) & (V[:, 1] < ypie + 0.06))
    fuera = np.setdiff1d(np.arange(len(V)), C.body_v)
    for s in (arriba, piernas, pies): s[fuera] = False

    col = np.tile(cp, (len(V), 1))
    brazo = np.abs(V[:, 0]) > abs(P['clavicle_l'][0]) + 0.10
    frente = V[:, 2] > P['spine_03'][2]
    if estilo == 'traje':
        yv = yn - 0.22; hw = 0.08 * np.clip((V[:, 1] - yv) / (yn + 0.02 - yv), 0, 1)
        v_camisa = frente & (np.abs(V[:, 0]) < hw) & ~brazo
        col[v_camisa | cuello] = cd
        corb = v_camisa & (np.abs(V[:, 0]) < 0.011 + 0.006 * np.clip((yn - 0.03 - V[:, 1]) / 0.15, 0, 1)) & (V[:, 1] < yn - 0.005)
        col[corb] = hexrgb(c_corbata)
        solapa = frente & ~brazo & ~v_camisa & (np.abs(V[:, 0]) < hw + 0.012) & (V[:, 1] > yv)
        col[solapa] = cp * 0.78
        col[arriba & (V[:, 1] < hem + 0.012)] = cp * 0.85
    else:
        eje_y = P['upperarm_l'][1] + (P['hand_l'][1] - P['upperarm_l'][1]) * np.clip(
            (np.abs(V[:, 0]) - abs(P['upperarm_l'][0])) / (manox - abs(P['upperarm_l'][0])), 0, 1)
        franja = brazo & (V[:, 1] - eje_y > 0.022)
        col[franja] = cd
        col[frente & (np.abs(V[:, 0]) < 0.0035) & ~brazo] = cp * 0.4
        col[cuello] = cp * 0.9
        col[arriba & (V[:, 1] < hem + 0.02)] = cp * 0.75
        col[arriba & brazo & (np.abs(V[:, 0]) > manox - 0.05)] = cp * 0.75
    gro_a = np.where(cuello, 0.004, np.where(brazo, 0.010, 0.013))
    gro_a = C.suavizar(gro_a, 3) + 0.0015 * (V[:, 1] < hem + 0.04)
    piezas = {f'{estilo}_arriba': cascara(C, arriba, gro_a, lin(col) * 255)}

    colp = np.tile(cp, (len(V), 1))
    if estilo == 'chandal':
        ejx = np.where(V[:, 1] > P['calf_l'][1], P['thigh_l'][0], P['calf_l'][0])
        colp[(np.abs(V[:, 0]) - abs(ejx) > 0.035) & (V[:, 1] < yp - 0.05)] = cd
        colp[V[:, 1] < ypie + 0.065] = cp * 0.75
    else:
        colp[V[:, 1] > yp + 0.045] = cp * 0.5
    gro_p = 0.009 + 0.006 * np.clip((P['calf_l'][1] - V[:, 1]) / 0.35, 0, 1)
    piezas[f'{estilo}_pantalon'] = cascara(C, piernas, C.suavizar(gro_p, 2), lin(colp) * 255)

    colz = np.tile(hexrgb('1a1714') if estilo == 'traje' else hexrgb('ecebe6'), (len(V), 1))
    colz[V[:, 1] < 0.018] = hexrgb('0d0b0a') if estilo == 'traje' else hexrgb('9a9a96')
    gro_z = np.where(C.N[:, 1] < -0.5, 0.0015, 0.007 + 0.003 * (V[:, 1] < 0.03))
    piezas[f'{estilo}_zapatos'] = cascara(C, pies, C.suavizar(gro_z, 2), lin(colz) * 255)
    for p in piezas.values():
        p['col'] = np.concatenate([p['col'], np.full((len(p['col']), 1), 255)], 1)
    return piezas
