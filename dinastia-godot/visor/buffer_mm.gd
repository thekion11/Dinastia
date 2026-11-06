class_name BufferMM
extends RefCounted
## Lectura y escritura en bloque del `buffer` de un MultiMesh 3D (12 floats de transformación por instancia, filas; luego color y datos si se usan).

## Transformación 3D de la instancia cuyo primer float está en `b` del `buffer` de un MultiMesh (filas: base en 0-2, 4-6, 8-10; origen en 3, 7, 11).
static func transform_de(buf: PackedFloat32Array, b: int) -> Transform3D:
	return Transform3D(Vector3(buf[b], buf[b + 4], buf[b + 8]), Vector3(buf[b + 1], buf[b + 5], buf[b + 9]), Vector3(buf[b + 2], buf[b + 6], buf[b + 10]), Vector3(buf[b + 3], buf[b + 7], buf[b + 11]))

## Inverso: arma el `buffer` (12 floats por instancia) de una lista de transformaciones, ya multiplicadas por `previa` (`previa * ts[i]`).
static func buffer_de(ts: Array, previa: Transform3D) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(ts.size() * 12)
	for i in ts.size():
		var t: Transform3D = previa * (ts[i] as Transform3D)
		var a := t.basis
		var o := t.origin
		var b := i * 12
		buf[b] = a.x.x
		buf[b + 1] = a.y.x
		buf[b + 2] = a.z.x
		buf[b + 3] = o.x
		buf[b + 4] = a.x.y
		buf[b + 5] = a.y.y
		buf[b + 6] = a.z.y
		buf[b + 7] = o.y
		buf[b + 8] = a.x.z
		buf[b + 9] = a.y.z
		buf[b + 10] = a.z.z
		buf[b + 11] = o.z
	return buf

## Pone en `mm` (con `instance_count` ya fijado) las transformaciones `previa * ts[i]`: en bloque, salvo sin pantalla (el MultiMesh simulado no guarda datos: instancia a instancia, como antes).
static func llenar(mm: MultiMesh, ts: Array, previa: Transform3D) -> void:
	if DisplayServer.get_name() == "headless":
		for i in ts.size():
			mm.set_instance_transform(i, previa * (ts[i] as Transform3D))
	else:
		mm.buffer = buffer_de(ts, previa)
