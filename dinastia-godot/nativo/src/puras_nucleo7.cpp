// FUNCIONES PURAS DEL NÚCLEO EN C++ (7.ª tanda, 21-11-2026, orden 63): las que leen tablas `const` de su propio archivo. Las tablas las
// genera `herramientas/generar_tablas_puras.py` (`puras_nucleo7_tablas.inc`, texto de Variant leído con `str_to_var`: distingue 1 de 1.0, los tipos coinciden).
// Traducción literal de la gemela GDScript `<nombre>_gd`. Lo que devuelven es una COPIA de la tabla (el GDScript devuelve la constante,
// de solo lectura; así nadie puede tocar la caché). Ninguna modifica sus argumentos.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cstdint>

#include "puras_nucleo7_tablas.inc"

using namespace godot;

namespace {
Variant leer_(const char *json) {
	return UtilityFunctions::str_to_var(String::utf8(json));
}
const Dictionary &detalle_() {
	static const Dictionary d = leer_(TABLA_DETALLE);
	return d;
}
const Dictionary &tipos_() {
	static const Dictionary d = leer_(TABLA_TIPOS_MOMENTO);
	return d;
}
const Dictionary &desenlaces_() {
	static const Dictionary d = leer_(TABLA_DESENLACES);
	return d;
}
// Busca la fila cuya clave (primer elemento) es `clave`; `vacia` si no hay.
Array fila_(const Array &tabla, const String &clave, const Array &vacia) {
	for (int64_t i = 0; i < tabla.size(); i++) {
		const Array f = tabla[i];
		if (String(f[0]) == clave) {
			return f.duplicate(true);
		}
	}
	return vacia;
}
Dictionary dict_por_id_(const Array &tabla, const String &id) {
	for (int64_t i = 0; i < tabla.size(); i++) {
		const Dictionary p = tabla[i];
		if (String(p["id"]) == id) {
			return p.duplicate(true);
		}
	}
	return Dictionary();
}
} // namespace

// `CarreraHabilidad.zona_de`
String DinastiaNativo::nuc_zona_habilidad(const String &hab) const {
	const Array zonas = detalle_().keys();
	for (int64_t i = 0; i < zonas.size(); i++) {
		const Array pares = detalle_()[zonas[i]];
		for (int64_t k = 0; k < pares.size(); k++) {
			const Array par = pares[k];
			if (String(par[0]) == hab) {
				return String(zonas[i]);
			}
		}
	}
	return hab;
}

// `IncidentesCiudad.ritmo_fuego` (FUEGO_BASE = 45.0, FUEGO_SIN_AGUA = 110.0)
double DinastiaNativo::nuc_ritmo_fuego(bool hay_presion) const {
	return hay_presion ? 1.0 : 45.0 / 110.0;
}

// `Expendedora.elegir`
Dictionary DinastiaNativo::nuc_elegir_expendedora(int64_t energia, int64_t hambre) const {
	const char *t = energia < 60 ? TABLA_BEBIDA : (hambre >= 40 ? TABLA_SNACK : TABLA_AGUA);
	return Dictionary(leer_(t));
}

// `TiendaGasolinera.elegir` (SURTIDO[0], [1] o [3])
Dictionary DinastiaNativo::nuc_elegir_gasolinera(int64_t hambre) const {
	static const Array s = leer_(TABLA_SURTIDO);
	const Dictionary d = s[hambre >= 40 ? 0 : (hambre >= 15 ? 1 : 3)];
	return d.duplicate(true);
}

// `Tactica.def_corner` / `def_libre` (si no existe la clave, la primera fila)
Array DinastiaNativo::nuc_def_corner(const String &clave) const {
	static const Array t = leer_(TABLA_CORNERS);
	return fila_(t, clave, Array(t[0]).duplicate(true));
}

Array DinastiaNativo::nuc_def_libre(const String &clave) const {
	static const Array t = leer_(TABLA_LIBRES);
	return fila_(t, clave, Array(t[0]).duplicate(true));
}

