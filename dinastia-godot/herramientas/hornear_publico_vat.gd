extends SceneTree
## HORNEA LA HINCHADA ANIMADA A TEXTURAS DE VÉRTICES (VAT) (26-10-2026, fila 6
## de `docs/04_auditorias/investigacion_s4/03_propuesta.md`: «hinchada y
## banquillo animados», aprobada por el dueño).
##
## Lo de antes (`hornear_publico.gd`) eran 8 poses QUIETAS. Esto hornea, para
## cada nivel de detalle (cerca/medio/lejos), UNA malla en la pose sentado y una
## textura con la posición y la normal de cada vértice en 16 fotogramas de 13
## clips de medio cuerpo (charla, aplauso, brazos cruzados, festejo, insulto…).
## `visor/hinchada.gdshader` lee la textura (dos `texelFetch` por clip) y miles
## de hinchas se mueven con el coste de UN MultiMesh por grupo, también en el
## renderizador Compatibility (móvil y Web). Técnica de referencia: el plugin VAT
## de antzGames (MIT); no se copia código, solo la idea (fila = fotograma,
## columna = vértice, filtro nearest).
##
## Los clips: Mesh2Motion (CC0, mismo esqueleto UE5) en la parte alta del cuerpo,
## sobre nuestra pose «sentado» (`BanquilloVivo.componer`). Los .glb de origen NO
## van al repositorio (13 MB, LFS no sube desde el contenedor): se bajan con
##   herramientas/bajar_mesh2motion.sh            (a ~/.cache/dinastia/mesh2motion)
##   godot --headless --path . -s res://herramientas/hornear_publico_vat.gd
## Salida: `assets/ciudad/publico/hincha_vat_<nivel>.res` (malla + textura +
## metadatos) y `assets/characters/quaternius/anims_m2m/m2m_parte_alta.res`.

## [clave, fuente, clip]  fuente: "m2m" (Mesh2Motion) o "q" (nuestros, a mano).
## El ORDEN es el índice de clip en el shader (ver `PublicoVat`).
const CLIPS := [
	["sentado", "m2m", "Sitting_Idle"], ["charla", "m2m", "Sitting_Talking"],
	["aplaude", "q", "aplaudir"], ["escucha", "m2m", "Idle Listening"],
	["asiente", "m2m", "Head Nod"], ["cruzados", "m2m", "Idle_FoldArms"],
	["manos_cabeza", "q", "manos_cabeza"], ["festeja_dos", "m2m", "Cheering_Two_Hands"],
	["festeja_puno", "m2m", "Victory Fist Pump"], ["festeja_brazo", "m2m", "Cheer_One_arm"],
	["insulta", "m2m", "Insult"], ["enfado", "m2m", "Angry"], ["rechazo", "m2m", "Reject"],
]
const ARCHIVOS := ["human-base-animations.glb", "human-addon-animations.glb", "human-mocap-animations.glb"]
const FOTOGRAMAS := 16
const OBJETIVOS := {"cerca": 450, "medio": 160, "lejos": 70}
const SALIDA := "res://assets/ciudad/publico/"
const SALIDA_ANIM := "res://assets/characters/quaternius/anims_m2m/"
const ESCALA := 0.96

var _esq: Skeleton3D
var _cuerpo: MeshInstance3D
var _ap: AnimationPlayer

