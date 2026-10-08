class_name Calidad
extends RefCounted

## Ajustes graficos del visor, en un solo sitio.
##
## POR QUE EXISTE
## El proyecto arrancó en `gl_compatibility`, que es el modo mas basico de Godot:
## sin oclusion ambiental, sin reflejos, sin niebla volumetrica y con un mapeado
## de tonos plano. Con eso la ciudad se veia como una maqueta de plastico por
## mucho que se le anadieran edificios. Se comprobo que esta maquina SI arranca
## **Vulkan 1.3 en Forward+** (Intel UHD, sin GPU dedicada), asi que se pasa a
## ese modo y se enciende lo que de verdad cambia la imagen.
##
## EL EQUILIBRIO HONESTO
## Forward+ con todo encendido a 4K en una Intel UHD **no va a 60 fps**, y decir
## lo contrario seria mentir. Por eso hay tres niveles: ULTRA para las capturas
## (da igual que un fotograma tarde segundos), ALTO para una pantalla grande, y
## MEDIO para jugar con soltura. El nivel se puede forzar por linea de ordenes.

enum { MEDIO, ALTO, ULTRA }

## EL NIVEL QUE HA ELEGIDO EL JUGADOR en Ajustes. Vive aqui y no en la pantalla
## de ajustes porque quien lo necesita es el visor 3D, que se monta desde otro
## sitio y no conoce la interfaz. Es de la MAQUINA, no de la partida: no va al
## guardado, igual que el zoom.
## OPTIMIZACION (21-9-2026), a pedido explicito del usuario ("mucho mas rapido
## y ligero sin perder la calidad", despues "quiero ALTO con minimo ~50 FPS
## en un equipo modesto, 8GB RAM DDR3"): primer intento bajo el default a
## MEDIO, pero eso SI pierde calidad (sin SSAO ni glow). Segundo intento,
## el bueno: ALTO se aligero por dentro (sombra 600m/4096 -> 420m/2048, MSAA
## x4 -> x2 -ver `sol()`/`aplicar_viewport()` mas abajo-) en vez de bajar de
## nivel. Medido con `pruebas/medir_rendimiento.gd` antes/despues, ver LEEME.md.
static var elegida: int = ALTO
## Bajar efectos durante el partido si los FPS caen de 40 (ver
## `RendimientoAdaptativo`). Encendido por defecto; se apaga en Ajustes.
static var adaptativa: bool = true

## Hora del dia. El atardecer es el que mejor sienta a un complejo deportivo:
## luz rasante, sombras largas y contraste, que es lo que hace que un render
## parezca una foto en vez de un dibujo tecnico.
enum { DIA, TARDE, NOCHE }

static func nivel_de_argumentos(por_defecto: int = ALTO) -> int:
	for a in OS.get_cmdline_user_args():
		match str(a).to_lower():
			"ultra": return ULTRA
			"alto": return ALTO
			"medio": return MEDIO
	return por_defecto

# --------------------------------------------------------------------- cielo

static func _cielo(momento: int) -> Sky:
	var cielo := Sky.new()
	var m := ProceduralSkyMaterial.new()
	match momento:
		NOCHE:
			m.sky_top_color = Color(0.02, 0.03, 0.08)
			m.sky_horizon_color = Color(0.09, 0.11, 0.18)
			m.ground_bottom_color = Color(0.02, 0.02, 0.03)
			m.ground_horizon_color = Color(0.07, 0.08, 0.12)
			m.sun_angle_max = 4.0
		TARDE:
			m.sky_top_color = Color(0.16, 0.30, 0.62)
			m.sky_horizon_color = Color(0.95, 0.68, 0.42)
			## El "suelo" del cielo tiene que casar con el horizonte o aparece una
			## banda oscura cortando la escena. Al atardecer hay que subirlo mucho:
			## con 0.14 salia una franja negra bajo el sol.
			m.ground_bottom_color = Color(0.42, 0.34, 0.30)
			m.ground_horizon_color = Color(0.88, 0.66, 0.48)
			m.sun_angle_max = 22.0
			m.sun_curve = 0.09
		_:
			m.sky_top_color = Color(0.22, 0.44, 0.80)
			m.sky_horizon_color = Color(0.80, 0.88, 0.95)
			m.ground_bottom_color = Color(0.32, 0.36, 0.32)
			m.ground_horizon_color = Color(0.72, 0.78, 0.82)
			m.sun_angle_max = 14.0
			m.sun_curve = 0.15
	m.energy_multiplier = 1.0
	cielo.sky_material = m
	## El cielo tambien ILUMINA la escena (luz ambiental), asi que su resolucion
	## importa: con la de por defecto las sombras suaves salen a manchas.
	cielo.radiance_size = Sky.RADIANCE_SIZE_128 if momento != NOCHE else Sky.RADIANCE_SIZE_64
	return cielo

