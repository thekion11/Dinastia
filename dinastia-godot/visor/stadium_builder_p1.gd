extends RefCounted
## [Capa 1/12 de `stadium_builder.gd`] _c, marcar_techo, ocultar_techo_ante, _box, _rect_outline, _verdes_reales … (+3)

## Construye el estadio en 3D a partir del perfil que exporta el HTML
## (perfilEstadio() en dinastia-futbol-manager base.html). Para el club del
## usuario ese perfil ES su estadio guardado en la pestaña Estadio (G.est);
## para un rival se deriva del hash de su id con los mismos catalogos, asi que
## cada club tiene un recinto propio y estable. Nada aqui se inventa al azar.

const PITCH_LEN := 105.0
const PITCH_WID := 68.0

## EL TECHO NO TAPA LA CÁMARA (MEGAPLAN fase 2): con techo de anillo la
## cámara de TV quedaba detrás de la losa cercana y medio campo se veía marrón.
## Cada losa sabe hacia dónde da afuera; la que queda entre la cámara y el
## campo pasa a una capa que las cámaras no dibujan, pero el sol sí: su sombra
## sobre la grada se mantiene (como en las retransmisiones de FC).
const CAPA_TECHO_OCULTO := 1 << 10

## El material de los paños que se ondulan (`red_arco.gdshader`).
static var _shader_red: Shader = null

## EL TÚNEL DE VERDAD (7-10-2026): medio ancho del hueco que abre en la
## tribuna del fondo +Z, y su eje X (el tipo «esquina» va hacia el córner).
const TUNEL_HUECO := 3.2

## Altura total del graderio, para que las camaras se coloquen contra el estadio
## real y no contra numeros fijos (un recinto de 8.000 y uno de 90.000 no admiten
## el mismo encuadre — es la misma idea que ya documenta EST_CAMS en el juego).
## ============================================================================
## EL GRADERIO POR BANDEJAS DE VERDAD (23-9-2026)
## ============================================================================
## Pedido del usuario: *"el estadio debe ser modular para lo de reformar el
## estadio y habrá que hacerle más bandejas y variantes para cuando uno agrande
## el estadio (máximo 150.000)"*.
##
## Hasta hoy una tribuna era UNA rampa continua de 11 m de fondo, y su altura
## salia de multiplicar 6,5 m por el numero de bandejas. Eso tenia un problema
## de raiz que la auditoria de esta misma sesion dejo anotado: con 3 bandejas la
## rampa sube 18 m en 11 m de fondo, o sea **58,6 grados**. Ninguna grada real
## pasa de ~35, y a 5 bandejas habria sido un acantilado de 70 grados.
##
## Ahora cada bandeja es su propia rampa, con su propio fondo, su pendiente
## acotada y un FRENTE vertical entre una y la siguiente -que es exactamente el
## perfil de un estadio de varias bandejas, y de paso es donde cuelgan los
## telones-. La tribuna crece hacia AFUERA al sumar bandejas, no solo hacia
## arriba, que es lo que hace que 5 bandejas sigan pareciendo un estadio.
##
## La cara interior (la que da al cesped) NO se mueve: sigue a `FRENTE_TRIBUNA`
## del eje nominal `dx`/`dz`. Asi la relacion con la cancha, las camaras, las
## vallas y el tunel es la misma con 1 bandeja que con 5.

## Lo que sube una grada de verdad. 33 grados es el limite de lo comodo; por
## encima, una tribuna se lee como una pared.
const RAKE_GRADOS := 33.0
## Fondo en planta de UNA bandeja.
const FONDO_BANDEJA := 10.0
## Lo que se echa atras cada bandeja respecto de la de abajo.
const RETRANQUEO_BANDEJA := 3.5
## El frente vertical entre una bandeja y la siguiente: palcos, pasillo y la
## reja donde se cuelgan los trapos.
const FRENTE_BANDEJA := 3.0
## Distancia del eje nominal de la tribuna (dx/dz) a su cara interior.
const FRENTE_TRIBUNA := 5.5
## Altura del borde de la primera bandeja sobre el cesped.
const ALTURA_PIE := 1.5
const NIVELES_MAX := 5

