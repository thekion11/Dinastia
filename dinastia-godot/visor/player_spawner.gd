class_name PlayerSpawner
extends RefCounted

## Pone los 22 titulares sobre el cesped, cada uno en su sitio de la formacion,
## con la equipacion real de su club, su cara y su estatura.
##
## Usa el cuerpo Quaternius (CC0, `FutbolistaQ`) con la equipación pintada
## encima (`VestidorQ.vestir_equipacion`). El muñeco low-poly de Kenney sigue
## en el proyecto como respaldo: si el modelo no carga, se cae a él en vez de
## dejar la cancha vacía.

const MODELO_RESPALDO := "res://assets/characters/Model/characterMedium.fbx"
const ANIM_RESPALDO := {"idle": "res://assets/characters/Animations/idle.fbx",
	"run": "res://assets/characters/Animations/run.fbx", "jump": "res://assets/characters/Animations/jump.fbx"}

var kit_factory: KitTextureFactory = KitTextureFactory.new()
## La equipación completa (`DisenosKit`) del equipo que se está creando.
var _kit_x: Dictionary = {}
var _shared_lib: AnimationLibrary
var _packed_respaldo: PackedScene
var usando_respaldo := false

## La estatura la manda el juego: es `j.altura` (en cm), la misma que se lee en
## la ficha del jugador, sorteada por demarcacion con alturaPuesto(). NO se
## inventa aqui — se probo y estaba mal: el modelo 3D tiene que medir lo que
## dice la ficha, o el central que en su ficha mide 1,95 salia igual de alto que
## el extremo de 1,70.
## El rango de respaldo solo se usa si el JSON viene de una version vieja del
## juego, anterior a que se exportara la altura.
const ALTURA_POR_PUESTO := {
	"POR": [1.86, 1.98], "DFC": [1.82, 1.94], "LTD": [1.72, 1.82], "LTI": [1.72, 1.82],
	"MCD": [1.76, 1.88], "MC": [1.72, 1.84], "MCO": [1.70, 1.82],
	"ED": [1.68, 1.80], "EI": [1.68, 1.80], "DC": [1.78, 1.92],
}

static func altura_de(jug: Dictionary, jid: String, puesto: String) -> float:
	var cm := float(jug.get("altura", 0.0))
	if cm > 120.0 and cm < 230.0:
		return cm / 100.0
	var r: Array = ALTURA_POR_PUESTO.get(puesto, [1.72, 1.86])
	var h: int = abs(int(("alt" + jid).hash())) % 1000
	return float(r[0]) + (float(r[1]) - float(r[0])) * (h / 999.0)

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var r := _find_anim_player(child)
		if r:
			return r
	return null

func _build_shared_lib() -> AnimationLibrary:
	if _shared_lib:
		return _shared_lib
	var lib := AnimationLibrary.new()
	for anim_name in ANIM_RESPALDO:
		var anim_scene = load(ANIM_RESPALDO[anim_name])
		if anim_scene == null:
			continue
		var inst = anim_scene.instantiate()
		var src_player := _find_anim_player(inst)
		if src_player:
			for a in src_player.get_animation_list():
				var anim_res: Animation = src_player.get_animation(a)
				if anim_name in ["idle", "run"]:
					anim_res.loop_mode = Animation.LOOP_LINEAR
				lib.add_animation(anim_name, anim_res)
		inst.queue_free()
	_shared_lib = lib
	return lib

## Mapea un slot de formacion [posCode,x%,y%] a una posicion en la cancha 3D.
## es_local: el equipo local defiende z=+52.5, el visitante z=-52.5 (ver
## exportarVisor3D() en el HTML: 'local'/'visita' ya vienen resueltos ahi,
## no hace falta la logica de 'mio' que usa el visor 2D).
static func slot_to_position(slot: Array, es_local: bool) -> Vector3:
	var x_pct: float = slot[1]
	var y_pct: float = slot[2]
	var length_coord: float = (100.0 - y_pct) if es_local else y_pct
	var width_coord: float = x_pct if es_local else (100.0 - x_pct)
	var z: float = 52.5 - (length_coord / 100.0) * 105.0
	var x: float = -34.0 + (width_coord / 100.0) * 68.0
	return Vector3(x, 0, z)

