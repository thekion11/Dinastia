// `Partido._cerrar_notas()` en C++ (10-11-2026, paso a C++, orden 35): la nota final de cada jugador del cruce (la de la IA que nadie mira) con las MISMAS cuentas y el MISMO orden de tiradas de azar
// (una `randf()` por jugador, en el orden de `_todos`, sobre el mismo generador `Azar._rng`). Solo lee y escribe propiedades (también lo de `Jugador.anotar_nota`: añadir a `notas` y quedarse con las 8 últimas).
#include "dinastia_nativo.h"

#include <godot_cpp/classes/random_number_generator.hpp>
#include <godot_cpp/variant/string_name.hpp>

#include <cmath>
#include <initializer_list>

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

// `Clima.del_partido` + `Clima.factor` + `Clima.factor_visita` (nucleo/clima.gd, 17-11-2026): lo que hace `Partido.fijar_clima(Clima.del_partido(…))`.
// Devuelve [info, factor, factor del visitante]. `globo` = la tabla GLOBO_PAIS (país → [.., latitud, ..]). Gemela: esas funciones de `Clima`.
namespace {
double clima_latitud(const Dictionary &globo, const String &pais) {
	if (globo.has(pais)) {
		const Array g = globo[pais];
		return double(g[1]);
	}
	return -33.4;
}
bool clima_en(const String &x, std::initializer_list<const char *> l) {
	for (const char *c : l) {
		if (x == c) {
			return true;
		}
	}
	return false;
}
String clima_estacion(const Dictionary &globo, const String &pais, int64_t semana) {
	const double lat = clima_latitud(globo, pais);
	if (std::fabs(lat) < 23.5) {
		return "tropical";
	}
	const int64_t s = semana > 1 ? semana : 1;
	int64_t mes = 1 + int64_t(double(s - 1) * 7.0 / 30.4 + 0.85);
	mes = mes < 1 ? 1 : (mes > 12 ? 12 : mes);
	if (lat < 0.0) {
		mes = ((mes + 5) % 12) + 1;
	}
	if (mes == 12 || mes == 1 || mes == 2) {
		return "invierno";
	}
	if (mes >= 3 && mes <= 5) {
		return "primavera";
	}
	if (mes >= 6 && mes <= 8) {
		return "verano";
	}
	return "otono";
}
} // namespace

