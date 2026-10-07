class_name RuedaPrensaEscena3D
extends Node3D
## EL PLATÓ DE LA RUEDA DE PRENSA, en 3D de verdad.
##
## Hasta hoy la rueda de prensa era texto plano sobre fondo oscuro, encogida
## dentro de la tarjeta de "asuntos pendientes": la pregunta, tres botones de
## respuesta y un selector de "cómo lo dices". Toda esa lógica sigue viviendo
## en `principal.gd` -este fichero no inventa diálogo nuevo, ni una pregunta
## ni una opción: solo les da un plató detrás-, pero ahora en pantalla
## completa (`_abrir_rueda_pantalla_completa()`), no en una tarjetita.
## Mismo principio que `SorteoEscena3D`: geometría procedural con
## `StandardMaterial3D`, nada de modelos importados ni texturas generadas por
## IA -se probó un generador gratis para esto mismo y salió sin color, ver
## `dinastia-assets-cc0-web.md`-.
##
## POR QUÉ UN FONDO DE PATROCINADORES Y NO UNA PARED LISA. Una rueda de
## prensa de verdad tiene detrás una pared con el escudo del club y los
## logos de los sponsors repetidos en rejilla -la foto de referencia que
## mandó el usuario lo muestra tal cual-. Se arma con un `SubViewport` que
## repite `Escudo.textura()` y `Marca.textura()` -el logo de sponsor que se
## añadió en la misma sesión que este fichero, antes esto habría sido texto
## plano y no habría tenido sentido ponerlo detrás de nadie-.
##
## EL DT SOLO SE VE DE PECHO PARA ARRIBA, a propósito: el podio tapa el
## resto, así que no hace falta piernas ni el retargeting Mixamo que sí
## necesita el futbolista del campo. Una cápsula con la cabeza encima, igual
## que el presentador del sorteo, es lo que se ve en cualquier rueda de
## prensa real a esa distancia de cámara.

var _camara: Camera3D
var _dt_cabeza: MeshInstance3D
var _dt_quad: MeshInstance3D
## Las dos manos apoyadas en el podio (14-9-2026, pedido explícito: "invierte
## en eso" tras el gesto del sorteo). Cada una es un `Node3D` (hombro) con el
## antebrazo y la mano colgando -mismo patrón barato que ya usa el
## presentador del sorteo (`SorteoEscena3D._montar_brazo_suelto`)-, colgado
## del propio retrato en vez de un cuerpo 3D real: el DT sigue siendo el
## retrato 2D de `CaraDT` -no vale la pena montar un humanoide entero para dos
## manos que solo se ven del codo para abajo, tapadas por el podio-.
var _dt_brazos: Array[Node3D] = []
var _t := 0.0
var _cam_pos := Vector3.ZERO
var _cam_mira := Vector3.ZERO

## LOS PLANOS DE CÁMARA (14-9-2026), mismo principio que ya prueba
## `SorteoEscena3D`: una retransmisión de verdad CORTA entre planos, no se
## queda fija -pedido explícito: llevar la rueda de prensa al mismo nivel de
## producción que el sorteo-. Tres planos, a la escala mucho más chica de
## este plató (10×8 m, contra los 13×9 del sorteo):
##  · de trabajo: el de siempre, cerca del DT, con el que se abre.
##  · general: más atrás y alto, se ve la sala entera con periodistas.
##  · lateral: desde el lado de los periodistas, con alguno en primer término.
## `fov` VARÍA POR PLANO -no es solo la posición-: con un FOV fijo (34°, un
## teleobjetivo cerrado) alejar la cámara unos metros apenas cambia lo que se
## ve, porque el "zoom" percibido sigue siendo el mismo. El plano general
## necesita abrir el ángulo de verdad para leerse como sala completa, no solo
## como el mismo plano un poco más lejos.
const PLANOS := [
	{"pos": Vector3(0.0, 1.5, 2.15), "mira": Vector3(0.0, 1.25, -0.5), "fov": 34.0},
	## Contra la pared del fondo, mirando hacia el podio: se ve la sala
	## entera -paredes, techo, periodistas de espaldas en primer plano- con el
	## DT pequeño al fondo, como el plano general de cualquier retransmisión.
	{"pos": Vector3(0.3, 2.3, 4.3), "mira": Vector3(0.0, 1.1, -1.4), "fov": 58.0},
	{"pos": Vector3(-2.2, 1.5, 1.8), "mira": Vector3(0.4, 1.3, -0.5), "fov": 42.0},
]
var _plano := 0
## MÁS CERCA Y CON MENOS ÁNGULO DE VISIÓN: a 2,5 m y 38° de FOV sobraba medio
## encuadre de vacío negro por encima y a los lados del podio -se vio en
## captura-. Un plano de entrevista de verdad encuadra de hombros para
## arriba llenando el cuadro, no un sujeto pequeño en medio de la nada.
## Y=1.42 dejaba la fila de arriba de la pared de sponsors justo en el borde
## del encuadre -se veía cortada a la mitad en pantalla completa, donde el
## recuadro tiene otra proporción que en la tarjetita chica de antes-. Un
## poco más abajo deja margen arriba sin perder nada del DT ni del podio.
## LA RAÍZ DE FONDO DE VARIAS RONDAS DE AJUSTE: a 1,75 m de distancia y 30°
## de FOV, CUALQUIER cosa cerca de la cámara -el DT, el podio- llena el
## encuadre entero, así que perseguir el tamaño exacto de cada pieza por
## separado nunca termina de cuadrar. Alejar un poco la cámara y abrir algo
## el FOV resuelve la causa de una vez en lugar de seguir retocando cada
## objeto.
const CAM_POS := Vector3(0.0, 1.5, 2.15)
const CAM_MIRA := Vector3(0.0, 1.25, -0.5)

