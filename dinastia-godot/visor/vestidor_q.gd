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
## LA ROPA APARTE (`RopaSeparada`, 26-9-2026): camiseta, pantalón y medias como
## mallas propias con volumen, en vez de pintadas sobre la piel. Se enciende
## en el diseñador y en Ajustes (en el partido cuesta tres mallas más por
## jugador).
static var ropa_aparte := false

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
		medias: Color = Color(0, 0, 0, 0), largo: bool = false, kit_x: Dictionary = {}, dorsal: int = 0) -> bool:
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
				MATERIAL_CUERPO, "MI_Superhero_Female":
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
	## REALISMO (26-9-2026): la posición de reposo de cada vértice, escrita en
	## la malla (UV2 = x,y; COLOR.r = z). Con ella el dibujo y los cortes de
	## las prendas se calculan exactos por píxel; con la textura de 8 bits de
	## antes salían en escalones de 7 mm.
	_con_reposo(cuerpo, superficie)
	var estilos: Variant = Datos.tabla("KITS")
	var i_estilo: int = maxi(0, (estilos as Array).find(estilo)) if estilos is Array else 0
	if pantalon.a == 0.0:
		pantalon = c2 if i_estilo == 0 else c1
	if medias.a == 0.0:
		medias = c1
	## EL DISEÑADOR (26-9-2026): sin equipación completa, se arma una con lo de
	## siempre (colores, estilo, pantalón y medias) para que TODO pase por el
	## mismo camino del shader.
	var kit := kit_x
	if kit.is_empty():
		kit = {"dis": estilo if DisenosKit.claves().has(estilo) else "liso",
			"cols": [c1.to_html(false), c2.to_html(false), c2.darkened(0.35).to_html(false), "ffffff", "111111"],
			"trim": 1, "num": "ffffff",
			"pant": {"dis": "liso", "c1": pantalon.to_html(false), "c2": c1.to_html(false)},
			"med": {"dis": "lisas", "c1": medias.to_html(false), "c2": c2.to_html(false)},
			"bot": {"mod": "clasico"}, "acc": {}}
	var clave := "%s|%s|%d|%s|%s|%s|%s|%d|%d" % [c1.to_html(false), c2.to_html(false), i_estilo,
		pantalon.to_html(false), medias.to_html(false), _piel_cuantizada(piel), largo, hash(kit), dorsal]
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
		mat.set_shader_parameter("usa_reposo", (cuerpo.mesh as ArrayMesh) != null and cuerpo.mesh.has_meta("con_reposo"))
		var un := DisenosKit.uniforms(kit, dorsal)
		for k: String in un:
			mat.set_shader_parameter(k, un[k])
		_cache_equipacion[clave] = mat
	if ropa_aparte and (cuerpo.mesh as ArrayMesh) != null and cuerpo.mesh.has_meta("con_reposo"):
		## El cuerpo, sin inflar (las prendas ya tienen su volumen).
		var k2 := clave + "|aparte"
		var mat_c: ShaderMaterial = _cache_equipacion.get(k2)
		if mat_c == null:
			mat_c = mat.duplicate() as ShaderMaterial
			mat_c.set_shader_parameter("holgura", 0.0)
			_cache_equipacion[k2] = mat_c
		cuerpo.set_surface_override_material(superficie, mat_c)
		RopaSeparada.vestir(cuerpo, superficie, mat)
		return true
	elif cuerpo.get_parent() != null:
		for h in cuerpo.get_parent().get_children():
			if h.has_meta("prenda_aparte"):
				h.queue_free()
	## Sin pantalla (banco headless) la malla no trae superficies.
	if superficie >= cuerpo.get_surface_override_material_count():
		return false
	cuerpo.set_surface_override_material(superficie, mat)
	return true

