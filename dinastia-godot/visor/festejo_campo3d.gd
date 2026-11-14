class_name FestejoCampo3D
extends HomenajeCampo3D
## LOS FESTEJOS DE TÍTULO EN 3D (10-11, el dueño pide realismo y animación): la misma base que el homenaje (césped de noche, grada del club
## en un MultiMesh, focos y papelitos, `HomenajeCampo3D`) con los MODELOS REALES del juego (`PlayerSpawner._crear_jugador`) y sus
## animaciones («celebrar», «celebrar_ls» de League-Soccer, «aplaudir», «saltar», «idle»). Modos (`TipoTitulo`):
##   escenario → tarima sobre el césped; el capitán levanta la copa de la competición (`Trofeo3D`) y el resto salta alrededor;
##   palco     → el equipo en un palco con baranda; las medallas se cuelgan de una en una y el capitán alza la copa;
##   fuegos    → el escenario más cohetes de colores (partículas) y más confeti;
##   sobrio    → el abrazo en el círculo central, aplaudiendo a la grada (ascenso y salvación);
##   manteo    → un corro que lanza al DT al aire: el DT SUBE Y BAJA de verdad;
##   foto      → dos filas frente a la cámara con la copa delante y el flash.
## La cámara se mueve sola (órbita lenta, distinta por modo). Coste: ≤ 9 jugadores, la grada en una llamada; `CON_3D` decide si se usa
## (calidad mínima → la escena 2D, `EscenaFestejo`). Sin pantalla no se monta (`crear` devuelve null).
const MODOS := ["escenario", "palco", "fuegos", "sobrio", "manteo", "foto", "champan", "desfile", "pasillo"]   ## los 3 últimos: `FestejoExtra3D`
const MAX_JUG := 9

var modo := "escenario"
var _copa: Node3D
var _capitan: Node3D
var _dt: Node3D
var _medallas: Array[Node3D] = []
var _flash: OmniLight3D
var _sin_copa := false   ## ascenso y salvación: sin trofeo
var _bus: Node3D   ## desfile (FestejoExtra3D)
var _caminan: Array[Node3D] = []   ## pasillo: el campeón que cruza
var _rival: Club
var _con_tifos := false   ## finales (copa, continental, supercopa, selección): tifos en la grada
var tifos := 0   ## lonas montadas (lo lee la prueba)
var jugadores := 0   ## cuántos modelos 3D se montaron (lo lee la prueba)
var estilo_camiseta := "liso"   ## (14-11) el diseño de la camiseta; las entregas de premios ponen el del club

## ¿Se usa el 3D? No en calidad mínima (ahí la escena 2D es el respaldo).
static func con_3d() -> bool:
	return DisplayServer.get_name() != "headless" and Calidad.elegida > Calidad.MINIMO

static func crear(m: String, club: Club, titulo: String, sin_copa := false, rival: Club = null, con_tifos := false) -> FestejoCampo3D:
	if DisplayServer.get_name() == "headless" or club == null:
		return null
	var h := FestejoCampo3D.new()
	h.modo = m
	h.stretch = true
	h.custom_minimum_size = Vector2(900, 360)
	h._vp = SubViewport.new()
	h._vp.own_world_3d = true
	h._vp.msaa_3d = Calidad.msaa_ui(Viewport.MSAA_2X)
	h.add_child(h._vp)
	h._sin_copa = sin_copa
	h._rival = rival
	h._con_tifos = con_tifos
	h._montar(club, titulo)
	return h

