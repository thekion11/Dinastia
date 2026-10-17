class_name CuartoArbitro
extends Node3D
## EL CARTEL DEL CUARTO ÁRBITRO (17-10-2026, M-139). Al empezar el añadido de
## cada tiempo, el cuarto árbitro sale a la banda (entre los dos banquillos,
## del lado de la tribuna principal) y levanta el cartel luminoso con los
## minutos: «+3» en dígitos verdes por las dos caras, con los brazos arriba. A los
## pocos segundos lo baja y se va (el nodo se borra solo): fuera de ese rato
## no hay ni un triángulo más en el partido.
##   CuartoArbitro.levantar(raiz, spawner, minutos, kit_arbitro)
## EL CAMBIO (17-10-2026, M-104): el mismo cartel con los dos dorsales, el que
## entra en verde (arriba) y el que sale en rojo (abajo), como en la tele:
##   CuartoArbitro.levantar_cambio(raiz, spawner, dorsal_sale, dorsal_entra, kit)

const X_BANDA := 35.3        ## a 1,3 m de la línea, entre los banquillos
const DURACION := 7.5
const ALTO_ARRIBA := 1.84
const ALTO_ABAJO := 1.05

var _cartel: Node3D
var _t := 0.0
var _persona: Dictionary = {}

static func levantar(raiz: Node3D, spawner: PlayerSpawner, minutos: int, kit: Dictionary = {}) -> CuartoArbitro:
	if raiz == null or minutos <= 0:
		return null
	return _salir(raiz, spawner, kit, cartel(minutos))

static func levantar_cambio(raiz: Node3D, spawner: PlayerSpawner, dorsal_sale: int, dorsal_entra: int, kit: Dictionary = {}) -> CuartoArbitro:
	if raiz == null:
		return null
	return _salir(raiz, spawner, kit, cartel_lineas([
		[str(dorsal_entra) if dorsal_entra > 0 else "--", VERDE],
		[str(dorsal_sale) if dorsal_sale > 0 else "--", ROJO]]))

const VERDE := Color(0.35, 1.0, 0.45)
const ROJO := Color(1.0, 0.25, 0.2)

static func _salir(raiz: Node3D, spawner: PlayerSpawner, kit: Dictionary, el_cartel: Node3D) -> CuartoArbitro:
	## Uno a la vez (si ya está en la banda, se reutiliza el cartel).
	var viejo := raiz.get_node_or_null("CuartoArbitro")
	if viejo != null:
		viejo.name = "CuartoArbitroViejo"
		viejo.queue_free()
	var c := CuartoArbitro.new()
	c.name = "CuartoArbitro"
	raiz.add_child(c)
	c.position = Vector3(X_BANDA, 0, 1.6)
	## De cara al campo (−X).
	c.rotation.y = -PI * 0.5
	if spawner != null:
		c._persona = spawner.spawn_cuarto_arbitro(c, kit)
		if not c._persona.is_empty():
			var n: Node3D = c._persona["nodo"]
			n.position = Vector3.ZERO
			n.rotation = Vector3.ZERO
			var ap: AnimationPlayer = c._persona.get("anim")
			if is_instance_valid(ap) and ap.has_animation("arbitro_tiempo_anadido"):
				ap.play("arbitro_tiempo_anadido")
	c._cartel = el_cartel
	c.add_child(c._cartel)
	c._cartel.position = Vector3(0, ALTO_ABAJO, 0.32)
	return c

## El cartel: caja negra con marco, panel de LED y el número por las dos caras.
static func cartel(minutos: int) -> Node3D:
	return cartel_lineas([["+%d" % minutos, VERDE]])

## El mismo cartel con una o dos líneas de LED ([texto, color] cada una).
static func cartel_lineas(lineas: Array) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Cartel"
	var caja := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.66, 0.44, 0.06)
	caja.mesh = bm
	var mc := StandardMaterial3D.new()
	mc.albedo_color = Color(0.06, 0.06, 0.07)
	mc.roughness = 0.45
	mc.metallic = 0.3
	caja.material_override = mc
	caja.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(caja)
	for lado in [1.0, -1.0]:
		var panel := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.58, 0.36)
		panel.mesh = q
		var mp := StandardMaterial3D.new()
		mp.albedo_color = Color(0.02, 0.05, 0.03)
		mp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		panel.material_override = mp
		panel.position = Vector3(0, 0, 0.031 * lado)
		panel.rotation.y = 0.0 if lado > 0.0 else PI
		raiz.add_child(panel)
		var n := lineas.size()
		for i in n:
			var l := Label3D.new()
			l.text = String(lineas[i][0])
			l.font_size = 150 if n == 1 else 92
			l.pixel_size = 0.0021
			l.outline_size = 0
			l.modulate = lineas[i][1]
			l.shaded = false
			l.double_sided = false
			l.no_depth_test = false
			var y := 0.0 if n == 1 else 0.085 - 0.17 * float(i)
			l.position = Vector3(0, y, 0.034 * lado)
			l.rotation.y = 0.0 if lado > 0.0 else PI
			raiz.add_child(l)
	return raiz

func _process(delta: float) -> void:
	_t += delta
	if _cartel == null:
		return
	## Sube en 0,6 s, aguanta, y baja al final.
	var sube := clampf(_t / 0.6, 0.0, 1.0)
	var baja := clampf((DURACION - _t) / 0.6, 0.0, 1.0)
	var k := minf(sube, baja)
	k = k * k * (3.0 - 2.0 * k)
	_cartel.position.y = lerpf(ALTO_ABAJO, ALTO_ARRIBA, k)
	_cartel.position.z = lerpf(0.32, 0.2, k)
	## Mantiene los brazos arriba mientras enseña el cartel.
	if not _persona.is_empty() and _t < DURACION - 0.6:
		var ap: AnimationPlayer = _persona.get("anim")
		if is_instance_valid(ap) and ap.has_animation("arbitro_tiempo_anadido") and ap.current_animation_position > 1.3:
			ap.seek(0.6, true)
	if _t >= DURACION:
		queue_free()
