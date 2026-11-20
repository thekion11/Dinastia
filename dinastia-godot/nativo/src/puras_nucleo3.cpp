// FUNCIONES PURAS DEL NÚCLEO EN C++ (3.ª tanda, 20-11-2026, orden 63). Mismas reglas que `puras_nucleo.cpp`: traducción literal de la
// gemela GDScript `<nombre>_gd`; las constantes de la clase GDScript llegan como argumentos. Esta tanda trabaja con Array, Dictionary,
// Vector2 y Vector3 (los componentes de los vectores son float de 32 bits, como en GDScript: se promueven a double al operar).
#include "dinastia_nativo.h"

#include <godot_cpp/variant/string.hpp>

#include <cmath>
#include <cstdint>

using namespace godot;

namespace {
inline double clampf3_(double v, double lo, double hi) { return v < lo ? lo : (v > hi ? hi : v); }
inline double maxf3_(double a, double b) { return a > b ? a : b; }
inline int64_t posmod3_(int64_t a, int64_t b) {
	int64_t v = a % b;
	if ((v < 0 && b > 0) || (v > 0 && b < 0)) {
		v += b;
	}
	return v;
}
} // namespace

// `AccionesJuego.xg`
double DinastiaNativo::nuc_xg(const Vector2 &desde) const {
	const double d = desde.length();
	const double angulo = std::fabs(std::atan2(3.66, d) * 2.0 * std::cos(std::atan2((double)desde.y, (double)desde.x)));
	return clampf3_(0.6 * angulo * angulo, 0.005, 0.75);
}

// `FaseFinalLiga._unir`
Array DinastiaNativo::nuc_unir_arrays(const Array &x, const Array &y) const {
	Array sal;
	const int64_t n = x.size() > y.size() ? x.size() : y.size();
	for (int64_t i = 0; i < n; i++) {
		Array a = i < x.size() ? Array(x[i]) : Array();
		Array b = i < y.size() ? Array(y[i]) : Array();
		Array r = a.duplicate(false);
		r.append_array(b);
		sal.append(r);
	}
	return sal;
}

// `FaseFinalLiga._vuelta`
Array DinastiaNativo::nuc_vuelta_pares(const Array &r) const {
	Array sal;
	for (int64_t k = 0; k < r.size(); k++) {
		const Array j = r[k];
		Array v;
		for (int64_t m = 0; m < j.size(); m++) {
			const Array par = j[m];
			Array dado;
			dado.append(par[1]);
			dado.append(par[0]);
			v.append(dado);
		}
		sal.append(v);
	}
	return sal;
}

// `Idiomas._escapar_re`
String DinastiaNativo::nuc_escapar_re(const String &t) const {
	String r = t;
	static const char *const cs[] = { "\\", ".", "^", "$", "|", "(", ")", "[", "]", "{", "}", "*", "+", "?" };
	for (const char *c : cs) {
		r = r.replace(String(c), String("\\") + String(c));
	}
	return r;
}

// `LogrosLargo._maximo_de`
int64_t DinastiaNativo::nuc_maximo_de(const Dictionary &registro) const {
	int64_t mejor = 0;
	const Array claves = registro.keys();
	for (int64_t i = 0; i < claves.size(); i++) {
		const Variant r = registro[claves[i]];
		int64_t v;
		if (r.get_type() == Variant::DICTIONARY) {
			v = (int64_t)Dictionary(r).get("n", 0);
		} else {
			v = (int64_t)r;
		}
		mejor = v > mejor ? v : mejor;
	}
	return mejor;
}

// `OcasionesDT.es_clara`. `k` = [DIST_MINIMO, LATERAL_MINIMO, ESPACIO_MINIMO, DIST_APURADA, LATERAL_CLARA, ESPACIO_APURADA, DIST_CLARA, ESPACIO_CLARA].
bool DinastiaNativo::nuc_es_clara(double dist_arco, double lateral, double espacio, int64_t nivel_arg, const PackedFloat64Array &k) const {
	if (nivel_arg == 2) {
		return dist_arco <= k[0] && std::fabs(lateral) <= k[1] && espacio >= k[2];
	}
	if (nivel_arg == 1) {
		return dist_arco <= k[3] && std::fabs(lateral) <= k[4] && espacio >= k[5];
	}
	return dist_arco <= k[6] && std::fabs(lateral) <= k[4] && espacio >= k[7];
}

