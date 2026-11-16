// `MotorLeague._calcular_sin_balon` (visor/motor_league.gd, 16-11-2026, orden del dueño «50 % del tiempo de CPU en C++», opción B): la colocación sin balón de
// League de un jugador (estrategia del puesto, roles intercambiados, apoyo ofensivo, componente defensiva, trampa, velocidad perezosa y caza del portador) en UNA
// llamada. Lee el estado del motor y de sus `LeagueEquipo` con `get` y usa las piezas ya portadas (`league_destino_forma`, `league_apoyo`, `league_mas_cercanos`).
// Misma aritmética, operación por operación: Vector2/Vector3 en float de 32 bits, escalares en double. Devuelve [destino, velocidad], o [] si algún «más cercanos»
// tiene más de 16 candidatos (entonces sigue la gemela GDScript, `_calcular_sin_balon_gd`). Igualdad en `pruebas/probar_nativo_sin_balon.gd`.
// Comparar diccionarios (`a == b` en GDScript compara contenido) equivale aquí a comparar el id: dos jugadores distintos nunca tienen el mismo diccionario.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>

using namespace godot;

namespace {
constexpr double MEDIO_LARGO = 52.5;
constexpr double V_PARADO = 0.0;
constexpr double V_CONDUCE = 3.5;
constexpr double V_TROTE = 5.0;
constexpr double V_SPRINT = 8.0;
constexpr double CAMBIO_PARADO_CONDUCE = 1.8;
constexpr double CAMBIO_CONDUCE_TROTE = 4.4;
constexpr double CAMBIO_TROTE_SPRINT = 6.2;
constexpr double DIST_A_VEL = 2.6;
constexpr double DIFICULTAD = 0.8;

struct Estrategia {
	double dmin, dmax, mult, amin, amax, umbral_carrera, kdef;
	bool trampa;
};
constexpr Estrategia E_DEF{ 12.0, 18.0, 1.1, 0.2, 0.9, 0.7, 1.9, true };
constexpr Estrategia E_MED{ 15.0, 20.0, 0.9, 0.1, 0.7, 0.9, 1.5, true };
constexpr Estrategia E_ATA{ 15.0, 20.0, 0.8, 0.1, 0.6, 0.7, 1.3, false };

inline double clampd(double v, double lo, double hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}
inline double normalizado(double v, double a, double b) {
	return b != a ? clampd((v - a) / (b - a), 0.0, 1.0) : 0.0; // NOSONAR(cpp:S1244): copia exacta de `LeagueNucleo.normalizado`
}
inline double curva(double x, double sesgo) {
	return (std::sin((x - 0.5) * Math::PI) * 0.5 + 0.5) * sesgo + x * (1.0 - sesgo);
}
inline double rango_velocidad(double v) {
	if (v >= CAMBIO_PARADO_CONDUCE && v < CAMBIO_CONDUCE_TROTE) {
		return V_CONDUCE;
	}
	if (v >= CAMBIO_CONDUCE_TROTE && v < CAMBIO_TROTE_SPRINT) {
		return V_TROTE;
	}
	if (v >= CAMBIO_TROTE_SPRINT) {
		return V_SPRINT;
	}
	return V_PARADO;
}
// `MotorJugable._rol`.
String rol(const Dictionary &p) {
	static const StringName k_slot("slot_code");
	const String s = p.get(k_slot, "");
	if (s == "DC" || s == "SD" || s == "DEL") {
		return "DC";
	}
	if (s == "ED" || s == "MD") {
		return "ED";
	}
	if (s == "EI" || s == "MI") {
		return "EI";
	}
	if (s == "MC" || s == "MCO" || s == "MCD") {
		return "MC";
	}
	if (s == "LD" || s == "CAD") {
		return "LD";
	}
	if (s == "LI" || s == "CAI") {
		return "LI";
	}
	return s; // "DFC" y el resto, tal cual
}
const Estrategia &grupo(const String &puesto) {
	if (puesto == "DFC" || puesto == "LD" || puesto == "LI" || puesto == "CAD" || puesto == "CAI") {
		return E_DEF;
	}
	return puesto == "DC" ? E_ATA : E_MED;
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
inline Vector2 ls(const Vector3 &v) {
	return Vector2(v.z, v.x);
}
Vector3 pos(const Dictionary &p) {
	static const StringName k_node("node");
	const Node3D *n = Object::cast_to<Node3D>(static_cast<Object *>(p.get(k_node, Variant())));
	return n != nullptr ? n->get_position() : Vector3();
}
Vector2 vel_ls(const Dictionary &p) {
	static const StringName k_vel("vel");
	return ls(Vector3(p[k_vel]));
}
inline bool mismo(const Dictionary &a, const Dictionary &b) {
	static const StringName k_id("id");
	return !a.is_empty() && !b.is_empty() && a.get(k_id, Variant()) == b.get(k_id, Variant());
}
int64_t tac(const Array &tacticas, bool local, const char *k) {
	const Dictionary tc = tacticas[local ? 0 : 1];
	return int64_t(tc.get(k, 1));
}
// `LeagueSinBalon.componente_defensiva`.
Vector2 componente_defensiva(const Vector2 &deseada, double sesgo, const Vector2 &rival_pos, bool rival_es_portador, double lado, double trampa_x, const Vector2 &mi_pos) {
	const double umbral = rival_es_portador ? 24.0 : 8.0;
	const Vector2 arco = Vector2(MEDIO_LARGO * lado, 0.0);
	const double d_arco = (arco - rival_pos).length();
	double hasta = clampd(d_arco - umbral, 0.4, MEDIO_LARGO);
	Vector2 punto = rival_pos + (arco - rival_pos).normalized() * hasta;
	if (double(punto.x) * lado > trampa_x * lado) {
		const double dx = double(arco.x) - double(rival_pos.x);
		if (std::fabs(dx) > 0.0001) {
			const double u = (trampa_x - double(rival_pos.x)) / dx;
			punto = rival_pos + (arco - rival_pos) * u;
			hasta = (punto - rival_pos).length();
		}
	}
	Vector2 defensa = deseada;
	const Vector2 a_punto = punto - deseada;
	const double holgura = double(a_punto.length()) - (hasta - 4.0);
	if (holgura > 0.0) {
		defensa = deseada + a_punto.normalized() * clampd(holgura, 0.0, a_punto.length());
	}
	const double holgura_real = double((punto - mi_pos).length()) - hasta;
	if (holgura_real > 0.0) {
		defensa += (arco - defensa).normalized() * holgura_real * 0.7;
	}
	return deseada * (1.0 - sesgo) + defensa * sesgo;
}
// `LeagueSinBalon.posicion_defensa` (distancia = 0).
Vector2 posicion_defensa(const Vector2 &rival_pos, const Vector2 &rival_mov, const Vector2 &mi_pos, double lado) {
	const Vector2 arco = Vector2(MEDIO_LARGO * lado, 0.0);
	const Vector2 al_arco = arco - rival_pos;
	const Vector2 medio = (mi_pos + rival_pos) * 0.5;
	const Vector2 perp = (mi_pos - medio).rotated(Math::PI * 0.5);
	const double den = double(al_arco.x) * double(perp.y) - double(al_arco.y) * double(perp.x);
	double u = 0.0;
	if (std::fabs(den) > 0.0001) {
		const Vector2 w = medio - rival_pos;
		u = (double(w.x) * double(perp.y) - double(w.y) * double(perp.x)) / den;
	}
	u = clampd(u, 0.0, 1.0);
	const Vector2 objetivo = rival_pos + al_arco * u;
	return objetivo + al_arco.normalized() * V_SPRINT * 0.1 + rival_mov * 0.14 + al_arco.normalized() * 0.0;
}
bool necesita_defender(double lado, const Vector2 &p, const Vector2 &objetivo) {
	const double hondo = std::fmax((double(objetivo.x) - double(p.x)) * -lado, 0.0) - 0.5;
	return std::fabs(double(objetivo.y) - double(p.y)) > hondo * 0.8;
}
double velocidad_perezosa(double v, double fresco, double dist_accion, double posesion_desv, double mente, double vel_media, double trabajo) {
	double a = v;
	if (a > V_SPRINT) {
		a = V_SPRINT + (a - V_SPRINT) * 0.1;
	}
	const double inicio = 18.0 * (fresco * 0.8 + 0.2);
	const double fin = 55.0 * (fresco * 0.5 + 0.5);
	const double pos_eq = clampd(posesion_desv - 0.5, 0.0, 1.0);
	const double por_rol = mente + pos_eq * (1.0 - mente * 2.0);
	const double pereza = normalizado(dist_accion, inicio, fin) * (0.5 + por_rol * 0.5);
	double r = a * (1.0 - pereza);
	if (v >= V_CONDUCE && r < V_CONDUCE) {
		r = V_CONDUCE;
	}
	double aire = std::pow(1.0 - normalizado(vel_media, V_PARADO, V_SPRINT), 0.8 - trabajo * 0.2);
	aire = clampd(aire * 1.2, 0.0, 1.0);
	aire = aire * pereza + 1.0 * (1.0 - pereza);
	return std::fmin(r, V_SPRINT * aire);
}
double umbral_caza(double mente, double fresco, double vel_media, double dificultad) {
	double u = 10.0 + (1.0 - mente) * 10.0;
	u *= 0.5 * fresco + 0.5 * (1.0 - normalizado(vel_media, V_PARADO, V_SPRINT));
	return u * (0.3 + dificultad * 0.7);
}
double trampa_offside(double x, double lado, double trampa_x) {
	const double media = 2.0;
	const double ax = x * lado;
	const double at = trampa_x * lado;
	if (ax > at - media) {
		const double frente = at - media;
		const double fac = clampd((ax - frente) / (media * 2.0), 0.0, 1.0);
		return (frente + media * fac) * lado;
	}
	return x;
}
} // namespace

// `MotorLeague._destino_forma`.
Vector2 DinastiaNativo::sb_destino_forma(Object *m, const Array &equipos, const Dictionary &p, const Vector2 &forma, const String &puesto, const Dictionary &mezcla) const {
	static const StringName k_local("es_local"), k_poseedor("poseedor"), k_ultimo("ultimo_toque"), k_balon("balon"), k_tacticas("tacticas"), k_lado_medio("_lado_medio"),
			k_ofens("ofensividad"), k_acum("acum"), k_lado("lado"), k_desv("posesion_desvanecida"), k_trampa("trampa_x");
	const bool local = bool(p[k_local]);
	Object *e = equipos[local ? 0 : 1];
	Object *e0 = equipos[0];
	const Dictionary poseedor = m->get(k_poseedor);
	const Dictionary foco_p = !poseedor.is_empty() ? poseedor : Dictionary(m->get(k_ultimo));
	Vector2 foco;
	if (!foco_p.is_empty()) {
		foco = ls(pos(foco_p));
	} else {
		const Node3D *b = Object::cast_to<Node3D>(static_cast<Object *>(m->get(k_balon)));
		foco = ls(b != nullptr ? b->get_position() : Vector3());
	}
	const Vector2 yo = ls(pos(p));
	const Array tacticas = m->get(k_tacticas);
	const double ofens = clampd(double(e->get(k_ofens)) + double(tac(tacticas, local, "mentalidad") - 1) * 0.15, 0.0, 1.0);
	const double lado = e->get(k_lado);
	Vector2 r = league_destino_forma(e0->get(k_acum), foco, yo, forma, puesto, lado, e->get(k_desv), ofens, m->get(k_lado_medio), e->get(k_trampa), mezcla);
	r.x = real_t(double(r.x) + -lado * double(tac(tacticas, local, "linea") - 1) * 4.0);
	return r;
}

Array DinastiaNativo::league_calcular_sin_balon(Object *m, const Dictionary &p, const Dictionary &reparto, bool designado_disputa) const {
	static const StringName k_local("es_local"), k_id("id"), k_equipos("equipos"), k_jugadores("jugadores"), k_poseedor("poseedor"), k_ultimo("ultimo_toque"),
			k_designado("_ls_designado"), k_por_id("_ls_por_id"), k_forma("ls_forma"), k_corredor("_ls_corredor"), k_corre_hasta("_ls_corre_hasta"),
			k_adelantado("_ls_adelantado"), k_pred("_ls_pred"), k_linea_rival("_ls_linea_rival"), k_marca("_ls_marca"), k_presiona("_ls_presiona"),
			k_presion_hasta("_ls_presion_hasta"), k_desig_eq("_ls_desig_eq"), k_t("t"), k_tacticas("tacticas"), k_lado("lado"), k_desv("posesion_desvanecida"),
			k_trampa("trampa_x"), k_aguante("aguante"), k_attr("attr"), k_fis("fis"), k_vel("vel");
	const bool local = bool(p[k_local]);
	const int i = local ? 0 : 1;
	const Array equipos = m->get(k_equipos);
	Object *e = equipos[i];
	const double lado = e->get(k_lado);
	const double desv = e->get(k_desv);
	const double trampa_x = e->get(k_trampa);
	const double t = m->get(k_t);
	const Array jugadores = m->get(k_jugadores);
	const Dictionary poseedor = m->get(k_poseedor);
	const Dictionary por_id = m->get(k_por_id);
	const Vector2 yo = ls(pos(p));
	const Vector2 mov = vel_ls(p);
	const String puesto = rol(p);
	const Estrategia &g = grupo(puesto);
	const double mente = mentalidad(puesto);
	const Dictionary designado = m->get(k_designado);
	const Dictionary desig = !designado.is_empty() ? designado : p;
	const double dist_accion = (yo - ls(pos(desig))).length();
	const Dictionary mezcla = e->call("mezcla_de", puesto);
	// Estática (su casilla) y dinámica (la del dueño de su rol).
	const Vector2 estatica = sb_destino_forma(m, equipos, p, p[k_forma], puesto, mezcla);
	const String id_p = p[k_id];
	const Dictionary dueno = por_id.get(String(reparto.get(id_p, p[k_id])), p);
	const Vector2 dinamica = (mismo(dueno, p) || !dueno.has(k_forma)) ? estatica : sb_destino_forma(m, equipos, p, dueno[k_forma], puesto, mezcla);
	const double sb = curva(g.mult * normalizado(dist_accion, g.dmin, g.dmax), 1.0);
	Vector2 deseada = estatica * sb + dinamica * (1.0 - sb);
	// Apoyo ofensivo (`LeagueSinBalon.sesgo_ataque`).
	double ab = normalizado(desv - 0.5, g.amin, g.amax);
	if (&g == &E_DEF) {
		ab *= std::fmin(0.72 + clampd(mente, 0.0, 1.0) * 0.52, 1.0);
	}
	const bool hay_pos = !poseedor.is_empty();
	const bool pos_mio = hay_pos && bool(poseedor[k_local]) == local;
	const Dictionary pred = m->get(k_pred);
	if (ab > 0.0 && pos_mio) {
		const Array corredor = m->get(k_corredor);
		const Array corre_hasta = m->get(k_corre_hasta);
		const Array adelantado = m->get(k_adelantado);
		const bool corre = ab > g.umbral_carrera && mismo(corredor[i], p) && t < double(corre_hasta[i]);
		const Vector2 principal = ls(pos(poseedor)) + vel_ls(poseedor) * 0.1;
		const PackedInt32Array kr = league_mas_cercanos(jugadores, principal * 0.3 + (yo + mov * 0.1) * 0.7, !local, 3, PackedStringArray());
		PackedStringArray excl;
		excl.push_back(id_p);
		const PackedInt32Array kc = league_mas_cercanos(jugadores, yo + mov * 0.1, local, 5, excl);
		if ((kr.size() == 1 && kr[0] == -2) || (kc.size() == 1 && kc[0] == -2)) {
			return Array();
		}
		Array rivales;
		for (int64_t k = 0; k < kr.size(); k++) {
			const Dictionary q = jugadores[kr[k]];
			Array par;
			par.push_back(ls(pos(q)));
			par.push_back(vel_ls(q));
			rivales.push_back(par);
		}
		Array mates;
		for (int64_t k = 0; k < kc.size(); k++) {
			const Dictionary q = jugadores[kc[k]];
			Array par;
			par.push_back(ls(pos(q)));
			par.push_back(vel_ls(q));
			mates.push_back(par);
		}
		const Array tacticas = m->get(k_tacticas);
		const double red = 0.68 + clampd(0.5 + double(tac(tacticas, local, "amplitud") - 1) * 0.25, 0.0, 1.0) * 0.20;
		Array bp;
		bp.push_back(pred[200]);
		bp.push_back(pred[350]);
		bp.push_back(pred[500]);
		bp.push_back(pred[650]);
		const Array linea_rival = m->get(k_linea_rival);
		Dictionary ea;
		ea["base"] = deseada;
		ea["pos"] = yo;
		ea["mov"] = mov;
		ea["lado"] = lado;
		ea["mente"] = mente;
		ea["puesto"] = puesto;
		ea["correr"] = corre;
		ea["adelantado"] = mismo(adelantado[i], p);
		ea["principal"] = principal;
		ea["es_principal"] = mismo(poseedor, p);
		ea["rivales"] = rivales;
		ea["companeros"] = mates;
		ea["posesion_desv"] = desv;
		ea["balon_pred"] = bp;
		ea["linea_offside"] = linea_rival[i];
		ea["red"] = red;
		const Vector2 apoyo = league_apoyo(ea);
		deseada = deseada * (1.0 - ab) + apoyo * ab;
	}
	// Componente defensiva sobre su marca y trampa del fuera de juego.
	const Array marcas = m->get(k_marca);
	const Dictionary marca = por_id.get(String(Dictionary(marcas[i]).get(id_p, "")), Dictionary());
	if (!marca.is_empty()) {
		const Vector2 rp = ls(pos(marca)) + vel_ls(marca) * 0.5;
		const double sd = std::pow(clampd(g.kdef - mente - desv, 0.0, 1.0), 0.7);
		deseada = componente_defensiva(deseada, sd, rp, mismo(marca, poseedor), lado, trampa_x, yo + mov * 0.14);
	}
	if (g.trampa) {
		deseada.x = real_t(trampa_offside(deseada.x, lado, trampa_x));
	}
	const double fresco = clampd(double(p.get(k_aguante, 1.0)), 0.0, 1.0);
	const double vmed = mov.length();
	const double trabajo = clampd(double(Dictionary(p[k_attr]).get(k_fis, 0.5)), 0.0, 1.0);
	const bool hay_rival_con = hay_pos && bool(poseedor[k_local]) != local;
	const Vector2 accion_r = hay_rival_con ? ls(pos(poseedor)) : Vector2(pred[200]);
	const double v = velocidad_perezosa(double((deseada - yo).length()) * DIST_A_VEL, fresco, (yo - accion_r).length(), desv, mente, vmed, trabajo);
	// Caza (solo sin la mejor posesión).
	int equipo_con_balon = -1;
	if (hay_pos) {
		equipo_con_balon = bool(poseedor[k_local]) ? 0 : 1;
	} else {
		const Dictionary ut = m->get(k_ultimo);
		if (!ut.is_empty()) {
			equipo_con_balon = bool(ut[k_local]) ? 0 : 1;
		}
	}
	Array r;
	if (equipo_con_balon != i && hay_rival_con) {
		const Vector2 rv = vel_ls(poseedor);
		const Vector2 op = ls(pos(poseedor)) + rv * 0.12;
		const Array presiona = m->get(k_presiona);
		const Array presion_hasta = m->get(k_presion_hasta);
		if (mismo(presiona[i], p) && double(presion_hasta[i]) > t) {
			r.push_back(op);
			r.push_back(V_SPRINT);
			return r;
		}
		const bool cerca_caza = double((op - (yo + mov * 0.04)).length()) < umbral_caza(mente, fresco, vmed, DIFICULTAD);
		const Array desig_eq = m->get(k_desig_eq);
		if (designado_disputa && cerca_caza && mismo(desig_eq[i], p)) {
			r.push_back(op);
			r.push_back(V_SPRINT);
			return r;
		}
		if (marca.is_empty() && cerca_caza) {
			const PackedInt32Array kk = league_mas_cercanos(jugadores, op - rv * 0.02, local, 3, PackedStringArray());
			if (kk.size() == 1 && kk[0] == -2) {
				return Array();
			}
			bool esta = false;
			for (int64_t k = 0; k < kk.size(); k++) {
				if (mismo(jugadores[kk[k]], p)) {
					esta = true;
					break;
				}
			}
			if (esta) {
				const Vector2 dp = posicion_defensa(ls(pos(poseedor)), rv, yo, lado);
				if (necesita_defender(lado, yo, dp)) {
					r.push_back(dp);
					r.push_back(clampd(double((dp - yo).length()) * DIST_A_VEL, 0.0, V_SPRINT));
					return r;
				}
			}
		}
	}
	r.push_back(deseada);
	r.push_back(rango_velocidad(clampd(v, 0.0, V_SPRINT)));
	return r;
}
