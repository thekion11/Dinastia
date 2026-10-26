extends "res://visor/stadium_builder_p2.gd"
## [Capa 3/12 de `stadium_builder.gd`] _banquillos_detalle, _tunel, geom_de_forma, _un_camarografo, _camarografos, _escudo_cancha

## `tipo` (16-9-2026, Fase 2 "Componentes"), catalogo `EST_BANQUILLOS`. El
## default ("cristal") es la burbuja de siempre, asi que un rival sigue igual.
## `est` (ronda 4 de calidad visual): mismo criterio que en `_corners()` y
## `_tunel()` -si trae `asiento1` (solo el estadio propio), los asientos
## "cristal"/"bunker"/"foso" salen del color de la camiseta.
static func _banquillos_detalle(root: Node3D, tipo: String = "cristal", est: Dictionary = {}) -> void:
	## LA "BURBUJA DE CRISTAL" ERA OPACA (23-9-2026). `Texturas.cristal()` nunca
	## asigna `transparency`, así que se quedaba en `TRANSPARENCY_DISABLED` con
	## un albedo casi negro, `metallic` 0,9 y `roughness` 0,05: para una ventana
	## de fachada de la ciudad está bien -no hace falta ver adentro-, pero aquí
	## daba **una caja de cromo negro espejada al borde de la banda**, que es el
	## banquillo POR DEFECTO del catálogo y sale en todos los planos de la
	## cámara principal. Los nueve asientos que se dibujan dentro no se veían
	## nunca. El `.duplicate()` es obligatorio: `cristal()` cachea por
	## `(encendida, calido)` y hay ventanas de ciudad usando esa misma instancia.
	var vidrio: StandardMaterial3D = Texturas.cristal(false).duplicate()
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.albedo_color = Color(0.55, 0.62, 0.68, 0.22)
	## Sin esto, dos paneles de metacrilato uno detrás de otro se ordenan mal y
	## parpadean según el ángulo.
	vidrio.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	vidrio.cull_mode = BaseMaterial3D.CULL_DISABLED
	vidrio.metallic = 0.1
	vidrio.roughness = 0.08
	var estructura := Texturas.metal(_c(est.get("banquilloCol", ""), "#292b30"), 0.4)
	## Cuero de verdad (16-9-2026) para los sillones -antes color plano, y era
	## justo el banquillo mas "de lujo" del catalogo el que menos brillaba de
	## verdad. El resto sigue con el plastico simple: es a proposito, un
	## banquillo de cristal comun no tiene por que tener cuero.
	var asiento: StandardMaterial3D = Texturas.cuero(Color(0.36, 0.20, 0.12)) if tipo == "sillones" \
		else _asiento_simple(_c(est.get("asiento1"), "#24262b"))
	var madera := Texturas.madera(Color(0.42, 0.28, 0.16))
	## Cuanto se hunde el banquillo bajo el nivel del campo. 0 = a ras, como
	## siempre; los dos "excavados" del catalogo (bunker/foso) lo bajan.
	var hundido := 0.55 if tipo in ["bunker", "foso"] else 0.0
	## La cancha usa X=ancho (banda a banda, cal +-34) y Z=largo (arco a arco,
	## +-52.5) -ver los goles en _add_goal() y las constantes MEDIO_LARGO /
	## MEDIO_ANCHO en control_partido.gd/match_playback.gd. Esto tenia X y Z
	## CAMBIADOS: el "lado*12.0" (pensado para separar los dos banquillos a
	## cada lado del CIRCULO CENTRAL, como dice el comentario de arriba) caia
	## en X en vez de Z, y el "40.5" (pensado como la distancia fija a la
	## banda) caia en Z en vez de X -asi el banquillo quedaba a 12m del centro
	## del campo EN ANCHO (bien adentro de la cancha) y a 40.5m de la mitad EN
	## LARGO (practicamente dentro del area chica). Se veia -y el usuario lo
	## confirmo con una foto- como una caja negra metida en el area, no un
	## banquillo en la banda.
	## 3.5 m detrás de la línea de banda (X=±34), los DOS en la tribuna
	## principal (X positivo), separados ±14 m del círculo central en Z.
	## El dugout se rota 90° para que la fila de asientos corra a lo largo
	## de la banda, no atravesando el césped.
	const DISTANCIA_LINEA_BANDA := 3.5
	var x_banda: float = PITCH_WID * 0.5 + DISTANCIA_LINEA_BANDA
	for lado in [-1.0, 1.0]:
		var base := Vector3(x_banda, -hundido, lado * 14.0)
		var n := Node3D.new()
		n.name = "BanquilloLocal" if lado < 0.0 else "BanquilloVisita"
		n.position = base
		n.rotation_degrees.y = 90.0
		root.add_child(n)
		match tipo:
			"banca":
				## A la vieja usanza: ni vidrio ni techo, solo el banco de
				## madera y nada mas -es lo mas barato del catalogo, y se nota.
				_box(n, Vector3(0, 0.45, -0.2), Vector3(7.6, 0.12, 0.9), madera)
				for k in range(4):
					var pata := _box(n, Vector3(-3.0 + k * 2.0, 0.22, -0.2), Vector3(0.1, 0.44, 0.8), madera)
					pata.material_override = estructura
			"foso":
				## Excavado Y cubierto: una losa plana en vez de vidrio, "solo
				## se ven las cabezas" -sin paredes transparentes, con techo bajo.
				var losa := _box(n, Vector3(0, 1.35, -0.3), Vector3(8.2, 0.15, 3.2), estructura)
				losa.position.y = hundido + 1.35
				_box(n, Vector3(0, 0.12, -0.2), Vector3(7.6, 0.24, 2.4), estructura)
				for k in range(9):
					_box(n, Vector3(-3.4 + k * 0.85, 0.55, 0.2), Vector3(0.6, 0.62, 0.6), asiento)
			_:  # "cristal" (siempre), "bunker" y "sillones" comparten la burbuja
				var techo := _box(n, Vector3(0, 2.05, -0.3), Vector3(8.0, 0.12, 3.0), estructura)
				techo.rotation.x = -0.12
				_box(n, Vector3(0, 1.1, 1.15), Vector3(8.0, 2.1, 0.08), vidrio)
				for s in [-1.0, 1.0]:
					_box(n, Vector3(s * 3.95, 1.1, -0.3), Vector3(0.08, 2.1, 3.0), vidrio)
				_box(n, Vector3(0, 0.12, -0.2), Vector3(7.6, 0.24, 2.4), estructura)
				if tipo == "sillones":
					## Menos asientos, mas anchos -son sillones reclinables, no
					## una fila de banco- separados a lo largo del mismo tramo.
					for k in range(7):
						_box(n, Vector3(-3.0 + k * 1.0, 0.55, 0.2), Vector3(0.72, 0.62, 0.6), asiento)
				else:
					## "cristal" y "bunker": exactamente la fila de siempre.
					for k in range(9):
						_box(n, Vector3(-3.4 + k * 0.85, 0.55, 0.2), Vector3(0.6, 0.62, 0.6), asiento)

