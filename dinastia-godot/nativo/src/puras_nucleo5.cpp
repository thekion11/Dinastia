// FUNCIONES PURAS DEL NÚCLEO EN C++ (5.ª tanda, 21-11-2026, orden 63). Mismas reglas que `puras_nucleo.cpp`: traducción literal de la
// gemela GDScript `<nombre>_gd`; las tablas (niveles de reputación, rutina, calles, rarezas) se copiaron de las constantes del GDScript.
// Ninguna modifica sus argumentos.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/string.hpp>

#include <cstdint>
#include <cstdlib>
#include <vector>

using namespace godot;

namespace {
struct Nivel {
	int64_t umbral;
	const char *nombre;
	const char *icono;
	int64_t tope;
	double mult;
};
// `Reputacion.NIVELES`
const Nivel NIVELES[] = {
	{ 0, "Local", "🏘️", 4, 1.00 },
	{ 35, "Regional", "🗺️", 6, 1.05 },
	{ 52, "Nacional", "🏳️", 8, 1.12 },
	{ 68, "Continental", "🌎", 10, 1.22 },
	{ 80, "Mundial", "🌍", 10, 1.35 },
	{ 90, "Leyenda", "👑", 10, 1.50 },
};
const int64_t N_NIVELES = (int64_t)(sizeof(NIVELES) / sizeof(NIVELES[0]));

// `Reloj.RUTINA`
struct Tramo {
	int64_t desde;
	const char *actividad;
};
const Tramo RUTINA[] = {
	{ 0, "dormir" }, { 420, "comer" }, { 450, "libre" }, { 540, "trabajo" }, { 780, "comer" },
	{ 810, "trabajo" }, { 1080, "libre" }, { 1230, "comer" }, { 1260, "libre" }, { 1380, "dormir" },
};
const int64_t MINUTOS_DIA = 1440;

int64_t clampi_(int64_t v, int64_t lo, int64_t hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}
} // namespace

// `Reputacion.nivel_de`
int64_t DinastiaNativo::nuc_nivel_reputacion(int64_t rep) const {
	int64_t n = 0;
	for (int64_t i = 0; i < N_NIVELES; i++) {
		if (rep >= NIVELES[i].umbral) {
			n = i;
		}
	}
	return n;
}

// `Reputacion.nombre_nivel`: «icono nombre»
String DinastiaNativo::nuc_nombre_nivel(int64_t rep) const {
	const Nivel &f = NIVELES[nuc_nivel_reputacion(rep)];
	return String::utf8(f.icono) + String(" ") + String::utf8(f.nombre);
}

// `Reputacion.tope_instalaciones`
int64_t DinastiaNativo::nuc_tope_instalaciones(int64_t rep) const {
	return NIVELES[nuc_nivel_reputacion(rep)].tope;
}

// `Reputacion.mult_patrocinio`
double DinastiaNativo::nuc_mult_patrocinio(int64_t rep) const {
	return NIVELES[nuc_nivel_reputacion(rep)].mult;
}

// `HabilidadesJugador.estrellas_de` (UMBRALES = [74.0, 81.0, 88.0])
int64_t DinastiaNativo::nuc_estrellas_de(double puntos) const {
	static const double UMBRALES[] = { 74.0, 81.0, 88.0 };
	int64_t n = 0;
	for (double u : UMBRALES) {
		if (puntos >= u) {
			n++;
		}
	}
	return n;
}

// `Finanzas.meses_de` (SEMANAS_DEL_MES = 4, MESES_TEMPORADA = 10; la división entera trunca igual que en GDScript)
int64_t DinastiaNativo::nuc_meses_de(int64_t partidos_en_casa) const {
	if (partidos_en_casa > 0) {
		const int64_t m = partidos_en_casa * 2 / 4;
		return m > 1 ? m : 1;
	}
	return 10;
}

// `Reloj.actividad_de_rutina`
String DinastiaNativo::nuc_actividad_rutina(int64_t minuto) const {
	String act = String::utf8(RUTINA[0].actividad);
	for (const Tramo &t : RUTINA) {
		if (minuto >= t.desde) {
			act = String::utf8(t.actividad);
		}
	}
	return act;
}

// `Reloj._fin_tramo`
int64_t DinastiaNativo::nuc_fin_tramo(int64_t minuto) const {
	for (const Tramo &t : RUTINA) {
		if (t.desde > minuto) {
			return t.desde;
		}
	}
	return MINUTOS_DIA;
}

