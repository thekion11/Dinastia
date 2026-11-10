extends Node
## LA COHERENCIA DE LOS MENÚS PRINCIPALES (10-11-2026, PRIORITARIO 1 del plan: «estética y diseño de los menús, falta pulir»; referencia: los
## menús de PES 2020 / eFootball). En PC (1600×900) mide, en inicio, plantel, táctica, mercado, competiciones y club, con 2 clubes de países distintos:
##  · ESCALA TIPOGRÁFICA: tamaños de letra distintos en el contenido (sin contar los títulos héroe ≥ `Tema.TAM_TITULO`): como mucho `MAX_TAMANOS`;
##  · REJILLA: el contenido de todas las pantallas de menú empieza en el mismo x y deja el mismo margen a la derecha;
##  · ESTADOS: todo lo que se pulsa tiene un estilo de foco que se ve (no vacío) y uno de pulsado;
##  · ESCUDOS Y CARAS: los de las filas de plantel y competiciones miden al menos `MIN_IMAGEN` px.
## FOTOS=1 guarda `est_<pantalla>_<club>.jpg` en CAPTURA_DIR. SOLO=Inicio,Táctica para unas pocas.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/auditoria_estetica_menus.tscn
const PANTALLAS := ["Inicio", "Mi plantel", "Táctica", "Mercado", "Clubes", "Club"]
const MAX_TAMANOS := 3
const MIN_IMAGEN := 28.0
var _p: Node
var _fallos := 0
var _resumen: Array = []
var _bordes: Array = []   ## [pantalla, x izquierdo, margen derecho] del contenido de cada menú
var _prefs_antes: Variant = null

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no se mide")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	if FileAccess.file_exists(Principal.PREFS):   ## la principal guarda sus preferencias: se devuelven como estaban
		_prefs_antes = FileAccess.get_file_as_bytes(Principal.PREFS)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 60:
		await get_tree().process_frame
	var m: Mundo = _p.mundo
	var clubes: Array = [m.mi_club()]
	for l: Liga in m.ligas:
		if not l.clubes.is_empty() and (l.clubes[0] as Club).pais != (clubes[0] as Club).pais:
			clubes.append(l.clubes[5 % l.clubes.size()])
			break
	var solo := OS.get_environment("SOLO")
	for c: Club in clubes:
		if m.mi_club() != c:
			m.tomar_el_mando(c.id)
			m.prensa.eventos_vistos.append("directiva:%d" % m.anio)
			_p.call("_refrescar")
		for i in 20:
			await get_tree().process_frame
		await _cerrar()
		for nombre: String in PANTALLAS:
			if solo != "" and not nombre in solo.split(","):
				continue
			await _pantalla(nombre, c)
	if _bordes.size() >= 2:
		var xs := _bordes.map(func(b: Array) -> float: return float(b[1]))
		var ds := _bordes.map(func(b: Array) -> float: return float(b[2]))
		_comprobar(xs.max() - xs.min() <= 2.0 and ds.max() - ds.min() <= 2.0, "rejilla: el contenido de los menús empieza en el mismo x (%s) y deja el mismo margen derecho (%s)" % [str(xs), str(ds)])
	print("RESUMEN")
	for r: String in _resumen:
		print("  " + r)
	print("===== FIN. %d fallos =====" % _fallos)
	if _prefs_antes is PackedByteArray:
		var f := FileAccess.open(Principal.PREFS, FileAccess.WRITE)
		if f != null:
			f.store_buffer(_prefs_antes)
			f.close()
	get_tree().quit(0 if _fallos == 0 else 1)

func _cerrar() -> void:
	for h: Node in _p.get_children():   ## la reunión de la directiva se CONTESTA (cerrada sin elegir se vuelve a ofrecer y taparía la pantalla)
		if h is EventoDialogo and not h.is_queued_for_deletion():
			(h as EventoDialogo).selector.elegir(0)
			for i in 90:
				await get_tree().process_frame
	for h: Node in _p.get_children():
		if h is PantallaMenu and not (h as PantallaMenu).cerrando():
			(h as PantallaMenu).cerrar()
		elif h is EventoPantallaCompleta or h is Competicion or h.name == "CapaTutorial":
			h.queue_free()
	for i in 20:
		await get_tree().process_frame

