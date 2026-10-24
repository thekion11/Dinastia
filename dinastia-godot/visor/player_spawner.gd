class_name PlayerSpawner
extends "res://visor/player_spawner_p1.gd"
## [Capa 2/2 de `player_spawner.gd`] spawn_cuarto_arbitro, spawn_banca, _banco_de_suplentes, spawn_sentados

## EL CUARTO ÁRBITRO (17-10-2026, M-139): solo sale cuando hace falta (el
## cartel del añadido), así no cuesta nada el resto del partido. Mismo modelo y
## camiseta que el trío.
func spawn_cuarto_arbitro(root: Node3D, kit: Dictionary = {}) -> Dictionary:
	var d := _crear_jugador(root, "cuarto_arbitro", "ARB", "", Color(String(kit.get("c1", "#111216"))),
		Color(String(kit.get("c2", "#e6d91a"))), "liso", 0, Color(0.74, 0.55, 0.42), Color(0.12, 0.1, 0.08), 0,
		Color(Color(String(kit.get("pantalon", "#121217"))), 1.0))
	return d

## LOS SUPLENTES, DE PIE EN LA ZONA TECNICA (22-9-2026, Fase 3 del ROADMAP:
## "efecto banquillo visual" / lenguaje corporal en la banda). Hasta hoy la
## banda estaba vacia -ni un solo suplente se veia en el visor 3D, solo el
## MUEBLE del banquillo (`StadiumBuilder._banquillos_detalle()`), nunca gente
## adentro-.
##
## DE PIE junto al banquillo, no sentados adentro: encajar una pose sentada
## en el asiento exacto de cada uno de los 5 tipos de banquillo -banca/
## cristal/bunker/sillones/foso, cada uno con su propia geometria interna, sin
## ninguna lista de "estas son las posiciones de los asientos" expuesta hacia
## afuera- es un riesgo de encaje (altura del asiento, choque con el vidrio,
## una pose de piernas nueva sin calibrar en este esqueleto) que no
## correspondia resolver en la misma ronda que conecta la banda por primera
## vez. De pie en la zona tecnica es igual de real -en un partido de verdad
## buena parte del banco pasa el partido de pie, no sentado- y sirve para los
## 5 tipos de banquillo por igual, sin tocar `StadiumBuilder`.
##
## `jugadores`: los citados que NO estan en el once, `Array[Jugador]` (no hace
## falta pasar por `Puente3D.once()`, se usa `Puente3D.jugador()` uno por
## uno). Como mucho 7 -mas modelos completos animados por equipo es carga real
## de verdad, y en una banda de verdad tampoco se distingue a todos con la
## misma nitidez desde la grada-.
func spawn_banca(root: Node3D, jugadores: Array, es_local: bool, kit: Dictionary,
		kit_portero: Dictionary = {}) -> Array:
	var c1 := Color(kit.get("c1", "#2b6b45"))
	var c2 := Color(kit.get("c2", "#ffffff"))
	var estilo: String = kit.get("estilo", "liso")
	_kit_x = kit.get("x", {})
	var img_kit := str(kit.get("img", "")) if kit.get("img") != null else ""
	var out: Array = []
	## Misma banda tecnica que usa `_banquillos_detalle()` para el mueble -X
	## fijo y positivo para los DOS equipos (la tribuna principal), base en
	## 3.5m tras la linea de banda, +-14m del circulo central en Z segun el
	## lado-.
	##
	## CORREGIDO CON CAPTURA REAL (22-9-2026): el primer valor (2.4m) ponia a
	## la gente DENTRO del propio banquillo -el vidrio frontal de la burbuja
	## "cristal"/"bunker" llega hasta X=39,65 (base 37.5 + 1.15 de fondo en
	## Z local, rotado 90 grados a X global) y la base estructural hasta
	## X=36,1 (37.5-1.4), asi que 36.4 caia adentro de ese rango, no al
	## frente-. 1.0m deja a la fila en la franja tecnica de verdad, entre la
	## linea de banda (X=34) y el borde mas cercano del banquillo (X=36,1),
	## con espacio de sobra para las dos.
	const DISTANCIA_LINEA_BANDA := 1.0
	var lado := -1.0 if es_local else 1.0
	var x_banda := 34.0 + DISTANCIA_LINEA_BANDA
	var cuantos: int = mini(jugadores.size(), 7)
	## Quién calienta con dominadas: el último de la fila que no sea portero.
	var calienta := -1
	for i in cuantos:
		if (jugadores[i] as Jugador).pos_e != "POR":
			calienta = i
	for i in cuantos:
		var j: Jugador = jugadores[i]
		var jug := Puente3D.jugador(j)
		var es_por: bool = j.pos_e == "POR"
		var look := _look_de(jug)
		var piel: Color = look[0]
		var pelo: Color = look[1]
		var kc1 := c1
		var kc2 := c2
		var kestilo := estilo
		var kimg := img_kit
		if es_por and not kit_portero.is_empty():
			kc1 = Color(kit_portero.get("c1", "#2fa06a"))
			kc2 = Color(kit_portero.get("c2", "#101010"))
			kestilo = str(kit_portero.get("estilo", "liso"))
			kimg = ""
		var liso := kc1 if kimg == "" else Color(0, 0, 0, 0)
		var nodo := _crear_jugador(root, j.id, j.pos_e, kimg, kc1, kc2, kestilo,
			int(jug.get("dorsal", 0)), piel, pelo, look[2], liso, jug)
		if nodo.is_empty():
			continue
		var n: Node3D = nodo["nodo"]
		## Fila a lo largo de la banda (eje Z), 1.6m entre uno y el siguiente,
		## centrada en el mismo punto que el banquillo fisico (lado*14.0).
		var z: float = lado * 14.0 + (float(i) - float(cuantos - 1) / 2.0) * 1.6
		n.position = Vector3(x_banda, 0, z)
		## Mirando hacia la cancha (X negativo desde la banda). Signo a
		## confirmar con una captura real -mismo tipo de trampa de "de canto
		## en vez de de frente" ya documentada para la camara de
		## `spike_tramo.gd"- antes de dar esto por cerrado.
		n.rotation.y = -PI * 0.5
		var entrada := {"node": n, "anim": nodo["anim"], "id": j.id, "jugador": jug,
			"base_pos": n.position, "slot_code": j.pos_e, "es_local": es_local,
			"realista": nodo["realista"], "banca": true}
		## El último de la fila (nunca un portero) calienta haciendo dominadas
		## con balón -mocap real, ver `Dominadas`-, un poco apartado del resto.
		if i == calienta and bool(nodo["realista"]):
			var clip := "dominadas_%d" % (1 + absi(j.id.hash()) % 3)
			## Apartado de la fila: un paso hacia el campo y fuera del hueco
			## de su vecino (con 1,4 m en Z caía encima del de al lado, que
			## está a 1,6 m) (13-10-2026).
			n.position.z += lado * 2.6
			n.position.x -= signf(x_banda) * 1.2
			entrada["base_pos"] = n.position
			var ap_d: AnimationPlayer = nodo["anim"]
			if Dominadas.montar(n, ap_d, clip) != null:
				ap_d.play(clip)
				entrada["reposo_anim"] = clip
		out.append(entrada)
	return out

