// LA DECISIÓN DEL PORTADOR DEL BALÓN DE LEAGUE, EN C++ (16-11-2026, paso a C++). Traducción LITERAL de `LeagueNucleo.situacion`, `regate` y `decidir` (visor/league_nucleo.gd) con sus
// piezas `espacio_libre`, `odds_pase`, `odds_pase_a`, `apoyo_pase` y `bono_apoyo`: Vector2 en 32 bits y el resto en double, como GDScript, en el mismo orden de operaciones.
// Las gemelas GDScript (`situacion_gd`, `regate_gd`, `decidir_gd`) se quedan de respaldo; `pruebas/probar_nativo.tscn` comprueba que dan los mismos bytes.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/random_number_generator.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include <cmath>
#include <vector>

using namespace godot;

namespace {

const double MEDIO_LARGO = 52.5;
const double MEDIO_ANCHO = 34.0;
const double V_SPRINT = 8.0;
const double DIST_A_VEL = 2.6;
const int64_t CORTO = 0;
const int64_t LARGO = 1;
const int64_t ALTO = 2;
const int64_t TIRO = 3;

// Los exponentes de `pow` pasan por una variable volátil: GDScript llama a la `pow` de la biblioteca y el compilador no debe convertir `pow(x, 2.0)` en `x * x`.
volatile double EXP_2 = 2.0;
volatile double EXP_1_5 = 1.5;

double clampd(double v, double lo, double hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}

double normalizado(double v, double a, double b) {
	return b != a ? clampd((v - a) / (b - a), 0.0, 1.0) : 0.0;
}

double curva(double x, double sesgo) {
	return (std::sin((x - 0.5) * Math::PI) * 0.5 + 0.5) * sesgo + x * (1.0 - sesgo);
}

double mentalidad(const String &puesto) {
	if (puesto == "POR" || puesto == "DFC") {
		return 0.0;
	}
	if (puesto == "LD" || puesto == "LI" || puesto == "MCD" || puesto == "CAD" || puesto == "CAI") {
		return 0.25;
	}
	if (puesto == "MC" || puesto == "MD" || puesto == "MI") {
		return 0.5;
	}
	if (puesto == "MCO" || puesto == "MP" || puesto == "ED" || puesto == "EI" || puesto == "SD") {
		return 0.75;
	}
	if (puesto == "DC") {
		return 1.0;
	}
	return 0.5;
}

// `LeagueNucleo.rango_velocidad`
double rango_velocidad(double v) {
	if (v >= 1.8 && v < 4.4) {
		return 3.5;
	}
	if (v >= 4.4 && v < 6.2) {
		return 5.0;
	}
	if (v >= 6.2) {
		return 8.0;
	}
	return 0.0;
}

struct Riv {
	Vector2 p;
	Vector2 m;
	bool por;
};

std::vector<Riv> leer_rivales(const Array &rivales) {
	std::vector<Riv> v;
	v.reserve(rivales.size());
	for (int64_t i = 0; i < rivales.size(); i++) {
		const Array r = rivales[i];
		v.push_back(Riv{ r[0], r[1], (bool)r[2] });
	}
	return v;
}

// `LeagueNucleo.espacio_libre`
double espacio_libre(const Vector2 &foco, const std::vector<Riv> &rivales, double seguro, double futuro, bool sin_portero) {
	double suma = 0.0;
	for (const Riv &r : rivales) {
		if (sin_portero && r.por) {
			continue;
		}
		Vector2 rp = r.p + r.m * (float)0.2;
		Vector2 hacia = (foco - rp).normalized() * (float)V_SPRINT * (float)std::fmax(futuro - 0.2, 0.0);
		if ((double)hacia.length() > (double)(foco - rp).length()) {
			hacia = foco - rp;
		}
		rp += hacia;
		suma += 1.0 - clampd((double)(rp - foco).length(), 0.0, seguro) / seguro;
	}
	return 1.0 - normalizado(suma, 0.0, 2.5);
}

// `LeagueNucleo.odds_pase`
double odds_pase(const Vector2 &origen, const Vector2 &destino, int64_t tipo, const std::vector<Riv> &rivales, double mult_vel) {
	const double escala = 1.0;
	double peligro = 0.0;
	const Vector2 seg = destino - origen;
	const double largo2 = (double)seg.length_squared();
	for (const Riv &r : rivales) {
		const Vector2 rp = r.p + r.m * (float)0.2;
		const double u = largo2 > 0.0 ? (double)(rp - origen).dot(seg) / largo2 : 0.0;
		const Vector2 punto = origen + seg * (float)clampd(u, 0.0, 1.0);
		const double dist_r = largo2 > 0.0 ? (double)(rp - (origen + seg * (float)u)).length() : (double)(rp - origen).length();
		if (u >= 0.0 && u <= 1.2) {
			if (tipo != ALTO || u < 0.2 || u > 0.65) {
				const double t_rival = (dist_r + 1.0) / V_SPRINT;
				const double castigo = (tipo == ALTO && u > 0.5) ? 2.5 : 0.0;
				const double t_balon = (0.7 + (double)(punto - origen).length() * u * 0.03 + castigo) / mult_vel;
				peligro += clampd(t_balon - t_rival + escala * 0.5, 0.0, escala);
			}
		}
	}
	if (tipo == ALTO) {
		peligro += 0.4;
	}
	return 1.0 - normalizado(peligro, 0.0, escala);
}

// `LeagueNucleo.odds_pase_a`
double odds_pase_a(const Vector2 &origen, const Vector2 &mov_origen, const Vector2 &receptor, const Vector2 &mov_receptor, double lado, int64_t tipo, const std::vector<Riv> &rivales) {
	const double d0 = (double)(receptor - origen).length();
	if (tipo == ALTO && d0 < 10.0) {
		return 0.0;
	}
	const double t_est = 0.7 + d0 * 0.03;
	Vector2 destino = receptor + mov_receptor * (float)clampd(t_est, 0.0, 0.5);
	if (tipo == LARGO) {
		destino += Vector2((float)(-lado * d0 * 0.2), 0.0f);
	}
	return odds_pase(origen + mov_origen * (float)0.12, destino, tipo, rivales, 1.0);
}

// `LeagueNucleo.situacion`
void situacion(const Vector2 &pos, const Vector2 &mov, double lado, const std::vector<Riv> &rivales, double *sal) {
	const Vector2 adelante_pos = pos + Vector2((float)-lado, 0.0f) * (float)V_SPRINT * (float)0.5;
	sal[0] = espacio_libre(adelante_pos, rivales, 5.0, 0.5, true);
	sal[1] = espacio_libre(pos + mov * (float)0.1, rivales, 5.0, 0.1, true);
	const double cerca = 1.0 - clampd((double)(Vector2((float)(MEDIO_LARGO * -lado), 0.0f) - pos).length() / (MEDIO_LARGO * 2.0), 0.0, 1.0);
	sal[2] = std::pow(cerca, EXP_1_5);
}

// `LeagueNucleo.apoyo_pase` / `bono_apoyo`
bool apoyo_pase(double esp_yo, double esp_c, double nota_yo, double nota_c, double largo_posesion) {
	const double retener = std::fmax(1.0 - clampd(esp_yo, 0.0, 1.0), clampd(largo_posesion, 0.0, 1.0));
	return retener >= 0.55 && esp_c >= esp_yo + 0.12 && nota_c >= nota_yo - 0.15;
}

double bono_apoyo(double esp_yo, double esp_c, double largo_posesion) {
	const double ganancia = clampd((esp_c - esp_yo) / 0.4, 0.0, 1.0);
	const double retener = std::fmax(1.0 - clampd(esp_yo, 0.0, 1.0), clampd(largo_posesion, 0.0, 1.0));
	return ganancia * retener * 0.35;
}

struct Fuerza {
	Vector2 o;
	bool repele;
	bool constante;
	double potencia;
	double escala;
	double exp;
};

// `LeagueNucleo.movimiento_campo` (igual que la de league_equipo_nativo.cpp)
Vector2 campo_movimiento(const std::vector<Fuerza> &campo, const Vector2 &actual, double amortigua) {
	Vector2 suma;
	double fuerza_total = 0.0;
	for (const Fuerza &f : campo) {
		const Vector2 o = f.o;
		const double dist = (double)(o - actual).length();
		double intensidad = 1.0;
		if (!f.constante) {
			intensidad = clampd(1.0 - dist / f.escala, 0.0, 1.0);
			if (f.exp != 1.0) {
				intensidad = std::pow(intensidad, f.exp);
			}
		}
		if (intensidad <= 0.0) {
			continue;
		}
		Vector2 rel = dist > 0.0 ? (o - actual).normalized() : Vector2();
		if (f.repele) {
			rel = -rel;
		} else if (dist < amortigua) {
			rel *= (float)(dist / amortigua);
		}
		const double fz = f.potencia * intensidad;
		suma += rel * (float)fz;
		fuerza_total += fz;
	}
	return fuerza_total > 0.0 ? (suma / (float)fuerza_total) * (float)V_SPRINT : Vector2();
}

} // namespace

