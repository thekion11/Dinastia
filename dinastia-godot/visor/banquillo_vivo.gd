class_name BanquilloVivo
extends RefCounted
## EL BANQUILLO Y LA GRADA, VIVOS (26-10-2026, fila 6 de la investigación s4:
## «hinchada y banquillo animados»). Hasta hoy los suplentes SENTADOS no hacían
## nada en todo el partido (ver `ui/estadio_p3.gd::_banca_gesto`: la pose
## «celebrar» es de pie y con la cadera bajada al banco salían hundidos).
##
## La solución: clips de MEDIO CUERPO. La parte de arriba (columna, brazos,
## cuello, cabeza, dedos) sale de Mesh2Motion (CC0, mismo esqueleto UE5 que el
## nuestro, ver `assets/characters/quaternius/anims_m2m/LICENCIA.md`); la de
## abajo (cadera, piernas) es NUESTRA pose «sentado», así que la cadera sigue en
## el banco y se festeja, se protesta o se charla sin levantarse.
##
## Los mismos clips compuestos se hornean a texturas de vértices para la
## hinchada (`herramientas/hornear_publico_vat.gd` y `visor/publico_vat.gd`).
##
## Si el recurso no está (otro checkout, o sin hornear), todo cae a lo de antes:
## `preparar()` devuelve false y nadie cambia de animación.

const RUTA_LIB := "res://assets/characters/quaternius/anims_m2m/m2m_parte_alta.res"
## Huesos que manda la pose «sentado» (cadera y piernas).
const ABAJO := ["root", "pelvis", "thigh_l", "calf_l", "foot_l", "ball_l", "ball_leaf_l",
	"thigh_r", "calf_r", "foot_r", "ball_r", "ball_leaf_r"]
## Clips de banquillo: nombre nuestro -> clip de la parte alta.
const CLIPS := {
	"sentado_festeja": "festeja_dos", "sentado_festeja_puno": "festeja_puno",
	"sentado_festeja_brazo": "festeja_brazo", "sentado_protesta": "enfado",
	"sentado_rechazo": "rechazo", "sentado_charla_m2m": "charla", "sentado_escucha": "escucha",
	"sentado_cruzados": "cruzados", "sentado_nervioso": "asiente",
}
const REPOSOS := ["sentado_charla_m2m", "sentado_escucha", "sentado_cruzados", "sentado"]
const FESTEJOS := ["sentado_festeja", "sentado_festeja_puno", "sentado_festeja_brazo"]
const PROTESTAS := ["sentado_protesta", "sentado_rechazo"]

static var _lib: AnimationLibrary = null
static var _probada := false

static func libreria() -> AnimationLibrary:
	if not _probada:
		_probada = true
		if ResourceLoader.exists(RUTA_LIB):
			_lib = load(RUTA_LIB) as AnimationLibrary
	return _lib

## El prefijo de pista ("Modelo/Skeleton3D") que usa este reproductor, sacado
## de su propia pose «sentado» (así vale para cualquier cuerpo).
static func prefijo_de(sentado: Animation) -> String:
	for i in sentado.get_track_count():
		var r := str(sentado.track_get_path(i))
		if r.contains(":"):
			return r.substr(0, r.rfind(":"))
	return ""

static func _hueso(a: Animation, i: int) -> String:
	var r := str(a.track_get_path(i))
	return r.substr(r.rfind(":") + 1)

## Medio cuerpo: la parte alta de `alto` (pistas con prefijo "@" o el que sea)
## sobre la cadera y las piernas de `sentado`. Los huesos que `alto` no anima
## se quedan como los tenga `sentado`.
static func componer(sentado: Animation, alto: Animation, prefijo: String, bucle := true) -> Animation:
	var a := Animation.new()
	a.length = alto.length
	a.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	var de_alto := {}
	for i in alto.get_track_count():
		var h := _hueso(alto, i)
		if h in ABAJO:
			continue
		de_alto[h] = true
		_copiar_pista(alto, i, a, prefijo + ":" + h, alto.length)
	for i in sentado.get_track_count():
		var h := _hueso(sentado, i)
		if de_alto.has(h):
			continue
		_copiar_pista(sentado, i, a, prefijo + ":" + h, alto.length)
	return a

