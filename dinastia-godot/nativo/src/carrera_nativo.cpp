// LA CURVA DE PROGRESO, LOS PRECIOS DE «LA RUTA» Y EL JUGADOR DEL MES, EN C++ (19-11-2026, orden del dueño: «convertir GDScript a C++ con líneas tocadas hace muy poco»).
// Cada función es copia operación a operación de su gemela GDScript (que se queda como respaldo y es la que corre si no hay extensión):
//   prog_*   = `nucleo/cantera_progreso.gd` (`ProgresoJugador`, 18-11),
//   hab_*    = `nucleo/carrera_habilidad.gd` (`CarreraHabilidad`, 16-11),
//   premio_* = `nucleo/premio_mensual.gd` (`PremioMensual.elegir`, 17-11).
// Cálculo en float de 64 bits (el `float` de GDScript). `pruebas/probar_nativo_carrera.gd` compara todo con la gemela GDScript.
#include "dinastia_nativo.h"

#include <godot_cpp/core/math.hpp>

#include <cmath>
#include <vector>

using namespace godot;

namespace {
inline double clampf_gd(double v, double lo, double hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}
// `ceili` de GDScript: Math::ceil y a entero.
inline int64_t ceili_gd(double v) {
	return int64_t(std::ceil(v));
}
// `posmod` de GDScript para enteros (resto siempre >= 0 con divisor > 0).
inline int64_t posmod_gd(int64_t a, int64_t b) {
	int64_t v = a % b;
	if (v < 0) {
		v += b;
	}
	return v;
}
}  // namespace

// `ProgresoJugador.por_edad`.
double DinastiaNativo::prog_por_edad(int64_t edad) const {
	return edad <= 20 ? 0.8 : (edad <= 22 ? 0.4 : 0.25);
}

// `ProgresoJugador.freno`.
double DinastiaNativo::prog_freno(int64_t edad, int64_t ovr, int64_t pot) const {
	if (ovr >= pot || edad >= 24) {
		return 0.0;
	}
	return prog_por_edad(edad) * clampf_gd(double(pot - ovr) / 8.0, 0.35, 1.0);
}

// `ProgresoJugador.prob_semanal`.
double DinastiaNativo::prog_prob_semanal(int64_t edad, int64_t ovr, int64_t pot, bool motor) const {
	double p = 0.10 * prog_freno(edad, ovr, pot);
	if (motor) {
		p *= 1.5;
	}
	return p;
}

// `CarreraHabilidad._factor_nivel`.
double DinastiaNativo::hab_factor_nivel(int64_t nivel) const {
	return 1.0 + double(nivel - 1) * 0.05;
}

// `CarreraHabilidad._factor_puesto`: `pesos` = los de `PesosPuesto.de(pos_e)[1]` (vacío si el puesto no tiene).
double DinastiaNativo::hab_factor_puesto(const PackedFloat64Array &pesos) const {
	double maximo = 0.0;
	for (int64_t i = 0; i < pesos.size(); i++) {
		const double w = pesos[i];
		maximo = w > maximo ? w : maximo;
	}
	return maximo > 0.0 ? clampf_gd(maximo / 0.39, 0.5, 1.5) : 1.0;
}

// `CarreraHabilidad.precio_zona` (sin las lecturas de estado): `valor` = el valor de la habilidad; `clase` = 0 «clave», 1 «util», otro «ajena».
double DinastiaNativo::hab_precio_zona(int64_t valor, int64_t clase, double factor_nivel, double factor_puesto) const {
	const double base = valor < 60 ? 1.0 : (valor < 70 ? 2.0 : (valor < 80 ? 3.0 : (valor < 90 ? 5.0 : 7.0)));
	const double por_puesto = clase == 0 ? 1.0 : (clase == 1 ? 1.5 : 2.0);
	return base * por_puesto * factor_nivel * factor_puesto * 6.0;
}

// `CarreraHabilidad.coste` (la cuenta): `suma` = suma de las habilidades de la zona, `n` = cuántas son, `z` = `precio_zona`.
int64_t DinastiaNativo::hab_coste(int64_t suma, int64_t n, double z) const {
	const double k = double(posmod_gd(suma, n));
	const double nf = double(n);
	const int64_t c = ceili_gd(z * (k + 1.0) / nf - 0.001) - ceili_gd(z * k / nf - 0.001);
	return c > 1 ? c : 1;
}

