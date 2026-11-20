class_name EstiloMundo
extends RefCounted
## ESTILO DEL MUNDO (15-11-2026, pedido del dueño): antes de crear el mundo se elige entre dos formas de verlo.
##   · MUNDO CLÁSICO: el aspecto de siempre, con MENOS partículas (la mitad) y MENOS movimiento (fondos y globo más lentos).
##   · MUNDO SUAVE: fondos quietos, sin partículas, y la pantalla solo se vuelve a dibujar cuando algo cambia (el ahorro de
##     `AhorroMenu`, que antes era solo de las calidades ligeras, en todas). Es el primer paso del estilo de la maqueta
##     (pantallas más limpias y un color por modo de juego): lo que falta está en `docs/PLAN_GENERAL.md`.
## Es de la MÁQUINA, no de la partida (como la calidad): se guarda en su propio archivo y vale para todo el juego.
const RUTA := "user://estilo_mundo.cfg"
const PARTICULAS_CLASICO := 0.5   ## cuántas partículas quedan en el clásico (antes, 1)
const MOVIMIENTO_CLASICO := 0.6   ## a qué ritmo se mueven los fondos y gira el globo en el clásico (antes, 1)

static var suave: bool = _leer()

static func _leer() -> bool:
	if OS.get_environment("ESTILO_MUNDO") != "":   ## para medir y capturar sin tocar lo guardado: ESTILO_MUNDO=suave|clasico
		return OS.get_environment("ESTILO_MUNDO") == "suave"
	var cf := ConfigFile.new()
	return cf.load(RUTA) == OK and bool(cf.get_value("estilo", "suave", false))

## ¿Ya se eligió alguna vez en esta máquina? (para dejar marcada la última elección)
static func elegido_antes() -> bool:
	var cf := ConfigFile.new()
	return cf.load(RUTA) == OK and cf.has_section_key("estilo", "suave")

static func elegir(es_suave: bool) -> void:
	suave = es_suave
	var cf := ConfigFile.new()
	cf.set_value("estilo", "suave", es_suave)
	cf.save(RUTA)

## Qué parte de las partículas de un fondo se queda: 0 en el suave (no hay), la mitad en el clásico.
static func factor_particulas() -> float:
	return 0.0 if suave else PARTICULAS_CLASICO

## A qué ritmo se mueve lo que se mueve solo (partículas, deriva del globo): 0 en el suave, más lento en el clásico.
static func factor_movimiento() -> float:
	return 0.0 if suave else MOVIMIENTO_CLASICO

## El interruptor de Ajustes (el mismo que se elige al empezar un juego nuevo). Las partículas que ya están en pantalla cambian al volver a abrirla.
static func crear(p: Object) -> void:
	var cb := CheckButton.new()
	cb.text = Idiomas.t("Mundo suave (fondos quietos, sin partículas)")
	cb.tooltip_text = Idiomas.t("Apagado: Mundo clásico, con menos partículas y movimiento que antes. Encendido: pantallas quietas que solo se dibujan al cambiar.")
	cb.button_pressed = suave
	cb.add_theme_font_size_override("font_size", Tema.letra(11))
	cb.toggled.connect(func(si: bool) -> void: elegir(si))
	p._lista_ajustes.add_child(cb)
