// `MotorJugable._cuerpos` + `CuerposFisica.solape` (10-11-2026, paso a C++). Misma aritmética, operación por operación: posiciones y vectores en float de 32 bits (Vector3), el resto en double como el `float` de GDScript.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>
#include <vector>

using namespace godot;

void DinastiaNativo::cuerpos_motor(const Array &jugadores, double minimo) const {
	static const StringName k_node("node"), k_vel("vel"), k_fuerza("fuerza"), k_aguante("aguante");
	const int64_t n = jugadores.size();
	for (int64_t i = 0; i < n; i++) {
		Dictionary pa = jugadores[i];
		const Variant va_nodo = pa[k_node];
		Node3D *a = Object::cast_to<Node3D>(static_cast<Object *>(va_nodo)); // un nodo ya liberado llega como null (= is_instance_valid falso)
		if (a == nullptr) {
			continue;
		}
		for (int64_t j = i + 1; j < n; j++) {
			Dictionary pb = jugadores[j];
			const Variant vb_nodo = pb[k_node];
			Node3D *b = Object::cast_to<Node3D>(static_cast<Object *>(vb_nodo));
			if (b == nullptr) {
				continue;
			}
			// CuerposFisica.solape(dx, dz, minimo, float(i * 7 + j), -1.0)
			const double dx = double(b->get_position().x) - double(a->get_position().x);
			const double dz = double(b->get_position().z) - double(a->get_position().z);
			const double d2 = dx * dx + dz * dz;
			if (d2 >= minimo * minimo) {
				continue;
			}
			const double d = std::sqrt(d2);
			Vector2 nrm2;
			if (d > 0.001) {
				nrm2 = Vector2(dx, dz) / d;
			} else {
				nrm2 = Vector2(1.0, 0.0).rotated(double(i * 7 + j));
				nrm2.y = -nrm2.y; // giro_z < 0
			}
			const Vector3 s(nrm2.x, minimo - d, nrm2.y);
			const Vector3 nrm(s.x, 0, s.z);
			const double ma = 0.6 + (double(pa.get(k_fuerza, 0.6)) * (0.75 + 0.25 * double(pa.get(k_aguante, 1.0)))) * 0.8;
			const double mb = 0.6 + (double(pb.get(k_fuerza, 0.6)) * (0.75 + 0.25 * double(pb.get(k_aguante, 1.0)))) * 0.8;
			const double hueco = s.y;
			a->set_position(a->get_position() - nrm * hueco * mb / (ma + mb));
			b->set_position(b->get_position() + nrm * hueco * ma / (ma + mb));
			const Vector3 va = pa[k_vel];
			const Vector3 vb = pb[k_vel];
			const double acerca = (va - vb).dot(nrm);
			if (acerca > 0.0) {
				pa[k_vel] = va - nrm * acerca * mb / (ma + mb);
				pb[k_vel] = vb + nrm * acerca * ma / (ma + mb);
			}
		}
	}
}
