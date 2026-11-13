extends Node
## EL MODO JUGADOR («La Ruta»), EN FOTOS (13-11-2026): la creación, las tres
## ofertas, Hoy recién firmado, el mini juego del entreno, el resumen de un
## partido y, tras simular unas semanas, Hoy, Yo y Ruta. Fuera del repo, en JPG.
##   SALIDA=<carpeta> [PUESTO=MC] [NOMBRE=…] [SEMANAS=6] [OFERTA=0..2] [PREFIJO=…] [MOVIL=1] xvfb-run -a godot --path . \
##     --rendering-driver vulkan --resolution 1280x720 res://pruebas/captura_modo_jugador.tscn
var _n := 0
var _ui: CarreraJugadorUI
var _salida := OS.get_environment("SALIDA")
var _prefijo := OS.get_environment("PREFIJO")
var _semanas := maxi(1, int(OS.get_environment("SEMANAS"))) if OS.get_environment("SEMANAS") != "" else 6
var _hechas := 0
var _paso := 0
var _toque: RutaToque

func _ready() -> void:
	## MOVIL=1: como en un teléfono (zoom de interfaz y, de pie, lienzo estrecho).
	if OS.get_environment("MOVIL") == "1":
		EscalaMovil.forzar = true
		EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	CarreraJugadorUI.mundo = null
	CarreraJugadorUI.nombre_pedido = OS.get_environment("NOMBRE")
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)
	if OS.get_environment("PUESTO") != "":
		_ui._puesto = OS.get_environment("PUESTO")
		_ui._pintar_crear()

func _foto(nombre: String) -> void:
	if _salida != "":
		get_viewport().get_texture().get_image().save_jpg("%s/%s%s.jpg" % [_salida, _prefijo, nombre], 0.9)

func _process(_d: float) -> void:
	_n += 1
	if _n % 12 != 0:
		return
	_paso += 1
	var c := _ui.carrera
	var m := CarreraJugadorUI.mundo
	match _paso:
		2:
			_foto("1_crear")
			_ui._buscar_club()
		3:
			_foto("2_ofertas")
			var ofertas := CarreraComienzo.pruebas(m, hash(c.jugador_id))
			_ui._firmar(ofertas[clampi(int(OS.get_environment("OFERTA")), 0, ofertas.size() - 1)])
		4:
			_foto("3_hoy")
			_toque = RutaToque.abrir(_ui)
		5:
			_toque._marca = _toque._centro + 0.02
			_toque.golpear()
		6:
			_foto("4_toque")
			_toque.queue_free()
			CarreraRuta.anotar_toque(c, m, 1.0)
			c.entrenar(m)
			_ui._cerrar_semana({"goles_local": 2, "goles_visita": 1, "goles": 1, "asist": 1, "nota": 8.2, "minutos": 90, "titular": true, "encajados": 1, "paradas": 3}, true)
		7:
			_foto("5_resumen")
			_ui._pintar_semana()
		8:
			for _i in _semanas:
				_ui._cerrar_semana({})
			_ui._pintar_semana()
		9:
			_foto("6_hoy_semanas")
			_ui._pestana = "yo"
			_ui._pintar_semana()
		10:
			_foto("7_yo")
			_ui._pestana = "ruta"
			_ui._pintar_semana()
		11:
			_foto("8_ruta")
			get_tree().quit()