## Boca del tunel de vestuarios, con el arco de entrada que trajo el usuario si
## esta disponible. Es por donde salen los equipos y da un punto focal a la
## tribuna principal, que era una pared lisa de 90 metros.
## `tipo` (16-9-2026, Fase 2 "Componentes"), catalogo `EST_TUNELES`. El
## default ("central") es exactamente la mole de siempre, asi que un rival
## sigue igual. `est` (ronda 4 de calidad visual): el portico inflable
## ("arco") sale del color de la camiseta si `est` lo trae -mismo criterio
## que los banderines de corner-, rojo generico si no (cualquier rival).
## `dz` (23-9-2026): el semi-largo del recinto. Antes no lo recibia y por eso
## el ancla del tunel era un numero fijo -ver el bug explicado abajo-.
static func _tunel(root: Node3D, tipo: String = "central", est: Dictionary = {},
		dz: float = 68.0) -> void:
	## SIN LUZ PROPIA, ESTA MOLE SE VE NEGRA (13-9-2026). Confirmado con una
	## captura real desde "Detrás del arco": la cara visible queda bajo la
	## cubierta de la tribuna, sin línea directa a sol/luna ni a los focos
	## -que apuntan al césped, no a una hornacina debajo del graderío-, y el
	## ambiente nocturno no basta para leer el material: sale un bloque
	## negro perfectamente plano, sin textura, que confundió al usuario
	## ("¿qué es eso en la portería?"). Un OmniLight cercano no lo arregló
	## -la hornacina sigue sin luz de verdad ahí dentro-, así que la solución
	## real es la misma que usa cualquier túnel de vestuarios de un estadio
	## real: SU PROPIA luz de entrada, no depender de que algo externo la
	## alcance. Material propio (no el `Texturas.hormigon()` compartido, para
	## no afectar a nadie más que lo use) con un pelín de emisión.
	## "esquina" desplaza toda la boca hacia el lado del corner en vez del
	## centro del lateral -los otros 4 tipos siguen centrados como siempre.
	var x_off := 24.0 if tipo == "esquina" else 0.0
	## BUG REAL ENCONTRADO Y CORREGIDO (21-9-2026, ver LEEME.md): la mole con
	## Z=45.0 quedaba DENTRO del campo -el arco esta en Z=52.5 (`MEDIO_LARGO`
	## de match_playback.gd/control_partido.gd) y la caja, de 6m de fondo,
	## llegaba hasta Z=48: a 4.5m de la linea de gol, encima del area chica-.
	## El usuario lo vio con sus propios ojos en una captura: la caja tapaba
	## el arco entero desde varios angulos de camara -no era un problema de
	## encuadre de camara, la estructura de verdad estaba sobre la cancha.
	## `ANCLA_Z` mueve todo el conjunto detras de la linea de gol, mismos
	## desfaces relativos entre mole/boca/tubo/arco que ya tenian.
	##
	## SEGUNDA PARTE DEL MISMO BUG (23-9-2026): ese arreglo dejo el ancla en
	## **64,0 metros FIJOS**, que es el `dz` de la forma "ingles" clavado a
	## mano. Con las otras cinco formas el tunel se va de sitio:
	##   - "oval" (dz=74): la tribuna empieza en 68,5 y la mole se queda en
	##     61..67, o sea SOLA sobre el hormigon, a 7 m por delante del
	##     graderio y fuera del plano de cesped.
	##   - "ingles" (dz=64) y "caldera" (65): la boca queda 2 m POR DENTRO de
	##     la rampa, enterrada, y no se ve.
	## El ancla correcta se deriva del recinto: la cara interior de la tribuna
	## esta en `dz - 5.5`, y la mole mide 6 m de fondo, asi que centrandola en
	## `dz - 2.5` su frente cae justo en esa cara y la boca queda a ras, que es
	## como se ve un tunel de vestuarios de verdad: un hueco oscuro en la
	## tribuna, ni delante ni enterrado.
	var ancla_z: float = dz - 2.5
	if tipo == "central" or tipo == "esquina" or tipo == "telescopico":
		## La mole maciza con una placa negra (lo de antes) ya no hace falta:
		## el pórtico, el pasillo y el vestuario los monta `TunelVestuario`.
		if tipo == "telescopico":
			## El tubo retractil se estira desde la boca hacia la cancha. Abierto
			## por los dos extremos: se puede salir caminando por dentro.
			var tubo := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 2.4
			cm.bottom_radius = 2.6
			cm.height = 5.0
			cm.cap_top = false
			cm.cap_bottom = false
			tubo.mesh = cm
			tubo.rotation.x = PI / 2.0
			tubo.position = Vector3(x_off, 1.9, ancla_z - 5.5)
			var mt: StandardMaterial3D = Texturas.metal(Color(0.55, 0.56, 0.58), 0.5).duplicate()
			mt.cull_mode = BaseMaterial3D.CULL_DISABLED
			tubo.material_override = mt
			root.add_child(tubo)
	elif tipo == "arco":
		## Portico hinchable: un arco curvo en vez de la mole de hormigon, con
		## un pelin de brillo propio -es lona iluminada por dentro, no piedra.
		## `Texturas.tela()` de base (16-9-2026) -es lona, no plastico duro- y
		## DUPLICADA antes de tocarle la emision: esa funcion cachea y devuelve
		## la MISMA instancia a cualquiera que pida el mismo color, y prenderle
		## la emision sin duplicar se la prendería tambien a cualquier otra
		## bandera roja de este color en el resto del estadio.
		var col_inflable := _c(est.get("asiento1"), "#d92626")
		var inflable: StandardMaterial3D = Texturas.tela(col_inflable, 0.7).duplicate()
		inflable.emission_enabled = true
		inflable.emission = col_inflable
		inflable.emission_energy_multiplier = 0.4
		## BUG REAL (23-9-2026): el portico estaba en **z = 42,5 FIJO**, y el
		## area grande va de z=33,75 a 50,25 -o sea que el arco inflable se
		## plantaba DENTRO DEL AREA, a 10 m de la linea de gol-. Es el mismo
		## bug que el comentario de mas arriba dice haber corregido el 21-9,
		## pero aquel arreglo solo toco las ramas "central/esquina/telescopico"
		## y estas dos se quedaron fuera. Ahora comparten el mismo ancla.
		var z_arco: float = ancla_z - 3.4
		var arco3d := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 2.6
		tm.outer_radius = 3.1
		arco3d.mesh = tm
		arco3d.rotation.x = PI / 2.0
		arco3d.position = Vector3(0, 3.1, z_arco)
		arco3d.material_override = inflable
		root.add_child(arco3d)
		for sx in [-1.0, 1.0]:
			_box(root, Vector3(sx * 2.8, 1.55, z_arco), Vector3(0.5, 3.1, 0.5), inflable)
	else:  # "foso": emerge desde debajo del cesped por una escalera iluminada
		## BUG REAL (23-9-2026): ademas del ancla fija, este tipo estaba
		## ENTERO POR DEBAJO DE y=0 (la mole de -1,8 a 0, los escalones hasta
		## -1,42). El plano de cesped es OPACO y cubre z hasta ±58,5, asi que
		## **no se veia absolutamente nada**: la emision alumbraba el reverso
		## del suelo. Un foso de verdad se ve porque la boca asoma sobre el
		## nivel del campo; subida para que sobresalga, con los escalones
		## bajando hacia dentro desde el borde.
		## Ahora la boca es el pórtico de `TunelVestuario`; el «foso» es su
		## umbral: tres peldaños bajos iluminados que bajan hacia la cancha.
		var escalones: StandardMaterial3D = Texturas.hormigon(Color(0.3, 0.31, 0.33), 29).duplicate()
		escalones.emission_enabled = true
		escalones.emission = Color(0.5, 0.55, 0.65)
		escalones.emission_energy_multiplier = 0.8
		for k in range(3):
			_box(root, Vector3(0, 0.25 - k * 0.08, ancla_z - 3.4 - k * 0.6),
				Vector3(4.6, 0.1, 0.6), escalones)

