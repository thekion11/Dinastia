// El ESTADO POR PASO del motor de League en C++ (16-11-2026, agente C, paso a C++): las partes puras de `MotorLeague._estado_league` / `_estado_sin_balon` / `_interferir`.
// Cada función es copia exacta de su GDScript (Vector2 en 32 bits, el `float` de GDScript en double, mismo orden de operaciones; el primero gana los empates). Las gemelas GDScript
// se quedan de respaldo (`_ms_al_balon`, `_linea_penultimo_gd`, `LeagueEquipo.registrar_acumular_gd`, `_candidatos_interferir_gd`...) y `pruebas/probar_nativo_estado.gd`
// comprueba que dan los mismos bytes.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>
#include <vector>

using namespace godot;

namespace {

// Lo que el estado necesita de un jugador: su sitio en el marco de League (z, x), la z de su velocidad y su equipo.
struct Fila {
	Vector2 ls;
	double vel_z;
	bool local;
};

// `LeagueEquipo.linea_penultimo(xs, lado_, balon_x)` con las `xs` de `MotorLeague._linea_penultimo_gd` (copia de `league_linea_penultimo`).
double linea(const std::vector<Fila> &filas, bool local, bool con_vel, double lado_, double balon_x) {
	double a = -INFINITY;
	double b = -INFINITY;
	for (const Fila &f : filas) {
		if (f.local != local) {
			continue;
		}
		double x = (double)f.ls.x;
		if (con_vel) {
			x = x + f.vel_z * 0.24;
		}
		const double v = (double)(float)x * lado_; // el PackedFloat32Array guarda 32 bits
		if (v > a) {
			b = a;
			a = v;
		} else if (v > b) {
			b = v;
		}
	}
	double l = (b > -INFINITY ? b : 0.0) * lado_;
	if (balon_x * lado_ > l * lado_) {
		l = balon_x;
	}
	if (l * lado_ < 0.0) {
		l = 0.01 * -lado_;
	}
	return l < -52.5 ? -52.5 : (l > 52.5 ? 52.5 : l);
}

} // namespace

// Una sola pasada por los 22 jugadores con lo que `_estado_league` y `_estado_sin_balon` piden del balón y las líneas (los nodos no se mueven entre una y otra):
// [0] ms que tarda en llegar al balón el local (`_ms_al_balon(true)`, 5000 si no hay), [1] el visitante, [2] índice del más cercano de todos al balón (`_mas_cercano_a_todos`, -1 si ninguno),
// [3] y [4] línea del penúltimo propio de cada equipo (`_linea_penultimo(i == 0, false, lado_i, b.x)`), [5] y [6] línea del fuera de juego del rival de cada equipo
// (`_linea_penultimo(i != 0, true, -lado_i, b.x)`).
PackedFloat64Array DinastiaNativo::league_estado_base(const Array &jugadores, const Vector2 &b, double lado0, double lado1) const {
	static const StringName k_node("node"), k_local("es_local"), k_vel("vel");
	std::vector<Fila> filas;
	const int64_t n = jugadores.size();
	filas.reserve((size_t)n);
	double mejor_ms[2] = { INFINITY, INFINITY };
	double mejor_d = INFINITY;
	int64_t sel = -1;
	for (int64_t i = 0; i < n; i++) {
		const Dictionary q = jugadores[i];
		const Variant vn = q[k_node];
		const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(vn));
		if (nodo == nullptr) {
			continue;
		}
		const Vector3 p = nodo->get_position();
		const Vector3 vel = q[k_vel];
		const bool local = (bool)q[k_local];
		const Vector2 yo(p.z, p.x);
		const double d = (double)(yo - b).length();
		const double ms = d / 7.0 * 1000.0;
		const int k = local ? 0 : 1;
		if (ms < mejor_ms[k]) {
			mejor_ms[k] = ms;
		}
		if (d < mejor_d) {
			mejor_d = d;
			sel = i;
		}
		filas.push_back({ yo, (double)vel.z, local });
	}
	PackedFloat64Array r;
	r.resize(7);
	r[0] = mejor_ms[0] < INFINITY ? mejor_ms[0] : 5000.0;
	r[1] = mejor_ms[1] < INFINITY ? mejor_ms[1] : 5000.0;
	r[2] = (double)sel;
	const double bx = (double)b.x;
	r[3] = linea(filas, true, false, lado0, bx);
	r[4] = linea(filas, false, false, lado1, bx);
	r[5] = linea(filas, false, true, -lado0, bx);
	r[6] = linea(filas, true, true, -lado1, bx);
	return r;
}

