extends Node
## CAPTURAS DE LA CONFIGURACIÓN DEL CLUB (fase 1, etapa 4), en Forward+ y a 1920×1080:
##   herramientas/captura.sh res://pruebas/f1c_captura_config.tscn
## Identidad, escudo, equipación, mascota 3D, juego y gráficos, y la confirmación.
var _p: PantallaConfigClub
var _n := 0
const PLAN := [
	[0, 25, "f1c_config_1_identidad"], [1, 70, "f1c_config_2_escudo"], [2, 45, "f1c_config_3_equipacion"],
	[3, 60, "f1c_config_4_mascota"], [4, 25, "f1c_config_5_estadio"], [5, 20, "f1c_config_6_casa"],
	[6, 25, "f1c_config_7_juego"], [7, 30, "f1c_config_8_confirmar"],
]
var _i := 0
var _espera := 0

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 2468)
	_p = PantallaConfigClub.new()
	_p.configurar({"mundo": m, "modo": "creador"})
	_p.datos.club.nombre = "Deportivo Andino"
	_p.datos.club.estadio_nombre = "La Fortaleza del Valle"
	_p.datos.club.color1 = "#0b3d91"
	_p.datos.club.color2 = "#f2c230"
	_p.datos.lema = "Hasta el último minuto"
	_p.datos.mascota = "aguila"
	add_child(_p)
	_ir()

func _ir() -> void:
	_p.ir_a(int(PLAN[_i][0]))
	_p._t_previa = 0.0
	_espera = int(PLAN[_i][1])

func _process(_dt: float) -> void:
	_n += 1
	_espera -= 1
	if _espera == 2 and int(PLAN[_i][0]) == 7:
		_p.siguiente()
	if _espera > 0:
		return
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % String(PLAN[_i][2]))
	print("captura ", PLAN[_i][2])
	_i += 1
	if _i >= PLAN.size():
		get_tree().quit()
		return
	_ir()
