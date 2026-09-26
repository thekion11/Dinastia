class_name MascotaQ
extends Node
## LA MASCOTA DEL CLUB, REHECHA (26-9-2026). Pedido del usuario: *"pueden
## mejorar las mascotas"*.
##
## Antes: una persona con la equipación y, pegadas a la cabeza, cuatro esferas
## de color plano (cabeza, hocico, ojos) y dos orejas; ocho animales, quieta
## saludando en bucle. Se leía como "un jugador con un globo en la cabeza".
##
## Ahora es un traje de mascota de verdad:
##   - PELAJE (`pelaje.gdshader`): mechones, grano, manchas, pelusa en el
##     borde a contraluz; rayas para el tigre y escamas para dragón, cocodrilo
##     y tiburón.
##   - CABEZA de dibujo animado: ojos grandes con iris, pupila y brillo, cejas,
##     sonrisa, mejillas, nariz, y un hocico o pico con la forma del animal.
##   - OREJAS, CUERNOS, CRESTAS Y MELENAS propios de cada uno de los 17
##     animales (antes 8).
##   - GUANTES enormes en las manos, PATAS en los pies y COLA (que se mueve).
##   - EL CUERPO: camiseta del club de manga larga y piernas del color del
##     pelaje, como los trajes de verdad.
##   - SE MUEVE: alterna saludo, aplauso, baile, salto, llamar a la hinchada…
##     y cada tanto da un paseo por la banda, en vez de un solo gesto en bucle.
## El animal sale del hash del club (`EstadioExtras.animal_de`): siempre el
## mismo para el mismo club.

## animal -> [color natural, orejas, hocico, cola, extra, mezcla con el club]
const ANIMALES := {
	"perro":     [Color(0.78, 0.58, 0.36), "caidas", "largo", "larga", "lengua", 0.30],
	"gato":      [Color(0.88, 0.62, 0.30), "puntiagudas", "redondo", "larga", "bigotes", 0.35],
	"oso":       [Color(0.46, 0.30, 0.18), "redondas", "redondo", "bola", "", 0.25],
	"aguila":    [Color(0.95, 0.95, 0.93), "", "pico", "plumas", "ceño", 0.10],
	"leon":      [Color(0.88, 0.66, 0.30), "redondas", "redondo", "larga_borla", "melena", 0.20],
	"toro":      [Color(0.30, 0.18, 0.12), "puntiagudas", "ancho", "larga_borla", "cuernos", 0.30],
	"zorro":     [Color(0.92, 0.46, 0.14), "puntiagudas", "largo", "tupida", "mejillas_blancas", 0.15],
	"lobo":      [Color(0.52, 0.52, 0.55), "puntiagudas", "largo", "tupida", "mejillas_blancas", 0.25],
	"tigre":     [Color(0.96, 0.56, 0.14), "redondas", "redondo", "larga", "rayas", 0.10],
	"gallo":     [Color(0.96, 0.95, 0.92), "", "pico", "plumas", "cresta", 0.20],
	"dragon":    [Color(0.22, 0.62, 0.32), "", "largo", "larga", "cuernos_dragon", 0.35],
	"caballo":   [Color(0.52, 0.33, 0.18), "caballo", "largo", "crin", "crin", 0.25],
	"conejo":    [Color(0.93, 0.91, 0.89), "largas", "redondo", "pompon", "dientes", 0.20],
	"pinguino":  [Color(0.08, 0.08, 0.11), "", "pico", "plumas", "antifaz", 0.15],
	"cocodrilo": [Color(0.26, 0.46, 0.22), "", "cocodrilo", "larga", "dientes_cocodrilo", 0.25],
	"buho":      [Color(0.56, 0.41, 0.26), "penachos", "pico", "plumas", "anteojos", 0.25],
	"mono":      [Color(0.46, 0.31, 0.20), "laterales", "redondo", "larga", "cara_clara", 0.20],
	"tiburon":   [Color(0.46, 0.52, 0.62), "", "tiburon", "aleta", "aleta_dorsal", 0.30],
}
const CON_ESCAMAS := ["dragon", "cocodrilo", "tiburon"]
const GESTOS := ["saludar_publico", "llamar_hinchada", "aplaudir", "baile", "puno_al_aire",
	"corazon_manos", "celebrar", "aplauso_arriba", "mano_oido", "saludo_mano"]

