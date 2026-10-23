extends RefCounted
## (Parte 1 de 2 de `player_spawner.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `player_spawner.gd`, conserva la clase.)

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

## La barra con la energía `e` (0-100): verde, amarilla o roja, sobre fondo
## oscuro. Las texturas se guardan por nivel (hay 29), no se crean cada vez.
static var _texturas_barra := {}
const BARRA_ANCHO := 104
const BARRA_ALTO := 9

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

static func poner_energia(b: Node3D, e: float) -> void:
	var s := b as Sprite3D
	if s == null:
		return
	var nivel := clampi(int(round(e / 100.0 * 28.0)), 0, 28)
	if not _texturas_barra.has(nivel):
		var img := Image.create(BARRA_ANCHO, BARRA_ALTO, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0.62))
		var ee := float(nivel) / 28.0
		var col := Color("52e07a") if ee >= 0.65 else (Color("f5d33b") if ee >= 0.4 else Color("ff5a3c"))
		var lleno := int(round(float(BARRA_ANCHO - 4) * ee))
		if lleno > 0:
			img.fill_rect(Rect2i(2, 2, lleno, BARRA_ALTO - 4), col)
		_texturas_barra[nivel] = ImageTexture.create_from_image(img)
	s.texture = _texturas_barra[nivel]

## La energía estimada al minuto `minuto`: arranca en su estado físico y baja
## más rápido cuanto peor está de forma (60 de forma ≈ -25 a los 90').
static func energia(fisico: float, forma: float, minuto: int) -> float:
	var ritmo := 0.40 - clampf(forma, 0.0, 100.0) * 0.0025
	return clampf(fisico - float(minuto) * ritmo, 0.0, 100.0)

static func actualizar_barra(b: Node3D, minuto: int) -> void:
	poner_energia(b, energia(float(b.get_meta("fisico", 100.0)), float(b.get_meta("forma", 60.0)), minuto))

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
	## (14-10-2026) Como en FC: una barra FINA y continua, no cuadraditos.
	var b := Sprite3D.new()
	b.name = BARRA
	b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.fixed_size = true
	b.pixel_size = TAM_ROTULO
	b.no_depth_test = true
	b.render_priority = 2
	b.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	b.offset = Vector2(0, -26)
	b.set_meta("fisico", float(jug.get("fisico", 100)))
	b.set_meta("forma", float(jug.get("forma", 60)))
	r.add_child(b)
	actualizar_barra(b, 0)

## RÓTULOS SIN AMONTONAR (MEGAPLAN fases 1 y 3): `filas` = diccionarios con
## "node" (los del estadio o los del motor jugable). Se proyectan a la pantalla
## y, si dos se tocan, queda el del jugador más cerca del balón; el que ya se
## veía tiene ventaja (si no, parpadeaban al cruzarse).
static func despejar_rotulos(filas: Array, cam: Camera3D, balon_pos: Vector3, alto_pantalla: float) -> void:
	if not mostrar_nombres or cam == null:
		return
	var lista: Array = []
	for f: Dictionary in filas:
		var n: Node3D = f.get("node")
		if not is_instance_valid(n) or not n.has_node(ROTULO) or not n.visible:
			continue
		var rot := n.get_node(ROTULO) as Label3D
		if cam.is_position_behind(rot.global_position):
			rot.visible = false
			continue
		lista.append([n.global_position.distance_to(balon_pos) * (0.75 if rot.visible else 1.0), rot])
	lista.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var k := alto_pantalla / (2.0 * tan(deg_to_rad(cam.fov) * 0.5))
	var puestos: Array[Rect2] = []
	for e: Array in lista:
		var rot: Label3D = e[1]
		var c := cam.unproject_position(rot.global_position)
		var px := rot.pixel_size * k
		var caja := Rect2(c - Vector2(rot.text.length() * 0.3 * rot.font_size * px, 0.5 * rot.font_size * px),
			Vector2(rot.text.length() * 0.6 * rot.font_size * px, 1.9 * rot.font_size * px))
		var choca := false
		for q: Rect2 in puestos:
			if q.grow(-2.0).intersects(caja):
				choca = true
				break
		rot.visible = not choca
		if not choca:
			puestos.append(caja)

static func _col(v, por_defecto: Color) -> Color:
	if typeof(v) == TYPE_STRING and str(v).begins_with("#"):
		return Color(str(v))
	return por_defecto

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

static func _es_equipacion(m: Material) -> bool:
	return m is ShaderMaterial and (m as ShaderMaterial).shader != null \
		and (m as ShaderMaterial).shader.resource_path.ends_with("equipacion_q.gdshader")

static func _con_brazalete(m: Material, color: Color) -> ShaderMaterial:
	var copia := (m as ShaderMaterial).duplicate() as ShaderMaterial
	copia.set_shader_parameter("acc_brazalete", Color(color, 1.0))
	return copia

## Pone el brazalete en el brazo izquierdo (uniforme `acc_brazalete` de
## `equipacion_q.gdshader`) en todas las mallas vestidas del jugador.
## El material de equipación está en caché (`VestidorQ`) y lo comparten otros:
## al capitán se le pone una COPIA, para no ponérselo a nadie más.
static func poner_brazalete(nodo: Node, color: Color) -> void:
	for mi in nodo.find_children("*", "MeshInstance3D", true, false):
		var g := mi as MeshInstance3D
		if _es_equipacion(g.material_override):
			g.material_override = _con_brazalete(g.material_override, color)
		for k in g.get_surface_override_material_count():
			if _es_equipacion(g.get_surface_override_material(k)):
				g.set_surface_override_material(k, _con_brazalete(g.get_surface_override_material(k), color))

