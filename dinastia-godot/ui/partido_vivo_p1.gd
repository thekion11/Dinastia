extends Control
## (Parte 1 de 3 de `partido_vivo.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `partido_vivo.gd`, conserva la clase.)

## El partido, en directo y con el entrenador dentro.
##
## Es la pantalla donde el juego deja de ser una hoja de cálculo. No simula nada:
## le pide un minuto al `Partido` cada tantos milisegundos y pinta lo que las
## señales le van contando. El mismo `Partido` que corre aquí es el que corre en
## el banco de pruebas headless a 8.000 partidos por segundo; lo único que cambia
## es que aquí hay alguien mirando.
##
## Lo que puede hacer el entrenador mientras corre el reloj -mover las perillas y
## meter cambios- se aplica al momento, porque `Partido.cambiar()` invalida la
## fuerza cacheada de los onces. Si no se notara en el marcador, sería un menú
## decorativo, que es el error que este proyecto ya ha pagado varias veces.

signal cerrado

## La misma paleta que css/estilo.css (`:root`), no una propia de Godot.
const COL_FONDO := Tema.FONDO
const COL_PANEL := Tema.PANEL
const COL_BORDE := Tema.BORDE
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE
const COL_ACENTO := Tema.ACENTO
const COL_VERDE := Tema.BIEN
const COL_ROJO := Tema.MAL
const COL_ORO := Tema.ORO

## Milisegundos por minuto de juego en cada velocidad. La pausa es la primera
## porque es la que más se usa: es cuando se piensa el cambio.
const VELOCIDADES := [
	{"txt": "Pausa", "ms": 0.0},
	{"txt": "Lento", "ms": 600.0},
	{"txt": "Normal", "ms": 250.0},
	{"txt": "Rápido", "ms": 80.0},
]

var partido: Partido
var mi_club: Club
## Cómo se mira este partido (plan maestro B2). Se fijan ANTES de `abrir()`.
var con_3d := true
var destacados := false
## El perfil de TU estadio -el que diseñaste en `EstadioPropio`-, calculado por
## quien te abrió esta pantalla (`mundo.perfil_estadio_de()`). Sin esto,
## `_ver_estadio()` caería en el genérico por hash y una reforma pagada nunca
## se vería en el partido en vivo.
var perfil_estadio: Dictionary = {}
## `[claro, oscuro]` de la piel de balón elegida -ver `abrir()`-.
var colores_balon: Array = []
## Lo que va a la PANTALLA GIGANTE del estadio cuando se abre el visor 3D
## (23-9-2026): tabla de la liga, máximos goleadores, nombre del torneo y del
## recinto. Se rellena desde `principal.gd`, que es quien tiene el `Mundo`
## delante; ni esta pantalla ni `VistaEstadio` lo conocen. Vacío es válido:
## la pantalla se queda con los paneles que salen del propio `Partido`.
var datos_pantalla: Dictionary = {}
## Si es un cruce a eliminación directa -Copa nacional, hoy la única que se
## dirige en vivo-, un empate en los 90' no se queda así: hay que jugar los
## penales aquí mismo, o el jugador vería "EMPATE" y se enteraría de quién
## pasó de ronda recién la semana siguiente, leyéndolo en un aviso.
var es_eliminatoria := false

var _velocidad := 2
var _acumulado := 0.0
var _marcador: Label
var _reloj: Label
var _estadisticas: Label
var _cronica: RichTextLabel
var _banquillo: VBoxContainer
var _campo: VBoxContainer
var _botones_vel: Array[Button] = []
var _btn_vel_actual: Button
var _saliendo: Jugador = null
var _pie: Label
var _btn_volver: Button
## La barra de quien manda ahora mismo. Ver `_construir()`.
var _momentum: ProgressBar
## El panel de estadísticas en vivo, cuarta columna. Ver `_construir()`.
var _panel_stats: VBoxContainer