## 0=sur 1=norte 2=este 3=oeste, mismo orden que el comentario de `stands` más
## abajo. `perfil()` (`nucleo/estadio_propio.gd`) usa estos mismos nombres para
## las claves de `est["bandejas"]`, así que este índice y ese diccionario
## siempre hablan el mismo idioma sin traducir nada en el medio.
const NOMBRE_BANDEJA := {0: "sur", 1: "norte", 2: "este", 3: "oeste"}

## `mi` (16-9-2026, Fase 2 "Componentes"): igual que en `build_pitch()`,
## opcional y solo para el escudo en grada/fachada/techo -`null` no cambia
## nada respecto a antes de esta fase.
## Cronómetro de la construcción (etapa 3): con TIEMPOS=1 imprime cada parte.
static var _t_tm := 0

const SHADER_BANDERA := preload("res://visor/bandera.gdshader")

## LA PANTALLA, CON CONTENIDO DE VERDAD (22-9-2026): "esa pantalla azul puede
## mejorarse", con razón -era un rectángulo de UN SOLO COLOR LISO, sin nada
## encima, ni marcador ni escudo ni nada que sugiera una transmisión real. El
## motivo original de dejarla lisa -"una jumbotron encendida se ve uniforme,
## textura ahí se leería como un panel roto"- seguía siendo válido para la
## GRADA (ruido de alta frecuencia = estática de TV, ver el bug del 21-9),
## pero no aplicaba aquí: un gráfico de bienvenida (degradado + escudo del
## club, la imagen que cualquier jumbotron real muestra antes/entre jugadas)
## es contenido de baja frecuencia, sin el problema que motivó dejarla lisa.
## Reutiliza `Escudo.textura()` -ya usado para el círculo central y la
## fachada, cero arte nuevo- en vez de inventar un logo aparte.
## HACES DE LUZ DE LOS FOCOS (informe de diseño, 13-10-2026: «los focos deben
## proyectar conos translúcidos sobre el césped»). Un cono aditivo del foco al
## campo, invisible de día y cada vez más visible cuanto más oscuro es el
## ambiente (`encender_conos`). Comparten un material.
static var _mat_cono: StandardMaterial3D = null

## BORRADO EL 23-9-2026: HABIA DOS BANQUILLOS, UNO ENCIMA DEL OTRO.
##
## Aqui vivia un `_banquillos(root, dx)` que pintaba una caja fija en
## x∈[35.2, 37.4], z∈[4.5, 13.5]. `_banquillos_detalle()` -el del catalogo, el
## que de verdad responde a lo que el usuario elige en Club -> Estadio- quedo
## en x∈[35.7, 38.7], z∈[10, 18] despues de que se corrigiera el cambio de ejes
## X/Z del 13-9. **Desde ese arreglo los dos se cruzaban** en x∈[35.7, 37.4] ×
## z∈[10, 13.5]: el cristal lateral del dugout atravesaba la caja vieja. La
## nota de `LEEME.md` que decia que estaban lejos quedo obsoleta ese mismo dia
## y nadie lo noto, porque desde la camara de TV una caja dentro de otra caja
## del mismo color no se distingue.
##
## Sintoma delator, ademas: recibia `dx` y NO LO USABA -todas sus medidas eran
## constantes-. Es exactamente el patron que la auditoria del 23-9 buscaba.
##
## No se reemplaza por nada: `_banquillos_detalle()` ya se llama SIEMPRE desde
## `build_pitch()` y cubre los seis tipos del catalogo.

