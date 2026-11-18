// El tráfico de la ciudad en C++ (18-11-2026), 2/3: obstáculos de los peatones (`libre_obst` + `_choca_circulos`), sirenas, `tapa_al_jugador`, `_colocar`, `_lateral`, `_esquivar`, `_mirar_delante` y `MovimientoNatural.marcha`. Ver `trafico_nativo.cpp`.
#include "trafico_comun.h"

#include <godot_cpp/variant/utility_functions.hpp>

#include <cmath>

using namespace godot;
using namespace godot::trafico;

// `ExploradorCiudad.en_rio`, `en_puente`, `libre`, `libre_obst` y `_choca_circulos` (visor/explorador_ciudad_p1.gd) con el radio del contexto.
	// `ExploradorCiudad.en_rio`, `en_puente`, `libre`, `libre_obst` y `_choca_circulos` (visor/explorador_ciudad_p1.gd) con el radio del contexto.
bool Paso::libre_q(const Vector3 &p) {
	if (!ctx_ok) {
		return bool(libre_fn.call(p));
	}
	const double radio = c_radio;
	const Vector2i kc(int32_t(Math::floor(double(p.x) / c_celda_obst)), int32_t(Math::floor(double(p.z) / c_celda_obst)));
	const Array celda = rej_obst.get(kc, Array());
	// libre(p, radio, celda)
	if (std::abs(double(p.x)) > c_limite || std::abs(double(p.z)) > c_limite) {
		return false;
	}
	if (std::abs(double(p.x) - c_rio_x) < 50.0 && std::abs(double(p.z)) < 1360.0) {
		const double linea = Math::snapped(double(p.z), c_celda_av);
		const bool puente = std::abs(double(p.z) - linea) < c_ancho_av * 0.5 - 1.0 && std::abs(double(p.x) - c_rio_x) < 66.0;
		if (!puente) {
			return false;
		}
	}
	for (int64_t i = 0; i < celda.size(); i++) {
		const Rect2 r = celda[i];
		const Vector2 fin = r.position + r.size;
		if (double(p.x) > double(r.position.x) - radio && double(p.x) < double(fin.x) + radio && double(p.z) > double(r.position.y) - radio && double(p.z) < double(fin.y) + radio) {
			return false;
		}
	}
	// _choca_circulos(p, radio)
	const int32_t cx = int32_t(Math::floor(double(p.x) / c_celda_circ));
	const int32_t cz = int32_t(Math::floor(double(p.z) / c_celda_circ));
	for (int32_t i = cx - 1; i < cx + 2; i++) {
		for (int32_t j = cz - 1; j < cz + 2; j++) {
			const Array lista = rej_circ.get(Vector2i(i, j), Array());
			for (int64_t q = 0; q < lista.size(); q++) {
				const Vector3 c = lista[q];
				const double dx = double(p.x) - double(c.x);
				const double dz = double(p.z) - double(c.y);
				const double rr = radio + double(c.z);
				if (dx * dx + dz * dz < rr * rr) {
					return false;
				}
			}
		}
	}
	return true;
}

// `TraficoCiudad.sirena_cerca`
	// `TraficoCiudad.sirena_cerca`
bool Paso::sirena_cerca(const Vector3 &p, const Vector3 &dir, double vel)  const {
	const double a = RADIO_SIRENA;
	const double b = vel * vel / 6.0 + 12.0;
	const double radio = a > b ? a : b;
	for (int64_t i = 0; i < sirenas.size(); i++) {
		Node3D *s = Object::cast_to<Node3D>(static_cast<Object *>(sirenas[i]));
		if (s == nullptr) {
			continue;
		}
		const Vector3 sp = s->get_position();
		if (double(Vector2(real_t(double(sp.x) - double(p.x)), real_t(double(sp.z) - double(p.z))).length()) < radio) {
			const Vector3 rel = sp - p;
			if (dir != Vector3() && double(rel.dot(dir)) < -1.0 && std::abs(double(rel.cross(dir).y)) < 3.5) {
				continue;
			}
			return true;
		}
	}
	return false;
}

