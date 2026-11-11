extends SceneTree
## CATÁLOGO DE LOS 21 CLIPS DE FÚTBOL DE ANDERSON ROHR (sesión 10, 11-11-2026): tipo, duración y, para patadas y regates, el CUADRO DE
## CONTACTO con el balón (el de mayor velocidad del pie que golpea, medida sobre el esqueleto de origen UE5 a 30 fps), el pie y la
## altura del pie en ese instante. Salida: `datos/animaciones_catalogo_rohr.json`.
##   godot --headless --path . --script res://herramientas/catalogo_rohr.gd
const CARPETA := "res://assets/characters/quaternius/anims_futbol/"
const SALIDA := "res://datos/animaciones_catalogo_rohr.json"
const FPS := 30.0
const TIPOS := {"Dribble": "regate", "Juggling": "malabares", "Throw_In": "saque_de_banda", "Side_Foot_Kick": "pase_con_el_interior",
	"Power_Kick": "tiro_potente", "Penalty_Kick": "penal", "Goal_Celebration": "celebracion_gol", "Goalkeeper_Save": "parada_portero",
	"Defending": "defensa", "Yellow_And_Red_Card": "tarjeta_roja", "Yellow_Card": "tarjeta_amarilla"}
const CON_BALON := ["regate", "malabares", "pase_con_el_interior", "tiro_potente", "penal"]

func _initialize() -> void:
	await process_frame
	var fichas := []
	for f in DirAccess.get_files_at(CARPETA):
		if not f.ends_with(".fbx"):
			continue
		var packed: PackedScene = load(CARPETA + f)
		var escena: Node = packed.instantiate()
		root.add_child(escena)
		await process_frame
		var ap: AnimationPlayer = escena.find_children("*", "AnimationPlayer", true, false)[0]
		var esq: Skeleton3D = escena.find_children("*", "Skeleton3D", true, false)[0]
		var nombre_anim := ""
		for a in ap.get_animation_list():
			if a != "RESET":
				nombre_anim = a
		var anim := ap.get_animation(nombre_anim)
		var tipo := "otro"
		for k: String in TIPOS:
			if f.contains(k):
				tipo = TIPOS[k]
				break
		var n := int(anim.length * FPS)
		var ficha := {"nombre": f.get_basename(), "fuente": "Free mocap pack 05: Soccer (Anderson Rohr)", "licencia": "uso libre según su autor (sin texto de licencia en el zip: ver LICENCIAS.md)",
			"tipo": tipo, "cuadros": n, "fps": int(FPS), "duracion_s": snappedf(anim.length, 0.001), "bucle": false}
		if CON_BALON.has(tipo):
			var ib := [esq.find_bone("ball_l"), esq.find_bone("ball_r")]
			var prev: Array = [Vector3.ZERO, Vector3.ZERO]
			var mejor := [0.0, 0.0]
			var cuadro := [0, 0]
			var alto := [0.0, 0.0]
			var picos: Array = [[], []]
			var vs: Array = [[], []]
			for k in n + 1:
				ap.play(nombre_anim)
				ap.seek(float(k) / FPS, true)
				ap.advance(0.0)
				for l in 2:
					var p: Vector3 = esq.global_transform * esq.get_bone_global_pose(ib[l]).origin
					var v: float = (p - (prev[l] as Vector3)).length() * FPS if k > 0 else 0.0
					vs[l].append(v)
					if k >= 4 and v > mejor[l]:   # los primeros cuadros saltan desde la pose inicial: no cuentan
						mejor[l] = v
						cuadro[l] = k
						alto[l] = p.y
					prev[l] = p
			var l_ := 0 if mejor[0] > mejor[1] else 1
			ficha["pie_que_golpea"] = "I" if l_ == 0 else "D"
			ficha["cuadro_toque_balon"] = cuadro[l_]
			ficha["tiempo_toque_s"] = snappedf(float(cuadro[l_]) / FPS, 0.001)
			ficha["velocidad_pie_ms"] = snappedf(mejor[l_], 0.1)
			ficha["altura_pie_m"] = snappedf(alto[l_], 0.001)
			if true:   # TODOS los golpeos: picos locales de velocidad (> 45 % del máximo); el principal es el más rápido
				var toques := []
				for l in 2:
					for k in range(4, n):
						var v0: float = vs[l][k]
						if v0 > 0.45 * mejor[l] and v0 >= vs[l][k - 1] and v0 > vs[l][k + 1]:
							toques.append({"cuadro": k, "pie": "I" if l == 0 else "D"})
				toques.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["cuadro"]) < int(b["cuadro"]))
				ficha["golpeos"] = toques
		fichas.append(ficha)
		ap.stop()
		escena.queue_free()
		await process_frame
	fichas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["nombre"]) < String(b["nombre"]))
	var out := FileAccess.open(SALIDA, FileAccess.WRITE)
	out.store_string(JSON.stringify(fichas, "\t"))
	out.close()
	for fi in fichas:
		print(fi["nombre"], " ", fi["tipo"], " ", fi["duracion_s"], " s  toque=", fi.get("cuadro_toque_balon", "-"), " ", fi.get("pie_que_golpea", ""))
	quit(0)
