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

// `MotorJugable._duelos` (visor/motor_jugable_p5.gd, 16-11-2026): las parejas (i < j, de equipos distintos, ningún portero) a 1,3 m o menos en el plano, en el orden
// del doble bucle de GDScript, como [i0, j0, i1, j1, …]. Dentro de ese bucle nadie cambia de sitio, de equipo ni de puesto (los empujones solo apuntan la fuerza,
// y si se pita algo el bucle se corta), así que la lista vale para todo el bucle; lo que sí cambia (contacto, gestos) lo sigue mirando GDScript pareja a pareja.
PackedInt32Array DinastiaNativo::duelos_parejas(const Array &jugadores) const {
	static const StringName k_node("node"), k_local("es_local"), k_por("por");
	const int64_t n = jugadores.size();
	Vector3 ps[64];
	bool local[64];
	bool vale[64];
	PackedInt32Array r;
	if (n > 64) {
		r.push_back(-1);
		return r;
	}
	for (int64_t i = 0; i < n; i++) {
		const Dictionary p = jugadores[i];
		const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(p.get(k_node, Variant())));
		vale[i] = nodo != nullptr && !bool(p.get(k_por, false));
		local[i] = bool(p.get(k_local, false));
		ps[i] = nodo != nullptr ? nodo->get_position() : Vector3();
	}
	for (int64_t i = 0; i < n; i++) {
		if (!vale[i]) {
			continue;
		}
		for (int64_t j = i + 1; j < n; j++) {
			if (!vale[j] || local[i] == local[j]) {
				continue;
			}
			const Vector3 dif = ps[j] - ps[i];
			if (double(Vector3(dif.x, 0.0, dif.z).length()) > 1.3) {
				continue;
			}
			r.push_back(int32_t(i));
			r.push_back(int32_t(j));
		}
	}
	return r;
}

// `MotorJugable._disputas` (visor/motor_jugable_p6.gd, 16-11-2026): el enfriamiento de los 22 (`enfriar` −= delta, sin bajar de 0) y, con el balón suelto
// (`suelto`), quién lo controla: el más cercano que llega (alcance 0,9 m; el portero en su área 1,6 m y hasta 2,4 m de alto; el que espera el pase 1,25 m con
// 0,55 m de ventaja). Devuelve su índice, o -1. `arco_z` = [z del arco propio del local, del visitante] (como `_arco_propio`); `pase_a_id` = id del receptor
// o null. Misma aritmética que la gemela (`_disputas_inicio_gd`).
int64_t DinastiaNativo::disputas_inicio(const Array &jugadores, double delta, bool suelto, const Vector3 &b, double t, const Variant &pase_a_id, const PackedFloat64Array &arco_z,
		double area_x, double area_z) const {
	static const Variant w_enfriar(String("enfriar"));
	static const StringName k_enfriar("enfriar"), k_levanta("levanta_hasta"), k_node("node"), k_por("por"), k_local("es_local"), k_id("id");
	const int64_t n = jugadores.size();
	for (int64_t i = 0; i < n; i++) {
		Dictionary p = jugadores[i];
		p[w_enfriar] = std::fmax(0.0, double(p[k_enfriar]) - delta);
	}
	if (!suelto) {
		return -1;
	}
	int64_t mejor = -1;
	double md = 99.0;
	for (int64_t i = 0; i < n; i++) {
		const Dictionary p = jugadores[i];
		if (double(p[k_enfriar]) > 0.0 || double(p.get(k_levanta, 0.0)) > t) {
			continue;
		}
		const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(p.get(k_node, Variant())));
		if (nodo == nullptr) {
			continue;
		}
		const Vector3 q = nodo->get_position();
		const double d = Vector2(double(q.x) - double(b.x), double(q.z) - double(b.z)).length();
		const bool por = bool(p[k_por]);
		const double az = arco_z[bool(p[k_local]) ? 0 : 1];
		const bool en_area = por && std::fabs(double(b.x)) < area_x && std::fabs(double(b.z) - az) < area_z;
		double alcance = en_area ? 1.6 : 0.9;
		double ventaja = 0.0;
		if (pase_a_id.get_type() != Variant::NIL && p.get(k_id, Variant()) == pase_a_id) {
			alcance = 1.25;
			ventaja = 0.55;
		}
		if (d < alcance && double(b.y) < (en_area ? 2.4 : 1.5) && d - ventaja < md) {
			md = d - ventaja;
			mejor = i;
		}
	}
	return mejor;
}

// `MotorColocacion.actualizar` (visor/motor_colocacion.gd, 16-11-2026): la distancia del más cercano de cada equipo al balón (en 3D, con tope 40 m), como
// [local, visitante]. Gemela: `MotorColocacion.cerca_gd`.
PackedFloat64Array DinastiaNativo::colocacion_cerca(const Array &jugadores, const Vector3 &b) const {
	static const StringName k_node("node"), k_local("es_local");
	double cerca[2] = { 40.0, 40.0 };
	const int64_t n = jugadores.size();
	for (int64_t i = 0; i < n; i++) {
		const Dictionary q = jugadores[i];
		const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(q.get(k_node, Variant())));
		if (nodo == nullptr) {
			continue;
		}
		const int e = bool(q[k_local]) ? 0 : 1;
		const double d = nodo->get_position().distance_to(b);
		cerca[e] = cerca[e] < d ? cerca[e] : d; // minf(cerca, d)
	}
	PackedFloat64Array r;
	r.push_back(cerca[0]);
	r.push_back(cerca[1]);
	return r;
}

