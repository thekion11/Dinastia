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
const TODAS := [[0, "Vestuario"], [-2, "Estacionamiento"], [-1, "Utilería"], [-1, "Enfermería"],
	[-1, "Vestuario visitante"], [1, "Oficina del DT"], [1, "Despacho del presidente"], [1, "Sala de vídeo"],
	[2, "Sala de prensa"], [2, "Museo del club"], [1, "Pasillo"], [0, "Ascensor"], [3, "Museo ampliado"]]
## PUERTAS=1 con SOLO=11,11: la segunda foto del ascensor con las puertas abiertas. RETIRADAS=1 pone camisetas retiradas en la partida (museo). SOLO=5,6 deja solo esas salas (índices de TODAS) y SIN_AVATAR=1 esconde al jugador (para ver el mobiliario).
var SALAS: Array = TODAS

func _ready() -> void:
	if OS.get_environment("SOLO") != "":
		SALAS = []
		for i in OS.get_environment("SOLO").split(","):
			SALAS.append(TODAS[int(i)])
	if OS.get_environment("ANIM") == "1":   ## la expansión del museo (planta 3) como la ve el jugador la primera vez: se olvida que ya se vio
		CargaCiudad.de("AjustesCiudad").guardar("museo_ampliado_visto", 0)
	var m := Mundo.new()
	## PAIS=ESP CLUB=5: otro país y otro club (regla 34: nunca revisar con un solo equipo).
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	m.generar([pais], 77)
	var club: Club = m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()]
	if OS.get_environment("RETIRADAS") == "1":
		m.tomar_el_mando(club.id)   ## (10-11) camisetas retiradas en la partida, para verlas en el museo del edificio real
		m.prensa.dorsales_retirados = [{"dorsal": 7, "nombre": "Carlos Valdivia", "anio": 2027}, {"dorsal": 10, "nombre": "Iván Pizarro", "anio": 2029}, {"dorsal": 5, "nombre": "Ricardo Ledesma", "anio": 2031}]
		set_meta("mundo", m)   ## que no se libere: `Mundo.actual()` es una referencia débil
	PersonajeDT.club_usuario = club.id
	var pl: Array = []
	for j: Jugador in club.plantilla:
		pl.append([pl.size() + 1, Nombres.visible(j.nombre)])
	EdificioClub.ctx = {"inst": {"park": 5, "med": 7, "video": 6, "museo": 6}, "dentro": {"sala_prensa": "television"},
		"plantilla": pl, "titulos": 4, "presidente": "Presidente Ficticio"}
	if OS.get_environment("TITULOS") != "":   ## TITULOS=14: palmarés grande (hitos ficticios; 0 = recién ascendido)
		var n_t := int(OS.get_environment("TITULOS"))
		var hs: Array = []
		for i in n_t:
			hs.append({"anio": 2005 + i * 2, "titulo": ["Liga", "Copa nacional", "Supercopa", "Copa continental"][i % 4], "cantidad": 1})
		EdificioClub.ctx["hitos"] = hs
		EdificioClub.ctx["titulos"] = n_t
	var perfil := EstadioPropio.new().perfil(m.ligas[0].clubes[int(OS.get_environment("PERFIL_DE"))] if OS.get_environment("PERFIL_DE") != "" else club)   ## PERFIL_DE=0: el estadio de OTRO club (para aislar qué cuelga)
	perfil["niveles"] = 2
	for kv in OS.get_environment("PERFIL_SET").split(",", false):   ## PERFIL_SET=aforo=85800,asiento2=#febe10: cambia campos del estadio (bisecar)
		var par := kv.split("=")
		perfil[par[0]] = int(par[1]) if par[1].is_valid_int() else par[1]
	if OS.get_environment("TRAZA") != "":
		var resumen := {}
		for c in perfil:
			if not (perfil[c] is Array) or (perfil[c] as Array).size() < 8:
				resumen[c] = perfil[c]
		print("PERFIL ", club.nombre, " ", resumen)
	if OS.get_environment("CALIDAD") != "":   ## nivel de calidad (-3 ULTRA BAJA … 3 ULTRA ALTA); sin esto, el de defecto
		Calidad.elegida = int(OS.get_environment("CALIDAD"))
		Calidad.aplicar_viewport(get_viewport(), Calidad.elegida)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, float(OS.get_environment("OCUPACION")) if OS.get_environment("OCUPACION") != "" else 0.85, null, null, perfil)

