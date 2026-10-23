extends Control
## (Parte 1 de 6 de `estadio.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `estadio.gd`, conserva la clase.)

## El estadio en 3D, dentro del propio juego.
##
## Hasta ahora el visor 3D era un programa aparte: el HTML exportaba un JSON, se
## abría otro proyecto de Godot y allí se veía el recinto. Aquí no hay puente ni
## fichero intermedio — el perfil lo produce el propio `Club` y la escena se
## construye en el momento.
##
## Esto es lo que Compatibility no podía dar. Corre en **Forward+**, que es lo
## único que trae oclusión ambiental, reflejos y niebla volumétrica; en
## Compatibility el estadio se ve plano y sin sombras suaves por mucho que se
## pidan. El proyecto entero está en Forward+ por esto, y la interfaz 2D se
## comporta exactamente igual (comprobado: Vulkan 1.3.237 sobre Intel UHD).

signal cerrado
## Lo pide el partido en vivo dirigido: al 45 se cierra para abrir el camarín.
var parar_en_descanso := false
var _descanso_hecho := false
## Eliminación directa (copa, cruces continentales): con el motor real, si
## acaba empatado hay prórroga y tanda de penales en el césped. Lo pone quien
## abre la vista (`PartidoVivo`), antes de `abrir()`.
var eliminatoria := false
var _marcador_tanda: MarcadorTanda

var _mini_pantalla: TextureRect
var club: Club
var visitante: Club
var _raiz3d: Node3D
var _rig: CameraRig
var _pie: Label
var _pie_base := ""
var _spawner: PlayerSpawner
## La camiseta del trío arbitral de este partido (también la del cuarto árbitro).
var _kit_arbitro: Dictionary = {}
var _en_campo: Array = []
## Los suplentes de pie junto al banquillo (22-9-2026, "efecto banquillo").
## Aparte de `_en_campo`: `MatchPlayback.tick()` solo mueve lo que hay en esa
## lista -la banca se queda quieta donde se paró, que es lo real- y no debe
## contarse como "en el campo" en ningún sitio que lea `_en_campo.size()`.
var _en_banca: Array = []
## La pantalla gigante del estadio (23-9-2026). El `SubViewport` se mantiene
## vivo mientras dure la vista -si se libera, su textura queda en negro- y se
## repinta solo: ver `ui/pantalla_estadio.gd`, que es quien decide qué enseña
## (marcador, estadísticas, goleadores, tabla) y cuándo rota.
var _pantalla: PantallaEstadio
## Lo que esta vista NO puede calcular sola porque no conoce el `Mundo`: la
## tabla de la liga, los máximos goleadores, el nombre del torneo y el del
## recinto. Se rellena desde fuera ANTES de `abrir()` -`principal.gd` y
## `partido_vivo.gd` sí tienen el mundo delante-. Vacío es válido: la pantalla
## simplemente se queda con los paneles que salen del propio `Partido`.
var datos_pantalla: Dictionary = {}
var partido: Partido
var _juego: MatchPlayback
var _btn_velocidad: Button
var _marcador: Label
var _balon: Node3D
var _control: ControlPartido
var _radar: RadarPartido
var _btn_modo: Button
## 3D DESTACADOS (25-9-2026, plan maestro B2): el partido corre a x4 y frena a
## velocidad normal en cada ocasión -remate o gol- durante `SEG_DESTACADO`
## segundos reales, para ver la jugada. La simulación es la misma: solo cambia
## a qué velocidad se mira.
var modo_destacados := false
const VEL_DESTACADOS_RAPIDO := 4
const VEL_DESTACADOS_JUGADA := 2
const SEG_DESTACADO := 6.0
var _destacado_hasta_ms := -1
var _btn_camara: Button
var _cajon: CajonAjustes
var _vineta: ColorRect
var _perfil: Dictionary = {}
var _banner: Label
var _banner_caja: PanelContainer
var _tween_banner: Tween
var _tween_marcador: Tween
var _caja_marcador: PanelContainer

## VARIEDAD DE GRADA (21-9-2026): hasta ahora este visor solo ponia "murmullo"
## una vez al abrir y lo dejaba en bucle todo el partido -sonido de fondo fijo,
## exactamente lo que el usuario ya habia descrito como "se siente generico".
## El catalogo de `Sonido` trae cantico/tambor/trompeta/aplauso/abucheo desde
## hace tiempo, sintetizados y probados, pero nunca sonaban en un partido real.
## RNG propio, no `Azar`: es puramente cosmetico (ver feedback-verification-
## discipline en memoria) y no debe correr el generador determinista del
## resultado del partido.
var _rng_ambiente := RandomNumberGenerator.new()
var _prox_ambiente := 0.0

