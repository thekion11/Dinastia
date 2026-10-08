class_name CityBuilder
extends Node3D

## Levanta la CIUDAD DEPORTIVA del club en 3D a partir de sus instalaciones.
##
## La idea que manda aqui: lo que el jugador ha construido se tiene que VER. Cada
## instalacion de G.inst es un edificio de verdad, y su NIVEL decide su tamano y
## su altura. Un club que no ha invertido nada tiene barracones; uno que lleva
## quince temporadas mejorando tiene un complejo. De un vistazo, sin leer numeros.
##
## Los edificios NO son el modelo de manzana de ciudad estirado: ese OBJ trae una
## manzana entera con calles y no sirve como edificio suelto. Se construyen con
## cajas, que es lo que permite que crezcan de verdad con el nivel. El estadio y
## las farolas si son modelos importados.

const RUTA_ESTADIO := "res://assets/ciudad/estadio.obj"
const RUTA_FAROLA := "res://assets/ciudad/farola.obj"

## LOS DOS MODELOS QUE TRAJO EL USUARIO (12-9-2026), convertidos con
## `herramientas/fbx_a_glb.py` -texturas bajadas a 1024 px, malla decimada-.
## Ver `dinastia-modelos-3d-usuario.md`: "ДОМ скетч" (casa boceto) y "Жилой
## комплекс" (complejo residencial), ambos en `recursos/modelos3d/`.
const RUTA_OFICINA_DT := "res://assets/ciudad/oficina_dt.glb"
## `complejo_residencial.glb` ya no se usa (26-9-2026): en su solar va la finca
## amurallada con enredadera (`_finca_enredadera`), a pedido del usuario.

## Los cinco rascacielos CC0 de Kenney (`recursos/modelos3d/cc0_web/LEEME.md`
## tiene la licencia completa: CC0, "City Kit Commercial" v2.1). Solo para el
## SKYLINE lejano -ver `_horizonte()`-, nunca dentro del recinto: son props
## sueltos, no el complejo que ya se levanta a mano con cajas medidas.
const RUTAS_HORIZONTE := [
	"res://assets/ciudad/kenney_buildings/building-skyscraper-a.glb",
	"res://assets/ciudad/kenney_buildings/building-skyscraper-b.glb",
	"res://assets/ciudad/kenney_buildings/building-skyscraper-c.glb",
	"res://assets/ciudad/kenney_buildings/building-skyscraper-d.glb",
	"res://assets/ciudad/kenney_buildings/building-skyscraper-e.glb",
]

## Siete autos CC0 de Kenney ("Car Kit") para el aparcamiento, en vez de
## alternar solo entre `coche1.fbx`/`coche2.fbx`. Se suman a los dos viejos,
## no los reemplazan -por si alguno de los GLB no cargara, el aparcamiento
## nunca se queda sin nada-.
const RUTAS_COCHES_KENNEY := [
	"res://assets/ciudad/kenney_cars/sedan.glb",
	"res://assets/ciudad/kenney_cars/sedan-sports.glb",
	"res://assets/ciudad/kenney_cars/suv.glb",
	"res://assets/ciudad/kenney_cars/suv-luxury.glb",
	"res://assets/ciudad/kenney_cars/hatchback-sports.glb",
	"res://assets/ciudad/kenney_cars/taxi.glb",
	"res://assets/ciudad/kenney_cars/van.glb",
]

## Las 18 instalaciones, con donde va cada una y de que color es su tejado.
## El orden importa: define la posicion en la parrilla del complejo.
## EL DOBLE DE GRANDES (12-9-2026). Con 9-16 m de fachada, al lado de un
## estadio de 110 m las instalaciones eran cajitas: el usuario dijo "no se ven
## los edificios, se siente un poco vacío, deben ser más grandes y detalladas",
## y tenía razón -un centro de entrenamiento de verdad es una nave de 40 m, no
## un quiosco-. Se doblan las medidas y la parrilla se separa en consecuencia.
const EDIFICIOS := [
	{"k": "ct",        "n": "Centro de entrenamiento", "col": Color(0.24, 0.52, 0.32), "ancho": 34.0, "fondo": 23.0},
	{"k": "acad",      "n": "Academia juvenil",        "col": Color(0.30, 0.46, 0.62), "ancho": 30.0, "fondo": 21.0},
	{"k": "med",       "n": "Centro médico",           "col": Color(0.78, 0.80, 0.82), "ancho": 24.0, "fondo": 19.0},
	{"k": "gim",       "n": "Gimnasio",                "col": Color(0.52, 0.34, 0.28), "ancho": 26.0, "fondo": 19.0},
	{"k": "resid",     "n": "Residencia",              "col": Color(0.62, 0.55, 0.40), "ancho": 28.0, "fondo": 21.0},
	{"k": "rehab",     "n": "Rehabilitacion",          "col": Color(0.70, 0.74, 0.78), "ancho": 22.0, "fondo": 17.0},
	{"k": "piscina",   "n": "Piscina",                 "col": Color(0.24, 0.58, 0.72), "ancho": 26.0, "fondo": 17.0},
	{"k": "cocina",    "n": "Comedor",                 "col": Color(0.72, 0.58, 0.34), "ancho": 22.0, "fondo": 17.0},
	{"k": "video",     "n": "Sala de video",           "col": Color(0.32, 0.32, 0.40), "ancho": 19.0, "fondo": 15.0},
	{"k": "pren",      "n": "Sala de prensa",          "col": Color(0.40, 0.36, 0.48), "ancho": 19.0, "fondo": 15.0},
	{"k": "museo",     "n": "Museo",                   "col": Color(0.66, 0.50, 0.22), "ancho": 24.0, "fondo": 19.0},
	{"k": "com",       "n": "Tienda",                  "col": Color(0.74, 0.36, 0.30), "ancho": 22.0, "fondo": 17.0},
	{"k": "guarderia", "n": "Guarderia",               "col": Color(0.80, 0.66, 0.34), "ancho": 19.0, "fondo": 15.0},
	{"k": "bienestar", "n": "Bienestar",               "col": Color(0.56, 0.60, 0.52), "ancho": 19.0, "fondo": 15.0},
	{"k": "esports",   "n": "Sala de juegos",          "col": Color(0.36, 0.30, 0.56), "ancho": 19.0, "fondo": 15.0},
]

## EL HUERTO NO ES UN EDIFICIO y por eso faltaba (12-9-2026). `Instalaciones`
## tiene DIECINUEVE obras y aquí solo se dibujaban quince. De las cuatro que
## faltaban, tres no son edificios y está bien que no lo sean -`trib` y `cal`
## SON el estadio, y `park` son los coches del aparcamiento-, pero `huerto`
## -"Huerto y zona sustentable"- sí ocupa suelo y no se veía en ninguna parte.
## Va aparte de `EDIFICIOS` porque lo suyo no es una caja con ventanas: son
## bancales de cultivo y un invernadero, y crecen a lo ancho con el nivel.
const HUERTO_EN := Vector3(-112.0, 0, 45.0)
const FILA_0_Z := 108.0
const FILA_PASO := 43.0

var datos: Dictionary = {}
var expansion: CiudadExpansion
## Huellas sólidas que no son fachadas (estadio, edificios del club): para el
## modo a pie / al volante (`ExploradorCiudad`).
var huellas: Array[Rect2] = []
var etiquetas: Array = []          ## [{pos:Vector3, texto:String, nivel:int}]
## LO QUE SE PUEDE TOCAR EN EL MAPA (plan maestro B7): cada instalación, su
## solar si todavía no existe, y el estadio. `VistaCiudad` proyecta `pos` a la
## pantalla para saber qué se clicó (el mapa no tiene colisiones).
## [{k, n, pos: Vector3, estado: "hecho"|"obra"|"solar"|"estadio"}]
var puntos_clic: Array = []
var _rotulos: Node3D

## LAS LUCES QUE DEPENDEN DE LA HORA. Se guardan al construir para poder
## encenderlas y apagarlas con el ciclo del sol sin recorrer el árbol entero
## cada fotograma -son decenas de farolas y todas las ventanas del complejo.
var _farolas_luz: Array[OmniLight3D] = []
var _ventanas_mat: Array[StandardMaterial3D] = []

func build(d: Dictionary) -> void:
	datos = d
	## La ciudad vieja se quita YA, no al final del cuadro: con `queue_free` las
	## dos ciudades convivían un cuadro y el motor avisaba «material is null»
	## al soltar la vieja (7-10-2026).
	for c in get_children():
		remove_child(c)
		c.free()
	etiquetas.clear()
	puntos_clic.clear()
	_rotulos = Node3D.new()
	_rotulos.name = "Rotulos"
	_farolas_luz.clear()
	_ventanas_mat.clear()
	_vias.clear()
	_frentes.clear()
	huellas.clear()
	_rect_vestuario = Rect2()
	_anillo_con_banderas = false
	_luminarias.clear()
	_luz_color = _color_luces()

	_suelo()
	_calles()
	_estadio()
	_campos()
	_complejo()
	_huerto()
	_piscina_olimpica()
	_polideportivo()
	_canchas_secundarias()
	_aparcamiento()
	_paradas_bus()
	_perimetro()
	_parcelas()
	_barrio_residencial()
	_frentes_urbanos()
	## LA CIUDAD GRANDE (7-10-2026): sustituye a los tres distritos sueltos de
	## la pasada anterior por una ciudad entera con su red vial.
	expansion = CiudadExpansion.new(self)
	expansion.construir()
	_karting()
	_arbolado()
	_horizonte()
	_trafico()
	## B7: el día de partido, el ánimo del barrio y los rótulos flotantes.
	if bool(datos.get("dia_partido", false)):
		_dia_de_partido()
	_animo_del_club()
	_rotulo_barrio()
	add_child(_rotulos)
	_despejar_vestuario(self)

## `noche` va de 0 (pleno día) a 1 (noche cerrada). Lo llama el ciclo del sol
## de `VistaCiudad` en cada fotograma. Las farolas se encienden con la luz, y
## las ventanas pasan de un reflejo apagado a estar iluminadas por dentro:
## es lo que hace que a las 22:00 la ciudad deportiva siga estando AHÍ en vez
## de desaparecer en un bloque negro.
func encender_luces(noche: float) -> void:
	if expansion != null:
		expansion.encender(noche)
	var f: float = clampf(noche, 0.0, 1.0)
	for l in _farolas_luz:
		if is_instance_valid(l):
			## 5,4 y no 2,4: se midió que a 2,4 las farolas SÍ estaban
			## encendidas -energía correcta, color correcto, visibles- pero el
			## charco de luz en el suelo no llegaba a leerse. El fallo no era
			## que no funcionaran, era que no se notaban.
			l.light_energy = 5.4 * f
			l.visible = f > 0.02
	## La luminaria se enciende ANTES que la luz del suelo y se apaga después:
	## en la vida real ves la bombilla encendida un buen rato antes de que se
	## note en el asfalto, y ese desfase es justo lo que hace creíble el
	## atardecer. `pow` con exponente < 1 sube rápido al principio.
	##
	## Y EL MULTIPLICADOR ES 1,6 POR EL `glow`, no por el brillo en sí:
	## `glow_hdr_threshold` está en 1,05, así que todo canal que pase de ahí
	## florece. Con 7 -el primer intento- un cian (0,49 · 0,88 · 1,0) se iba a
	## (3,4 · 6,2 · 7): los TRES canales por encima del umbral, y el halo salía
	## BLANCO, con lo que el color elegido no se veía -que era justo lo único
	## que se le pedía a la farola-. Con 1,6 el canal rojo se queda en 0,79,
	## por debajo del umbral, y el halo conserva el tono.
	## 2,2 y no 7: a 7 el tonemapper satura la luminaria a BLANCO y el color
	## elegido no se veía -que es justo lo único que se pedía de ella-. El
	## brillo que hace falta para que se note de lejos lo pone el halo (`glow`
	## del entorno), no la emisión bruta.
	for lm in _luminarias:
		if lm != null:
			lm.emission_energy_multiplier = 1.6 * pow(f, 0.45)
	for m in _ventanas_mat:
		if m != null:
			## Cada tira se enciende en SU propio umbral de la noche (0,55 de
			## margen) y llega a SU propio techo de brillo (0,5 a 1,0): así no
			## se prende todo el edificio de golpe a la misma hora, y unas
			## pocas ventanas se quedan siempre más apagadas que el resto,
			## como una oficina vacía o alguien que ya se fue.
			var azar: float = m.get_meta("_azar_ventana", 0.5)
			var umbral: float = azar * 0.55
			var t: float = clampf((f - umbral) / (1.0 - umbral), 0.0, 1.0)
			## El TECHO no sale del mismo azar que el umbral tal cual -si no,
			## las que se encienden tarde serían siempre además las más
			## tenues, demasiado ordenado para verse al azar de verdad-. Un
			## segundo valor derivado del primero, y cerca de un tercio de las
			## ventanas se quedan oscuras -o casi- toda la noche: ninguna
			## oficina real enciende el 100% de sus luces a la vez.
			var azar2: float = fmod(azar * 7.13 + 0.37, 1.0)
			var techo: float = 1.0 - smoothstep(0.60, 0.93, azar2) * 0.88
			m.emission_energy_multiplier = lerpf(0.18, 2.6 * techo, t)
	## El río también sigue la hora: de noche un agua igual de clara que a
	## mediodía se vería como una franja fluorescente en mitad del campo.
	if _agua_mat != null:
		_agua_mat.set_shader_parameter("brillo", lerpf(1.0, 0.28, f))

# ---------------------------------------------------------------- suelo

func _suelo() -> void:
	## Antes esto era UNA losa de asfalto gris azulado de 520x520, y era lo que
	## mas afeaba la escena: un complejo deportivo en mitad de una plancha azul.
	## Ahora son tres capas, como en la realidad: el campo verde alrededor, la
	## explanada de asfalto donde se levantan los edificios, y los viales.
	## 2.400 m de lado y no 520: con el plano corto se veia el BORDE DEL MUNDO, una
	## linea recta donde el terreno se acababa y empezaba el cielo. Un terreno que
	## llega hasta el horizonte cuesta lo mismo y quita de golpe el aire de maqueta.
	for t in _terreno():
		add_child(t)

	## PAVIMENTO SOLO DONDE HACE FALTA (12-9-2026). Antes esto era UNA plancha
	## de asfalto de 228x310 que cubría el recinto entero: desde arriba, la
	## ciudad deportiva parecía un aparcamiento del tamaño del complejo, con
	## cuatro edificios encima. Un complejo de verdad es CÉSPED con pavimento
	## donde se pisa: la plaza de los edificios y la explanada del aparcamiento.
	## El césped ya lo pone el plano de abajo, así que aquí solo van esas dos.
	## `Texturas.asfalto()` (17-9-2026): esta plaza entera -hasta 276x160 m- era
	## color plano puro. La funcion existia en `texturas.gd` desde antes de esta
	## sesion, escrita y sin conectar a ningun lado; se conecta aqui por fin.
	## DUPLICADA antes de tocar rugosidad/metalico -esa funcion cachea y
	## comparte instancia por tinte+semilla, mutarla sin duplicar le
	## cambiaria el acabado a cualquier otro asfalto de este mismo tono.
	var ma: StandardMaterial3D = Texturas.asfalto(Color(0.20, 0.205, 0.215)).duplicate()
	## Asfalto algo pulido: con rugosidad 0.95 no reflejaba nada y se leia como
	## fieltro gris. A 0.55 recoge el cielo del atardecer y parece firme mojado.
	ma.roughness = 0.55
	ma.metallic = 0.08
	## La plaza de las instalaciones se dimensiona por las que DE VERDAD están
	## construidas -cuatro por fila, 32 m entre filas-: con una plaza fija, un
	## club que solo tiene tres instalaciones aparecía con un descampado
	## asfaltado de 150 m esperando edificios que aún no existen.
	var cuantas := 0
	var inst_p: Dictionary = datos.get("inst", {})
	for e in EDIFICIOS:
		if int(inst_p.get(e["k"], 0)) > 0:
			cuantas += 1
	var filas_p: int = maxi(1, int(ceil(float(maxi(cuantas, 1)) / 4.0)))
	var fondo_p: float = 56.0 + (filas_p - 1) * 48.0
	var centro_p: float = 118.0 + (filas_p - 1) * 24.0
	## 7-10-2026: la plaza de las instalaciones ya no es una losa de asfalto
	## de 276 m (se leía como un aparcamiento con edificios encima, «falta de
	## coherencia»): el complejo es césped con paseos, ver `_campus()`.
	for zona in [
			{"pos": Vector3(104, 0.02, -45), "tam": Vector2(90, 80)},   # explanada del aparcamiento
		]:
		var asfalto := MeshInstance3D.new()
		var pa := PlaneMesh.new()
		pa.size = zona["tam"]
		asfalto.mesh = pa
		asfalto.position = zona["pos"]
		asfalto.material_override = ma
		add_child(asfalto)

	## Vial de entrada, que le da escala al conjunto y guia la mirada al estadio.
	## El acceso: de la puerta sur del recinto hasta el propio estadio, pasando
	## entre los campos. Es lo que ata el recinto al anillo de calles.
	## 26-9-2026: la avenida de acceso es una calle completa como las demás
	## (asfalto, marcas, bordillo y aceras), no un plano oscuro sin nada.
	## Llega hasta el anillo sur (antes se quedaba 22 m corta: una calle que
	## no desembocaba en ninguna parte).
	_via(Vector3(0, 0, (-90.0 + RING_Z_SUR) * 0.5), Vector2(14, RING_Z_SUR + 90.0), Texturas.asfalto(Color(0.17, 0.175, 0.185)), null, false)

## Arbolado alrededor del complejo. Es lo que mas hace por que la escena deje de
## parecer una maqueta: rompe la horizontal, da sombras y da ESCALA — sin nada
## vivo al lado, un edificio de 30 m y uno de 6 se ven igual de grandes.
##
## Van en un MultiMesh y no como nodos sueltos: son varios cientos y cada uno
## como nodo propio hundiria los fotogramas en una Intel UHD. Con MultiMesh el
## motor los dibuja de una sola pasada.
func _arbolado() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77123

	var tronco_mm := MultiMesh.new()
	tronco_mm.transform_format = MultiMesh.TRANSFORM_3D
	var cil := CylinderMesh.new()
	cil.top_radius = 0.28
	cil.bottom_radius = 0.42
	cil.height = 4.6
	cil.radial_segments = 7
	tronco_mm.mesh = cil

	var copa_mm := MultiMesh.new()
	copa_mm.transform_format = MultiMesh.TRANSFORM_3D
	copa_mm.use_colors = true
	var esf := SphereMesh.new()
	esf.radius = 3.4
	esf.height = 7.2
	esf.radial_segments = 10
	esf.rings = 6
	copa_mm.mesh = esf

	## Posiciones: en el cesped, FUERA de la explanada y fuera del estadio, y
	## alineados a lo largo del vial como una avenida arbolada.
	var sitios: Array = []
	for i in range(210):
		var x := rng.randf_range(-520.0, 520.0)
		var z := rng.randf_range(-380.0, 520.0)
		if absf(x) < 145.0 and z > -275.0 and z < 250.0:
			continue                      # todo el recinto del club
		## NUEVO (12-9-2026): ni encima de las calles ni dentro de las
		## parcelas. Un árbol plantado en mitad de la calzada, o dentro de un
		## solar cercado, delata que las dos cosas se colocaron sin mirarse.
		if absf(absf(x) - RING_X) < ANCHO_CALLE and z > RING_Z_NORTE - 20.0 and z < RING_Z_SUR + 20.0:
			continue
		if absf(z - RING_Z_NORTE) < ANCHO_CALLE or absf(z - RING_Z_SUR) < ANCHO_CALLE:
			continue
		if absf(x - BARRIO_EN.x) < ANCHO_CALLE and z > RING_Z_SUR:
			continue                      # ramal del barrio
		if Vector2(x - BARRIO_EN.x, z - BARRIO_EN.z).length() < 70.0:
			continue                      # el propio barrio
		var en_parcela := false
		for clave: String in PARCELAS:
			var p: Dictionary = PARCELAS[clave]
			var c: Vector2 = p["pos"]
			if absf(x - c.x) < float(p["ancho"]) * 0.5 + 6.0 and absf(z - c.y) < float(p["fondo"]) * 0.5 + 6.0:
				en_parcela = true
				break
		if en_parcela:
			continue
		if x < RIO_X + 55.0 and x > RIO_X - 55.0:
			continue                      # el río
		if _en_frente_urbano(x, z):
			continue                      # las manzanas de edificios
		sitios.append(Vector3(x, 0, z))
	for lado in [-1.0, 1.0]:
		for i in range(9):
			sitios.append(Vector3(lado * 12.5, 0, -55.0 + i * 22.0))

	## ARBOLADO DENTRO DEL RECINTO Y EN LAS PARCELAS (12-9-2026): "las áreas
	## entre los bloques se sienten algo vacías". Tenía razón: los árboles
	## estaban TODOS fuera de la valla, así que el interior -que es donde más
	## se mira- era pavimento pelado. Se plantan en los huecos entre edificios
	## y en el perímetro de cada parcela, esquivando lo que ya hay.
	for i in range(80):
		var x2 := rng.randf_range(-140.0, 140.0)
		var z2 := rng.randf_range(-240.0, 290.0)
		## Ni sobre los campos, ni sobre la avenida, ni encima de un edificio.
		if absf(x2) < 90.0 and z2 > -55.0 and z2 < 70.0:
			continue                      # campos de entrenamiento
		if absf(x2) < 12.0:
			continue                      # avenida de acceso
		if z2 > 100.0 and z2 < 290.0 and absf(fmod(absf(x2) + 37.0, 74.0) - 37.0) < 22.0:
			continue                      # columnas de edificios
		if Vector2(x2, z2 + 150.0).length() < 95.0:
			continue                      # el estadio
		if absf(x2 - 112.0) < 32.0 and z2 > -150.0 and z2 < 10.0:
			continue                      # polideportivo y canchas
		if absf(x2 + 112.0) < 36.0 and z2 > -85.0 and z2 < 60.0:
			continue                      # piscina y huerto
		sitios.append(Vector3(x2, 0, z2))
	## Y una orla de arbolado alrededor de cada parcela, que es lo que las ata
	## al paisaje en vez de dejarlas como pegatinas sobre el césped.
	for clave: String in PARCELAS:
		var pp: Dictionary = PARCELAS[clave]
		var c2: Vector2 = pp["pos"]
		var an: float = float(pp["ancho"]) * 0.5 + 9.0
		var fo: float = float(pp["fondo"]) * 0.5 + 9.0
		for i in range(16):
			var t2: float = float(i) / 16.0 * TAU
			sitios.append(Vector3(c2.x + cos(t2) * an, 0, c2.y + sin(t2) * fo))

	tronco_mm.instance_count = sitios.size()
	copa_mm.instance_count = sitios.size()
	for i in range(sitios.size()):
		var p: Vector3 = sitios[i]
		var esc: float = rng.randf_range(0.75, 1.45)
		var t := Transform3D(Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(esc, esc, esc)),
			p + Vector3(0, 2.3 * esc, 0))
		tronco_mm.set_instance_transform(i, t)
		var tc := Transform3D(Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(
			Vector3(esc * rng.randf_range(0.85, 1.15), esc, esc * rng.randf_range(0.85, 1.15))),
			p + Vector3(0, 6.2 * esc, 0))
		copa_mm.set_instance_transform(i, tc)
		## Cada copa de un verde distinto: un bosque de un solo verde se lee como
		## papel pintado por muchos arboles que tenga.
		copa_mm.set_instance_color(i, Color(0.14, 0.30, 0.13).lerp(
			Color(0.34, 0.52, 0.20), rng.randf()))

	## Troncos de TODOS los arboles del mapa (MultiMesh), madera real (17-9-2026).
	var mt: StandardMaterial3D = Texturas.madera(Color(0.26, 0.19, 0.13)).duplicate()
	mt.roughness = 0.95
	var mi_t := MultiMeshInstance3D.new()
	mi_t.multimesh = tronco_mm
	mi_t.material_override = mt
	add_child(mi_t)

	## VIENTO EN EL FOLLAJE (13-9-2026): antes un `StandardMaterial3D` fijo
	## dejaba cientos de copas completamente rígidas, lo que más delata una
	## ciudad de maqueta. `follaje_viento.gdshader` hace lo mismo -color por
	## instancia sobre un tinte base, mismo roughness/specular de siempre-
	## pero además mece cada copa con una fase propia sacada de su posición.
	var mc := ShaderMaterial.new()
	mc.shader = load("res://visor/follaje_viento.gdshader")
	## El verde ya viene por copa: con el tinte base encima se multiplicaba dos
	## veces y las copas salían NEGRAS (8-10-2026).
	mc.set_shader_parameter("tinte_base", Color(1.0, 1.0, 1.0))
	var mi_c := MultiMeshInstance3D.new()
	mi_c.multimesh = copa_mm
	mi_c.material_override = mc
	add_child(mi_c)

## ============================================================================
##  EL TERRENO (12-9-2026, tercera pasada)
## ============================================================================
##
## Antes esto era UN `PlaneMesh` de 5.000 m: perfectamente plano hasta el
## horizonte, y por eso el mapa se leía como una maqueta sobre una mesa. Un
## terreno de verdad ONDULA. Ahora es una malla generada con ruido, con una
## regla que es la clave de todo: **la zona construida se queda plana**.
##
## Por qué plana en el centro: las calles, las parcelas, el recinto y el
## estadio son planos rígidos colocados a y=0. Si el terreno subiera y bajara
## debajo de ellos, asomarían flotando por un lado y enterrados por el otro.
## Así que la altura vale 0 dentro del radio construido, y de ahí hacia fuera
## sube suavemente -con una transición larga, o se vería el escalón-. Es el
## mismo truco que usa cualquier juego de gestión con un mapa "natural"
## alrededor de una parcela edificable.
const TERRENO_LADO := 7600.0
const TERRENO_CELDAS := 160          ## 121x121 vértices: suficiente para que las
                                     ## lomas se lean y barato de generar.
const LLANO_RADIO := 1480.0          ## dentro de esto, altura 0 garantizada
const LLANO_TRANSICION := 520.0      ## y esto es lo que tarda en empezar a subir
const TERRENO_ALTURA := 78.0

## Se guardan para poder preguntar la altura en cualquier punto DESPUÉS de
## generar la malla: lo que se plante fuera del llano -los edificios del
## horizonte- tiene que apoyarse en la loma, no flotar sobre ella.
var _ruido_terreno: FastNoiseLite
var _ruido_detalle: FastNoiseLite

func altura_en(x: float, z: float) -> float:
	if _ruido_terreno == null:
		return 0.0
	return _altura_terreno(x, z, _ruido_terreno, _ruido_detalle)

## EN BALDOSAS, NO EN UNA SOLA MALLA (12-9-2026, segunda vuelta del terreno).
## Con el terreno entero en un único `MeshInstance3D` las farolas no iluminaban
## el suelo: en el render de Compatibility -el que usa el móvil, y el que usan
## estas pruebas- cada OBJETO recibe como mucho un puñado de luces (8 por
## defecto), y una malla de 5 km es UN objeto. Las 54 farolas se repartían ocho
## plazas para todo el mapa, así que de noche el suelo salía negro mientras las
## canchas -que sí son mallas sueltas- se veían iluminadas. Troceado en
## baldosas, cada una elige sus luces cercanas y el alumbrado funciona.
const TERRENO_BALDOSAS := 8

