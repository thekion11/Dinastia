// FUNCIONES PURAS DEL NÚCLEO EN C++ (2.ª tanda, 20-11-2026, orden 63). Mismas reglas que `puras_nucleo.cpp`: traducción literal de la
// gemela GDScript `<nombre>_gd`. Las constantes de la clase GDScript llegan como ARGUMENTOS (el envoltorio las pasa): si alguien las
// cambia en GDScript, C++ no queda desfasado. Las tablas de texto (`puras_nucleo2_tablas.inc`) se generaron desde el GDScript.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/string.hpp>

#include <cmath>
#include <cstdint>

using namespace godot;

namespace {
// `wrapi` del motor (Math::wrapi).
inline int64_t wrapi_(int64_t v, int64_t mn, int64_t mx) {
	const int64_t rango = mx - mn;
	return rango == 0 ? mn : mn + (((v - mn) % rango) + rango) % rango;
}
} // namespace

#include "puras_nucleo2_tablas.inc"

// `OcasionesDT.nivel` (`cupo_min` = `OcasionesDT.CUPO_MIN`)
int64_t DinastiaNativo::nuc_nivel_ocasion(int64_t minuto, int64_t minuto_fin, int64_t hechas, int64_t cupo_arg, int64_t cupo_min) const {
	const double quedan = (double)(minuto_fin - minuto);
	const int64_t m = cupo_min < cupo_arg ? cupo_min : cupo_arg;
	if (hechas < m && quedan < (double)(m - hechas) * 6.0) {
		return 2;
	}
	return quedan < (double)(cupo_arg - hechas) * 12.0 ? 1 : 0;
}

// `Viajes.medio` (`km_bus_max` = KM_BUS_MAX, `km_avion_max` = KM_AVION_MAX)
String DinastiaNativo::nuc_medio_viaje(double km, double km_bus_max, double km_avion_max) const {
	if (km <= km_bus_max) {
		return "bus";
	}
	return km <= km_avion_max ? "avion" : "charter";
}

// `Viajes.noches` (`km_bus_noche` = KM_BUS_NOCHE)
int64_t DinastiaNativo::nuc_noches_viaje(double km, double km_bus_noche) const {
	if (km <= km_bus_noche) {
		return 0;
	}
	if (km <= 2500.0) {
		return 1;
	}
	return km <= 9000.0 ? 2 : 3;
}

// `Calendario.toca_continental_selecciones`
bool DinastiaNativo::nuc_toca_continental(const String &clave, int64_t anio) const {
	if (clave == "ucl" || clave == "lib" || clave == "oce") {
		return (anio - 2028) % 4 == 0;
	}
	if (clave == "conc" || clave == "afr") {
		return anio % 2 != 0;
	}
	if (clave == "asia") {
		return (anio - 2027) % 4 == 0;
	}
	return false;
}

// `RetosSemana.cumple`
bool DinastiaNativo::nuc_cumple_reto(const String &id, int64_t gf, int64_t gc) const {
	if (id == "ganar") {
		return gf > gc;
	}
	if (id == "ganar_2") {
		return gf - gc >= 2;
	}
	if (id == "cero") {
		return gc == 0;
	}
	if (id == "no_perder") {
		return gf >= gc;
	}
	if (id == "marcar_2") {
		return gf >= 2;
	}
	if (id == "marcar_3") {
		return gf >= 3;
	}
	if (id == "encajar_1") {
		return gc <= 1;
	}
	return false;
}

// `Partida._seq_de`
int64_t DinastiaNativo::nuc_seq_de(const String &id, const String &prefijo, int64_t defecto) const {
	const String n = id.trim_prefix(prefijo);
	return (id.begins_with(prefijo) && n.is_valid_int()) ? n.to_int() : defecto;
}

// `Selecciones._hash_txt`
int64_t DinastiaNativo::nuc_hash_txt(const String &s) const {
	int64_t h = 0;
	for (int64_t i = 0; i < s.length(); i++) {
		h = wrapi_(h * 31 + (int64_t)s.unicode_at(i), -2147483648LL, 2147483648LL);
	}
	return h < 0 ? -h : h;
}

// `Nombres._es_letra`
bool DinastiaNativo::nuc_es_letra_nombre(const String &c) const {
	if (c.is_empty()) {
		return false;
	}
	const int64_t u = (int64_t)c.unicode_at(0);
	if ((u >= 65 && u <= 90) || (u >= 97 && u <= 122)) {
		return true;
	}
	return u >= 0xC0 && u <= 0x17F;
}

// `IdiomasInverso._prefijo`: letras iguales al principio (sin mirar mayúsculas).
int64_t DinastiaNativo::nuc_prefijo_comun(const String &a, const String &b) const {
	const String x = a.to_lower();
	const String y = b.to_lower();
	int64_t n = 0;
	while (n < x.length() && n < y.length() && x.unicode_at(n) == y.unicode_at(n)) {
		n += 1;
	}
	return n;
}

void DinastiaNativo::_bind_puras2() {
	_bind_puras3();
	ClassDB::bind_method(D_METHOD("nuc_icono_calendario", "tipo"), &DinastiaNativo::nuc_icono_calendario);
	ClassDB::bind_method(D_METHOD("nuc_concepto_crisis", "tipo"), &DinastiaNativo::nuc_concepto_crisis);
	ClassDB::bind_method(D_METHOD("nuc_grupo_dialogo", "animo"), &DinastiaNativo::nuc_grupo_dialogo);
	ClassDB::bind_method(D_METHOD("nuc_linea_de", "puesto"), &DinastiaNativo::nuc_linea_de);
	ClassDB::bind_method(D_METHOD("nuc_aviso_incidente", "tipo"), &DinastiaNativo::nuc_aviso_incidente);
	ClassDB::bind_method(D_METHOD("nuc_resuelto_incidente", "tipo"), &DinastiaNativo::nuc_resuelto_incidente);
	ClassDB::bind_method(D_METHOD("nuc_situacion_libre", "situacion"), &DinastiaNativo::nuc_situacion_libre);
	ClassDB::bind_method(D_METHOD("nuc_nombre_escena", "e"), &DinastiaNativo::nuc_nombre_escena);
	ClassDB::bind_method(D_METHOD("nuc_nivel_ocasion", "minuto", "minuto_fin", "hechas", "cupo_arg", "cupo_min"), &DinastiaNativo::nuc_nivel_ocasion);
	ClassDB::bind_method(D_METHOD("nuc_medio_viaje", "km", "km_bus_max", "km_avion_max"), &DinastiaNativo::nuc_medio_viaje);
	ClassDB::bind_method(D_METHOD("nuc_noches_viaje", "km", "km_bus_noche"), &DinastiaNativo::nuc_noches_viaje);
	ClassDB::bind_method(D_METHOD("nuc_toca_continental", "clave", "anio"), &DinastiaNativo::nuc_toca_continental);
	ClassDB::bind_method(D_METHOD("nuc_cumple_reto", "id", "gf", "gc"), &DinastiaNativo::nuc_cumple_reto);
	ClassDB::bind_method(D_METHOD("nuc_seq_de", "id", "prefijo", "defecto"), &DinastiaNativo::nuc_seq_de);
	ClassDB::bind_method(D_METHOD("nuc_hash_txt", "s"), &DinastiaNativo::nuc_hash_txt);
	ClassDB::bind_method(D_METHOD("nuc_es_letra_nombre", "c"), &DinastiaNativo::nuc_es_letra_nombre);
	ClassDB::bind_method(D_METHOD("nuc_prefijo_comun", "a", "b"), &DinastiaNativo::nuc_prefijo_comun);
}