## EL PARTIDO, JUGADO DE VERDAD (13-10-2026). Con el motor real encendido
## (`_pref("motor_real")`, por defecto sí) ya no hay jugadas con guion: los 22
## los mueve `MotorJugable`, el resultado sale del césped y el `Partido` solo
## lleva el reloj y el acta (`motor_externo`). La pizarra y los cambios que
## hace el DT -desde el panel de pausa o desde la pantalla 2D- cambian lo que
## pasa. Y con «Controlar a mi equipo» manejas a tus jugadores como en FC.
var _motor: MotorJugable
var _mi_lado := -1
var _acum_motor := 0.0
var _t_tactica := 0.0
var _cursor: Node3D
var _indicador: IndicadorFC
var _tiros_de := {}
var _goles_de := {}
var _ayuda_control: Label
var _panel_dt: PanelDTPartido
var _panel_controles: PanelControles
## Estadísticas a pedido y rótulos de la tele (16-10-2026).
var _stats: EstadisticasVivo
var _panel_stats: PanelEstadisticas
var _rotulos_hechos := {}
## Lo que el DT rival cambia en vivo (sin tocar la táctica guardada de su club).
var _ajuste_rival := [{}, {}]
var _final_motor := false
var _anadido_avisado := {}
var _nombres_globales := true
const DT_MOTOR := 1.0 / 60.0
## Segundos reales por minuto de partido con el motor real.
const SEG_POR_MINUTO := {"rapido": 4.0, "normal": 5.5, "largo": 7.5}

var _explorador: ExploradorEstadio
var _ocultos: Array = []

## `fixed_size` compensa la DISTANCIA, no el zoom: con "Tele Dinámica" (campo
## de visión estrecho) los nombres salían tres veces más grandes que con la de
## TV. Se reescalan con la tangente del campo de visión de la cámara activa,
## tomando la de TV (46°) como referencia. Solo cuando cambia el campo de visión.
var _fov_rotulos := -1.0

## RÓTULOS SIN AMONTONAR (MEGAPLAN fase 1): en las jugadas de área los
## nombres se pisaban. Cada décima de segundo se proyectan a la pantalla y, si
## dos se tocan, queda el del jugador más cerca del balón. El que ya se veía
## tiene ventaja (si no, parpadeaban al cruzarse dos jugadores).
var _t_despeje := 0.0

## La energía bajo cada nombre, una vez por minuto simulado.
var _minuto_barras := -1

## Preferencias de lo que se ve sobre la transmisión, en el mismo archivo que
## el resto de ajustes (`user://ajustes.cfg`, sección `hud`).
## PRÁCTICA LIBRE (M-130): sin ceremonia ni presentación, con el motor real.
var practica := false

## Dónde se sienta el DT sancionado: la grada de los banquillos, a la altura
## de su banquillo (estadio 2.0, fase 3).
static var butaca_sancion: Dictionary = {}
## El perfil del estadio que se está montando (para la butaca del sancionado).
static var perfil_actual: Dictionary = {}

## EL RÓTULO DE LA JUGADA (25-9-2026): como en la tele, cuando un equipo
## construye una jugada del catálogo aparece su nombre debajo del marcador
## ("▸ PARED FRONTAL 1-2"), con el color del equipo, y se va solo.
var _rotulo_jugada: PanelContainer
var _lbl_jugada: Label
var _tween_jugada: Tween

## Sonidos de grada sin evento puntual detras -el "ruido de fondo con vida"
## que faltaba-. Uno por bloque para no repetir siempre el mismo: percusion,
## instrumento suelto y reaccion humana (canto/aplauso/abucheo, este ultimo
## mas probable si el visitante ataca, nunca si el propio equipo va ganando
## comodo -no tiene sentido que la propia hinchada abuchee sin motivo).
const AMBIENTE_PERCUSION := ["tambor", "trompeta", "bengala"]
const AMBIENTE_REACCION := ["cantico", "aplauso"]


## LA OLA (20-10-2026, M-044): una vez por partido, como mucho, la grada da la
## vuelta al estadio. Con el partido decidido (dos goles o más) casi seguro
## pasada la hora; si no, alguna vez en un rato tranquilo del segundo tiempo.
var _ola_min := -1