func _terreno() -> Array[MeshInstance3D]:
	var ruido := FastNoiseLite.new()
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido.seed = 20260912
	ruido.frequency = 0.00055
	ruido.fractal_octaves = 4
	ruido.fractal_lacunarity = 2.1
	var detalle := FastNoiseLite.new()
	detalle.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detalle.seed = 771
	detalle.frequency = 0.0035
	_ruido_terreno = ruido
	_ruido_detalle = detalle

	var paso := TERRENO_LADO / float(TERRENO_CELDAS)
	var mitad := TERRENO_LADO * 0.5
	var alturas: Array = []
	alturas.resize((TERRENO_CELDAS + 1) * (TERRENO_CELDAS + 1))
	for j in range(TERRENO_CELDAS + 1):
		for i in range(TERRENO_CELDAS + 1):
			var x := -mitad + i * paso
			var z := -mitad + j * paso
			alturas[j * (TERRENO_CELDAS + 1) + i] = _altura_terreno(x, z, ruido, detalle)

	## SHADER DE LADERA (12-9-2026): antes una sola textura de césped se
	## estiraba sobre TODO el relieve, así que una loma de 78 m se veía con
	## césped hasta en la parte casi vertical. `terreno.gdshader` mezcla la
	## misma textura con roca/tierra procedural según `NORMAL.y` -plano sigue
	## siendo césped, la pendiente se vuelve roca-, un solo material para las
	## 64 baldosas igual que antes.
	var shader_terreno := load("res://visor/terreno.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader_terreno
	mat.set_shader_parameter("textura_cesped", _textura_cesped())
	mat.set_shader_parameter("escala_cesped", Vector2(20.0, 20.0))

	var salida: Array[MeshInstance3D] = []
	var por_baldosa: int = TERRENO_CELDAS / TERRENO_BALDOSAS
	var idx := func(ii: int, jj: int) -> int: return jj * (TERRENO_CELDAS + 1) + ii
	for bj in range(TERRENO_BALDOSAS):
		for bi in range(TERRENO_BALDOSAS):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for j in range(bj * por_baldosa, (bj + 1) * por_baldosa):
				for i in range(bi * por_baldosa, (bi + 1) * por_baldosa):
					var x0 := -mitad + i * paso
					var z0 := -mitad + j * paso
					var p00 := Vector3(x0, alturas[idx.call(i, j)], z0)
					var p10 := Vector3(x0 + paso, alturas[idx.call(i + 1, j)], z0)
					var p01 := Vector3(x0, alturas[idx.call(i, j + 1)], z0 + paso)
					var p11 := Vector3(x0 + paso, alturas[idx.call(i + 1, j + 1)], z0 + paso)
					## Dos triángulos por celda, en el orden que deja la cara
					## hacia arriba (si se invierte, desde la cámara no hay
					## nada: un agujero verde donde estaba el suelo).
					## NORMALES (26-9-2026): `generate_normals()` las daba hacia
					## ABAJO con este orden de vértices, y el shader pintaba todo
					## el llano como roca gris y sin luz. Ahora salen del propio
					## relieve (diferencias centrales), suaves y hacia arriba.
					## Y el ORDEN: con el de antes la cara quedaba hacia abajo y el
					## motor la descartaba; lo que se veía era el "suelo" pálido
					## del cielo, no el terreno.
					var ns := [_normal_rejilla(alturas, i, j, paso), _normal_rejilla(alturas, i + 1, j, paso), _normal_rejilla(alturas, i, j + 1, paso), _normal_rejilla(alturas, i + 1, j, paso), _normal_rejilla(alturas, i + 1, j + 1, paso), _normal_rejilla(alturas, i, j + 1, paso)]
					var k := 0
					for tri in [[p00, p10, p01], [p10, p11, p01]]:
						for p: Vector3 in tri:
							st.set_normal(ns[k])
							st.set_uv(Vector2(p.x, p.z) / 20.0)
							st.add_vertex(p)
							k += 1
			var mi := MeshInstance3D.new()
			mi.mesh = st.commit()
			mi.material_override = mat
			salida.append(mi)
	return salida

## Normal de la rejilla de alturas en el vértice (i, j), siempre hacia arriba.
func _normal_rejilla(alturas: Array, i: int, j: int, paso: float) -> Vector3:
	var n := TERRENO_CELDAS
	var h := func(ii: int, jj: int) -> float: return float(alturas[clampi(jj, 0, n) * (n + 1) + clampi(ii, 0, n)])
	var dx: float = (h.call(i + 1, j) - h.call(i - 1, j)) / (2.0 * paso)
	var dz: float = (h.call(i, j + 1) - h.call(i, j - 1)) / (2.0 * paso)
	return Vector3(-dx, 1.0, -dz).normalized()

## La altura en un punto: cero en la zona construida, y a partir de ahí una
## rampa suave (`smoothstep`) hacia las lomas del ruido. El detalle fino se
## suma con MENOS peso cerca del llano, o el borde del campo de juego quedaría
## rizado justo donde empieza el césped liso.
func _altura_terreno(x: float, z: float, ruido: FastNoiseLite, detalle: FastNoiseLite) -> float:
	var d := Vector2(x, z).length()
	if d <= LLANO_RADIO:
		return 0.0
	var t: float = clampf((d - LLANO_RADIO) / LLANO_TRANSICION, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	var h: float = ruido.get_noise_2d(x, z) * TERRENO_ALTURA
	h += detalle.get_noise_2d(x, z) * 6.0
	return h * t

## Cesped generado por codigo: dos verdes mezclados con ruido menudo. Sin una
## textura, una explanada de 520 m de un solo color se lee como un papel pintado.
static func _textura_cesped() -> ImageTexture:
	## 26-9-2026: 512 px (antes 96) sobre 20 m, sin costuras: briznas finas en
	## dos verdes, matas más oscuras y algo de hierba seca, con mipmaps.
	var n := 512
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260902
	var ruido := FastNoiseLite.new()
	ruido.seed = 911
	ruido.frequency = 0.02
	var manchas := ruido.get_seamless_image(n, n)
	var a := Color(0.11, 0.27, 0.08)
	var b := Color(0.20, 0.40, 0.12)
	var seca := Color(0.42, 0.40, 0.20)
	for y in range(n):
		for x in range(n):
			var m := manchas.get_pixel(x, y).r
			var t: float = rng.randf() * 0.7 + m * 0.5
			var c := a.lerp(b, clampf(t, 0.0, 1.0))
			if rng.randf() < 0.04:
				c = c.darkened(0.3)
			elif m > 0.72 and rng.randf() < 0.25:
				c = c.lerp(seca, 0.5)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## ============================================================================
##  LA CIUDAD CRECE CON EL CLUB (12-9-2026)
## ============================================================================
##
## La idea, en una frase: **si el club sube, la ciudad se nota**. Un club de
## reputación 30 está en un pueblo con cuatro edificios al fondo; uno de 90
## está en una ciudad con skyline, barrio grande y tráfico. No hace falta un
## sistema nuevo -la reputación y los socios ya existen y ya suben solos con
## los títulos-, hace falta que el mapa los LEA.
##
## Por qué importa más de lo que parece: hasta ahora ganar la liga cambiaba una
## tabla. Con esto, ganar la liga se ve desde la ventanilla del coche.

## 0 con reputación 20 o menos, 1 con 90 o más. Es la curva que decide cuánta
## ciudad hay alrededor.
func _empuje_club() -> float:
	var rep := float(datos.get("club", {}).get("rep", 50))
	return clampf((rep - 20.0) / 70.0, 0.0, 1.0)

func _color_club(cual: String, porDefecto: Color) -> Color:
	var club: Dictionary = datos.get("club", {})
	var s := str(club.get(cual, ""))
	if s.begins_with("#") and s.length() >= 7:
		return Color(s)
	return porDefecto

# ---------------------------------------------------------------- estadio

## EL ESTADIO DE VERDAD, EL MISMO QUE SE JUEGA (12-9-2026).
##
## Antes aquí había una maqueta: `estadio.obj`, una malla genérica escalada por
## el aforo. Servía como bulto, pero el usuario lo dijo claro: "el estadio debe
## estar tal cual como esté en el club, si fue modificado debe notarse". Y ya
## existía la pieza exacta para eso -`StadiumBuilder`, el mismo constructor que
## levanta el recinto en el partido en vivo, alimentado por el perfil que
## devuelve `EstadioPropio`-: la forma, las bandejas, el techo, el corte del
## césped, el color de las butacas y hasta los focos que elegiste salen ahí.
## Reformar el estadio en Club → Estadio ahora se ve TAMBIÉN desde el mapa.
##
## Va dentro de un nodo propio y desplazado al norte: `StadiumBuilder` lo
## construye siempre centrado en el origen (es su contrato con el visor de
## partido, donde el estadio ES la escena), así que aquí se mueve entero.
const ESTADIO_EN := Vector3(0, 0, -150)

func _estadio() -> void:
	var perfil: Dictionary = datos.get("perfil_estadio", {})
	if not perfil.is_empty():
		var nodo := Node3D.new()
		nodo.position = ESTADIO_EN
		nodo.set_meta("en_ciudad", true)
		add_child(nodo)
		var aforo := int(perfil.get("aforo", datos.get("club", {}).get("cap", 20000)))
		## EL MISMO ESTADIO QUE EN EL PARTIDO Y EN EL VISOR (8-10-2026): misma
		## semilla (el id del club) y el club para escudos, telones y pantallas.
		## Antes la semilla era el aforo y sin club: butacas y detalles distintos.
		var club_obj: Club = datos.get("club_obj") as Club
		var semilla := club_obj._hash_id() if club_obj != null else aforo
		StadiumBuilder.build_pitch(nodo, perfil, club_obj)
		## Ocupación media-baja: fuera de partido el estadio no está lleno, pero
		## con 0,06 la grada salía de un gris uniforme y desde el mapa el
		## estadio se leía como una pista de hockey. Con 0,35 se distinguen las
		## butacas del club, que es lo que lo hace reconocible desde arriba.
		## Con la galería subterránea (2.0, fase 6) la puerta del sótano queda abierta.
		GaleriaClub.en_ciudad = true
		StadiumBuilder.build(nodo, perfil, aforo, 0.85 if bool(datos.get("dia_partido", false)) else 0.35, semilla, club_obj)
		GaleriaClub.en_ciudad = false
		huellas.append(Rect2(ESTADIO_EN.x - 62.0, ESTADIO_EN.z - 80.0, 124.0, 160.0))
		## El vestuario del túnel sobresale por detrás de la tribuna (estadio 2.0).
		var tv := TunelVestuario.datos(perfil, StadiumBuilder.niveles_de(perfil, aforo))
		## La galería que une el sótano del club con el complejo, y su caseta.
		var g1 := _color_club("c1", Color(0.2, 0.5, 0.3))
		var g2 := _color_club("c2", Color(0.95, 0.95, 0.95))
		GaleriaClub.montar(nodo, tv, g1, g2, String(perfil.get("club_nombre", "")))
		GaleriaClub.montar_caseta(self, tv, g1)
		_rect_vestuario = Rect2(ESTADIO_EN.x + float(tv["x0"]) - TunelVestuario.VEST_MEDIO - 0.4,
			ESTADIO_EN.z + float(tv["z_out"]), TunelVestuario.VEST_MEDIO * 2.0 + 0.8, TunelVestuario.VEST_FONDO + 0.4)
		huellas.append(_rect_vestuario)
		## La entrada del club (8-10-2026): la garita del portero es sólida y
		## delante de la puerta no puede haber bolardos, bancos ni papeleras.
		var x0e := ESTADIO_EN.x + float(tv["x0"])
		var zfe := ESTADIO_EN.z + float(tv["z_fin"])
		var rg := EntradaClub.rect_garita(float(tv["x0"]), float(tv["z_fin"]))
		huellas.append(Rect2(rg.position + Vector2(ESTADIO_EN.x, ESTADIO_EN.z), rg.size))
		_rect_entrada = Rect2(EntradaClub.centro(x0e) - 7.5, zfe + 0.3, 15.0, 5.5)
		puntos_clic.append({"k": "estadio", "n": str(datos.get("club", {}).get("estadioNom", "Estadio")),
			"pos": ESTADIO_EN + Vector3(0, 15, 0), "estado": "estadio"})
		## Si se están ampliando las tribunas o mejorando el recinto, se nota.
		for o in datos.get("obras", []):
			if str(o.get("k", "")) in ["trib", "cal"]:
				_grua(ESTADIO_EN + Vector3(95.0, 0, 20.0), 70.0)
				break
		etiquetas.append({
			"pos": ESTADIO_EN + Vector3(0, 40, 0),
			"texto": str(datos.get("club", {}).get("estadioNom", "Estadio")),
			"nivel": int(datos.get("inst", {}).get("trib", 0)),
		})
		return
	_estadio_maqueta()

## Respaldo: la maqueta de siempre, por si no llega perfil -por ejemplo desde
## una prueba que solo pasa `inst`-. Mejor una maqueta que un hueco.
func _estadio_maqueta() -> void:
	var malla := load(RUTA_ESTADIO)
	if malla == null:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	var aforo := float(datos.get("club", {}).get("cap", 20000))
	var k: float = clampf(sqrt(aforo / 20000.0), 0.65, 1.8)
	## Escala MEDIDA, no a ojo: el OBJ mide 7.298 unidades de largo y un estadio real
	## ronda los 220 m, asi que 220/7298 = 0.030. Con el 0.09 que puse a ojo salia de
	## 650 metros y se comia la escena entera.
	## Su origen ya esta en Y=0 y centrado en X, asi que apoya solo en el suelo.
	mi.scale = Vector3.ONE * 0.030 * k
	mi.position = Vector3(0, 0, -150)
	## El OBJ no trae materiales. Se le daba el color SECUNDARIO del club, pero en
	## la mayoria de los escudos ese color es el blanco, asi que el estadio salia
	## de un blanco yeso y parecia una maqueta sin terminar. Ahora es hormigon
	## teñido hacia el color PRINCIPAL: se reconoce al club y sigue leyendose como
	## un edificio.
	var hormigon := Color(0.62, 0.63, 0.64)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = hormigon.lerp(_color_club("c1", hormigon), 0.45)
	mat.roughness = 0.6
	mat.metallic = 0.06
	mat.metallic_specular = 0.4
	mi.material_override = mat
	add_child(mi)
	## Cesped dentro del recinto: sin el, el hueco del estadio se ve del mismo color
	## que las gradas y no se entiende que ahi dentro hay un campo.
	var cesp := MeshInstance3D.new()
	var cp := PlaneMesh.new()
	cp.size = Vector2(38 * k, 25 * k)
	cesp.mesh = cp
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.19, 0.45, 0.23)
	cmat.roughness = 1.0
	cesp.material_override = cmat
	cesp.position = Vector3(0, 0.6, -150)
	add_child(cesp)
	etiquetas.append({
		"pos": Vector3(0, 75 * k, -150),
		"texto": str(datos.get("club", {}).get("estadioNom", "Estadio")),
		"nivel": int(datos.get("inst", {}).get("trib", 0)),
	})

# ---------------------------------------------------------------- campos

func _campos() -> void:
	## Un campo de entrenamiento por cada nivel del centro de entrenamiento, con un
	## minimo de uno: sin campos no hay club. Es el lector mas directo de esa
	## inversion — subes 'ct' y aparece cesped nuevo.
	var niv := int(datos.get("inst", {}).get("ct", 0))
	var n: int = clampi(niv + 1, 1, 6)
	## DOS POR FILA Y MÁS GRANDES (12-9-2026): con tres campos de 35 m por fila
	## el complejo parecía un patio de colegio al lado de un estadio de 110 m
	## de ancho. Ahora cada campo mide 78x50 -tres cuartos de uno reglamentario-
	## y se entiende que ahí entrena un plantel profesional.
	for i in range(n):
		var fila := i / 2
		var col := i % 2
		var x := -45.0 + col * 90.0
		var z := -25.0 + fila * 64.0
		_un_campo(Vector3(x, 0.02, z), i == 0)

func _un_campo(pos: Vector3, principal: bool) -> void:
	var m := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	## 105x68 son las medidas reales; aquí van a 3/4, que es lo que permite
	## meter cuatro campos sin que el recinto se estire un kilómetro.
	pl.size = Vector2(78, 50)
	m.mesh = pl
	var mat := StandardMaterial3D.new()
	## CON CORTE DE CÉSPED, no un verde plano. Sobre el césped general del
	## recinto -que es otro verde parecido- un campo liso no se distinguía: se
	## veía un rectángulo apenas más oscuro. Con las rayas del corte se lee como
	## campo de fútbol al primer vistazo, incluso desde la cámara del mapa. La
	## textura es la MISMA que usa el estadio de verdad (`StadiumBuilder`), así
	## que los campos de entrenamiento y la cancha del estadio se parecen entre
	## sí, como en un club real.
	## RAYAS EN LOS DOS, cambiando la dirección. Con "damero" en los campos
	## secundarios aquello se leía como un tablero de ajedrez, no como césped
	## cortado: el damero de un estadio de verdad es mucho más fino que el que
	## sale aquí a esta escala. Dos direcciones de raya bastan para que los
	## campos no parezcan copiados y sigan leyéndose como campos.
	mat.albedo_texture = StadiumBuilder._make_grass_texture(
		"rayas" if principal else "rayasH",
		Color(0.29, 0.60, 0.30), Color(0.17, 0.42, 0.20))
	mat.roughness = 0.98
	m.material_override = mat
	m.position = pos
	add_child(m)
	_lineas_campo(pos)

func _lineas_campo(centro: Vector3) -> void:
	## Las lineas van como cajas finisimas y no como material: un campo sin lineas
	## se lee como una alfombra verde, no como un campo de futbol.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.94, 0.92)
	mat.roughness = 0.9
	var media := func(ancho: float, fondo: float, off: Vector3) -> void:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(ancho, 0.06, fondo)
		b.mesh = bm
		b.material_override = mat
		b.position = centro + off + Vector3(0, 0.04, 0)
		add_child(b)
	media.call(78.0, 0.3, Vector3.ZERO)                  # linea de medio campo (a lo ancho)
	media.call(0.3, 50.0, Vector3.ZERO)                  # linea central
	media.call(78.0, 0.3, Vector3(0, 0, -25.0))          # fondo
	media.call(78.0, 0.3, Vector3(0, 0, 25.0))           # fondo
	media.call(0.3, 50.0, Vector3(-39.0, 0, 0))          # banda
	media.call(0.3, 50.0, Vector3(39.0, 0, 0))           # banda

# ---------------------------------------------------------------- edificios

func _complejo() -> void:
	## Solo se levanta lo CONSTRUIDO: una instalacion a nivel 0 no existe todavia y
	## no debe aparecer, o el complejo se veria igual de lleno el primer dia que en
	## la temporada quince y la inversion no se notaria.
	var inst: Dictionary = datos.get("inst", {})
	var obras: Array = datos.get("obras", [])
	var enObra := {}
	for o in obras:
		enObra[str(o.get("k", ""))] = int(o.get("semanas", 0))

	## SITIO FIJO POR INSTALACIÓN (B7). Antes se compactaban solo las
	## construidas y un edificio cambiaba de sitio al levantar otro; ahora cada
	## una tiene su parcela, y la que no existe todavía se ve como SOLAR con su
	## cartel: es lo que permite construir desde el mapa.
	var i := -1
	for e in EDIFICIOS:
		i += 1
		var niv := int(inst.get(e["k"], 0))
		var obra: bool = enObra.has(e["k"])
		## Cuatro por fila y no cinco: con cinco la parrilla se salia de la valla por
		## el lado, y un complejo con edificios fuera del recinto no se lee como un
		## complejo, se lee como un error de colocacion.
		## Cuatro por fila como siempre, pero con el DOBLE de separación: los
		## edificios pasaron de 9-16 m a 19-34 m de fachada y con la parrilla
		## vieja (42 x 32 m) se solapaban unos con otros.
		var fila := i / 4
		var col := i % 4
		var x := -111.0 + col * 74.0
		## B7: filas cada 43 m desde z=108. Con 48 desde 118 la cuarta fila
		## (que ahora siempre existe, como solares) caía encima de la calle
		## exterior de z=262.
		var z := FILA_0_Z + fila * FILA_PASO
		var pos := Vector3(x, 0, z)
		if niv <= 0 and not obra:
			_solar_libre(e, pos)
			continue
		_edificio(e, niv, obra, pos)
		if obra:
			var total := float(Instalaciones.SEMANAS.get(String(e["k"]), Instalaciones.SEMANAS_POR_DEFECTO))
			var faltan := float(enObra[e["k"]])
			_obra_en_curso(pos, float(e["ancho"]), float(e["fondo"]), 6.0 * maxi(1, niv + 1), 1.0 - faltan / maxf(total, 1.0))
		var texto_r: String = ("%s 🏗 %d sem" % [str(e["n"]), int(enObra[e["k"]])]) if obra else ("%s  N%d" % [str(e["n"]), niv])
		_rotulo(pos + Vector3(0, 6.0 * maxi(1, niv) + 8.0, 0), texto_r,
			Color(1.0, 0.85, 0.4) if obra else Color(1, 1, 1))
		puntos_clic.append({"k": String(e["k"]), "n": str(e["n"]), "pos": pos + Vector3(0, 6.0 * maxi(1, niv) * 0.5, 0),
			"estado": "obra" if obra else "hecho"})
	_campus()

## EL CAMPUS (7-10-2026): un paseo peatonal delante de cada fila de
## instalaciones, el acceso pavimentado de cada puerta hasta el paseo, y bancos,
## farolillos y árboles en línea. Es lo que une los edificios en UN complejo en
## vez de cajas sueltas sobre una losa.
func _campus() -> void:
	var losa := _mat_simple(Color(0.8, 0.77, 0.7), 0.9)
	var banco := _mat_simple(Color(0.45, 0.32, 0.2), 0.8)
	var hoja := _mat_simple(Color(0.2, 0.42, 0.22), 0.9)
	var tronco := _mat_simple(Color(0.35, 0.26, 0.18), 0.9)
	var filas := int(ceil(float(EDIFICIOS.size()) / 4.0))
	for fila in filas:
		var z := FILA_0_Z + float(fila) * FILA_PASO + 19.0
		## La última fila da ya a la calle exterior: su acera hace de paseo.
		if z + 6.0 > EX_S - ANCHO_CALLE * 0.5 - 2.0:
			continue
		for lado in [-1.0, 1.0]:
			## Del borde del complejo a la avenida central, sin pisarla.
			_caja_en(Vector3(lado * 82.0, 0.05, z), Vector3(146.0, 0.1, 6.0), losa)
			for k in 7:
				var x: float = lado * (18.0 + float(k) * 20.0)
				_cil_en(Vector3(x, 1.4, z - 4.2), 0.18, 2.8, tronco)
				_cil_en(Vector3(x, 3.6, z - 4.2), 1.6, 2.6, hoja, 0.4)
				_caja_en(Vector3(x + 7.0, 0.35, z + 3.6), Vector3(2.2, 0.7, 0.6), banco)
		## El acceso de cada edificio de la fila hasta el paseo.
		for col in 4:
			var i := fila * 4 + col
			if i >= EDIFICIOS.size():
				break
			var e: Dictionary = EDIFICIOS[i]
			var x2 := -111.0 + float(col) * 74.0
			var z0 := FILA_0_Z + float(fila) * FILA_PASO + float(e["fondo"]) * 0.5
			var largo := maxf(1.0, (z - 3.0) - z0)
			_caja_en(Vector3(x2, 0.06, z0 + largo * 0.5), Vector3(7.0, 0.1, largo), losa)

func _edificio(e: Dictionary, niv: int, enObra: bool, pos: Vector3) -> void:
	## La ALTURA sale del nivel: 4 metros por planta. Es la senal visual mas barata
	## y mas clara de "aqui he invertido".
	var plantas: int = maxi(1, niv)
	## 6 m por planta y no 4: a 4 los edificios quedaban como losas aplastadas y no
	## se podian CONTAR las plantas de un vistazo, que es justo lo que tiene que
	## comunicar el nivel de la instalacion.
	var alto := 6.0 * plantas
	var ancho: float = float(e["ancho"]) * (1.0 + 0.06 * (plantas - 1))
	var fondo: float = float(e["fondo"]) * (1.0 + 0.06 * (plantas - 1))

	var mat: StandardMaterial3D
	if enObra and niv <= 0:
		## En obra y sin nivel todavia: se ve el esqueleto, no un edificio acabado.
		mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.45, 0.25)
		mat.roughness = 1.0
	else:
		## `Texturas.hormigon()` (17-9-2026): el comentario de esta funcion ya
		## PEDIA hormigon pintado desde antes de esta sesion -"nada de plastico
		## brillante"- pero nunca se conecto la fabrica de texturas de verdad,
		## solo se afino rugosidad/metalico sobre un color plano. DUPLICADO
		## antes de sobreescribir esos tres valores: son las paredes mas
		## repetidas del mapa -una entrada de cache por cada color de club que
		## exista, compartida entre todos los edificios de ese club.
		## Fachada clara con el color de la instalación en tono suave (antes
		## el color puro sobre el hormigón oscuro dejaba el complejo casi negro).
		## 7-10-2026: una sola paleta para todo el complejo -hormigón claro con
		## el color de la instalación muy suave y el acento del club-. Con la
		## textura de hormigón y el color al 45 % salían cajas casi negras.
		mat = _mat_simple((e["col"] as Color).lerp(Color(0.93, 0.92, 0.89), 0.72), 0.7)
	## CADA INSTALACIÓN CON SU ARQUITECTURA (7-10-2026, «a la ciudad le falta
	## mejorar las instalaciones»): hasta hoy el cuerpo era SIEMPRE la misma
	## caja y solo cambiaban los adornos, así que desde el mapa la piscina, el
	## museo y la tienda eran el mismo bloque repetido en cuadrícula. Ahora la
	## forma dice qué es: nave con bóveda, pabellón de cristal con el agua
	## dentro, torre de habitaciones, clínica escalonada, templo con columnas,
	## escuela en L, pabellón con terraza, caja de medios con cristal oscuro.
	var forma := String(FORMAS.get(String(e["k"]), "caja")) if not (enObra and niv <= 0) else "caja"
	huellas.append(Rect2(pos.x - ancho * 0.5, pos.z - fondo * 0.5, ancho, fondo))
	_cuerpo_instalacion(forma, pos, ancho, fondo, alto, plantas, mat)

	## Franja del color del club en el tejado: ata los edificios al club y no a
	## un poligono industrial cualquiera.
	## Solo las formas de tejado plano a la altura `alto` llevan la franja y
	## las máquinas: en una bóveda o un frontón atravesarían la cubierta.
	var plano := forma in ["caja", "medios", "tienda", "clinica", "escuela"]
	if plano:
		var techo := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(ancho + 0.6, 0.5, fondo + 0.6)
		if forma == "escuela":
			tm.size = Vector3(ancho + 0.6, 0.5, fondo * 0.56 + 0.6)
		techo.mesh = tm
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
		techo.material_override = tmat
		techo.position = pos + Vector3(0, alto + 0.25, -fondo * 0.22 if forma == "escuela" else 0.0)
		add_child(techo)

	_detalle_edificio(pos, ancho, fondo, alto, e, plano, not (forma in ["templo", "pabellon"]))
	_rasgo_instalacion(String(e["k"]), pos, ancho, fondo, alto, niv)
	if not enObra or niv > 0:
		_personal_en(String(e["k"]), pos, fondo, niv)

	etiquetas.append({
		"pos": pos + Vector3(0, alto + 3.0, 0),
		"texto": str(e["n"]) + ("  (en obra)" if enObra else ""),
		"nivel": niv,
	})

const FORMAS := {
	"ct": "nave", "gim": "nave", "piscina": "cristal", "resid": "torre",
	"med": "clinica", "rehab": "clinica", "museo": "templo", "acad": "escuela",
	"guarderia": "escuela", "cocina": "pabellon", "bienestar": "pabellon",
	"video": "medios", "pren": "medios", "esports": "medios", "com": "tienda",
}

func _cuerpo_instalacion(forma: String, pos: Vector3, ancho: float, fondo: float, alto: float, plantas: int, mat: StandardMaterial3D) -> void:
	match forma:
		"nave":
			## Nave deportiva: muro bajo y bóveda de cañón a lo largo.
			var muro := alto * 0.55 + 2.0
			_caja_en(pos + Vector3(0, muro * 0.5, 0), Vector3(ancho, muro, fondo), mat)
			_boveda(pos + Vector3(0, muro, 0), ancho, fondo, _mat_simple(Color(0.78, 0.8, 0.82), 0.35, 0.0), 0.42)
			_ventanas(pos, ancho, fondo, maxi(1, plantas / 2))
		"cristal":
			## Pabellón de cristal con la lámina de agua dentro y bóveda.
			var muro2 := maxf(6.0, alto * 0.6)
			var vidrio := StandardMaterial3D.new()
			vidrio.albedo_color = Color(0.62, 0.82, 0.9, 0.38)
			vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vidrio.roughness = 0.08
			vidrio.metallic = 0.3
			_caja_en(pos + Vector3(0, muro2 * 0.5, 0), Vector3(ancho, muro2, fondo), vidrio)
			var agua := StandardMaterial3D.new()
			agua.albedo_color = Color(0.1, 0.55, 0.78)
			agua.roughness = 0.05
			agua.emission_enabled = true
			agua.emission = Color(0.05, 0.25, 0.35)
			_caja_en(pos + Vector3(0, 0.35, 0), Vector3(ancho * 0.78, 0.3, fondo * 0.62), agua)
			_caja_en(pos + Vector3(0, 0.15, 0), Vector3(ancho - 0.6, 0.3, fondo - 0.6), _mat_simple(Color(0.9, 0.9, 0.88), 0.7))
			for k in 6:
				_caja_en(pos + Vector3(-ancho * 0.39 + float(k) * ancho * 0.156, 0.52, 0), Vector3(0.12, 0.06, fondo * 0.6), _mat_simple(Color.WHITE, 0.6))
			_boveda(pos + Vector3(0, muro2, 0), ancho, fondo, _mat_simple(Color(0.86, 0.9, 0.93), 0.3, 0.0), 0.35)
		"torre":
			## Residencia: torre estrecha y alta con balcones corridos.
			var a2 := ancho * 0.62
			var h := alto * 1.45 + 4.0
			_caja_en(pos + Vector3(0, 2.5, 0), Vector3(ancho, 5.0, fondo), mat)
			_caja_en(pos + Vector3(0, 5.0 + h * 0.5, -fondo * 0.12), Vector3(a2, h, fondo * 0.62), mat)
			var bal := _mat_simple(Color(0.95, 0.95, 0.93), 0.6)
			var pisos := int(h / 3.2)
			for k in pisos:
				_caja_en(pos + Vector3(0, 5.0 + 1.2 + float(k) * 3.2, -fondo * 0.12 + fondo * 0.31 + 0.6), Vector3(a2 + 0.4, 0.25, 1.2), bal)
			_ventanas(pos + Vector3(0, 0, -fondo * 0.12), a2, fondo * 0.62, maxi(2, int(h / 6.0)))
		"clinica":
			## Clínica: zócalo ancho y volumen blanco más estrecho encima.
			var blanco := _mat_simple(Color(0.95, 0.96, 0.97), 0.45)
			var bajo := maxf(5.0, alto * 0.55)
			_caja_en(pos + Vector3(0, bajo * 0.5, 0), Vector3(ancho, bajo, fondo), blanco)
			if alto > bajo + 1.0:
				_caja_en(pos + Vector3(-ancho * 0.12, bajo + (alto - bajo) * 0.5, -fondo * 0.1), Vector3(ancho * 0.7, alto - bajo, fondo * 0.75), blanco)
			_caja_en(pos + Vector3(0, bajo * 0.5, fondo * 0.5 + 0.05), Vector3(ancho * 0.9, bajo * 0.55, 0.1), _vidrio_oscuro())
			_ventanas(pos, ancho, fondo, plantas)
		"templo":
			## Museo: podio, cuerpo, columnata delante y frontón.
			var piedra := _mat_simple(Color(0.86, 0.82, 0.72), 0.75)
			_caja_en(pos + Vector3(0, 0.8, 1.5), Vector3(ancho + 4.0, 1.6, fondo + 7.0), piedra)
			var h2 := maxf(9.0, alto)
			_caja_en(pos + Vector3(0, 1.6 + h2 * 0.5, -1.0), Vector3(ancho, h2, fondo - 2.0), piedra)
			var cols := 6
			for k in cols:
				var x := -ancho * 0.42 + float(k) * ancho * 0.84 / float(cols - 1)
				_cil_en(pos + Vector3(x, 1.6 + (h2 - 1.2) * 0.5, fondo * 0.5 + 2.6), 0.75, h2 - 1.2, piedra)
			_caja_en(pos + Vector3(0, 1.6 + h2 - 0.6, fondo * 0.5 + 2.4), Vector3(ancho + 1.0, 1.2, 4.2), piedra)
			var fronton := MeshInstance3D.new()
			var pr := PrismMesh.new()
			pr.size = Vector3(ancho + 1.0, 3.2, 4.2)
			fronton.mesh = pr
			fronton.material_override = piedra
			fronton.position = pos + Vector3(0, 1.6 + h2 + 1.6, fondo * 0.5 + 2.4)
			add_child(fronton)
		"escuela":
			## Academia y guardería: escuela en L de ladrillo.
			var ladrillo := Texturas.hormigon(Color(0.66, 0.38, 0.3)).duplicate() as StandardMaterial3D
			ladrillo.roughness = 0.85
			_caja_en(pos + Vector3(0, alto * 0.5, -fondo * 0.22), Vector3(ancho, alto, fondo * 0.56), ladrillo)
			_caja_en(pos + Vector3(-ancho * 0.32, alto * 0.4, fondo * 0.18), Vector3(ancho * 0.36, alto * 0.8, fondo * 0.64), ladrillo)
			_ventanas(pos + Vector3(0, 0, -fondo * 0.22), ancho, fondo * 0.56, plantas)
		"pabellon":
			## Comedor y bienestar: planta baja acristalada y una cubierta que
			## vuela sobre la terraza.
			var h3 := maxf(5.0, alto * 0.7)
			_caja_en(pos + Vector3(0, h3 * 0.5, -1.0), Vector3(ancho - 2.0, h3, fondo - 2.0), mat)
			_caja_en(pos + Vector3(0, h3 * 0.5, fondo * 0.5 - 1.0 + 0.05), Vector3(ancho - 3.0, h3 * 0.7, 0.1), _vidrio_oscuro())
			_caja_en(pos + Vector3(0, h3 + 0.3, 1.5), Vector3(ancho + 3.0, 0.6, fondo + 5.0), _mat_simple(Color(0.88, 0.86, 0.8), 0.6))
			for sx in [-1.0, 1.0]:
				_cil_en(pos + Vector3(sx * (ancho * 0.5 + 0.8), h3 * 0.5, fondo * 0.5 + 3.2), 0.22, h3, _mat_simple(Color(0.3, 0.3, 0.32), 0.5))
		"medios":
			## Prensa, vídeo y juegos: caja con piel de cristal oscuro y franja.
			_caja_en(pos + Vector3(0, alto * 0.5, 0), Vector3(ancho, alto, fondo), mat)
			_caja_en(pos + Vector3(0, alto * 0.55, fondo * 0.5 + 0.06), Vector3(ancho * 0.94, alto * 0.7, 0.12), _vidrio_oscuro())
			_caja_en(pos + Vector3(ancho * 0.5 + 0.06, alto * 0.55, 0), Vector3(0.12, alto * 0.7, fondo * 0.9), _vidrio_oscuro())
		"tienda":
			## Tienda oficial: escaparate entero de cristal y cartel del club.
			_caja_en(pos + Vector3(0, alto * 0.5, 0), Vector3(ancho, alto, fondo), mat)
			var vit := _vidrio_oscuro()
			vit.emission_enabled = true
			vit.emission = Color(0.35, 0.3, 0.2)
			_caja_en(pos + Vector3(0, 2.4, fondo * 0.5 + 0.06), Vector3(ancho * 0.92, 4.2, 0.12), vit)
			_caja_en(pos + Vector3(0, alto + 1.4, fondo * 0.5 - 0.5), Vector3(ancho * 0.6, 2.4, 0.4), _mat_simple(_color_club("c1", Color(0.2, 0.5, 0.3)), 0.5, 0.25))
		_:
			_caja_en(pos + Vector3(0, alto * 0.5, 0), Vector3(ancho, alto, fondo), mat)
			_ventanas(pos, ancho, fondo, plantas)

