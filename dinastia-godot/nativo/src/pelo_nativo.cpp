// LAS CUENTAS DEL PELO POR CAPAS, EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»). `visor/pelo_capas_p1.gd` (30-9-2026): `_normales`, `_densidades`, `_max` y
// `visor/pelo_capas.gd`: `_suavizar`, copiadas operación a operación (Vector3 en float de 32 bits, el resto en 64, como GDScript). Gemelas GDScript: `_normales_gd`,
// `_densidades_gd`, `_max_gd` y `_suavizar_gd`. `pruebas/probar_nativo_pelo.gd` las compara byte a byte.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/vector3.hpp>

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