func _apply_material(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in range(mi.get_surface_override_material_count()):
			mi.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_material(child, mat)

## Un jugador, con el modelo realista si se puede y con el de respaldo si no.
func _crear_jugador(root: Node3D, jid: String, puesto: String, img_kit: String,
		c1: Color, c2: Color, estilo: String, dorsal: int, piel: Color, pelo: Color,
		barba: int, color_liso: Color = Color(0, 0, 0, 0), jug: Dictionary = {}) -> Dictionary:
	if not usando_respaldo and USAR_MODELO_Q:
		var dq: Dictionary = FutbolistaQ.crear(altura_de(jug, jid, puesto), "male")
		if not dq.is_empty():
			root.add_child(dq["nodo"])
			FutbolistaQ.terminar(dq, true)
			## Menos músculo que el modelo base (13-10-2026) y, desde el 21-10,
			## la complexión de cada uno según su físico (M-081).
			if jug.is_empty() or puesto == "ARB":
				PersonajeDT.adelgazar(dq)
			else:
				PersonajeDT.cuerpo_futbolista(dq, jug, jid)
			## Equipación pintada sobre el cuerpo (camiseta con su estilo,
			## pantalón, medias, botines); la ropa teñida de antes queda solo
			## como respaldo si faltara la máscara.
			var pantalon := color_liso if puesto == "ARB" else Color(0, 0, 0, 0)
			## La equipación completa del club (diseñador), salvo arquero y
			## árbitro, que visten la suya.
			var kx: Dictionary = {} if puesto in ["POR", "ARB"] else _kit_x
			if not VestidorQ.vestir_equipacion(dq, c1, c2, estilo, piel, pelo, pantalon, Color(0, 0, 0, 0), false, kx, dorsal):
				VestidorQ.vestir(dq, c1)
			## EL BRAZALETE DEL CAPITÁN (M-073, 21-10): el shader lo tenía pero nadie
			## se lo ponía. Amarillo, o blanco si la camiseta ya es amarilla.
			if bool(jug.get("capitan", false)) and puesto != "ARB":
				var amarilla := c1.s > 0.3 and absf(c1.h - 0.14) < 0.06
				poner_brazalete(dq["nodo"], Color("ffffff") if amarilla else Color("ffd600"))
			## Pelo, barba y cejas, con el mismo corte que su retrato 2D.
			var look_j = jug.get("look")
			var corte := "corto"
			if typeof(look_j) == TYPE_DICTIONARY and look_j.get("pelo") is String:
				corte = look_j["pelo"]
			## Barba 3D solo para las barbas completas del retrato (1, 4 y 6):
			## bigote, perilla o barba de días no son esa malla.
			PeloQ.poner(dq, corte, pelo, barba in [1, 4, 6])
			## Y su cara: los rasgos del retrato (o la foto real) moldeados
			## sobre la cabeza. Después del pelo: con foto esconde las cejas y
			## la barba 3D.
			if typeof(look_j) == TYPE_DICTIONARY:
				var datos_cara := {"look": look_j, "foto": String(jug.get("foto", ""))}
				## Sin foto (ficticios, reales sin foto): una cara y un corte de
				## la biblioteca modular, siempre los mismos para el mismo id.
				if String(datos_cara["foto"]) == "" and BibliotecaCaras.hay() and puesto != "ARB":
					datos_cara["biblio"] = BibliotecaCaras.para(jid, piel, pelo)
				VestidorQ.poner_cara(dq, datos_cara, piel)
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
##
## `kit` (17-10-2026, M-072): la camiseta del trío que eligió
## `Puente3D.kit_arbitro` para que contraste con los dos equipos. Vacío = de
## negro, como siempre.
func spawn_arbitros(root: Node3D, kit: Dictionary = {}) -> Array:
	var camiseta := Color(String(kit.get("c1", "#111216")))
	var ribete := Color(String(kit.get("c2", "#e6d91a")))
	var pantalon := Color(String(kit.get("pantalon", "#121217")))
	var puestos := [
		{"id": "arbitro", "pos": Vector3(6.0, 0, 8.0), "rot": -0.6, "alto": 1.80},
		{"id": "linea_a", "pos": Vector3(-36.5, 0, -22.0), "rot": PI * 0.5, "alto": 1.78},
		{"id": "linea_b", "pos": Vector3(36.5, 0, 22.0), "rot": -PI * 0.5, "alto": 1.78},
	]
	var out: Array = []
	for p in puestos:
		var d := _crear_jugador(root, str(p["id"]), "ARB", "", camiseta,
			ribete, "liso", 0, Color(0.82, 0.63, 0.5), Color(0.16, 0.12, 0.09), 0,
			Color(pantalon, 1.0))
		if d.is_empty():
			continue
		var n: Node3D = d["nodo"]
		n.position = p["pos"]
		n.rotation.y = float(p["rot"])
		out.append({"node": n, "anim": d["anim"], "id": p["id"], "jugador": {},
			"base_pos": p["pos"], "slot_code": "ARB", "es_local": true,
			"realista": d["realista"], "arbitro": true})
	return out
