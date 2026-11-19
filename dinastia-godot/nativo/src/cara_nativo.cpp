// EL BORDE DE LA CARA PEGADO AL CRÁNEO, EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»). `visor/cara_malla.gd` (30-9-2026):
// `_pegar_borde` (por cada vértice del borde, la piel más cercana en la rejilla de 12 mm y el plano tangente) y `_rejilla_piel` (la rejilla), copiadas operación a
// operación (Vector3 en float de 32 bits y el resto en 64, como GDScript). Gemelas GDScript: `_pegar_borde_gd`, `_rejilla_piel_gd`. `pruebas/probar_nativo_cara.gd` las compara.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/vector3i.hpp>

#include <cmath>

using namespace godot;

namespace {
constexpr double CELDA = 0.012;
}

// `CaraMalla._pegar_borde` (sin el caso de «cuerpo vacío» ni `CARA_BORDE_Z`, que decide GDScript): [posiciones nuevas, distancia a la piel de cada vértice].
Array DinastiaNativo::cara_pegar_borde(const PackedVector3Array &pos, const PackedFloat32Array &alfa, const Dictionary &rejilla) const {
	PackedVector3Array salida = pos.duplicate();
	PackedFloat32Array lejos;
	lejos.resize(salida.size());
	lejos.fill(0.0f);
	const int64_t n = salida.size() < alfa.size() ? salida.size() : alfa.size();
	for (int64_t i = 0; i < n; i++) {
		const double a = double(alfa[i]);
		if (a >= 1.0) {
			continue;
		}
		const Vector3 q = salida[i];
		const Vector3 qc = (q / real_t(CELDA)).floor();
		const int cx = int(qc.x), cy = int(qc.y), cz = int(qc.z);
		bool hay = false;
		Vector3 mejor, n_mejor;
		double d_mejor = 0.022 * 0.022;
		// ±2 celdas (24 mm).
		for (int gx = cx - 2; gx < cx + 3; gx++) {
			for (int gy = cy - 2; gy < cy + 3; gy++) {
				for (int gz = cz - 2; gz < cz + 3; gz++) {
					const Variant clave = Vector3i(gx, gy, gz);
					if (!rejilla.has(clave)) {
						continue;
					}
					const Array celda = rejilla[clave];
					const PackedVector3Array pv = celda[0];
					const PackedVector3Array nv = celda[1];
					for (int64_t k = 0; k < pv.size(); k++) {
						const double dd = double(pv[k].distance_squared_to(q));
						if (dd < d_mejor) {
							d_mejor = dd;
							mejor = pv[k];
							n_mejor = nv[k];
							hay = true;
						}
					}
				}
			}
		}
		lejos.set(i, hay ? float(std::sqrt(d_mejor)) : 1.0f);
		if (!hay) {
			continue;
		}
		const real_t desp = real_t(double(n_mejor.dot(q - mejor)) - 0.0015);
		const Vector3 sobre = q - n_mejor * desp;
		const double peso = a <= 0.0 ? 1.0 : (a < 0.9 ? 0.85 : 0.5);
		salida.set(i, q.lerp(sobre, real_t(peso)));
	}
	Array res;
	res.push_back(salida);
	res.push_back(lejos);
	return res;
}

// `CaraMalla._rejilla_piel` (la construcción): celdas de 12 mm → [posiciones, normales] de la piel de la cabeza por delante de las orejas.
Dictionary DinastiaNativo::cara_rejilla_piel(const PackedVector3Array &cv, const PackedVector3Array &nn) const {
	Dictionary r;
	for (int64_t i = 0; i < cv.size(); i++) {
		const Vector3 p = cv[i];
		if (double(p.y) > 1.52 && double(p.z) > -0.002 && std::fabs(double(p.x)) < 0.11 && double(nn[i].length_squared()) > 0.5) {
			const Vector3 pc = (p / real_t(CELDA)).floor();
			const Variant k = Vector3i(int(pc.x), int(pc.y), int(pc.z));
			if (!r.has(k)) {
				Array par;
				par.push_back(PackedVector3Array());
				par.push_back(PackedVector3Array());
				r[k] = par;
			}
			Array par = r[k];
			PackedVector3Array pv = par[0];
			PackedVector3Array nv = par[1];
			pv.append(p);
			nv.append(nn[i].normalized());
			Array nuevo;
			nuevo.push_back(pv);
			nuevo.push_back(nv);
			r[k] = nuevo;
		}
	}
	return r;
}

// `CaraMalla._armar` (las normales): la suma de las normales de cada cara en sus vértices, normalizada (o hacia atrás, Vector3.BACK, si es nula). `n` = vértices.
PackedVector3Array DinastiaNativo::cara_normales(const PackedVector3Array &pos, const PackedInt32Array &tri, int64_t n) const {
	PackedVector3Array normales;
	normales.resize(n);
	for (int64_t t = 0; t < tri.size() - 2; t += 3) {
		const Vector3 a = pos[tri[t]];
		const Vector3 fn = (pos[tri[t + 1]] - a).cross(pos[tri[t + 2]] - a);
		for (int k = 0; k < 3; k++) {
			const int32_t v = tri[t + k];
			normales.set(v, normales[v] + fn);
		}
	}
	for (int64_t i = 0; i < n; i++) {
		const Vector3 q = normales[i];
		normales.set(i, double(q.length_squared()) > 0.0 ? q.normalized() : Vector3(0, 0, 1));
	}
	return normales;
}
