extends "res://visor/stadium_builder_p6.gd"
## (Parte 7 de 11 de `stadium_builder.gd`.)

## `ocupacion` (22-9-2026): antes estas 5 filas reales -las que la camara de TV
## ve de cerca, ver el comentario de mas arriba- se quedaban con la butaca
## vacia aunque `_make_stand_texture()` ya pinte gente de verdad desde la fila
## 6 para arriba. Exactamente al reves de lo que importa: la grada se veia mas
## llena lejos que cerca. Aqui se decide, asiento por asiento y con el mismo
## `rng` -asi el patron sale estable entre recargas del mismo estadio, no
## parpadea de una partida a otra-, si va ocupado, respetando la MISMA
## `ocupacion` real (asistencia del partido) que ya gobierna la textura: un
## estadio semivacio en la simulacion economica se ve semivacio tambien aqui,
## esto no es decoracion aparte con su propio numero inventado.
## LOS TRAPOS DE LA HINCHADA (23-9-2026).
##
## En `ea_fc25_referencia.mp4` los telones colgados sobre las primeras filas
## son LO QUE MAS ROMPE la uniformidad de la grada: sin ellos el graderio se
## lee como una alfombra de puntos por muy bien que este el publico. Y en una
## cancha chilena son media identidad del estadio.
##
## SE MONTAN COMO HIJOS DEL `deck`, EN COORDENADAS LOCALES, a proposito: el
## deck ya viene inclinado, asi que la pendiente, la orientacion y la posicion
## sobre la rampa salen gratis del propio nodo. Calcularlas en coordenadas de
## mundo habria significado deshacer a mano la rotacion de cada una de las 4
## tribunas -justo el tipo de cuenta que produjo la mitad de los bugs que se
## arreglaron hoy-.
##
## Un `PlaneMesh` mira hacia +Y (esta tumbado), que es exactamente como queda
## un trapo extendido sobre las butacas. `size` es (x, z) en local.
static func _telones(deck: MeshInstance3D, tam: Vector3, lateral: bool,
		est: Dictionary, seed_val: int) -> void:
	var largo: float = tam.z if lateral else tam.x
	var fondo: float = tam.x if lateral else tam.z
	if largo < 12.0 or fondo < 4.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var c1 := _c(est.get("asiento1"), "#1f5f3d")
	var c2 := _c(est.get("asiento2"), "#e8e8e8")
	## Tela de verdad, no color plano: un trapo pintado se lee como cartulina.
	## Sin brillo -es una sabana vieja atada a la reja, no un pendon nuevo.
	## Uno claro SIEMPRE entre los tres: los trapos de una hinchada son en su
	## mayoria sabanas blancas pintadas, y contra una grada del color del club
	## es lo unico que destaca de verdad. Si el segundo color del club ya es
	## claro, se usa ese; si no, se aclara el primero.
	var claro: Color = c2 if c2.get_luminance() > 0.55 else c1.lightened(0.7)
	var telas: Array[StandardMaterial3D] = [
		Texturas.tela(claro), Texturas.tela(c1), Texturas.tela(claro.darkened(0.12)),
	]
	## EL BORDE OSCURO NO ES DECORACION (23-9-2026). Los colores del trapo son
	## los MISMOS que los de las butacas -es la hinchada de ese club-, asi que
	## un panel liso de ese color sobre esa grada es invisible: se funde con el
	## fondo. El reborde negro le da silueta contra cualquier patron, que es
	## exactamente lo que hace que se lean en el video de referencia.
	var borde := Texturas.tela(Color(0.06, 0.07, 0.08))
	var cuantos := 3
	for k in cuantos:
		## Mas hondos de lo que parece necesario (23-9-2026, corregido mirando
		## la captura): un trapo tumbado sobre una rampa de casi 60 grados se
		## ve MUY escorzado desde la cancha, asi que 1,6 m de fondo daban una
		## rayita. 2,8-4,2 m se leen como un telon.
		var ancho: float = rng.randf_range(8.0, 15.0)
		var hondo: float = rng.randf_range(2.8, 4.2)
		## Reparto a lo largo, con holgura, para que no se amontonen ni se
		## salgan por las puntas de la tribuna.
		var centro: float = -largo * 0.5 + largo * (float(k) + 0.5) / float(cuantos) \
			+ rng.randf_range(-largo * 0.08, largo * 0.08)
		## POR ENCIMA DE LA ZONA DE BUTACAS REALES (corregido con una captura,
		## 23-9-2026). El primer intento los puso en el tercio bajo de la rampa
		## y NO SE VEIA NINGUNO: ahi es justo donde `_butacas()` pone las filas
		## de butacas 3D, que miden ~0,8 m, asi que un trapo tumbado a 0,34 m
		## quedaba enterrado entre ellas. De la mitad de la rampa hacia arriba
		## solo hay textura, asi que el telon se ve entero -y ademas es donde
		## cuelgan en `ea_fc25_referencia.mp4`, arriba, no al borde del cesped.
		## SIN PISAR LOS VOMITORIOS (23-9-2026). Los dos iban a la misma franja
		## alta de la rampa y a 1 cm de altura de diferencia (borde del telón a
		## 0,32 y boca a 0,33): se solapaban casi siempre, así que o el trapo
		## tapaba la boca de acceso o la boca aparecía pintada sobre el trapo, y
		## a la rasante con que se ve una grada eso además parpadea. Los telones
		## se quedan en la franja media-alta y los vomitorios se van al borde de
		## arriba del todo.
		var d: float = -fondo * 0.5 + fondo * rng.randf_range(0.45, 0.70)
		var pos_borde := Vector3(d, 0.32, centro) if lateral else Vector3(centro, 0.32, d)
		var m0 := MeshInstance3D.new()
		var pm0 := PlaneMesh.new()
		pm0.size = Vector2(hondo + 0.26, ancho + 0.26) if lateral \
			else Vector2(ancho + 0.26, hondo + 0.26)
		m0.mesh = pm0
		m0.position = pos_borde
		m0.material_override = borde
		deck.add_child(m0)
		var m := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(hondo, ancho) if lateral else Vector2(ancho, hondo)
		m.mesh = pm
		## 0,36 m sobre el plano del deck: por encima del cojin de las butacas
		## (0,24) y del propio reborde (0,32), sin peleas de profundidad.
		m.position = pos_borde + Vector3(0, 0.04, 0)
		m.material_override = telas[rng.randi_range(0, telas.size() - 1)]
		## Nombre UNICO por telon, no el mismo para los tres. Con el nombre
		## repetido Godot le pone un sufijo a los hermanos y la busqueda por
		## nombre de la prueba solo encontraba uno por tribuna -parecia que
		## faltaban ocho de doce y estaban todos ahi.
		m.name = "TelonHinchada_%d" % k
		deck.add_child(m)
	_vomitorios(deck, largo, fondo, lateral)
