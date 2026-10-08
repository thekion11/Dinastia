extends Node
## (Sin `class_name`: este script ES el autoload `Sonido`, y Godot rechaza una
## clase global que se llame igual que un singleton — "Class Sonido hides an
## autoload singleton". El autoload ya da el nombre.)
## El sonido del juego, sintetizado. Ni un solo fichero de audio.
##
## En el HTML esto es Web Audio: osciladores, ruido filtrado y envolventes, todo
## generado en el momento. Aquí se hace lo mismo pero al revés en el tiempo: en
## vez de sintetizar en cada reproducción, se generan las ondas UNA VEZ al
## arrancar y se guardan como `AudioStreamWAV`. Sintetizar cuesta; reproducir un
## buffer ya hecho, no. Y en un partido a velocidad rápida suenan cincuenta
## silbatos por minuto.
##
## LA VARIACIÓN NO ES UN ADORNO. Cada efecto se desafina y se destempla un poco:
## un silbato idéntico cincuenta veces seguidas lo detecta el oído enseguida y
## suena a máquina. Con un 6% de deriva suena a estadio. Es el mismo truco del
## HTML y por eso de cada efecto se generan varias variantes que se van rotando.
##
## Cero dependencias de fichero significa además que esto sigue funcionando si
## un día el proyecto se empaqueta para Android o para web.

const FRECUENCIA := 22050
const VARIANTES := 4

## Los tres buses del HTML, para que se puedan bajar por separado: los efectos
## del partido, el ambiente del estadio y los clics de la interfaz.
enum Bus { EFECTOS, AMBIENTE, INTERFAZ }

var volumen := {Bus.EFECTOS: 0.8, Bus.AMBIENTE: 0.5, Bus.INTERFAZ: 0.35}
var encendido := true

var _bancos: Dictionary = {}       ## nombre -> Array[AudioStreamWAV]
var _voces: Array[AudioStreamPlayer] = []
var _siguiente := 0

## Ocho reproductores en rueda. Con uno solo, un gol durante el murmullo cortaría
## el murmullo; con ocho, se solapan como en un estadio de verdad.
const VOCES := 8

var _mutex := Mutex.new()
var _hilo: Thread = null
var _parar := false

func _ready() -> void:
	for i in VOCES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_voces.append(p)
	_hilo = Thread.new()
	_hilo.start(_generar_en_fondo, Thread.PRIORITY_LOW)

## Los 205 sonidos del catálogo.
const NOMBRES := ["silbato", "gol", "gol_rival", "roja", "amarilla",
	"murmullo", "ovacion", "poste", "clic", "moneda", "pitido_final",
	"ocasion", "atajada", "falta", "corner", "trofeo",
	"lesion", "cambio", "fichaje", "ascenso", "descenso", "logro",
	## La segunda tanda: la interfaz, el campo, la grada y la gestion.
	"clic_suave", "abrir", "cerrar", "error", "aviso", "correo", "guardado",
	"telefono", "saque_inicial", "penal", "penal_fallado", "travesano",
	"remate_fuera", "var", "segunda_amarilla", "fuera_de_juego",
	"tambor", "trompeta", "abucheo", "aplauso", "cantico", "bengala",
	"lluvia_ambiente", "vestuario", "flashes", "contrato", "despido",
	"dinero_entra", "dinero_sale", "sorteo", "cronometro", "himno",
	"fin_temporada",
	## Y los que pedia el LEEME: uno propio por evento.
	"clausula", "lesion_grave", "oferta", "contrato_vence", "obra",
	"venta", "ronda_superada",
	## Los ocho sonidos de gol que se eligen en el diseño del estadio
	## (`EST_SONIDOS`): mismas claves que guarda `EstadioPropio`.
	"gol_bombo", "gol_sirena", "gol_campana", "gol_organo",
	"gol_explosion", "gol_sintetico", "gol_tambores", "gol_silencio",
	## TERCERA TANDA (21-9-2026), a pedido explícito del usuario: "que sean
	## cerca de 200 sonidos" -de 65 a unos 200 situaciones distintas, no
	## solo más variantes de las mismas-. Organizado en los mismos bloques
	## que ya usaba el catálogo, cada uno nuevo con su propia receta, no
	## una reetiquetada de otra.
	## --- Más momentos de partido ---
	"saque_banda", "saque_puerta", "fuera_de_banda", "rebote", "palo_doble",
	"atajada_punos", "atajada_pies", "gol_cabeza", "gol_chilena", "gol_falta",
	"gol_penal", "autogol", "mano_penal", "simulacion", "var_anulado",
	"medio_tiempo", "reanudacion", "calentamiento", "salida_tunel",
	"presentacion_alineaciones", "despeje", "entrada_dura",
	"recuperacion_balon", "pase_largo", "control_balon",
	## --- Más grada ---
	"ola_mexicana", "silbido_agudo", "coro_rival", "pitos_arbitro",
	"bocina_vuvuzela", "tambor_visitante", "suspiro_grada", "alarido_atajada",
	"tension_publico", "silbidos_impaciencia", "ultimo_minuto",
	"descuento_anunciado", "grada_de_pie", "bufanda_alzada",
	"pancarta_desplegada", "humo_bengala", "cornetin", "campanas_iglesia",
	"animador_grada", "eco_estadio", "lluvia_fuerte", "viento_fuerte",
	"trueno", "multitud_entrando", "multitud_saliendo",
	## --- Más gestión / carrera ---
	"entrenamiento", "sesion_tactica", "rueda_prensa_pregunta",
	"rueda_prensa_aplauso", "scouting_informe", "oferta_rechazada",
	"oferta_aceptada", "renovacion", "prestamo", "veto_fichaje",
	"mercado_cierra", "premio_individual", "capitania", "retiro_jugador",
	"debut_juvenil", "ascenso_juvenil", "sancion_directiva",
	"reunion_directiva", "patrocinio_nuevo", "inauguracion_obra",
	"entrada_taquilla", "aumento_socios", "huelga_hinchas",
	"elecciones_club", "votacion_ganada", "votacion_perdida", "premio_liga",
	"descenso_administrativo", "multa", "cesion_jugador",
	"renovacion_rechazada", "agente_llamada", "rumor_fichaje",
	"medico_parte", "alta_medica", "baja_medica", "entrenamiento_lesion",
	"objetivo_cumplido", "objetivo_fallado", "mejora_instalaciones",
	## --- Más interfaz ---
	"seleccionar", "deseleccionar", "arrastrar", "soltar", "desbloqueo",
	"nivel_subido", "notificacion", "confirmar", "cancelar", "deslizar",
	## --- Más festejos y momentos de gol ---
	"celebracion_grupal", "celebracion_individual", "festejo_banco",
	"festejo_hinchada_extra", "remontada", "gol_agonico", "hat_trick",
	"doblete", "gol_rapido", "gol_confirmado_var",
	## --- Clima y ambiente ---
	"niebla_ambiente", "calor_extremo", "frio_extremo", "noche_estadio",
	"dia_soleado",
	## --- Más árbitro y disciplina ---
	"tarjeta_banco", "protesta_jugador", "protesta_masiva",
	"amonestacion_verbal", "tiempo_anadido", "ventaja", "libre_indirecto",
	"mano_fuera_area", "fuera_terreno_juego", "calambre",
	## --- Más estilo de juego ---
	"pase_corto", "centro", "regate", "tiro_potente", "tiro_flojo",
	"paso_atras", "presion_alta", "contragolpe", "posesion_larga",
	"cambio_ritmo",
	## --- Recorridos a pie (etapa 1, 8-10-2026): se pedían y no existían ---
	"puerta", "paso"]


## Genera TODO de golpe, en el hilo que llama. Solo para pruebas y
## herramientas: el juego usa el hilo de fondo de `_ready()`.
func _generar_todo() -> void:
	for nombre: String in NOMBRES:
		banco(nombre)

## EN SEGUNDO PLANO (25-9-2026). Antes `_ready()` sintetizaba los 820 sonidos
## (205 × 4 variantes) en el hilo principal: medido, 12 segundos de pantalla
## congelada al abrir el juego. Ahora un hilo los va haciendo mientras se juega,
## y si alguien pide uno que todavía no está, `banco()` hace solo ese, al
## momento -unos milisegundos-. La síntesis no toca `Azar` (cada receta usa su
## propio generador), así que el hilo no altera ninguna partida.
func _generar_en_fondo() -> void:
	for nombre: String in NOMBRES:
		if _parar:
			return
		_mutex.lock()
		var ya := _bancos.has(nombre)
		_mutex.unlock()
		if ya:
			continue
		var b := _sintetizar_banco(nombre)
		_mutex.lock()
		if not _bancos.has(nombre):
			_bancos[nombre] = b
		_mutex.unlock()

func _sintetizar_banco(nombre: String) -> Array[AudioStreamWAV]:
	var b: Array[AudioStreamWAV] = []
	for v in VARIANTES:
		b.append(_sintetizar(nombre, float(v) / float(VARIANTES)))
	return b

