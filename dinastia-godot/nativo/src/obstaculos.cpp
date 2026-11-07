// `Optimizar.obstaculo_multimalla` (el bucle por instancia), en C++ (7-11-2026, carga de la ciudad). Traducción literal de la versión GDScript (que se queda de respaldo):
// mismas operaciones y mismo orden; `float` de GDScript = double, los Vector3/AABB/Rect2 = float de 32 bits. `pruebas/probar_nativo.tscn` lo compara byte a byte.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/aabb.hpp>
#include <godot_cpp/variant/basis.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>

using namespace godot;

// `Optimizar._en_rejilla`: ¿cae (x, z) dentro de algún rectángulo sólido de su celda de la rejilla?
static bool en_rejilla(const Dictionary &rej, double celda_rej, double x, double z) {
	const Vector2i k(int32_t(std::floor(x / celda_rej)), int32_t(std::floor(z / celda_rej)));
	if (!rej.has(k)) {
		return false;
	}
	const Array lista = rej[k];
	const Vector2 p(real_t(x), real_t(z));
	for (int64_t i = 0; i < lista.size(); i++) {
		const Rect2 r = lista[i];
		if (r.has_point(p)) {
			return true;
		}
	}
	return false;
}

static double lim_max(double a, double b) { return a > b ? a : b; }
static double lim_min(double a, double b) { return a < b ? a : b; }
static double clampf_(double v, double lo, double hi) { return v < lo ? lo : (v > hi ? hi : v); }

// `Optimizar._circulos`: los círculos de choque de una pieza de base sx × sz centrada en c.
static void circulos(PackedVector3Array &sal, const Vector3 &c, double sx, double sz) {
	const double largo = lim_max(sx, sz);
	const double ancho = lim_min(sx, sz);
	if (largo <= ancho * 1.8) {
		sal.append(Vector3(c.x, c.z, real_t(clampf_(largo * 0.5, 0.15, 3.0))));
		return;
	}
	const double r_c = clampf_(ancho * 0.5, 0.15, 2.5);
	const Vector2 eje = sx >= sz ? Vector2(1, 0) : Vector2(0, 1);
	const double sep = lim_max(0.0, largo * 0.5 - r_c);
	int64_t n = int64_t(std::ceil(sep * 2.0 / (2.0 * r_c))) + 1;
	if (n < 2) {
		n = 2;
	}
	for (int64_t i = 0; i < n; i++) {
		const double t = -sep + (sep - (-sep)) * (double(i) / double(n - 1)); // lerpf(-sep, sep, i / (n - 1))
		sal.append(Vector3(real_t(double(c.x) + double(eje.x) * t), real_t(double(c.z) + double(eje.y) * t), real_t(r_c)));
	}
}

PackedVector3Array DinastiaNativo::obstaculos_multimalla(const Transform3D &nodo_t, const PackedFloat32Array &buf, int64_t paso, int64_t n, const AABB &base,
		double raiz_y, double min_alto, double max_base, const Dictionary &rej, double celda_rej) const {
	PackedVector3Array sal;
	const float *b = buf.ptr();
	for (int64_t i = 0; i < n; i++) {
		const float *f = b + i * paso;
		// `BufferMM.transform_de`: filas de la matriz 3×4; el origen en 3, 7 y 11.
		const Transform3D t(Basis(Vector3(f[0], f[4], f[8]), Vector3(f[1], f[5], f[9]), Vector3(f[2], f[6], f[10])), Vector3(f[3], f[7], f[11]));
		const AABB caja = (nodo_t * t).xform(base);
		const double sx = caja.size.x;
		const double sz = caja.size.z;
		if (double(caja.size.y) < min_alto || double(caja.position.y) - raiz_y > max_base || lim_max(sx, sz) > 8.0 || lim_min(sx, sz) < 0.08) {
			continue;
		}
		const Vector3 c = caja.get_center();
		if (!en_rejilla(rej, celda_rej, c.x, c.z)) {
			circulos(sal, c, sx, sz);
		}
	}
	return sal;
}
