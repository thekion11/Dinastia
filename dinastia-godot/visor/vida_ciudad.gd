class_name VidaCiudad
extends Node
## LA VIDA EN 3D (fase 3 del plan del lunes, 26-10-2026). Plan §2.2c: el reloj de la
## partida (`Reloj`) manda sobre la luz de la ciudad y corre mientras paseas; la
## jornada en el club cuenta como trabajo; comer y dormir mueven `Necesidades`; la
## Casa Grande se abre por dentro (`CasaDT`) con tu familia; el móvil adelanta el
## reloj con la rutina; el coche depende de `VidaDT.transporte`, y conducir a lo
## loco acaba en el calabozo. No inventa reglas de simulación: la SEMANA la sigue
## avanzando `Mundo.avanzar_semana()` (la misma llamada que el PC), solo que aquí
## también la dispara dormir el domingo.
##
## Se cuelga del explorador (`enganchar`): el explorador le pregunta en los puntos
## justos (E en un interior, E en una sala del estadio, la T del móvil, el HUD) y
## todo lo demás pasa en `_process`. Sin `Mundo` no se engancha y el paseo es el
## de siempre (las pruebas viejas y la ciudad sin partida no cambian).

## 1 minuto real = 10 minutos de juego (un minuto de juego cada 6 s).
const SEG_POR_MINUTO := 6.0
const MULTAS_CALABOZO := 3
const CONFIANZA_CALABOZO := 3
const ESTRES_CALABOZO := 4
const ESTRES_DESMAYO := 6
const HORA_PARTIDO := 15
const ZONA_COMEDOR := "Comedor del plantel"
const DIAS := ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
## Dónde se come algo en la ciudad (interiores de manzana): clave → lo que pasa.
const COMIDAS := {
	"edificio_bar": "Un café con algo en la barra. Media hora y a seguir.",
	"edificio_panaderia": "Pan recién hecho y un café de pie. Media hora.",
	"edificio_mercado": "Fruta y un bocadillo del mercado. Media hora.",
}

var mundo: Mundo
var expl: ExploradorCiudad
var vista: VistaCiudad
var casa: CasaDT = null
## Las citas en persona en 3D (fase 4): flecha, cuerpos y charla.
var citas_3d: CitasCiudad = null
var en_casa := false
var _punto_casa := {}
var _acum := 0.0
var _cuadro: CuadroDialogo
var _t_cuadro := 0.0
var _capa_tel: CanvasLayer
var _calabozo_semana := ""
var _desmayo_en_curso := false

# ========================================================================== ENGANCHE

static func enganchar(e: ExploradorCiudad, v: VistaCiudad, m: Mundo) -> VidaCiudad:
	if e == null or m == null or m.reloj == null:
		return null
	var s := VidaCiudad.new()
	s.name = "Vida"
	s.mundo = m
	s.expl = e
	s.vista = v
	e.add_child(s)
	e.vida = s
	m.reloj.tiempo_pasado.connect(s._al_pasar_tiempo)
	m.reloj.hora_cambiada.connect(s._al_cambiar_hora)
	m.reloj.semana_agotada.connect(s._al_agotar_semana)
	if m.necesidades != null:
		m.necesidades.estado_cambiado.connect(s._al_cambiar_nivel)
		m.necesidades.agotamiento.connect(s._desmayo)
	s._sincronizar_luz()
	if m.citas != null:
		s.citas_3d = CitasCiudad.crear(s)
	return s

## ¿Se puede salir en coche esta semana? {coche, motivo}. Con «micro» no hay coche
## propio; y una semana de cada ocho (por hash, estable) el coche está en el taller.
static func transporte(m: Mundo) -> Dictionary:
	if m == null or m.vida == null or m.mi_club() == null:
		return {"coche": true, "motivo": ""}
	if m.vida.transporte == "micro":
		return {"coche": false, "motivo": "Sin coche propio: esta semana te mueves en bus y metro (Mi Vida → Transporte)."}
	if absi(("averia|%d|%d|%s" % [m.anio, m.semana, m.mi_club().id]).hash()) % 8 == 0:
		return {"coche": false, "motivo": "🔧 Tu coche está en el taller esta semana: bus y metro."}
	return {"coche": true, "motivo": ""}

