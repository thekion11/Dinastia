extends Node
## (10-11) ESTADIOS ICÓNICOS DEL PACK REAL: para cada club, su estadio con la CÁMARA REAL DEL PARTIDO (`VistaEstadio` + `CameraRig`) y una
## vista aérea, midiendo llamadas de dibujo. Solo con el pack real (`Datos.usar_base_real(true)`): nombres reales solo en pack_real.json.
##   OUT=carpeta CALIDAD=0|2 SOLO=1,3 herramientas/captura.sh res://pruebas/captura_estadios_iconicos.tscn
const CLUBES := ["Manch3ster Utd", "B4rcelona", "Flum1nense", "B0ca Juni0rs", "B4yern Múnich", "M1lan", "Am3rica", "U. de Ch1le", "Par1s SG",
	"Atl. Naci0nal", "AmaZ4lu"]
const PAISES: Array[String] = ["ENG", "ESP", "BRA", "ARG", "GER", "ITA", "MEX", "CHI", "FRA", "COL", "RSA"]
## TANDA=2: la segunda (10-11): fachada curva, colchón iluminado y 9 países nuevos.
const CLUBES_2 := ["Aj4x", "Univers1tario", "Kash1ma A.", "Al-H1lal", "Al Ahly", "R4ja C.", "Atl4nta Utd", "M3lbourne V.", "Barcel0na SC",
	"B4yern Múnich", "B4rcelona"]
const PAISES_2: Array[String] = ["NED", "PER", "JPN", "KSA", "EGY", "MAR", "USA", "AUS", "ECU", "GER", "ESP"]
var _m: Mundo
var _dir := ""

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame

func _ready() -> void:
	_dir = OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/fotos_estadios"
	DirAccess.make_dir_recursive_absolute(_dir)
	Calidad.elegida = int(OS.get_environment("CALIDAD")) if OS.get_environment("CALIDAD") != "" else Calidad.MEDIO
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	print("pack real: ", Datos.usar_base_real(true))
	var dos := OS.get_environment("TANDA") == "2"
	var clubes: Array = CLUBES_2 if dos else CLUBES
	_m = Mundo.new()
	_m.generar(PAISES_2 if dos else PAISES, 2026)
	var solo := OS.get_environment("SOLO")
	for i in clubes.size():
		if solo != "" and not str(i) in solo.split(","):
			continue
		await _uno(i, clubes[i])
	print("FIN")
	get_tree().quit()

func _uno(i: int, nombre: String) -> void:
	var c: Club = null
	for x: Club in _m.clubes.values():
		if x.nombre == nombre:
			c = x
	if c == null:
		print("NO ENCONTRADO ", nombre)
		return
	var liga := _m.liga_de(c)
	var rival: Club = liga.clubes[0] if liga.clubes[0] != c else liga.clubes[1]
	_m.mi_club_id = c.id
	Partido.ctx_club_id = c.id
	var partido := Partido.new(c, rival)
	var vista := VistaEstadio.new()
	add_child(vista)
	vista.abrir(c, 0.85, rival, partido)
	await _esperar(12.0)
	var est := c.perfil_estadio()
	var llamadas := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	print("ESTADIO %d %s (%s) %s %d %s · %d llamadas · piezas: arco=%s torres=%s costillas=%s techo_lados=%s" % [i, nombre, c.pais,
		est.get("forma"), int(est.get("niveles", 0)), est.get("techo"), llamadas, est.has("arco"), est.get("torres_rampa", 0), est.get("costillas", 0), est.has("bandejas")] + ("  curva=%s colchon=%s" % [est.has("fachada_curva"), est.has("colchon")]))
	get_viewport().get_texture().get_image().save_jpg("%s/%02d_%s_partido.jpg" % [_dir, i, c.pais], 0.88)
	var aerea := Camera3D.new()
	aerea.far = 1500.0
	vista.add_child(aerea)
	aerea.global_position = Vector3(-125, 72, 140)
	aerea.look_at(Vector3(0, 8, 0), Vector3.UP)
	aerea.make_current()
	await _esperar(1.5)
	get_viewport().get_texture().get_image().save_jpg("%s/%02d_%s_aerea.jpg" % [_dir, i, c.pais], 0.88)
	vista.queue_free()
	await _esperar(1.0)