## Butacas de verdad en las primeras filas de cada tribuna.
##
## POR QUE SOLO EN LAS PRIMERAS FILAS
## El modelo de fila de tres butacas que trajo el usuario tiene 38.916 vertices;
## simplificado al 2,5% con Blender baja a 988 (assets/ciudad/asientos_lod.glb).
## Aun asi, llenar las cuatro tribunas enteras serian ~10.000 filas = 10 millones
## de vertices, que una Intel UHD no mueve. Puestas en las CINCO PRIMERAS filas
## salen unas 1.100 y se ven exactamente donde importa: al borde del cesped, que
## es donde la camara de TV pasa cerca.
##
## "DE LA SEXTA FILA HACIA ARRIBA... A ESA DISTANCIA NO SE DISTINGUE" -CIERTO
## SOLO EN UN GRADERIO DE 1 NIVEL, FALSO EN UNO DE 2-3 (22-9-2026). El usuario
## lo vio de inmediato comparando sus propias capturas: en un "Cuenco de 3
## niveles" (alto=19.5, `largo_rake`~21m) las 5 filas reales cubren solo 4.4m,
## ~21% de la rampa -el 79% restante es la textura de `_make_stand_texture()`
## SOLA, estirada sobre una pendiente larga y vista casi de canto desde una
## camara de estadio, que es justo la combinacion que hace aliasing severo
## (mismo fenomeno que la "estatica de TV" ya documentada, no una textura
## rota nueva). "De abajo se ve bien" (las 5 filas reales) vs. "de arriba" (la
## textura sola) no es una ilusion, es una cobertura real desigual que el
## supuesto original -pensado con un graderio de 1 nivel en mente- no preveia.
## Arreglo: escalar las filas reales CON el numero de niveles, no un numero
## fijo -un estadio de 1 nivel sigue costando exactamente lo mismo que
## siempre (el caso que ya se veia bien y no habia que tocar), uno de 3
## niveles cubre 3x mas alto sin disparar el costo a las ~10.000 filas que sí
## preocupaban al comentario original.
const RUTA_BUTACAS := "res://assets/ciudad/asientos_lod.glb"
const FILAS_REALES := 5
const PASO_FILA := 0.88          ## fondo de cada fila, en metros
const PASO_BUTACA := 1.52        ## ancho de una fila de tres butacas

## Hincha de mentira para las filas reales, deliberadamente low-poly -a
## diferencia de la butaca real (988 vertices, ver mas arriba), esto se repite
## por cada asiento OCUPADO de las 5 filas reales de las 4 tribunas, asi que el
## presupuesto por instancia tiene que ser minimo: un torso (capsula) y una
## cabeza (esfera), un puñado de segmentos cada una -a la distancia de camara
## donde esto se ve (borde del cesped, nunca un primer plano de cara), no hace
## falta mas- unidas en una sola malla para que un unico MultiMesh alcance.
static var _malla_hincha: Mesh

## EL HINCHA MÍNIMO (etapa 3, 8-10-2026). En calidad MEDIO la hinchada lejana
## era 1,7 M de los 3,1 M de triángulos del partido (decenas de miles de
## hinchas de 60). Este tiene la MISMA silueta y alturas -el shader de la
## hinchada pinta cuello, cabeza y pelo por altura- con un torso de 5 lados
## sin tapa de abajo (la tapa la sientan las butacas) y una cabeza de 5x2:
## 26 triángulos. A más de 30 m, que es donde está, no se distingue.
static var _malla_hincha_min: Mesh

## PERSONAS REALES EN LA GRADA (14-10-2026). Las mallas de `assets/ciudad/publico/`
## son el MISMO modelo humano que juega, horneado en 6 poses (quieto, aplaude,
## celebra, puño, señala, saluda) y cortado en la cadera, a dos niveles de detalle
## (`herramientas/hornear_publico.gd`). Devuelve las 6 mallas del nivel o [] si
## faltan (entonces se usa el maniquí de siempre).
static var _hornead := {}
const POSES_PUBLICO := ["quieto", "charla", "aplaude", "aplaude_arriba", "puno", "pulgar", "cruzados", "cabeza"]

## DETALLE SEGÚN LA DISTANCIA (16-10-2026, `pruebas/medir_partido` con ARBOL=1:
## el público de la bandeja baja de la tribuna de enfrente eran 808.000 de los
## 1,16 M de triángulos del plano de TV, con mallas «cerca» de ~620 triángulos
## vistas a 80-100 m). La bandeja se parte en 3 tramos a lo largo; cada tramo
## lleva su versión de detalle (visible a menos de `LOD_PUBLICO` m del centro
## del tramo: primeros planos, celebraciones, Carrera de Jugador) y una
## suplente con la malla «lejos» en 2 poses (más allá). Godot mide la distancia
## al centro de cada MultiMesh, por eso los tramos.
const LOD_PUBLICO := 55.0
const TRAMOS_PUBLICO := 3

