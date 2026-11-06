class_name BufferMM
extends RefCounted
## Lectura y escritura en bloque del `buffer` de un MultiMesh 3D (12 floats de transformación por instancia, filas; luego color y datos si se usan).

## Transformación 3D de la instancia cuyo primer float está en `b` del `buffer` de un MultiMesh (filas: base en 0-2, 4-6, 8-10; origen en 3, 7, 11).
static func transform_de(buf: PackedFloat32Array, b: int) -> Transform3D:
	return Transform3D(Vector3(buf[b], buf[b + 4], buf[b + 8]), Vector3(buf[b + 1], buf[b + 5], buf[b + 9]), Vector3(buf[b + 2], buf[b + 6], buf[b + 10]), Vector3(buf[b + 3], buf[b + 7], buf[b + 11]))
