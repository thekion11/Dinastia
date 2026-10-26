extends Node
## SESIÓN 6 · AUDITORÍA VISUAL (26-10-2026): el estadio en un partido de verdad con
## la cámara de juego, de día o de noche (CLIMA=dia|noche), hacia el fotograma 150 (sin GPU el minuto 8 tarda demasiado).
##   CLIMA=noche herramientas/captura.sh res://pruebas/captura_s6_auditoria_partido.tscn
var _n := 0
var _vista: VistaEstadio
var _partido: Partido
var _clima := "dia"

func _ready() -> void:
	_clima = OS.get_environment("CLIMA") if OS.get_environment("CLIMA") != "" else "dia"
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var par := m.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	var perfil := m.perfil_estadio_de(par[0]).duplicate()
	perfil["clima"] = _clima
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.9, par[1], _partido, perfil)
	_vista.get("_juego").vel_idx = 4

func _process(_d: float) -> void:
	_n += 1
	if _n == 150:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/s6a_partido_%s.png" % _clima)
		get_tree().quit()