## LA CARA 2D MOLDEADA SOBRE EL MODELO 3D (29-9-2026). Llamar DESPUÉS de
## `vestir_equipacion`. `datos` sale de `Cara.datos_3d()` (vía `Puente3D`):
## {"look": aspecto del retrato, "foto": ruta del retrato real (opcional)}.
## Cada jugador lleva su propio material de cuerpo (el de la equipación, con
## la cara encima) y sus ojos. Devuelve false si no pudo.
const SHADER_OJOS := "res://visor/ojos_q.gdshader"
## La misma compensación de saturación que `cara_malla.gdshader`.
const SATURACION_PIEL := 0.92

## La misma normalización de exposición que `cara_malla.gdshader` (por la
## luminancia lineal de su piel en la foto).
static func exposicion_piel(lum: float) -> float:
	return clampf(0.55 * pow(lum, 0.6) / maxf(lum, 0.001), 0.75, 3.0)
static var _cache_cara := {}

static func poner_cara(d: Dictionary, datos: Dictionary, piel: Color) -> bool:
	var modelo: Node = d.get("modelo")
	var lk: Variant = datos.get("look")
	if modelo == null or not (lk is Dictionary):
		return false
	var ruta := String(datos.get("foto", ""))
	var foto: Texture2D = Cara.foto_de_ruta(ruta) if ruta != "" else null
	var af := _afin_foto(Cara.puntos_foto(ruta)) if foto != null else []
	var bi := int((lk as Dictionary).get("barba", 0))
	## IGUALITO A LA FOTO (29-9-2026): la foto trae sus propias cejas y su
	## barba; las mallas 3D encima duplicaban cejas y tapaban la barba real.
	## Y la foto se lleva al color de la piel del modelo (balance de blancos y
	## flash de cada fotógrafo): así no se nota dónde termina la foto.
	var tono_foto := Vector3.ONE
	## LA CARA DE VERDAD EN 3D (30-9-2026): si hay malla de su cara, va la
	## malla (forma y píxeles exactos de la foto) en vez de la proyección, y el
	## cuerpo toma el tono EXACTO de su piel en la foto.
	var nombre_foto := Cara.nombre_de_ruta(ruta) if ruta != "" else ""
	var con_malla := false
	if foto != null and CaraMalla.tiene(nombre_foto):
		var cara_hd := CaraMalla.foto(nombre_foto)
		var tono := CaraMalla.tono_piel(nombre_foto, cara_hd)
		if tono.a > 0.0:
			piel = tono
		if CaraMalla.poner(d, nombre_foto, cara_hd, piel) != null:
			con_malla = true
			_ocultar_cejas_y_barba(d.get("nodo", modelo))
			var pelo_foto := CaraMalla.color_pelo(nombre_foto)
			if pelo_foto.a > 0.0:
				_teñir_pelo(d.get("nodo", modelo), pelo_foto)
	if foto != null and not con_malla:
		if af.is_empty():
			foto = null
		else:
			_ocultar_cejas_y_barba(d.get("nodo", modelo))
			tono_foto = _ajuste_foto(foto, af, piel)
	## Sin foto usable: los rasgos del retrato.
	var rasgos: Texture2D = null if foto != null else Cara.textura_rasgos(lk)
	var barba: Texture2D = null if foto != null else Cara.textura_barba(lk)
	var iris := Color(String(Cara.IRIS[clampi(int((lk as Dictionary).get("ojos", 0)), 0, Cara.IRIS.size() - 1)]))
	var puesta := false
	for mv in _mallas(modelo):
		var mi: MeshInstance3D = mv
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var orig := mi.mesh.surface_get_material(s)
			var nombre := orig.resource_name if orig != null else ""
			var activo := mi.get_active_material(s)
			if activo is ShaderMaterial and (activo as ShaderMaterial).shader != null \
					and (activo as ShaderMaterial).shader.resource_path == SHADER_EQUIPACION:
				if not bool((activo as ShaderMaterial).get_shader_parameter("usa_reposo")):
					continue
				var clave := "%d|%d|%s|%s" % [activo.get_instance_id(), hash(lk), ruta, con_malla]
				var mc: ShaderMaterial = _cache_cara.get(clave)
				if mc == null:
					mc = (activo as ShaderMaterial).duplicate() as ShaderMaterial
					mc.set_shader_parameter("hay_cara", not con_malla)
					if con_malla:
						mc.set_shader_parameter("hay_malla", true)
						## El cuerpo, del color exacto de su piel en la foto.
						var pl := piel.srgb_to_linear()
						var v := Vector3(pl.r, pl.g, pl.b)
						var gris := v.dot(Vector3(0.2126, 0.7152, 0.0722))
						v = Vector3.ONE * gris + (v - Vector3.ONE * gris) * SATURACION_PIEL
						mc.set_shader_parameter("piel_foto", v * exposicion_piel(gris))
					elif foto != null:
						mc.set_shader_parameter("hay_foto", true)
						mc.set_shader_parameter("foto_tex", foto)
						mc.set_shader_parameter("foto_u", af[0])
						mc.set_shader_parameter("foto_v", af[1])
						mc.set_shader_parameter("foto_tono", tono_foto)
						mc.set_shader_parameter("foto_espejo", _lado_foto(Cara.puntos_foto(ruta)))
					else:
						mc.set_shader_parameter("cara_tex", rasgos)
						if barba != null:
							mc.set_shader_parameter("barba_tex", barba)
							mc.set_shader_parameter("barba_color", Color(String((lk as Dictionary).get("peloC", "#231a14"))))
							## Bajo la barba 3D (1, 4 y 6) solo una sombra de pelo.
							mc.set_shader_parameter("barba_fuerza", 0.55 if bi in [1, 4, 6] else 0.95)
					_cache_cara[clave] = mc
				mi.set_surface_override_material(s, mc)
				puesta = true
			elif nombre == MATERIAL_OJOS and con_malla:
				## Los ojos de la foto ya están en la malla de la cara.
				mi.visible = false
			elif nombre == MATERIAL_OJOS and ResourceLoader.exists(SHADER_OJOS):
				_con_reposo_simple(mi)
				if s >= mi.get_surface_override_material_count():
					continue
				var clave_o := "ojos|%s|%s|%s" % [iris.to_html(false), _piel_cuantizada(piel), ruta]
				var mo: ShaderMaterial = _cache_cara.get(clave_o)
				if mo == null:
					mo = ShaderMaterial.new()
					mo.shader = load(SHADER_OJOS)
					mo.set_shader_parameter("iris", iris)
					mo.set_shader_parameter("piel", piel)
					if foto != null:
						mo.set_shader_parameter("apertura", 0.78)
						mo.set_shader_parameter("blanco", 0.82)
					_cache_cara[clave_o] = mo
				mi.set_surface_override_material(s, mo)
	return puesta

