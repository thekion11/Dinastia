// LA COLOCACIÓN Y EL HISTORIAL DE LEAGUE, EN C++ (16-11-2026, paso a C++). Traducción LITERAL de `LeagueNucleo.posicion_formacion` y `formacion_adaptada`
// (visor/league_nucleo.gd), de `LeagueEquipo.acumular` y `LeagueEquipo.media_f` (visor/league_equipo.gd): Vector2 en 32 bits y el resto en double, como GDScript, en el
// mismo orden de operaciones. Las gemelas GDScript se quedan de respaldo; `pruebas/probar_nativo.tscn` comprueba que dan los mismos bytes.
#include "dinastia_nativo.h"

#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include <cmath>
#include <vector>

using namespace godot;

namespace {

const double MEDIO_LARGO = 52.5;
const double MEDIO_ANCHO = 34.0;
const double PROFUNDIDAD = 0.45;
const double ANCHURA = 0.95;

double clampd(double v, double lo, double hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}

// `LeagueNucleo.normalizado`
double normalizado(double v, double a, double b) {
	return b != a ? clampd((v - a) / (b - a), 0.0, 1.0) : 0.0;
}

// `LeagueNucleo.curva`
double curva(double x, double sesgo) {
	return (std::sin((x - 0.5) * Math::PI) * 0.5 + 0.5) * sesgo + x * (1.0 - sesgo);
}

// `LeagueNucleo.mentalidad`
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

// `LeagueNucleo.formacion_adaptada`
Vector2 formacion_adaptada(Vector2 forma, double lado, double atras, double delante, double bajo, double alto, double y_foco, double y_fuerza, const Vector2 &micro, double micro_f, double mf, double mfs) {
	Vector2 p = forma;
	if (mfs > 0.0) {
		const double sesgo = curva(clampd(1.0 - std::fabs((double)p.x * 1.2), 0.0, 1.0), 1.0) * mfs;
		p.x = (float)((double)p.x * (1.0 - sesgo) + (mf * 2.0 - 1.0) * sesgo);
	}
	p.x = (float)(atras + ((double)p.x * 0.5 + 0.5) * (delante - atras));
	p.y = (float)(bajo + ((double)p.y * -lado * 0.5 + 0.5) * (alto - bajo));
	const Vector2 pura = p;
	if (y_fuerza > 0.0) {
		const double b = (1.0 - clampd(std::fabs(y_foco - (double)p.y) / std::fabs(alto - bajo), 0.0, 1.0)) * (0.2 + 0.8 * std::fabs(y_foco) / MEDIO_ANCHO) * y_fuerza;
		p.y = (float)((double)p.y * (1.0 - b) + y_foco * b);
	}
	if (micro_f > 0.0) {
		const double dist = (double)((micro - pura) * Vector2(1.0f, 0.8f)).length() / 50.0;
		if (dist < 1.0) {
			double mb = curva(1.0 - dist, 0.3);
			mb += (1.0 - normalizado(std::fabs(dist - 0.15), 0.0, 0.25)) * 0.1;
			mb = clampd(mb, 0.0, 1.0) * micro_f;
			const Vector2 mp((float)micro.x, (float)((double)micro.y * 0.6 + (double)p.y * 0.4));
			p = p * (float)(1.0 - mb) + mp * (float)mb;
		}
	}
	return p;
}

} // namespace