// `TraficoCiudad.tapa_al_jugador`
	// `TraficoCiudad.tapa_al_jugador`
bool Paso::tapa_al_jugador(const Vector3 &pos, const Vector3 &dir, double umbral, double ancho, const Vector3 &pj, double ang, const Vector2 &h) {
	const Vector2 d = Vector2(dir.x, dir.z).normalized();
	const double sn = std::sin(ang);
	const double cs = std::cos(ang);
	for (int i = 0; i < 5; i++) {
		const double kq = 0.2 + double(i) / 4.0 * (umbral - 0.2);
		const double rx = double(pos.x) + double(d.x) * kq - double(pj.x);
		const double rz = double(pos.z) + double(d.y) * kq - double(pj.z);
		const double a0 = std::abs(rx * cs - rz * sn) - double(h.x);
		const double ex = a0 > 0.0 ? a0 : 0.0;
		const double a1 = std::abs(rx * sn + rz * cs) - double(h.y);
		const double ez = a1 > 0.0 ? a1 : 0.0;
		if (ex * ex + ez * ez < ancho * ancho) {
			const double b0 = std::abs((double(pos.x) - double(pj.x)) * cs - (double(pos.z) - double(pj.z)) * sn) - double(h.x);
			const double ox = b0 > 0.0 ? b0 : 0.0;
			const double b1 = std::abs((double(pos.x) - double(pj.x)) * sn + (double(pos.z) - double(pj.z)) * cs) - double(h.y);
			const double oz = b1 > 0.0 ? b1 : 0.0;
			return ox * ox + oz * oz >= 0.01;
		}
	}
	return false;
}

// `TraficoCiudad._colocar`
	// `TraficoCiudad._colocar`
void Paso::colocar(Dictionary v, double delta) {
	Node3D *nodo = nodo_de(v, k);
	if (nodo == nullptr) {
		return;
	}
	const int64_t ri = int64_t(v[k.ruta]);
	const Ruta &r = ruta(ri);
	Vector3 pos, dir;
	ruta_en(r, double(v[k.s]), pos, dir);
	nodo->set_position(pos + Vector3(0, real_t(double(v[k.alto])), 0) + Vector3(dir.z, 0, -dir.x) * real_t(gf(v, k.lat, 0.0)));
	double yaw = std::atan2(double(dir.x), double(dir.z)) + double(v[k.giro]);
	if (delta > 0.0 && bool(v.get(k.peaton, false))) {
		Vector3 p2, prox;
		ruta_en(r, double(v[k.s]) + MN_ANTICIPO, p2, prox);
		const double objetivo = std::atan2(double(prox.x), double(prox.z)) + double(v[k.giro]);
		yaw = Math::lerp_angle(double(nodo->get_rotation().y), objetivo, 1.0 - std::exp(-MN_GIRO * delta));
	}
	Vector3 rot = nodo->get_rotation();
	rot.y = real_t(yaw);
	nodo->set_rotation(rot);
}

// `TraficoCiudad._lateral`
	// `TraficoCiudad._lateral`
void Paso::lateral(Dictionary v, double delta, double vel) {
	const double t_lat = gf(v, k.t_lat, 0.0);
	if (t_lat > 0.0) {
		v[k.t_lat] = t_lat - delta;
	} else if (gf(v, k.lat_obj, 0.0) != 0.0) {
		v[k.lat_obj] = 0.0;
	}
	const double lat = gf(v, k.lat, 0.0);
	const double obj = gf(v, k.lat_obj, 0.0);
	if (lat != obj) {
		v[k.lat] = Math::move_toward(lat, obj, vel * delta);
	}
}

// `TraficoCiudad._esquivar`
	// `TraficoCiudad._esquivar`
