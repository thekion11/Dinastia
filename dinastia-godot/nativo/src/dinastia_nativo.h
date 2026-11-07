// LOS BUCLES PESADOS, EN C++ (30-10-2026, rendimiento). Cada función es la traducción LITERAL
// de su versión GDScript (mismas operaciones, mismo orden y misma precisión: float de 64 bits
// donde GDScript usa `float`, de 32 donde usa Vector3), para dar los MISMOS bytes. Las pruebas
// lo comprueban (`pruebas/probar_nativo.tscn`); si la extensión no está (plataforma sin binario),
// el juego usa la versión GDScript (`Nativo` en nucleo/nativo.gd).
#pragma once

#include <godot_cpp/classes/fast_noise_lite.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/aabb.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

namespace godot {

class DinastiaNativo : public RefCounted {
	GDCLASS(DinastiaNativo, RefCounted)

protected:
	static void _bind_methods();

public:
	// `RuidosFondo._con_rampa`: cada gris de `src` pasa a los 4 bytes RGBA de la tabla `lut`.
	PackedByteArray rampa(const PackedByteArray &src, const PackedByteArray &lut) const;
	// `VestidorQ._alisado`: [CUSTOM0, CUSTOM1] de la ropa (suavizado de Taubin).
	Array alisado(const PackedVector3Array &pos, const PackedVector3Array &nor, const PackedInt32Array &idx) const;
	// `TerrenoArreglos.calcular_gd`: las baldosas [vértices, normales, UV] del relieve de la ciudad.
	Array terreno(const Ref<FastNoiseLite> &ruido, const Ref<FastNoiseLite> &detalle, double lado, int celdas,
			int baldosas, double llano_radio, double llano_trans, double alto, const Vector2 &monte, double monte_alto,
			double monte_radio) const;
	// `CityBuilder._imagen_hierba_gd`: la textura de hierba (azar del motor, misma secuencia).
	Ref<Image> hierba(const Ref<Image> &manchas, int64_t semilla) const;
	// `OnceAuto.asignar_gd` (el once automático de `Club.once`, M-469): para cada ranura (en `orden`) el índice del libre que la ocupa (-1 si nadie).
	// `ranuras` = {puestos, ks, ws, grupos, por}; `libres` = los `Jugador` (se leen aquí: pos_e, ovr, pos_sec, atributos, forma, moral); `grupo_de` = {pos_e: grupo}.
	// Calcula `Jugador.media_en` con los mismos pasos (los atributos de cada jugador se leen una sola vez).
	PackedInt32Array once_asignar_libres(const Dictionary &ranuras, const Array &libres, const Dictionary &grupo_de, const PackedInt32Array &orden) const;
	// `Optimizar.obstaculo_multimalla` (el bucle por instancia de un MultiMesh): los círculos de choque como PackedVector3Array [x, z, radio]. `buf` = el buffer del MultiMesh (`paso` floats por instancia).
	PackedVector3Array obstaculos_multimalla(const Transform3D &nodo_t, const PackedFloat32Array &buf, int64_t paso, int64_t n, const AABB &base, double raiz_y, double min_alto, double max_base,
			const Dictionary &rej, double celda_rej) const;
};

} // namespace godot
