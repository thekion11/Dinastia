class_name RuedaPrensaMesa
extends RefCounted
## LA RUEDA DE PRENSA CON MESA LARGA Y EL DT SENTADO (10-11, R7 del análisis `docs/04_auditorias/PROLOGO_REFERENCIA_2026-11-10.md`). En la
## referencia del dueño el DT no está de pie en un atril: está SENTADO a una mesa larga con el frente del color del club y el escudo, el
## jefe de prensa a su lado y la pared de patrocinadores detrás. Solo con el personaje 3D del jugador (con el retrato 2D sigue el atril).
## Bandera `activa` (apagarla devuelve el atril de siempre). Los planos de cámara van aquí también (`PLANOS`, con el plano medio R6).
static var activa := true

const POS_DT := Vector3(0, 0, -0.95)
const MESA_Y := 0.78        ## el tablero
const MESA_Z := -0.45       ## centro de la mesa (frente en z≈0)
const JEFE_X := 0.95        ## el jefe de prensa, a la derecha del DT (vista desde la sala)
## Planos con el DT sentado (cabeza a ~1,2 m): 0 frontal de trabajo, 1 general desde el fondo, 2 tres cuartos, 3 plano MEDIO del DT
## con los micrófonos delante (R6: el de la respuesta, alterna con el frontal).
const PLANOS := [
	{"pos": Vector3(0.0, 1.32, 2.55), "mira": Vector3(0.0, 1.02, -0.8), "fov": 40.0},
	{"pos": Vector3(0.3, 2.3, 4.3), "mira": Vector3(0.0, 1.0, -1.2), "fov": 58.0},
	{"pos": Vector3(-1.2, 1.5, 0.6), "mira": Vector3(0.2, 1.05, -0.9), "fov": 42.0},   ## entre la mesa y la 1.ª fila (más atrás caía dentro de una cabeza)
	{"pos": Vector3(0.0, 1.22, 1.05), "mira": Vector3(0.0, 1.1, -0.95), "fov": 33.0},
]

## ¿Se monta la mesa en esta rueda? (con la bandera y con el personaje 3D del jugador).
static func usar() -> bool:
	return activa and not PersonajeDT.del_usuario.is_empty()

static func en(escena: Node) -> bool:
	return escena.has_meta("mesa")

## La mesa, su frente con el escudo, las dos sillas, el jefe de prensa y los extras (micrófonos, balón, focos) a la altura de la mesa.
static func montar(escena: Node3D, club: Club, c1: Color, c2: Color, rng: RandomNumberGenerator) -> void:
	escena.set_meta("mesa", true)
	var madera := _mat(Color(0.32, 0.24, 0.17), 0.55)
	var tablero := _caja(escena, Vector3(0, MESA_Y - 0.025, MESA_Z), Vector3(3.0, 0.05, 0.85), madera)
	tablero.name = "MesaPrensa"
	var frente_col := c1 if c1.get_luminance() > 0.12 else c1.lerp(c2, 0.25)
	_caja(escena, Vector3(0, MESA_Y * 0.5, MESA_Z + 0.41), Vector3(3.0, MESA_Y - 0.05, 0.03), _mat(frente_col.darkened(0.15), 0.7))
	## El escudo en el centro del frente (en la referencia, grande).
	if club != null:
		var tex := Escudo.textura(club, 160)
		if tex != null:
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.42, 0.42)
			q.mesh = qm
			var m := StandardMaterial3D.new()
			m.albedo_texture = tex
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			q.material_override = m
			q.position = Vector3(0, MESA_Y * 0.52, MESA_Z + 0.43)
			escena.add_child(q)
	## Las sillas: la del DT y la del jefe de prensa.
	var silla := _mat(Color(0.1, 0.1, 0.12), 0.6)
	for x: float in [0.0, JEFE_X]:
		_caja(escena, Vector3(x, 0.22, POS_DT.z - 0.04), Vector3(0.5, 0.44, 0.48), silla)
		_caja(escena, Vector3(x, 0.78, POS_DT.z - 0.27), Vector3(0.5, 0.7, 0.06), silla)
	_jefe_prensa(escena, rng)
	_atrezo(escena, club)
	RuedaPrensaExtras.montar(escena, c1, c2, true)

## R8: el DT ENTRA por la izquierda caminando, se gira hacia la sala y se sienta, como en la referencia. Si falta
## alguna animación, se sienta directamente. `entrada = false` (las pruebas que miran al DT ya sentado) lo sienta de golpe.
static var entrada := true
const ENTRA_DESDE := Vector3(-2.4, 0, -1.0)
const SEG_CAMINAR := 2.6