// `LeagueNucleo.situacion` → [espacio_adelante, espacio, adelante]
Array DinastiaNativo::league_situacion(const Vector2 &pos, const Vector2 &mov, double lado, const Array &rivales) const {
	double s[3];
	situacion(pos, mov, lado, leer_rivales(rivales), s);
	Array r;
	r.push_back(s[0]);
	r.push_back(s[1]);
	r.push_back(s[2]);
	return r;
}

// `LeagueNucleo.regate` → [dirección, velocidad]
Array DinastiaNativo::league_regate(const Vector2 &pos, const Vector2 &mov, const Vector2 &mirada, double lado, const Array &cercanos, double mente, double ofensivo, double iman) const {
	const double empuje = 0.55 + clampd(ofensivo, 0.0, 1.0) * 0.28 + clampd(mente, 0.0, 1.0) * 0.12;
	const double fondo = normalizado(std::fabs((double)pos.x) / MEDIO_LARGO, 0.0, 1.0);
	const double centro_inv = (1.0 - fondo * fondo) * 0.5;
	const Vector2 arco((float)(-lado * MEDIO_LARGO), (float)((double)pos.y * (1.0 - iman) * centro_inv));
	const double futuro = 0.25;
	std::vector<Fuerza> campo;
	campo.reserve(cercanos.size() + 3);
	for (int64_t i = 0; i < cercanos.size(); i++) {
		const Array r = cercanos[i];
		campo.push_back(Fuerza{ (Vector2)r[0] + (Vector2)r[1] * (float)futuro, true, false, 2.0, 10.0, 1.0 });
	}
	const double sy = pos.y >= 0.0f ? 1.0 : -1.0;
	const double sx = pos.x >= 0.0f ? 1.0 : -1.0;
	campo.push_back(Fuerza{ Vector2(pos.x, (float)((MEDIO_ANCHO + 5.0) * sy)), true, false, 4.0, 20.0, 0.7 });
	campo.push_back(Fuerza{ Vector2((float)((MEDIO_LARGO + 5.0) * sx), pos.y), true, false, 4.0, 20.0, 0.7 });
	campo.push_back(Fuerza{ arco, false, true, empuje, 1.0, 1.0 });
	const Vector2 m = campo_movimiento(campo, pos + mov * (float)futuro, 1.0);
	const Vector2 dir = (double)m.length() > 0.0 ? m.normalized() : mirada;
	Array r;
	r.push_back(dir);
	r.push_back(rango_velocidad(clampd((double)m.length() * DIST_A_VEL, 0.0, V_SPRINT)));
	return r;
}

