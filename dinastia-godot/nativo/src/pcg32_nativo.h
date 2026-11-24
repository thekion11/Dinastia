// El azar del motor copiado (`RandomNumberGenerator` = RandomPCG de Godot 4.7.2), compartido por las funciones que siembran su propio
// generador (la hierba de `terreno_hierba.cpp` y el ruido del sonido de `sonido_nativo.cpp`). Sacado de terreno_hierba.cpp el 19-11-2026.
#pragma once

#include <cmath>
#include <cstdint>

namespace godot {

// EL AZAR DEL MOTOR, COPIADO: `RandomNumberGenerator` es RandomPCG (PCG32 de thirdparty/misc/pcg.cpp,
// incremento por defecto 1442695040888963407) y su `randf` (core/math/random_pcg.h, con CLZ32).
// Llamar al motor 600.000 veces costaba ~90 ms; copiado da la MISMA secuencia (la prueba lo mira).
struct Pcg32 {
	uint64_t state = 0;
	uint64_t inc = 0;
	uint32_t rand() {
		const uint64_t oldstate = state;
		state = oldstate * 6364136223846793005ULL + (inc | 1);
		const uint32_t xorshifted = uint32_t(((oldstate >> 18u) ^ oldstate) >> 27u);
		const uint32_t rot = uint32_t(oldstate >> 59u);
		return (xorshifted >> rot) | (xorshifted << ((32u - rot) & 31u));
	}
	void seed(uint64_t initstate, uint64_t initseq = 1442695040888963407ULL) {
		state = 0U;
		inc = (initseq << 1u) | 1u;
		rand();
		state += initstate;
		rand();
	}
	float randf() {
		const uint32_t proto_exp_offset = rand();
		if (proto_exp_offset == 0) {
			return 0;
		}
		return std::ldexp(float(rand() | 0x80000001), -32 - __builtin_clz(proto_exp_offset));
	}
	// `rand(bounds)` del motor (pcg32_boundedrand_r): un entero en [0, bounds) sin sesgo.
	uint32_t rand_acotado(uint32_t bounds) {
		const uint32_t umbral = (0u - bounds) % bounds;
		for (;;) {
			const uint32_t r = rand();
			if (r >= umbral) {
				return r % bounds;
			}
		}
	}
	// `randi_range(desde, hasta)` del motor (`RandomPCG::random(int, int)`).
	int32_t randi_range(int32_t desde, int32_t hasta) {
		if (desde == hasta) {
			return desde;
		}
		const int32_t menor = desde < hasta ? desde : hasta;
		const int32_t dif = desde > hasta ? desde - hasta : hasta - desde;
		return int32_t(rand_acotado(uint32_t(dif) + 1u)) + menor;
	}
	// `randf_range(desde, hasta)` del motor: en float de 32 bits (`RandomPCG::randf_range(float, float)`).
	float randf_range(float desde, float hasta) {
		const float r = randf() * (hasta - desde);
		return r + desde;
	}
};

}  // namespace godot
