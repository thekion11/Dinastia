// TRÁFICO DE LA CIUDAD EN C++ (18-11-2026): estructuras y constantes comunes de `trafico_nativo.cpp`, `trafico_cuerpo.cpp` y `trafico_cede.cpp` (el código de `TraficoCiudad._process`, partido en tres archivos por la norma de 450 líneas).
#pragma once

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

namespace godot {
namespace trafico {


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
inline const K &kk() {
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
inline void ruta_en(const Ruta &r, double s, Vector3 &pos, Vector3 &dir) {
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
inline Node3D *nodo_de_v(const Dictionary &v, const K &k);
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

inline Node3D *nodo_de(const Dictionary &v, const K &k) {
	const Variant n = v[k.nodo];
	return Object::cast_to<Node3D>(static_cast<Object *>(n));
}

inline Node3D *nodo_de_v(const Dictionary &v, const K &k) { return nodo_de(v, k); }
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

















	bool libre_activo()  const {return ctx_ok || libre_fn.is_valid(); }
	// `ExploradorCiudad.en_rio`, `en_puente`, `libre`, `libre_obst` y `_choca_circulos` (visor/explorador_ciudad_p1.gd) con el radio del contexto.
	bool libre_q(const Vector3 &p);
	// `TraficoCiudad.sirena_cerca`
	bool sirena_cerca(const Vector3 &p, const Vector3 &dir, double vel)  const;
	// `TraficoCiudad.tapa_al_jugador`
	static bool tapa_al_jugador(const Vector3 &pos, const Vector3 &dir, double umbral, double ancho, const Vector3 &pj, double ang, const Vector2 &h);
	// `TraficoCiudad._colocar`
	void colocar(Dictionary v, double delta);
	// `TraficoCiudad._lateral`
	void lateral(Dictionary v, double delta, double vel);
	// `TraficoCiudad._esquivar`
	bool esquivar(Dictionary v, double de_lat, double preferido);
	// `TraficoCiudad._mirar_delante`
	void mirar_delante(Dictionary v, double s, double delta);
	// `TraficoCiudad._rejilla_paso`
	void rejilla_paso(bool hay_cam, const Vector3 &ojo);
	static Vector2 hueco(bool coche) {return coche ? Vector2(7.0, 1.7) : Vector2(1.3, 0.55); }
	// `TraficoCiudad._en_hueco`
	static bool en_hueco(const Vector2 &pa, const Vector2 &da, bool coche, const Vector2 &pb, double ancho_extra);
	// `TraficoCiudad._cede_paso`
	bool cede_paso(Dictionary v, int64_t idx, double delta);
	// `MovimientoNatural.marcha`
	double marcha(Dictionary v, double avance, double pedido, double delta);
	void luz_freno(Dictionary v, double valor);
	void pausar_anim(Dictionary v, bool pausar);
	void paso(double delta_real, bool hay_cam, const Vector3 &ojo, const Vector3 &adelante, bool hay_jugador, const Vector3 &pj, int64_t cuadro);
};

} // namespace trafico
} // namespace godot
