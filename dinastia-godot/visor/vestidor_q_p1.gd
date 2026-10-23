extends RefCounted
## (Parte 1 de 3 de `vestidor_q.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `vestidor_q.gd`, conserva la clase.)

## Viste a `FutbolistaQ` con una camiseta de verdad -pieza "Peasant" del pack
## gratis "Modular Character Outfits - Fantasy" de Quaternius (mismo
## esqueleto que "Universal Base Characters", confirmado hueso por hueso:
## `neck_01`/`spine_01/02/03` caen en la misma posicion en ambos .gltf-.
##
## LA FORMA NO ES PERFECTA -tiene cinturon con hebilla y cuello en V, cosas
## de una tunica medieval, no de una camiseta deportiva- pero la geometria
## (mangas, torso, no hay malla de camiseta separada en el cuerpo base) es lo
## unico gratis y compatible con este esqueleto que se encontro. Verificado
## con capturas reales que el resultado, coloreado, se lee como camiseta con
## detalle en vez de disfraz -ver LEEME.md, 21-9-2026.
##
## COLOR PLANO, NO FOTO REAL: se probo pegar una foto real de equipacion
## directo (`recursos/equipaciones/`) y con un diseño simple (Colo-Colo,
## blanco con franja) se veia razonable, pero el atlas UV de esta prenda es
## complejo, asi que no hay garantia de que calce con diseños mas elaborados
## (rayas, logos). Camino confiable: retinado por luminancia,
## aplicada a la tela Y al cuero (antes solo la tela, el cuero quedaba cafe
## y se leia a disfraz -corregido a pedido del usuario, "aun se puede ver
## mejor").

## Las 4 piezas modulares -a pedido del usuario ("faltan partes sin camiseta,
## y nos faltan los short y los zapatos"), el torso solo dejaba hombros y
## brazos al descubierto. Mismo esqueleto las 4, mismo mecanismo de apego.
const PIEZAS_MALE := [
	"res://assets/characters/quaternius/ropa/Male_Peasant_Body.gltf",
	"res://assets/characters/quaternius/ropa/Male_Peasant_Arms.gltf",
	"res://assets/characters/quaternius/ropa/Male_Peasant_Legs.gltf",
	"res://assets/characters/quaternius/ropa/Male_Peasant_Feet.gltf",
]

## LA EQUIPACIÓN DE VERDAD (25-9-2026). En vez de colgar las 4 piezas de ropa
## medieval y teñirlas -que dejaba a los jugadores casi negros (marrón × color
## del club) y con la piel asomando por los desgarros de la túnica-, la
## camiseta, el pantalón, las medias y los botines se pintan SOBRE el propio
## cuerpo con `equipacion_q.gdshader`. Ver `herramientas/mascara_equipacion.py`
## para cómo se sacó, de la geometría del modelo, qué píxel es cada prenda.
## Además ahorra 4 mallas con esqueleto por jugador y el barrido de 16 millones
## de píxeles en GDScript que costaba cada color de club nuevo.
const SHADER_EQUIPACION := "res://visor/equipacion_q.gdshader"
const MASCARA := "res://assets/characters/quaternius/equipacion_mascara.png"
const COORDS := "res://assets/characters/quaternius/equipacion_coords.png"
const MATERIAL_CUERPO := "MI_Superhero_Male"
const MATERIAL_CEJAS := "MI_Hair_1"
const MATERIAL_OJOS := "MI_Eyes"
const DIST_OJOS := 35.0
## Tono medio de la piel de la textura original (sRGB), medido sobre los
## píxeles que no son prenda: para teñirla al tono de cada jugador.
const PIEL_REF := Color(0.6456, 0.4475, 0.3127)
## Materiales ya montados por combinación de colores/estilo/piel: los once de
## un equipo comparten material y el motor los puede agrupar.
static var _cache_equipacion := {}
## LA ROPA APARTE (`RopaSeparada`, 26-9-2026): camiseta, pantalón y medias como
## mallas propias con volumen, en vez de pintadas sobre la piel. Se enciende
## en el diseñador y en Ajustes (en el partido cuesta tres mallas más por
## jugador).
static var ropa_aparte := false

static var _packed_male: Array = []
## cache de texturas recoloreadas por color exacto, para no repetir el
## barrido de 16M pixeles por cada jugador del mismo club.
static var _cache_textura := {}