## Las variantes de un sonido, generándolas si todavía no estaban.
func banco(nombre: String) -> Array:
	_mutex.lock()
	var b: Variant = _bancos.get(nombre)
	_mutex.unlock()
	if b != null:
		return b
	if not NOMBRES.has(nombre):
		return []
	var nuevo := _sintetizar_banco(nombre)
	_mutex.lock()
	if not _bancos.has(nombre):
		_bancos[nombre] = nuevo
	var r: Array = _bancos[nombre]
	_mutex.unlock()
	return r

func _exit_tree() -> void:
	_parar = true
	if _hilo != null and _hilo.is_started():
		_hilo.wait_to_finish()

## Reproduce un efecto. Si no existe, no hace nada y no se queja: un sonido que
## falta no puede tumbar un partido.
func toca(nombre: String, bus: Bus = Bus.EFECTOS) -> void:
	if not encendido:
		return
	var variantes: Array = banco(nombre)
	if variantes.is_empty():
		return
	var p := _voces[_siguiente % VOCES]
	_siguiente += 1
	## LA VARIANTE NO SE SORTEA CON `Azar`. `Azar` es el generador DETERMINISTA
	## de la partida: si elegir cual de las cuatro variantes suena consumiera un
	## numero de ahi, subir el volumen o jugar con los sonidos apagados daria
	## resultados distintos en la liga. Es exactamente la trampa que ya se pago
	## una vez en este proyecto con un feed cosmetico, y solo la caza el banco.
	## Aqui basta con ir rotando: el oido no distingue una rueda de un sorteo.
	p.stream = variantes[_siguiente % variantes.size()]
	p.volume_db = linear_to_db(maxf(0.001, float(volumen[bus])))
	p.play()

# --- síntesis ---------------------------------------------------------------