static func _cinta_led(root: Node3D, pos: Vector3, cara: Vector3, largo: float, est: Dictionary) -> void:
	if _shader_cinta == null:
		_shader_cinta = load("res://visor/cinta_led.gdshader")
	var q := QuadMesh.new()
	q.size = Vector2(largo, 1.2)
	var mi := MeshInstance3D.new()
	mi.name = "CintaLED"
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = _shader_cinta
	m.set_shader_parameter("c1", Color(str(est.get("hincha1", est.get("asiento1", "#1f5f3d")))))
	m.set_shader_parameter("c2", Color(str(est.get("hincha2", est.get("asiento2", "#ffffff")))))
	m.set_shader_parameter("largo", largo)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.position = pos
	## El QuadMesh mira a +Z: se gira hacia `cara` (hacia el campo).
	mi.rotation.y = atan2(cara.x, cara.z)

## LA ESQUINA, COMO GRADA DE VERDAD (23-9-2026).
##
## Pedido directo del usuario -"siento que un error grave son las bandejas de
## las esquinas, se ven feas"-, y tenía toda la razón. Eran **un cubo sólido**
## con la textura de grada encima, y ahí se juntaban dos cosas malas:
##
##   1. Por el atlas de UV de `BoxMesh` (medido hoy, ver `build()`), cada cara
##      del cubo solo mostraba **el 17% de la textura**, ampliado 3x2. Al lado
##      de unas tribunas que desde hoy sí muestran la textura entera, la
##      esquina se veía como un borrón gigante.
##   2. Era una PARED VERTICAL entre dos gradas inclinadas. Aunque la textura
##      hubiera estado bien, no había forma de que leyera como continuación del
##      cuenco.
##
## Ahora la esquina es lo que es en un estadio de verdad: la misma grada dando
## la vuelta, en diagonal a 45°, con una rampa por bandeja a la misma altura
## que las de las tribunas vecinas. Cada rampa es un `QuadMesh` -que sí mapea
## la textura entera- y detrás va un bloque oscuro que le da masa y tapa el
## exterior.
static func _esquina_grada(root: Node3D, sx: float, sz: float, dx: float, dz: float,
		alto: float, niveles: int, grada_mat: Material, muro_mat: Material,
		ang: float, est: Dictionary, ocupacion: float, seed_val: int,
		techo: bool = false) -> void:
	var dir := Vector3(sx, 0.0, sz).normalized()
	## Donde se cortarían las dos caras interiores de las tribunas vecinas: es
	## el vértice del que arranca el chaflán.
	var p0 := Vector3(sx * (dx - FRENTE_TRIBUNA), 0.0, sz * (dz - FRENTE_TRIBUNA))
	var subida_b := subida_bandeja()
	var largo_rake := sqrt(FONDO_BANDEJA * FONDO_BANDEJA + subida_b * subida_b)
	## El quad mira a +Z sin girar; se le da la vuelta para que mire AL CAMPO
	## (-dir) y se le echa el respaldo hacia atrás con la misma pendiente que
	## las tribunas.
	var giro := atan2(-sx, -sz)
	var masa := fondo_tribuna(niveles)
	## El bloque de atrás: da masa y cierra el exterior. Va detrás de la ÚLTIMA
	## bandeja, no detrás de la primera. Puesto a `masa/2 + medio fondo` -que es
	## lo que parecía razonable- su cara quedaba a 5,5 m del vértice y se tragaba
	## las bandejas 1 a 4, que arrancan a 8,5 m: en la captura se veía un hueco
	## negro donde tenía que haber grada. La cara delantera tiene que quedar a
	## `fondo_tribuna` exactos, que es donde acaba la última rampa.
	var centro_masa := p0 + dir * (fondo_tribuna(niveles) + masa * 0.5)
	var caja := _box(root, Vector3(centro_masa.x, alto / 2.0, centro_masa.z),
		Vector3(masa, alto, masa), muro_mat)
	caja.rotation.y = giro
	## La losa de techo de la esquina. El "anillo perimetral" tenia CUATRO
	## huecos sin techo justo sobre las esquinas -y a la vez dos losas
	## solapadas ahi mismo, que es el z-fighting que se arregla en `build()`-.
	if techo:
		var tapa := _box(root, Vector3(centro_masa.x, alto + 0.4, centro_masa.z),
			Vector3(masa * 1.5, 0.5, masa * 1.5), muro_mat)
		marcar_techo(tapa, Vector3(sx, 0.0, sz).normalized())
		tapa.rotation.y = giro
	for b in niveles:
		var avance: float = float(b) * RETRANQUEO_BANDEJA + FONDO_BANDEJA / 2.0
		var centro := p0 + dir * avance
		var y_pie: float = ALTURA_PIE + float(b) * (subida_b + FRENTE_BANDEJA)
		## El chaflán se ensancha con cada bandeja: cuanto más atrás, más largo
		## es el hueco que hay entre los extremos de las dos tribunas vecinas.
		var ancho: float = 12.0 + float(b) * RETRANQUEO_BANDEJA * 2.0
		## `PlaneMesh`, NO `QuadMesh` (23-9-2026). Dos motivos, y los dos eran
		## bugs de verdad del primer intento:
		##
		##  1. LA TEXTURA IBA GIRADA 90 GRADOS, que es la razon de fondo de que
		##     la esquina siguiera "viendose fea" despues de dejar de ser un
		##     cubo. `_make_stand_texture()` genera la imagen con **U = subiendo
		##     la rampa** y **V = a lo largo de la tribuna**: las filas de gente
		##     son lineas de U constante y las escaleras bandas de V constante.
		##     Un `QuadMesh` vive en su plano XY, asi que los ejes quedaban
		##     cruzados y en las cuatro esquinas las filas corrian VERTICALES
		##     subiendo la pendiente y las escaleras cruzaban la rampa de lado a
		##     lado. Un `PlaneMesh` vive en XZ con U en X y V en Z: exactamente
		##     el mismo reparto que la cara de arriba de un deck.
		##  2. La normal de un `QuadMesh` es +Z y la de un `PlaneMesh` es +Y.
		##     `_butacas()` coloca a la gente en el plano XZ del nodo y la
		##     levanta en Y, o sea que necesita la normal en +Y. Con el quad,
		##     los hinchas habrian quedado DENTRO del plano y mirando de canto.
		var q := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(largo_rake, ancho)
		q.mesh = pm
		q.position = Vector3(centro.x, y_pie + subida_b / 2.0, centro.z)
		## Misma base que un deck de tribuna, girada al angulo de la esquina:
		## local X sube la rampa en diagonal, local Y es la normal, local Z
		## corre a lo largo del chaflan.
		var theta := atan2(-dir.z, dir.x)
		q.basis = Basis().rotated(Vector3(0, 0, 1), ang).rotated(Vector3.UP, theta)
		## Su propio material, para que la textura repita a lo largo del chaflan
		## con la misma densidad que en las tribunas (cada ~20 m). Con el
		## material compartido de las cuatro esquinas no se podia: `ancho`
		## cambia en cada bandeja.
		var mat_b: StandardMaterial3D = grada_mat.duplicate()
		mat_b.uv1_scale = Vector3(1.0, maxf(1.0, ancho / 20.0), 1.0)
		q.material_override = mat_b
		root.add_child(q)
		## Y hinchada de verdad, no solo textura: hasta ahora `_esquina_grada()`
		## recibia `est`, `ocupacion` y `seed_val` y **no usaba ninguno de los
		## tres** -el sintoma delator que esta misma auditoria ya documento para
		## el `_banquillos(root, dx)` que se borro-. En la practica las esquinas
		## no tenian ni una persona en 3D mientras las tribunas de al lado
		## estaban llenas. Se pasa `b + 1` como bandeja para que NUNCA pidan el
		## modelo caro de butacas: son cuatro rampas mas y solo se ven de lejos.
		_butacas(q, Vector3(largo_rake, 0.4, ancho), true, est, ocupacion,
			alto, ang, b + 1)