## Si la foto es de tres cuartos, qué mitad mira a la cámara (-1 la izquierda
## de la imagen, 1 la derecha), o 0 si es de frente. La punta de la nariz se
## corre hacia el lado lejano (medido con 5 retratos: de frente < 0,02; tres
## cuartos 0,14-0,28).
static func _lado_foto(p: Array) -> int:
	if p.size() < 8:
		return 0
	var sep := absf(float(p[2]) - float(p[0]))
	if sep < 0.001:
		return 0
	var corrida := (float(p[6]) - (float(p[0]) + float(p[2])) * 0.5) / sep
	if corrida > 0.12:
		return -1
	if corrida < -0.12:
		return 1
	return 0

## Tiñe el pelo 3D (`PeloQ`) con el color de la foto (misma cuenta que
## `PeloQ._material`: la textura del pack es oscura y se aclara x1,7).
static func _teñir_pelo(raiz: Node, color: Color) -> void:
	var pelo := raiz.find_child("Pelo", true, false)
	if pelo == null:
		return
	for mv in _mallas(pelo):
		var mi: MeshInstance3D = mv
		var m := mi.material_override as StandardMaterial3D
		if m == null:
			continue
		m = m.duplicate() as StandardMaterial3D
		m.albedo_color = Color(minf(color.r * 1.7, 1.0), minf(color.g * 1.7, 1.0), minf(color.b * 1.7, 1.0))
		mi.material_override = m