## EL HINCHA DE LAS PRIMERAS FILAS (29-9-2026). Pedido del usuario al ver el
## partido jugable de la Carrera de Jugador ("ese público se ve horrible"):
## ahí la cámara va a ras de césped y las primeras filas quedan a pocos metros.
## La cápsula+esfera de arriba, de cerca, es una pastilla con una bola. Esta
## lleva hombros, brazos, cuello y cabeza -el pelo lo pinta el shader por
## altura-, ~150 vértices, y SOLO se usa en las filas bajas de la bandeja de
## abajo: las de arriba siguen con la barata, que a 30 m no se distingue.
static var _malla_hincha_det: Mesh

## `rake` (23-9-2026): la inclinacion REAL de esta rampa, en radianes. Las
## butacas y los hinchas son hijos del `deck` YA INCLINADO, asi que heredaban
## la pendiente entera: con 3 niveles el graderio va a `atan2(18, 11)` = **58,6
## grados**, o sea que el publico estaba tumbado hacia atras casi 60 grados,
## como en un despegue. Ninguna grada real pasa de ~35, y en las de verdad las
## butacas van sobre ESCALONES horizontales, no sobre el plano inclinado.
## Contrarrotando cada instancia por -rake alrededor del eje que inclino el
## deck, la butaca y el hincha quedan de pie y en su sitio de la pendiente,
## que es exactamente lo que pasa en un estadio.
## `bandeja` (23-9-2026): qué piso del graderío es este, contando desde el
## césped. Decide cuántas filas de butacas 3D se pueden permitir -ver la nota
## del presupuesto, más abajo-.
## Una cinta LED de 1,2 m de alto y `largo` m, en `pos`, de cara a `cara`.
static var _shader_cinta: Shader

## LA ESCALERA DE ACCESO (21-10-2026): entre el pasillo a ras de césped y la
## primera fila de la bandeja baja hay un muro de ~2 m. Delante de cada pasillo,
## unos peldaños de hormigón que bajan hasta el suelo, hacia el campo. Así se
## sube a la grada caminando (`RecorridoClub.camino_a_butaca`).
const PELDANO_ALTO := 0.18
const PELDANO_FONDO := 0.3

static var _mat_peldano: StandardMaterial3D
static var _mat_baranda: StandardMaterial3D

## LA BUTACA DE LEJOS (29-9-2026): las medidas del modelo real
## (`asientos_lod.glb`: 1,50 × 0,74 × 0,59 m, tres asientos, respaldo en -Z)
## hechas con cinco cajas -asiento corrido, tres respaldos con su hueco y la
## viga-: ~120 vértices contra 994. Se usa en las filas altas, donde la
## cámara nunca llega a distinguirlas.
static var _butaca_lejos: Mesh

## El piso de la grada bajo las butacas: hormigón gris, compartido.
static var _escalones: StandardMaterial3D

## PALETA DE LAS VALLAS (MEGAPLAN B6): los mismos textos, otra estética. La
## de fábrica ("marcas") deja cada anuncio con el color de su marca.
const NEON := [Color(0.25, 0.95, 1.0), Color(1.0, 0.3, 0.85), Color(0.6, 1.0, 0.25),
	Color(1.0, 0.72, 0.2)]

## EL EXTERIOR DEL ESTADIO (25-9-2026, plan maestro B6.2). Hasta hoy el recinto
## terminaba en su muro y detrás había una explanada gris vacía. Ahora, como en
## cualquier estadio de verdad: una fila de taquillas frente a la tribuna sur,
## la tienda oficial en la esquina y un estacionamiento con coches detrás de la
## tribuna norte. Todo sale de una semilla local (no de `Azar`): el mismo
## estadio siempre tiene los coches en el mismo sitio.
const RUTAS_COCHES := [
	"res://assets/ciudad/kenney_cars/sedan.glb",
	"res://assets/ciudad/kenney_cars/sedan-sports.glb",
	"res://assets/ciudad/kenney_cars/suv.glb",
	"res://assets/ciudad/kenney_cars/hatchback-sports.glb",
	"res://assets/ciudad/kenney_cars/taxi.glb",
	"res://assets/ciudad/kenney_cars/van.glb",
]

