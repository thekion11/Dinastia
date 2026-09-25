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
const RUTA_COCHE1 := "res://assets/ciudad/coche1.fbx"
const RUTA_COCHE2 := "res://assets/ciudad/coche2.fbx"

## LOS DOS MODELOS QUE TRAJO EL USUARIO (12-9-2026), convertidos con
## `herramientas/fbx_a_glb.py` -texturas bajadas a 1024 px, malla decimada-.
## Ver `dinastia-modelos-3d-usuario.md`: "ДОМ скетч" (casa boceto) y "Жилой
## комплекс" (complejo residencial), ambos en `recursos/modelos3d/`.
const RUTA_OFICINA_DT := "res://assets/ciudad/oficina_dt.glb"
const RUTA_COMPLEJO_EXTRA := "res://assets/ciudad/complejo_residencial.glb"

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
	{"k": "med",       "n": "Centro medico",           "col": Color(0.78, 0.80, 0.82), "ancho": 24.0, "fondo": 19.0},
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

var datos: Dictionary = {}
var etiquetas: Array = []          ## [{pos:Vector3, texto:String, nivel:int}]

## LAS LUCES QUE DEPENDEN DE LA HORA. Se guardan al construir para poder
## encenderlas y apagarlas con el ciclo del sol sin recorrer el árbol entero
## cada fotograma -son decenas de farolas y todas las ventanas del complejo.
var _farolas_luz: Array[OmniLight3D] = []
var _ventanas_mat: Array[StandardMaterial3D] = []

func build(d: Dictionary) -> void:
	datos = d
	for c in get_children():
		c.queue_free()
	etiquetas.clear()
	_farolas_luz.clear()
	_ventanas_mat.clear()
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
	_arbolado()
	_horizonte()
	_trafico()