## Geometria del recinto segun la forma elegida en el disenador del juego.
## dx/dz son la distancia del CENTRO de cada tribuna al centro del campo.
## La tribuna tiene 11 de fondo, asi que su cara interior queda en dx-5.5:
## esa cara nunca puede quedar por dentro de la valla perimetral (38 a lo ancho,
## 56.5 tras el arco) o el graderio se comeria la cancha. Por eso el minimo
## practico es dx>=44.5 y dz>=63.5, aunque "compacto ingles" se quede en ese
## limite justamente porque su gracia es estar encima del campo.
## Devuelve {dx, dz, esquinas, abierta} — abierta = indice de tribuna omitida.
static func geom_de_forma(forma: String) -> Dictionary:
	match forma:
		"ingles":
			return {"dz": 64.0, "dx": 45.0, "esquinas": true, "abierta": -1}
		"rect":
			return {"dz": 67.0, "dx": 48.0, "esquinas": false, "abierta": -1}
		"herradura":
			return {"dz": 66.0, "dx": 47.0, "esquinas": true, "abierta": 1}
		"caldera":
			return {"dz": 65.0, "dx": 46.0, "esquinas": true, "abierta": -1}
		"oval":
			return {"dz": 74.0, "dx": 54.0, "esquinas": true, "abierta": -1}
		## Formas nuevas (MEGAPLAN B6). "dos": solo las dos laterales, los
		## fondos a cielo abierto (campos chicos y de barrio). "principal":
		## cuatro cajas y una gran tribuna de honor una bandeja más alta.
		"dos":
			return {"dz": 67.0, "dx": 47.0, "esquinas": false, "abierta": -1, "abiertas": [0, 1]}
		"principal":
			return {"dz": 67.0, "dx": 48.0, "esquinas": false, "abierta": -1, "principal": 2}
		## (21-10-2026, M-002) «estrecho»: caja pegada al césped, sin esquinas
		## (los campos ingleses modernos); «asimetrico»: la tribuna de honor más
		## alta y un fondo a cielo abierto.
		"estrecho":
			return {"dz": 62.5, "dx": 43.5, "esquinas": false, "abierta": -1}
		"asimetrico":
			return {"dz": 66.0, "dx": 47.0, "esquinas": false, "abierta": 1, "principal": 2}
		_:  # cuenco
			return {"dz": 68.0, "dx": 49.0, "esquinas": true, "abierta": -1}

