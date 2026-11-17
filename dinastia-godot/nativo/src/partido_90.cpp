// `Partido.simular_minuto()` x 90 para los cruces de la IA que nadie mira (10-11-2026, paso a C++). Ver nucleo/partido_rapido.gd: mismas llamadas al generador de azar, en el mismo orden, y los sucesos
// raros (gol, tarjeta, penal, lesión, cambio, plan del minuto 60) vuelven al GDScript original. El estado que lee C++ se guarda en variables locales y se vuelca al objeto antes de cada vuelta a GDScript.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/random_number_generator.hpp>
#include <godot_cpp/variant/string_name.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

#include "partido_90.h"

void DinastiaNativo::simular_90(Object *p, Object *ayuda, const Dictionary &cfg, const Ref<RandomNumberGenerator> &rng, bool azar_propio) const {
	static const StringName k_minuto("minuto"), k_term("terminado_ya"), k_fl("_fza_local"), k_fv("_fza_visita"), k_ata("ata"), k_def("def"), k_plan("_plan_aplicado");
	static const StringName k_rem_l("remates_local"), k_rem_v("remates_visita"), k_tp_l("tiros_puerta_local"), k_tp_v("tiros_puerta_visita"), k_xg_l("xg_local"), k_xg_v("xg_visita");
	static const StringName k_cor_l("corners_local"), k_cor_v("corners_visita"), k_fal_l("faltas_local"), k_fal_v("faltas_visita"), k_fue_l("fueras_local"), k_fue_v("fueras_visita");
	static const StringName k_pos("posesion_local"), k_ol("once_local"), k_ov("once_visita"), k_apo("_aportes"), k_local("local"), k_visita("visita"), k_id("id"), k_pos_e("pos_e");

	AzarNativo az;
	az.rng = rng;
	az.propio = azar_propio;
	az.entrar();
	Estado e;
	e.p = p;
	e.ayuda = ayuda;
	e.once_l = p->get(k_ol);
	e.once_v = p->get(k_ov);
	e.aportes = p->get(k_apo);
	e.club_l = p->get(k_local);
	e.club_v = p->get(k_visita);
	e.minuto = int64_t(p->get(k_minuto));
	e.rem_l = int64_t(p->get(k_rem_l));
	e.rem_v = int64_t(p->get(k_rem_v));
	e.tp_l = int64_t(p->get(k_tp_l));
	e.tp_v = int64_t(p->get(k_tp_v));
	e.xg_l = double(p->get(k_xg_l));
	e.xg_v = double(p->get(k_xg_v));
	e.cor_l = int64_t(p->get(k_cor_l));
	e.cor_v = int64_t(p->get(k_cor_v));
	e.fal_l = int64_t(p->get(k_fal_l));
	e.fal_v = int64_t(p->get(k_fal_v));
	e.fue_l = int64_t(p->get(k_fue_l));
	e.fue_v = int64_t(p->get(k_fue_v));
	e.posesion = double(p->get(k_pos));
	bool plan_aplicado = bool(p->get(k_plan));

	const double igual = cfg["igual"], base_ataque = cfg["base_ataque"], sensib = cfg["sensib"], satura = cfg["satura"];
	const double bono_l = cfg["bono_l"], bono_v = cfg["bono_v"], clima = cfg["clima"], clima_v = cfg["clima_v"];
	const bool ritmo0 = cfg["ritmo0"];
	const double pc_l = cfg["pc_l"], pc_v = cfg["pc_v"], pf_l = cfg["pf_l"], pf_v = cfg["pf_v"], pfuera = cfg["pfuera"];
	const double k = cfg["k"], conv = cfg["conv"], r_ataj = cfg["r_ataj"], r_poste = cfg["r_poste"];
	const double p_penal = cfg["p_penal"], f_var = cfg["f_var"], p_amarilla = cfg["p_amarilla"], p_lesion = cfg["p_lesion"];
	const String perfil = cfg["perfil"];
	const bool hay_arbitro = cfg["hay_arbitro"];
	const int64_t fin = int64_t(cfg["fin"]);
	const Dictionary grupo_de = cfg["grupo_de"];
	const Dictionary bases_gol = cfg["bases_gol"];
	const bool casero = perfil == String("casero");
	const int tipo_arb = !hay_arbitro ? 0 : (perfil == String("tarjetero") ? 1 : (casero ? 2 : (perfil == String("estricto") ? 3 : (perfil == String("figura") ? 4 : 0))));

	// `_probabilidad`: A4-PAR-L02, el cociente se satura en el logaritmo (funciones del motor, no de la libm de esta librería).
	auto probabilidad = [&](double ata, double def_rival) -> double {
		const double l = satura * UtilityFunctions::tanh(UtilityFunctions::log(maxf_gd(ata / maxf_gd(def_rival, 0.001), 0.001)) / satura);
		return base_ataque * igual * UtilityFunctions::exp(sensib * l);
	};
	// Lo que depende de la fuerza de los onces: se recalcula tras cada vuelta a GDScript (cambio, roja, plan).
	auto refrescar = [&]() {
		const Dictionary fl = p->get(k_fl);
		const Dictionary fv = p->get(k_fv);
		e.ata_l = fl[k_ata];
		e.def_l = fl[k_def];
		e.ata_v = fv[k_ata];
		e.def_v = fv[k_def];
		e.pl = probabilidad(e.ata_l, e.def_v) * bono_l * clima;
		e.pv = probabilidad(e.ata_v, e.def_l) * bono_v * clima * clima_v;
		e.terminado = bool(p->get(k_term));
	};
	// Los seis contadores que `_contar_penal` toca desde GDScript: se vuelcan antes y se releen después (el xG se suma en el mismo orden).
	auto volcar_penal = [&]() {
		p->set(k_rem_l, e.rem_l);
		p->set(k_rem_v, e.rem_v);
		p->set(k_tp_l, e.tp_l);
		p->set(k_tp_v, e.tp_v);
		p->set(k_xg_l, e.xg_l);
		p->set(k_xg_v, e.xg_v);
	};
	auto leer_penal = [&]() {
		e.rem_l = int64_t(p->get(k_rem_l));
		e.rem_v = int64_t(p->get(k_rem_v));
		e.tp_l = int64_t(p->get(k_tp_l));
		e.tp_v = int64_t(p->get(k_tp_v));
		e.xg_l = double(p->get(k_xg_l));
		e.xg_v = double(p->get(k_xg_v));
	};
	// `_aporte(j, v)`
	// `Partido._anotar` (nucleo/partido_p2.gd), 16-11-2026: el gol entero aquí, sin volver a GDScript (sin roles: lo garantiza `_puede`). El goleador sale de la misma
	// tirada de `Azar` (`az`) que daba `PartidoPonderado.goleador`; el asistente, de su generador propio sembrado con «id_minuto», como `asistente`. Las señales
	// (`marco_gol`, `gol`) se emiten con el azar del motor al día (`az.salir`), por si quien escucha tira dados.
	const Dictionary bases_asist = cfg["bases_asist"];
	static const StringName k_gl("goles_local"), k_gv("goles_visita"), k_pdl("peor_diferencia_local"), k_pdv("peor_diferencia_visita"), k_goles("goles"), k_asistencias("asistencias"), k_notas("_notas"),
			k_cronica("cronica"), k_momentum("momentum_eventos"), k_nombre("nombre"), k_marco("marco_gol"), k_gol("gol");
	auto anotar_gol = [&](Object *club, const Array &once, bool es_local) {
		Object *autor = nullptr;
		if (!once.is_empty()) {
			const int64_t i = elegir_ponderado(once, grupo_de, bases_gol, 0.02, "tir", PackedFloat64Array(), az.randf(), nullptr);
			if (i >= 0) {
				autor = once[i];
			}
		}
		az.salir();
		int64_t gl = int64_t(p->get(k_gl));
		int64_t gv = int64_t(p->get(k_gv));
		if (es_local) {
			gl += 1;
			p->set(k_gl, gl);
		} else {
			gv += 1;
			p->set(k_gv, gv);
		}
		p->set(k_pdl, std::min(int64_t(p->get(k_pdl)), gl - gv));
		p->set(k_pdv, std::min(int64_t(p->get(k_pdv)), gv - gl));
		Object *asistente = nullptr;
		if (autor != nullptr) {
			autor->set(k_goles, int64_t(autor->get(k_goles)) + 1); // `Jugador.anotar`
			autor->emit_signal(k_marco);
			Dictionary notas = p->get(k_notas);
			const Variant id = autor->get(k_id);
			const double nota = double(notas.get(id, 6.0)) + 1.1;
			notas[id] = nota < 10.0 ? nota : 10.0;
			Ref<RandomNumberGenerator> r2;
			r2.instantiate();
			r2->set_seed(uint64_t((String(id) + "_" + String::num_int64(e.minuto)).hash()));
			const int64_t ia = elegir_ponderado(once, grupo_de, bases_asist, 0.05, "pas", PackedFloat64Array(), r2->randf(), autor);
			if (ia >= 0) {
				asistente = once[ia];
				asistente->set(k_asistencias, int64_t(asistente->get(k_asistencias)) + 1); // (16-11, informe G-02) como `Partido._anotar`
			}
		}
		Array cronica = p->get(k_cronica);
		Dictionary d;
		d["min"] = e.minuto;
		d["tipo"] = "gol";
		d["club"] = club->get(k_id);
		d["autor"] = autor != nullptr ? autor->get(k_nombre) : Variant(String("?"));
		cronica.push_back(d);
		Array mom = p->get(k_momentum); // `_momentum_push(2, es_local)`
		mom.push_back(es_local ? 2 : -2);
		if (mom.size() > 12) {
			mom.remove_at(0);
		}
		p->emit_signal(k_gol, club, autor != nullptr ? Variant(autor) : Variant(), e.minuto, asistente != nullptr ? Variant(asistente) : Variant());
		az.entrar();
	};

	// `PartidoRapido.hit_amarilla` + `Partido._amonestar` (16-11-2026), con el generador del motor (se llama tras `az.salir`): el camino de siempre de una
	// amarilla que no es la segunda del partido. La segunda (que puede ser roja: sanción, fuera del once, `_revisar_siete`) la hace GDScript (`_amonestar`) y la
	// que completa el ciclo de amarillas, `PartidoRapido.hit_acumula` (`Disciplina`). Devuelve true si el once y la fuerza no cambiaron.
	const int64_t ciclo_amarillas = int64_t(cfg["ciclo_amarillas"]);
	static const StringName k_amar_hoy("_amarillas_hoy"), k_amarillas("amarillas"), k_tarjeta("tarjeta");
	auto amarilla_nativa = [&](bool casero_) -> bool {
		const bool solo_visita = casero_ && rng->randf() < 0.35;
		const int64_t nl = solo_visita ? 0 : e.once_l.size();
		const int64_t n = nl + e.once_v.size();
		if (n == 0) {
			return true; // `_alguien` de una lista vacía: nadie
		}
		const int64_t k = rng->randi_range(0, n - 1);
		Object *j = k < nl ? Object::cast_to<Object>(e.once_l[k]) : Object::cast_to<Object>(e.once_v[k - nl]);
		if (j == nullptr) {
			return true;
		}
		Dictionary hoy = p->get(k_amar_hoy);
		const Variant id = j->get(k_id);
		const int64_t previas = int64_t(hoy.get(id, 0));
		if (previas >= 1) {
			p->call("_amonestar", j);
			return false;
		}
		const int64_t am = int64_t(j->get(k_amarillas)) + 1;
		j->set(k_amarillas, am);
		hoy[id] = previas + 1;
		p->emit_signal(k_tarjeta, j, false, e.minuto);
		if (am > 0 && am % ciclo_amarillas == 0) {
			ayuda->call("hit_acumula", p, j);
		}
		return true;
	};

	auto aporte = [&](Object *j, double v) {
		if (j != nullptr) {
			const Variant id = j->get(k_id);
			e.aportes[id] = double(e.aportes.get(id, 0.0)) + v;
		}
	};
	// `_atacar(c, once, es_local)`
	auto atacar = [&](bool es_local) {
		Array &once = es_local ? e.once_l : e.once_v;
		const Variant &club = es_local ? e.club_l : e.club_v;
		// _chequeo_arbitral
		switch (tipo_arb) {
			case 1:
				if (az.randf() < 0.010 * f_var) {
					p->set(k_minuto, e.minuto);
					az.salir();
					ayuda->call("hit_tarjetero", p);
					az.entrar();
					refrescar();
				}
				break;
			case 2:
				if (az.randf() < 0.008 * f_var) {
					p->set(k_minuto, e.minuto);
					az.salir();
					ayuda->call("hit_casero", p);
					az.entrar();
					refrescar();
				}
				break;
			case 3:
				if (az.randf() < 0.004 * f_var) {
					p->set(k_minuto, e.minuto);
					volcar_penal();
					az.salir();
					ayuda->call("hit_estricto", p);
					az.entrar();
					leer_penal();
					refrescar();
				}
				break;
			case 4:
				if (az.randf() < 0.003 * f_var) {
					p->set(k_minuto, e.minuto);
					az.salir();
					ayuda->call("hit_figura", p);
					az.entrar();
				}
				break;
			default:
				break;
		}
		// _penal_en_area
		if (az.randf() < p_penal) {
			p->set(k_minuto, e.minuto);
			volcar_penal();
			az.salir();
			ayuda->call("hit_penal", p, club, once, es_local);
			az.entrar();
			leer_penal();
			refrescar();
			return;
		}
		const double xg = (0.09 + UtilityFunctions::pow(az.randf(), 0.25) * 0.22) / k;
		if (es_local) {
			e.rem_l += 1;
			e.xg_l += xg;
		} else {
			e.rem_v += 1;
			e.xg_v += xg;
		}
		const double r = az.randf();
		if (r < conv) {
			if (es_local) {
				e.tp_l += 1;
			} else {
				e.tp_v += 1;
			}
			p->set(k_minuto, e.minuto);
			anotar_gol(club, once, es_local);
			e.terminado = bool(p->get(k_term));
			return;
		}
		// _elegir_goleador (sin roles: lo garantiza `_puede`)
		Object *autor = nullptr;
		if (!once.is_empty()) {
			const int64_t i = elegir_ponderado(once, grupo_de, bases_gol, 0.02, "tir", PackedFloat64Array(), az.randf(), nullptr);
			if (i >= 0) {
				autor = once[i];
			}
		}
		// tipo del remate y `_aporte_remate`
		if (r < r_ataj) {
			if (es_local) {
				e.tp_l += 1;
			} else {
				e.tp_v += 1;
			}
			aporte(autor, 0.2);
			const Array &rival = es_local ? e.once_v : e.once_l;
			for (int64_t q = 0; q < rival.size(); q++) {
				Object *j = rival[q];
				if (String(j->get(k_pos_e)) == String("POR")) {
					aporte(j, 0.2);
					break;
				}
			}
		} else if (r < r_poste) {
			aporte(autor, 0.15);
		}
	};

	refrescar();
	while (!e.terminado) {
		e.minuto += 1;
		if (e.hay_lesionados) {
			// (16-11) Con la lista de lesionados vacía `PartidoLesiones.atender` no hace nada (ni azar, ni estado, ni fuerzas): se deja de llamar hasta la próxima lesión.
			static const StringName k_lesionados("lesionados");
			if (Dictionary(p->get_meta(k_lesionados, Dictionary())).is_empty()) {
				e.hay_lesionados = false;
			} else {
				p->set(k_minuto, e.minuto);
				az.salir();
				ayuda->call("atender", p);
				az.entrar();
				refrescar();
			}
		}
		if (e.minuto == 60 && !plan_aplicado) {
			plan_aplicado = true;
			p->set(k_plan, true);
			p->set(k_minuto, e.minuto);
			az.salir();
			p->call("_aplicar_plan");
			az.entrar();
			refrescar();
		}
		// La posesión se deduce de quién llega más (media móvil del 6 %, topes 22-78).
		const double dominio = e.pl / maxf_gd(e.pl + e.pv, 0.0001);
		const double empuje = ritmo0 ? 1.06 : 1.0;
		e.posesion = CLAMP(e.posesion * 0.94 + dominio * 100.0 * empuje * 0.06, 22.0, 78.0);
		if (az.randf() < pc_l) {
			e.cor_l += 1;
		}
		if (az.randf() < pc_v) {
			e.cor_v += 1;
		}
		if (az.randf() < pf_l) {
			e.fal_l += 1;
		}
		if (az.randf() < pf_v) {
			e.fal_v += 1;
		}
		if (az.randf() < pfuera) {
			e.fue_l += 1;
		}
		if (az.randf() < pfuera) {
			e.fue_v += 1;
		}
		if (az.randf() < e.pl) {
			atacar(true);
		}
		e.terminado = bool(p->get(k_term)); // el árbitro (tarjetero, penal…) pudo dejar a alguien con menos de 7 dentro de `atacar`
		if (az.randf() < e.pv && !e.terminado) { // (17-11) una roja que deja a uno con menos de 7 suspende el partido DENTRO del minuto: ya no se juega más
			atacar(false);
		}
		e.terminado = bool(p->get(k_term));
		if (e.terminado) {
			break;
		}
		// _incidencias
		if (az.randf() < p_amarilla) {
			p->set(k_minuto, e.minuto);
			az.salir();
			if (amarilla_nativa(casero)) {
				az.entrar(); // ni roja ni cambios en el once: la fuerza no cambia
			} else {
				az.entrar();
				refrescar();
			}
		}
		if (az.randf() < p_lesion) {
			p->set(k_minuto, e.minuto);
			az.salir();
			ayuda->call("hit_lesion", p);
			az.entrar();
			e.hay_lesionados = true;
			refrescar();
		}
		e.terminado = bool(p->get(k_term));
		if (e.minuto >= fin) {
			break;
		}
	}
	az.salir();
	p->set(k_minuto, e.minuto);
	p->set(k_rem_l, e.rem_l);
	p->set(k_rem_v, e.rem_v);
	p->set(k_tp_l, e.tp_l);
	p->set(k_tp_v, e.tp_v);
	p->set(k_xg_l, e.xg_l);
	p->set(k_xg_v, e.xg_v);
	p->set(k_cor_l, e.cor_l);
	p->set(k_cor_v, e.cor_v);
	p->set(k_fal_l, e.fal_l);
	p->set(k_fal_v, e.fal_v);
	p->set(k_fue_l, e.fue_l);
	p->set(k_fue_v, e.fue_v);
	p->set(k_pos, e.posesion);
}

// ¿Hace el motor lo mismo que `AzarNativo`? Siembra generadores del motor con varias semillas y compara 4000 tiradas y el estado final con las propias.
bool DinastiaNativo::pcg_coincide() const {
	const int64_t semillas[] = { 1, 4711, 20260912, 987654321012345LL, 0x7fffffffffffffffLL };
	for (int64_t semilla : semillas) {
		Ref<RandomNumberGenerator> a;
		a.instantiate();
		a->set_seed(semilla);
		AzarNativo az;
		az.rng = a;
		az.propio = true;
		az.entrar();
		Ref<RandomNumberGenerator> b;
		b.instantiate();
		b->set_seed(semilla);
		for (int i = 0; i < 4000; i++) {
			if (az.randf() != b->randf()) {
				return false;
			}
		}
		az.salir();
		if (a->get_state() != b->get_state()) {
			return false;
		}
	}
	return true;
}
