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
## SEMÁFOROS PEATONALES CON BOTÓN (M-170, 28-10-2026): en cada poste, bajo la cabeza de cada eje, el hombrecito (rojo / verde, y verde
## intermitente los últimos `INTERMITE` s) de quien cruza en paralelo a ese eje, y un botón amarillo a 1,1 m. `pedir()` (E junto al poste)
## adelanta el siguiente verde peatonal a 2 s, o avisa de que ya se puede cruzar.

const VERDE := 14.0
const AMBAR := 3.0
const TODO_ROJO := 1.0
const CICLO := (VERDE + AMBAR + TODO_ROJO) * 2.0
const INTERMITE := 4.0   ## s finales del verde en que el hombrecito verde parpadea
const RADIO_BOTON := 2.6

var t := 0.0
var cruces: Array = []
var _luces := {}   ## "eje|color" -> StandardMaterial3D
var botones: Array[Vector3] = []   ## dónde está cada botón peatonal (en el poste, a 1,1 m)

func montar(lista: Array, exp: CiudadExpansion) -> void:
	cruces = lista
	var postes: Array[Transform3D] = []
	var cabezas: Array[Transform3D] = []
	var luces := {}
	for eje in 2:
		for col in ["r", "a", "v", "pr", "pv"]:
			luces["%d|%s" % [eje, col]] = [] as Array[Transform3D]
	var cab_p: Array[Transform3D] = []
	var brazos: Array[Transform3D] = []
	var botones_t: Array[Transform3D] = []
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
				## Peatonal de ese eje (28-10): cabeza de 30 × 60 cm a 2,5 m, en su propio brazo, mirando al paso de cebra de la acera de enfrente
				## (la ve quien espera al otro lado y cruza la calle PERPENDICULAR a este eje: verde solo cuando esa calle tiene rojo).
				var lat := Vector3(mira.z, 0, -mira.x)
				var ang := atan2(mira.x, mira.z)
				var cp := base + Vector3(0, 2.5, 0) + mira * 0.12 + lat * 0.62
				cab_p.append(Transform3D(Basis(Vector3.UP, ang).scaled_local(Vector3(0.3, 0.6, 0.16)), cp))
				var brazo := Basis(Vector3.UP, ang).scaled_local(Vector3(0.62, 0.06, 0.06))
				brazos.append(Transform3D(brazo, base + Vector3(0, 2.5, 0) + mira * 0.12 + lat * 0.31))
				var lente := Basis(Vector3.UP, ang).scaled_local(Vector3(0.24, 0.24, 1.0))
				(luces["%d|pr" % eje] as Array).append(Transform3D(lente, cp + Vector3(0, 0.15, 0) + mira * 0.085))
				(luces["%d|pv" % eje] as Array).append(Transform3D(lente, cp + Vector3(0, -0.15, 0) + mira * 0.085))
			## El botón peatonal en el poste, hacia la esquina de la acera.
			var pb: Vector3 = base + Vector3(-esquina.x * 0.16, 1.1, -esquina.y * 0.16)
			botones.append(pb)
			botones_t.append(Transform3D(Basis.from_scale(Vector3(0.14, 0.22, 0.1)), pb))
	var gris := StandardMaterial3D.new()
	gris.albedo_color = Color(0.22, 0.23, 0.24)
	gris.roughness = 0.5
	_mm(CylinderMesh.new(), gris, postes)
	var negro := StandardMaterial3D.new()
	negro.albedo_color = Color(0.08, 0.08, 0.09)
	_mm(BoxMesh.new(), negro, cabezas)
	_mm(BoxMesh.new(), negro, cab_p)
	_mm(BoxMesh.new(), gris, brazos)
	var amarillo := StandardMaterial3D.new()
	amarillo.albedo_color = Color(1.0, 0.82, 0.1)
	amarillo.emission_enabled = true
	amarillo.emission = Color(1.0, 0.8, 0.1)
	amarillo.emission_energy_multiplier = 0.5
	_mm(BoxMesh.new(), amarillo, botones_t)
	var esf := SphereMesh.new()
	esf.radial_segments = 8
	esf.rings = 4
	for clave: String in luces:
		var col := clave.split("|")[1]
		var m := StandardMaterial3D.new()
		var base_c := {"r": Color(1, 0.12, 0.08), "a": Color(1, 0.7, 0.05), "v": Color(0.15, 1, 0.35), "pr": Color(1, 0.12, 0.08), "pv": Color(0.15, 1, 0.35)}[col] as Color
		m.albedo_color = Color(base_c.r * 0.25, base_c.g * 0.25, base_c.b * 0.25, 1.0)
		m.emission_enabled = true
		m.emission = base_c
		m.emission_energy_multiplier = 0.0
		var peatonal_l := col.length() == 2
		if peatonal_l:
			## El hombrecito: quieto (rojo) o andando (verde), dibujado a mano sobre un fondo transparente.
			var tex := pictograma(col == "pv")
			m.albedo_texture = tex
			m.emission_texture = tex
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_luces[clave] = m
		var lista2: Array[Transform3D] = []
		lista2.assign(luces[clave])
		_mm(QuadMesh.new() if peatonal_l else esf, m, lista2)
	_aplicar()