// `LeagueNucleo.decidir`; `zona_tiro` = `LeagueNucleo.ZONA_TIRO`.
Dictionary DinastiaNativo::league_decidir(const Dictionary &yo, const Array &companeros, const Array &rivales_a, const Vector2 &mov_balon, double posesion, const Ref<RandomNumberGenerator> &azar,
		int64_t muestras, double zona_tiro) const {
	static const StringName k_mov("mov"), k_pos("pos"), k_lado("lado"), k_puesto("puesto"), k_tec_pase("tec_pase"), k_posee("posee_ms"), k_sit("sit"), k_tec_tiro("tec_tiro"), k_i("i");
	const std::vector<Riv> rivales = leer_rivales(rivales_a);
	const Vector2 mov = yo[k_mov];
	const Vector2 pos = yo[k_pos];
	const double lado = yo[k_lado];
	const String puesto_yo = yo[k_puesto];
	const double mente = mentalidad(puesto_yo);
	const double dif = normalizado((double)(mov_balon - mov).length(), 0.0, 10.0);
	const double toque_dificil = dif - (double)yo[k_tec_pase] * dif * 0.8;
	const double largo_posesion = std::pow(normalizado((double)yo[k_posee], 0.0, 5000.0), EXP_2);
	const double p_esp_adel = 0.4;
	const double p_esp = 0.3;
	const double p_adel = 2.0 + mente * 5.0;
	const double total1 = p_esp_adel + p_esp + p_adel;
	const double umbral_mejora = 0.06 * (1.0 - mente);
	const double p_dif = 1.0 + std::pow(mente, EXP_2) * 10.0;
	const double p_pase = 1.0;
	const double pase_min = 0.2 * (1.0 - mente) - largo_posesion * 0.1;
	const double total2 = p_dif + p_pase;
	const double umbral_pase = 0.12 - largo_posesion * 0.06;
	const Array sit = yo[k_sit];
	const double sit0 = sit[0], sit1 = sit[1], sit2 = sit[2];
	const double nota_yo = (sit0 * p_esp_adel + sit1 * p_esp + sit2 * p_adel) / total1;
	bool hay_mejor = false;
	double mejor_total = 0.0;
	Variant mejor_i;
	int64_t mejor_tipo = CORTO;
	double mejor_odds = 0.0;
	for (int64_t k = 0; k < companeros.size(); k++) {
		const Dictionary c = companeros[k];
		const Array cs = c[k_sit];
		const double cs0 = cs[0], cs1 = cs[1], cs2 = cs[2];
		double nota = (cs0 * p_esp_adel + cs1 * p_esp + cs2 * p_adel) / total1;
		if (String(c[k_puesto]) == "POR") {
			nota *= 0.7;
		}
		const bool progresa = nota > nota_yo + umbral_mejora;
		const bool apoyo = apoyo_pase(sit1, cs1, nota_yo, nota, largo_posesion);
		if (!(progresa || apoyo)) {
			continue;
		}
		const double bono = apoyo ? bono_apoyo(sit1, cs1, largo_posesion) : 0.0;
		const Vector2 cpos = c[k_pos];
		const Vector2 cmov = c[k_mov];
		const double oc = odds_pase_a(pos, mov, cpos, cmov, lado, CORTO, rivales);
		const double ol = odds_pase_a(pos, mov, cpos, cmov, lado, LARGO, rivales);
		const double oa = odds_pase_a(pos, mov, cpos, cmov, lado, ALTO, rivales);
		int64_t tipo = CORTO;
		double odds = oc;
		if (!(oc >= ol && oc >= oa)) {
			if (ol >= oa) {
				tipo = LARGO;
				odds = ol;
			} else {
				tipo = ALTO;
				odds = oa;
			}
		}
		const double total = (std::fmax(nota - nota_yo, 0.0) * p_dif + odds * p_pase + bono - toque_dificil) / total2;
		if (total > mejor_total && total > umbral_pase && odds > pase_min) {
			mejor_total = total;
			hay_mejor = true;
			mejor_i = c[k_i];
			mejor_tipo = tipo;
			mejor_odds = odds;
		}
	}
	Array cola;
	if (mente < 0.25) {
		const double propension = 1.0 - mente * 2.0;
		const double cerca_arco = 1.0 - normalizado((double)(pos - Vector2((float)(MEDIO_LARGO * lado), 0.0f)).length(), 2.0, 16.0);
		bool panico = false;
		if (puesto_yo != "POR") {
			panico = (!hay_mejor || mejor_odds < propension * cerca_arco) && posesion < 0.9 + propension * cerca_arco * 0.8;
		} else {
			panico = posesion < 3.0;
		}
		if (panico) {
			Dictionary d;
			d[String("accion")] = String("panico");
			cola.push_back(d);
		}
	}
	if (hay_mejor) {
		Dictionary d;
		d[String("accion")] = String("pase");
		d[String("i")] = mejor_i;
		d[String("tipo")] = mejor_tipo;
		d[String("odds")] = mejor_odds;
		cola.push_back(d);
	}
	const double dist_arco = normalizado((double)(Vector2((float)(MEDIO_LARGO * -lado), 0.0f) - pos).length(), 0.0, 32.0);
	const double ideal = curva(1.0 - normalizado((double)(Vector2((float)((MEDIO_LARGO - 7.0) * -lado), 0.0f) - pos).length(), 0.0, zona_tiro), 1.0);
	if (ideal > 0.1) {
		double mejor_y = 0.0;
		const Vector2 origen = pos + mov * (float)0.12;
		double odds_t = odds_pase(origen, Vector2((float)((MEDIO_LARGO + 1.0) * -lado), 0.0f), TIRO, rivales, 3.0);
		const double ys[2] = { -3.6, 3.6 };
		for (int j = 0; j < 2; j++) {
			const double y = ys[j];
			const double o = odds_pase(origen, Vector2((float)((MEDIO_LARGO + 1.0) * -lado), (float)y), TIRO, rivales, 3.0);
			if (o > odds_t) {
				odds_t = o;
				mejor_y = (y > 0.0 ? 1.0 : (y < 0.0 ? -1.0 : 0.0)) * 3.5;
			}
		}
		odds_t = std::sqrt(odds_t);
		const double muestras_d = (double)(muestras > 1 ? muestras : 1);
		if (odds_t + std::pow((double)azar->randf(), 1.0 / muestras_d) * 0.28 > 0.55) {
			const double tec = yo[k_tec_tiro];
			Dictionary d;
			d[String("accion")] = String("tiro");
			d[String("y")] = mejor_y + (double)azar->randf_range(-1.0 + tec, 1.0 - tec);
			d[String("potencia")] = (double)azar->randf_range(0.7 * (0.6 + dist_arco * 0.4), 1.0 * (0.6 + dist_arco * 0.4));
			cola.push_back(d);
		}
	}
	Dictionary r;
	if (!cola.is_empty()) {
		r = ((Dictionary)cola[0]).duplicate();
	} else {
		r[String("accion")] = String("conducir");
	}
	r[String("cola")] = cola;
	r[String("zona")] = ideal > 0.1;
	return r;
}