## `look_dt`: el aspecto de quien habla de verdad (`Roles.look_efectivo()` si el
## jugador es el DT, o `CaraDT.look_de_nombre()` del empleado si no). Vacío ->
## geometría genérica de siempre (compatibilidad hacia atrás).
## `clubes_competencia`: los clubes de tu liga -la pared de sponsors ahora
## muestra SUS escudos, como una pared de prensa real de un torneo, en vez de
## marcas genéricas. Vacío -> las marcas de siempre (compatibilidad hacia atrás).
func montar(club: Club, acento: Color, nivel: int = Calidad.ALTO, look_dt: Dictionary = {},
		clubes_competencia: Array = []) -> void:
	var we := Calidad.entorno(nivel, Calidad.NOCHE)
	add_child(we)
	var env := we.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.78)
	env.ambient_light_energy = 0.85
	## Bloom suave: los focos de sala tienen que quemar un poco, o el plató se
	## ve plano y de oficina en vez de televisado.
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 1.1
	env.tonemap_exposure = 1.0
	env.volumetric_fog_enabled = false

	_montar_suelo()
	_montar_sala()
	_montar_periodistas()
	_montar_fondo_sponsors(club, acento, clubes_competencia)
	_montar_banderas(club)
	_montar_luces()
	_montar_podio()
	_montar_dt(look_dt)
	_montar_gesto_dt(look_dt)
	_montar_camara()

# ---------------------------------------------------------------------------
#  LA SALA (14-9-2026)
# ---------------------------------------------------------------------------
#
# Antes el podio y la pared de sponsors flotaban sobre un suelo de 10×8 m sin
# nada alrededor: en cuanto la cámara se abría un poco de más se veía el
# vacío. Mismo principio que ya resolvió esto para el sorteo
# (`SorteoEscena3D._montar_sala()`): paredes que cierran el encuadre y un
# techo con su truss de focos, a la escala mucho más chica de este plató.

## LAS BANDERAS DE LA SALA (MEGAPLAN fase 4): la del país del club y la del
## club, en mástiles a los dos lados de la pared de sponsors.
func _montar_banderas(club: Club) -> void:
	if club == null:
		return
	var asta := StandardMaterial3D.new()
	asta.albedo_color = Color(0.8, 0.8, 0.83)
	asta.metallic = 0.9
	asta.roughness = 0.3
	var texs := [Banderas.textura(club.pais), Banderas.de_club(club)]
	for i in 2:
		var lado := -1.0 if i == 0 else 1.0
		var base := Vector3(lado * 2.95, 0.0, -1.4)
		var palo := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.02
		cm.bottom_radius = 0.03
		cm.height = 2.25
		palo.mesh = cm
		palo.material_override = asta
		palo.position = base + Vector3(0, 1.125, 0)
		add_child(palo)
		## Colgada del asta, cae vertical (sala cerrada: sin viento).
		var qm := QuadMesh.new()
		qm.size = Vector2(0.9, 0.6)
		qm.subdivide_width = 10
		qm.subdivide_depth = 4
		qm.center_offset = Vector3(0.45, 0, 0)
		var tela := MeshInstance3D.new()
		tela.mesh = qm
		var mat := ShaderMaterial.new()
		mat.shader = StadiumBuilder.SHADER_BANDERA
		mat.set_shader_parameter("usa_dibujo", true)
		mat.set_shader_parameter("espejo", lado > 0.0)
		mat.set_shader_parameter("dibujo", texs[i])
		mat.set_shader_parameter("tela", Texturas.tela(Color.WHITE).detail_albedo)
		mat.set_shader_parameter("ancho", 0.9)
		mat.set_shader_parameter("fase", float(i) * 2.0)
		mat.set_shader_parameter("viento", 0.12)
		tela.material_override = mat
		tela.position = base + Vector3(0, 1.88, 0.02)
		tela.rotation.y = 0.0 if lado < 0.0 else PI
		add_child(tela)