func _montar(club: Club, titulo: String) -> void:
	var c1 := Color(club.color1)
	var c2 := Color(club.color2)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.7)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = Calidad.elegida > Calidad.BAJA
	env.glow_intensity = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	var fuera := modo in ["champan", "desfile"]   ## vestuario y calle: sin césped ni grada
	if fuera:
		env.background_color = Color(0.36, 0.42, 0.58) if modo == "desfile" else Color(0.1, 0.1, 0.12)   ## (10-11) cielo de tarde azulado: el anaranjado claro se quemaba con el brillo
		env.glow_enabled = false
		env.ambient_light_energy = 0.55 if modo == "desfile" else 0.9   ## (10-11) en Forward+ la calle salía quemada con 0,9 más el sol
	else:
		_cesped(raiz)
		_grada(raiz, c1, c2)
		_focos(raiz)
		if _con_tifos:
			tifos = FestejoExtra3D.tifos(raiz, club, c1, c2)
	if modo not in ["sobrio", "champan", "desfile"]:
		_papelitos(raiz)
	_copa = Trofeo3D.de_competicion(titulo, 0.9)
	_copa.visible = not _sin_copa
	raiz.add_child(_copa)
	var once: Array = club.once()
	if once.is_empty():
		once = club.plantilla.slice(0, MAX_JUG)
	var spawner = load("res://visor/player_spawner.gd").new()
	match modo:
		"escenario", "fuegos": _escenario(raiz, spawner, once, c1, c2)
		"palco": _palco(raiz, spawner, once, c1, c2)
		"sobrio": _sobrio(raiz, spawner, once, c1, c2)
		"manteo": _manteo(raiz, spawner, once, c1, c2)
		"foto": _foto(raiz, spawner, once, c1, c2)
		"champan":
			_copa.visible = false
			FestejoExtra3D.champan(self, raiz, spawner, once, c1, c2)
		"desfile":
			_bus = FestejoExtra3D.desfile(self, raiz, spawner, once, c1, c2)
			raiz.remove_child(_copa)
			_bus.add_child(_copa)   ## la copa viaja en el bus, sobre el capitán
		"pasillo":
			_copa.visible = false
			_caminan = FestejoExtra3D.pasillo(self, raiz, spawner, once, _rival, c1, c2)
	if spawner is Node:
		(spawner as Node).queue_free()
	if modo == "fuegos":
		_cohetes(raiz, c1, c2)
	if modo == "pasillo":   ## (10-11) el más caro (15 jugadores): sin sombras de los focos, que duplicaban el dibujo de cada modelo
		for n in raiz.get_children():
			if n is Light3D:
				(n as Light3D).shadow_enabled = false
	_cam = Camera3D.new()
	_cam.fov = 40.0
	_vp.add_child(_cam)
	_colocar_camara()

