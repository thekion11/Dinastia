// FUNCIONES PURAS DEL NÚCLEO EN C++ (6.ª tanda, 21-11-2026, orden 63). Mismas reglas que `puras_nucleo.cpp`: traducción literal de la
// gemela GDScript `<nombre>_gd`. Las de recorridos usan `hash(Array)` del motor (UtilityFunctions::hash = el `hash()` de GDScript).
// Ninguna modifica sus argumentos.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cstdint>
#include <cstdlib>
#include <vector>

using namespace godot;

namespace {
int64_t absi_(int64_t v) {
	return v < 0 ? -v : v;
}

// `RecorridosRed.base_de`
String base_de_(const String &r) {
	String t = r;
	if (t.ends_with("c")) {
		t = t.substr(0, t.length() - 1);
	}
	if (t.ends_with("e")) {
		t = t.substr(0, t.length() - 1);
	}
	return t;
}

int64_t flota_(const String &r) {
	Array a;
	a.append(base_de_(r));
	a.append(String("flota"));
	return 6 + absi_(UtilityFunctions::hash(a)) % 9;
}

// `IdiomasInverso._prefijo`
int64_t prefijo_(const String &a, const String &b) {
	const String x = a.to_lower();
	const String y = b.to_lower();
	int64_t n = 0;
	while (n < x.length() && n < y.length() && x.unicode_at(n) == y.unicode_at(n)) {
		n++;
	}
	return n;
}

// `Actualizador.partes`: los números de cada trozo separado por «.» (los no numéricos valen 0)
std::vector<int64_t> partes_(const String &v) {
	String s = v.strip_edges();
	if (s.begins_with("v")) {
		s = s.substr(1);
	}
	if (s.begins_with("V")) {
		s = s.substr(1);
	}
	std::vector<int64_t> out;
	const PackedStringArray trozos = s.split(".");
	for (int64_t i = 0; i < trozos.size(); i++) {
		const String trozo = trozos[i];
		String n;
		for (int64_t k = 0; k < trozo.length(); k++) {
			const char32_t c = trozo[k];
			if (c >= U'0' && c <= U'9') {
				n += String::chr(c);
			} else {
				break;
			}
		}
		out.push_back(n != "" ? n.to_int() : 0);
	}
	return out;
}
} // namespace

// `Actualizador.comparar`
int64_t DinastiaNativo::nuc_comparar_version(const String &a, const String &b) const {
	const std::vector<int64_t> pa = partes_(a);
	const std::vector<int64_t> pb = partes_(b);
	const size_t n = pa.size() > pb.size() ? pa.size() : pb.size();
	for (size_t i = 0; i < n; i++) {
		const int64_t x = i < pa.size() ? pa[i] : 0;
		const int64_t y = i < pb.size() ? pb[i] : 0;
		if (x != y) {
			return x < y ? -1 : 1;
		}
	}
	return 0;
}

// `Actualizador.nombre_archivo` y `ruta_destino` (CARPETA = "user://parches")
String DinastiaNativo::nuc_nombre_parche(const String &version) const {
	return String("parche_") + version + String(".pck");
}

String DinastiaNativo::nuc_ruta_parche(const String &version) const {
	return String("user://parches").path_join(nuc_nombre_parche(version));
}

// `Nombres.huella`
String DinastiaNativo::nuc_huella_nombre(const String &nombre) const {
	return nombre.strip_edges().to_lower().md5_text().substr(0, 12);
}

// `PresetsTactica.limpiar_nombre` (LARGO_NOMBRE = 24)
String DinastiaNativo::nuc_limpiar_nombre_tactica(const String &n) const {
	return n.strip_edges().left(24);
}

// `FormacionPropia.nombre_valido` (PREFIJO = «★ »)
String DinastiaNativo::nuc_nombre_valido_formacion(const String &nombre) const {
	const String prefijo = String::utf8("★ ");
	const String n = nombre.strip_edges().replace(prefijo, "").left(24);
	return prefijo + (n != "" ? n : String::utf8("Mi formación"));
}

// `FormatosConti.premio_de_ronda` (PREMIO_RONDA y PREMIO_RONDA_LIB)
int64_t DinastiaNativo::nuc_premio_de_ronda(const String &k, int64_t vivos_antes) const {
	const bool lib = (k == "lib" || k == "sud");
	switch (vivos_antes) {
		case 16:
			return lib ? 180000 : 90000;
		case 8:
			return lib ? 350000 : 180000;
		case 4:
			return lib ? 500000 : 250000;
		default:
			return 0;
	}
}