## El entretiempo. `_entretiempo` es "el camarín está abierto ahora mismo";
## `_entretiempo_hecho` es "ya se paró una vez", para que no vuelva a pararse
## cada minuto a partir del 45.
var _entretiempo := false
var _entretiempo_hecho := false
var _charla_dada := false
var _texto_charla: LineEdit
## Arengas que quedan. Tres por partido: si fueran ilimitadas se arengaría a los
## once en el minuto uno y dejaría de ser una decisión sobre A QUIÉN levantar.
var _arengas: int = 3
## El camarín, que hace falta para la charla. Se recibe en `abrir()` en vez de
## buscarlo: esta pantalla no conoce a `Mundo` y no tiene por qué conocerlo.
var vestuario: Vestuario
## `Roles`, para saber si mandas tú o tu DT empleado -`mando()` del HTML-.
## Igual que `vestuario`, se recibe en vez de buscarlo.
var roles: Roles
## Una vez por partido, igual que `M.palcoUsado` del HTML.
var _palco_usado := false

## LA INVASION DE CAMPO. Minuto 70, perdiendo en casa y con la grada harta: el
## partido se para veinte minutos con la policia desalojando, y el camarin se
## vuelve a abrir. La tirada la hace ahora `Partido.simular_minuto()` para
## cualquier vista (ver `Partido.fijar_hinchada()`); aqui solo se cuenta.
var _invasion_pendiente := false

## `instrViva('banda')` del HTML: gritar desde la banda baja la ansiedad del
## once un par de puntos, con una de cuatro frases al azar. Protestar de más
## tiene consecuencia real: con el árbitro ya caliente
## (`Federacion.enojo_arbitral>=2`) hay 16% de que te expulsen del área
## técnica.
##
## Simplificación real frente al HTML: el original abre además un CASO DE
## TRIBUNAL que te deja sancionado varios PARTIDOS futuros (`expulsarDT()`/
## `G.dtSusp`, todo un sistema de "disciplina del banquillo" que Godot no
## tiene portado) -aquí la consecuencia se queda en ESTE partido: expulsado,
## no puedes volver a gritar desde la banda hasta el próximo.
const _FRASES_BANDA := [
	"🗣️ Gritas desde la banda: el equipo aprieta los dientes.",
	"👏 Aplaudes de pie: la hinchada te sigue.",
	"😤 Pateas una botella: los tuyos se despiertan.",
	"🧘 Te sientas tranquilo: bajas la ansiedad del equipo.",
]
var _expulsado_banda := false

## Las tres frases y los dos sonidos de "casi gol" del HTML (juego.js:2141,
## 2145, 2149): estaban en `sfx()` desde siempre pero nadie los llamaba en
## Godot porque `Partido` solo contaba el remate y no decia como habia
## terminado. El sonido, igual que en `_al_gol`, solo suena si el remate es
## mio -asi lo hacia el HTML tambien-: los remates fallados del rival no
## interrumpen el murmullo de fondo.
const _FRASES_ATAJADA := [
	"🧤 Atajada del arquero tras remate de ",
	"🧤 Manotazo salvador ante el remate de ",
	"🧤 Vuela y saca al córner el disparo de ",
]
const _FRASES_FALLO := [
	"❌ Ocasión clara fallada",
	"😱 La manda a las nubes",
	"🙈 Se le va por poco",
	"🥅 Solo frente al arquero y la tira afuera",
]

func _escribir(bbcode: String) -> void:
	_cronica.append_text(bbcode + "\n")

func _limpiar(n: Node) -> void:
	for h in n.get_children():
		n.remove_child(h)
		h.queue_free()

## `mando()` del HTML: si tu rol es despacho/dueño/cantera/ayudante, el once
## no lo pones tú -lo pone tu DT empleado-. `Roles.manda()` ya es ese mismo
## booleano, portado hace tiempo, solo que ninguna pantalla lo consultaba
## todavía: el ayudante o el dueño podían tocar la pizarra y los cambios en
## vivo exactamente igual que un DT.
func _en_palco() -> bool:
	return roles != null and roles.manda()

func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

func _mi_once() -> Array[Jugador]:
	return partido.once_local if partido.local == mi_club else partido.once_visita