func _init() -> void:
	var dir_m2m := OS.get_environment("M2M_DIR")
	if dir_m2m == "":
		dir_m2m = OS.get_environment("HOME") + "/.cache/dinastia/mesh2motion"
	var d := FutbolistaQ.crear(1.78, "male")
	var raiz: Node3D = d["nodo"]
	root.add_child(raiz)
	FutbolistaQ.terminar(d, true)
	_ap = d["anim"]
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		if mi.name == "SuperHero_Male":
			_cuerpo = mi
	_esq = _cuerpo.get_parent() as Skeleton3D if _cuerpo != null else null
	if _esq == null:
		push_error("no hay cuerpo con esqueleto")
		quit(1)
		return
	await process_frame
	var alta := _parte_alta(dir_m2m)
	if alta.get_animation_list().size() < CLIPS.size():
		push_error("faltan clips (¿corriste herramientas/bajar_mesh2motion.sh?): %s" % [alta.get_animation_list()])
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(SALIDA_ANIM)
	ResourceSaver.save(alta, SALIDA_ANIM + "m2m_parte_alta.res", ResourceSaver.FLAG_COMPRESS)
	## Los clips compuestos, en la librería del reproductor de horneado.
	var sentado := _ap.get_animation("sentado")
	var pre := BanquilloVivo.prefijo_de(sentado)
	var lib := _ap.get_animation_library("")
	var duraciones: Array[float] = []
	for c: Array in CLIPS:
		var comp := BanquilloVivo.componer(sentado, alta.get_animation(String(c[0])), pre)
		lib.add_animation("vat_" + String(c[0]), comp)
		duraciones.append(comp.length)
	## Pose base: el primer clip a mitad (de ella salen la malla y el recorte).
	var base := _posar("vat_sentado", 0.5)
	var pelvis_y := _esq.get_bone_global_pose(_esq.find_bone("pelvis")).origin.y
	var cabeza_y := _esq.get_bone_global_pose(_esq.find_bone("Head")).origin.y
	## Todos los fotogramas, una sola vez (los niveles comparten el horneado).
	var cuadros: Array = []
	for c: Array in CLIPS:
		for f in FOTOGRAMAS:
			cuadros.append(_posar("vat_" + String(c[0]), float(f) / float(FOTOGRAMAS)))
	for nivel: String in OBJETIVOS:
		var malla := _hornear_nivel(base, cuadros, int(OBJETIVOS[nivel]), pelvis_y, cabeza_y)
		malla.set_meta("vat_clips", CLIPS.map(func(c: Array) -> String: return String(c[0])))
		malla.set_meta("vat_duraciones", duraciones)
		malla.set_meta("vat_fotogramas", FOTOGRAMAS)
		var ruta := "%shincha_vat_%s.res" % [SALIDA, nivel]
		ResourceSaver.save(malla, ruta, ResourceSaver.FLAG_COMPRESS)
		print("%-6s %4d vértices, textura %dx%d, %d bytes en disco" % [nivel, malla.get_meta("vat_vertices"),
			(malla.get_meta("vat_tex") as Texture2D).get_width(), (malla.get_meta("vat_tex") as Texture2D).get_height(),
			FileAccess.get_file_as_bytes(ruta).size()])
	print("HORNEADO VAT ", CLIPS.size(), " clips x ", FOTOGRAMAS, " fotogramas")
	quit()

## La parte alta de cada clip, con pistas "@:hueso" (el prefijo lo pone quien la usa).
func _parte_alta(dir_m2m: String) -> AnimationLibrary:
	var fuentes := {}
	var esq_m2m: Skeleton3D = null
	for f: String in ARCHIVOS:
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(dir_m2m + "/" + f, st) != OK:
			push_warning("no se pudo leer " + f)
			continue
		var escena := doc.generate_scene(st)
		root.add_child(escena)
		for n in escena.find_children("*", "AnimationPlayer", true, false):
			var ap := n as AnimationPlayer
			for nombre in ap.get_animation_list():
				fuentes[nombre] = ap.get_animation(nombre)
		if esq_m2m == null:
			esq_m2m = escena.find_children("*", "Skeleton3D", true, false)[0]
	var alta := AnimationLibrary.new()
	for c: Array in CLIPS:
		var a: Animation = null
		if String(c[1]) == "q":
			a = _ap.get_animation(String(c[2])) if _ap.has_animation(String(c[2])) else null
			if a != null:
				a = _con_prefijo(a, "@")
		elif fuentes.has(c[2]) and esq_m2m != null:
			a = _retargetear(fuentes[c[2]], esq_m2m)
		if a != null:
			alta.add_animation(String(c[0]), a)
	return alta

func _con_prefijo(o: Animation, pre: String) -> Animation:
	var a: Animation = o.duplicate(true)
	for i in a.get_track_count():
		var r := str(a.track_get_path(i))
		a.track_set_path(i, NodePath(pre + ":" + r.substr(r.rfind(":") + 1)))
	return a