func _montar_sala() -> void:
	var oscuro := StandardMaterial3D.new()
	oscuro.albedo_color = Color(0.05, 0.05, 0.06)
	oscuro.roughness = 0.8

	## Paredes laterales, ligeramente giradas hacia dentro -mismo truco que el
	## sorteo- para que el encuadre se cierre en vez de escapar a negro.
	for lado in [-1.0, 1.0]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.2, 4.2, 8.5)
		m.mesh = bm
		m.material_override = oscuro
		m.position = Vector3(lado * 5.1, 2.1, 0.2)
		m.rotation.y = deg_to_rad(-lado * 6.0)
		add_child(m)

	## El techo y su truss: el detalle barato que más dice "esto es un
	## recinto", no un decorado flotando.
	var techo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(10.4, 0.2, 8.6)
	techo.mesh = tm
	techo.material_override = oscuro
	techo.position = Vector3(0, 4.15, 0.2)
	add_child(techo)
	var barra_mat := StandardMaterial3D.new()
	barra_mat.albedo_color = Color(0.12, 0.13, 0.15)
	barra_mat.metallic = 0.65
	barra_mat.roughness = 0.5
	for i in 2:
		var barra := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(9.6, 0.1, 0.1)
		barra.mesh = bm2
		barra.material_override = barra_mat
		barra.position = Vector3(0, 3.85, -1.6 + float(i) * 3.2)
		add_child(barra)
		for j in 5:
			var foco := MeshInstance3D.new()
			var fm := CylinderMesh.new()
			fm.top_radius = 0.08
			fm.bottom_radius = 0.11
			fm.height = 0.24
			foco.mesh = fm
			foco.material_override = barra_mat
			foco.position = Vector3(-3.6 + float(j) * 1.8, 3.68, -1.6 + float(i) * 3.2)
			foco.rotation.x = deg_to_rad(24.0)
			add_child(foco)

## LOS PERIODISTAS. No hay que modelarlos con detalle -a la distancia con la
## que se ven en el plano general y lateral, lo que vende la sala es que HAY
## GENTE, no la cara de cada uno-: mismo patrón barato que
## `SorteoEscena3D._montar_publico()`, cajas de asiento + cápsulas de cuerpo.
## Sentados de espaldas a la cámara de trabajo -mirando al podio-, a los
## lados de donde se para esa cámara, para que aparezcan en los planos
## general y lateral sin taparle nunca la cara al DT.
func _montar_periodistas() -> void:
	var mat_silla := StandardMaterial3D.new()
	mat_silla.albedo_color = Color(0.14, 0.14, 0.17)
	mat_silla.roughness = 0.85
	var mat_gente := StandardMaterial3D.new()
	## Más clara que el primer intento -con la luz de relleno nueva, un gris
	## casi tan oscuro como el fondo seguía sin leerse-: esto es decorado que
	## tiene que notarse que hay gente, no una silueta perfecta.
	mat_gente.albedo_color = Color(0.24, 0.25, 0.29)
	mat_gente.roughness = 0.85
	for fila in 2:
		var z := 1.5 + float(fila) * 1.05
		for lado in [-1.0, 1.0]:
			for i in 3:
				## Hueco ocasional: una fila llena del todo se lee como
				## decorado repetido, no como público de verdad.
				if fmod(float(fila * 7 + i * 5) * 0.19, 1.0) < 0.2:
					continue
				var x: float = float(lado) * (1.7 + float(i) * 0.75)
				var silla := MeshInstance3D.new()
				var sm := BoxMesh.new()
				sm.size = Vector3(0.42, 0.42, 0.42)
				silla.mesh = sm
				silla.material_override = mat_silla
				silla.position = Vector3(x, 0.21, z)
				add_child(silla)
				var cuerpo := MeshInstance3D.new()
				var cm := CapsuleMesh.new()
				cm.radius = 0.14
				cm.height = 0.56
				cuerpo.mesh = cm
				cuerpo.material_override = mat_gente
				cuerpo.position = Vector3(x, 0.68, z + 0.02)
				add_child(cuerpo)

# ---------------------------------------------------------------------------
#  EL SUELO
# ---------------------------------------------------------------------------

func _montar_suelo() -> void:
	var m := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(10, 8)
	m.mesh = p
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.07, 0.08)
	mat.metallic = 0.5
	mat.roughness = 0.35
	m.material_override = mat
	add_child(m)

# ---------------------------------------------------------------------------
#  LA PARED DE PATROCINADORES
# ---------------------------------------------------------------------------
#
# Se arma en un `SubViewport` -mismo truco que la pantalla gigante del
# sorteo-: es la única forma de tener el escudo y los logos con bordes
# nítidos dentro de una escena 3D, porque una malla con una textura pintada a
# mano se ve borrosa en cuanto la cámara se acerca.

## MÁS FILAS Y MÁS CHICAS, no menos: la primera versión tenía 3 filas de
## logos gigantes -cada uno casi tan alto como el propio podio- y la pared
## se comía la escena entera. Una pared de prensa real repite decenas de
## logos PEQUEÑOS; el tamaño que de verdad importa es el de la placa entera
## contra la altura de una persona, no el de cada logo suelto.
const FILAS_LOGO := 4
const COLS_LOGO := 9