## Esconde las cejas (las del cuerpo y las de `PeloQ`) y la barba 3D.
static func _ocultar_cejas_y_barba(raiz: Node) -> void:
	if raiz == null:
		return
	for mv in _mallas(raiz):
		var mi: MeshInstance3D = mv
		if mi.name in ["Eyebrows", "Eyebrows_Regular", "Hair_Beard"]:
			mi.visible = false

## Cuánto hay que multiplicar la foto (por canal, en lineal) para que su piel
## media sea la piel del modelo: la media de un óvalo de la cara (sin ojos
## ni boca, que son más oscuros) contra el tono del jugador.
static func _ajuste_foto(foto: Texture2D, af: Array, piel: Color) -> Vector3:
	var img := foto.get_image()
	if img == null or af.size() != 2:
		return Vector3.ONE
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var suma := Vector3.ZERO
	var n := 0
	for sy in range(28, 52, 2):
		for sx in range(22, 43, 2):
			var ov := Vector2((sx - 32.0) / 9.5, (sy - 39.0) / 12.5)
			if ov.length() > 1.0:
				continue
			## Fuera ojos, cejas y boca.
			if absf(sy - 32.0) < 3.5 or absf(sy - 44.5) < 2.5:
				continue
			var q := Vector3(sx, sy, 1.0)
			var px := int((af[0] as Vector3).dot(q) * w)
			var py := int((af[1] as Vector3).dot(q) * h)
			if px < 0 or py < 0 or px >= w or py >= h:
				continue
			var c := img.get_pixel(px, py).srgb_to_linear()
			suma += Vector3(c.r, c.g, c.b)
			n += 1
	if n < 8:
		return Vector3.ONE
	var media := suma / float(n)
	var objetivo := piel.srgb_to_linear()
	return Vector3(clampf(objetivo.r / maxf(media.x, 0.01), 0.5, 1.8),
		clampf(objetivo.g / maxf(media.y, 0.01), 0.5, 1.8),
		clampf(objetivo.b / maxf(media.z, 0.01), 0.5, 1.8))

## La transformación afín que lleva los ojos y la boca del retrato (espacio
## 0-64 de `Cara.svg_rasgos`) a los de la foto (0-1). [] si no hay puntos o
## son degenerados.
static func _afin_foto(p: Array) -> Array:
	if p.size() < 6:
		return []
	var origen := [Vector2(26, 33), Vector2(38, 33), Vector2(32, 44.5)]
	var destino := [Vector2(p[0], p[1]), Vector2(p[2], p[3]), Vector2(p[4], p[5])]
	## Resolver [a b c; d e f] con tres puntos: base con el primero.
	var o1: Vector2 = origen[1] - origen[0]
	var o2: Vector2 = origen[2] - origen[0]
	var d1: Vector2 = destino[1] - destino[0]
	var d2: Vector2 = destino[2] - destino[0]
	var det := o1.x * o2.y - o1.y * o2.x
	if absf(det) < 0.001 or absf(d1.x * d2.y - d1.y * d2.x) < 0.0001:
		return []
	## M * o1 = d1 y M * o2 = d2  =>  M = [d1 d2] * inversa([o1 o2]).
	var inv := [Vector2(o2.y, -o1.y) / det, Vector2(-o2.x, o1.x) / det]  # columnas de la inversa
	var a: float = d1.x * inv[0].x + d2.x * inv[0].y
	var b: float = d1.x * inv[1].x + d2.x * inv[1].y
	var dd: float = d1.y * inv[0].x + d2.y * inv[0].y
	var e: float = d1.y * inv[1].x + d2.y * inv[1].y
	var c: float = destino[0].x - (a * origen[0].x + b * origen[0].y)
	var f: float = destino[0].y - (dd * origen[0].x + e * origen[0].y)
	return [Vector3(a, b, c), Vector3(dd, e, f)]