## Solo rotaciones de la parte alta, por nombre de hueso (sin mayúsculas: el
## nuestro es "Head", el de Mesh2Motion "head"). Corrige el reposo por si los
## dos esqueletos no lo tienen idéntico: q = reposo_nuestro · reposo_origen⁻¹ · q_origen.
func _retargetear(o: Animation, esq_o: Skeleton3D) -> Animation:
	var nuestros := {}
	for i in _esq.get_bone_count():
		nuestros[_esq.get_bone_name(i).to_lower()] = i
	var a := Animation.new()
	a.length = o.length
	a.loop_mode = Animation.LOOP_LINEAR
	for i in o.get_track_count():
		if o.track_get_type(i) != Animation.TYPE_ROTATION_3D:
			continue
		var r := str(o.track_get_path(i))
		var h := r.substr(r.rfind(":") + 1)
		if not nuestros.has(h.to_lower()) or h.to_lower() in BanquilloVivo.ABAJO:
			continue
		var bi: int = nuestros[h.to_lower()]
		var bo := esq_o.find_bone(h)
		var corr := Quaternion.IDENTITY
		if bo >= 0:
			corr = _esq.get_bone_rest(bi).basis.get_rotation_quaternion() * esq_o.get_bone_rest(bo).basis.get_rotation_quaternion().inverse()
		var t := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(t, NodePath("@:" + _esq.get_bone_name(bi)))
		for k in o.track_get_key_count(i):
			a.rotation_track_insert_key(t, o.track_get_key_time(i, k), (corr * (o.track_get_key_value(i, k) as Quaternion)).normalized())
	return a

## Pone el esqueleto en `clip` a la fracción `t` y devuelve [posiciones, normales] con la piel aplicada.
func _posar(clip: String, t: float) -> Array:
	_ap.play(clip)
	_ap.seek(t * _ap.current_animation_length, true)
	_esq.force_update_all_bone_transforms()
	return _vestir()

## Piel por CPU (igual que `hornear_publico.gd`).
func _vestir() -> Array:
	var arr: Array = _cuerpo.mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var hs = arr[Mesh.ARRAY_BONES]
	var ws = arr[Mesh.ARRAY_WEIGHTS]
	var piel: Skin = _cuerpo.skin
	var mats: Array[Transform3D] = []
	for i in piel.get_bind_count():
		var hueso := piel.get_bind_bone(i)
		if hueso < 0:
			hueso = _esq.find_bone(piel.get_bind_name(i))
		mats.append(_esq.get_bone_global_pose(hueso) * piel.get_bind_pose(i))
	var por: int = hs.size() / vs.size()
	var po := PackedVector3Array()
	var no := PackedVector3Array()
	po.resize(vs.size())
	no.resize(vs.size())
	for v in vs.size():
		var p := Vector3.ZERO
		var nn := Vector3.ZERO
		for k in por:
			var w: float = ws[v * por + k]
			if w <= 0.0:
				continue
			var m: Transform3D = mats[int(hs[v * por + k])]
			p += (m * vs[v]) * w
			nn += (m.basis * ns[v]) * w
		po[v] = p
		no[v] = nn.normalized()
	return [po, no, arr[Mesh.ARRAY_INDEX]]

