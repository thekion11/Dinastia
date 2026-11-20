// FUNCIONES PURAS DEL NÚCLEO EN C++ (20-11-2026, orden 63 del dueño: todo lo portable pasa a C++ aunque no gane tiempo).
// Cada una es la traducción LITERAL de su versión GDScript (mismas operaciones y mismo orden, `float` de GDScript = double),
// que se queda como gemela `<nombre>_gd` (respaldo para plataformas sin binario y comparación en `pruebas/probar_nativo_puras.gd`).
// Aritmética entera como en GDScript (división/módulo truncados); `int(x)` = truncar; `round` = `std::round` (mitad lejos del 0).
#include "dinastia_nativo.h"

#include <godot_cpp/variant/string.hpp>

#include <cmath>
#include <cstdint>

using namespace godot;

namespace {
// `clampi`/`clampf` de GDScript (macro CLAMP del motor: no reordena min y max).
inline int64_t clampi_(int64_t v, int64_t lo, int64_t hi) { return v < lo ? lo : (v > hi ? hi : v); }
inline double clampf_(double v, double lo, double hi) { return v < lo ? lo : (v > hi ? hi : v); }
inline double maxf_(double a, double b) { return a > b ? a : b; }
// `posmod` del motor.
inline int64_t posmod_(int64_t a, int64_t b) {
	int64_t v = a % b;
	if ((v < 0 && b > 0) || (v > 0 && b < 0)) {
		v += b;
	}
	return v;
}
} // namespace

void DinastiaNativo::_bind_puras() {
	_bind_puras2();
	ClassDB::bind_method(D_METHOD("nuc_cuota_francesa", "deuda", "tasa", "cuotas"), &DinastiaNativo::nuc_cuota_francesa);
	ClassDB::bind_method(D_METHOD("nuc_pascua", "anio"), &DinastiaNativo::nuc_pascua);
	ClassDB::bind_method(D_METHOD("nuc_es_avenida_columna", "i"), &DinastiaNativo::nuc_es_avenida_columna);
	ClassDB::bind_method(D_METHOD("nuc_es_avenida_fila", "j"), &DinastiaNativo::nuc_es_avenida_fila);
	ClassDB::bind_method(D_METHOD("nuc_agente_aprieta", "clientes", "confianza"), &DinastiaNativo::nuc_agente_aprieta);
	ClassDB::bind_method(D_METHOD("nuc_por_edad", "edad"), &DinastiaNativo::nuc_por_edad);
	ClassDB::bind_method(D_METHOD("nuc_alcanza", "prestigio"), &DinastiaNativo::nuc_alcanza);
	ClassDB::bind_method(D_METHOD("nuc_puntos_mundial", "nota", "goles", "asist", "titulos"), &DinastiaNativo::nuc_puntos_mundial);
	ClassDB::bind_method(D_METHOD("nuc_xp_para", "n"), &DinastiaNativo::nuc_xp_para);
	ClassDB::bind_method(D_METHOD("nuc_clave_dia", "anio", "semana", "dia"), &DinastiaNativo::nuc_clave_dia);
	ClassDB::bind_method(D_METHOD("nuc_abs_semana", "anio", "semana"), &DinastiaNativo::nuc_abs_semana);
	ClassDB::bind_method(D_METHOD("nuc_mes_de", "semana"), &DinastiaNativo::nuc_mes_de);
	ClassDB::bind_method(D_METHOD("nuc_orden_de_semillas", "n"), &DinastiaNativo::nuc_orden_de_semillas);
	ClassDB::bind_method(D_METHOD("nuc_socios_de", "aforo", "rep"), &DinastiaNativo::nuc_socios_de);
	ClassDB::bind_method(D_METHOD("nuc_rr", "n"), &DinastiaNativo::nuc_rr);
	ClassDB::bind_method(D_METHOD("nuc_puesto_de", "x", "y"), &DinastiaNativo::nuc_puesto_de);
	ClassDB::bind_method(D_METHOD("nuc_es_letra", "c"), &DinastiaNativo::nuc_es_letra);
	ClassDB::bind_method(D_METHOD("nuc_techo_tope", "techo", "ovr"), &DinastiaNativo::nuc_techo_tope);
	ClassDB::bind_method(D_METHOD("nuc_delta_de", "peso", "cumplido"), &DinastiaNativo::nuc_delta_de);
	ClassDB::bind_method(D_METHOD("nuc_hueco", "minuto", "minuto_fin", "restantes"), &DinastiaNativo::nuc_hueco);
	ClassDB::bind_method(D_METHOD("nuc_prob_tiro_3d", "dist", "lateral", "tapada", "tiro_attr"), &DinastiaNativo::nuc_prob_tiro_3d);
	ClassDB::bind_method(D_METHOD("nuc_cuota", "p"), &DinastiaNativo::nuc_cuota);
	ClassDB::bind_method(D_METHOD("nuc_curva_hora", "hora"), &DinastiaNativo::nuc_curva_hora);
	ClassDB::bind_method(D_METHOD("nuc_delegacion", "rep"), &DinastiaNativo::nuc_delegacion);
	ClassDB::bind_method(D_METHOD("nuc_dir_equipo", "eq"), &DinastiaNativo::nuc_dir_equipo);
	ClassDB::bind_method(D_METHOD("nuc_toca_olimpicos", "anio"), &DinastiaNativo::nuc_toca_olimpicos);
}

