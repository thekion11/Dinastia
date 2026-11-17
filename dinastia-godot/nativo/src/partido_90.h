// El generador de azar y el estado del partido simulado de la IA en C++ (sacados de partido_90.cpp el 17-11-2026 por la norma de 450 líneas). Solo lo incluye
// partido_90.cpp.
#pragma once

#include "dinastia_nativo.h"

#include <godot_cpp/classes/random_number_generator.hpp>

#include <cmath>

using namespace godot;

namespace {

// `maxf` de GDScript: (a > b) ? a : b
inline double maxf_gd(double a, double b) {
	return a > b ? a : b;
}

// El generador de azar del juego (`Azar._rng`, PCG32 de Godot). Propio: la misma aritmética que el motor, sobre su `state` (se vuelca antes de cada vuelta a GDScript y se relee después). Si la
// autocomprobación (`pcg_coincide`) no confirma que el motor hace lo mismo, se usan las llamadas del motor (más lentas, mismo resultado).
struct AzarNativo {
	Ref<RandomNumberGenerator> rng;
	bool propio = false;
	uint64_t state = 0;
	static constexpr uint64_t INC = (1442695040888963407ULL << 1) | 1ULL;
	inline uint32_t rand32() {
		const uint64_t old = state;
		state = old * 6364136223846793005ULL + INC;
		const uint32_t xs = uint32_t(((old >> 18) ^ old) >> 27);
		const uint32_t rot = uint32_t(old >> 59);
		return (xs >> rot) | (xs << ((0u - rot) & 31u));
	}
	inline float randf() {
		if (!propio) {
			return rng->randf();
		}
		const uint32_t e = rand32();
		if (e == 0) {
			return 0.0f;
		}
		return float(std::ldexp(double(rand32() | 0x80000001u), -32 - __builtin_clz(e)));
	}
	inline void entrar() {
		if (propio) {
			state = rng->get_state();
		}
	}
	inline void salir() {
		if (propio) {
			rng->set_state(state);
		}
	}
};

struct Estado {
	Object *p;
	Object *ayuda;
	Array once_l, once_v;
	Dictionary aportes;
	Variant club_l, club_v;
	int64_t minuto;
	// contadores propios
	int64_t rem_l = 0, rem_v = 0, tp_l = 0, tp_v = 0, cor_l = 0, cor_v = 0, fal_l = 0, fal_v = 0, fue_l = 0, fue_v = 0;
	double xg_l = 0.0, xg_v = 0.0, posesion = 50.0;
	// fuerza (copia de `_fza_*`)
	double ata_l = 0.0, def_l = 0.0, ata_v = 0.0, def_v = 0.0;
	double pl = 0.0, pv = 0.0;
	bool hay_lesionados = false;
	bool terminado = false;
};

} // namespace
