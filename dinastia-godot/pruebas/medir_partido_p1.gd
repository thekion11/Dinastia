extends Node
## (Parte 1 de 2 de `medir_partido.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `medir_partido.gd`, conserva la clase.)

## MEDICIÓN DEL PARTIDO 3D QUE NO DEPENDE DE LA GRÁFICA (25-9-2026).
##
##   godot --path . --rendering-driver vulkan --resolution 1280x720 \
##         res://pruebas/medir_partido.tscn [-- medio|alto|ultra]
##
## `diagnostico_fps_partido.gd` mide FPS, y los FPS dependen de la máquina: en
## un servidor sin GPU (render por software) salen 3, y en una Intel UHD 45. Lo
## que SÍ se puede comparar entre máquinas y entre versiones del código es lo
## que el juego le PIDE a la gráfica y a la CPU en cada fotograma:
##   * llamadas de dibujo y triángulos -lo que más castiga a una integrada-,
##   * objetos 3D visibles,
##   * tiempo total del fotograma (en un servidor sin GPU es casi todo render
##     por software: sirve para comparar versiones, no máquinas),
##   * memoria de vídeo.
## Se mide con la cámara de TV, con el partido corriendo, tras dejar que el
## estadio termine de montarse.

const CALENTAR := 40
const MUESTRAS := 120

var _vista: VistaEstadio
var _n := 0
var _llamadas: Array[float] = []
var _triangulos: Array[float] = []
var _objetos: Array[float] = []
var _proceso: Array[float] = []
var _lienzo: Array[float] = []   ## (17-11) llamadas de dibujo del 2D (HUD) del viewport principal

var _fin := false

## Con PARTES=1: apaga un grupo a la vez y mira cuánto baja el fotograma
## (triángulos y llamadas de verdad, con la cámara de TV).
var _parte := -1
var _ocultos: Array = []
var _base := Vector2.ZERO
const GRUPOS := ["butacas", "hinchas", "jugadores", "pelo", "resto_multimesh", "focos", "fundidos", "mm_sin_nombre", "ojos_cejas", "coches", "sombras"]

## Con ARBOL=1: apaga cada hijo directo de la raíz 3D (y los hijos de los grandes)
## y mira cuántos triángulos y llamadas se ahorran con la cámara de TV.
var _cola_arbol: Array = []
var _prev: Node3D = null
var _base_a := Vector2.ZERO
var _paso_a := 0
var _arbol_listo := false

## POR_HIJOS=1 (19-10/20-10-2026): con el partido CONGELADO (pausa total: el
## mismo fotograma siempre) esconde por turnos cada parte del escenario y mide
## cuántas llamadas y triángulos pone en pantalla. Baja de nivel en las partes
## que pesan (más de 40 mil triángulos o 15 llamadas), hasta 4 niveles.
## (El 19-10 se hizo sin congelar y no servía: la cámara se movía.)
var _ph_cola: Array = []
var _ph_actual: Variant = null
var _ph_espera := 0
var _ph_base := Vector2.ZERO
var _ph_res: Array = []
var _ph_listo := false
var _ph_estables := 0

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	if OS.get_environment("RES3D_AUTO") != "":
		Calidad.res3d_auto = OS.get_environment("RES3D_AUTO") == "1"   ## (10-11, P1) RES3D_AUTO=1/0: fuerza la resolución 3D automática (en escritorio viene apagada)
	Calidad.modo_rendimiento = OS.get_environment("MODO_RENDIMIENTO") == "1"   ## (10-11) MODO_RENDIMIENTO=1: sin glow ni sombra del sol
	Calidad.sin_msaa = OS.get_environment("SIN_MSAA") != ""   ## (10-11) SIN_MSAA=1: apaga el MSAA del viewport (como la «Prueba de rendimiento» de Ajustes) para medir cuánto cuesta en cada nivel.
	var mundo := Mundo.new()
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"   ## (10-11) PAIS=ESP CLUB=5: otro país y otro club (regla del dueño: nunca medir con un solo equipo).
	mundo.generar([pais], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[int(OS.get_environment("CLUB")) % mundo.ligas[0].clubes.size()].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	## NOCHE=1 (10-11): el estadio se abre CON el perfil de noche, como en el juego (antes se aplicaba `Ambience` otra vez encima del de día y quedaban DOS luces direccionales con sombra: medía de más).
	var perfil_n := {}
	if OS.get_environment("NOCHE") != "":
		perfil_n = EstadioPropio.new().perfil(par[0])   ## el perfil completo del estadio del club, con el clima puesto a noche
		perfil_n["clima"] = "noche"
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]), perfil_n)