static func sentar(escena: Node, d: Dictionary) -> void:
	if not en(escena) or d.is_empty():
		return
	var ap: AnimationPlayer = d.get("anim") as AnimationPlayer
	var n: Node3D = d["nodo"]
	var raiz := n.get_parent() as Node3D
	var y_sentado := _y_silla(n)
	var caminar := ""
	if ap != null:
		if not ap.has_animation("caminar_formal"):
			load("res://visor/anim_extra.gd").asegurar(ap, d.get("esqueleto"), "caminar_formal")
		caminar = "caminar_formal" if ap.has_animation("caminar_formal") else ("caminar" if ap.has_animation("caminar") else "")
	if not entrada or caminar == "" or not ap.has_animation("sentado"):
		if ap != null and ap.has_animation("sentado"):
			ap.play("sentado")
		n.position.y = y_sentado
		return
	## Camina de lado hacia su silla (mirando a +X), gira hacia la sala y se sienta. La pose es la «sentado» de siempre (la de la
	## directiva): las de Sitting_Enter / Sitting_Talking de la biblioteca extra lo dejaban hundido bajo la mesa (otra altura de cadera).
	raiz.position = ENTRA_DESDE
	raiz.rotation.y = PI * 0.5
	ap.get_animation(caminar).loop_mode = Animation.LOOP_LINEAR
	ap.play(caminar, 0.2)
	## Mientras entra, la cámara se queda en el plano frontal (si no, el corte al periodista que pregunta se comía la entrada).
	var tw := escena.create_tween()
	escena.set_meta("entrada_tw", tw)   ## el tiempo del juego, no el reloj: en un equipo lento el reloj corría más que la animación
	tw.tween_property(raiz, "position", POS_DT, SEG_CAMINAR)
	tw.tween_property(raiz, "rotation:y", 0.0, 0.45)
	tw.tween_callback(func() -> void: ap.play("sentado", 0.35))
	tw.tween_property(n, "position:y", y_sentado, 0.4)

## Sentado, los gestos de cuerpo entero lo levantarían: solo la cara (la pose de hablar sentado de la biblioteca extra lo hundía).
## Devuelve true si se ocupó (con la mesa).
static func gesto_sentado(escena: Node, _d: Dictionary) -> bool:
	return en(escena)

## La altura del nodo del modelo para quedar sentado en su silla (la del asiento a 0,44 m).
static func _y_silla(n: Node3D) -> float:
	var cadera = CargaCiudad.de("MetroCiudad").altura_cadera(n)
	return n.position.y + (0.44 + 0.04 - cadera * 0.99 if cadera > 0.0 else 0.0)

static func _a_la_silla(d: Dictionary) -> void:
	var n: Node3D = d["nodo"]
	n.position.y = _y_silla(n)

## El jefe de prensa: traje y corbata, sentado a la derecha del DT.
static func _jefe_prensa(escena: Node3D, rng: RandomNumberGenerator) -> void:
	var raiz := Node3D.new()
	raiz.name = "JefePrensa"
	raiz.position = Vector3(JEFE_X, 0, POS_DT.z)
	escena.add_child(raiz)
	var asp := PersonajeDT.aleatorio(rng)
	asp.merge({"ropa": "traje", "c_ropa": "22252b", "c_ropa2": "f2f2f2", "corbata": true, "gorra": false, "auriculares": false}, true)
	var d := PersonajeDT.crear(raiz, asp, Color(0.13, 0.15, 0.2), Color.WHITE)
	if d.is_empty():
		raiz.queue_free()
		return
	CargaCiudad.de("PeatonQ").calzar(d, "1c1c1e")
	var ap: AnimationPlayer = d.get("anim") as AnimationPlayer
	if ap != null and ap.has_animation("sentado"):
		ap.play("sentado")
	_a_la_silla(d)
	raiz.rotation.y = -0.18   ## un poco girado hacia el DT