// `CallesCiudad.nombre_columna` / `nombre_fila` (K = 12; `clampi` sobre el tamaño de la tabla)
String DinastiaNativo::nuc_nombre_columna(int64_t i) const {
	static const std::vector<String> T = { String::utf8("Av. Las Tinajas"), String::utf8("Los Chincoles"), String::utf8("Los Talleres"), String::utf8("Av. La Chimba"), String::utf8("Los Tejares"), String::utf8("Las Bodegas"), String::utf8("Av. Los Pescadores"), String::utf8("Av. La Ribera"), String::utf8("El Molle"), String::utf8("Av. El Salitre"), String::utf8("Los Aromos"), String::utf8("El Peumo"), String::utf8("Av. Los Copihues"), String::utf8("Las Camelias"), String::utf8("Los Maitenes"), String::utf8("Av. Las Araucarias"), String::utf8("Av. Los Alerces"), String::utf8("El Coigüe"), String::utf8("Av. La Cordillera"), String::utf8("Los Litres"), String::utf8("Las Lilas"), String::utf8("Av. Los Andes"), String::utf8("Los Zorzales"), String::utf8("Las Diucas"), String::utf8("Av. Cerro Blanco") };
	return T[clampi_(i + 12, 0, (int64_t)T.size() - 1)];
}

String DinastiaNativo::nuc_nombre_fila(int64_t j) const {
	static const std::vector<String> T = { String::utf8("Av. Las Vizcachas"), String::utf8("Los Canelos"), String::utf8("Los Espinos"), String::utf8("Av. El Algarrobo"), String::utf8("Los Jazmines"), String::utf8("El Arrayán"), String::utf8("Av. Los Pimientos"), String::utf8("Las Achiras"), String::utf8("Av. El Estadio"), String::utf8("Av. Las Golondrinas"), String::utf8("Los Tordos"), String::utf8("Las Loicas"), String::utf8("Av. La Herradura"), String::utf8("El Belloto"), String::utf8("Los Lingues"), String::utf8("Av. Los Quillayes"), String::utf8("El Ulmo"), String::utf8("Las Pataguas"), String::utf8("Av. El Sauce"), String::utf8("Los Raulíes"), String::utf8("El Chañar"), String::utf8("Av. Las Acacias"), String::utf8("Los Queltehues"), String::utf8("Las Tencas"), String::utf8("Av. Los Cóndores") };
	return T[clampi_(j + 12, 0, (int64_t)T.size() - 1)];
}

// `Meta.rareza_de` (RAREZAS = leyenda 999, oro 80, plata 70, bronce 0)
String DinastiaNativo::nuc_rareza_de(int64_t ovr, bool leyenda) const {
	if (leyenda) {
		return "leyenda";
	}
	if (ovr >= 80) {
		return "oro";
	}
	if (ovr >= 70) {
		return "plata";
	}
	return "bronce";
}

// `RecorridosRed.base_de`: quita UN «c» y después UN «e» del final (trim_suffix no repite)
String DinastiaNativo::nuc_base_recorrido(const String &r) const {
	String t = r;
	if (t.ends_with("c")) {
		t = t.substr(0, t.length() - 1);
	}
	if (t.ends_with("e")) {
		t = t.substr(0, t.length() - 1);
	}
	return t;
}

// `absi(s.hash())` (Politica._h, CitasP1._h, HistoriaClub._h, Clima._hash)
int64_t DinastiaNativo::nuc_hash_abs(const String &s) const {
	return (int64_t)s.hash();
}

void DinastiaNativo::_bind_puras5() {
	ClassDB::bind_method(D_METHOD("nuc_nivel_reputacion", "rep"), &DinastiaNativo::nuc_nivel_reputacion);
	ClassDB::bind_method(D_METHOD("nuc_nombre_nivel", "rep"), &DinastiaNativo::nuc_nombre_nivel);
	ClassDB::bind_method(D_METHOD("nuc_tope_instalaciones", "rep"), &DinastiaNativo::nuc_tope_instalaciones);
	ClassDB::bind_method(D_METHOD("nuc_mult_patrocinio", "rep"), &DinastiaNativo::nuc_mult_patrocinio);
	ClassDB::bind_method(D_METHOD("nuc_estrellas_de", "puntos"), &DinastiaNativo::nuc_estrellas_de);
	ClassDB::bind_method(D_METHOD("nuc_meses_de", "partidos_en_casa"), &DinastiaNativo::nuc_meses_de);
	ClassDB::bind_method(D_METHOD("nuc_actividad_rutina", "minuto"), &DinastiaNativo::nuc_actividad_rutina);
	ClassDB::bind_method(D_METHOD("nuc_fin_tramo", "minuto"), &DinastiaNativo::nuc_fin_tramo);
	ClassDB::bind_method(D_METHOD("nuc_nombre_columna", "i"), &DinastiaNativo::nuc_nombre_columna);
	ClassDB::bind_method(D_METHOD("nuc_nombre_fila", "j"), &DinastiaNativo::nuc_nombre_fila);
	ClassDB::bind_method(D_METHOD("nuc_rareza_de", "ovr", "leyenda"), &DinastiaNativo::nuc_rareza_de);
	ClassDB::bind_method(D_METHOD("nuc_base_recorrido", "r"), &DinastiaNativo::nuc_base_recorrido);
	ClassDB::bind_method(D_METHOD("nuc_hash_abs", "s"), &DinastiaNativo::nuc_hash_abs);
}
