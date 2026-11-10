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
