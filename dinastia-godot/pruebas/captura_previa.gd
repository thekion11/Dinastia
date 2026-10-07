extends Node
## `vPrevia()` del HTML, ahora en la pestaña "Partido" que antes era un atajo
## de dos líneas: rival, árbitro, DT de enfrente, cómo se miden las plantillas
## y las cuotas. Se construyen las obras de la sala de vídeo para ver también
## el bloque del informe del rival, que va condicionado a tenerla.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_previa.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		## BUG REAL ENCONTRADO 22-9-2026, verificando la extension del
		## espionaje tactico: "Partido" NUNCA fue un `id` de `GRUPOS` -es un
		## HUB contextual (`HUBS["partido"]`), solo alcanzable tocando su
		## boton y de ahi a `_ir_a_pestana()`-. `_elegir_grupo("partido")` no
		## tiraba error (`_grupo_por_id()` vuelve `{}` en silencio) pero
		## tampoco cambiaba de pestaña: esta captura llevaba desde que se
		## escribio mostrando CENTRAL, nunca la pantalla de Partido de
		## verdad. Nadie lo habia notado porque nadie habia vuelto a mirar
		## la imagen resultante hasta hoy.
		_pantalla.call("_ir_a_pestana", "Partido")
	if _n == ESPERA + 2:
		_guardar("res://pruebas/capturas/pantalla_previa.png")
	if _n == ESPERA + 4:
		var mun = _pantalla.get("mundo")
		mun.obras.niveles["video"] = 2
		## El informe del rival NO depende de la sala de vídeo -esa sube
		## `Instalaciones.factor_previa()`/similar, otra cosa de esta misma
		## pantalla-, depende de `Prensa.dato_del_rival` (comprado por
		## "espía" en la sala de prensa) o de `Entrenamiento.ve_tactica_
		## rival()` (el perk "lectura" del DT). El comentario original de
		## este archivo lo daba por hecho sin comprobarlo -corregido aquí
		## 22-9-2026, forzando el flag directo, igual que ya hace
		## `pruebas/banco.gd` para la misma comprobación-.
		mun.prensa.dato_del_rival = true
		_pantalla.call("_refrescar")
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_previa_video.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
