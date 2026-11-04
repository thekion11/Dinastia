extends BaseIdea
## EL MENÚ NO CARGA EL ESTADIO NI EL PARTIDO 3D (NI LOS GRUPOS CHICOS) (3-11-2026, memoria del menú; `docs/04_auditorias/compilacion_menu_2026-11-03.md`).
## Godot compila un script en cuanto otro lo nombra: nombrar `VistaEstadio` o `StadiumBuilder` desde la interfaz del menú metía ~85 scripts (~65 MB) en
## memoria al abrir el juego. Ahora se cargan al usarlos (`load("res://…")`). Esta prueba corre en su propio proceso (en el banco, otras pruebas ya cargaron
## el estadio): instancia `Principal` y comprueba que NINGUNO de los scripts gordos de la familia estadio/partido quedó en caché.

const GORDOS := ["res://ui/estadio.gd", "res://visor/stadium_builder.gd", "res://visor/motor_jugable.gd", "res://visor/tunel_vestuario.gd",
	"res://ui/principal/jornada_partido.gd", "res://visor/ceremonia_partido.gd", "res://visor/entorno_estadio.gd", "res://visor/match_playback.gd",
	## Los grupos chicos (3-11, 2.ª tanda): partido jugable y sus extras, edificio del club y museo, rueda de prensa 3D, creador de personaje, kits, minijuegos.
	"res://ui/partido_jugable.gd", "res://visor/edificio_club.gd", "res://visor/galeria_club.gd", "res://visor/recorrido_club.gd", "res://visor/museo_ampliado.gd",
	"res://ui/principal/rueda_prensa.gd", "res://ui/rueda_prensa_escena3d.gd", "res://ui/componentes/creador_personaje.gd", "res://ui/componentes/sala_minijuegos.gd",
	"res://ui/componentes/panel_controles.gd", "res://ui/componentes/telefono.gd", "res://ui/componentes/disenador_kit.gd", "res://visor/repeticion.gd", "res://visor/cine_gol.gd",
	## A4 (4-11, memoria antes de la ciudad): pantallas de gestión que no pinta el menú al arrancar y pantallas modales que solo salen en un evento.
	"res://ui/pantallas/pantalla_plantel.gd", "res://ui/pantallas/pantalla_ficha.gd", "res://ui/pantallas/pantalla_opciones.gd",
	"res://ui/componentes/escena_despido.gd", "res://ui/componentes/presentacion_fichaje.gd", "res://ui/componentes/documental_temporada.gd",
	"res://ui/componentes/mesa_agente_ui.gd", "res://ui/sorteo.gd", "res://ui/sorteo_escena3d.gd", "res://visor/celebracion_trofeo.gd", "res://visor/pc_oficina.gd"]

func _probar() -> void:
	_titulo("EL MENÚ NO CARGA EL ESTADIO NI EL PARTIDO 3D")
	for r: String in GORDOS:
		_comprobar(FileAccess.file_exists(r), "existe %s" % r)
	var ps := load("res://escenas/principal.tscn") as PackedScene
	var pr := ps.instantiate()
	add_child(pr)
	await get_tree().process_frame
	var cargados: Array[String] = []
	for r: String in GORDOS:
		if ResourceLoader.has_cached(r):
			cargados.append(r)
	_comprobar(cargados.is_empty(), "tras abrir el menú no hay en memoria: %s" % str(cargados))
	## Y al USARLOS sí se cargan (el 3D sigue funcionando): el acceso perezoso de la jornada y de la pantalla del estadio.
	_comprobar(pr.get("_jornada") != null and ResourceLoader.has_cached("res://ui/principal/jornada_partido.gd"), "la jornada se crea al usarla")
	_comprobar(pr.get("_ui_club_estadio") != null and ResourceLoader.has_cached("res://ui/pantallas/pantalla_club_estadio.gd"), "la pantalla del estadio se crea al usarla")
	pr.queue_free()
