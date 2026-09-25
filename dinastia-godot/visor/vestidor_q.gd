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
## complejo -no es una foto de frente simple como el modelo viejo (ver
## `Vestidor.gd`, "EL GOLPE DE SUERTE")-, asi que no hay garantia de que
## calce con diseños mas elaborados (rayas, logos). Camino confiable: la
## misma tecnica de retinado que ya usa `Vestidor._retenir()` para la piel,
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

## Retine la textura base hacia `color`, igual que `Vestidor._retenir()`:
## la tela clara va al color pedido, el cuero oscuro va a una sombra del
## MISMO color -no queda cafe-. Cacheada por color exacto.
static func _textura_recoloreada(color: Color) -> ImageTexture:
	var clave := color.to_html(false)
	if _cache_textura.has(clave):
		return _cache_textura[clave]
	var base := Image.load_from_file("res://assets/characters/quaternius/ropa/T_Peasant_BaseColor.png")
	if base == null:
		return null
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

static func _mallas(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_mallas(c))
	return out
