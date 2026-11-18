// EL TRÁFICO DE LA CIUDAD 3D, EN C++ (18-11-2026, orden del dueño: la ciudad a C++, sin tocar lo visual).
// Traducción LITERAL de `TraficoCiudad._process` (visor/trafico_ciudad.gd) y de sus auxiliares: `Ruta.en`, `_rejilla_paso`,
// `_cede_paso`, `_en_hueco`, `_lateral`, `_mirar_delante`, `_esquivar`, `tapa_al_jugador`, `sirena_cerca`, `_colocar` y la parte
// numérica de `MovimientoNatural.marcha/girar`. Mismas operaciones en el mismo orden y misma precisión (float de 64 bits donde
// GDScript usa `float`; de 32 donde usa Vector2/Vector3) y MISMO ORDEN de llamadas a `randf()` (comparte el azar global del motor).
// Lo que sigue en GDScript (animaciones, gestos, semáforos, mirada) se llama de vuelta con `call`. La versión GDScript
// (`_paso_gd`) se queda de respaldo (Android/Web sin binario) y de referencia: `pruebas/probar_nativo_ciudad.tscn`.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/geometry_instance3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>
#include <unordered_map>
#include <vector>

using namespace godot;

namespace {

// Constantes de TraficoCiudad / MovimientoNatural.
const double ARRANQUE = 2.4, FRENADA = 3.5, PLAN = 2.6, TIRON = 8.0, LADO_ESQUIVA = 0.75, SEPARA_LADO = 0.6, VEL_LATERAL = 0.9;
const double LAT_ADELANTA = 3.4, VEL_ADELANTA = 1.6, VISTA_ADELANTA = 30.0, SUSTO_PASO = 2.2;
const double MIRA_CADA = 0.25, MIRA_DELANTE = 1.2, RADIO_SIRENA = 55.0, CELDA_PASO = 8.0, RADIO_PASO = 70.0, PACIENCIA_PASO = 4.0;
const double MN_ARRANQUE = 0.45, MN_GIRO = 7.0, MN_ANTICIPO = 0.5, MN_MIN_CAMBIO = 0.4;

struct K {
	Variant nodo = String("nodo"), ruta = String("ruta"), s = String("s"), vel = String("vel"), alto = String("alto"), giro = String("giro"), peaton = String("peaton"), oculto = String("oculto"), lod = String("lod"), dt = String("dt"),
			espera = String("espera"), pausa = String("pausa"), rut_pausa = String("rut_pausa"), susto = String("susto"), vact = String("vact"), aact = String("aact"), faros = String("faros"), frena = String("frena"),
			paradas = String("paradas"), espera_parada = String("espera_parada"), cola = String("cola"), lat = String("lat"), lat_obj = String("lat_obj"), t_lat = String("t_lat"), t_mira = String("t_mira"),
			pidio = String("pidio"), cediendo = String("cediendo"), sin_ceder = String("sin_ceder"), apausa = String("apausa"), k = String("k"), t_anda = String("t_anda"), anda = String("anda"), rampa = String("rampa"),
			freno{"freno"};
};
const K &kk() {
	static const K k;
	return k;
}

struct Ruta {
	bool listo = false;
	PackedVector3Array puntos;
	PackedFloat32Array acum;
	double largo = 0.0;
	int64_t n = 0;
};

// `Ruta.en`: posición y dirección a una distancia `s`.
void ruta_en(const Ruta &r, double s, Vector3 &pos, Vector3 &dir) {
	if (r.largo <= 0.001 || r.n < 2) {
		pos = Vector3();
		dir = Vector3(0, 0, -1);
		return;
	}
	const double d = Math::fposmod(s, r.largo);
	const Vector3 *pp = r.puntos.ptr();
	const float *pa = r.acum.ptr();
	int64_t lo = 0;
	int64_t hi = r.n - 1;
	while (lo < hi) {
		const int64_t mid = (lo + hi + 1) / 2;
		if (double(pa[mid]) <= d) {
			lo = mid;
		} else {
			hi = mid - 1;
		}
	}
	const Vector3 a = pp[lo];
	const Vector3 b = pp[(lo + 1) % r.n];
	const double dist = double(a.distance_to(b));
	const double tramo = dist > 0.001 ? dist : 0.001;
	const double t = (d - double(pa[lo])) / tramo;
	pos = a.lerp(b, real_t(t));
	dir = (b - a).normalized();
}

// `o == v` de GDScript compara los diccionarios enteros (caro con muchos peatones por ruta): son el mismo móvil si tienen el mismo nodo vivo (con un nodo liberado se compara como GDScript).
Node3D *nodo_de_v(const Dictionary &v, const K &k);
inline bool mismo_movil(const Dictionary &a, const Dictionary &b, const K &k) {
	Node3D *na = nodo_de_v(a, k);
	Node3D *nb = nodo_de_v(b, k);
	if (na != nullptr && nb != nullptr) {
		return na == nb;
	}
	return a == b;
}

struct Ent {
	int64_t idx;
	Vector2 pos;
	Vector2 dir;
	bool coche;
	float y;
};

inline int64_t clave(int64_t x, int64_t z) { return (x << 32) ^ (z & 0xffffffffLL); }

Node3D *nodo_de(const Dictionary &v, const K &k) {
	const Variant n = v[k.nodo];
	return Object::cast_to<Node3D>(static_cast<Object *>(n));
}

Node3D *nodo_de_v(const Dictionary &v, const K &k) { return nodo_de(v, k); }
inline double gf(const Dictionary &v, const Variant &k, double def) { return double(v.get(k, def)); }

struct Paso {
	Object *tr;
	const K &k;
	Array vehiculos;
	std::vector<Ruta> rutas;
	Array rutas_v;
	Dictionary controles;
	Dictionary en_cola;
	Dictionary peatones_ruta;
	Object *semaforos = nullptr;
	Object *jugador = nullptr;
	Vector2 huella;
	Callable libre_fn;
	// `libre_ctx` (lo pone el explorador de la ciudad): la comprobación de `libre_fn` (`libre_obst(q, radio) and not _choca_circulos(q, radio)`) sin salir de C++.
	bool ctx_ok = false;
	Dictionary rej_obst, rej_circ;
	double c_radio = 0.3, c_limite = 1480.0, c_celda_obst = 32.0, c_celda_circ = 8.0, c_rio_x = -470.0, c_celda_av = 110.0, c_ancho_av = 24.0;
	Array sirenas;
	std::unordered_map<int64_t, std::vector<Ent>> rejilla;