func _pantalla(nombre: String, c: Club) -> void:
	if nombre != "Inicio":
		_p.call("_ir_a_pestana", nombre)
	for i in 30:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	for t: Node in _p.find_children("CapaTutorial", "", false, false):
		t.queue_free()
	await get_tree().process_frame
	var capa: Control = GuardianFoco.capa_arriba(_p)
	var raiz: Control = capa if capa != null else _p
	var et := "%s · %s (%s)" % [nombre, c.nombre, c.pais]
	if OS.get_environment("FOTOS") == "1":
		var dir := OS.get_environment("CAPTURA_DIR") if OS.get_environment("CAPTURA_DIR") != "" else "user://"
		get_viewport().get_texture().get_image().save_jpg(dir.path_join("est_%s_%s.jpg" % [nombre.replace(" ", "_").replace("á", "a"), c.pais]), 0.85)
	_medir(et, raiz)
	if raiz is PantallaMenu:
		var hueco: Control = raiz.get("_hueco_contenido")
		if hueco != null:
			var r := hueco.get_global_rect()
			var ancho := get_viewport().get_visible_rect().size.x
			var der := ancho - r.end.x if not bool((raiz.get("_menu") as Dictionary).get("ficha", false)) else -1.0
			if der >= 0.0:
				_bordes.append([nombre, r.position.x, der])
	await _cerrar()

func _medir(et: String, raiz: Control) -> void:
	var tamanos := {}
	var sin_foco: Array = []
	var imagenes: Array = []
	for n: Node in raiz.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c.modulate.a < 0.05 or c.get_viewport() != get_viewport():
			continue
		var t: Variant = c.get("text")
		var txt := String(t).strip_edges() if t != null else ""
		if txt != "" and (c is Label or c is Button) and _tiene_letras(txt) and not (c is Label and txt.length() <= 3 and txt == txt.to_upper()):   ## sin las iniciales de los escudos
			var tam := c.get_theme_font_size("font_size")
			if tam < Tema.TAM_TITULO:
				tamanos[tam] = int(tamanos.get(tam, 0)) + 1
				if OS.get_environment("DEPURA") != "" and tam <= int(OS.get_environment("DEPURA")):
					print("    DEPURA %d «%s» %s" % [tam, txt.left(30), c.get_parent().get_parent().name])
		if c is BaseButton and not (c as BaseButton).disabled and c.focus_mode != Control.FOCUS_NONE and not (c is Button and (c as Button).flat):
			var f := c.get_theme_stylebox("focus")
			var pr := c.get_theme_stylebox("pressed")
			if f == null or f is StyleBoxEmpty or pr == null or pr is StyleBoxEmpty:
				sin_foco.append("%s «%s»" % [c.get_class(), txt.left(14)])
		## escudos y caras: imágenes casi cuadradas (la fila puede estirarlas un poco en alto); cuenta el lado menor, que es lo que se ve
		var lado := minf(c.size.x, c.size.y)
		if c is TextureRect and (c as TextureRect).texture != null and lado >= 12.0 and lado <= 140.0 and maxf(c.size.x, c.size.y) <= lado * 1.4:
			imagenes.append(lado)
	var lista := tamanos.keys()
	lista.sort()
	## los tamaños que pesan (≥ 3 % de los textos): los que hacen la jerarquía que se ve
	var total := 0
	for k: int in tamanos:
		total += int(tamanos[k])
	var principales := lista.filter(func(k: int) -> bool: return float(tamanos[k]) / maxf(1.0, float(total)) >= 0.03)
	_comprobar(principales.size() <= MAX_TAMANOS, "[%s] escala tipográfica: %d tamaños que pesan %s (todos: %s)" % [et, principales.size(), str(principales), _hist(tamanos, lista)])
	_comprobar(sin_foco.is_empty(), "[%s] todo lo que se pulsa tiene foco y pulsado que se ven (%d sin: %s)" % [et, sin_foco.size(), ", ".join(sin_foco.slice(0, 4))])
	var img_max: float = imagenes.max() if not imagenes.is_empty() else 0.0
	_resumen.append("%-40s tamaños %s · imágenes cuadradas: %d (mayor %.0f px, menor %.0f px)" % [et, _hist(tamanos, lista), imagenes.size(), img_max, imagenes.min() if not imagenes.is_empty() else 0.0])
	if et.begins_with("Mi plantel") or et.begins_with("Clubes"):
		var chicas := imagenes.filter(func(x: float) -> bool: return x < MIN_IMAGEN - 0.5)
		_comprobar(chicas.is_empty(), "[%s] escudos y caras de las filas de al menos %.0f px (%d menores: %s)" % [et, MIN_IMAGEN, chicas.size(), str(chicas.slice(0, 6))])

func _hist(t: Dictionary, lista: Array) -> String:
	return ", ".join(lista.map(func(k: int) -> String: return "%d×%d" % [k, int(t[k])]))

func _tiene_letras(s: String) -> bool:
	for i in s.length():
		var u := s.unicode_at(i)
		if (u >= 65 and u <= 90) or (u >= 97 and u <= 122) or (u >= 0xC0 and u <= 0x24F):
			return true
	return false