# --------------------------------------------------------------------- entorno

## Monta el WorldEnvironment con todo lo que el nivel permita.
static func entorno(nivel: int, momento: int = TARDE) -> WorldEnvironment:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = _cielo(momento)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.0 if momento != NOCHE else 0.45

	## Reflejos del cielo en los materiales. Es lo que hace que el asfalto mojado
	## y los cristales dejen de parecer carton pintado.
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	## MAPEADO DE TONOS. Lo mas barato y lo que mas cambia: sin esto los colores
	## se saturan y se aplastan en las luces, y todo parece plastico.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	## Al atardecer el sol esta bajo y la escena se apaga: hace falta abrir un
	## punto o todo queda en penumbra parda.
	env.tonemap_exposure = 1.25 if momento == TARDE else (1.0 if momento == DIA else 1.4)
	env.tonemap_white = 6.0

	## Oclusion ambiental: la suciedad de contacto en las esquinas y bajo los
	## edificios. Es lo que los asienta en el suelo en vez de dejarlos flotando.
	if nivel >= ALTO:
		env.ssao_enabled = true
		env.ssao_radius = 3.0
		env.ssao_intensity = 2.6
		env.ssao_power = 1.6
		env.ssao_detail = 0.6
		env.ssao_horizon = 0.08

	if nivel >= ULTRA:
		## SDFGI: LA PIEZA GRANDE DE FORWARD+ QUE FALTABA POR ENCENDER
		## (13-9-2026). SSIL de arriba solo rebota lo que la CÁMARA ve en
		## pantalla -si la fachada que tiñe de verde el césped queda fuera de
		## cuadro, no rebota nada-. SDFGI construye una escena voxelizada de
		## verdad detrás de cámara, así que la luz rebota aunque la fuente o
		## la superficie iluminada estén fuera de la vista -la sombra bajo una
		## marquesina se ilumina con el cielo que le entra de lado, un
		## interior nunca queda negro solo porque la ventana no se vea-. Es
		## caro -por eso solo en ULTRA, igual que SSIL/SSR/niebla volumétrica-.
		## VALORES CORREGIDOS TRAS UNA SOBREEXPOSICIÓN REAL: el primer intento
		## (energy 1,2, bounce_feedback 0,5) dejó la ciudad entera BLANCA -no
		## sutil, la pantalla casi entera quemada-, confirmado comparando el
		## mismo fotograma con SDFGI encendido y apagado
		## (`pruebas/captura_sdfgi.gd`). Es el "runaway" clásico de SDFGI: con
		## tantas fachadas y pavimento CLAROS en esta ciudad, cada rebote
		## amplifica el anterior, y con `bounce_feedback` alto eso se
		## realimenta hasta saturar. Con 0,55 de energía y 0,1 de feedback -
		## rebote sutil, sin bucle- la imagen vuelve a verse como sin SDFGI,
		## solo con las sombras y esquinas algo menos negras.
		env.sdfgi_enabled = true
		env.sdfgi_cascades = 6
		env.sdfgi_min_cell_size = 0.25
		env.sdfgi_use_occlusion = true
		env.sdfgi_bounce_feedback = 0.1
		## FALSO: no hacía falta que SDFGI TAMBIÉN leyera el cielo. El entorno
		## ya manda ambiente del cielo por su cuenta (`ambient_light_source =
		## AMBIENT_SOURCE_SKY`, más arriba): con las dos vías sumadas, una
		## azotea plana que ve medio cielo despejado se contaba DOS VECES -esa
		## era la sobreexposición real, no bajaba ni tras 220 fotogramas de
		## convergencia-. Apagado aquí, SDFGI solo aporta el rebote entre
		## superficies, que es lo que de verdad faltaba.
		env.sdfgi_read_sky_light = false
		env.sdfgi_energy = 0.55
		## Rebote indirecto de la luz: el color del cesped tiñe las fachadas.
		env.ssil_enabled = true
		env.ssil_intensity = 0.9
		env.ssil_radius = 6.0
		## Reflejos en pantalla para el asfalto y los cristales.
		env.ssr_enabled = true
		env.ssr_max_steps = 48
		env.ssr_fade_in = 0.2
		env.ssr_fade_out = 3.0

	## Resplandor de las luces fuertes (focos, sol, ventanas encendidas).
	if nivel >= ALTO:
		env.glow_enabled = true
		env.glow_intensity = 0.55 if momento != NOCHE else 1.1
		env.glow_bloom = 0.12
		env.glow_hdr_threshold = 1.05
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	## Niebla volumetrica: da cuerpo al aire y separa los planos. Con luz rasante
	## es lo que crea los rayos entre las torres de focos.
	if nivel >= ULTRA:
		env.volumetric_fog_enabled = true
		## 0.006 ahogaba la escena entera en bruma naranja: a 300 m de complejo la
		## niebla se comia edificios, cesped y estadio. Tiene que NOTARSE apenas.
		env.volumetric_fog_density = 0.0011
		env.volumetric_fog_albedo = Color(0.90, 0.91, 0.94)
		env.volumetric_fog_length = 220.0
		env.volumetric_fog_gi_inject = 0.35
	else:
		env.fog_enabled = true
		env.fog_light_color = Color(0.78, 0.80, 0.84)
		env.fog_density = 0.00035
		env.fog_sky_affect = 0.0

	## Ajuste fino de color. Poco, pero quita el gris lechoso.
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.08

	we.environment = env
	return we

