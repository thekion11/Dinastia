extends Node
## ESTADIO 2.0, fase 2: el edificio del club por plantas. Una foto por sala,
## entrando por el ascensor. Hoja: `pruebas/capturas/edificio_club.png`.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/captura_edificio_club.tscn

var _vista: VistaEstadio
var _ex: ExploradorEstadio
var _imgs: Array[Image] = []
var _n := 0
var _paso := 0
## [planta, sala] en el orden de las fotos.
const SALAS := [[0, "Vestuario"], [-2, "Estacionamiento"], [-1, "Utilería"], [-1, "Enfermería"],
	[-1, "Vestuario visitante"], [1, "Oficina del DT"], [1, "Despacho del presidente"], [1, "Sala de vídeo"],
	[2, "Sala de prensa"], [2, "Museo del club"], [1, "Pasillo"], [0, "Ascensor"]]

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var club: Club = m.ligas[0].clubes[0]
	PersonajeDT.club_usuario = club.id
	var pl: Array = []
	for j: Jugador in club.plantilla:
		pl.append([pl.size() + 1, Nombres.visible(j.nombre)])
	EdificioClub.ctx = {"inst": {"park": 5, "med": 7, "video": 6, "museo": 6}, "dentro": {"sala_prensa": "television"},
		"plantilla": pl, "titulos": 4, "presidente": "Presidente Ficticio"}
	var perfil := EstadioPropio.new().perfil(club)
	perfil["niveles"] = 2
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, perfil)

func _foto() -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(480, 270)
	_imgs.append(img)

func _colocar(planta: int, sala: String) -> void:
	_ex.ir_a_planta(planta)
	for z: Dictionary in _ex.zonas:
		if int(z.get("planta", 0)) == planta and String(z["nombre"]) == sala:
			var r: Rect2 = z["r"]
			## Desde el fondo de la sala mirando hacia el escaparate (−Z).
			_ex.cuerpo.position = Vector3(r.get_center().x, RecorridoClub.y_de(planta), minf(r.end.y - 0.3, r.get_center().y + 1.6))
			_ex.rumbo = PI
			_ex.paso(Vector2.ZERO, false, 0.0)
			_ex._colocar_camara(1.0)
			print("SALA ", planta, " ", sala, " zona=", _ex.zona_en(_ex.cuerpo.position).get("nombre", "?"))
			return
	print("NO HAY SALA ", planta, " ", sala)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
		_ex = _vista._explorador
		_ex.set_physics_process(false)
	if _n >= 10 and (_n - 10) % 6 == 0:
		if _paso > 0:
			_foto()
		if _paso >= SALAS.size():
			var hoja := Image.create(480 * 4, 270 * 3, false, Image.FORMAT_RGBA8)
			for k in _imgs.size():
				hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 4) * 480, (k / 4) * 270))
			hoja.save_png("res://pruebas/capturas/edificio_club.png")
			print("HOJA OK")
			get_tree().quit()
			return
		_colocar(int(SALAS[_paso][0]), String(SALAS[_paso][1]))
		_paso += 1