## Cada efecto es una receta de tonos y ruido sobre una envolvente. `sal` mueve
## la afinación y la duración un poco en cada variante.
func _sintetizar(nombre: String, sal: float) -> AudioStreamWAV:
	var tono := 0.94 + sal * 0.12      ## multiplicador de altura
	var largo := 0.90 + sal * 0.20     ## multiplicador de duración
	var m: PackedFloat32Array = PackedFloat32Array()
	match nombre:
		"silbato":
			## Dos armónicos muy juntos batiendo entre sí: es lo que hace que un
			## silbato suene a silbato y no a pitido de horno.
			m = _tono(2650.0 * tono, 0.34 * largo, 0.30, "seno")
			_mezclar(m, _tono(3980.0 * tono, 0.34 * largo, 0.16, "seno"))
			_mezclar(m, _ruido(0.34 * largo, 2400.0, 3600.0, 0.05))
		"pitido_final":
			m = _tono(2650.0 * tono, 1.10 * largo, 0.30, "seno")
			_mezclar(m, _tono(3980.0 * tono, 1.10 * largo, 0.16, "seno"))
		"gol":
			## Rugido: ruido grave que se abre, más una fanfarria de tres notas.
			m = _ruido(1.60 * largo, 300.0, 1500.0, 0.22)
			_mezclar(m, _tono(523.0 * tono, 0.9, 0.09, "sierra"), 0.05)
			_mezclar(m, _tono(659.0 * tono, 0.8, 0.09, "sierra"), 0.20)
			_mezclar(m, _tono(784.0 * tono, 1.0, 0.10, "sierra"), 0.36)
		"gol_rival":
			## El silencio incómodo: murmullo que se apaga y dos notas tristes.
			m = _ruido(1.20 * largo, 420.0, 140.0, 0.14)
			_mezclar(m, _tono(392.0 * tono, 0.16, 0.05, "sierra"), 0.05)
			_mezclar(m, _tono(311.0 * tono, 0.36, 0.05, "sierra"), 0.20)
		"roja":
			m = _tono(150.0 * tono, 0.35 * largo, 0.09, "sierra")
			_mezclar(m, _ruido(0.80 * largo, 900.0, 300.0, 0.08), 0.10)
		"amarilla":
			m = _tono(320.0 * tono, 0.18 * largo, 0.06, "cuadrada")
		"murmullo":
			## El ambiente de fondo. Ruido rosa muy filtrado y muy largo.
			m = _ruido(3.00, 200.0, 900.0, 0.05)
		"ovacion":
			m = _ruido(2.20 * largo, 500.0, 2200.0, 0.16)
		"poste":
			## Golpe seco y metálico: un tono alto que se apaga en nada.
			m = _tono(1180.0 * tono, 0.30 * largo, 0.20, "seno")
			_mezclar(m, _tono(2360.0 * tono, 0.16 * largo, 0.08, "seno"))
		"clic":
			m = _tono(880.0 * tono, 0.05, 0.05, "cuadrada")
		"moneda":
			m = _tono(1320.0 * tono, 0.08, 0.06, "seno")
			_mezclar(m, _tono(1760.0 * tono, 0.10, 0.05, "seno"), 0.05)
		"ocasion":
			## El "uuuh" de la grada cuando la pelota pasa cerca. `nombre` no
			## lleva variacion de altura por jugada -eso lo pone el navegador
			## con R(0,140) en cada disparo, aqui ya lo cubren las variantes-.
			m = _ruido(0.72 * largo, 630.0 * tono, 1008.0 * tono, 0.10)
		"atajada":
			## Manotazo del arquero mas, casi siempre, el aplauso de la grada
			## detras -el HTML lo tiraba solo un 45% de las veces; aqui suena
			## siempre porque la variedad ya la dan las cuatro variantes-.
			m.resize(int(0.68 * largo * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.40 * largo, 800.0 * tono, 500.0, 0.07))
			_mezclar(m, _tono(300.0 * tono, 0.10, 0.03, "seno"))
			_mezclar(m, _ruido(0.50, 520.0, 900.0, 0.05), 0.18)
		"falta":
			m = _ruido(0.22 * largo, 2400.0 * tono, 2300.0, 0.085)
			_mezclar(m, _tono(220.0 * tono, 0.12, 0.025, "seno"), 0.06)
		"corner":
			m.resize(int(0.65 * largo * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.18 * largo, 2300.0 * tono, 2200.0, 0.07))
			_mezclar(m, _ruido(0.45, 520.0, 780.0, 0.05), 0.20)
		"trofeo":
			## El festejo mas largo del catalogo: fanfarria de cuatro notas +
			## rugido + dos "canticos" de tribuna a los 0.7s y a los 3s -los
			## `setTimeout(...,700)` y `...,3000)` del HTML-. Por eso el buffer
			## se reserva primero a los 5s finales: `_mezclar()` no alarga el
			## array de destino, solo escribe dentro de lo que ya exista, y si
			## se empezara por la fanfarria de 0.14s el cantico de los 3s se
			## recortaria en silencio sin que nada avisara.
			m.resize(int(5.0 * largo * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.14 * largo, 0.05, "cuadrada"))
			_mezclar(m, _tono(659.0 * tono, 0.14 * largo, 0.05, "cuadrada"), 0.14)
			_mezclar(m, _tono(784.0 * tono, 0.14 * largo, 0.05, "cuadrada"), 0.28)
			_mezclar(m, _tono(1047.0 * tono, 0.50 * largo, 0.05, "cuadrada"), 0.42)
			_mezclar(m, _ruido(2.40 * largo, 700.0, 240.0, 0.15))
			_mezclar(m, _cantico(1.3), 0.70)
			_mezclar(m, _cantico(1.3), 3.00)
		## De aqui para abajo: cinco efectos que el HTML nunca tuvo -no hay
		## `sfx('lesion')` ni `sfx('cambio')` ni nada parecido a fichaje o a
		## ascenso/descenso en `juego.js`-. Antes de esta sesion esos momentos
		## sonaban a silencio. Son composicion propia con el mismo instrumental
		## de siempre (osciladores + ruido filtrado), no un port de nada.
		"lesion":
			## Un golpe sordo y una caida de dos notas: preocupado, no tragico.
			m = _ruido(0.35 * largo, 260.0 * tono, 90.0, 0.10)
			_mezclar(m, _tono(200.0 * tono, 0.28 * largo, 0.07, "sierra"), 0.02)
			_mezclar(m, _tono(140.0 * tono, 0.30 * largo, 0.05, "sierra"), 0.16)
		"cambio":
			## Dos pitidos de pizarra, neutros: ni buena ni mala noticia.
			m = _tono(700.0 * tono, 0.09, 0.05, "cuadrada")
			_mezclar(m, _tono(900.0 * tono, 0.09, 0.05, "cuadrada"), 0.12)
		"fichaje":
			## Un arpegio corto que sube mas un brillo de ruido agudo: "trato
			## cerrado". Mas pequeno que "trofeo" -esto pasa cada semana, no
			## una vez al año-.
			m.resize(int(0.60 * largo * float(FRECUENCIA)))
			_mezclar(m, _tono(440.0 * tono, 0.12 * largo, 0.05, "seno"))
			_mezclar(m, _tono(554.0 * tono, 0.12 * largo, 0.05, "seno"), 0.10)
			_mezclar(m, _tono(659.0 * tono, 0.22 * largo, 0.06, "seno"), 0.20)
			_mezclar(m, _ruido(0.40 * largo, 1800.0, 2600.0, 0.04), 0.02)
		"logro":
			## El "tin-TON" de un logro desbloqueado, al estilo de las consolas:
			## dos notas limpias que SUBEN una quinta, con un brillo corto
			## encima. Tiene que reconocerse en medio milisegundo y no pisar lo
			## que este sonando: por eso es agudo, seco y corto -0,45 s contra
			## los 5 de "trofeo"-. Un logro no es un titulo; es un guino.
			m.resize(int(0.45 * largo * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.10 * largo, 0.03, "seno"))
			_mezclar(m, _tono(1318.0 * tono, 0.30 * largo, 0.04, "seno"), 0.09)
			_mezclar(m, _ruido(0.16 * largo, 3000.0, 5000.0, 0.03), 0.08)
		"ascenso":
			## Una subida de tres escalones mas una nota larga y un oleaje de
			## grada: mas grande que "fichaje", mas corto que "trofeo" -no hay
			## cantico, esto no es un titulo-.
			m.resize(int(1.6 * largo * float(FRECUENCIA)))
			_mezclar(m, _tono(392.0 * tono, 0.18 * largo, 0.06, "sierra"))
			_mezclar(m, _tono(494.0 * tono, 0.18 * largo, 0.06, "sierra"), 0.16)
			_mezclar(m, _tono(587.0 * tono, 0.18 * largo, 0.06, "sierra"), 0.32)
			_mezclar(m, _tono(784.0 * tono, 0.55 * largo, 0.08, "sierra"), 0.48)
			_mezclar(m, _ruido(1.10 * largo, 400.0, 1600.0, 0.12), 0.10)
		"descenso":
			## El espejo del ascenso: ruido que se apaga y tres escalones
			## bajando, largo porque es un golpe que se asienta, no un
			## sobresalto como "gol_rival".
			m.resize(int(1.6 * largo * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.30 * largo, 500.0, 160.0, 0.12))
			_mezclar(m, _tono(311.0 * tono, 0.30 * largo, 0.05, "sierra"), 0.05)
			_mezclar(m, _tono(262.0 * tono, 0.30 * largo, 0.05, "sierra"), 0.30)
			_mezclar(m, _tono(196.0 * tono, 0.50 * largo, 0.06, "sierra"), 0.60)
		## ---------------------------------------------------------------
		##  LA SEGUNDA TANDA
		## ---------------------------------------------------------------
		##
		## Veintiséis efectos más, todos con el mismo instrumental de siempre
		## —osciladores y ruido filtrado—. La razón de que existan es que medio
		## juego seguía siendo mudo: pasabas una semana, firmabas un contrato,
		## te llegaba un correo, guardabas la partida y no sonaba nada.
		##
		## LA REGLA DE LA INTERFAZ. Todo lo que va al bus INTERFAZ dura menos de
		## 0,2 s y suena bajo. Un clic que se oye es un clic que molesta a la
		## tercera vez, y en este juego se hacen miles.
		"clic_suave":
			## El clic de las pestañas: más apagado que "clic", porque cambiar de
			## pantalla se hace veinte veces por minuto.
			m = _tono(1180.0 * tono, 0.035, 0.028, "seno")
		"puerta":
			## Puerta corredera de cristal: el soplido de las hojas (ruido que
			## baja de agudo a grave) y un golpe sordo al llegar al tope.
			m.resize(int(0.75 * largo * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.6 * largo, 2600.0 * tono, 500.0, 0.10))
			_mezclar(m, _tono(95.0 * tono, 0.12, 0.10, "seno"), 0.58 * largo)
			_mezclar(m, _ruido(0.08, 900.0, 300.0, 0.06), 0.58 * largo)
		"paso":
			## Un paso de suela sobre baldosa: golpe grave muy corto y un roce.
			m = _tono(120.0 * tono, 0.07, 0.07, "seno")
			_mezclar(m, _ruido(0.06, 1800.0 * tono, 600.0, 0.05))
		"abrir":
			## Un panel que se abre: dos notas que SUBEN, muy cortas.
			m.resize(int(0.14 * float(FRECUENCIA)))
			_mezclar(m, _tono(660.0 * tono, 0.05, 0.030, "seno"))
			_mezclar(m, _tono(990.0 * tono, 0.06, 0.026, "seno"), 0.045)
		"cerrar":
			## Y el espejo: las mismas dos notas al revés.
			m.resize(int(0.14 * float(FRECUENCIA)))
			_mezclar(m, _tono(990.0 * tono, 0.05, 0.028, "seno"))
			_mezclar(m, _tono(660.0 * tono, 0.06, 0.024, "seno"), 0.045)
		"error":
			## El "no se puede": dos notas juntas y disonantes. No es un castigo,
			## es un aviso —por eso es corto y no grave—.
			m.resize(int(0.22 * float(FRECUENCIA)))
			_mezclar(m, _tono(220.0 * tono, 0.16, 0.055, "cuadrada"))
			_mezclar(m, _tono(233.0 * tono, 0.16, 0.045, "cuadrada"))
		"aviso":
			## El de una noticia que hay que mirar. Sube, y se queda arriba.
			m.resize(int(0.34 * float(FRECUENCIA)))
			_mezclar(m, _tono(784.0 * tono, 0.10, 0.045, "seno"))
			_mezclar(m, _tono(1047.0 * tono, 0.22, 0.040, "seno"), 0.09)
		"correo":
			## Un sobre que llega: golpe de papel y campanita.
			m.resize(int(0.36 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.09, 1800.0, 900.0, 0.045))
			_mezclar(m, _tono(1568.0 * tono, 0.24, 0.032, "seno"), 0.07)
		"guardado":
			## Tres notas que bajan, tranquilas: la partida está a salvo.
			m.resize(int(0.44 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.032, "seno"))
			_mezclar(m, _tono(784.0 * tono, 0.10, 0.030, "seno"), 0.09)
			_mezclar(m, _tono(587.0 * tono, 0.22, 0.032, "seno"), 0.18)
		"telefono":
			## El representante que llama. Dos ciclos del timbre de un fijo, que
			## es lo que se reconoce al instante como "te están llamando".
			m.resize(int(1.10 * float(FRECUENCIA)))
			for ciclo in 2:
				var t0f := float(ciclo) * 0.55
				for rep in 6:
					_mezclar(m, _tono(1000.0 * tono, 0.028, 0.030, "seno"), t0f + float(rep) * 0.036)
					_mezclar(m, _tono(1250.0 * tono, 0.028, 0.024, "seno"), t0f + float(rep) * 0.036)

		## ---------------------------------------------------------------
		##  LO QUE PASA EN EL CAMPO
		## ---------------------------------------------------------------
		"saque_inicial":
			## El pitido de arranque: uno solo, más largo que el de falta, con el
			## murmullo de la grada subiendo por detrás.
			m.resize(int(1.40 * float(FRECUENCIA)))
			_mezclar(m, _tono(2650.0 * tono, 0.50, 0.26, "seno"))
			_mezclar(m, _tono(3980.0 * tono, 0.50, 0.13, "seno"))
			_mezclar(m, _ruido(1.20, 300.0, 1400.0, 0.14), 0.18)
		"penal":
			## LA TENSIÓN. No es un golpe: es un silencio que se llena. Un
			## redoble grave que crece y no resuelve —lo que resuelve es lo que
			## suene después, "gol" o "atajada"—.
			m.resize(int(1.80 * float(FRECUENCIA)))
			for i in 26:
				var t0p := float(i) * 0.065
				_mezclar(m, _ruido(0.05, 110.0, 70.0, 0.03 + float(i) * 0.0035), t0p)
			_mezclar(m, _tono(98.0 * tono, 1.60, 0.05, "sierra"))
		"penal_fallado":
			## El "ooooh" que se corta en seco y el golpe del poste que no fue.
			m.resize(int(1.20 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.55, 700.0, 1100.0, 0.13))
			_mezclar(m, _ruido(0.60, 420.0, 120.0, 0.09), 0.45)
			_mezclar(m, _tono(174.0 * tono, 0.40, 0.05, "sierra"), 0.40)
		"travesano":
			## Como el poste pero más agudo y con más cola: el larguero canta.
			m = _tono(1560.0 * tono, 0.45 * largo, 0.20, "seno")
			_mezclar(m, _tono(3120.0 * tono, 0.24 * largo, 0.07, "seno"))
			_mezclar(m, _ruido(0.50, 600.0, 900.0, 0.06), 0.06)
		"remate_fuera":
			## El silbido del balón y el suspiro corto de la grada.
			m.resize(int(0.80 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.20, 3000.0, 800.0, 0.06))
			_mezclar(m, _ruido(0.55, 560.0, 300.0, 0.07), 0.16)
		"var":
			## El VAR: tres pitidos electrónicos iguales, fríos, sin grada. Es a
			## propósito la cosa menos futbolística del catálogo.
			m.resize(int(0.90 * float(FRECUENCIA)))
			for i in 3:
				_mezclar(m, _tono(1400.0 * tono, 0.10, 0.05, "cuadrada"), float(i) * 0.22)
		"segunda_amarilla":
			## Amarilla + roja pegadas: se oye la primera y se entiende la
			## segunda antes de leer nada.
			m.resize(int(0.90 * float(FRECUENCIA)))
			_mezclar(m, _tono(320.0 * tono, 0.16, 0.055, "cuadrada"))
			_mezclar(m, _tono(150.0 * tono, 0.34, 0.085, "sierra"), 0.22)
			_mezclar(m, _ruido(0.60, 900.0, 300.0, 0.07), 0.26)
		"fuera_de_juego":
			## Un pitido corto y el murmullo de protesta: nadie aplaude un fuera
			## de juego.
			m.resize(int(0.90 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.16, 2400.0, 2300.0, 0.075))
			_mezclar(m, _ruido(0.65, 380.0, 220.0, 0.07), 0.14)

		## ---------------------------------------------------------------
		##  LA GRADA
		## ---------------------------------------------------------------
		"tambor":
			## El bombo de la barra: cuatro golpes graves con su tiempo. Es el
			## sonido que hace que un estadio suene lleno aunque no haya nadie.
			m.resize(int(2.20 * float(FRECUENCIA)))
			for i in 8:
				_mezclar(m, _ruido(0.16, 90.0, 55.0, 0.16 if i % 2 == 0 else 0.09), float(i) * 0.26)
				_mezclar(m, _tono(62.0 * tono, 0.20, 0.10, "seno"), float(i) * 0.26)
		"trompeta":
			## Las tres notas de trompeta de tribuna. Desafinada a propósito: en
			## una grada nadie afina.
			m.resize(int(1.30 * float(FRECUENCIA)))
			_mezclar(m, _tono(392.0 * tono * 1.01, 0.30, 0.055, "sierra"))
			_mezclar(m, _tono(523.0 * tono * 0.99, 0.30, 0.055, "sierra"), 0.28)
			_mezclar(m, _tono(659.0 * tono, 0.55, 0.060, "sierra"), 0.56)
		"abucheo":
			## El silbido de la grada contra los suyos. Ruido agudo y largo, sin
			## nada de tono: no hay melodía en una pitada.
			m = _ruido(2.20 * largo, 1900.0, 2600.0, 0.13)
			_mezclar(m, _ruido(2.00, 700.0, 500.0, 0.06), 0.10)
		"aplauso":
			## Aplauso corto y educado. Es el de "buen intento", no el de gol.
			m = _ruido(0.90 * largo, 1400.0, 2000.0, 0.09)
		"cantico":
			## El cántico de tribuna, ya solo: existía dentro de "trofeo" y no se
			## podía tirar por su cuenta.
			m = _cantico(1.0)
		"bengala":
			## El siseo de una bengala: ruido agudo constante, sin ataque y sin
			## final —se enciende y ya está—.
			m = _ruido(2.60 * largo, 4200.0, 3400.0, 0.055)
		"lluvia_ambiente":
			## Fondo de partido pasado por agua. Muy filtrado y muy plano: si
			## tuviera forma, se notaría que se repite.
			m = _ruido(3.20, 2600.0, 3000.0, 0.045)
		"vestuario":
			## El eco de un vestuario vacío: un golpe de puerta y el zumbido de
			## los fluorescentes.
			m.resize(int(1.80 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.22, 240.0, 90.0, 0.10))
			_mezclar(m, _tono(100.0, 1.60, 0.018, "seno"), 0.05)
			_mezclar(m, _tono(150.0, 1.60, 0.010, "seno"), 0.05)
		"flashes":
			## Las cámaras de la sala de prensa: seis disparos irregulares.
			m.resize(int(1.30 * float(FRECUENCIA)))
			for i in 7:
				_mezclar(m, _ruido(0.045, 5200.0, 2200.0, 0.05), float(i) * 0.17 + float(i % 3) * 0.03)

		## ---------------------------------------------------------------
		##  LA GESTIÓN
		## ---------------------------------------------------------------
		"contrato":
			## El bolígrafo y el sello: firmar tiene que sonar a papel, no a
			## fanfarria. La fanfarria ya la tiene "fichaje".
			m.resize(int(0.70 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.30, 3200.0, 1400.0, 0.035))
			_mezclar(m, _ruido(0.10, 300.0, 120.0, 0.11), 0.34)
			_mezclar(m, _tono(523.0 * tono, 0.22, 0.030, "seno"), 0.40)
		"despido":
			## Te echaron. Una nota grave, larga y sola. Nada de ruido de grada:
			## esto no pasa en el campo.
			m.resize(int(2.20 * float(FRECUENCIA)))
			_mezclar(m, _tono(87.0 * tono, 1.90, 0.09, "sierra"))
			_mezclar(m, _tono(131.0 * tono, 1.10, 0.045, "seno"), 0.30)
		"dinero_entra":
			## Caja registradora corta: dos monedas que suben.
			m.resize(int(0.32 * float(FRECUENCIA)))
			_mezclar(m, _tono(1320.0 * tono, 0.09, 0.045, "seno"))
			_mezclar(m, _tono(1980.0 * tono, 0.16, 0.038, "seno"), 0.07)
		"dinero_sale":
			## Y las mismas dos, bajando.
			m.resize(int(0.32 * float(FRECUENCIA)))
			_mezclar(m, _tono(1320.0 * tono, 0.09, 0.040, "seno"))
			_mezclar(m, _tono(880.0 * tono, 0.16, 0.034, "seno"), 0.07)
		"sorteo":
			## El bombo girando: bolas de plástico chocando. Ruido corto repetido
			## catorce veces a destiempo, que es lo que suena a bombo.
			m.resize(int(1.80 * float(FRECUENCIA)))
			for i in 16:
				var tb := float(i) * 0.11 + float((i * 7) % 5) * 0.014
				_mezclar(m, _ruido(0.05, 1500.0 + float((i * 13) % 900), 700.0, 0.055), tb)
		"cronometro":
			## Los últimos minutos: un tictac que se acelera. No avisa de nada
			## que no sepas; lo que hace es que se te note en el cuerpo.
			m.resize(int(2.40 * float(FRECUENCIA)))
			var t0c := 0.0
			var paso_c := 0.34
			while t0c < 2.2:
				_mezclar(m, _tono(1700.0 * tono, 0.03, 0.045, "cuadrada"), t0c)
				t0c += paso_c
				paso_c = maxf(0.10, paso_c * 0.88)
		"himno":
			## Ocho notas de himno de club, en modo mayor y con eco de estadio.
			## No es el himno de nadie: es un motivo genérico que suena a uno.
			m.resize(int(3.60 * float(FRECUENCIA)))
			var notas := [392.0, 392.0, 523.0, 494.0, 440.0, 392.0, 349.0, 392.0]
			for i in notas.size():
				var t0h := float(i) * 0.40
				var hz: float = float(notas[i]) * tono
				_mezclar(m, _tono(hz, 0.42, 0.050, "sierra"), t0h)
				_mezclar(m, _tono(hz * 2.0, 0.34, 0.020, "seno"), t0h)
				## El eco: la misma nota 90 ms después y a un tercio de volumen.
				_mezclar(m, _tono(hz, 0.34, 0.017, "sierra"), t0h + 0.09)
			_mezclar(m, _ruido(3.40, 240.0, 700.0, 0.035))
		"fin_temporada":
			## El cierre del año: acorde largo que se abre y se apaga. Ni
			## celebración ni derrota —la temporada se acabó y ya está—.
			m.resize(int(3.00 * float(FRECUENCIA)))
			for hz2 in [262.0, 330.0, 392.0, 523.0]:
				_mezclar(m, _tono(float(hz2) * tono, 2.60, 0.045, "seno"), 0.0)
			_mezclar(m, _ruido(2.40, 500.0, 200.0, 0.07), 0.20)

		## ---------------------------------------------------------------
		##  LOS QUE PEDÍA EL LEEME: UNO PROPIO POR EVENTO
		## ---------------------------------------------------------------
		##
		## El pendiente nº2 del LEEME, en su orden: «candidatos a sonido propio,
		## por orden de cuánto cambian la partida». Hasta ahora nueve tipos de
		## `Aviso` se repartían cinco recetas, así que cobrar una cláusula sonaba
		## exactamente igual que pagar una obra.
		"clausula":
			## Te pagaron la cláusula: dinero mucho, pero no lo elegiste tú. Por
			## eso sube y termina con un golpe seco, no con una fanfarria.
			m.resize(int(1.10 * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.12, 0.045, "seno"))
			_mezclar(m, _tono(784.0 * tono, 0.12, 0.045, "seno"), 0.11)
			_mezclar(m, _tono(1047.0 * tono, 0.40, 0.050, "seno"), 0.22)
			_mezclar(m, _ruido(0.30, 200.0, 90.0, 0.10), 0.55)
		"lesion_grave":
			## La versión larga de "lesion": el mismo golpe, pero la caída sigue
			## bajando y no se recupera. Media temporada fuera se tiene que oír.
			m.resize(int(2.20 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.40, 260.0, 80.0, 0.12))
			_mezclar(m, _tono(196.0 * tono, 0.50, 0.070, "sierra"), 0.03)
			_mezclar(m, _tono(147.0 * tono, 0.60, 0.060, "sierra"), 0.42)
			_mezclar(m, _tono(110.0 * tono, 1.20, 0.055, "sierra"), 0.95)
		"oferta":
			## Llega una oferta por uno de los tuyos. Interrogación: dos notas que
			## suben y se quedan colgadas sin resolver.
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(440.0 * tono, 0.14, 0.040, "seno"))
			_mezclar(m, _tono(587.0 * tono, 0.34, 0.042, "seno"), 0.13)
		"contrato_vence":
			## El aviso de que se te va gratis. Un tictac doble y una nota baja:
			## esto es un plazo, no una noticia.
			m.resize(int(0.90 * float(FRECUENCIA)))
			_mezclar(m, _tono(1500.0 * tono, 0.04, 0.038, "cuadrada"))
			_mezclar(m, _tono(1500.0 * tono, 0.04, 0.038, "cuadrada"), 0.20)
			_mezclar(m, _tono(233.0 * tono, 0.45, 0.050, "sierra"), 0.38)
		"obra":
			## La obra terminada: un martillazo y el acorde de "ya está". Es la
			## única del grupo que suena a construcción y no a despacho.
			m.resize(int(1.30 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.13))
			_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.11), 0.16)
			for hz3 in [349.0, 440.0, 523.0]:
				_mezclar(m, _tono(float(hz3) * tono, 0.80, 0.040, "seno"), 0.34)
		"venta":
			## Venta cerrada: la caja de "dinero_entra" con el sello de "contrato"
			## detrás. Vender es cobrar y firmar a la vez.
			m.resize(int(0.80 * float(FRECUENCIA)))
			_mezclar(m, _tono(1320.0 * tono, 0.09, 0.045, "seno"))
			_mezclar(m, _tono(1980.0 * tono, 0.14, 0.038, "seno"), 0.07)
			_mezclar(m, _ruido(0.09, 300.0, 120.0, 0.10), 0.30)
		"ronda_superada":
			## Pasas de ronda: no es un título -eso es "trofeo"-, es seguir vivo.
			## Cuatro notas que suben y la grada detrás, y se acaba.
			m.resize(int(1.80 * float(FRECUENCIA)))
			_mezclar(m, _tono(330.0 * tono, 0.16, 0.050, "sierra"))
			_mezclar(m, _tono(392.0 * tono, 0.16, 0.050, "sierra"), 0.14)
			_mezclar(m, _tono(494.0 * tono, 0.16, 0.050, "sierra"), 0.28)
			_mezclar(m, _tono(659.0 * tono, 0.60, 0.060, "sierra"), 0.42)
			_mezclar(m, _ruido(1.30, 500.0, 1700.0, 0.11), 0.20)
		## EL SONIDO DE GOL QUE SE ELIGE EN EL ESTADIO -`sfxGol(estilo)` del HTML,
		## sus ocho recetas-. `EstadioPropio.ajustes["sonidoGol"]` se podía
		## elegir y pagar, pero `Sonido` tocaba siempre el mismo "gol" fijo: era
		## un desplegable que no hacía nada. Todas llevan debajo el mismo
		## rugido de grada (`ruido(0,2.1,700,220,0.17)`, que en el HTML va antes
		## del `if`), y los `setTimeout(cantico...)` son `_cantico()` mezclado
		## con retraso. Por eso cada una reserva el buffer entero PRIMERO: la
		## trampa ya pagada con "trofeo" -`_mezclar()` no alarga el destino-.
		## Diferencias honestas: `_tono()` no tiene glissando ni onda triangular,
		## así que la sirena se hace por tramos y el triángulo es un seno.
		"gol_bombo":
			m.resize(int(3.3 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			for golpe_b in 7:
				_bombo(m, float(golpe_b) * 0.42, 0.17)
			var trompeta := [523.0, 523.0, 659.0, 784.0, 784.0, 659.0]
			for nt in trompeta.size():
				_mezclar(m, _tono(float(trompeta[nt]) * tono, 0.34, 0.045, "sierra"), 0.5 + float(nt) * 0.42)
			_mezclar(m, _cantico(1.25), 1.0)
		"gol_sirena":
			m.resize(int(3.8 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			var tramos := [88.0, 102.0, 120.0, 130.0, 124.0, 118.0]
			for tr in tramos.size():
				_mezclar(m, _tono(float(tramos[tr]) * tono, 0.70, 0.09, "sierra"), float(tr) * 0.55)
			_mezclar(m, _tono(66.0 * tono, 3.40, 0.05, "seno"))
		"gol_campana":
			m.resize(int(5.3 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			var parciales := [1.0, 2.76, 5.4, 8.9]
			for golpe_c in 4:
				var t_camp := float(golpe_c) * 0.95
				for pj in parciales.size():
					_mezclar(m, _tono(262.0 * float(parciales[pj]) * tono, 2.4 / float(pj + 1), 0.055 / float(pj + 1), "seno"), t_camp)
				_mezclar(m, _ruido(0.12, 3200.0, 1800.0, 0.03), t_camp)
			_mezclar(m, _cantico(1.1), 1.8)
		"gol_organo":
			m.resize(int(3.6 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			var acordes := [[262.0, 330.0, 392.0], [294.0, 370.0, 440.0], [349.0, 440.0, 523.0], [392.0, 494.0, 587.0]]
			for ac in acordes.size():
				for f_org in (acordes[ac] as Array):
					_mezclar(m, _tono(float(f_org) * tono, 0.62, 0.035, "sierra"), float(ac) * 0.55)
					_mezclar(m, _tono(float(f_org) * 2.0 * tono, 0.60, 0.018, "seno"), float(ac) * 0.55)
			_mezclar(m, _cantico(1.15), 1.4)
		"gol_explosion":
			m.resize(int(3.3 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			_mezclar(m, _ruido(0.50, 1800.0, 60.0, 0.28))
			_mezclar(m, _tono(44.0 * tono, 0.70, 0.20, "seno"))
			_mezclar(m, _ruido(1.10, 900.0, 200.0, 0.09), 0.42)
			for chispa in 5:
				_mezclar(m, _ruido(0.14, 2600.0, 1400.0, 0.06), 1.1 + float(chispa) * 0.17)
			_mezclar(m, _cantico(1.35), 1.1)
		"gol_sintetico":
			m.resize(int(2.2 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.05, "cuadrada"))
			_mezclar(m, _tono(1174.0 * tono, 0.10, 0.05, "cuadrada"), 0.09)
			_mezclar(m, _tono(1568.0 * tono, 0.50, 0.06, "cuadrada"), 0.18)
			_mezclar(m, _tono(98.0 * tono, 0.90, 0.09, "sierra"))
			_mezclar(m, _ruido(0.90, 4200.0, 900.0, 0.06), 0.16)
			for eco in 3:
				_mezclar(m, _tono(1568.0 * tono, 0.12, 0.03, "seno"), 0.7 + float(eco) * 0.14)
		"gol_tambores":
			m.resize(int(3.4 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			for golpe_t in 16:
				var t_tam := float(golpe_t) * 0.19
				if golpe_t % 4 == 0:
					_bombo(m, t_tam, 0.15)
				else:
					_mezclar(m, _ruido(0.10, 1400.0, 600.0, 0.055), t_tam)
				if golpe_t % 2 == 1:
					_mezclar(m, _ruido(0.06, 5200.0, 3000.0, 0.03), t_tam + 0.09)
			_mezclar(m, _cantico(1.3), 1.2)
		"gol_silencio":
			## "Solo la gente": sin efecto, el rugido puro y dos cánticos.
			m.resize(int(4.8 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			_mezclar(m, _ruido(2.60, 520.0, 180.0, 0.11), 0.1)
			_mezclar(m, _cantico(1.4), 0.5)
			_mezclar(m, _cantico(1.2), 2.6)

		## =================================================================
		##  TERCERA TANDA (21-9-2026): de 65 a ~200, a pedido del usuario.
		##  Mismo instrumental de siempre (osciladores + ruido filtrado),
		##  recetas mas breves que las primeras dos tandas a proposito -son
		##  135 nuevas de una vez, no vale la pena un ensayo de una pagina
		##  por cada una-, pero cada una es una composicion propia, no una
		##  copia con el nombre cambiado.
		## =================================================================

		## --- Mas momentos de partido ---
		"saque_banda":
			m = _ruido(0.18 * largo, 1200.0 * tono, 900.0, 0.05)
		"saque_puerta":
			m = _tono(400.0 * tono, 0.14, 0.05, "seno")
			_mezclar(m, _ruido(0.30, 700.0, 300.0, 0.04), 0.05)
		"fuera_de_banda":
			m = _ruido(0.30 * largo, 1500.0, 600.0, 0.06)
		"rebote":
			m = _tono(900.0 * tono, 0.06, 0.10, "seno")
			_mezclar(m, _tono(700.0 * tono, 0.05, 0.07, "seno"), 0.05)
		"palo_doble":
			## Como "poste" pero DOS golpes seguidos -la mala suerte redoblada.
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(1180.0 * tono, 0.20, 0.18, "seno"))
			_mezclar(m, _tono(1180.0 * tono, 0.20, 0.16, "seno"), 0.22)
		"atajada_punos":
			m.resize(int(0.40 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.14, 700.0, 200.0, 0.14))
			_mezclar(m, _tono(150.0 * tono, 0.10, 0.05, "seno"))
		"atajada_pies":
			m.resize(int(0.35 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.10, 900.0, 400.0, 0.10))
			_mezclar(m, _tono(250.0 * tono, 0.12, 0.04, "seno"), 0.03)
		"gol_cabeza":
			m.resize(int(2.6 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.80, 700.0, 220.0, 0.17))
			_mezclar(m, _tono(220.0 * tono, 0.14, 0.08, "seno"))
			_mezclar(m, _cantico(1.1), 0.6)
		"gol_chilena":
			## La obra de arte: el rugido mas largo del catalogo, la sorpresa
			## primero -silencio breve- y despues explota.
			m.resize(int(3.6 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.30, 2000.0, 500.0, 0.05), 0.0)
			_mezclar(m, _ruido(2.60, 700.0, 220.0, 0.22), 0.35)
			_mezclar(m, _cantico(1.5), 0.9)
			_mezclar(m, _cantico(1.3), 2.4)
		"gol_falta":
			m.resize(int(2.4 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.80, 700.0, 220.0, 0.17))
			_mezclar(m, _tono(1560.0 * tono, 0.30, 0.10, "seno"))
			_mezclar(m, _cantico(1.1), 0.5)
		"gol_penal":
			m.resize(int(2.4 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.80, 700.0, 220.0, 0.20))
			_mezclar(m, _tono(660.0 * tono, 0.30, 0.09, "sierra"))
			_mezclar(m, _cantico(1.2), 0.5)
		"autogol":
			## Incomodo, no triste del todo: un acorde raro que no resuelve.
			m.resize(int(1.6 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.00, 500.0, 200.0, 0.09))
			_mezclar(m, _tono(233.0 * tono, 0.40, 0.05, "sierra"), 0.10)
			_mezclar(m, _tono(247.0 * tono, 0.40, 0.05, "sierra"), 0.20)
		"mano_penal":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(1400.0 * tono, 0.10, 0.05, "cuadrada"))
			_mezclar(m, _ruido(0.40, 900.0, 300.0, 0.07), 0.12)
		"simulacion":
			## El "uy" desconfiado de la grada: ruido corto y disonante.
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.35, 800.0, 600.0, 0.08))
			_mezclar(m, _tono(310.0 * tono, 0.20, 0.03, "sierra"), 0.05)
		"var_anulado":
			m.resize(int(1.20 * float(FRECUENCIA)))
			for i2 in 3:
				_mezclar(m, _tono(1400.0 * tono, 0.10, 0.05, "cuadrada"), float(i2) * 0.22)
			_mezclar(m, _tono(180.0 * tono, 0.50, 0.06, "sierra"), 0.70)
		"medio_tiempo":
			m = _tono(2650.0 * tono, 0.60 * largo, 0.28, "seno")
			_mezclar(m, _tono(3980.0 * tono, 0.60 * largo, 0.14, "seno"))
		"reanudacion":
			m.resize(int(1.0 * float(FRECUENCIA)))
			_mezclar(m, _tono(2650.0 * tono, 0.30, 0.24, "seno"))
			_mezclar(m, _ruido(0.80, 300.0, 900.0, 0.08), 0.10)
		"calentamiento":
			m = _ruido(1.80 * largo, 400.0, 700.0, 0.05)
			_mezclar(m, _tono(300.0, 0.10, 0.03, "seno"), 0.40)
		"salida_tunel":
			m.resize(int(2.2 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.00, 300.0, 1400.0, 0.16))
		"presentacion_alineaciones":
			m.resize(int(1.6 * float(FRECUENCIA)))
			_mezclar(m, _tono(440.0 * tono, 0.16, 0.05, "seno"))
			_mezclar(m, _tono(554.0 * tono, 0.16, 0.05, "seno"), 0.14)
			_mezclar(m, _tono(659.0 * tono, 0.40, 0.06, "seno"), 0.28)
		"despeje":
			m = _tono(500.0 * tono, 0.10, 0.10, "seno")
			_mezclar(m, _ruido(0.14, 700.0, 300.0, 0.05))
		"entrada_dura":
			m.resize(int(0.40 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.16, 300.0, 100.0, 0.13))
			_mezclar(m, _tono(140.0 * tono, 0.12, 0.04, "sierra"), 0.02)
		"recuperacion_balon":
			m = _tono(700.0 * tono, 0.08, 0.07, "seno")
		"pase_largo":
			m = _ruido(0.35 * largo, 2200.0, 500.0, 0.06)
		"control_balon":
			m = _tono(600.0 * tono, 0.05, 0.06, "seno")

		## --- Mas grada ---
		"ola_mexicana":
			## Un barrido de intensidad, izquierda a derecha: ruido que crece
			## y decrece en oleada.
			m.resize(int(2.40 * float(FRECUENCIA)))
			for i3 in 6:
				_mezclar(m, _ruido(0.55, 1200.0, 2000.0, 0.10), float(i3) * 0.30)
		"silbido_agudo":
			m = _tono(3200.0 * tono, 0.60 * largo, 0.08, "seno")
		"coro_rival":
			m = _cantico(0.8)
			_mezclar(m, _ruido(0.30, 1800.0, 2200.0, 0.04))
		"pitos_arbitro":
			m = _ruido(1.60 * largo, 2200.0, 2600.0, 0.12)
		"bocina_vuvuzela":
			m = _tono(233.0 * tono, 1.80 * largo, 0.10, "sierra")
			_mezclar(m, _tono(235.5 * tono, 1.80 * largo, 0.08, "sierra"))
		"tambor_visitante":
			m.resize(int(1.80 * float(FRECUENCIA)))
			for i4 in 6:
				_mezclar(m, _ruido(0.14, 85.0, 50.0, 0.13), float(i4) * 0.30)
		"suspiro_grada":
			m = _ruido(0.60 * largo, 900.0, 300.0, 0.09)
		"alarido_atajada":
			m = _ruido(1.20 * largo, 500.0, 2000.0, 0.14)
			_mezclar(m, _cantico(0.6), 0.3)
		"tension_publico":
			m = _ruido(2.80, 250.0, 700.0, 0.06)
		"silbidos_impaciencia":
			m = _ruido(1.80 * largo, 2000.0, 2400.0, 0.09)
		"ultimo_minuto":
			m.resize(int(1.40 * float(FRECUENCIA)))
			var t0u := 0.0
			var paso_u := 0.30
			while t0u < 1.3:
				_mezclar(m, _tono(1900.0 * tono, 0.03, 0.04, "cuadrada"), t0u)
				t0u += paso_u
				paso_u = maxf(0.08, paso_u * 0.85)
		"descuento_anunciado":
			m.resize(int(0.70 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.04, "seno"))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.04, "seno"), 0.30)
		"grada_de_pie":
			m = _ruido(2.00 * largo, 500.0, 2200.0, 0.16)
		"bufanda_alzada":
			m = _cantico(1.0)
		"pancarta_desplegada":
			m = _ruido(1.20 * largo, 1400.0, 400.0, 0.05)
		"humo_bengala":
			m = _ruido(1.80 * largo, 3800.0, 3000.0, 0.045)
		"cornetin":
			m = _tono(587.0 * tono, 0.40 * largo, 0.07, "sierra")
		"campanas_iglesia":
			m.resize(int(2.0 * float(FRECUENCIA)))
			for hz4 in [523.0, 659.0]:
				_mezclar(m, _tono(float(hz4) * tono, 1.80, 0.05, "seno"))
		"animador_grada":
			m = _tono(500.0 * tono, 0.30 * largo, 0.06, "cuadrada")
			_mezclar(m, _ruido(0.40, 1400.0, 2000.0, 0.05), 0.28)
		"eco_estadio":
			m.resize(int(2.2 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.30, 900.0, 300.0, 0.10))
			_mezclar(m, _ruido(0.30, 900.0, 300.0, 0.04), 0.35)
		"lluvia_fuerte":
			m = _ruido(3.20, 2800.0, 3200.0, 0.08)
		"viento_fuerte":
			m = _ruido(3.20, 300.0, 700.0, 0.07)
		"trueno":
			m = _ruido(1.60 * largo, 120.0, 40.0, 0.20)
		"multitud_entrando":
			m = _ruido(3.00, 400.0, 900.0, 0.06)
		"multitud_saliendo":
			m = _ruido(3.00, 700.0, 350.0, 0.06)

		## --- Mas gestion / carrera ---
		"entrenamiento":
			m.resize(int(1.0 * float(FRECUENCIA)))
			for i5 in 3:
				_mezclar(m, _tono(600.0 * tono, 0.06, 0.05, "seno"), float(i5) * 0.30)
		"sesion_tactica":
			m = _tono(700.0 * tono, 0.10, 0.04, "cuadrada")
			_mezclar(m, _tono(900.0 * tono, 0.10, 0.04, "cuadrada"), 0.14)
		"rueda_prensa_pregunta":
			m = _tono(500.0 * tono, 0.12, 0.05, "seno")
		"rueda_prensa_aplauso":
			m = _ruido(0.80 * largo, 1400.0, 2000.0, 0.08)
		"scouting_informe":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.10, 1800.0, 900.0, 0.04))
			_mezclar(m, _tono(1200.0 * tono, 0.20, 0.03, "seno"), 0.08)
		"oferta_rechazada":
			m = _tono(220.0 * tono, 0.30, 0.05, "sierra")
		"oferta_aceptada":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.14, 0.05, "seno"))
			_mezclar(m, _tono(659.0 * tono, 0.22, 0.05, "seno"), 0.13)
		"renovacion":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.30, 3200.0, 1400.0, 0.03))
			_mezclar(m, _tono(587.0 * tono, 0.24, 0.030, "seno"), 0.36)
		"prestamo":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _tono(660.0 * tono, 0.10, 0.04, "seno"))
			_mezclar(m, _tono(550.0 * tono, 0.16, 0.03, "seno"), 0.10)
		"veto_fichaje":
			m = _tono(196.0 * tono, 0.40, 0.06, "sierra")
		"mercado_cierra":
			m.resize(int(1.20 * float(FRECUENCIA)))
			for i6 in 4:
				_mezclar(m, _tono(1500.0 * tono, 0.04, 0.038, "cuadrada"), float(i6) * 0.24)
		"premio_individual":
			m.resize(int(1.00 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.12, 0.04, "seno"))
			_mezclar(m, _tono(1318.0 * tono, 0.40, 0.05, "seno"), 0.12)
			_mezclar(m, _ruido(0.30, 3000.0, 5000.0, 0.03), 0.10)
		"capitania":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _tono(659.0 * tono, 0.30, 0.05, "seno"))
		"retiro_jugador":
			m.resize(int(2.20 * float(FRECUENCIA)))
			_mezclar(m, _tono(220.0 * tono, 1.90, 0.06, "seno"))
			_mezclar(m, _ruido(1.20, 500.0, 2000.0, 0.06), 0.60)
		"debut_juvenil":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(659.0 * tono, 0.14, 0.045, "seno"))
			_mezclar(m, _tono(880.0 * tono, 0.24, 0.045, "seno"), 0.13)
		"ascenso_juvenil":
			m.resize(int(0.80 * float(FRECUENCIA)))
			_mezclar(m, _tono(494.0 * tono, 0.14, 0.05, "sierra"))
			_mezclar(m, _tono(659.0 * tono, 0.30, 0.06, "sierra"), 0.14)
		"sancion_directiva":
			m = _tono(140.0 * tono, 0.45, 0.07, "sierra")
		"reunion_directiva":
			m = _tono(600.0 * tono, 0.08, 0.03, "cuadrada")
			_mezclar(m, _tono(600.0 * tono, 0.08, 0.03, "cuadrada"), 0.20)
		"patrocinio_nuevo":
			m.resize(int(0.55 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.045, "seno"))
			_mezclar(m, _tono(1108.0 * tono, 0.22, 0.045, "seno"), 0.10)
		"inauguracion_obra":
			m.resize(int(1.60 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.13))
			for hz5 in [349.0, 440.0, 523.0, 659.0]:
				_mezclar(m, _tono(float(hz5) * tono, 0.90, 0.035, "seno"), 0.40)
		"entrada_taquilla":
			m.resize(int(0.30 * float(FRECUENCIA)))
			_mezclar(m, _tono(1320.0 * tono, 0.08, 0.045, "seno"))
		"aumento_socios":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.14, 0.04, "seno"))
			_mezclar(m, _tono(784.0 * tono, 0.30, 0.04, "seno"), 0.13)
		"huelga_hinchas":
			m = _ruido(2.40, 1900.0, 2600.0, 0.10)
		"elecciones_club":
			m = _tono(700.0 * tono, 0.10, 0.04, "cuadrada")
			_mezclar(m, _tono(900.0 * tono, 0.10, 0.04, "cuadrada"), 0.16)
		"votacion_ganada":
			m.resize(int(0.70 * float(FRECUENCIA)))
			_mezclar(m, _tono(659.0 * tono, 0.14, 0.045, "seno"))
			_mezclar(m, _tono(988.0 * tono, 0.30, 0.045, "seno"), 0.13)
		"votacion_perdida":
			m = _tono(233.0 * tono, 0.40, 0.06, "sierra")
		"premio_liga":
			m.resize(int(2.2 * float(FRECUENCIA)))
			for hz6 in [262.0, 330.0, 392.0, 523.0]:
				_mezclar(m, _tono(float(hz6) * tono, 1.80, 0.04, "seno"))
			_mezclar(m, _cantico(1.0), 0.4)
		"descenso_administrativo":
			m = _tono(98.0 * tono, 1.40, 0.08, "sierra")
		"multa":
			m.resize(int(0.40 * float(FRECUENCIA)))
			_mezclar(m, _tono(1320.0 * tono, 0.08, 0.04, "seno"))
			_mezclar(m, _tono(880.0 * tono, 0.16, 0.035, "seno"), 0.08)
		"cesion_jugador":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _tono(660.0 * tono, 0.10, 0.04, "seno"))
			_mezclar(m, _tono(550.0 * tono, 0.16, 0.03, "seno"), 0.10)
		"renovacion_rechazada":
			m = _tono(200.0 * tono, 0.40, 0.06, "sierra")
		"agente_llamada":
			m.resize(int(0.60 * float(FRECUENCIA)))
			for rep2 in 3:
				_mezclar(m, _tono(1000.0 * tono, 0.028, 0.030, "seno"), float(rep2) * 0.10)
		"rumor_fichaje":
			m = _tono(500.0 * tono, 0.10, 0.03, "seno")
			_mezclar(m, _ruido(0.20, 900.0, 1400.0, 0.02), 0.05)
		"medico_parte":
			m = _tono(600.0 * tono, 0.10, 0.035, "cuadrada")
		"alta_medica":
			m.resize(int(0.45 * float(FRECUENCIA)))
			_mezclar(m, _tono(659.0 * tono, 0.12, 0.04, "seno"))
			_mezclar(m, _tono(880.0 * tono, 0.20, 0.04, "seno"), 0.11)
		"baja_medica":
			m = _tono(233.0 * tono, 0.30, 0.05, "sierra")
		"entrenamiento_lesion":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.20, 300.0, 100.0, 0.10))
			_mezclar(m, _tono(180.0 * tono, 0.30, 0.05, "sierra"), 0.05)
		"objetivo_cumplido":
			m.resize(int(1.00 * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.14, 0.045, "seno"))
			_mezclar(m, _tono(659.0 * tono, 0.14, 0.045, "seno"), 0.13)
			_mezclar(m, _tono(880.0 * tono, 0.40, 0.05, "seno"), 0.26)
		"objetivo_fallado":
			m = _tono(200.0 * tono, 0.50, 0.06, "sierra")
		"mejora_instalaciones":
			m.resize(int(1.10 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.12))
			_mezclar(m, _tono(440.0 * tono, 0.60, 0.035, "seno"), 0.35)

		## --- Mas interfaz ---
		"seleccionar":
			m = _tono(1000.0 * tono, 0.04, 0.04, "seno")
		"deseleccionar":
			m = _tono(700.0 * tono, 0.04, 0.03, "seno")
		"arrastrar":
			m = _tono(500.0 * tono, 0.05, 0.025, "seno")
		"soltar":
			m = _tono(650.0 * tono, 0.06, 0.03, "seno")
		"desbloqueo":
			m.resize(int(0.40 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.04, "seno"))
			_mezclar(m, _tono(1318.0 * tono, 0.20, 0.04, "seno"), 0.09)
		"nivel_subido":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _tono(659.0 * tono, 0.10, 0.04, "seno"))
			_mezclar(m, _tono(988.0 * tono, 0.30, 0.04, "seno"), 0.09)
		"notificacion":
			m = _tono(1047.0 * tono, 0.08, 0.04, "seno")
		"confirmar":
			m = _tono(880.0 * tono, 0.06, 0.04, "seno")
		"cancelar":
			m = _tono(440.0 * tono, 0.08, 0.04, "cuadrada")
		"deslizar":
			m = _ruido(0.10, 2000.0, 1200.0, 0.025)

		## --- Mas festejos y momentos de gol ---
		"celebracion_grupal":
			m.resize(int(2.0 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.60, 700.0, 2200.0, 0.15))
			_mezclar(m, _cantico(1.0), 0.4)
		"celebracion_individual":
			m = _ruido(1.00 * largo, 700.0, 2000.0, 0.10)
		"festejo_banco":
			m.resize(int(1.20 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.90, 700.0, 1800.0, 0.10))
		"festejo_hinchada_extra":
			m.resize(int(2.60 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.20, 600.0, 2400.0, 0.20))
			_mezclar(m, _cantico(1.5), 0.4)
			_mezclar(m, _cantico(1.3), 2.0)
		"remontada":
			m.resize(int(3.0 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.40, 700.0, 220.0, 0.20))
			for hz7 in [392.0, 523.0, 659.0]:
				_mezclar(m, _tono(float(hz7) * tono, 0.50, 0.06, "sierra"), 0.10)
			_mezclar(m, _cantico(1.3), 1.0)
		"gol_agonico":
			m.resize(int(3.4 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.20, 1900.0, 900.0, 0.05))
			_mezclar(m, _ruido(2.60, 700.0, 220.0, 0.24), 0.25)
			_mezclar(m, _cantico(1.6), 0.6)
		"hat_trick":
			m.resize(int(2.6 * float(FRECUENCIA)))
			for hz8 in [523.0, 659.0, 784.0]:
				_mezclar(m, _tono(float(hz8) * tono, 0.30, 0.06, "sierra"), (hz8 - 523.0) / 261.0 * 0.20)
			_mezclar(m, _ruido(1.80, 700.0, 2000.0, 0.14), 0.60)
		"doblete":
			m.resize(int(1.8 * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.20, 0.06, "sierra"))
			_mezclar(m, _tono(659.0 * tono, 0.30, 0.06, "sierra"), 0.20)
			_mezclar(m, _ruido(1.20, 700.0, 2000.0, 0.10), 0.45)
		"gol_rapido":
			m.resize(int(2.0 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.60, 700.0, 220.0, 0.18))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.05, "seno"))
		"gol_confirmado_var":
			m.resize(int(2.4 * float(FRECUENCIA)))
			for i7 in 2:
				_mezclar(m, _tono(1400.0 * tono, 0.10, 0.04, "cuadrada"), float(i7) * 0.22)
			_mezclar(m, _ruido(1.60, 700.0, 2200.0, 0.16), 0.50)

		## --- Clima y ambiente ---
		"niebla_ambiente":
			m = _ruido(3.00, 200.0, 500.0, 0.04)
		"calor_extremo":
			m = _ruido(2.40, 1200.0, 1600.0, 0.02)
		"frio_extremo":
			m = _ruido(1.60 * largo, 400.0, 900.0, 0.03)
		"noche_estadio":
			m = _ruido(3.20, 100.0, 300.0, 0.04)
		"dia_soleado":
			m = _ruido(2.60, 800.0, 1400.0, 0.03)

		## --- Mas arbitro y disciplina ---
		"tarjeta_banco":
			m = _tono(320.0 * tono, 0.20, 0.06, "cuadrada")
			_mezclar(m, _ruido(0.30, 900.0, 300.0, 0.05), 0.10)
		"protesta_jugador":
			m = _ruido(1.20 * largo, 500.0, 300.0, 0.08)
		"protesta_masiva":
			m = _ruido(2.20 * largo, 500.0, 300.0, 0.14)
		"amonestacion_verbal":
			m = _tono(500.0 * tono, 0.14, 0.04, "seno")
		"tiempo_anadido":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(1400.0 * tono, 0.08, 0.05, "cuadrada"))
		"ventaja":
			m = _tono(700.0 * tono, 0.10, 0.04, "seno")
			_mezclar(m, _tono(900.0 * tono, 0.10, 0.03, "seno"), 0.06)
		"libre_indirecto":
			m = _tono(2650.0 * tono, 0.20 * largo, 0.20, "seno")
		"mano_fuera_area":
			m = _tono(1400.0 * tono, 0.08, 0.05, "cuadrada")
		"fuera_terreno_juego":
			m = _tono(400.0 * tono, 0.10, 0.04, "seno")
		"calambre":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.20, 300.0, 100.0, 0.09))
			_mezclar(m, _tono(160.0 * tono, 0.30, 0.04, "sierra"), 0.06)

		## --- Mas estilo de juego ---
		"pase_corto":
			m = _tono(700.0 * tono, 0.04, 0.05, "seno")
		"centro":
			m = _ruido(0.30 * largo, 2000.0, 700.0, 0.06)
		"regate":
			m.resize(int(0.30 * float(FRECUENCIA)))
			_mezclar(m, _tono(600.0 * tono, 0.05, 0.04, "seno"))
			_mezclar(m, _tono(750.0 * tono, 0.05, 0.04, "seno"), 0.08)
		"tiro_potente":
			m = _ruido(0.20 * largo, 3200.0, 700.0, 0.08)
		"tiro_flojo":
			m = _ruido(0.16 * largo, 1400.0, 600.0, 0.04)
		"paso_atras":
			m = _tono(500.0 * tono, 0.06, 0.04, "seno")
		"presion_alta":
			m = _ruido(0.40 * largo, 700.0, 300.0, 0.07)
		"contragolpe":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(700.0 * tono, 0.06, 0.05, "seno"))
			_mezclar(m, _ruido(0.40, 2200.0, 700.0, 0.06), 0.05)
		"posesion_larga":
			m = _ruido(2.00, 300.0, 600.0, 0.09)
		"cambio_ritmo":
			m = _tono(500.0 * tono, 0.10, 0.04, "seno")
			_mezclar(m, _tono(700.0 * tono, 0.10, 0.04, "seno"), 0.10)
	return _a_wav(m)

