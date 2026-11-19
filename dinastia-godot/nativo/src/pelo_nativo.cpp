// LAS CUENTAS DEL PELO POR CAPAS, EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»). `visor/pelo_capas_p1.gd` (30-9-2026): `_normales`, `_densidades`, `_max` y
// `visor/pelo_capas.gd`: `_suavizar`, copiadas operación a operación (Vector3 en float de 32 bits, el resto en 64, como GDScript). Gemelas GDScript: `_normales_gd`,
// `_densidades_gd`, `_max_gd` y `_suavizar_gd`. `pruebas/probar_nativo_pelo.gd` las compara byte a byte.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/vector3.hpp>

#include <cmath>
#include <vector>

using namespace godot;

// `PeloCapas._normales`: normal por vértice (suma de las normales de sus caras, vuelta hacia fuera: la nariz, vértice 1, hacia delante).
PackedVector3Array DinastiaNativo::pelo_normales(const PackedVector3Array &pos, const PackedInt32Array &tri) const {
	PackedVector3Array n;
	n.resize(pos.size());
	for (int64_t t = 0; t < tri.size() - 2; t += 3) {
		const Vector3 a = pos[tri[t]];
		const Vector3 fn = (pos[tri[t + 1]] - a).cross(pos[tri[t + 2]] - a);
		for (int j = 0; j < 3; j++) {
			const int32_t v = tri[t + j];
			n.set(v, n[v] + fn);
		}
	}
	const double signo = (n.size() > 1 ? double(n[1].z) >= 0.0 : true) ? 1.0 : -1.0;
	for (int64_t i = 0; i < n.size(); i++) {
		n.set(i, (n[i] * real_t(signo)).normalized());
	}
	return n;
}

// `PeloCapas._densidades` (la cuenta): cada byte entre 255, hasta `n` valores (el resto, ceros).
PackedFloat32Array DinastiaNativo::pelo_densidades(const PackedByteArray &bytes, int64_t n) const {
	PackedFloat32Array out;
	out.resize(n);
	const int64_t m = bytes.size() < n ? bytes.size() : n;
	for (int64_t i = 0; i < m; i++) {
		out.set(i, float(double(bytes[i]) / 255.0));
	}
	return out;
}

// `PeloCapas._max`: el mayor valor (o 0).
double DinastiaNativo::pelo_max(const PackedFloat32Array &a) const {
	double m = 0.0;
	for (int64_t i = 0; i < a.size(); i++) {
		const double v = double(a[i]);
		m = m > v ? m : v;
	}
	return m;
}

// `PeloCapas._suavizar`: reparte un poco de cada valor a sus vecinos (el mayor de lo que ya tenía y `a * f`).
PackedFloat32Array DinastiaNativo::pelo_suavizar(const PackedFloat32Array &a, const PackedInt32Array &tri, double f) const {
	PackedFloat32Array out = a.duplicate();
	for (int64_t t = 0; t < tri.size() - 2; t += 3) {
		for (int j = 0; j < 3; j++) {
			const int64_t i0 = tri[t + j];
			for (int kk = 0; kk < 3; kk++) {
				const int64_t i1 = tri[t + kk];
				if (i0 < a.size() && i1 < a.size()) {
					const double actual = double(out[i1]);
					const double nuevo = double(a[i0]) * f;
					out.set(i1, float(actual > nuevo ? actual : nuevo));
				}
			}
		}
	}
	return out;
}

// `PeloCapas._solo_con`: los triángulos con al menos `minimo` vértices de densidad mayor que 0,02.
PackedInt32Array DinastiaNativo::pelo_solo_con(const PackedInt32Array &tri, const PackedFloat32Array &dens, int64_t minimo) const {
	PackedInt32Array out;
	for (int64_t t = 0; t < tri.size() - 2; t += 3) {
		int64_t n = 0;
		for (int j = 0; j < 3; j++) {
			const int64_t v = tri[t + j];
			if (v < dens.size() && double(dens[v]) > 0.02) {
				n++;
			}
		}
		if (n >= minimo) {
			out.append(tri[t]);
			out.append(tri[t + 1]);
			out.append(tri[t + 2]);
		}
	}
	return out;
}

// `PeloCapas._anillo`: los vértices a `anillos` pasos (por triángulos) de los de `base`, como Dictionary {vértice: true} en el MISMO orden de inserción.
Dictionary DinastiaNativo::pelo_anillo(const PackedInt32Array &base, const PackedInt32Array &tri, int64_t anillos) const {
	int32_t mayor = -1;
	for (int64_t i = 0; i < base.size(); i++) {
		mayor = base[i] > mayor ? base[i] : mayor;
	}
	for (int64_t i = 0; i < tri.size(); i++) {
		mayor = tri[i] > mayor ? tri[i] : mayor;
	}
	std::vector<char> dentro(size_t(mayor + 1), 0);
	std::vector<int32_t> orden;
	auto meter = [&](int32_t v) {
		if (v >= 0 && !dentro[v]) {
			dentro[v] = 1;
			orden.push_back(v);
		}
	};
	for (int64_t i = 0; i < base.size(); i++) {
		meter(base[i]);
	}
	for (int64_t k = 0; k < anillos; k++) {
		std::vector<char> visto(size_t(mayor + 1), 0);
		std::vector<int32_t> nuevos;
		for (int64_t t = 0; t < tri.size() - 2; t += 3) {
			const int32_t a = tri[t], b = tri[t + 1], c = tri[t + 2];
			if ((a >= 0 && dentro[a]) || (b >= 0 && dentro[b]) || (c >= 0 && dentro[c])) {
				const int32_t tv[3] = { a, b, c };
				for (int j = 0; j < 3; j++) {
					if (tv[j] >= 0 && !visto[tv[j]]) {
						visto[tv[j]] = 1;
						nuevos.push_back(tv[j]);
					}
				}
			}
		}
		for (int32_t v : nuevos) {
			meter(v);
		}
	}
	Dictionary d;
	for (int32_t v : orden) {
		d[int64_t(v)] = true;
	}
	return d;
}

// `PeloCapas._candidatos_cuero` (la cuenta): [vértices por encima de 1,52 m y dentro de ±14 cm, triángulos que tocan alguno, en su orden].
Array DinastiaNativo::pelo_candidatos(const PackedVector3Array &v, const PackedInt32Array &ind) const {
	PackedInt32Array verts, tri;
	std::vector<char> marca(size_t(v.size()), 0);
	for (int64_t i = 0; i < v.size(); i++) {
		const Vector3 p = v[i];
		if (double(p.y) < 1.52 || std::fabs(double(p.x)) > 0.14) {
			continue;
		}
		verts.append(int32_t(i));
		marca[size_t(i)] = 1;
	}
	for (int64_t t = 0; t < ind.size() - 2; t += 3) {
		if (marca[size_t(ind[t])] || marca[size_t(ind[t + 1])] || marca[size_t(ind[t + 2])]) {
			tri.append(ind[t]);
			tri.append(ind[t + 1]);
			tri.append(ind[t + 2]);
		}
	}
	Array res;
	res.push_back(verts);
	res.push_back(tri);
	return res;
}