## Dónde empieza una partida cargada en 3D (bloque 7): "" = en el menú de siempre
## (prólogo sin ver, pruebas, vida apagada → PC); "oficina" o "casa" (lunes 08:00).
static func arranque_3d(m: Mundo) -> String:
	if m == null or not m.prologo_visto or m.ciudad == null or m.obras == null or m.reloj == null:
		return ""
	if OrquestadorMundo.sin_prologo or OS.get_environment("PROLOGO") == "0":
		return ""
	if m.necesidades != null and m.necesidades.modo == "apagada":
		return "oficina"
	if m.reloj.dia == 0 and m.reloj.minuto <= Reloj.HORA_INICIO * Reloj.MINUTOS_HORA:
		return "casa"
	return "oficina"

# ====================================================================== RELOJ VIVO

func _process(delta: float) -> void:
	if expl == null or not is_instance_valid(expl) or expl.cuerpo == null:
		return
	if _t_cuadro > 0.0:
		_t_cuadro -= delta
		if _t_cuadro <= 0.0 and _cuadro != null:
			_cuadro.cerrar()
	## Pausado (diálogo, PC, móvil) o andando solo por la puerta: el tiempo no corre.
	if not expl.is_physics_processing() or String(expl.estado) == "puerta":
		return
	_acum += delta
	while _acum >= SEG_POR_MINUTO:
		_acum -= SEG_POR_MINUTO
		if not mundo.reloj.agotada():
			mundo.reloj.avanzar_minutos(1, actividad_actual())
	if expl.multas >= MULTAS_CALABOZO:
		_calabozo()

## Lo que cuenta el tiempo ahora mismo para `Necesidades`: en el club de lunes a
## viernes es jornada (09-18) u horas extra (18-23); el resto, libre.
func actividad_actual() -> String:
	var r := mundo.reloj
	if String(expl.estado) == "estadio" and not r.es_fin_de_semana():
		if r.es_jornada_laboral():
			return "trabajo"
		if r.hora() >= Reloj.JORNADA_FIN and r.hora() < 23:
			return "horas_extra"
	return "libre"

func _al_pasar_tiempo(_minutos: int, _actividad: String) -> void:
	_sincronizar_luz()

## Cada hora de horas extra: +1 de preparación (balance) y +1 de estrés (`VidaDT`).
func _al_cambiar_hora(hora: int, _dia: int) -> void:
	if mundo.vida == null or actividad_actual() != "horas_extra":
		return
	mundo.vida.balance = clampi(mundo.vida.balance + 1, 0, 100)
	mundo.vida.estres = clampi(mundo.vida.estres + 1, 0, 100)
	if hora == Reloj.JORNADA_FIN + 1:
		_notificar(Idiomas.t("🕖 Horas extra: preparas mejor la semana, pero el estrés sube."))

func _al_agotar_semana() -> void:
	_decir(Idiomas.t("Domingo por la noche"), Idiomas.t("La semana se acaba: duerme en tu cama o pulsa «Avanzar semana» en el PC."))

## La luz de la ciudad ES la hora del reloj (la vuelta de 2 min queda apagada).
func _sincronizar_luz() -> void:
	if vista == null or not is_instance_valid(vista):
		return
	vista._ciclo_activo = false
	vista._hora = mundo.reloj.hora_decimal()
	vista._aplicar_hora()
	if expl._movil != null:
		expl._movil.reloj_texto = etiqueta_hora()

## «Martes 10:40», para el HUD y el móvil en la mano.
func etiqueta_hora() -> String:
	var r := mundo.reloj
	return "%s %s" % [Idiomas.t(DIAS[clampi(r.dia, 0, 6)]), r.texto_hora()]

# ===================================================================== NECESIDADES

func _al_cambiar_nivel(necesidad: String, nivel: int) -> void:
	if nivel <= 0:
		return
	if necesidad == "energia":
		if nivel == 1:
			_notificar(Idiomas.t("🩺 Estás cansado: come algo y duerme pronto."))
		else:
			_decir(Idiomas.t("El médico del club"), Idiomas.t("Estás al límite. Si no duermes, caerás redondo donde estés."))
	elif necesidad == "hambre":
		_notificar(Idiomas.t("🍽 Tienes hambre: el comedor del plantel, tu casa o un bar de la ciudad.") if nivel == 1
			else Idiomas.t("🍽 Famélico. Come ya: el rendimiento se resiente."))

