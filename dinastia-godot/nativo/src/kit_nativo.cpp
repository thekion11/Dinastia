// LA PINTURA DE LA CABEZA DEL JUGADOR (KitTextureFactory), EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»): `_caja_util`, `_color_dominante`,
// `_retenir` y `_paint_barba` (visor/kit_texture_factory.gd, octubre). Copia operación a operación sobre los bytes de la imagen (RGBA8 o RGB8), con las conversiones de
// `Image.get_pixel` / `set_pixel` del motor y la cuenta en 64 bits (el `float` de GDScript). Gemelas GDScript: `_caja_util_gd`, `_color_dominante_gd`, `_retenir_gd`, `_paint_barba_gd`.
// `pruebas/probar_nativo_kit.gd` compara los resultados. Con un formato que no sea RGBA8/RGB8 devuelven la señal «no soportado» y GDScript sigue por su camino.
#include "dinastia_nativo.h"
#include "img_nativo.h"

#include <godot_cpp/variant/rect2i.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>
#include <vector>

using namespace godot;

namespace {
// Una vista de solo lectura de los bytes de una imagen RGB8/RGBA8 (como `Image.get_pixel`).
struct Vista {
	PackedByteArray datos;
	int64_t w = 0, h = 0;
	int bpp = 0;
	bool ok = false;
	explicit Vista(const Ref<Image> &img) {
		if (img.is_null()) {
			return;
		}
		const Image::Format f = img->get_format();
		bpp = f == Image::FORMAT_RGBA8 ? 4 : (f == Image::FORMAT_RGB8 ? 3 : 0);
		if (bpp == 0) {
			return;
		}
		w = img->get_width();
		h = img->get_height();
		datos = img->get_data();
		ok = datos.size() >= w * h * bpp;
	}
	Color px(int64_t x, int64_t y) const {
		const uint8_t *q = datos.ptr() + (y * w + x) * bpp;
		return Color(float(double(q[0]) / 255.0), float(double(q[1]) / 255.0), float(double(q[2]) / 255.0), bpp == 4 ? float(double(q[3]) / 255.0) : 1.0f);
	}
};
}  // namespace

// `KitTextureFactory._caja_util`: la caja del dibujo (descartando el fondo de la esquina). Rect2i(0, 0, -1, -1) = formato no soportado.
Rect2i DinastiaNativo::kit_caja_util(const Ref<Image> &img) const {
	const Vista v(img);
	if (!v.ok || v.w < 2 || v.h < 2) {
		return Rect2i(0, 0, -1, -1);
	}
	const int64_t w = v.w, h = v.h;
	const Color fondo = v.px(1, 1);
	int64_t x0 = w, y0 = h, x1 = 0, y1 = 0;
	for (int64_t y = 0; y < h; y += 2) {
		for (int64_t x = 0; x < w; x += 2) {
			const Color p = v.px(x, y);
			if (double(p.a) < 0.35) {
				continue;
			}
			if (std::fabs(double(p.r) - double(fondo.r)) + std::fabs(double(p.g) - double(fondo.g)) + std::fabs(double(p.b) - double(fondo.b)) < 0.16) {
				continue;
			}
			x0 = x < x0 ? x : x0;
			y0 = y < y0 ? y : y0;
			x1 = x > x1 ? x : x1;
			y1 = y > y1 ? y : y1;
		}
	}
	if (x1 <= x0 || y1 <= y0) {
		return Rect2i(0, 0, int32_t(w), int32_t(h));
	}
	return Rect2i(int32_t(x0), int32_t(y0), int32_t(x1 - x0), int32_t(y1 - y0));
}

// `KitTextureFactory._color_dominante`: el color más repetido de una zona (cubos de 8×8×8). Color con alfa 0 y r = -1 = formato no soportado.
Color DinastiaNativo::kit_color_dominante(const Ref<Image> &img, const Rect2i &r) const {
	const Vista v(img);
	if (!v.ok) {
		return Color(-1, 0, 0, 0);
	}
	std::vector<int> cubos(512, 0);
	int mejor = 0;
	int mejor_k = -1;
	const int64_t ya = r.position.y + 16, yb = r.position.y + r.size.y - 16;
	const int64_t xa = r.position.x + 10, xb = r.position.x + r.size.x - 10;
	for (int64_t y = ya; y < yb; y += 5) {
		for (int64_t x = xa; x < xb; x += 5) {
			const Color p = v.px(x, y);
			const int k = (int(double(p.r) * 7.99) << 6) | (int(double(p.g) * 7.99) << 3) | int(double(p.b) * 7.99);
			const int n = ++cubos[k];
			if (n > mejor) {
				mejor = n;
				mejor_k = k;
			}
		}
	}
	if (mejor_k < 0) {
		return Color(0.2f, 0.2f, 0.2f);
	}
	Vector3 acc;
	int n2 = 0;
	for (int64_t y = ya; y < yb; y += 5) {
		for (int64_t x = xa; x < xb; x += 5) {
			const Color p = v.px(x, y);
			const int k = (int(double(p.r) * 7.99) << 6) | (int(double(p.g) * 7.99) << 3) | int(double(p.b) * 7.99);
			if (k == mejor_k) {
				acc += Vector3(p.r, p.g, p.b);
				n2++;
			}
		}
	}
	if (n2 == 0) {
		return Color(0.2f, 0.2f, 0.2f);
	}
	acc /= real_t(double(n2));
	return Color(acc.x, acc.y, acc.z);
}