// `MotorLeague._mas_cercano_al(punto, local, [], 1)` de los dos equipos a la vez: [índice del local, índice del visitante] (-1 si no hay).
PackedInt32Array DinastiaNativo::league_cercanos_equipos(const Array &jugadores, const Vector2 &punto) const {
	static const StringName k_node("node"), k_local("es_local");
	double mejor[2] = { INFINITY, INFINITY };
	int32_t sel[2] = { -1, -1 };
	const int64_t n = jugadores.size();
	for (int64_t i = 0; i < n; i++) {
		const Dictionary q = jugadores[i];
		const Variant vn = q[k_node];
		const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(vn));
		if (nodo == nullptr) {
			continue;
		}
		const Vector3 p = nodo->get_position();
		const int k = (bool)q[k_local] ? 0 : 1;
		const double d = (double)(Vector2(p.z, p.x) - punto).length_squared();
		if (d < mejor[k]) {
			mejor[k] = d;
			sel[k] = (int32_t)i;
		}
	}
	PackedInt32Array r;
	r.resize(2);
	r[0] = sel[0];
	r[1] = sel[1];
	return r;
}

// `LeagueEquipo.registrar(e0, ...)` + `acumular_gd()` + `media_f_gd(lado_hist, 6000)` en un paso: [balon_hist, lado_hist, resto, acum, lado_medio]. Al llenarse (600) el original recorta con `slice` en cada
// entrada nueva: el resultado es siempre las últimas 600 del historial más lo nuevo.
Array DinastiaNativo::league_registrar(const PackedVector2Array &balon_hist, const PackedFloat32Array &lado_hist, double resto, const Vector2 &balon, double lado_posesion, double dt) const {
	const double PASO = 0.01;
	const int64_t HISTORIA = 600;
	resto += dt;
	int64_t nuevas = 0;
	while (resto >= PASO) {
		resto -= PASO;
		nuevas++;
	}
	const int64_t viejas = balon_hist.size();
	PackedVector2Array bh = balon_hist;
	PackedFloat32Array lh = lado_hist;
	if (nuevas > 0) {
		const int64_t total = viejas + nuevas;
		const int64_t ini = total > HISTORIA ? total - HISTORIA : 0;
		PackedVector2Array nb;
		PackedFloat32Array nl;
		nb.resize(total - ini);
		nl.resize(total - ini);
		const float lp = (float)lado_posesion;
		const Vector2 *ob = balon_hist.ptr();
		const float *ol = lado_hist.ptr();
		Vector2 *db = nb.ptrw();
		float *dl = nl.ptrw();
		for (int64_t k = ini; k < total; k++) {
			if (k < viejas) {
				db[k - ini] = ob[k];
				dl[k - ini] = ol[k];
			} else {
				db[k - ini] = balon;
				dl[k - ini] = lp;
			}
		}
		bh = nb;
		lh = nl;
	}
	const int64_t nb_tam = bh.size();
	PackedVector2Array acum;
	acum.resize(nb_tam + 1);
	{
		const Vector2 *src = bh.ptr();
		Vector2 *dst = acum.ptrw();
		Vector2 s;
		dst[0] = s;
		for (int64_t i = 0; i < nb_tam; i++) {
			s += src[i];
			dst[i + 1] = s;
		}
	}
	// `LeagueEquipo.media_f_gd(lado_hist, 6000.0)`
	const int64_t lt = lh.size();
	int64_t quiero = (int64_t)(6000.0 / 10.0);
	if (quiero < 1) {
		quiero = 1;
	}
	const int64_t m = lt < quiero ? lt : quiero;
	double medio = 0.0;
	if (m > 0) {
		const float *src = lh.ptr();
		double suma = 0.0;
		for (int64_t i = 0; i < m; i++) {
			suma += (double)src[lt - 1 - i];
		}
		medio = suma / (double)m;
	}
	Array r;
	r.resize(5);
	r[0] = bh;
	r[1] = lh;
	r[2] = resto;
	r[3] = acum;
	r[4] = medio;
	return r;
}

