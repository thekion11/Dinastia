// LA LOCOMOCIÓN DE LEAGUE-SOCCER EN C++ (10-11-2026, paso a C++ de la fase 4c de docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md).
// Traducción LITERAL de visor/league_movimiento.gd (`elegir`, `cuerpo_permitido`, `sesgo_giro`, `similitud`, `similitud_cuerpo`, `_mira`)
// y de visor/league_auto.gd (`legal_gd`, el bucle de huesos de `construir`): mismas operaciones y en el mismo orden; double donde
// GDScript usa `float` y Vector2 / Quaternion / Vector3 de 32 bits donde los usa GDScript. El GDScript se queda de respaldo
// (Android sin binario, Web, `DINASTIA_SIN_NATIVO=1`); `pruebas/probar_nativo.tscn` comprueba que dan lo mismo.
#include "dinastia_nativo.h"

#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/quaternion.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>

using namespace godot;

namespace {

const double SPRINT = 8.0;
const double CONTRABANDO = 0.1 * Math::PI;
const double MARGEN = 0.01;

// `LeagueMovimiento.cuerpo_permitido`
double cuerpo_permitido(double ang) {
	const double a = Math::wrapf(ang, -Math::PI, Math::PI);
	if (std::fabs(a) < 0.125 * Math::PI) {
		return 0.0;
	}
	return (std::fabs(a) < 0.5 * Math::PI ? 0.25 * Math::PI : 0.75 * Math::PI) * (a > 0.0 ? 1.0 : -1.0);
}

double clampd(double v, double lo, double hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}

// `LeagueMovimiento.sesgo_giro`
double sesgo_giro(const Vector2 &actual, const Vector2 &deseado) {
	const Vector2 dn = (double)deseado.length() > 0.0001 ? deseado.normalized() : actual.normalized();
	const double ang = (double)actual.length() > 0.0001 ? std::fabs((double)dn.angle_to(actual)) : 0.0;
	const double por_giro = std::sin(ang - 0.5 * Math::PI) * 0.5 + 0.5;
	const double por_vel = clampd((double)actual.length() / (SPRINT - 0.5), 0.0, 1.0);
	return por_vel * por_giro * 0.9;
}

// `LeagueMovimiento.similitud` (sobre un cuadrante o un clip: solo usa «pref» y «sale»)
double similitud(const Dictionary &c, const Vector2 &dir, double vel_deseada, double sesgo) {
	static const StringName k_pref("pref"), k_sale("sale");
	const Vector2 deseado = dir * vel_deseada * (1.0 - sesgo);
	const Vector2 sale_dir = c[k_pref];
	const double valor = (deseado - sale_dir * (double)c[k_sale]).length();
	return valor - std::fabs((double)dir.dot(sale_dir)) * 4.0;
}

// `LeagueMovimiento.similitud_cuerpo`
double similitud_cuerpo(const Dictionary &c, const Vector2 &dir, double mirar) {
	static const StringName k_ang("ang"), k_cuerpo_sale("cuerpo_sale");
	const double ang = c[k_ang];
	const double cuerpo_sale = c[k_cuerpo_sale];
	const Vector2 sale_dir = Vector2(0, -1).rotated(ang);
	const double sale = ang + clampd((double)sale_dir.angle_to(dir), -CONTRABANDO, CONTRABANDO);
	return std::fabs(Math::angle_difference(mirar, cuerpo_sale + sale)) + std::fabs(cuerpo_sale) * 0.05;
}

// `LeagueMovimiento._mira`
double mira(const Dictionary &c) {
	static const StringName k_cuerpo_sale("cuerpo_sale"), k_pref("pref");
	const Vector2 pref = c[k_pref];
	return cuerpo_permitido((double)c[k_cuerpo_sale]) + (double)Vector2(0, -1).angle_to(pref);
}

} // namespace

