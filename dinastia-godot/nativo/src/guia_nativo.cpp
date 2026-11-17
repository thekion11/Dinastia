// `LeagueGuia._paso_gd` (visor/league_guia.gd, 16-11-2026, orden del dueño «50 % del tiempo de CPU en C++»): la guía de los clips de arranque, frenada
// y giro sobre la velocidad de los jugadores, y las marchas. Va en dos pasadas: `guia_pendientes` dice quién tiene que DECIDIR un clip (lo hace
// GDScript con el catálogo de clips, `LeagueGuia.decidir`) y `guia_seguir` aplica la guía o la marcha a todos. Es equivalente al bucle único de
// GDScript porque decidir, seguir y la marcha de un jugador solo leen y escriben su propio diccionario. Misma aritmética, operación por operación:
// los Vector3 y Vector2 en float de 32 bits y los escalares en double, igual que allí. `guía de clips` en `pruebas/probar_nativo_guia.gd`.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/animation_player.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>

using namespace godot;

namespace {
struct Claves {
	StringName node{ "node" }, levantar_en{ "levantar_en" }, levanta_hasta{ "levanta_hasta" }, gesto_hasta{ "gesto_hasta" }, por{ "por" }, ls_guia{ "ls_guia" },
			ls_espera_g{ "ls_espera_g" }, mirar_hasta{ "mirar_hasta" }, vel{ "vel" }, hasta{ "hasta" }, t0{ "t0" }, dur{ "dur" }, sp0{ "sp0" }, fin{ "fin" }, h0{ "h0" },
			ang{ "ang" }, ls_humano{ "ls_humano" }, objetivo{ "objetivo" }, ls_trans_hasta{ "ls_trans_hasta" }, ls_fin_yaw{ "ls_fin_yaw" }, ls_off_extra{ "ls_off_extra" },
			ls_cuerpo{ "ls_cuerpo" }, anim_actual{ "anim_actual" };
	// Para ESCRIBIR se usan claves String, como GDScript: una clave nueva puesta con StringName quedaría como &"…" en el diccionario (otro tipo
	// de clave al guardar y al comparar con `var_to_bytes`), aunque se lea igual.
	String w_vel{ "vel" }, w_ls_trans_hasta{ "ls_trans_hasta" }, w_ls_espera_g{ "ls_espera_g" }, w_ls_off_extra{ "ls_off_extra" }, w_ls_cuerpo{ "ls_cuerpo" },
			w_anim_actual{ "anim_actual" };
};
const Claves &claves() {
	static const Claves c;
	return c;
}

// Constantes de `LeagueGuia` y `LeagueMovimiento` (mismas cifras).
constexpr double K_CPU = 11.0;
constexpr double K_USUARIO = 5.0;
constexpr double CORTE_USUARIO = 0.5;
constexpr double CORTE_CPU = 2.0;
constexpr double PAUSA_CORTE = 0.5;
constexpr double MARCHA_DRIBBLE = 3.5;
constexpr double MARCHA_WALK = 5.0;
constexpr double TOLERANCIA = 1.08;
constexpr double IDLE_DRIBBLE = 1.8;
constexpr double DRIBBLE_WALK = 4.4;
constexpr double WALK_SPRINT = 6.2;

inline double suave(double u) {
	u = u < 0.0 ? 0.0 : (u > 1.0 ? 1.0 : u);
	return u * u * (3.0 - 2.0 * u);
}

// El nodo del jugador si cuenta para la guía este paso; null si se salta (nodo liberado, en el suelo o levantándose).
Node3D *nodo_si_cuenta(const Dictionary &p, double t) {
	const Claves &c = claves();
	Node3D *n = Object::cast_to<Node3D>(static_cast<Object *>(p.get(c.node, Variant())));
	if (n == nullptr || double(p.get(c.levantar_en, 0.0)) > 0.0 || double(p.get(c.levanta_hasta, 0.0)) > t) {
		return nullptr;
	}
	return n;
}

// `LeagueLocomocion.enderezar`.
void enderezar(Dictionary &p) {
	const Claves &c = claves();
	p[c.w_ls_off_extra] = double(p.get(c.ls_off_extra, 0.0)) + double(p.get(c.ls_cuerpo, 0.0));
	p[c.w_ls_cuerpo] = 0.0;
	if (String(p.get(c.anim_actual, "")).begins_with("ls_ciclo__")) {
		p[c.w_anim_actual] = "";
	}
}

// `LeagueGuia._seguir_clip`.
Vector3 seguir_clip(Dictionary &p, Node3D *n, const Vector3 &v, double t, double delta, bool es_humano, int64_t &cortes, int64_t &guiados) {
	const Claves &c = claves();
	const Dictionary g = p[c.ls_guia];
	const double u = (t - double(g[c.t0])) / double(g[c.dur]);
	const double vel = Math::lerp(double(g[c.sp0]), double(g[c.fin]), suave(u));
	const double h0 = double(g[c.h0]);
	const double ang = double(g[c.ang]);
	const double rumbo = h0 + ang * suave(u / 0.8);
	const Vector3 clip = Vector3(std::sin(rumbo), 0.0, std::cos(rumbo)) * vel;
	Vector3 pide = Vector3(p.get(c.objetivo, Vector3())) - n->get_position();
	pide.y = 0.0;
	const double corte = es_humano ? CORTE_USUARIO : CORTE_CPU;
	const double desvio = double(pide.length()) > 0.5 ? std::fabs(UtilityFunctions::angle_difference(h0 + ang, std::atan2(double(pide.x), double(pide.z)))) : 0.0;
	if ((u > 0.3 || es_humano) && desvio > corte) {
		p[c.w_ls_trans_hasta] = 0.0; // `LeagueLocomocion.cortar`
		p.erase(c.ls_fin_yaw);
		enderezar(p);
		p.erase(c.ls_guia);
		p[c.w_ls_espera_g] = t + PAUSA_CORTE;
		cortes++;
		return v;
	}
	guiados++;
	const double a = 1.0 - std::exp(-(es_humano ? K_USUARIO : K_CPU) * delta);
	const Vector3 plano = Vector3(v.x, 0.0, v.z);
	if (es_humano) {
		const double sp = plano.length();
		if (sp < 0.01) {
			return v;
		}
		return plano * (Math::lerp(sp, vel, a) / sp) + Vector3(0.0, v.y, 0.0);
	}
	return plano.lerp(clip, a) + Vector3(0.0, v.y, 0.0);
}

// `LeagueGuia._marcha`.
Vector3 marcha(const Dictionary &p, Node3D *n, const Vector3 &v, double delta) {
	const Claves &c = claves();
	const double sp = Vector2(v.x, v.z).length();
	if (sp < IDLE_DRIBBLE || sp >= WALK_SPRINT || !p.has(c.objetivo)) {
		return v;
	}
	const Vector3 obj = p[c.objetivo];
	const Vector3 np = n->get_position();
	if (double(Vector2(double(obj.x) - double(np.x), double(obj.z) - double(np.z)).length()) * 2.5 < sp * 1.15) {
		return v;
	}
	double m = sp >= DRIBBLE_WALK ? MARCHA_WALK : MARCHA_DRIBBLE;
	m = std::fmin(m, sp * TOLERANCIA);
	if (std::fabs(sp - m) < 0.02) {
		return v;
	}
	const double a = 1.0 - std::exp(-3.0 * delta);
	const double objetivo = Math::lerp(sp, m, a);
	return Vector3(v.x, 0.0, v.z) * (objetivo / sp) + Vector3(0.0, v.y, 0.0);
}
} // namespace