var _ap: AnimationPlayer
var _cuerpo: Node3D
var _cola: Node3D
var _t := 0.0
var _hasta := 0.0
var _caminando := false
var _dir := 1.0
var _giro0 := 0.0
var _rng := RandomNumberGenerator.new()

## Arma la mascota del club en `root` (ya dentro del árbol) y la devuelve.
static func crear(root: Node3D, c: Club, animal: String, pos: Vector3, giro_y: float) -> Node3D:
	if not root.is_inside_tree():
		return null
	var d := FutbolistaQ.crear(1.9, "male")
	if d.is_empty():
		return null
	var nodo: Node3D = d["nodo"]
	nodo.name = "Mascota"
	nodo.position = pos
	nodo.rotation_degrees.y = giro_y
	root.add_child(nodo)
	FutbolistaQ.terminar(d, true)
	var fila: Array = ANIMALES.get(animal, ANIMALES["oso"])
	var c1 := Color(c.color1)
	var c2 := Color(c.color2)
	var natural: Color = fila[0]
	var pelo: Color = natural.lerp(c1, float(fila[5]))
	## Camiseta del club de manga larga; piernas y "piel" del color del pelaje.
	VestidorQ.vestir_equipacion(d, c1, c2, "liso", pelo, pelo.darkened(0.2), pelo, pelo, true)

	var esq: Skeleton3D = d["esqueleto"]
	var k := 1.0 / maxf((d["modelo"] as Node3D).scale.x, 0.01)
	var mat_pelo := material_pelaje(pelo, animal)
	var claro := pelo.lightened(0.45) if animal != "pinguino" else Color(0.96, 0.96, 0.95)
	var mat_claro := material_pelaje(claro, "")

	## La cabeza, pegada al hueso para que se mueva con él.
	var cab := _pegar(esq, "Head", k)
	cab.position = Vector3(0, 0.13 * k, 0.03 * k)
	cabeza(cab, animal, fila, pelo, mat_pelo, mat_claro, c1, c2)

	## Guantes y patas: lo primero que delata un traje de mascota.
	var mat_guante := material_pelaje(Color(0.97, 0.97, 0.96) if animal in ["perro", "gato", "oso", "conejo", "mono", "leon"] else pelo.darkened(0.15), "")
	for lado in ["l", "r"]:
		var mano := _pegar(esq, "hand_" + lado, k)
		_esf(mano, Vector3(0, 0.075, 0), 0.1, mat_guante, Vector3(1.0, 1.2, 0.9))
		_cil(mano, Vector3(0, -0.01, 0), Vector3.ZERO, 0.07, 0.05, _mat(c2, 0.8))
		var pie := _pegar(esq, "foot_" + lado, k)
		_esf(pie, Vector3(0, 0.02, 0.06), 0.12, mat_pelo, Vector3(1.0, 0.75, 1.35))
		for dedo in [-1.0, 0.0, 1.0]:
			_esf(pie, Vector3(dedo * 0.05, 0.0, 0.17), 0.04, mat_claro)

	## La cola, colgando de la cintura por detrás (el modelo mira a +Z).
	var cola := Node3D.new()
	cola.name = "Cola"
	cola.position = Vector3(0, 0.95, -0.17)
	nodo.add_child(cola)
	_cola_de(cola, String(fila[3]), mat_pelo, mat_claro, c2)

	var ctl := MascotaQ.new()
	ctl.name = "Animador"
	ctl._ap = d["anim"]
	ctl._cuerpo = nodo
	ctl._cola = cola
	ctl._giro0 = nodo.rotation.y
	ctl._rng.seed = hash(c.id + "|mascota_baile")
	nodo.add_child(ctl)
	return nodo

func _ready() -> void:
	_gesto()

func _process(delta: float) -> void:
	delta = minf(delta, 0.1)
	_t += delta
	if _cola != null:
		_cola.rotation.y = sin(_t * (9.0 if not _caminando else 5.0)) * 0.45
		_cola.rotation.x = -0.25 + sin(_t * 3.1) * 0.08
	if _caminando and _cuerpo != null:
		## Paseo por la banda, de un lado al otro de su sitio.
		var fwd: Vector3 = _cuerpo.global_transform.basis.z.normalized()
		_cuerpo.position += fwd * 1.1 * delta
	if _t >= _hasta:
		_t = 0.0
		if _caminando:
			_caminando = false
			_cuerpo.rotation.y = _giro0
			_gesto()
		elif _rng.randf() < 0.3 and _ap.has_animation("caminar"):
			## Camina a lo largo de la banda (de lado respecto de la
			## hinchada), una vez hacia cada lado: siempre vuelve a su sitio.
			_caminando = true
			_cuerpo.rotation.y = _giro0 + PI * 0.5 * _dir
			_dir = -_dir
			_ap.play("caminar")
			_hasta = _rng.randf_range(2.5, 4.0)
		else:
			_gesto()

