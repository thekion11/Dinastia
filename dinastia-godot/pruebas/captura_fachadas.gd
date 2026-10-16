extends Node
## LAS FACHADAS DE LOS ESTADIOS, VISTAS DESDE FUERA (16-10-2026).
##
##   herramientas/captura.sh res://pruebas/captura_fachadas.tscn
##   (SALIDA=antes|despues, por defecto «despues»; SOLO=0,2 elige estadios; PLANOS=calle,dron)
##
## Seis estadios de estilos distintos (ladrillo, membrana, vidrio, hormigón,
## barrio y chapa) y tres planos de cada uno: aéreo desde la esquina, a pie de
## calle frente a una tribuna y la cámara de TRANSMISIÓN del partido (la que se
## ve en el plano general) y el «Dron orbital». Deja `pruebas/capturas/fachada_<SALIDA>_<n>_<plano>`.

## [nombre, índice en PRESETS_B6 (-1 = perfil de un club chico), clima, niveles, aforo, cambios]
const ESTADIOS := [
	["ladrillo", 1, "dia", 2, 44000, {}],
	["membrana", 4, "noche", 4, 90000, {}],
	["vidrio", 3, "dia", 2, 46000, {}],
	["hormigon", 6, "tarde", 3, 66000, {}],
	["barrio", -1, "dia", 1, 9000, {"forma": "ingles", "techo": "parcial", "fachada": "hormigon"}],
	["chapa", 5, "noche", 3, 66000, {}],
]
var PLANOS := ["aereo", "calle", "tv", "dron"]

var _mundo: Mundo
var _cam: Camera3D
var _raiz: Node3D
var _i := -1
var _plano := 0
var _frame := 0
var _salida := "despues"
var _solo: Array = []
var _geo := {}

func _ready() -> void:
	if OS.get_environment("SALIDA") != "":
		_salida = OS.get_environment("SALIDA")
	if OS.get_environment("PLANOS") != "":
		PLANOS = Array(OS.get_environment("PLANOS").split(","))
	if OS.get_environment("SOLO") != "":
		for s in OS.get_environment("SOLO").split(","):
			_solo.append(int(s))
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	_cam = Camera3D.new()
	_cam.far = 900.0
	add_child(_cam)
	_cam.current = true
	_siguiente_estadio()

func _siguiente_estadio() -> void:
	_i += 1
	while _i < ESTADIOS.size() and not _solo.is_empty() and not (_i in _solo):
		_i += 1
	if _i >= ESTADIOS.size():
		print("FIN capturas de fachadas")
		get_tree().quit()
		return
	if _raiz != null:
		_raiz.queue_free()
	_raiz = Node3D.new()
	add_child(_raiz)
	var fila: Array = ESTADIOS[_i]
	var clubes: Array = _mundo.ligas[0].clubes
	var c: Club = clubes[(_i * 3) % clubes.size()]
	var perfil: Dictionary
	if int(fila[1]) >= 0:
		var e := EstadioPropio.new()
		for k: String in (EstadioPropio.PRESETS_B6[int(fila[1])][3] as Dictionary):
			e.ajustes[k] = EstadioPropio.PRESETS_B6[int(fila[1])][3][k]
		perfil = e.perfil(_mundo.mi_club())
		c = _mundo.mi_club()
	else:
		perfil = c.perfil_estadio()
	for k: String in (fila[5] as Dictionary):
		perfil[k] = fila[5][k]
	perfil["clima"] = fila[2]
	perfil["niveles"] = fila[3]
	perfil["aforo"] = fila[4]
	Ambience.apply(_raiz, perfil, null, Calidad.elegida)
	StadiumBuilder.build_pitch(_raiz, perfil, c)
	StadiumBuilder.build(_raiz, perfil, int(fila[4]), 0.85, c._hash_id(), c)
	var g := StadiumBuilder.geom_de_forma(String(perfil["forma"]))
	var niv := StadiumBuilder.niveles_de(perfil, int(fila[4]))
	_geo = {
		"dx": float(g["dx"]), "dz": float(g["dz"]),
		"fx": StadiumBuilder.centro_tribuna(float(g["dx"]), niv) + StadiumBuilder.fondo_tribuna(niv) / 2.0,
		"fz": StadiumBuilder.centro_tribuna(float(g["dz"]), niv) + StadiumBuilder.fondo_tribuna(niv) / 2.0,
		"alto": StadiumBuilder.altura_de(perfil, int(fila[4])),
	}
	print("estadio %d (%s): forma %s, %d niveles, fachada %s" % [_i, fila[0], perfil["forma"], niv,
		perfil.get("fachada", "hormigon")])
	_plano = 0
	_frame = 0
	_encuadre()

func _encuadre() -> void:
	var fx: float = _geo["fx"]
	var fz: float = _geo["fz"]
	var alto: float = _geo["alto"]
	match PLANOS[_plano]:
		"aereo":
			_cam.fov = 55.0
			_cam.position = Vector3(fx + 70.0, alto + 42.0, fz + 85.0)
			_cam.look_at(Vector3(fx * 0.25, alto * 0.45, fz * 0.3), Vector3.UP)
		"calle":
			_cam.fov = 62.0
			_cam.position = Vector3(fx + 34.0, 2.2, 22.0)
			_cam.look_at(Vector3(fx, alto * 0.42, -4.0), Vector3.UP)
		"tv":
			_cam.fov = CameraRig.FOV_TRANSMISION
			_cam.position = Vector3(minf(CameraRig.DISTANCIA_TELE_X_MAX, float(_geo["dx"]) - 7.0), CameraRig.ALTURA_TRANSMISION, 0.0)
			_cam.look_at(Vector3(0, 0, 0), Vector3.UP)
		"dron":
			## El «Dron orbital» del partido: el plano general desde arriba.
			_cam.fov = 48.0
			_cam.position = Vector3(0, alto + 28.0, 60.0)
			_cam.look_at(Vector3(0, 0, 0), Vector3.UP)

func _process(_d: float) -> void:
	if _i >= ESTADIOS.size():
		return
	_frame += 1
	if _frame < 6:
		return
	var nombre := "res://pruebas/capturas/fachada_%s_%d_%s_%s.png" % [_salida, _i + 1, ESTADIOS[_i][0], PLANOS[_plano]]
	get_viewport().get_texture().get_image().save_png(nombre)
	print("captura: ", nombre)
	_frame = 0
	_plano += 1
	if _plano >= PLANOS.size():
		_siguiente_estadio()
	else:
		_encuadre()