static func _mat(c: Color, rug: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	return m

static func _caja(escena: Node3D, pos: Vector3, tam: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	escena.add_child(mi)
	return mi

## ¿El DT está entrando? (la cámara espera en el plano frontal).
static func entrando(escena: Node) -> bool:
	if not escena.has_meta("entrada_tw"):
		return false
	var tw = escena.get_meta("entrada_tw")
	return tw is Tween and (tw as Tween).is_valid() and (tw as Tween).is_running()

## LO QUE HAY ENCIMA DE UNA MESA DE PRENSA DE VERDAD (10-11, «puedes hacerlo muchísimo mejor»): una placa delante de cada uno con el
## escudo, una botella de agua y un vaso para cada uno.
static func _atrezo(escena: Node3D, club: Club) -> void:
	var placa := _mat(Color(0.08, 0.08, 0.1), 0.4)
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.75, 0.88, 0.95, 0.35)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.roughness = 0.05
	vidrio.metallic = 0.2
	var tapa := _mat(Color(0.1, 0.35, 0.8), 0.4)
	var tex: Texture2D = Escudo.textura(club, 96) if club != null else null
	for x: float in [0.0, JEFE_X]:
		## La placa: un prisma bajo inclinado hacia la sala con el escudo pequeño.
		var pl := _caja(escena, Vector3(x, MESA_Y + 0.05, MESA_Z + 0.3), Vector3(0.34, 0.1, 0.04), placa)
		pl.rotation_degrees.x = -18.0
		if tex != null:
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.075, 0.075)
			q.mesh = qm
			var m := StandardMaterial3D.new()
			m.albedo_texture = tex
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			q.material_override = m
			q.position = Vector3(0, 0, 0.021)
			pl.add_child(q)
		## Botella y vaso, a la derecha de cada uno.
		var bx := x + 0.3
		var bot := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.032
		cm.bottom_radius = 0.035
		cm.height = 0.22
		cm.radial_segments = 12
		bot.mesh = cm
		bot.material_override = vidrio
		bot.position = Vector3(bx, MESA_Y + 0.11, MESA_Z - 0.05)
		escena.add_child(bot)
		var tp := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.016
		tm.bottom_radius = 0.016
		tm.height = 0.03
		tm.radial_segments = 8
		tp.mesh = tm
		tp.material_override = tapa
		tp.position = bot.position + Vector3(0, 0.125, 0)
		escena.add_child(tp)
		var vaso := MeshInstance3D.new()
		var vm := CylinderMesh.new()
		vm.top_radius = 0.035
		vm.bottom_radius = 0.028
		vm.height = 0.1
		vm.radial_segments = 12
		vaso.mesh = vm
		vaso.material_override = vidrio
		vaso.position = Vector3(bx + 0.1, MESA_Y + 0.05, MESA_Z + 0.08)
		escena.add_child(vaso)

## LUZ DE PLATÓ (10-11): en la referencia la sala está a oscuras y la luz cae sobre la mesa y la pared; los periodistas son SILUETAS.
## Los periodistas pasan a la capa visual 2 y las luces de la mesa, de la pared y del DT dejan de tocarlos (máscara 1); los ilumina solo
## el ambiente. Un foco cenital más sobre la mesa. Se llama al final de `montar()`, cuando ya están todas las luces.
static var luz_plato := true   ## bandera (las pruebas la apagan para comparar)
static func iluminar(escena: Node3D) -> void:
	if not en(escena) or not luz_plato:
		return
	var sala = escena.get("_sala")
	if sala is Array:
		for d: Dictionary in sala:
			var r := d.get("raiz") as Node3D
			if r != null:
				for g: Node in r.find_children("*", "GeometryInstance3D", true, false):
					(g as GeometryInstance3D).layers = 2
	var flash = escena.get("_flash")
	for l: Node in escena.find_children("*", "Light3D", true, false):
		if l != flash:
			(l as Light3D).light_cull_mask = 1
	## Sin luz propia para los periodistas: los ilumina solo el ambiente (cada luz de más es otra pasada de dibujo en Compatibilidad).
	var cenital := SpotLight3D.new()
	cenital.light_color = Color(1, 0.96, 0.88)
	cenital.light_energy = 2.2
	cenital.spot_range = 5.0
	cenital.spot_angle = 52.0   ## abierto: cubre al DT y al jefe de prensa (una luz menos)
	cenital.spot_attenuation = 1.2
	cenital.light_cull_mask = 1
	escena.add_child(cenital)
	cenital.look_at_from_position(Vector3(JEFE_X * 0.5, 3.1, 0.7), Vector3(JEFE_X * 0.5, 1.0, POS_DT.z + 0.2), Vector3.UP)
	for w: Node in escena.find_children("*", "WorldEnvironment", true, false):
		var env := (w as WorldEnvironment).environment
		if env != null:
			env.ambient_light_energy = 0.5   ## la sala, en penumbra (las luces de la mesa y la pared hacen el resto)
