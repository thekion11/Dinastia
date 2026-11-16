// `MotorLeague._mas_cercano_al` con `cuantos == 1` y sin excluidos (16-11-2026, paso a C++): el índice (en `jugadores`) del compañero o rival más cercano a un punto del marco de League.
// Misma cuenta que la pasada de GDScript: `ls(pos(q))` = (z, x) en 32 bits, distancia al cuadrado de `Vector2` y el primero gana los empates (comparación estricta).
#include "dinastia_nativo.h"

#include <cmath>

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

using namespace godot;

int64_t DinastiaNativo::league_mas_cercano(const Array &jugadores, const Vector2 &punto, bool local) const {
	static const StringName k_node("node"), k_local("es_local");
	double mejor = INFINITY;
	int64_t sel = -1;
	const int64_t n = jugadores.size();
	for (int64_t i = 0; i < n; i++) {
		const Dictionary q = jugadores[i];
		if ((bool)q[k_local] != local) {
			continue;
		}
		const Variant vn = q[k_node];
		const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(vn));
		if (nodo == nullptr) {
			continue; // el motor nunca deja un jugador sin nodo; con un nodo liberado GDScript habría fallado
		}
		const Vector3 p = nodo->get_position();
		const double d = (double)(Vector2(p.z, p.x) - punto).length_squared();
		if (d < mejor) {
			mejor = d;
			sel = i;
		}
	}
	return sel;
}

// `MotorLeague._estado_sin_balon`, el balón suelto: el jugador (de cualquier equipo) a menor `(ls(pos) - punto).length()` (la raíz, no el cuadrado: dos distancias distintas pueden dar la misma raíz en float).
int64_t DinastiaNativo::league_mas_cercano_todos(const Array &jugadores, const Vector2 &punto) const {
	static const StringName k_node("node");
	double mejor = INFINITY;
	int64_t sel = -1;
	const int64_t n = jugadores.size();
	for (int64_t i = 0; i < n; i++) {
		const Dictionary q = jugadores[i];
		const Variant vn = q[k_node];
		const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(vn));
		if (nodo == nullptr) {
			continue;
		}
		const Vector3 p = nodo->get_position();
		const double d = (double)(Vector2(p.z, p.x) - punto).length();
		if (d < mejor) {
			mejor = d;
			sel = i;
		}
	}
	return sel;
}

// `_ls_por_id.clear()` + `_ls_por_id[String(q["id"])] = q` para cada jugador.
void DinastiaNativo::league_indexar(const Array &jugadores, Dictionary destino) const {
	static const StringName k_id("id");
	destino.clear();
	const int64_t n = jugadores.size();
	for (int64_t i = 0; i < n; i++) {
		const Dictionary q = jugadores[i];
		destino[String(q[k_id])] = q;
	}
}

// `LeagueEquipo.linea_penultimo(xs, lado_, balon_x)` con `xs` armado como lo hace `MotorLeague`: la x League (= z del mundo) de los jugadores con `es_local == local` (más su velocidad por 0,24 si `con_vel`), en 32 bits.
double DinastiaNativo::league_linea_penultimo(const Array &jugadores, bool local, bool con_vel, double lado_, double balon_x) const {
	static const StringName k_node("node"), k_local("es_local"), k_vel("vel");
	double a = -INFINITY;
	double b = -INFINITY;
	const int64_t n = jugadores.size();
	for (int64_t i = 0; i < n; i++) {
		const Dictionary q = jugadores[i];
		if ((bool)q[k_local] != local) {
			continue;
		}
		const Variant vn = q[k_node];
		const Node3D *nodo = Object::cast_to<Node3D>(static_cast<Object *>(vn));
		if (nodo == nullptr) {
			continue;
		}
		double x = (double)nodo->get_position().z;
		if (con_vel) {
			const Vector3 vel = q[k_vel];
			x = x + (double)vel.z * 0.24;
		}
		const double v = (double)(float)x * lado_; // el PackedFloat32Array guarda 32 bits
		if (v > a) {
			b = a;
			a = v;
		} else if (v > b) {
			b = v;
		}
	}
	double linea = (b > -INFINITY ? b : 0.0) * lado_;
	if (balon_x * lado_ > linea * lado_) {
		linea = balon_x;
	}
	if (linea * lado_ < 0.0) {
		linea = 0.01 * -lado_;
	}
	return linea < -52.5 ? -52.5 : (linea > 52.5 ? 52.5 : linea);
}