## El pictograma peatonal de 64 × 64: la figura sobre transparente (el color lo pone el material). `anda` = piernas abiertas y brazos en balanceo.
static func pictograma(anda: bool) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 64:
		for x in 64:
			var dx := float(x) - 32.0
			var dy := float(y)
			var dentro := dx * dx + (dy - 11.0) * (dy - 11.0) <= 36.0   ## cabeza
			if not dentro and dy >= 20.0 and dy <= 40.0:
				dentro = absf(dx) <= 6.0   ## torso
			if not dentro and dy > 20.0 and dy < 42.0:
				var br := 12.0 - (dy - 20.0) * 0.5 if anda else 12.0
				dentro = absf(absf(dx) - br) <= 3.0   ## brazos
			if not dentro and dy > 38.0 and dy < 62.0:
				var abre := (dy - 38.0) * 0.55 if anda else 0.0
				dentro = absf(absf(dx) - (abre if anda else 4.5)) <= 3.5   ## piernas
			if dentro:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

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

## Estado peatonal del eje `eje` (el que cruza en paralelo a él): «v» verde fijo, «i» verde intermitente, «r» rojo.
func peatonal(eje: int) -> String:
	var fase := fmod(t - (0.0 if eje == 0 else CICLO * 0.5) + CICLO, CICLO)
	if fase < VERDE - INTERMITE:
		return "v"
	if fase < VERDE + AMBAR:
		return "i"
	return "r"

## Segundos hasta el siguiente verde peatonal de cualquier eje (0 si ya hay uno fijo).
func para_cruzar() -> float:
	var mejor := INF
	for eje in 2:
		var fase := fmod(t - (0.0 if eje == 0 else CICLO * 0.5) + CICLO, CICLO)
		mejor = minf(mejor, 0.0 if fase < VERDE - INTERMITE else CICLO - fase)
	return mejor

## El botón: si ya se puede cruzar, «ya»; si no, adelanta el siguiente verde para que llegue en 2 s y devuelve «espera».
func pedir() -> String:
	var falta := para_cruzar()
	if falta <= 0.0:
		return "ya"
	if falta > 2.0:
		t = fposmod(t + falta - 2.0, CICLO)
	return "espera"

## El jugador pulsa el botón: el aviso de la ciudad dice qué pasa (`e` es el `ExploradorCiudad`).
func pedir_con_aviso(e: Object) -> void:
	var r := pedir()
	Sonido.toca("puerta", Sonido.Bus.EFECTOS)
	e._aviso.text = Idiomas.t("Ya puedes cruzar.") if r == "ya" else Idiomas.t("Pedido: el hombrecito se pone verde en unos segundos.")

## El poste con botón más cercano a `p` (a menos de RADIO_BOTON), o INF si no hay.
func boton_cerca(p: Vector3) -> float:
	var mejor := INF
	for b: Vector3 in botones:
		mejor = minf(mejor, Vector2(b.x - p.x, b.z - p.z).length())
	return mejor if mejor <= RADIO_BOTON else INF

func _aplicar() -> void:
	for eje in 2:
		var pe := peatonal(eje)
		var verde_p := pe == "v" or (pe == "i" and int(t * 2.0) % 2 == 0)
		var mv: StandardMaterial3D = _luces.get("%d|pv" % eje)
		var mr: StandardMaterial3D = _luces.get("%d|pr" % eje)
		if mv != null:
			mv.emission_energy_multiplier = 1.3 if verde_p else 0.0
		if mr != null:
			mr.emission_energy_multiplier = 1.3 if pe == "r" else 0.0
	for eje in 2:
		var e := estado(eje)
		for col in ["r", "a", "v"]:
			var m: StandardMaterial3D = _luces.get("%d|%s" % [eje, col])
			if m != null:
				m.emission_energy_multiplier = 3.0 if col == e else 0.0