## Una bóveda de cañón sobre un muro: medio cilindro a lo ancho, aplanado.
func _boveda(base: Vector3, ancho: float, fondo: float, m: Material, aplanado: float) -> void:
	var b := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = fondo * 0.5
	cm.bottom_radius = fondo * 0.5
	cm.height = ancho
	cm.radial_segments = 24
	b.mesh = cm
	b.material_override = m
	b.rotation.z = PI * 0.5
	b.scale = Vector3(1.0, 1.0, 1.0)
	b.position = base
	## Aplanado en vertical: el eje local X queda vertical tras el giro.
	b.scale = Vector3(aplanado * 2.0, 1.0, 1.0)
	add_child(b)

func _vidrio_oscuro() -> StandardMaterial3D:
	var v := StandardMaterial3D.new()
	v.albedo_color = Color(0.12, 0.18, 0.24)
	v.metallic = 0.7
	v.roughness = 0.12
	return v

## Lo que convierte una caja con ventanas en un EDIFICIO: la marquesina de la
## entrada con sus pilares, las máquinas de la cubierta y una banda de rótulo
## del color del club sobre la puerta. Son cuatro piezas y cambian la lectura
## por completo -sin ellas, a media distancia todas las instalaciones son la
## misma caja pintada de otro color.
## ============================================================================
##  CADA INSTALACIÓN CON SU CARA (26-9-2026)
## ============================================================================
## "Que las instalaciones sean mejores": hasta hoy las quince eran la misma caja
## con marquesina y tres bultos en el techo, solo cambiaba el color. Ahora cada
## una lleva lo que la delata desde el mapa: la cruz roja y la ambulancia del
## centro médico, la cristalera del gimnasio, las parabólicas de la sala de
## prensa, el pórtico con la copa del museo, los toldos de la tienda, los
## columpios de la guardería, el neón de la sala de juegos... Y más cuanto más
## nivel: una instalación grande se nota también en lo que tiene alrededor.
## TINTES PARA EL KIT (7-10-2026): los edificios del kit de Kenney salían
## todos del mismo blanco. Se multiplica su textura por un tono pastel (uno de
## ocho, cacheado por material) para que las calles tengan fachadas de colores.
const TINTES := [Color(1.0, 0.86, 0.72), Color(0.86, 0.93, 1.0), Color(0.9, 1.0, 0.88), Color(1.0, 0.82, 0.8),
	Color(1.0, 0.95, 0.75), Color(0.92, 0.86, 1.0), Color(0.95, 0.78, 0.62), Color(0.82, 0.9, 0.9)]
var _cache_tintes := {}

func tenir(n: Node, semilla: int) -> void:
	var t: int = absi(semilla) % TINTES.size()
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for s in m3.mesh.get_surface_count():
			var orig := m3.mesh.surface_get_material(s) as StandardMaterial3D
			if orig == null:
				continue
			var clave := "%d|%d" % [orig.get_instance_id(), t]
			var m: StandardMaterial3D = _cache_tintes.get(clave)
			if m == null:
				m = orig.duplicate() as StandardMaterial3D
				m.albedo_color = orig.albedo_color * TINTES[t]
				_cache_tintes[clave] = m
			m3.set_surface_override_material(s, m)

func _mat_simple(c: Color, rug := 0.6, emi := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	if emi > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emi
	return m

func _caja_en(pos: Vector3, tam: Vector3, m: Material, giro := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = giro
	add_child(mi)
	return mi

func _cil_en(pos: Vector3, r: float, h: float, m: Material, r_arriba := -1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r if r_arriba < 0.0 else r_arriba
	c.bottom_radius = r
	c.height = h
	mi.mesh = c
	mi.material_override = m
	mi.position = pos
	add_child(mi)
	return mi

func _rasgo_instalacion(k: String, pos: Vector3, ancho: float, fondo: float, alto: float, niv: int) -> void:
	var fz: float = fondo * 0.5
	var blanco := _mat_simple(Color(0.95, 0.95, 0.94), 0.5)
	var c1 := _color_club("c1", Color(0.2, 0.5, 0.3))
	match k:
		"med", "rehab":
			## Cruz roja luminosa en la fachada y una ambulancia en la puerta.
			var rojo := _mat_simple(Color(0.9, 0.1, 0.12), 0.4, 1.4)
			var yc := minf(alto - 2.5, 9.0)
			_caja_en(pos + Vector3(ancho * 0.3, yc, fz + 0.3), Vector3(3.6, 1.1, 0.3), rojo)
			_caja_en(pos + Vector3(ancho * 0.3, yc, fz + 0.3), Vector3(1.1, 3.6, 0.3), rojo)
			var amb: PackedScene = load("res://assets/ciudad/kenney_cars/ambulance.glb")
			if amb != null:
				var a: Node3D = amb.instantiate()
				a.scale = Vector3.ONE * 1.65
				a.position = pos + Vector3(-ancho * 0.32, 0, fz + 8.0)
				a.rotation.y = PI * 0.5
				add_child(a)
		"gim":
			## Cristalera a toda la fachada, con máquinas asomando detrás.
			var vidrio := Texturas.cristal(true, false)
			_caja_en(pos + Vector3(0, minf(alto, 6.0) * 0.5, fz + 0.15), Vector3(ancho * 0.8, minf(alto, 6.0) - 0.8, 0.2), vidrio)
			var metal := _mat_simple(Color(0.2, 0.2, 0.22), 0.4)
			for i in 5:
				_caja_en(pos + Vector3(-ancho * 0.3 + i * ancho * 0.15, 0.8, fz - 1.6), Vector3(0.9, 1.6, 2.0), metal)
		"acad", "resid":
			## Tejado a dos aguas y arcos de fútbol pequeños delante.
			var teja := _mat_simple(Color(0.62, 0.28, 0.18), 0.8)
			for s in [-1.0, 1.0]:
				var faldon := _caja_en(pos + Vector3(0, alto + 2.2, s * fondo * 0.25), Vector3(ancho + 1.0, 0.4, fondo * 0.56), teja)
				faldon.rotation.x = -0.42 * s
			if k == "acad":
				for s2 in [-1.0, 1.0]:
					_arquito(pos + Vector3(s2 * ancho * 0.3, 0, fz + 12.0), blanco)
			else:
				## Bicicletas de los chicos: soporte y ruedas del kit.
				for i in 4:
					_poner_extra("wheel-default", pos + Vector3(-ancho * 0.35 + i * 1.2, 0.5, fz + 3.0), 1.4, PI * 0.5)
		"cocina":
			## Terraza con parasoles y chimenea de cocina.
			var paras: PackedScene = load("res://assets/ciudad/kenney_comercial/detail-parasol-a.glb")
			for i in 3:
				if paras != null:
					var pa: Node3D = paras.instantiate()
					pa.scale = Vector3.ONE * 5.0
					pa.position = pos + Vector3(-ancho * 0.3 + i * ancho * 0.3, 0, fz + 9.0)
					add_child(pa)
			var acero := _mat_simple(Color(0.7, 0.7, 0.72), 0.3)
			_cil_en(pos + Vector3(ancho * 0.35, alto + 2.5, -fondo * 0.3), 0.6, 5.0, acero)
		"video", "pren":
			## Parabólicas y antena en el techo; la sala de prensa, con el
			## "photocall" de patrocinadores en la entrada.
			var gris := _mat_simple(Color(0.88, 0.88, 0.9), 0.4)
			for i in 2:
				var plato := _cil_en(pos + Vector3(-ancho * 0.25 + i * 3.5, alto + 2.2, 0), 1.5, 0.3, gris, 0.4)
				plato.rotation.x = -0.9
			_cil_en(pos + Vector3(ancho * 0.3, alto + 4.0, -fondo * 0.2), 0.12, 8.0, gris)
			if k == "pren":
				var photocall := _caja_en(pos + Vector3(0, 1.6, fz + 6.0), Vector3(8.0, 3.2, 0.2), _mat_simple(c1, 0.6))
				photocall.rotation.y = 0.0
		"museo":
			## Pórtico de columnas y la copa dorada sobre su pedestal.
			var piedra := _mat_simple(Color(0.86, 0.83, 0.76), 0.7)
			for i in 6:
				_cil_en(pos + Vector3(-ancho * 0.35 + i * ancho * 0.14, 3.5, fz + 2.0), 0.55, 7.0, piedra)
			_caja_en(pos + Vector3(0, 7.3, fz + 2.0), Vector3(ancho * 0.85, 0.8, 3.0), piedra)
			var oro := _mat_simple(Color(0.95, 0.75, 0.2), 0.25)
			oro.metallic = 0.9
			_caja_en(pos + Vector3(0, 0.8, fz + 11.0), Vector3(2.0, 1.6, 2.0), piedra)
			_cil_en(pos + Vector3(0, 2.4, fz + 11.0), 0.25, 1.6, oro, 0.25)
			_cil_en(pos + Vector3(0, 3.8, fz + 11.0), 0.3, 1.4, oro, 1.1)
		"com":
			## Escaparates con toldos a rayas del club.
			var toldo: PackedScene = load("res://assets/ciudad/kenney_comercial/detail-awning-wide.glb")
			for i in 2:
				if toldo != null:
					var t: Node3D = toldo.instantiate()
					t.scale = Vector3.ONE * 5.0
					t.position = pos + Vector3(-ancho * 0.25 + i * ancho * 0.5, 2.5, fz + 0.4)
					add_child(t)
			_caja_en(pos + Vector3(0, 1.8, fz + 0.12), Vector3(ancho * 0.75, 2.6, 0.12), Texturas.cristal(true, true))
		"guarderia":
			## Parque infantil: tobogán, columpio y arenero de colores.
			var col := [Color(0.95, 0.3, 0.3), Color(0.3, 0.6, 0.95), Color(0.98, 0.8, 0.2)]
			var base_p := pos + Vector3(0, 0, fz + 10.0)
			var tob := _caja_en(base_p + Vector3(-4, 1.2, 0), Vector3(1.2, 0.2, 5.0), _mat_simple(col[0]))
			tob.rotation.x = 0.45
			for s in [-1.0, 1.0]:
				_cil_en(base_p + Vector3(3.0 + s * 1.5, 1.5, 0), 0.1, 3.0, _mat_simple(col[1]))
			_caja_en(base_p + Vector3(3.0, 3.0, 0), Vector3(3.2, 0.15, 0.15), _mat_simple(col[1]))
			_caja_en(base_p + Vector3(0, 0.1, 4.0), Vector3(4.0, 0.2, 3.0), _mat_simple(Color(0.9, 0.82, 0.6)))
		"bienestar":
			## Cúpula de cristal y jardín de piedras.
			var dom := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = minf(ancho, fondo) * 0.22
			sm.height = sm.radius
			sm.is_hemisphere = true
			dom.mesh = sm
			dom.material_override = Texturas.cristal(true, false)
			dom.position = pos + Vector3(0, alto + 0.3, 0)
			add_child(dom)
		"esports":
			## Neón del color del club alrededor del techo y pantalla gigante.
			var neon := _mat_simple(c1.lightened(0.3), 0.3, 3.0)
			for s in [-1.0, 1.0]:
				_caja_en(pos + Vector3(0, alto - 0.3, s * (fondo * 0.5 + 0.1)), Vector3(ancho, 0.25, 0.1), neon)
				_caja_en(pos + Vector3(s * (ancho * 0.5 + 0.1), alto - 0.3, 0), Vector3(0.1, 0.25, fondo), neon)
			_caja_en(pos + Vector3(0, minf(alto, 6.0) * 0.55, fz + 0.2), Vector3(ancho * 0.5, 2.6, 0.15), _mat_simple(Color(0.2, 0.5, 1.0), 0.3, 1.6))
		"ct":
			## Placas solares en el techo y una pizarra táctica gigante.
			var panel := _mat_simple(Color(0.08, 0.12, 0.25), 0.2)
			panel.metallic = 0.6
			for i in 4:
				var pl := _caja_en(pos + Vector3(-ancho * 0.3 + i * ancho * 0.2, alto + 1.0, fondo * 0.15), Vector3(ancho * 0.16, 0.1, 4.0), panel)
				pl.rotation.x = -0.4
			_caja_en(pos + Vector3(-ancho * 0.5 - 0.2, minf(alto, 6.0) * 0.5, 0), Vector3(0.2, 3.5, 7.0), _mat_simple(Color(0.1, 0.35, 0.18), 0.6))
		"piscina":
			## Trampolín y escalerilla junto a la entrada.
			_caja_en(pos + Vector3(ancho * 0.3, 1.5, fz + 3.0), Vector3(0.8, 0.1, 3.5), blanco)
			_cil_en(pos + Vector3(ancho * 0.3, 0.75, fz + 1.5), 0.15, 1.5, blanco)
	## Con nivel alto, bandera del club y jardineras en la entrada.
	if niv >= 4:
		var mastil := _cil_en(pos + Vector3(-ancho * 0.5 - 3.0, 5.0, fz + 3.0), 0.1, 10.0, blanco)
		mastil.name = "Mastil"
		_caja_en(pos + Vector3(-ancho * 0.5 - 2.0, 9.2, fz + 3.0), Vector3(2.0, 1.2, 0.05), _mat_simple(c1, 0.8))
		var verde := _mat_simple(Color(0.18, 0.4, 0.16), 0.9)
		for s in [-1.0, 1.0]:
			_caja_en(pos + Vector3(s * ancho * 0.35, 0.5, fz + 5.0), Vector3(3.0, 1.0, 1.2), _mat_simple(Color(0.5, 0.5, 0.48)))
			_caja_en(pos + Vector3(s * ancho * 0.35, 1.2, fz + 5.0), Vector3(2.8, 0.6, 1.0), verde)

func _arquito(p: Vector3, m: Material) -> void:
	for s in [-1.0, 1.0]:
		_cil_en(p + Vector3(s * 1.8, 0.9, 0), 0.07, 1.8, m)
	var trav := _cil_en(p + Vector3(0, 1.8, 0), 0.07, 3.6, m)
	trav.rotation.z = PI * 0.5

## EL PERSONAL, A LA VISTA (26-9-2026, "que tengan trabajadores reales"): en la
## puerta de cada instalación está su gente, con el uniforme de su oficio
## (bata blanca en el médico, chaquetilla en el comedor, chándal del club en el
## centro de entrenamiento...). Uno por instalación, dos desde nivel 4 y tres
## desde nivel 7, como su plantilla de verdad (`Trabajadores`).
const UNIFORMES := {
	"med": ["f2f2f2", "cfe0f5"], "rehab": ["f2f2f2", "b3d4f0"], "cocina": ["ffffff", "222222"],
	"gim": ["111111", "c62828"], "piscina": ["d32f2f", "ffeb3b"], "guarderia": ["f9a825", "2e7d32"],
	"museo": ["2b2b33", "d4af37"], "com": ["club", "ffffff"], "ct": ["club", "club2"],
	"acad": ["club", "club2"], "resid": ["455a64", "ffffff"], "video": ["263238", "90a4ae"],
	"pren": ["1f2a44", "ffffff"], "bienestar": ["8d6e63", "d7ccc8"], "esports": ["6a1b9a", "00e5ff"],
}

func _personal_en(k: String, pos: Vector3, fondo: float, niv: int) -> void:
	if not is_inside_tree():
		_personal_pendiente.append([k, pos, fondo, niv])
		return
	var cuantos := 1 + (1 if niv >= 4 else 0) + (1 if niv >= 7 else 0)
	var cols: Array = UNIFORMES.get(k, ["455a64", "ffffff"])
	var c1 := _color_club("c1", Color(0.2, 0.5, 0.3))
	var c2 := _color_club("c2", Color.WHITE)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(k + "|personal")
	for i in cuantos:
		var raiz := Node3D.new()
		add_child(raiz)
		var col_a: Color = c1 if cols[0] == "club" else Color(String(cols[0]))
		var col_b: Color = c2 if cols[1] == "club2" else (c1 if cols[1] == "club" else Color(String(cols[1])))
		var asp := {"cuerpo": "female" if rng.randf() < 0.45 else "male", "ropa": "polo",
			"c_ropa": col_a.to_html(false), "c_ropa2": col_b.to_html(false),
			"pelo": PersonajeDT.CORTES[rng.randi() % 10], "color_pelo": PersonajeDT.COLORES_PELO[rng.randi() % 6],
			"piel": PersonajeDT.PIELES[rng.randi() % PersonajeDT.PIELES.size()], "reloj": false,
			"altura": rng.randf_range(1.6, 1.88)}
		if k in ["cocina", "med", "rehab"]:
			## Bata o chaquetilla lisa, blanca de arriba abajo.
			asp["c_ropa2"] = col_a.to_html(false)
		var d := PersonajeDT.crear(raiz, asp, c1, c2)
		if d.is_empty():
			raiz.queue_free()
			continue
		raiz.position = pos + Vector3(-4.0 + i * 3.2, 0, fondo * 0.5 + 6.0 + rng.randf_range(-1.0, 1.0))
		raiz.rotation.y = rng.randf_range(-0.6, 0.6)
		var ap: AnimationPlayer = d["anim"]
		for g: String in ["hablar", "brazos_jarra", "parado"]:
			if ap.has_animation(g) and rng.randf() < 0.6:
				ap.play(g)
				ap.seek(rng.randf() * ap.current_animation_length, true)
				break
		for mi in raiz.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).visibility_range_end = 260.0

var _personal_pendiente: Array = []

func _notification(que: int) -> void:
	if que == NOTIFICATION_ENTER_TREE and not _personal_pendiente.is_empty():
		var lista := _personal_pendiente.duplicate()
		_personal_pendiente.clear()
		for p: Array in lista:
			_personal_en(String(p[0]), p[1], float(p[2]), int(p[3]))

func _detalle_edificio(pos: Vector3, ancho: float, fondo: float, alto: float, e: Dictionary, cubierta := true, marquesina := true) -> void:
	## Se llamaba "hormigon" desde antes de esta sesion sin serlo -color plano
	## puro. `Texturas.hormigon()` de verdad ahora (17-9-2026), duplicado para
	## conservar la rugosidad 0.7 ya afinada aqui en vez del 0.92 por defecto.
	var hormigon: StandardMaterial3D = Texturas.hormigon(Color(0.80, 0.80, 0.79)).duplicate()
	hormigon.roughness = 0.7
	var acento := StandardMaterial3D.new()
	acento.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
	acento.roughness = 0.5
	acento.metallic = 0.2

	## MARQUESINA: un voladizo sobre la entrada, en la cara sur (la que mira al
	## acceso), con dos pilares. Es el gesto que dice "por aquí se entra".
	var z_frente: float = fondo * 0.5
	if not marquesina:
		return
	var mar := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(ancho * 0.5, 0.45, 5.0)
	mar.mesh = mm
	mar.material_override = hormigon
	mar.position = pos + Vector3(0, 4.6, z_frente + 2.2)
	add_child(mar)
	for lado in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.28
		pm.bottom_radius = 0.28
		pm.height = 4.6
		pil.mesh = pm
		pil.material_override = hormigon
		pil.position = pos + Vector3(lado * ancho * 0.21, 2.3, z_frente + 4.2)
		add_child(pil)

	## RÓTULO: banda de color del club sobre la puerta. Ata el edificio al club
	## igual que la franja del tejado, pero a la altura de la vista.
	var rot := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(ancho * 0.46, 1.5, 0.3)
	rot.mesh = rm
	rot.material_override = acento
	rot.position = pos + Vector3(0, 5.9, z_frente + 0.2)
	add_child(rot)

	## MÁQUINAS DE CUBIERTA: climatizadoras y un cajón de escalera. Es lo que
	## rompe la silueta plana del tejado, que es lo que más delata a una caja.
	if not cubierta:
		return
	var maq: StandardMaterial3D = Texturas.metal(Color(0.58, 0.59, 0.61), 0.55).duplicate()
	maq.metallic = 0.35
	for par in [
			{"p": Vector3(-ancho * 0.22, 0, -fondo * 0.18), "s": Vector3(4.2, 2.0, 3.2)},
			{"p": Vector3(ancho * 0.18, 0, fondo * 0.2), "s": Vector3(3.0, 1.5, 2.6)},
			{"p": Vector3(ancho * 0.3, 0, -fondo * 0.26), "s": Vector3(2.4, 2.8, 2.4)},
		]:
		var m2 := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = par["s"]
		m2.mesh = bm2
		m2.material_override = maq
		var s2: Vector3 = par["s"]
		m2.position = pos + (par["p"] as Vector3) + Vector3(0, alto + 0.5 + s2.y * 0.5, 0)
		add_child(m2)

func _ventanas(pos: Vector3, ancho: float, fondo: float, plantas: int) -> void:
	## Una tira de ventanas por planta. Sin esto las cajas parecen contenedores;
	## con esto se leen como edificios y ademas se CUENTAN las plantas de un vistazo.
	## CRISTAL de verdad, no una franja azul pintada: metalico y muy pulido, para
	## que refleje el cielo. Es el detalle que mas hace por el realismo de un
	## edificio — un cristal que no refleja nada se lee como carton.
	##
	## CADA TIRA CON SU PROPIO MATERIAL (12-9-2026): antes había UN solo
	## material por edificio entero, compartido por todas sus plantas y caras,
	## así que de noche el edificio se encendía como un bloque -todo o nada-,
	## que no es como se ve una oficina real. Con un material por tira y un
	## azar propio guardado en cada uno, `encender_luces()` las enciende en
	## umbrales distintos: unas plantas ya de tarde, otras bien entrada la
	## noche, y unas pocas se quedan más apagadas siempre -el piso vacío o el
	## que ya se fue a casa-. La semilla sale de la posición del edificio, no
	## de `randf()` a secas, para que el mismo edificio se vea IGUAL cada vez
	## que se construye la ciudad, no parpadeando entre partidas.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pos)
	## Marco oscuro entre plantas: separa los pisos y da grosor a la fachada.
	## Este sí se comparte -no depende de la hora, no necesita variar-.
	## Compartido entre TODAS las plantas de TODOS los edificios del mapa.
	var marco: StandardMaterial3D = Texturas.metal(Color(0.13, 0.13, 0.14), 0.5).duplicate()
	marco.metallic = 0.35
	for p in range(plantas):
		var y := 6.0 * p + 3.0
		for lado in [-1.0, 1.0]:
			for eje in [0, 1]:
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.10, 0.14, 0.18)
				mat.metallic = 0.95
				mat.metallic_specular = 0.9
				mat.roughness = 0.06
				mat.emission_enabled = true
				## De día un reflejo apagado; de noche, luz encendida dentro.
				## Lo sube `encender_luces()`, que lee `_azar_ventana` de aquí.
				mat.emission = Color(0.98, 0.86, 0.58)
				mat.emission_energy_multiplier = 0.18
				mat.set_meta("_azar_ventana", rng.randf())
				_ventanas_mat.append(mat)
				var v := MeshInstance3D.new()
				var vm := BoxMesh.new()
				var m2 := MeshInstance3D.new()
				var mm := BoxMesh.new()
				var off: Vector3
				if eje == 0:
					vm.size = Vector3(ancho * 0.84, 1.9, 0.12)
					mm.size = Vector3(ancho * 0.88, 2.5, 0.09)
					off = Vector3(0, y, lado * (fondo * 0.5 + 0.07))
				else:
					## Tambien en los costados: antes solo habia ventanas en dos
					## caras y desde media vuelta el edificio parecia un muro ciego.
					vm.size = Vector3(0.12, 1.9, fondo * 0.8)
					mm.size = Vector3(0.09, 2.5, fondo * 0.84)
					off = Vector3(lado * (ancho * 0.5 + 0.07), y, 0)
				v.mesh = vm
				v.material_override = mat
				v.position = pos + off
				m2.mesh = mm
				m2.material_override = marco
				m2.position = pos + off * 0.995
				add_child(m2)
				add_child(v)

## El huerto: bancales de cultivo en hileras y un invernadero al lado. Cuántos
## bancales salen depende del nivel, igual que las plantas de un edificio: es
## la misma promesa de siempre -lo que construyes se VE-, solo que aquí crece
## a lo ancho porque un huerto no tiene pisos.
func _huerto() -> void:
	var niv := int(datos.get("inst", {}).get("huerto", 0))
	if niv <= 0:
		return
	var hileras: int = clampi(niv * 2, 2, 10)

	var tierra: StandardMaterial3D = Texturas.hormigon(Color(0.32, 0.23, 0.16)).duplicate()
	tierra.roughness = 0.98
	var planta := StandardMaterial3D.new()
	planta.albedo_color = Color(0.28, 0.52, 0.20)
	planta.roughness = 0.9

	for i in range(hileras):
		var z: float = HUERTO_EN.z - (hileras - 1) * 2.4 + i * 4.8
		var bancal := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(26.0, 0.5, 3.0)
		bancal.mesh = bm
		bancal.material_override = tierra
		bancal.position = Vector3(HUERTO_EN.x, 0.25, z)
		add_child(bancal)
		## La mata de encima, en cubos bajos: a la altura de cámara del mapa,
		## un bancal de tierra pelada y uno plantado tienen que distinguirse.
		var mata := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = Vector3(24.0, 0.9, 1.9)
		mata.mesh = mm
		mata.material_override = planta
		mata.position = Vector3(HUERTO_EN.x, 0.9, z)
		add_child(mata)

	## El invernadero: cristal de verdad -el mismo material translúcido que
	## usan las ventanas de los edificios- sobre un zócalo claro.
	var inv := MeshInstance3D.new()
	var im := BoxMesh.new()
	im.size = Vector3(10.0, 5.0, 14.0)
	inv.mesh = im
	var cristal := StandardMaterial3D.new()
	cristal.albedo_color = Color(0.72, 0.88, 0.80, 0.45)
	cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cristal.metallic = 0.5
	cristal.roughness = 0.12
	inv.material_override = cristal
	inv.position = HUERTO_EN + Vector3(-22.0, 2.5, 0)
	add_child(inv)
	_cartel(HUERTO_EN + Vector3(0, 0, -(hileras * 2.4 + 10.0)), "Huerto del club", true)

# ---------------------------------------------------------- deporte de verdad
#
# "Para potenciar el concepto de CIUDAD DEPORTIVA, sumar un polideportivo
# cerrado, una piscina olímpica o canchas secundarias" -del análisis que trajo
# el usuario, y es la pega más justa de todas: un complejo con cuatro cajas de
# oficinas y unos campos de fútbol es una sede administrativa, no una ciudad
# deportiva. Las tres cosas van atadas a instalaciones que YA existen en
# `Instalaciones.CATALOGO`, así que aparecen cuando las construyes y no antes.

## La piscina olímpica: 50 x 25 m reales, con sus ocho calles marcadas y el
## borde de playa. Sale del nivel de `piscina`.
func _piscina_olimpica() -> void:
	if int(datos.get("inst", {}).get("piscina", 0)) <= 0:
		return
	var centro := Vector3(-112.0, 0, -60.0)

	var borde := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(62.0, 0.4, 37.0)
	borde.mesh = bm
	## El borde de la piscina, hormigon real (17-9-2026).
	var mb: StandardMaterial3D = Texturas.hormigon(Color(0.86, 0.86, 0.83)).duplicate()
	mb.roughness = 0.85
	borde.material_override = mb
	borde.position = centro + Vector3(0, 0.2, 0)
	add_child(borde)

	var agua := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(50, 25)
	## Subdividido para que el shader del agua tenga vértices que mover: es la
	## misma trampa que ya se pagó con el río.
	pl.subdivide_width = 26
	pl.subdivide_depth = 14
	agua.mesh = pl
	var sh := load(RUTA_SHADER_AGUA)
	if sh != null:
		var sm := ShaderMaterial.new()
		sm.shader = sh
		## Agua de piscina: turquesa, casi sin ola -una piscina no tiene
		## oleaje de río- y con la escala de onda mucho más fina.
		sm.set_shader_parameter("color_hondo", Color(0.05, 0.34, 0.44))
		sm.set_shader_parameter("color_orilla", Color(0.30, 0.70, 0.78))
		sm.set_shader_parameter("altura_ola", 0.09)
		sm.set_shader_parameter("escala_ola", 0.42)
		sm.set_shader_parameter("velocidad", 0.9)
		agua.material_override = sm
	agua.position = centro + Vector3(0, 0.45, 0)
	add_child(agua)

	## Las ocho calles: corcheras a lo largo. Sin ellas es un estanque azul.
	var corchera := StandardMaterial3D.new()
	corchera.albedo_color = Color(0.92, 0.72, 0.18)
	corchera.roughness = 0.7
	for i in range(7):
		var c := MeshInstance3D.new()
		var cbm := BoxMesh.new()
		cbm.size = Vector3(50.0, 0.22, 0.3)
		c.mesh = cbm
		c.material_override = corchera
		c.position = centro + Vector3(0, 0.6, -10.9 + i * 3.12)
		add_child(c)
	_cartel(centro + Vector3(0, 0, -24.0), "Piscina olímpica", true)

## El polideportivo: una nave con cubierta curva -lo que de lejos distingue un
## pabellón de una caja de oficinas-. Sale del nivel de `gim`.
func _polideportivo() -> void:
	if int(datos.get("inst", {}).get("gim", 0)) < 2:
		return
	var centro := Vector3(112.0, 0, -130.0)
	## Hormigon real (17-9-2026).
	var muro: StandardMaterial3D = Texturas.hormigon(Color(0.80, 0.81, 0.83)).duplicate()
	muro.roughness = 0.6
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(46.0, 11.0, 30.0)
	cuerpo.mesh = bm
	cuerpo.material_override = muro
	cuerpo.position = centro + Vector3(0, 5.5, 0)
	add_child(cuerpo)
	_ventanas(centro, 46.0, 30.0, 1)

	## La cubierta curva, hecha con medio cilindro tumbado. Es LA silueta de un
	## pabellón: sin ella, esto sería otra caja más del complejo.
	var techo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 15.5
	cm.bottom_radius = 15.5
	cm.height = 46.0
	cm.radial_segments = 22
	techo.mesh = cm
	## Cubierta metalica real (17-9-2026), duplicada para conservar el color
	## mezclado con el del club y el metalico ya afinado.
	var mt: StandardMaterial3D = Texturas.metal(
		_color_club("c1", Color(0.2, 0.5, 0.3)).lerp(Color(0.75, 0.76, 0.78), 0.45), 0.45).duplicate()
	mt.metallic = 0.35
	techo.material_override = mt
	techo.position = centro + Vector3(0, 11.0, 0)
	techo.rotation = Vector3(0, 0, PI * 0.5)
	techo.scale = Vector3(1.0, 1.0, 0.42)
	add_child(techo)
	_cartel(centro + Vector3(0, 0, -20.0), "Polideportivo", true)

## Canchas de tenis y pádel, en batería. Salen del nivel del centro de
## entrenamiento: son las "canchas secundarias" que pedía el análisis.
func _canchas_secundarias() -> void:
	var niv := int(datos.get("inst", {}).get("ct", 0))
	if niv < 2:
		return
	var cuantas: int = clampi(niv, 2, 6)
	var base := Vector3(112.0, 0, -20.0)
	var suelo := StandardMaterial3D.new()
	suelo.albedo_color = Color(0.32, 0.44, 0.58)
	suelo.roughness = 0.9
	var linea := StandardMaterial3D.new()
	linea.albedo_color = Color(0.94, 0.94, 0.92)
	linea.roughness = 0.8
	## Es tela de verdad -una red de tenis-, no plastico (17-9-2026).
	var red: StandardMaterial3D = Texturas.tela(Color(0.16, 0.17, 0.18)).duplicate()
	red.roughness = 0.85
	for i in range(cuantas):
		var c := base + Vector3((i % 2) * 26.0 - 13.0, 0, (i / 2) * 18.0)
		var pista := MeshInstance3D.new()
		var pl := PlaneMesh.new()
		pl.size = Vector2(22, 14)
		pista.mesh = pl
		pista.material_override = suelo
		pista.position = c + Vector3(0, 0.05, 0)
		add_child(pista)
		## Líneas y red: cuatro cajas finas. A la escala del mapa es justo lo
		## que hace falta para que se lea "cancha" y no "rectángulo azul".
		for l in [
				{"s": Vector3(18.0, 0.03, 0.2), "p": Vector3(0, 0, -4.6)},
				{"s": Vector3(18.0, 0.03, 0.2), "p": Vector3(0, 0, 4.6)},
				{"s": Vector3(0.2, 0.03, 9.4), "p": Vector3(-9.0, 0, 0)},
				{"s": Vector3(0.2, 0.03, 9.4), "p": Vector3(9.0, 0, 0)},
			]:
			var m := MeshInstance3D.new()
			var bm2 := BoxMesh.new()
			bm2.size = l["s"]
			m.mesh = bm2
			m.material_override = linea
			m.position = c + (l["p"] as Vector3) + Vector3(0, 0.08, 0)
			add_child(m)
		var neta := MeshInstance3D.new()
		var nm := BoxMesh.new()
		nm.size = Vector3(0.12, 1.05, 9.6)
		neta.mesh = nm
		neta.material_override = red
		neta.position = c + Vector3(0, 0.55, 0)
		add_child(neta)
	_cartel(base + Vector3(0, 0, -14.0), "Tenis y pádel", true)

# ------------------------------------------------------- parques y transporte

## EL PARQUE DEL BARRIO: "faltan parques urbanos o plazas recreativas dentro
## del barrio residencial para que los habitantes tengan zonas de descanso".
## Un césped propio más claro que el campo, caminos en cruz, un estanque y
## arbolado denso: es lo que convierte una hilera de casas en un sitio donde
## se vive.
func _parque_barrio() -> void:
	var centro := BARRIO_EN + Vector3(0, 0, 66.0)
	var cesp := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(96, 72)
	cesp.mesh = pl
	## `Texturas.cesped()` (17-9-2026): el parque del barrio, y de paso su
	## primer call site en todo el proyecto -estaba escrita y sin conectar.
	var mc: StandardMaterial3D = Texturas.cesped(Color(0.26, 0.50, 0.26)).duplicate()
	mc.roughness = 0.96
	cesp.material_override = mc
	cesp.position = centro + Vector3(0, 0.07, 0)
	add_child(cesp)

	## `Texturas.asfalto()` reutilizado para el camino de tierra compactada
	## -mismo generador de grano/rugosidad, con un tinte claro de arena en vez
	## del gris oscuro habitual.
	var camino: StandardMaterial3D = Texturas.asfalto(Color(0.68, 0.62, 0.52)).duplicate()
	camino.roughness = 0.92
	for l in [
			{"s": Vector3(96.0, 0.06, 4.5), "p": Vector3.ZERO},
			{"s": Vector3(4.5, 0.06, 72.0), "p": Vector3.ZERO},
		]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = l["s"]
		m.mesh = bm
		m.material_override = camino
		m.position = centro + (l["p"] as Vector3) + Vector3(0, 0.11, 0)
		add_child(m)

	## El estanque, con el mismo shader del río a escala de charca.
	var agua := MeshInstance3D.new()
	var pa := PlaneMesh.new()
	pa.size = Vector2(26, 16)
	pa.subdivide_width = 14
	pa.subdivide_depth = 10
	agua.mesh = pa
	var sh := load(RUTA_SHADER_AGUA)
	if sh != null:
		var sm := ShaderMaterial.new()
		sm.shader = sh
		sm.set_shader_parameter("color_hondo", Color(0.07, 0.20, 0.22))
		sm.set_shader_parameter("color_orilla", Color(0.22, 0.44, 0.44))
		sm.set_shader_parameter("altura_ola", 0.12)
		sm.set_shader_parameter("escala_ola", 0.5)
		sm.set_shader_parameter("velocidad", 0.5)
		agua.material_override = sm
	agua.position = centro + Vector3(-26.0, 0.16, 18.0)
	add_child(agua)
	_cartel(centro + Vector3(0, 0, -40.0), "Parque del barrio", false)

## PARADAS DE AUTOBÚS a lo largo del anillo: "integrar paradas de autobús...
## le daría una sensación de mayor dinamismo funcional". Marquesina, banco y
## poste con señal, en los cuatro puntos donde de verdad haría falta parar:
## el estadio, el centro comercial, la zona industrial y el barrio.
func _paradas_bus() -> void:
	var sitios := [
		{"p": Vector3(RING_X - 13.0, 0, -170.0), "a": -PI * 0.5, "n": "Estadio"},
		{"p": Vector3(-RING_X + 13.0, 0, 110.0), "a": PI * 0.5, "n": "Centro comercial"},
		{"p": Vector3(RING_X - 13.0, 0, 140.0), "a": -PI * 0.5, "n": "Zona industrial"},
		{"p": Vector3(BARRIO_EN.x + 13.0, 0, RING_Z_SUR + 60.0), "a": -PI * 0.5, "n": "Barrio"},
	]
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.72, 0.86, 0.92, 0.4)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.metallic = 0.4
	vidrio.roughness = 0.1
	var metal: StandardMaterial3D = Texturas.metal(Color(0.08, 0.09, 0.1), 0.4).duplicate()
	metal.metallic = 0.6
	var acento := StandardMaterial3D.new()
	acento.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
	acento.roughness = 0.5

	for s in sitios:
		var raiz := Node3D.new()
		raiz.position = s["p"]
		raiz.rotation.y = float(s["a"])
		add_child(raiz)
		## Techo de la marquesina, con la franja del club por delante.
		var techo := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(7.5, 0.22, 3.0)
		techo.mesh = tm
		techo.material_override = metal
		techo.position = Vector3(0, 3.1, 0)
		raiz.add_child(techo)
		var franja := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(7.6, 0.5, 0.16)
		franja.mesh = fm
		franja.material_override = acento
		franja.position = Vector3(0, 2.85, 1.5)
		raiz.add_child(franja)
		## Trasera de cristal y dos pilares.
		var pared := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(7.5, 2.5, 0.1)
		pared.mesh = pm
		pared.material_override = vidrio
		pared.position = Vector3(0, 1.6, -1.4)
		raiz.add_child(pared)
		for lado in [-1.0, 1.0]:
			var pil := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.11
			cm.bottom_radius = 0.11
			cm.height = 3.0
			pil.mesh = cm
			pil.material_override = metal
			pil.position = Vector3(lado * 3.5, 1.5, 1.3)
			raiz.add_child(pil)
		## El banco.
		var banco := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(5.4, 0.16, 0.7)
		banco.mesh = bm
		banco.material_override = acento
		banco.position = Vector3(0, 0.75, -0.9)
		raiz.add_child(banco)
		_cartel(s["p"] + Vector3(0, 0, -6.0), "🚌 " + String(s["n"]), true)

	_terminal_buses()

