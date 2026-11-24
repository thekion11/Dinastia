extends "res://pruebas/auditoria_gestion_movil.gd"
## LAS PANTALLAS DEL PARTIDO EN EL TELÉFONO (17-11-2026, Auditoría: «táctil a 2400×1080: botones de ≥ 9 mm, nada debajo de la muesca»). El mismo
## teléfono que `auditoria_gestion_movil` (400 ppp, 6,5", 2400×1080 en horizontal, zoom de interfaz del móvil) con la previa, sus pestañas, la pausa,
## el descanso, el resultado final y los momentos, cada una con un club de otro país (orden 34). En cada pantalla:
##  · lo que se TOCA mide al menos `MIN_MM_TOCA` (9 mm) de alto y de ancho, y dos cosas que se tocan no se pisan;
##  · nada que se toque ni ningún texto cae en la franja de la MUESCA: `MUESCA_MM` en los dos bordes cortos (en horizontal la cámara del
##    teléfono queda a un lado u otro según cómo se gire);
##  · y lo de la gestión: letra ≥ 1,8 mm, ningún texto cortado, nada fuera por los lados (`_medir`).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 2400x1080 res://pruebas/auditoria_tactil_partido.tscn

const MIN_MM_TOCA := 9.0
const MUESCA_MM := 5.0

class VistaFalsa extends Control:
	signal cerrado
	func _abrir_panel_dt() -> void: pass
	func abrir_estadisticas() -> void: pass
	func abrir_controles() -> void: pass
	func _simular_resto_motor() -> void: pass
	func salir() -> void: cerrado.emit()

class VivoFalso extends Node:
	var partido: Partido
	var mi_club: Club
	func _salir_segunda() -> void: pass

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no se mide (el tamaño de la ventana es el del teléfono)")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	if FileAccess.file_exists(Principal.PREFS):
		_prefs_antes = FileAccess.get_file_as_bytes(Principal.PREFS)
	PantallaMovil.dpi_forzado = dpi
	EscalaMovil.forzar = true
	EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	EscalaMovil.vigilar(get_tree())
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 60:
		await get_tree().process_frame
	_p.set("_zoom_interfaz", EscalaMovil.ZOOM_MOVIL)
	EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	_elegir_clubes()
	await _cerrar_capas()
	var k := 0
	for c: Club in _clubes:
		await _con_club(c)
		var m: Mundo = _p.mundo
		var liga: Liga = m.liga_de_club(c) if m.has_method("liga_de_club") else null
		if liga == null:
			for l: Liga in m.ligas:
				if l.clubes.has(c):
					liga = l
		var rival: Club = liga.clubes[(liga.clubes.find(c) + 3) % liga.clubes.size()]
		var p := Partido.new(c, rival)
		var clima := Clima.del_partido(c.pais, m.semana, m.anio, c.id + rival.id)
		await _pantallas(p, c, liga, clima, k)
		k += 1
	print("RESUMEN (px/mm %.2f · lienzo %s)" % [PantallaMovil.px_por_mm(self), get_viewport().get_visible_rect().size])
	for r: String in _resumen:
		print("  " + r)
	print("===== FIN. %d fallos =====" % _fallos)
	PantallaMovil.dpi_forzado = 0.0
	EscalaMovil.forzar = false
	_devolver_preferencias()
	get_tree().quit(0 if _fallos == 0 else 1)

func _esperar(n := 12) -> void:
	for i in n:
		await get_tree().process_frame

func _pantallas(p: Partido, c: Club, liga: Liga, clima: Dictionary, k: int) -> void:
	var pais := c.pais
	var menu := MenuPartido.mostrar(_p, p, c, liga, clima)
	await _esperar()
	await _tocar("%s previa" % pais, menu)
	for tab: String in (["uniforme", "estadio", "saque", "opciones", "camara"] if k == 0 else ["saque", "opciones"]):
		menu._abrir(tab)
		await _esperar()
		await _tocar("%s previa: %s" % [pais, tab], menu)
	menu.queue_free()
	var v := VistaFalsa.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p.add_child(v)
	p.minuto = 52
	var pausa := MenuPausaPartido.abrir(v, p)
	await _esperar()
	await _tocar("%s pausa" % pais, pausa)
	v.queue_free()
	p.preparar()
	while p.minuto < 45:
		p.simular_minuto()
	var vivo := VivoFalso.new()
	vivo.partido = p
	vivo.mi_club = c
	_p.add_child(vivo)
	DescansoPartido.en_pruebas = true
	var d := DescansoPartido.mostrar(vivo)
	DescansoPartido.en_pruebas = false
	await _esperar()
	await _tocar("%s descanso" % pais, d._raiz)
	d.queue_free()
	vivo.queue_free()
	while not p.terminado_ya:
		p.simular_minuto()
	var r := ResultadoPartido.mostrar(_p, p, c)
	await _esperar()
	await _tocar("%s final" % pais, r._raiz)
	r.queue_free()
	var mo := MomentosPartido.mostrar(_p, p, c)
	await _esperar()
	await _tocar("%s momentos" % pais, mo._raiz)
	mo.queue_free()
	await _esperar(4)

## Lo de 9 mm y la muesca, y después lo de la gestión (`_medir`).
func _tocar(etiqueta: String, raiz: Control) -> void:
	var mm := PantallaMovil.px_por_mm(self)
	var lienzo := get_viewport().get_visible_rect().size
	var franja := MUESCA_MM * mm
	var chicos: Array = []
	var en_muesca: Array = []
	var n := 0
	for c: Control in _visibles(raiz):
		var rc := c.get_global_rect()
		var txt := _texto(c)
		if _tocable(c):
			n += 1
			var r := _recorte(c)
			if r.size.y >= rc.size.y - 1.0 and r.size.x >= rc.size.x - 1.0 and (rc.size.x / mm < MIN_MM_TOCA - 0.05 or rc.size.y / mm < MIN_MM_TOCA - 0.05):
				chicos.append("%s «%s» %.1f×%.1f" % [c.get_class(), (txt if txt != "" else String(c.name)).left(14).replace("\n", " "), rc.size.x / mm, rc.size.y / mm])
		if (_tocable(c) or (txt != "" and c is Label)) and (rc.position.x < franja or rc.end.x > lienzo.x - franja):
			if rc.size.x < lienzo.x * 0.9:   ## lo que ocupa todo el ancho (fondos, filas a sangre) no cuenta
				en_muesca.append("%s «%s»" % [c.get_class(), (txt if txt != "" else String(c.name)).left(14).replace("\n", " ")])
	_comprobar(chicos.is_empty(), "[%s] lo que se toca mide ≥ %.0f mm (%d de %d menores: %s)" % [etiqueta, MIN_MM_TOCA, chicos.size(), n, ", ".join(chicos.slice(0, EJEMPLOS))])
	_comprobar(en_muesca.is_empty(), "[%s] nada en la franja de la muesca (%.0f mm a cada lado; %d: %s)" % [etiqueta, MUESCA_MM, en_muesca.size(), ", ".join(en_muesca.slice(0, EJEMPLOS))])
	if OS.get_environment("FOTOS") == "1":
		var dir := OS.get_environment("CAPTURA_DIR") if OS.get_environment("CAPTURA_DIR") != "" else "user://"
		get_viewport().get_texture().get_image().save_jpg(dir.path_join("tactil_partido_%s.jpg" % etiqueta.replace(" ", "_").replace(":", "")), 0.85)
	_medir(etiqueta, raiz)
