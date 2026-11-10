// `Partido._cerrar_notas()` en C++ (10-11-2026, paso a C++, orden 35): la nota final de cada jugador del cruce (la de la IA que nadie mira) con las MISMAS cuentas y el MISMO orden de tiradas de azar
// (una `randf()` por jugador, en el orden de `_todos`, sobre el mismo generador `Azar._rng`). Solo lee y escribe propiedades; `Jugador.anotar_nota` se llama tal cual (es de GDScript).
#include "dinastia_nativo.h"

#include <godot_cpp/classes/random_number_generator.hpp>
#include <godot_cpp/variant/string_name.hpp>

#include <cmath>

using namespace godot;

void DinastiaNativo::cerrar_notas(Object *p, const Ref<RandomNumberGenerator> &rng) const {
	static const StringName k_todos("_todos"), k_ol("once_local"), k_ov("once_visita"), k_local("local"), k_plantilla("plantilla"), k_notas("_notas"), k_gl("goles_local"), k_gv("goles_visita");
	static const StringName k_id("id"), k_forma("forma"), k_partidos("partidos"), k_anotar("anotar_nota"), k_cerradas("_notas_cerradas");
	p->set(k_cerradas, true);
	const int64_t gl = p->get(k_gl);
	const int64_t gv = p->get(k_gv);
	const bool gano_local = gl > gv;
	const bool empate = gl == gv;
	const Array todos = p->get(k_todos);
	const Array once_l = p->get(k_ol);
	const Array once_v = p->get(k_ov);
	Dictionary notas = p->get(k_notas);
	Array plantilla_local;
	bool plantilla_leida = false;
	for (int64_t i = 0; i < todos.size(); i++) {
		Object *j = todos[i];
		// `es_del_local(j)`: once_local.has(j) or (not once_visita.has(j) and local.plantilla.has(j))
		bool suyo = once_l.has(todos[i]);
		if (!suyo && !once_v.has(todos[i])) {
			if (!plantilla_leida) {
				Object *loc = p->get(k_local);
				plantilla_local = loc->get(k_plantilla);
				plantilla_leida = true;
			}
			suyo = plantilla_local.has(todos[i]);
		}
		double bono = 0.0;
		if (!empate) {
			bono = (gano_local == suyo) ? 0.6 : -0.6;
		}
		const Variant id = j->get(k_id);
		const double base = double(notas.get(id, 6.0));
		const double azar = double(rng->randf());
		double n = base + bono + azar * 1.4 - 0.7;
		n = n < 3.0 ? 3.0 : (n > 10.0 ? 10.0 : n);
		n = std::round(n * 10.0) / 10.0;
		j->call(k_anotar, n);
		const double forma = double(int64_t(j->get(k_forma)));
		int64_t f = int64_t(std::round(forma * 0.7 + n * 10.0 * 0.3));
		f = f < 20 ? 20 : (f > 99 ? 99 : f);
		j->set(k_forma, f);
		j->set(k_partidos, int64_t(j->get(k_partidos)) + 1);
	}
}
