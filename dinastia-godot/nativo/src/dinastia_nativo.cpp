// Ver dinastia_nativo.h. Cada función sigue paso a paso a su original en GDScript.
#include "dinastia_nativo.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/vector3i.hpp>

#include <unordered_map>
#include <vector>

using namespace godot;

void DinastiaNativo::_bind_methods() {
	ClassDB::bind_method(D_METHOD("rampa", "src", "lut"), &DinastiaNativo::rampa);
	ClassDB::bind_method(D_METHOD("alisado", "pos", "nor", "idx"), &DinastiaNativo::alisado);
	ClassDB::bind_method(D_METHOD("terreno", "ruido", "detalle", "lado", "celdas", "baldosas", "llano_radio", "llano_trans", "alto", "monte", "monte_alto", "monte_radio"), &DinastiaNativo::terreno);
	ClassDB::bind_method(D_METHOD("hierba", "manchas", "semilla"), &DinastiaNativo::hierba);
}

PackedByteArray DinastiaNativo::rampa(const PackedByteArray &src, const PackedByteArray &lut) const {
	PackedByteArray dst;
	const int64_t n = src.size();
	dst.resize(n * 4);
	if (lut.size() < 256 * 4) {
		return dst;
	}
	const uint8_t *s = src.ptr();
	const uint8_t *l = lut.ptr();
	uint8_t *d = dst.ptrw();
	for (int64_t i = 0; i < n; i++) {
		const int o = int(s[i]) * 4;
		d[i * 4] = l[o];
		d[i * 4 + 1] = l[o + 1];
		d[i * 4 + 2] = l[o + 2];
		d[i * 4 + 3] = l[o + 3];
	}
	return dst;
}

namespace {
struct HashV3i {
	size_t operator()(const Vector3i &v) const {
		return (size_t(uint32_t(v.x)) * 73856093u) ^ (size_t(uint32_t(v.y)) * 19349663u) ^ (size_t(uint32_t(v.z)) * 83492791u);
	}
};
struct IgualV3i {
	bool operator()(const Vector3i &a, const Vector3i &b) const { return a == b; }
};
} // namespace

Array DinastiaNativo::alisado(const PackedVector3Array &pos, const PackedVector3Array &nor, const PackedInt32Array &idx) const {
	const int64_t n = pos.size();
	PackedFloat32Array c0;
	PackedFloat32Array c1;
	c0.resize(n * 4);
	c1.resize(n * 3);
	Array salida;
	if (n == 0) {
		salida.push_back(c0);
		salida.push_back(c1);
		return salida;
	}
	// Soldar los vértices duplicados en las costuras de UV (misma posición).
	std::unordered_map<Vector3i, int, HashV3i, IgualV3i> id_de;
	std::vector<int> soldado(n);
	std::vector<Vector3> unicos;
	for (int64_t i = 0; i < n; i++) {
		const Vector3 r = (pos[i] * real_t(10000.0)).round();
		const Vector3i k(int32_t(r.x), int32_t(r.y), int32_t(r.z));
		auto it = id_de.find(k);
		if (it == id_de.end()) {
			it = id_de.emplace(k, int(unicos.size())).first;
			unicos.push_back(pos[i]);
		}
		soldado[i] = it->second;
	}
	const int64_t m = int64_t(unicos.size());
	std::vector<std::vector<int>> vecinos(m);
	const int64_t ni = idx.size();
	auto tiene = [](const std::vector<int> &v, int x) {
		for (int y : v) {
			if (y == x) {
				return true;
			}
		}
		return false;
	};
	for (int64_t t = 0; t < ni - 2; t += 3) {
		const int a = soldado[idx[t]];
		const int b = soldado[idx[t + 1]];
		const int c = soldado[idx[t + 2]];
		const int pares[3][2] = { { a, b }, { b, c }, { c, a } };
		for (const auto &par : pares) {
			const int u = par[0];
			const int w = par[1];
			if (!tiene(vecinos[u], w)) {
				vecinos[u].push_back(w);
			}
			if (!tiene(vecinos[w], u)) {
				vecinos[w].push_back(u);
			}
		}
	}
	// Taubin: un paso que encoge (lambda) y otro que infla (mu). Como en GDScript: la media en
	// Vector3 (32 bits) y el factor `f` (64 bits) convertido a 32 al multiplicar.
	std::vector<Vector3> p = unicos;
	std::vector<Vector3> q;
	for (int it = 0; it < 110; it++) {
		const double f = (it % 2 == 0) ? 0.62 : -0.5;
		q = p;
		for (int64_t i = 0; i < m; i++) {
			const std::vector<int> &vs = vecinos[i];
			if (vs.empty()) {
				continue;
			}
			Vector3 media;
			for (int v : vs) {
				media += p[v];
			}
			media /= real_t(double(vs.size()));
			q[i] = p[i] + (media - p[i]) * real_t(f);
		}
		p.swap(q);
	}
	// Normales de la superficie alisada.
	std::vector<Vector3> ns(m);
	for (int64_t t = 0; t < ni - 2; t += 3) {
		const int a2 = soldado[idx[t]];
		const int b2 = soldado[idx[t + 1]];
		const int c2 = soldado[idx[t + 2]];
		const Vector3 fn = (p[b2] - p[a2]).cross(p[c2] - p[a2]);
		ns[a2] += fn;
		ns[b2] += fn;
		ns[c2] += fn;
	}
	float *d0 = c0.ptrw();
	float *d1 = c1.ptrw();
	for (int64_t i = 0; i < n; i++) {
		const int w2 = soldado[i];
		const Vector3 nr = i < nor.size() ? nor[i] : Vector3();
		Vector3 sn = ns[w2].normalized();
		if (double(sn.dot(nr)) < 0.0) {
			sn = -sn;
		}
		const double relleno = double((p[w2] - pos[i]).dot(nr));
		d0[i * 4] = sn.x;
		d0[i * 4 + 1] = sn.y;
		d0[i * 4 + 2] = sn.z;
		d0[i * 4 + 3] = float(CLAMP(relleno, -0.035, 0.03));
		d1[i * 3] = nr.x;
		d1[i * 3 + 1] = nr.y;
		d1[i * 3 + 2] = nr.z;
	}
	salida.push_back(c0);
	salida.push_back(c1);
	return salida;
}