## LOS BOTINES SE NOTAN (14-10-2026): sin diseño de club todos llevaban el negro
## clásico. Ahora cada jugador (dorsal + color de su club) calza uno de una
## docena de modelos, la mayoría de colores vivos; porteros y árbitro, negro.
const BOTINES_VARIADOS := ["clasico", "blanco", "rayo", "fuego", "hielo", "neon", "talon_rojo",
	"punta_plata", "coral", "solar", "glaciar", "clasico", "blanco", "esmeralda"]

## LA CARA 2D MOLDEADA SOBRE EL MODELO 3D (29-9-2026). Llamar DESPUÉS de
## `vestir_equipacion`. `datos` sale de `Cara.datos_3d()` (vía `Puente3D`):
## {"look": aspecto del retrato, "foto": ruta del retrato real (opcional)}.
## Cada jugador lleva su propio material de cuerpo (el de la equipación, con
## la cara encima) y sus ojos. Devuelve false si no pudo.
const SHADER_OJOS := "res://visor/ojos_q.gdshader"
## La misma compensación de saturación que `cara_malla.gdshader`.
const SATURACION_PIEL := 1.0
## Compensación del "pie" del mapeo de tonos (ver `cara_malla.gdshader`).
const COMPENSAR_PIEL := 1.6
static var _cache_cara := {}

static var _mallas_reposo: Dictionary = {}

static func _botin_de(dorsal: int, c1: Color) -> String:
	if dorsal <= 0:
		return "clasico"
	return BOTINES_VARIADOS[absi(dorsal * 31 + int(c1.r8) * 7 + int(c1.b8)) % BOTINES_VARIADOS.size()]

static func _cargar_male() -> Array:
	if _packed_male.is_empty():
		for ruta in PIEZAS_MALE:
			var p: PackedScene = load(ruta)
			if p != null:
				_packed_male.append(p)
	return _packed_male

## Retine la textura base hacia `color`, por luminancia:
## la tela clara va al color pedido, el cuero oscuro va a una sombra del
## MISMO color -no queda cafe-. Cacheada por color exacto.
static func _textura_recoloreada(color: Color) -> ImageTexture:
	var clave := color.to_html(false)
	if _cache_textura.has(clave):
		return _cache_textura[clave]
	## Por el recurso importado, no con `Image.load_from_file()`: en el juego
	## exportado el .png original no viaja (solo su `.ctex`) y aquello fallaba
	## sin avisar -Godot lo advierte al cargar: "this will not work on export"-.
	var tex_base: Texture2D = load("res://assets/characters/quaternius/ropa/T_Peasant_BaseColor.png")
	if tex_base == null:
		return null
	var base := tex_base.get_image()
	if base == null:
		return null
	if base.is_compressed():
		base.decompress()
	base.clear_mipmaps()
	base.convert(Image.FORMAT_RGBA8)
	var datos := base.get_data()

	## Mismas dos referencias medidas una vez -21-9-2026, `pruebas/
	## recolorear_tunica.gd`- sobre la textura original: tela clara y cuero
	## oscuro. Constantes, no remedidas cada vez: la textura de origen no
	## cambia entre llamadas.
	const REF_CLARA := Vector3(0.578142, 0.553347, 0.44582)
	const REF_OSCURA := Vector3(0.218756, 0.146647, 0.068617)
	var objetivo := Vector3(color.r, color.g, color.b)
	## La sombra/ribete: el mismo color pero bien oscurecido -un cuarto de
	## luminosidad-, para que lea como pliegue/costura, no como otro material.
	var objetivo_sombra := objetivo * 0.30
	var kr: float = objetivo.x / maxf(REF_CLARA.x, 0.02)
	var kg: float = objetivo.y / maxf(REF_CLARA.y, 0.02)
	var kb: float = objetivo.z / maxf(REF_CLARA.z, 0.02)
	var kr2: float = objetivo_sombra.x / maxf(REF_OSCURA.x, 0.02)
	var kg2: float = objetivo_sombra.y / maxf(REF_OSCURA.y, 0.02)
	var kb2: float = objetivo_sombra.z / maxf(REF_OSCURA.z, 0.02)

	for i in range(0, datos.size(), 4):
		var cr := datos[i] / 255.0
		var cg := datos[i + 1] / 255.0
		var cb := datos[i + 2] / 255.0
		var l: float = 0.2126 * cr + 0.7152 * cg + 0.0722 * cb
		if l > 0.30:
			datos[i] = int(clampf(cr * kr, 0.0, 1.0) * 255.0)
			datos[i + 1] = int(clampf(cg * kg, 0.0, 1.0) * 255.0)
			datos[i + 2] = int(clampf(cb * kb, 0.0, 1.0) * 255.0)
		else:
			datos[i] = int(clampf(cr * kr2, 0.0, 1.0) * 255.0)
			datos[i + 1] = int(clampf(cg * kg2, 0.0, 1.0) * 255.0)
			datos[i + 2] = int(clampf(cb * kb2, 0.0, 1.0) * 255.0)

	var nueva := Image.create_from_data(base.get_width(), base.get_height(), false, Image.FORMAT_RGBA8, datos)
	## OPTIMIZACION (21-9-2026): la textura de origen es 4096x4096 -64MB SIN
	## comprimir cada una-, pero esta prenda en pantalla nunca ocupa mas de
	## unos cientos de pixeles, ni en un primer plano. Medido con `pruebas/
	## medir_texturas.gd`: 9 texturas de 4096x4096 sumaban 576MB, la mayoria
	## de ellas ESTA -una por cada color de club distinto, generada en tiempo
	## de ejecucion-. Reducir a 1024 (16x menos memoria por textura) no se
	## nota jugando, se nota en el perfil.
	nueva.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
	nueva.generate_mipmaps()
	var tex := ImageTexture.create_from_image(nueva)
	_cache_textura[clave] = tex
	return tex