static func _un_camarografo(root: Node3D, pos: Vector3, chaleco: Material, pantalon: Material, piel: Material, equipo: Material) -> void:
	var base := Node3D.new()
	## `VistaEstadio` busca este nombre para poner un operador de verdad en
	## lugar del maniquí de cajas (26-9-2026); los trozos con meta "cuerpo" son
	## los que se ocultan, la cámara y el monopié se quedan.
	base.name = "Camarografo"
	base.position = pos
	## Siempre mirando al centro del campo: nadie graba de espaldas a la jugada.
	var hacia := -pos
	hacia.y = 0
	if hacia.length() > 0.01:
		base.rotation.y = atan2(hacia.x, hacia.z)
	root.add_child(base)
	## RENDIMIENTO (17-9-2026): 5 camarógrafos × 6 piezas cada uno son 30 mallas
	## proyectando sombra por una figura de fondo del tamaño de un maniquí -en
	## una Intel UHD el paso de sombras es de lo más caro que hay. Sin sombra
	## propia no se nota (la tira su propia base sobre el césped) y se ahorran
	## 30 mallas del atlas de sombras enteras.
	for m: MeshInstance3D in [
			_box(base, Vector3(-0.1, 0.4, 0), Vector3(0.14, 0.8, 0.14), pantalon),
			_box(base, Vector3(0.1, 0.4, 0), Vector3(0.14, 0.8, 0.14), pantalon),
			_box(base, Vector3(0, 1.15, 0), Vector3(0.42, 0.5, 0.26), chaleco),
			_box(base, Vector3(0, 0.55, 0.32), Vector3(0.06, 1.1, 0.06), equipo),
			_box(base, Vector3(0, 1.15, 0.34), Vector3(0.30, 0.22, 0.55), equipo),
		]:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if m.material_override != equipo:
			m.set_meta("cuerpo", true)
	var cabeza := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.14
	sm.height = 0.28
	cabeza.mesh = sm
	cabeza.position = Vector3(0, 1.55, 0)
	cabeza.material_override = piel
	cabeza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cabeza.set_meta("cuerpo", true)
	base.add_child(cabeza)

