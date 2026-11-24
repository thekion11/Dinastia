// LAS TEXTURAS DE GRADA, EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»). `StadiumBuilder._make_stand_texture_calc` y `_make_stand_texture_tramos`
// (visor/stadium_builder_p4.gd, septiembre): el patrón de asientos con los colores del club (franjas, aros, damero, degradé…), el grano por butaca y el público encima (el núcleo está en
// `publico_nativo.cpp`). Operación a operación, con el azar del motor (PCG32 copiado). Devuelven la imagen RGB8 de 96×320 SIN mipmaps (los genera GDScript). Gemelas `_make_stand_texture_gd`
// (la imagen de la primera) y `_make_stand_texture_tramos_gd`. `pruebas/probar_nativo_publico.gd` compara los bytes.
#include "dinastia_nativo.h"
#include "img_nativo.h"
#include "pcg32_nativo.h"
#include "publico_nativo.h"

#include <cmath>

using namespace godot;

namespace {
constexpr double TAU_GD = 6.2831853071795864769252867666;

inline int codigo_patron(const String &p) {
	if (p == "franjas" || p == "vertical3") return 1;
	if (p == "aros") return 2;
	if (p == "damero") return 3;
	if (p == "degrade") return 4;
	if (p == "bicolor") return 5;
	if (p == "diagonal") return 6;
	if (p == "moteado") return 7;
	if (p == "sectores" || p == "mosaico") return 8;
	if (p == "ola") return 9;
	if (p == "bandera") return 10;
	return 0;
}

// El color de un texel: `s` = posición a lo largo (global o dentro del tercio), `r` = subiendo la rampa.
inline Color color_patron(int cod, double s, double r, const Color &a1, const Color &a2, const Color &a3) {
	switch (cod) {
		case 1: return int64_t(s * 8.0) % 2 == 0 ? a1 : a2;
		case 2: return int64_t(r * 5.0) % 2 == 0 ? a1 : a2;
		case 3: return (int64_t(s * 8.0) + int64_t(r * 5.0)) % 2 == 0 ? a1 : a2;
		case 4: return a1.lerp(a2, float(r));
		case 5: return s < 0.5 ? a1 : a2;
		case 6: return int64_t((s + r) * 8.0) % 2 == 0 ? a1 : a2;
		case 7: return int64_t(s * 40.0 + r * 13.0) % 5 == 0 ? a2 : a1;
		case 8: {
			const int64_t i = int64_t(s * 3.0) % 3;
			return i == 0 ? a1 : (i == 1 ? a2 : a3);
		}
		case 9: return a1.lerp(a2, float(0.5 + 0.5 * std::sin(s * TAU_GD * 2.0)));
		case 10: {
			const int64_t i = int64_t(r * 3.0) % 3;
			return i == 0 ? a1 : (i == 1 ? a2 : a3);
		}
		default: return a1;
	}
}

// El grano por butaca (`rng.randf() - 0.5) * 0.05`) sumado a cada canal, acotado.
inline Color con_grano(const Color &col, Pcg32 &rng) {
	const double grano = (double(rng.randf()) - 0.5) * 0.05;
	auto c = [grano](float v) {
		double q = double(v) + grano;
		q = q < 0.0 ? 0.0 : (q > 1.0 ? 1.0 : q);
		return float(q);
	};
	return Color(c(col.r), c(col.g), c(col.b));
}
}  // namespace

Ref<Image> DinastiaNativo::grada_imagen(const String &patron, const Color &a1, const Color &a2, const Color &a3, int64_t semilla, double lleno) const {
	const int64_t w = 96, h = 320;
	LienzoRGB img(w, h);
	Pcg32 rng;
	rng.seed(uint64_t(semilla));
	const int cod = codigo_patron(patron);
	for (int64_t y = 0; y < h; y++) {
		for (int64_t x = 0; x < w; x++) {
			const double r = double(x) / double(w);
			const double s = double(y) / double(h);
			img.poner(x, y, con_grano(color_patron(cod, s, r, a1, a2, a3), rng));
		}
	}
	pintar_publico_interno(img, w, h, a1, a2, lleno, rng);
	return img.imagen();
}

Ref<Image> DinastiaNativo::grada_tramos(const Array &patrones, const Array &colores, int64_t semilla, double lleno) const {
	const int64_t w = 96, h = 320;
	LienzoRGB img(w, h);
	Pcg32 rng;
	rng.seed(uint64_t(semilla));
	for (int64_t y = 0; y < h; y++) {
		const double s = double(y) / double(h);
		int64_t tercio = int64_t(s * 3.0);
		tercio = tercio < 0 ? 0 : (tercio > 2 ? 2 : tercio);
		const String patron = tercio < patrones.size() ? String(patrones[tercio]) : String("franjas");
		Color a1 = Color(1, 1, 1), a2 = Color(0, 0, 0), a3 = Color(190.0f / 255.0f, 190.0f / 255.0f, 190.0f / 255.0f);   // Color.GRAY (0xBEBEBE)
		if (tercio < colores.size()) {
			const Array trio = colores[tercio];
			a1 = trio[0];
			a2 = trio[1];
			a3 = trio.size() > 2 ? Color(trio[2]) : a1;
		}
		const double s_local = std::fmod(s * 3.0, 1.0);
		const int cod = codigo_patron(patron);
		for (int64_t x = 0; x < w; x++) {
			const double r = double(x) / double(w);
			img.poner(x, y, con_grano(color_patron(cod, s_local, r, a1, a2, a3), rng));
		}
	}
	const Array trio_c = colores.size() > 1 ? Array(colores[1]) : Array(colores[0]);
	pintar_publico_interno(img, w, h, Color(trio_c[0]), Color(trio_c[1]), lleno, rng);
	return img.imagen();
}
