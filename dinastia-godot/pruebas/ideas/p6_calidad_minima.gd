extends BaseIdea
## VIGILANTE DE LA CALIDAD MÍNIMA (4-11-2026). La ciudad volvía a encender la sombra del sol en cada actualización del ciclo del sol (costaba −42 % de llamadas en MÍNIMO):
## aquí se comprueba (1) en el código, que ninguna asignación de sombra/glow/SSAO/MSAA alto en visor/ y ui/ se haga sin mirar la calidad, y (2) con la ciudad y el estadio
## abiertos en MÍNIMO y el sol ya girado, que NINGUNA luz tiene sombra y que ningún entorno tiene glow, SSAO, SSIL, SSR, SDFGI ni niebla volumétrica.

const PATRON := "shadow_enabled = true|glow_enabled = true|ssao_enabled = true|msaa_3d = Viewport.MSAA_4X|msaa_3d = Viewport.MSAA_8X|shadow_enabled = dia"

func _probar() -> void:
	_titulo("P6: CALIDAD MÍNIMA SIN OVERRIDES")
	var sospechosos: Array[String] = []
	for raiz in ["res://visor", "res://ui"]:
		_escanear(raiz, sospechosos)
	for s in sospechosos:
		print("  SIN MIRAR LA CALIDAD: ", s)
	_comprobar(sospechosos.is_empty(), "asignaciones de sombra/glow/SSAO/MSAA sin mirar la calidad (%d)" % sospechosos.size())
	Calidad.elegida = Calidad.MINIMO
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var vc := VistaCiudad.new()
	add_child(vc)
	await vc.abrir(c, m.obras, m.ciudad, m.perfil_estadio_de(c))
	for i in 30:
		await get_tree().process_frame
	_revisar(vc, "ciudad")
	vc.free()
	var ve := VistaEstadio.new()
	add_child(ve)
	await ve.abrir(c, 0.5, null, null, m.perfil_estadio_de(c))
	for i in 30:
		await get_tree().process_frame
	_revisar(ve, "estadio")
	ve.free()

func _escanear(dir: String, fuera: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".gd"):
			continue
		if dir.path_join(f) == "res://visor/calidad.gd":
			continue   ## ahí se decide la calidad: cada efecto va dentro de su `if nivel >= …`
		var n := 0
		var previa := ""
		for l in FileAccess.get_file_as_string(dir.path_join(f)).split("\n"):
			n += 1
			var t := l.strip_edges()
			var antes := previa
			previa = t
			if t.begins_with("##") or t.begins_with("#"):
				continue
			for p in PATRON.split("|"):
				if t.contains(p) and not (t.contains("Calidad") or t.contains("nivel") or t.contains("MINIMO") or t.contains("ALTO") or antes.contains("nivel >=")):
					fuera.append("%s:%d  %s" % [dir.path_join(f), n, t.left(90)])
					break
	for d in DirAccess.get_directories_at(dir):
		_escanear(dir.path_join(d), fuera)

func _revisar(raiz: Node, que: String) -> void:
	var con_sombra := 0
	for l in raiz.find_children("*", "Light3D", true, false):
		if (l as Light3D).shadow_enabled and (l as Light3D).visible:
			con_sombra += 1
			print("  luz con sombra: ", l.get_path())
	_comprobar(con_sombra == 0, "%s en MÍNIMO: ninguna luz con sombra (%d)" % [que, con_sombra])
	var malos := 0
	for w in raiz.find_children("*", "WorldEnvironment", true, false):
		var e := (w as WorldEnvironment).environment
		if e != null and (e.glow_enabled or e.ssao_enabled or e.ssil_enabled or e.ssr_enabled or e.sdfgi_enabled or e.volumetric_fog_enabled):
			malos += 1
			print("  entorno con efectos: ", w.get_path())
	_comprobar(malos == 0, "%s en MÍNIMO: ningún entorno con glow/SSAO/SSIL/SSR/SDFGI/niebla volumétrica (%d)" % [que, malos])
