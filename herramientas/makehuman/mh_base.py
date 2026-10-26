"""Base MakeHuman (CC0) -> malla re-posada al esqueleto Quaternius/UE del juego (65 huesos).
Solo lee datos (obj, json, .target). Devuelve un dict con todo lo que necesitan recursos y escritor."""
import json, os
import numpy as np

DM = 0.1  # decímetros -> metros


def leer_obj(ruta):
    V, VT, F = [], [], []
    grupo = None
    for l in open(ruta):
        if l.startswith('v '): V.append([float(x) for x in l.split()[1:4]])
        elif l.startswith('vt '): VT.append([float(x) for x in l.split()[1:3]])
        elif l.startswith('g '): grupo = l.split()[1]
        elif l.startswith('f '):
            F.append((grupo, [tuple(int(a) - 1 for a in t.split('/')[:2]) for t in l.split()[1:]]))
    return np.array(V), np.array(VT), F


def quat_m(qq):
    x, y, z, w = qq
    return np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                     [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                     [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]])


def esqueleto_q(ruta):
    q = json.load(open(ruta))
    qn = q['nodes']; padre = {}
    for i, n in enumerate(qn):
        for c in n.get('children', []): padre[c] = i
    cache = {}
    def trs(n):
        M = np.eye(4)
        M[:3, :3] = quat_m(n.get('rotation', [0, 0, 0, 1])) @ np.diag(n.get('scale', [1, 1, 1]))
        M[:3, 3] = n.get('translation', [0, 0, 0]); return M
    def glob(i):
        if i not in cache: cache[i] = (glob(padre[i]) if i in padre else np.eye(4)) @ trs(qn[i])
        return cache[i]
    js = q['skins'][0]['joints']; nombres = {i: qn[i]['name'] for i in js}
    qpadre = {qn[i]['name']: (qn[padre[i]]['name'] if padre.get(i) in nombres else None) for i in js}
    rot, pos = {}, {}
    for i in js:
        R = glob(i)[:3, :3]; rot[qn[i]['name']] = R / np.linalg.norm(R, axis=0); pos[qn[i]['name']] = glob(i)[:3, 3]
    return qpadre, rot, pos


def alinear(a, b):
    a = a / np.linalg.norm(a); b = b / np.linalg.norm(b); v = np.cross(a, b); c = a @ b
    if np.linalg.norm(v) < 1e-9: return np.eye(3)
    K = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
    return np.eye(3) + K + K @ K * (1 / (1 + c))


PIERNA = {'thigh', 'calf', 'foot', 'ball'}
DED = {'thumb': 1, 'index': 2, 'middle': 3, 'ring': 4, 'pinky': 5}