## El bombo del HTML (`bombo(t0,vol)` dentro de `sfxGol()`): un seno grave de
## 58 Hz y un golpe de ruido corto. El HTML le hace un glissando hacia 32 Hz;
## `_tono()` no barre frecuencia, y a esa altura el oído no lo distingue.
func _bombo(m: PackedFloat32Array, t0: float, vol: float) -> void:
	_mezclar(m, _tono(58.0, 0.28, vol, "seno"), t0)
	_mezclar(m, _ruido(0.08, 300.0, 90.0, 0.05), t0)

## El "sol-sol-la-sol-do-si" de la tribuna (`cantico()` en juego.js), con
## palmas entre nota y nota. Solo lo usa "trofeo" -es el unico sitio del HTML
## donde se llama-, pero como aporte propio de este porte tambien podria
## engancharse a cualquier festejo futuro sin sintetizar nada nuevo.
func _cantico(intensidad: float) -> PackedFloat32Array:
	var base := [196.0, 196.0, 220.0, 196.0, 262.0, 247.0]
	var vol := 0.030 * intensidad
	var m: PackedFloat32Array = PackedFloat32Array()
	m.resize(int(2.1 * float(FRECUENCIA)))
	for i in base.size():
		var t0 := float(i) * 0.34
		for arm in [1, 2, 3]:
			var forma := "sierra" if arm == 1 else "seno"
			_mezclar(m, _tono(base[i] * float(arm), 0.30, vol / (float(arm) * 1.6), forma), t0)
		_mezclar(m, _ruido(0.09, 2200.0, 2600.0, 0.05 * intensidad), t0 + 0.02)
	return m

