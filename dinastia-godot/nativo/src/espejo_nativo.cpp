// EL ESPEJO DE LAS ANIMACIONES, EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»). `AnimExtra.espejar` (visor/anim_extra_p1.gd, 26-9-2026): el mismo
// movimiento reflejado izquierda <-> derecha, evaluando la pose global a 30 fotogramas por segundo, reflejando el cuerpo y volviendo a rotaciones locales. Copia operación a operación
// (Basis, Transform3D y Quaternion de float de 32 bits, como GDScript; el tiempo en 64). La caché por clave sigue en GDScript. Gemela GDScript: `AnimExtra._espejar_gd`.
// `pruebas/probar_nativo_espejo.gd` compara los clips resultantes pista a pista.
#include "dinastia_nativo.h"

#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/basis.hpp>
#include <godot_cpp/variant/node_path.hpp>
#include <godot_cpp/variant/quaternion.hpp>
#include <godot_cpp/variant/transform3d.hpp>

#include <vector>

using namespace godot;

namespace {
// `AnimExtra._par`: el hueso del otro lado (`_l` <-> `_r`) o el mismo.
String par_de_nombre(const String &nombre) {
	if (nombre.ends_with("_l")) {
		return nombre.substr(0, nombre.length() - 2) + "_r";
	}
	if (nombre.ends_with("_r")) {
		return nombre.substr(0, nombre.length() - 2) + "_l";
	}
	return nombre;
}

// Un conjunto de huesos con su pista, que recuerda el orden de la primera inserción (como un Dictionary de GDScript).
struct Pistas {
	std::vector<int> pista;   // hueso -> pista (-1 = ninguna)
	std::vector<int> orden;   // huesos en orden de primera inserción
	explicit Pistas(int n) :
			pista(n, -1) {}
	void poner(int hueso, int t) {
		if (pista[hueso] < 0) {
			orden.push_back(hueso);
		}
		pista[hueso] = t;
	}
	bool tiene(int hueso) const {
		return pista[hueso] >= 0;
	}
};
}  // namespace

Ref<Animation> DinastiaNativo::anim_espejar(const Ref<Animation> &original, Skeleton3D *esq, const String &prefijo) const {
	const int n = esq->get_bone_count();
	Pistas rot(n), pos(n);
	for (int t = 0; t < original->get_track_count(); t++) {
		const String ruta = String(original->track_get_path(t));
		const String hueso = ruta.substr(ruta.rfind(":") + 1);
		const int i = esq->find_bone(hueso);
		if (i < 0) {
			continue;
		}
		switch (original->track_get_type(t)) {
			case Animation::TYPE_ROTATION_3D:
				rot.poner(i, t);
				break;
			case Animation::TYPE_POSITION_3D:
				pos.poner(i, t);
				break;
			default:
				break;
		}
	}
	if (rot.orden.empty()) {
		return Ref<Animation>();
	}
	// El reflejo del cuerpo: la x del modelo cambia de signo.
	const Basis S(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1));
	std::vector<int> par_de(n), padres(n);
	std::vector<Transform3D> reposo(n);
	for (int i = 0; i < n; i++) {
		const int p = esq->find_bone(par_de_nombre(esq->get_bone_name(i)));
		par_de[i] = p >= 0 ? p : i;
		padres[i] = esq->get_bone_parent(i);
		reposo[i] = esq->get_bone_rest(i);
	}
	// Reposo global y la corrección de ejes de cada par.
	std::vector<Transform3D> rg(n);
	for (int i = 0; i < n; i++) {
		const int pa = padres[i];
		rg[i] = pa < 0 ? reposo[i] : rg[pa] * reposo[i];
	}
	std::vector<Basis> corr(n);
	for (int i = 0; i < n; i++) {
		const int src = par_de[i];
		const Basis reflejado = S * rg[src].basis.orthonormalized() * S;
		corr[i] = reflejado.inverse() * rg[i].basis.orthonormalized();
	}
	Ref<Animation> out;
	out.instantiate();
	out->set_length(original->get_length());
	out->set_loop_mode(original->get_loop_mode());
	// Pistas de salida: todo hueso que tenga pista él o su par.
	Pistas destinos(n);
	for (int i : rot.orden) {
		destinos.poner(i, 0);
		destinos.poner(par_de[i], 0);
	}
	Pistas pistas_out(n);
	for (int i : destinos.orden) {
		const int t = out->add_track(Animation::TYPE_ROTATION_3D);
		out->track_set_path(t, NodePath(prefijo + String(":") + esq->get_bone_name(i)));
		pistas_out.poner(i, t);
	}
	Pistas pos_out(n);
	for (int i : pos.orden) {
		const int d = par_de[i];
		const int t2 = out->add_track(Animation::TYPE_POSITION_3D);
		out->track_set_path(t2, NodePath(prefijo + String(":") + esq->get_bone_name(d)));
		pos_out.poner(d, t2);
	}
	const double paso = 1.0 / 30.0;
	double tiempo = 0.0;
	const double largo = double(original->get_length());
	std::vector<Transform3D> g(n), ge(n);
	while (tiempo <= largo + 0.0001) {
		// Pose global del original.
		for (int i = 0; i < n; i++) {
			const Transform3D &loc = reposo[i];
			const Quaternion q = rot.tiene(i) ? original->rotation_track_interpolate(rot.pista[i], tiempo) : loc.basis.get_rotation_quaternion();
			const Vector3 o = pos.tiene(i) ? original->position_track_interpolate(pos.pista[i], tiempo) : loc.origin;
			const Transform3D tl(Basis(q), o);
			const int pa = padres[i];
			g[i] = pa < 0 ? tl : g[pa] * tl;
		}
		// Pose global espejada.
		for (int i = 0; i < n; i++) {
			const Transform3D &gs = g[par_de[i]];
			ge[i] = Transform3D(S * gs.basis.orthonormalized() * S * corr[i], S.xform(gs.origin));
		}
		for (int i : pistas_out.orden) {
			const int pa2 = padres[i];
			const Transform3D local = pa2 < 0 ? ge[i] : ge[pa2].affine_inverse() * ge[i];
			out->rotation_track_insert_key(pistas_out.pista[i], tiempo, local.basis.orthonormalized().get_rotation_quaternion());
		}
		for (int i : pos_out.orden) {
			const int pa3 = padres[i];
			const Transform3D local2 = pa3 < 0 ? ge[i] : ge[pa3].affine_inverse() * ge[i];
			out->position_track_insert_key(pos_out.pista[i], tiempo, local2.origin);
		}
		tiempo += paso;
	}
	return out;
}