def construir(data, qgltf, morfos_rel, sexo='m'):
    V, VT, F = leer_obj(os.path.join(data, '3dobjs/base.obj'))
    def target(rel):
        d = np.zeros_like(V)
        for l in open(os.path.join(data, 'targets', rel)):
            if l[0] == '#' or not l.strip(): continue
            p = l.split(); d[int(p[0])] = [float(x) for x in p[1:4]]
        return d
    MD = 'macrodetails/'; sx = 'female' if sexo == 'f' else 'male'
    def uni(edad, mus, peso): return target(MD + f'universal-{sx}-{edad}-{mus}muscle-{peso}weight.target')
    joven = uni('young', 'average', 'average') + target(MD + f'caucasian-{sx}-young.target')
    viejo = uni('old', 'average', 'average') + target(MD + f'caucasian-{sx}-old.target')
    base = V + joven
    ua = uni('young', 'average', 'average')
    morfos = {'edad': viejo - joven,
              'peso_mas': uni('young', 'average', 'max') - ua, 'peso_menos': uni('young', 'average', 'min') - ua,
              'musculo': uni('young', 'max', 'average') - ua, 'barriga': target('stomach/stomach-pregnant-incr.target')}
    for k, rel in morfos_rel.items():
        morfos[k] = sum(target(r) for r in rel.split('+'))
    mascaras = {'labios': np.linalg.norm(target('mouth/mouth-lowerlip-volume-incr.target'), axis=1)
                + np.linalg.norm(target('mouth/mouth-upperlip-volume-incr.target'), axis=1)}
    base = base * DM; base[:, 1] -= base[:, 1].min()
    for k in morfos: morfos[k] = morfos[k] * DM

    sk = json.load(open(os.path.join(data, 'rigs/default.mhskel')))
    def jpos(j): return base[sk['joints'][j]].mean(0)
    def head(b): return jpos(sk['bones'][b]['head'])
    def tail(b): return jpos(sk['bones'][b]['tail'])
    wmh = json.load(open(os.path.join(data, 'rigs/default_weights.mhw')))['weights']
    qpadre, QROT, QPOS = esqueleto_q(qgltf)

    POS = {'root': np.zeros(3), 'pelvis': head('root'), 'spine_01': head('spine04'), 'spine_02': head('spine03'),
           'spine_03': head('spine01'), 'neck_01': head('neck01'), 'Head': head('head')}
    PESO = {'root': 'pelvis', 'spine05': 'pelvis', 'pelvis.L': 'pelvis', 'pelvis.R': 'pelvis', 'spine04': 'spine_01',
            'spine03': 'spine_02', 'spine02': 'spine_02', 'spine01': 'spine_03', 'breast.L': 'spine_03',
            'breast.R': 'spine_03', 'neck01': 'neck_01', 'neck02': 'neck_01', 'neck03': 'neck_01'}
    HIJO = {}
    for L, s in (('L', 'l'), ('R', 'r')):
        POS.update({f'clavicle_{s}': head(f'clavicle.{L}'), f'upperarm_{s}': head(f'upperarm01.{L}'),
                    f'lowerarm_{s}': head(f'lowerarm01.{L}'), f'hand_{s}': head(f'wrist.{L}'),
                    f'thigh_{s}': head(f'upperleg01.{L}'), f'calf_{s}': head(f'lowerleg01.{L}'),
                    f'foot_{s}': head(f'foot.{L}'), f'ball_{s}': head(f'toe3-1.{L}'), f'ball_leaf_{s}': tail(f'toe3-3.{L}')})
        for d, k in DED.items():
            for j in (1, 2, 3):
                POS[f'{d}_0{j}_{s}'] = head(f'finger{k}-{j}.{L}'); PESO[f'finger{k}-{j}.{L}'] = f'{d}_0{j}_{s}'
                HIJO[f'{d}_0{j}_{s}'] = f'{d}_0{j + 1}_{s}' if j < 3 else f'{d}_04_leaf_{s}'
            POS[f'{d}_04_leaf_{s}'] = tail(f'finger{k}-3.{L}')
        PESO.update({f'clavicle.{L}': f'clavicle_{s}', f'shoulder01.{L}': f'clavicle_{s}',
                     f'upperarm01.{L}': f'upperarm_{s}', f'upperarm02.{L}': f'upperarm_{s}',
                     f'lowerarm01.{L}': f'lowerarm_{s}', f'lowerarm02.{L}': f'lowerarm_{s}', f'wrist.{L}': f'hand_{s}',
                     f'upperleg01.{L}': f'thigh_{s}', f'upperleg02.{L}': f'thigh_{s}',
                     f'lowerleg01.{L}': f'calf_{s}', f'lowerleg02.{L}': f'calf_{s}', f'foot.{L}': f'foot_{s}'})
        for m in range(1, 5): PESO[f'metacarpal{m}.{L}'] = f'hand_{s}'
        for t in range(1, 6):
            for j in (1, 2, 3): PESO[f'toe{t}-{j}.{L}'] = f'ball_{s}'
        HIJO.update({f'clavicle_{s}': f'upperarm_{s}', f'upperarm_{s}': f'lowerarm_{s}', f'lowerarm_{s}': f'hand_{s}',
                     f'hand_{s}': f'middle_01_{s}',
                     f'thigh_{s}': f'calf_{s}', f'calf_{s}': f'foot_{s}', f'foot_{s}': f'ball_{s}'})
    assert set(POS) == set(QPOS), set(QPOS) ^ set(POS)

    orden = []
    def visitar(nm):
        orden.append(nm)
        for c in [k for k, p in qpadre.items() if p == nm]: visitar(c)
    visitar([k for k, p in qpadre.items() if p is None][0])
    G, R, NPOS = {}, {}, {}
    for nm in orden:
        pa = qpadre[nm]
        Rp = R[pa] if pa else np.eye(3); Gp = G[pa] if pa else np.eye(4)
        h = (Gp @ np.append(POS[nm], 1))[:3]
        if nm == 'pelvis':
            h = QPOS['pelvis'].copy()
        elif nm.split('_')[0] in PIERNA and pa:
            h = NPOS[pa] + (QPOS[nm] - QPOS[pa])  # largos de pierna de Quaternius (pies sobre el césped)
        NPOS[nm] = h
        Rb = Rp
        if nm in HIJO:
            Rb = alinear(Rp @ (POS[HIJO[nm]] - POS[nm]), QPOS[HIJO[nm]] - QPOS[nm]) @ Rp
        R[nm] = Rb; M = np.eye(4); M[:3, :3] = Rb; M[:3, 3] = h - Rb @ POS[nm]; G[nm] = M

    NB = len(orden); bi = {nm: i for i, nm in enumerate(orden)}
    W = np.zeros((len(V), NB))
    for b, lst in wmh.items():
        for vi, w in lst: W[vi, bi[PESO.get(b, 'Head')]] += w
    W[W.sum(1) == 0, bi['Head']] = 1
    W /= W.sum(1, keepdims=True)
    Mv = np.einsum('vb,bij->vij', W, np.stack([G[nm] for nm in orden]))
    pos = np.einsum('vij,vj->vi', Mv[:, :3, :3], base) + Mv[:, :3, 3]
    morf = {k: np.einsum('vij,vj->vi', Mv[:, :3, :3], d) for k, d in morfos.items()}
    GB = {}
    for nm in orden:
        M = np.eye(4); M[:3, :3] = QROT[nm]; M[:3, 3] = NPOS[nm]; GB[nm] = M
    return {'V': pos, 'VT': VT, 'F': F, 'W': W, 'orden': orden, 'bi': bi, 'qpadre': qpadre, 'GB': GB,
            'morfos': morf, 'mascaras': mascaras, 'NPOS': NPOS, 'QPOS': QPOS}


def caras(F, grupos):
    """Caras (índices de vértice y de uv) de los grupos dados, trianguladas."""
    tv, tt = [], []
    for g, f in F:
        if g not in grupos: continue
        for k in range(1, len(f) - 1):
            tv.append([f[0][0], f[k][0], f[k + 1][0]]); tt.append([f[0][1], f[k][1], f[k + 1][1]])
    return np.array(tv), np.array(tt)


def normales(p, tri):
    n = np.zeros_like(p); a, b, c = p[tri[:, 0]], p[tri[:, 1]], p[tri[:, 2]]
    fn = np.cross(b - a, c - a)
    for k in range(3): np.add.at(n, tri[:, k], fn)
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
