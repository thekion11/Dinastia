// El relieve de la ciudad y la textura de hierba (30-10-2026): copias exactas de
// `TerrenoArreglos.calcular_gd` y `CityBuilder._imagen_hierba_gd`. El ruido y el azar son los
// del motor (FastNoiseLite, RandomNumberGenerator), así la secuencia es la misma.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/fast_noise_lite.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/random_number_generator.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>
#include <vector>

using namespace godot;

// `TerrenoArreglos.altura` (las cuentas en float de 64 bits, como GDScript).
static double altura_terreno(double x, double z, FastNoiseLite *ruido, FastNoiseLite *detalle,
		double llano_radio, double llano_trans, double alto, const Vector2 &monte, double monte_alto, double monte_radio) {
	const double d = double(Vector2(real_t(x), real_t(z)).length());
	if (d <= llano_radio) {
		return 0.0;
	}
	double t = CLAMP((d - llano_radio) / llano_trans, 0.0, 1.0);
	t = t * t * (3.0 - 2.0 * t);
	double h = double(ruido->get_noise_2d(real_t(x), real_t(z))) * alto;
	h += double(detalle->get_noise_2d(real_t(x), real_t(z))) * 6.0;
	const double dm = double(Vector2(real_t(x), real_t(z)).distance_to(monte));
	return h * t + monte_alto * std::exp(-dm * dm / (2.0 * monte_radio * monte_radio)) * t;
}

Array DinastiaNativo::terreno(const Ref<FastNoiseLite> &ruido, const Ref<FastNoiseLite> &detalle, double lado,
		int celdas, int baldosas, double llano_radio, double llano_trans, double alto, const Vector2 &monte,
		double monte_alto, double monte_radio) const {
	Array salida;
	if (ruido.is_null() || detalle.is_null() || celdas <= 0 || baldosas <= 0) {
		return salida;
	}
	const double paso = lado / double(celdas);
	const double mitad = lado * 0.5;
	const int fila = celdas + 1;
	std::vector<double> alturas(size_t(fila) * fila);
	for (int j = 0; j < fila; j++) {
		for (int i = 0; i < fila; i++) {
			const double x = -mitad + i * paso;
			const double z = -mitad + j * paso;
			alturas[size_t(j) * fila + i] = altura_terreno(x, z, ruido.ptr(), detalle.ptr(), llano_radio, llano_trans, alto, monte, monte_alto, monte_radio);
		}
	}
	auto h = [&](int ii, int jj) {
		return alturas[size_t(CLAMP(jj, 0, celdas)) * fila + CLAMP(ii, 0, celdas)];
	};
	std::vector<Vector3> normales(size_t(fila) * fila);
	for (int j = 0; j < fila; j++) {
		for (int i = 0; i < fila; i++) {
			const double dx = (h(i + 1, j) - h(i - 1, j)) / (2.0 * paso);
			const double dz = (h(i, j + 1) - h(i, j - 1)) / (2.0 * paso);
			normales[size_t(j) * fila + i] = Vector3(real_t(-dx), real_t(1.0), real_t(-dz)).normalized();
		}
	}
	const int por_baldosa = celdas / baldosas;
	const real_t veinte = real_t(20.0);
	for (int bj = 0; bj < baldosas; bj++) {
		for (int bi = 0; bi < baldosas; bi++) {
			PackedVector3Array vs;
			PackedVector3Array ns;
			PackedVector2Array uvs;
			const int64_t celdas_b = int64_t(por_baldosa) * por_baldosa;
			vs.resize(celdas_b * 6);
			ns.resize(celdas_b * 6);
			uvs.resize(celdas_b * 6);
			Vector3 *pv = vs.ptrw();
			Vector3 *pn = ns.ptrw();
			Vector2 *pu = uvs.ptrw();
			int64_t k = 0;
			for (int j = bj * por_baldosa; j < (bj + 1) * por_baldosa; j++) {
				for (int i = bi * por_baldosa; i < (bi + 1) * por_baldosa; i++) {
					const double x0 = -mitad + i * paso;
					const double z0 = -mitad + j * paso;
					const Vector3 p00(real_t(x0), real_t(alturas[size_t(j) * fila + i]), real_t(z0));
					const Vector3 p10(real_t(x0 + paso), real_t(alturas[size_t(j) * fila + i + 1]), real_t(z0));
					const Vector3 p01(real_t(x0), real_t(alturas[size_t(j + 1) * fila + i]), real_t(z0 + paso));
					const Vector3 p11(real_t(x0 + paso), real_t(alturas[size_t(j + 1) * fila + i + 1]), real_t(z0 + paso));
					const Vector3 v[6] = { p00, p10, p01, p10, p11, p01 };
					const Vector3 n6[6] = { normales[size_t(j) * fila + i], normales[size_t(j) * fila + i + 1],
						normales[size_t(j + 1) * fila + i], normales[size_t(j) * fila + i + 1],
						normales[size_t(j + 1) * fila + i + 1], normales[size_t(j + 1) * fila + i] };
					for (int q = 0; q < 6; q++) {
						pv[k + q] = v[q];
						pn[k + q] = n6[q];
						pu[k + q] = Vector2(v[q].x, v[q].z) / veinte;
					}
					k += 6;
				}
			}
			Array b;
			b.push_back(vs);
			b.push_back(ns);
			b.push_back(uvs);
			salida.push_back(b);
		}
	}
	return salida;
}

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
		return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
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
};

// Los píxeles se leen y escriben directo, con la MISMA conversión que `Image::get_pixel` (L8:
// `ptr / 255.0`) y `set_pixel` (RGB8: `uint8_t(CLAMP(c * 255.0, 0, 255))`) del motor 4.7.2.
static inline uint8_t a_byte(float v) {
	const double d = v * 255.0;
	return uint8_t(d < 0 ? 0.0 : (d > 255 ? 255.0 : d));
}

Ref<Image> DinastiaNativo::hierba(const Ref<Image> &manchas, int64_t semilla) const {
	const int n = manchas.is_valid() ? manchas->get_width() : 0;
	if (n == 0 || manchas->get_height() != n || manchas->get_format() != Image::FORMAT_L8) {
		return Ref<Image>();   // el llamador usa entonces la versión GDScript
	}
	const PackedByteArray datos_m = manchas->get_data();
	const uint8_t *pm = datos_m.ptr();
	PackedByteArray datos;
	datos.resize(int64_t(n) * n * 3);
	uint8_t *pd = datos.ptrw();
	Pcg32 rng;
	rng.seed(uint64_t(semilla));
	const Color a(0.11, 0.27, 0.08);
	const Color b(0.20, 0.40, 0.12);
	const Color seca(0.42, 0.40, 0.20);
	for (int y = 0; y < n; y++) {
		for (int x = 0; x < n; x++) {
			const int64_t o = int64_t(y) * n + x;
			const float l = pm[o] / 255.0;
			const double m = double(l);
			const double t = double(rng.randf()) * 0.7 + m * 0.5;
			Color c = a.lerp(b, float(CLAMP(t, 0.0, 1.0)));
			if (double(rng.randf()) < 0.04) {
				c = c.darkened(0.3);
			} else if (m > 0.72 && double(rng.randf()) < 0.25) {
				c = c.lerp(seca, 0.5);
			}
			pd[o * 3] = a_byte(c.r);
			pd[o * 3 + 1] = a_byte(c.g);
			pd[o * 3 + 2] = a_byte(c.b);
		}
	}
	return Image::create_from_data(n, n, false, Image::FORMAT_RGB8, datos);
}
