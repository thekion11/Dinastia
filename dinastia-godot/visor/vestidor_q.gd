class_name VestidorQ
extends RefCounted
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
## Tono medio de la piel de la textura original (sRGB), medido sobre los
## píxeles que no son prenda: para teñirla al tono de cada jugador.
const PIEL_REF := Color(0.6456, 0.4475, 0.3127)
## Materiales ya montados por combinación de colores/estilo/piel: los once de
## un equipo comparten material y el motor los puede agrupar.
static var _cache_equipacion := {}

static var _packed_male: Array = []
## cache de texturas recoloreadas por color exacto, para no repetir el
## barrido de 16M pixeles por cada jugador del mismo club.
static var _cache_textura := {}

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

## Pinta la equipación sobre un `FutbolistaQ` ya terminado. Devuelve false si
## no pudo (sin shader o sin máscara) y quien llama cae a `vestir()`.
##
## `pantalon`/`medias` con alfa 0 = automáticos: medias del color principal,
## pantalón del secundario en una camiseta lisa y del principal en una con
## dibujo (Boca: azul con franja oro y pantalón azul; Colo-Colo: blanca lisa y
## pantalón negro).
static func vestir_equipacion(d: Dictionary, c1: Color, c2: Color, estilo: String,
		piel: Color, pelo: Color, pantalon: Color = Color(0, 0, 0, 0),
		medias: Color = Color(0, 0, 0, 0), largo: bool = false) -> bool:
	var modelo: Node = d.get("modelo")
	if modelo == null or not ResourceLoader.exists(SHADER_EQUIPACION) \
			or not ResourceLoader.exists(MASCARA) or not ResourceLoader.exists(COORDS):
		return false
	var cuerpo: MeshInstance3D = null
	var superficie := -1
	for mv in _mallas(modelo):
		var mi: MeshInstance3D = mv
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s)
			if m == null:
				continue
			match m.resource_name:
				MATERIAL_CUERPO:
					cuerpo = mi
					superficie = s
				MATERIAL_CEJAS:
					mi.set_surface_override_material(s, _material_liso(pelo, 0.9))
				MATERIAL_OJOS:
					## Las texturas de ojos del pack no vinieron en el repo:
					## sin esto, blanco puro de fábrica y mirada de maniquí.
					mi.set_surface_override_material(s, _material_liso(Color(0.12, 0.09, 0.07), 0.3))
	if cuerpo == null:
		return false
	var estilos: Variant = Datos.tabla("KITS")
	var i_estilo: int = maxi(0, (estilos as Array).find(estilo)) if estilos is Array else 0
	if pantalon.a == 0.0:
		pantalon = c2 if i_estilo == 0 else c1
	if medias.a == 0.0:
		medias = c1
	var clave := "%s|%s|%d|%s|%s|%s|%s" % [c1.to_html(false), c2.to_html(false), i_estilo,
		pantalon.to_html(false), medias.to_html(false), _piel_cuantizada(piel), largo]
	var mat: ShaderMaterial = _cache_equipacion.get(clave)
	if mat == null:
		var original := cuerpo.get_active_material(superficie) as BaseMaterial3D
		mat = ShaderMaterial.new()
		mat.shader = load(SHADER_EQUIPACION)
		if original != null and original.albedo_texture != null:
			mat.set_shader_parameter("piel_tex", original.albedo_texture)
		if original != null and original.normal_enabled and original.normal_texture != null:
			mat.set_shader_parameter("normal_tex", original.normal_texture)
			mat.set_shader_parameter("usa_normal", true)
		mat.set_shader_parameter("mascara", load(MASCARA))
		mat.set_shader_parameter("coords", load(COORDS))
		mat.set_shader_parameter("color1", c1)
		mat.set_shader_parameter("color2", c2)
		mat.set_shader_parameter("color_pantalon", pantalon)
		mat.set_shader_parameter("color_medias", medias)
		mat.set_shader_parameter("estilo", i_estilo)
		mat.set_shader_parameter("tinte_piel", _tinte(piel))
		mat.set_shader_parameter("largo", largo)
		_cache_equipacion[clave] = mat
	cuerpo.set_surface_override_material(superficie, mat)
	return true

## El tono del jugador sobre el de la textura, en espacio lineal (el shader
## multiplica ya en lineal). Acotado: un tono extremo no puede quemar la piel.
static func _tinte(piel: Color) -> Vector3:
	var a := piel.srgb_to_linear()
	var b := PIEL_REF.srgb_to_linear()
	return Vector3(clampf(a.r / b.r, 0.15, 1.8), clampf(a.g / b.g, 0.15, 1.8), clampf(a.b / b.b, 0.15, 1.8))

## Ocho niveles por canal: dos jugadores de piel casi igual comparten material.
static func _piel_cuantizada(piel: Color) -> String:
	return "%d%d%d" % [int(piel.r * 8.0), int(piel.g * 8.0), int(piel.b * 8.0)]

static func _material_liso(color: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rugosidad
	return m

static func _mallas(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_mallas(c))
	return out