## Cuánto se espera tras el gol antes de repetirlo: el remate, el balón en la
## red y el primer festejo se ven en vivo; después, la repetición.
const SEG_ANTES_REPETICION := 6.0
var _repe: Repeticion
var _intro: IntroPartido
var _ceremonia: CeremoniaPartido
var _ceremonia_pendiente := ""
var _rotulo_repe: PanelContainer

var _goles_autor := {}

## LA SALA VAR (26-9-2026): el partido se para, se ve la sala por dentro con
## los monitores mostrando la jugada desde cuatro cámaras, y se sigue.
var _sala_var: SalaVAR = null

var _btn_dificultad: Button


# --- la secuencia del gol (motor real) -------------------------------------

## LA REALIZACIÓN DEL GOL (13-10-2026, como en el vídeo de FC 26): el goleador
## corriendo a celebrar de cerca, corte al banquillo que salta, la grada, un
## barrido con el escudo y la repetición. Mientras, el motor alarga la
## celebración (`duracion_gol`) y el reloj no corre.
## La secuencia vive en `CineGol` (compartida con la Carrera de Jugador).
var _cine: CineGol
var _cine_t: float:
	get:
		return _cine.t if is_instance_valid(_cine) else -1.0


## LA BARRA DE POTENCIA Y LA FLECHA DE APUNTE (jugando tú, como en FC): al
## cargar un tiro o un balón parado, la barra abajo al centro; en córners y
## faltas, una flecha en el césped hacia donde apuntas.
var _barra_pot: ProgressBar
var _flecha_apunte: MeshInstance3D

## Se da tamaño a sí misma, en vez de fiarlo a las anclas.
##
## Un Control solo hereda el rectángulo de su padre si el padre es otro Control.
## Colgada de un `Node` normal -como en las pruebas de captura- se queda en 0×0
## para siempre, y entonces cualquier ancla en fracciones apunta al mismo sitio:
## el marcador "centrado" al 0,5 acababa pegado al borde izquierdo, encima de los
## botones de cámara. Los botones sí salían bien porque van con offsets absolutos
## desde la esquina, que con tamaño cero siguen valiendo.
func _ajustar_a_pantalla() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size

func _pref(k: String, por_defecto: bool) -> bool:
	if practica and k in ["intro", "ceremonia"]:
		return false
	if practica and k == "motor_real":
		return true
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return por_defecto
	return bool(cfg.get_value(CajonAjustes.SECCION, k, por_defecto))

## LA PANTALLA GIGANTE. Busca las mallas que `StadiumBuilder._pantallas()` dejó
## marcadas como "PantallaMarcador" -puede haber una, dos (tipo "dos") o hasta
## tres ("todo", con el cubo suspendido)- y les reemplaza la textura estática
## por la del `SubViewport` de `PantallaEstadio`. Un solo `SubViewport` para
## todas: las dos/tres muestran lo mismo, como en un estadio real.
##
## REHECHA EL 23-9-2026 con el video de referencia del usuario delante. Antes
## era un `Label` "0 - 0" más el nombre completo de los clubes, que se salía
## del lienzo (bug documentado en `LEEME.md`). Ahora todo el diseño y la
## rotación de paneles viven en `ui/pantalla_estadio.gd`; aquí solo queda
## engancharla al 3D y darle los datos.
func _montar_pantalla() -> void:
	var pantallas := _raiz3d.find_children("PantallaMarcador*", "MeshInstance3D", true, false)
	if pantallas.is_empty() or club == null:
		return
	_pantalla = PantallaEstadio.new()
	add_child(_pantalla)
	var recinto := String(datos_pantalla.get("recinto", ""))
	if recinto == "":
		recinto = club.estadio_nombre
	_pantalla.montar(club, visitante, partido, datos_pantalla, recinto)

	var tex := _pantalla.get_texture()
	if _mini_pantalla != null:
		_mini_pantalla.texture = tex
		_mini_pantalla.visible = _pref("pantalla_esquina", true)
	for p: MeshInstance3D in pantallas:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.emission_enabled = true
		mat.emission_texture = tex
		## Mismo brillo que ya se ajustó el 22-9 contra el bloom del
		## post-procesado: más alto quema el contenido, más bajo no se lee
		## "encendida" desde la cancha.
		mat.emission_energy_multiplier = 1.1
		p.material_override = mat