## CAMARÓGRAFOS AL BORDE DEL CAMPO (13-9-2026). Pedido del usuario ("faltan
## camarógrafos"): un estadio de televisión de verdad siempre tiene gente
## trabajando detrás de cada arco y a pie de línea en la mitad de cancha, y
## sin ellos el perímetro del césped se siente vacío. Figuras sencillas -no
## un personaje completo, no hace falta para un detalle de fondo- de un
## operador con chaleco de prensa y su cámara sobre un monopié, mirando
## siempre hacia el centro del campo.
static func _camarografos(root: Node3D) -> void:
	var chaleco := StandardMaterial3D.new()
	chaleco.albedo_color = Color(0.85, 0.55, 0.08)
	var pantalon := StandardMaterial3D.new()
	pantalon.albedo_color = Color(0.12, 0.13, 0.15)
	var piel := StandardMaterial3D.new()
	piel.albedo_color = Color(0.62, 0.47, 0.38)
	var equipo := StandardMaterial3D.new()
	equipo.albedo_color = Color(0.06, 0.06, 0.07)
	equipo.metallic = 0.5
	equipo.roughness = 0.4
	## Detrás de cada arco (a los dos lados, como en la tele de verdad) y a pie
	## de línea en la mitad de cancha, del lado de la cámara principal.
	var puestos: Array[Vector3] = [
		Vector3(21.0, 0, 54.5), Vector3(-21.0, 0, 54.5),
		Vector3(21.0, 0, -54.5), Vector3(-21.0, 0, -54.5),
		Vector3(36.5, 0, 0.0),
	]
	for p in puestos:
		_un_camarografo(root, p, chaleco, pantalon, piel, equipo)

