extends Node
## SESIÓN 6 · AUDITORÍA VISUAL (26-10-2026): la ciudad propia con la cámara real
## del mapa y a pie, de día (13:00) y de noche (22:30), para buscar texturas rotas,
## objetos flotando, LOD que salta e iluminación rara.
##   herramientas/captura.sh res://pruebas/captura_s6_auditoria_ciudad.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n)

func _hora(h: float) -> void:
	_v.set("_hora", h)
	_v.call("_aplicar_hora")

func _a_pie(pos: Vector3, rumbo: float) -> void:
	var e: ExploradorCiudad = _v.get("_explorador")
	e.cuerpo.position = pos
	e.rumbo = rumbo

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_hora(13.0)
	if _n == 20:
		_foto("s6a_mapa_dia")
		_hora(22.5)
	if _n == 30:
		_foto("s6a_mapa_noche")
		_v.explorar("pie")
		_a_pie(Vector3(-30, 0.2, -470), PI)
	if _n == 44:
		_foto("s6a_pie_noche_estadio")
		_a_pie(Vector3(334, 0.2, -560), PI)
		_hora(13.0)
	if _n == 58:
		_foto("s6a_pie_dia_calle")
		get_tree().quit()