## `noche` va de 0 (pleno día) a 1 (noche cerrada). Lo llama el ciclo del sol
## de `VistaCiudad` en cada fotograma. Las farolas se encienden con la luz, y
## las ventanas pasan de un reflejo apagado a estar iluminadas por dentro:
## es lo que hace que a las 22:00 la ciudad deportiva siga estando AHÍ en vez
## de desaparecer en un bloque negro.
func encender_luces(noche: float) -> void:
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
	for zona in [
			{"pos": Vector3(0, 0.02, centro_p), "tam": Vector2(276, fondo_p)},
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
	var via := MeshInstance3D.new()
	var pv := PlaneMesh.new()
	## De la puerta sur (el anillo, z=320) hasta la boca del estadio (z=-90),
	## por el pasillo que queda entre las dos columnas de campos. Ni un metro
	## más al norte: ahí empieza el estadio.
	pv.size = Vector2(14, 410)
	via.mesh = pv
	via.position = Vector3(0, 0.04, 115)
	## Mismo `Texturas.asfalto()`, duplicado por el mismo motivo que `ma` arriba
	## -tinte distinto (mas oscuro, es una via, no la plaza), asi que ya es una
	## entrada de cache distinta, pero igual se duplica antes de mutar.
	var mv: StandardMaterial3D = Texturas.asfalto(Color(0.14, 0.14, 0.155)).duplicate()
	mv.roughness = 0.42
	mv.metallic = 0.1
	via.material_override = mv
	add_child(via)

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
const TERRENO_LADO := 5000.0
const TERRENO_CELDAS := 120          ## 121x121 vértices: suficiente para que las
                                     ## lomas se lean y barato de generar.
const LLANO_RADIO := 620.0           ## dentro de esto, altura 0 garantizada
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
					## hacia arriba (si se invierte, el terreno se ve desde
					## abajo y desde la cámara no hay nada: un agujero verde
					## donde estaba el suelo).
					for tri in [[p00, p01, p10], [p10, p01, p11]]:
						for p: Vector3 in tri:
							st.set_uv(Vector2(p.x, p.z) / 20.0)
							st.add_vertex(p)
			st.generate_normals()
			var mi := MeshInstance3D.new()
			mi.mesh = st.commit()
			mi.material_override = mat
			salida.append(mi)
	return salida

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
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260902
	var a := Color(0.20, 0.42, 0.20)
	var b := Color(0.27, 0.52, 0.26)
	for y in range(n):
		for x in range(n):
			var t: float = rng.randf()
			# alguna mata mas oscura de vez en cuando, para que no sea ruido plano
			if rng.randf() < 0.06:
				t = -0.35
			img.set_pixel(x, y, a.lerp(b, clampf(t, 0.0, 1.0)))
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
		add_child(nodo)
		var aforo := int(perfil.get("aforo", datos.get("club", {}).get("cap", 20000)))
		StadiumBuilder.build_pitch(nodo, perfil)
		## Ocupación media-baja: fuera de partido el estadio no está lleno, pero
		## con 0,06 la grada salía de un gris uniforme y desde el mapa el
		## estadio se leía como una pista de hockey. Con 0,35 se distinguen las
		## butacas del club, que es lo que lo hace reconocible desde arriba.
		StadiumBuilder.build(nodo, perfil, aforo, 0.35, aforo)
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

	var i := 0
	for e in EDIFICIOS:
		var niv := int(inst.get(e["k"], 0))
		var obra: bool = enObra.has(e["k"])
		if niv <= 0 and not obra:
			continue
		## Cuatro por fila y no cinco: con cinco la parrilla se salia de la valla por
		## el lado, y un complejo con edificios fuera del recinto no se lee como un
		## complejo, se lee como un error de colocacion.
		## Cuatro por fila como siempre, pero con el DOBLE de separación: los
		## edificios pasaron de 9-16 m a 19-34 m de fachada y con la parrilla
		## vieja (42 x 32 m) se solapaban unos con otros.
		var fila := i / 4
		var col := i % 4
		var x := -111.0 + col * 74.0
		var z := 118.0 + fila * 48.0
		_edificio(e, niv, obra, Vector3(x, 0, z))
		i += 1

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

	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(ancho, alto, fondo)
	cuerpo.mesh = bm
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
		mat = Texturas.hormigon(e["col"]).duplicate()
		mat.roughness = 0.62
		mat.metallic = 0.04
		mat.metallic_specular = 0.35
	cuerpo.material_override = mat
	cuerpo.position = pos + Vector3(0, alto * 0.5, 0)
	add_child(cuerpo)

	_ventanas(pos, ancho, fondo, plantas)

	## Franja del color del club en el tejado: ata los edificios al club y no a
	## un poligono industrial cualquiera.
	var techo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(ancho + 0.6, 0.5, fondo + 0.6)
	techo.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
	techo.material_override = tmat
	techo.position = pos + Vector3(0, alto + 0.25, 0)
	add_child(techo)

	_detalle_edificio(pos, ancho, fondo, alto, e)

	etiquetas.append({
		"pos": pos + Vector3(0, alto + 3.0, 0),
		"texto": str(e["n"]) + ("  (en obra)" if enObra else ""),
		"nivel": niv,
	})

## Lo que convierte una caja con ventanas en un EDIFICIO: la marquesina de la
## entrada con sus pilares, las máquinas de la cubierta y una banda de rótulo
## del color del club sobre la puerta. Son cuatro piezas y cambian la lectura
## por completo -sin ellas, a media distancia todas las instalaciones son la
## misma caja pintada de otro color.
func _detalle_edificio(pos: Vector3, ancho: float, fondo: float, alto: float, e: Dictionary) -> void:
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

func _aparcamiento() -> void:
	## Los coches salen del nivel de 'park': el jugador invierte en accesos y ve
	## el aparcamiento llenarse. Sin nivel, un par de coches del personal.
	##
	## AHORA CON VARIEDAD: a los dos FBX de siempre se suman los 7 GLB CC0 de
	## Kenney (`RUTAS_COCHES_KENNEY`). Cada fuente trae su propia escala -las
	## dos FBX ya estaban calibradas a 1.4-, y la de Kenney se ajustó aparte
	## con `captura_ciudad.gd` porque su pack no viene a la misma escala que
	## el resto de props de este proyecto.
	var pool: Array = []
	var c1 := load(RUTA_COCHE1)
	if c1 != null:
		pool.append({"esc": c1, "escala": 1.4})
	var c2 := load(RUTA_COCHE2)
	if c2 != null:
		pool.append({"esc": c2, "escala": 1.4})
	for ruta in RUTAS_COCHES_KENNEY:
		var kc: PackedScene = load(ruta)
		if kc != null:
			pool.append({"esc": kc, "escala": 1.65})
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
		var esc: PackedScene = par["esc"]
		var nodo: Node3D = esc.instantiate()
		## Al este del acceso, entre el estadio y los campos: es donde de verdad
		## aparca la gente un día de partido, junto a la puerta.
		var fila := i / 7
		var col := i % 7
		nodo.position = Vector3(97.0 + col * 5.5, 0, -62.0 + fila * 8.0)
		nodo.rotation.y = PI * 0.5
		nodo.scale = Vector3.ONE * float(par["escala"])
		add_child(nodo)

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
		var radio: float = rng.randf_range(560.0, 780.0)
		var pos := Vector3(sin(ang) * radio, 0, cos(ang) * radio)
		var esc: PackedScene = mallas[rng.randi() % mallas.size()]
		var nodo: Node3D = esc.instantiate()
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
]