## Un tono con envolvente exponencial de caída, que es la que suena natural: el
## sonido arranca de golpe y se apaga deprisa al principio y despacio al final.
func _tono(hz: float, dur: float, vol: float, forma: String) -> PackedFloat32Array:
	var n := int(dur * float(FRECUENCIA))
	var m := PackedFloat32Array()
	m.resize(n)
	var paso := hz * TAU / float(FRECUENCIA)
	for i in n:
		var t := float(i) / float(n)
		var env: float = exp(-5.0 * t)
		var f := float(i) * paso
		var s := 0.0
		match forma:
			"seno": s = sin(f)
			"cuadrada": s = 1.0 if sin(f) >= 0.0 else -1.0
			"sierra": s = fmod(f / TAU, 1.0) * 2.0 - 1.0
			_: s = sin(f)
		m[i] = s * env * vol
	return m

## Ruido con un barrido de filtro entre dos frecuencias. El filtro es un paso
## bajo de un polo: no es un biquad como el del navegador, pero para ruido de
## grada la diferencia no se oye y cuesta una décima parte.
func _ruido(dur: float, f0: float, f1: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * float(FRECUENCIA))
	var m := PackedFloat32Array()
	m.resize(n)
	var estado := 0.0
	var rng := RandomNumberGenerator.new()
	## Semilla fija: el mismo efecto suena igual en cada partida. La variación
	## viene de las cuatro variantes, no de que cada reproducción sea distinta.
	rng.seed = int(f0) * 7919 + int(f1)
	for i in n:
		var t := float(i) / float(n)
		var corte: float = lerpf(f0, f1, t)
		var a: float = clampf(corte / float(FRECUENCIA) * 6.28, 0.02, 0.95)
		estado += a * (rng.randf_range(-1.0, 1.0) - estado)
		## Ataque rápido y caída larga: el ruido de una grada sube de golpe.
		var env: float = minf(t / 0.12, 1.0) * exp(-3.2 * t)
		m[i] = estado * env * vol
	return m