## LA TERMINAL: "una estación o un eje vial mejor conectado" pedía el análisis.
## Las cuatro marquesinas eran paradas sueltas -sin ellas parecía que el
## transporte público no tenía de dónde salir-; la terminal es el origen: un
## cobertizo largo con varias dársenas, junto al acceso norte, que es donde de
## verdad convergen el estadio y el aparcamiento.
func _terminal_buses() -> void:
	var centro := Vector3(178.0, 0, -100.0)
	## DUPLICADO para conservar el metalico 0.4 ya afinado -mas apagado que el
	## 0.75 por defecto de la fabrica, que aqui se veria demasiado cromado.
	var metal: StandardMaterial3D = Texturas.metal(Color(0.10, 0.11, 0.13), 0.5).duplicate()
	metal.metallic = 0.4
	var acento := StandardMaterial3D.new()
	acento.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
	acento.roughness = 0.5
	var pav: StandardMaterial3D = Texturas.asfalto(Color(0.24, 0.25, 0.27)).duplicate()
	pav.roughness = 0.85

	var suelo := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(46, 16)
	suelo.mesh = pl
	suelo.material_override = pav
	suelo.position = centro + Vector3(0, 0.03, 0)
	add_child(suelo)

	## El cobertizo: techo largo sobre cuatro pilares, con la franja del club
	## a lo largo del alero -misma idea que la marquesina de cada instalación-.
	var techo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(44.0, 0.4, 10.0)
	techo.mesh = tm
	techo.material_override = metal
	techo.position = centro + Vector3(0, 4.6, 0)
	add_child(techo)
	var franja := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(44.4, 0.5, 0.2)
	franja.mesh = fm
	franja.material_override = acento
	franja.position = centro + Vector3(0, 4.35, 5.1)
	add_child(franja)
	for i in range(5):
		var pil := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.3
		cm.bottom_radius = 0.3
		cm.height = 4.4
		pil.mesh = cm
		pil.material_override = metal
		pil.position = centro + Vector3(-20.0 + i * 10.0, 2.2, 4.4)
		add_child(pil)
	_cartel(centro + Vector3(0, 0, -9.0), "🚌 Terminal de buses", true)

# ---------------------------------------------------------------- aparcamiento

## ============================================================================
##  LOS COCHES (26-9-2026)
## ============================================================================
## "En nuestra ciudad están conduciendo mal": los del kit de Kenney tienen el
## morro en +Z (medido: su lado largo es Z, y en una captura de perfil el capó
## queda del lado +Z), pero el tráfico los giraba -90° creyendo que miraban a
## X. Iban todos DE LADO, como cangrejos. Ahora cada coche se instancia ya
## mirando a +Z y el tráfico no les suma ningún giro.
##
## Y "tenemos mejores": `coche1.fbx`/`coche2.fbx`, los realistas. Su licencia
## no está verificada (ver `LICENCIAS.md`) y las versiones publicables no los
## llevan (`export_presets.cfg`), así que entran SOLO si el archivo está: en la
## copia de trabajo sí, en una versión exportada no, y ahí queda Kenney.
## Vienen con Z hacia arriba y el morro en -X: se enderezan dentro de un nodo.
const RUTA_COCHE_REAL_1 := "res://assets/ciudad/coche1.fbx"
const RUTA_COCHE_REAL_2 := "res://assets/ciudad/coche2.fbx"

static func flota_coches() -> Array:
	var pool: Array = []
	for par in [[RUTA_COCHE_REAL_1, "res://assets/ciudad/Car Texture 1.png"], [RUTA_COCHE_REAL_2, "res://assets/ciudad/Car Texture 2.png"]]:
		if ResourceLoader.exists(par[0]):
			var e: PackedScene = load(par[0])
			if e != null:
				var tex: Texture2D = load(par[1]) if ResourceLoader.exists(par[1]) else null
				## Pesan como cuatro Kenney cada uno: son los que más se ven.
				for _r in range(4):
					pool.append({"esc": e, "escala": 1.1, "fbx": true, "tex": tex})
	for ruta in RUTAS_COCHES_KENNEY:
		var kc: PackedScene = load(ruta)
		if kc != null:
			pool.append({"esc": kc, "escala": 1.65, "fbx": false})
	return pool

## VEHÍCULOS PROPORCIONADOS (7-10-2026, «vehículos más realistas y que sean
## proporcionados»): los del kit de Kenney son de juguete -a escala 1,65 un
## turismo medía 2,1 m de alto y 2,5 de ancho, y un camión de bomberos 5 m de
## largo-. Cada modelo se lleva a sus medidas reales (ancho, alto, largo en
## metros) midiéndolo una vez; la deformación se limita para que las ruedas
## no se vean ovaladas (el alto nunca baja del 72 % del factor del largo).
const MEDIDAS_REALES := {
	"sedan": Vector3(1.9, 1.65, 4.6), "sedan-sports": Vector3(1.9, 1.45, 4.5), "suv": Vector3(1.95, 1.8, 4.7),
	"suv-luxury": Vector3(2.0, 1.85, 4.95), "hatchback-sports": Vector3(1.85, 1.5, 4.2), "taxi": Vector3(1.9, 1.7, 4.6),
	"van": Vector3(2.0, 2.1, 5.1), "truck": Vector3(2.5, 3.3, 8.0), "truck-flat": Vector3(2.5, 3.0, 8.0),
	"tractor-police": Vector3(2.1, 2.6, 4.4), "ambulance": Vector3(2.1, 2.7, 6.0), "police": Vector3(1.9, 1.65, 4.8),
	"delivery": Vector3(2.1, 2.6, 6.0), "garbage-truck": Vector3(2.5, 3.4, 8.5), "firetruck": Vector3(2.5, 3.3, 9.0),
	"delivery-flat": Vector3(2.1, 2.4, 6.0),
}
static var _escalas_reales := {}

static func escala_real(esc: PackedScene) -> Vector3:
	var ruta := esc.resource_path
	if _escalas_reales.has(ruta):
		return _escalas_reales[ruta]
	var nombre := ruta.get_file().get_basename()
	var res := Vector3.ONE * 1.65
	if MEDIDAS_REALES.has(nombre):
		var tmp: Node3D = esc.instantiate()
		var caja := _caja_local(tmp, Transform3D.IDENTITY)
		tmp.free()
		if caja.size.x > 0.01 and caja.size.y > 0.01 and caja.size.z > 0.01:
			var m: Vector3 = MEDIDAS_REALES[nombre]
			res = Vector3(m.x / caja.size.x, m.y / caja.size.y, m.z / caja.size.z)
			res.y = maxf(res.y, res.z * 0.72)
			res.x = maxf(res.x, res.z * 0.6)
	_escalas_reales[ruta] = res
	return res

## La caja de todas las mallas de un nodo que no está en el árbol.
static func _caja_local(n: Node, t: Transform3D) -> AABB:
	var caja := AABB()
	var hay := false
	var tt := t * (n as Node3D).transform if n is Node3D else t
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		caja = tt * (n as MeshInstance3D).mesh.get_aabb()
		hay = true
	for h in n.get_children():
		var c := _caja_local(h, tt)
		if c.size != Vector3.ZERO:
			caja = c if not hay else caja.merge(c)
			hay = true
	return caja

## Un coche de la flota, ya con el morro hacia +Z y a su escala.
static func instanciar_coche(par: Dictionary, rng: RandomNumberGenerator = null) -> Node3D:
	var modelo: Node3D = (par["esc"] as PackedScene).instantiate()
	if not bool(par.get("fbx", false)):
		modelo.scale = escala_real(par["esc"])
		return modelo
	var raiz := Node3D.new()
	raiz.add_child(modelo)
	## Z arriba -> Y arriba (90° en X) y morro de -X a +Z (90° en Y).
	modelo.basis = Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.5)
	raiz.scale = Vector3.ONE * float(par["escala"])
	var mat := StandardMaterial3D.new()
	if par.get("tex") != null:
		mat.albedo_texture = par["tex"]
	## Cada coche de un color: la textura lleva el detalle y el tinte la pintura.
	var tintes := [Color.WHITE, Color(0.85, 0.2, 0.18), Color(0.2, 0.35, 0.75), Color(0.2, 0.2, 0.22), Color(0.75, 0.75, 0.78), Color(0.9, 0.75, 0.2), Color(0.25, 0.5, 0.3)]
	if rng != null:
		mat.albedo_color = tintes[rng.randi() % tintes.size()]
	mat.roughness = 0.35
	mat.metallic = 0.3
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat
	return raiz

## EL AUTOBÚS URBANO (7-10-2026): el kit no trae ninguno y la furgoneta
## agrandada medía 6 m de alto. Este se arma con piezas: 12 m de largo, 3,1 de
## alto y 2,55 de ancho, con franja de ventanas, parabrisas, dos puertas,
## rótulo de destino encendido, ruedas y el color de la línea. Mira a +Z.
static func autobus(col: Color, destino: String = "") -> Node3D:
	var raiz := Node3D.new()
	var pintura := StandardMaterial3D.new()
	pintura.albedo_color = col
	pintura.roughness = 0.35
	pintura.metallic = 0.2
	var blanco := StandardMaterial3D.new()
	blanco.albedo_color = Color(0.94, 0.94, 0.92)
	blanco.roughness = 0.4
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.12, 0.16, 0.2)
	vidrio.roughness = 0.08
	vidrio.metallic = 0.6
	var goma := StandardMaterial3D.new()
	goma.albedo_color = Color(0.06, 0.06, 0.06)
	goma.roughness = 0.9
	var piezas := [
		[Vector3(0, 1.0, 0), Vector3(2.55, 1.2, 12.0), pintura],           ## faldón
		[Vector3(0, 2.3, 0), Vector3(2.5, 1.4, 11.9), vidrio],            ## ventanas
		[Vector3(0, 3.05, 0), Vector3(2.55, 0.2, 12.0), blanco],          ## techo
		[Vector3(0, 3.25, -1.5), Vector3(1.8, 0.25, 3.0), blanco],        ## climatizador
		[Vector3(0, 2.3, 5.97), Vector3(2.3, 1.5, 0.08), vidrio],         ## parabrisas
		[Vector3(0, 1.0, 6.02), Vector3(2.4, 0.5, 0.05), blanco],         ## parachoques
		[Vector3(0, 2.85, 6.0), Vector3(1.8, 0.28, 0.06), null],          ## rótulo
	]
	for pz: Array in piezas:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = pz[1]
		mi.mesh = bm
		mi.position = pz[0]
		if pz[2] != null:
			mi.material_override = pz[2]
		else:
			var led := StandardMaterial3D.new()
			led.albedo_color = Color(1.0, 0.7, 0.1)
			led.emission_enabled = true
			led.emission = Color(1.0, 0.6, 0.1)
			led.emission_energy_multiplier = 1.5
			mi.material_override = led
		raiz.add_child(mi)
	## Pilares entre ventanas y las dos puertas (lado derecho, +X).
	for k in 7:
		var pil := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(2.58, 1.4, 0.18)
		pil.mesh = bm2
		pil.material_override = pintura
		pil.position = Vector3(0, 2.3, -5.4 + float(k) * 1.8)
		raiz.add_child(pil)
	for zp: float in [4.6, -0.8]:
		var pu := MeshInstance3D.new()
		var bm3 := BoxMesh.new()
		bm3.size = Vector3(0.06, 2.3, 1.2)
		pu.mesh = bm3
		pu.material_override = vidrio
		pu.position = Vector3(1.29, 1.55, zp)
		raiz.add_child(pu)
	## Ruedas.
	for zr: float in [3.8, -3.6]:
		for xr: float in [-1.15, 1.15]:
			var r := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.5
			cm.bottom_radius = 0.5
			cm.height = 0.32
			r.mesh = cm
			r.material_override = goma
			r.rotation.z = PI * 0.5
			r.position = Vector3(xr, 0.5, zr)
			raiz.add_child(r)
	if destino != "":
		var l := Label3D.new()
		l.text = destino
		l.font_size = 32
		l.pixel_size = 0.006
		l.modulate = Color(0.1, 0.05, 0.0)
		l.outline_size = 0
		l.position = Vector3(0, 2.85, 6.04)
		raiz.add_child(l)
	return raiz

func _aparcamiento() -> void:
	## Los coches salen del nivel de 'park': el jugador invierte en accesos y ve
	## el aparcamiento llenarse. Sin nivel, un par de coches del personal.
	##
	## AHORA CON VARIEDAD: a los dos FBX de siempre se suman los 7 GLB CC0 de
	## Kenney (`RUTAS_COCHES_KENNEY`). Cada fuente trae su propia escala -las
	## dos FBX ya estaban calibradas a 1.4-, y la de Kenney se ajustó aparte
	## con `captura_ciudad.gd` porque su pack no viene a la misma escala que
	## el resto de props de este proyecto.
	##
	## SOLO KENNEY DESDE EL 25-9-2026: `coche1.fbx`/`coche2.fbx` no tienen licencia
	## verificada (ver `LICENCIAS.md`) y los 7 de Kenney son CC0. Las versiones
	## publicables ni siquiera los llevan (`export_presets.cfg`).
	var pool: Array = flota_coches()
	if pool.is_empty():
		return
	var niv := int(datos.get("inst", {}).get("park", 0))
	var n: int = clampi(2 + niv * 4, 2, 22)
	var rng := RandomNumberGenerator.new()
	rng.seed = 45021

	## LAS PLAZAS PINTADAS. Sin ellas, los coches parecían abandonados sobre
	## una plancha de asfalto; con las líneas se entiende que eso es un
	## aparcamiento aunque esté medio vacío -que es justo lo que cuenta el
	## nivel de la instalación-.
	var pintura := StandardMaterial3D.new()
	pintura.albedo_color = Color(0.88, 0.88, 0.84)
	pintura.roughness = 0.8
	for fila in range(2):
		for col in range(8):
			var m := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.25, 0.04, 5.2)
			m.mesh = bm
			m.material_override = pintura
			m.position = Vector3(94.5 + col * 5.5, 0.06, -62.0 + fila * 8.0)
			add_child(m)
	for i in range(n):
		var par: Dictionary = pool[rng.randi() % pool.size()]
		var nodo: Node3D = instanciar_coche(par, rng)
		## Al este del acceso, entre el estadio y los campos: es donde de verdad
		## aparca la gente un día de partido, junto a la puerta.
		var fila := i / 7
		var col := i % 7
		nodo.position = Vector3(97.0 + col * 5.5, 0, -62.0 + fila * 8.0)
		## A lo largo de la plaza pintada (que corre en Z), unos de frente y
		## otros marcha atrás, como aparca la gente de verdad.
		nodo.rotation.y = 0.0 if rng.randf() < 0.6 else PI
		add_child(nodo)
	## Las dos plazas VIP junto a la puerta: los deportivos del kit (el del
	## presidente y el de la estrella del equipo).
	for k in 2:
		_poner_extra(["race", "race-future"][k], Vector3(141.0, 0, -62.0 + k * 8.0), 1.65, PI)
	_rotulo(Vector3(141.0, 4.0, -58.0), "VIP", Color(1.0, 0.85, 0.4), 22)

	_farolas()

## ============================================================================
##  LAS FAROLAS (12-9-2026, a petición del usuario)
## ============================================================================
##
## Antes eran `farola.obj` -un modelo descargado, gris, pequeño y con la misma
## silueta en todas partes-. El usuario pidió "negras y más grandes, y que sus
## luces sean de colores que uno pueda escoger durante la noche", y tiene
## sentido más allá del capricho: de noche las farolas son lo único que dibuja
## el trazado de la ciudad, así que son un elemento de IDENTIDAD, no un adorno.
## Elegir su color es elegir de qué color se ve tu ciudad a las 23:00.
##
## Se construyen por código -y no con un modelo- por dos razones: se puede
## teñir la luminaria en tiempo real cuando el jugador cambia el color, y la
## silueta se controla (negra, alta, con brazo curvo) en vez de heredarla.
const FAROLA_ALTO := 13.0

## El color por defecto si la partida no tiene uno elegido: ámbar de sodio, el
## de toda la vida.
const LUZ_POR_DEFECTO := Color("#ffb75e")

var _luz_color: Color = LUZ_POR_DEFECTO
var _luminarias: Array[StandardMaterial3D] = []

func _color_luces() -> Color:
	var s := str(datos.get("luces", ""))
	if s.begins_with("#") and s.length() >= 7:
		return Color(s)
	return LUZ_POR_DEFECTO

