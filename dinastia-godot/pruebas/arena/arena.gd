extends Node
## ARENA DE PRUEBAS (P5, 3-11): un banco aislado para probar UNA pieza del partido sola, mirarla desde cuatro cámaras a la vez y medirla.
## Monta SOLO lo pedido: cancha + N jugadores + árbitro (+ balón), sin público, sin ciudad, sin menú. Todo por variables de entorno:
##
##   ARENA=cancha|jugador|arbitro|balon|porteria|partido    qué se monta (por defecto «jugador»)
##   N=11            jugadores por equipo en «partido» (1 en «jugador», «arbitro» y «balon»; «porteria»: un tirador y el portero)
##   CAMARAS=4       cuántas de las cuatro vistas se dibujan (1 = medir la pieza sin el coste de las otras tres)
##   VELOCIDAD=1     reloj acelerado (Engine.time_scale; T en vivo: 1-2-4-8)
##   DURACION=0      segundos de reloj de pared; 0 = hasta cerrar (en headless, 8 por defecto)
##   CALIDAD=minima|media|alta|ultra      (por defecto la elegida del juego)
##   MOTOR=0|1       el motor jugable lleva a los 22 (1 en «partido» y «balon»/«porteria», 0 en el resto)
##   ESTADIO=0|1     monta además el estadio entero (público, vallas, focos) para medir lo que cuesta
##   SEMILLA=4711    mundo y motor
##   INFORME=1       al montar, imprime qué pesa cada pieza del campo (triángulos, objetos, sombras)
##   OCULTAR=a,b     oculta las piezas cuyo nombre contenga a o b (para medir lo que cuestan)
##   CAPTURA=ruta.jpg   guarda la pantalla a los 4 s (revisión a ojo sin GPU)
##
##   godot --path . --rendering-driver vulkan --resolution 1280x720 res://pruebas/arena/arena.tscn
##   ARENA=arbitro CAMARAS=1 DURACION=10 godot --headless --path . res://pruebas/arena/arena.tscn   (métricas en /tmp/arena_arbitro.csv)
## Teclas: 1-4 una cámara a pantalla completa · 0 la cuadrícula · T velocidad · Esc salir. Ver `ArenaMetricas` y `ArenaCamaras`.

var modo := "jugador"
var _camaras: ArenaCamaras
var _metricas: ArenaMetricas
var _raiz: Node3D
var _motor: MotorJugable
var _lista: Array = []
var _balon: Node3D
var _rotulo: Label
var _t := 0.0
var _duracion := 0.0
var _proximo_toque := 1.0
var _capturada := false

static func _env(nombre: String, defecto: String) -> String:
	var v := OS.get_environment(nombre)
	return v if v != "" else defecto

func _ready() -> void:
	modo = _env("ARENA", "jugador").to_lower()
	var nivel := _calidad(_env("CALIDAD", ""))
	Calidad.elegida = nivel
	Engine.max_fps = 0
	Engine.time_scale = float(_env("VELOCIDAD", "1"))
	_duracion = float(_env("DURACION", "8" if DisplayServer.get_name() == "headless" else "0"))
	var mundo := Mundo.new()
	mundo.generar(["CHI"], int(_env("SEMILLA", "4711")))
	var a: Club = mundo.ligas[0].clubes[0]
	var b: Club = mundo.ligas[0].clubes[1]
	_camaras = ArenaCamaras.new()
	add_child(_camaras)
	_raiz = _camaras.montar(clampi(int(_env("CAMARAS", "4")), 1, 4), nivel)
	_camaras.escala = 1.0 if modo in ["cancha", "partido", "porteria"] else 0.3
	var perfil := mundo.perfil_estadio_de(a).duplicate()
	Ambience.apply(_raiz, perfil, null, nivel)
	StadiumBuilder.build_pitch(_raiz, perfil, a)
	if _env("ESTADIO", "0") == "1":
		StadiumBuilder.build(_raiz, perfil, int(perfil.get("aforo", 20000)), 0.8, a._hash_id(), a)
	_montar_jugadores(a, b)
	_ocultar_y_informar()
	_camaras.foco = _foco
	_metricas = ArenaMetricas.new()
	add_child(_metricas)
	_metricas.iniciar(modo)
	_rotulo = Label.new()
	_rotulo.position = Vector2(10, 26)
	_rotulo.add_theme_font_size_override("font_size", 13)
	_rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	_rotulo.add_theme_constant_override("outline_size", 4)
	add_child(_rotulo)

func _calidad(nombre: String) -> int:
	match nombre.to_lower():
		"minima", "minimo", "mínima", "mínimo": return Calidad.MINIMO
		"media", "medio": return Calidad.MEDIO
		"alta", "alto": return Calidad.ALTO
		"ultra": return Calidad.ULTRA
	return Calidad.elegida

