extends Node
## (Parte 1 de 2 de `vida_ciudad.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `vida_ciudad.gd`, conserva la clase.)

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
## Gente sentada en los bancos de la ciudad (P3, pasada 2).
var sentados: GenteSentada = null
var puertas: PuertaVida = null
var escaleras: EscaleraVida = null
var paraguas: ParaguasVida = null
var pasajeros: PasajerosBus = null
var en_casa := false
var _punto_casa := {}
var _acum := 0.0
var _cuadro: CuadroDialogo
var _t_cuadro := 0.0
var _capa_tel: CanvasLayer
var _calabozo_semana := ""
var _desmayo_en_curso := false
var _t_vacio := 0.0
var _redes_sin_luz := 0
var _redes_inundados := 0

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
	EstacionCentral.reloj = m.reloj   ## los trenes de la estación van por el reloj del juego
	m.reloj.tiempo_pasado.connect(s._al_pasar_tiempo)
	m.reloj.hora_cambiada.connect(s._al_cambiar_hora)
	m.reloj.semana_agotada.connect(s._al_agotar_semana)
	if m.necesidades != null:
		m.necesidades.estado_cambiado.connect(s._al_cambiar_nivel)
		m.necesidades.agotamiento.connect(s._desmayo)
	## Las redes de la ciudad son las de la partida (si no había, nacen con ella).
	var red: RedesCiudadVista = s._redes()
	if red != null:
		if m.redes_ciudad == null:
			m.redes_ciudad = red.modelo
		else:
			red.adoptar(m.redes_ciudad)
	s._sincronizar_luz()
	if m.citas != null:
		s.citas_3d = CitasCiudad.crear(s)
	s.sentados = GenteSentada.crear(s)
	s.puertas = PuertaVida.crear(s)
	s.escaleras = EscaleraVida.crear(s)
	s.paraguas = ParaguasVida.crear(s)
	s.pasajeros = PasajerosBus.crear(s)
	## Arranque 3D tras recuperar la copia de un guardado dañado: el aviso se ve aquí (el registro del
	## menú central, donde iba antes, no se abre hasta mucho después).
	if Partida.cargada_de_respaldo:
		Partida.cargada_de_respaldo = false
		s._decir(Idiomas.t("Guardado recuperado"), Idiomas.t("El último guardado estaba dañado: se recuperó la copia anterior."))
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
	call("poner_extras")   ## el balón del parque y la máquina del estadio (una sola vez cada uno; ver `VidaCiudad.poner_extras`)
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
	(self as VidaCiudad).gasolina_tick(delta)
	if expl.multas >= MULTAS_CALABOZO:
		(self as VidaCiudad)._calabozo()

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
	var redes := (self as VidaCiudad)._redes()
	if redes != null:
		redes.hora_cambiada(hora, mundo.clima())
		avisos_redes()
		_sincronizar_luz()
	if mundo.vida == null or actividad_actual() != "horas_extra":
		return
	mundo.vida.balance = clampi(mundo.vida.balance + 1, 0, 100)
	mundo.vida.estres = clampi(mundo.vida.estres + 1, 0, 100)
	if hora == Reloj.JORNADA_FIN + 1:
		(self as VidaCiudad)._notificar(Idiomas.t("🕖 Horas extra: preparas mejor la semana, pero el estrés sube."))

func _al_agotar_semana() -> void:
	(self as VidaCiudad)._decir(Idiomas.t("Domingo por la noche"), Idiomas.t("La semana se acaba: duerme en tu cama o pulsa «Avanzar semana» en el PC."))

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
			(self as VidaCiudad)._notificar(Idiomas.t("🩺 Estás cansado: come algo y duerme pronto."))
		else:
			(self as VidaCiudad)._decir(Idiomas.t("El médico del club"), Idiomas.t("Estás al límite. Si no duermes, caerás redondo donde estés."))
	elif necesidad == "hambre":
		(self as VidaCiudad)._notificar(Idiomas.t("🍽 Tienes hambre: el comedor del plantel, tu casa o un bar de la ciudad.") if nivel == 1
			else Idiomas.t("🍽 Famélico. Come ya: el rendimiento se resiente."))

## Energía a cero fuera de la cama: despiertas en casa con estrés y un titular.
func _desmayo() -> void:
	if _desmayo_en_curso or mundo.necesidades == null:
		return
	_desmayo_en_curso = true
	if String(expl.estado) in ["anden", "tren", "puerta", "subsuelo", "cima"]:
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
	(self as VidaCiudad)._titular("El DT se desploma en plena calle: «agotamiento», dice el club", "Lo recogieron unos vecinos.")
	(self as VidaCiudad)._decir(Idiomas.t("Despiertas en casa"), Idiomas.t("Caíste redondo de agotamiento. Te trajeron a casa; mañana lo lee toda la ciudad."))
	(self as VidaCiudad)._tras_dormir()
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
	if zona == "Sala de prensa" and EdificioClub.expendedora_cerca((self as VidaCiudad).expl.cuerpo.position - CityBuilder.ESTADIO_EN):
		return (self as VidaCiudad).usar_expendedora()   ## la máquina del pasillo de la sala de prensa
	if zona != ZONA_COMEDOR:
		return false
	(self as VidaCiudad)._comer(Idiomas.t("Comes con el plantel en el comedor del club. Media hora de charla y plato caliente."))
	return true

## Lo que cuenta el evento del apagón (móvil y prensa): empieza, lo arregla el jugador o lo arregla la cuadrilla.
func avisos_redes() -> void:
	var redes := (self as VidaCiudad)._redes()
	if redes == null:
		return
	## Cortes e inundaciones nuevos: una notificación en el móvil (si no es ya el aviso del evento del apagón).
	var sin_luz := roundi((1.0 - redes.fraccion_luz()) * 25.0)
	var inundados := redes.modelo.sectores_inundados()
	var avisos := redes.tomar_avisos()
	if sin_luz > _redes_sin_luz and avisos.is_empty():
		(self as VidaCiudad)._notificar(Idiomas.t("🔌 Corte de luz: %d sectores a oscuras.") % sin_luz)
	if inundados > _redes_inundados:
		(self as VidaCiudad)._notificar(Idiomas.t("🌧 Inundación: %d sectores con agua en la calle.") % inundados)
	_redes_sin_luz = sin_luz
	_redes_inundados = inundados
	for a: Dictionary in avisos:
		match String(a["tipo"]):
			"inicio":
				(self as VidaCiudad)._notificar(Idiomas.t("⚡ Apagón por la tormenta: dos sectores sin luz. Un técnico te escribe: «El disyuntor general ha saltado, bajo la ciudad. Busca las tapas con aro de óxido.»"))
			"cuadrilla":
				(self as VidaCiudad)._notificar(Idiomas.t("⚡ La cuadrilla municipal repuso la luz a primera hora."))
				(self as VidaCiudad)._titular("Una noche a oscuras por la tormenta", "La cuadrilla municipal tardó toda la madrugada en reponer la luz.")
			"resuelto":
				(self as VidaCiudad)._titular("Vuelve la luz en la ciudad sin explicación", "Los vecinos hablan de un «ángel de las alcantarillas». Nadie sabe quién bajó a arreglarlo.", "bien")
