// `MotorJugable._mover_fisica_gd` (visor/motor_jugable_p5.gd, 15-11-2026, paso a C++): el movimiento de los jugadores del motor del partido (velocidad con inercia,
// giro, empujón del duelo, posición, rumbo del cuerpo, inclinación y aguante). Misma aritmética que el GDScript, operación por operación: los Vector3 en float de
// 32 bits y los escalares en double, igual que allí. `igualdad` en `pruebas/probar_nativo.tscn`.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace {
inline double clampd(double v, double lo, double hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}
// `MovimientoNatural.inclinacion` / `cabeceo`.
inline double inclinacion(double actual, double giro, double vel, double delta) {
	const double obj = clampd(-std::atan(vel * giro / 9.8) * 0.3, -0.2, 0.2) * UtilityFunctions::smoothstep(2.0, 4.5, std::fabs(vel));
	return actual + (obj - actual) * (1.0 - std::exp(-5.0 * delta));
}
inline double cabeceo(double actual, double acel, double delta) {
	const double obj = clampd(acel * 0.025, -0.07, 0.14);
	return actual + (obj - actual) * (1.0 - std::exp(-5.0 * delta));
}
} // namespace

PackedFloat64Array DinastiaNativo::mover_jugadores_fisica(const Array &jugadores, const Vector3 &bpos, double delta, double t, bool hay_poseedor, const Variant &poseedor_id,
		bool poseedor_local, double a_max_base, double ancho, double largo, double giro_rapido, const PackedFloat64Array &coste_aguante) const {
	static const StringName k_node("node"), k_obj("objetivo"), k_levanta("levanta_hasta"), k_attr("attr"), k_rit("rit"), k_fis("fis"), k_correr("correr"), k_aguante("aguante"),
			k_freno("freno"), k_freno_hasta("freno_duelo_hasta"), k_freno_duelo("freno_duelo"), k_vel("vel"), k_giro_firme("giro_firme"), k_emp_obj("empujon_obj"),
			k_emp("empujon"), k_mirar_hasta("mirar_hasta"), k_mirar("mirar"), k_por("por"), k_jockey("jockey"), k_local("es_local"), k_sp_antes("sp_antes"), k_id("id");
	const int64_t n = jugadores.size();
	PackedFloat64Array salida;
	salida.resize(n * 4);
	double *out = salida.ptrw();
	for (int64_t i = 0; i < n; i++) {
		out[i * 4] = 0.0;
		out[i * 4 + 1] = 0.0;
		out[i * 4 + 2] = 0.0;
		out[i * 4 + 3] = 0.0;
		Dictionary p = jugadores[i];
		const Variant va_nodo = p[k_node];
		Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(va_nodo)); // un nodo ya liberado llega como null (= is_instance_valid falso)
		if (nodo == nullptr || !p.has(k_obj)) {
			continue;
		}
		out[i * 4] = 1.0;
		Vector3 np = nodo->get_position();
		const bool es_poseedor = hay_poseedor && p.get(k_id, Variant()) == poseedor_id;
		Vector3 obj = (double(p.get(k_levanta, 0.0)) <= t) ? Vector3(p[k_obj]) : np;
		obj.y = 0.0;
		const Vector3 dif = obj - Vector3(np.x, 0, np.z);
		const double dist = dif.length();
		const Dictionary attr = p[k_attr];
		const double rit = double(attr[k_rit]);
		const double aguante = double(p[k_aguante]);
		double tope = (4.4 + rit * 4.2) * (bool(p.get(k_correr, false)) ? 1.0 : 0.62) * (0.7 + 0.3 * aguante);
		if (es_poseedor) {
			tope *= 0.88;
		}
		tope *= double(p.get(k_freno, 1.0));
		if (double(p.get(k_freno_hasta, 0.0)) > t) {
			tope *= double(p.get(k_freno_duelo, 1.0));
		}
		Vector3 deseada = Vector3();
		if (dist > 0.25) {
			deseada = dif / dist * std::min(tope, dist * 2.5);
		}
		Vector3 vel = p[k_vel];
		const double sp0 = vel.length();
		const double sp_des = deseada.length();
		const bool giro_firme = bool(p.get(k_giro_firme, false));
		if (sp0 > 0.6 && sp_des > 0.1) {
			const Vector3 dir0 = vel / sp0;
			const Vector3 dir1 = deseada / sp_des;
			const double ang = dir0.signed_angle_to(dir1, Vector3(0, 1, 0));
			double giro_rad = 9.0 + (2.6 - 9.0) * clampd(sp0 / 8.0, 0.0, 1.0);
			if (giro_firme) {
				giro_rad *= 2.4;
			}
			const double giro_max = giro_rad * delta;
			const Vector3 dir = dir0.rotated(Vector3(0, 1, 0), clampd(ang, -giro_max, giro_max));
			const double objetivo_sp = sp_des * (1.0 - 0.6 * clampd((std::fabs(ang) - 0.5) / 2.0, 0.0, 1.0));
			const double acel = (objetivo_sp > sp0) ? (6.0 + rit * 2.0) : 11.0;
			vel = dir * UtilityFunctions::move_toward(sp0, objetivo_sp, acel * delta);
		} else {
			vel = vel.move_toward(deseada, (sp_des > sp0) ? (6.0 + rit * 2.0) * delta : 11.0 * delta);
		}
		const double a_max = (giro_firme ? a_max_base * 1.35 : a_max_base) * delta;
		const Vector3 vel_ant = p[k_vel];
		const Vector3 dv = vel - vel_ant;
		if (dv.length() > a_max) {
			vel = vel_ant + dv.normalized() * a_max;
		}
		p[k_vel] = vel;
		np += vel * delta;
		const Vector3 emp_obj_v = p.get(k_emp_obj, Vector3());
		Vector3 emp = p.get(k_emp, Vector3());
		if (emp_obj_v != Vector3() || emp != Vector3()) {
			emp = emp.move_toward(emp_obj_v, 22.0 * delta);
			p[k_emp_obj] = (emp_obj_v.length() > 0.05) ? Vector3(emp_obj_v * std::exp(-7.0 * delta)) : Vector3();
			p[k_emp] = (emp.length() > 0.02 || emp_obj_v != Vector3()) ? emp : Vector3();
			np += emp * delta;
		}
		np = Vector3(clampd(np.x, -ancho - 2.0, ancho + 2.0), np.y, clampd(np.z, -largo - 2.0, largo + 2.0));
		nodo->set_position(np);
		const double sp = vel.length();
		Vector3 hacia_b = bpos - np;
		hacia_b.y = 0.0;
		bool atras = false;
		Vector3 rot = nodo->get_rotation();
		const double giro_antes = rot.y;
		bool corre_recto = false;
		const bool por = bool(p[k_por]);
		const bool es_local = bool(p[k_local]);
		if (double(p.get(k_mirar_hasta, 0.0)) > t) {
			rot.y = UtilityFunctions::rotate_toward(rot.y, double(p[k_mirar]), giro_rapido * delta);
		} else if (sp > 0.5 && sp < 4.2 && !es_poseedor && !por && hacia_b.length() < 18.0 && hay_poseedor && poseedor_local != es_local &&
				vel.normalized().dot(hacia_b.normalized()) < -0.35) {
			atras = true;
			rot.y = UtilityFunctions::rotate_toward(rot.y, UtilityFunctions::atan2(hacia_b.x, hacia_b.z), 7.0 * delta);
		} else if ((por || bool(p.get(k_jockey, false))) && !es_poseedor && sp < 6.0 && hacia_b.length() > 0.5) {
			rot.y = UtilityFunctions::rotate_toward(rot.y, UtilityFunctions::atan2(hacia_b.x, hacia_b.z), 8.0 * delta);
		} else if (sp > 0.4) {
			rot.y = UtilityFunctions::rotate_toward(rot.y, UtilityFunctions::atan2(vel.x, vel.z), 9.0 * delta);
			corre_recto = true;
		} else if (!es_poseedor) {
			const Vector3 hacia = bpos - np;
			rot.y = UtilityFunctions::rotate_toward(rot.y, UtilityFunctions::atan2(hacia.x, hacia.z), 4.0 * delta);
		}
		nodo->set_rotation(rot);
		if (delta > 0.0) {
			rot = nodo->get_rotation();
			rot.z = inclinacion(rot.z, corre_recto ? UtilityFunctions::angle_difference(giro_antes, rot.y) / delta : 0.0, sp, delta);
			nodo->set_rotation(rot);
			rot = nodo->get_rotation();
			const double sp_antes = double(p.get(k_sp_antes, sp));
			rot.x = cabeceo(rot.x, corre_recto ? (sp - sp_antes) / delta : 0.0, delta);
			nodo->set_rotation(rot);
			p[k_sp_antes] = sp;
		}
		if (bool(p.get(k_correr, false)) && sp > 5.0) {
			const double coste = coste_aguante[es_local ? 0 : 1];
			p[k_aguante] = std::max(0.2, double(p[k_aguante]) - delta * 0.012 * (1.4 - double(attr[k_fis])) * coste);
		} else {
			p[k_aguante] = std::min(1.0, double(p[k_aguante]) + delta * 0.006);
		}
		out[i * 4 + 1] = sp;
		out[i * 4 + 2] = atras ? 1.0 : 0.0;
		out[i * 4 + 3] = hacia_b.length();
	}
	return salida;
}