func _foto() -> void:
	print("LLAMADAS ", _imgs.size(), " ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " tris ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), " tex_MB ", snappedf(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0, 0.1), " vram_MB ", snappedf(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0, 0.1))   ## medida de dibujo por sala
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	if OS.get_environment("COMPLETA") == "1":   ## cada sala a tamaño completo (para ver el parpadeo del suelo, texturas…)
		img.save_png(OS.get_environment("SALIDA").replace(".png", "_%d.png" % _imgs.size()))
	img.resize(480, 270)
	_imgs.append(img)

func _colocar(planta: int, sala: String) -> void:
	_ex.planta = planta   ## (10-11) sin el viaje gradual del ascensor (`AscensorViaje`, 1 s por planta): la foto salía antes de llegar
	_ex.en_viaje = false
	for z: Dictionary in _ex.zonas:
		if int(z.get("planta", 0)) == planta and String(z["nombre"]) == sala:
			var r: Rect2 = z["r"]
			## Desde el fondo de la sala mirando hacia el escaparate (−Z).
			_ex.cuerpo.position = Vector3(r.get_center().x, RecorridoClub.y_de(planta), minf(r.end.y - 0.3, r.get_center().y + 1.6))
			_ex.rumbo = PI
			if sala == "Ascensor":   ## (10-11) de frente a las puertas; con PUERTAS=1 la 2.ª foto de la lista (SOLO=11,11) las lleva abiertas
				_ex.rumbo = 0.0
				PuertasAscensor.mover(get_tree(), float(planta) * EdificioClub.ALTO_PLANTA, OS.get_environment("PUERTAS") == "1" and (_paso >= 1 or SALAS.size() == 1), 0.0)
			_ex.paso(Vector2.ZERO, false, 0.0)
			_ex._colocar_camara(1.0)
			if OS.get_environment("SIN_AVATAR") == "1":
				_ex.cuerpo.visible = false
			print("SALA ", planta, " ", sala, " zona=", _ex.zona_en(_ex.cuerpo.position).get("nombre", "?"))
			return
	print("NO HAY SALA ", planta, " ", sala)

func _process(_d: float) -> void:
	_n += 1
	if OS.get_environment("TRAZA") != "":
		print("FRAME ", _n, " t=", Time.get_ticks_msec() / 1000)
	if _n == 8:
		_vista.recorrer()
		_ex = _vista._explorador
		if OS.get_environment("TRAZA") != "":
			var inst := 0
			var tris := 0
			var mayor := ""
			var mx := 0
			for mm: MultiMeshInstance3D in _vista.find_children("*", "MultiMeshInstance3D", true, false):
				inst += mm.multimesh.instance_count
				var tm := mm.multimesh.instance_count * (mm.multimesh.mesh.get_faces().size() / 3 if mm.multimesh.mesh != null else 0)
				tris += tm
				if tm > mx:
					mx = tm
					mayor = "%s (%d × %d)" % [mm.name, mm.multimesh.instance_count, mm.multimesh.mesh.get_faces().size() / 3]
			print("MULTIMALLAS instancias ", inst, " triángulos ", tris, " mayor ", mayor)
		_ex.set_physics_process(false)
	if _n >= 10 and (_n - 10) % (14 if OS.get_environment("PUERTAS") == "1" else 6) == 0:
		if _paso > 0:
			_foto()
		if _paso >= SALAS.size():
			var hoja := Image.create(480 * 4, 270 * 3, false, Image.FORMAT_RGBA8)
			var nombre := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "res://pruebas/capturas/edificio_club.png"
			for k in _imgs.size():
				hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 4) * 480, (k / 4) * 270))
			hoja.save_png(nombre)
			print("HOJA OK")
			get_tree().quit()
			return
		_colocar(int(SALAS[_paso][0]), String(SALAS[_paso][1]))
		_paso += 1