static func _mallas(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_mallas(c))
	return out

## Le pone la ropa a un `FutbolistaQ` ya creado -llamar despues de
## `FutbolistaQ.terminar()`, con el esqueleto real ya en el arbol-. `color`:
## el color primario del club (mismo `c1` que ya usa `PlayerSpawner`). Pega
## las 4 piezas (torso/brazos/piernas/pies) -a pedido del usuario, el torso
## solo dejaba hombros, brazos, piernas y pies al descubierto.
static func vestir(d: Dictionary, color: Color) -> void:
	var esq_cuerpo: Skeleton3D = d.get("esqueleto")
	if esq_cuerpo == null:
		return
	var piezas := _cargar_male()
	if piezas.is_empty():
		return
	var tex := _textura_recoloreada(color)

	for packed in piezas:
		var instancia: Node3D = (packed as PackedScene).instantiate()
		## La prenda trae su PROPIO Skeleton3D -no sirve, es el cuerpo el que
		## tiene que animarla-: solo interesan sus MeshInstance3D, reapuntadas
		## al esqueleto real del jugador. Confirmado antes de escribir esto
		## (no supuesto) que ambos .gltf comparten los mismos nombres de
		## hueso (`neck_01`, `spine_01/02/03`...), asi que no hace falta
		## retargeting, solo reapuntar `.skeleton`.
		for malla_v in _mallas(instancia):
			var malla: MeshInstance3D = malla_v
			malla.get_parent().remove_child(malla)
			## Hija del propio Skeleton3D del cuerpo -mismo patron que ya usa
			## el body mesh original- para heredar la escala real del jugador
			## (`modelo.scale` en `FutbolistaQ.terminar()`) sin volver a
			## aplicarla a mano: colgarla de la raiz del jugador, que NO
			## tiene esa escala, la dejaba del porte equivocado.
			esq_cuerpo.add_child(malla)
			malla.skeleton = malla.get_path_to(esq_cuerpo)
			## BUG REAL VISTO EN CAPTURA (21-9-2026, el usuario: "falta que se
			## acople mejor al cuerpo, hay partes sin camiseta"): la ropa y la
			## piel del cuerpo desnudo ocupan casi la misma superficie, y sin
			## nada que las separe compiten por que malla se dibuja encima -
			## sale piel a parches, no una costura limpia. Un infladito
			## uniforme empuja la ropa un pelin hacia afuera del cuerpo, el
			## mismo truco de siempre para esto (no es exclusivo de Godot).
			malla.scale = Vector3.ONE * 1.015
			if tex != null:
				for s in range(malla.mesh.get_surface_count() if malla.mesh else 0):
					var m := malla.get_active_material(s)
					## `Male_Peasant_Arms` trae DOS materiales -la tela
					## ("MI_Peasant") y la piel de la mano ("MI_Regular_Male")-.
					## Solo la tela se retine: pintarle el color del club a
					## la piel de la mano tambien seria un bug nuevo, no un
					## acierto -las manos quedarian del color de la camiseta.
					var nombre := m.resource_name if m != null else ""
					if nombre != "MI_Peasant":
						continue
					var sm: StandardMaterial3D = (m as StandardMaterial3D).duplicate() if m is StandardMaterial3D else StandardMaterial3D.new()
					sm.albedo_texture = tex
					malla.set_surface_override_material(s, sm)
		instancia.queue_free()

