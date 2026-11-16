// EL BALÓN DEL MOTOR DE LEAGUE, EN C++ (16-11-2026, paso a C++). Traducción LITERAL de
// `LeagueNucleo.fuerzas_balon` (visor/league_nucleo.gd), del bucle de `MotorLeague._mover_balon`
// (visor/motor_league_p1.gd) y de la predicción de `MotorLeague._estado_sin_balon` (visor/motor_league.gd):
// Vector3 / Vector2 en 32 bits y el resto en double, como GDScript. Las gemelas GDScript se quedan de
// respaldo (Android sin binario, Web, `DINASTIA_SIN_NATIVO=1`); `pruebas/probar_nativo.tscn` comprueba que dan los mismos bytes.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>

using namespace godot;

namespace {

struct CfgBalon {
	double rebote, rebote_lineal, arrastre, roce, roce_lineal, gravedad, cesped, humedad;
	Vector3 viento;
};

CfgBalon leer_cfg(const Dictionary &cfg) {
	static const StringName k_rebote("rebote"), k_rebote_lineal("rebote_lineal"), k_arrastre("arrastre"), k_roce("roce"), k_roce_lineal("roce_lineal"),
			k_gravedad("gravedad"), k_cesped("cesped"), k_humedad("humedad"), k_viento("viento");
	CfgBalon c;
	c.rebote = cfg[k_rebote];
	c.rebote_lineal = cfg[k_rebote_lineal];
	c.arrastre = cfg[k_arrastre];
	c.roce = cfg[k_roce];
	c.roce_lineal = cfg[k_roce_lineal];
	c.gravedad = cfg[k_gravedad];
	c.cesped = cfg[k_cesped];
	c.humedad = cfg[k_humedad];
	c.viento = cfg[k_viento];
	return c;
}

double clampd(double v, double lo, double hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}

// `LeagueNucleo.fuerzas_balon`
void fuerzas(Vector3 &pos, Vector3 &mom, const CfgBalon &c, double dt, double radio) {
	mom.y = (float)((double)mom.y + c.gravedad * dt);
	const double velo = (double)mom.length();
	const double velo_frenada = velo - c.arrastre * velo * velo * dt;
	mom = velo > 0.0 ? (mom / (float)velo * (float)velo_frenada) : Vector3();
	const double abajo = (double)pos.y - radio;
	const double hierba = std::pow(clampd(1.0 - abajo / c.cesped, 0.0, 1.0), 0.7);
	mom += c.viento * (float)((1.0 - hierba) * dt);
	if ((double)pos.y < radio) {
		if ((double)mom.y < 0.0) {
			mom.y = (float)(-(double)mom.y * c.rebote);
			const double m = (double)mom.y - c.rebote_lineal;
			mom.y = (float)(m > 0.0 ? m : 0.0);
		}
		pos.y = (float)radio;
	}
	if ((double)pos.y < radio + c.cesped) {
		const double moja = 1.0 - clampd(c.humedad, 0.0, 1.0) * 0.5;
		const double roce = c.roce * hierba * moja;
		Vector2 xy(mom.x, mom.z);
		const double v = (double)xy.length();
		double nv = v - roce * v * v * dt;
		nv = clampd(nv - c.roce_lineal * hierba * moja * dt, 0.0, 100000.0);
		xy = v > 0.0 ? xy.normalized() * (float)nv : Vector2();
		mom.x = xy.x;
		mom.z = xy.y;
	}
}

} // namespace

// La trayectoria prevista del balón cada `dt` s durante `total` pasos, ya en el sistema de League (`_ls3`: (z, x, y)). Índice 0 = el balón ahora.
PackedVector3Array DinastiaNativo::balon_prediccion(const Vector3 &bp0, const Vector3 &bv0, const Dictionary &cfg, bool hay_poseedor, const Vector3 &vel_poseedor, int64_t total, double dt, double radio) const {
	const CfgBalon c = leer_cfg(cfg);
	PackedVector3Array salida;
	salida.resize(total + 1);
	Vector3 bp = bp0;
	Vector3 bv = bv0;
	salida[0] = Vector3(bp.z, bp.x, bp.y);
	for (int64_t k = 1; k <= total; k++) {
		if (!hay_poseedor) {
			fuerzas(bp, bv, c, dt, radio);
			bp += bv * (float)dt;
		} else {
			bp += vel_poseedor * (float)dt;
		}
		salida[k] = Vector3(bp.z, bp.x, bp.y);
	}
	return salida;
}

// El bucle de pasos de 10 ms del balón suelto de `MotorLeague._mover_balon`. `estado` = [p, vel, giro, resto]; devuelve lo mismo, ya avanzado.
// `k` = {paso, radio, alto_aire, vel_y_aire, magnus, giro_aire, giro_suelo_pot, largo, palo, larguero}.
Array DinastiaNativo::balon_avanzar(const Vector3 &p0, const Vector3 &vel0, const Vector3 &giro0, double resto0, double delta, const Dictionary &cfg, const PackedFloat64Array &k) const {
	const CfgBalon c = leer_cfg(cfg);
	const double paso = k[0], radio = k[1], umbral_y = k[2], umbral_vy = k[3], magnus = k[4], giro_aire = k[5], giro_suelo = k[6], largo = k[7], palo = k[8], larguero = k[9];
	Vector3 p = p0, vel = vel0, giro = giro0;
	double resto = resto0 + delta;
	while (resto >= paso) {
		resto -= paso;
		const bool en_aire = (double)p.y > umbral_y || std::fabs((double)vel.y) > umbral_vy;
		if (en_aire) {
			vel += giro.cross(vel) * (float)magnus * (float)paso;
			giro *= (float)std::exp(-giro_aire * paso);
		} else {
			giro *= (float)std::pow(giro_suelo, paso * 60.0);
		}
		fuerzas(p, vel, c, paso, radio);
		p += vel * (float)paso;
		if (std::fabs((double)p.z) > largo && std::fabs((double)p.x) < palo && (double)p.y < larguero) {
			vel *= 0.85f;
			p.z = (float)clampd((double)p.z, -largo - 1.8, largo + 1.8);
		}
	}
	Array r;
	r.resize(4);
	r[0] = p;
	r[1] = vel;
	r[2] = giro;
	r[3] = resto;
	return r;
}
