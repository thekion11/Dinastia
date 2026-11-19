class_name Ambience
extends RefCounted

## Ambiente del partido = la hora/atmosfera que el usuario eligio para SU estadio
## (EST_CLIMAS en el juego: dia/tarde/noche/lluvia/nieve/niebla/tormenta) combinada
## con el clima REAL que tuvo ese partido concreto (CLIMAS en el juego: despejado,
## nublado, lluvia, tormenta, viento, calor, frio, niebla). Son cosas distintas:
## una es la hora del dia, la otra es el tiempo que hizo.

const AMBIENTES := {
	"dia":      {"top": "#7fb6d9", "hor": "#cfe4ef", "oscuro": 0.0},
	"tarde":    {"top": "#e08a4a", "hor": "#f6cf9a", "oscuro": 0.35},
	"noche":    {"top": "#0a1420", "hor": "#132436", "oscuro": 1.0},
	"lluvia":   {"top": "#3f4d57", "hor": "#66757f", "oscuro": 0.6},
	"nieve":    {"top": "#8a97a3", "hor": "#d7e2ea", "oscuro": 0.35},
	"niebla":   {"top": "#6e7a78", "hor": "#9fa9a6", "oscuro": 0.45},
	"tormenta": {"top": "#232c36", "hor": "#3c4b58", "oscuro": 0.9},
}

## Cuanto ensombrece cada clima de partido, y cuanta niebla mete
const CLIMA_PARTIDO := {
	"despejado": {"oscuro": 0.0,  "niebla": 0.0},
	"nublado":   {"oscuro": 0.18, "niebla": 0.05},
	"lluvia":    {"oscuro": 0.42, "niebla": 0.30},
	"tormenta":  {"oscuro": 0.62, "niebla": 0.40},
	"viento":    {"oscuro": 0.08, "niebla": 0.05},
	"calor":     {"oscuro": 0.0,  "niebla": 0.10},
	"frio":      {"oscuro": 0.20, "niebla": 0.18},
	## `Mundo.clima()` lo escribe con tilde: sin esta fila el frío salía «despejado».
	"frío":      {"oscuro": 0.20, "niebla": 0.18},
	"niebla":    {"oscuro": 0.30, "niebla": 0.75},
}

const _RUTA_STADIUM_BUILDER := "res://visor/stadium_builder.gd"


