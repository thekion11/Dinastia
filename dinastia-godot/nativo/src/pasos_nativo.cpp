// LAS PIEZAS DEL PASO DEL MOTOR DEL PARTIDO (16-11-2026, orden del dueño «60 % del tiempo de CPU en C++»; separadas de guia_nativo.cpp el 17-11 por la
// norma de 450 líneas): duelos, disputas, cercanía al balón de la colocación, animación de los 22 y locomoción de League. Cada función es copia exacta de su
// gemela GDScript (la cita su comentario); la igualdad la comprueban `pruebas/probar_nativo_sin_balon.gd` y `probar_nativo.gd`.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/animation_player.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>

using namespace godot;

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
// `CicloCarrera.CICLO` (visor/ciclo_carrera.gd, 17-11): velocidad con escala 1 (0 = no es ciclo) y margen de escala de cada ciclo.
const double CICLOS[] = { 0.0, 3.4, 7.0, 3.6, 2.6, 0.0, 0.0, 2.0, 2.0, 0.0 };
const double ESC_MIN[] = { 1.0, 0.55, 0.6, 0.7, 0.7, 1.0, 1.0, 0.7, 0.7, 1.0 };
const double ESC_MAX[] = { 1.0, 1.55, 1.45, 1.4, 1.4, 1.0, 1.0, 1.4, 1.4, 1.0 };
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
		// `CicloCarrera.ciclo`: con histéresis (a correr a 5,2 m/s; de vuelta a trotar por debajo de 4,5).
		static const String c_correr_h("correr");
		int a = sp < 0.5 ? 0 : (sp >= (String(p.get(k_actual, "")) == c_correr_h ? 4.5 : 5.2) ? 2 : 1);
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
		const double escala = c > 0.0 ? std::fmin(std::fmax(sp / c, ESC_MIN[a]), ESC_MAX[a]) : 1.0; // `CicloCarrera.escala`
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

// `LeagueLocomocion._paso` (visor/league_locomocion.gd, 16-11-2026): el bucle de los 22. Hace aquí el camino común de `_uno` (clip en curso, o la compensación
// del giro que se apaga y el modelo que se recoloca) y devuelve, en orden, lo que necesita GDScript: índice·2 = puede empezar clip (`_quizas_empezar`),
// índice·2+1 = `_uno` entero (terminar un clip, enderezar fuera de cámara, ciclo del cuerpo girado que toca revisar o empezar clip tras la compensación).
// Cada jugador solo toca lo suyo y lo que se hace aquí no mira bibliotecas de clips ni cámara, así que el orden relativo de lo que hace GDScript es el de siempre.
PackedInt32Array DinastiaNativo::loco_paso(const Array &jugadores, double t, double delta, int64_t poseedor, double recolocar) const {
	static const StringName k_propio("ls_propio_hasta"), k_trans("ls_trans_hasta"), k_off("ls_off"), k_cuerpo("ls_cuerpo"), k_anim_act("anim_actual"), k_revisar("ls_revisar"),
			k_por("por"), k_gesto("gesto_hasta"), k_mirar("mirar_hasta"), k_espera("ls_espera"), k_visto("ls_visto"), k_node("node"), k_modelo("ls_modelo"), k_anim("anim"),
			k_yaw0("ls_yaw0"), k_fin_yaw("ls_fin_yaw"), k_seguir_t("ls_seguir_t"), k_ciclo_act("ls_ciclo_actual"), k_escala("ls_escala"), k_off_extra("ls_off_extra"),
			k_modelo_base("ls_modelo_base");
	static const Variant w_off(String("ls_off")), w_cuerpo(String("ls_cuerpo")), w_off_extra(String("ls_off_extra"));
	static const String c_parado("parado"), c_trotar("trotar"), c_correr("correr");
	auto en_ciclos = [&](const Variant &v) {
		const Variant::Type tipo = v.get_type();
		if (tipo != Variant::STRING && tipo != Variant::STRING_NAME) {
			return false;
		}
		const String a = v;
		return a == c_parado || a == c_trotar || a == c_correr;
	};
	PackedInt32Array salida;
	const int64_t total = jugadores.size();
	for (int64_t i = 0; i < total; i++) {
		Dictionary p = jugadores[i];
		if (p.has(k_propio)) {
			continue;
		}
		const bool en_curso = double(p.get(k_trans, 0.0)) > t;
		double off = double(p.get(k_off, 0.0));
		const double cuerpo = double(p.get(k_cuerpo, 0.0));
		if (!en_curso && off == 0.0 && cuerpo == 0.0) { // NOSONAR(cpp:S1244): copia exacta de la gemela
			if (!en_ciclos(p.get(k_anim_act, Variant()))) {
				continue;
			}
			if (double(p.get(k_revisar, -1.0)) > t || i == poseedor || bool(p.get(k_por, false)) || double(p.get(k_gesto, 0.0)) > t || double(p.get(k_mirar, 0.0)) > t ||
					double(p.get(k_espera, 0.0)) > t) {
				continue;
			}
			salida.push_back(int32_t(i * 2));
			continue;
		}
		// `_uno`: ¿todo por el camino común?
		if (!en_curso && cuerpo != 0.0 && !bool(p.get(k_visto, true))) { // NOSONAR(cpp:S1244)
			salida.push_back(int32_t(i * 2 + 1));
			continue;
		}
		Node3D *n = Object::cast_to<Node3D>(static_cast<Object *>(p.get(k_node, Variant())));
		Node3D *modelo = Object::cast_to<Node3D>(static_cast<Object *>(p.get(k_modelo, Variant())));
		if (n == nullptr || modelo == nullptr) {
			p[w_off] = 0.0;
			p[w_cuerpo] = 0.0;
			continue;
		}
		AnimationPlayer *ap = Object::cast_to<AnimationPlayer>(static_cast<Object *>(p.get(k_anim, Variant())));
		if (en_curso) {
			if (ap != nullptr) {
				ap->set_speed_scale(1.0);
			}
			off = UtilityFunctions::angle_difference(double(n->get_rotation().y), double(p[k_yaw0]));
		} else {
			if (p.has(k_fin_yaw)) {
				salida.push_back(int32_t(i * 2 + 1));
				continue;
			}
			const bool cuerpo_quieto = cuerpo == 0.0; // NOSONAR(cpp:S1244)
			const bool ciclo_vigente = double(p.get(k_seguir_t, -1.0)) > t && p.get(k_anim_act, Variant()) == p.get(k_ciclo_act, Variant());
			if (!cuerpo_quieto && !ciclo_vigente) {
				salida.push_back(int32_t(i * 2 + 1));
				continue;
			}
			if (double(p.get(k_trans, 0.0)) <= t && cuerpo_quieto && en_ciclos(String(p.get(k_anim_act, "")))) {
				salida.push_back(int32_t(i * 2 + 1)); // tras la compensación puede empezar un clip: `_quizas_empezar` desde `_uno`
				continue;
			}
			off = std::fabs(off) > 0.01 ? off * std::exp(-recolocar * delta) : 0.0;
			p[w_off] = off;
			if (!cuerpo_quieto && ap != nullptr) {
				ap->set_speed_scale(double(p.get(k_escala, 1.0)));
			}
		}
		const double nuevo_off = off + double(p.get(k_off_extra, 0.0));
		p[w_off] = nuevo_off;
		p[w_off_extra] = 0.0;
		const double giro = double(p[k_modelo_base]) + nuevo_off;
		Vector3 rot = modelo->get_rotation();
		if (std::fabs(giro - double(rot.y)) > 0.002) {
			rot.y = giro;
			modelo->set_rotation(rot);
		}
	}
	return salida;
}