func _gesto() -> void:
	if _ap == null:
		return
	var hay: Array[String] = []
	for g: String in GESTOS:
		if _ap.has_animation(g):
			hay.append(g)
	if hay.is_empty():
		if _ap.has_animation("parado"):
			_ap.play("parado")
		_hasta = 5.0
		return
	var g2: String = hay[_rng.randi() % hay.size()]
	_ap.play(g2, 0.25)
	_hasta = maxf(_ap.current_animation_length, 1.5) * float(_rng.randi_range(1, 2))

# -----------------------------------------------------------------------------
#  LA CABEZA
# -----------------------------------------------------------------------------

static func cabeza(cab: Node3D, animal: String, fila: Array, pelo: Color, mat_pelo: Material,
		mat_claro: Material, c1: Color, c2: Color) -> void:
	var oscuro := _mat(Color(0.06, 0.05, 0.05), 0.35)
	var rosa := _mat(Color(0.95, 0.58, 0.62), 0.8)
	var hocico := String(fila[2])
	var extra := String(fila[4])
	## El cráneo: un poco más ancho que alto, como los trajes.
	_esf(cab, Vector3.ZERO, 0.34, mat_pelo, Vector3(1.06, 0.97, 0.94))

	## LOS OJOS: blanco, iris, pupila y el brillo que les da vida.
	var ojo_y := 0.08
	var ojo_z := 0.27
	var sep := 0.125
	if hocico == "cocodrilo":
		ojo_y = 0.2
		ojo_z = 0.2
	var iris_col := Color(0.35, 0.22, 0.1) if animal not in ["aguila", "buho", "tigre", "gato", "lobo", "dragon"] else Color(0.95, 0.72, 0.1)
	if extra == "anteojos":
		for s in [-1.0, 1.0]:
			_esf(cab, Vector3(sep * s * 1.1, ojo_y, ojo_z - 0.02), 0.14, mat_claro, Vector3(1, 1, 0.45))
	if extra == "antifaz":
		_esf(cab, Vector3(0, -0.02, 0.12), 0.27, mat_claro, Vector3(1.05, 0.95, 0.85))
	for s in [-1.0, 1.0]:
		var o := Vector3(sep * s, ojo_y, ojo_z)
		_esf(cab, o, 0.09, _mat(Color(0.98, 0.98, 0.97), 0.25), Vector3(1.0, 1.18, 0.62))
		_esf(cab, o + Vector3(0.008 * s, -0.005, 0.045), 0.052, _mat(iris_col, 0.3), Vector3(1, 1.1, 0.5))
		_esf(cab, o + Vector3(0.01 * s, -0.005, 0.062), 0.03, oscuro, Vector3(1, 1.15, 0.5))
		var brillo := _mat(Color.WHITE, 0.1, 1.2)
		_esf(cab, o + Vector3(0.022 * s + 0.01, 0.02, 0.078), 0.012, brillo)
		## Cejas: expresivas, del segundo color del club (el ceño del águila
		## las inclina hacia adentro).
		var ceja := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.014
		cm.height = 0.1
		ceja.mesh = cm
		ceja.material_override = _mat(pelo.darkened(0.55), 0.8)
		ceja.position = o + Vector3(0, 0.11, 0.0)
		ceja.rotation_degrees = Vector3(0, 0, 90.0 + (-22.0 if extra == "ceño" else 12.0) * s)
		cab.add_child(ceja)
		## Mejillas.
		if hocico != "pico" and hocico != "cocodrilo" and hocico != "tiburon":
			_esf(cab, Vector3(0.2 * s, -0.06, 0.22), 0.05, _mat(Color(1.0, 0.55, 0.55), 0.9, 0.0, 0.55))

	## EL HOCICO (o pico), la nariz y la sonrisa.
	var punta := Vector3(0, -0.07, 0.4)
	match hocico:
		"redondo":
			_esf(cab, Vector3(0, -0.09, 0.25), 0.15, mat_claro, Vector3(1.2, 0.85, 0.9))
			punta = Vector3(0, -0.04, 0.385)
		"ancho":
			_esf(cab, Vector3(0, -0.1, 0.26), 0.17, mat_claro, Vector3(1.4, 0.85, 0.9))
			punta = Vector3(0, -0.06, 0.41)
			for s in [-1.0, 1.0]:
				_esf(cab, Vector3(0.06 * s, -0.08, 0.41), 0.025, oscuro)
			var aro := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.035
			tm.outer_radius = 0.05
			aro.mesh = tm
			aro.material_override = _mat(Color(0.85, 0.75, 0.3), 0.25)
			aro.position = Vector3(0, -0.16, 0.41)
			aro.rotation_degrees = Vector3(90, 0, 0)
			cab.add_child(aro)
		"largo":
			_esf(cab, Vector3(0, -0.07, 0.3), 0.14, mat_claro if animal in ["perro", "lobo", "zorro"] else mat_pelo, Vector3(0.85, 0.75, 1.55))
			punta = Vector3(0, -0.03, 0.51)
		"pico":
			var col_pico := Color(1.0, 0.72, 0.1) if animal != "pinguino" else Color(1.0, 0.5, 0.1)
			var pico := _mat(col_pico, 0.4)
			_cono(cab, Vector3(0, -0.04, 0.37), Vector3(80, 0, 0), 0.075, 0.22 if animal != "buho" else 0.12, pico)
			if animal == "aguila":
				_esf(cab, Vector3(0, -0.1, 0.44), 0.035, pico)
			punta = Vector3.ZERO
		"cocodrilo":
			_esf(cab, Vector3(0, -0.06, 0.34), 0.17, mat_pelo, Vector3(0.95, 0.45, 2.0))
			punta = Vector3(0, 0.0, 0.66)
		"tiburon":
			_esf(cab, Vector3(0, -0.02, 0.2), 0.2, mat_pelo, Vector3(1.0, 0.7, 1.4))
			_esf(cab, Vector3(0, -0.12, 0.22), 0.18, mat_claro, Vector3(1.0, 0.45, 1.3))
			punta = Vector3.ZERO
	if punta != Vector3.ZERO:
		_esf(cab, punta, 0.045 if hocico != "cocodrilo" else 0.025, oscuro, Vector3(1.3, 0.9, 1.0))
		## Sonrisa: un arco de puntos bajo la nariz.
		if hocico != "cocodrilo":
			for i in range(-3, 4):
				var x := float(i) * 0.028
				_esf(cab, Vector3(x, punta.y - 0.075 + x * x * 2.2, punta.z - 0.05 - absf(x) * 0.25), 0.013, oscuro)

	## LAS OREJAS.
	match String(fila[1]):
		"puntiagudas":
			for s in [-1.0, 1.0]:
				_cono(cab, Vector3(0.19 * s, 0.31, -0.02), Vector3(-8, 0, -22 * s), 0.1, 0.24, mat_pelo)
				_cono(cab, Vector3(0.19 * s, 0.3, 0.025), Vector3(-8, 0, -22 * s), 0.055, 0.15, rosa)
		"redondas":
			for s in [-1.0, 1.0]:
				_esf(cab, Vector3(0.24 * s, 0.26, -0.02), 0.1, mat_pelo, Vector3(1, 1, 0.5))
				_esf(cab, Vector3(0.24 * s, 0.26, 0.02), 0.06, rosa, Vector3(1, 1, 0.4))
		"caidas":
			for s in [-1.0, 1.0]:
				var oreja := _esf(cab, Vector3(0.33 * s, -0.02, -0.02), 0.13, _pelaje_oscuro(pelo), Vector3(0.45, 1.25, 0.75))
				oreja.rotation_degrees.z = 14.0 * s
		"largas":
			for s in [-1.0, 1.0]:
				var o2 := _caps(cab, Vector3(0.11 * s, 0.52, -0.03), Vector3(0, 0, -9 * s), 0.07, 0.5, mat_pelo)
				o2.scale = Vector3(1, 1, 0.5)
				var o3 := _caps(cab, Vector3(0.11 * s, 0.52, 0.0), Vector3(0, 0, -9 * s), 0.04, 0.4, rosa)
				o3.scale = Vector3(1, 1, 0.4)
		"laterales":
			for s in [-1.0, 1.0]:
				_esf(cab, Vector3(0.37 * s, 0.02, -0.02), 0.12, mat_pelo, Vector3(0.4, 1, 1))
				_esf(cab, Vector3(0.39 * s, 0.02, 0.0), 0.075, rosa, Vector3(0.3, 1, 1))
		"caballo":
			for s in [-1.0, 1.0]:
				_cono(cab, Vector3(0.13 * s, 0.34, -0.04), Vector3(0, 0, -12 * s), 0.06, 0.18, mat_pelo)
		"penachos":
			for s in [-1.0, 1.0]:
				_cono(cab, Vector3(0.2 * s, 0.3, 0.0), Vector3(0, 0, -30 * s), 0.07, 0.2, _pelaje_oscuro(pelo))

	## LO PROPIO DE CADA ANIMAL.
	match extra:
		"melena":
			var mat_melena := material_pelaje(pelo.lerp(c2, 0.25).darkened(0.35), "")
			for i in range(16):
				var a := TAU * float(i) / 16.0
				_esf(cab, Vector3(cos(a) * 0.35, sin(a) * 0.33, -0.06), 0.13, mat_melena)
			_esf(cab, Vector3(0, 0.02, -0.14), 0.36, mat_melena)
		"cuernos":
			var hueso := _mat(Color(0.95, 0.9, 0.8), 0.45)
			for s in [-1.0, 1.0]:
				_cil(cab, Vector3(0.3 * s, 0.2, 0), Vector3(0, 0, -70 * s), 0.05, 0.16, hueso)
				_cono(cab, Vector3(0.42 * s, 0.3, 0), Vector3(0, 0, -20 * s), 0.05, 0.2, hueso)
		"cuernos_dragon":
			var cuerno := _mat(Color(0.95, 0.85, 0.55), 0.5)
			for s in [-1.0, 1.0]:
				_cono(cab, Vector3(0.15 * s, 0.3, -0.12), Vector3(-45, 0, -10 * s), 0.06, 0.3, cuerno)
			for i in range(4):
				_cono(cab, Vector3(0, 0.32 - i * 0.1, -0.2 - i * 0.07), Vector3(-40 - i * 15, 0, 0), 0.05, 0.14, _mat(c2, 0.6))
			for s in [-1.0, 1.0]:
				_esf(cab, Vector3(0.04 * s, 0.0, 0.52), 0.018, oscuro)
		"cresta":
			var rojo := _mat(Color(0.88, 0.1, 0.12), 0.6)
			for i in range(4):
				_esf(cab, Vector3(0, 0.34 + (0.03 if i % 2 == 1 else 0.0), 0.12 - i * 0.1), 0.075, rojo, Vector3(0.5, 1, 1))
			_esf(cab, Vector3(0, -0.2, 0.36), 0.05, rojo, Vector3(0.7, 1.4, 0.7))
		"crin":
			var crin := material_pelaje(c2.darkened(0.2), "")
			for i in range(6):
				_esf(cab, Vector3(0, 0.33 - i * 0.04, 0.12 - i * 0.1), 0.06, crin, Vector3(0.5, 1.4, 1))
		"lengua":
			_esf(cab, Vector3(0.03, -0.2, 0.43), 0.05, rosa, Vector3(1, 0.4, 1.3))
		"bigotes":
			for s in [-1.0, 1.0]:
				for j in range(3):
					_cil(cab, Vector3(0.14 * s, -0.08 + j * 0.02, 0.36), Vector3(0, 0, 90 + (j - 1) * 12 * s), 0.004, 0.2, oscuro)
		"dientes":
			var blanco := _mat(Color(0.98, 0.98, 0.96), 0.3)
			for s in [-0.5, 0.5]:
				var dnt := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.035, 0.05, 0.015)
				dnt.mesh = bm
				dnt.material_override = blanco
				dnt.position = Vector3(0.02 * s * 2.0, -0.16, 0.37)
				cab.add_child(dnt)
		"dientes_cocodrilo", "aleta_dorsal":
			var blanco2 := _mat(Color(0.98, 0.98, 0.96), 0.3)
			var z0 := 0.3 if extra == "dientes_cocodrilo" else 0.25
			for s in [-1.0, 1.0]:
				for j in range(5):
					_cono(cab, Vector3(0.12 * s, -0.12, z0 + j * 0.06), Vector3(180, 0, 0), 0.018, 0.045, blanco2)
			if extra == "aleta_dorsal":
				var aleta := _cono(cab, Vector3(0, 0.42, -0.08), Vector3(-20, 0, 0), 0.16, 0.3, mat_pelo)
				aleta.scale = Vector3(0.3, 1, 1)
		"mejillas_blancas":
			for s in [-1.0, 1.0]:
				_esf(cab, Vector3(0.2 * s, -0.1, 0.16), 0.12, mat_claro, Vector3(1, 0.8, 0.8))
		"cara_clara":
			_esf(cab, Vector3(0, 0.0, 0.2), 0.22, mat_claro, Vector3(1.1, 1.05, 0.6))