## NOMBRE Y DORSAL FLOTANDO SOBRE CADA JUGADOR (25-9-2026, ROADMAP Fase 3:
## "nombre del jugador flotando sobre cada futbolista", y el análisis externo:
## "a distancia de juego los jugadores son siluetas minúsculas"). `fixed_size`:
## el rótulo mide lo mismo en pantalla esté cerca o en la otra punta del campo,
## que es justo cuando hace falta. Se enciende y apaga para todos a la vez desde
## el botón "Nombres" de `VistaEstadio`.
static var mostrar_nombres := true
const ROTULO := "Rotulo"
const BARRA := "Barra"
## Tamaño del rótulo con la cámara de TV; `VistaEstadio._escalar_rotulos()` lo
## corrige para las cámaras con más o menos zoom.
const TAM_ROTULO := 0.00055

##
## Los del visitante van medio metro más arriba: el caso más común de dos
## jugadores pegados es un defensor marcando a un delantero RIVAL, y con los
## rótulos a la misma altura se pisaban ("5 QuiFigueroa" en captura).
static func poner_rotulo(n: Node3D, jug: Dictionary, es_local: bool = true) -> void:
	var nombre := String(jug.get("nombre", ""))
	if nombre == "":
		return
	var partes := nombre.split(" ", false)
	var apellido := partes[partes.size() - 1] if partes.size() > 0 else nombre
	var dorsal := int(jug.get("dorsal", 0))
	var r := Label3D.new()
	r.name = ROTULO
	r.text = ("%d  %s" % [dorsal, apellido]) if dorsal > 0 else apellido
	r.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	r.fixed_size = true
	r.pixel_size = TAM_ROTULO
	r.font_size = 30
	r.outline_size = 10
	r.modulate = Color(1, 1, 1, 0.95)
	r.outline_modulate = Color(0, 0, 0, 0.85)
	## Por encima de todo: si la cabeza de otro lo tapara, se perdería el
	## nombre justo en las jugadas con más gente.
	r.no_depth_test = true
	r.render_priority = 2
	r.position = Vector3(0, 2.25 if es_local else 2.8, 0)
	r.visible = mostrar_nombres
	n.add_child(r)
	## LA BARRA DE ESTADO (26-9-2026, pendiente del estadio): bajo el nombre,
	## ocho segmentos con la energía que le queda. Va colgada del rótulo, así
	## que se oculta y se escala con él; `offset` está en píxeles del propio
	## rótulo, y con `fixed_size` queda siempre a la misma distancia del texto.
	var b := Label3D.new()
	b.name = BARRA
	b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.fixed_size = true
	b.pixel_size = TAM_ROTULO
	b.font_size = 22
	b.outline_size = 8
	b.outline_modulate = Color(0, 0, 0, 0.85)
	b.no_depth_test = true
	b.render_priority = 2
	b.offset = Vector2(0, -34)
	b.set_meta("fisico", float(jug.get("fisico", 100)))
	b.set_meta("forma", float(jug.get("forma", 60)))
	r.add_child(b)
	actualizar_barra(b, 0)

## La energía estimada al minuto `minuto`: arranca en su estado físico y baja
## más rápido cuanto peor está de forma (60 de forma ≈ -25 a los 90').
static func energia(fisico: float, forma: float, minuto: int) -> float:
	var ritmo := 0.40 - clampf(forma, 0.0, 100.0) * 0.0025
	return clampf(fisico - float(minuto) * ritmo, 0.0, 100.0)

static func actualizar_barra(b: Label3D, minuto: int) -> void:
	var e := energia(float(b.get_meta("fisico", 100.0)), float(b.get_meta("forma", 60.0)), minuto)
	var llenos := clampi(int(ceil(e / 12.5)), 0, 8)
	b.text = "▰".repeat(llenos) + "▱".repeat(8 - llenos)
	b.modulate = Color("5fd35f") if e >= 65.0 else (Color("f0c040") if e >= 40.0 else Color("e5534b"))