func _process(_d: float) -> void:
	if _fin:
		return
	if _saltar_intro_ceremonia():
		return
	_n += 1
	if _n == 5:
		(_vista.get("_rig") as CameraRig).switch_to(0)
	_fase_festejo_efecto()
	if _n < CALENTAR:
		return
	_fase_diagnostico_oclusion()
	_fase_ocultar()
	_fase_escena_medicion()
	if OS.get_environment("POR_HIJOS") != "":
		call(&"_por_hijos")
		return
	if OS.get_environment("PARTES") != "":
		_partes()
		return
	if OS.get_environment("ARBOL") != "":
		_arbol()
		return
	_muestrear()


## La intro y la ceremonia (filas, alineaciones, himno) se saltan: se mide el JUEGO con la cámara de TV.
## Devuelve true si el fotograma se ha usado en la intro o la ceremonia (hay que salir de _process).
func _saltar_intro_ceremonia() -> bool:
	## La intro y la ceremonia (filas, alineaciones, himno) se saltan: se mide
	## el JUEGO con la cámara de TV. Hasta el 19-10 se medía la ceremonia.
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
		return true
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
		return true
	return false


## FESTEJO=1 (confeti y bengalas de la grada durante toda la muestra) y EFECTO / DIAG_ENTORNO (antes de medir).
func _fase_festejo_efecto() -> void:
	## FESTEJO=1 (17-10-2026): mide con el confeti y las bengalas de la grada
	## encendidos durante toda la muestra (lo peor de un gol del local).
	if _n == CALENTAR - 4 and OS.get_environment("FESTEJO") != "":
		FestejoGrada.lanzar(_vista.get("_raiz3d"), Color(0.8, 0.1, 0.1), Color(1, 1, 1), "salida", 600.0)
	if _n == CALENTAR - 15 and (OS.get_environment("EFECTO") != "" or OS.get_environment("DIAG_ENTORNO") != ""):
		MedirPartidoExp.efecto(_vista)   ## 15 fotogramas ANTES de medir: apagar un efecto recompila shaders y ese tirón no debe entrar en la muestra


## DIAG_OCLU=1 (6-11): ¿está montada la oclusión del entorno y qué ve? (cámara, recinto, altura)
func _fase_diagnostico_oclusion() -> void:
	if (_n == CALENTAR or _n == CALENTAR + 50) and OS.get_environment("DIAG_OCLU") != "":
		## DIAG_OCLU=1 (6-11): ¿está montada la oclusión del entorno y qué ve? (cámara, recinto, altura)
		var oc: Node = _vista.find_child("EntornoOclusion", true, false)
		var cam := get_viewport().get_camera_3d()
		if oc == null:
			print("DIAG_OCLU: NO montada (estadio abierto o calidad > MEDIO)")
		else:
			var vis_n := 0
			var vis_sa := 0
			for c in oc.entorno.get_children():
				var gi: Array = c.find_children("*", "GeometryInstance3D", true, false)
				var propio := 1 if c is GeometryInstance3D else 0
				if c is Node3D and (c as Node3D).visible:
					vis_n += gi.size() + propio
					if c.is_in_group("sin_agrupar"):
						vis_sa += gi.size() + propio
			print("DIAG_OCLU n=%d: hijos visibles del entorno: %d geometrías (%d del horizonte); hijos=%d, ocultables=%d" % [_n, vis_n, vis_sa, oc.entorno.get_child_count(), oc.ocultables.size()])
			var otros: Array[String] = []
			for c in oc.entorno.get_children():
				if c is Node3D and (c as Node3D).visible and not c.is_in_group("sin_agrupar") or (c is Node3D and (c as Node3D).visible and c.is_in_group("sin_agrupar") and c.get_child_count() == 0):
					otros.append("%s[%s] hijos=%d" % [c.name, c.get_class(), c.get_child_count()])
			print("DIAG_OCLU visibles que no deberían: %d -> %s" % [otros.size(), ", ".join(otros.slice(0, 12))])
			var no_h: Array[String] = []
			for c in oc.entorno.get_children():
				if c.is_in_group("sin_agrupar") and c.get_child_count() > 3:
					no_h.append("%s hijos=%d" % [c.name, c.get_child_count()])
			print("DIAG_OCLU sin_agrupar con >3 hijos: %s" % ", ".join(no_h.slice(0, 12)))
			var cam_o: Camera3D = oc.get_viewport().get_camera_3d()
			print("DIAG_OCLU: oclusión procesa=%s modo=%d t=%.3f cam_propia=%s dentro_arbol=%s" % [str(oc.is_processing()), oc.process_mode, oc._t, str(cam_o.global_position) if cam_o != null else "NULA", str(oc.is_inside_tree())])
			print("DIAG_OCLU: montada mx=%.1f mz=%.1f alto=%.1f cam=%s tapado=%s" % [oc.mx, oc.mz, oc.ALTO, str(cam.global_position), str(oc.tapado(cam.global_position))])


