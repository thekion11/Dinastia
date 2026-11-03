extends BaseIdea
## FOTO DE EQUIPO SIN BRAZOS QUE ATRAVIESEN (3-11, prioridad del dueño): coloca al once como lo hace `CeremoniaFoto` y mide, con los huesos de la pose real,
## cuántas manos/antebrazos quedan dentro del TRONCO de un compañero (a menos de `RADIO_TRONCO` del eje pelvis–cuello) y cuántas dentro del propio. Con FOTO_DETALLE=1 lista lo peor.

const RADIO_TRONCO := 0.17     ## m: lo que se cuenta como «dentro del cuerpo» (el torso mide ~0,2-0,25 m de medio ancho en el pecho)
const HUESOS_BRAZO := ["lowerarm_l", "lowerarm_r", "hand_l", "hand_r"]

func _dist_segmento(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return (p - (a + ab * t)).length()

func _ready() -> void:
	await get_tree().process_frame
	_titulo("FOTO DE EQUIPO: BRAZOS")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var l := Puente3D.once(a.once())
	var club_b: Club = m.ligas[0].clubes[1]
	var v := Puente3D.once(club_b.once())
	var lista := sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a))
	var rivales := sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(club_b.tactica.formacion), false, Puente3D.kit(club_b), Puente3D.kit_portero(club_b))
	var todos: Array = lista + rivales
	var anim := func(ap: AnimationPlayer, nombre: String) -> void:
		if ap != null and ap.has_animation(nombre):
			ap.play(nombre)
	var guardado := CeremoniaFoto.colocar(todos, anim)
	var visibles := rivales.filter(func(p: Dictionary) -> bool: return (p["node"] as Node3D).visible).size()
	_comprobar(visibles == 0, "el equipo visitante no sale en la foto del local (%d de %d visibles)" % [visibles, rivales.size()])
	_comprobar(guardado.size() == 11, "se guardan los once locales para devolverlos (%d)" % guardado.size())
	for i in 6:
		await get_tree().process_frame
	for p: Dictionary in lista:
		var ap: AnimationPlayer = p["anim"]
		ap.seek(0.5, true)
		ap.advance(0.0)
	var esq: Array = []
	for p: Dictionary in lista:
		esq.append(FutbolistaQ.esqueleto_de(p["node"]))
	## Segmentos del cuerpo de cada jugador (hueso A, hueso B, radio): tronco, muslos y pantorrillas.
	var cuerpo: Array = []
	for j in lista.size():
		var ej: Skeleton3D = esq[j]
		var segs: Array = []
		for par: Array in [["pelvis", "neck_01", 0.17], ["thigh_l", "calf_l", 0.10], ["thigh_r", "calf_r", 0.10], ["calf_l", "foot_l", 0.08], ["calf_r", "foot_r", 0.08]]:
			var ia := ej.find_bone(String(par[0]))
			var ib := ej.find_bone(String(par[1]))
			if ia >= 0 and ib >= 0:
				segs.append([ej.global_transform * ej.get_bone_global_pose(ia).origin, ej.global_transform * ej.get_bone_global_pose(ib).origin, float(par[2]), String(par[0])])
		cuerpo.append(segs)
	if OS.get_environment("FOTO_DETALLE") != "":
		for i in [0, 1, 7, 8]:
			var e: Skeleton3D = esq[i]
			var cur: String = (lista[i]["anim"] as AnimationPlayer).assigned_animation
			print("    [%d] %s pelvis %s mano_l %s mano_r %s" % [i, cur, str(e.global_transform * e.get_bone_global_pose(e.find_bone("pelvis")).origin), str(e.global_transform * e.get_bone_global_pose(e.find_bone("hand_l")).origin), str(e.global_transform * e.get_bone_global_pose(e.find_bone("hand_r")).origin)])
	var ajenos := 0
	var propios := 0
	var peor := []
	for i in lista.size():
		var ei: Skeleton3D = esq[i]
		for b: String in HUESOS_BRAZO:
			var hb := ei.find_bone(b)
			if hb < 0:
				continue
			var pos: Vector3 = ei.global_transform * ei.get_bone_global_pose(hb).origin
			for j in lista.size():
				for sg: Array in cuerpo[j]:
					var d := _dist_segmento(pos, sg[0], sg[1])
					if d < float(sg[2]) * (0.6 if i == j else 1.0):
						if i == j:
							propios += 1
						else:
							ajenos += 1
						peor.append([d - float(sg[2]), i, j, "%s → %s" % [b, sg[3]]])
	peor.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	print("  partes del brazo dentro del cuerpo de un compañero: %d · dentro del propio: %d" % [ajenos, propios])
	if OS.get_environment("FOTO_DETALLE") != "":
		for x: Array in peor.slice(0, 12):
			print("    jugador %d %s (jugador %d): penetra %.2f m" % [x[1], x[3], x[2], -x[0]])
	_comprobar(ajenos == 0, "ningún brazo atraviesa el tronco de un compañero (%d)" % ajenos)
	_comprobar(propios == 0, "ningún brazo atraviesa el propio tronco (%d)" % propios)
	CeremoniaFoto.devolver(guardado, todos, anim)
	var vuelven := rivales.filter(func(p: Dictionary) -> bool: return (p["node"] as Node3D).visible).size()
	_comprobar(vuelven == rivales.size(), "al acabar la foto el rival reaparece (%d de %d)" % [vuelven, rivales.size()])
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