Dictionary DinastiaNativo::league_elegir(const Array &grupos, double sp, double rel, double deseada, bool parado, double mirar, const String &pie) const {
	static const StringName k_reposo1("reposo1"), k_clips("clips"), k_reposo("reposo"), k_pie("pie");
	const Vector2 dir = Vector2(0, -1).rotated(rel);
	const double sesgo = sesgo_giro(Vector2(0, -sp), dir * deseada);
	Array cuadrante;
	double mv = INFINITY;
	const int64_t nq = grupos.size();
	for (int64_t i = 0; i < nq; i++) {
		const Dictionary q = grupos[i];
		const double v = similitud(q, dir, deseada, sesgo) + ((bool)q[k_reposo1] ? 0.0 : 0.001);
		if (v < mv) {
			mv = v;
			cuadrante = q[k_clips];
		}
	}
	if (cuadrante.is_empty()) {
		return Dictionary();
	}
	const int64_t n = cuadrante.size();
	Dictionary elegido = cuadrante[0];
	for (int64_t i = 0; i < n; i++) {
		const Dictionary c = cuadrante[i];
		if ((int64_t)c[k_reposo] == 1) {
			elegido = c;
			break;
		}
	}
	double mc = INFINITY;
	if (!std::isnan(mirar)) {
		for (int64_t i = 0; i < n; i++) {
			const Dictionary c = cuadrante[i];
			const double r = similitud_cuerpo(c, dir, mirar);
			if (r < mc) {
				mc = r;
				elegido = c;
			}
		}
	}
	if (pie.is_empty() || parado || String(elegido[k_pie]) == pie) {
		return elegido;
	}
	const double m = mira(elegido);
	for (int64_t i = 0; i < n; i++) {
		const Dictionary c = cuadrante[i];
		if (String(c[k_pie]) == pie && (std::isnan(mirar) || std::fabs(Math::angle_difference(mira(c), m)) <= 0.06 * Math::PI)) {
			return c;
		}
	}
	return elegido;
}

bool DinastiaNativo::league_legal(int64_t vi, int64_t vo, double cuerpo_sale, double cuerpo_ini, double a) const {
	if (vo - vi > 1) {
		return false;
	}
	if ((int64_t)std::round(vo * std::cos(a) - vi) < -3) {
		return false;
	}
	if (vi == 3 && vo == 1 && (std::fabs(cuerpo_sale) > 0.25 * Math::PI + MARGEN || std::fabs(a) > 0.25 * Math::PI + MARGEN)) {
		return false;
	}
	if (vi > 0 && vo > 0 && std::fabs(a) > 0.5 * Math::PI + MARGEN) {
		return false;
	}
	if (vi + vo > 4 && std::fabs(a) > 0.25 * Math::PI + MARGEN) {
		return false;
	}
	const double delta_cuerpo = Math::wrapf(cuerpo_sale - cuerpo_ini, -Math::PI, Math::PI);
	if (std::fabs(a + delta_cuerpo) > Math::PI + MARGEN) {
		return false;
	}
	return true;
}

void DinastiaNativo::league_mezclar(const Ref<Animation> &sal, const Ref<Animation> &a1, const Ref<Animation> &a2, const PackedInt32Array &cuadros,
		const PackedFloat64Array &mezclas, double ang, const Quaternion &giro_padre) const {
	const int64_t nt = a1->get_track_count();
	const int64_t nc = cuadros.size();
	const double largo1 = a1->get_length();
	const double largo2 = a2->get_length();
	const Quaternion giro_inv = giro_padre.inverse();
	for (int64_t i = 0; i < nt; i++) {
		const Animation::TrackType tipo = a1->track_get_type(i);
		const NodePath ruta = a1->track_get_path(i);
		const int64_t j = a2->find_track(ruta, tipo);
		if (j < 0 || !(tipo == Animation::TYPE_ROTATION_3D || tipo == Animation::TYPE_POSITION_3D)) {
			continue;
		}
		const int64_t k = sal->add_track(tipo);
		sal->track_set_path(k, ruta);
		const bool pelvis = String(ruta).ends_with(":pelvis");
		for (int64_t x = 0; x < nc; x++) {
			const double t = cuadros[x] / 100.0;
			const double m0 = mezclas[x * 2];
			const double m1 = mezclas[x * 2 + 1];
			if (tipo == Animation::TYPE_ROTATION_3D) {
				Quaternion r = a1->rotation_track_interpolate(i, t < largo1 ? t : largo1).slerp(
						a2->rotation_track_interpolate(j, t < largo2 ? t : largo2), m0);
				if (pelvis) {
					const Quaternion arriba(Vector3(0, 1, 0), ang * (m0 * 0.7 + m1 * 0.3));
					r = (giro_inv * arriba * giro_padre) * r;
				}
				sal->rotation_track_insert_key(k, t, r);
			} else {
				sal->position_track_insert_key(k, t, a1->position_track_interpolate(i, t < largo1 ? t : largo1).lerp(
						a2->position_track_interpolate(j, t < largo2 ? t : largo2), m0));
			}
		}
	}
}