// `OcasionesDT.recomendar`
String DinastiaNativo::nuc_recomendar(const Dictionary &lect, double gol_tras_pase, double gol_tras_conducir) const {
	String mejor = "";
	double mv = -1.0;
	static const char *const claves[] = { "tiro", "pase", "conducir" };
	for (const char *c : claves) {
		const String k(c);
		if (!lect.has(k)) {
			continue;
		}
		const Dictionary sub = lect[k];
		double v = (double)sub["prob"];
		if (k == "pase") {
			v *= gol_tras_pase * 0.9;
		} else if (k == "conducir") {
			v *= gol_tras_conducir * 0.9;
		}
		if (v > mv) {
			mv = v;
			mejor = k;
		}
	}
	return mejor;
}

// `Politica.relacion`
int64_t DinastiaNativo::nuc_relacion_politica(const Dictionary &g) const {
	if ((int64_t)g.get("apoyo_club", -1) >= (int64_t)g.get("desde", 0)) {
		return 1;
	}
	if ((int64_t)g.get("recelo_club", -1) >= (int64_t)g.get("desde", 0)) {
		return -1;
	}
	return 0;
}

// `RecorridosMapa.antes`
bool DinastiaNativo::nuc_antes_recorrido(const String &a, const String &c) const {
	const bool la = a.begins_with("C");
	const bool lc = c.begins_with("C");
	return la == lc ? (a < c) : lc;
}

// `RecorridosRed.sector_de` (constantes de la clase como argumentos)
int64_t DinastiaNativo::nuc_sector_de(const Vector3 &pos, double periferia, double rio_x, double rio_medio, double nuc_z0, double nuc_x1, double nuc_z1) const {
	if (maxf3_(std::fabs((double)pos.x), std::fabs((double)pos.z)) > periferia) {
		return 600;
	}
	if (pos.x < rio_x - rio_medio) {
		return 500;
	}
	if (pos.z < nuc_z0 && std::fabs((double)pos.x) < 700.0) {
		return 200;
	}
	if (pos.x > nuc_x1) {
		return 300;
	}
	if (pos.z > nuc_z1) {
		return 400;
	}
	return 100;
}

// `RecorridosRed.sector_del_codigo`
int64_t DinastiaNativo::nuc_sector_del_codigo(const String &cod) const {
	const String cifras = cod.substr(2);
	if (cifras.length() == 4 && cifras.substr(0, 1).to_int() >= 1 && cifras.substr(0, 1).to_int() <= 6) {
		return cifras.substr(0, 1).to_int() * 100;
	}
	return 0;
}

// `RedesCiudad.tiempo_de`
Dictionary DinastiaNativo::nuc_tiempo_de(const String &clima, int64_t hora) const {
	const int64_t h = posmod3_(hora, 24);
	Dictionary d;
	if (clima == "lluvia") {
		d["viento"] = 0.4;
		d["lluvia"] = (h >= 13 && h <= 20) ? 6.0 : 1.0;
	} else if (clima == "tormenta") {
		d["viento"] = 0.95;
		d["lluvia"] = (h >= 12 && h <= 22) ? 22.0 : 4.0;
	} else if (clima == "viento") {
		d["viento"] = 0.95;
		d["lluvia"] = 0.0;
	} else if (clima == "calor" || clima == "despejado") {
		d["viento"] = 0.3;
		d["lluvia"] = 0.0;
	} else {
		d["viento"] = 0.5;
		d["lluvia"] = 0.0;
	}
	return d;
}

// `SeleccionEquipo._total`
int64_t DinastiaNativo::nuc_total_grupos(const Dictionary &por_grupo) const {
	int64_t n = 0;
	const Array claves = por_grupo.keys();
	for (int64_t i = 0; i < claves.size(); i++) {
		n += Array(por_grupo[claves[i]]).size();
	}
	return n;
}