func _montar_fondo_sponsors(club: Club, acento: Color, clubes_competencia: Array = []) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(2000, 700)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)

	var fondo := ColorRect.new()
	fondo.color = acento.darkened(0.82)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(fondo)

	## LOS ESCUDOS DE TU LIGA (14-9-2026), no marcas genéricas -pedido
	## explícito: "que al fondo fueran los escudos de los clubes de la
	## competencia correspondiente"-. Antes esto rotaba por `Datos.tabla
	## ("MARCAS")`, sponsors sin relación con el partido que se acaba de
	## jugar. Una pared de prensa de liga de verdad muestra los equipos que
	## compiten, no auspiciadores al azar. Si no llega ninguna competencia
	## -compatibilidad hacia atrás, por ejemplo una prueba vieja- se cae a
	## las marcas de siempre.
	var otros: Array = []
	for c: Club in clubes_competencia:
		if c != null and c != club:
			otros.append(c)
	var marcas: Array = Datos.tabla("MARCAS") if otros.is_empty() else []
	var grid := GridContainer.new()
	grid.columns = COLS_LOGO
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	vp.add_child(grid)
	var total := FILAS_LOGO * COLS_LOGO
	for i in total:
		var celda := TextureRect.new()
		celda.custom_minimum_size = Vector2(150, 120)
		celda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		celda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		## Cada tercera celda es el escudo del club anfitrión -mismo patrón
		## que una pared real, donde se repite más que el resto-; el resto va
		## rotando por los rivales de la liga (o, si no hay, por las marcas).
		if i % 3 == 0:
			celda.texture = Escudo.textura(club, 110)
		elif not otros.is_empty():
			var rival: Club = otros[i % otros.size()]
			celda.texture = Escudo.textura(rival, 110)
		elif marcas != null and not marcas.is_empty():
			var fila: Array = marcas[i % marcas.size()]
			celda.texture = Marca.textura(String(fila[0]), String(fila[1]), 110)
		grid.add_child(celda)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.85
	var tex := vp.get_texture()
	mat.albedo_texture = tex
	mat.emission_texture = tex
	## EL TAMAÑO FÍSICO ES LO QUE IMPORTA, no el número de logos. 9,6×3,0 m
	## -más alto que una persona y más ancho que el podio por completo- hacía
	## que la pared se comiera la escena y el DT quedara como un punto en la
	## esquina. 5,4×1,7 m centrado a la altura de cabeza-pecho es lo que
	## ocupa de verdad una placa de sponsors detrás de un podio real.
	var quad := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(5.4, 1.7)
	quad.mesh = q
	quad.material_override = mat
	quad.position = Vector3(0, 1.55, -1.6)
	add_child(quad)

# ---------------------------------------------------------------------------
#  LUCES
# ---------------------------------------------------------------------------

func _montar_luces() -> void:
	## APUNTADAS A LA CABEZA Y EL PECHO DEL DT (y~1.55), no al podio: la
	## primera versión apuntaba a y=1.35 -la altura del PODIO- y el DT, medio
	## metro más arriba, quedaba casi a oscuras contra una pared de sponsors
	## emisiva y mucho más brillante. Es la razón por la que en la primera
	## captura el DT se veía como una mancha oscura sin forma.
	## OJO CON LA ENERGÍA, otra vez -misma trampa que ya se pagó en el sorteo
	## ("a 1,4 los balones salían reventados")-: a 8.0 la cabeza del DT salía
	## quemada, una esfera blanca sin rasgos en vez de una cara. El sorteo
	## calibró su foco principal a 4.0 con atenuación 1.4; aquí el sujeto está
	## más cerca de la luz que el bombo, así que baja un poco más todavía.
	var clave := SpotLight3D.new()
	clave.light_color = Color(1, 0.98, 0.94)
	clave.light_energy = 3.2
	clave.spot_range = 8.0
	clave.spot_angle = 34.0
	clave.spot_attenuation = 1.4
	clave.shadow_enabled = true
	add_child(clave)
	clave.look_at_from_position(Vector3(-1.0, 2.6, 1.6), Vector3(0, 1.55, -0.45), Vector3.UP)

	var relleno := SpotLight3D.new()
	relleno.light_color = Color(0.85, 0.9, 1.0)
	relleno.light_energy = 1.6
	relleno.spot_range = 8.0
	relleno.spot_angle = 42.0
	relleno.spot_attenuation = 1.4
	add_child(relleno)
	relleno.look_at_from_position(Vector3(1.3, 2.1, 1.8), Vector3(0, 1.55, -0.45), Vector3.UP)

	## Contraluz para separar al DT de la pared -sin esto el traje oscuro se
	## funde contra el fondo también oscuro entre logo y logo.
	var contra := OmniLight3D.new()
	contra.light_color = Color(0.7, 0.78, 1.0)
	contra.light_energy = 3.0
	contra.omni_range = 3.0
	contra.position = Vector3(0, 1.9, -1.0)
	add_child(contra)

	## LOS PERIODISTAS (14-9-2026): sin luz propia eran invisibles -su material
	## (0.14,0.15,0.18) contra un fondo casi negro (0.05,0.05,0.06) se leía
	## como negro puro, mismo error ya documentado para el DT y el
	## presentador del sorteo-. Un relleno tenue y frío, alto y centrado sobre
	## la zona donde se sientan, solo para que se noten como siluetas -no
	## para que compitan con el DT, que sigue siendo lo único bien iluminado
	## de la escena-.
	var luz_publico := OmniLight3D.new()
	luz_publico.light_color = Color(0.55, 0.6, 0.7)
	luz_publico.light_energy = 1.1
	luz_publico.omni_range = 4.5
	luz_publico.position = Vector3(0, 3.2, 1.8)
	add_child(luz_publico)

# ---------------------------------------------------------------------------
#  EL PODIO
# ---------------------------------------------------------------------------