## Como `_con_reposo` pero sin el alisado: solo la pose de reposo (UV2 = x,y;
## COLOR.r = z) en todas las superficies. Para los ojos.
static func _con_reposo_simple(mi: MeshInstance3D) -> void:
	var original := mi.mesh as ArrayMesh
	if original == null or original.has_meta("con_reposo"):
		return
	var id := original.get_instance_id()
	if _mallas_reposo.has(id):
		mi.mesh = _mallas_reposo[id]
		return
	var nueva := ArrayMesh.new()
	nueva.blend_shape_mode = original.blend_shape_mode
	for bs in original.get_blend_shape_count():
		nueva.add_blend_shape(original.get_blend_shape_name(bs))
	for s in original.get_surface_count():
		var arr := original.surface_get_arrays(s)
		var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv2 := PackedVector2Array()
		var col := PackedColorArray()
		uv2.resize(pos.size())
		col.resize(pos.size())
		for i in pos.size():
			uv2[i] = Vector2(pos[i].x, pos[i].y)
			col[i] = Color(clampf((pos[i].z + 0.25) / 0.5, 0.0, 1.0), 0.0, 0.0, 1.0)
		arr[Mesh.ARRAY_TEX_UV2] = uv2
		arr[Mesh.ARRAY_COLOR] = col
		## Conservar el formato de los canales CUSTOM (los ojos traen uno) y los
		## 8 huesos por vértice: sin eso Godot rechaza la superficie.
		var fmt := original.surface_get_format(s)
		var banderas := fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		for c in 4:
			var shift: int = Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT + c * Mesh.ARRAY_FORMAT_CUSTOM_BITS
			banderas |= fmt & (Mesh.ARRAY_FORMAT_CUSTOM_MASK << shift)
		nueva.add_surface_from_arrays(original.surface_get_primitive_type(s), arr, original.surface_get_blend_shape_arrays(s),
			{}, banderas)
		if nueva.get_surface_count() <= s:
			return
		nueva.surface_set_material(s, original.surface_get_material(s))
		nueva.surface_set_name(s, original.surface_get_name(s))
	nueva.set_meta("con_reposo", true)
	_mallas_reposo[id] = nueva
	mi.mesh = nueva

static var _mallas_reposo: Dictionary = {}

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
		nueva.add_surface_from_arrays(original.surface_get_primitive_type(s), arr, formas, {}, banderas)
		## Sin pantalla (banco headless) el servidor falso no guarda superficies.
		if nueva.get_surface_count() <= s:
			return
		nueva.surface_set_material(s, original.surface_get_material(s))
		nueva.surface_set_name(s, original.surface_get_name(s))
	nueva.set_meta("con_reposo", true)
	_mallas_reposo[id] = nueva
	mi.mesh = nueva

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
	for it in 24:
		var f: float = 0.55 if it % 2 == 0 else -0.58
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
		c0[i * 4 + 3] = clampf(relleno, 0.0, 0.03)
		c1[i * 3] = nr.x
		c1[i * 3 + 1] = nr.y
		c1[i * 3 + 2] = nr.z
	return [c0, c1]

## El tono del jugador sobre el de la textura, en espacio lineal (el shader
## multiplica ya en lineal). Acotado: un tono extremo no puede quemar la piel.
static func _tinte(piel: Color) -> Vector3:
	var a := piel.srgb_to_linear()
	var b := PIEL_REF.srgb_to_linear()
	## Hasta 3,2: una piel clara de foto con flash (224,164,129) pide 2,7 en el
	## azul; con el tope viejo de 1,8 el cuello salía amarillo pálido al lado
	## de la cara real.
	return Vector3(clampf(a.r / b.r, 0.15, 3.2), clampf(a.g / b.g, 0.15, 3.2), clampf(a.b / b.b, 0.15, 3.2))

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