// `Banco.cuota_francesa`
int64_t DinastiaNativo::nuc_cuota_francesa(int64_t deuda, double tasa, int64_t cuotas) const {
	if (cuotas <= 0) {
		return deuda;
	}
	if (tasa <= 0.0) {
		return (int64_t)std::ceil((double)deuda / (double)cuotas);
	}
	const double f = std::pow(1.0 + tasa, -(double)cuotas);
	return (int64_t)std::ceil((double)deuda * tasa / (1.0 - f));
}

// `Calendario.pascua`: [mes, dia] de la Pascua (cómputo de Gauss con las divisiones de GDScript: entero / flotante → truncar).
Array DinastiaNativo::nuc_pascua(int64_t anio) const {
	const int64_t a = anio % 19;
	const int64_t b = (int64_t)((double)anio / 100.0);
	const int64_t c = anio % 100;
	const int64_t d = (int64_t)((double)b / 4.0);
	const int64_t e = b % 4;
	const int64_t f = (int64_t)((double)(b + 8) / 25.0);
	const int64_t g = (int64_t)((double)(b - f + 1) / 3.0);
	const int64_t h = (19 * a + b - d - g + 15) % 30;
	const int64_t i = (int64_t)((double)c / 4.0);
	const int64_t k = c % 4;
	const int64_t l = (32 + 2 * e + 2 * i - h - k) % 7;
	const int64_t m = (int64_t)((double)(a + 11 * h + 22 * l) / 451.0);
	const int64_t mes = (int64_t)((double)(h + l - 7 * m + 114) / 31.0);
	const int64_t dia = ((h + l - 7 * m + 114) % 31) + 1;
	Array r;
	r.append(mes);
	r.append(dia);
	return r;
}

// `CallesCiudad.es_avenida_columna` / `es_avenida_fila`
bool DinastiaNativo::nuc_es_avenida_columna(int64_t i) const { return i % 3 == 0 || i == -5 || i == 4; }
bool DinastiaNativo::nuc_es_avenida_fila(int64_t j) const { return j % 3 == 0 || j == -4 || j == 6; }

// `Cantera.agente_aprieta`
bool DinastiaNativo::nuc_agente_aprieta(int64_t clientes, int64_t confianza) const { return clientes >= 2 && confianza < 0; }

// `CanteraProgreso.por_edad`
double DinastiaNativo::nuc_por_edad(int64_t edad) const { return edad <= 20 ? 0.8 : (edad <= 22 ? 0.4 : 0.25); }

// `CargoSeleccion._alcanza`
int64_t DinastiaNativo::nuc_alcanza(int64_t prestigio) const { return 40 + (int64_t)std::round((double)prestigio * 0.6); }

// `CarreraPremios._puntos_mundial`
double DinastiaNativo::nuc_puntos_mundial(double nota, int64_t goles, int64_t asist, int64_t titulos) const {
	return nota * 10.0 + (double)(goles + asist) * 0.3 + (double)titulos * 3.0;
}

// `CarreraRuta.xp_para`
int64_t DinastiaNativo::nuc_xp_para(int64_t n) const { return 150 + 60 * n; }

// `CarteraDT.clave_dia`
int64_t DinastiaNativo::nuc_clave_dia(int64_t anio, int64_t semana, int64_t dia) const { return anio * 1000 + semana * 10 + dia; }

// `Charlas._abs`, `EventosCantera._abs`, `Licencia._abs`, `VidaDT._abs` (las cuatro son la misma cuenta): semana absoluta.
int64_t DinastiaNativo::nuc_abs_semana(int64_t anio, int64_t semana) const { return anio * 60 + semana; }

// `Clima.mes_de`
int64_t DinastiaNativo::nuc_mes_de(int64_t semana) const {
	const int64_t s = semana > 1 ? semana : 1;
	return clampi_(1 + (int64_t)((double)(s - 1) * 7.0 / 30.4 + 0.85), 1, 12);
}