// `LeagueNucleo.posicion_formacion(e)`; `e` TIENE que traer «mezcla» (el único llamador, `MotorLeague._destino_forma`, siempre la trae).
Vector2 DinastiaNativo::league_posicion_formacion(const Dictionary &e) const {
	static const StringName k_puesto("puesto"), k_lado("lado"), k_of("ofensividad"), k_mezcla("mezcla"), k_bx("balon_x_lento"), k_by("balon_y_lento"), k_foco("foco"), k_pd("posesion_desvanecida"),
			k_b3("balon_3s"), k_b2("balon_2s"), k_lpm("lado_posesion_medio"), k_trampa("trampa_x"), k_forma("forma");
	static const StringName k_os("os"), k_ds("ds"), k_od("od"), k_dd("dd"), k_ow("ow"), k_dw("dw"), k_oh("oh"), k_dh("dh"), k_omi("omi"), k_dmi("dmi"), k_om("om"), k_dm("dm"), k_oms("oms"), k_dms("dms");
	const String puesto = e[k_puesto];
	const double lado = e[k_lado];
	const double mente = mentalidad(puesto);
	const double of = e[k_of];
	const Dictionary f = e[k_mezcla];
	const double os = clampd((double)f[k_os] + (-0.5 + mente) * 0.2 - 0.3 + of * 0.3, 0.0, 1.0);
	const double ds = clampd((double)f[k_ds] + (0.5 - mente) * 0.2 - 0.3 + (1.0 - of) * 0.3, 0.0, 1.0);
	const double bx = e[k_bx];
	const double by = e[k_by];
	Vector2 foco = e[k_foco];
	const double b_pos = normalizado((double)e[k_pd] - 0.5, 0.3, 0.7);
	const double b_balon = normalizado((bx / MEDIO_LARGO) * -lado, -0.7, 0.7);
	const double bb = (1.0 - std::fabs(b_pos * 2.0 - 1.0)) * 0.6;
	const double pb = clampd(b_pos * (1.0 - bb) + b_balon * bb + (of - 0.5) * 0.3, 0.0, 1.0);
	const Vector2 b3 = e[k_b3];
	const Vector2 b2 = e[k_b2];
	foco = b3 * (float)pb + (b2 * 0.5f + foco * 0.5f) * (float)(1.0 - pb);
	const double prof = PROFUNDIDAD * ((double)f[k_od] * pb + (double)f[k_dd] * (1.0 - pb));
	const double anch = ANCHURA * ((double)f[k_ow] * pb + (double)f[k_dw] * (1.0 - pb));
	const double off_x = MEDIO_LARGO * lado * (((double)f[k_oh] * 2.0 - 1.0) * pb + ((double)f[k_dh] * 2.0 - 1.0) * (1.0 - pb));
	const double side_f = os * pb + ds * (1.0 - pb);
	const double sf = pb * 2.0 - 1.0;
	const double side_x = 0.2 * sf * -lado * MEDIO_LARGO + 0.8 * -(double)e[k_lpm] * MEDIO_LARGO;
	double cx = clampd(bx * (1.0 - side_f) + side_x * side_f + off_x, -MEDIO_LARGO, MEDIO_LARGO);
	double cy = clampd(by, -MEDIO_ANCHO, MEDIO_ANCHO);
	cx *= (1.0 - prof) * 0.95 + 0.05;
	cy *= (1.0 - anch) * 0.9 + 0.1;
	double atras = cx - prof * MEDIO_LARGO * -lado;
	const double delante = cx + prof * MEDIO_LARGO * -lado;
	const double bajo = cy - anch * MEDIO_ANCHO;
	const double alto = cy + anch * MEDIO_ANCHO;
	const double trampa = e[k_trampa];
	if (atras * lado > trampa * lado) {
		atras = trampa;
	}
	const double y_fuerza = 0.5 * pb + 0.2 * (1.0 - pb);
	double dfx = (double)foco.x + lado * 2.0;
	if (dfx * lado > atras * lado) {
		dfx = atras;
	}
	const Vector2 defensivo((float)clampd(dfx, -MEDIO_LARGO, MEDIO_LARGO), (float)((double)foco.y * 0.9));
	const Vector2 micro = Vector2((float)clampd((double)foco.x - lado * 1.0, -MEDIO_LARGO, MEDIO_LARGO), (float)((double)foco.y * 0.9)) * (float)pb + defensivo * (float)(1.0 - pb);
	double micro_f = (double)f[k_omi] * pb + (double)f[k_dmi] * (1.0 - pb);
	const double msb = normalizado((bx / MEDIO_LARGO) * -lado, -0.7, 0.7) * 0.7 + 0.3;
	micro_f *= 0.2 + 0.8 * (std::pow(msb, 0.8) * pb + std::pow(1.0 - msb, 0.6) * (1.0 - pb));
	const double mf = ((double)f[k_om] * pb + (double)f[k_dm] * (1.0 - pb)) * 0.7 + normalizado((bx / MEDIO_LARGO) * -lado, -0.8, 0.8) * 0.3;
	const double mfs = (double)f[k_oms] * pb + (double)f[k_dms] * (1.0 - pb);
	const Vector2 forma = e[k_forma];
	const Vector2 r = formacion_adaptada(forma, lado, atras, delante, bajo, alto, by, y_fuerza, micro, micro_f, mf, mfs);
	return Vector2((float)clampd((double)r.x, -MEDIO_LARGO, MEDIO_LARGO), (float)clampd((double)r.y, -MEDIO_ANCHO, MEDIO_ANCHO));
}