## Una farola: pie, mástil negro que se estrecha, brazo curvo y la luminaria.
## `hacia` es el ángulo al que apunta el brazo, para que el brazo caiga sobre
## la calzada y no hacia el campo.
func _una_farola(pos: Vector3, hacia: float) -> void:
	## `Texturas.metal()` (17-9-2026) en vez de color plano -docenas de farolas
	## por mapa (9x2 en la calle principal, mas el anillo entero)-. Duplicada
	## para conservar el metalico 0.55 ya afinado -menos cromado que el 0.75
	## por defecto-, pero las texturas de ruido caras de generar siguen
	## compartidas por referencia desde el cache de `Texturas`.
	var negro: StandardMaterial3D = Texturas.metal(Color(0.055, 0.058, 0.065), 0.42).duplicate()
	negro.metallic = 0.55

	var raiz := Node3D.new()
	raiz.position = pos
	raiz.rotation.y = hacia
	add_child(raiz)

	## Pie: un dado ancho abajo, que es lo que hace que no parezca un palo
	## clavado en el césped.
	var pie := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.42
	pm.bottom_radius = 0.62
	pm.height = 1.1
	pie.mesh = pm
	pie.material_override = negro
	pie.position = Vector3(0, 0.55, 0)
	raiz.add_child(pie)

	var mastil := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.17
	mm.bottom_radius = 0.34
	mm.height = FAROLA_ALTO
	mastil.mesh = mm
	mastil.material_override = negro
	mastil.position = Vector3(0, FAROLA_ALTO * 0.5 + 0.8, 0)
	raiz.add_child(mastil)

	## El brazo: tres tramos cortos girando un poco cada uno. Es la forma más
	## barata de sugerir una curva sin generar una malla a medida, y el brazo
	## curvo es justo lo que distingue una farola de calle de un poste.
	var largo := 1.5
	var punta := Vector3(0, FAROLA_ALTO + 0.6, 0)
	var ang := -0.95
	for i in range(3):
		var tramo := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.15
		tm.bottom_radius = 0.16
		tm.height = largo
		tramo.mesh = tm
		tramo.material_override = negro
		## RENDIMIENTO (17-9-2026): 3 tramos x cada farola del mapa (docenas)
		## son muchas mallas finas proyectando sombra por un brazo de 1,5 m que
		## ya queda bajo la sombra del mastil. Sin sombra propia no se nota.
		tramo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var dir := Vector3(sin(ang), cos(ang), 0)
		tramo.position = punta + dir * (largo * 0.5)
		tramo.rotation.z = -ang
		raiz.add_child(tramo)
		punta += dir * largo
		ang += 0.62

	## LA LUMINARIA: la carcasa negra y, debajo, el cristal que de verdad
	## emite. Se guarda su material para poder encenderlo y teñirlo con el
	## ciclo del sol sin reconstruir nada.
	var carcasa := MeshInstance3D.new()
	var cm2 := BoxMesh.new()
	cm2.size = Vector3(1.9, 0.42, 0.85)
	carcasa.mesh = cm2
	carcasa.material_override = negro
	carcasa.position = punta + Vector3(0.55, -0.1, 0)
	raiz.add_child(carcasa)

	var vidrio := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(1.6, 0.16, 0.7)
	vidrio.mesh = vm
	var lm := StandardMaterial3D.new()
	lm.albedo_color = _luz_color
	lm.emission_enabled = true
	lm.emission = _luz_color
	lm.emission_energy_multiplier = 0.0    ## la enciende el ciclo del sol
	vidrio.material_override = lm
	vidrio.position = punta + Vector3(0.55, -0.34, 0)
	raiz.add_child(vidrio)
	_luminarias.append(lm)

	var luz := OmniLight3D.new()
	luz.omni_range = 46.0
	luz.light_energy = 0.0
	luz.light_color = _luz_color
	luz.position = punta + Vector3(0.55, -0.6, 0)
	raiz.add_child(luz)
	_farolas_luz.append(luz)

	## BANDERINES DEL CLUB en el mástil, a media altura. Es el detalle que dice
	## de QUIÉN es esta ciudad -que es de lo que va toda esta pantalla-: en
	## cuanto los ves repetidos calle abajo, el mapa deja de ser "una ciudad" y
	## pasa a ser "la ciudad del club". Dos paños, uno de cada color.
	var colores := [_color_club("c1", Color(0.2, 0.5, 0.3)), _color_club("c2", Color(0.9, 0.9, 0.9))]
	for i in range(2):
		## `Texturas.tela()` (17-9-2026) en vez de color plano -mismo criterio
		## que el resto de banderas del proyecto esta sesion. `cull_mode` ya
		## viene en `Texturas.tela()`.
		var tela: StandardMaterial3D = Texturas.tela(colores[i]).duplicate()
		tela.roughness = 0.9
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, 2.2, 1.35)
		b.mesh = bm
		b.material_override = tela
		## RENDIMIENTO: dos banderines x docenas de farolas -sombra apagada,
		## una tela de este tamaño no se nota si no la tira.
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.position = Vector3(0.45 * (1.0 if i == 0 else -1.0), FAROLA_ALTO * 0.62, 0)
		raiz.add_child(b)

## En dos hileras a lo largo del vial de acceso, con el brazo hacia la calzada.
func _farolas() -> void:
	for i in range(9):
		for lado in [-1.0, 1.0]:
			## El brazo mira SIEMPRE hacia el eje de la calle: una farola con el
			## brazo hacia el campo alumbra el césped y deja la calzada a
			## oscuras, que es justo al revés de para lo que está.
			_una_farola(Vector3(lado * 11.0, 0, -60.0 + i * 42.0),
				(PI * 0.5) if lado < 0.0 else (-PI * 0.5))

# ---------------------------------------------------------------- horizonte

## Una ciudad de fondo, lejos del complejo. Antes del horizonte solo habia
## cesped hasta el borde del mundo (2.400 m, ver `_suelo()`): un complejo
## deportivo en mitad de la nada no se lee como parte de una ciudad de
## verdad. Con un puñado de edificios altos y lejanos -nunca dentro del
## recinto- se resuelve barato: son cinco mallas reutilizadas muchas veces,
## no un barrio entero modelado a mano.
##
## RADIO Y ESCALA, LOS DOS AJUSTADOS CON LA CAPTURA, NO A OJO. El primer
## intento los puso a 600-900 m -"la camara nunca pasa de 700 m, un radio
## mayor no se veria"-, y en la captura no se veía NINGUNO: la niebla
## volumétrica de `Calidad.gd` tiene solo 220 m de alcance
## (`volumetric_fog_length`), así que todo lo que queda más lejos se lava
## contra el cielo aunque el motor lo siga dibujando. Con radio 280-430 -justo
## fuera del recinto (que llega a z≈230) pero dentro de la niebla- y una
## escala más alta para que se lean como rascacielos y no como postes, el
## horizonte por fin aparece en la captura.
func _horizonte() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var mallas: Array = []
	for ruta in RUTAS_HORIZONTE:
		var esc: PackedScene = load(ruta)
		if esc != null:
			mallas.append(esc)
	if mallas.is_empty():
		return
	## De 10 edificios al fondo con un club modesto a 46 con uno grande: es el
	## indicador más visible de todos, porque el skyline se ve desde cualquier
	## ángulo de cámara.
	var cuantos: int = int(round(lerpf(10.0, 46.0, _empuje_club())))
	for i in range(cuantos):
		var ang: float = rng.randf() * TAU
		## MÁS LEJOS QUE ANTES (12-9-2026): a 280-430 m el horizonte se metía
		## justo encima de las parcelas nuevas -que están a ~300 m- y salían
		## rascacielos plantados dentro de un solar. Ahora empieza donde acaba
		## el mapa jugable.
		## 7-10-2026: con la ciudad grande, el horizonte empieza donde acaba ella.
		var radio: float = rng.randf_range(1560.0, 1950.0)
		var pos := Vector3(sin(ang) * radio, 0, cos(ang) * radio)
		var esc: PackedScene = mallas[rng.randi() % mallas.size()]
		var nodo: Node3D = esc.instantiate()
		if rng.randf() < 0.45:
			tenir(nodo, rng.randi())
		## Y además más ALTOS con el club grande: una ciudad de primera no solo
		## tiene más edificios, los tiene más altos.
		var escala: float = 6.0 * rng.randf_range(0.8, 1.4) * lerpf(0.75, 1.35, _empuje_club())
		nodo.scale = Vector3.ONE * escala
		## Apoyado en la loma, no a y=0: desde que el terreno ondula, un
		## edificio a altura fija queda flotando en la ladera o enterrado hasta
		## el tercer piso, y es de lo primero que canta que el mundo es falso.
		nodo.position = Vector3(pos.x, altura_en(pos.x, pos.z) - 1.0, pos.z)
		nodo.rotation.y = rng.randf() * TAU
		add_child(nodo)

# ---------------------------------------------------------------- casa y complejo del usuario

## La caja real de un modelo importado, midiendo su AABB -nunca a ojo, cada
## exportador trae sus propias unidades. Mismo método que ya usó
## `RuedaPrensaEscena3D._montar_podio_generado()` para el podio generado.
func _caja_de(n: Node) -> AABB:
	var caja := AABB()
	var primero := true
	for m: MeshInstance3D in _mallas_de(n):
		var a: AABB = m.mesh.get_aabb() if m.mesh != null else AABB()
		a = m.transform * a
		if primero:
			caja = a
			primero = false
		else:
			caja = caja.merge(a)
	return caja

func _mallas_de(n: Node) -> Array[MeshInstance3D]:
	var salida: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		salida.append(n)
	for h in n.get_children():
		salida.append_array(_mallas_de(h))
	return salida

## ============================================================================
##  EL PLANO DEL MAPA (12-9-2026)
## ============================================================================
##
## Antes esto era UN recinto con todo dentro y césped hasta el horizonte: no
## se entendía como un sitio, no había forma de recorrerlo con la vista y los
## CINCO TERRENOS que el jugador compra en Club → Ciudad no existían en 3D -eran
## solo una lista de texto-. El usuario lo dijo claro: "las instalaciones deben
## tener su espacio, los terrenos deben estar delimitados, la cosa residencial
## conectada con calles; primero planifica el espacio".
##
## EL PLANO, de norte (-z) a sur (+z):
##
##      ╔═══ calle norte (z=-250) ══════════════════════╗
##      ║  [RIBERA]        ESTADIO         [NORTE]      ║
##      ║  x=-290,z=-170   (0,-150)        x=290,z=-170 ║
##   calle                                            calle
##   oeste        ┌── RECINTO DEL CLUB ──┐            este
##  (x=-200)      │ campos · aparcamiento │          (x=200)
##      ║         │ instalaciones (PERIFERIA)         ║
##      ║  [CENTRO]       └──────────────┘  [SUR]     ║
##      ║  x=-295,z=150                   x=295,z=190 ║
##      ╚═══ calle sur (z=+340) ════════════════════════╝
##                      │ ramal
##                [BARRIO RESIDENCIAL]  (-70, 470)
##
## El sitio de cada parcela NO es decorativo: sale de lo que dice su propia
## descripción en la tabla `TERRENOS` -"norte, pegado al estadio", "ribera del
## río", "solar en el centro", "fundo en la periferia" (que es el propio
## recinto del club) y "terreno sur, zona industrial"-.

## MEDIDAS DEL MAPA. El estadio de verdad (`StadiumBuilder`) ocupa unos 110 x
## 150 m reales y va al norte, así que el recinto del club llega hasta z=-280;
## el anillo de calles lo rodea por fuera y las parcelas quedan al otro lado de
## la calle, que es lo que las hace leerse como terrenos vecinos y no como
## trozos sueltos del mismo sitio. Queda hueco de sobra entre el anillo y el
## horizonte (a 620 m) para lo que venga después.
const ANCHO_CALLE := 16.0
const RING_X := 205.0
const RING_Z_NORTE := -320.0
const RING_Z_SUR := 350.0
## La circunvalación exterior cruza los tramos este y oeste del anillo aquí.
const EX_N := -282.0
const EX_S := 262.0

## Dónde cae cada terreno comprable. "periferia" no tiene parcela propia: ES el
## recinto del club, así que solo lleva cartel.
##
## TODO ESTO SE APRETÓ (12-9-2026, segunda pasada): con el anillo a 235 m y las
## parcelas a 360, el estadio -que ahora es el de verdad y mide 110x150 m
## REALES- quedaba como un sello en mitad de un prado y el mapa no se leía de
## una vez. La regla aquí es que la referencia de tamaño la pone el estadio, no
## al revés: todo lo demás se acerca hasta que un vistazo abarque el conjunto.
const PARCELAS := {
	"norte":  {"pos": Vector2(300, -180), "ancho": 130.0, "fondo": 160.0},
	"ribera": {"pos": Vector2(-304, -180), "ancho": 130.0, "fondo": 160.0},
	"centro": {"pos": Vector2(-306, 110), "ancho": 140.0, "fondo": 180.0},
	"sur":    {"pos": Vector2(306, 140), "ancho": 140.0, "fondo": 180.0},
}

## Los negocios que SÍ se pueden ver: los que la tabla `NEGOCIOS` ata a un
## terreno concreto. `resto` y `escuela` no tienen terreno (`null` en la tabla),
## así que no ocupan suelo y no se dibujan: no es un olvido, es que el propio
## juego dice que no están en ningún sitio.
const NEGOCIOS_EN_PARCELA := {
	"hotel": "norte",
	"parking": "norte",
	"comercial": "centro",
	"clinica": "periferia",
}

## LA MANZANA COMERCIAL: ocho edificios distintos del kit CC0, no cuatro
## repetidos. Una manzana de verdad no tiene dos edificios iguales seguidos, y
## con solo cuatro modelos el patrón se cantaba desde la cámara del mapa.
const RUTAS_COMERCIAL := [
	"res://assets/ciudad/kenney_comercial/building-a.glb",
	"res://assets/ciudad/kenney_comercial/building-c.glb",
	"res://assets/ciudad/kenney_comercial/building-e.glb",
	"res://assets/ciudad/kenney_comercial/building-g.glb",
	"res://assets/ciudad/kenney_comercial/building-i.glb",
	"res://assets/ciudad/kenney_comercial/building-k.glb",
	"res://assets/ciudad/kenney_comercial/building-m.glb",
	"res://assets/ciudad/kenney_comercial/building-n.glb",
	## 26-9-2026: los seis que faltaban del kit ("hay un pack completo sin usar").
	"res://assets/ciudad/kenney_comercial_extra/building-b.glb",
	"res://assets/ciudad/kenney_comercial_extra/building-d.glb",
	"res://assets/ciudad/kenney_comercial_extra/building-f.glb",
	"res://assets/ciudad/kenney_comercial_extra/building-h.glb",
	"res://assets/ciudad/kenney_comercial_extra/building-j.glb",
	"res://assets/ciudad/kenney_comercial_extra/building-l.glb",
	## 7-10-2026: las seis versiones del kit básico que quedaban sin poner.
	"res://assets/ciudad/kenney_comercial/building-b.glb",
	"res://assets/ciudad/kenney_comercial/building-d.glb",
	"res://assets/ciudad/kenney_comercial/building-f.glb",
	"res://assets/ciudad/kenney_comercial/building-h.glb",
	"res://assets/ciudad/kenney_comercial/building-j.glb",
	"res://assets/ciudad/kenney_comercial/building-l.glb",
]

## Naves para la zona industrial del terreno sur: los modelos "de poco
## detalle" del mismo kit, que son justo bloques simples -perfectos para una
## nave y baratos de dibujar-.
const RUTAS_NAVES := [
	"res://assets/ciudad/kenney_comercial/low-detail-building-wide-a.glb",
	"res://assets/ciudad/kenney_comercial/low-detail-building-wide-b.glb",
	"res://assets/ciudad/kenney_comercial/low-detail-building-a.glb",
	"res://assets/ciudad/kenney_comercial/low-detail-building-e.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-b.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-c.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-d.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-f.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-g.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-h.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-i.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-j.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-k.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-l.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-m.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-n.glb",
]

## Los toldos y parasoles del kit: el detalle de calle que separa "unos bloques
## puestos en fila" de "una calle comercial".
const RUTAS_MOBILIARIO := [
	"res://assets/ciudad/kenney_comercial/detail-awning.glb",
	"res://assets/ciudad/kenney_comercial/detail-awning-wide.glb",
	"res://assets/ciudad/kenney_comercial/detail-parasol-a.glb",
	"res://assets/ciudad/kenney_comercial/detail-parasol-b.glb",
	"res://assets/ciudad/kenney_comercial_extra/detail-overhang.glb",
	"res://assets/ciudad/kenney_comercial_extra/detail-overhang-wide.glb",
]

## VEHÍCULOS DE SERVICIO, más raros que los coches normales: una ambulancia, un
## camión de basura o un coche de policía cada tanto es lo que hace que el
## tráfico parezca de una ciudad y no de un circuito. Van aparte de
## `RUTAS_COCHES_KENNEY` precisamente para poder dosificarlos.
## EL AUTOBÚS. El kit CC0 de coches no trae un bus de verdad -se revisó el
## catálogo completo-, así que se usa la furgoneta de reparto a una escala
## mucho mayor: más grande que cualquier coche de la calle y a menor
## velocidad, que es justo cómo se distingue un autobús de un auto en
## cualquier ciudad.
const RUTA_BUS := "res://assets/ciudad/kenney_cars/van.glb"

const RUTAS_SERVICIO := [
	## 26-9-2026: los que faltaban del kit (camiones y la patrulla rural).
	"res://assets/ciudad/kenney_cars_extra/truck.glb",
	"res://assets/ciudad/kenney_cars_extra/truck-flat.glb",
	"res://assets/ciudad/kenney_cars_extra/tractor-police.glb",
	"res://assets/ciudad/kenney_cars/ambulance.glb",
	"res://assets/ciudad/kenney_cars/police.glb",
	"res://assets/ciudad/kenney_cars/delivery.glb",
	"res://assets/ciudad/kenney_cars/garbage-truck.glb",
	"res://assets/ciudad/kenney_cars/firetruck.glb",
	"res://assets/ciudad/kenney_cars/delivery-flat.glb",
]

# ---------------------------------------------------------------- calles

## La red de calles: un anillo alrededor del recinto del club y un ramal corto
## a cada parcela. Es lo que convierte cinco cosas sueltas en un sitio por el
## que se puede ir: sin calles, una parcela a 300 m del estadio parece un error
## de colocación, no un terreno del otro lado de la calle.
func _calles() -> void:
	## La red de calles entera -el anillo completo mas los ramales a cada
	## parcela, la mayor superficie de asfalto del mapa- tambien conecta
	## `Texturas.asfalto()` (17-9-2026).
	var asfalto: StandardMaterial3D = Texturas.asfalto(Color(0.13, 0.13, 0.145)).duplicate()
	asfalto.roughness = 0.45
	asfalto.metallic = 0.1
	var linea := StandardMaterial3D.new()
	linea.albedo_color = Color(0.85, 0.82, 0.55)
	linea.roughness = 0.8

	## El anillo, en cuatro tramos.
	var largo_ns: float = RING_Z_SUR - RING_Z_NORTE
	var centro_ns: float = (RING_Z_SUR + RING_Z_NORTE) * 0.5
	_via(Vector3(-RING_X, 0, centro_ns), Vector2(ANCHO_CALLE, largo_ns), asfalto, linea, false)
	_via(Vector3(RING_X, 0, centro_ns), Vector2(ANCHO_CALLE, largo_ns), asfalto, linea, false)
	_via(Vector3(0, 0, RING_Z_NORTE), Vector2(RING_X * 2.0 + ANCHO_CALLE, ANCHO_CALLE), asfalto, linea, true)
	_via(Vector3(0, 0, RING_Z_SUR), Vector2(RING_X * 2.0 + ANCHO_CALLE, ANCHO_CALLE), asfalto, linea, true)

	## Ramales del anillo a cada parcela: un trozo corto que ata la parcela a
	## la calle, para que se lea que da a ella y no que flota al lado.
	for clave: String in PARCELAS:
		var p: Dictionary = PARCELAS[clave]
		var pos: Vector2 = p["pos"]
		var borde_x: float = pos.x - float(p["ancho"]) * 0.5 * signf(pos.x)
		var desde: float = RING_X * signf(pos.x)
		var medio: float = (borde_x + desde) * 0.5
		var largo: float = absf(borde_x - desde) + ANCHO_CALLE
		_via(Vector3(medio, 0, pos.y), Vector2(largo, ANCHO_CALLE), asfalto, linea, true)

	## Y el ramal al barrio residencial, que cuelga del tramo sur del anillo.
	## Termina delante del portón de la finca (la acera del fondo de saco
	## queda justo ante la verja).
	var fin_barrio: float = FINCA_PORTON_Z - BORDILLO - ACERA
	_via(Vector3(BARRIO_EN.x, 0, (RING_Z_SUR + fin_barrio) * 0.5),
		Vector2(ANCHO_CALLE, fin_barrio - RING_Z_SUR), asfalto, linea, false)

	## El acceso al karting, que cuelga del anillo sur hasta sus boxes.
	var fin_k: float = KARTING_EN.z - 22.0 - 16.0
	_via(Vector3(KARTING_EN.x, 0, (RING_Z_SUR + fin_k) * 0.5),
		Vector2(ANCHO_CALLE, fin_k - RING_Z_SUR), asfalto, linea, false)

	## EL EJE EXTERIOR (12-9-2026): "integrar... un eje vial mejor conectado
	## entre la zona industrial, el centro comercial y el estadio". Tenía
	## razón: con solo el anillo, para ir de la zona industrial (este) al
	## centro comercial (oeste) había que rodear el recinto del club por
	## dentro. Este segundo anillo pasa POR FUERA, rozando las cuatro parcelas,
	## y las conecta entre sí directamente. Es lo que en una ciudad de verdad
	## es la circunvalación, y de paso encierra el mapa como un conjunto.
	var ex_x := 392.0
	var ex_n := EX_N
	var ex_s := EX_S
	var largo_ex: float = ex_s - ex_n
	var centro_ex: float = (ex_s + ex_n) * 0.5
	_via(Vector3(-ex_x, 0, centro_ex), Vector2(ANCHO_CALLE, largo_ex), asfalto, linea, false)
	_via(Vector3(ex_x, 0, centro_ex), Vector2(ANCHO_CALLE, largo_ex), asfalto, linea, false)
	_via(Vector3(0, 0, ex_n), Vector2(ex_x * 2.0 + ANCHO_CALLE, ANCHO_CALLE), asfalto, linea, true)
	_via(Vector3(0, 0, ex_s), Vector2(ex_x * 2.0 + ANCHO_CALLE, ANCHO_CALLE), asfalto, linea, true)

	## PASOS DE CEBRA en cada cruce. Es el detalle más barato que existe para
	## que un cruce de dos franjas grises se lea como una intersección de
	## verdad, y además marca por dónde se entra a cada parcela.
	var cebra := StandardMaterial3D.new()
	cebra.albedo_color = Color(0.93, 0.93, 0.90)
	cebra.roughness = 0.75
	for clave: String in PARCELAS:
		var pp: Dictionary = PARCELAS[clave]
		var ppos: Vector2 = pp["pos"]
		_cebra(Vector3(RING_X * signf(ppos.x), 0, ppos.y), true, cebra)
	_cebra(Vector3(0, 0, RING_Z_SUR), false, cebra)
	_cebra(Vector3(BARRIO_EN.x, 0, RING_Z_SUR), false, cebra)
	_construir_vias()
	_farolas_anillo()

## Farolas a lo largo del anillo, por el lado de fuera. Cumplen dos funciones y
## las dos importan: de día llenan el vacío entre la calle y el campo -que era
## justo lo que se sentía desangelado-, y de noche son las que dibujan el
## trazado de la ciudad cuando ya no se ve el asfalto.
func _farolas_anillo() -> void:
	## `hacia` = el ángulo que pone el brazo sobre la calzada, que en el anillo
	## es siempre hacia el centro del mapa.
	var puestos: Array = []
	var paso := 62.0
	var z := RING_Z_NORTE + paso * 0.5
	while z < RING_Z_SUR:
		## Sobre la acera (26-9-2026): a 13 m quedaban dentro de las
		## fachadas de los frentes urbanos.
		puestos.append({"p": Vector3(-RING_X - 11.3, 0, z), "a": -PI * 0.5})
		puestos.append({"p": Vector3(RING_X + 11.3, 0, z), "a": PI * 0.5})
		z += paso
	var x := -RING_X + paso * 0.5
	while x < RING_X:
		puestos.append({"p": Vector3(x, 0, RING_Z_NORTE - 11.3), "a": 0.0})
		puestos.append({"p": Vector3(x, 0, RING_Z_SUR + 11.3), "a": PI})
		x += paso
	for d in puestos:
		## Ni en mitad de la boca de un ramal que entra al anillo.
		var p: Vector3 = d["p"]
		var en_calle := false
		for v in _vias:
			var r := _rect_en(v, true)
			if p.x > r[0] - 1.0 and p.x < r[1] + 1.0 and p.z > r[2] - 1.0 and p.z < r[3] + 1.0:
				en_calle = true
				break
		if not en_calle:
			_una_farola(p, float(d["a"]))

## Un paso de cebra: siete franjas a lo ancho de la calle. `cruza_x` dice si
## las franjas se pintan cruzando el eje X (para una calle que corre en Z) o
## al revés.
func _cebra(centro: Vector3, cruza_x: bool, mat: Material) -> void:
	for i in range(7):
		var d: float = -ANCHO_CALLE * 0.42 + i * (ANCHO_CALLE * 0.84 / 6.0)
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.3, 0.05, ANCHO_CALLE * 0.8) if cruza_x \
			else Vector3(ANCHO_CALLE * 0.8, 0.05, 1.3)
		m.mesh = bm
		m.material_override = mat
		m.position = centro + (Vector3(d, 0.17, 0) if cruza_x else Vector3(0, 0.17, d))
		add_child(m)

## Un tramo de calle completo (26-9-2026, rehecho: "las calles de la ciudad se
## ven mal"): calzada con asfalto de verdad, líneas de borde continuas, eje
## discontinuo, bordillo, acera de baldosa elevada a cada lado, tapas de
## alcantarilla y sumideros junto al bordillo. `tam` es (ancho_x, largo_z) tal
## cual, y `horizontal` dice hacia dónde corre la calle.
const ACERA := 3.6
const BORDILLO := 0.3

static var _mat_blanco: StandardMaterial3D = null
static var _mat_bordillo: StandardMaterial3D = null
static var _mat_tapa: StandardMaterial3D = null

## RED DE CALLES, NO TRAMOS SUELTOS (26-9-2026, segunda pasada: "hay calles
## que no cierran"). Cada tramo ponía su acera de punta a punta sin saber de
## los demás: donde un ramal llegaba al anillo, la acera del anillo le cerraba
## la boca (la calle "chocaba" con un bordillo), y los finales ciegos quedaban
## con el asfalto cortado a pelo. Ahora `_via()` solo apunta el tramo y pone su
## calzada; `_construir_vias()` arma aceras, bordillos y marcas cuando ya se
## conocen TODOS: cada acera se abre donde entra otra calle, las esquinas las
## pone uno solo de los dos tramos (el que se apuntó antes, sin solaparse), la
## esquina exterior del anillo se completa, y un final sin salida se cierra con
## su bordillo y su acera como un fondo de saco de verdad.
var _vias: Array[Dictionary] = []

func _via(centro: Vector3, tam: Vector2, mat_asfalto: Material, _mat_linea: Material, horizontal: bool) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tam.x, 0.12, tam.y)
	m.mesh = bm
	m.material_override = mat_asfalto
	## Un pelo más alta cada calzada: en los cruces dos cajas coplanarias
	## parpadeaban peleándose por el mismo píxel.
	m.position = centro + Vector3(0, 0.06 + _vias.size() * 0.0008, 0)
	add_child(m)
	_vias.append({"c": centro, "tam": tam, "h": horizontal})

## El rectángulo de un tramo en las coordenadas (a lo largo, a lo ancho) de
## otro tramo `h`: [a0, a1, l0, l1].
static func _rect_en(w: Dictionary, h: bool) -> Array:
	var c: Vector3 = w["c"]
	var t: Vector2 = w["tam"]
	var x0 := c.x - t.x * 0.5
	var x1 := c.x + t.x * 0.5
	var z0 := c.z - t.y * 0.5
	var z1 := c.z + t.y * 0.5
	return [x0, x1, z0, z1] if h else [z0, z1, x0, x1]

## [lo, hi] menos los huecos: los trozos que quedan.
static func _restar(lo: float, hi: float, huecos: Array) -> Array:
	var trozos: Array = [[lo, hi]]
	for g: Array in huecos:
		var nuevos: Array = []
		for t: Array in trozos:
			if g[1] <= t[0] or g[0] >= t[1]:
				nuevos.append(t)
				continue
			if g[0] > t[0]:
				nuevos.append([t[0], g[0]])
			if g[1] < t[1]:
				nuevos.append([g[1], t[1]])
		trozos = nuevos
	return trozos.filter(func(t: Array) -> bool: return t[1] - t[0] > 0.15)

static func _solapa(a0: float, a1: float, b0: float, b1: float) -> bool:
	return minf(a1, b1) - maxf(a0, b0) > 0.01

func _construir_vias() -> void:
	if _mat_blanco == null:
		_mat_blanco = StandardMaterial3D.new()
		_mat_blanco.albedo_color = Color(0.9, 0.9, 0.87)
		_mat_blanco.roughness = 0.7
		_mat_bordillo = Texturas.hormigon(Color(0.66, 0.66, 0.64), 61)
		_mat_tapa = StandardMaterial3D.new()
		_mat_tapa.albedo_color = Color(0.16, 0.16, 0.17)
		_mat_tapa.metallic = 0.6
		_mat_tapa.roughness = 0.5
	var baldosa := Texturas.baldosa()
	var borde_acera: float = BORDILLO + ACERA
	for i in _vias.size():
		var v: Dictionary = _vias[i]
		var h: bool = v["h"]
		var c: Vector3 = v["c"]
		var t: Vector2 = v["tam"]
		var ca: float = c.x if h else c.z
		var cl: float = c.z if h else c.x
		var largo: float = t.x if h else t.y
		var ancho: float = t.y if h else t.x
		var lo: float = ca - largo * 0.5
		var hi: float = ca + largo * 0.5
		## Pone una caja de `da` a lo largo por `dl` a lo ancho, centrada en
		## (a, l) de este tramo.
		var caja := func(a: float, l: float, da: float, dl: float, alto: float, y: float, mat: Material) -> void:
			var mi := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(da, alto, dl) if h else Vector3(dl, alto, da)
			mi.mesh = b
			mi.material_override = mat
			mi.position = Vector3(a, y, l) if h else Vector3(l, y, a)
			add_child(mi)
		var otros: Array = []
		for j in _vias.size():
			if j != i:
				var r := _rect_en(_vias[j], h)
				r.append(j)
				otros.append(r)
		## ¿Cada punta desemboca en otra calle?
		var conecta := {}
		for fin: float in [lo, hi]:
			conecta[fin] = null
			for r: Array in otros:
				if fin >= r[0] - 1.0 and fin <= r[1] + 1.0 and cl >= r[2] - 1.0 and cl <= r[3] + 1.0:
					conecta[fin] = r
					break

		for s_l: float in [-1.0, 1.0]:
			var banda_b := [cl + s_l * ancho * 0.5, cl + s_l * (ancho * 0.5 + BORDILLO)]
			var banda_a := [cl + s_l * (ancho * 0.5 + BORDILLO), cl + s_l * (ancho * 0.5 + borde_acera)]
			banda_b.sort()
			banda_a.sort()
			var huecos: Array = []
			for r: Array in otros:
				if _solapa(banda_a[0], banda_a[1], r[2], r[3]) or _solapa(banda_b[0], banda_b[1], r[2], r[3]):
					## La esquina la pone el tramo apuntado antes.
					var extra: float = 0.0 if i < int(r[4]) else borde_acera
					huecos.append([r[0] - extra, r[1] + extra])
			var desde := lo
			var hasta := hi
			## Esquina exterior: la acera de fuera sigue hasta cerrar la vuelta.
			for fin: float in [lo, hi]:
				var r2: Variant = conecta[fin]
				if r2 == null or i > int(r2[4]):
					continue
				if _solapa(banda_a[0], banda_a[1], r2[2], r2[3]):
					continue
				if fin == lo:
					desde = float(r2[0]) - borde_acera
				else:
					hasta = float(r2[1]) + borde_acera
			for tr: Array in _restar(desde, hasta, huecos):
				var da: float = tr[1] - tr[0]
				var am: float = (tr[0] + tr[1]) * 0.5
				caja.call(am, (banda_b[0] + banda_b[1]) * 0.5, da, BORDILLO, 0.22, 0.11, _mat_bordillo)
				caja.call(am, (banda_a[0] + banda_a[1]) * 0.5, da, ACERA, 0.18, 0.09, baldosa)
			## Línea de borde y sumideros: se cortan justo en el asfalto ajeno.
			var l_linea: float = cl + s_l * (ancho * 0.5 - 0.6)
			var huecos_l: Array = []
			for r: Array in otros:
				if l_linea >= r[2] and l_linea <= r[3]:
					huecos_l.append([r[0], r[1]])
			for tr: Array in _restar(lo, hi, huecos_l):
				caja.call((tr[0] + tr[1]) * 0.5, l_linea, tr[1] - tr[0], 0.15, 0.02, 0.13, _mat_blanco)
				var d: float = tr[0] + 20.0
				while d < tr[1] - 10.0:
					caja.call(d, cl + s_l * (ancho * 0.5 - 0.3), 0.9, 0.45, 0.02, 0.125, _mat_tapa)
					d += 40.0

		## Eje discontinuo (trazos de 4 m cada 10 m) y tapas de registro, fuera
		## de los cruces.
		var dentro := func(a: float, l: float) -> bool:
			for r: Array in otros:
				if a >= r[0] - 2.0 and a <= r[1] + 2.0 and l >= r[2] and l <= r[3]:
					return true
			return false
		var a_eje: float = lo + 5.0
		while a_eje < hi - 2.0:
			if not dentro.call(a_eje, cl):
				caja.call(a_eje, cl, 4.0, 0.15, 0.02, 0.13, _mat_blanco)
			a_eje += 10.0
		var dt: float = lo + 35.0
		while dt < hi - 20.0:
			if not dentro.call(dt, cl + ancho * 0.22):
				var tapa := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.35
				cm.bottom_radius = 0.35
				cm.height = 0.02
				tapa.mesh = cm
				tapa.material_override = _mat_tapa
				tapa.position = Vector3(dt, 0.125, cl + ancho * 0.22) if h else Vector3(cl + ancho * 0.22, 0.125, dt)
				add_child(tapa)
			dt += 70.0

		## FONDO DE SACO: la punta que no da a ninguna calle se cierra con
		## bordillo y acera de lado a lado.
		for fin: float in [lo, hi]:
			if conecta[fin] != null:
				continue
			var hacia: float = -1.0 if fin == lo else 1.0
			var total: float = ancho + 2.0 * borde_acera
			caja.call(fin + hacia * BORDILLO * 0.5, cl, BORDILLO, ancho, 0.22, 0.11, _mat_bordillo)
			caja.call(fin + hacia * (BORDILLO + ACERA * 0.5), cl, ACERA, total, 0.18, 0.09, baldosa)