# ---------------------------------------------------------------- utilidades

static func _c(hex, fallback := "#ffffff") -> Color:
	if typeof(hex) == TYPE_STRING and hex != "":
		return Color(hex)
	return Color(fallback)

static func marcar_techo(mi: MeshInstance3D, fuera: Vector3) -> void:
	if mi == null:
		return
	mi.add_to_group("techo_estadio")
	mi.set_meta("fuera", Vector3(fuera.x, 0.0, fuera.z).normalized())

## Llamar cada fotograma con la cámara activa.
static func ocultar_techo_ante(cam: Camera3D) -> void:
	if cam == null or not cam.is_inside_tree():
		return
	cam.cull_mask &= ~CAPA_TECHO_OCULTO
	for n in cam.get_tree().get_nodes_in_group("techo_estadio"):
		var mi := n as MeshInstance3D
		if mi == null:
			continue
		var fuera: Vector3 = mi.get_meta("fuera", Vector3.ZERO)
		var d := (cam.global_position - mi.global_position)
		var detras := Vector3(d.x, 0.0, d.z).dot(fuera) > -3.0
		mi.layers = CAPA_TECHO_OCULTO if detras else 1

static func _box(root: Node3D, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = center
	mi.material_override = mat
	root.add_child(mi)
	return mi

static func _rect_outline(root: Node3D, center: Vector3, w: float, d: float, line_w: float, y: float, mat: Material) -> void:
	_box(root, center + Vector3(0, y, d / 2.0), Vector3(w, 0.03, line_w), mat)
	_box(root, center + Vector3(0, y, -d / 2.0), Vector3(w, 0.03, line_w), mat)
	_box(root, center + Vector3(w / 2.0, y, 0), Vector3(line_w, 0.03, d), mat)
	_box(root, center + Vector3(-w / 2.0, y, 0), Vector3(line_w, 0.03, d), mat)

# ------------------------------------------------------------------- cancha

## Dibuja el corte del cesped como textura procedural. El patron y los dos tonos
## de verde salen del disenador de estadio del juego (EST_CESPED / EST_TONOS).
## CÉSPED DE VERDAD (MEGAPLAN fase 2): los verdes del diseñador salían
## fluorescentes y las dos franjas casi iguales (frente a EA FC: verde apagado y
## corte muy marcado). Se respeta el tono elegido pero con la saturación y la
## claridad de un césped real, y las franjas se separan al menos un 22 % (lo
## que da el corte en dos sentidos de la cortadora).
static func _verdes_reales(a: Color, b: Color) -> Array:
	var salida: Array = []
	for c: Color in [a, b]:
		salida.append(Color.from_hsv(c.h, minf(c.s, 0.5) * 0.9, clampf(c.v, 0.32, 0.5)))
	var ca: Color = salida[0]
	var cb: Color = salida[1]
	var claro := ca if ca.v >= cb.v else cb
	var oscuro := cb if ca.v >= cb.v else ca
	if claro.v < oscuro.v * 1.22:
		claro = Color.from_hsv(claro.h, claro.s * 0.94, minf(oscuro.v * 1.22, 0.62))
	## (El orden de vuelta respeta cuál era el "claro" del diseñador.)
	return [claro, oscuro] if ca.v >= cb.v else [oscuro, claro]

static func _make_grass_texture(patron: String, claro: Color, oscuro: Color) -> ImageTexture:
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in range(n):
		for x in range(n):
			var u := float(x) / n
			var v := float(y) / n
			var band := 0
			match patron:
				## ~6 m por franja (20 a lo largo), como el corte real.
				"rayas":
					band = int(v * 20.0)
				"rayasH":
					band = int(u * 20.0)
				"damero":
					band = int(u * 10.0) + int(v * 10.0)
				"damGrande":
					band = int(u * 5.0) + int(v * 5.0)
				## (`Club` sortea "circulos": antes no casaba y salía liso.)
				"circular", "circulos":
					band = int(Vector2(u - 0.5, v - 0.5).length() * 16.0)
				"diagonal":
					band = int((u + v) * 10.0)
				"espiga":
					band = int((u + fmod(v * 6.0, 1.0)) * 8.0)
				"cruz":
					band = 1 if (absf(u - 0.5) < 0.12 or absf(v - 0.5) < 0.12) else 0
				"abanico":
					band = int(atan2(v - 0.5, u - 0.5) * 6.0)
				"rombos":
					band = int((absf(u - 0.5) + absf(v - 0.5)) * 14.0)
				"mitades":
					band = 0 if v < 0.5 else 1
				## "liso" (y lo desconocido): en un campo de verdad el corte
				## siempre se nota un poco -franjas muy suaves, un tercio-.
				_:
					band = int(v * 20.0)
					img.set_pixel(x, y, claro.lerp(oscuro, 0.33) if band % 2 == 0 else oscuro)
					continue
			img.set_pixel(x, y, claro if band % 2 == 0 else oscuro)
	var tex := ImageTexture.create_from_image(img)
	return tex

## `tipo` (16-9-2026, "el estadio por MODULOS", Fase 2 "Componentes"): el
## patron del tejido, catalogo `EST_REDTIPO`. El default ("cuadrada") es
## EXACTAMENTE el dibujo que ya existia antes de esta fase -un marco de 2 px
## repetido por el `uv1_scale` grande que ya le pone `_add_goal`-, asi que
## cualquier arco que no pida un tipo (todos los rivales, que no traen esta
## clave) sale identico a como salia siempre.
static func _make_net_texture(color: Color, tipo: String = "cuadrada") -> ImageTexture:
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var col_cordel := Color(color.r, color.g, color.b, 0.92)
	var col_hueco := Color(0, 0, 0, 0.0)
	## Grano en el cordel (16-9-2026), mismo truco que ya usa el grano de la
	## grada: sin variar ni el color ni el alfa pixel a pixel, el cordel sale
	## de un blanco perfectamente uniforme -una linea calculada, no una cuerda
	## real-, y con el `uv1_scale` grande de `_add_goal` esa uniformidad se
	## repite cientos de veces y se nota mucho mas que en una textura chica.
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for y in range(n):
		for x in range(n):
			var en_cordel: bool
			match tipo:
				"fina":
					en_cordel = x < 1 or x >= n - 1 or y < 1 or y >= n - 1
				"gruesa":
					en_cordel = x < 4 or x >= n - 4 or y < 4 or y >= n - 4
				"rombo":
					## Cordel diagonal en vez de un marco recto: dos diagonales
					## cruzadas por celda, que a esta resolucion se lee como
					## una malla de rombos en vez de cuadrados.
					en_cordel = absf((x - y) % 16 - 8) < 2 or absf((x + y) % 16 - 8) < 2
				"hexagonal":
					## Aproximacion barata de un panal: filas de diagonales que
					## alternan de sentido cada 8 px, como el ladrillo hexagonal
					## visto de lejos -no hace falta la geometria real, a la
					## distancia de camara de este juego no se distingue-.
					var fila := int(y / 8.0)
					var desfase := 4 if fila % 2 == 0 else 0
					en_cordel = (x + desfase) % 8 < 2 or y % 8 < 2
				_:  # "cuadrada", el dibujo de siempre
					en_cordel = x < 2 or x >= n - 2 or y < 2 or y >= n - 2
			if en_cordel:
				var luz := 1.0 + (rng.randf() - 0.5) * 0.35
				var alfa := clampf(col_cordel.a + (rng.randf() - 0.5) * 0.12, 0.55, 1.0)
				img.set_pixel(x, y, Color(
					clampf(col_cordel.r * luz, 0.0, 1.0), clampf(col_cordel.g * luz, 0.0, 1.0),
					clampf(col_cordel.b * luz, 0.0, 1.0), alfa))
			else:
				img.set_pixel(x, y, col_hueco)
	return ImageTexture.create_from_image(img)
static func _mat_red_onda(tex: Texture2D, escala: Vector2, medio: Vector2) -> ShaderMaterial:
	if _shader_red == null:
		_shader_red = load("res://visor/red_arco.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _shader_red
	m.set_shader_parameter("textura", tex)
	m.set_shader_parameter("escala_uv", escala)
	m.set_shader_parameter("medio_tam", medio)
	return m