func _arengar(j: Jugador) -> void:
	if _arengas <= 0:
		return
	var problema := partido.arengar(j)
	if problema != "":
		_escribir("[color=#8ea595]%s.[/color]" % problema)
		return
	_arengas -= 1
	Sonido.toca("ovacion", Sonido.Bus.AMBIENTE)
	_escribir("[color=#c9a227]📣 Le gritas a %s desde la banda. Se enciende.[/color]" % j.nombre)
	(self as PartidoVivo)._refrescar()

func _pintar_campo() -> void:
	_limpiar(_campo)
	if _en_palco():
		var av := _texto(11, COL_SUAVE)
		av.text = Idiomas.t("🥂 Dirige %s desde el banquillo. Los cambios y la charla son cosa suya.") % roles.dt_nombre()
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_campo.add_child(av)
		for j in _mi_once():
			var l := _texto(12, COL_ORO if partido.con_impulso(j) else COL_TEXTO)
			l.text = "%s%s  %s  %d" % ["🔥 " if partido.con_impulso(j) else "", j.pos_e, j.nombre, j.ovr]
			_campo.add_child(l)
		return
	var ayuda := _texto(11, COL_SUAVE)
	ayuda.text = Idiomas.t("Pulsa a quién sacas.") if _saliendo == null else Idiomas.t("Ahora, quién entra.")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_campo.add_child(ayuda)
	## LAS ARENGAS. Gritarle a uno desde la banda: le sube la moral y rinde un
	## 12% más durante dieciocho minutos. Tres por partido, porque si fueran
	## ilimitadas se arengaría a los once en el minuto uno y dejaría de ser una
	## decisión sobre A QUIÉN levantar.
	var ta := _texto(11, COL_ORO)
	ta.text = Idiomas.t("📣 ARENGAS  ·  te quedan %d") % _arengas
	_campo.add_child(ta)
	for j in _mi_once():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 4)
		_campo.add_child(fila)
		var encendido := partido.con_impulso(j)
		var b := Button.new()
		b.text = "%s%s  %s  %d" % ["🔥 " if encendido else "", j.pos_e, j.nombre, j.ovr]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color",
			COL_ORO if encendido else (COL_ACENTO if j == _saliendo else COL_TEXTO))
		b.disabled = partido.terminado_ya
		b.pressed.connect(func() -> void:
			_saliendo = null if _saliendo == j else j
			(self as PartidoVivo)._refrescar())
		fila.add_child(b)
		var ba := Button.new()
		ba.text = "📣"
		ba.tooltip_text = Idiomas.t("Arengarle: le sube la moral y rinde un 12% más durante 18 minutos.")
		ba.add_theme_font_size_override("font_size", 11)
		ba.custom_minimum_size = Vector2(34, 0)
		ba.disabled = partido.terminado_ya or _arengas <= 0 or encendido
		ba.pressed.connect(func() -> void: _arengar(j))
		fila.add_child(ba)

# --- reloj ------------------------------------------------------------------

func _poner_velocidad(i: int) -> void:
	_velocidad = i
	for k in _botones_vel.size():
		_botones_vel[k].button_pressed = (k == i)
	if _btn_vel_actual != null:
		_btn_vel_actual.text = "⏱ " + String(VELOCIDADES[i]["txt"])