# ---------------------------------------------------------------- parcelas

## Las cinco parcelas del mapa. Una parcela SIN comprar se ve igual de
## delimitada que una comprada -un solar con su cerco y su cartel-, solo que
## en tierra y con el cerco apagado: el jugador tiene que poder ver lo que
## todavía no es suyo, o la pantalla de compra no significa nada.
func _parcelas() -> void:
	var mios: Array = datos.get("terrenos", [])
	var negocios: Dictionary = datos.get("negocios", {})
	for clave: String in PARCELAS:
		var p: Dictionary = PARCELAS[clave]
		var pos: Vector2 = p["pos"]
		var ancho: float = p["ancho"]
		var fondo: float = p["fondo"]
		var mio: bool = mios.has(clave)
		_solar(Vector3(pos.x, 0, pos.y), ancho, fondo, mio)
		_cartel(Vector3(pos.x, 0, pos.y - fondo * 0.5 + 8.0), _nombre_terreno(clave), mio)
		if clave == "ribera":
			_rio()
			if mio:
				_casa_ribera(Vector3(pos.x, 0, pos.y))
		if clave == "sur" and mio:
			_zona_industrial()
	## El recinto del club ES el terreno "periferia" ("fundo en la periferia:
	## perfecto para la ciudad deportiva", dice la tabla), así que lleva cartel
	## dentro en vez de parcela aparte.
	_cartel(Vector3(118.0, 0, 60.0), _nombre_terreno("periferia"), mios.has("periferia"))

	## Y encima de las parcelas, los negocios que ya se construyeron.
	for neg: String in NEGOCIOS_EN_PARCELA:
		if not bool(negocios.get(neg, false)):
			continue
		match neg:
			"hotel": _hotel()
			"parking": _parking_negocio()
			"comercial": _centro_comercial()
			"clinica": _clinica()

func _nombre_terreno(clave: String) -> String:
	for f: Array in _tabla_terrenos():
		if f.size() > 1 and String(f[0]) == clave:
			return String(f[1])
	return clave.capitalize()

func _tabla_terrenos() -> Array:
	var t: Variant = Datos.tabla("TERRENOS")
	return t as Array if t is Array else []

## Un solar: la explanada de tierra, el bordillo que lo delimita y, si es tuyo,
## una franja del color del club en el bordillo.
func _solar(centro: Vector3, ancho: float, fondo: float, mio: bool) -> void:
	var suelo := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(ancho, fondo)
	suelo.mesh = pl
	var m: StandardMaterial3D = Texturas.hormigon(
		Color(0.42, 0.38, 0.30) if not mio else Color(0.30, 0.30, 0.31)).duplicate()
	m.roughness = 0.95
	suelo.material_override = m
	suelo.position = centro + Vector3(0, 0.06, 0)
	add_child(suelo)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color_club("c1", Color(0.3, 0.6, 0.4)) if mio else Color(0.62, 0.60, 0.56)
	mat.roughness = 0.7
	## Bordillo de 0,9 m: suficiente para leerse desde la cámara alta del mapa
	## sin taparlo todo cuando se baja a mirar la parcela de cerca.
	var lados := [
		{"p": Vector3(0, 0.45, fondo * 0.5), "s": Vector3(ancho, 0.9, 1.2)},
		{"p": Vector3(0, 0.45, -fondo * 0.5), "s": Vector3(ancho, 0.9, 1.2)},
		{"p": Vector3(-ancho * 0.5, 0.45, 0), "s": Vector3(1.2, 0.9, fondo)},
		{"p": Vector3(ancho * 0.5, 0.45, 0), "s": Vector3(1.2, 0.9, fondo)},
	]
	for l in lados:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = l["s"]
		b.mesh = bm
		b.material_override = mat
		b.position = centro + (l["p"] as Vector3)
		add_child(b)

## El cartel de una parcela: un poste y el nombre en grande. `Label3D` y no una
## textura: se lee desde cualquier ángulo (mira siempre a la cámara) y no hay
## que rasterizar nada. El tamaño es de MAPA -letras de ~9 m- porque la cámara
## por defecto está a 470 m: a tamaño de cartel real no se leería ninguno.
func _cartel(pos: Vector3, texto: String, mio: bool) -> void:
	var poste := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.6
	cm.height = 16.0
	poste.mesh = cm
	var pm: StandardMaterial3D = Texturas.metal(Color(0.32, 0.33, 0.35), 0.6).duplicate()
	pm.metallic = 0.3
	poste.mesh.material = pm
	poste.position = pos + Vector3(0, 8.0, 0)
	add_child(poste)

	var l := Label3D.new()
	l.text = texto
	## Letras de ~5 m: a la altura de cámara del mapa (165 m) se leen sin
	## esfuerzo, y al bajar a mirar una parcela de cerca no tapan el edificio.
	## A 9 m -el primer intento- los carteles eran más anchos que su parcela.
	l.font_size = 36
	l.pixel_size = 0.14
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1, 1, 1) if mio else Color(0.85, 0.85, 0.88)
	l.outline_size = 14
	l.outline_modulate = Color(0.06, 0.08, 0.07, 0.9)
	l.no_depth_test = false
	l.position = pos + Vector3(0, 21.0, 0)
	add_child(l)

## La ribera lleva río: es lo que hace que ese terreno se entienda sin leer su
## descripción, y de paso rompe la explanada verde por el oeste. Con su velero,
## que es lo que `vagabond.obj` resultó ser de verdad -no una persona, pese al
## nombre; ver `dinastia-calidad-grafica.md`- y llevaba dos semanas sin usarse.
const RIO_X := -470.0  ## 7-10-2026: entre el anillo exterior (-392) y el bulevar (-550)
const RUTA_VELERO := "res://assets/ciudad/vagabond.obj"

const RUTA_SHADER_AGUA := "res://visor/agua.gdshader"
var _agua_mat: ShaderMaterial

func _rio() -> void:
	var agua := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	## 7-10-2026: el río cruza la ciudad grande entera, de punta a punta.
	pl.size = Vector2(80, 2700)
	## SUBDIVIDIDO, o el oleaje no tiene dónde ocurrir: un `PlaneMesh` sin
	## subdividir tiene cuatro vértices, y un shader que mueve vértices sobre
	## cuatro puntos no produce olas, produce un plano inclinado que cabecea.
	pl.subdivide_width = 12
	pl.subdivide_depth = 300
	agua.mesh = pl
	var sh := load(RUTA_SHADER_AGUA)
	if sh != null:
		var sm := ShaderMaterial.new()
		sm.shader = sh
		sm.set_shader_parameter("color_hondo", Color(0.06, 0.16, 0.24))
		sm.set_shader_parameter("color_orilla", Color(0.18, 0.38, 0.44))
		## Con la ola de 0,55 m los valles bajaban del suelo y asomaba el
		## césped en mitad del río (visto al alargarlo, 7-10-2026).
		sm.set_shader_parameter("altura_ola", 0.16)
		agua.material_override = sm
		_agua_mat = sm
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.16, 0.29, 0.38)
		m.metallic = 0.55
		m.roughness = 0.12
		agua.material_override = m
	agua.position = Vector3(RIO_X, 0.3, 0)
	add_child(agua)
	## Las dos orillas: sin ellas el agua es un rectángulo azul pegado sobre el
	## césped, y desde la cámara alta se nota que no hay cauce.
	var tierra := StandardMaterial3D.new()
	tierra.albedo_color = Color(0.44, 0.40, 0.31)
	tierra.roughness = 0.95
	for lado in [-1.0, 1.0]:
		var orilla := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(9.0, 1.6, 2700.0)
		orilla.mesh = bm
		orilla.material_override = tierra
		orilla.position = Vector3(RIO_X + lado * 44.0, 0.4, 0)
		add_child(orilla)

## LA CASA DE LA RIBERA: el modelo moderno que trajo el usuario ("ДОМ скетч").
## Antes se probó como edificio suelto dentro del recinto y se veía como una
## masa rota -el usuario pidió sacarla, con razón-. Aquí funciona por dos
## motivos que no son el modelo: tiene su PARCELA (bordillo, cartel, su propio
## suelo, no flotando en mitad del pavimento) y es lo bastante grande como
## para que se distinga su arquitectura -22 m de alto, no 7-. Y encaja con lo
## que la propia tabla dice del terreno: "ribera del río: vistas y polémica".
func _casa_ribera(centro: Vector3) -> void:
	var esc := load(RUTA_OFICINA_DT)
	if esc == null or not (esc is PackedScene):
		return
	var n: Node3D = (esc as PackedScene).instantiate()
	var raiz := Node3D.new()
	add_child(raiz)
	raiz.add_child(n)
	var caja := _caja_de(n)
	var alto: float = caja.size.y
	var escala := (22.0 / alto) if alto > 0.001 else 1.0
	raiz.scale = Vector3.ONE * escala
	## El origen del modelo no está en su base (el AABB empieza por debajo de
	## cero): sin corregirlo queda medio enterrado.
	raiz.position = centro + Vector3(0, -caja.position.y * escala, 0)
	raiz.rotation.y = PI * 0.5

## El velero ya no se monta aquí: navega, así que lo cuelga `_trafico()` de su
## propia ruta por el río. Esta función solo lo fabrica.
## Un bote de paseo (casco, cabina y toldo), lo bastante bajo para pasar bajo
## los puentes. Mira a +Z como los coches.
func _hacer_bote(k: int) -> Node3D:
	var n := Node3D.new()
	n.name = "Bote"
	var casco := [Color(0.9, 0.9, 0.88), Color(0.15, 0.3, 0.55), Color(0.7, 0.15, 0.12)][k % 3] as Color
	var mc := _mat_simple(casco, 0.4)
	var c := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.4, 1.2, 9.0)
	c.mesh = bm
	c.material_override = mc
	c.position = Vector3(0, 0.3, 0)
	n.add_child(c)
	var proa := MeshInstance3D.new()
	var pr := PrismMesh.new()
	pr.size = Vector3(3.4, 2.2, 1.2)
	proa.mesh = pr
	proa.material_override = mc
	proa.rotation = Vector3(PI * 0.5, 0, 0)
	proa.position = Vector3(0, 0.3, 5.0)
	n.add_child(proa)
	var cab := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(2.6, 1.3, 3.2)
	cab.mesh = cb
	cab.material_override = _mat_simple(Color(0.95, 0.95, 0.93), 0.5)
	cab.position = Vector3(0, 1.5, -0.8)
	n.add_child(cab)
	var toldo := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(3.0, 0.12, 3.6)
	toldo.mesh = tb
	toldo.material_override = _mat_simple(_color_club("c1", Color(0.2, 0.5, 0.3)), 0.7)
	toldo.position = Vector3(0, 2.25, -0.8)
	n.add_child(toldo)
	return n

func _hacer_velero() -> Node3D:
	var malla := load(RUTA_VELERO)
	if malla == null:
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.93, 0.93, 0.90)
	mat.roughness = 0.45
	mi.material_override = mat
	## Escala MEDIDA, no a ojo -misma regla de siempre-: se ajusta para que el
	## casco mida unos 13 m, que es un velero de recreo de verdad.
	var esc := 1.0
	if mi.mesh != null:
		var caja: AABB = mi.mesh.get_aabb()
		var largo: float = maxf(maxf(caja.size.x, caja.size.z), 0.001)
		esc = 13.0 / largo
	mi.scale = Vector3.ONE * esc
	return mi

# ---------------------------------------------------------------- trafico

## Lo que hace que el mapa esté VIVO: coches dando vueltas por el anillo, por
## la avenida de acceso y por la calle del barrio, y el velero navegando el
## río. Todo lo mueve `TraficoCiudad` sobre recorridos cerrados -ver ahí el
## por qué de cada decisión-; aquí solo se dibujan los recorridos y se decide
## cuántos vehículos van en cada uno.
const CARRIL := 4.0     ## separación del eje de la calle a cada carril

func _trafico() -> void:
	var t := TraficoCiudad.new()
	t.name = "Trafico"
	add_child(t)
	_karts_en_pista(t)

	## La flota: los coches normales pesan mucho más que los de servicio -uno de
	## cada cinco- porque si no el mapa parece una emergencia permanente.
	var coches: Array = flota_coches()
	for ruta in RUTAS_SERVICIO:
		var esc2: PackedScene = load(ruta)
		if esc2 != null:
			coches.append({"esc": esc2, "escala": 1.65, "fbx": false})

	var rng := RandomNumberGenerator.new()
	rng.seed = 8821

	## 1) EL ANILLO, en los dos sentidos. Dos carriles separados del eje, uno
	## por sentido: con un solo recorrido todos los coches iban en fila india
	## por el mismo sitio y la calle de vuelta quedaba vacía.
	var n_norte: float = RING_Z_NORTE
	var n_sur: float = RING_Z_SUR
	for sentido in [1.0, -1.0]:
		var off: float = CARRIL * sentido
		var esquinas := PackedVector3Array([
			Vector3(RING_X - off, 0.25, n_norte + off),
			Vector3(RING_X - off, 0.25, n_sur - off),
			Vector3(-RING_X + off, 0.25, n_sur - off),
			Vector3(-RING_X + off, 0.25, n_norte + off),
		])
		if sentido < 0.0:
			esquinas.reverse()
		var id := t.agregar_ruta(_redondear(esquinas, 26.0))
		if coches.is_empty():
			continue
		## Y el TRÁFICO también sube con el club: de 4 coches por sentido en un
		## club de barrio a 10 en uno grande. Una ciudad de primera división no
		## puede tener las calles igual de vacías que una de tercera.
		var por_sentido: int = int(round(lerpf(4.0, 10.0, _empuje_club())))
		for i in range(por_sentido):
			var nodo: Node3D = instanciar_coche(coches[rng.randi() % coches.size()], rng)
			## Giro 0: `instanciar_coche` ya deja el morro en +Z (ver arriba).
			t.agregar_vehiculo(nodo, id, rng.randf() * 1800.0,
				rng.randf_range(13.0, 22.0), 0.0, 0.0)

	## 1b) EL EJE EXTERIOR, con su propio tráfico -si la circunvalación estuviera
	## vacía se notaría más que si no existiera-.
	for sentido2 in [1.0, -1.0]:
		var off2: float = CARRIL * sentido2
		var esq2 := PackedVector3Array([
			Vector3(392.0 - off2, 0.25, -282.0 + off2),
			Vector3(392.0 - off2, 0.25, 262.0 - off2),
			Vector3(-392.0 + off2, 0.25, 262.0 - off2),
			Vector3(-392.0 + off2, 0.25, -282.0 + off2),
		])
		if sentido2 < 0.0:
			esq2.reverse()
		var id_ex := t.agregar_ruta(_redondear(esq2, 30.0))
		if coches.is_empty():
			continue
		for i in range(int(round(lerpf(3.0, 7.0, _empuje_club())))):
			var n_ex: Node3D = instanciar_coche(coches[rng.randi() % coches.size()], rng)
			t.agregar_vehiculo(n_ex, id_ex, rng.randf() * 2200.0,
				rng.randf_range(15.0, 24.0), 0.0, 0.0)
		## Y dos autobuses por sentido, en la misma ruta -es el eje que pasa
		## junto a las cuatro paradas y la terminal-, más grandes y más lentos
		## que el tráfico normal.
		for i in range(2):
			if true:
				var bus: Node3D = autobus(Color(0.95, 0.75, 0.15), "ESTADIO")
				t.agregar_vehiculo(bus, id_ex, rng.randf_range(200.0, 2000.0),
					9.0, 0.0, 0.0)

	## 2) LA AVENIDA DE ACCESO y 3) LA CALLE DEL BARRIO: circuitos estrechos
	## -se baja por un carril y se sube por el otro-, que es lo que hace que un
	## tramo sin salida tenga tráfico sin necesidad de dar media vuelta a lo
	## bruto delante de la cámara.
	for tramo in [
			{"x": 0.0, "z0": -85.0, "z1": RING_Z_SUR - 10.0, "n": 3},
			{"x": BARRIO_EN.x, "z0": RING_Z_SUR + 10.0, "z1": FINCA_PORTON_Z - 14.0, "n": 2},
		]:
		var x: float = tramo["x"]
		var z0: float = tramo["z0"]
		var z1: float = tramo["z1"]
		var circuito := PackedVector3Array([
			Vector3(x - CARRIL, 0.25, z0), Vector3(x - CARRIL, 0.25, z1),
			Vector3(x + CARRIL, 0.25, z1), Vector3(x + CARRIL, 0.25, z0),
		])
		var id2 := t.agregar_ruta(_redondear(circuito, 7.0))
		if coches.is_empty():
			continue
		for i in range(int(tramo["n"])):
			var nodo2: Node3D = instanciar_coche(coches[rng.randi() % coches.size()], rng)
			t.agregar_vehiculo(nodo2, id2, rng.randf() * 600.0,
				rng.randf_range(9.0, 15.0), 0.0, 0.0)

	## 5) LOS PEATONES (26-9-2026, B7): por las aceras del anillo y de la
	## avenida, en los dos sentidos, más cuanto más grande es el club.
	var rng_p := RandomNumberGenerator.new()
	rng_p.seed = 5150
	for sentido_p: float in [1.0, -1.0]:
		var acera: float = (ANCHO_CALLE * 0.5 + BORDILLO + ACERA * 0.5) * sentido_p
		var esq_p := PackedVector3Array([
			Vector3(RING_X + acera, 0.3, RING_Z_NORTE - acera),
			Vector3(RING_X + acera, 0.3, RING_Z_SUR + acera),
			Vector3(-RING_X - acera, 0.3, RING_Z_SUR + acera),
			Vector3(-RING_X - acera, 0.3, RING_Z_NORTE - acera),
		])
		if sentido_p < 0.0:
			esq_p.reverse()
		var id_p := t.agregar_ruta(_redondear(esq_p, 20.0))
		for i in range(int(round(lerpf(10.0, 22.0, _empuje_club())))):
			_un_peaton(t, rng_p, id_p, rng_p.randf() * 2400.0)
	var acera_av := PackedVector3Array([
		Vector3(-(ANCHO_CALLE * 0.5 + BORDILLO + ACERA * 0.5), 0.3, -85.0), Vector3(-(ANCHO_CALLE * 0.5 + BORDILLO + ACERA * 0.5), 0.3, RING_Z_SUR - 10.0),
		Vector3(ANCHO_CALLE * 0.5 + BORDILLO + ACERA * 0.5, 0.3, RING_Z_SUR - 10.0), Vector3(ANCHO_CALLE * 0.5 + BORDILLO + ACERA * 0.5, 0.3, -85.0),
	])
	var id_av := t.agregar_ruta(_redondear(acera_av, 5.0))
	for i in range(int(round(lerpf(6.0, 14.0, _empuje_club())))):
		_un_peaton(t, rng_p, id_av, rng_p.randf() * 900.0)

	## 4) LOS BOTES DEL RÍO (7-10-2026). El velero tiene el mástil más alto
	## que los puentes de la ciudad grande: se queda amarrado en el puerto y
	## el río lo recorren botes de paseo, que pasan por debajo.
	var cauce := PackedVector3Array([
		Vector3(RIO_X - 14.0, 0.0, -1300.0), Vector3(RIO_X - 14.0, 0.0, 1300.0),
		Vector3(RIO_X + 14.0, 0.0, 1300.0), Vector3(RIO_X + 14.0, 0.0, -1300.0),
	])
	var id3 := t.agregar_ruta(_redondear(cauce, 13.0))
	for k in 3:
		t.agregar_vehiculo(_hacer_bote(k), id3, 2700.0 * float(k), 4.0, 0.15, 0.0)
	if expansion != null:
		expansion.trafico(t, coches, rng)

## Un peatón de verdad (`PeatonQ`: hombre o mujer del paquete Quaternius, con
## ropa de calle, pelo y a veces barba) caminando por la acera a paso humano.
## Los modelos miran a +Z, que es lo que `TraficoCiudad` alinea con la marcha.
func _un_peaton(t: TraficoCiudad, rng: RandomNumberGenerator, ruta: int, s0: float) -> void:
	var d := PeatonQ.crear(rng)
	if d.is_empty():
		return
	t.agregar_vehiculo(d["nodo"], ruta, s0, rng.randf_range(1.15, 1.5), 0.18, 0.0)
	PeatonQ.terminar(d)

## Redondea las esquinas de un recorrido: en cada vértice se corta `radio`
## metros por cada lado y se cose el hueco con un arco de cuatro tramos. Sin
## esto, un coche llega a la esquina y gira 90° en un fotograma -se ve como un
## salto- y el velero daba un volantazo imposible al final del río.
func _redondear(puntos: PackedVector3Array, radio: float) -> PackedVector3Array:
	var n := puntos.size()
	if n < 3 or radio <= 0.01:
		return puntos
	var salida := PackedVector3Array()
	for i in range(n):
		var prev: Vector3 = puntos[(i - 1 + n) % n]
		var act: Vector3 = puntos[i]
		var sig: Vector3 = puntos[(i + 1) % n]
		var a: Vector3 = (prev - act)
		var b: Vector3 = (sig - act)
		## El radio nunca puede comerse más de la mitad de un tramo, o las
		## curvas de dos esquinas seguidas se solaparían y el recorrido se
		## cruzaría consigo mismo.
		var r: float = minf(radio, minf(a.length(), b.length()) * 0.45)
		var pa: Vector3 = act + a.normalized() * r
		var pb: Vector3 = act + b.normalized() * r
		salida.append(pa)
		for k in range(1, 4):
			var tt: float = float(k) / 4.0
			## Bézier cuadrática con el vértice como punto de control: es la
			## curva más barata que entra y sale tangente a los dos tramos.
			var q0: Vector3 = pa.lerp(act, tt)
			var q1: Vector3 = act.lerp(pb, tt)
			salida.append(q0.lerp(q1, tt))
		salida.append(pb)
	return salida

# ---------------------------------------------------------------- negocios

## El hotel del club: ocho plantas en la parcela norte, con las mismas ventanas
## que el resto de edificios para que se lea como parte del mismo mundo.
func _hotel() -> void:
	var pos := Vector3(268.0, 0, -218.0)
	var plantas := 8
	var alto := 6.0 * plantas
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(26.0, alto, 18.0)
	cuerpo.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.82, 0.72)
	mat.roughness = 0.6
	mat.metallic = 0.05
	cuerpo.material_override = mat
	cuerpo.position = pos + Vector3(0, alto * 0.5, 0)
	add_child(cuerpo)
	_ventanas(pos, 26.0, 18.0, plantas)
	var techo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(27.0, 0.6, 19.0)
	techo.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
	techo.material_override = tmat
	techo.position = pos + Vector3(0, alto + 0.3, 0)
	add_child(techo)
	_cartel(pos + Vector3(0, 0, -14.0), "Hotel del club", true)

## El estacionamiento: es subterráneo, así que lo que se ve es la RAMPA de
## bajada y el murete, no un edificio. Dibujar una torre de aparcamiento sería
## contradecir lo que dice el propio negocio.
func _parking_negocio() -> void:
	var pos := Vector3(334.0, 0, -145.0)
	var mat: StandardMaterial3D = Texturas.hormigon(Color(0.26, 0.27, 0.29)).duplicate()
	mat.roughness = 0.7
	var rampa := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(14.0, 0.6, 26.0)
	rampa.mesh = bm
	rampa.material_override = mat
	rampa.position = pos + Vector3(0, -1.2, 0)
	rampa.rotation.x = 0.14
	add_child(rampa)
	for lado in [-1.0, 1.0]:
		var muro := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = Vector3(1.0, 2.4, 26.0)
		muro.mesh = mm
		muro.material_override = mat
		muro.position = pos + Vector3(lado * 7.5, 0.4, 0)
		add_child(muro)
	_cartel(pos + Vector3(0, 0, 18.0), "Estacionamiento", true)

## El centro comercial: cuatro edificios comerciales CC0 de Kenney (mismo pack
## "City Kit Commercial" que ya da los rascacielos del horizonte) en manzana,
## en vez de una caja lisa. Es LA joya del negocio según el propio juego, así
## que tiene que verse como una manzana entera, no como un galpón.
func _centro_comercial() -> void:
	var base := Vector3(-306.0, 0, 110.0)
	var mallas: Array = []
	for ruta in RUTAS_COMERCIAL:
		var esc: PackedScene = load(ruta)
		if esc != null:
			mallas.append(esc)
	if mallas.is_empty():
		return
	var sitios := [
		Vector3(-38, 0, -52), Vector3(12, 0, -52),
		Vector3(-38, 0, -8), Vector3(12, 0, -8),
		Vector3(-38, 0, 36), Vector3(12, 0, 36),
		Vector3(-38, 0, 72), Vector3(12, 0, 72),
	]
	## VARIEDAD, que era la primera pega del análisis: "los bloques se ven muy
	## idénticos entre sí". Con la misma escala y la misma orientación, ocho
	## edificios distintos siguen leyéndose como ocho copias. Tres cosas lo
	## arreglan casi gratis: cada uno a su altura (la escala en Y va aparte de
	## la del suelo), cada uno mirando a un lado, y la fila retranqueada -unos
	## pegados a la acera y otros metidos hacia dentro-, que es lo que de
	## verdad hace que una manzana parezca crecida y no estampada.
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 5150
	for i in range(sitios.size()):
		var esc: PackedScene = mallas[i % mallas.size()]
		var nodo: Node3D = esc.instantiate()
		## Los modelos de Kenney vienen en unidades de kit: la escala 6 es la
		## que ya se calibró para el horizonte.
		var base_esc := 6.0
		nodo.scale = Vector3(base_esc * rng2.randf_range(0.88, 1.12),
			base_esc * rng2.randf_range(0.7, 1.55),
			base_esc * rng2.randf_range(0.88, 1.12))
		nodo.position = base + (sitios[i] as Vector3) + Vector3(rng2.randf_range(-5.0, 5.0), 0, 0)
		nodo.rotation.y = (PI * 0.5) * float(rng2.randi() % 4)
		add_child(nodo)

	## El mobiliario de calle entre los dos frentes de la manzana: toldos y
	## parasoles del mismo kit. Es poca cosa y cambia mucho -sin ellos son
	## bloques en una parrilla; con ellos hay una calle comercial.
	var muebles: Array = []
	for ruta2 in RUTAS_MOBILIARIO:
		var e2: PackedScene = load(ruta2)
		if e2 != null:
			muebles.append(e2)
	if not muebles.is_empty():
		for i in range(6):
			var mu: Node3D = (muebles[i % muebles.size()] as PackedScene).instantiate()
			mu.scale = Vector3.ONE * 5.0
			mu.position = base + Vector3(-13.0, 0, -44.0 + i * 24.0)
			mu.rotation.y = PI * 0.5
			add_child(mu)
	_cartel(base + Vector3(0, 0, -92.0), "Centro comercial", true)