## EL PODIO GENERADO POR IA (11-9-2026), EN HÍBRIDO CON UN OCULTADOR PROCEDURAL.
##
## El usuario pidió explícitamente "usa el generador para crear cada uno de
## los objetos", así que se reintentó lo que en el primer intento de la
## sesión salía blanco puro -y esa parte SÍ se resolvió de verdad-: el GLB de
## TripoSR SÍ trae color por vértice (`COLOR_0`, comprobado a mano con un
## script de depuración -70994 colores reales, ni vacíos ni blancos-). Lo que
## faltaba era decirle al material que lo USARA: sin
## `vertex_color_use_as_albedo`, cualquier `StandardMaterial3D` por defecto
## ignora el color por vértice y pinta con su albedo por defecto, que es
## blanco. El color que trae el vértice es sombreado en gris -la foto de
## origen era casi monocroma-, así que se tiñe con `albedo_color` -que
## MULTIPLICA sobre el vértice, no lo reemplaza- en vez de regenerar la
## imagen de origen a mano.
##
## LO QUE SEGUÍA FALLANDO: reconstruido de una sola foto, el modelo no trae
## una "altura de mesa" predecible ni una superficie plana definida -a
## diferencia de una caja procedural, donde uno elige la altura a mano-, así
## que la mesa del modelo quedaba demasiado baja para tapar al DT de la
## cintura para abajo. Ajustar SOLO la escala nunca dio un resultado fiable
## -se probó de 1,1 a 1,57 m de alto total, y en ningún punto la mesa quedaba
## exactamente donde hacía falta-.
##
## LA SOLUCIÓN: NO ELEGIR ENTRE LAS DOS TÉCNICAS, USAR LAS DOS A LA VEZ. El
## modelo generado se queda encima -aporta el detalle real que una caja lisa
## no tiene: la mesa en cuña, los dos micrófonos de cuello de ganso, el
## sombreado real de la forma-, y una caja procedural sencilla, TEÑIDA DEL
## MISMO COLOR, se esconde detrás para garantizar que el DT quede tapado
## exactamente a la altura que se necesita, sin depender de adivinar la
## geometría reconstruida. Al ser del mismo tono y quedar detrás, no se nota
## la costura: se lee como un solo podio.
const RUTA_PODIO_IA := "res://assets/props/generado_ia/podio_prensa.glb"
const USAR_PODIO_IA := true
const TINTE_PODIO := Color(0.16, 0.22, 0.5)

func _montar_podio() -> void:
	var uso_generado := USAR_PODIO_IA and _montar_podio_generado()
	## El ocultador SIEMPRE se monta -tanto si el modelo generado cargó como
	## si no-: es lo único de lo que depende que el DT quede bien tapado, así
	## que no puede fallar en silencio si el asset generado no está.
	if not uso_generado:
		## Sin el modelo generado, el ocultador no hace falta -el podio
		## procedural completo ya se tapa a sí mismo-.
		_montar_podio_procedural()
	else:
		_montar_ocultador_podio()

## La caja lisa detrás del modelo generado. Mismas medidas que tenía el
## podio procedural completo -ya probadas y correctas-, pero sin los
## micrófonos: esos ya los aporta el modelo generado, y duplicarlos se vería
## raro (cuatro brazos de micrófono en vez de dos).
func _montar_ocultador_podio() -> void:
	var met := StandardMaterial3D.new()
	met.albedo_color = TINTE_PODIO.darkened(0.15)
	met.metallic = 0.2
	met.roughness = 0.6
	## MÁS BAJA A PROPÓSITO -0,75 m, no 1,05-: si el ocultador llega tan alto
	## como el podio procedural completo, se traga la mesa y los micrófonos
	## del modelo generado -que a 1,1 m de alto tienen la mesa a media altura,
	## no al tope-, y solo asoman las puntas. Dejándolo más bajo, la mesa y
	## los micrófonos del modelo generado quedan POR ENCIMA del ocultador,
	## visibles de verdad, y el DT solo asoma del pecho para arriba.
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.75, 0.5)
	cuerpo.mesh = bm
	cuerpo.material_override = met
	cuerpo.position = Vector3(0, 0.375, -0.12)
	add_child(cuerpo)

func _montar_podio_generado() -> bool:
	if not ResourceLoader.exists(RUTA_PODIO_IA):
		return false
	var esc := load(RUTA_PODIO_IA)
	var n := (esc as PackedScene).instantiate() if esc is PackedScene else null
	if n == null:
		return false
	var mallas := _mallas_de(n)
	## COMPROBAR QUE DE VERDAD HAY ALGO QUE PINTAR -misma regla que ya dejó
	## escrita `Sorteo._montar_presentador_modelo()`: un `load()` que no da
	## null no significa que haya una malla visible dentro.
	if mallas.is_empty():
		n.queue_free()
		return false

	var raiz := Node3D.new()
	add_child(raiz)
	raiz.add_child(n)

	## LA ESCALA Y LA POSICIÓN SE MIDEN, NO SE ADIVINAN -mismo motivo que ya
	## dejó escrito Sorteo: cada exportador usa las unidades que le da la
	## gana-. 1,1 m es la altura a la que el modelo se ve proporcionado de
	## verdad -comprobado con capturas de cuatro ángulos-; el ocultador de
	## atrás es quien se encarga de la altura de oclusión, así que aquí ya no
	## hace falta forzar el número para que "tape bien".
	var caja := AABB()
	var primero := true
	for m in mallas:
		var a: AABB = m.mesh.get_aabb() if m.mesh != null else AABB()
		a = m.transform * a
		if primero:
			caja = a
			primero = false
		else:
			caja = caja.merge(a)
	var alto := caja.size.y
	var escala := (1.1 / alto) if alto > 0.001 else 1.0
	raiz.scale = Vector3.ONE * escala
	var centro := (caja.position + caja.size * 0.5) * escala
	var pie_y := caja.position.y * escala
	raiz.position = Vector3(-centro.x, -pie_y, -0.1 - centro.z)

	for m in mallas:
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.albedo_color = TINTE_PODIO
		mat.roughness = 0.7
		m.material_override = mat
	return true

