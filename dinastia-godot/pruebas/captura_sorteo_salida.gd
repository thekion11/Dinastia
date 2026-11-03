extends Node
## LA SALIDA DE LOS EQUIPOS Y EL SORTEO con la cámara real del partido (U6, 3-11): la salida del túnel con los niños, las dos filas y el sorteo de campo con los capitanes.
## Cada momento se fija en el reloj de la ceremonia y se espera unos fotogramas a que los jugadores lleguen a su sitio. Salen en /tmp/sorteo_salida_<n>.png.
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_sorteo_salida.tscn --compat
const MOMENTOS := [7.0, 12.5, 17.0, 22.0, 29.0, 30.8]      ## salida, salida (mitad), fila local, fila visita, sorteo, sorteo (moneda)
const ESPERA := 12

var _vista: VistaEstadio
var _cer: CeremoniaPartido
var _n := 0
var _i := 0
var _desde := 0

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
		_desde = _n
	if _n < 40 or not is_instance_valid(_cer):
		return
	## El reloj avanza a paso real (0,1 s) hasta el momento: así los jugadores caminan de verdad y llegan a su sitio, como en el partido.
	if _n == _desde + 1:
		while float(_cer.get("_t")) < float(MOMENTOS[_i]) and is_instance_valid(_cer):
			_cer._process(0.1)
	if _n - _desde >= ESPERA + 3:
		get_viewport().get_texture().get_image().save_png("/tmp/sorteo_salida_%d.png" % (_i + 1))
		print("FOTO %d a los %.1f s" % [_i + 1, float(MOMENTOS[_i])])
		_i += 1
		_desde = _n
		if _i >= MOMENTOS.size():
			get_tree().quit()
