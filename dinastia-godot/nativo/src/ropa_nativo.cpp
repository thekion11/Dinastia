// LA ROPA APARTE, EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»). `visor/ropa_separada.gd` (26-9-2026): los bucles por vértice y por triángulo
// de `mallas()`, copiados operación a operación (la zona de cada vértice, los triángulos de la prenda, el reordenado y el desplazamiento por la holgura) y `_subconjunto`.
// La gemela GDScript se queda como respaldo (`_prenda_gd`, `_subconjunto_gd`). Vector3 en float de 32 bits, el resto en 64, como GDScript. `pruebas/probar_nativo_ropa.gd` las compara.
#include "dinastia_nativo.h"

#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>

#include <cmath>
#include <vector>

using namespace godot;

namespace {
// `RopaSeparada.prenda_en`.
inline int prenda_en(const Vector3 &p) {
	const double ax = std::fabs(double(p.x));
	const double y = double(p.y);
	if (ax > 0.215 && y > 1.2) {
		return ax < 0.44 ? 1 : 0;
	}
	if (y >= 0.955 && y < 1.535) {
		return 1;
	}
	if (y >= 0.6 && y < 1.03) {
		return 2;
	}
	if (y >= 0.09 && y < 0.48) {
		return 3;
	}
	return 0;
}

// `RopaSeparada.holgura_en`.
inline double holgura_en(int prenda, const Vector3 &p) {
	const double ax = std::fabs(double(p.x));
	const double y = double(p.y);
	switch (prenda) {
		case 1:
			if (ax > 0.215 && y > 1.2) {
				return 0.016 + 0.03 * Math::smoothstep(0.24, 0.43, ax);
			}
			return 0.02 + 0.018 * Math::smoothstep(1.3, 1.0, y);
		case 2:
			return 0.024 + 0.03 * Math::smoothstep(0.85, 0.61, y);
		case 3:
			return 0.006;
		default:
			return 0.0;
	}
}
}  // namespace

// Lo que `RopaSeparada.mallas` saca para UNA prenda `cual`: [índices nuevos, orden (vértice original de cada nuevo), posiciones, normales], o [] si no hay triángulos.
Array DinastiaNativo::ropa_prenda(const PackedVector3Array &pos, const PackedVector3Array &nor, const PackedInt32Array &idx, int64_t cual) const {
	const int64_t n = pos.size();
	std::vector<int32_t> zona(n);
	for (int64_t i = 0; i < n; i++) {
		zona[i] = prenda_en(pos[i]);
	}
	std::vector<int32_t> mapa(n, -1);
	std::vector<int32_t> orden;
	PackedInt32Array nuevos;
	const int32_t *pi = idx.ptr();
	for (int64_t t = 0; t + 2 < idx.size(); t += 3) {
		const int32_t a = pi[t], b = pi[t + 1], c = pi[t + 2];
		if (zona[a] != cual || zona[b] != cual || zona[c] != cual) {
			continue;
		}
		const int32_t tri[3] = { a, b, c };
		for (int k = 0; k < 3; k++) {
			const int32_t v = tri[k];
			if (mapa[v] < 0) {
				mapa[v] = int32_t(orden.size());
				orden.push_back(v);
			}
			nuevos.append(mapa[v]);
		}
	}
	Array res;
	if (nuevos.is_empty()) {
		return res;
	}
	PackedInt32Array o;
	PackedVector3Array p2, n2;
	o.resize(orden.size());
	p2.resize(orden.size());
	n2.resize(orden.size());
	for (int64_t i = 0; i < int64_t(orden.size()); i++) {
		const int32_t v = orden[i];
		const Vector3 p = pos[v];
		const Vector3 nn = nor[v];
		Vector3 q = p + nn * real_t(holgura_en(int(cual), p));
		// El bajo de la camiseta cae un poco.
		if (cual == 1 && double(p.y) < 1.03 && std::fabs(double(p.x)) < 0.215) {
			q.y = real_t(double(q.y) - 0.012 * Math::smoothstep(1.03, 0.96, double(p.y)));
		}
		o.set(i, v);
		p2.set(i, q);
		n2.set(i, nn);
	}
	res.push_back(nuevos);
	res.push_back(o);
	res.push_back(p2);
	res.push_back(n2);
	return res;
}

// `RopaSeparada._subconjunto`: los elementos `orden` de un array empaquetado (`ancho` valores por vértice); otro tipo se devuelve igual.
Variant DinastiaNativo::ropa_subconjunto(const Variant &src, const PackedInt32Array &orden, int64_t ancho) const {
	const int64_t m = orden.size();
	switch (src.get_type()) {
		case Variant::PACKED_VECTOR2_ARRAY: {
			const PackedVector2Array s = src;
			PackedVector2Array o;
			o.resize(m);
			for (int64_t i = 0; i < m; i++) {
				o.set(i, s[orden[i]]);
			}
			return o;
		}
		case Variant::PACKED_VECTOR3_ARRAY: {
			const PackedVector3Array s = src;
			PackedVector3Array o;
			o.resize(m);
			for (int64_t i = 0; i < m; i++) {
				o.set(i, s[orden[i]]);
			}
			return o;
		}
		case Variant::PACKED_COLOR_ARRAY: {
			const PackedColorArray s = src;
			PackedColorArray o;
			o.resize(m);
			for (int64_t i = 0; i < m; i++) {
				o.set(i, s[orden[i]]);
			}
			return o;
		}
		case Variant::PACKED_FLOAT32_ARRAY: {
			const PackedFloat32Array s = src;
			PackedFloat32Array o;
			o.resize(m * ancho);
			for (int64_t i = 0; i < m; i++) {
				for (int64_t k = 0; k < ancho; k++) {
					o.set(i * ancho + k, s[int64_t(orden[i]) * ancho + k]);
				}
			}
			return o;
		}
		case Variant::PACKED_INT32_ARRAY: {
			const PackedInt32Array s = src;
			PackedInt32Array o;
			o.resize(m * ancho);
			for (int64_t i = 0; i < m; i++) {
				for (int64_t k = 0; k < ancho; k++) {
					o.set(i * ancho + k, s[int64_t(orden[i]) * ancho + k]);
				}
			}
			return o;
		}
		default:
			return src;
	}
}