namespace {

// El filtro común de `MotorLeague._interferir` (cortar = false) y `_cortar_pase` (cortar = true): los índices (en orden) de los jugadores del otro equipo que `rival_local`, no porteros, no el usuario con el mando
// (`usuario_id` vacío = ninguno), a 10 m o menos del balón previsto a 200 ms y libres: sin enfriar ni en un gesto (interferir) o sin una orden de cortar vigente (`ls_cortar_hasta`, cortar).
PackedInt32Array candidatos(const Array &jugadores, bool rival_local, const String &usuario_id, double t, const Vector2 &bola, bool cortar) {
	static const StringName k_node("node"), k_local("es_local"), k_por("por"), k_enfriar("enfriar"), k_gesto("gesto_hasta"), k_cortar("ls_cortar_hasta"), k_id("id");
	PackedInt32Array r;
	const bool hay_usuario = !usuario_id.is_empty();
	const int64_t n = jugadores.size();
	for (int64_t i = 0; i < n; i++) {
		const Dictionary q = jugadores[i];
		if ((bool)q[k_local] == rival_local || (bool)q[k_por]) {
			continue;
		}
		const Variant vn = q[k_node]; // la distancia primero: casi todos están lejos del balón y se descartan sin más consultas
		const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(vn));
		if (nodo == nullptr) {
			continue;
		}
		const Vector3 p = nodo->get_position();
		if ((double)Vector2(p.z, p.x).distance_to(bola) > 10.0) {
			continue;
		}
		if (hay_usuario && String(q[k_id]) == usuario_id) {
			continue;
		}
		if (cortar) {
			if ((double)q.get(k_cortar, 0.0) > t) {
				continue;
			}
		} else if ((double)q.get(k_enfriar, 0.0) > 0.0 || (double)q.get(k_gesto, 0.0) > t) {
			continue;
		}
		r.push_back((int32_t)i);
	}
	return r;
}

} // namespace

PackedInt32Array DinastiaNativo::league_interferir_candidatos(const Array &jugadores, bool rival_local, const String &usuario_id, double t, const Vector2 &bola) const {
	return candidatos(jugadores, rival_local, usuario_id, t, bola, false);
}

PackedInt32Array DinastiaNativo::league_cortar_candidatos(const Array &jugadores, bool local_pasa, const String &usuario_id, double t, const Vector2 &bola) const {
	return candidatos(jugadores, local_pasa, usuario_id, t, bola, true);
}

// `MotorLeague._mas_cercano_al(punto, local, excluir, cuantos)` para varios o con excluidos: los índices (en `jugadores`) de los `cuantos` del equipo más cercanos a `punto`, de menor a mayor distancia al cuadrado.
// El original ordena con `sort_custom` (estricto `<`); con 16 o menos Godot usa su ordenación por inserción, que con una comparación estricta es ESTABLE: los empates salen en el orden de `jugadores`.
// Eso es lo que copia aquí. Con más de 16 candidatos (el original pasaría a la ordenación rápida, que no es estable) devuelve [-2] y se queda GDScript. `excluidos` = los ids de `excluir`
// (dos jugadores distintos nunca tienen el mismo diccionario, así que `Array.has` equivale a comparar el id).
PackedInt32Array DinastiaNativo::league_mas_cercanos(const Array &jugadores, const Vector2 &punto, bool local, int64_t cuantos, const PackedStringArray &excluidos) const {
	static const StringName k_node("node"), k_local("es_local"), k_id("id");
	struct Cand {
		float d;
		int32_t i;
	};
	Cand cs[16];
	int64_t n = 0;
	const int64_t tam = jugadores.size();
	for (int64_t i = 0; i < tam; i++) {
		const Dictionary q = jugadores[i];
		if ((bool)q[k_local] != local) {
			continue;
		}
		if (excluidos.size() > 0) {
			const String id = String(q[k_id]);
			bool fuera = false;
			for (int64_t e = 0; e < excluidos.size(); e++) {
				if (excluidos[e] == id) {
					fuera = true;
					break;
				}
			}
			if (fuera) {
				continue;
			}
		}
		const Variant vn = q[k_node];
		const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(vn));
		if (nodo == nullptr) {
			continue;
		}
		if (n >= 16) {
			PackedInt32Array r;
			r.push_back(-2);
			return r;
		}
		const Vector3 p = nodo->get_position();
		cs[n].d = (Vector2(p.z, p.x) - punto).length_squared();
		cs[n].i = (int32_t)i;
		n++;
	}
	for (int64_t a = 1; a < n; a++) { // ordenación por inserción con comparación estricta (la de Godot para 16 o menos)
		const Cand v = cs[a];
		int64_t b = a;
		while (b > 0 && v.d < cs[b - 1].d) {
			cs[b] = cs[b - 1];
			b--;
		}
		cs[b] = v;
	}
	PackedInt32Array r;
	const int64_t m = cuantos < n ? cuantos : n;
	for (int64_t k = 0; k < m; k++) {
		r.push_back(cs[k].i);
	}
	return r;
}