// `LeagueEquipo.acumular`: las sumas acumuladas del historial del balón (n + 1 entradas).
PackedVector2Array DinastiaNativo::league_acumular(const PackedVector2Array &hist) const {
	const int64_t n = hist.size();
	PackedVector2Array acum;
	acum.resize(n + 1);
	Vector2 s;
	acum[0] = s;
	for (int64_t i = 0; i < n; i++) {
		s += hist[i];
		acum[i + 1] = s;
	}
	return acum;
}

// `LeagueEquipo.media_f`: la media de los últimos `ms` / 10 valores (en double, como `var s := 0.0`).
double DinastiaNativo::league_media_f(const PackedFloat32Array &hist, double ms) const {
	const int64_t tam = hist.size();
	int64_t quiero = (int64_t)(ms / 10.0);
	if (quiero < 1) {
		quiero = 1;
	}
	const int64_t n = tam < quiero ? tam : quiero;
	if (n == 0) {
		return 0.0;
	}
	double s = 0.0;
	for (int64_t i = 0; i < n; i++) {
		s += (double)hist[tam - 1 - i];
	}
	return s / (double)n;
}

// ---------------------------------------------------------------------------------------------------------------------------
// El apoyo ofensivo sin balón (`LeagueSinBalon.apoyo`) y su campo de fuerzas (`LeagueNucleo.movimiento_campo`). 16-11-2026.
namespace {

const double V_SPRINT = 8.0;

struct Fuerza {
	Vector2 o;
	bool repele;
	bool constante;
	double potencia;
	double escala;
	double exp;
};

// `LeagueNucleo.movimiento_campo`
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

Vector2 DinastiaNativo::league_movimiento_campo(const Array &campo, const Vector2 &actual, double amortigua) const {
	std::vector<Fuerza> v;
	v.reserve(campo.size());
	for (int64_t i = 0; i < campo.size(); i++) {
		const Array f = campo[i];
		v.push_back(Fuerza{ f[0], (bool)f[1], (bool)f[2], (double)f[3], (double)f[4], (double)f[5] });
	}
	return campo_movimiento(v, actual, amortigua);
}

// `LeagueSinBalon.apoyo(e)`: `e` = {base, pos, mov, lado, mente, puesto, correr, adelantado, principal, es_principal, rivales [[pos, mov]], companeros [[pos, mov]], posesion_desv, balon_pred [Vector2 x4], linea_offside, red}.
Vector2 DinastiaNativo::league_apoyo(const Dictionary &e) const {
	static const StringName k_lado("lado"), k_pos("pos"), k_mov("mov"), k_principal("principal"), k_mente("mente"), k_red("red"), k_puesto("puesto"), k_base("base"), k_adelantado("adelantado"),
			k_correr("correr"), k_rivales("rivales"), k_pd("posesion_desv"), k_companeros("companeros"), k_es_principal("es_principal"), k_balon_pred("balon_pred"), k_linea("linea_offside");
	const double lado = e[k_lado];
	const Vector2 actual = (Vector2)e[k_pos] + (Vector2)e[k_mov] * 0.1f;
	const Vector2 principal = e[k_principal];
	const double mente = e[k_mente];
	const double red = e[k_red];
	double peso_rival = 0.3;
	const String puesto = e[k_puesto];
	if (puesto == "DFC" || puesto == "LD" || puesto == "LI") {
		peso_rival *= 2.2;
	} else if (puesto == "MCD") {
		peso_rival *= 2.0;
	} else if (puesto == "MC" || puesto == "MD" || puesto == "MI") {
		peso_rival *= 1.6;
	} else if (puesto == "MCO" || puesto == "MP" || puesto == "ED" || puesto == "EI") {
		peso_rival *= 1.2;
	}
	std::vector<Fuerza> campo;
	Vector2 o = e[k_base];
	if ((bool)e[k_adelantado]) {
		o.x = (float)((double)o.x + -lado * (0.3 + 0.7 * mente) * 12.0);
	} else {
		const double carril = ((double)principal.y >= 0.0 ? -1.0 : 1.0) * 8.0;
		const double cant = 22.0 * curva(1.0 - normalizado(std::fabs(carril - (double)actual.y), 0.0, 30.0), 1.0);
		o.x = (float)((double)o.x + -lado * std::pow(mente, 1.5) * cant);
	}
	campo.push_back(Fuerza{ o, false, true, 0.7 * (0.3 + 0.7 * normalizado((double)(o - actual).length(), 0.0, 20.0)), 1.0, 1.0 });
	const bool corre = (bool)e[k_correr];
	if (corre) {
		campo.push_back(Fuerza{ Vector2((float)(-lado * MEDIO_LARGO), (float)((double)actual.y * 0.5)), false, true, 2.0, 1.0, 1.0 });
	}
	const Array rivales = e[k_rivales];
	for (int64_t i = 0; i < rivales.size(); i++) {
		const Array r = rivales[i];
		const Vector2 rp = (Vector2)r[0] + (Vector2)r[1] * 0.1f;
		const Vector2 detras = rp != principal ? rp + (rp - principal).normalized() * 2.0f : rp;
		campo.push_back(Fuerza{ detras, true, false, peso_rival * (corre ? 0.5 : 1.0), corre ? 2.0 : 5.0, 0.7 });
	}
	const double pd = e[k_pd];
	if (pd >= 1.02) {
		const Array companeros = e[k_companeros];
		for (int64_t i = 0; i < companeros.size(); i++) {
			const Array c = companeros[i];
			campo.push_back(Fuerza{ (Vector2)c[0] + (Vector2)c[1] * 0.1f, true, false, 0.4, 14.0 * red, 1.0 });
		}
	}
	const bool es_p = e[k_es_principal];
	if (!es_p && pd >= 1.06) {
		const Array bps = e[k_balon_pred];
		for (int64_t i = 0; i < bps.size(); i++) {
			campo.push_back(Fuerza{ (Vector2)bps[i], true, false, 1.0, 2.0, 0.5 });
		}
	}
	if (!es_p) {
		campo.push_back(Fuerza{ principal, false, false, 0.45, 28.0 * red, 1.0 });
		campo.push_back(Fuerza{ principal, true, false, 0.45, 16.0 * red, 1.0 });
	}
	Vector2 r2 = actual + campo_movimiento(campo, actual, 7.0);
	const double linea = e[k_linea];
	const double margen = 0.08;
	if ((double)r2.x * -lado > linea * -lado - margen) {
		r2.x = (float)(linea - margen * -lado);
	}
	return Vector2((float)clampd((double)r2.x, -MEDIO_LARGO, MEDIO_LARGO), (float)clampd((double)r2.y, -MEDIO_ANCHO, MEDIO_ANCHO));
}