## Abre el estadio del local en 3D, encima del partido.
##
## El reloj se para mientras tanto: si siguiera corriendo, el jugador volvería
## del estadio y se habría perdido veinte minutos de su propio partido.
func _ver_estadio() -> void:
	var antes := _velocidad
	_poner_velocidad(0)
	## BUG REAL, ENCONTRADO CON UNA CAPTURA (13-9-2026): un comentario de
	## `principal.gd` decía que esta pantalla "ya deja hueco de sobra" para el
	## 3D y por eso no hacía falta esconder nada. Era una suposición nunca
	## comprobada con una imagen: `_pintar_campo()` + `_pintar_camarin()` +
	## `_pintar_banquillo()` + `_pintar_estadisticas_vivo()` cubren la
	## pantalla ENTERA, borde a borde. `VistaEstadio` se construía perfecto
	## -con el partido de verdad dentro- y quedaba invisible detrás: Godot
	## pinta los `Control` SIEMPRE encima del 3D, sin importar el orden de los
	## nodos. El botón "Ver en 3D" durante un partido dirigido probablemente
	## nunca mostró nada. Mismo arreglo que ya usa
	## `principal.gd::_ver_estadio_propio()`: esconder los hijos visibles
	## propios y devolverlos tal cual al volver.
	##
	## Y NO BASTA CON ESCONDER LOS PROPIOS: `PartidoVivo` vive colgado de
	## `principal.gd` (`_dirigir()` hace `add_child(vivo)` sobre sí mismo), y
	## esa pantalla de abajo -tabla, cabecera, pestañas- es OTRO Control
	## opaco en el mismo viewport. Escondiendo solo los hijos de aquí, la
	## primera prueba con captura real seguía mostrando el panel del club por
	## debajo: dos capas del mismo problema, no una. Hay que esconder también
	## los hijos visibles del padre mientras el 3D está abierto.
	var ocultados: Array = []
	for h in get_children():
		if h is Control and (h as Control).visible:
			(h as Control).visible = false
			ocultados.append(h)
	var padre := get_parent()
	if padre != null:
		for h in padre.get_children():
			if h != self and h is Control and (h as Control).visible:
				(h as Control).visible = false
				ocultados.append(h)
	var vista := VistaEstadio.new()
	## ANTES de `abrir()`: `VistaEstadio._construir()` monta la pantalla gigante
	## dentro de esa llamada, así que asignarlo después llegaría tarde y la
	## pantalla se quedaría sin tabla ni goleadores.
	vista.datos_pantalla = datos_pantalla
	vista.modo_destacados = destacados
	add_child(vista)
	## La ocupación que se ve en las gradas es la de verdad: la que sale de la
	## curva de la taquilla con el precio de entrada que has puesto tú. Un
	## estadio medio vacío tiene que verse medio vacío.
	var f := Finanzas.new(partido.local)
	var gente := float(f.asistencia()) / float(maxi(partido.local.estadio_aforo, 1))
	## Y con el partido de verdad dentro: los 22 juegan, el marcador corre y lo que
	## pase ahi es lo que va a la tabla. El reloj de esta pantalla queda parado
	## mientras tanto — manda el de la vista 3D, para que no haya dos relojes.
	vista.parar_en_descanso = not _entretiempo_hecho
	## Eliminatoria: con el motor real, prórroga y penales se juegan en el 3D.
	vista.eliminatoria = es_eliminatoria
	vista.abrir(partido.local, clampf(gente, 0.05, 1.0), partido.visita, partido, perfil_estadio, colores_balon)
	vista.cerrado.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as Control).visible = true
		_poner_velocidad(antes))

func _salir_segunda() -> void:
	if not _charla_dada:
		_escribir("[color=#8ea595]🤐 Te quedaste callado en el camarín. El equipo sale como entró.[/color]")
	_entretiempo = false
	_escribir("[color=#8ea595]▶️ Comienza la segunda parte.[/color]")
	(self as PartidoVivo)._refrescar()
	## Si el partido se estaba viendo en 3D, la segunda parte también.
	if con_3d and not partido.terminado_ya:
		_ver_estadio()

func _dar_charla(tono: String) -> void:
	var v := vestuario
	if v == null or _charla_dada:
		return
	var r: Dictionary = v.charla(_mi_once(), tono)
	_charla_dada = true
	_escribir("[color=#c9a227]%s Charla (%s):[/color] %s. (%d ↑ / %d ↓)" % [
		String(r["icono"]), String(r["nombre"]).to_lower(), String(r["reaccion"]),
		int(r["suben"]), int(r["bajan"])])
	Sonido.toca("clic", Sonido.Bus.INTERFAZ)
	(self as PartidoVivo)._refrescar()

func _charla_libre(texto: String) -> void:
	var v := vestuario
	if v == null or _charla_dada:
		return
	var limpio := texto.strip_edges()
	if limpio == "":
		return
	_escribir("[color=#e9eeea]🗣️ «%s»[/color]" % limpio.substr(0, 110))
	_dar_charla(v.tono_de_texto(limpio))

