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
## TANDA=3: la tercera (10-11): los grandes de cada liga, niveles por lado, esquinas una a una y la fachada curva que ya no tapan las esquinas.
const CLUBES_3 := ["B0ca Juni0rs", "R3al Madrid", "Int3r", "L1verpool", "D0rtmund", "T0ttenham", "R0ma", "R1ver Plate", "Sa0 Paulo",
	"Guadalaj4ra", "C0lo-C0lo", "B4rcelona"]
const PAISES_3: Array[String] = ["ARG", "ESP", "ITA", "ENG", "GER", "BRA", "MEX", "CHI"]
## TANDA=4: la cuarta (10-11): los grandes de cada liga que aún no tenían piezas.
const CLUBES_4 := ["Atlét1co Madrid", "Sev1lla", "C1ty de Manch.", "Juv3ntus", "Lev3rkusen", "M4rsella", "Rac1ng Club", "Ind3pendiente",
	"Palme1ras", "C0rinthians", "M0nterrey", "F3yenoord", "PSV", "Al-1ttihad", "K4izer Chiefs", "Ol1mpia", "Mill0narios", "Al1anza Lima", "LDU Qu1to"]
const PAISES_4: Array[String] = ["ESP", "ENG", "ITA", "GER", "FRA", "ARG", "BRA", "MEX", "NED", "KSA", "RSA", "PAR", "COL", "PER", "ECU"]
var _m: Mundo
var _dir := ""
var _fija: Camera3D   ## la cámara del plano congelado: el juego puede quitársela al acabar la celebración

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
	var tanda := OS.get_environment("TANDA")
	var clubes: Array = CLUBES_2 if tanda == "2" else (CLUBES_3 if tanda == "3" else (CLUBES_4 if tanda == "4" else CLUBES))
	_m = Mundo.new()
	_m.generar(PAISES_2 if tanda == "2" else (PAISES_3 if tanda == "3" else (PAISES_4 if tanda == "4" else PAISES)), 2026)
	var solo := OS.get_environment("SOLO")
	for i in clubes.size():
		if solo != "" and not str(i) in solo.split(","):
			continue
		await _uno(i, clubes[i])
	print("FIN")
	get_tree().quit()
	await get_tree().create_timer(3600.0).timeout   ## no sigue con nada más mientras sale

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
	## Mediana de 30 fotogramas: un fotograma suelto puede pillar un pico (sombras que se rehacen, carga) y dar el triple.
	var muestras: Array[int] = []
	for _f in 30:
		await get_tree().process_frame
		muestras.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		if OS.get_environment("PICOS") == "desglose" and muestras[-1] > _umbral(99999):
			await _congelar()
	muestras.sort()
	var llamadas := muestras[15]
	print("   llamadas min/mediana/max: %d / %d / %d" % [muestras[0], llamadas, muestras[29]])
	print("ESTADIO %d %s (%s) %s %d %s · %d llamadas · piezas: arco=%s torres=%s costillas=%s techo_lados=%s" % [i, nombre, c.pais,
		est.get("forma"), int(est.get("niveles", 0)), est.get("techo"), llamadas, est.has("arco"), est.get("torres_rampa", 0), est.get("costillas", 0), est.has("bandejas")] + ("  curva=%s colchon=%s" % [est.has("fachada_curva"), est.has("colchon")]))
	if OS.get_environment("PICOS") != "":
		await _picos(llamadas)
	get_viewport().get_texture().get_image().save_jpg("%s/%02d_%s_partido.jpg" % [_dir, i, c.pais], 0.88)
	if OS.get_environment("DESGLOSE") != "":
		await _desglose(vista, llamadas)
	var aerea := Camera3D.new()
	aerea.far = 1500.0
	vista.add_child(aerea)
	aerea.global_position = Vector3(-125, 72, 140)
	aerea.look_at(Vector3(0, 8, 0), Vector3.UP)
	aerea.make_current()
	for _f in 40:   ## una repetición puede quitarle la cámara: se la devuelve en cada fotograma
		await get_tree().process_frame
		if not aerea.current:
			aerea.make_current()
	get_viewport().get_texture().get_image().save_jpg("%s/%02d_%s_aerea.jpg" % [_dir, i, c.pais], 0.88)
	vista.queue_free()
	await _esperar(1.0)

