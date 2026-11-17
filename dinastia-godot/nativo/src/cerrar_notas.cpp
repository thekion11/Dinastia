// `Partido._cerrar_notas()` en C++ (10-11-2026, paso a C++, orden 35): la nota final de cada jugador del cruce (la de la IA que nadie mira) con las MISMAS cuentas y el MISMO orden de tiradas de azar
// (una `randf()` por jugador, en el orden de `_todos`, sobre el mismo generador `Azar._rng`). Solo lee y escribe propiedades (también lo de `Jugador.anotar_nota`: añadir a `notas` y quedarse con las 8 últimas).
#include "dinastia_nativo.h"

#include <godot_cpp/classes/random_number_generator.hpp>
#include <godot_cpp/variant/string_name.hpp>

#include <cmath>

using namespace godot;

void DinastiaNativo::cerrar_notas(Object *p, const Ref<RandomNumberGenerator> &rng) const {
	static const StringName k_todos("_todos"), k_ol("once_local"), k_ov("once_visita"), k_local("local"), k_plantilla("plantilla"), k_notas("_notas"), k_gl("goles_local"), k_gv("goles_visita");
	static const StringName k_id("id"), k_forma("forma"), k_partidos("partidos"), k_cerradas("_notas_cerradas"), k_lista("notas");
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
		{ // `Jugador.anotar_nota(n)` (16-11: aquí mismo, sin volver a GDScript por cada jugador)
			Array lista = j->get(k_lista);
			lista.push_back(n);
			if (lista.size() > 8) {
				lista.remove_at(0);
			}
		}
		const double forma = double(int64_t(j->get(k_forma)));
		int64_t f = int64_t(std::round(forma * 0.7 + n * 10.0 * 0.3));
		f = f < 20 ? 20 : (f > 99 ? 99 : f);
		j->set(k_forma, f);
		j->set(k_partidos, int64_t(j->get(k_partidos)) + 1);
	}
}

// `LeyesPais._ya_cumple` (nucleo/leyes_pais.gd, 16-11-2026): ¿el once ya cumple el tope de cupo en cancha y los juveniles que pide la liga? Con `ocupa_cupo`
// copiado tal cual (pasaporte del país o comunitario, y los criterios «extranjero», «no_ue» y «no_formado»). `clubes` ya resuelto (si venía vacío, `clubes_mundo`).
bool DinastiaNativo::leyes_ya_cumple(const Array &once, const String &pais, int64_t tope, const Array &juveniles, const String &criterio, const Array &ue, const Dictionary &clubes) const {
	static const StringName k_look("look"), k_pais("pais"), k_formacion("club_formacion"), k_edad("edad");
	static const Variant v_pasaporte(String("pasaporte"));
	const bool pais_ue = ue.has(pais);
	if (tope > 0) {
		int64_t n = 0;
		for (int64_t i = 0; i < once.size(); i++) {
			Object *j = once[i];
			if (j == nullptr) {
				continue; // `ocupa_cupo(null)` = false
			}
			const Dictionary look = j->get(k_look);
			const String pas = look.get(v_pasaporte, "");
			if (pas != "" && (pas == pais || (ue.has(pas) && pais_ue && criterio == "no_ue"))) {
				continue;
			}
			const String jp = j->get(k_pais);
			bool ocupa;
			if (criterio == "no_ue") {
				ocupa = jp != pais && !(ue.has(jp) && pais_ue);
			} else if (criterio == "no_formado") {
				if (jp == pais) {
					ocupa = false;
				} else {
					const Variant cf = clubes.get(j->get(k_formacion), Variant());
					Object *club = cf.get_type() == Variant::OBJECT ? static_cast<Object *>(cf) : nullptr;
					ocupa = !(club != nullptr && String(club->get(k_pais)) == pais);
				}
			} else {
				ocupa = jp != pais;
			}
			if (ocupa) {
				n += 1;
			}
		}
		if (n > tope) {
			return false;
		}
	}
	for (int64_t q = 0; q < juveniles.size(); q++) {
		const int64_t edad = juveniles[q];
		bool hay = false;
		for (int64_t i = 0; i < once.size(); i++) {
			Object *j = once[i];
			if (j != nullptr && int64_t(j->get(k_edad)) <= edad) {
				hay = true;
				break;
			}
		}
		if (!hay) {
			return false;
		}
	}
	return true;
}
