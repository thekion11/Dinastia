extends SceneTree
## LEAGUE-SOCCER → NUESTRO ESQUELETO (01-11-2026, misión del dueño: «agarrar todo» de github.com/awest813/League-Soccer, Apache 2.0).
## Convierte las 296 animaciones `.anim` (respaldo en `terceros/league_soccer/animaciones/`) a una AnimationLibrary .res para el
## esqueleto de Quaternius, a 30 fps. Cada clip va también ESPEJADO («…_espejo»): el motor de origen hace un solo paso y espeja el otro.
##   godot --headless --path . --script res://herramientas/league_anim_a_res.gd
## Retarget por DIRECCIÓN: en el origen el reposo es la extremidad recta y colgando (Z arriba, mira a −Y, izquierda +X); el nuestro es
## la T (Y arriba, mira a +Z, izquierda +X). Para cada articulación, A = el giro que lleva su dirección de reposo de origen a la de
## nuestro hueso; el hueso queda en  G_origen · A⁻¹ · reposo_nuestro  (G_origen = rotación global de la articulación en ese cuadro).
## Columna y cuello se reparten entre los huesos intermedios. El desplazamiento del jugador se descarta (lo mueve el motor), salvo
## la altura, que va a la pelvis.
const ORIGEN := "res://terceros/league_soccer/animaciones/"
const SALIDA := "res://assets/characters/quaternius/anims_league/league.res"
const FPS := 30.0
const PADRE := {"body": "", "middle": "body", "neck": "middle", "left_shoulder": "middle", "left_elbow": "left_shoulder",
	"right_shoulder": "middle", "right_elbow": "right_shoulder", "left_thigh": "body", "left_knee": "left_thigh",
	"left_ankle": "left_knee", "right_thigh": "body", "right_knee": "right_thigh", "right_ankle": "right_knee"}
## Articulación de origen → nuestro hueso, y hacia dónde apunta en reposo en el origen (ya en ejes de Godot).
const MAPA := {"body": ["pelvis", Vector3.UP], "middle": ["spine_03", Vector3.UP], "neck": ["Head", Vector3.UP],
	"left_shoulder": ["upperarm_l", Vector3.DOWN], "left_elbow": ["lowerarm_l", Vector3.DOWN],
	"right_shoulder": ["upperarm_r", Vector3.DOWN], "right_elbow": ["lowerarm_r", Vector3.DOWN],
	"left_thigh": ["thigh_l", Vector3.DOWN], "left_knee": ["calf_l", Vector3.DOWN], "left_ankle": ["foot_l", Vector3.BACK],
	"right_thigh": ["thigh_r", Vector3.DOWN], "right_knee": ["calf_r", Vector3.DOWN], "right_ankle": ["foot_r", Vector3.BACK]}
## Hacia qué hueso hijo mide la dirección de reposo nuestra.
const HIJO := {"pelvis": "spine_01", "spine_03": "neck_01", "Head": "", "upperarm_l": "lowerarm_l", "lowerarm_l": "hand_l",
	"upperarm_r": "lowerarm_r", "lowerarm_r": "hand_r", "thigh_l": "calf_l", "calf_l": "foot_l", "foot_l": "ball_l",
	"thigh_r": "calf_r", "calf_r": "foot_r", "foot_r": "ball_r"}
## Huesos intermedios: [hueso, articulación A, articulación B, mezcla] (giro = slerp de los dos deltas).
const MEZCLA := [["spine_01", "body", "middle", 0.33], ["spine_02", "body", "middle", 0.66], ["neck_01", "middle", "neck", 0.5]]
const PRE := "Armature/Skeleton3D:"
const ALTURA_ORIGEN := 0.96

var esq: Skeleton3D
var reposo_g := {}    ## hueso -> Transform3D global de reposo
var alinear := {}     ## articulación -> Quaternion A

func _init() -> void:
	var d := FutbolistaQ.crear(1.8, "male")
	esq = d["esqueleto"]
	for i in esq.get_bone_count():
		reposo_g[esq.get_bone_name(i)] = esq.get_bone_global_rest(i)
	for art: String in MAPA:
		var hueso: String = MAPA[art][0]
		var nuestro := Vector3.UP
		if String(HIJO.get(hueso, "")) != "":
			nuestro = ((reposo_g[HIJO[hueso]] as Transform3D).origin - (reposo_g[hueso] as Transform3D).origin).normalized()
		alinear[art] = Quaternion(MAPA[art][1] as Vector3, nuestro)
	var lib := AnimationLibrary.new()
	var n := 0
	for ruta: String in _anims(ORIGEN):
		var datos := _leer(ruta)
		if datos.is_empty():
			continue
		var nombre := "ls_" + ruta.trim_prefix(ORIGEN).trim_suffix(".anim").replace("/", "__")
		lib.add_animation(nombre, _convertir(datos))
		lib.add_animation(nombre + "_espejo", _convertir(_espejar(datos)))
		n += 1
	DirAccess.make_dir_recursive_absolute(SALIDA.get_base_dir())
	print("convertidas: ", n, " (+ espejos)  guardar: ", ResourceSaver.save(lib, SALIDA, ResourceSaver.FLAG_COMPRESS))
	(d["nodo"] as Node).free()
	quit(0)

func _anims(dir: String) -> Array:
	var r: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".anim"):
			r.append(dir + f)
	for s in DirAccess.get_directories_at(dir):
		r.append_array(_anims(dir + s + "/"))
	r.sort()
	return r

