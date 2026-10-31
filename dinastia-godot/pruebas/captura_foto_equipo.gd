extends Node
## LA FOTO DE EQUIPO de la ceremonia (semana 4, 27-10-2026) con el estadio y los jugadores reales:
## un fotograma con flash y otro sin él. Sale en /tmp/foto_equipo_{flash,sin}.png.
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_foto_equipo.tscn

var _vista: VistaEstadio
var _cer: CeremoniaPartido
var _n := 0

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _process(_d: float) -> void:
	_n += 1
	if _n == 40:
		var perfil: Dictionary = _vista.get("_perfil")
		var gc := StadiumBuilder.geom_de_forma(String(perfil.get("forma", "oval")))
		var partido: Partido = _vista.get("partido")
		var vieja: Variant = _vista.get("_ceremonia")
		if vieja is CeremoniaPartido and is_instance_valid(vieja):
			(vieja as CeremoniaPartido).terminar()
		_cer = CeremoniaPartido.iniciar(_vista, _vista.get("_raiz3d"), _vista.get("_en_campo"), partido.local, partido.visita,
			"Estadio", float(gc["dx"]), float(gc["dz"]), StadiumBuilder.tunel_x(perfil))
		_vista.get("_juego").vel_idx = 0
		_vista.set("_ceremonia", _cer)
		_cer.set("_t", CeremoniaPartido.INICIO_SORTEO - CeremoniaPartido.T_FOTO + 0.05)
	elif _n > 40 and _n < 200 and is_instance_valid(_cer):
		_cer.set("_t", CeremoniaPartido.INICIO_SORTEO - CeremoniaPartido.T_FOTO + (0.72 if _n < 120 else 1.2))
	if _n == 110:
		get_viewport().get_texture().get_image().save_png("/tmp/foto_equipo_flash.png")
		print("FOTO flash")
	if _n == 190:
		get_viewport().get_texture().get_image().save_png("/tmp/foto_equipo_sin.png")
		print("FOTO sin")
		get_tree().quit()
