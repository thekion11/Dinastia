extends SceneTree
## CLIPS DE MIXAMO LISTOS PARA EL PARTIDO (19-11-2026). De la biblioteca grande (`anims_mixamo/mixamo.res`, 55 clips, ~4 MB) saca los
## que usa el partido, RECORTADOS para que el momento del golpe caiga donde lo espera la capa visual (`LeagueAcciones.PICO`: la
## cabeza arriba a los 0,3 s del arranque del clip, como los cabezazos de League), con su ESPEJO ya horneado. Sale una biblioteca
## pequeña (`mixamo_partido.res`) que se abre en pleno partido sin tirón.
##   godot --headless --path . --script res://herramientas/mixamo_partido.gd
## Medido (19-11, FK propia sobre nuestro esqueleto, `docs/04_auditorias/cobertura_mixamo_vs_libres_2026-11-18.md`): «soccer_header»
## agacha la cadera a 0,75 m a los 0,8 s, despega, la cabeza llega arriba (+0,33 m) a 1,13 s y aterriza hacia 1,5 s.
## Los «header_soccerball» de Mixamo son dominadas de cabeza (la cabeza no sube ni 3 cm): no sirven de remate y no se usan aquí.
const ENTRADA := "res://assets/characters/quaternius/anims_mixamo/mixamo.res"
const SALIDA := "res://assets/characters/quaternius/anims_mixamo/mixamo_partido.res"
## clave de salida -> [clip de origen, desde (s), hasta (s)]
const RECORTES := {"mx_cabezazo": ["soccer_header", 0.83, 1.80]}

func _initialize() -> void:
	var origen := load(ENTRADA) as AnimationLibrary
	if origen == null:
		printerr("MIXAMO_PARTIDO: no está ", ENTRADA)
		quit(1)
		return
	var molde := FutbolistaQ.crear(FutbolistaQ.ALTURA_BASE)
	root.add_child(molde["nodo"])
	var esq: Skeleton3D = molde["esqueleto"]
	var lib := AnimationLibrary.new()
	for clave: String in RECORTES:
		var r: Array = RECORTES[clave]
		if not origen.has_animation(String(r[0])):
			printerr("MIXAMO_PARTIDO: falta el clip ", r[0])
			continue
		var a := recortar(origen.get_animation(String(r[0])), float(r[1]), float(r[2]))
		lib.add_animation(clave, a)
		var e: Animation = AnimExtra.espejar(a, esq, "", clave)
		if e != null:
			e.loop_mode = Animation.LOOP_NONE
			lib.add_animation(clave + "_espejo", e)
		print("MIXAMO_PARTIDO %s: %.2f s (de %s, %.2f-%.2f s)%s" % [clave, a.length, r[0], r[1], r[2], " + espejo" if e != null else ""])
	var err := ResourceSaver.save(lib, SALIDA, ResourceSaver.FLAG_COMPRESS)
	print("MIXAMO_PARTIDO: %d clips en %s (%s)" % [lib.get_animation_list().size(), SALIDA, error_string(err)])
	quit(0 if err == OK else 1)

## Una copia de `a` entre `desde` y `hasta` (s), con el tiempo empezando en 0. Se muestrea a 30 fps (como el horneado).
static func recortar(a: Animation, desde: float, hasta: float) -> Animation:
	var r := Animation.new()
	r.length = minf(hasta, a.length) - desde
	r.loop_mode = Animation.LOOP_NONE
	for i in a.get_track_count():
		var tipo := a.track_get_type(i)
		if tipo != Animation.TYPE_ROTATION_3D and tipo != Animation.TYPE_POSITION_3D:
			continue
		var n := r.add_track(tipo)
		r.track_set_path(n, a.track_get_path(i))
		var t := 0.0
		while t <= r.length + 0.0001:
			if tipo == Animation.TYPE_ROTATION_3D:
				r.rotation_track_insert_key(n, t, a.rotation_track_interpolate(i, desde + t))
			else:
				r.position_track_insert_key(n, t, a.position_track_interpolate(i, desde + t))
			t += 1.0 / 30.0
	return r
