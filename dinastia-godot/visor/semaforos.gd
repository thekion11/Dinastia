class_name Semaforos
extends Node3D
## LOS SEMÁFOROS DE LA CIUDAD (7-10-2026). En cada cruce de avenida hay dos
## postes (esquinas opuestas) con una cabeza para cada eje. Todos los cruces
## comparten el mismo ciclo por ejes:
##   eje 0 (norte-sur): VERDE 14 s → ÁMBAR 3 s → ROJO; eje 1 (este-oeste) igual,
##   desfasado, con 1 s de todo rojo entre medias.
## Las luces son seis MultiMesh (eje × color) que se encienden cambiando la
## emisión de su material: cuesta lo mismo con 10 cruces que con 200.
## `verde(eje)` es lo que consulta el tráfico para frenar en rojo.

const VERDE := 14.0
const AMBAR := 3.0
const TODO_ROJO := 1.0
const CICLO := (VERDE + AMBAR + TODO_ROJO) * 2.0

var t := 0.0
var cruces: Array = []
var _luces := {}   ## "eje|color" -> StandardMaterial3D

func montar(lista: Array, exp: CiudadExpansion) -> void:
	cruces = lista
	var postes: Array[Transform3D] = []
	var cabezas: Array[Transform3D] = []
	var luces := {}
	for eje in 2:
		for col in ["r", "a", "v"]:
			luces["%d|%s" % [eje, col]] = [] as Array[Transform3D]
	var off := CiudadExpansion.ANCHO_AV * 0.5 + 1.2
	for p: Vector3 in cruces:
		for esquina: Vector2 in [Vector2(1, 1), Vector2(-1, -1)]:
			var base := p + Vector3(esquina.x * off, 0, esquina.y * off)
			postes.append(Transform3D(Basis.from_scale(Vector3(0.18, 5.2, 0.18)), base + Vector3(0, 2.6, 0)))
			## Una cabeza mirando a cada eje (al tráfico que llega).
			for eje in 2:
				var mira := Vector3(0, 0, -esquina.y) if eje == 0 else Vector3(-esquina.x, 0, 0)
				var lado := Vector3(mira.z, 0, -mira.x) * 0.0
				var c := base + Vector3(0, 4.4, 0) + mira * 0.35 + lado
				cabezas.append(Transform3D(Basis.from_scale(Vector3(0.75, 2.2, 0.6)), c))
				for k in 3:
					var col := ["r", "a", "v"][k] as String
					var pl := c + Vector3(0, 0.68 - float(k) * 0.68, 0) + mira * 0.33
					(luces["%d|%s" % [eje, col]] as Array).append(Transform3D(Basis.from_scale(Vector3.ONE * 0.48), pl))
	var gris := StandardMaterial3D.new()
	gris.albedo_color = Color(0.22, 0.23, 0.24)
	gris.roughness = 0.5
	_mm(CylinderMesh.new(), gris, postes)
	var negro := StandardMaterial3D.new()
	negro.albedo_color = Color(0.08, 0.08, 0.09)
	_mm(BoxMesh.new(), negro, cabezas)
	var esf := SphereMesh.new()
	esf.radial_segments = 8
	esf.rings = 4
	for clave: String in luces:
		var col := clave.split("|")[1]
		var m := StandardMaterial3D.new()
		var base_c := {"r": Color(1, 0.12, 0.08), "a": Color(1, 0.7, 0.05), "v": Color(0.15, 1, 0.35)}[col] as Color
		m.albedo_color = base_c * 0.25
		m.emission_enabled = true
		m.emission = base_c
		m.emission_energy_multiplier = 0.0
		_luces[clave] = m
		var lista2: Array[Transform3D] = []
		lista2.assign(luces[clave])
		_mm(esf, m, lista2)
	_aplicar()

func _mm(malla: Mesh, mat: Material, ts: Array[Transform3D]) -> void:
	if ts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	add_child(mi)

func _process(delta: float) -> void:
	t = fmod(t + delta, CICLO)
	_aplicar()

## "v", "a" o "r" para el eje en este instante.
func estado(eje: int) -> String:
	var fase := fmod(t - (0.0 if eje == 0 else CICLO * 0.5) + CICLO, CICLO)
	if fase < VERDE:
		return "v"
	if fase < VERDE + AMBAR:
		return "a"
	return "r"

func verde(eje: int) -> bool:
	return estado(eje) == "v"

func _aplicar() -> void:
	for eje in 2:
		var e := estado(eje)
		for col in ["r", "a", "v"]:
			var m: StandardMaterial3D = _luces.get("%d|%s" % [eje, col])
			if m != null:
				m.emission_energy_multiplier = 3.0 if col == e else 0.0
