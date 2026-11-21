extends Node
## AUDITORÍA DE LAS RUTAS DEL PERSONAL DEL CLUB (20-11, orden del dueño: «deben moverse mejor, no atravesar objetos»). Abre el club de tres
## clubes de tres países, y para cada persona del personal recorre cada tramo de su ruta con una cápsula del tamaño de una persona
## (`PersonalEstadio.RADIO`, 1,6 m) contra TODO lo sólido del edificio (muebles, paredes, tabiques). Un tramo que choca = «atraviesa».
##   godot --headless --path . res://pruebas/auditoria_rutas_personal.tscn   (CLUBES="CHI:0,ESP:3,ARG:5"; INFORME=1 lista cada tramo)
## Termina con «FIN. N fallos» (el banco `estadio` lo cubre con la parte lógica).
var _vista: VistaEstadio
var _n := 0
var _fallos := 0
var _clubes: Array = []
var _i := 0

func _ready() -> void:
	var txt := OS.get_environment("CLUBES") if OS.get_environment("CLUBES") != "" else "CHI:0,ESP:3,ARG:5"
	for par in txt.split(","):
		var p := par.split(":")
		_clubes.append([p[0], int(p[1])])
	_abrir()

func _abrir() -> void:
	## Solo con calidad MEDIA o más el personal pasea (en ULTRA BAJA y BAJA se queda en su puesto): CALIDAD=-3..3, por defecto 0.
	Calidad.elegida = int(OS.get_environment("CALIDAD")) if OS.get_environment("CALIDAD") != "" else Calidad.MEDIA
	var pais: String = _clubes[_i][0]
	var m := Mundo.new()
	m.generar([pais], 77)
	var club: Club = m.ligas[0].clubes[int(_clubes[_i][1]) % m.ligas[0].clubes.size()]
	PersonajeDT.club_usuario = club.id
	var pl: Array = []
	for j: Jugador in club.plantilla:
		pl.append([pl.size() + 1, Nombres.visible(j.nombre)])
	EdificioClub.ctx = {"inst": {"park": 5, "med": 7, "video": 6, "museo": 6}, "dentro": {"sala_prensa": "television"},
		"plantilla": pl, "titulos": 4, "presidente": "Presidente Ficticio"}
	var perfil := EstadioPropio.new().perfil(club)
	perfil["niveles"] = 2
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, perfil)
	_n = 0
	print("== CLUB ", pais, " ", club.nombre)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
	var personal := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
	if _n >= 30 and (personal == null or personal.rutas_listas or _n >= 400):
		_revisar()
		_vista.queue_free()
		_i += 1
		if _i >= _clubes.size():
			print("===== FIN. %d fallos" % _fallos)
			get_tree().quit(1 if _fallos > 0 else 0)
		else:
			_abrir()

func _revisar() -> void:
	var personal := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
	if personal == null:
		_fallos += 1
		print("  FALLO no hay personal en el club")
		return
	var espacio := (_vista as Node).get_viewport().find_world_3d().direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = PersonalEstadio.RADIO
	cap.height = 1.6
	print("  calidad=%d en_puesto=%s rutas_listas=%s" % [Calidad.elegida, PersonalEstadio.en_puesto(), personal.rutas_listas])
	if OS.get_environment("MAPA") != "":   ## MAPA=planta: dibuja la ocupación (# = no cabe una persona) de x -9..9, z 78..92, cada 25 cm
		var yp := RecorridoClub.y_de(int(OS.get_environment("MAPA")))
		for iz in range(0, 57):
			var fila := ""
			for ix in range(0, 73):
				var pp := Vector3(-9.0 + ix * 0.25, yp, 78.0 + iz * 0.25)
				fila += "." if _choca(espacio, cap, pp, pp) == "" else "#"
			print("  z=%5.2f %s" % [78.0 + iz * 0.25, fila])
	var tramos := 0
	var malos := 0
	for g: Dictionary in personal.gente:
		var ruta: Array = g["ruta"]
		if OS.get_environment("INFORME") == "1" and String(g["clave"]) in OS.get_environment("VER").split(","):
			var dbg := ""
			for pt: Vector3 in ruta:
				dbg += " (%.2f,%.2f)%s" % [pt.x, pt.z, "" if _choca(espacio, cap, pt, pt) == "" else "*"]
			print("  ruta ", g["clave"], ":", dbg)
		for k in range(ruta.size() - 1):
			tramos += 1
			var choque := _choca(espacio, cap, ruta[k], ruta[k + 1])
			if choque != "":
				malos += 1
				_fallos += 1
				print("  FALLO %s (planta %d): el tramo %d atraviesa %s" % [g["clave"], int(g["planta"]), k, choque])
		if ruta.size() == 1 or ruta.is_empty():
			print("  (ruta corta: ", g["clave"], ")")
	print("  tramos: %d, atraviesan: %d, sin camino libre: %d" % [tramos, malos, personal.rutas_sin_camino])
	## Andando de verdad: 3 minutos de partida a 30 fotogramas/s; cuenta los instantes con alguien DENTRO de un mueble o pared y los choques entre personas.
	var dentro := 0
	var juntos := 0
	var pasos_total := 0
	var peor_dist := 99.0
	for paso in 5400:
		personal._process(1.0 / 30.0)
		if paso % 3 != 0:
			continue
		for g: Dictionary in personal.gente:
			var n: Node3D = g["nodo"]
			if not n.visible:
				continue
			pasos_total += 1
			if _choca(espacio, cap, n.position, n.position) != "":
				dentro += 1
				if OS.get_environment("INFORME") == "1" and dentro < 6:
					print("    DENTRO ", g["clave"], " en ", n.position)
			for o: Dictionary in personal.gente:
				if o != g and int(o["planta"]) == int(g["planta"]) and (o["nodo"] as Node3D).visible:
					var dd := Vector2(n.position.x - (o["nodo"] as Node3D).position.x, n.position.z - (o["nodo"] as Node3D).position.z).length()
					peor_dist = minf(peor_dist, dd)
					if dd < 0.35:
						juntos += 1
	print("  andando: %d muestras, DENTRO de algo: %d, personas a menos de 35 cm: %d (mínima %.2f m)" % [pasos_total, dentro, juntos, peor_dist])
	if dentro > 0:
		_fallos += 1
		print("  FALLO alguien entra en un mueble o una pared al andar")

## Nombre de lo primero sólido que toca la cápsula a lo largo de a→b (cada 10 cm), "" si va libre.
func _choca(espacio: PhysicsDirectSpaceState3D, cap: CapsuleShape3D, a: Vector3, b: Vector3) -> String:
	var largo := a.distance_to(b)
	var pasos := maxi(int(largo / 0.1), 1)
	for s in pasos + 1:
		var p := a.lerp(b, float(s) / pasos)
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cap
		q.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 0.12 + 0.8, 0))
		q.collide_with_bodies = true
		var r := espacio.intersect_shape(q, 2)
		if not r.is_empty():
			var col := r[0]["collider"] as Node
			var nom := String(col.get_parent().name) if col != null and col.get_parent() != null else "?"
			var det := ""
			if OS.get_environment("INFORME") == "1" and col != null:
				for sh in col.find_children("*", "CollisionShape3D", true, false):
					var cs := sh as CollisionShape3D
					det += " [%s en y=%.2f %s]" % [cs.shape.get_class(), cs.global_position.y, (cs.shape as BoxShape3D).size if cs.shape is BoxShape3D else ""]
			return "«%s» en (%.1f, %.2f, %.1f)%s" % [nom, p.x, p.y, p.z, det]
	return ""
