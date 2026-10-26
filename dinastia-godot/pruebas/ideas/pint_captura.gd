extends Node
## FOTOS DEL CLUB POR DENTRO CON LA CÁMARA REAL (26-10-2026, paquete pint).
## Recorre con `ExploradorEstadio` (su propia cámara: tercera o primera persona)
## el vestuario, el túnel y las plantas del edificio, con la plantilla, el
## presidente y los títulos cargados como en la partida (`EdificioClub.ctx`).
##   herramientas/captura.sh res://pruebas/ideas/pint_captura.tscn
##   SUFIJO=_antes (nombre de las fotos) · TOMAS=1,3 (solo esas)
## Las fotos van a /tmp/capturas/pint/ en JPG.

var _vista: VistaEstadio
var _ex: ExploradorEstadio
var _n := 0
var _tomas: Array = []
var _k := 0
var _sufijo := OS.get_environment("SUFIJO")

## [nombre, planta, (x, z) relativos al eje del túnel y al fondo, rumbo, ¿primera persona?]
## x relativo a x0; z relativo a z_out (+) o a z_fin (−) según la marca «f».
const TOMAS := [
	["vestuario", 0, Vector2(1.0, 6.0), "o", -PI / 2.0, false],
	["taquillas", 0, Vector2(-5.2, 4.2), "o", -PI / 2.0, true],
	["tunel", 0, Vector2(0.0, -3.0), "o", PI, false],
	["oficinas", 1, Vector2(-5.0, -3.6), "f", PI, false],
	["museo", 2, Vector2(5.8, -3.6), "f", PI, false],
	["utileria", -1, Vector2(-5.5, -3.6), "f", PI, false],
]

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	var filtro := OS.get_environment("TOMAS")
	for i in TOMAS.size():
		if filtro == "" or str(i + 1) in filtro.split(","):
			_tomas.append(TOMAS[i])
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var club := m.mi_club()
	PersonajeDT.club_usuario = club.id
	var pl: Array = []
	var n := 1
	for j: Jugador in club.plantilla:
		pl.append([j.dorsal if j.dorsal > 0 else n, Nombres.visible(j.nombre)])
		n += 1
	EdificioClub.ctx = {"plantilla": pl, "titulos": 4, "presidente": "Don Ernesto Vidal",
		"gente": m.gente.fichas.duplicate(true) if m.gente != null else {}, "inst": {"museo": 4, "video": 4, "med": 3}}
	EdificioClub.mundo_ref = weakref(m)
	set_meta("mundo", m)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85)

func _colocar(t: Array) -> void:
	var d: Dictionary = _ex._datos
	var x0 := float(d["x0"])
	var rel: Vector2 = t[2]
	var z := (float(d["z_out"]) + rel.y) if String(t[3]) == "o" else (float(d["z_fin"]) + rel.y)
	_ex.ir_a_planta(int(t[1]))
	_ex.cuerpo.position = Vector3(x0 + rel.x, RecorridoClub.y_de(int(t[1])), z)
	_ex.rumbo = float(t[4])
	_ex.cuerpo.rotation.y = _ex.rumbo
	_ex.primera_persona = bool(t[5])
	_ex._colocar_camara(1.0)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
		_ex = _vista.get("_explorador")
		_ex.set_physics_process(false)
	if _n < 10:
		return
	## Una toma cada 25 cuadros: se coloca, se deja asentar y se fotografía.
	var fase := (_n - 10) % 25
	if _k >= _tomas.size():
		get_tree().quit()
		return
	if fase == 0:
		_colocar(_tomas[_k])
	elif fase < 24:
		_ex._colocar_camara(1.0)
	else:
		var img := get_viewport().get_texture().get_image()
		img.resize(1280, 720)
		var ruta := "/tmp/capturas/pint/%d_%s%s.jpg" % [_k + 1, String(_tomas[_k][0]), _sufijo]
		img.save_jpg(ruta, 0.88)
		print("FOTO ", ruta, " zona=", _ex.zona_en(_ex.cuerpo.position).get("nombre", "?"))
		_k += 1