Array DinastiaNativo::clima_partido(const String &pais, const String &pais_visita, int64_t semana, int64_t anio, const String &semilla, bool neutral, const Dictionary &globo) const {
	const String est = clima_estacion(globo, pais, semana);
	const bool frio = std::fabs(clima_latitud(globo, pais)) >= 45.0;
	const int64_t h = int64_t((pais + String("|") + String::num_int64(anio) + String("|") + String::num_int64(semana) + String("|") + semilla).hash());   // absi(hash) = hash (no es negativo)
	const double r = double(h % 1000) / 1000.0;
	const double r2 = double((h / 1000) % 1000) / 1000.0;
	const bool desierto = clima_en(pais, { "KSA", "EGY", "QAT", "UAE" });
	double p_lluvia = est == "invierno" ? 0.34 : (est == "otono" ? 0.28 : (est == "primavera" ? 0.22 : (est == "verano" ? 0.10 : 0.30)));
	if (desierto) {
		p_lluvia = 0.03;
	}
	String clave;
	if (frio && est == "invierno" && r < 0.22) {
		clave = "nieve";
	} else if (r < p_lluvia) {
		clave = (clima_en(est, { "verano", "tropical" }) && r2 < 0.35) ? "tormenta" : "lluvia";
	} else if (clima_en(est, { "otono", "invierno" }) && r < p_lluvia + 0.07) {
		clave = "niebla";
	} else {
		clave = r2 < 0.5 ? "noche" : (r2 < 0.8 ? "tarde" : "dia");
	}
	const bool calor = clima_en(clave, { "dia", "tarde" }) && (clima_en(est, { "verano", "tropical" }) || desierto);
	const bool altura = clima_en(pais, { "BOL", "ECU", "COL", "MEX" });
	String texto;
	if (clave == "nieve") {
		texto = String::utf8("Nieve y frío de invierno");
	} else if (clave == "lluvia") {
		texto = String::utf8("Lluvia") + (est == "invierno" ? String::utf8(" fría de invierno") : String());
	} else if (clave == "tormenta") {
		texto = String::utf8("Tormenta eléctrica");
	} else if (clave == "niebla") {
		texto = String::utf8("Niebla cerrada");
	} else if (clave == "noche") {
		texto = String::utf8("Noche despejada");
	} else if (clave == "tarde") {
		texto = String::utf8("Tarde despejada");
	} else {
		texto = String::utf8("Mediodía despejado");
	}
	if (calor) {
		texto = String::utf8("Calor intenso") + (desierto ? String::utf8(" y seco") : String());
	}
	if (altura) {
		texto += String::utf8(", en la altura");
	}
	Dictionary info;
	info["clave"] = clave;
	info["calor"] = calor;
	info["altura"] = altura;
	info["texto"] = texto;
	info["estacion"] = est;
	// `Clima.factor`
	double f = clave == "lluvia" ? 0.93 : (clave == "tormenta" ? 0.88 : (clave == "nieve" ? 0.85 : (clave == "niebla" ? 0.95 : 1.0)));
	if (calor) {
		f *= 0.96;
	}
	// `Clima.factor_visita` (1 si el campo es neutral, como `fijar_clima`)
	double fv = 1.0;
	if (!neutral && pais_visita != pais) {
		if (altura && !clima_en(pais_visita, { "BOL", "ECU", "COL", "MEX" })) {
			fv *= 0.92;
		}
		if (calor && std::fabs(clima_latitud(globo, pais_visita)) >= 40.0) {
			fv *= 0.95;
		}
		if (clave == "nieve" && std::fabs(clima_latitud(globo, pais_visita)) < 23.5) {
			fv *= 0.93;
		}
	}
	Array res;
	res.push_back(info);
	res.push_back(f);
	res.push_back(fv);
	return res;
}

// `Partido.invalidar_fuerza` (nucleo/partido_p1.gd, 17-11-2026): `fuerza()` de los dos onces en una llamada: las cuatro medias (`medias_linea`, como
// `PartidoMedias.nativo`), los multiplicadores de la táctica (`Tactica.multiplicador_ataque/defensa`, con sus tablas copiadas), los bonus del club, la moda
// táctica, el videoanálisis del club del jugador y los rasgos del once. `m` = [mapa_grupos, mapa_lateral, mapa_banda, impulsos, minuto, arenga, ley_del_ex,
// ex_de_mi_club, ctx_moda, ctx_club_id, ctx_analisis]. Devuelve [{ata, def} del local, del visitante]. Gemela: `Partido._invalidar_fuerza_gd`.
namespace {
const double MENT_ATA[] = { 0.88, 1.0, 1.12 }, MENT_DEF[] = { 1.10, 1.0, 0.90 }, PRES_ATA[] = { 0.97, 1.0, 1.05 }, RITMO_ATA[] = { 0.95, 1.0, 1.07 },
			 RITMO_DEF[] = { 1.05, 1.0, 0.95 }, LINEA_ATA[] = { 0.96, 1.0, 1.06 }, LINEA_DEF[] = { 1.06, 1.0, 0.93 }, AMPL_ATA[] = { 0.98, 1.0, 1.04 },
			 AMPL_DEF[] = { 1.03, 1.0, 0.98 }, VERT_ATA[] = { 0.97, 1.0, 1.04 }, VERT_DEF[] = { 1.03, 1.0, 0.96 }, PERD_ATA[] = { 0.97, 1.0, 1.04 },
			 PERD_DEF[] = { 1.04, 1.0, 0.97 };
} // namespace