bool Paso::esquivar(Dictionary v, double de_lat, double preferido) {
	if (gf(v, k.t_lat, 0.0) > 0.0 && std::abs(gf(v, k.lat_obj, 0.0) - de_lat) > SEPARA_LADO) {
		v[k.t_lat] = 1.5;
		return true;
	}
	Vector3 pos, dir;
	ruta_en(ruta(int64_t(v[k.ruta])), double(v[k.s]), pos, dir);
	const Vector3 fuera = Vector3(dir.z, 0, -dir.x);
	const double sgs[2] = { preferido, -preferido };
	for (int i = 0; i < 2; i++) {
		double lat = de_lat + LADO_ESQUIVA * sgs[i];
		lat = lat < -1.0 ? -1.0 : (lat > 1.0 ? 1.0 : lat);
		if (std::abs(lat - de_lat) < SEPARA_LADO) {
			continue;
		}
		if (libre_activo()) {
			const Vector3 q1 = pos + fuera * real_t(lat);
			const Vector3 q2 = pos + fuera * real_t(lat) + dir * real_t(1.5);
			if (!(libre_q(q1) && libre_q(q2))) {
				continue;
			}
		}
		v[k.lat_obj] = lat;
		v[k.t_lat] = 1.5;
		return true;
	}
	return false;
}

// `TraficoCiudad._mirar_delante`
	// `TraficoCiudad._mirar_delante`
void Paso::mirar_delante(Dictionary v, double s, double delta) {
	if (!libre_activo()) {
		return;
	}
	const double azar = UtilityFunctions::randf() * MIRA_CADA; // el valor por defecto de `get` se evalúa SIEMPRE
	const double t = double(v.get(k.t_mira, azar)) - delta;
	if (t > 0.0) {
		v[k.t_mira] = t;
		return;
	}
	v[k.t_mira] = MIRA_CADA;
	Vector3 pos, dir;
	ruta_en(ruta(int64_t(v[k.ruta])), s, pos, dir);
	const double lat = gf(v, k.lat, 0.0);
	const Vector3 q = pos + Vector3(dir.z, 0, -dir.x) * real_t(lat) + dir * real_t(MIRA_DELANTE);
	if (!libre_q(q)) {
		esquivar(v, lat, 1.0);
	}
}

// `MovimientoNatural.marcha`
	// `MovimientoNatural.marcha`
double Paso::marcha(Dictionary v, double avance, double pedido, double delta) {
	const bool anda = avance > pedido * 0.3;
	double kk_ = gf(v, k.k, 1.0);
	kk_ = Math::move_toward(kk_, anda ? 1.0 : 0.0, anda ? delta / MN_ARRANQUE : 1.0);
	v[k.k] = kk_;
	const double t = gf(v, k.t_anda, 0.0) - delta;
	const bool ya = bool(v.get(k.anda, true));
	if (anda != ya && t <= 0.0) {
		v[k.anda] = anda;
		v[k.t_anda] = MN_MIN_CAMBIO;
		tr->call("_cb_mn_clip", v, anda ? String("caminar") : String("parado"), kk_);
	} else {
		v[k.t_anda] = t > 0.0 ? t : 0.0;
		if (anda && ya && kk_ < 1.0) {
			tr->call("_cb_mn_vel", v, double(v[k.vel]) * (kk_ > 0.4 ? kk_ : 0.4));
		}
	}
	if (anda && ya && kk_ >= 1.0 && bool(v.get(k.rampa, false))) {
		v[k.rampa] = false;
		tr->call("_cb_mn_vel", v, double(v[k.vel]));
	}
	if (kk_ < 1.0) {
		v[k.rampa] = true;
	}
	const double lim = pedido * kk_;
	return avance < lim ? avance : lim;
}

void Paso::luz_freno(Dictionary v, double valor) {
	Object *fm = static_cast<Object *>(v[k.faros]);
	GeometryInstance3D *g = Object::cast_to<GeometryInstance3D>(fm);
	if (g != nullptr) {
		g->set_instance_shader_parameter(StringName("freno"), valor);
	}
}

void Paso::pausar_anim(Dictionary v, bool pausar) {
	if (bool(v.get(k.apausa, false)) == pausar) {
		return;
	}
	tr->call("_pausar_anim", v, pausar);
}