static func _copiar_pista(o: Animation, i: int, d: Animation, ruta: String, largo: float) -> void:
	var t := d.add_track(o.track_get_type(i))
	d.track_set_path(t, NodePath(ruta))
	d.track_set_interpolation_type(t, o.track_get_interpolation_type(i))
	var ultimo: Variant = null
	for k in o.track_get_key_count(i):
		var tk := o.track_get_key_time(i, k)
		ultimo = o.track_get_key_value(i, k)
		if tk <= largo + 0.0001:
			d.track_insert_key(t, tk, ultimo)
	if d.track_get_key_count(t) == 0 and ultimo != null:
		d.track_insert_key(t, 0.0, ultimo)

## Suma los clips de banquillo a la librería del reproductor (una sola vez por
## librería: las comparten los jugadores del mismo cuerpo).
static func preparar(ap: AnimationPlayer) -> bool:
	if ap == null or not ap.has_animation("sentado"):
		return false
	if ap.has_animation("sentado_festeja"):
		return true
	var alta := libreria()
	if alta == null or not ap.has_animation_library(""):
		return false
	var lib := ap.get_animation_library("")
	var sentado := ap.get_animation("sentado")
	var pre := prefijo_de(sentado)
	if pre == "":
		return false
	for nombre: String in CLIPS:
		var origen := String(CLIPS[nombre])
		if alta.has_animation(origen):
			lib.add_animation(nombre, componer(sentado, alta.get_animation(origen), pre))
	return ap.has_animation("sentado_festeja")

## Los suplentes sentados de un lado (los de `PlayerSpawner.spawn_sentados`:
## en la banda, X≈35, con la raíz bajada al banco y reproduciendo «sentado*»).
static func sentados(raiz: Node, es_local: bool) -> Array[AnimationPlayer]:
	var out: Array[AnimationPlayer] = []
	if raiz == null:
		return out
	for n in raiz.find_children("*", "AnimationPlayer", true, false):
		var ap := n as AnimationPlayer
		var cuerpo := ap.get_parent() as Node3D
		if cuerpo == null or not ap.current_animation.begins_with("sentado"):
			continue
		var p := cuerpo.position
		if absf(absf(p.x) - 35.0) > 1.5 or p.y > -0.2 or absf(p.z) < 8.0:
			continue
		## El local va en Z negativa (`spawn_sentados`: lado = -1).
		if (p.z < 0.0) != es_local:
			continue
		out.append(ap)
	return out

## Reacción del banco sentado: "gol" (festejan sin levantarse), "protesta"
## (brazos al árbitro), "reposo" (cada uno con lo suyo: charla, escucha, brazos
## cruzados). Vuelven solos a su reposo a los `dura` segundos.
static func reaccionar(raiz: Node, tipo: String, es_local: bool, dura := 3.2) -> int:
	var n := 0
	for ap in sentados(raiz, es_local):
		if not preparar(ap):
			continue
		var semilla := absi(ap.get_instance_id()) % 97
		var clip := ""
		match tipo:
			"gol": clip = FESTEJOS[semilla % FESTEJOS.size()]
			"protesta": clip = PROTESTAS[semilla % PROTESTAS.size()]
			_: clip = REPOSOS[semilla % REPOSOS.size()]
		if not ap.has_animation(clip):
			continue
		ap.play(clip, 0.25)
		## Cada uno a su ritmo: no es una coreografía.
		ap.seek(fmod(float(semilla) * 0.137, ap.current_animation_length), true)
		n += 1
		if tipo == "gol" or tipo == "protesta":
			var reposo: String = REPOSOS[(semilla / 3) % REPOSOS.size()]
			ap.get_tree().create_timer(dura + float(semilla % 5) * 0.15).timeout.connect(func() -> void:
				if is_instance_valid(ap) and ap.has_animation(reposo) and ap.current_animation == clip:
					ap.play(reposo, 0.4))
	return n