	explicit Paso(Object *t) : tr(t), k(kk()) {}

	const Ruta &ruta(int64_t i) {
		Ruta &r = rutas[i];
		if (!r.listo) {
			Object *o = static_cast<Object *>(rutas_v[i]);
			r.puntos = o->get("puntos");
			r.acum = o->get("acumulado");
			r.largo = double(o->get("largo"));
			r.n = r.puntos.size();
			r.listo = true;
		}
		return r;
	}

	bool libre_activo() const { return ctx_ok || libre_fn.is_valid(); }

	// `ExploradorCiudad.en_rio`, `en_puente`, `libre`, `libre_obst` y `_choca_circulos` (visor/explorador_ciudad_p1.gd) con el radio del contexto.
	bool libre_q(const Vector3 &p) {
		if (!ctx_ok) {
			return bool(libre_fn.call(p));
		}
		const double radio = c_radio;
		const Vector2i kc(int32_t(Math::floor(double(p.x) / c_celda_obst)), int32_t(Math::floor(double(p.z) / c_celda_obst)));
		const Array celda = rej_obst.get(kc, Array());
		// libre(p, radio, celda)
		if (std::abs(double(p.x)) > c_limite || std::abs(double(p.z)) > c_limite) {
			return false;
		}
		if (std::abs(double(p.x) - c_rio_x) < 50.0 && std::abs(double(p.z)) < 1360.0) {
			const double linea = Math::snapped(double(p.z), c_celda_av);
			const bool puente = std::abs(double(p.z) - linea) < c_ancho_av * 0.5 - 1.0 && std::abs(double(p.x) - c_rio_x) < 66.0;
			if (!puente) {
				return false;
			}
		}
		for (int64_t i = 0; i < celda.size(); i++) {
			const Rect2 r = celda[i];
			const Vector2 fin = r.position + r.size;
			if (double(p.x) > double(r.position.x) - radio && double(p.x) < double(fin.x) + radio && double(p.z) > double(r.position.y) - radio && double(p.z) < double(fin.y) + radio) {
				return false;
			}
		}
		// _choca_circulos(p, radio)
		const int32_t cx = int32_t(Math::floor(double(p.x) / c_celda_circ));
		const int32_t cz = int32_t(Math::floor(double(p.z) / c_celda_circ));
		for (int32_t i = cx - 1; i < cx + 2; i++) {
			for (int32_t j = cz - 1; j < cz + 2; j++) {
				const Array lista = rej_circ.get(Vector2i(i, j), Array());
				for (int64_t q = 0; q < lista.size(); q++) {
					const Vector3 c = lista[q];
					const double dx = double(p.x) - double(c.x);
					const double dz = double(p.z) - double(c.y);
					const double rr = radio + double(c.z);
					if (dx * dx + dz * dz < rr * rr) {
						return false;
					}
				}
			}
		}
		return true;
	}

