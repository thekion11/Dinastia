extends "res://visor/city_builder_p1.gd"
## [Capa 2/12 de `city_builder.gd`] _marca, _color_luces, _altura_terreno, _textura_cesped, _normal_rejilla, _terreno … (+6)

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

## Las calles del núcleo como rectángulos (centro xz, tamaño): las lee el GPS
## (`MinimapaCiudad`), que antes solo dibujaba la red de fuera.
static var vias_mapa: Array[Rect2] = []

## La ribera lleva río: es lo que hace que ese terreno se entienda sin leer su
## descripción, y de paso rompe la explanada verde por el oeste. Con su velero,
## que es lo que `vagabond.obj` resultó ser de verdad -no una persona, pese al
## nombre; ver `dinastia-calidad-grafica.md`- y llevaba dos semanas sin usarse.
const RIO_X := -470.0  ## 7-10-2026: entre el anillo exterior (-392) y el bulevar (-550)
const RUTA_VELERO := "res://assets/ciudad/vagabond.obj"

const RUTA_SHADER_AGUA := "res://visor/agua.gdshader"
var _agua_mat: ShaderMaterial

# ---------------------------------------------------------------- trafico

## Lo que hace que el mapa esté VIVO: coches dando vueltas por el anillo, por
## la avenida de acceso y por la calle del barrio, y el velero navegando el
## río. Todo lo mueve `TraficoCiudad` sobre recorridos cerrados -ver ahí el
## por qué de cada decisión-; aquí solo se dibujan los recorridos y se decide
## cuántos vehículos van en cada uno.
const CARRIL := 4.0     ## separación del eje de la calle a cada carril

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

var manzanas_distrito := 0


const RUTA_CASA_GIGANTE := "res://assets/ciudad/complejo_residencial.glb"
var casa_gigante: Node3D = null


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

var _karts_pendientes: Dictionary = {}

## LA CIUDAD RESPONDE AL CLUB (fase 5): pancartas en la euforia, persianas y
## grafitis en la crisis. Ver `CiudadAnimo`.
var animo_montado: Dictionary = {}

## Banderas del club en las farolas del anillo (día de partido y euforia).
var _anillo_con_banderas := false

## ESTADIO 2.0: el vestuario está detrás de la tribuna, donde muere la avenida
## del estadio. Las marcas viales y piezas planas de la calle que caen dentro
## asomarían por su suelo: se quitan.
var _rect_vestuario := Rect2()
var _rect_entrada := Rect2()

## Un hincha de pie en tres piezas (pantalón, camiseta, piel), cada una con su
## color por instancia. Low-poly: se ven de lejos y son cientos.
static var _piezas_hincha: Array = []
func _marca(que: String) -> void:
	if _medir_tiempos:
		var ahora := Time.get_ticks_usec()
		print("TIEMPO %-24s %6.0f ms" % [que, (ahora - _t_marca) / 1000.0])
		_t_marca = ahora

func _color_luces() -> Color:
	var s := str(datos.get("luces", ""))
	if s.begins_with("#") and s.length() >= 7:
		return Color(s)
	return LUZ_POR_DEFECTO

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

## Normal de la rejilla de alturas en el vértice (i, j), siempre hacia arriba.
func _normal_rejilla(alturas: Array, i: int, j: int, paso: float) -> Vector3:
	var n := TERRENO_CELDAS
	var h := func(ii: int, jj: int) -> float: return float(alturas[clampi(jj, 0, n) * (n + 1) + clampi(ii, 0, n)])
	var dx: float = (h.call(i + 1, j) - h.call(i - 1, j)) / (2.0 * paso)
	var dz: float = (h.call(i, j + 1) - h.call(i, j - 1)) / (2.0 * paso)
	return Vector3(-dx, 1.0, -dz).normalized()

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

func _via(centro: Vector3, tam: Vector2, mat_asfalto: Material, _mat_linea: Material, horizontal: bool) -> void:
	vias_mapa.append(Rect2(Vector2(centro.x, centro.z) - tam * 0.5, tam))
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
	var ma: StandardMaterial3D = Texturas.asfalto(Color(0.42, 0.425, 0.435)).duplicate()
	## Asfalto algo pulido: con rugosidad 0.95 no reflejaba nada y se leia como
	## fieltro gris. A 0.55 recoge el cielo del atardecer y parece firme mojado.
	ma.roughness = 0.55
	## (25-10-2026) sin metálico y tinte más claro: ver la nota de `_calles`.
	ma.metallic = 0.0
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
	_via(Vector3(0, 0, (-90.0 + RING_Z_SUR) * 0.5), Vector2(14, RING_Z_SUR + 90.0), Texturas.asfalto(Color(0.40, 0.405, 0.415)), null, false)

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

static func _solapa(a0: float, a1: float, b0: float, b1: float) -> bool:
	return minf(a1, b1) - maxf(a0, b0) > 0.01

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