func _mezclar(destino: PackedFloat32Array, fuente: PackedFloat32Array, retraso: float = 0.0) -> void:
	var off := int(retraso * float(FRECUENCIA))
	for i in fuente.size():
		var k := i + off
		if k < destino.size():
			destino[k] = clampf(destino[k] + fuente[i], -1.0, 1.0)

## Los pasa a 16 bits, que es lo que quiere `AudioStreamWAV`.
func _a_wav(m: PackedFloat32Array) -> AudioStreamWAV:
	var datos := PackedByteArray()
	datos.resize(m.size() * 2)
	for i in m.size():
		var v := int(clampf(m[i], -1.0, 1.0) * 32767.0)
		datos.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = FRECUENCIA
	w.stereo = false
	w.data = datos
	return w

## Los nombres de los efectos que hay cargados, y una ficha de cada uno.
##
## Existen para que el banco de pruebas pueda comprobar que la sintesis produce
## ondas de verdad. Un banco que "carga" pero suena a nada es peor que uno que
## falla: no hay error, y el juego se queda mudo sin que nadie sepa por que.
func catalogo() -> Array:
	var l := NOMBRES.duplicate()
	l.sort()
	return l

func ficha(nombre: String) -> Dictionary:
	var variantes: Array = banco(nombre)
	if variantes.is_empty():
		return {}
	var w: AudioStreamWAV = variantes[0]
	var pico := 0
	for i in range(0, w.data.size() - 1, 64):
		pico = maxi(pico, absi(w.data.decode_s16(i)))
	return {
		"variantes": variantes.size(),
		"segundos": float(w.data.size() / 2) / float(FRECUENCIA),
		"pico": pico,
	}
