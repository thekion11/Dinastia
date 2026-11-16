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