## Lo que se oculta antes de medir: grupos enteros (OCULTAR_GRUPOS), piezas por nombre (OCULTAR) y la gente fuera del campo.
func _fase_ocultar() -> void:
	if _n == CALENTAR and OS.get_environment("OCULTAR_GRUPOS") != "":
		## OCULTAR_GRUPOS=hinchas,butacas (4-11): apaga grupos enteros de `GRUPOS` y mide el resto (cuánto ganaría un nivel más ligero).
		for gr in OS.get_environment("OCULTAR_GRUPOS").split(","):
			for g in _de_grupo(gr):
				(g as Node3D).visible = false
	if _n == CALENTAR and OS.get_environment("OCULTAR") != "":
		## OCULTAR=Cuero,Eyes (17-10-2026): esconde las piezas con ese nombre
		## para medir lo que de verdad cuestan en pantalla (con LOD y recorte).
		var nombres := OS.get_environment("OCULTAR").split(",")
		## (20-10) También contenedores: cualquier Node3D con ese nombre.
		for g in _vista.find_children("*", "Node3D", true, false):
			if String(g.name).rstrip("0123456789@_") in nombres or String(g.name) in nombres:
				(g as Node3D).visible = false
	if _n == CALENTAR and OS.get_environment("SIN_GENTE_FUERA") != "":
		_ocultar_gente_fuera()


## SIN_GENTE_FUERA=1 (20-10-2026): esconde a toda persona con esqueleto que no está en el campo.
func _ocultar_gente_fuera() -> void:
	## SIN_GENTE_FUERA=1 (20-10-2026): esconde a toda persona con esqueleto que
	## no está en el campo (suplentes, cuerpo técnico, camarógrafos,
	## recogepelotas, mascota…) para medir cuánto cuestan.
	var en_campo := {}
	for f: Dictionary in _vista.get("_en_campo"):
		if f.get("node") != null:
			en_campo[f["node"]] = true
	var ocultos := 0
	for esq in _vista.find_children("*", "Skeleton3D", true, false):
		var x: Node = esq
		var es_campo := false
		while x != null and x != _vista:
			if en_campo.has(x):
				es_campo = true
				break
			x = x.get_parent()
		if not es_campo:
			(esq as Node3D).visible = false
			ocultos += 1
	print("SIN_GENTE_FUERA: %d esqueletos ocultos" % ocultos)


## La escena de la medición: experimentos de sombras, multimallas, butacas livianas y el aplicado de MedirPartidoExp.
func _fase_escena_medicion() -> void:
	if _n == CALENTAR:
		MedirPartidoExp.aplicar(_vista)   ## (10-11) SIN_OMNI, SIN_ENTORNO_FX, SIN_SOMBRA_FINOS: experimentos de rendimiento en `medir_partido_exp.gd`
	if _n == CALENTAR and OS.get_environment("SIN_SOMBRAS") != "":
		## SIN_SOMBRAS=1 (19-10-2026): cuánto de lo dibujado son las sombras.
		for l in _vista.find_children("*", "Light3D", true, false):
			(l as Light3D).shadow_enabled = false
	if _n == CALENTAR and OS.get_environment("LISTA_MM") != "":
		call(&"_lista_multimallas")
	if _n == CALENTAR and OS.get_environment("LIVIANAS") != "":
		## LIVIANAS=1 (19-10-2026): butacas cercanas con la malla de 60 triángulos.
		Optimizar.butacas_livianas(_vista, true)


