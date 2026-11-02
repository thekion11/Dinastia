extends Node3D
## [Capa 1/4 de `rueda_prensa_escena3d.gd`] _montar_suelo, _montar_sala, _montar_periodistas, _montar_fondo_sponsors, _montar_banderas, _montar_luces

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
var _dt_3d_pendiente := false
var _dt_3d: Dictionary = {}
var _t_gesto_dt := 3.0
var _rng_dt := RandomNumberGenerator.new()
## Solo gestos suaves (26-10): los «Spell_*» estiraban el brazo hacia la cámara.
const GESTOS_PRENSA := ["charla"]
## (§2.5) El tono de la última respuesta ("seguro", "evasivo", "humilde"): el próximo gesto es el suyo.
var tono_dt := ""
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
	{"pos": Vector3(0.0, 1.62, 2.15), "mira": Vector3(0.0, 1.4, -0.5), "fov": 34.0},
	## Contra la pared del fondo, mirando hacia el podio: se ve la sala
	## entera -paredes, techo, periodistas de espaldas en primer plano- con el
	## DT pequeño al fondo, como el plano general de cualquier retransmisión.
	{"pos": Vector3(0.3, 2.3, 4.3), "mira": Vector3(0.0, 1.1, -1.4), "fov": 58.0},
	## A tres cuartos (26-10): el lateral de antes dejaba al DT de perfil.
	{"pos": Vector3(-1.25, 1.58, 2.0), "mira": Vector3(0.1, 1.4, -0.6), "fov": 38.0},
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

# ---------------------------------------------------------------------------
#  LA PARED DE PATROCINADORES
# ---------------------------------------------------------------------------
#
# Se arma en un `SubViewport` -mismo truco que la pantalla gigante del
# sorteo-: es la única forma de tener el escudo y los logos con bordes
# nítidos dentro de una escena 3D, porque una malla con una textura pintada a
# mano se ve borrosa en cuanto la cámara se acerca.

## Muchas piezas pequeñas, como una pared de prensa real (no logos gigantes).
const FILAS_LOGO := 4
const COLS_LOGO := 8

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

func _montar_sala() -> void:
	var oscuro := StandardMaterial3D.new()
	oscuro.albedo_color = Color(0.13, 0.13, 0.15)
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

func _montar_fondo_sponsors(club: Club, acento: Color, _clubes_competencia: Array = []) -> void:
	## Vive en `ParedPrensa` (26-10): según el contexto de la rueda (patrón del
	## club, competición o previa). `_contexto` lo fija `montar()` (capa 2).
	ParedPrensa.montar(self, club, acento, get("_contexto") if get("_contexto") != null else {})

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

# ---------------------------------------------------------------------------
#  LUCES
# ---------------------------------------------------------------------------

func _montar_luces() -> void:
	## APUNTADAS A LA CABEZA Y EL PECHO DEL DT (y~1.55), no al podio: la
	## primera versión apuntaba a y=1.35 -la altura del PODIO- y el DT, medio
	## metro más arriba, quedaba casi a oscuras contra una pared de sponsors
	## emisiva y mucho más brillante. Es la razón por la que en la primera
	## captura el DT se veía como una mancha oscura sin forma.
	## OJO CON LA ENERGÍA: a 8.0 la cabeza del DT salía quemada (como en el sorteo).
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

	## LOS PERIODISTAS (14-9-2026): sin luz propia eran invisibles; un relleno
	## tenue y frío para que se noten como siluetas, sin competir con el DT.
	var luz_publico := OmniLight3D.new()
	luz_publico.light_color = Color(0.55, 0.6, 0.7)
	luz_publico.light_energy = 1.1
	luz_publico.omni_range = 4.5
	luz_publico.position = Vector3(0, 3.2, 1.8)
	add_child(luz_publico)
	## La sala alrededor de la pared, algo menos negra (26-10).
	var sala := OmniLight3D.new()
	sala.light_color = Color(0.8, 0.82, 0.9)
	sala.light_energy = 0.9
	sala.omni_range = 6.0
	sala.position = Vector3(0, 2.6, -0.6)
	add_child(sala)