## LA ZONA INDUSTRIAL del terreno sur. Ese solar era el único que se quedaba
## vacío pase lo que pase: ningún negocio de la tabla lo pide, así que no tenía
## nada encima ni aunque lo compraras. Ahora, en cuanto es tuyo, se llena de
## naves, contenedores y maquinaria: es terreno del club y tiene que notarse
## que lo es -y de paso deja de ser el agujero del mapa-.
func _zona_industrial() -> void:
	var p: Dictionary = PARCELAS.get("sur", {})
	if p.is_empty():
		return
	var c: Vector2 = p["pos"]
	var base := Vector3(c.x, 0, c.y)

	var naves: Array = []
	for ruta in RUTAS_NAVES:
		var esc: PackedScene = load(ruta)
		if esc != null:
			naves.append(esc)
	## Seis naves, repartidas entre los 16 modelos (con todos, la fila se
	## salía del terreno por el fondo).
	for i in range(mini(naves.size(), 6)):
		var nave: Node3D = (naves[(i * 5 + 2) % naves.size()] as PackedScene).instantiate()
		nave.scale = Vector3.ONE * 7.0
		nave.position = base + Vector3(-32.0 + (i % 2) * 58.0, 0, -46.0 + (i / 2) * 56.0)
		nave.rotation.y = PI * 0.5
		add_child(nave)

	## Maquinaria aparcada y contenedores: lo que de verdad distingue una zona
	## industrial de un polígono de oficinas.
	var trastos := [
		{"r": "res://assets/ciudad/kenney_cars/tractor-shovel.glb", "p": Vector3(24, 0, 4), "e": 2.0},
		{"r": "res://assets/ciudad/kenney_cars/garbage-truck.glb", "p": Vector3(-6, 0, 28), "e": 2.0},
		{"r": "res://assets/ciudad/kenney_cars/delivery-flat.glb", "p": Vector3(30, 0, 34), "e": 2.0},
	]
	for t2 in trastos:
		var esc2: PackedScene = load(String(t2["r"]))
		if esc2 == null:
			continue
		var nodo: Node3D = esc2.instantiate()
		nodo.scale = Vector3.ONE * float(t2["e"])
		nodo.position = base + (t2["p"] as Vector3)
		nodo.rotation.y = 0.6
		add_child(nodo)

	## El desguace del fondo: piezas sueltas y pilas de ruedas del kit.
	_desguace(base + Vector3(44.0, 0, 60.0), 5510)
	var caja_esc: PackedScene = load("res://assets/ciudad/kenney_cars/box.glb")
	if caja_esc != null:
		var rng := RandomNumberGenerator.new()
		rng.seed = 33117
		for i in range(14):
			var caja: Node3D = caja_esc.instantiate()
			caja.scale = Vector3.ONE * rng.randf_range(2.2, 3.4)
			caja.position = base + Vector3(rng.randf_range(-8.0, 46.0), 0, rng.randf_range(-24.0, 14.0))
			caja.rotation.y = rng.randf() * TAU
			add_child(caja)

## La clínica abierta al público: dentro del recinto (su terreno es la
## periferia, o sea el propio complejo), con la cruz a la vista.
func _clinica() -> void:
	var pos := Vector3(112.0, 0, 45.0)
	var alto := 12.0
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(22.0, alto, 17.0)
	cuerpo.mesh = bm
	var mat: StandardMaterial3D = Texturas.hormigon(Color(0.92, 0.93, 0.94)).duplicate()
	mat.roughness = 0.55
	cuerpo.material_override = mat
	cuerpo.position = pos + Vector3(0, alto * 0.5, 0)
	add_child(cuerpo)
	_ventanas(pos, 22.0, 17.0, 2)
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color(0.78, 0.14, 0.14)
	rojo.emission_enabled = true
	rojo.emission = Color(0.78, 0.14, 0.14)
	rojo.emission_energy_multiplier = 0.4
	for par in [Vector3(5.0, 1.2, 0.4), Vector3(1.4, 4.2, 0.4)]:
		var c := MeshInstance3D.new()
		var cbm := BoxMesh.new()
		cbm.size = par
		c.mesh = cbm
		c.material_override = rojo
		c.position = pos + Vector3(0, alto + 3.4, -8.8)
		add_child(c)
	_cartel(pos + Vector3(0, 0, -15.0), "Clínica deportiva", true)

# ---------------------------------------------------------------- barrio

## EL BARRIO RESIDENCIAL: el complejo que trajo el usuario ("Жилой комплекс"),
## al final del ramal sur y con su propia manzana. No va en el horizonte
## lejano -ahí se perdía- ni dentro del recinto: es el vecindario con el que
## el club comparte calle, y por eso tiene calle propia que lo une al anillo.
##
## LA CASA MODERNA (`oficina_dt.glb`) NO SE USA, y no es un olvido: de cerca
## se ve muy bien -es arquitectura moderna de verdad, ver
## `pruebas/pantalla_oficina_dt_aislada.png`- pero al tamaño de un edificio
## dentro del mapa se lee como una masa de formas rotas, que es exactamente lo
## que el usuario pidió quitar. Queda en `assets/ciudad/` por si algún día hay
## una escena a pie de calle donde sí luzca.
const BARRIO_EN := Vector3(-60.0, 0, 470.0)

## La finca amurallada ocupa el solar de la casa; entre las dos hileras de
## casas del barrio (a 42-52 m del eje) y con el portón mirando a la calle,
## que termina justo delante.
const FINCA_TAM := Vector2(64.0, 72.0)
const FINCA_PORTON_Z := BARRIO_EN.z - FINCA_TAM.y * 0.5

func _barrio_residencial() -> void:
	## LA CASA YA NO SE VE (26-9-2026, pedido del usuario: "esa casa que es
	## un modelo 3D debería ser cubierta por un muro de enredaderas, para que
	## sea más lindo el paisaje sin verla"). Se mide para saber cuánto ocupaba
	## -el barrio se sigue ordenando alrededor de ese solar- y en su lugar va
	## una finca cerrada por un muro cubierto de hiedra, con su portón y
	## árboles que asoman por encima.
	_finca_enredadera(BARRIO_EN, FINCA_TAM)
	## La Casa Grande ya no cabe aquí: tiene finca propia en la ciudad grande
	## (`CiudadExpansion`, 2x2 manzanas al sur del barrio).
	_cartel(Vector3(BARRIO_EN.x + 14.0, 0, FINCA_PORTON_Z - 6.0), "Barrio residencial", false)

	## UN BARRIO ES MÁS DE UNA CASA. Con el complejo solo, aquello era una
	## mansión suelta en mitad del campo al final de una carretera; con una
	## hilera de casas a cada lado de la calle se lee como el vecindario con el
	## que el club comparte esquina, que es lo que el usuario pidió. Se
	## reutilizan los edificios CC0 de Kenney -los mismos del centro comercial-
	## a menos escala, que a este tamaño pasan por casas de barrio.
	var casas: Array = []
	for ruta in RUTAS_COMERCIAL:
		var e2: PackedScene = load(ruta)
		if e2 != null:
			casas.append(e2)
	if casas.is_empty():
		return
	## EL BARRIO CRECE CON LOS SOCIOS. No con la reputación: son los socios los
	## que viven al lado del club, y es el número que sube cuando la gente se
	## engancha. De 3 casas por acera a 8 -con 60.000 socios, el barrio entero-.
	var socios := float(datos.get("club", {}).get("socios", 8000))
	var por_acera: int = clampi(3 + int(socios / 9000.0), 3, 8)
	## Igual que la manzana comercial: cada casa a su altura, con su retranqueo
	## y mirando a su lado. Un barrio de casas clónicas alineadas a tiralíneas
	## se lee como un polígono, no como un barrio.
	var rng3 := RandomNumberGenerator.new()
	rng3.seed = 9012
	var k := 0
	for lado in [-1.0, 1.0]:
		for i in range(por_acera):
			var esc2: PackedScene = casas[k % casas.size()]
			var casa: Node3D = esc2.instantiate()
			var e3 := 3.2
			casa.scale = Vector3.ONE * e3 * rng3.randf_range(0.85, 1.2)
			casa.position = BARRIO_EN + Vector3(
				lado * rng3.randf_range(42.0, 52.0), 0, -60.0 + i * 30.0 + rng3.randf_range(-4.0, 4.0))
			casa.rotation.y = ((PI * 0.5) if lado < 0.0 else (-PI * 0.5)) + rng3.randf_range(-0.12, 0.12)
			add_child(casa)
			k += 1
	_parque_barrio()


## ============================================================================
##  LOS FRENTES URBANOS (26-9-2026)
## ============================================================================
## Pedido del usuario: *"pon también los edificios 3D que no se usaron, hay un
## pack completo sin usar"*. Del kit CC0 "City Kit Commercial" de Kenney solo
## se usaban 8 de los 14 edificios y 4 de los 16 bloques simples. Ahora están
## todos, y además hay dónde verlos: las aceras de fuera del anillo (norte y
## sur) tienen manzanas continuas -una fila de fachada pegada a la acera, con
## los edificios de detalle mirando a la calle, y una segunda fila detrás con
## los bloques simples-, que es lo que convierte una carretera entre prados en
## una calle de ciudad. Cuántas manzanas hay depende del club (igual que el
## horizonte): un club chico tiene tramos sueltos, uno grande calles enteras.
var _frentes: Array[Rect2] = []

func _en_frente_urbano(x: float, z: float) -> bool:
	for r in _frentes:
		if r.grow(4.0).has_point(Vector2(x, z)):
			return true
	## Ni sobre ninguna calle con sus aceras (ramales incluidos).
	for v in _vias:
		var rv := _rect_en(v, true)
		if x > rv[0] - 8.0 and x < rv[1] + 8.0 and z > rv[2] - 8.0 and z < rv[3] + 8.0:
			return true
	return false