PackedInt32Array DinastiaNativo::guia_pendientes(const Array &jugadores, double t) const {
	const Claves &c = claves();
	PackedInt32Array salida;
	const int64_t total = jugadores.size();
	for (int64_t i = 0; i < total; i++) {
		Dictionary p = jugadores[i];
		if (nodo_si_cuenta(p, t) == nullptr) {
			continue;
		}
		if (double(p.get(c.gesto_hasta, 0.0)) > t || bool(p.get(c.por, false))) {
			p.erase(c.ls_guia);
			continue;
		}
		if (!p.has(c.ls_guia) && double(p.get(c.ls_espera_g, 0.0)) <= t && double(p.get(c.mirar_hasta, 0.0)) <= t) {
			salida.push_back(int32_t(i));
		}
	}
	return salida;
}

PackedInt32Array DinastiaNativo::guia_seguir(const Array &jugadores, double t, double delta, int64_t usuario, bool marchas) const {
	const Claves &c = claves();
	int64_t cortes = 0;
	int64_t guiados = 0;
	const int64_t total = jugadores.size();
	for (int64_t i = 0; i < total; i++) {
		Dictionary p = jugadores[i];
		Node3D *n = nodo_si_cuenta(p, t);
		if (n == nullptr || double(p.get(c.gesto_hasta, 0.0)) > t || bool(p.get(c.por, false))) {
			continue; // (la guía de estos ya la borró `guia_pendientes`)
		}
		const Vector3 v = p[c.vel];
		Vector3 nuevo = v;
		if (p.has(c.ls_guia) && double(Dictionary(p[c.ls_guia])[c.hasta]) > t) {
			nuevo = seguir_clip(p, n, v, t, delta, i == usuario || bool(p.get(c.ls_humano, false)), cortes, guiados);
		} else {
			p.erase(c.ls_guia);
			if (marchas) {
				nuevo = marcha(p, n, v, delta);
			}
		}
		if (nuevo != v) {
			p[c.w_vel] = nuevo;
			n->set_position(n->get_position() + (nuevo - v) * delta);
		}
	}
	PackedInt32Array r;
	r.push_back(int32_t(cortes));
	r.push_back(int32_t(guiados));
	return r;
}

