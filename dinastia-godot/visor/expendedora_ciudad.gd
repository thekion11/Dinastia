class_name ExpendedoraCiudad
extends RefCounted
## LAS MÁQUINAS EXPENDEDORAS (27-10-2026, semana 6 del plan): cuerpo rojo, vitrina con latas y botellas, teclado y ranura. `montar` la pone en cualquier
## `CityBuilder` (ciudad, andén del metro, estadio) con su punto `expendedora_<n>`; `servicio` es el gancho de la E (vía `ComercioCiudad`).
## Sin azar: todo sale de la posición.
## La máquina como nodo suelto (sin `CityBuilder`): se usa también dentro del estadio y en el metro. Mira a su +Z; `pos` en el suelo.
static func nodo(pos: Vector3, giro: float) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = giro
	n.name = "Expendedora"
	var rojo := _mat(Color(0.78, 0.1, 0.1), 0.45)
	var gris := _mat(Color(0.2, 0.2, 0.22), 0.4)
	var vidrio := _mat(Color(0.12, 0.16, 0.2), 0.15)
	n.add_child(_caja(Vector3(0.0, 0.95, 0.0), Vector3(0.95, 1.9, 0.8), rojo))
	n.add_child(_caja(Vector3(-0.1, 1.2, 0.41), Vector3(0.6, 1.2, 0.03), vidrio))      ## vitrina
	var colores := [Color(0.95, 0.85, 0.2), Color(0.2, 0.6, 0.95), Color(0.95, 0.5, 0.15), Color(0.3, 0.8, 0.4)]
	for fila in 4:
		for col in 3:
			n.add_child(_caja(Vector3(-0.3 + float(col) * 0.2, 1.65 - float(fila) * 0.27, 0.43), Vector3(0.12, 0.2, 0.08), _mat(colores[(fila + col) % colores.size()], 0.5)))
	n.add_child(_caja(Vector3(0.36, 1.35, 0.41), Vector3(0.16, 0.5, 0.04), gris))      ## teclado y ranura
	n.add_child(_caja(Vector3(0.0, 0.3, 0.41), Vector3(0.7, 0.2, 0.04), gris))          ## trampilla de salida
	return n

static func _mat(c: Color, rug: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	return m

## En la ciudad: el nodo más su punto `expendedora_<n>` (E).
static func montar(b: CityBuilder, pos: Vector3, giro: float) -> void:
	var k := "expendedora_%d" % (absi(hash(Vector2(pos.x, pos.z))) % 100000)
	b.add_child(nodo(pos, giro))
	b.puntos_clic.append({"k": k, "n": Idiomas.t("Máquina expendedora"), "pos": pos, "estado": "ciudad", "radio": 8.0, "alcance": 3.0})

static func _caja(centro: Vector3, tam: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = centro
	return mi

static func servicio(e, k: String) -> bool:
	if not k.begins_with("expendedora_"):
		return false
	return e.vida != null and e.vida.usar_expendedora()