# ---------------------------------------------------------------------- sol

## Luz principal. `momento` decide la inclinacion y el color; a mas nivel, mas
## cascadas de sombra (mas nitidas de cerca sin perder las lejanas).
static func sol(nivel: int, momento: int = TARDE) -> DirectionalLight3D:
	var luz := DirectionalLight3D.new()
	match momento:
		NOCHE:
			luz.rotation_degrees = Vector3(-62, -30, 0)
			luz.light_color = Color(0.62, 0.70, 0.92)
			luz.light_energy = 0.30
		TARDE:
			## 14 grados sobre el horizonte: sombras largas, que es lo que da
			## sensacion de volumen. Con el sol a plomo todo se ve plano.
			luz.rotation_degrees = Vector3(-14, -42, 0)
			luz.light_color = Color(1.0, 0.86, 0.68)
			luz.light_energy = 1.5
		_:
			luz.rotation_degrees = Vector3(-48, -38, 0)
			luz.light_color = Color(1.0, 0.97, 0.92)
			luz.light_energy = 1.25
	luz.shadow_enabled = true
	## Sombras suaves de verdad: `angular_distance` es el tamano aparente del sol,
	## y es lo que hace que la sombra se vaya abriendo con la distancia al objeto,
	## como en la realidad. Con 0 salen recortadas con tijera.
	luz.light_angular_distance = 0.6
	luz.shadow_blur = 1.0
	## AJUSTE (21-9-2026), a pedido del usuario -hardware modesto, 8GB RAM
	## DDR3-: 4 cortes se mantienen en ALTO (la calidad de sombra SI se nota),
	## pero la distancia baja de 600 a 420m -sombra nitida donde de verdad se
	## juega, no hasta el fondo de una tribuna que la camara raras veces
	## encuadra entera-. Medido con `pruebas/medir_rendimiento.gd`, ver LEEME.md.
	luz.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if nivel >= ALTO \
		else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	luz.directional_shadow_max_distance = 420.0 if nivel >= ALTO else 320.0
	luz.directional_shadow_split_1 = 0.06
	luz.directional_shadow_split_2 = 0.16
	luz.directional_shadow_split_3 = 0.42
	luz.directional_shadow_fade_start = 0.85
	luz.shadow_normal_bias = 1.4
	return luz

# ------------------------------------------------------------------ viewport

## ¿Renderizador de compatibilidad (OpenGL: móvil, web, capturas)?
static func es_compatibilidad() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"

## Ajustes del propio viewport: suavizado de bordes y filtrado de texturas. Sin
## esto, a 4K se ven los dientes de sierra de cada farola.
static func aplicar_viewport(vp: Viewport, nivel: int) -> void:
	if vp == null:
		return
	## AJUSTE (21-9-2026), mismo pedido -equipo modesto-: MSAA x4 costaba 4
	## veces el ancho de banda de framebuffer de x2 para una diferencia que
	## casi no se nota en el angulo de camara tipico de un partido (no es un
	## FPS en primera persona donde cada borde se ve de cerca). Bajado a x2 en
	## ALTO, x4 se guarda para ULTRA (capturas, donde SI importa el detalle).
	## FXAA y TAA solo existen en Forward+/Mobile: en compatibilidad (móvil,
	## web) el motor avisaba en cada pantalla 3D y no hacía nada.
	var avanzado := not es_compatibilidad()
	if nivel >= ULTRA:
		vp.msaa_3d = Viewport.MSAA_8X
		if avanzado:
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			vp.use_taa = true
	elif nivel >= ALTO:
		vp.msaa_3d = Viewport.MSAA_2X
		if avanzado:
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	else:
		vp.msaa_3d = Viewport.MSAA_2X
	vp.use_debanding = true
	## Atlas de sombra: 4096 a 2048 en ALTO -un cuarto de la memoria/ancho de
	## banda-, mismo criterio que el MSAA de arriba. 8192 se guarda para ULTRA.
	if nivel >= ULTRA:
		RenderingServer.directional_shadow_atlas_set_size(8192, true)
	elif nivel >= ALTO:
		RenderingServer.directional_shadow_atlas_set_size(2048, true)