## Lo que cada modo pone en el campo. Los jugadores salen de los dos primeros clubes de un mundo ficticio de semilla fija.
func _montar_jugadores(a: Club, b: Club) -> void:
	if modo == "cancha":
		return
	var n := int(_env("N", "11")) if modo == "partido" else (2 if modo == "porteria" else 1)
	var sp := PlayerSpawner.new()
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	var xi_l: Array = l["xi"].slice(0, n) if modo == "partido" else [l["xi"][5]]
	var xi_v: Array = v["xi"].slice(0, n) if modo == "partido" else ([v["xi"][0]] if modo == "porteria" else [])
	_lista.append_array(sp.spawn_team(_raiz, xi_l, l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	if not xi_v.is_empty():
		_lista.append_array(sp.spawn_team(_raiz, xi_v, v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	if modo in ["partido", "arbitro"]:
		_lista.append_array(sp.spawn_arbitros(_raiz, Puente3D.kit_arbitro(Puente3D.kit(a), Puente3D.kit(b), 1, [Puente3D.kit_portero(a), Puente3D.kit_portero(b)])))
	if modo in ["jugador", "arbitro"]:
		for p: Dictionary in _lista:
			if p.has("base_pos"):
				(p["node"] as Node3D).position = Vector3(0, 0, 0)
	if modo in ["partido", "balon", "porteria"]:
		_balon = StadiumBuilder.spawn_ball(_raiz, Vector3(0, 0.11, 0))
	var con_motor := _env("MOTOR", "1" if modo in ["partido", "balon", "porteria"] else "0") == "1"
	if con_motor and _balon != null:
		_motor = MotorJugable.new()
		add_child(_motor)
		_motor.autopiloto = modo == "partido"
		_motor.preparar(_lista, _balon, "", int(_env("SEMILLA", "4711")))   ## `preparar` separa solo a los árbitros (`arbitro: true`)
		if modo == "partido":
			_motor._saque_de_centro(true)

## Qué miran las cámaras: el balón si lo hay, si no el primer jugador, si no el centro.
func _foco() -> Vector3:
	if _balon != null and is_instance_valid(_balon):
		return _balon.position
	if not _lista.is_empty() and is_instance_valid(_lista[0]["node"]):
		return (_lista[0]["node"] as Node3D).position
	return Vector3.ZERO

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.0001)
	_t += real
	## «balon» y «porteria»: un toque cada tres segundos de reloj de juego, para ver rodar, botar y entrar el balón.
	if _motor != null and modo in ["balon", "porteria"]:
		_proximo_toque -= delta
		if _proximo_toque <= 0.0:
			_proximo_toque = 3.0
			var rng := RandomNumberGenerator.new()
			rng.seed = int(_t * 1000.0)
			_motor.estado = "juego"
			_motor.poseedor = {}
			_balon.position = Vector3(rng.randf_range(-6, 6), 0.11, 20.0 if modo == "porteria" else 0.0)
			var hacia := Vector3(rng.randf_range(-3.2, 3.2), rng.randf_range(0.0, 2.0), 52.0) - _balon.position if modo == "porteria" else Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1))
			_motor.vel_balon = hacia.normalized() * (rng.randf_range(14.0, 26.0) if modo == "porteria" else rng.randf_range(6.0, 16.0))
			_motor.vel_balon.y += 3.0
	_rotulo.text = "ARENA «%s» · ×%.0f · %s\n%s" % [modo, Engine.time_scale, _metricas.resumen_corto(), "1-4 cámara · 0 cuadrícula · T velocidad · Esc salir"]
	if not _capturada and _t >= 4.0 and _env("CAPTURA", "") != "":
		_capturada = true
		get_viewport().get_texture().get_image().save_jpg(_env("CAPTURA", ""), 0.9)
	if _duracion > 0.0 and _t >= _duracion:
		_metricas.imprimir_resumen()
		get_tree().quit()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		var k := (e as InputEventKey).keycode
		if k == KEY_T:
			Engine.time_scale = 1.0 if Engine.time_scale >= 8.0 else Engine.time_scale * 2.0
		elif k == KEY_ESCAPE:
			_metricas.imprimir_resumen()
			get_tree().quit()

## Una categoría por hijo de la raíz, para poder apagar «lo mismo» aunque los nodos no tengan nombre propio:
## gradas (mallas con decenas de MultiMesh), personal (muñecos de 9-10 mallas), tunel, mascota, edificios, otros.
func _categoria(h: Node) -> String:
	var n := String(h.name)
	if n.begins_with("Tunel"):
		return "tunel"
	if n.begins_with("Mascota"):
		return "mascota"
	var geom := h.find_children("*", "GeometryInstance3D", true, false).size()
	if h is MeshInstance3D and geom >= 10:
		return "gradas"
	if h.get_class() == "Node3D" and geom >= 8 and geom <= 12:
		return "personal"
	return "otros"

## INFORME y OCULTAR (R2): qué pesa cada hijo directo de la raíz del campo, y apagar piezas por nombre para medir el resto.
func _ocultar_y_informar() -> void:
	var quitar := _env("OCULTAR", "").split(",", false)
	for h in _raiz.get_children():
		for q: String in quitar:
			if (String(h.name).to_lower() + "|" + _categoria(h)).contains(q.to_lower()) and h is Node3D:
				(h as Node3D).visible = false
	if _env("INFORME", "0") != "1":
		return
	var filas: Array = []
	for h in _raiz.get_children():
		var tri := 0
		var obj := 0
		var sombras := 0
		var nodos: Array = h.find_children("*", "GeometryInstance3D", true, false)
		if h is GeometryInstance3D:
			nodos.append(h)
		for n: GeometryInstance3D in nodos:
			var veces := 1
			var malla: Mesh = null
			if n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
				var mm := (n as MultiMeshInstance3D).multimesh
				malla = mm.mesh
				veces = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			elif n is MeshInstance3D:
				malla = (n as MeshInstance3D).mesh
			if malla == null:
				continue
			tri += (malla.get_faces().size() / 3) * veces
			obj += 1
			sombras += 1 if n.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 0
		filas.append([tri, obj, sombras, "%s (%s) [%s]" % [h.name, h.get_class(), _categoria(h)]])
	filas.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	_informe_multimesh()
	for h in _raiz.get_children():
		if String(h.name).begins_with("Tunel"):
			var por_clase := {}
			for d in h.find_children("*", "", true, false):
				var k := d.get_class() + (" (con hijos)" if d.get_child_count() > 0 and d is MeshInstance3D else "")
				por_clase[k] = int(por_clase.get(k, 0)) + 1
			print("TUNEL por clase: ", por_clase)
			var resto := {}
			for d in h.find_children("*", "MeshInstance3D", true, false):
				var mi := d as MeshInstance3D
				var k := "%s | mat_override=%s | hijos=%d | visible=%s | tri=%d" % [mi.mesh.get_class() if mi.mesh != null else "sin malla", mi.material_override != null, mi.get_child_count(), mi.visible, (mi.mesh.get_faces().size() / 3) if mi.mesh != null else 0]
				resto[k] = int(resto.get(k, 0)) + 1
			var claves := resto.keys()
			claves.sort_custom(func(a: String, b: String) -> bool: return resto[a] > resto[b])
			for k: String in claves.slice(0, 8):
				print("   ", resto[k], " × ", k)
	print("INFORME de piezas (triángulos · objetos · con sombra):")
	for fila: Array in filas.slice(0, 25):
		print("  %9d  %5d  %5d   %s" % [fila[0], fila[1], fila[2], fila[3]])
	if _env("INFORME_OTROS", "0") == "1":
		var otros := filas.filter(func(r: Array) -> bool: return String(r[3]).ends_with("[otros]"))
		otros.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
		print("OTROS por objetos:")
		for r: Array in otros.slice(0, 20):
			print("  %9d  %5d  %5d   %s" % [r[0], r[1], r[2], r[3]])

## Todos los MultiMesh del campo juntos, por nombre: instancias, triángulos por malla y total (el público y las butacas son MultiMesh).
func _informe_multimesh() -> void:
	var por_nombre := {}
	for n in _raiz.find_children("*", "MultiMeshInstance3D", true, false):
		var m := n as MultiMeshInstance3D
		if m.multimesh == null or m.multimesh.mesh == null:
			continue
		var veces := m.multimesh.visible_instance_count if m.multimesh.visible_instance_count >= 0 else m.multimesh.instance_count
		var por := m.multimesh.mesh.get_faces().size() / 3
		var clave := "%s" % [String(m.name).rstrip("0123456789@")]
		var fila: Array = por_nombre.get(clave, [0, 0, 0, por, 0])
		fila[0] += 1
		fila[1] += veces
		fila[2] += por * veces
		fila[3] = por
		fila[4] += 1 if m.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 0
		por_nombre[clave] = fila
	var claves := por_nombre.keys()
	claves.sort_custom(func(a: String, b: String) -> bool: return por_nombre[a][2] > por_nombre[b][2])
	print("MULTIMESH del campo (nombre · nodos · instancias · tri/malla · triángulos totales · con sombra):")
	for c: String in claves.slice(0, 16):
		var r: Array = por_nombre[c]
		print("  %-28s %4d %8d %6d %10d %4d" % [c, r[0], r[1], r[3], r[2], r[4]])