# -----------------------------------------------------------------------------
#  LA COLA
# -----------------------------------------------------------------------------

static func _cola_de(cola: Node3D, tipo: String, mat_pelo: Material, mat_claro: Material, c2: Color) -> void:
	match tipo:
		"larga", "larga_borla", "tupida":
			var n := 7
			for i in range(n):
				var f := float(i) / float(n - 1)
				var r := lerpf(0.075, 0.04, f) * (1.6 if tipo == "tupida" else 1.0)
				## Baja y luego se curva hacia arriba, como una "S" suave.
				var p := Vector3(0, -0.1 * sin(f * PI) + f * 0.25, -f * 0.55)
				_esf(cola, p, r, mat_pelo)
			if tipo == "larga_borla":
				_esf(cola, Vector3(0, 0.27, -0.58), 0.08, material_pelaje(c2.darkened(0.3), ""))
			if tipo == "tupida":
				_esf(cola, Vector3(0, 0.27, -0.6), 0.075, mat_claro)
		"bola":
			_esf(cola, Vector3(0, 0, -0.04), 0.09, mat_pelo)
		"pompon":
			_esf(cola, Vector3(0, 0, -0.05), 0.11, mat_claro)
		"plumas":
			for i in range(5):
				var pl := _cono(cola, Vector3((i - 2) * 0.05, -0.05, -0.12), Vector3(-110, (i - 2) * 14.0, 0), 0.05, 0.3, mat_pelo)
				pl.scale = Vector3(1, 1, 0.3)
		"crin":
			var crin := material_pelaje(c2.darkened(0.2), "")
			for i in range(5):
				_caps(cola, Vector3((i - 2) * 0.03, -0.25, -0.08), Vector3(-20, 0, (i - 2) * 6.0), 0.035, 0.55, crin)
		"aleta":
			var al := _cono(cola, Vector3(0, 0, -0.18), Vector3(-90, 0, 0), 0.12, 0.3, mat_pelo)
			al.scale = Vector3(0.3, 1, 1)