## Los primeros 7 disponibles, de pie; del 8 al 12, sentados en el banco
## simple de al lado (22-9-2026, "que los que no caben estén sentados").
func _poner_banca_de(c: Club, once_c: Array[Jugador], es_local: bool) -> void:
	_en_banca.append_array(VistaEstadio.poner_banca_de(_raiz3d, _spawner, c, once_c, es_local))

## Sentado DE VERDAD en la butaca (21-10-2026): la butaca da el suelo del
## escalón y la animación de sentado espera el origen en el suelo con la silla
## a ~0,45 m: se baja la cadera hasta el asiento (la misma cuenta que los bancos
## del metro). Antes, el DT sancionado y la directiva flotaban medio metro.
static func _a_la_butaca(n: Node3D) -> void:
	var cadera := MetroCiudad.altura_cadera(n)
	if cadera > 0.0:
		n.position.y += MetroCiudad.BANCO_ASIENTO + 0.08 - cadera * 0.99

## LA DIRECTIVA EN SU SITIO (21-10-2026, M-040): el presidente y dos directivos
## del club de casa, de traje, sentados en la segunda fila de la tribuna
## principal a la altura del medio campo (el palco). Con el mismo modelo y la
## misma animación de sentado que el DT sancionado; caras fijas por club.
static func poner_directiva(raiz: Node3D, c: Club, perfil: Dictionary) -> Array:
	var gente: Array = []
	if c == null or perfil.is_empty():
		return gente
	var trajes := ["15171c", "2b2f3a", "3a3328"]
	for k in 3:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("directiva_%s_%d" % [c.id, k])
		var asp := PersonajeDT.aleatorio(rng)
		asp.merge({"cuerpo": "male", "ropa": "traje", "c_ropa": trajes[k], "c_ropa2": "f2f2f2", "corbata": true,
			"gorra": false, "bufanda": k == 2, "auriculares": false, "pendiente": false, "cadena": false,
			"manga_corta": false, "tatuaje": 0, "pelo": ["corto", "rapado", "corto", "calvo"][rng.randi() % 4]}, true)
		if k == 0:
			## El presidente: canas.
			asp["color_pelo"] = ["9b9b98", "c8c8c4", "6e6a66"][rng.randi() % 3]
		var b := RecorridoClub.butaca(perfil, 1.0, (float(k) - 1.0) * 1.15, 2, raiz)
		var d := PersonajeDT.crear(raiz, asp, Color(c.color1), Color(c.color2))
		if d.is_empty():
			continue
		var n: Node3D = d["nodo"]
		n.name = "Directiva_%d" % k
		n.position = b["pos"]
		n.rotation.y = float(b["rumbo"])
		_a_la_butaca(n)
		## Zapatos de vestir (sin ellos, sentados se les veían los pies descalzos).
		PeatonQ.calzar(d, "1c1c1e")
		var ap: AnimationPlayer = d.get("anim") as AnimationPlayer
		if ap != null and ap.has_animation("sentado"):
			ap.play("sentado")
			ap.seek(rng.randf() * 0.6, true)
		RecorridoClub.despejar_hinchas(raiz, raiz.global_position + (b["pos"] as Vector3) + Vector3(0, 0.5, 0), 0.5)
		gente.append(n)
	return gente

## LA BANDA YA NO ESTÁ VACÍA (22-9-2026). Hasta hoy solo se veían los 22 +
## árbitros: ni un suplente, aunque el club tenga 20+ jugadores citables. La
## "banca visual" es una muestra -los mejores disponibles que no están en el
## once, hasta 7-, no la lista real de quién puede entrar (`Partido.cambiar()`
## acepta cualquier jugador disponible de la plantilla entera, no solo estos
## 7): esto es solo lo que se VE de pie junto al banquillo, no una regla
## nueva de convocatoria.
func _poner_banca(once_local: Array[Jugador], once_visita: Array[Jugador]) -> void:
	_en_banca.clear()
	if club == null or visitante == null:
		return
	_poner_banca_de(club, once_local, true)
	_poner_banca_de(visitante, once_visita, false)
	if partido != null:
		poner_directiva(_raiz3d, club, _perfil)