func _frentes_urbanos() -> void:
	var detalle: Array[PackedScene] = []
	for ruta in RUTAS_COMERCIAL:
		var e: PackedScene = load(ruta)
		if e != null:
			detalle.append(e)
	var bloques: Array[PackedScene] = []
	for ruta in RUTAS_NAVES:
		var e2: PackedScene = load(ruta)
		if e2 != null:
			bloques.append(e2)
	if detalle.is_empty():
		return
	var toldos: Array[PackedScene] = []
	for ruta in RUTAS_MOBILIARIO:
		var e3: PackedScene = load(ruta)
		if e3 != null:
			toldos.append(e3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 26092026
	var lleno: float = lerpf(0.45, 1.0, _empuje_club())
	## Las cuatro aceras de fuera del anillo. `dir` es hacia dónde avanza la
	## fila, `afuera` hacia dónde queda el solar (lejos de la calle).
	var tramos := [
		{"calle": Vector3(0, 0, RING_Z_SUR), "dir": Vector3.RIGHT, "afuera": Vector3.BACK, "largo": RING_X},
		{"calle": Vector3(0, 0, RING_Z_NORTE), "dir": Vector3.RIGHT, "afuera": Vector3.FORWARD, "largo": RING_X},
		{"calle": Vector3(RING_X, 0, (RING_Z_SUR + RING_Z_NORTE) * 0.5), "dir": Vector3.BACK, "afuera": Vector3.RIGHT, "largo": (RING_Z_SUR - RING_Z_NORTE) * 0.5},
		{"calle": Vector3(-RING_X, 0, (RING_Z_SUR + RING_Z_NORTE) * 0.5), "dir": Vector3.BACK, "afuera": Vector3.LEFT, "largo": (RING_Z_SUR - RING_Z_NORTE) * 0.5},
	]
	for t in tramos:
		_fila_urbana(t["calle"], t["dir"], t["afuera"], float(t["largo"]), detalle, bloques, toldos, rng, lleno)

# ---------------------------------------------------------------- distritos

## LOS DISTRITOS DE FUERA (7-10-2026, pedido: «en la ciudad faltan edificios y
## cosas 3D que tenemos»). Vista desde arriba, la ciudad acababa en el anillo:
## una fila corta de fachadas y después campo hasta el horizonte. Aquí se
## levantan MANZANAS de verdad en el suelo libre de fuera (norte, este y
## sudeste), con sus calles, con todo el kit comercial en las fachadas, las
## naves «de poco detalle» como bloques interiores y, en el centro del distrito
## norte, los rascacielos del kit (que hasta hoy solo estaban de fondo). Cuantos
## más socios y reputación, más manzanas llenas. Se apartan del río, del
## barrio, del karting y de las parcelas.
const DISTRITOS := [
	{"nombre": "Distrito Norte", "desde": Vector2(-360, -575), "hasta": Vector2(360, -410), "centro": true},
	{"nombre": "Distrito Este", "desde": Vector2(425, -270), "hasta": Vector2(590, 250), "centro": false},
	{"nombre": "Ensanche Sur", "desde": Vector2(230, 300), "hasta": Vector2(420, 545), "centro": false},
]
const MANZANA := Vector2(54.0, 42.0)
const CALLE_DISTRITO := 14.0

func _distritos() -> void:
	var comercial: Array[PackedScene] = []
	for ruta in RUTAS_COMERCIAL:
		var e: PackedScene = load(ruta)
		if e != null:
			comercial.append(e)
	var naves: Array[PackedScene] = []
	for ruta in RUTAS_NAVES:
		var e2: PackedScene = load(ruta)
		if e2 != null:
			naves.append(e2)
	var altos: Array[PackedScene] = []
	for ruta in RUTAS_HORIZONTE:
		var e3: PackedScene = load(ruta)
		if e3 != null:
			altos.append(e3)
	var toldos: Array[PackedScene] = []
	for ruta in RUTAS_MOBILIARIO:
		var e4: PackedScene = load(ruta)
		if e4 != null:
			toldos.append(e4)
	if comercial.is_empty():
		return
	var asfalto: StandardMaterial3D = Texturas.asfalto(Color(0.14, 0.14, 0.15)).duplicate()
	asfalto.roughness = 0.5
	var acera := _mat_simple(Color(0.42, 0.41, 0.39), 0.9)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7102026
	var lleno: float = lerpf(0.62, 1.0, _empuje_club())
	manzanas_distrito = 0
	for d: Dictionary in DISTRITOS:
		var desde: Vector2 = d["desde"]
		var hasta: Vector2 = d["hasta"]
		var paso := MANZANA + Vector2(CALLE_DISTRITO, CALLE_DISTRITO)
		var nx := int(floor((hasta.x - desde.x) / paso.x))
		var nz := int(floor((hasta.y - desde.y) / paso.y))
		if nx <= 0 or nz <= 0:
			continue
		## Centrado en su rectángulo.
		var origen := desde + ((hasta - desde) - Vector2(nx, nz) * paso + Vector2(CALLE_DISTRITO, CALLE_DISTRITO)) * 0.5
		## Las calles del distrito: una rejilla de franjas de asfalto.
		var ancho_total := float(nx) * paso.x + CALLE_DISTRITO
		var fondo_total := float(nz) * paso.y + CALLE_DISTRITO
		var esquina := origen - Vector2(CALLE_DISTRITO, CALLE_DISTRITO)
		for i in nx + 1:
			var x := esquina.x + CALLE_DISTRITO * 0.5 + float(i) * paso.x
			_franja(Vector3(x, 0, esquina.y + fondo_total * 0.5), Vector2(CALLE_DISTRITO, fondo_total), asfalto)
		for k in nz + 1:
			var z := esquina.y + CALLE_DISTRITO * 0.5 + float(k) * paso.y
			_franja(Vector3(esquina.x + ancho_total * 0.5, 0, z), Vector2(ancho_total, CALLE_DISTRITO), asfalto)
		var mitad := Vector2(float(nx) * 0.5, float(nz) * 0.5)
		for i in nx:
			for k in nz:
				var c2 := origen + Vector2(float(i) * paso.x + MANZANA.x * 0.5, float(k) * paso.y + MANZANA.y * 0.5)
				var c := Vector3(c2.x, 0, c2.y)
				## La acera de la manzana.
				var base := _caja_en(Vector3(c.x, altura_en(c.x, c.z) + 0.1, c.z), Vector3(MANZANA.x, 0.2, MANZANA.y), acera)
				base.name = "Manzana"
				if rng.randf() > lleno:
					continue
				manzanas_distrito += 1
				## El corazón del distrito norte: torres.
				var cerca_centro: bool = bool(d["centro"]) and absf(float(i) + 0.5 - mitad.x) <= 1.0 and absf(float(k) + 0.5 - mitad.y) <= 1.0
				if cerca_centro and not altos.is_empty():
					## Tres torres por manzana y comercios en la planta baja.
					for o: Vector3 in [Vector3(-14, 0, -9), Vector3(14, 0, -9), Vector3(0, 0, 10)]:
						_torre_distrito(altos[rng.randi() % altos.size()], c + o, rng)
				else:
					_manzana(c, comercial, naves, toldos, rng)
		_cartel(Vector3(origen.x - 6.0, 0, origen.y - 6.0), String(d["nombre"]), false)

var manzanas_distrito := 0

func _franja(centro: Vector3, tam: Vector2, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tam.x, 0.1, tam.y)
	m.mesh = bm
	m.material_override = mat
	m.position = Vector3(centro.x, altura_en(centro.x, centro.z) + 0.05, centro.z)
	add_child(m)

## Una manzana: fachadas del kit mirando a la calle por los cuatro lados y un
## bloque alto dentro que asoma por encima.
func _manzana(c: Vector3, comercial: Array[PackedScene], naves: Array[PackedScene], toldos: Array[PackedScene], rng: RandomNumberGenerator) -> void:
	var lados := [
		{"n": Vector3(0, 0, 1), "dir": Vector3.RIGHT, "largo": MANZANA.x, "fondo": MANZANA.y},
		{"n": Vector3(0, 0, -1), "dir": Vector3.LEFT, "largo": MANZANA.x, "fondo": MANZANA.y},
		{"n": Vector3(1, 0, 0), "dir": Vector3.FORWARD, "largo": MANZANA.y, "fondo": MANZANA.x},
		{"n": Vector3(-1, 0, 0), "dir": Vector3.BACK, "largo": MANZANA.y, "fondo": MANZANA.x},
	]
	for l: Dictionary in lados:
		var n: Vector3 = l["n"]
		var dir: Vector3 = l["dir"]
		var largo: float = float(l["largo"]) - 14.0   ## las esquinas quedan libres
		var u := -largo * 0.5
		var giro := atan2(n.x, n.z)
		while u < largo * 0.5 - 5.0:
			var nodo: Node3D = comercial[rng.randi() % comercial.size()].instantiate()
			if rng.randf() < 0.45:
				tenir(nodo, rng.randi())
			var s: float = 4.6 * rng.randf_range(0.9, 1.1)
			nodo.scale = Vector3.ONE * s
			var caja := _caja_de(nodo)
			var ancho: float = maxf(caja.size.x * s, 5.0)
			var fondo: float = maxf(caja.size.z * s, 5.0)
			if u + ancho > largo * 0.5:
				nodo.free()
				break
			var p: Vector3 = c + dir * (u + ancho * 0.5) + n * (float(l["fondo"]) * 0.5 - fondo * 0.5 - 0.5)
			nodo.rotation.y = giro
			nodo.position = Vector3(p.x, altura_en(p.x, p.z) - 0.1, p.z)
			add_child(nodo)
			_frentes.append(_rect_de(p, dir, ancho, fondo))
			if not toldos.is_empty() and rng.randf() < 0.25:
				var tl: Node3D = toldos[rng.randi() % toldos.size()].instantiate()
				tl.scale = Vector3.ONE * 3.8
				tl.rotation.y = giro
				var tp: Vector3 = c + dir * (u + ancho * 0.5) + n * (float(l["fondo"]) * 0.5 + 1.2)
				tl.position = Vector3(tp.x, altura_en(tp.x, tp.z), tp.z)
				add_child(tl)
			u += ancho + rng.randf_range(0.3, 2.0)
	if not naves.is_empty() and rng.randf() < 0.85:
		var b: Node3D = naves[rng.randi() % naves.size()].instantiate()
		var sb: float = 5.5 * rng.randf_range(0.9, 1.2)
		b.scale = Vector3.ONE * sb
		b.rotation.y = float(rng.randi() % 4) * PI * 0.5
		b.position = Vector3(c.x, altura_en(c.x, c.z) - 0.1, c.z)
		add_child(b)

## Una torre del kit en el centro del distrito norte, con su plaza.
func _torre_distrito(esc: PackedScene, c: Vector3, rng: RandomNumberGenerator) -> void:
	var t: Node3D = esc.instantiate()
	var s: float = 3.6 * rng.randf_range(0.85, 1.3) * lerpf(0.85, 1.3, _empuje_club())
	t.scale = Vector3.ONE * s
	t.rotation.y = float(rng.randi() % 4) * PI * 0.5
	t.position = Vector3(c.x, altura_en(c.x, c.z) - 0.1, c.z)
	add_child(t)
	var caja := _caja_de(t)
	_frentes.append(Rect2(c.x - caja.size.x * s * 0.5, c.z - caja.size.z * s * 0.5, caja.size.x * s, caja.size.z * s))

## Una fila de edificios a lo largo de una acera. Se salta los cruces, el
## ramal del barrio y los ramales y solares de las parcelas.
func _fila_urbana(calle: Vector3, dir: Vector3, afuera: Vector3, medio_largo: float,
		detalle: Array[PackedScene], bloques: Array[PackedScene], toldos: Array[PackedScene],
		rng: RandomNumberGenerator, lleno: float) -> void:
	## La línea de fachada: justo detrás de la acera (calzada/2 + bordillo +
	## acera + un metro de retranqueo).
	var linea: float = ANCHO_CALLE * 0.5 + BORDILLO + ACERA + 1.0
	## Los edificios del kit miran a +Z: se giran para dar la cara a su calle.
	var giro: float = atan2(-afuera.x, -afuera.z)
	var u := -medio_largo + ANCHO_CALLE
	var orden := 0
	while u < medio_largo - ANCHO_CALLE:
		var eje: Vector3 = calle + dir * u
		if _hueco_urbano(eje, afuera, linea):
			u += 6.0
			continue
		## Tramos vacíos con un club chico: la calle se va llenando.
		if rng.randf() > lleno:
			u += rng.randf_range(18.0, 30.0)
			continue
		var esc: PackedScene = detalle[(orden * 5 + rng.randi() % 3) % detalle.size()]
		orden += 1
		var nodo: Node3D = esc.instantiate()
		var s: float = 5.5 * rng.randf_range(0.9, 1.1)
		nodo.scale = Vector3.ONE * s
		var caja := _caja_de(nodo)
		var ancho: float = maxf(caja.size.x * s, 6.0)
		var fondo: float = maxf(caja.size.z * s, 6.0)
		## No invadir el hueco siguiente (cruce, ramal o parcela).
		if _hueco_urbano(calle + dir * (u + ancho), afuera, linea):
			nodo.free()
			u += 6.0
			continue
		var c: Vector3 = calle + dir * (u + ancho * 0.5) + afuera * (linea + fondo * 0.5)
		nodo.rotation.y = giro
		nodo.position = Vector3(c.x, altura_en(c.x, c.z) - 0.2, c.z)
		add_child(nodo)
		_frentes.append(_rect_de(c, dir, ancho, fondo))
		## Un toldo o marquesina sobre la acera, uno de cada tres locales.
		if not toldos.is_empty() and rng.randf() < 0.33:
			var tl: Node3D = toldos[rng.randi() % toldos.size()].instantiate()
			tl.scale = Vector3.ONE * 4.5
			tl.rotation.y = giro
			var tp: Vector3 = calle + dir * (u + ancho * 0.5) + afuera * (linea - 1.6)
			tl.position = Vector3(tp.x, altura_en(tp.x, tp.z), tp.z)
			add_child(tl)
		## Segunda fila: un bloque simple detrás, más alto, que asoma por
		## encima de la fachada como en cualquier centro.
		if not bloques.is_empty() and rng.randf() < 0.8:
			var b: Node3D = bloques[rng.randi() % bloques.size()].instantiate()
			if rng.randf() < 0.45:
				tenir(b, rng.randi())
			var sb: float = 6.0 * rng.randf_range(0.9, 1.2)
			b.scale = Vector3.ONE * sb
			var cb := _caja_de(b)
			var fondo_b: float = maxf(cb.size.z * sb, 6.0)
			var pb: Vector3 = c + afuera * (fondo * 0.5 + 4.0 + fondo_b * 0.5)
			if not _hueco_urbano(pb - afuera * (linea + fondo * 0.5 + 4.0 + fondo_b * 0.5), afuera, linea + fondo + 4.0 + fondo_b):
				b.rotation.y = giro
				b.position = Vector3(pb.x, altura_en(pb.x, pb.z) - 0.2, pb.z)
				add_child(b)
				_frentes.append(_rect_de(pb, dir, maxf(cb.size.x * sb, 6.0), fondo_b))
			else:
				b.free()
		u += ancho + rng.randf_range(0.5, 3.5)

func _rect_de(c: Vector3, dir: Vector3, ancho: float, fondo: float) -> Rect2:
	var ex: float = ancho if absf(dir.x) > 0.5 else fondo
	var ez: float = fondo if absf(dir.x) > 0.5 else ancho
	return Rect2(c.x - ex * 0.5, c.z - ez * 0.5, ex, ez)

## ¿Hay algo en este punto de la acera que no se puede tapar? El ramal del
## barrio, los ramales de las parcelas (con su solar) y el río.
func _hueco_urbano(eje: Vector3, afuera: Vector3, fondo: float) -> bool:
	var lejos: Vector3 = eje + afuera * (fondo + 30.0)
	if absf(eje.z - RING_Z_SUR) < 1.0 and absf(eje.x - BARRIO_EN.x) < 70.0:
		return true
	if absf(eje.z - RING_Z_SUR) < 1.0 and absf(eje.x - KARTING_EN.x) < ANCHO_CALLE + 6.0:
		return true                   # el acceso al karting
	## Los cruces con la circunvalación exterior (z = -282 y z = 262).
	if absf(absf(eje.x) - RING_X) < 1.0 and (absf(eje.z - EX_N) < ANCHO_CALLE + 6.0 or absf(eje.z - EX_S) < ANCHO_CALLE + 6.0):
		return true
	for clave: String in PARCELAS:
		var p: Dictionary = PARCELAS[clave]
		var c: Vector2 = p["pos"]
		var r := Rect2(c.x - float(p["ancho"]) * 0.5, c.y - float(p["fondo"]) * 0.5, float(p["ancho"]), float(p["fondo"])).grow(14.0)
		## El ramal que la ata al anillo corre a la altura de su centro.
		if absf(eje.z - c.y) < ANCHO_CALLE + 6.0 and signf(eje.x) == signf(c.x) and absf(eje.x) > RING_X - 1.0:
			return true
		if r.has_point(Vector2(eje.x, eje.z)) or r.has_point(Vector2(lejos.x, lejos.z)):
			return true
	if lejos.x < RIO_X + 60.0 and lejos.x > RIO_X - 60.0:
		return true
	return false


const RUTA_CASA_GIGANTE := "res://assets/ciudad/complejo_residencial.glb"
var casa_gigante: Node3D = null

## La casa grande del barrio (`complejo_residencial.glb`), medida y centrada
## dentro de la finca, con un margen de jardín hasta el muro y el camino de
## entrada desde el portón.
func _casa_gigante(centro: Vector3, tam: Vector2) -> void:
	var esc := load(RUTA_CASA_GIGANTE)
	if esc == null or not (esc is PackedScene):
		return
	var n: Node3D = (esc as PackedScene).instantiate()
	var raiz := Node3D.new()
	raiz.name = "CasaGigante"
	add_child(raiz)
	raiz.add_child(n)
	var caja := _caja_de(n)
	## El origen del modelo no está en su centro ni en su base: se corrige.
	n.position = -Vector3(caja.position.x + caja.size.x * 0.5, caja.position.y, caja.position.z + caja.size.z * 0.5)
	var margen := 8.0
	var escala := minf((tam.x - margen * 2.0) / maxf(caja.size.x, 0.01), (tam.y - margen * 2.0 - 6.0) / maxf(caja.size.z, 0.01))
	raiz.scale = Vector3.ONE * escala
	raiz.rotation.y = PI
	raiz.position = centro + Vector3(0, 0.05, 3.0)
	casa_gigante = raiz
	## El camino desde el portón hasta la puerta.
	var losa := _mat_simple(Color(0.78, 0.74, 0.66), 0.85)
	var z0 := centro.z - tam.y * 0.5
	_caja_en(Vector3(centro.x, 0.06, z0 + 5.0), Vector3(6.0, 0.1, 10.0), losa)
	_rotulo(centro + Vector3(0, caja.size.y * escala + 6.0, 0), "🏰 La Casa Grande", Color(1, 0.92, 0.7), 22)
	puntos_clic.append({"k": "casa_grande", "n": "La Casa Grande", "pos": centro, "estado": "ciudad"})

## La finca del barrio: muro de 5,5 m cubierto de enredadera, con la copa de
## la hiedra desbordando por arriba (bultos irregulares, no una arista recta),
## un portón de hierro hacia la calle y árboles dentro.
func _finca_enredadera(centro: Vector3, tam: Vector2) -> void:
	var hiedra := Texturas.enredadera()
	var alto := 5.5
	var grosor := 1.2
	var portal := 9.0
	var mitad := tam * 0.5
	## Cuatro lados; el norte (hacia el ramal) con el hueco del portón.
	var lados := [
		{"c": Vector3(0, 0, mitad.y), "t": Vector3(tam.x, alto, grosor)},
		{"c": Vector3(-mitad.x, 0, 0), "t": Vector3(grosor, alto, tam.y)},
		{"c": Vector3(mitad.x, 0, 0), "t": Vector3(grosor, alto, tam.y)},
		{"c": Vector3(-(tam.x + portal) * 0.25, 0, -mitad.y), "t": Vector3((tam.x - portal) * 0.5, alto, grosor)},
		{"c": Vector3((tam.x + portal) * 0.25, 0, -mitad.y), "t": Vector3((tam.x - portal) * 0.5, alto, grosor)},
	]
	var bultos: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 4401
	for l in lados:
		var t: Vector3 = l["t"]
		var p: Vector3 = centro + (l["c"] as Vector3)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = t
		mi.mesh = bm
		mi.material_override = hiedra
		mi.position = p + Vector3(0, alto * 0.5, 0)
		add_child(mi)
		## La hiedra que desborda: bultos cada ~2 m por arriba y algunos
		## colgando por las caras.
		var largo: float = maxf(t.x, t.z)
		var eje := Vector3(1, 0, 0) if t.x > t.z else Vector3(0, 0, 1)
		var d := -largo * 0.5 + 1.0
		while d < largo * 0.5 - 0.5:
			var r := rng.randf_range(0.9, 1.5)
			var q := p + eje * d + Vector3(0, alto + rng.randf_range(-0.5, 0.1), 0)
			bultos.append(Transform3D(Basis().scaled(Vector3(r * 1.3, r * 0.8, r * 1.1)), q))
			if rng.randf() < 0.35:
				var lado_c: float = -1.0 if rng.randf() < 0.5 else 1.0
				var normal := Vector3(0, 0, 1) if t.x > t.z else Vector3(1, 0, 0)
				var q2 := p + eje * d + normal * lado_c * grosor * 0.5 + Vector3(0, rng.randf_range(1.0, alto - 1.0), 0)
				bultos.append(Transform3D(Basis().scaled(Vector3(0.9, 1.6, 0.9) * rng.randf_range(0.5, 0.8)), q2))
			d += rng.randf_range(1.6, 2.4)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var esf := SphereMesh.new()
	esf.radius = 1.0
	esf.height = 2.0
	esf.radial_segments = 10
	esf.rings = 6
	mm.mesh = esf
	mm.instance_count = bultos.size()
	for k in bultos.size():
		mm.set_instance_transform(k, bultos[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = hiedra
	add_child(mmi)
	## Pilares de piedra y portón de hierro.
	var piedra := Texturas.hormigon(Color(0.62, 0.6, 0.56), 77)
	var hierro := StandardMaterial3D.new()
	hierro.albedo_color = Color(0.08, 0.08, 0.09)
	hierro.metallic = 0.7
	hierro.roughness = 0.4
	for s in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(1.6, alto + 0.8, 1.6)
		pil.mesh = pb
		pil.material_override = piedra
		pil.position = centro + Vector3(s * portal * 0.5, (alto + 0.8) * 0.5, -mitad.y)
		add_child(pil)
	var barrotes := int(portal / 0.35)
	for b in barrotes:
		var bar := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.035
		cm.bottom_radius = 0.035
		cm.height = alto - 1.0
		bar.mesh = cm
		bar.material_override = hierro
		bar.position = centro + Vector3(-portal * 0.5 + 0.9 + b * (portal - 1.8) / float(maxi(barrotes - 1, 1)), (alto - 1.0) * 0.5, -mitad.y)
		add_child(bar)
	for y in [0.6, alto - 1.2]:
		var trav := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(portal - 1.6, 0.1, 0.08)
		trav.mesh = tb
		trav.material_override = hierro
		trav.position = centro + Vector3(0, y, -mitad.y)
		add_child(trav)
	## Dentro, sobre el propio césped del terreno: árboles que asoman por
	## encima del muro.
	var tronco := StandardMaterial3D.new()
	tronco.albedo_color = Color(0.3, 0.2, 0.12)
	var copa := StandardMaterial3D.new()
	copa.albedo_color = Color(0.13, 0.34, 0.12)
	copa.roughness = 0.9
	for k in 14:
		var pos := centro + Vector3(rng.randf_range(-mitad.x + 5.0, mitad.x - 5.0), 0, rng.randf_range(-mitad.y + 8.0, mitad.y - 5.0))
		var h := rng.randf_range(8.0, 12.0)
		var tr := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.3
		tc.bottom_radius = 0.45
		tc.height = h
		tr.mesh = tc
		tr.material_override = tronco
		tr.position = pos + Vector3(0, h * 0.5, 0)
		add_child(tr)
		var cp := MeshInstance3D.new()
		var cs := SphereMesh.new()
		cs.radius = rng.randf_range(3.2, 4.6)
		cs.height = cs.radius * 1.8
		cp.mesh = cs
		cp.material_override = copa
		cp.position = pos + Vector3(0, h, 0)
		add_child(cp)


## ============================================================================
##  LO QUE FALTABA DEL CAR KIT (26-9-2026)
## ============================================================================
## "Hay modelos 3D de los packs de ciudad que no se implementaron". Del Car Kit
## CC0 de Kenney se usaban 17 de 50. Ahora: camiones y patrulla en el tráfico,
## los dos deportivos en las plazas VIP del aparcamiento, los cinco karts en su
## pista (dando vueltas de verdad), y las ruedas, conos y piezas sueltas en el
## taller del karting y en el desguace de la zona industrial.
const KARTS := ["kart-oobi", "kart-oodi", "kart-ooli", "kart-oopi", "kart-oozi"]
const RUEDAS := ["wheel-default", "wheel-dark", "wheel-racing", "wheel-truck", "wheel-tractor-back", "wheel-tractor-front"]
const PIEZAS := ["debris-bolt", "debris-bumper", "debris-door-window", "debris-door", "debris-drivetrain-axle",
	"debris-drivetrain", "debris-nut", "debris-plate-a", "debris-plate-b", "debris-plate-small-a",
	"debris-plate-small-b", "debris-spoiler-a", "debris-spoiler-b", "debris-tire"]
const KARTING_EN := Vector3(118.0, 0, 468.0)
const RUEDAS_TODAS := ["wheel-default", "wheel-dark", "wheel-racing", "wheel-truck", "wheel-tractor-back",
	"wheel-tractor-front", "wheel-tractor-dark-back", "wheel-tractor-dark-front"]

static func _extra(nombre: String) -> PackedScene:
	var r := "res://assets/ciudad/kenney_cars_extra/%s.glb" % nombre
	return load(r) if ResourceLoader.exists(r) else null

func _poner_extra(nombre: String, pos: Vector3, esc: float, giro: float) -> Node3D:
	var e := _extra(nombre)
	if e == null:
		return null
	var n: Node3D = e.instantiate()
	n.scale = Vector3.ONE * esc
	n.position = pos
	n.rotation.y = giro
	add_child(n)
	return n

## Pilas de ruedas y piezas sueltas alrededor de `centro`.
func _desguace(centro: Vector3, semilla: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	## Todas las piezas y ruedas del kit al menos una vez (7-10-2026).
	for k in PIEZAS.size():
		_poner_extra(PIEZAS[k], centro + Vector3(-14.0 + float(k) * 2.1, 0, 11.0), 2.4, rng.randf() * TAU)
	for k in RUEDAS_TODAS.size():
		var rr := _poner_extra(RUEDAS_TODAS[k], centro + Vector3(-12.0 + float(k) * 2.6, 0.5, -11.0), 2.2, 0.0)
		if rr != null:
			rr.rotation.x = PI * 0.5
	for i in 6:
		var p := centro + Vector3(rng.randf_range(-12.0, 12.0), 0, rng.randf_range(-8.0, 8.0))
		var rueda: String = RUEDAS[rng.randi() % RUEDAS.size()]
		for k in rng.randi_range(2, 5):
			var r := _poner_extra(rueda, p + Vector3(0, k * 0.55, 0), 2.2, rng.randf() * TAU)
			if r != null:
				r.rotation.x = PI * 0.5
	for i in 18:
		_poner_extra(PIEZAS[rng.randi() % PIEZAS.size()],
			centro + Vector3(rng.randf_range(-14.0, 14.0), 0, rng.randf_range(-10.0, 10.0)),
			rng.randf_range(2.0, 2.8), rng.randf() * TAU)

## La pista de karting, al sur del anillo: óvalo de asfalto con piano de
## colores, barrera de neumáticos, conos, boxes con su taller, y los cinco
## karts del kit dando vueltas (una ruta más de `TraficoCiudad`).
func _karting() -> void:
	puntos_clic.append({"k": "karting", "n": "Karting · contrarreloj", "pos": KARTING_EN, "estado": "ciudad"})
	if _extra(KARTS[0]) == null:
		return
	var c := KARTING_EN
	var largo := 70.0
	var radio := 22.0
	var ancho_p := 9.0
	var asf := Texturas.asfalto(Color(0.15, 0.15, 0.16), 77)
	var cesp := StandardMaterial3D.new()
	cesp.albedo_color = Color(0.2, 0.42, 0.16)
	## El óvalo: tramo recto + dos curvas (discos), y dentro el césped.
	for capa: Array in [[radio, asf, 0.05], [radio - ancho_p, cesp, 0.07]]:
		var r: float = capa[0]
		var bm := BoxMesh.new()
		bm.size = Vector3(largo, 0.1, r * 2.0)
		var caja := MeshInstance3D.new()
		caja.mesh = bm
		caja.material_override = capa[1]
		caja.position = c + Vector3(0, capa[2], 0)
		add_child(caja)
		for s in [-1.0, 1.0]:
			var cm := CylinderMesh.new()
			cm.top_radius = r
			cm.bottom_radius = r
			cm.height = 0.1
			cm.radial_segments = 40
			var disco := MeshInstance3D.new()
			disco.mesh = cm
			disco.material_override = capa[1]
			disco.position = c + Vector3(s * largo * 0.5, capa[2], 0)
			add_child(disco)
	## Piano rojo y blanco en el borde interior de las rectas.
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color(0.85, 0.12, 0.12)
	var blanco := StandardMaterial3D.new()
	blanco.albedo_color = Color(0.95, 0.95, 0.95)
	for s in [-1.0, 1.0]:
		for k in 14:
			var pz := MeshInstance3D.new()
			var pb := BoxMesh.new()
			pb.size = Vector3(largo / 14.0, 0.06, 0.8)
			pz.mesh = pb
			pz.material_override = rojo if k % 2 == 0 else blanco
			pz.position = c + Vector3(-largo * 0.5 + (k + 0.5) * largo / 14.0, 0.12, s * (radio - ancho_p - 0.4))
			add_child(pz)
	## Barrera de neumáticos por fuera, a lo largo de todo el contorno.
	var n_bar := 64
	for k in n_bar:
		var t := float(k) / float(n_bar)
		var p := _en_ovalo(c, largo, radio + 1.5, t)
		_poner_extra("wheel-dark" if k % 3 != 0 else "wheel-default", p, 2.4, 0.0)
		_poner_extra("wheel-dark", p + Vector3(0, 0.5, 0), 2.4, 0.4)
	## Conos en las curvas.
	for k in 10:
		var t2 := 0.2 + 0.05 * k if k < 5 else 0.7 + 0.05 * (k - 5)
		_poner_extra("cone-flat" if k % 2 == 0 else "cone-flat", _en_ovalo(c, largo, radio - ancho_p - 1.2, t2), 2.5, 0.0)
	## Boxes: una nave baja con el taller de ruedas y piezas al lado.
	var boxes := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(26.0, 5.0, 9.0)
	boxes.mesh = bb
	boxes.material_override = Texturas.hormigon(Color(0.7, 0.7, 0.72), 88)
	boxes.position = c + Vector3(0, 2.5, -radio - 9.0)
	add_child(boxes)
	var techo := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(28.0, 0.4, 11.0)
	techo.mesh = tb
	techo.material_override = rojo
	techo.position = c + Vector3(0, 5.2, -radio - 9.0)
	add_child(techo)
	_desguace(c + Vector3(largo * 0.5 + radio + 10.0, 0, -radio - 6.0), 9021)
	_rotulo(c + Vector3(0, 10.0, -radio - 9.0), "🏎 Karting", Color(1, 1, 1), 26)
	_frentes.append(Rect2(c.x - largo * 0.5 - radio - 18.0, c.z - radio - 16.0, largo + radio * 2.0 + 36.0, radio * 2.0 + 20.0))
	## Los cinco karts en carrera.
	var ruta := PackedVector3Array()
	for k in 48:
		ruta.append(_en_ovalo(c, largo, radio - ancho_p * 0.5, float(k) / 48.0) + Vector3(0, 0.12, 0))
	_karts_pendientes = {"ruta": ruta}

## Un punto del óvalo (rectas en X, curvas en los extremos), `t` de 0 a 1.
static func _en_ovalo(c: Vector3, largo: float, r: float, t: float) -> Vector3:
	var recta := largo
	var curva := PI * r
	var total := 2.0 * recta + 2.0 * curva
	var d := fposmod(t, 1.0) * total
	if d < recta:
		return c + Vector3(-largo * 0.5 + d, 0, -r)
	d -= recta
	if d < curva:
		var a := d / r
		return c + Vector3(largo * 0.5 + sin(a) * r, 0, -cos(a) * r)
	d -= curva
	if d < recta:
		return c + Vector3(largo * 0.5 - d, 0, r)
	d -= recta
	var a2 := d / r
	return c + Vector3(-largo * 0.5 - sin(a2) * r, 0, cos(a2) * r)

var _karts_pendientes: Dictionary = {}

## Llamado desde `_trafico()`, cuando ya existe el tráfico.
func _karts_en_pista(t: TraficoCiudad) -> void:
	if _karts_pendientes.is_empty():
		return
	var id := t.agregar_ruta(_karts_pendientes["ruta"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	for i in KARTS.size():
		var e := _extra(KARTS[i])
		if e == null:
			continue
		var n: Node3D = e.instantiate()
		n.scale = Vector3.ONE * 2.2
		t.agregar_vehiculo(n, id, float(i) * 22.0, rng.randf_range(11.0, 15.0), 0.0, 0.0)
	_karts_pendientes = {}

# ---------------------------------------------------------------- perimetro

func _perimetro() -> void:
	## Cierra el recinto. Un complejo sin valla se ve como piezas sueltas flotando
	## en una explanada; con valla se lee como UN sitio.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color_club("c2", Color(0.75, 0.75, 0.75))
	mat.roughness = 0.6
	## La valla se calcula para que QUEPA todo: el estadio llega a z=-125 y la ultima
	## fila de edificios a z=195. Antes estaba en 150 y tres edificios se quedaban
	## fuera del recinto.
	## Se calcula desde el contenido REAL en vez de a ojo: 15 instalaciones en filas
	## de cuatro son cuatro filas, y la ultima cae en z = 115 + 3*32 = 211. Poner la
	## valla en 206 dejaba un edificio fuera del recinto.
	var filas: int = int(ceil(float(EDIFICIOS.size()) / 4.0))
	## Justo antes de la calle exterior (z=262, 16 m de ancho).
	var zFondo: float = FILA_0_Z + (filas - 1) * FILA_PASO + 14.0
	## HASTA -280 Y NO -128 (12-9-2026): desde que el estadio es el de verdad
	## y no una maqueta, ocupa de z=-260 a z=-120, así que con la valla vieja
	## el estadio quedaba FUERA de su propio recinto.
	var zFrente := -250.0
	var largo: float = zFondo - zFrente
	var centro: float = (zFondo + zFrente) * 0.5
	var lados := [
		{"p": Vector3(0, 1.5, zFrente), "s": Vector3(292, 3, 0.8)},
		{"p": Vector3(0, 1.5, zFondo),  "s": Vector3(292, 3, 0.8)},
		{"p": Vector3(-146, 1.5, centro), "s": Vector3(0.8, 3, largo)},
		{"p": Vector3(146, 1.5, centro),  "s": Vector3(0.8, 3, largo)},
	]
	for l in lados:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = l["s"]
		m.mesh = bm
		m.material_override = mat
		m.position = l["p"]
		add_child(m)


# ---------------------------------------------------------------------------
#  B7 (25-9-2026, plan maestro): SOLARES, OBRAS, RÓTULOS Y DÍA DE PARTIDO
# ---------------------------------------------------------------------------

## La parcela de una instalación que todavía no existe: tierra, un borde de
## bordillo y un cartel "Solar". Se clica para construirla.
func _solar_libre(e: Dictionary, pos: Vector3) -> void:
	var tierra := StandardMaterial3D.new()
	tierra.albedo_color = Color(0.46, 0.38, 0.27)
	tierra.roughness = 1.0
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(float(e["ancho"]), 0.3, float(e["fondo"]))
	mi.mesh = bm
	mi.material_override = tierra
	mi.position = pos + Vector3(0, 0.15, 0)
	add_child(mi)
	_rotulo(pos + Vector3(0, 6.0, 0), "＋ %s" % str(e["n"]), Color(0.75, 0.85, 0.78, 0.8), 22)
	puntos_clic.append({"k": String(e["k"]), "n": str(e["n"]), "pos": pos + Vector3(0, 1.0, 0), "estado": "solar"})

## Una obra se VE: andamio alrededor, subiendo con el avance, y una grúa.
func _obra_en_curso(pos: Vector3, ancho: float, fondo: float, alto_final: float, avance: float) -> void:
	## Conos de obra alrededor (del Car Kit, 26-9-2026).
	for k in 12:
		var a := TAU * float(k) / 12.0
		_poner_extra("cone-flat", pos + Vector3(cos(a) * (ancho * 0.5 + 4.0), 0, sin(a) * (fondo * 0.5 + 4.0)), 2.4, a)
	var tubo := StandardMaterial3D.new()
	tubo.albedo_color = Color(0.85, 0.62, 0.18)
	tubo.roughness = 0.6
	var alto := maxf(3.0, alto_final * clampf(avance + 0.15, 0.15, 1.0))
	var paso := 4.0
	for lado in 4:
		var largo: float = ancho if lado < 2 else fondo
		var n := int(largo / paso) + 1
		for k in n:
			var t := -largo / 2.0 + float(k) * paso
			var p: Vector3
			match lado:
				0: p = Vector3(t, 0, fondo / 2.0 + 1.2)
				1: p = Vector3(t, 0, -fondo / 2.0 - 1.2)
				2: p = Vector3(ancho / 2.0 + 1.2, 0, t)
				_: p = Vector3(-ancho / 2.0 - 1.2, 0, t)
			var poste := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.18, alto, 0.18)
			poste.mesh = bm
			poste.material_override = tubo
			poste.position = pos + p + Vector3(0, alto / 2.0, 0)
			add_child(poste)
	## Pasarelas cada 3 m de altura.
	var pisos := int(alto / 3.0)
	for f in pisos:
		var y := 3.0 * float(f + 1)
		for z in [fondo / 2.0 + 1.2, -fondo / 2.0 - 1.2]:
			var tabla := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(ancho + 2.4, 0.12, 0.9)
			tabla.mesh = tm
			tabla.material_override = tubo
			tabla.position = pos + Vector3(0, y, z)
			add_child(tabla)
	_grua(pos + Vector3(ancho / 2.0 + 9.0, 0, -fondo / 2.0 - 6.0), alto_final + 22.0)

## La grúa torre: mástil de celosía (en cajas), pluma y contrapluma.
func _grua(pos: Vector3, alto: float) -> void:
	var amarillo := StandardMaterial3D.new()
	amarillo.albedo_color = Color(0.95, 0.72, 0.10)
	amarillo.roughness = 0.5
	var raiz := Node3D.new()
	raiz.name = "Grua"
	raiz.position = pos
	add_child(raiz)
	var mastil := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, alto, 1.6)
	mastil.mesh = bm
	mastil.material_override = amarillo
	mastil.position = Vector3(0, alto / 2.0, 0)
	raiz.add_child(mastil)
	var pluma := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(1.0, 1.0, alto * 0.9)
	pluma.mesh = pm
	pluma.material_override = amarillo
	pluma.position = Vector3(0, alto + 0.5, alto * 0.3)
	raiz.add_child(pluma)
	var contrapeso := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(2.2, 2.0, 3.0)
	contrapeso.mesh = cm
	var gris := StandardMaterial3D.new()
	gris.albedo_color = Color(0.35, 0.36, 0.38)
	contrapeso.material_override = gris
	contrapeso.position = Vector3(0, alto - 0.2, -alto * 0.12)
	raiz.add_child(contrapeso)
	## El cable con su carga, colgando de la punta.
	var cable := MeshInstance3D.new()
	var cbm := BoxMesh.new()
	cbm.size = Vector3(0.08, alto * 0.45, 0.08)
	cable.mesh = cbm
	cable.material_override = gris
	cable.position = Vector3(0, alto - alto * 0.225, alto * 0.62)
	raiz.add_child(cable)
	raiz.rotation.y = float(int(pos.x * 7.0 + pos.z) % 360) * PI / 180.0

## Un rótulo flotante: siempre del mismo tamaño en pantalla y mirando a cámara.
func _rotulo(pos: Vector3, texto: String, color: Color, tam: int = 28) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = tam
	l.outline_size = 10
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.pixel_size = 0.0007
	l.no_depth_test = true
	l.position = pos
	l.add_to_group("rotulo_mapa")
	_rotulos.add_child(l)

func mostrar_rotulos(si: bool) -> void:
	if _rotulos != null:
		_rotulos.visible = si

## LA CIUDAD RESPONDE AL CLUB (fase 5): pancartas en la euforia, persianas y
## grafitis en la crisis. Ver `CiudadAnimo`.
var animo_montado: Dictionary = {}

func _animo_del_club() -> void:
	var animo: Dictionary = datos.get("animo", {})
	if animo.is_empty():
		return
	var c1 := _color_club("c1", Color(0.2, 0.5, 0.3))
	var c2 := _color_club("c2", Color(1, 1, 1))
	animo_montado = CiudadAnimo.montar(self, animo, _frentes, ESTADIO_EN, c1, c2)
	var est := String(animo.get("estado", "normal"))
	if est == "euforia":
		_banderas_anillo(c1, c2)
	var txt := {"euforia": "🏆 LA CIUDAD ESTÁ DE FIESTA", "bien": "🙂 Buen ambiente en la ciudad",
		"mal": "😒 La ciudad empieza a impacientarse", "crisis": "😡 LA CIUDAD ESTÁ HARTA"}.get(est, "") as String
	if txt != "":
		var col := Color(1.0, 0.85, 0.3) if est in ["euforia", "bien"] else Color(1.0, 0.45, 0.4)
		_rotulo(ESTADIO_EN + Vector3(0, 78.0, 0), "%s · %s" % [txt, String(animo.get("motivo", ""))], col, 26)

## El humor del barrio sobre el barrio.
func _rotulo_barrio() -> void:
	if not datos.has("vecinos"):
		return
	var v := int(datos["vecinos"])
	var cara := "🙂" if v >= 65 else ("😠" if v <= 35 else "😐")
	var col := Color(0.55, 0.9, 0.6) if v >= 65 else (Color(1.0, 0.5, 0.45) if v <= 35 else Color(1.0, 0.85, 0.45))
	_rotulo(BARRIO_EN + Vector3(0, 55.0, 0), "%s Vecinos %d/100" % [cara, v], col)

## DÍA DE PARTIDO: banderas del club en las farolas del anillo y la hinchada
## caminando hacia el estadio. La gente es un MultiMesh de cápsulas -600 en un
## solo draw call- con los dos colores del club y ropa neutra.
func _dia_de_partido() -> void:
	var c1 := _color_club("c1", Color(0.2, 0.5, 0.3))
	var c2 := _color_club("c2", Color(1, 1, 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	_banderas_anillo(c1, c2)
	_hinchada_estadio(c1, c2, rng)

## Banderas del club en las farolas del anillo (día de partido y euforia).
var _anillo_con_banderas := false

func _banderas_anillo(c1: Color, c2: Color) -> void:
	if _anillo_con_banderas:
		return
	_anillo_con_banderas = true
	for i in 28:
		var t := float(i) / 28.0
		var x := lerpf(-RING_X, RING_X, t)
		for z in [RING_Z_NORTE + ANCHO_CALLE, RING_Z_SUR - ANCHO_CALLE]:
			var mastil := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.2, 9.0, 0.2)
			mastil.mesh = bm
			var gris := StandardMaterial3D.new()
			gris.albedo_color = Color(0.7, 0.7, 0.72)
			mastil.material_override = gris
			mastil.position = Vector3(x, 4.5, z)
			add_child(mastil)
			StadiumBuilder._bandera_ondeante(self, Vector3(x + 1.3, 7.6, z), Vector2(2.6, 1.6),
				c1 if i % 2 == 0 else c2, 0.0, float(i) * 0.7)

func _en_huella(p: Vector3) -> bool:
	for r: Rect2 in huellas:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false

## ESTADIO 2.0: el vestuario está detrás de la tribuna, donde muere la avenida
## del estadio. Las marcas viales y piezas planas de la calle que caen dentro
## asomarían por su suelo: se quitan.
var _rect_vestuario := Rect2()
var _rect_entrada := Rect2()

func _despejar_vestuario(n: Node, t: Transform3D = Transform3D()) -> void:
	## Se llama antes de que la ciudad esté en el árbol: las posiciones se
	## componen a mano (relativas a la ciudad), no con `global_position`.
	if _rect_vestuario.size == Vector2.ZERO or n.name == "TunelVestuario":
		return
	for h in n.get_children():
		if not (h is Node3D):
			continue
		var th: Transform3D = t * (h as Node3D).transform
		if h is MeshInstance3D:
			var mi := h as MeshInstance3D
			var p := th.origin
			var en_entrada := _rect_entrada.has_point(Vector2(p.x, p.z)) and p.y < 3.0 and mi.get_aabb().size.y >= 0.3 and mi.get_aabb().size.y < 3.5
			if mi.mesh != null and (en_entrada or (_rect_vestuario.has_point(Vector2(p.x, p.z)) and mi.get_aabb().size.y < 0.3 and p.y < 0.5)):
				mi.get_parent().remove_child(mi)
				mi.queue_free()
				continue
		_despejar_vestuario(h, th)

## La marea de gente alrededor del estadio.
##
## 8-10-2026: antes era una cápsula por persona, toda del color del club, y
## desde arriba se leían como PALOS blancos y negros clavados en el césped
## (el usuario: «¿esas cosas negras y blancas como palos son personas?»).
## Ahora cada hincha tiene piernas con pantalón, torso y brazos con la
## camiseta, cuello y cabeza con su tono de piel: tres MultiMesh que comparten
## posiciones (una sola llamada de dibujo por pieza para los 600).
func _hinchada_estadio(c1: Color, c2: Color, rng: RandomNumberGenerator) -> void:
	var piezas := _mallas_hincha_de_pie()
	var n := 600
	var mms: Array[MultiMesh] = []
	for pz in 3:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = piezas[pz]
		mm.instance_count = n
		mms.append(mm)
	var pieles := [Color(0.96, 0.8, 0.66), Color(0.87, 0.67, 0.5), Color(0.72, 0.52, 0.36), Color(0.5, 0.34, 0.22), Color(0.34, 0.22, 0.15)]
	var pantalones := [Color(0.16, 0.2, 0.32), Color(0.12, 0.12, 0.14), Color(0.3, 0.32, 0.36), Color(0.42, 0.36, 0.28), Color(0.22, 0.3, 0.48)]
	for k in n:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(105.0, 150.0)
		var p := ESTADIO_EN + Vector3(cos(ang) * r, 0.0, sin(ang) * r * 0.8)
		## Nadie dentro de un edificio (el vestuario del estadio, por ejemplo).
		for intento in 8:
			if not _en_huella(p):
				break
			ang = rng.randf() * TAU
			p = ESTADIO_EN + Vector3(cos(ang) * r, 0.0, sin(ang) * r * 0.8)
		## Mirando más o menos al estadio, cada uno a su altura.
		var hacia := ESTADIO_EN - p
		var giro := atan2(hacia.x, hacia.z) + rng.randf_range(-0.9, 0.9)
		var esc := rng.randf_range(0.9, 1.08)
		var t := Transform3D(Basis(Vector3.UP, giro).scaled(Vector3.ONE * esc), p)
		var tono := rng.randf()
		var camiseta: Color = c1 if tono < 0.45 else (c2 if tono < 0.7 else Color(0.2, 0.22, 0.25).lerp(Color(0.85, 0.85, 0.85), rng.randf()))
		var cols := [pantalones[rng.randi() % pantalones.size()], camiseta, pieles[rng.randi() % pieles.size()]]
		for pz in 3:
			mms[pz].set_instance_transform(k, t)
			mms[pz].set_instance_color(k, cols[pz])
	var gente := Node3D.new()
	gente.name = "Hinchada"
	add_child(gente)
	for pz in 3:
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mms[pz]
		gente.add_child(mi)
	_rotulo(ESTADIO_EN + Vector3(0, 62.0, 0), "⚽ HOY HAY PARTIDO", Color(1.0, 0.85, 0.3))

## Un hincha de pie en tres piezas (pantalón, camiseta, piel), cada una con su
## color por instancia. Low-poly: se ven de lejos y son cientos.
static var _piezas_hincha: Array = []

static func _mallas_hincha_de_pie() -> Array:
	if not _piezas_hincha.is_empty():
		return _piezas_hincha
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	## Piernas.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pierna := CapsuleMesh.new()
	pierna.radius = 0.085
	pierna.height = 0.9
	pierna.radial_segments = 6
	pierna.rings = 1
	for lado in [-1.0, 1.0]:
		st.append_from(pierna, 0, Transform3D(Basis(), Vector3(0.1 * lado, 0.45, 0)))
	var cadera := CylinderMesh.new()
	cadera.top_radius = 0.17
	cadera.bottom_radius = 0.16
	cadera.height = 0.16
	cadera.radial_segments = 7
	cadera.rings = 1
	st.append_from(cadera, 0, Transform3D(Basis().scaled(Vector3(1, 1, 0.72)), Vector3(0, 0.86, 0)))
	st.generate_normals()
	var piernas := st.commit()
	## Torso y brazos.
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var torso := CylinderMesh.new()
	torso.top_radius = 0.2
	torso.bottom_radius = 0.17
	torso.height = 0.58
	torso.radial_segments = 7
	torso.rings = 1
	st.append_from(torso, 0, Transform3D(Basis().scaled(Vector3(1, 1, 0.7)), Vector3(0, 1.21, 0)))
	var brazo := CapsuleMesh.new()
	brazo.radius = 0.055
	brazo.height = 0.62
	brazo.radial_segments = 5
	brazo.rings = 1
	for lado in [-1.0, 1.0]:
		st.append_from(brazo, 0, Transform3D(Basis(Vector3(0, 0, 1), 0.08 * lado), Vector3(0.25 * lado, 1.17, 0)))
	st.generate_normals()
	var camiseta := st.commit()
	## Cuello y cabeza.
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cuello := CylinderMesh.new()
	cuello.top_radius = 0.05
	cuello.bottom_radius = 0.055
	cuello.height = 0.1
	cuello.radial_segments = 5
	cuello.rings = 1
	st.append_from(cuello, 0, Transform3D(Basis(), Vector3(0, 1.54, 0)))
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.11
	cabeza.height = 0.25
	cabeza.radial_segments = 8
	cabeza.rings = 5
	st.append_from(cabeza, 0, Transform3D(Basis(), Vector3(0, 1.67, 0)))
	st.generate_normals()
	var piel := st.commit()
	for m: Mesh in [piernas, camiseta, piel]:
		m.surface_set_material(0, mat)
	_piezas_hincha = [piernas, camiseta, piel]
	return _piezas_hincha