## {articulación: [[cuadro, valor], …]} (valor: Vector3 para «player», Quaternion en ejes de Godot para el resto).
func _leer(ruta: String) -> Dictionary:
	var r := {}
	for linea in FileAccess.get_file_as_string(ruta).split("\n"):
		if linea.begins_with("<") or linea.strip_edges() == "" or not linea.contains(","):
			continue
		var p := linea.split(",")
		var art := p[0].strip_edges()
		var paso := 4 if art == "player" else 5
		var claves: Array = []
		var k := 1
		while k + paso - 1 < p.size():
			var f := float(p[k])
			if art == "player":
				claves.append([f, Vector3(float(p[k + 1]), float(p[k + 3]), -float(p[k + 2]))])
			else:
				claves.append([f, Quaternion(float(p[k + 1]), float(p[k + 3]), -float(p[k + 2]), float(p[k + 4])).normalized()])
			k += paso
		r[art] = claves
	return r

## Izquierda ↔ derecha y reflejo en el plano sagital (x → −x): el cuaternión (x, y, z, w) pasa a (x, −y, −z, w).
func _espejar(datos: Dictionary) -> Dictionary:
	var r := {}
	for art: String in datos:
		var otro := art.replace("left_", "TMP_").replace("right_", "left_").replace("TMP_", "right_")
		var claves: Array = []
		for c: Array in datos[art]:
			var v: Variant = c[1]
			if v is Vector3:
				claves.append([c[0], Vector3(-(v as Vector3).x, (v as Vector3).y, (v as Vector3).z)])
			else:
				var q := v as Quaternion
				claves.append([c[0], Quaternion(q.x, -q.y, -q.z, q.w)])
		r[otro] = claves
	return r

func _muestra(claves: Array, cuadro: float) -> Variant:
	if claves.is_empty():
		return null
	if cuadro <= float(claves[0][0]):
		return claves[0][1]
	for i in range(1, claves.size()):
		if cuadro <= float(claves[i][0]):
			var a: Array = claves[i - 1]
			var b: Array = claves[i]
			var f := (cuadro - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
			if a[1] is Vector3:
				return (a[1] as Vector3).lerp(b[1], f)
			return (a[1] as Quaternion).slerp(b[1], f)
	return claves[-1][1]

func _convertir(datos: Dictionary) -> Animation:
	var ultimo := 0.0
	for art: String in datos:
		for c: Array in datos[art]:
			ultimo = maxf(ultimo, float(c[0]))
	var largo := ultimo / 100.0
	var a := Animation.new()
	a.length = maxf(largo, 1.0 / FPS)
	var pistas := {}
	for h: String in ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head", "upperarm_l", "lowerarm_l", "upperarm_r",
			"lowerarm_r", "thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r"]:
		var i := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(i, NodePath(PRE + h))
		pistas[h] = i
	var pp := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(pp, NodePath(PRE + "pelvis"))
	var cuadros := maxi(2, ceili(largo * FPS) + 1)
	for k in cuadros:
		var t := minf(float(k) / FPS, largo)
		var cuadro := t * 100.0
		## Rotación global de cada articulación de origen y su delta respecto a nuestro reposo.
		var g := {}
		var delta := {}
		for art: String in PADRE:
			var q: Variant = _muestra(datos.get(art, []), cuadro)
			var local := q as Quaternion if q != null else Quaternion.IDENTITY
			var padre: String = PADRE[art]
			g[art] = ((g[padre] as Quaternion) * local) if padre != "" else local
			delta[art] = (g[art] as Quaternion) * (alinear[art] as Quaternion).inverse()
		var objetivo := {}   ## hueso -> Basis global deseada
		for art: String in MAPA:
			objetivo[MAPA[art][0]] = Basis(delta[art] as Quaternion) * (reposo_g[MAPA[art][0]] as Transform3D).basis
		for m: Array in MEZCLA:
			var dq := (delta[m[1]] as Quaternion).slerp(delta[m[2]], float(m[3]))
			objetivo[m[0]] = Basis(dq) * (reposo_g[m[0]] as Transform3D).basis
		## Locales: de la raíz hacia abajo (los no mapeados siguen a su padre con su giro de reposo).
		var actual := {}
		for i in esq.get_bone_count():
			var nombre := esq.get_bone_name(i)
			var pi := esq.get_bone_parent(i)
			var bp: Basis = actual[esq.get_bone_name(pi)] if pi >= 0 else Basis.IDENTITY
			var bg: Basis = objetivo[nombre] if objetivo.has(nombre) else bp * esq.get_bone_rest(i).basis
			actual[nombre] = bg
			if pistas.has(nombre):
				a.rotation_track_insert_key(pistas[nombre], t, (bp.inverse() * bg).get_rotation_quaternion())
		var jp: Variant = _muestra(datos.get("player", []), cuadro)
		var alto := (jp as Vector3).y if jp != null else 0.0
		## La pelvis vive en el espacio de `root`, que viene GIRADO (allí la altura es Z): el «arriba» del esqueleto se pasa a ese
		## espacio (antes se sumaba a su Y y el cuerpo que caía se desplazaba en horizontal en vez de bajar: tropiezo flotando).
		var ip := esq.find_bone("pelvis")
		var reposo_p := esq.get_bone_rest(ip).origin
		var g_raiz: Basis = (reposo_g[esq.get_bone_name(esq.get_bone_parent(ip))] as Transform3D).basis
		var altura_pelvis := (reposo_g["pelvis"] as Transform3D).origin.y
		a.position_track_insert_key(pp, t, reposo_p + g_raiz.inverse() * Vector3(0, alto * (altura_pelvis / ALTURA_ORIGEN), 0))
	return a