func _mallas_de(n: Node) -> Array[MeshInstance3D]:
	var salida: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		salida.append(n)
	for h in n.get_children():
		salida.append_array(_mallas_de(h))
	return salida

## EL PODIO PROCEDURAL DE RESPALDO. Si el fichero generado no está -por
## ejemplo, en una máquina donde nunca se copió el asset-, la escena sigue
## funcionando con cajas simples en vez de romperse o quedar sin podio.
func _montar_podio_procedural() -> void:
	var met := StandardMaterial3D.new()
	met.albedo_color = Color(0.14, 0.15, 0.17)
	met.metallic = 0.35
	met.roughness = 0.4

	## El cuerpo: una caja recta y, encima, un panel inclinado -el mismo gesto
	## de la foto de referencia (el frente en cuña, no un cubo liso)-.
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 1.05, 0.55)
	cuerpo.mesh = bm
	cuerpo.material_override = met
	cuerpo.position = Vector3(0, 0.525, -0.1)
	add_child(cuerpo)

	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.94, 0.06, 0.6)
	panel.mesh = pm
	panel.material_override = met
	panel.position = Vector3(0, 1.06, -0.08)
	panel.rotation_degrees.x = -8.0
	add_child(panel)

	## Los dos micrófonos de cuello de ganso: mismo par cápsula+cilindro que el
	## brazo del presentador del sorteo, aquí quietos.
	var mic_mat := StandardMaterial3D.new()
	mic_mat.albedo_color = Color(0.05, 0.05, 0.06)
	mic_mat.metallic = 0.2
	mic_mat.roughness = 0.5
	for lado in [-1.0, 1.0]:
		var base_pos := Vector3(lado * 0.22, 1.1, -0.05)
		var cuello := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.012
		cm.bottom_radius = 0.014
		cm.height = 0.32
		cuello.mesh = cm
		cuello.material_override = mic_mat
		cuello.position = base_pos + Vector3(0, 0.16, 0)
		cuello.rotation_degrees.x = -22.0 * lado * 0.4
		add_child(cuello)
		var capsula := MeshInstance3D.new()
		var capm := CapsuleMesh.new()
		capm.radius = 0.028
		capm.height = 0.1
		capsula.mesh = capm
		capsula.material_override = mic_mat
		capsula.rotation_degrees.z = 90.0
		capsula.position = base_pos + Vector3(0.05 * lado, 0.32, 0)
		add_child(capsula)

# ---------------------------------------------------------------------------
#  EL DT, DE PECHO PARA ARRIBA
# ---------------------------------------------------------------------------

## AZUL MARINO VISIBLE, NO NEGRO PURO. La primera versión usaba un traje casi
## negro (0.11,0.12,0.17) contra un fondo casi negro (0.05,0.05,0.06): por
## bien iluminado que estuviera, el contraste de color era tan bajo que el DT
## se leía como una mancha sin forma. Mismo problema, mismo arreglo, que ya se
## documentó para el presentador del sorteo -"el negro puro contra un plató
## oscuro se come la silueta"-. Se mantiene como RESPALDO genérico si no hay
## `look_dt` -por ejemplo, una prueba vieja que llama a `montar()` sin el
## parámetro nuevo-.
func _montar_dt_generico() -> void:
	var traje := StandardMaterial3D.new()
	traje.albedo_color = Color(0.16, 0.19, 0.30)
	traje.roughness = 0.75
	var piel := StandardMaterial3D.new()
	piel.albedo_color = Color(0.56, 0.44, 0.36)
	piel.roughness = 0.65

	var torso := MeshInstance3D.new()
	var tm := CapsuleMesh.new()
	tm.radius = 0.22
	tm.height = 1.05
	torso.mesh = tm
	torso.material_override = traje
	torso.position = Vector3(0, 0.95, -0.5)
	add_child(torso)

	_dt_cabeza = MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.15
	cm.height = 0.3
	_dt_cabeza.mesh = cm
	_dt_cabeza.material_override = piel
	_dt_cabeza.position = Vector3(0, 1.68, -0.5)
	add_child(_dt_cabeza)

	var corbata := MeshInstance3D.new()
	var com := BoxMesh.new()
	com.size = Vector3(0.06, 0.32, 0.02)
	corbata.mesh = com
	var cor_mat := StandardMaterial3D.new()
	cor_mat.albedo_color = Color(0.55, 0.12, 0.14)
	cor_mat.roughness = 0.6
	corbata.material_override = cor_mat
	corbata.position = Vector3(0, 1.28, -0.24)
	add_child(corbata)