// `Continental._orden_de_semillas`
Array DinastiaNativo::nuc_orden_de_semillas(int64_t n) const {
	Array orden;
	orden.append((int64_t)0);
	int64_t tam = 1;
	while (tam < n) {
		Array sig;
		for (int64_t k = 0; k < orden.size(); k++) {
			const int64_t x = orden[k];
			sig.append(x);
			sig.append(tam * 2 - 1 - x);
		}
		orden = sig;
		tam *= 2;
	}
	return orden;
}

// `EntradaCampeonato._socios_de`
int64_t DinastiaNativo::nuc_socios_de(int64_t aforo, int64_t rep) const { return (int64_t)((double)aforo * (0.22 + (double)rep / 420.0)); }

// `FaseFinalLiga._rr`
int64_t DinastiaNativo::nuc_rr(int64_t n) const { return n % 2 == 1 ? n : n - 1; }

// `FormacionPropia.puesto_de`
String DinastiaNativo::nuc_puesto_de(double x, double y) const {
	const bool banda = x >= 76.0 || x <= 24.0;
	const bool derecha = x >= 50.0;
	if (banda) {
		if (y >= 70.0) {
			return derecha ? "LD" : "LI";
		}
		if (y >= 54.0) {
			return derecha ? "CAD" : "CAI";
		}
		if (y >= 28.0) {
			return derecha ? "MD" : "MI";
		}
		return derecha ? "ED" : "EI";
	}
	if (y >= 70.0) {
		return "DFC";
	}
	if (y >= 58.0) {
		return "MCD";
	}
	if (y >= 40.0) {
		return "MC";
	}
	if (y >= 28.0) {
		return "MCO";
	}
	return "DC";
}

// `Idiomas._es_letra`
bool DinastiaNativo::nuc_es_letra(int64_t c) const {
	return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || (c >= 192 && c <= 687) || (c >= 48 && c <= 57) || c == 191 || c == 161;
}

// `Jugador.techo_tope`
int64_t DinastiaNativo::nuc_techo_tope(int64_t techo, int64_t ovr) const {
	int64_t t = techo;
	if (t > 90) {
		t = 90 + (int64_t)std::round((double)(t - 90) * 0.5);
	}
	return clampi_(t, ovr, 97);
}

// `ObjetivosCierre.delta_de`
int64_t DinastiaNativo::nuc_delta_de(int64_t peso, bool cumplido) const {
	return cumplido ? peso : -(int64_t)std::ceil((double)peso * 1.25);
}

// `OcasionesDT.hueco`
int64_t DinastiaNativo::nuc_hueco(int64_t minuto, int64_t minuto_fin, int64_t restantes) const {
	if (restantes <= 0) {
		return 999;
	}
	return clampi_((int64_t)((double)(minuto_fin - minuto) / ((double)restantes + 1.5)), 3, 15);
}

// `OcasionesDT.prob_tiro_3d`
double DinastiaNativo::nuc_prob_tiro_3d(double dist, double lateral, bool tapada, double tiro_attr) const {
	if (tapada) {
		return 0.02;
	}
	const double geo = 0.08 + 0.85 * std::exp(-(dist - 8.0) / 7.0) + 0.006 * std::fabs(lateral);
	const double calidad = 0.65 + 0.35 * clampf_((tiro_attr - 0.54) / 0.45, -0.5, 1.2);
	return clampf_(geo * calidad, 0.02, 0.9);
}

// `Previa._cuota`
double DinastiaNativo::nuc_cuota(double p) const { return maxf_(1.03, 1.07 / maxf_(p, 0.01)); }

// `RedesCiudad.curva`
double DinastiaNativo::nuc_curva_hora(int64_t hora) const {
	const double h = (double)posmod_(hora, 24);
	return 0.4 + 0.45 * std::exp(-std::pow(h - 8.0, 2.0) / 8.0) + 0.6 * std::exp(-std::pow(h - 20.0, 2.0) / 10.0);
}

// `Viajes.delegacion`
int64_t DinastiaNativo::nuc_delegacion(int64_t rep) const {
	return clampi_((int64_t)std::round(38.0 + ((double)rep - 70.0) * 0.45), 32, 52);
}

// `MotorLibre._dir`
double DinastiaNativo::nuc_dir_equipo(int64_t eq) const { return eq == 0 ? 1.0 : -1.0; }

// `Olimpicos.toca`
bool DinastiaNativo::nuc_toca_olimpicos(int64_t anio) const { return anio >= 2028 && (anio - 2028) % 4 == 0; }