## El escudo pintado en el circulo central, sobre el cesped. `donde` viene del
## catalogo `EST_ESCUDOS` -esta funcion solo mira "cancha"/"todo", el resto de
## posiciones (grada/fachada/techo) las resuelve `_escudo_tribuna()` en
## `build()`, que es quien conoce la geometria del graderio-. El default de
## `est.get("escudoDonde", ...)` en TODOS los call sites de esta fase es
## "sin", a proposito distinto del default de fabrica de `EST_DEF`
## ("cancha"): un rival nunca trae esta clave, y el estadio que no ha tocado
## el diseñador tampoco debe empezar a mostrar un escudo que nunca pidio.
static func _escudo_cancha(root: Node3D, mi: Club, donde: String) -> void:
	if donde != "cancha" and donde != "todo":
		return
	## PINTURA, NO PEGATINA (29-9-2026, mapa de metas 20). De cerca -la
	## cinemática del fichaje- el escudo se veía tosco: 256 px sin mipmaps
	## estirados en 9 m, opaco y sin luz, como un plástico encima del césped.
	## Ahora: 1024 px con mipmaps y filtro anisótropo (bordes limpios de cerca y
	## sin parpadeo de lejos), recibe el sol y las sombras como el césped, y la
	## pintura deja ver un poco la hierba.
	var tex := Escudo.textura(mi, 1024)
	if tex == null:
		return
	var img := tex.get_image()
	if img != null and not img.is_empty():
		if img.is_compressed():
			img.decompress()
		img.generate_mipmaps()
		tex = ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = Color(1, 1, 1, 0.55)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	mat.metallic_specular = 0.1
	var quad := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(9.0, 9.0)
	quad.mesh = qm
	quad.rotation.x = -PI / 2.0
	quad.position = Vector3(0, 0.03, 0)
	quad.material_override = mat
	root.add_child(quad)

## Una caja de 1 m de lado, compartida: cada tubo y cada poste es una instancia escalada.
static var _caja_1: BoxMesh
static func _caja_unidad() -> BoxMesh:
	if _caja_1 == null:
		_caja_1 = BoxMesh.new()
	return _caja_1

