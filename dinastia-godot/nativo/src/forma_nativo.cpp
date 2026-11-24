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

// `MotorJugable._forma` (visor/motor_jugable_p8_p1.gd) con NUESTRA colocación, entera en una llamada (17-11-2026, porte aprobado por Auditoría). Lo que no
// cambia dentro de un paso lo arma GDScript una vez en `ctx` (`MotorCombinado._ctx_forma`, gemela `_forma_ctx_gd`):
//   [0] motor, [1] t, [2] jugadores, [3] estado de MotorColocacion local, [4] visitante (diccionarios vivos: bal, sesgo), [5] lin local, [6] lin visitante,
//   [7] men local, [8] men visitante, [9] amp local, [10] amp visitante, [11] estado de MotorAdaptacion (vivo; null = apagada), [12] sin roles dinámicos,
//   [13] LARGO, [14] ANCHO.
// Con el reparto de roles caducado devuelve null (GDScript lo recalcula y sigue por la gemela).
static const double PESO_Z_CON = 0.34, PESO_Z_SIN = 0.45, PESO_X_CON = 0.18, PESO_X_SIN = 0.22, ARRANQUE = 15.0, TOPE_LADO = 4.0;

static inline double lerp_d(double a, double b, double w) {
	return a + (b - a) * w;
}

static inline double clamp_d(double v, double lo, double hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}

Variant DinastiaNativo::forma_c4(const Array &ctx, const Dictionary &p, bool en_posesion) const {
	static const StringName k_local("es_local"), k_base("base_pos");
	static const String k_bal("bal"), k_sesgo("sesgo"), k_vistos("vistos"), k_x("x");
	const bool local = bool(p[k_local]);
	Vector3 base;
	if (bool(ctx[12])) {
		base = p[k_base];
	} else {
		const Variant vb = roles_base(Object::cast_to<Object>(ctx[0]), p, double(ctx[1]), ctx[2]);
		if (vb.get_type() == Variant::NIL) {
			return Variant();
		}
		base = vb;
	}
	const Dictionary est = ctx[local ? 3 : 4];
	const Vector3 b = est[k_bal];
	double s = est[k_sesgo];
	if (en_posesion) {
		s = s > 0.6 ? s : 0.6;
	}
	const double zb = lerp_d(PESO_Z_SIN, PESO_Z_CON, s);
	const double xb = lerp_d(PESO_X_SIN, PESO_X_CON, s);
	const double p0 = zb, p1 = xb, p2 = 1.0 - zb, p3 = 1.0 - xb;
	const double d = local ? 1.0 : -1.0;
	const double lin = ctx[local ? 5 : 6];
	const double men = ctx[local ? 7 : 8];
	const double amp = ctx[local ? 9 : 10];
	double desvio = 0.0;
	if (!en_posesion && ctx[11].get_type() == Variant::DICTIONARY) {
		const Dictionary ad = ctx[11];
		const int rival = local ? 1 : 0;
		const Array vistos = ad[k_vistos];
		if (!(double(vistos[rival]) < ARRANQUE)) {
			const Array xs = ad[k_x];
			desvio = clamp_d(double(xs[rival]) * 0.3, -TOPE_LADO, TOPE_LADO);
		}
	}
	double z = double(base.z) * p2 + double(b.z) * p0 + (en_posesion ? d * (9.0 + men * 3.0) : -d * 3.0);
	z += d * (lin * 3.5 + men * 2.0);
	const double x = double(base.x) * (p3 + (en_posesion ? amp * 0.12 : 0.0)) + double(b.x) * p1 + desvio;
	const double largo = ctx[13], ancho = ctx[14];
	z = clamp_d(z, -largo + 4.0, largo - 4.0);
	return Vector3(clamp_d(x, -ancho + 2.0, ancho - 2.0), 0, z);
}
