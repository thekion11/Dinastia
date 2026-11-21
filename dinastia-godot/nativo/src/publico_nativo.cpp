// EL PÚBLICO DE LA TEXTURA DE GRADA, EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»). `StadiumBuilder._pintar_publico` (visor/stadium_builder_p4.gd, 23-9-2026):
// las filas alineadas de hinchas, el escalón oscuro entre filas y las escaleras de hormigón, con el azar del motor. Operación a operación sobre los bytes RGB8. El generador `rng` de
// GDScript sigue con la MISMA secuencia: se toma su estado (`RandomNumberGenerator.state`, el PCG32 del motor), se avanza aquí y se le devuelve. Gemela GDScript: `_pintar_publico_gd`.
// `pruebas/probar_nativo_publico.gd` compara los bytes y el estado final del generador.
#include "dinastia_nativo.h"
#include "img_nativo.h"
#include "pcg32_nativo.h"
#include "publico_nativo.h"

#include <godot_cpp/classes/random_number_generator.hpp>

#include <cmath>

using namespace godot;

// El núcleo (compartido con las texturas de grada, `grada_nativo.cpp`): pinta el público sobre `lz` con el generador `rng`.
void godot::pintar_publico_interno(LienzoRGB &lz, int64_t w, int64_t h, const Color &a1, const Color &a2, double lleno, Pcg32 &rng) {
	const Color piel[4] = { Color(0.95f, 0.78f, 0.62f), Color(0.80f, 0.60f, 0.42f), Color(0.55f, 0.38f, 0.26f), Color(0.36f, 0.24f, 0.17f) };
	const Color ropa[6] = { Color(0.85f, 0.85f, 0.88f), Color(0.15f, 0.16f, 0.2f), a1, a2, Color(0.7f, 0.2f, 0.2f), Color(0.2f, 0.3f, 0.7f) };
	const double r_alto = std::round(0.5 / (20.0 / double(h)));
	const int64_t alto_persona = int64_t(r_alto) > 2 ? int64_t(r_alto) : 2;
	const int64_t piel_persona = alto_persona / 3 > 1 ? alto_persona / 3 : 1;
	const double r_paso = std::round(double(w) * 0.85 / 21.0);
	const int64_t paso_fila = int64_t(r_paso) > 3 ? int64_t(r_paso) : 3;
	const double lleno_c = lleno < 0.0 ? 0.0 : (lleno > 1.0 ? 1.0 : lleno);
	const int64_t escaleras[2] = { int64_t(double(h) * 0.31), int64_t(double(h) * 0.78) };
	const int64_t ancho_escalera = alto_persona / 3 > 2 ? alto_persona / 3 : 2;
	for (int64_t fila = 0; fila < w / paso_fila; fila++) {
		const int64_t x0 = fila * paso_fila;
		for (int64_t y = 0; y < h; y++) {
			lz.poner(x0, y, lz.leer(x0, y).darkened(0.42f));
		}
		int64_t y_asiento = rng.randi_range(0, int32_t(alto_persona - 1));
		while (y_asiento < h) {
			bool en_escalera = false;
			for (int e = 0; e < 2; e++) {
				const int64_t d = y_asiento - escaleras[e];
				if ((d < 0 ? -d : d) < ancho_escalera + alto_persona / 2) {
					en_escalera = true;
					break;
				}
			}
			if (!en_escalera && double(rng.randf()) < lleno_c) {
				const Color col_ropa = ropa[rng.randi_range(0, 5)];
				const Color col_piel = piel[rng.randi_range(0, 3)];
				for (int64_t dy = 0; dy < alto_persona - 1; dy++) {
					const int64_t yy = y_asiento + dy;
					if (yy >= h) {
						break;
					}
					const Color col = dy < piel_persona ? col_piel : col_ropa;
					const int64_t tope = paso_fila - 1 > 2 ? paso_fila - 1 : 2;
					for (int64_t dx = 1; dx < tope; dx++) {
						const int64_t xx = x0 + dx < w - 1 ? x0 + dx : w - 1;
						lz.poner(xx, yy, col);
					}
				}
			}
			y_asiento += alto_persona;
		}
	}
	const Color cemento(0.30f, 0.31f, 0.33f);
	for (int e = 0; e < 2; e++) {
		for (int64_t dy = 0; dy < ancho_escalera; dy++) {
			const int64_t yy = escaleras[e] + dy;
			if (yy >= h) {
				continue;
			}
			for (int64_t x = 0; x < w; x++) {
				lz.poner(x, yy, cemento.darkened(float(double(rng.randf()) * 0.10)));
			}
		}
	}
}

// Devuelve la imagen pintada (RGB8 de w×h), o null si `img` no es RGB8 de ese tamaño.
Ref<Image> DinastiaNativo::publico_pintar(const Ref<Image> &img, int64_t w, int64_t h, const Color &a1, const Color &a2, double lleno, const Ref<RandomNumberGenerator> &rng_gd) const {
	Ref<Image> nada;
	if (img.is_null() || rng_gd.is_null() || img->get_format() != Image::FORMAT_RGB8 || img->has_mipmaps() || img->get_width() != w || img->get_height() != h || w < 1 || h < 1) {
		return nada;
	}
	LienzoRGB lz(w, h);
	lz.datos = img->get_data();
	Pcg32 rng;
	rng.state = uint64_t(rng_gd->get_state());
	rng.inc = (1442695040888963407ULL << 1u) | 1u;
	pintar_publico_interno(lz, w, h, a1, a2, lleno, rng);
	rng_gd->set_state(int64_t(rng.state));
	return lz.imagen();
}
