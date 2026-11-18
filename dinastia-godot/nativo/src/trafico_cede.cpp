// El tráfico de la ciudad en C++ (18-11-2026), 3/3: la rejilla de ceder el paso (`_rejilla_paso`, `_en_hueco`, `_cede_paso`). Ver `trafico_nativo.cpp`.
#include "trafico_comun.h"

#include <godot_cpp/variant/utility_functions.hpp>

#include <cmath>

using namespace godot;
using namespace godot::trafico;

// `TraficoCiudad._rejilla_paso`
	// `TraficoCiudad._rejilla_paso`
void Paso::rejilla_paso(bool hay_cam, const Vector3 &ojo) {
	rejilla.clear();
	const int64_t n = vehiculos.size();
	for (int64_t idx = 0; idx < n; idx++) {
		Dictionary v = vehiculos[idx];
		const double alto = double(v[k.alto]);
		if (alto >= 0.3 || bool(v.get(k.oculto, false)) || int64_t(v.get(k.lod, 0)) > 0) {
			continue;
		}
		Node3D *nodo = nodo_de(v, k);
		if (nodo == nullptr) {
			continue;
		}
		const Vector3 q = nodo->get_position();
		if (hay_cam) {
			const double ax = std::abs(double(q.x) - double(ojo.x));
			const double az = std::abs(double(q.z) - double(ojo.z));
			if ((ax > az ? ax : az) > RADIO_PASO) {
				continue;
			}
		}
		Vector3 p, dir;
		ruta_en(ruta(int64_t(v[k.ruta])), double(v[k.s]), p, dir);
		const int64_t kx = int64_t(Math::floor(double(q.x) / CELDA_PASO));
		const int64_t kz = int64_t(Math::floor(double(q.z) / CELDA_PASO));
		rejilla[clave(kx, kz)].push_back({ idx, Vector2(q.x, q.z), Vector2(dir.x, dir.z).normalized(), alto < 0.05, q.y });
	}
}

// `TraficoCiudad._en_hueco`
	// `TraficoCiudad._en_hueco`
bool Paso::en_hueco(const Vector2 &pa, const Vector2 &da, bool coche, const Vector2 &pb, double ancho_extra) {
	const Vector2 rel = pb - pa;
	const Vector2 h = hueco(coche);
	const double frente = double(rel.dot(da));
	if (frente <= 0.2 || frente > double(h.x)) {
		return false;
	}
	return std::abs(double(rel.cross(da))) < double(h.y) + ancho_extra;
}

// `TraficoCiudad._cede_paso`
	// `TraficoCiudad._cede_paso`
bool Paso::cede_paso(Dictionary v, int64_t idx, double delta) {
	Node3D *nodo = nodo_de(v, k);
	if (nodo == nullptr || double(v[k.alto]) >= 0.3) {
		return false;
	}
	if (gf(v, k.cediendo, 0.0) > PACIENCIA_PASO) {
		v[k.cediendo] = 0.0;
		v[k.sin_ceder] = 1.5;
		return false;
	}
	if (gf(v, k.sin_ceder, 0.0) > 0.0) {
		v[k.sin_ceder] = double(v[k.sin_ceder]) - delta;
		return false;
	}
	const bool coche = double(v[k.alto]) < 0.05;
	const Vector3 npos = nodo->get_position();
	const Vector2 pa = Vector2(npos.x, npos.z);
	const int64_t ruta_i = int64_t(v[k.ruta]);
	Vector3 pp, d3;
	ruta_en(ruta(ruta_i), double(v[k.s]), pp, d3);
	const Vector2 da = Vector2(d3.x, d3.z).normalized();
	const int64_t kx0 = int64_t(Math::floor(double(pa.x) / CELDA_PASO));
	const int64_t kz0 = int64_t(Math::floor(double(pa.y) / CELDA_PASO));
	for (int dx = -1; dx < 2; dx++) {
		for (int dz = -1; dz < 2; dz++) {
			auto it = rejilla.find(clave(kx0 + dx, kz0 + dz));
			if (it == rejilla.end()) {
				continue;
			}
			for (const Ent &e : it->second) {
				const int64_t j = e.idx;
				if (j == idx) {
					continue;
				}
				Dictionary o = vehiculos[j];
				if (int64_t(o[k.ruta]) == ruta_i) {
					continue;
				}
				if (std::abs(double(e.y) - double(npos.y)) > 2.5) {
					continue;
				}
				const Vector2 pb = e.pos;
				const bool otro_coche = e.coche;
				if (coche && otro_coche && gf(o, k.espera, 0.0) > 0.0 && o.has(k.paradas) && double(da.dot(e.dir)) > 0.9) {
					const Vector2 rel_b = pb - pa;
					const double lado_b = std::abs(double(rel_b.dot(Vector2(-da.y, da.x))));
					const double frente_b = double(rel_b.dot(da));
					if (frente_b > -9.0 && frente_b < VISTA_ADELANTA && lado_b < 5.0) {
						v[k.lat_obj] = LAT_ADELANTA;
						v[k.t_lat] = 1.5;
					}
				}
				const bool de_frente = !coche && !otro_coche && double(da.dot(e.dir)) < -0.7;
				if (de_frente) {
					const Vector2 rel_o = pb - pa;
					const double frente_o = double(rel_o.dot(da));
					if (frente_o > 0.2 && frente_o < 4.0) {
						const double lado_o = double(rel_o.dot(Vector2(da.y, -da.x))) + gf(v, k.lat, 0.0);
						if (std::abs(lado_o - gf(v, k.lat, 0.0)) < SEPARA_LADO + 0.3) {
							esquivar(v, lado_o, -1.0);
						}
					}
				}
				const bool paralelo = coche && otro_coche && std::abs(double(da.dot(e.dir))) > 0.8;
				const double extra = otro_coche ? (paralelo ? 0.9 : 2.3) : 0.3;
				if (!en_hueco(pa, da, coche, pb, extra)) {
					continue;
				}
				if (!coche && otro_coche && en_hueco(pb, e.dir, true, pa, 0.3)) {
					continue;
				}
				if (coche == otro_coche && !de_frente && en_hueco(pb, e.dir, otro_coche, pa, coche ? extra : 0.3)) {
					const double der = double((pb - pa).dot(Vector2(-da.y, da.x)));
					const bool yo_cedo = std::abs(der) > 1.0 ? der > 1.0 : j < idx;
					if (!yo_cedo) {
						continue;
					}
				}
				v[k.cediendo] = gf(v, k.cediendo, 0.0) + delta;
				return true;
			}
		}
	}
	v[k.cediendo] = 0.0;
	return false;
}