// `LeagueGuia.paso` (17-11-2026): lo de `guia_pendientes` más la primera mitad de `LeagueGuia.decidir` (cadencia `lg_revisar`, velocidad deseada de
// `LeagueLocomocion.deseada`, clases de velocidad de `LeagueMovimiento.rango` y la prueba de arranque / frenada / giro). Devuelve, por cada jugador que SÍ tiene
// que elegir clip, [índice, sp, rel, sp_des] (GDScript sigue con `LeagueGuia.decidir_clip`: catálogo, `estable` y `empezar`). Escribe `lg_revisar` como `decidir`.
namespace {
inline double ls_rango(double v) {
	if (v >= 6.2) {
		return 8.0;
	}
	if (v >= 4.4) {
		return 5.0;
	}
	if (v >= 1.8) {
		return 3.5;
	}
	return 0.0;
}
} // namespace

PackedFloat64Array DinastiaNativo::guia_previo(const Array &jugadores, double t, int64_t poseedor) const {
	const Claves &c = claves();
	static const StringName k_lg_revisar("lg_revisar"), k_attr("attr"), k_rit("rit"), k_correr("correr"), k_aguante("aguante"), k_freno("freno");
	static const Variant w_lg_revisar(String("lg_revisar"));
	PackedFloat64Array salida;
	const int64_t total = jugadores.size();
	for (int64_t i = 0; i < total; i++) {
		Dictionary p = jugadores[i];
		Node3D *n = nodo_si_cuenta(p, t);
		if (n == nullptr) {
			continue;
		}
		if (double(p.get(c.gesto_hasta, 0.0)) > t || bool(p.get(c.por, false))) {
			p.erase(c.ls_guia);
			continue;
		}
		if (p.has(c.ls_guia) || double(p.get(c.ls_espera_g, 0.0)) > t || double(p.get(c.mirar_hasta, 0.0)) > t) {
			continue;
		}
		// `decidir`
		if (double(p.get(k_lg_revisar, 0.0)) > t || i == poseedor) {
			continue;
		}
		p[w_lg_revisar] = t + 0.1;
		const Vector3 v = p[c.vel];
		const double sp = Vector2(v.x, v.z).length();
		// `LeagueLocomocion.deseada`
		Vector3 des;
		if (p.has(c.objetivo) && !(double(p.get(c.levanta_hasta, 0.0)) > t)) {
			const Vector3 obj = p[c.objetivo];
			const Vector3 np = n->get_position();
			const Vector3 dif = Vector3(double(obj.x) - double(np.x), 0.0, double(obj.z) - double(np.z));
			const double dist = dif.length();
			if (dist > 0.25) {
				const Dictionary attr = p[k_attr];
				const double tope = (4.4 + double(attr[k_rit]) * 4.2) * (bool(p.get(k_correr, false)) ? 1.0 : 0.62) * (0.7 + 0.3 * double(p[k_aguante]));
				const double a = tope * double(p.get(k_freno, 1.0));
				const double b = dist * 2.5;
				des = dif / dist * (a < b ? a : b);
			}
		}
		const double sp_des = des.length();
		const double entra = ls_rango(sp);
		const double sale = ls_rango(sp_des);
		const double rel = sp_des > 0.1 ? UtilityFunctions::angle_difference(double(n->get_rotation().y), std::atan2(double(des.x), double(des.z))) : 0.0;
		const bool arranca = entra == 0.0 && sale > 0.0; // NOSONAR(cpp:S1244): clases de velocidad exactas, como la gemela
		const bool frena = entra > 0.0 && sale == 0.0; // NOSONAR(cpp:S1244)
		const bool gira = entra > 0.0 && sale > 0.0 && std::fabs(rel) >= 0.6;
		if (!(arranca || frena || gira)) {
			continue;
		}
		salida.push_back(double(i));
		salida.push_back(sp);
		salida.push_back(rel);
		salida.push_back(sp_des);
	}
	return salida;
}
