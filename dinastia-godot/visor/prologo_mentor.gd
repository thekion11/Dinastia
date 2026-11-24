class_name PrologoMentor
extends Node3D
## EL MENTOR QUE TE GUÍA POR EL CLUB (fase 2 del plan del lunes, 26-10-2026).
##
## Un cuerpo del juego (`PersonajeDT`, el mismo humano que el personal del
## estadio) con el nombre y el cargo que ya da `Tutorial.mentor_de` para tu
## modo: el presidente si eres DT, tu jefe si eres ayudante, el enviado del
## fondo si eres el jeque… Sabe cuatro cosas: ir andando a un punto, mirarte,
## hacer un gesto al hablar y «adelantarse» (va unos pasos hacia la siguiente
## sala y se esfuma: el edificio tiene plantas y ascensor, y hacerle buscar el
## camino de verdad sería otro sistema; así siempre te espera donde toca).
##
## Coordenadas: las del mundo del explorador (`ExploradorCiudad`), que es el
## origen (0,0,0) de la ciudad; el estadio está en `CargaCiudad.de("CityBuilder").ESTADIO_EN`.

signal llegado

const VEL := 1.55            ## m/s andando (algo menos que el jugador a pie)
const VEL_CLIP := 1.06       ## m/s a los que avanza el clip «caminar» (medido el 20-11): la animación se acompasa a lo que de verdad avanza
const GIRO := 7.0            ## rad/s de giro hacia el rumbo (antes giraba de golpe)
const ACEL := 1.8            ## m/s² al arrancar
const FRENO := 3.0           ## m/s² al frenar
const RADIO_CUERPO := 0.3
const ALCANCE_LLEGADA := 0.25
const ALTURA_ROTULO := 2.15

var nombre := ""
var cargo := ""
var anim: AnimationPlayer
var _destino := Vector3.INF
var _esfumando := false
var _escala_base := 1.0
var _rotulo: Label3D

## `look`: lo que devuelve `Tutorial.mentor_de` (nombre, cargo, semilla, canas).
## `c1`/`c2`: los colores del club (el traje lleva el tono del club de corbata).
func crear(look: Dictionary, c1: Color, c2: Color) -> void:
	nombre = String(look.get("nombre", "Mentor"))
	cargo = String(look.get("cargo", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(look.get("semilla", nombre)))
	var asp := PersonajeDT.aleatorio(rng)
	## Traje oscuro con corbata: es alguien del club, no un paseante (o el chándal del club
	## si `look["ropa"]` lo pide: los futbolistas del vestuario, fase 5).
	asp["ropa"] = String(look.get("ropa", "traje"))
	asp["c_ropa"] = String(look.get("c_ropa", "#1c2233"))
	asp["c_ropa2"] = String(look.get("c_ropa2", "#f2f2f2"))
	asp["corbata"] = asp["ropa"] == "traje"
	asp["gorra"] = false
	if bool(look.get("canas", false)):
		asp["color_pelo"] = "#b9b9b9"
		asp["edad"] = 62
	var d := PersonajeDT.crear(self, asp, c1, c2)
	if d.has("anim"):
		anim = d["anim"]
		PersonajeDT.gestos_banda(d)
	_rotulo = Label3D.new()
	_rotulo.text = "%s\n%s" % [nombre, cargo]
	_rotulo.font_size = 26
	_rotulo.pixel_size = 0.0022
	_rotulo.outline_size = 6
	_rotulo.visibility_range_end = 16.0
	_rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_rotulo.position = Vector3(0, ALTURA_ROTULO, 0)
	_rotulo.modulate = Color(1.0, 0.86, 0.45)
	add_child(_rotulo)
	_animar("parado")

## Cajas de los obstáculos blandos (setos, jardineras, arbustos) que el prólogo localiza al construir la
## ciudad. Quien aparece de golpe no debe quedar dentro de uno (queja del dueño, 2-11-2026: el
## acompañante de la bienvenida atravesaba un arbusto).
static var obstaculos: Array[AABB] = []
const MARGEN := 0.45

## `p` desplazado en horizontal hasta quedar fuera de todo obstáculo (con un margen).
static func fuera_de_obstaculos(p: Vector3) -> Vector3:
	for _vuelta in 4:
		var movido := false
		for a: AABB in obstaculos:
			var b := a.grow(MARGEN)
			if p.y + 1.8 < b.position.y or p.y > b.end.y:
				continue
			if p.x > b.position.x and p.x < b.end.x and p.z > b.position.z and p.z < b.end.z:
				var salidas := [b.position.x - p.x, b.end.x - p.x, b.position.z - p.z, b.end.z - p.z]
				var mejor := 0
				for i in 4:
					if absf(float(salidas[i])) < absf(float(salidas[mejor])):
						mejor = i
				if mejor < 2:
					p.x += float(salidas[mejor]) + (-0.01 if mejor == 0 else 0.01)
				else:
					p.z += float(salidas[mejor]) + (-0.01 if mejor == 2 else 0.01)
				movido = true
		if not movido:
			break
	return p

## Aparece de golpe en `p` (se usa con la pantalla en negro o tras esfumarse).
func colocar(p: Vector3, rumbo: float = PI) -> void:
	p = fuera_de_obstaculos(p)
	position = p
	rotation.y = rumbo
	scale = Vector3.ONE * _escala_base
	visible = true
	_esfumando = false
	_destino = Vector3.INF
	_animar("parado")

var _ruta: Array[Vector3] = []   ## puntos que faltan hasta `_destino`, rodeando lo que estorbe (20-11, «no atravesar objetos»)
var _v := 0.0

## Camina hasta `p` (misma altura) y avisa con `llegado`. Rodea los obstáculos blandos del prólogo y lo sólido que haya en el camino; si no
## hay camino libre, va en línea recta como antes (no se inventa un rodeo).
func ir_a(p: Vector3) -> void:
	_destino = Vector3(p.x, position.y, p.z)
	_ruta = _camino_a(_destino)
	_ruta.remove_at(0)
	_animar("caminar")

## `RutaLibre.camino` hasta `d` con los obstáculos blandos (cajas) y la física del mundo, si el mentor ya está en el árbol.
func _camino_a(d: Vector3) -> Array[Vector3]:
	var fis := Callable()
	if is_inside_tree():
		fis = RutaLibre.libre_fisico(get_world_3d().direct_space_state, RADIO_CUERPO, 0.35)
	var libre := func(q: Vector3) -> bool:
		for a: AABB in obstaculos:
			var b := a.grow(RADIO_CUERPO)
			if q.y + 1.8 >= b.position.y and q.y <= b.end.y and q.x > b.position.x and q.x < b.end.x and q.z > b.position.z and q.z < b.end.z:
				return false
		return not fis.is_valid() or fis.call(q)
	return RutaLibre.camino(position, d, libre)

## Se gira hacia un punto (hacia ti cuando hablas con él).
func mirar_a(p: Vector3) -> void:
	_mirar_hacia(p)

## Un gesto al hablar (los de la banda del DT) y la cara contenta; si el cuerpo
## no lo trae, se queda parado sin romper nada.
func gesto(nombres: Array = ["senalar", "brazos_jarra", "aplaudir"]) -> void:
	Expresion.de(self).poner("alegre", 2.5)
	if anim == null:
		return
	for n: String in nombres:
		for clave in [n, "banda/" + n]:
			if anim.has_animation(clave):
				anim.play(clave, 0.25)
				anim.queue("parado")
				return

## «Me adelanto»: da unos pasos hacia `hacia`, se encoge y desaparece. Al
## llegar la pantalla a la siguiente sala, `colocar()` lo pone allí.
func adelantarse(hacia: Vector3) -> void:
	var dir := Vector3(hacia.x - position.x, 0.0, hacia.z - position.z)
	if dir.length() < 0.5:
		dir = Vector3(0, 0, -1).rotated(Vector3.UP, rotation.y)
	_destino = position + dir.normalized() * 3.0
	_ruta = _camino_a(_destino)
	_ruta.remove_at(0)
	_animar("caminar")
	_esfumando = true
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		visible = false
		_destino = Vector3.INF
		_animar("parado"))