## Energía a cero fuera de la cama: despiertas en casa con estrés y un titular.
func _desmayo() -> void:
	if _desmayo_en_curso or mundo.necesidades == null:
		return
	_desmayo_en_curso = true
	if String(expl.estado) in ["anden", "tren", "puerta"]:
		_desmayo_en_curso = false
		return
	expl._fundido()
	if String(expl.estado) == "interior":
		expl._salir_del_edificio()
	elif String(expl.estado) == "estadio":
		expl._salir_del_estadio()
	var cg := _punto_ciudad("casa_grande")
	if cg != Vector3.INF:
		expl.cuerpo.position = expl.buscar_libre(cg)
	mundo.reloj.esperar_hasta(CasaDT.HORA_LEVANTARSE, "dormir")
	if mundo.vida != null:
		mundo.vida.estres = clampi(mundo.vida.estres + ESTRES_DESMAYO, 0, 100)
		mundo.vida._anotar("Te desmayaste de agotamiento; te llevaron a casa.", mundo.anio, mundo.semana)
	_titular("El DT se desploma en plena calle: «agotamiento», dice el club", "Lo recogieron unos vecinos.")
	_decir(Idiomas.t("Despiertas en casa"), Idiomas.t("Caíste redondo de agotamiento. Te trajeron a casa; mañana lo lee toda la ciudad."))
	_tras_dormir()
	_desmayo_en_curso = false

func _punto_ciudad(k: String) -> Vector3:
	if expl.cb == null:
		return Vector3.INF
	for pc: Dictionary in expl.cb.puntos_clic:
		if String(pc["k"]) == k:
			return pc["pos"]
	return Vector3.INF

## E en una sala del estadio: el comedor del plantel da de comer. true si lo usó.
func usar_en_estadio(zona: String) -> bool:
	if zona != ZONA_COMEDOR:
		return false
	_comer(Idiomas.t("Comes con el plantel en el comedor del club. Media hora de charla y plato caliente."))
	return true

func _comer(texto: String) -> void:
	mundo.reloj.avanzar_minutos(30, "comer")
	_decir(Idiomas.t("Comer"), texto)
	Sonido.toca("clic", Sonido.Bus.EFECTOS)

# ============================================================================ CASA

## ¿Esta E en la ciudad es la puerta de tu casa?
func es_mi_casa(k: String) -> bool:
	return k == "casa_grande" and String(expl.estado) == "calle" and expl.modo == "pie"

## Entra a la Casa Grande por dentro: la misma mecánica que cualquier interior
## (`_mover_en_interior`, salir por la puerta), con `CasaDT` como sala.
func entrar_casa() -> void:
	if en_casa or expl.cb == null:
		return
	expl._fundido()
	var raiz := Node3D.new()
	raiz.name = "CasaPaseo"
	raiz.position = expl._INT_ORIGEN
	expl.cb.add_child(raiz)
	casa = CasaDT.new()
	casa.montar(raiz, mundo, Vector3.ZERO)
	if casa.interior == null:
		raiz.queue_free()
		casa = null
		return
	expl._int_raiz = raiz
	expl._int = casa.interior
	expl._int_circulos = casa.obstaculos()
	expl._calle_pos = expl.cuerpo.position
	expl._calle_rumbo = expl.rumbo
	expl.estado = "interior"
	expl._bajo_tierra(true)
	expl._vel_pie = 0.0
	var t := casa.interior.tam_sala()
	expl.cuerpo.position = expl._INT_ORIGEN + Vector3(0, 0.05, t.z * 0.5 - 1.6)
	expl.rumbo = PI
	expl.cuerpo.rotation.y = PI
	expl.cuerpo.visible = not expl.primera_persona
	expl._cerca = {}
	expl._aviso.text = ""
	expl._colocar_camara(1.0)
	en_casa = true
	Sonido.toca("puerta", Sonido.Bus.EFECTOS)

## Lo llama el explorador al empezar a salir de un interior: la sala de la casa
## la libera `CasaDT` (no cuelga del árbol), no el explorador.
func al_salir_interior() -> void:
	if en_casa:
		expl._int = null
		en_casa = false
		casa = null
		_punto_casa = {}

## El aviso de la E dentro de un interior: tu casa (cama, mesa, sofá, familia) o
## pedir algo de comer en un bar. Lo llama `_mover_en_interior` cada cuadro.
func avisar_interior() -> void:
	_punto_casa = {}
	if en_casa and casa != null:
		_punto_casa = casa.cercano(expl.cuerpo.position)
		if not _punto_casa.is_empty():
			expl._aviso.text = String(_punto_casa["texto"])
	elif _clave_interior() in COMIDAS and expl._int_cerca.is_empty():
		expl._aviso.text = Idiomas.t("E: pedir algo de comer · la puerta: salir")

func _clave_interior() -> String:
	return String(expl._int.clave).get_slice("|", 0) if is_instance_valid(expl._int) else ""