## EL DT CON SU CARA DE VERDAD (14-9-2026). Hasta hoy era una cápsula lisa con
## una esfera de "piel" encima -ni rasgos, ni corte de pelo, ni el traje que el
## jugador eligió en Mi Carrera-. `CaraDT.textura()` YA dibuja ese retrato
## completo -cara con los rasgos elegidos, corte de pelo, traje y corbata,
## viewBox cuadrado de hombros para arriba- porque es EL MISMO SVG que ya se
## usa en la pantalla de Mi Carrera; no hace falta un sistema de UV-mapping
## sobre geometría 3D -eso sigue pausado a propósito, ver ROADMAP fase 5- para
## que el jugador se vea a sí mismo en su propia rueda de prensa: basta con
## mostrar ese mismo retrato en un plano dentro de la escena.
func _montar_dt(look_dt: Dictionary) -> void:
	if look_dt.is_empty():
		_montar_dt_generico()
		return
	var tex := CaraDT.textura(look_dt, 256)
	if tex == null:
		_montar_dt_generico()
		return
	var quad := MeshInstance3D.new()
	var q := QuadMesh.new()
	## El SVG es cuadrado (64x64, hombros hasta arriba de la cabeza): 0,95 m de
	## lado da unos hombros de ancho creíble sin devorar la pared de sponsors,
	## del mismo orden que medía la cápsula genérica que reemplaza.
	q.size = Vector2(0.95, 0.95)
	quad.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	## UNSHADED + emission, igual que la pared de sponsors: el retrato ya trae
	## su propio sombreado pintado en el SVG, así que depender de las luces del
	## plató solo lo oscurecía sin aportar nada.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 0.9
	## El fondo de tarjeta del SVG (`rect opacity=".3"`) se traduce en alpha
	## parcial, no en un rectángulo sólido detrás de la figura.
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material_override = mat
	## Centrado en la misma altura que ocupaba el conjunto torso+cabeza
	## genérico (de ~0,4 a ~1,83 m): el quad de 0,95 m centrado en Y=1.12 va de
	## 0,645 a 1,595, tapado por abajo por el podio igual que antes.
	quad.position = Vector3(0, 1.12, -0.5)
	add_child(quad)
	_dt_quad = quad

## LAS MANOS APOYADAS EN EL PODIO (14-9-2026, pedido explícito tras el gesto
## del sorteo: "invierte en eso"). Un DT que nunca gesticula ni apoya las
## manos se lee como una foto pegada en cuanto la cámara se aleja del plano de
## trabajo -el retrato de `_montar_dt()` es un plano 2D fijo-. Un brazo por
## lado, cada uno UN SOLO TRAMO recto desde el hombro hasta la mano, sin codo
## intermedio: depurar el gesto del presentador del sorteo esta misma sesión
## costó horas por un codo que, visto desde cierto plano de cámara, se
## alineaba con la vista y el brazo se leía como una línea estirada -mismo
## hueso, misma pose, solo cambiaba el ángulo-. Un tramo único no tiene ese
## riesgo desde ningún ángulo, y a la distancia y el tamaño con que se ve un
## DT de pecho para arriba no se nota la falta del codo.
func _montar_gesto_dt(look_dt: Dictionary) -> void:
	var piel_mat := StandardMaterial3D.new()
	piel_mat.albedo_color = Color(String(look_dt.get("piel", "#c68863")))
	piel_mat.roughness = 0.7
	var manga := StandardMaterial3D.new()
	## Azul marino fijo, no el traje que eligió `CaraDT`: la manga casi no se
	## ve -la tapan el propio brazo y el borde del podio-, así que no vale la
	## pena acoplarse a qué traje salió sorteado para acertar el tono exacto.
	manga.albedo_color = Color(0.15, 0.17, 0.26)
	manga.roughness = 0.8
	_dt_brazos.clear()
	for lado in [-1.0, 1.0]:
		## RE-MEDIDO UNA SEGUNDA VEZ mirando la captura con calibración real
		## (proyectando `Vector3(0,y,-0.5)` a píxeles): el borde del podio que
		## de verdad tapa al DT en esta escena no está a 1,05 m -la altura del
		## `cuerpo` procedural completo-, sino a los 0,75 m del ocultador que
		## se monta CON el podio generado por IA (`USAR_PODIO_IA := true`, el
		## camino que corre de verdad aquí). Con eso, el hueco visible entre
		## el borde del podio y la barbilla es minúsculo -pura cuestión de
		## cuánto torso deja ver este plano tan cerrado-: un brazo en
		## DIAGONAL desde un "hombro" alto no cabe sin pegarse a la cara. Lo
		## que sí cabe, y es más real de todos modos -un antebrazo apoyado en
		## una mesa queda plano sobre ella, no en diagonal desde el hombro- es
		## un tramo casi HORIZONTAL a la altura de la propia mesa (0,85 m,
		## justo por encima del ocultador) que va desde cerca del cuerpo hasta
		## el borde delantero.
		var hombro := Vector3(lado * 0.2, 0.85, -0.35)
		var mano_pos := Vector3(lado * 0.23, 0.85, -0.05)
		var brazo := Node3D.new()
		add_child(brazo)
		brazo.add_child(_segmento(hombro, mano_pos, 0.045, manga))
		var mano := MeshInstance3D.new()
		var mm := SphereMesh.new()
		mm.radius = 0.048
		mm.height = 0.096
		mano.mesh = mm
		mano.material_override = piel_mat
		mano.position = mano_pos
		brazo.add_child(mano)
		_dt_brazos.append(brazo)

