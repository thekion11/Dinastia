class_name PlayerSpawner
extends RefCounted

## Pone los 22 titulares sobre el cesped, cada uno en su sitio de la formacion,
## con la equipacion real de su club, su cara y su estatura.
##
## Usa el modelo humano realista (`futbolista_cr7.glb`, esqueleto Mixamo) con las
## animaciones generadas por AnimMixamo. El muneco low-poly de Kenney que habia
## antes sigue en el proyecto como respaldo: si el modelo realista no carga —
## porque falte el .glb o la maquina no dé para 22 cuerpos de 17.000 vertices—
## se cae a el en vez de dejar la cancha vacia.

const MODELO_RESPALDO := "res://assets/characters/Model/characterMedium.fbx"
const ANIM_RESPALDO := {"idle": "res://assets/characters/Animations/idle.fbx",
	"run": "res://assets/characters/Animations/run.fbx", "jump": "res://assets/characters/Animations/jump.fbx"}

var kit_factory: KitTextureFactory = KitTextureFactory.new()
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

func spawn_team(root: Node3D, xi: Array, jugadores: Dictionary, formacion: Dictionary,
		es_local: bool, kit: Dictionary, kit_portero: Dictionary = {}) -> Array:
	var slots: Array = formacion.get("s", [])
	var c1 := Color(kit.get("c1", "#2b6b45"))
	var c2 := Color(kit.get("c2", "#ffffff"))
	var estilo: String = kit.get("estilo", "liso")
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

		## OJO: en la rama del modelo realista, `Vestidor.vestir()` NO recibe c1/c2.
		## Solo mira `kit_img` y `color_liso`. Con las dos vacías se queda la
		## textura que trae el modelo de fábrica —el amarillo y azul del Al-Nassr—
		## y los 22 jugadores salen vestidos igual, los dos equipos y el portero.
		## Así que cuando no hay una equipación real que ponerle, se le pasa el
		## color del club como color liso.
		var liso := kc1 if kimg == "" else Color(0, 0, 0, 0)
		var nodo := _crear_jugador(root, jid, str(slot[0]), kimg, kc1, kc2, kestilo,
			int(jug.get("dorsal", 0)), piel, pelo, look[2], liso, jug)
		if nodo.is_empty():
			continue
		var n: Node3D = nodo["nodo"]
		n.position = base_pos
		if not es_local:
			n.rotation.y = PI

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
		out.append({"node": n, "anim": nodo["anim"], "id": j.id, "jugador": jug,
			"base_pos": n.position, "slot_code": j.pos_e, "es_local": es_local,
			"realista": nodo["realista"], "banca": true})
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
	var banco := BoxMesh.new()
	banco.size = Vector3(0.9, 0.1, largo_banco)
	var mi := MeshInstance3D.new()
	mi.mesh = banco
	mi.position = Vector3(x_banda, 0.45, z0 + lado * largo_banco * 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.20, 0.12)
	mi.material_override = mat
	root.add_child(mi)

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
			VestidorQ.vestir(dq, c1)
			var apq: AnimationPlayer = dq["anim"]
			if apq.has_animation("parado"):
				apq.play("parado")
			return {"nodo": dq["nodo"], "anim": apq, "realista": true}
		usando_respaldo = true
		push_warning("PlayerSpawner: no cargo el modelo Quaternius, se usa el de respaldo")

	if not usando_respaldo:
		var d: Dictionary = Futbolista.crear(altura_de(jug, jid, puesto))
		if not d.is_empty():
			root.add_child(d["nodo"])
			Futbolista.terminar(d)
			Vestidor.vestir(d["modelo"], img_kit, piel, pelo, color_liso)
			var ap: AnimationPlayer = d["anim"]
			if ap.has_animation("parado"):
				ap.play("parado")
			return {"nodo": d["nodo"], "anim": ap, "realista": true}
		usando_respaldo = true
		push_warning("PlayerSpawner: no cargo el modelo realista, se usa el de respaldo")

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