// `RecorridosRed.flota`, `patente` y `ocupacion`
int64_t DinastiaNativo::nuc_flota_recorrido(const String &r) const {
	return flota_(r);
}

String DinastiaNativo::nuc_patente_recorrido(const String &r, int64_t bus) const {
	static const String LETRAS = "BCDFGHJKLPRSTVWXYZ";
	Array id;
	id.append(base_de_(r));
	id.append(bus % flota_(r));
	Array a = id.duplicate();
	a.append(String("patente"));
	int64_t h = absi_(UtilityFunctions::hash(a));
	String s;
	for (int i = 0; i < 4; i++) {
		s += LETRAS.substr(h % LETRAS.length(), 1);
		h /= LETRAS.length();
	}
	Array c = id.duplicate();
	c.append(String("cifras"));
	const int64_t cif = 10 + absi_(UtilityFunctions::hash(c)) % 90;
	return s + String("-") + String::num_int64(cif).lpad(2, "0");
}

int64_t DinastiaNativo::nuc_ocupacion_recorrido(const String &r, int64_t vuelta, int64_t minuto_dia, int64_t dia) const {
	Array a;
	a.append(r);
	a.append(vuelta);
	a.append(dia);
	a.append(String("ocup"));
	const int64_t o = absi_(UtilityFunctions::hash(a)) % 10;
	const int64_t h = minuto_dia / 60;
	const bool punta = dia < 5 && ((h >= 7 && h < 9) || (h >= 18 && h < 20));
	if (punta) {
		return o < 3 ? 0 : (o < 7 ? 1 : 2);
	}
	return o < 6 ? 0 : (o < 9 ? 1 : 2);
}

// `IdiomasInverso.mejor`
String DinastiaNativo::nuc_mejor_inverso(const String &actual, const String &nueva, const String &traduccion) const {
	if (actual == "") {
		return nueva;
	}
	return prefijo_(nueva, traduccion) >= prefijo_(actual, traduccion) ? nueva : actual;
}

// `RecorridosMapa.vuelta_de`
String DinastiaNativo::nuc_vuelta_recorrido(const String &num) const {
	if (!num.ends_with("c")) {
		String t = num;
		if (t.ends_with("e")) {
			t = t.substr(0, t.length() - 1);
		}
		return t + String("c");
	}
	return num.substr(0, num.length() - 1);
}

void DinastiaNativo::_bind_puras6() {
	ClassDB::bind_method(D_METHOD("nuc_comparar_version", "a", "b"), &DinastiaNativo::nuc_comparar_version);
	ClassDB::bind_method(D_METHOD("nuc_nombre_parche", "version"), &DinastiaNativo::nuc_nombre_parche);
	ClassDB::bind_method(D_METHOD("nuc_ruta_parche", "version"), &DinastiaNativo::nuc_ruta_parche);
	ClassDB::bind_method(D_METHOD("nuc_huella_nombre", "nombre"), &DinastiaNativo::nuc_huella_nombre);
	ClassDB::bind_method(D_METHOD("nuc_limpiar_nombre_tactica", "n"), &DinastiaNativo::nuc_limpiar_nombre_tactica);
	ClassDB::bind_method(D_METHOD("nuc_nombre_valido_formacion", "nombre"), &DinastiaNativo::nuc_nombre_valido_formacion);
	ClassDB::bind_method(D_METHOD("nuc_premio_de_ronda", "k", "vivos_antes"), &DinastiaNativo::nuc_premio_de_ronda);
	ClassDB::bind_method(D_METHOD("nuc_flota_recorrido", "r"), &DinastiaNativo::nuc_flota_recorrido);
	ClassDB::bind_method(D_METHOD("nuc_patente_recorrido", "r", "bus"), &DinastiaNativo::nuc_patente_recorrido);
	ClassDB::bind_method(D_METHOD("nuc_ocupacion_recorrido", "r", "vuelta", "minuto_dia", "dia"), &DinastiaNativo::nuc_ocupacion_recorrido);
	ClassDB::bind_method(D_METHOD("nuc_mejor_inverso", "actual", "nueva", "traduccion"), &DinastiaNativo::nuc_mejor_inverso);
	ClassDB::bind_method(D_METHOD("nuc_vuelta_recorrido", "num"), &DinastiaNativo::nuc_vuelta_recorrido);
}