## Naves para la zona industrial del terreno sur: los modelos "de poco
## detalle" del mismo kit, que son justo bloques simples -perfectos para una
## nave y baratos de dibujar-.
const RUTAS_NAVES := [
	"res://assets/ciudad/kenney_comercial/low-detail-building-wide-a.glb",
	"res://assets/ciudad/kenney_comercial/low-detail-building-wide-b.glb",
	"res://assets/ciudad/kenney_comercial/low-detail-building-a.glb",
	"res://assets/ciudad/kenney_comercial/low-detail-building-e.glb",
]

## Los toldos y parasoles del kit: el detalle de calle que separa "unos bloques
## puestos en fila" de "una calle comercial".
const RUTAS_MOBILIARIO := [
	"res://assets/ciudad/kenney_comercial/detail-awning.glb",
	"res://assets/ciudad/kenney_comercial/detail-awning-wide.glb",
	"res://assets/ciudad/kenney_comercial/detail-parasol-a.glb",
	"res://assets/ciudad/kenney_comercial/detail-parasol-b.glb",
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
	_via(Vector3(BARRIO_EN.x, 0, (RING_Z_SUR + BARRIO_EN.z) * 0.5),
		Vector2(ANCHO_CALLE, BARRIO_EN.z - RING_Z_SUR + ANCHO_CALLE), asfalto, linea, false)

	## EL EJE EXTERIOR (12-9-2026): "integrar... un eje vial mejor conectado
	## entre la zona industrial, el centro comercial y el estadio". Tenía
	## razón: con solo el anillo, para ir de la zona industrial (este) al
	## centro comercial (oeste) había que rodear el recinto del club por
	## dentro. Este segundo anillo pasa POR FUERA, rozando las cuatro parcelas,
	## y las conecta entre sí directamente. Es lo que en una ciudad de verdad
	## es la circunvalación, y de paso encierra el mapa como un conjunto.
	var ex_x := 392.0
	var ex_n := -282.0
	var ex_s := 262.0
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
		puestos.append({"p": Vector3(-RING_X - 13.0, 0, z), "a": -PI * 0.5})
		puestos.append({"p": Vector3(RING_X + 13.0, 0, z), "a": PI * 0.5})
		z += paso
	var x := -RING_X + paso * 0.5
	while x < RING_X:
		puestos.append({"p": Vector3(x, 0, RING_Z_NORTE - 13.0), "a": 0.0})
		puestos.append({"p": Vector3(x, 0, RING_Z_SUR + 13.0), "a": PI})
		x += paso
	for d in puestos:
		_una_farola(d["p"], float(d["a"]))

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

## Un tramo de calle con su línea discontinua en medio. `tam` es (ancho_x, largo_z)
## tal cual, y `horizontal` dice hacia dónde corren las marcas viales.
func _via(centro: Vector3, tam: Vector2, mat_asfalto: Material, mat_linea: Material, horizontal: bool) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tam.x, 0.12, tam.y)
	m.mesh = bm
	m.material_override = mat_asfalto
	m.position = centro + Vector3(0, 0.06, 0)
	add_child(m)
	## Las marcas: trazos de 6 m cada 14 m. Una calle sin marcas es una franja
	## gris; con marcas se lee como calzada desde cualquier altura de cámara.
	var largo: float = tam.x if horizontal else tam.y
	var n: int = int(largo / 14.0)
	for i in range(n):
		var d: float = -largo * 0.5 + 7.0 + i * 14.0
		var t := MeshInstance3D.new()
		var tbm := BoxMesh.new()
		tbm.size = Vector3(6.0, 0.04, 0.5) if horizontal else Vector3(0.5, 0.04, 6.0)
		t.mesh = tbm
		t.material_override = mat_linea
		t.position = centro + (Vector3(d, 0.14, 0) if horizontal else Vector3(0, 0.14, d))
		add_child(t)

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
const RIO_X := -400.0
const RUTA_VELERO := "res://assets/ciudad/vagabond.obj"