// `KitTextureFactory._retenir` (el bucle): los bytes RGBA8 con la piel y el pelo vueltos a teñir en las zonas dadas (la última, de las manos, todo a piel).
PackedByteArray DinastiaNativo::kit_retener(const PackedByteArray &datos_in, int64_t w, int64_t h, const Color &piel, const Color &pelo, double lum_piel, double lum_pelo, const Rect2i &cabeza, const Rect2i &manos) const {
	PackedByteArray datos = datos_in;
	uint8_t *d = datos.ptrw();
	const Rect2i zonas[2] = { cabeza, manos };
	for (int zi = 0; zi < 2; zi++) {
		const Rect2i r = zonas[zi];
		const bool todo_piel = zi == 1;
		const int64_t ye = r.position.y + r.size.y < h ? r.position.y + r.size.y : h;
		const int64_t xe = r.position.x + r.size.x < w ? r.position.x + r.size.x : w;
		for (int64_t y = r.position.y; y < ye; y++) {
			const int64_t fila = y * w;
			for (int64_t x = r.position.x; x < xe; x++) {
				const int64_t i = (fila + x) * 4;
				if (d[i + 3] < 40) {
					continue;
				}
				const double cr = double(d[i]) / 255.0;
				const double cg = double(d[i + 1]) / 255.0;
				const double cb = double(d[i + 2]) / 255.0;
				const double l = 0.2126 * cr + 0.7152 * cg + 0.0722 * cb;
				const double mx = cr > (cg > cb ? cg : cb) ? cr : (cg > cb ? cg : cb);
				const double mn = cr < (cg < cb ? cg : cb) ? cr : (cg < cb ? cg : cb);
				const double sat = mx <= 0.0 ? 0.0 : (mx - mn) / mx;
				Color destino;
				double ref;
				if (todo_piel) {
					destino = piel;
					ref = lum_piel;
				} else if (l > 0.40 && sat < 0.62) {
					destino = piel;
					ref = lum_piel;
				} else if (l < 0.36 && sat > 0.30) {
					destino = pelo;
					ref = lum_pelo;
				} else {
					continue;
				}
				double k = l / ref;
				k = k < 0.42 ? 0.42 : (k > 1.55 ? 1.55 : k);
				const double cs[3] = { double(destino.r), double(destino.g), double(destino.b) };
				for (int c = 0; c < 3; c++) {
					double q = cs[c] * k;
					q = q < 0.0 ? 0.0 : (q > 1.0 ? 1.0 : q);
					d[i + c] = uint8_t(int(q * 255.0));
				}
			}
		}
	}
	return datos;
}

// `KitTextureFactory._paint_barba` (el bucle): los bytes RGBA8 de `img` con la sombra de barba. Devuelve la imagen cambiada, o null si no es RGBA8.
Ref<Image> DinastiaNativo::kit_barba(const Ref<Image> &img, const Color &pelo, int64_t barba, const Rect2i &rect) const {
	Ref<Image> nada;
	if (img.is_null() || img->get_format() != Image::FORMAT_RGBA8) {
		return nada;
	}
	const int64_t w = img->get_width();
	PackedByteArray datos = img->get_data();
	uint8_t *d = datos.ptrw();
	const double fuerza_d = 0.22 + double(barba) * 0.09;
	const double fuerza = fuerza_d < 0.22 ? 0.22 : (fuerza_d > 0.72 ? 0.72 : fuerza_d);
	const int64_t alto = barba >= 4 ? rect.size.y : int64_t(double(rect.size.y) * 0.72);
	for (int64_t y = rect.position.y; y < rect.position.y + alto; y++) {
		for (int64_t x = rect.position.x; x < rect.position.x + rect.size.x; x++) {
			uint8_t *q = d + (y * w + x) * 4;
			const Color p(float(double(q[0]) / 255.0), float(double(q[1]) / 255.0), float(double(q[2]) / 255.0), float(double(q[3]) / 255.0));
			if (double(p.a) < 0.2) {
				continue;
			}
			const Color c = p.lerp(pelo, float(fuerza));
			q[0] = LienzoRGB::a_byte(c.r);
			q[1] = LienzoRGB::a_byte(c.g);
			q[2] = LienzoRGB::a_byte(c.b);
			q[3] = LienzoRGB::a_byte(c.a);
		}
	}
	return Image::create_from_data(w, img->get_height(), false, Image::FORMAT_RGBA8, datos);
}