## DESGLOSE=1: apaga uno a uno los grupos grandes (≥ 15 mallas, hasta 4 niveles de hondo) y dice cuántas llamadas ahorra cada uno.
func _desglose(raiz: Node, base: int) -> void:
	var grupos: Array[Node3D] = []
	_grupos(raiz, 0, grupos)
	for g in grupos:
		if _fija != null and not _fija.current:
			_fija.make_current()
			await get_tree().process_frame
		g.visible = false
		await get_tree().process_frame
		await get_tree().process_frame
		var d := base - RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		g.visible = true
		if d >= 15:
			print("   -%d  %s" % [d, raiz.get_path_to(g)])

func _grupos(n: Node, hondo: int, fuera: Array[Node3D]) -> void:
	for h in n.get_children():
		if h.find_children("*", "GeometryInstance3D", true, false).size() < 15:
			continue
		if h is Node3D:
			fuera.append(h)
		if hondo < 4:
			_grupos(h, hondo + (1 if h is Node3D else 0), fuera)

## PICOS=1: 400 fotogramas; los que pasan de 1,6× la mediana se cuentan con su cámara y lo que creció (objetos, primitivas).
func _picos(mediana: int) -> void:
	var rs := RenderingServer
	## PICOS_F = fotogramas a recorrer; PICOS_ESCALA acelera el partido para pasar por más planos (saque, córner, gol, repetición…).
	Engine.time_scale = float(OS.get_environment("PICOS_ESCALA")) if OS.get_environment("PICOS_ESCALA") != "" else 1.0
	var n_f := int(OS.get_environment("PICOS_F")) if OS.get_environment("PICOS_F") != "" else 400
	for f in n_f:
		await get_tree().process_frame
		var ll := rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		if ll > _umbral(mediana) and OS.get_environment("PICOS") == "desglose":
			await _congelar()
			return
		if ll > mediana * 1.6:
			var cam := get_viewport().get_camera_3d()
			print("   PICO f%d: %d llamadas · %d objetos · %d prims · cam=%s pos=%s" % [f, ll, rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
				rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), cam.get_path() if cam else "-", cam.global_position.round() if cam else Vector3.ZERO])
		elif f % 500 == 0:
			var cam := get_viewport().get_camera_3d()
			print("   normal f%d: %d llamadas · %d objetos · cam=%s" % [f, ll, rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), cam.get_path() if cam else "-"])

## PICOS_UMBRAL: ≤ 10 = veces la mediana; > 10 = llamadas absolutas (cuando la mediana ya está dentro del pico).
func _umbral(mediana: int) -> float:
	var u := float(OS.get_environment("PICOS_UMBRAL")) if OS.get_environment("PICOS_UMBRAL") != "" else 3.0
	return u if u > 10.0 else mediana * u