	// `TraficoCiudad.sirena_cerca`
	bool sirena_cerca(const Vector3 &p, const Vector3 &dir, double vel) const {
		const double a = RADIO_SIRENA;
		const double b = vel * vel / 6.0 + 12.0;
		const double radio = a > b ? a : b;
		for (int64_t i = 0; i < sirenas.size(); i++) {
			Node3D *s = Object::cast_to<Node3D>(static_cast<Object *>(sirenas[i]));
			if (s == nullptr) {
				continue;
			}
			const Vector3 sp = s->get_position();
			if (double(Vector2(real_t(double(sp.x) - double(p.x)), real_t(double(sp.z) - double(p.z))).length()) < radio) {
				const Vector3 rel = sp - p;
				if (dir != Vector3() && double(rel.dot(dir)) < -1.0 && std::abs(double(rel.cross(dir).y)) < 3.5) {
					continue;
				}
				return true;
			}
		}
		return false;
	}

	// `TraficoCiudad.tapa_al_jugador`
	static bool tapa_al_jugador(const Vector3 &pos, const Vector3 &dir, double umbral, double ancho, const Vector3 &pj, double ang, const Vector2 &h) {
		const Vector2 d = Vector2(dir.x, dir.z).normalized();
		const double sn = std::sin(ang);
		const double cs = std::cos(ang);
		for (int i = 0; i < 5; i++) {
			const double kq = 0.2 + double(i) / 4.0 * (umbral - 0.2);
			const double rx = double(pos.x) + double(d.x) * kq - double(pj.x);
			const double rz = double(pos.z) + double(d.y) * kq - double(pj.z);
			const double a0 = std::abs(rx * cs - rz * sn) - double(h.x);
			const double ex = a0 > 0.0 ? a0 : 0.0;
			const double a1 = std::abs(rx * sn + rz * cs) - double(h.y);
			const double ez = a1 > 0.0 ? a1 : 0.0;
			if (ex * ex + ez * ez < ancho * ancho) {
				const double b0 = std::abs((double(pos.x) - double(pj.x)) * cs - (double(pos.z) - double(pj.z)) * sn) - double(h.x);
				const double ox = b0 > 0.0 ? b0 : 0.0;
				const double b1 = std::abs((double(pos.x) - double(pj.x)) * sn + (double(pos.z) - double(pj.z)) * cs) - double(h.y);
				const double oz = b1 > 0.0 ? b1 : 0.0;
				return ox * ox + oz * oz >= 0.01;
			}
		}
		return false;
	}