## E dentro de un interior. true si la vida se lo quedó (si no, charla o salida de siempre).
func usar_interior() -> bool:
	if en_casa and casa != null and not _punto_casa.is_empty():
		var r := casa.usar(String(_punto_casa["clave"]), String(_punto_casa.get("nombre", "")))
		if r.is_empty():
			return false
		if String(_punto_casa["clave"]) == "cama":
			expl._fundido()
		_decir(String(r["titulo"]), String(r["texto"]))
		if String(_punto_casa["clave"]) == "cama":
			_tras_dormir()
		return true
	var k := _clave_interior()
	if k in COMIDAS and expl._int_cerca.is_empty():
		_comer(Idiomas.t(String(COMIDAS[k])))
		return true
	return false

## Tras dormir: si era domingo por la noche, la semana avanza (la MISMA llamada que
## el PC) y amanece el lunes a las 08:00.
func _tras_dormir() -> void:
	if mundo.reloj.agotada():
		_avanzar_semana_3d()
	_sincronizar_luz()

func _avanzar_semana_3d() -> void:
	if not mundo.temporada_en_curso():
		_decir(Idiomas.t("Temporada terminada"), Idiomas.t("En el PC: «Temporada siguiente»."))
		return
	mundo.avanzar_semana()
	## El menú central del PC, si ya está creado, se entera.
	for pc in get_tree().root.find_children("*", "PcOficina", true, false):
		var pr: Variant = pc.get("_principal")
		if pr != null and is_instance_valid(pr) and (pr as Node).has_method("_refrescar"):
			(pr as Node).call("_refrescar")
	_notificar(Idiomas.t("📅 Nueva semana: lunes, 08:00."))

# ======================================================================== TELÉFONO

## La T del paseo: el móvil de siempre (con la app Agenda) sobre el mundo, en pausa.
func abrir_telefono() -> void:
	if is_instance_valid(_capa_tel) or not expl.is_physics_processing():
		return
	_capa_tel = CanvasLayer.new()
	_capa_tel.layer = 45
	add_child(_capa_tel)
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_tel.add_child(raiz)
	var pop := Telefono.abrir(raiz, mundo)
	expl.pausar(true)
	pop.tree_exited.connect(func() -> void:
		if is_instance_valid(expl):
			expl.pausar(false)
		if is_instance_valid(_capa_tel):
			_capa_tel.queue_free()
		_sincronizar_luz())

# ======================================================================= CALABOZO

## Tres multas por conducción temeraria: noche en el calabozo. −3 de confianza de la
## directiva y un titular, una vez por semana; el reloj salta a las 08:00.
func _calabozo() -> void:
	expl.multas = 0
	var clave := "%d|%d" % [mundo.anio, mundo.semana]
	if _calabozo_semana == clave:
		return
	_calabozo_semana = clave
	expl._fundido()
	mundo.reloj.esperar_hasta(CasaDT.HORA_LEVANTARSE, "dormir")
	if mundo.directiva != null:
		mundo.directiva.confianza = clampi(mundo.directiva.confianza - CONFIANZA_CALABOZO, 0, 100)
	if mundo.vida != null:
		mundo.vida.estres = clampi(mundo.vida.estres + ESTRES_CALABOZO, 0, 100)
		mundo.vida._anotar("Una noche en el calabozo por conducción temeraria.", mundo.anio, mundo.semana)
	_titular("El DT, una noche en comisaría por conducción temeraria", "Tres multas en una tarde. La directiva, «muy molesta».")
	_decir(Idiomas.t("Una noche en el calabozo"), Idiomas.t("Tres multas en una tarde: pasas la noche en comisaría. La directiva te lo descuenta en confianza y mañana sales en portada."))
	_tras_dormir()

# ========================================================================= AVISOS

func _titular(t: String, c: String) -> void:
	if mundo.prensa != null and mundo.prensa.titular_pendiente.is_empty():
		mundo.prensa.titular_pendiente = {"t": Idiomas.t(t), "c": Idiomas.t(c), "tipo": "mal", "medio": "La Tribuna"}

func _notificar(texto: String) -> void:
	if expl._movil != null:
		expl._movil.notificar(texto, 5.0)
	elif expl._aviso != null:
		expl._aviso.text = texto

## Un cuadro de diálogo corto (el de las charlas del paseo) que se cierra solo.
func _decir(titulo: String, texto: String) -> void:
	if _cuadro == null or not is_instance_valid(_cuadro):
		_cuadro = CuadroDialogo.new()
		add_child(_cuadro)
	_cuadro.decir(titulo, texto, Color(1.0, 0.86, 0.5), 0, 1)
	_t_cuadro = 5.0
