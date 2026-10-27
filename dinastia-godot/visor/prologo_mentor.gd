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
## origen (0,0,0) de la ciudad; el estadio está en `CityBuilder.ESTADIO_EN`.

signal llegado

const VEL := 1.55            ## m/s andando (algo menos que el jugador a pie)
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
	## Traje oscuro con corbata: es alguien del club, no un paseante.
	asp["ropa"] = "traje"
	asp["c_ropa"] = "#1c2233"
	asp["c_ropa2"] = "#f2f2f2"
	asp["corbata"] = true
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

## Aparece de golpe en `p` (se usa con la pantalla en negro o tras esfumarse).
func colocar(p: Vector3, rumbo: float = PI) -> void:
	position = p
	rotation.y = rumbo
	scale = Vector3.ONE * _escala_base
	visible = true
	_esfumando = false
	_destino = Vector3.INF
	_animar("parado")

## Camina en línea recta hasta `p` (misma altura) y avisa con `llegado`.
func ir_a(p: Vector3) -> void:
	_destino = Vector3(p.x, position.y, p.z)
	_mirar_hacia(_destino)
	_animar("caminar")

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
	_mirar_hacia(_destino)
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
	var d := Vector3(_destino.x - position.x, 0.0, _destino.z - position.z)
	var paso := VEL * delta
	if d.length() <= maxf(paso, ALCANCE_LLEGADA):
		position = Vector3(_destino.x, position.y, _destino.z)
		_destino = Vector3.INF
		if not _esfumando:
			_animar("parado")
			llegado.emit()
		return
	position += d.normalized() * paso

func _mirar_hacia(p: Vector3) -> void:
	var v := p - position
	if Vector2(v.x, v.z).length() > 0.01:
		rotation.y = atan2(v.x, v.z)

func _animar(nombre_anim: String) -> void:
	if anim != null and anim.has_animation(nombre_anim) and anim.current_animation != nombre_anim:
		anim.play(nombre_anim, 0.3)
