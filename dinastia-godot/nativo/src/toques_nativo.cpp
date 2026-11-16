// `LeagueToques.alcanza` (visor/league_toques.gd) EN C++ (16-11-2026, paso a C++): ¿alguna animación de un tipo toca el balón previsto? Traducción literal: Vector2 en 32 bits, el resto en double,
// mismo orden de clases de velocidad y de animaciones (la primera que toca antes gana; a igual cuadro, la primera). La gemela GDScript es `LeagueToques.alcanza_gd`.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>

using namespace godot;

Dictionary DinastiaNativo::league_alcanza(const Dictionary &por_tipo, double r0, double r1, double bono_vel, const Vector2 &pos, const Vector2 &mirada, double vel, const PackedVector3Array &pred) const {
	static const StringName k_cuadro("cuadro"), k_balon("balon"), k_nombre("nombre");
	static const char *ORDEN_VEL[4] = { "idle", "dribble", "walk", "sprint" };
	const Vector2 f = (double)mirada.length() > 0.0 ? mirada.normalized() : Vector2(1, 0);
	const Vector2 izq(-f.y, f.x);
	const int c = vel < 1.8 ? 0 : (vel < 4.4 ? 1 : (vel < 6.2 ? 2 : 3));
	const int64_t tam = pred.size();
	Dictionary mejor;
	int64_t mejor_cuadro = -1;
	const int orden[3] = { 0, -1, 1 };
	for (int i = 0; i < 3; i++) {
		const int k = c + orden[i];
		if (k < 0 || k > 3) {
			continue;
		}
		const Variant va = por_tipo.get(String(ORDEN_VEL[k]), Array());
		const Array lista = va;
		for (int64_t j = 0; j < lista.size(); j++) {
			const Dictionary a = lista[j];
			const int64_t cuadro = (int64_t)(double)a[k_cuadro];
			if (cuadro < 0 || cuadro >= tam) { // un cuadro negativo (que GDScript leería desde el final) no existe en el catálogo; aquí se salta en vez de leer fuera del arreglo
				continue;
			}
			if (!mejor.is_empty() && cuadro >= mejor_cuadro) {
				continue;
			}
			const Array bal = a[k_balon];
			if (bal.size() < 3) {
				continue;
			}
			const Vector3 b = pred[cuadro];
			double dz = std::fabs((double)b.z - (double)bal[2]);
			if ((double)b.z < 0.5) {
				const double m = dz - 0.15;
				dz = m > 0.0 ? m : 0.0;
			}
			if (dz >= 0.22) {
				continue;
			}
			const Vector2 punto = pos + f * (float)(-(double)bal[1]) + izq * (float)(double)bal[0];
			const double por_cuadro = std::pow((double)cuadro / 24.0, 0.7);
			const double radio = 0.3 * r0 * por_cuadro * (1.0 + 1.6 + bono_vel) + r1;
			if ((double)Vector2(b.x, b.y).distance_to(punto) < radio) {
				mejor = Dictionary();
				mejor[String("anim")] = a[k_nombre]; // claves String (no StringName): igual que el literal de GDScript, también al serializar
				mejor[String("ms")] = cuadro * 10;
				mejor[String("punto")] = punto;
				mejor_cuadro = cuadro;
			}
		}
	}
	return mejor;
}