## Recorte en la cadera y simplificación sobre la pose base (como el horneado
## de poses), guardando QUÉ vértice original es cada uno: así cada fotograma
## se lee del mismo vértice.
func _hornear_nivel(base: Array, cuadros: Array, objetivo: int, pelvis_y: float, cabeza_y: float) -> ArrayMesh:
	var vs: PackedVector3Array = base[0]
	var idx: PackedInt32Array = base[2]
	var corte := pelvis_y - 0.02
	var tris := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		if vs[idx[t]].y >= corte - 0.1 and vs[idx[t + 1]].y >= corte - 0.1 and vs[idx[t + 2]].y >= corte - 0.1:
			tris.append(idx[t])
			tris.append(idx[t + 1])
			tris.append(idx[t + 2])
	var usados := {}
	for i in tris:
		usados[i] = true
	var cx := 0.0
	var cz := 0.0
	for i in usados:
		cx += vs[i].x
		cz += vs[i].z
	cx /= float(usados.size())
	cz /= float(usados.size())
	## Simplificación con la malla completa (índices originales).
	var im := ImporterMesh.new()
	var a2 := []
	a2.resize(Mesh.ARRAY_MAX)
	a2[Mesh.ARRAY_VERTEX] = vs
	a2[Mesh.ARRAY_NORMAL] = base[1]
	a2[Mesh.ARRAY_INDEX] = tris
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, a2, [], {}, null, "cuerpo")
	im.generate_lods(25.0, 60.0, [])
	var mejor: PackedInt32Array = tris
	var mejor_dif := 1 << 30
	var candidatos: Array = [tris]
	for l in im.get_surface_lod_count(0):
		candidatos.append(im.get_surface_lod_indices(0, l))
	for c: PackedInt32Array in candidatos:
		var u := {}
		for i in c:
			u[i] = true
		if absi(u.size() - objetivo) < mejor_dif:
			mejor_dif = absi(u.size() - objetivo)
			mejor = c
	var orig := PackedInt32Array()
	var mapa := {}
	var ind := PackedInt32Array()
	for i in mejor:
		if not mapa.has(i):
			mapa[i] = orig.size()
			orig.append(i)
		ind.append(mapa[i])
	var w := orig.size()
	var conv := func(p: Vector3) -> Vector3:
		return Vector3((p.x - cx) * ESCALA, (maxf(p.y, corte) - pelvis_y) * ESCALA + 0.12, (p.z - cz) * ESCALA)
	## Posiciones de todos los fotogramas y su caja (para cuantizar a 8 bits).
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := -lo
	var todas: Array = []
	for cu: Array in cuadros:
		var ps := PackedVector3Array()
		for k in w:
			var p: Vector3 = conv.call((cu[0] as PackedVector3Array)[orig[k]])
			ps.append(p)
			lo = lo.min(p)
			hi = hi.max(p)
		todas.append(ps)
	lo -= Vector3.ONE * 0.01
	hi += Vector3.ONE * 0.01
	var filas := cuadros.size()
	## Arriba las posiciones (filas 0..F-1), abajo las normales (F..2F-1).
	var img := Image.create_empty(w, filas * 2, false, Image.FORMAT_RGBA8)
	for f in filas:
		var ns: PackedVector3Array = cuadros[f][1]
		for k in w:
			var q: Vector3 = ((todas[f] as PackedVector3Array)[k] - lo) / (hi - lo)
			img.set_pixel(k, f, Color(q.x, q.y, q.z, 1.0))
			var n: Vector3 = Vector3.DOWN if vs[orig[k]].y < corte else ns[orig[k]]
			n = n * 0.5 + Vector3.ONE * 0.5
			img.set_pixel(k, filas + f, Color(n.x, n.y, n.z, 1.0))
	## La malla: la pose base, y en UV.x qué columna de la textura es cada vértice.
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	var uv := PackedVector2Array()
	var nb: PackedVector3Array = base[1]
	for k in w:
		pos.append(conv.call(vs[orig[k]]))
		nor.append(Vector3.DOWN if vs[orig[k]].y < corte else nb[orig[k]])
		uv.append(Vector2((float(k) + 0.5) / float(w), 0.0))
	var a3 := []
	a3.resize(Mesh.ARRAY_MAX)
	a3[Mesh.ARRAY_VERTEX] = pos
	a3[Mesh.ARRAY_NORMAL] = nor
	a3[Mesh.ARRAY_TEX_UV] = uv
	a3[Mesh.ARRAY_INDEX] = ind
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a3)
	## Los brazos en alto del festejo salen de la caja de la pose quieta.
	mesh.custom_aabb = AABB(lo, hi - lo)
	var y_cabeza := (cabeza_y - pelvis_y) * ESCALA + 0.12
	var maxy := -1e9
	for p in pos:
		maxy = maxf(maxy, p.y)
	mesh.set_meta("cuello_desde", y_cabeza - 0.04)
	mesh.set_meta("cuello_hasta", y_cabeza + 0.03)
	mesh.set_meta("pelo_desde", y_cabeza + 0.115)
	mesh.set_meta("alto", maxy)
	mesh.set_meta("vat_tex", ImageTexture.create_from_image(img))
	mesh.set_meta("vat_min", lo)
	mesh.set_meta("vat_max", hi)
	mesh.set_meta("vat_vertices", w)
	return mesh