static func _material_liso(color: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rugosidad
	return m

## LA ROPA TAPA LOS MÚSCULOS (26-9-2026, pedido: "que la ropa le tape los
## músculos"). El cuerpo del pack es de superhéroe: pectorales, abdominales y
## bíceps marcados. Pintada encima, la camiseta parecía body-paint. Aquí se
## calcula, UNA vez por malla, la misma superficie ALISADA (suavizado de
## Taubin, que no encoge el volumen): para cada vértice, su normal alisada y
## cuánto habría que sacarlo hacia fuera para tapar el hueco entre músculos.
## El shader lo usa solo donde hay tela. Devuelve [CUSTOM0, CUSTOM1]:
## CUSTOM0 = normal alisada (xyz) + relleno (w); CUSTOM1 = normal de reposo.
static func _alisado(pos: PackedVector3Array, nor: Variant, idx: Variant) -> Array:
	var n := pos.size()
	var c0 := PackedFloat32Array()
	var c1 := PackedFloat32Array()
	c0.resize(n * 4)
	c1.resize(n * 3)
	if not (nor is PackedVector3Array) or not (idx is PackedInt32Array) or n == 0:
		return [c0, c1]
	var normales: PackedVector3Array = nor
	var indices: PackedInt32Array = idx
	## Soldar los vértices duplicados en las costuras de UV (misma posición).
	var id_de := {}
	var soldado := PackedInt32Array()
	soldado.resize(n)
	var unicos := PackedVector3Array()
	for i in n:
		var k: Vector3i = Vector3i((pos[i] * 10000.0).round())
		if not id_de.has(k):
			id_de[k] = unicos.size()
			unicos.append(pos[i])
		soldado[i] = int(id_de[k])
	var m := unicos.size()
	var vecinos: Array[PackedInt32Array] = []
	vecinos.resize(m)
	for t in range(0, indices.size() - 2, 3):
		var a := soldado[indices[t]]
		var b := soldado[indices[t + 1]]
		var c := soldado[indices[t + 2]]
		for par: Array in [[a, b], [b, c], [c, a]]:
			var u: int = par[0]
			var w: int = par[1]
			if not vecinos[u].has(w):
				vecinos[u].append(w)
			if not vecinos[w].has(u):
				vecinos[w].append(u)
	## Taubin: un paso que encoge (lambda) y otro que infla (mu).
	var p := unicos.duplicate()
	## 13-10-2026: 24 → 64 pasos; con 24 la camiseta aún marcaba abdominales.
	var t0 := Time.get_ticks_msec()
	for it in 110:
		var f: float = 0.62 if it % 2 == 0 else -0.5
		var q := p.duplicate()
		for i in m:
			var vs: PackedInt32Array = vecinos[i]
			if vs.is_empty():
				continue
			var media := Vector3.ZERO
			for v in vs:
				media += p[v]
			media /= float(vs.size())
			q[i] = p[i] + (media - p[i]) * f
		p = q
	print_verbose("alisado: %d ms" % (Time.get_ticks_msec() - t0))
	## Normales de la superficie alisada.
	var ns := PackedVector3Array()
	ns.resize(m)
	for t in range(0, indices.size() - 2, 3):
		var a2 := soldado[indices[t]]
		var b2 := soldado[indices[t + 1]]
		var c2 := soldado[indices[t + 2]]
		var fn := (p[b2] - p[a2]).cross(p[c2] - p[a2])
		ns[a2] += fn
		ns[b2] += fn
		ns[c2] += fn
	for i in n:
		var w2 := soldado[i]
		var nr: Vector3 = normales[i]
		var sn := ns[w2].normalized()
		## El orden de los triángulos decide el signo: que apunte como la real.
		if sn.dot(nr) < 0.0:
			sn = -sn
		var relleno: float = (p[w2] - pos[i]).dot(nr)
		c0[i * 4] = sn.x
		c0[i * 4 + 1] = sn.y
		c0[i * 4 + 2] = sn.z
		## 13-10-2026: también hacia dentro (los pectorales y bíceps se marcaban).
		c0[i * 4 + 3] = clampf(relleno, -0.035, 0.03)
		c1[i * 3] = nr.x
		c1[i * 3 + 1] = nr.y
		c1[i * 3 + 2] = nr.z
	return [c0, c1]

## LOS NIVELES DE DETALLE DE LA MALLA ORIGINAL (17-10-2026, MEGA AUDITORÍA 2
## punto 14). El importador genera para el cuerpo 8 versiones más livianas (de
## 12.566 triángulos a 48) y Godot elige la que toca según lo que mide en
## pantalla. Al rehacer la malla con `add_surface_from_arrays(..., {}, ...)` se
## perdían: los 22 jugadores, árbitros y banquillo se dibujaban SIEMPRE
## completos, también a 50 m (≈1 M de los 1,8 M de triángulos del partido). Los
## índices de cada nivel se copian tal cual: los vértices no cambian de orden.
static func lods_de(original: ArrayMesh, s: int) -> Dictionary:
	var r := {}
	var d := RenderingServer.mesh_get_surface(original.get_rid(), s)
	var lods: Array = d.get("lods", [])
	if lods.is_empty():
		return r
	var n_idx := int(d.get("index_count", 0))
	var bytes_idx: PackedByteArray = d.get("index_data", PackedByteArray())
	if n_idx <= 0 or bytes_idx.is_empty():
		return r
	var ancho := bytes_idx.size() / n_idx  # 2 (16 bits) o 4 (32 bits)
	for l: Dictionary in lods:
		var datos: PackedByteArray = l.get("index_data", PackedByteArray())
		var idx := PackedInt32Array()
		if ancho == 2:
			var u16 := PackedInt32Array()
			u16.resize(datos.size() / 2)
			for i in u16.size():
				u16[i] = datos.decode_u16(i * 2)
			idx = u16
		else:
			idx = datos.to_int32_array()
		if idx.size() >= 3:
			r[float(l.get("edge_length", 0.0))] = idx
	return r

## Cambia la malla del cuerpo por una copia con la pose de reposo en UV2 y
## COLOR. Se hace una vez por malla original (todos los jugadores comparten la
## misma copia).
static func _con_reposo(mi: MeshInstance3D, superficie: int) -> void:
	var original := mi.mesh as ArrayMesh
	if original == null or original.has_meta("con_reposo"):
		return
	var id := original.get_instance_id()
	if _mallas_reposo.has(id):
		mi.mesh = _mallas_reposo[id]
		return
	var nueva := ArrayMesh.new()
	nueva.blend_shape_mode = original.blend_shape_mode
	for b in original.get_blend_shape_count():
		nueva.add_blend_shape(original.get_blend_shape_name(b))
	for s in original.get_surface_count():
		var arr := original.surface_get_arrays(s)
		if s == superficie:
			var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var uv2 := PackedVector2Array()
			var col := PackedColorArray()
			uv2.resize(pos.size())
			col.resize(pos.size())
			for i in pos.size():
				var p: Vector3 = pos[i]
				uv2[i] = Vector2(p.x, p.y)
				col[i] = Color(clampf((p.z + 0.25) / 0.5, 0.0, 1.0), 0.0, 0.0, 1.0)
			arr[Mesh.ARRAY_TEX_UV2] = uv2
			arr[Mesh.ARRAY_COLOR] = col
			var liso := _alisado(pos, arr[Mesh.ARRAY_NORMAL], arr[Mesh.ARRAY_INDEX])
			arr[Mesh.ARRAY_CUSTOM0] = liso[0]
			arr[Mesh.ARRAY_CUSTOM1] = liso[1]
		var formas := original.surface_get_blend_shape_arrays(s)
		var banderas := 0
		if s == superficie:
			banderas = (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) \
				| (Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT)
		nueva.add_surface_from_arrays(original.surface_get_primitive_type(s), arr, formas, lods_de(original, s), banderas)
		## Sin pantalla (banco headless) el servidor falso no guarda superficies.
		if nueva.get_surface_count() <= s:
			return
		nueva.surface_set_material(s, original.surface_get_material(s))
		nueva.surface_set_name(s, original.surface_get_name(s))
	nueva.set_meta("con_reposo", true)
	_mallas_reposo[id] = nueva
	mi.mesh = nueva

## Ocho niveles por canal: dos jugadores de piel casi igual comparten material.
static func _piel_cuantizada(piel: Color) -> String:
	return "%d%d%d" % [int(piel.r * 8.0), int(piel.g * 8.0), int(piel.b * 8.0)]

## El tono del jugador sobre el de la textura, en espacio lineal (el shader
## multiplica ya en lineal). Acotado: un tono extremo no puede quemar la piel.
static func _tinte(piel: Color) -> Vector3:
	var a := piel.srgb_to_linear()
	var b := PIEL_REF.srgb_to_linear()
	## Hasta 3,2: una piel clara de foto con flash (224,164,129) pide 2,7 en el
	## azul; con el tope viejo de 1,8 el cuello salía amarillo pálido al lado
	## de la cara real.
	return Vector3(clampf(a.r / b.r, 0.15, 3.2), clampf(a.g / b.g, 0.15, 3.2), clampf(a.b / b.b, 0.15, 3.2))