func spawn_team(root: Node3D, xi: Array, jugadores: Dictionary, formacion: Dictionary,
		es_local: bool, kit: Dictionary, kit_portero: Dictionary = {}) -> Array:
	var slots: Array = formacion.get("s", [])
	var c1 := Color(kit.get("c1", "#2b6b45"))
	var c2 := Color(kit.get("c2", "#ffffff"))
	var estilo: String = kit.get("estilo", "liso")
	_kit_x = kit.get("x", {})
	var img_kit := str(kit.get("img", "")) if kit.get("img") != null else ""
	var out: Array = []

	for i in range(xi.size()):
		var jid = xi[i]
		var jug: Dictionary = jugadores.get(jid, {})
		if jug.is_empty():
			continue
		var slot: Array = slots[i] if i < slots.size() else ["", 50, 50]
		var base_pos := slot_to_position(slot, es_local)
		var es_por: bool = str(slot[0]) == "POR"
		var look := _look_de(jug)
		var piel: Color = look[0]
		var pelo: Color = look[1]

		# el arquero viste distinto a sus companeros, como en el futbol real
		var kc1 := c1
		var kc2 := c2
		var kestilo := estilo
		var kimg := img_kit
		if es_por and not kit_portero.is_empty():
			kc1 = Color(kit_portero.get("c1", "#2fa06a"))
			kc2 = Color(kit_portero.get("c2", "#101010"))
			kestilo = str(kit_portero.get("estilo", "liso"))
			kimg = ""

		## Color liso: el pantalón del árbitro y, en el muñeco de respaldo, la
		## equipación cuando no hay una imagen de camiseta que ponerle.
		var liso := kc1 if kimg == "" else Color(0, 0, 0, 0)
		var nodo := _crear_jugador(root, jid, str(slot[0]), kimg, kc1, kc2, kestilo,
			int(jug.get("dorsal", 0)), piel, pelo, look[2], liso, jug)
		if nodo.is_empty():
			continue
		var n: Node3D = nodo["nodo"]
		n.position = base_pos
		if not es_local:
			n.rotation.y = PI
		poner_rotulo(n, jug, es_local)

		out.append({"node": n, "anim": nodo["anim"], "id": jid, "jugador": jug,
			"base_pos": base_pos, "slot_code": slot[0], "es_local": es_local,
			"realista": nodo["realista"]})
	return out

## El arbitro y los dos jueces de linea. Mismo modelo que los jugadores, de negro
## y sin equipacion de club, y colocados como en un partido de verdad: el arbitro
## en diagonal por el centro y cada juez de linea en su banda, en su mitad.
## Devuelve la misma estructura que spawn_team para que MatchPlayback los mueva
## igual que a los demas.
func spawn_arbitros(root: Node3D) -> Array:
	var puestos := [
		{"id": "arbitro", "pos": Vector3(6.0, 0, 8.0), "rot": -0.6, "alto": 1.80},
		{"id": "linea_a", "pos": Vector3(-36.5, 0, -22.0), "rot": PI * 0.5, "alto": 1.78},
		{"id": "linea_b", "pos": Vector3(36.5, 0, 22.0), "rot": -PI * 0.5, "alto": 1.78},
	]
	var out: Array = []
	for p in puestos:
		var d := _crear_jugador(root, str(p["id"]), "ARB", "", Color(0.06, 0.06, 0.08),
			Color(0.9, 0.85, 0.1), "liso", 0, Color(0.82, 0.63, 0.5), Color(0.16, 0.12, 0.09), 0,
			Color(0.07, 0.07, 0.09, 1.0))
		if d.is_empty():
			continue
		var n: Node3D = d["nodo"]
		n.position = p["pos"]
		n.rotation.y = float(p["rot"])
		out.append({"node": n, "anim": d["anim"], "id": p["id"], "jugador": {},
			"base_pos": p["pos"], "slot_code": "ARB", "es_local": true,
			"realista": d["realista"], "arbitro": true})
	return out

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
			n.position.z += lado * 1.4
			entrada["base_pos"] = n.position
			var ap_d: AnimationPlayer = nodo["anim"]
			if Dominadas.montar(n, ap_d, clip) != null:
				ap_d.play(clip)
				entrada["reposo_anim"] = clip
		out.append(entrada)
	return out

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

## Modelo Quaternius en partidos reales (21-9-2026), a pedido explicito del
## usuario -"conectalo igual, desnudo por ahora"-. El cuerpo mocap real ya esta
## listo (parado/caminar/trotar/correr/patear/celebrar/atajar/cabezazo/
## mostrar_tarjeta/penal, ver AnimQuaternius).
## VESTIDO (21-9-2026, mismo dia): `VestidorQ.vestir()` -pieza "Peasant" del
## pack gratis "Modular Character Outfits - Fantasy", mismo esqueleto,
## coloreada al color del club, no foto real (el UV no la soporta de forma
## confiable, ver LEEME.md)-. Bandera para volver atras en una linea si hace
## falta.
const USAR_MODELO_Q := true