## Los paños de fuera de la torre de una esquina (el bloque que cierra la
## grada en diagonal, ver `_esquina_grada`): la cara del fondo y los dos
## costados, sin el tramo de dentro de los costados (ahí se junta con las
## tribunas). Mismas cuentas que `_esquina_grada`.
static func _caras_esquina(sx: float, sz: float, dx: float, dz: float, alto: float,
		niveles: int, techo: bool) -> Array:
	var dir := Vector3(sx, 0.0, sz).normalized()
	var p0 := Vector3(sx * (dx - FRENTE_TRIBUNA), 0.0, sz * (dz - FRENTE_TRIBUNA))
	var masa := fondo_tribuna(niveles)
	var centro := p0 + dir * (masa * 1.5)
	var sal: Array = [FachadaEstadio.cara(centro + dir * (masa * 0.5), dir, masa, alto, "esquina", techo, masa, niveles)]
	var perp := Vector3(-dir.z, 0.0, dir.x)
	for lado in [1.0, -1.0]:
		var n: Vector3 = perp * lado
		var cf := FachadaEstadio.cara(centro + n * (masa * 0.5), n, masa, alto, "esquina", techo, masa, niveles)
		var dentro := centro - dir * (masa * 0.5) + n * (masa * 0.5)
		var s_in: float = (dentro - (cf["o"] as Vector3)).dot(cf["u"] as Vector3)
		cf["excluir"] = [Vector2(s_in - 0.5, s_in + masa * 0.4) if s_in < masa * 0.5 else Vector2(s_in - masa * 0.4, s_in + 0.5)]
		sal.append(cf)
	return sal