	// `TraficoCiudad._colocar`
	void colocar(Dictionary v, double delta) {
		Node3D *nodo = nodo_de(v, k);
		if (nodo == nullptr) {
			return;
		}
		const int64_t ri = int64_t(v[k.ruta]);
		const Ruta &r = ruta(ri);
		Vector3 pos, dir;
		ruta_en(r, double(v[k.s]), pos, dir);
		nodo->set_position(pos + Vector3(0, real_t(double(v[k.alto])), 0) + Vector3(dir.z, 0, -dir.x) * real_t(gf(v, k.lat, 0.0)));
		double yaw = std::atan2(double(dir.x), double(dir.z)) + double(v[k.giro]);
		if (delta > 0.0 && bool(v.get(k.peaton, false))) {
			Vector3 p2, prox;
			ruta_en(r, double(v[k.s]) + MN_ANTICIPO, p2, prox);
			const double objetivo = std::atan2(double(prox.x), double(prox.z)) + double(v[k.giro]);
			yaw = Math::lerp_angle(double(nodo->get_rotation().y), objetivo, 1.0 - std::exp(-MN_GIRO * delta));
		}
		Vector3 rot = nodo->get_rotation();
		rot.y = real_t(yaw);
		nodo->set_rotation(rot);
	}

	// `TraficoCiudad._lateral`
	void lateral(Dictionary v, double delta, double vel) {
		const double t_lat = gf(v, k.t_lat, 0.0);
		if (t_lat > 0.0) {
			v[k.t_lat] = t_lat - delta;
		} else if (gf(v, k.lat_obj, 0.0) != 0.0) {
			v[k.lat_obj] = 0.0;
		}
		const double lat = gf(v, k.lat, 0.0);
		const double obj = gf(v, k.lat_obj, 0.0);
		if (lat != obj) {
			v[k.lat] = Math::move_toward(lat, obj, vel * delta);
		}
	}

	// `TraficoCiudad._esquivar`
	bool esquivar(Dictionary v, double de_lat, double preferido) {
		if (gf(v, k.t_lat, 0.0) > 0.0 && std::abs(gf(v, k.lat_obj, 0.0) - de_lat) > SEPARA_LADO) {
			v[k.t_lat] = 1.5;
			return true;
		}
		Vector3 pos, dir;
		ruta_en(ruta(int64_t(v[k.ruta])), double(v[k.s]), pos, dir);
		const Vector3 fuera = Vector3(dir.z, 0, -dir.x);
		const double sgs[2] = { preferido, -preferido };
		for (int i = 0; i < 2; i++) {
			double lat = de_lat + LADO_ESQUIVA * sgs[i];
			lat = lat < -1.0 ? -1.0 : (lat > 1.0 ? 1.0 : lat);
			if (std::abs(lat - de_lat) < SEPARA_LADO) {
				continue;
			}
			if (libre_activo()) {
				const Vector3 q1 = pos + fuera * real_t(lat);
				const Vector3 q2 = pos + fuera * real_t(lat) + dir * real_t(1.5);
				if (!(libre_q(q1) && libre_q(q2))) {
					continue;
				}
			}
			v[k.lat_obj] = lat;
			v[k.t_lat] = 1.5;
			return true;
		}
		return false;
	}

	// `TraficoCiudad._mirar_delante`
	void mirar_delante(Dictionary v, double s, double delta) {
		if (!libre_activo()) {
			return;
		}
		const double azar = UtilityFunctions::randf() * MIRA_CADA; // el valor por defecto de `get` se evalúa SIEMPRE
		const double t = double(v.get(k.t_mira, azar)) - delta;
		if (t > 0.0) {
			v[k.t_mira] = t;
			return;
		}
		v[k.t_mira] = MIRA_CADA;
		Vector3 pos, dir;
		ruta_en(ruta(int64_t(v[k.ruta])), s, pos, dir);
		const double lat = gf(v, k.lat, 0.0);
		const Vector3 q = pos + Vector3(dir.z, 0, -dir.x) * real_t(lat) + dir * real_t(MIRA_DELANTE);
		if (!libre_q(q)) {
			esquivar(v, lat, 1.0);
		}
	}