## EL BANCO DE LOS SUPLENTES, DE VERDAD (26-9-2026, plan maestro C2). Era una
## tabla marrón a 0,45 m y nada más. Ahora es lo que hay en un estadio: una
## base, una butaca por jugador -asiento y respaldo del color del club-, la
## pared de atrás y un techo con frente de metacrilato. Las butacas van justo
## donde se sienta cada uno (mismo `paso`), así que la pose no cambia.
static func _banco_de_suplentes(root: Node3D, x: float, z0: float, lado: float, cuantos: int,
		paso: float, largo: float, color: Color) -> void:
	var zc := z0 + lado * largo * 0.5
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.22, 0.23, 0.25)
	base_mat.roughness = 0.7
	var butaca := StandardMaterial3D.new()
	butaca.albedo_color = color.lerp(Color(0.12, 0.12, 0.14), 0.25)
	butaca.roughness = 0.45
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.72, 0.74, 0.77)
	metal.metallic = 0.6
	metal.roughness = 0.35
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.6, 0.7, 0.78, 0.25)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.cull_mode = BaseMaterial3D.CULL_DISABLED
	vidrio.roughness = 0.05
	var caja := func(pos: Vector3, tam: Vector3, mat: Material) -> void:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = tam
		mi.mesh = bm
		mi.material_override = mat
		mi.position = pos
		root.add_child(mi)
	## Plataforma y pared trasera.
	caja.call(Vector3(x + 0.15, 0.04, zc), Vector3(1.6, 0.08, largo + 0.6), base_mat)
	caja.call(Vector3(x + 0.85, 1.05, zc), Vector3(0.1, 2.0, largo + 0.6), base_mat)
	## Una butaca por jugador: asiento, respaldo y el pie metálico.
	for i in cuantos:
		var z := z0 + lado * (float(i) + 0.5) * paso
		caja.call(Vector3(x + 0.05, 0.45, z), Vector3(0.5, 0.08, 0.5), butaca)
		caja.call(Vector3(x + 0.33, 0.78, z), Vector3(0.08, 0.62, 0.5), butaca)
		caja.call(Vector3(x + 0.1, 0.23, z), Vector3(0.08, 0.38, 0.08), metal)
	## Techo con frente de metacrilato (el del banquillo de un estadio de hoy).
	caja.call(Vector3(x + 0.2, 2.08, zc), Vector3(1.5, 0.08, largo + 0.6), metal)
	caja.call(Vector3(x - 0.55, 1.75, zc), Vector3(0.03, 0.65, largo + 0.6), vidrio)
	for extremo in [-1.0, 1.0]:
		caja.call(Vector3(x + 0.15, 1.05, zc + extremo * (largo + 0.6) * 0.5), Vector3(1.5, 2.0, 0.04), vidrio)