// `Finanzas.def_campana`
Array DinastiaNativo::nuc_def_campana(const String &clave) const {
	static const Array t = leer_(TABLA_CAMPANAS);
	return fila_(t, clave, Array());
}

// `LogrosLargo.fila`
Array DinastiaNativo::nuc_fila_logro(const String &clave) const {
	static const Array t = leer_(TABLA_LOGROS);
	return fila_(t, clave, Array());
}

// `Retos.datos`
Array DinastiaNativo::nuc_datos_reto(const String &id) const {
	static const Array t = leer_(TABLA_RETOS);
	return fila_(t, id, Array());
}

// `RoperoDT.articulo`
Dictionary DinastiaNativo::nuc_articulo_ropero(const String &id) const {
	static const Array t = leer_(TABLA_ROPERO);
	return dict_por_id_(t, id);
}

// `CarreraMomentos.desenlace` (el tipo ha de existir en TIPOS, como en el GDScript; si no, este lanza error y el C++ usa la clase vacía)
Dictionary DinastiaNativo::nuc_desenlace_momento(const String &tipo, double q) const {
	const Array t = tipos_().get(tipo, Array());
	const String clase = t.size() > 3 ? String(t[3]) : String();
	const int64_t nivel = q >= 1.0 ? 0 : (q >= 0.6 ? 1 : 2);
	const Array textos = desenlaces_().get(clase, Array());
	Dictionary d;
	d["texto"] = textos.size() > nivel ? String(textos[nivel]) : String();
	d["gol"] = (int64_t)0;
	d["asist"] = (int64_t)0;
	d["parada"] = (int64_t)0;
	d["encajado"] = (int64_t)0;
	d["nota"] = nivel == 0 ? 0.7 : (nivel == 1 ? 0.3 : -0.3);
	if (clase == "gol") {
		d["gol"] = (int64_t)(nivel == 0 ? 1 : 0);
	} else if (clase == "asist") {
		d["asist"] = (int64_t)(nivel == 0 ? 1 : 0);
	} else if (clase == "muro") {
		d["encajado"] = (int64_t)(nivel == 2 ? 1 : 0);
	} else if (clase == "guante") {
		d["parada"] = (int64_t)(nivel < 2 ? 1 : 0);
		d["encajado"] = (int64_t)(nivel == 2 ? 1 : 0);
	}
	if ((int64_t)d["gol"] == 1) {
		d["nota"] = 1.0;
	}
	return d;
}

void DinastiaNativo::_bind_puras7() {
	ClassDB::bind_method(D_METHOD("nuc_zona_habilidad", "hab"), &DinastiaNativo::nuc_zona_habilidad);
	ClassDB::bind_method(D_METHOD("nuc_ritmo_fuego", "hay_presion"), &DinastiaNativo::nuc_ritmo_fuego);
	ClassDB::bind_method(D_METHOD("nuc_elegir_expendedora", "energia", "hambre"), &DinastiaNativo::nuc_elegir_expendedora);
	ClassDB::bind_method(D_METHOD("nuc_elegir_gasolinera", "hambre"), &DinastiaNativo::nuc_elegir_gasolinera);
	ClassDB::bind_method(D_METHOD("nuc_def_corner", "clave"), &DinastiaNativo::nuc_def_corner);
	ClassDB::bind_method(D_METHOD("nuc_def_libre", "clave"), &DinastiaNativo::nuc_def_libre);
	ClassDB::bind_method(D_METHOD("nuc_def_campana", "clave"), &DinastiaNativo::nuc_def_campana);
	ClassDB::bind_method(D_METHOD("nuc_fila_logro", "clave"), &DinastiaNativo::nuc_fila_logro);
	ClassDB::bind_method(D_METHOD("nuc_datos_reto", "id"), &DinastiaNativo::nuc_datos_reto);
	ClassDB::bind_method(D_METHOD("nuc_articulo_ropero", "id"), &DinastiaNativo::nuc_articulo_ropero);
	ClassDB::bind_method(D_METHOD("nuc_desenlace_momento", "tipo", "q"), &DinastiaNativo::nuc_desenlace_momento);
}