## Un jugador real con su animación; devuelve su nodo (o null si el modelo no se pudo crear).
func _jugador(raiz: Node3D, spawner, j: Jugador, pos: Vector3, mira: float, anim: String, c1: Color, c2: Color, desfase := 0.0) -> Node3D:
	var nodo := Node3D.new()
	nodo.position = pos
	nodo.rotation.y = mira
	raiz.add_child(nodo)
	var datos := Puente3D.jugador(j)
	var look: Array = load("res://visor/player_spawner.gd")._look_de(datos)
	var d: Dictionary = spawner._crear_jugador(nodo, j.id, "POR" if j.pos_e == "POR" else "DEL", "", c1, c2, estilo_camiseta, maxi(j.dorsal, 1),
		look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
	if d.is_empty():
		return nodo
	jugadores += 1
	var ap: AnimationPlayer = d.get("anim")
	if ap != null:
		var nombre := "celebrar" if ap.has_animation("celebrar") else "idle"
		for a: String in anim.split("|"):   ## «caminar|trotar|run»: la primera que tenga el modelo
			if ap.has_animation(a):
				nombre = a
				break
		if ap.has_animation(nombre):
			ap.play(nombre)
			ap.seek(fmod(desfase, maxf(ap.current_animation_length, 0.1)), true)
	return nodo

func _escenario(raiz: Node3D, sp, once: Array, c1: Color, c2: Color) -> void:
	_caja(raiz, Vector3(0, 0.25, 0), Vector3(7.5, 0.5, 3.2), _mat(Color(0.08, 0.09, 0.12), 0.5))   ## la tarima
	_caja(raiz, Vector3(0, 0.52, 1.6), Vector3(7.5, 0.06, 0.06), _mat(Color(0.95, 0.78, 0.3), 0.3, 1.5))   ## filo dorado
	var n := mini(once.size(), MAX_JUG)
	for k in n:
		var x := (float(k) - float(n - 1) * 0.5) * 0.8
		var anim := "celebrar_ls" if k % 2 == 0 else "celebrar"
		var nodo := _jugador(raiz, sp, once[k], Vector3(x, 0.5, 0.2 - absf(x) * 0.08), 0.0, anim if k != n / 2 else "celebrar", c1, c2, k * 0.37)
		if k == n / 2:
			_capitan = nodo

func _palco(raiz: Node3D, sp, once: Array, c1: Color, c2: Color) -> void:
	_caja(raiz, Vector3(0, 1.0, -0.6), Vector3(8.5, 2.0, 2.4), _mat(Color(0.13, 0.15, 0.2)))   ## el palco, elevado
	_caja(raiz, Vector3(0, 3.0, 0.55), Vector3(8.5, 0.06, 0.06), _mat(Color(0.8, 0.82, 0.86), 0.3))   ## la baranda, a la cintura
	_caja(raiz, Vector3(0, 1.4, 0.62), Vector3(8.5, 1.1, 0.04), _mat(c1.darkened(0.3)))   ## la lona del club, bajo los pies
	var n := mini(once.size(), 8)
	for k in n:
		var x := (float(k) - float(n - 1) * 0.5) * 0.95
		var nodo := _jugador(raiz, sp, once[k], Vector3(x, 2.0, -0.2 if k != n / 2 else -0.7), 0.0, "aplaudir" if k != n / 2 else "celebrar", c1, c2, k * 0.5)
		if k == n / 2:
			_capitan = nodo
		var med := MeshInstance3D.new()   ## la medalla, oculta hasta que «se la cuelgan»
		var cm := CylinderMesh.new()
		cm.top_radius = 0.07
		cm.bottom_radius = 0.07
		cm.height = 0.015
		med.mesh = cm
		med.rotation_degrees = Vector3(90, 0, 0)
		med.material_override = _mat(Color(0.95, 0.78, 0.3), 0.25, 0.8)
		med.position = Vector3(x, 3.25, 0.05)
		med.visible = false
		raiz.add_child(med)
		_medallas.append(med)

func _sobrio(raiz: Node3D, sp, once: Array, c1: Color, c2: Color) -> void:
	_copa.visible = false   ## sin copa: es un ascenso o una salvación
	var n := mini(once.size(), MAX_JUG)
	for k in n:
		var a := TAU * k / n
		var pos := Vector3(cos(a) * 1.3, 0, sin(a) * 1.3)
		_jugador(raiz, sp, once[k], pos, atan2(-pos.x, -pos.z) + PI, "aplaudir" if k % 3 != 0 else "celebrar", c1, c2, k * 0.3)

func _manteo(raiz: Node3D, sp, once: Array, c1: Color, c2: Color) -> void:
	_copa.visible = false
	var n := mini(once.size(), 8)
	for k in n:
		var a := TAU * k / n
		var pos := Vector3(cos(a) * 1.15, 0, sin(a) * 1.15)
		_jugador(raiz, sp, once[k], pos, atan2(-pos.x, -pos.z) + PI, "celebrar", c1, c2, k * 0.1)
	## El DT con SU modelo (`PersonajeDT`: el que creó el jugador o el de por defecto); si no se puede, un jugador de traje oscuro.
	_dt = Node3D.new()
	raiz.add_child(_dt)
	var dd := PersonajeDT.crear(_dt, PersonajeDT.del_usuario, c1, c2)
	if dd.is_empty() and not once.is_empty():
		_dt.queue_free()
		_dt = _jugador(raiz, sp, once[0], Vector3(0, 2.0, 0), 0.0, "saltar", Color(0.12, 0.13, 0.16), Color(0.92, 0.92, 0.95))
	elif not dd.is_empty():
		jugadores += 1

func _foto(raiz: Node3D, sp, once: Array, c1: Color, c2: Color) -> void:
	var n := mini(once.size(), MAX_JUG)
	for k in n:
		var fila := 0 if k < 5 else 1
		var i := k if fila == 0 else k - 5
		var cuantos := 5 if fila == 0 else n - 5
		var x := (float(i) - float(cuantos - 1) * 0.5) * 0.85
		_jugador(raiz, sp, once[k], Vector3(x, 0.0 if fila == 0 else 0.35, -0.6 if fila == 0 else 0.5), 0.0, "idle" if fila == 0 else "aplaudir", c1, c2, k * 0.2)
	if n > 5:
		_caja(raiz, Vector3(0, 0.17, 0.5), Vector3(4.2, 0.35, 0.8), _mat(Color(0.1, 0.11, 0.14)))   ## el banquito de la fila de delante
	_copa.position = Vector3(0, 0.0, 1.3)
	_flash = OmniLight3D.new()
	_flash.position = Vector3(0, 2.0, 5.0)
	_flash.omni_range = 12.0
	_flash.light_energy = 0.0
	raiz.add_child(_flash)

## Cohetes: unas ráfagas de partículas de colores sobre la grada.
func _cohetes(raiz: Node3D, c1: Color, c2: Color) -> void:
	var cols := [Color(1.0, 0.82, 0.3), c1.lightened(0.3), c2, Color(1, 0.4, 0.4)]
	for k in 4:
		var p := CPUParticles3D.new()
		p.amount = 60
		p.lifetime = 1.6
		p.explosiveness = 0.95
		p.position = Vector3(-15.0 + k * 10.0, 14.0 + (k % 2) * 2.0, -16.0)
		p.direction = Vector3(0, 1, 0)
		p.spread = 180.0
		p.initial_velocity_min = 5.0
		p.initial_velocity_max = 7.0
		p.gravity = Vector3(0, -2.5, 0)
		var sm := SphereMesh.new()
		sm.radius = 0.09
		sm.height = 0.18
		sm.radial_segments = 6
		sm.rings = 3
		p.mesh = sm
		p.material_override = _mat(cols[k], 0.5, 4.0)
		p.preprocess = k * 0.4
		raiz.add_child(p)

func _colocar_camara() -> void:
	var mira := Vector3(0, 1.4, 0)
	var pos: Vector3
	match modo:
		"palco":
			mira = Vector3(0, 2.9, 0)
			pos = Vector3(sin(_t * 0.15) * 2.5, 2.4, 8.0)
		"champan":
			mira = Vector3(0, 1.4, -0.6)
			pos = Vector3(sin(_t * 0.2) * 2.0, 1.9, 4.6)
		"desfile":
			var bx := _bus.position.x if _bus != null else 0.0
			mira = Vector3(bx, 2.8, 0)
			pos = Vector3(bx + 11.0, 4.6, 3.4)   ## en la calzada, delante del bus (no dentro de los edificios)
		"pasillo":
			mira = Vector3(0, 1.1, 0)
			pos = Vector3(-9.0 + sin(_t * 0.15) * 1.0, 2.2, 3.2)
		"foto":
			mira = Vector3(0, 1.0, 0)
			pos = Vector3(0, 1.6, 6.5 + sin(_t * 0.4) * 0.15)
		"manteo":
			mira = Vector3(0, 1.9, 0)
			pos = Vector3(sin(_t * 0.25) * 6.5, 1.8, cos(_t * 0.25) * 6.5)
		"sobrio":
			pos = Vector3(sin(_t * 0.2) * 5.5, 2.8, cos(_t * 0.2) * 5.5)
		_:
			var ang := sin(_t * 0.2) * 0.6
			pos = Vector3(sin(ang) * 7.5, 2.2 + sin(_t * 0.3) * 0.3, cos(ang) * 7.5)
	_cam.transform = Transform3D(Basis(), pos).looking_at(mira, Vector3.UP)

func _process(d: float) -> void:
	if _cam == null:
		return
	_t += d
	_colocar_camara()
	FestejoExtra3D.tick(self, _t)
	if _copa != null and _copa.visible and modo != "foto":   ## la copa en alto, sobre el capitán, que sube y baja
		var base := _capitan.position if _capitan != null else Vector3(0, 0.5, 0)
		_copa.position = base + Vector3(0, 1.95 + absf(sin(_t * 1.8)) * 0.3, 0.35)   ## (10-11) en las manos, un poco por delante de la cabeza
		_copa.rotation.y = sin(_t * 0.7) * 0.4
	if _dt != null:   ## el manteo: el DT sube y baja, girando un poco en el aire
		var fase := fmod(_t * 0.9, 1.0)
		_dt.position.y = 1.5 + 4.0 * fase * (1.0 - fase) * 1.4   ## de las manos (1,5 m) a ~2,9 m y vuelta
		_dt.rotation.x = -PI * 0.3   ## echado hacia atrás en el aire (de lado a la cámara se ve entero)
		_dt.rotation.z = sin(_t * 5.6) * 0.2
	for k in _medallas.size():   ## las medallas se cuelgan de una en una
		_medallas[k].visible = _t > 0.8 + k * 0.6
	if _flash != null:
		_flash.light_energy = maxf(0.0, 1.0 - fmod(_t, 2.5) * 4.0) * 8.0
