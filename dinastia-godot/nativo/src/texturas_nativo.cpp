// TEXTURAS PROCEDIMENTALES EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»), con su gemela GDScript cada una:
//   telon_imagen      = `TelonesPintados._imagen` y sus pasos (`_rayas`, `_bandas`, `_diagonal`, `_cuadros`, `_letras`, `_desgaste`, `_transponer`), 15-11,
//   azulejo_imagenes  = las dos imágenes de `VestuarioRealista.azulejo`,
//   cesped_imagen     = `CespedTextura.nueva` (las franjas, el damero y los círculos del corte del césped).
// Operación a operación (doble precisión donde GDScript usa `float`; Color en float de 32), el azar del motor con el PCG32 copiado. `pruebas/probar_nativo_texturas.gd` compara los bytes.
#include "dinastia_nativo.h"
#include "img_nativo.h"
#include "pcg32_nativo.h"

#include <godot_cpp/variant/vector2.hpp>

#include <cmath>

using namespace godot;

namespace {
constexpr int64_t TANCHO = 256;
constexpr int64_t TALTO = 96;

// `fposmod` de GDScript (Math::fposmod).
inline double fposmod_gd(double x, double y) {
	double v = std::fmod(x, y);
	if ((v < 0 && y > 0) || (v > 0 && y < 0)) {
		v += y;
	}
	v += 0.0;
	return v;
}
}  // namespace

Ref<Image> DinastiaNativo::telon_imagen(const Color &c1_in, const Color &c2, int64_t p, bool girado) const {
	Color c1 = c1_in;
	LienzoRGB img(TANCHO, TALTO);
	// Contraste mínimo.
	Color claro = c2;
	if (std::fabs(double(c2.get_luminance()) - double(c1.get_luminance())) <= 0.25) {
		if (double(c1.get_luminance()) > 0.5) {
			claro = c1;
			c1 = Color(0.07f, 0.07f, 0.08f);
		} else {
			claro = c1.lightened(0.75f);
		}
	}
	const Color a = c1, b = claro;
	switch (p) {
		case 0:  // _rayas (verticales)
			for (int64_t x = 0; x < TANCHO; x++) {
				for (int64_t y = 0; y < TALTO; y++) {
					img.poner(x, y, (x / 24) % 2 == 0 ? a : b);
				}
			}
			break;
		case 1:  // _bandas
			for (int64_t y = 0; y < TALTO; y++) {
				const Color c = (y >= TALTO / 3 && y < 2 * TALTO / 3) ? a : b;
				for (int64_t x = 0; x < TANCHO; x++) {
					img.poner(x, y, c);
				}
			}
			break;
		case 2:  // _diagonal
			for (int64_t x = 0; x < TANCHO; x++) {
				for (int64_t y = 0; y < TALTO; y++) {
					const double d = double(x) - double(y) * (double(TANCHO) / double(TALTO)) * 0.6;
					img.poner(x, y, std::fabs(d - 60.0) < 34.0 ? a : b);
				}
			}
			break;
		case 3:  // _cuadros
			for (int64_t x = 0; x < TANCHO; x++) {
				for (int64_t y = 0; y < TALTO; y++) {
					img.poner(x, y, ((x / 32) + (y / 32)) % 2 == 0 ? a : b);
				}
			}
			break;
		default: {  // _letras
			img.llenar(b);
			img.rellenar(0, 0, TANCHO, 12, a);
			img.rellenar(0, TALTO - 12, TANCHO, 12, a);
			Pcg32 rng;
			rng.seed(uint64_t(int64_t(a.to_rgba32()) ^ 0x5bd1));
			int64_t x = 14;
			while (x < TANCHO - 26) {
				const int64_t w = rng.randi_range(14, 22);
				const int64_t y0 = 24;
				const int64_t h = TALTO - 48;
				img.rellenar(x, y0, 5, h, a);
				switch (rng.randi_range(0, 3)) {
					case 0:
						img.rellenar(x, y0, w, 5, a);
						img.rellenar(x, y0 + h / 2, w - 4, 5, a);
						break;
					case 1:
						img.rellenar(x + w - 5, y0, 5, h, a);
						img.rellenar(x, y0 + h / 2, w, 5, a);
						break;
					case 2:
						img.rellenar(x, y0, w, 5, a);
						img.rellenar(x, y0 + h - 5, w, 5, a);
						break;
					default:
						img.rellenar(x, y0 + h - 5, w, 5, a);
						break;
				}
				x += w + rng.randi_range(6, 10);
				if (double(rng.randf()) < 0.2) {
					x += 12;
				}
			}
			break;
		}
	}
	// _desgaste: manchas de pintura y suciedad.
	for (int64_t bx = 0; bx < TANCHO; bx += 8) {
		for (int64_t by = 0; by < TALTO; by += 8) {
			const double f = 1.0 + 0.06 * (fposmod_gd(std::sin(double(bx) * 12.99 + double(by) * 78.23) * 43758.55, 2.0) - 1.0);
			const int64_t xe = bx + 8 < TANCHO ? bx + 8 : TANCHO;
			const int64_t ye = by + 8 < TALTO ? by + 8 : TALTO;
			for (int64_t x = bx; x < xe; x++) {
				for (int64_t y = by; y < ye; y++) {
					const Color c = img.leer(x, y);
					img.poner(x, y, Color(float(double(c.r) * f), float(double(c.g) * f), float(double(c.b) * f)));
				}
			}
		}
	}
	if (girado) {
		LienzoRGB t(TALTO, TANCHO);
		for (int64_t x = 0; x < TANCHO; x++) {
			for (int64_t y = 0; y < TALTO; y++) {
				t.poner(y, x, img.leer(x, y));
			}
		}
		return t.imagen();
	}
	return img.imagen();
}