## LOS QUE NO CABEN, SENTADOS (22-9-2026, pedido directo del usuario tras ver
## las capturas del banquillo de pie: "que los que no caben estén sentados").
## Hasta 5 MAS por equipo -de pie ya van 7 (`spawn_banca()`), con estos son
## hasta 12, un banco de verdad hoy en dia-, en un banco SENCILLO propio
## -tabla y nada mas, no uno de los 5 tipos elaborados de
## `StadiumBuilder._banquillos_detalle()`, mismo criterio ya explicado ahi
## sobre no arriesgar el encaje de una pose nueva en una geometria ajena-,
## continuando la fila de pie hacia afuera en Z -NO duplicado en X: entre la
## linea de banda (X=34) y la cara del banquillo fisico (X=36,1) ya no cabe
## una segunda fila, es una franja de apenas 2,1m-.
func spawn_sentados(root: Node3D, jugadores: Array, es_local: bool, kit: Dictionary,
		kit_portero: Dictionary = {}) -> Array:
	var c1 := Color(kit.get("c1", "#2b6b45"))
	var c2 := Color(kit.get("c2", "#ffffff"))
	var estilo: String = kit.get("estilo", "liso")
	_kit_x = kit.get("x", {})
	var img_kit := str(kit.get("img", "")) if kit.get("img") != null else ""
	var out: Array = []
	if jugadores.is_empty():
		return out
	var lado := -1.0 if es_local else 1.0
	var x_banda := 35.0
	var cuantos: int = mini(jugadores.size(), 5)
	## Arranca donde termina la fila de pie (7 figuras, 1.6m de paso,
	## centradas en `lado*14.0`) mas un hueco de un paso, y sigue alejandose
	## del centro -no se mete hacia la mitad de cancha, donde vive el resto
	## de la banda tecnica (cuarto arbitro, etc.)-.
	var z0: float = lado * 14.0 + lado * (3.0 * 1.6 + 1.6)
	var paso_sentado := 1.1
	var largo_banco: float = float(cuantos) * paso_sentado + 0.4
	_banco_de_suplentes(root, x_banda, z0, lado, cuantos, paso_sentado, largo_banco, c1)

	for i in cuantos:
		var j: Jugador = jugadores[i]
		var jug := Puente3D.jugador(j)
		var es_por: bool = j.pos_e == "POR"
		var look := _look_de(jug)
		var piel: Color = look[0]
		var pelo: Color = look[1]
		var kc1 := c1
		var kc2 := c2
		var kestilo := estilo
		var kimg := img_kit
		if es_por and not kit_portero.is_empty():
			kc1 = Color(kit_portero.get("c1", "#2fa06a"))
			kc2 = Color(kit_portero.get("c2", "#101010"))
			kestilo = str(kit_portero.get("estilo", "liso"))
			kimg = ""
		var liso := kc1 if kimg == "" else Color(0, 0, 0, 0)
		var nodo := _crear_jugador(root, j.id, j.pos_e, kimg, kc1, kc2, kestilo,
			int(jug.get("dorsal", 0)), piel, pelo, look[2], liso, jug)
		if nodo.is_empty():
			continue
		var n: Node3D = nodo["nodo"]
		var z: float = z0 + lado * (float(i) + 0.5) * paso_sentado
		## `ALTO_ASIENTO_OFFSET` (`AnimQuaternius`, medido con
		## `pruebas/diagnostico_altura_cadera_q.gd`: cadera de pie a 1,03m,
		## banco a 0,45m) baja la RAIZ del modelo -la pose "sentado" solo
		## dobla las piernas, no mueve la cadera en el espacio por si sola-.
		n.position = Vector3(x_banda, AnimQuaternius.ALTO_ASIENTO_OFFSET, z)
		n.rotation.y = -PI * 0.5
		var ap: AnimationPlayer = nodo["anim"]
		if is_instance_valid(ap) and ap.has_animation("sentado"):
			ap.play("sentado")
		out.append({"node": n, "anim": ap, "id": j.id, "jugador": jug,
			"base_pos": n.position, "slot_code": j.pos_e, "es_local": es_local,
			"realista": nodo["realista"], "banca": true, "sentado": true})
	return out