## EL ENTRENADOR EN LA BANDA (26-9-2026): tu personaje del creador en el
## área técnica de tu club, y un DT rival (siempre el mismo por club) en la
## otra. Delante de su fila de suplentes, del lado del centro del campo.
## CAMARÓGRAFOS Y GUARDIAS DE VERDAD (26-9-2026). El constructor deja a cada
## operador como un maniquí de cajas con su cámara; aquí se oculta el maniquí
## y se pone una persona entera detrás de la cámara. Y seis guardias de
## seguridad detrás de las vallas, de espaldas al juego, mirando a la grada.
func _poner_personal() -> void:
	var sig := VistaEstadio.poner_personal(_raiz3d)
	if sig != null:
		sig.balon = _balon

## Documento de arquitectura: maniquíes residuales en (0,0,0) se leían como
## "el gigante" en el centro del campo. No se toca a los 22 ni al balón.
func _purgar_nodos_fantasma() -> void:
	if _raiz3d == null:
		return
	var vivos: Dictionary = {}
	for p in _en_campo:
		var n = p.get("node")
		if is_instance_valid(n):
			vivos[n] = true
	for nodo in _raiz3d.get_children():
		if nodo == _balon or nodo == _rig:
			continue
		if vivos.has(nodo):
			continue
		if nodo is CharacterBody3D and nodo.global_position.length() < 0.35:
			push_warning("[LIMPIEZA] Eliminado nodo fantasma residual: %s" % nodo.name)
			nodo.queue_free()
		elif nodo is MeshInstance3D and String(nodo.name).to_lower().contains("dummy"):
			nodo.queue_free()

## Saca a los 22 al campo, cada uno en su ranura de la formación y con la
## equipación de su club.
##
## Los datos van por `Puente3D`, que traduce mis objetos `Jugador` y `Club` a los
## diccionarios que espera el equipador. Ese código viene del visor que era un
## programa aparte y ya está depurado -el atlas de texturas, el re-teñido, el
## escalado del esqueleto Mixamo-, así que se adapta en la frontera en vez de
## reescribirlo.
func _sacar_los_22() -> void:
	_spawner = PlayerSpawner.new()
	_en_campo.clear()
	## Si hay partido, salen los onces DEL PARTIDO, no los que devolvería el club
	## ahora mismo. No son lo mismo en cuanto entra el primer cambio: `club.once()`
	## volvería a armar el equipo desde cero y en el campo aparecería el titular
	## que acaba de salir.
	var once_local := partido.once_local if partido != null else club.once()
	var once_visita := partido.once_visita if partido != null else visitante.once()
	var l := Puente3D.once(once_local)
	var v := Puente3D.once(once_visita)
	## El local ataca hacia un lado y el visitante hacia el otro: `spawn_team` lo
	## resuelve con `es_local`, que además le da la vuelta al jugador.
	var kit_l := Puente3D.kit(club)
	var kit_v := Puente3D.kit_visita(club, visitante)
	var por_l := Puente3D.kit_portero(club)
	var por_v := Puente3D.kit_portero(visitante)
	_en_campo.append_array(_spawner.spawn_team(_raiz3d, l["xi"], l["jugadores"],
		Puente3D.formacion(club.tactica.formacion), true, kit_l, por_l))
	_en_campo.append_array(_spawner.spawn_team(_raiz3d, v["xi"], v["jugadores"],
		Puente3D.formacion(visitante.tactica.formacion), false, kit_v, por_v))
	## El trío de la camiseta que mejor se distingue de los dos (M-072).
	_kit_arbitro = Puente3D.kit_arbitro(kit_l, kit_v, hash(club.id + "|" + visitante.id), [por_l, por_v])
	_en_campo.append_array(_spawner.spawn_arbitros(_raiz3d, _kit_arbitro))
	_poner_banca(once_local, once_visita)
	_poner_personal()
	_purgar_nodos_fantasma()

func _rotar_camara() -> void:
	if _rig != null:
		_rig.cycle()
		if _btn_camara != null:
			_btn_camara.text = Idiomas.t("📷 Cámara: ") + _rig.current_name()
		if _pie != null:
			_pie.text = _pie_base + Idiomas.t("  ·  cámara: ") + _rig.current_name()

func _dejar_de_recorrer() -> void:
	if _explorador == null:
		return
	_explorador.queue_free()
	_explorador = null
	for c in _ocultos:
		if is_instance_valid(c):
			(c as CanvasItem).visible = true
	_ocultos = []
	if _rig != null:
		_rig.set_process(true)
		_rig.set_process_unhandled_input(true)
		_rig.switch_to(_rig.current_index)