// Las dos imágenes del azulejo: [albedo, normal] de n×n.
Array DinastiaNativo::azulejo_imagenes(int64_t n) const {
	LienzoRGB alb(n, n), nor(n, n);
	Pcg32 rng;
	rng.seed(77);
	const int64_t paso = 128;
	for (int64_t y = 0; y < n; y++) {
		for (int64_t x = 0; x < n; x++) {
			const int64_t gx = x % paso;
			const int64_t gy = y % paso;
			const bool junta = gx < 3 || gy < 3;
			double v = 0.93 + (double(rng.randf()) - 0.5) * 0.03;
			if (junta) {
				v = 0.62;
			}
			alb.poner(x, y, Color(float(v), float(v), float(v * 1.01)));
			double nx = 0.5;
			double ny = 0.5;
			if (gx < 3) {
				nx = 0.5 + (gx < 1 ? 0.28 : -0.0);
			}
			if (gy < 3) {
				ny = 0.5 + (gy < 1 ? 0.28 : -0.0);
			}
			nor.poner(x, y, Color(float(nx), float(ny), 1.0f));
		}
	}
	Array res;
	res.push_back(alb.imagen());
	res.push_back(nor.imagen());
	return res;
}

// `CespedTextura.nueva`: 256×256.
Ref<Image> DinastiaNativo::cesped_imagen(const String &patron, const Color &claro, const Color &oscuro) const {
	const int64_t n = 256;
	LienzoRGB img(n, n);
	// El caso de cada patrón (0 = liso o desconocido, que pinta aparte).
	int caso = 0;
	if (patron == "rayas") caso = 1;
	else if (patron == "rayasH") caso = 2;
	else if (patron == "damero") caso = 3;
	else if (patron == "damGrande") caso = 4;
	else if (patron == "circular" || patron == "circulos") caso = 5;
	else if (patron == "diagonal") caso = 6;
	else if (patron == "espiga") caso = 7;
	else if (patron == "cruz") caso = 8;
	else if (patron == "abanico") caso = 9;
	else if (patron == "rombos") caso = 10;
	else if (patron == "mitades") caso = 11;
	for (int64_t y = 0; y < n; y++) {
		for (int64_t x = 0; x < n; x++) {
			const double u = double(x) / double(n);
			const double v = double(y) / double(n);
			int64_t band = 0;
			switch (caso) {
				case 1: band = int64_t(v * 16.0); break;
				case 2: band = int64_t(u * 14.0); break;
				case 3: band = int64_t(u * 10.0) + int64_t(v * 10.0); break;
				case 4: band = int64_t(u * 5.0) + int64_t(v * 5.0); break;
				case 5: band = int64_t(double(Vector2(float(u - 0.5), float(v - 0.5)).length()) * 16.0); break;
				case 6: band = int64_t((u + v) * 10.0); break;
				case 7: band = int64_t((u + std::fmod(v * 6.0, 1.0)) * 8.0); break;
				case 8: band = (std::fabs(u - 0.5) < 0.12 || std::fabs(v - 0.5) < 0.12) ? 1 : 0; break;
				case 9: band = int64_t(std::atan2(v - 0.5, u - 0.5) * 6.0); break;
				case 10: band = int64_t((std::fabs(u - 0.5) + std::fabs(v - 0.5)) * 14.0); break;
				case 11: {
					const Color lado = v < 0.5 ? claro : oscuro;
					const Color otro = v < 0.5 ? oscuro : claro;
					img.poner(x, y, int64_t(v * 16.0) % 2 == 1 ? lado.lerp(otro, 0.3f) : lado);
					continue;
				}
				default: {
					band = int64_t(v * 16.0);
					img.poner(x, y, band % 2 == 0 ? oscuro.lerp(claro, 0.3f) : oscuro);
					continue;
				}
			}
			img.poner(x, y, band % 2 == 0 ? claro : oscuro);
		}
	}
	return img.imagen();
}
