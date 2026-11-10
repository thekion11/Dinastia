extends Node
## NADA DESAPARECE A LA VISTA (10-11, sesión 7): oclusión por sala del vestuario (`OcultarEstadioDentro`). En el centro del vestuario, con la cámara real del recorrido, gira 12 rumbos;
## en cada uno toma una foto CON la ocultación que decide el explorador y, sin mover nada, otra tras devolver el estadio entero (`devolver`). Cuenta los píxeles que cambian (más de 25/255 de
## luminancia): tiene que ser 0 (o ruido) en todos los rumbos, y a la vez en los de espaldas a la boca la primera foto tiene el estadio oculto.
##   PAIS=ESP CLUB=5 herramientas/captura.sh res://pruebas/captura_oclusion_vestuario.tscn --compat
var _vista: VistaEstadio
var _ex: ExploradorEstadio
var _n := 0
var _k := -1
var _fase := 0
var _a: Image
var _b1: Image
var _peor := 0
var _ocultos_n := 0
var _oculto := false

func _ready() -> void:
	Calidad.elegida = Calidad.MINIMO
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	var m := Mundo.new()
	m.generar([pais], 77)
	var club: Club = m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()]
	PersonajeDT.club_usuario = club.id
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, EstadioPropio.new().perfil(club))

func _lum(img: Image) -> Image:
	var i := img.duplicate() as Image
	i.convert(Image.FORMAT_L8)
	return i

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
		_ex = _vista._explorador
		_ex.planta = 0
		var d: Dictionary = _ex._datos
		_ex.cuerpo.position = Vector3(d["x0"], 0.02, (float(d["z_out"]) + float(d["z_fin"])) / 2.0)
		_ex.vel = 0.0
		_k = 0
		_fase = 0
		_ex.rumbo = 0.0
		return
	if _k < 0 or _n < 20:
		return
	if _fase < 15:   ## unos fotogramas para que el explorador decida y la cámara se asiente
		_fase += 1
		return
	if _fase == 15:
		_a = _lum(get_viewport().get_texture().get_image())
		var ocultos: Dictionary = _ex.get_meta(OcultarEstadioDentro.META, {})
		_oculto = not ocultos.is_empty()
		if _oculto:
			_ocultos_n += 1
		if OS.get_environment("SALIDA") != "":
			get_viewport().get_texture().get_image().save_png("%s_%02d_a.png" % [OS.get_environment("SALIDA"), _k])
		_ex.set_physics_process(false)
		OcultarEstadioDentro.devolver(_ex)
		_fase = 100
		return
	if _fase == 100:
		_fase = 101
		return
	var b := _lum(get_viewport().get_texture().get_image())
	if OS.get_environment("SALIDA") != "" and _fase == 101:
		get_viewport().get_texture().get_image().save_png("%s_%02d_b.png" % [OS.get_environment("SALIDA"), _k])
	if _fase == 101:   ## segunda foto sin cambiar nada: el ruido propio (personal animado, tramado)
		_b1 = b
		_fase = 102
		return
	var ruido := _dif(_b1, b)
	var cambian := _dif(_a, _b1)
	var neto := maxi(0, cambian - ruido)
	_peor = maxi(_peor, neto)
	print("RUMBO %2d (%.2f rad)  cambian al devolver el estadio: %6d   ruido propio: %6d   neto: %6d   estadio oculto: %s" % [_k, _ex.rumbo, cambian, ruido, neto, "SÍ" if _oculto else "no"])
	_k += 1
	if _k >= 12:
		print("OCLUSION_VESTUARIO peor=%d píxeles; rumbos con el estadio oculto: %d de 12" % [_peor, _ocultos_n])
		get_tree().quit()
		return
	_ex.set_physics_process(true)
	_ex.rumbo = TAU * float(_k) / 12.0
	_fase = 0

func _dif(x: Image, y: Image) -> int:
	var dx := x.get_data()
	var dy := y.get_data()
	var c := 0
	for i in dx.size():
		if absi(dx[i] - dy[i]) > 25:
			c += 1
	return c
