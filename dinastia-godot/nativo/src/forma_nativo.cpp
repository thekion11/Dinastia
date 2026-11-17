// PRUEBA PEQUEÑA (17-11-2026, orden de Auditoría): `MotorRoles.base` en C++ para medir cuánto se gana al portar `_forma`. Copia exacta de la gemela
// GDScript (visor/motor_roles.gd): con el reparto guardado en la meta del motor fresco (< 0,5 s), la base del dueño del puesto; si no, null (GDScript recalcula).
#include "dinastia_nativo.h"

#include <godot_cpp/variant/vector3.hpp>

using namespace godot;

Variant DinastiaNativo::roles_base(Object *m, const Dictionary &p, double t, const Array &jugadores) const {
	static const StringName k_local("es_local"), k_id("id"), k_base("base_pos"), k_rl("_roles_l"), k_rv("_roles_v");
	static const String k_t("t"), k_mapa("mapa");
	const StringName clave = bool(p[k_local]) ? k_rl : k_rv;
	if (!m->has_meta(clave)) {
		return Variant();
	}
	const Dictionary e = m->get_meta(clave);
	const double et = e[k_t];
	if (!(t >= et && t - et < 0.5)) {
		return Variant();
	}
	const Dictionary mapa = e[k_mapa];
	const String id = p[k_id];
	const String dueno = mapa.get(id, p[k_id]);
	if (dueno == id) {
		return p[k_base];
	}
	const int n = jugadores.size();
	for (int i = 0; i < n; i++) {
		const Dictionary q = jugadores[i];
		if (String(q[k_id]) == dueno) {
			return q[k_base];
		}
	}
	return p[k_base];
}