// `CarreraHabilidad._promedio` (la cuenta): redondeo de GDScript (`round`: .5 se aleja del cero).
int64_t DinastiaNativo::hab_promedio(const PackedInt32Array &valores) const {
	int64_t suma = 0;
	for (int64_t i = 0; i < valores.size(); i++) {
		suma += valores[i];
	}
	const int64_t n = valores.size() > 1 ? valores.size() : 1;
	return int64_t(std::round(double(suma) / double(n)));
}

// `CarreraHabilidad.coste_puesto` (la cuenta): `misma_linea` = el puesto nuevo es de su misma línea, `conocido` = ya está en `pos_sec`.
int64_t DinastiaNativo::hab_coste_puesto(bool misma_linea, bool conocido, double factor_nivel) const {
	int64_t base = misma_linea ? 12 : 24;
	if (conocido) {
		base = int64_t(double(base) / 2.0);
	}
	const int64_t c = ceili_gd(double(base) * factor_nivel - 0.001);
	return c > 1 ? c : 1;
}

// `CarreraHabilidad.detalle` (el reparto inicial de una zona): para cada habilidad de `ids`, su valor alrededor de `meta` con el desvío fijo del jugador
// (`absi(hash(id_jugador + id_habilidad)) % 13 - 6`, 0 si la zona tiene una sola) y el promedio puesto en la zona.
PackedInt32Array DinastiaNativo::hab_reparto(const String &id_jugador, const PackedStringArray &ids, int64_t meta) const {
	const int64_t n = ids.size();
	PackedInt32Array sal;
	if (n == 0) {
		return sal;
	}
	sal.resize(n);
	std::vector<int64_t> desvios(n);
	int64_t suma = 0;
	for (int64_t i = 0; i < n; i++) {
		int64_t dv = 0;
		if (n > 1) {
			const int64_t h = int64_t((id_jugador + ids[i]).hash());
			dv = (h < 0 ? -h : h) % 13 - 6;
		}
		desvios[i] = dv;
		suma += dv;
	}
	const int64_t media = int64_t(std::round(double(suma) / double(n)));
	for (int64_t i = 0; i < n; i++) {
		int64_t v = meta + desvios[i] - media;
		v = v < 1 ? 1 : (v > 99 ? 99 : v);
		sal.set(i, int32_t(v));
	}
	return sal;
}

// `PremioMensual.elegir` (el bucle por todos los jugadores de la liga): el ganador entre las plantillas de `clubes` (o null). Lee `plantilla` de cada club
// y `notas`, `partidos` y `ovr` de cada jugador.
Variant DinastiaNativo::premio_mejor(const Array &clubes, int64_t minimo_notas) const {
	static const StringName k_plantilla("plantilla"), k_notas("notas"), k_partidos("partidos"), k_ovr("ovr");
	Variant mejor;
	int64_t mejor_ovr = 0;
	double mejor_media = -1.0;
	for (int64_t ci = 0; ci < clubes.size(); ci++) {
		Object *c = Object::cast_to<Object>(clubes[ci]);
		if (c == nullptr) {
			continue;
		}
		const Array plantilla = c->get(k_plantilla);
		for (int64_t ji = 0; ji < plantilla.size(); ji++) {
			Object *j = Object::cast_to<Object>(plantilla[ji]);
			if (j == nullptr) {
				continue;
			}
			const Array notas = j->get(k_notas);
			const int64_t partidos = j->get(k_partidos);
			const int64_t de_esta = notas.size() < partidos ? notas.size() : partidos;
			if (de_esta < minimo_notas) {
				continue;
			}
			const int64_t cuantas = de_esta < 4 ? de_esta : 4;
			double media = 0.0;
			for (int64_t k = notas.size() - cuantas; k < notas.size(); k++) {
				media += double(notas[k]);
			}
			media /= double(cuantas);
			const int64_t ovr = j->get(k_ovr);
			if (media > mejor_media || (Math::is_equal_approx(media, mejor_media) && mejor.get_type() != Variant::NIL && ovr > mejor_ovr)) {
				mejor_media = media;
				mejor = plantilla[ji];
				mejor_ovr = ovr;
			}
		}
	}
	return mejor;
}