	// `TraficoCiudad._rejilla_paso`
	void rejilla_paso(bool hay_cam, const Vector3 &ojo) {
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

	static Vector2 hueco(bool coche) { return coche ? Vector2(7.0, 1.7) : Vector2(1.3, 0.55); }

	// `TraficoCiudad._en_hueco`
	static bool en_hueco(const Vector2 &pa, const Vector2 &da, bool coche, const Vector2 &pb, double ancho_extra) {
		const Vector2 rel = pb - pa;
		const Vector2 h = hueco(coche);
		const double frente = double(rel.dot(da));
		if (frente <= 0.2 || frente > double(h.x)) {
			return false;
		}
		return std::abs(double(rel.cross(da))) < double(h.y) + ancho_extra;
	}

	// `TraficoCiudad._cede_paso`
	bool cede_paso(Dictionary v, int64_t idx, double delta) {
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

	// `MovimientoNatural.marcha`
	double marcha(Dictionary v, double avance, double pedido, double delta) {
		const bool anda = avance > pedido * 0.3;
		double kk_ = gf(v, k.k, 1.0);
		kk_ = Math::move_toward(kk_, anda ? 1.0 : 0.0, anda ? delta / MN_ARRANQUE : 1.0);
		v[k.k] = kk_;
		const double t = gf(v, k.t_anda, 0.0) - delta;
		const bool ya = bool(v.get(k.anda, true));
		if (anda != ya && t <= 0.0) {
			v[k.anda] = anda;
			v[k.t_anda] = MN_MIN_CAMBIO;
			tr->call("_cb_mn_clip", v, anda ? String("caminar") : String("parado"), kk_);
		} else {
			v[k.t_anda] = t > 0.0 ? t : 0.0;
			if (anda && ya && kk_ < 1.0) {
				tr->call("_cb_mn_vel", v, double(v[k.vel]) * (kk_ > 0.4 ? kk_ : 0.4));
			}
		}
		if (anda && ya && kk_ >= 1.0 && bool(v.get(k.rampa, false))) {
			v[k.rampa] = false;
			tr->call("_cb_mn_vel", v, double(v[k.vel]));
		}
		if (kk_ < 1.0) {
			v[k.rampa] = true;
		}
		const double lim = pedido * kk_;
		return avance < lim ? avance : lim;
	}

	void luz_freno(Dictionary v, double valor) {
		Object *fm = static_cast<Object *>(v[k.faros]);
		GeometryInstance3D *g = Object::cast_to<GeometryInstance3D>(fm);
		if (g != nullptr) {
			g->set_instance_shader_parameter(StringName("freno"), valor);
		}
	}

	void pausar_anim(Dictionary v, bool pausar) {
		if (bool(v.get(k.apausa, false)) == pausar) {
			return;
		}
		tr->call("_pausar_anim", v, pausar);
	}

	void paso(double delta_real, bool hay_cam, const Vector3 &ojo, const Vector3 &adelante, bool hay_jugador, const Vector3 &pj, int64_t cuadro) {
		rejilla_paso(hay_cam, ojo);
		const int64_t n = vehiculos.size();
		for (int64_t idx = 0; idx < n; idx++) {
			Dictionary v = vehiculos[idx];
			if (bool(v.get(k.oculto, false))) {
				continue;
			}
			const int64_t nivel = int64_t(v.get(k.lod, 0));
			if (nivel > 0 && (idx + cuadro) % (nivel == 1 ? 3 : 12) != 0) {
				v[k.dt] = gf(v, k.dt, 0.0) + delta_real;
				continue;
			}
			const double delta = delta_real + gf(v, k.dt, 0.0);
			v[k.dt] = 0.0;
			if (hay_cam) {
				Node3D *nv = nodo_de(v, k);
				if (nv != nullptr) {
					const Vector3 q = nv->get_position();
					const double ax = std::abs(double(q.x) - double(ojo.x));
					const double az = std::abs(double(q.z) - double(ojo.z));
					const double lejos = ax > az ? ax : az;
					const int64_t nl = lejos < 150.0 ? 0 : (lejos < 260.0 ? 1 : 2);
					pausar_anim(v, nl == 2 || double(adelante.dot(q - ojo)) < -3.0);
					v[k.lod] = nl;
				}
			}
			if (gf(v, k.espera, 0.0) > 0.0) {
				v[k.espera] = double(v[k.espera]) - delta;
				if (double(v[k.espera]) <= 0.0 && v.has(k.pausa)) {
					v.erase(k.pausa);
					tr->call("_cb_peaton_reanuda", v);
				}
				continue;
			}
			const bool es_peaton = bool(v.get(k.peaton, false));
			if (es_peaton && UtilityFunctions::randf() < 0.0004 * delta * 60.0 * gf(v, k.rut_pausa, 1.0)) {
				v[k.espera] = UtilityFunctions::randf_range(3.0, 9.0);
				v[k.pausa] = true;
				tr->call("_cb_peaton_espera", v, UtilityFunctions::randf());
				continue;
			}
			double avance = double(v[k.vel]) * delta;
			if (gf(v, k.susto, 0.0) > 0.0) {
				v[k.susto] = double(v[k.susto]) - delta;
				avance *= SUSTO_PASO;
			}
			const int64_t ruta_i = int64_t(v[k.ruta]);
			const double s0 = double(v[k.s]);
			const double largo = ruta(ruta_i).largo;
			bool frena = false;
			const bool suave = !es_peaton;
			double vact = gf(v, k.vact, double(v[k.vel]));
			double tope = INFINITY;
			double aterriza = -1.0;
			double mira = 12.0;
			if (suave) {
				const double m2 = vact * vact / (2.0 * PLAN) + 2.0;
				mira = 12.0 > m2 ? 12.0 : m2;
			}
			if (semaforos != nullptr && controles.has(ruta_i)) {
				const Array cs = controles[ruta_i];
				for (int64_t ci = 0; ci < cs.size(); ci++) {
					const Dictionary c = cs[ci];
					const double d = Math::fposmod(double(c[k.s]) - s0, largo);
					const bool visto = suave ? d < mira : (d < avance + 0.5 && d < 12.0);
					const int64_t eje = int64_t(c["eje"]);
					// `peatonal` y `verde` no tienen efectos: solo se consultan si el control está a la vista (el resultado es el mismo).
					bool libre = true;
					if (visto) {
						static const StringName n_peatonal("peatonal"), n_verde("verde");
						libre = es_peaton ? String(semaforos->call(n_peatonal, eje)) == "v" : bool(semaforos->call(n_verde, eje));
					}
					if (visto && !libre) {
						if (es_peaton && !bool(v.get(k.pidio, false))) {
							v[k.pidio] = true;
							semaforos->call("pulsa_npc", eje);
							tr->call("_gesto", v, String("saludo_mano"));
						}
						const double r0 = d - 0.3 > 0.0 ? d - 0.3 : 0.0;
						avance = suave ? (avance < r0 ? avance : r0) : r0;
						const double tp = std::sqrt(2.0 * PLAN * r0);
						tope = tope < tp ? tope : tp;
						frena = true;
						break;
					}
				}
			}
			if (es_peaton && !frena) {
				v.erase(k.pidio);
			}
			if (suave && !sirenas.is_empty()) {
				Node3D *nn = nodo_de(v, k);
				if (nn != nullptr) {
					Vector3 pp, dd;
					ruta_en(ruta(ruta_i), s0, pp, dd);
					if (sirena_cerca(nn->get_position(), dd, vact)) {
						tope = 0.0;
						frena = true;
					}
				}
			}
			if (v.has(k.faros) && bool(v[k.frena]) != frena) {
				v[k.frena] = frena;
				luz_freno(v, frena ? 1.0 : 0.0);
			}
			if (v.has(k.paradas)) {
				const Array ps = Variant(v[k.paradas]);
				for (int64_t pi = 0; pi < ps.size(); pi++) {
					const double d2 = Math::fposmod(double(ps[pi]) - s0, largo);
					if (suave && d2 < mira) {
						const double r0 = d2 - 0.3 > 0.0 ? d2 - 0.3 : 0.0;
						const double tp = std::sqrt(2.0 * PLAN * r0);
						tope = tope < tp ? tope : tp;
					}
					double umbral = avance;
					if (suave) {
						const double a = 0.35;
						const double b = vact * delta;
						umbral = a > b ? a : b;
					}
					if (d2 < umbral) {
						aterriza = d2 + 0.05;
						avance = d2 + 0.05;
						v[k.espera] = double(v.get(k.espera_parada, 8.0));
						break;
					}
				}
			}
			if (v.has(k.cola)) {
				const Array col = en_cola[ruta_i];
				for (int64_t oi = 0; oi < col.size(); oi++) {
					const Dictionary o = col[oi];
					if (mismo_movil(o, v, k)) {
						continue;
					}
					const double d3 = Math::fposmod(double(o[k.s]) - s0, largo);
					if (d3 < 9.0 + avance) {
						const double r0 = d3 - 8.0 > 0.0 ? d3 - 8.0 : 0.0;
						avance = avance < r0 ? avance : r0;
					}
					if (suave && d3 < mira + 9.0) {
						const double r1 = d3 - 9.0 > 0.0 ? d3 - 9.0 : 0.0;
						const double c2 = double(o.get(k.vact, o[k.vel])) + std::sqrt(2.0 * PLAN * r1);
						tope = tope < c2 ? tope : c2;
					}
				}
			}
			if (es_peaton) {
				lateral(v, delta, VEL_LATERAL);
				mirar_delante(v, s0, delta);
			} else if (v.has(k.lat_obj) || gf(v, k.lat, 0.0) != 0.0) {
				lateral(v, delta, VEL_ADELANTA);
			}
			if (es_peaton && peatones_ruta.has(ruta_i)) {
				const Array pr = peatones_ruta[ruta_i];
				for (int64_t oi = 0; oi < pr.size(); oi++) {
					Dictionary o = pr[oi];
					if (mismo_movil(o, v, k)) {
						continue;
					}
					const double d4 = Math::fposmod(double(o[k.s]) - s0, largo);
					const bool separados = std::abs(gf(v, k.lat, 0.0) - gf(o, k.lat, 0.0)) > SEPARA_LADO;
					if (d4 < 2.5) {
						if (separados) {
							const double a = gf(v, k.t_lat, 0.0);
							v[k.t_lat] = a > 1.0 ? a : 1.0;
							continue;
						}
						if (gf(o, k.espera, 0.0) > 0.0 || gf(o, k.cediendo, 0.0) > 0.0 || double(o[k.vel]) < double(v[k.vel]) * 0.9) {
							esquivar(v, gf(o, k.lat, 0.0), 1.0);
						}
					} else if (Math::fposmod(s0 - double(o[k.s]), largo) < 1.2 && separados) {
						const double a = gf(v, k.t_lat, 0.0);
						v[k.t_lat] = a > 0.5 ? a : 0.5;
					}
					if (d4 < 0.9 + avance && !separados) {
						const double r0 = d4 - 0.9 > 0.0 ? d4 - 0.9 : 0.0;
						avance = avance < r0 ? avance : r0;
						if (gf(o, k.espera, 0.0) <= 0.0 && UtilityFunctions::randf() < 0.004) {
							tr->call("_charlar", v, o);
							avance = 0.0;
						}
					}
				}
			}
			if (hay_jugador && avance > 0.0) {
				Node3D *nodo_v = nodo_de(v, k);
				if (nodo_v != nullptr) {
					const Vector3 np = nodo_v->get_position();
					const Vector3 rel = Vector3(real_t(double(pj.x) - double(np.x)), 0, real_t(double(pj.z) - double(np.z)));
					if (double(rel.length_squared()) < 256.0) {
						Vector3 pp, dir_v;
						ruta_en(ruta(ruta_i), s0, pp, dir_v);
						const bool peaton = es_peaton;
						Node3D *jn = Object::cast_to<Node3D>(jugador);
						if (tapa_al_jugador(np, dir_v, peaton ? 1.25 : 5.7, peaton ? 0.4 : 1.0, pj, double(jn->get_rotation().y), huella)) {
							avance = 0.0;
							if (peaton && double(huella.y) < 0.6) {
								const double lado_j = double(Vector3(dir_v.z, 0, -dir_v.x).dot(rel));
								esquivar(v, gf(v, k.lat, 0.0) + lado_j, lado_j > 0.0 ? -1.0 : 1.0);
							}
						}
					}
				}
			}
			if (avance > 0.0 && cede_paso(v, idx, delta)) {
				avance = 0.0;
				if (v.has(k.faros) && !bool(v[k.frena])) {
					v[k.frena] = true;
					luz_freno(v, 1.0);
				}
			}
			if (suave && delta > 0.0) {
				const double vv = double(v[k.vel]);
				const double objetivo = vv < tope ? vv : tope;
				const double ganancia = tope < vv ? 1.0 / delta : 6.0;
				double a_pedida = (objetivo - vact) * ganancia;
				a_pedida = a_pedida < -FRENADA ? -FRENADA : (a_pedida > ARRANQUE ? ARRANQUE : a_pedida);
				const double a_act = Math::move_toward(gf(v, k.aact, 0.0), a_pedida, TIRON * delta);
				const double nv = vact + a_act * delta;
				vact = nv > 0.0 ? nv : 0.0;
				v[k.aact] = a_act;
				if (avance < vact * delta) {
					vact = avance / delta;
				} else {
					avance = vact * delta;
				}
				if (aterriza >= 0.0) {
					avance = aterriza;
				}
				if (gf(v, k.espera, 0.0) > 0.0) {
					vact = 0.0;
				}
				v[k.vact] = vact;
			}
			if (es_peaton && hay_jugador && nivel == 0) {
				Node3D *nv2 = nodo_de(v, k);
				if (nv2 != nullptr) {
					const Vector3 d = pj - nv2->get_position(); // distance_squared_to(pj) = (pj - pos).length_squared()
					tr->call("_cb_mirada", v, double(d.length_squared()), delta);
				}
			}
			if (es_peaton) {
				avance = marcha(v, avance, double(v[k.vel]) * delta, delta);
			}
			v[k.s] = s0 + avance;
			colocar(v, delta);
		}
	}
};

} // namespace

// `TraficoCiudad._paso_nativo`: el cuerpo entero de `_process` (ver `visor/trafico_ciudad.gd`). `sirenas` = `TraficoCiudad.sirenas`.
void DinastiaNativo::trafico_paso(Object *tr, double delta_real, bool hay_cam, const Vector3 &ojo, const Vector3 &adelante, bool hay_jugador, const Vector3 &pj, const Array &sirenas) const {
	if (tr == nullptr) {
		return;
	}
	Paso p(tr);
	p.vehiculos = tr->get("_vehiculos");
	p.rutas_v = tr->get("_rutas");
	p.rutas.resize(size_t(p.rutas_v.size()));
	p.controles = tr->get("_controles");
	p.en_cola = tr->get("_en_cola");
	p.peatones_ruta = tr->get("_peatones_ruta");
	p.semaforos = static_cast<Object *>(tr->get("semaforos"));
	p.jugador = static_cast<Object *>(tr->get("jugador"));
	p.huella = tr->get("jugador_huella");
	p.libre_fn = tr->get("libre_fn");
	const Dictionary lctx = tr->get("libre_ctx");
	if (!lctx.is_empty()) {
		p.ctx_ok = true;
		p.rej_obst = lctx["obst"];
		p.rej_circ = lctx["circ"];
		p.c_radio = double(lctx["radio"]);
		p.c_limite = double(lctx["limite"]);
		p.c_celda_obst = double(lctx["celda_obst"]);
		p.c_celda_circ = double(lctx["celda_circ"]);
		p.c_rio_x = double(lctx["rio_x"]);
		p.c_celda_av = double(lctx["celda_av"]);
		p.c_ancho_av = double(lctx["ancho_av"]);
	}
	p.sirenas = sirenas;
	const int64_t cuadro = int64_t(tr->get("_cuadro")) + 1;
	tr->set("_cuadro", cuadro);
	p.paso(delta_real, hay_cam, ojo, adelante, hay_jugador && p.jugador != nullptr, pj, cuadro);
}
