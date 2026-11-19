// LA IMAGEN DE LA ENREDADERA, EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»). `Texturas.enredadera` (visor/texturas_p1.gd): 256×256 de verde oscuro con
// 1.400 hojas (elipses giradas, más claras hacia el centro) y 40 florecillas, con el azar del motor (PCG32 copiado, la misma secuencia). Operación a operación; el paso a RGB8 como
// `Image.set_pixel` (255 por canal, truncado). Gemela: `_imagen_enredadera_gd`. `pruebas/probar_nativo_asfalto.gd` (el mismo archivo de pruebas) compara los bytes.
#include "dinastia_nativo.h"
#include "pcg32_nativo.h"

#include <godot_cpp/variant/color.hpp>

#include <cmath>

using namespace godot;

namespace {
inline uint8_t a_byte(float canal) {
	double v = double(canal) * 255.0;
	v = v < 0.0 ? 0.0 : (v > 255.0 ? 255.0 : v);
	return uint8_t(v);
}
inline void poner(uint8_t *p, int64_t n, int64_t x, int64_t y, const Color &c) {
	uint8_t *q = p + (y * n + x) * 3;
	q[0] = a_byte(c.r);
	q[1] = a_byte(c.g);
	q[2] = a_byte(c.b);
}
inline int64_t posmod_gd(int64_t a, int64_t b) {
	int64_t v = a % b;
	return v < 0 ? v + b : v;
}
constexpr double TAU_GD = 6.2831853071795864769252867666;
}  // namespace

Ref<Image> DinastiaNativo::enredadera_imagen(int64_t semilla, int64_t n) const {
	PackedByteArray sal;
	sal.resize(n * n * 3);
	uint8_t *p = sal.ptrw();
	const Color fondo(0.07f, 0.15f, 0.05f);
	for (int64_t i = 0; i < n * n; i++) {
		poner(p, n, i % n, i / n, fondo);
	}
	Pcg32 rng;
	rng.seed(uint64_t(semilla));
	for (int k = 0; k < 1400; k++) {
		const int64_t cx = int64_t(rng.rand() % uint32_t(n));
		const int64_t cy = int64_t(rng.rand() % uint32_t(n));
		const int64_t r = rng.randi_range(3, 7);
		const double ang = double(rng.randf()) * TAU_GD;
		const float tr = rng.randf_range(0.08f, 0.22f);
		const float tg = rng.randf_range(0.24f, 0.46f);
		const float tb = rng.randf_range(0.06f, 0.14f);
		Color tono(tr, tg, tb);
		if (k > 1300) {
			tono = tono.lightened(0.25f);
		}
		const double ca = std::cos(ang), sa = std::sin(ang);
		const double r2 = double(r * r);
		for (int64_t dy = -r; dy <= r; dy++) {
			for (int64_t dx = -r; dx <= r; dx++) {
				// Hoja: elipse girada, más clara hacia el centro.
				const double u = double(dx) * ca + double(dy) * sa;
				const double w = double(-dx) * sa + double(dy) * ca;
				const double q = (u * u) / r2 + (w * w) / r2 * 3.0;
				if (q <= 1.0) {
					poner(p, n, posmod_gd(cx + dx, n), posmod_gd(cy + dy, n), tono.lightened(float((1.0 - q) * 0.15)));
				}
			}
		}
	}
	const int dx4[5] = { 0, 1, 0, -1, 0 };
	const int dy4[5] = { 0, 0, 1, 0, -1 };
	for (int k = 0; k < 40; k++) {
		const int64_t fx = int64_t(rng.rand() % uint32_t(n));
		const int64_t fy = int64_t(rng.rand() % uint32_t(n));
		const Color flor = k % 3 != 0 ? Color(0.95f, 0.95f, 0.9f) : Color(0.7f, 0.45f, 0.85f);
		for (int d = 0; d < 5; d++) {
			poner(p, n, posmod_gd(fx + dx4[d], n), posmod_gd(fy + dy4[d], n), flor);
		}
	}
	return Image::create_from_data(n, n, false, Image::FORMAT_RGB8, sal);
}
