class_name DificultadPartido
extends RefCounted
## LA DIFICULTAD DE LA CPU EN EL PARTIDO JUGABLE DE LA CARRERA (caza de fallos, 4-11-2026). La dificultad (8 categorías, orden 14 del dueño) solo la aplicaba el
## partido en que manejas a todo un equipo (`VistaEstadio`: `equipo_cpu()` salía de `control_equipo`); en el partido de la carrera y «jugar partido» (un solo jugador)
## `equipo_cpu()` era -1 y el nivel elegido no hacía NADA. Ahora el equipo RIVAL es la CPU con el nivel guardado en los ajustes (el mismo que se cicla en el estadio).
## Debutante (la normal) no cambia nada: es el motor calibrado de siempre.

static func aplicar(motor: MotorJugable, es_local_usuario: bool) -> void:
	if motor == null:
		return
	motor.equipo_cpu_fijo = 1 if es_local_usuario else 0
	motor.dificultad_cpu = VistaEstadio.dificultad_cpu_guardada()
	motor.fijar_dificultad(motor.dificultad_cpu)

## El botón «🤖 Dificultad de la CPU» del menú de PAUSA del partido jugable (4-11, orden 31): cicla los 8 niveles, se guarda en los ajustes (la misma clave que el modo
## estadio) y vale al momento. Va antes de «Simular lo que queda».
static func boton_en_pausa(pj: Control, capa: Control) -> void:
	var cajas := capa.find_children("*", "VBoxContainer", true, false)
	if cajas.is_empty() or pj.get("motor") == null:
		return
	var v := cajas[0] as VBoxContainer
	var b := Button.new()
	b.custom_minimum_size = Vector2(360, 44)
	b.add_theme_font_size_override("font_size", 17)
	b.text = texto()
	b.pressed.connect(func() -> void:
		var orden: Array = MotorJugable.ORDEN_DIFICULTAD
		var nivel := String(orden[(orden.find(VistaEstadio.dificultad_cpu_guardada()) + 1) % orden.size()])
		guardar(nivel)
		aplicar(pj.motor, bool(pj._es_local_usuario))
		b.text = texto())
	v.add_child(b)
	v.move_child(b, maxi(v.get_child_count() - 2, 1))

static func texto() -> String:
	return Idiomas.t("🤖 Dificultad de la CPU: ") + Idiomas.t(String(MotorJugable.DIFICULTADES[VistaEstadio.dificultad_cpu_guardada()]["nombre"]))

static func guardar(nivel: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "dificultad_cpu8", nivel)
	cfg.save(CajonAjustes.RUTA)