## Una cápsula que va exactamente de `desde` a `hasta`. `Quaternion(from, to)`
## da la rotación de arco más corto que lleva un eje a otro -aquí, del +Y por
## defecto de `CapsuleMesh` a la dirección real del brazo-, así que no hace
## falta descomponer en ángulos de Euler ni arriesgarse a un signo cambiado.
func _segmento(desde: Vector3, hasta: Vector3, radio: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radio
	cm.height = maxf(desde.distance_to(hasta), radio * 2.1)
	mi.mesh = cm
	mi.material_override = mat
	var medio := (desde + hasta) * 0.5
	var dir := (hasta - desde).normalized()
	mi.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), medio)
	return mi

# ---------------------------------------------------------------------------
#  CÁMARA
# ---------------------------------------------------------------------------

func _montar_camara() -> void:
	_camara = Camera3D.new()
	_camara.fov = 34.0
	add_child(_camara)
	_cam_pos = CAM_POS
	_cam_mira = CAM_MIRA
	## `look_at_from_position()` y no `position=` + `look_at()`: en el momento
	## en que `montar()` corre, esta escena todavía puede no estar dentro del
	## árbol -`_abrir_rueda_pantalla_completa()` arma el `SubViewport` entero
	## antes de colgarlo del popup-, y `look_at()` a secas exige un transform
	## global válido, que
	## solo existe una vez dentro del árbol. `look_at_from_position()` calcula
	## la orientación sin depender de eso.
	_camara.look_at_from_position(_cam_pos, _cam_mira, Vector3.UP)
	var at := CameraAttributesPractical.new()
	at.dof_blur_far_enabled = true
	at.dof_blur_far_distance = 3.2
	at.dof_blur_far_transition = 1.8
	at.dof_blur_amount = 0.05
	_camara.attributes = at

## Corta a otro plano -mismo patrón que `SorteoEscena3D.cortar_plano()`-.
## Se llama sola por tiempo (ver `_process()`); no depende de que
## `principal.gd` avise de cada pregunta nueva, así que funciona igual
## aunque el jugador tarde en elegir una respuesta.
func _cortar_plano() -> void:
	_plano = (_plano + 1) % PLANOS.size()

func _process(delta: float) -> void:
	_t += delta
	## Un corte cada varios segundos, siempre volviendo al plano de trabajo
	## entre los otros dos -que es donde de verdad se lee la pregunta y las
	## respuestas-, en vez de recorrer los tres en fila.
	var ciclo := fmod(_t, 9.0)
	var plano_activo := 0
	if ciclo > 7.5:
		plano_activo = 2
	elif ciclo > 5.0:
		plano_activo = 1
	if _camara != null:
		var d: Dictionary = PLANOS[plano_activo]
		var desde: Vector3 = d["pos"]
		var hacia: Vector3 = d["mira"]
		var fov_dest: float = d["fov"]
		## Deriva mínima DENTRO de cada plano -una entrevista es casi fija,
		## pero un corte seco entre posiciones estáticas se lee como
		## diapositivas, no como una retransmisión-.
		var deriva := Vector3(sin(_t * 0.18) * 0.04, sin(_t * 0.13) * 0.02, 0.0)
		var k := clampf(delta * 4.0, 0.0, 1.0)
		_cam_pos = _cam_pos.lerp(desde + deriva, k)
		_cam_mira = _cam_mira.lerp(hacia, k)
		_camara.fov = lerpf(_camara.fov, fov_dest, k)
		_camara.look_at_from_position(_cam_pos, _cam_mira, Vector3.UP)
	if _dt_cabeza != null:
		## Un asentimiento apenas perceptible: sin ningún movimiento, la cabeza
		## esférica se lee como un maniquí en cuanto se detiene la cámara.
		_dt_cabeza.rotation.x = sin(_t * 0.7) * 0.02
	if _dt_quad != null:
		## El retrato es un plano fijo: sin nada, se lee como una foto pegada
		## en cuanto la cámara se aleja lo suficiente para notarlo (el plano
		## general y el lateral). Un balanceo mínimo -sin rotar, que
		## deformaría la imagen de forma rara- da la sensación de que el
		## presentador respira sin necesitar un rig 3D.
		_dt_quad.position.y = 1.12 + sin(_t * 0.9) * 0.006
	## Manos quietas del todo se leen tan a maniquí como la cabeza sin
	## asentir: un vaivén mínimo -desfasado entre las dos, para que no se
	## muevan como una sola pieza- da un ligero apoyo de peso al hablar.
	for i in _dt_brazos.size():
		_dt_brazos[i].position.y = sin(_t * 0.8 + float(i) * 1.7) * 0.006