## Las piezas (en el espacio del deck) de los pasamanos de los pasillos y de la
## barandilla del borde bajo (las usa `_montar_pasillos`). `suelo`: la altura de
## la cara de arriba del deck en su espacio (0,2 en una losa de 0,4; 0 en un plano).
static func _piezas_baranda(pasillos_l: Array[float], lateral: bool, fondo: float, largo: float,
		sentido: float, rake: float, suelo := 0.2) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var eje_rake := Vector3(0, 0, 1) if lateral else Vector3(1, 0, 0)
	var de_pie := Basis().rotated(eje_rake, -rake)
	var arriba: Vector3 = de_pie * Vector3.UP
	var tubo := 0.05
	for l: float in pasillos_l:
		## El pasamanos, a lo largo de la pendiente (como el de siempre).
		var esc := Vector3(fondo - 0.6, tubo, tubo) if lateral else Vector3(tubo, tubo, fondo - 0.6)
		out.append(Transform3D(Basis.from_scale(esc), _en_deck(lateral, 0.0, l, suelo + 0.75)))
		## Sus postes: verticales en el mundo, del suelo de la grada al pasamanos.
		var alto_poste: float = 0.75 / maxf(arriba.y, 0.3)
		var n_postes: int = maxi(2, int((fondo - 1.0) / 1.8) + 1)
		for k in n_postes:
			var d: float = -fondo * 0.5 + 0.5 + (fondo - 1.0) * float(k) / float(n_postes - 1)
			var pie: Vector3 = _en_deck(lateral, d, l, suelo)
			out.append(Transform3D(de_pie * Basis.from_scale(Vector3(0.04, alto_poste, 0.04)), pie + arriba * alto_poste * 0.5))
	if largo < 4.0:
		return out
	## La barandilla del borde bajo: dos tubos corridos (a 1,0 y 0,55 m) y un
	## poste cada ~2,4 m, sobre el filo de la bandeja.
	var d0: float = sentido * (-fondo * 0.5 + 0.12)
	var largo_util: float = largo - 0.4
	for h: float in [1.0, 0.55]:
		var esc_r := Vector3(tubo, tubo, largo_util) if lateral else Vector3(largo_util, tubo, tubo)
		out.append(Transform3D(de_pie * Basis.from_scale(esc_r), _en_deck(lateral, d0, 0.0, suelo) + arriba * h))
	var n_f: int = maxi(2, int(largo_util / 2.4) + 1)
	for k in n_f:
		var l: float = -largo_util * 0.5 + largo_util * float(k) / float(n_f - 1)
		out.append(Transform3D(de_pie * Basis.from_scale(Vector3(0.045, 1.0, 0.045)), _en_deck(lateral, d0, l, suelo) + arriba * 0.5))
	return out

## El punto del deck a `d` del centro en el eje del fondo, `l` en el largo y `y` de alto.
static func _en_deck(lateral: bool, d: float, l: float, y: float) -> Vector3:
	return Vector3(d, y, l) if lateral else Vector3(l, y, d)

## La textura de la cubierta de metal (la usa `_techo_mat`).
static var _techos_mat := {}
static var _tex_techo: ImageTexture
## 4 × 4 m de cubierta en 128 px: vigas oscuras cada 2 m en las dos direcciones y
## la greca de la chapa (una banda cada 25 cm). Gris claro: el color lo pone el tinte.
static func _tex_cubierta() -> ImageTexture:
	if _tex_techo != null:
		return _tex_techo
	var n := 128
	var img := Image.create(n, n, true, Image.FORMAT_RGB8)
	for y in n:
		for x in n:
			var v := 0.92 if (x / 4) % 2 == 0 else 1.0
			if x % 64 < 3 or y % 64 < 3:
				v = 0.5
			elif x % 64 < 5 or y % 64 < 5:
				v = 0.72
			img.set_pixel(x, y, Color(v, v, v))
	img.generate_mipmaps()
	_tex_techo = ImageTexture.create_from_image(img)
	return _tex_techo
