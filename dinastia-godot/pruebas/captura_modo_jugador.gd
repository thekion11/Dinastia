extends Node
## EL MODO JUGADOR («La Ruta»), EN FOTOS (13-11-2026): la creación, las tres
## ofertas, Hoy recién firmado, el mini juego del entreno, el resumen de un
## partido y, tras simular unas semanas, Hoy, Yo y Ruta. Fuera del repo, en JPG.
##   SALIDA=<carpeta> [PUESTO=MC] [NOMBRE=…] [SEMANAS=6] [OFERTA=0..2] [PREFIJO=…] [MOVIL=1] [TEMPORADA=1] [BOTAS=1] [IDIOMA=en] xvfb-run -a godot --path . \
##     --rendering-driver vulkan --resolution 1280x720 res://pruebas/captura_modo_jugador.tscn
var _n := 0
var _ui: CarreraJugadorUI
var _salida := OS.get_environment("SALIDA")
var _prefijo := OS.get_environment("PREFIJO")
var _semanas := maxi(1, int(OS.get_environment("SEMANAS"))) if OS.get_environment("SEMANAS") != "" else 6
var _hechas := 0
var _paso := 0
var _toque: RutaToque
var _mo: RutaMomentos

## Para la marca a `desvio` anchos de la zona «bien» del centro y golpea.
func _jugada(desvio: float) -> void:
	_mo._barra.parada = true
	_mo._barra.marca = clampf(_mo._barra.centro + _mo._barra.bueno * desvio * (1.0 if _mo._barra.centro < 0.5 else -1.0), 0.0, 1.0)
	_mo.golpear()

func _ready() -> void:
	## MOVIL=1: como en un teléfono (zoom de interfaz y, de pie, lienzo estrecho).
	if OS.get_environment("MOVIL") == "1":
		EscalaMovil.forzar = true
		EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	RutaEstilo.sin_animar = true
	## IDIOMA=en|pt|fr|it|de|ca|pl|tr: para repasar las traducciones en pantalla.
	if OS.get_environment("IDIOMA") != "":
		Idiomas.idioma = OS.get_environment("IDIOMA")
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
			## BOTAS=1: con fama para la primera oferta de botas, que se firma (Rayo) antes del partido.
			if OS.get_environment("BOTAS") == "1":
				c.fama = 20
				c.eventos.insert(0, CarreraPatrocinio.eventos(c)[0])
				c.hitos["patro_1"] = true
				_ui._pintar_semana()
				await get_tree().process_frame
				await get_tree().process_frame
			_foto("3_hoy")
			if OS.get_environment("BOTAS") == "1":
				c.resolver(m, 0, 0)
			_toque = RutaToque.abrir(_ui)
		5:
			_toque._pista.parada = true
			_toque._pista.marca = _toque._pista.centro + 0.02
			_toque.golpear()
		6:
			_foto("4_toque")
			_toque.queue_free()
			CarreraRuta.anotar_toque(c, m, 1.0)
			_ui._msg = c.entrenar(m)
			## El partido, en «Los Momentos»: perfecto, bien, (foto), perfecto y fallo.
			_mo = RutaMomentos.abrir(_ui, _ui._partido_de_la_semana(c.club(m)))
			_mo.terminado.connect(func(res: Dictionary) -> void: _ui._cerrar_semana(res, true))
		7:
			_jugada(0.0)
		8:
			_jugada(0.8)
		9:
			_foto("5_momentos")
			_jugada(0.0)
		10:
			_jugada(3.0)
		11:
			_foto("6_resumen")
			_ui._pintar_semana()
		12:
			for _i in _semanas:
				_ui._cerrar_semana({})
			## TEMPORADA=1: hasta el final, para la pantalla del cierre.
			var tope := 70
			while OS.get_environment("TEMPORADA") == "1" and m.temporada_en_curso() and tope > 0:
				_ui._cerrar_semana({})
				tope -= 1
			if OS.get_environment("TEMPORADA") == "1" and c.ruta.get("temporada") is Dictionary:
				(c.ruta["temporada"] as Dictionary)["visto"] = false
			_ui._pintar_semana()
		13:
			_foto("7_hoy_semanas")
			_ui._pestana = "yo"
			_ui._pintar_semana()
		14:
			_foto("8_yo")
			_ui._pestana = "ruta"
			_ui._pintar_semana()
		15:
			_foto("9_ruta")
			get_tree().quit()