## `nivel`: el mismo `Calidad.MINIMO/MEDIO/ALTO/ULTRA` que ya respeta `ciudad_vista.gd`.
## HASTA AHORA EL PARTIDO IGNORABA POR COMPLETO EL AJUSTE DE CALIDAD -a
## diferencia de la ciudad, que sí lo mira (`ciudad_vista.gd:78`)-: la oclusión
## ambiental y las sombras en 4 cascadas salían encendidas siempre, aunque el
## jugador hubiera elegido "Medio" en Ajustes para tener soltura. En una Intel
## UHD sin GPU dedicada esas dos cosas son las más caras de Forward+ (el propio
## `Calidad.gd` las reserva para ALTO+ en la ciudad), y el partido -22 jugadores
## animados, balón, cámaras siguiendo la acción- es la escena más pesada de las
## dos. Con esto "Medio" en Ajustes por fin alivia también el partido, no solo
## la ciudad.
static func apply(root: Node3D, est: Dictionary, clima_partido, nivel: int = Calidad.ALTO) -> void:
	var amb_key := str(est.get("clima", "dia"))
	## AMBIENTE=noche (o dia, tarde…): fuerza el ambiente del estadio, solo para capturas y comparaciones (16-11, frente 2).
	if OS.get_environment("AMBIENTE") != "":
		amb_key = OS.get_environment("AMBIENTE")
	var amb: Dictionary = AMBIENTES.get(amb_key, AMBIENTES["dia"])

	var clima_key := "despejado"
	if typeof(clima_partido) == TYPE_ARRAY and clima_partido.size() > 0:
		clima_key = str(clima_partido[0])
	var cp: Dictionary = CLIMA_PARTIDO.get(clima_key, CLIMA_PARTIDO["despejado"])

	var oscuro: float = clampf(float(amb["oscuro"]) + float(cp["oscuro"]) * 0.6, 0.0, 1.0)
	load(_RUTA_STADIUM_BUILDER).encender_conos(oscuro)
	var niebla: float = float(cp["niebla"])

	var top := Color(str(amb["top"])).darkened(float(cp["oscuro"]) * 0.5)
	var hor := Color(str(amb["hor"])).darkened(float(cp["oscuro"]) * 0.5)

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = top
	sm.sky_horizon_color = hor
	sm.ground_bottom_color = Color(0.10, 0.11, 0.13)
	sm.ground_horizon_color = hor.darkened(0.35)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	## LUZ DE DÍA SUAVE (16-11, referencia de FC Mobile): más luz del cielo de día (las sombras no se van a negro); de noche, igual que antes.
	env.ambient_light_energy = lerpf(1.35, 1.0, oscuro)
	env.glow_enabled = ModoRendimiento.glow(nivel)   ## (4-11) MÍNIMO: sin resplandor (pasada de pantalla completa)
	env.glow_intensity = 0.5 + oscuro * 0.5
	## EL UMBRAL, QUE FALTABA (23-9-2026). Se quedaba en 1.0, o sea que
	## cualquier blanco puro entraba entero al bloom -incluidas las rayas de cal
	## del campo, que además estaban en "no iluminado" y por tanto se mantenían
	## en 1.0 de noche: se leían como neón-. `calidad.gd` ya sube este mismo
	## umbral a 1,05 para la ciudad; el partido se había quedado sin él.
	env.glow_hdr_threshold = 1.05
	if niebla > 0.01:
		env.fog_enabled = true
		env.fog_light_color = hor
		env.fog_density = niebla * 0.012
	## Todo lo que trae Forward+ y antes no se podia usar (el proyecto estaba en
	## gl_compatibility): mapeado de tonos ACES, oclusion ambiental de contacto y
	## reflejos del cielo. Es lo que separa un cesped "verde plano" de uno con
	## volumen, y lo que asienta a los jugadores en el suelo en vez de dejarlos
	## flotando sobre su sombra.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = lerpf(1.05, 1.35, oscuro)
	env.tonemap_white = 6.0
	_tono_de_prueba(env)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY if nivel > Calidad.MINIMO else Environment.REFLECTION_SOURCE_DISABLED   ## (4-11) MÍNIMO: sin reflejos del cielo también aquí (se los devolvía el ambiente)
	if nivel >= Calidad.ALTO:
		env.ssao_enabled = true
		env.ssao_radius = 1.4
		env.ssao_intensity = 2.2
		env.ssao_power = 1.5
	env.adjustment_enabled = ModoRendimiento.ajuste_color(nivel)
	env.adjustment_contrast = 1.05
	env.adjustment_saturation = 1.06
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	print_verbose("AMB ambiente=%s clima=%s oscuro=%.2f cielo_top=%s" % [amb_key, clima_key, oscuro, top])

	# Luz principal: sol de dia, luna floja de noche.
	var key := DirectionalLight3D.new()
	## (16-11, frente 2) De día el sol de tarde de la tele: más bajo (36°) y casi de costado al campo, así la tribuna
	## de enfrente echa su sombra sobre una franja del césped como en PES 2020/FC. De noche, la luna de siempre.
	key.rotation_degrees = Vector3(lerpf(-36.0, -40.0, oscuro), lerpf(-75.0, -35.0, oscuro), 0)
	key.light_energy = lerpf(1.35, 0.25, oscuro)
	key.light_color = Color(1.0, 0.97, 0.90).lerp(Color(0.65, 0.72, 0.95), oscuro)
	key.shadow_enabled = Calidad.sombra_solar(nivel)   ## MÍNIMO: sin la pasada de sombras (~1/4 de las llamadas del partido)
	## Sombras suaves de verdad: el tamano aparente del sol hace que la sombra se
	## abra con la distancia, como en la realidad. Sin esto salen recortadas.
	key.light_angular_distance = 1.2   ## (16-11) antes 0,5: la penumbra de la tribuna sobre el césped se abre más (borde suave); sin coste extra
	key.shadow_blur = 1.0
	## (16-11) Sombras menos negras (también la de la tribuna sobre el césped, que se queda pero más suave). Sin coste: solo cambia
	## cuánto oscurece la sombra, no la pasada de sombras.
	key.shadow_opacity = lerpf(0.72, 1.0, oscuro)
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if nivel >= Calidad.ALTO \
		else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	key.directional_shadow_max_distance = 260.0 if nivel >= Calidad.ALTO else 160.0
	key.directional_shadow_split_1 = 0.05
	key.directional_shadow_split_2 = 0.15
	key.shadow_normal_bias = 1.2
	root.add_child(key)

	# De noche, los focos del estadio: una segunda direccional cenital y suave
	# (mucho mas barata en grafica integrada que cuatro focos con sombra).
	if oscuro > 0.45 and str(est.get("focos", "torres")) != "sin":
		var fill := DirectionalLight3D.new()
		fill.rotation_degrees = Vector3(-78, 130, 0)
		fill.light_energy = 0.40 + oscuro * 0.35
		## B6.1: del color que se eligió para los focos.
		fill.light_color = load(_RUTA_STADIUM_BUILDER).color_luz(est)
		fill.shadow_enabled = false
		## Sin brillo especular: es una luz de RELLENO. Casi vertical, su
		## reflejo caía en el centro del campo y era media causa de la
		## "columna misteriosa" (ver `StadiumBuilder.build_pitch()`).
		fill.light_specular = 0.0
		root.add_child(fill)

## MAPEO DE TONOS A ELEGIR (16-11, frente 2): el juego sigue con ACES; `TONO=agx` o `TONO=aces_bajo` (ACES con 15 %
## menos de exposición) solo existen para que el dueño compare capturas y decida (ACES lava las pieles claras muy
## iluminadas y satura los medios). No es una opción del juego todavía.
static func _tono_de_prueba(env: Environment) -> void:
	match OS.get_environment("TONO"):
		"agx":
			env.tonemap_mode = Environment.TONE_MAPPER_AGX
			env.tonemap_white = 16.0
		"aces_bajo":
			env.tonemap_exposure *= 0.85