## Congela ESE plano en una cámara quieta, pausa el juego y mira qué lo infla.
func _congelar() -> void:
	var rs := RenderingServer
	## Congela ESE plano en una cámara quieta y mira qué grupos lo inflan.
	var cam0 := get_viewport().get_camera_3d()
	var fija := Camera3D.new()
	fija.name = cam0.name   ## mismo nombre: `LodCine` la trata como la cámara del plano
	fija.fov = cam0.fov
	fija.far = cam0.far
	add_child(fija)
	fija.global_transform = cam0.global_transform
	var pos0 := cam0.global_position.round()
	var nombre0 := String(cam0.name)
	fija.make_current()
	_fija = fija
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	if OS.get_environment("LODCINE") != "":
		## Antes/después de `LodCine` en ESTE plano: llamadas y foto de cada uno.
		for act: bool in [false, true]:
			LodCine.activo = act
			for _f in 4:
				await get_tree().process_frame
			var lcs := get_tree().root.find_children("LodCine", "", true, false)
			print("   LODCINE %s (cám. %s, %d vigías, apagadas %s): %d llamadas" % ["SÍ" if act else "NO", get_viewport().get_camera_3d().name, lcs.size(), lcs.map(func(x): return x._apagadas.size()), rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
			get_viewport().get_texture().get_image().save_jpg("%s/%s_lodcine_%s.jpg" % [_dir, OS.get_environment("SOLO"), "si" if act else "no"], 0.9)
		get_tree().quit()
		await get_tree().create_timer(3600.0).timeout
	var b0 := rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	for fg: Node in get_tree().root.find_children("FestejoGrada", "", true, false):
		(fg as Node3D).visible = false
		await get_tree().process_frame
		await get_tree().process_frame
		print("   SIN FESTEJO DE GRADA: -%d" % (b0 - rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)))
		(fg as Node3D).visible = true
		await get_tree().process_frame
	for vp: Node in get_tree().root.find_children("*", "SubViewport", true, false):
		var sv := vp as SubViewport
		var m0 := sv.render_target_update_mode
		sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
		await get_tree().process_frame
		await get_tree().process_frame
		print("   SIN SUBVIEWPORT %s: -%d" % [get_tree().root.get_path_to(sv), b0 - rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
		sv.render_target_update_mode = m0
		await get_tree().process_frame
	if OS.get_environment("LOD_PRUEBA") != "":
		## Ensayo: apagar las piezas PEQUEÑAS (< T m) que estén a más de R m de la cámara. ¿Cuánto ahorra?
		var rt := OS.get_environment("LOD_PRUEBA").split(",")
		var r := float(rt[0])
		var t := float(rt[1]) if rt.size() > 1 else 8.0
		var apagadas: Array[GeometryInstance3D] = []
		for g: Node in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if not gi.is_visible_in_tree() or _es_persona(gi):
				continue
			var caja := gi.global_transform * gi.get_aabb()
			if caja.size.length() < t and caja.get_center().distance_to(_fija.global_position) > r:
				gi.visible = false
				apagadas.append(gi)
		await get_tree().process_frame
		await get_tree().process_frame
		print("   LOD r=%s t=%s: %d piezas apagadas, -%d llamadas" % [r, t, apagadas.size(), b0 - rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
		get_viewport().get_texture().get_image().save_jpg("%s/lod_despues.jpg" % _dir, 0.9)
		for gi in apagadas:
			if is_instance_valid(gi):
				gi.visible = true
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/lod_antes.jpg" % _dir, 0.9)
		get_tree().quit()
		return
	var foto0 := _visibles(get_tree().root)
	var serie: Array[int] = []
	for _k in (int(OS.get_environment("PICOS_SERIE")) if OS.get_environment("PICOS_SERIE") != "" else 12):   ## ¿el pico sigue con el plano quieto (es lo que se ve) o se va solo (es el corte de cámara)?
		serie.append(rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		await get_tree().process_frame
	var base := serie[-1]
	print("   PLANO CONGELADO %s %s: %s llamadas" % [nombre0, pos0, serie])
	var foto1 := _visibles(get_tree().root)
	for k: String in foto0:
		if not foto1.has(k):
			print("   SE FUE: ", k)
	for k: String in foto1:
		if not foto0.has(k):
			print("   LLEGO: ", k)
	## Los SubViewport (cartas, retratos, pantallas) dibujan su propio mundo: ¿cuánto pesan?
	for vp: Node in get_tree().root.find_children("*", "SubViewport", true, false):
		var sv := vp as SubViewport
		var antes := sv.render_target_update_mode
		sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
		await get_tree().process_frame
		await get_tree().process_frame
		var d := base - rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		sv.render_target_update_mode = antes
		await get_tree().process_frame
		print("   SUBVIEWPORT -%d  %s (modo %d, propio=%s)" % [d, get_tree().root.get_path_to(sv), antes, sv.own_world_3d])
	await _desglose(get_tree().root, base)
	get_tree().quit()
	await get_tree().create_timer(3600.0).timeout   ## no sigue con nada más mientras sale

## Rutas de los nodos visibles con algo que dibujar (3D y 2D), hasta 6 niveles.
func _visibles(n: Node, hondo: int = 0) -> Dictionary:
	var fuera := {}
	for h in n.get_children():
		var vis: bool = h.visible if (h is Node3D or h is CanvasItem) else true
		if not vis:
			continue
		if hondo < 6:
			fuera.merge(_visibles(h, hondo + 1))
		if hondo <= 4 and (h is Node3D or h is CanvasItem):
			fuera[String(get_tree().root.get_path_to(h))] = true
	return fuera

## Jugadores, árbitros, balón y gente animada: nunca se apagan (se notaría).
func _es_persona(n: Node) -> bool:
	var p := n
	for _k in 8:
		if p == null:
			return false
		if p is Skeleton3D or String(p.name).to_lower().contains("balon") or String(p.name).to_lower().contains("ball"):
			return true
		p = p.get_parent()
	return false