## LA PISTA DE ATLETISMO (23-9-2026). `pista` es un bool del catálogo cuyo
## capítulo cuesta **480.000 -el más caro del diseñador de estadio- y hasta hoy
## no se dibujaba NADA**: `EstadioPropio.ambiente()` le restaba 3,5 de ánimo (la
## contrapartida de alejar al público) y esa penalización era todo lo que el
## jugador recibía por su dinero. Cero referencias en todo `visor/`.
##
## Se dibuja en la explanada que ya existe entre la reja perimetral y la cara
## interior de la tribuna, que es exactamente donde va una pista de verdad. En
## "óvalo" (dx=54) esa franja da 10,5 m -una pista completa-; en las formas
## compactas sale más estrecha, que es precisamente por lo que un recinto de
## atletismo se diseña ovalado.
static func _pista_atletismo(root: Node3D, est: Dictionary, dx: float, dz: float) -> void:
	if not bool(est.get("pista", false)):
		return
	var tartan := StandardMaterial3D.new()
	tartan.albedo_color = Color(0.62, 0.24, 0.17)
	tartan.roughness = 0.95
	var cal := StandardMaterial3D.new()
	cal.albedo_color = Color(0.92, 0.93, 0.92)
	cal.roughness = 1.0
	## De la reja hacia afuera, hasta donde empieza el graderío.
	var x0 := 38.0
	var z0 := 56.5
	var x1: float = dx - FRENTE_TRIBUNA
	var z1: float = dz - FRENTE_TRIBUNA
	var ancho_x: float = x1 - x0
	var ancho_z: float = z1 - z0
	if ancho_x < 1.0 or ancho_z < 1.0:
		return
	## El anillo: dos bandas largas, dos cortas y las cuatro esquinas.
	for sx in [1.0, -1.0]:
		_box(root, Vector3(sx * (x0 + ancho_x / 2.0), 0.012, 0.0),
			Vector3(ancho_x, 0.02, z0 * 2.0), tartan)
	for sz in [1.0, -1.0]:
		_box(root, Vector3(0.0, 0.012, sz * (z0 + ancho_z / 2.0)),
			Vector3(x0 * 2.0, 0.02, ancho_z), tartan)
		for sx in [1.0, -1.0]:
			_box(root, Vector3(sx * (x0 + ancho_x / 2.0), 0.012, sz * (z0 + ancho_z / 2.0)),
				Vector3(ancho_x, 0.02, ancho_z), tartan)
	## Las calles: una raya blanca cada 1,22 m, que es la medida reglamentaria.
	var calles: int = maxi(1, int(ancho_x / 1.22))
	for k in range(1, calles + 1):
		var off: float = x0 + float(k) * 1.22
		if off >= x1:
			break
		for sx in [1.0, -1.0]:
			_box(root, Vector3(sx * off, 0.025, 0.0), Vector3(0.05, 0.02, z0 * 2.0), cal)
	var calles_z: int = maxi(1, int(ancho_z / 1.22))
	for k in range(1, calles_z + 1):
		var off: float = z0 + float(k) * 1.22
		if off >= z1:
			break
		for sz in [1.0, -1.0]:
			_box(root, Vector3(0.0, 0.025, sz * off), Vector3(x0 * 2.0, 0.02, 0.05), cal)