## Muestra de un fotograma (llamadas, triángulos, objetos, proceso y el HUD); al completar MUESTRAS, informe y salida.
func _muestrear() -> void:
	_llamadas.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_triangulos.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_objetos.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_proceso.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	_lienzo.append(MedirHudAB.leer(_vista, _llamadas.size() - 1, MUESTRAS))   ## (17-11) HUD_AB=1: coste 2D del HUD con y sin él
	if _llamadas.size() >= MUESTRAS:
		_fin = true
		if OS.get_environment("FOTO") != "":
			get_viewport().get_texture().get_image().save_png(OS.get_environment("FOTO"))
		print("MEDICION calidad=%d  llamadas=%.0f  triangulos=%.0f  objetos=%.0f  lienzo2d=%.0f  fotograma=%.2f ms (peor %.2f)  vram=%.0f MB" % [
			Calidad.elegida, _media(_llamadas), _media(_triangulos), _media(_objetos), _media(_lienzo),
			_media(_proceso), _proceso.max(),
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
		for l in _vista.find_children("*", "Light3D", true, false):
			var dl := l as DirectionalLight3D
			var ol := l as OmniLight3D
			print("LUZ %s sombra=%s%s%s" % [l.name, (l as Light3D).shadow_enabled, "" if dl == null else " cortes=%d dist=%.0f" % [dl.directional_shadow_mode, dl.directional_shadow_max_distance],
				"" if ol == null else " omni rango=%.1f energia=%.2f visible=%s padre=%s/%s" % [ol.omni_range, ol.light_energy, str(ol.is_visible_in_tree()), l.get_parent().name if l.get_parent() != null else "", l.get_parent().get_parent().name if l.get_parent() != null and l.get_parent().get_parent() != null else ""]])
		if OS.get_environment("DETALLE") != "":
			for f: Dictionary in Optimizar.informe(_vista, 25):
				print("DETALLE tris=%d piezas=%d corte=%.0f  %s" % [f["tris"], f["piezas"], f["corte"], f["clave"]])
		if OS.get_environment("NODOS") != "":
			_por_nodo()
		if OS.get_environment("CERRAR") != "":
			## Cierre normal: se suelta la vista y se espera antes de salir.
			_vista.queue_free()
			await get_tree().create_timer(1.0).timeout
		get_tree().quit()

## Con NODOS=1 (17-10-2026): suma triángulos por NOMBRE de nodo de las piezas de
## los personajes (hijos del esqueleto y del pelo), con la distancia a la cámara:
## `DETALLE` agrupa por malla y junta todas las piezas sin nombre de recurso.
func _por_nodo() -> void:
	var cam := get_viewport().get_camera_3d()
	var suma := {}
	for n in _vista.find_children("*", "MeshInstance3D", true, false):
		var g := n as MeshInstance3D
		if not g.is_visible_in_tree() or g.mesh == null:
			continue
		var p := g.get_parent()
		if not (p is Skeleton3D or p is BoneAttachment3D or String(p.name) == "PeloCapas" or (p.get_parent() != null and p.get_parent() is Skeleton3D)):
			continue
		var clave := String(g.name).rstrip("0123456789@").left(30)
		if not suma.has(clave):
			suma[clave] = {"tris": 0, "piezas": 0, "lejos": 0, "corte": g.visibility_range_end}
		var t: int = Optimizar._tris(g.mesh)
		suma[clave]["tris"] += t
		suma[clave]["piezas"] += 1
		if cam != null and g.global_position.distance_to(cam.global_position) > 25.0:
			suma[clave]["lejos"] += 1
	var lista := suma.keys()
	lista.sort_custom(func(a, b): return suma[a]["tris"] > suma[b]["tris"])
	for k in lista:
		print("NODO %-30s tris=%7d piezas=%3d a>25m=%3d corte=%.0f" % [k, suma[k]["tris"], suma[k]["piezas"], suma[k]["lejos"], suma[k]["corte"]])

func _media(a: Array[float]) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(1.0, float(a.size()))

func _de_grupo(nombre: String) -> Array:
	var r := []
	for n in _vista.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var es_mm := g is MultiMeshInstance3D
		var mn := ""
		if es_mm and (g as MultiMeshInstance3D).multimesh != null and (g as MultiMeshInstance3D).multimesh.mesh != null:
			mn = (g as MultiMeshInstance3D).multimesh.mesh.resource_name
		match nombre:
			"butacas": if String(g.name).begins_with("Butacas"): r.append(g)
			"hinchas": if es_mm and not String(g.name).begins_with("Butacas") and (g as MultiMeshInstance3D).multimesh.instance_count > 200: r.append(g)
			"jugadores": if g.get_parent() is Skeleton3D: r.append(g)
			"pelo": if String(g.get_parent().name) == "PeloCapas" or String(g.name).begins_with("Pelo"): r.append(g)
			"resto_multimesh": if es_mm: r.append(g)
			"focos": if String(g.name).begins_with("stadium_light"): r.append(g)
			"fundidos": if String(g.name).begins_with("Fundid"): r.append(g)
			"mm_sin_nombre": if es_mm and String(g.name).begins_with("@MultiMesh"): r.append(g)
			"ojos_cejas": if String(g.name).begins_with("Eyes") or String(g.name).begins_with("Eyebrow"): r.append(g)
			"coches": if String(g.name) == "car" or String(g.name) == "whell": r.append(g)
	return r

func _partes() -> void:
	var m := Vector2(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if (_n - CALENTAR) % 6 != 5:
		return
	if _parte == -1:
		_base = m
		print("PARTES base tris=%d llamadas=%d" % [m.x, m.y])
	else:
		print("PARTES sin %s: -%d tris  -%d llamadas" % [GRUPOS[_parte], _base.x - m.x, _base.y - m.y])
		for g in _ocultos:
			if g is GeometryInstance3D:
				g.visible = true
			else:
				for l in _vista.find_children("*", "DirectionalLight3D", true, false):
					l.shadow_enabled = true
		_ocultos.clear()
	_parte += 1
	if _parte >= GRUPOS.size():
		get_tree().quit()
		return
	if GRUPOS[_parte] == "sombras":
		for l in _vista.find_children("*", "DirectionalLight3D", true, false):
			l.shadow_enabled = false
		_ocultos = ["luz"]
	else:
		_ocultos = _de_grupo(GRUPOS[_parte])
		for g in _ocultos:
			g.visible = false

func _arbol() -> void:
	## 16-10-2026: el partido se congela (la cámara de TV seguía al balón y la
	## base cambiaba sola: salían ahorros negativos) y cada parte se compara con
	## una base tomada JUSTO antes de apagarla.
	Engine.time_scale = 0.0
	var raiz: Node3D = _vista.get("_raiz3d")
	var m := Vector2(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_paso_a += 1
	if _paso_a % 4 != 0:
		return
	if _prev != null:
		var pista := ""
		if _prev is MeshInstance3D and (_prev as MeshInstance3D).mesh != null:
			var mm := (_prev as MeshInstance3D).mesh
			pista = "%s %s" % [mm.get_class(), str(mm.get_aabb().size.round())]
		elif _prev is MultiMeshInstance3D and (_prev as MultiMeshInstance3D).multimesh != null:
			pista = "MultiMesh x%d" % (_prev as MultiMeshInstance3D).multimesh.instance_count
		else:
			pista = "%d hijos" % _prev.get_child_count()
		print("ARBOL sin %-34s %8d tris  %5d llamadas  (%s)" % [_prev.get_path().get_concatenated_names().right(40), _base_a.x - m.x, _base_a.y - m.y, pista])
		_prev.visible = true
		_prev = null
		return
	if _cola_arbol.is_empty() and _paso_a > 4:
		if not _arbol_listo:
			_arbol_listo = true
			print("ARBOL base tris=%d llamadas=%d" % [m.x, m.y])
			for c in raiz.get_children():
				if c is Node3D:
					_cola_arbol.append(c)
			var extra: Array = []
			for c in _cola_arbol:
				if c.get_child_count() > 6:
					for g in c.get_children():
						if g is Node3D:
							extra.append(g)
			_cola_arbol.append_array(extra)
			return
		get_tree().quit()
		return
	if _cola_arbol.is_empty():
		return
	_base_a = m
	_prev = _cola_arbol.pop_front()
	_prev.visible = false

func _medida() -> Vector2:
	return Vector2(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