func _process(delta: float) -> void:
	if _destino == Vector3.INF:
		return
	var meta := _ruta[0] if not _ruta.is_empty() else _destino
	var d := Vector3(meta.x - position.x, 0.0, meta.z - position.z)
	var es_fin := _ruta.size() <= 1
	if d.length() <= (maxf(VEL * delta, ALCANCE_LLEGADA) if es_fin else 0.15):
		if not es_fin:
			_ruta.remove_at(0)
			return
		position = Vector3(_destino.x, position.y, _destino.z)
		_destino = Vector3.INF
		_ruta.clear()
		_v = 0.0
		if not _esfumando:
			_animar("parado")
			llegado.emit()
		return
	## Gira sin saltos, arranca y frena, va más despacio mientras gira mucho y acompasa el paso (antes: giro de golpe y 1,55 m/s con un clip de 1,06).
	var rumbo := atan2(d.x, d.z)
	var error := absf(angle_difference(rotation.y, rumbo))
	rotation.y = lerp_angle(rotation.y, rumbo, clampf(GIRO * delta, 0.0, 1.0))
	var v_obj := minf(VEL, 0.25 + d.length() * 1.2) if es_fin else VEL
	v_obj *= clampf(cos(error), 0.0, 1.0)
	_v = move_toward(_v, v_obj, (ACEL if v_obj > _v else FRENO) * delta)
	position += d.normalized() * minf(_v * delta, d.length())
	if anim != null and _v > 0.12:
		anim.speed_scale = clampf(_v / VEL_CLIP, 0.5, 1.6)

func _mirar_hacia(p: Vector3) -> void:
	var v := p - position
	if Vector2(v.x, v.z).length() > 0.01:
		rotation.y = atan2(v.x, v.z)

## Hablar: el clip de charla de la UAL (brazos y cabeza vivos) mientras dura el cuadro
## de diálogo; al terminar vuelve a «parado». (§2.2e P3, 27-10-2026)
func hablar(si: bool) -> void:
	if anim == null:
		return
	if si:
		if load("res://visor/anim_extra.gd").asegurar(anim, FutbolistaQ.esqueleto_de(self), "charla"):
			anim.play("charla", 0.3)
	else:
		_animar("parado")

func _animar(nombre_anim: String) -> void:
	if anim != null and anim.has_animation(nombre_anim) and anim.current_animation != nombre_anim:
		anim.play(nombre_anim, 0.3)
	if anim != null and nombre_anim != "caminar":
		anim.speed_scale = 1.0   ## el ritmo de paso solo vale al caminar