# -----------------------------------------------------------------------------
#  MATERIALES Y PIEZAS
# -----------------------------------------------------------------------------

static var _cache_pelaje: Dictionary = {}

static func material_pelaje(col: Color, animal: String) -> ShaderMaterial:
	var clave := col.to_html() + "|" + animal
	if _cache_pelaje.has(clave):
		return _cache_pelaje[clave]
	var m := ShaderMaterial.new()
	m.shader = load("res://visor/pelaje.gdshader")
	m.set_shader_parameter("color", col)
	m.set_shader_parameter("color_puntas", col.lightened(0.25))
	m.set_shader_parameter("rayas", 0.85 if animal == "tigre" else 0.0)
	m.set_shader_parameter("escamas", 1.0 if animal in CON_ESCAMAS else 0.0)
	_cache_pelaje[clave] = m
	return m

static func _pelaje_oscuro(col: Color) -> ShaderMaterial:
	return material_pelaje(col.darkened(0.3), "")

static func _mat(col: Color, rug: float = 0.7, emision: float = 0.0, alfa: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col, alfa)
	m.roughness = rug
	if emision > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emision
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

## Un nodo pegado a un hueso, con la escala del modelo compensada: dentro,
## las medidas son metros reales.
static func _pegar(esq: Skeleton3D, hueso: String, k: float) -> Node3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = hueso
	esq.add_child(ba)
	var n := Node3D.new()
	n.scale = Vector3.ONE * k
	ba.add_child(n)
	return n

static func _esf(root: Node3D, pos: Vector3, r: float, m: Material, esc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 20
	sm.rings = 10
	mi.mesh = sm
	mi.material_override = m
	mi.position = pos
	mi.scale = esc
	root.add_child(mi)
	return mi

static func _cono(root: Node3D, pos: Vector3, giro: Vector3, r: float, h: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = giro
	root.add_child(mi)
	return mi

static func _cil(root: Node3D, pos: Vector3, giro: Vector3, r: float, h: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = giro
	root.add_child(mi)
	return mi

static func _caps(root: Node3D, pos: Vector3, giro: Vector3, r: float, h: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = giro
	root.add_child(mi)
	return mi