Dictionary DinastiaNativo::fuerza_una(const Array &once, Object *c, Object *enfrente, const Array &m) const {
	static const StringName k_tactica("tactica"), k_ment("mentalidad"), k_pres("presion"), k_ritmo("ritmo"), k_linea("linea"), k_ampl("amplitud"), k_salida("salida_corta"),
			k_marca("marca_al_hombre"), k_tiro("tiro_lejano"), k_vert("verticalidad"), k_perd("tras_perdida"), k_fdj("fuera_de_juego"), k_form("formacion"),
			k_bon_a("bonus_ataque"), k_bon_d("bonus_defensa"), k_id("id"), k_rasgo("rasgo");
	const PackedFloat64Array medias = medias_linea(once, m[0], m[1], m[2], m[3], int64_t(m[4]), double(m[5]), double(m[6]), m[7], enfrente != nullptr ? String(enfrente->get(k_id)) : String());
	double por = medias[0];
	if (por <= 0.0) {
		por = 35.0;
	}
	const double defe = medias[1], med = medias[2], del = medias[3];
	double ata = del * 0.55 + med * 0.38 + defe * 0.07;
	double dfa = defe * 0.5 + por * 0.3 + med * 0.2;
	Object *t = c->get(k_tactica);
	const int64_t ment = t->get(k_ment), pres = t->get(k_pres), ritmo = t->get(k_ritmo), linea = t->get(k_linea), ampl = t->get(k_ampl), vert = t->get(k_vert), perd = t->get(k_perd);
	double ma = MENT_ATA[ment] * PRES_ATA[pres] * RITMO_ATA[ritmo] * LINEA_ATA[linea] * AMPL_ATA[ampl];
	if (bool(t->get(k_salida))) {
		ma *= 1.03;
	}
	if (bool(t->get(k_marca))) {
		ma *= 0.98;
	}
	if (bool(t->get(k_tiro))) {
		ma *= 1.02;
	}
	ma *= VERT_ATA[vert] * PERD_ATA[perd];
	double md = MENT_DEF[ment] * RITMO_DEF[ritmo] * LINEA_DEF[linea] * AMPL_DEF[ampl];
	if (bool(t->get(k_marca))) {
		md *= 1.03;
	}
	if (bool(t->get(k_fdj))) {
		md *= 1.06;
	}
	md *= VERT_DEF[vert] * PERD_DEF[perd];
	ata *= ma * double(c->get(k_bon_a));
	dfa *= md * double(c->get(k_bon_d));
	int64_t killer = 0, muralla = 0, cerebro = 0, veloz = 0;
	for (int64_t i = 0; i < once.size(); i++) {
		Object *j = once[i];
		const String r = j->get(k_rasgo);
		if (r == "killer") {
			killer++;
		} else if (r == "muralla") {
			muralla++;
		} else if (r == "cerebro") {
			cerebro++;
		} else if (r == "veloz") {
			veloz++;
		}
	}
	const Dictionary moda = m[8];
	const Variant form = t->get(k_form);
	const double fm = double(moda.get(form, 1.0));
	ata *= fm;
	dfa *= fm;
	const double analisis = m[10];
	if (String(c->get(k_id)) == String(m[9]) && analisis > 1.0) {
		ata *= analisis;
		dfa *= analisis;
	}
	ata *= 1.0 + 0.012 * double(killer) + 0.008 * double(veloz) + 0.005 * double(cerebro);
	dfa *= 1.0 + 0.012 * double(muralla) + 0.005 * double(cerebro);
	Dictionary r;
	r["ata"] = ata;
	r["def"] = dfa;
	return r;
}

Array DinastiaNativo::fuerza_dos(const Array &once_l, const Array &once_v, Object *local, Object *visita, const Array &m) const {
	Array r;
	r.push_back(fuerza_una(once_l, local, visita, m));
	r.push_back(fuerza_una(once_v, visita, local, m));
	return r;
}