## Un jugador, con el modelo realista si se puede y con el de respaldo si no.
func _crear_jugador(root: Node3D, jid: String, puesto: String, img_kit: String,
		c1: Color, c2: Color, estilo: String, dorsal: int, piel: Color, pelo: Color,
		barba: int, color_liso: Color = Color(0, 0, 0, 0), jug: Dictionary = {}) -> Dictionary:
	if not usando_respaldo and USAR_MODELO_Q:
		var dq: Dictionary = FutbolistaQ.crear(altura_de(jug, jid, puesto), "male")
		if not dq.is_empty():
			root.add_child(dq["nodo"])
			FutbolistaQ.terminar(dq, true)
			## Equipación pintada sobre el cuerpo (camiseta con su estilo,
			## pantalón, medias, botines); la ropa teñida de antes queda solo
			## como respaldo si faltara la máscara.
			var pantalon := color_liso if puesto == "ARB" else Color(0, 0, 0, 0)
			## La equipación completa del club (diseñador), salvo arquero y
			## árbitro, que visten la suya.
			var kx: Dictionary = {} if puesto in ["POR", "ARB"] else _kit_x
			if not VestidorQ.vestir_equipacion(dq, c1, c2, estilo, piel, pelo, pantalon, Color(0, 0, 0, 0), false, kx, dorsal):
				VestidorQ.vestir(dq, c1)
			## Pelo, barba y cejas, con el mismo corte que su retrato 2D.
			var look_j = jug.get("look")
			## Y su cara: los rasgos del retrato (o la foto real) moldeados
			## sobre la cabeza.
			if typeof(look_j) == TYPE_DICTIONARY:
				VestidorQ.poner_cara(dq, {"look": look_j, "foto": String(jug.get("foto", ""))}, piel)
			var corte := "corto"
			if typeof(look_j) == TYPE_DICTIONARY and look_j.get("pelo") is String:
				corte = look_j["pelo"]
			## Barba 3D solo para las barbas completas del retrato (1, 4 y 6):
			## bigote, perilla o barba de días no son esa malla.
			PeloQ.poner(dq, corte, pelo, barba in [1, 4, 6])
			var apq: AnimationPlayer = dq["anim"]
			if apq.has_animation("parado"):
				apq.play("parado")
			return {"nodo": dq["nodo"], "anim": apq, "realista": true}
		usando_respaldo = true
		push_warning("PlayerSpawner: no cargo el modelo Quaternius, se usa el de respaldo")

	if _packed_respaldo == null:
		_packed_respaldo = load(MODELO_RESPALDO)
	if _packed_respaldo == null:
		push_error("PlayerSpawner: tampoco se pudo cargar " + MODELO_RESPALDO)
		return {}
	var node: Node3D = _packed_respaldo.instantiate()
	root.add_child(node)
	var variant: int = abs(int(jid.hash())) % 4
	var mat := kit_factory.get_material(c1, c2, estilo, dorsal, variant, img_kit, piel, pelo, barba)
	_apply_material(node, mat)
	var ap2 := _find_anim_player(node)
	if ap2 == null:
		ap2 = AnimationPlayer.new()
		node.add_child(ap2)
	if ap2.has_animation_library(""):
		ap2.remove_animation_library("")
	ap2.add_animation_library("", _build_shared_lib())
	if ap2.has_animation("idle"):
		ap2.play("idle")
	return {"nodo": node, "anim": ap2, "realista": false}

func _apply_material(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in range(mi.get_surface_override_material_count()):
			mi.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_material(child, mat)

## Aspecto del jugador tal y como lo tiene el juego: lookVisor3D() manda en el
## JSON el mismo tono de piel, color de pelo y barba que se ven en su ficha. Sin
## esto los veintidos futbolistas comparten cuatro caras y se nota mucho.
## Devuelve [piel, pelo, barba].
static func _look_de(jug: Dictionary) -> Array:
	var piel := Color(0.85, 0.66, 0.52)
	var pelo := Color(0.19, 0.13, 0.09)
	var barba := 0
	var look = jug.get("look")
	if typeof(look) == TYPE_DICTIONARY:
		piel = _col(look.get("piel"), piel)
		pelo = _col(look.get("peloC"), pelo)
		barba = int(look.get("barba", 0))
	return [piel, pelo, barba]

static func _col(v, por_defecto: Color) -> Color:
	if typeof(v) == TYPE_STRING and str(v).begins_with("#"):
		return Color(str(v))
	return por_defecto