const RUTA_SHADER_AGUA := "res://visor/agua.gdshader"
var _agua_mat: ShaderMaterial

func _rio() -> void:
	var agua := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(80, 900)
	## SUBDIVIDIDO, o el oleaje no tiene dónde ocurrir: un `PlaneMesh` sin
	## subdividir tiene cuatro vértices, y un shader que mueve vértices sobre
	## cuatro puntos no produce olas, produce un plano inclinado que cabecea.
	pl.subdivide_width = 12
	pl.subdivide_depth = 140
	agua.mesh = pl
	var sh := load(RUTA_SHADER_AGUA)
	if sh != null:
		var sm := ShaderMaterial.new()
		sm.shader = sh
		sm.set_shader_parameter("color_hondo", Color(0.06, 0.16, 0.24))
		sm.set_shader_parameter("color_orilla", Color(0.18, 0.38, 0.44))
		agua.material_override = sm
		_agua_mat = sm
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.16, 0.29, 0.38)
		m.metallic = 0.55
		m.roughness = 0.12
		agua.material_override = m
	agua.position = Vector3(RIO_X, 0.1, -120)
	add_child(agua)
	## Las dos orillas: sin ellas el agua es un rectángulo azul pegado sobre el
	## césped, y desde la cámara alta se nota que no hay cauce.
	var tierra := StandardMaterial3D.new()
	tierra.albedo_color = Color(0.44, 0.40, 0.31)
	tierra.roughness = 0.95
	for lado in [-1.0, 1.0]:
		var orilla := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(9.0, 1.6, 900.0)
		orilla.mesh = bm
		orilla.material_override = tierra
		orilla.position = Vector3(RIO_X + lado * 44.0, 0.4, -120)
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

	## La flota: los coches normales pesan mucho más que los de servicio -uno de
	## cada cinco- porque si no el mapa parece una emergencia permanente.
	var coches: Array = []
	for ruta in RUTAS_COCHES_KENNEY:
		var esc: PackedScene = load(ruta)
		if esc != null:
			for _r in range(4):
				coches.append(esc)
	for ruta in RUTAS_SERVICIO:
		var esc2: PackedScene = load(ruta)
		if esc2 != null:
			coches.append(esc2)

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
			var nodo: Node3D = (coches[rng.randi() % coches.size()] as PackedScene).instantiate()
			nodo.scale = Vector3.ONE * 1.65
			## -90° y no +90°: ver la nota del signo en `TraficoCiudad._colocar()`.
			## Con +90° medimos alineación morro/marcha = -1,000 en los veinte
			## vehículos, o sea la flota entera circulando marcha atrás.
			t.agregar_vehiculo(nodo, id, rng.randf() * 1800.0,
				rng.randf_range(13.0, 22.0), 0.0, -PI * 0.5)

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
			var n_ex: Node3D = (coches[rng.randi() % coches.size()] as PackedScene).instantiate()
			n_ex.scale = Vector3.ONE * 1.65
			t.agregar_vehiculo(n_ex, id_ex, rng.randf() * 2200.0,
				rng.randf_range(15.0, 24.0), 0.0, -PI * 0.5)
		## Y dos autobuses por sentido, en la misma ruta -es el eje que pasa
		## junto a las cuatro paradas y la terminal-, más grandes y más lentos
		## que el tráfico normal.
		var bus_esc: PackedScene = load(RUTA_BUS)
		if bus_esc != null:
			for i in range(2):
				var bus: Node3D = bus_esc.instantiate()
				bus.scale = Vector3.ONE * 3.1
				t.agregar_vehiculo(bus, id_ex, rng.randf_range(200.0, 2000.0),
					9.0, 0.0, -PI * 0.5)

	## 2) LA AVENIDA DE ACCESO y 3) LA CALLE DEL BARRIO: circuitos estrechos
	## -se baja por un carril y se sube por el otro-, que es lo que hace que un
	## tramo sin salida tenga tráfico sin necesidad de dar media vuelta a lo
	## bruto delante de la cámara.
	for tramo in [
			{"x": 0.0, "z0": -85.0, "z1": RING_Z_SUR - 10.0, "n": 3},
			{"x": BARRIO_EN.x, "z0": RING_Z_SUR + 10.0, "z1": BARRIO_EN.z - 30.0, "n": 2},
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
			var nodo2: Node3D = (coches[rng.randi() % coches.size()] as PackedScene).instantiate()
			nodo2.scale = Vector3.ONE * 1.65
			t.agregar_vehiculo(nodo2, id2, rng.randf() * 600.0,
				rng.randf_range(9.0, 15.0), 0.0, -PI * 0.5)

	## 4) EL VELERO. Mismo circuito estrecho, pero en el agua y muy lento: un
	## velero a 22 m/s sería una lancha motora.
	var barco := _hacer_velero()
	if barco != null:
		var cauce := PackedVector3Array([
			Vector3(RIO_X - 14.0, 0.0, -520.0), Vector3(RIO_X - 14.0, 0.0, 230.0),
			Vector3(RIO_X + 14.0, 0.0, 230.0), Vector3(RIO_X + 14.0, 0.0, -520.0),
		])
		var id3 := t.agregar_ruta(_redondear(cauce, 13.0))
		t.agregar_vehiculo(barco, id3, 120.0, 3.4, 0.7, -PI * 0.5)

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
	for i in range(naves.size()):
		var nave: Node3D = (naves[i] as PackedScene).instantiate()
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

func _barrio_residencial() -> void:
	var esc := load(RUTA_COMPLEJO_EXTRA)
	if esc == null or not (esc is PackedScene):
		return
	var n: Node3D = (esc as PackedScene).instantiate()
	var raiz := Node3D.new()
	add_child(raiz)
	raiz.add_child(n)
	## Medido, no a ojo: el origen del modelo no está en su base, así que sin
	## corregir la `y` quedaría medio enterrado.
	var caja := _caja_de(n)
	var alto: float = caja.size.y
	var escala := (40.0 / alto) if alto > 0.001 else 1.0
	raiz.scale = Vector3.ONE * escala
	raiz.position = BARRIO_EN + Vector3(0, -caja.position.y * escala, 0)
	raiz.rotation.y = PI
	_cartel(BARRIO_EN + Vector3(0, 0, -62.0), "Barrio residencial", false)

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
			casa.scale = Vector3(e3 * rng3.randf_range(0.85, 1.2),
				e3 * rng3.randf_range(0.75, 1.45), e3 * rng3.randf_range(0.85, 1.2))
			casa.position = BARRIO_EN + Vector3(
				lado * rng3.randf_range(42.0, 52.0), 0, -60.0 + i * 30.0 + rng3.randf_range(-4.0, 4.0))
			casa.rotation.y = ((PI * 0.5) if lado < 0.0 else (-PI * 0.5)) + rng3.randf_range(-0.12, 0.12)
			add_child(casa)
			k += 1
	_parque_barrio()

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
	var zFondo: float = 118.0 + (filas - 1) * 48.0 + 34.0
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