// `TorneoSelecciones._cruces` (la rotación del método del círculo; `f` >= 0)
Array DinastiaNativo::nuc_cruces(const Array &g, int64_t f) const {
	Array lista = g.duplicate(false);
	if (lista.size() % 2 == 1) {
		lista.append(Variant());
	}
	const int64_t n = lista.size();
	Array rot;
	rot.append(lista[0]);
	for (int64_t k = 1; k < n; k++) {
		rot.append(lista[1 + (k - 1 + f) % (n - 1)]);
	}
	Array out;
	for (int64_t k = 0; k < n / 2; k++) {
		const Variant a = rot[k];
		const Variant b = rot[n - 1 - k];
		if (a.get_type() != Variant::NIL && b.get_type() != Variant::NIL) {
			Array par;
			if ((f + k) % 2 == 0) {
				par.append(a);
				par.append(b);
			} else {
				par.append(b);
				par.append(a);
			}
			out.append(par);
		}
	}
	return out;
}

// `VestuarioP3.motivo_satisfaccion`
String DinastiaNativo::nuc_motivo_satisfaccion(const Dictionary &sat, bool baja) const {
	static const char *const claves[] = { "min", "rend", "tact", "inst" };
	String elegida = claves[0];
	for (const char *c : claves) {
		const String k(c);
		if ((baja && (int64_t)sat[k] < (int64_t)sat[elegida]) || (!baja && (int64_t)sat[k] > (int64_t)sat[elegida])) {
			elegida = k;
		}
	}
	if (baja) {
		if (elegida == "min") {
			return "Pocos minutos de juego";
		}
		if (elegida == "rend") {
			return "Su mal rendimiento";
		}
		if (elegida == "tact") {
			return "Juega fuera de su puesto";
		}
		return "Instalaciones pobres";
	}
	if (elegida == "min") {
		return "Minutos de juego";
	}
	if (elegida == "rend") {
		return "Su buen rendimiento";
	}
	if (elegida == "tact") {
		return String::utf8("Cómodo en su puesto");
	}
	return "Buenas instalaciones";
}

void DinastiaNativo::_bind_puras3() {
	ClassDB::bind_method(D_METHOD("nuc_xg", "desde"), &DinastiaNativo::nuc_xg);
	ClassDB::bind_method(D_METHOD("nuc_unir_arrays", "x", "y"), &DinastiaNativo::nuc_unir_arrays);
	ClassDB::bind_method(D_METHOD("nuc_vuelta_pares", "r"), &DinastiaNativo::nuc_vuelta_pares);
	ClassDB::bind_method(D_METHOD("nuc_escapar_re", "t"), &DinastiaNativo::nuc_escapar_re);
	ClassDB::bind_method(D_METHOD("nuc_maximo_de", "registro"), &DinastiaNativo::nuc_maximo_de);
	ClassDB::bind_method(D_METHOD("nuc_es_clara", "dist_arco", "lateral", "espacio", "nivel_arg", "k"), &DinastiaNativo::nuc_es_clara);
	ClassDB::bind_method(D_METHOD("nuc_recomendar", "lect", "gol_tras_pase", "gol_tras_conducir"), &DinastiaNativo::nuc_recomendar);
	ClassDB::bind_method(D_METHOD("nuc_relacion_politica", "g"), &DinastiaNativo::nuc_relacion_politica);
	ClassDB::bind_method(D_METHOD("nuc_antes_recorrido", "a", "c"), &DinastiaNativo::nuc_antes_recorrido);
	ClassDB::bind_method(D_METHOD("nuc_sector_de", "pos", "periferia", "rio_x", "rio_medio", "nuc_z0", "nuc_x1", "nuc_z1"), &DinastiaNativo::nuc_sector_de);
	ClassDB::bind_method(D_METHOD("nuc_sector_del_codigo", "cod"), &DinastiaNativo::nuc_sector_del_codigo);
	ClassDB::bind_method(D_METHOD("nuc_tiempo_de", "clima", "hora"), &DinastiaNativo::nuc_tiempo_de);
	ClassDB::bind_method(D_METHOD("nuc_total_grupos", "por_grupo"), &DinastiaNativo::nuc_total_grupos);
	ClassDB::bind_method(D_METHOD("nuc_cruces", "g", "f"), &DinastiaNativo::nuc_cruces);
	ClassDB::bind_method(D_METHOD("nuc_motivo_satisfaccion", "sat", "baja"), &DinastiaNativo::nuc_motivo_satisfaccion);
}
