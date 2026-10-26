"""MakeHuman CC0 + recursos propios -> <base>_cuerpo.glb y <base>_ropa.glb con el esqueleto del juego.
Uso: python3 -I mh_generar.py <data_makehuman> <gltf_quaternius> <base_salida> [m|f]"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from mh_base import construir, caras, normales
from mh_glb import Glb
import mh_recursos as R
import mh_piezas as PZ
import mh_tex as T
import mh_loft as LO
import mh_trajes as TJ
import mh_trajes2 as T2
import mh_pelo_f as PF

DATA, QG, BASE = sys.argv[1:4]; SEXO = sys.argv[4] if len(sys.argv) > 4 else 'm'
MORFOS = {
    'cabeza_edad': 'head/head-age-incr.target', 'cabeza_ovalada': 'head/head-oval.target',
    'cabeza_cuadrada': 'head/head-square.target', 'cabeza_redonda': 'head/head-round.target',
    'cabeza_triangular': 'head/head-triangular.target', 'cabeza_gorda': 'head/head-fat-incr.target',
    'nariz_ancha': 'nose/nose-scale-horiz-incr.target', 'nariz_larga': 'nose/nose-scale-vert-incr.target',
    'nariz_giba': 'nose/nose-hump-incr.target', 'nariz_punta_ancha': 'nose/nose-point-width-incr.target',
    'nariz_aguilena': 'nose/nose-greek-incr.target', 'nariz_fina': 'nose/nose-scale-horiz-decr.target',
    'cejas_arriba': 'eyebrows/eyebrows-trans-up.target',
    'cejas_angulo_arriba': 'eyebrows/eyebrows-angle-up.target', 'cejas_angulo_abajo': 'eyebrows/eyebrows-angle-down.target',
    'menton_estrecho': 'chin/chin-width-decr.target', 'menton_suave': 'chin/chin-prominent-decr.target',
    'mandibula_suave': 'chin/chin-bones-decr.target',
    'pomulos': 'cheek/l-cheek-bones-incr.target+cheek/r-cheek-bones-incr.target',
    'labios_gruesos': 'mouth/mouth-upperlip-volume-incr.target+mouth/mouth-lowerlip-volume-incr.target',
}
m = construir(DATA, QG, MORFOS, SEXO)
if SEXO == 'f': PZ.BARBA = 0.0; R.ANCHO_CEJA = 0.5; R.LARGO_PESTANA = 1.6
C = R.Cuerpo(m); V = m['V']
tono = tuple(R.lin(R.hexrgb('c68d68'))) + (1,)

# ------------------------------ cuerpo ------------------------------
g = Glb()
def poner(gg, nombre, pz, mat): gg.malla(nombre, **pz, mat=mat)
z = PZ.mascaras(C)
zonas, vid_cab = PZ.cuerpo(C, z)
mult = R.textura_piel(C, solo_mult=True)
mat_cuerpo = g.material('Piel', tono, 0.55, g.textura(PZ.textura_atlas(C, mult), 'image/jpeg'))
for nombre, pz in zonas.items():
    if nombre == 'Cuerpo_Cabeza':
        poner(g, nombre, pz, g.material('Piel_cabeza', tono, 0.5,
                                        g.textura(PZ.textura_cabeza(C, pz, vid_cab, mult), 'image/jpeg')))
        if SEXO == 'f':
            poner(g, 'Cuerpo_Cabeza_maquillaje', pz, g.material('Piel_cabeza_maquillaje', tono, 0.45, g.textura(
                PZ.textura_cabeza(C, pz, vid_cab, mult, maquillaje=True), 'image/jpeg')))
    else:
        poner(g, nombre, pz, mat_cuerpo)
tvo, _ = caras(m['F'], {'helper-l-eye', 'helper-r-eye'})
idx, inv = np.unique(tvo, return_inverse=True); tri = inv.reshape(-1, 3); p = V[idx]
col = np.tile([1.0, 1.0, 1.0], (len(idx), 1))
for lado, (c, r) in C.ojos.items():
    sel = np.sign(p[:, 0]) == lado; fr = (p[:, 2] - c[2]) / r; d = np.linalg.norm(p[:, :2] - c[:2], axis=1) / r
    col[sel & (fr > 0) & (d < 0.47)] = R.hexrgb('5a3a22'); col[sel & (fr > 0) & (d < 0.2)] = [0.02, 0.02, 0.02]
col = np.concatenate([R.lin(col) * 255, np.full((len(idx), 1), 255)], 1)
g.malla('Ojos', p, normales(V, tvo)[idx], tri, C.top4[idx], C.tw[idx], g.material('Ojos', (0.9, 0.9, 0.9, 1), 0.2),
        col=col, morfos=C.morfos_de(idx))
pelo_c = tuple(R.lin(R.hexrgb('2a1c12'))) + (1,)
poner(g, 'Cejas', R.cejas(C), g.material('Cejas', pelo_c, 0.8, g.textura(R.png(R.textura_cejas())), 'MASK', True))
poner(g, 'Pestanas', R.pestanas(C), g.material('Pestanas', (0.01, 0.01, 0.01, 1), 0.8,
      g.textura(R.png(R.textura_pestanas())), 'MASK', True))
for corte in ('corto', 'entradas', 'canoso', 'rapado'):
    pz, tex = PZ.pelo(C, corte, 'ffffff')
    c = tuple(R.lin(R.hexrgb('9a9a9a' if corte == 'canoso' else '2a1c12'))) + (1,)
    poner(g, 'Pelo_' + corte, pz, g.material('Pelo_' + corte, c, 0.95, g.textura(tex), 'MASK'))
if SEXO == 'f':
    t_mech = g.textura(PF.textura_mechones(), 'image/png')
    t_liso = g.textura(PF.textura_mechones(puntas=False, largo=(30, 90)), 'image/png')
    poner(g, 'Pelo_melena', PF.melena_capas(C), g.material('Pelo_melena', pelo_c, 0.9, t_mech, 'MASK', True))
    col_, goma = PF.coleta(C)
    poner(g, 'Pelo_coleta', col_, g.material('Pelo_coleta', pelo_c, 0.9, t_liso, 'MASK', True))
    poner(g, 'Pelo_coleta_goma', goma, g.material('Pelo_goma', (0.02, 0.02, 0.02, 1), 0.6))
    poner(g, 'Pelo_mono', PF.mono(C), g.material('Pelo_mono', pelo_c, 0.9, t_liso, 'MASK', True))
OUT_C = BASE + '_cuerpo.glb'
g.escribir(OUT_C, m['orden'], m['qpadre'], m['GB'], 'MakeHuman assets CC0 1.0; recursos propios')

# ------------------------------ ropa ------------------------------
g = Glb()
def tela(tam, esc, amp, rayas=None):
    a = 200 * (1 + T.ruido(tam, 1, amp) + T.ruido(tam, esc, amp * 0.6))
    if rayas: a *= 1 + rayas * np.sin(np.arange(tam)[None, :] * 2 * np.pi / 6 + np.arange(tam)[:, None] * 2 * np.pi / 6)
    return g.textura(T.jpg(np.repeat(a[..., None], 3, 2)), 'image/jpeg')
t_lana = tela(512, 8, 0.05); t_seda = tela(256, 4, 0.02, 0.06); t_cuero = tela(256, 16, 0.03); t_pique = tela(512, 1, 0.09)
M = LO.Medidas(C); pr = {}
cam, (ys_c, Rs_c, cz_c) = T2.camisa(M, abierta=SEXO == 'f'); pr.update(cam)
if SEXO != 'f': pr.update(T2.corbata(M, ys_c, Rs_c, cz_c, M.yn - 0.33))
pr.update(T2.chaqueta(M, 'chaqueta')); pr.update(T2.pantalon(M)); pr.update(TJ.zapatos(M))
pr.update(T2.chaqueta(M, 'abrigo')); pr.update(T2.polo(M))
MAT = {'Camisa': ('f2f2ee', 0.8, t_lana), 'Corbata': ('7a1f2b', 0.45, t_seda), 'Chaqueta': ('2b2f36', 0.85, t_lana),
       'Chaqueta_solapa': ('262a30', 0.75, t_lana), 'Chaqueta_botones': ('15161a', 0.35, None),
       'Pantalon': ('2b2f36', 0.85, t_lana), 'Zapatos': ('1a1714', 0.35, t_cuero), 'Suela': ('0d0b0a', 0.8, None),
       'Abrigo': ('3a3f4a', 0.9, t_lana), 'Abrigo_solapa': ('343944', 0.85, t_lana), 'Abrigo_botones': ('15161a', 0.35, None),
       'Polo': ('1f5fa8', 0.85, t_pique), 'Polo_botones': ('f0f0ec', 0.4, None), 'Polo_escudo': ('f0c020', 0.5, None)}
for nombre, (pos, tri, uv) in pr.items():
    c, rug, tx = MAT[nombre]
    pz = LO.pieza(C, pos, tri, uv * ([1, 4] if nombre == 'Corbata' else [3, 6]))
    poner(g, 'Tr_' + nombre, pz, g.material('Tr_' + nombre, tuple(R.lin(R.hexrgb(c))) + (1,), rug, tx, doble=True))
OUT_R = BASE + '_ropa.glb'
g.escribir(OUT_R, m['orden'], m['qpadre'], m['GB'], 'MakeHuman assets CC0 1.0; recursos propios')
for o in (OUT_C, OUT_R): print('ok', o, round(os.path.getsize(o) / 1e6, 2), 'MB')
