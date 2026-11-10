extends Node
## LO QUE PIDE EL CLUB A PIE A LA GRÁFICA (10-11-2026, rendimiento en móvil): abre el estadio propio, entra en el recorrido a pie (`ExploradorEstadio`, el edificio del club con sus plantas) y mide
## llamadas de dibujo, triángulos, objetos y fotograma en el punto de salida y en el centro de varias salas de cada planta. Como `medir_partido`: llamadas/triángulos/memoria no dependen de la máquina;
## el fotograma de llvmpipe sirve para comparar a igual resolución.
##   PAIS=ESP CLUB=5 HW_DRIVER=opengl3 herramientas/hw_modesto.sh res://pruebas/medir_club.tscn -- baja   (niveles: ultrabaja baja mediabaja medio ...; SIN_MSAA=1, SIN_OMNI=1)
const CALENTAR := 25
const MUESTRAS := 30
var _vista: VistaEstadio
var _ex: ExploradorEstadio
var _n := 0
var _puntos: Array = []   ## [nombre, Vector3, planta]
var _i := -1
var _desde := 0
var _llam: Array[float] = []
var _tris: Array[float] = []
var _obj: Array[float] = []
var _ms: Array[float] = []
var _res: Array[String] = []
var _todas: Array[Vector4] = []

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ULTRA_BAJA)
	Calidad.sin_msaa = OS.get_environment("SIN_MSAA") != ""
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	var m := Mundo.new()
	m.generar([pais], 77)
	var club: Club = m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()]
	PersonajeDT.club_usuario = club.id
	var perfil := EstadioPropio.new().perfil(club)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, perfil)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
		_ex = _vista._explorador
		if OS.get_environment("SIN_OCULTAR") != "":
			_ex.set_physics_process(false)   ## SIN_OCULTAR=1: sin `OcultarEstadioDentro` (la ocultación se hace en el _physics_process del explorador): el estado de ANTES del cambio
	if _n < 30 or _ex == null:
		return
	if _i == -1:
		_armar_puntos()
		_i = 0
		_ir(0)
		return
	if OS.get_environment("SIN_OMNI") != "" and _n % 10 == 0:
		for l in _vista.find_children("*", "OmniLight3D", true, false):
			(l as Light3D).visible = false
	if _n - _desde < CALENTAR:
		return
	_llam.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_tris.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_obj.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	if _llam.size() < MUESTRAS:
		return
	if _i == 0 and OS.get_environment("DETALLE") != "":
		for fila: Dictionary in Optimizar.informe(_vista, 22):
			print("DETALLE tris=%d piezas=%d corte=%.0f  %s" % [fila["tris"], fila["piezas"], fila["corte"], fila["clave"]])
	if OS.get_environment("FOTO_DIR") != "":
		get_viewport().get_texture().get_image().save_jpg("%s/club_%02d_%s.jpg" % [OS.get_environment("FOTO_DIR"), _i, String(_puntos[_i][0]).replace(" ", "_")], 0.85)
	var f := Vector4(_media(_llam), _media(_tris), _media(_obj), _media(_ms))
	_todas.append(f)
	print("CLUB punto «%s» (planta %d): llamadas=%.0f triangulos=%.0f objetos=%.0f fotograma=%.1f ms" % [_puntos[_i][0], _puntos[_i][2], f.x, f.y, f.z, f.w])
	_i += 1
	if _i >= _puntos.size():
		var s := Vector4.ZERO
		var peor := Vector4.ZERO
		for t in _todas:
			s += t
			peor = Vector4(maxf(peor.x, t.x), maxf(peor.y, t.y), maxf(peor.z, t.z), maxf(peor.w, t.w))
		s /= float(_todas.size())
		print("MEDICION_CLUB calidad=%d puntos=%d  MEDIA llamadas=%.0f triangulos=%.0f objetos=%.0f fotograma=%.1f ms | PEOR llamadas=%.0f triangulos=%.0f fotograma=%.1f ms | vram=%.0f MB" % [
			Calidad.elegida, _todas.size(), s.x, s.y, s.z, s.w, peor.x, peor.y, peor.w, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
		get_tree().quit()
		return
	_ir(_i)

func _ir(k: int) -> void:
	_llam.clear(); _tris.clear(); _obj.clear(); _ms.clear()
	var p: Array = _puntos[k]
	_ex.planta = int(p[2])
	_ex.cuerpo.position = p[1]
	_ex.vel = 0.0
	if OS.get_environment("RUMBO") != "":
		_ex.rumbo = float(OS.get_environment("RUMBO"))   ## RUMBO=0: mirando a +Z (de espaldas a la boca del túnel); sin él, el de siempre (hacia la boca)
	_desde = _n
	if OS.get_environment("TOP") != "" and _i == (int(OS.get_environment("TOP_I")) if OS.get_environment("TOP_I") != "" else 9):
		## TOP=1: en el punto 9 (sala de prensa), triángulos y piezas visibles agrupados por el hijo de primer nivel del estadio del que cuelgan.
		var raiz: Node = _vista.get("_raiz3d")
		var acum := {}
		for g in raiz.find_children("*", "MeshInstance3D", true, false) + raiz.find_children("*", "MultiMeshInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if not gi.is_visible_in_tree():
				continue
			var x: Node = g
			while x.get_parent() != raiz and x.get_parent() != null:
				x = x.get_parent()
			var clave := "%s [%s]" % [String(x.name).left(28), x.get_class()]
			if not acum.has(clave):
				acum[clave] = Vector2.ZERO
			var t := 0
			if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
				t = Optimizar._tris((g as MeshInstance3D).mesh)
			elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null and (g as MultiMeshInstance3D).multimesh.mesh != null:
				t = Optimizar._tris((g as MultiMeshInstance3D).multimesh.mesh) * (g as MultiMeshInstance3D).multimesh.visible_instance_count if (g as MultiMeshInstance3D).multimesh.visible_instance_count >= 0 else Optimizar._tris((g as MultiMeshInstance3D).multimesh.mesh) * (g as MultiMeshInstance3D).multimesh.instance_count
			acum[clave] += Vector2(t, 1)
		var ks := acum.keys()
		ks.sort_custom(func(a, b): return acum[a].x > acum[b].x)
		for kk in ks:
			print("TOP %-40s tris=%8d piezas=%4d" % [kk, int(acum[kk].x), int(acum[kk].y)])
	if OS.get_environment("OCULTAR_ESTADIO") != "":
		## OCULTAR_ESTADIO=1: estimación de cuánto se ahorraría si dentro del edificio (plantas distintas de 0) no se dibujara el estadio de fuera: se ocultan los hijos de primer nivel del estadio
		## que no son luces, entorno, el edificio (TunelVestuario), la calle (Exterior), la fachada ni el explorador (OCULTAR_ESTADIO=2 oculta también EntornoEstadio).
		var dentro: bool = int(p[2]) != 0
		var guardar := ["TunelVestuario", "Exterior", "Fachada"] + ([] if OS.get_environment("OCULTAR_ESTADIO") == "2" else ["EntornoEstadio"])
		var n_oc := 0
		var raiz: Node = _vista.get("_raiz3d")
		for h in raiz.get_children():
			if not (h is Node3D) or h is Light3D or h == _ex or String(h.name) in guardar or h is Camera3D:
				continue
			(h as Node3D).visible = not dentro
			n_oc += 1 if dentro else 0
		print("OCULTAR_ESTADIO: planta %d, %d nodos de primer nivel ocultos" % [int(p[2]), n_oc])
	if OS.get_environment("SOLO_PLANTA") != "":
		## SOLO_PLANTA=1: estimación de cuánto se ahorraría si solo se dibujara la planta del edificio en la que estás (los hijos de EdificioClub se clasifican por su altura).
		var ocultos := 0
		for ed in _vista.find_children("EdificioClub*", "Node3D", true, false):
			for h in ed.get_children():
				if h is Node3D and not h is Light3D:
					var pl := floori(((h as Node3D).position.y + 0.3) / EdificioClub.ALTO_PLANTA)
					(h as Node3D).visible = pl == int(p[2])
					if pl != int(p[2]):
						ocultos += 1
		print("SOLO_PLANTA: planta %d, %d hijos ocultos" % [int(p[2]), ocultos])

## Salida de la planta 0 + el centro de hasta 3 salas grandes de cada planta (sin pasillos, bandas ni ascensores).
func _armar_puntos() -> void:
	_puntos.append(["salida", _ex._datos["inicio"], 0])
	var por_planta := {}
	for z: Dictionary in _ex.zonas:
		var nom := String(z["nombre"])
		var r: Rect2 = z["r"]
		if nom in ["Ascensor", "Pasillo", "Banda"] or minf(r.size.x, r.size.y) < 3.0:
			continue
		var pl := int(z.get("planta", 0))
		if not por_planta.has(pl):
			por_planta[pl] = []
		if (por_planta[pl] as Array).size() < 3:
			(por_planta[pl] as Array).append(nom)
			_puntos.append([nom, Vector3(r.get_center().x, RecorridoClub.y_de(pl), r.get_center().y), pl])

func _media(a: Array[float]) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(1.0, float(a.size()))
