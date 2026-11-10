// Funciones del partido simulado (10-11-2026, paso a C++). Cada una sigue paso a paso a su original en GDScript (`Partido`, nucleo/partido_p2.gd).
#include "dinastia_nativo.h"

#include <vector>

using namespace godot;

// `_elegir_goleador` y `_elegir_asistente`: peso de cada jugador = base de su línea × (0,5 + atributo/100) × (peso de su rol), sorteo con la tirada `r_unit` × total,
// restando pesos hasta pasar de cero; si la resta no alcanza (redondeo) gana el último candidato. Devuelve el índice en `once`.
int64_t DinastiaNativo::elegir_ponderado(const Array &once, const Dictionary &grupo_de, const Dictionary &bases, double base_def, const String &atr, const PackedFloat64Array &pesos_rol, double r_unit, Object *excluir) const {
	static const StringName k_pos_e("pos_e");
	static const StringName k_atributos("atributos");
	const StringName k_atr(atr);
	const int64_t n = once.size();
	std::vector<double> pesos;
	std::vector<int64_t> idx;
	pesos.reserve(n);
	idx.reserve(n);
	double total = 0.0;
	const bool con_roles = !pesos_rol.is_empty();
	for (int64_t i = 0; i < n; i++) {
		Object *j = once[i];
		if (j == excluir) {
			continue;
		}
		double base = base_def;
		const String grupo = grupo_de.get(String(j->get(k_pos_e)), String("MED"));
		if (bases.has(grupo)) {
			base = double(bases[grupo]);
		}
		const Dictionary atributos = j->get(k_atributos);
		base *= 0.5 + double(atributos.get(String(atr), 50)) / 100.0;
		if (con_roles) {
			base *= pesos_rol[int64_t(idx.size())];
		}
		pesos.push_back(base);
		idx.push_back(i);
		total += base;
	}
	if (idx.empty()) {
		return -1;
	}
	double r = r_unit * total;
	for (size_t i = 0; i < idx.size(); i++) {
		r -= pesos[i];
		if (r <= 0.0) {
			return idx[i];
		}
	}
	return idx.back();
}

// `Partido._media_linea` para las cuatro líneas a la vez (POR, DEF, MED, DEL): la media de rendimiento de los jugadores de cada línea del once, con la ley del ex, la arenga y el pie de los laterales.
// Devuelve [POR, DEF, MED, DEL]; una línea sin jugadores vale 50,0 (como el GDScript). `ex_id`: id del club de enfrente ("" = ninguno). `arenga_mult`: el multiplicador ya calculado de la arenga.
PackedFloat64Array DinastiaNativo::medias_linea(const Array &once, const Dictionary &grupo_de, const Dictionary &lateral_de, const Dictionary &banda_de, const Dictionary &impulsos, int64_t minuto,
		double arenga_mult, double ley_ex, const Dictionary &ex_de_mi_club, const String &ex_id) const {
	static const StringName k_pos_e("pos_e"), k_id("id"), k_ovr("ovr"), k_forma("forma"), k_fisico("fisico"), k_moral("moral");
	double suma[4] = { 0.0, 0.0, 0.0, 0.0 };
	int64_t n[4] = { 0, 0, 0, 0 };
	for (int64_t i = 0; i < once.size(); i++) {
		Object *j = once[i];
		const String pos_e = j->get(k_pos_e);
		const String g = grupo_de.get(pos_e, String("MED"));
		int linea = -1;
		if (g == String("POR")) {
			linea = 0;
		} else if (g == String("DEF")) {
			linea = 1;
		} else if (g == String("MED")) {
			linea = 2;
		} else if (g == String("DEL")) {
			linea = 3;
		}
		if (linea < 0) {
			continue;
		}
		const Variant id = j->get(k_id);
		double impulso = 1.0;
		if (!ex_id.is_empty() && String(ex_de_mi_club.get(id, String(""))) == ex_id) {
			impulso *= ley_ex;
		}
		if (int64_t(impulsos.get(id, int64_t(-1))) > minuto) {
			impulso *= arenga_mult;
		}
		if (bool(lateral_de.get(pos_e, false))) {
			const String banda = banda_de.get(pos_e, String(""));
			if (banda != String("")) {
				const String sid = id;
				int64_t h = 5381;
				for (int64_t q = 0; q < sid.length(); q++) {
					h = ((h << 5) + h + int64_t(sid.unicode_at(q))) & 0x7FFFFFFF;
				}
				const String pie = (h % 100 < 76) ? String("D") : String("I");
				if (banda != pie) {
					impulso *= 0.94;
				}
			}
		}
		const double ovr = double(int64_t(j->get(k_ovr)));
		suma[linea] += ovr * (0.7 + 0.003 * double(int64_t(j->get(k_forma)))) * (0.85 + 0.0015 * double(int64_t(j->get(k_fisico)))) * (0.9 + 0.002 * double(int64_t(j->get(k_moral)))) * impulso;
		n[linea] += 1;
	}
	PackedFloat64Array r;
	r.resize(4);
	for (int q = 0; q < 4; q++) {
		r.set(q, n[q] == 0 ? 50.0 : suma[q] / double(n[q]));
	}
	return r;
}
