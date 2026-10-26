"""Escritor glTF binario (.glb) para las piezas del modelo: skin común, morphs dispersos, texturas PNG."""
import json, struct
import numpy as np


def m2trs(M):
    t = M[:3, 3]; Rm = M[:3, :3]
    w = np.sqrt(max(0, 1 + Rm[0, 0] + Rm[1, 1] + Rm[2, 2])) / 2
    x = np.sqrt(max(0, 1 + Rm[0, 0] - Rm[1, 1] - Rm[2, 2])) / 2
    y = np.sqrt(max(0, 1 - Rm[0, 0] + Rm[1, 1] - Rm[2, 2])) / 2
    z = np.sqrt(max(0, 1 - Rm[0, 0] - Rm[1, 1] + Rm[2, 2])) / 2
    x = np.copysign(x, Rm[2, 1] - Rm[1, 2]); y = np.copysign(y, Rm[0, 2] - Rm[2, 0]); z = np.copysign(z, Rm[1, 0] - Rm[0, 1])
    qq = np.array([x, y, z, w]); qq /= np.linalg.norm(qq)
    return {'translation': t.tolist(), 'rotation': qq.tolist()}


class Glb:
    def __init__(self):
        self.blob = bytearray(); self.views = []; self.accs = []
        self.images = []; self.textures = []; self.mats = []; self.meshes = []

    def _vista(self, b, target=None):
        while len(self.blob) % 4: self.blob.append(0)
        off = len(self.blob); self.blob.extend(b)
        v = {'buffer': 0, 'byteOffset': off, 'byteLength': len(b)}
        if target: v['target'] = target
        self.views.append(v); return len(self.views) - 1

    def acc(self, arr, comp, tipo, target=None, minmax=False, norm=False):
        arr = np.ascontiguousarray(arr)
        a = {'bufferView': self._vista(arr.tobytes(), target), 'componentType': comp, 'count': len(arr), 'type': tipo}
        if minmax: a['min'] = arr.min(0).tolist(); a['max'] = arr.max(0).tolist()
        if norm: a['normalized'] = True
        self.accs.append(a); return len(self.accs) - 1

    def acc_disperso(self, d):
        d = d.astype(np.float32); idx = np.nonzero(np.abs(d).max(1) > 1e-6)[0].astype(np.uint32)
        a = {'componentType': 5126, 'count': len(d), 'type': 'VEC3',
             'min': d.min(0).tolist(), 'max': d.max(0).tolist()}
        if len(idx):
            a['sparse'] = {'count': int(len(idx)),
                           'indices': {'bufferView': self._vista(idx.tobytes()), 'componentType': 5125},
                           'values': {'bufferView': self._vista(np.ascontiguousarray(d[idx]).tobytes())}}
        else:
            a['bufferView'] = self._vista(d.tobytes())
        self.accs.append(a); return len(self.accs) - 1

    def textura(self, png_bytes, mime='image/png'):
        self.images.append({'bufferView': self._vista(png_bytes), 'mimeType': mime})
        self.textures.append({'source': len(self.images) - 1}); return len(self.textures) - 1

    def material(self, nombre, color=(1, 1, 1, 1), rug=0.7, tex=None, alfa=None, doble=False):
        m = {'name': nombre, 'pbrMetallicRoughness': {'baseColorFactor': list(color), 'metallicFactor': 0.0,
                                                       'roughnessFactor': rug}}
        if tex is not None: m['pbrMetallicRoughness']['baseColorTexture'] = {'index': tex}
        if alfa == 'MASK': m['alphaMode'] = 'MASK'; m['alphaCutoff'] = 0.5
        elif alfa == 'BLEND': m['alphaMode'] = 'BLEND'
        if doble: m['doubleSided'] = True
        self.mats.append(m); return len(self.mats) - 1

    def malla(self, nombre, pos, nrm, tri, joints, weights, mat, uv=None, col=None, morfos=None):
        at = {'POSITION': self.acc(pos.astype(np.float32), 5126, 'VEC3', 34962, True),
              'NORMAL': self.acc(nrm.astype(np.float32), 5126, 'VEC3', 34962),
              'JOINTS_0': self.acc(joints.astype(np.uint16), 5123, 'VEC4', 34962),
              'WEIGHTS_0': self.acc(weights.astype(np.float32), 5126, 'VEC4', 34962)}
        if uv is not None: at['TEXCOORD_0'] = self.acc(uv.astype(np.float32), 5126, 'VEC2', 34962)
        if col is not None: at['COLOR_0'] = self.acc(col.astype(np.uint8), 5121, 'VEC4', 34962, norm=True)
        prim = {'attributes': at, 'indices': self.acc(tri.astype(np.uint32).reshape(-1), 5125, 'SCALAR', 34963),
                'material': mat}
        me = {'name': nombre, 'primitives': [prim]}
        if morfos:
            usados = [k for k, d in morfos.items() if np.abs(d).max() > 1e-5]
            if usados:
                prim['targets'] = [{'POSITION': self.acc_disperso(morfos[k])} for k in usados]
                me['extras'] = {'targetNames': usados}; me['weights'] = [0.0] * len(usados)
        self.meshes.append(me)

    def escribir(self, ruta, orden, qpadre, GB, info):
        bi = {nm: i for i, nm in enumerate(orden)}; NB = len(orden)
        nodes = []
        for nm in orden:
            pa = qpadre[nm]; L = np.linalg.inv(GB[pa]) @ GB[nm] if pa else GB[nm]
            n = {'name': nm, **m2trs(L)}
            ch = [bi[c] for c in orden if qpadre[c] == nm]
            if ch: n['children'] = ch
            nodes.append(n)
        ibm = np.stack([np.linalg.inv(GB[nm]).T for nm in orden]).astype(np.float32)
        skin = {'joints': list(range(NB)), 'inverseBindMatrices': self.acc(ibm.reshape(NB, 16), 5126, 'MAT4'),
                'skeleton': 0}
        for i, me in enumerate(self.meshes): nodes.append({'name': me['name'], 'mesh': i, 'skin': 0})
        nodes.append({'name': 'Armature', 'children': [0] + list(range(NB, NB + len(self.meshes)))})
        g = {'asset': {'version': '2.0', 'generator': 'mh_a_glb', 'copyright': info},
             'scene': 0, 'scenes': [{'nodes': [len(nodes) - 1]}], 'nodes': nodes, 'meshes': self.meshes,
             'materials': self.mats, 'skins': [skin], 'accessors': self.accs, 'bufferViews': self.views,
             'buffers': [{'byteLength': 0}]}
        if self.images: g['images'] = self.images; g['textures'] = self.textures
        while len(self.blob) % 4: self.blob.append(0)
        g['buffers'][0]['byteLength'] = len(self.blob)
        js = json.dumps(g).encode(); js += b' ' * ((4 - len(js) % 4) % 4)
        with open(ruta, 'wb') as fo:
            fo.write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(self.blob)))
            fo.write(struct.pack('<II', len(js), 0x4E4F534A)); fo.write(js)
            fo.write(struct.pack('<II', len(self.blob), 0x004E4942)); fo.write(self.blob)