## EL CAMARÍN DEL ENTRETIEMPO. Va arriba del todo del panel derecho y solo
## existe mientras el reloj está parado en el 45: es lo único que hay que
## resolver en ese momento, y si estuviera siempre visible dejaría de ser un
## momento.
##
## Los seis tonos NO son seis grados de lo mismo: cada uno tiene su margen, y
## los de más recorrido son los que más pueden hundirte. "Sacudir" va de -9 a
## +14, así que es la jugada del que va perdiendo y no tiene nada que perder.
func _pintar_camarin() -> void:
	var v := vestuario
	if v == null:
		return
	var t := _texto(13, COL_ORO)
	t.text = Idiomas.t("🔵 CAMARÍN — ENTRETIEMPO")
	_banquillo.add_child(t)
	## Desde el palco no se habla en el camarín -es cosa de tu DT empleado-,
	## pero el partido tiene que poder seguir: la única puerta es salir a la
	## segunda parte.
	if _en_palco():
		var ap := _texto(11, COL_SUAVE)
		ap.text = Idiomas.t("%s da la charla. No es cosa tuya.") % roles.dt_nombre()
		ap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_banquillo.add_child(ap)
		var salir_p := Button.new()
		salir_p.text = Idiomas.t("▶️  Salir a la segunda parte")
		salir_p.custom_minimum_size = Vector2(0, 30)
		salir_p.pressed.connect(_salir_segunda)
		_banquillo.add_child(salir_p)
		_banquillo.add_child(HSeparator.new())
		return
	if _charla_dada:
		var ya := _texto(11, COL_SUAVE)
		ya.text = Idiomas.t("Ya has hablado. Puedes hacer cambios y mover la pizarra antes de salir.")
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_banquillo.add_child(ya)
	else:
		var ay := _texto(11, COL_SUAVE)
		ay.text = Idiomas.t("A un líder o a una muralla les va la exigencia; a un frágil o a un cerebro, el elogio.")
		ay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_banquillo.add_child(ay)
		var rej := GridContainer.new()
		rej.columns = 3
		_banquillo.add_child(rej)
		for clave: String in Vestuario.TONOS:
			var fila: Array = Vestuario.TONOS[clave]
			var b := Button.new()
			b.text = "%s %s" % [String(fila[1]), String(fila[0])]
			b.add_theme_font_size_override("font_size", 11)
			b.tooltip_text = Idiomas.t("Efecto en la moral: de %d a %d. Ansiedad: %+d.") % [int(fila[2]), int(fila[3]), int(fila[4])]
			var k := clave
			b.pressed.connect(func() -> void: _dar_charla(k))
			rej.add_child(b)
		## La charla escrita: el tono se deduce de lo que escribes. Es lo más
		## barato del sistema y lo que más mete en el papel — decir "así no,
		## señores" y ver que el equipo lo acusa vale más que elegir de una lista.
		_texto_charla = LineEdit.new()
		_texto_charla.placeholder_text = Idiomas.t("…o díselo con tus palabras y pulsa Enter")
		_texto_charla.add_theme_font_size_override("font_size", 12)
		_texto_charla.text_submitted.connect(_charla_libre)
		_banquillo.add_child(_texto_charla)
	var salir := Button.new()
	salir.text = Idiomas.t("▶️  Salir a la segunda parte")
	salir.custom_minimum_size = Vector2(0, 30)
	salir.pressed.connect(_salir_segunda)
	_banquillo.add_child(salir)
	_banquillo.add_child(HSeparator.new())

## Una fila "etiqueta … valor" para el panel del banquillo, mismo patrón que
## `_dato()` de `principal.gd` pero sin depender de esa pantalla.
func _dato_banquillo(etiqueta: String, valor: String, color: Color) -> void:
	var h := HBoxContainer.new()
	var a := _texto(11, COL_SUAVE)
	a.text = etiqueta
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.clip_text = true
	h.add_child(a)
	var b := _texto(11, color)
	b.text = valor
	h.add_child(b)
	_banquillo.add_child(h)