## Una bandera de tela que ondea, con el borde izquierdo en `pos` (el asta).
static func _bandera_ondeante(root: Node3D, pos: Vector3, tam: Vector2, color: Color, giro: float, fase: float) -> MeshInstance3D:
	var qm := QuadMesh.new()
	qm.size = tam
	qm.subdivide_width = 10
	qm.subdivide_depth = 4
	## El quad se centra en su origen: se corre medio ancho para que el borde
	## x=0 (UV 0, quieto) quede pegado al asta.
	qm.center_offset = Vector3(tam.x * 0.5, 0, 0)
	var m := MeshInstance3D.new()
	m.name = "Bandera"
	m.mesh = qm
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_BANDERA
	mat.set_shader_parameter("color", color)
	## La misma trama de `Texturas.tela()`, para que se lea como tejido.
	mat.set_shader_parameter("tela", Texturas.tela(Color.WHITE).detail_albedo)
	mat.set_shader_parameter("ancho", tam.x)
	mat.set_shader_parameter("fase", fase)
	m.material_override = mat
	m.position = pos
	m.rotation.y = giro
	root.add_child(m)
	return m

## LAS BANDERAS DE LA HINCHADA (23-9-2026). Otro conector mudo: `banderas` tiene
## SEIS valores en el catálogo, `EstadioPropio.ambiente()` paga +1,5 de ánimo
## por "tifo" y por "bufandas"... y **en todo `visor/` no había una sola
## referencia**. El jugador elegía "Tifo gigante en la popular" y no aparecía
## ningún tifo.
static func _banderas(root: Node3D, est: Dictionary, dx: float, dz: float,
		alto: float, niveles: int, mi: Club) -> void:
	var tipo := String(est.get("banderas", "club"))
	if tipo == "sin":
		return
	var c1 := _c(est.get("asiento1"), "#1f5f3d")
	var c2 := _c(est.get("asiento2"), "#e8e8e8")
	var z_frente: float = dz - FRENTE_TRIBUNA
	match tipo:
		"tifo":
			## Un telón gigante sobre la popular: el escudo del club, a lo
			## ancho de media tribuna. Es lo que promete la etiqueta, y no hace
			## falta arte nuevo -se reutiliza `Escudo.textura()`-.
			if mi == null:
				return
			var tex := Escudo.textura(mi, 512)
			if tex == null:
				return
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 1.0
			var lado: float = clampf(alto * 0.75, 8.0, 26.0)
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(lado, lado)
			q.mesh = qm
			q.position = Vector3(0, alto * 0.55, -(z_frente + 1.0))
			q.material_override = mat
			root.add_child(q)
		"bufandas":
			## Una banda de color a media grada: miles de bufandas en alto se
			## leen de lejos como una franja maciza del color del club.
			var banda := Texturas.tela(c1)
			for sz in [1.0, -1.0]:
				var b := _box(root, Vector3(0, alto * 0.5, sz * (z_frente + 0.8)),
					Vector3(dx * 1.2, 2.6, 0.2), banda)
				b.name = "BandaBufandas"
		_:
			## "club", "paises" y "banderines": mástiles en lo alto del recinto.
			## Cambian el reparto y el color, que es lo que las distingue.
			var colores: Array[Color] = []
			if tipo == "club":
				colores = [c1, c2]
			else:
				colores = [Color(0.85, 0.2, 0.2), Color(0.95, 0.85, 0.25),
					Color(0.2, 0.4, 0.85), Color(0.95, 0.95, 0.95), Color(0.2, 0.7, 0.35)]
			var cuantos := 10 if tipo != "banderines" else 22
			var asta := Texturas.metal(Color(0.8, 0.81, 0.84), 0.4)
			for i in cuantos:
				var a := TAU * float(i) / float(cuantos)
				var d := Vector2(cos(a), sin(a))
				var k: float = maxf(absf(d.x) / (dx + 2.0), absf(d.y) / (dz + 2.0))
				if k <= 0.0001:
					continue
				var p := Vector3(d.x / k, alto + 1.0, d.y / k)
				var h := 3.2 if tipo != "banderines" else 1.6
				var m := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.05
				cm.bottom_radius = 0.07
				cm.height = h
				cm.radial_segments = 5
				m.mesh = cm
				m.material_override = asta
				m.position = p + Vector3(0, h / 2.0, 0)
				root.add_child(m)
				## Tela que ondea (25-9-2026): un plano subdividido con el
				## shader `bandera.gdshader`, sujeto al asta por un lado. Antes
				## era una caja rígida, como una chapa.
				var tam := Vector2(1.3, 0.85) if tipo != "banderines" else Vector2(0.6, 0.45)
				_bandera_ondeante(root, p + Vector3(0, h * 0.82, 0), tam, colores[i % colores.size()], a, float(i) * 1.7)

static func _cono_de_luz(root: Node3D, desde: Vector3, hasta: Vector3, radio_suelo: float, luz: Color) -> void:
	if _mat_cono == null:
		_mat_cono = StandardMaterial3D.new()
		_mat_cono.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_cono.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_cono.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat_cono.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat_cono.albedo_color = Color(luz, 0.0)
	var largo := desde.distance_to(hasta)
	var dir := (desde - hasta).normalized()
	var cono := CylinderMesh.new()
	cono.top_radius = 0.25
	cono.bottom_radius = radio_suelo
	cono.height = largo
	cono.radial_segments = 10
	cono.rings = 0
	cono.cap_top = false
	cono.cap_bottom = false
	var mi := MeshInstance3D.new()
	mi.mesh = cono
	mi.material_override = _mat_cono
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), (desde + hasta) * 0.5)
	mi.add_to_group("foco_cono")
	root.add_child(mi)
