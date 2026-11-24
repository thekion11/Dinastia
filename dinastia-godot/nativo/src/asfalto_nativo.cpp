// LA IMAGEN DEL ASFALTO, EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»). `Texturas._imagen_asfalto` (visor/texturas_p1.gd): los 512×512
// píxeles que mezclan tres ruidos ya generados (grande, medio y grietas) con granos sueltos del azar del motor (PCG32 copiado, la misma secuencia) y el tinte.
// Operación a operación: la cuenta en 64 bits, el color como float de 32 y el paso a RGB8 como `Image.set_pixel` (255 por el canal, truncado). Gemela: `_imagen_asfalto_gd`.
// Devuelve la imagen RGB8, o null si los ruidos no son L8 del tamaño pedido (entonces GDScript sigue por su camino). `pruebas/probar_nativo_asfalto.gd` compara los bytes.
#include "dinastia_nativo.h"
#include "pcg32_nativo.h"

#include <godot_cpp/variant/color.hpp>

using namespace godot;

namespace {
inline uint8_t a_byte(float canal) {
	double v = double(canal) * 255.0;
	v = v < 0.0 ? 0.0 : (v > 255.0 ? 255.0 : v);
	return uint8_t(v);
}
// `Image.get_pixel(x, y).r` de una imagen L8: el byte entre 255.
inline double gris(const uint8_t *p, int64_t i) {
	return double(float(double(p[i]) / 255.0));
}
}  // namespace

Ref<Image> DinastiaNativo::asfalto_imagen(const Ref<Image> &grande, const Ref<Image> &medio, const Ref<Image> &grieta, const Color &tinte, int64_t semilla, int64_t n) const {
	Ref<Image> vacio;
	const Ref<Image> ims[3] = { grande, medio, grieta };
	for (int k = 0; k < 3; k++) {
		if (ims[k].is_null() || ims[k]->get_width() != n || ims[k]->get_height() != n || ims[k]->get_format() != Image::FORMAT_L8) {
			return vacio;
		}
	}
	const PackedByteArray dg = grande->get_data(), dm = medio->get_data(), dc = grieta->get_data();
	if (dg.size() != n * n || dm.size() != n * n || dc.size() != n * n) {
		return vacio;
	}
	PackedByteArray sal;
	sal.resize(n * n * 3);
	uint8_t *ps = sal.ptrw();
	const uint8_t *pg = dg.ptr(), *pm = dm.ptr(), *pc = dc.ptr();
	Pcg32 rng;
	rng.seed(uint64_t(semilla));
	for (int64_t y = 0; y < n; y++) {
		for (int64_t x = 0; x < n; x++) {
			const int64_t i = y * n + x;
			const double g = gris(pg, i);
			const double md = gris(pm, i);
			double v = 0.82 + (g - 0.5) * 0.28 + (md - 0.5) * 0.12;
			// Árido: granos claros y oscuros sueltos.
			const double r = double(rng.randf());
			if (r < 0.05) {
				v += 0.35;
			} else if (r < 0.10) {
				v -= 0.22;
			} else {
				v += (double(rng.randf()) - 0.5) * 0.1;
			}
			// Grietas finas, solo en las zonas gastadas.
			if (gris(pc, i) < 0.03 && g > 0.6) {
				double t = (g - 0.6) / 0.08;
				t = t < 0.0 ? 0.0 : (t > 1.0 ? 1.0 : t);
				v -= 0.2 * t;
			}
			ps[i * 3 + 0] = a_byte(float(double(tinte.r) * v));
			ps[i * 3 + 1] = a_byte(float(double(tinte.g) * v));
			ps[i * 3 + 2] = a_byte(float(double(tinte.b) * v));
		}
	}
	return Image::create_from_data(n, n, false, Image::FORMAT_RGB8, sal);
}