// `MotorJugable._mover_jugadores` (visor/motor_jugable_p5_p1.gd, 16-11-2026): la animación de los 22 según su movimiento (`res` = [válido, velocidad, va_atrás,
// distancia al balón] por jugador, de `mover_jugadores_fisica`). Por jugador devuelve [código, escala]: código = índice en ANIMS, −1 = no se toca, −2 = lo hace
// GDScript entero (`_animar_uno`: el que se levanta del suelo y el parado que quizá está fundido, que necesita `forma_fisica`). Con `aplicar` hace además lo
// que haría `_anim(p, nombre, false)` con esos nombres (en el motor de League: clip propio → nada; transición o cuerpo girado → `ls_pedido`; si no, la de
// siempre) y pone `speed_scale`. Gemela de las decisiones: `_anim_decidir_gd`.
namespace {
const char *ANIMS[] = { "parado", "trotar", "correr", "conducir", "trotar_atras", "marcar", "portero_listo", "portero_lateral_der", "portero_lateral_izq", "cansado" };
// `CICLO_ANIM` (0 = no está).
const double CICLOS[] = { 0.0, 3.4, 7.0, 3.6, 2.6, 0.0, 0.0, 2.0, 2.0, 0.0 };
} // namespace

PackedFloat64Array DinastiaNativo::animar_jugadores(const Array &jugadores, const PackedFloat64Array &res, double t, const Variant &poseedor_id, bool cansancio_real, bool league,
		bool aplicar) const {
	static const StringName k_node("node"), k_vel("vel"), k_levantar("levantar_en"), k_gesto("gesto_hasta"), k_jockey("jockey"), k_por("por"), k_id("id"), k_anim("anim"),
			k_actual("anim_actual"), k_propio("ls_propio_hasta"), k_trans("ls_trans_hasta"), k_cuerpo("ls_cuerpo"), k_tiempo_de("ls_tiempo_de");
	static const Variant w_pedido(String("ls_pedido")), w_actual(String("anim_actual"));
	const int64_t n = jugadores.size();
	PackedFloat64Array out;
	out.resize(n * 2);
	const bool hay_pos = poseedor_id.get_type() != Variant::NIL;
	for (int64_t i = 0; i < n; i++) {
		out[i * 2] = -1.0;
		out[i * 2 + 1] = -1.0;
		if (res[i * 4] == 0.0) { // NOSONAR(cpp:S1244): bandera exacta (0 o 1) de `mover_jugadores_fisica`
			continue;
		}
		Dictionary p = jugadores[i];
		if (double(p.get(k_levantar, 0.0)) > 0.0) {
			out[i * 2] = -2.0;
			continue;
		}
		if (double(p.get(k_gesto, 0.0)) > t) {
			continue;
		}
		const double sp = res[i * 4 + 1];
		const bool atras = res[i * 4 + 2] > 0.5;
		const double hacia_b = res[i * 4 + 3];
		const bool es_pos = hay_pos && p.get(k_id, Variant()) == poseedor_id;
		const bool por = bool(p.get(k_por, false));
		int a = sp < 0.5 ? 0 : (sp < 5.2 ? 1 : 2);
		if (es_pos && sp >= 0.5 && sp < 6.5) {
			a = 3;
		} else if (atras) {
			a = 4;
		} else if (bool(p.get(k_jockey, false)) && !es_pos && sp < 4.5) {
			a = 5;
		} else if (sp < 0.5 && por && hacia_b < 32.0) {
			a = 6;
		} else if (por && !es_pos && sp >= 0.5 && sp < 6.0) {
			const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(p.get(k_node, Variant())));
			const double ry = nodo != nullptr ? double(nodo->get_rotation().y) : 0.0;
			const Vector3 fr = Vector3(std::sin(ry), 0.0, std::cos(ry));
			const Vector3 der = Vector3(-fr.z, 0.0, fr.x);
			const Vector3 vel = p[k_vel];
			const double lat = vel.dot(der);
			const double fon = vel.dot(fr);
			if (std::fabs(lat) >= std::fabs(fon) * 0.8) {
				a = lat > 0.0 ? 7 : 8;
			} else if (fon < 0.0) {
				a = 4;
			}
		} else if (sp < 0.5 && cansancio_real) {
			out[i * 2] = -2.0; // `forma_fisica(p)` la mira GDScript
			continue;
		}
		const double c = CICLOS[a];
		const double escala = c > 0.0 ? std::fmin(std::fmax(sp / c, 0.7), 1.4) : 1.0;
		out[i * 2] = double(a);
		out[i * 2 + 1] = escala;
		if (!aplicar) {
			continue;
		}
		const String nombre = ANIMS[a];
		AnimationPlayer *ap = Object::cast_to<AnimationPlayer>(static_cast<Object *>(p.get(k_anim, Variant())));
		bool sigue = true;
		if (league) {
			if (p.has(k_propio)) {
				sigue = false; // `LeagueAcciones.ocupado`
			} else if (!(double(p.get(k_trans, 0.0)) <= t && double(p.get(k_cuerpo, 0.0)) == 0.0)) { // NOSONAR(cpp:S1244): copia de `LeagueLocomocion.bloquea`
				p[w_pedido] = nombre;
				sigue = false;
			}
		}
		if (sigue) {
			if (String(p.get(k_actual, "")) != nombre && ap != nullptr && ap->has_animation(nombre)) {
				ap->play(nombre, 0.2);
				p[w_actual] = nombre;
			}
			if (league && p.has(k_tiempo_de)) {
				p.erase(k_tiempo_de); // `LeagueAcciones.igualar` sin gesto
			}
		}
		if (ap != nullptr) {
			ap->set_speed_scale(escala);
		}
	}
	return out;
}
