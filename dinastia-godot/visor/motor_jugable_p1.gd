extends Node
## (Parte 1 de 12 de `motor_jugable.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `motor_jugable.gd`, conserva la clase.)

## EL PARTIDO JUGABLE (29-9-2026, mapa de metas 18: Carrera de Jugador). Hasta
## hoy el 3D solo DRAMATIZABA lo que `nucleo/partido.gd` ya había decidido: el
## resultado salía de una simulación y los 22 seguían jugadas prehechas. Aquí
## el partido se JUEGA: el balón tiene física de verdad, los 21 que no manejas
## piensan solos y el resultado sale de lo que pase en el césped.
##
##   BALÓN: vuela con gravedad, arrastre y efecto; rueda frenando; bota; pega
##   en el poste y en el larguero; es gol cuando cruza la línea entre los palos.
##
##   REGLAS: saque de centro, de banda, de esquina y de puerta; faltas, tiros
##   libres y penales (con amarillas); descanso y final.
##
##   LOS NPC: cada equipo mantiene su dibujo y lo mueve con el balón (bloque que
##   bascula y se adelanta con la posesión). Sin balón, el más cercano presiona,
##   el segundo tapa, los demás marcan en su zona. Con balón, el portador valora
##   tirar, pasar (progresión, desmarque, riesgo de la línea) o conducir, y los
##   compañeros se desmarcan SIGUIENDO LAS JUGADAS PREHECHAS del catálogo
##   (`CatalogoJugadas`, ATQ-01..15) como patrón: cada fase dice a qué zona corre
##   cada puesto y a quién conviene pasarla. El portero se coloca entre el balón
##   y el arco, sale a por los balones sueltos del área y se estira si llega.
##
##   TÚ: controlas a UN jugador (tu futbolista) con el mando o el teclado
##   (`Mando`). Con balón: pase, tiro con potencia, centro, pase largo, pase al
##   hueco y regate. Sin balón: presionar, entrada, barrida y pedir el balón. Si
##   te toca lanzar un córner, una falta o un penal, apuntas y cargas la fuerza.
##
## Coordenadas del visor: X = ancho (±34 m), Z = largo (±52,5 m). El local ataca
## hacia +Z (su portero sale en -47, ver `PlayerSpawner.slot_to_position`).

signal gol(es_local: bool, autor: String, asistente: String)
signal aviso(texto: String)
signal cambio_estado(estado: String)
signal terminado
## Un cambio: quién sale, quién entra, de qué equipo (MEGAPLAN fase 3).
signal sustitucion(sale: String, entra: String, es_local: bool)
## PRÓRROGA Y PENALES (17-10-2026): solo con `eliminatoria` y empate.
signal prorroga_empieza
signal tanda_empieza
signal tanda_tiro(equipo: int, jugador_id: String, marcado: bool)
signal tanda_terminada(goles_local: int, goles_visita: int)

const LARGO := 52.5
const ANCHO := 34.0
const PALO := 3.66
const LARGUERO := 2.44
const AREA_X := 20.16
const AREA_Z := 16.5
const PUNTO_PENAL := 11.0
const R := 0.11
const G := 9.81
## EL CÉSPED (13-10-2026): con 0,55/s + 1,1 m/s² el balón rodaba como en el
## barro -un pase de 20 m tardaba ~3 s y llegaba muerto- y la sonda medía el
## balón SIN dueño el 88 % del tiempo. Ahora frena como un césped cortado: un
## pase raso de 20 m tarda ~1,5 s y llega a ~11 m/s.
const ROCE_SUELO := 0.18      ## frenado proporcional al rodar (1/s)
const ROCE_FIJO := 0.7        ## frenado constante al rodar (m/s²)
const ARRASTRE := 0.06
const BOTE := 0.55

var jugadores: Array = []
## El trío arbitral (los de `PlayerSpawner.spawn_arbitros`): no juegan, pero se
## mueven con la jugada para que la cancha no tenga tres estatuas.
var arbitros: Array = []
var balon: Node3D
var vel_balon := Vector3.ZERO
var giro_balon := Vector3.ZERO
var usuario: Dictionary = {}
## Sin usuario (o en las pruebas), también tu jugador lo maneja la IA.
var autopiloto := false
var duracion_mitad := 240.0   ## segundos reales por tiempo
## La mitad con la que se calibró la IA en `sonda_motor_dt` (240 s). Las
## decisiones que se tiran «por duelo» (la finta) se escalan con ella para que
## salgan las mismas POR PARTIDO con cualquier ritmo (ver `_escala_ritmo`).
const MITAD_CALIBRADA := 240.0
var t := 0.0
var mitad := 1
var goles := [0, 0]            ## [local, visita]
var estado := "saque"          ## juego | saque | gol | descanso | tanda | fin
## Partido de eliminación directa: con empate al 90' hay prórroga (mitades 3 y
## 4, de 15', un tercio de `duracion_mitad`) y, si sigue, tanda de penales.
var eliminatoria := false
var prorroga := false
var poseedor: Dictionary = {}
var ultimo_toque: Dictionary = {}
var penultimo_toque: Dictionary = {}
var pase_a: Dictionary = {}    ## a quién va el último pase (para correr a recibirlo)
var saque := {}
var apuntando := false         ## el usuario está lanzando una jugada a balón parado
var apunte := {"ang": 0.0, "loft": 0.3, "fuerza": 0.0, "fase": 0.0, "x": 0.0, "y": 0.8}
var cargando := false
var carga := 0.0
var pedido_hasta := 0.0        ## hasta cuándo vale que pediste el balón
var _pase_usuario_vivo := false ## el balón en camino es un pase tuyo
## Quién dio ese pase: con el control del equipo el mando salta al receptor, así
## que «el que recibe no es `usuario`» dejaba sin contar casi todos (20-10-2026).
var _pase_usuario_de: Dictionary = {}
var stats := {"fueras_de_juego": 0, "goles": 0, "asist": 0, "pases": 0, "pases_ok": 0, "tiros": 0, "a_puerta": 0,
	"entradas": 0, "entradas_ok": 0, "toques": 0, "faltas": 0}
var posesion := [0.0, 0.0]
var tiros := [0, 0]
var _rng := RandomNumberGenerator.new()
## FUERA DE JUEGO (MEGAPLAN fase 3): la foto del momento del pase. Quién del
## equipo que patea estaba adelantado; si uno de ellos recibe, se pita.
## {"local": bool, "ids": {id: true}}
var _offside := {}
## CAMBIOS (MEGAPLAN fase 3). `extra` es el jugador que espera en la banda: tú
## si empiezas en el banco (`entra_usuario_min` >= 0) o el suplente de tu
## puesto si empiezas jugando (te pueden sacar). El cambio se hace en el
## primer balón parado desde su minuto, como en el fútbol.
var extra: Dictionary = {}
var entra_usuario_min := -1
var usuario_sustituido := false
var ultimo_cambio: Dictionary = {}   ## {sale, entra, pos} del último `_cambiar`
var minutos_usuario := 0.0
var _cambio_hecho := false
## El nivel de exigencia del DT para sacarte: con buena relación aguanta más.
var exigencia_dt := 0.5
var prob_cambio_extra := 0.0   ## (para las pruebas: 1 = seguro que te cambia)
var _cambio_decidido := false

var fueras_de_juego := [0, 0]
## Fueras de juego que cazó la trampa de cada equipo (el que defiende).
var trampa_cazados := [0, 0]
var _offside_previo := {}
## EL VAR CON LA JUGADA REAL (17-10-2026): en cada pase, cuánto estaba cada
## compañero por delante de la línea (m > 0 = adelantado; el juez solo pita
## por encima de 0,3 m). Al recibir se guarda el del receptor, y el gol deja
## en `margen_gol` el del goleador (INF si no hubo pase medible).
var _margenes_pase := {}
var _margen_recepcion := {}
var margen_gol := INF
## Las dos líneas del fuera de juego en el pase del gol, en Z del mundo (M-118):
## {"linea": la del penúltimo defensor (o el balón), "atacante": el goleador}.
## Vacío si no hubo pase medible. La sala VAR las dibuja en su monitor.
var lineas_gol := {}
var _ultima_anim := ""
var _jugada := {}             ## la jugada prehecha que guía el ataque del poseedor
var _decision_en := 0.0
var _t_estado := 0.0
var depurar := false

# ---------------------------------------------------------------- modo DT
## EL PARTIDO DEL ENTRENADOR CON ESTE MOTOR (13-10-2026, pedido: «que ya no
## sean solo jugadas predeterminadas, que los cambios de jugadores o tácticas
## puedan cambiar el resultado, y controlar a los jugadores de mi equipo como
## en el vídeo»). Todo esto viene APAGADO: la Carrera de Jugador juega igual que
## antes. `VistaEstadio` lo enciende para el partido del DT.
##
## Un remate terminado (gol aparte): "atajada", "poste" o "fallo".
signal remate(es_local: bool, autor_id: String, tipo: String)
## Una tarjeta de verdad (con `tarjetas_reales`): la segunda amarilla expulsa.
signal tarjeta(jugador_id: String, roja: bool, es_local: bool)
## El árbitro hace un gesto (M-106): «arbitro_silbato», «senalar_falta»,
## «mostrar_tarjeta», «arbitro_ventaja», «arbitro_penal», «fin»… La vista lo usa
## para el silbato (el motor no toca sonidos: corre también en las sondas).
signal gesto_arbitro(nombre: String)
## La pizarra de cada equipo: [local, visita], con "mentalidad" (0-3), "presion",
## "linea", "amplitud" y "ritmo" (0-2). 1 es el término medio y, con todo a 1,
## el motor juega EXACTAMENTE como antes.
var tacticas: Array = [{}, {}]
## El cansancio baja los atributos (un suplente fresco se nota).
var cansancio_real := false
## Las amarillas cuentan y la segunda expulsa (y el equipo juega con uno menos).
var tarjetas_reales := false
## -1: nadie; 0: manejas al local; 1: a la visita. Manejas al que tiene el balón
## o al más cercano, y cambias con `jugar_cambiar` (Q / LB), como en FC.
var control_equipo := -1
## PRÁCTICA LIBRE (21-10-2026, M-130): para aprender los controles. El rival se
## queda en su sitio (conos con camiseta), el reloj no acaba nunca y, si el
## rival se hace con el balón, vuelve a tus pies. `empezar_practica()`.
var practica := false
var _practica_pos := {}
## Si se da, el stick se lee respecto a ESTA cámara (la de televisión, de lado):
## arriba en la pantalla es hacia el fondo de la imagen.
var camara: Camera3D = null
var expulsados: Array = []
var corners := [0, 0]
var faltas := [0, 0]
## Pases de cada equipo y cuántos llegaron a un compañero (la precisión que
## enseña la transmisión), y despejes.
var pases := [0, 0]
var pases_ok := [0, 0]
var despejes := [0, 0]
var _pase_eq := -1
var _manual_hasta := 0.0
var _tiro_vivo: Dictionary = {}
var _t_attr := 0.0
var _eligiendo := false
var _manual_tiro := false
## Cuántas veces se ha pateado el balón: el portero decide UNA vez por disparo.
var _n_patada := 0
## Qué clase de golpeo es el próximo `_patear` (lo fija quien patea).
var _ctx_golpeo := ""
var cuenta_aire := {}
## Lo que dura la celebración antes del saque (el partido del DT la alarga para
## su secuencia de cámaras) y quién marcó.
var duracion_gol := 3.2
## TIEMPO AÑADIDO (13-10-2026): segundos de motor que se juegan después del
## 45' y del 90' (0 = nada, como en la Carrera de Jugador). El reloj se queda
## en 45/90 y se cuenta el «+».
var anadido := [0.0, 0.0]
var _goleador: Dictionary = {}
## Fintas que la IA ha intentado (para pruebas y estadísticas).
var regates_ia := 0
## Fintas de la IA en las que el defensor picó.
var regates_ia_ok := 0
var _celebra_anim := "celebrar"

# ---------------------------------------------------------------- dificultad
## DIFICULTAD DE LA CPU (20-10-2026, pedido del dueño). Como en FC: solo toca al
## equipo que maneja la CPU frente al tuyo. «profesional» es el motor de
## siempre (todo lo calibrado). Cada nivel cambia la calidad de sus jugadores
## (`attr`), lo que piensa el que lleva el balón (`pausa`) y la presión.
## (La «pausa» del portador NO se usa como dificultad: pensar más con el balón
## hace que conduzca más hasta el área y tire MÁS. Se probó jugando: contra
## «Principiante» la CPU tiraba 7 veces. Queda en 1,0 para todos.)
const DIFICULTADES := {
	"principiante": {"nombre": "Principiante", "attr": 0.75, "pausa": 1.0, "presion": -1},
	"amateur": {"nombre": "Amateur", "attr": 0.85, "pausa": 1.0, "presion": -1},
	"semipro": {"nombre": "Semiprofesional", "attr": 0.94, "pausa": 1.0, "presion": 0},
	"profesional": {"nombre": "Profesional", "attr": 1.0, "pausa": 1.0, "presion": 0},
	"clase_mundial": {"nombre": "Clase mundial", "attr": 1.06, "pausa": 1.0, "presion": 1},
	"leyenda": {"nombre": "Leyenda", "attr": 1.12, "pausa": 1.0, "presion": 1},
}
const ORDEN_DIFICULTAD := ["principiante", "amateur", "semipro", "profesional", "clase_mundial", "leyenda"]
var dificultad_cpu := "profesional"
## Qué equipo es la CPU (0 local, 1 visita). -1 = el contrario al que manejas
## (si no manejas a nadie, ninguno: CPU contra CPU juegan igual).
var equipo_cpu_fijo := -1

# ---------------------------------------------------------------- penales

## LA TANDA DE PENALES, EN EL CÉSPED (17-10-2026). Cinco por equipo y muerte
## súbita, todos al mismo arco (+Z), los demás en el círculo central. Los
## lanzadores van en orden (los de mejor tiro primero, el portero al final) y
## cada penal reutiliza el de siempre: `_tirar` con su error, el apunte y la
## carga del usuario (`_apuntar_usuario`) y el círculo de serenidad. Cuando
## tu equipo defiende y lo manejas tú, eliges el lado del portero con el stick
## antes del disparo. El resultado NO pasa por `gol`: va a `tanda_tiro` y, al
## final, a `tanda_terminada` (el acta lo guarda con `penales_externos`).
##   tanda = {tiros: [[bool…], [bool…]], orden: [[p…], [p…]], empieza,
##            fase (entrar|preparar|apuntar|vuelo|resultado|fin), lanzador,
##            portero, lado (-1 / 0 / 1 en X del mundo), cruzo}
var tanda: Dictionary = {}
const TANDA_ARCO := Vector3(0, 0, LARGO)
const TANDA_PUNTO := Vector3(0, R, LARGO - PUNTO_PENAL)
## Tu portero sin lado elegido: adivina como el de la IA.
const SIN_ELEGIR := 99

## FALTAS POR PUNTOS (20-10-2026, del vídeo que regaló el dueño): la sanción
## sale de CÓMO fue la entrada, no de una tirada. Cada factor suma su peso y el
## total decide: falta ≥ 1,0 · amarilla ≥ 4,0 · roja directa ≥ 7,0 (por detrás
## + a gran velocidad + último hombre = 7,3 → roja).
const PESO_FALTA := {"agarron": 1.4, "por_detras": 3.0, "empujon": 1.7, "gran_velocidad": 2.0,
	"deslizante": 2.6, "profesional": 2.3, "de_pie": 1.2, "hombro": 0.9, "agresiva": 2.4}
const UMBRAL_AMARILLA := 4.0
const UMBRAL_ROJA := 7.0
## La última falta pitada: {"puntos", "factores": [claves de PESO_FALTA], "sancion"}.
var ultima_falta := {}
## Tarjetas por partido: [amarillas, rojas directas] de cada equipo (para las sondas).
var tarjetas_motor := [[0, 0], [0, 0]]

# ---------------------------------------------------------------- duelos

## LOS DUELOS CUERPO A CUERPO (16-10-2026, pendiente «duelos/contacto»). Antes
## los cuerpos del motor ni siquiera chocaban (el `_resolver_choques` de
## `MatchPlayback` no corre con el motor real) y una entrada era solo una
## tirada de dados con un gesto. Ahora hay contacto de verdad:
##   - CUERPOS: nadie atraviesa a nadie; al chocar, el más fuerte aparta más
##     al débil (masa = fuerza) y se pierde la velocidad del choque.
##   - HOMBRO CON HOMBRO: dos rivales corriendo juntos tras el balón (o uno
##     llevándolo) se cargan; gana la posición el de más fuerza, equilibrio y
##     carrera; el que pierde trastabilla de lado, frena y, si llevaba el
##     balón, muchas veces se le escapa.
##   - BALÓN DIVIDIDO: dos que llegan casi a la vez a un balón suelto; se lo
##     queda el que llega antes y aguanta el choque; si empatan, rebota.
##   - AGARRÓN: el defensor que llega por detrás del que lleva el balón (o
##     del que va a recibir) puede tirarle de la camiseta según su
##     agresividad; frena al atacante y, si lo retiene, el árbitro pita.
## Los atributos que deciden salen de la ficha (`_rasgos_duelo`). Contadores
## en `duelos` (sondas y `pruebas/prueba_duelos.tscn`).
## Interruptores (para las sondas: medir qué cambia cada parte).
var duelos_activos := true
var cuerpos_activos := true
var duelos := {"hombro": 0, "dividido": 0, "agarron": 0, "faltas": 0, "balon_perdido": 0, "rebote": 0}
const RADIO_CUERPO := 0.31

## Fuerza, equilibrio y agresividad de 0 a 1. La ficha no tiene agresividad:
## sale de la defensa y el físico (los que van al choque), del rasgo
## («muralla» más, «cerebro» menos) y de un carácter fijo por jugador.
## Los factores de una falta, para que el jugador entienda la tarjeta.
const NOMBRE_FACTOR := {"agarron": "agarrón", "por_detras": "por detrás", "empujon": "empujón",
	"gran_velocidad": "a gran velocidad", "deslizante": "en plancha", "profesional": "último hombre",
	"de_pie": "de pie", "hombro": "carga", "agresiva": "agresiva"}

## Adónde va `p` cuando su equipo ataca el último tercio: primer palo, punto
## de penal, segundo palo o frontal según su puesto y el lado del balón.
## Vector3.INF = sigue con su forma (o no toca llegar).
static var LLEGADA := OS.get_environment("SIN_LLEGADA") == ""

## GIRO RÁPIDO (M-115, 19-10-2026): ≈690°/s, lo más rápido que gira el cuerpo
## de un futbolista al encararse a un pase (por debajo de los 720°/s que la
## sonda de física marca como imposibles). `_mirar` lo deja pedido `dur` s.
const GIRO_RAPIDO := 12.0
## El margen aleatorio del sorteo de tiro (menos = se tira más). Ver `_ia_portador`.
static var CHISPA_TIRO := float(OS.get_environment("CHISPA_TIRO")) if OS.get_environment("CHISPA_TIRO") != "" else 0.16
## Cuánto vale cada metro que avanza un pase al elegirlo (más = más vertical).
static var CHISPA_AVANCE := float(OS.get_environment("CHISPA_AVANCE")) if OS.get_environment("CHISPA_AVANCE") != "" else 0.08
## Multiplica lo que piensa el portador antes de decidir (menos = juego más rápido).
static var CHISPA_PAUSA := float(OS.get_environment("CHISPA_PAUSA")) if OS.get_environment("CHISPA_PAUSA") != "" else 1.0
## LA PRISA (21-10-2026, vídeo de gameplay: el partido a ritmo «normal» acabó
## 0-0 con un tiro). El motor se calibró con mitades de 240 s, y lo que pasa en
## el césped va por SEGUNDOS, no por minutos de fútbol: con 180 s («normal»)
## salían 1,3 goles y ~6 tiros por equipo; con 121 s («rápido»), 0,8. Cuanto
## más corta la mitad, más directo se juega (piensa menos, mira más al arco y
## se anima antes a tirar), para que un partido tenga lo de un partido. Desde
## 240 s no cambia nada (la Carrera de Jugador juega con 240). Además, los
## ritmos del DT pasaron a 4 / 5,5 / 7,5 s por minuto (`VistaEstadio`): el
## «normal» dura como un partido de FC (~10 min) y da ~2,5 goles y ~15 tiros.
## PRISA_REF=segundos de referencia (0 = sin compensar).
static var PRISA_REF := float(OS.get_environment("PRISA_REF")) if OS.get_environment("PRISA_REF") != "" else 240.0
## Tope de aceleración total de un jugador (m/s²), ver `_mover_jugadores`.
static var A_MAX := float(OS.get_environment("A_MAX")) if OS.get_environment("A_MAX") != "" else 18.0

## LA LÍNEA DEFENSIVA COMÚN (M-123, 19-10-2026). Antes cada defensor marcaba a
## su delantero por separado y la línea se rompía: uno habilitaba a todos. Ahora
## los cuatro de atrás comparten una altura que sale de la pizarra y del balón:
## - de base, la altura media de su forma (con la «línea» de la pizarra);
## - si al portador nadie le aprieta y mira al arco, la línea recula (cubre la
##   espalda); si está presionado o el balón va hacia atrás, sube;
## - con la TRAMPA del fuera de juego sube más y más rápido, dejando atrás al
##   delantero que se queda colgado;
## - nunca se mete en su área chica ni pasa al balón.
## Se calcula una vez por paso y se mueve suave (la línea va junta, sin saltos).
var _linea_def := [INF, INF]
static var _SIN_LINEA := OS.get_environment("SIN_LINEA") != ""   ## (sondas: la defensa de antes)
var _linea_def_t := [-1.0, -1.0]

## Quién lo lanza. El usuario, si es de su equipo y le toca: los córners y las
## faltas si es lanzador (o el más cercano en las bandas), y los penales si se
## hizo cargo de ellos.
var lanza_usuario := {"corner": true, "falta": true, "penal": true, "banda": false}

## (Para las sondas que miden ritmo sin este efecto.)
var sin_gestion_tiempo := false

var _receptor_marcado: Dictionary = {}
var _flecha_receptor: MeshInstance3D

# ---------------------------------------------------------------- FC 26

var _gestos := ControlFC.new()
var _mods_carga := ""
var _mod_tiro := ""
var _pared: Dictionary = {}
var _falta_tactica := false
var _cambio_rs_hasta := 0.0
var _tac_base: Array = [{}, {}]
var _presion_equipo_hasta := 0.0
## Para la interfaz: la última filigrana que salió (nombre, estrellas, logrado).
signal filigrana(nombre: String, estrellas: int, logrado: bool)
## Una táctica rápida de la cruceta: quien tenga la pizarra del club (el
## partido del DT) la apunta ahí, que es de donde el motor la vuelve a leer.
signal tactica_rapida(equipo: int, clave: String, valor: int)

var lento := 0.0
var bloqueo := false
var _pareja_bloqueo := false
var _error_extra := 1.0
var _presion_doble := false
var _rb_ultimo := -9.0
var _y_ultimo := -9.0
var _palo_largo_hasta := 0.0
var _receptor_i := -1
var _anillo: MeshInstance3D

## LOS GESTOS DEL ÁRBITRO EN EL MOTOR REAL (17-10-2026, M-106). Hasta hoy los
## clips `arbitro_*` solo los usaba `MatchPlayback`: con el motor el árbitro
## caminaba y nada más. Ahora pita, señala la dirección de la falta, deja
## seguir (ventaja), señala el penal, el córner y el saque de puerta, habla
## con el amonestado y le ENSEÑA la tarjeta (una cartulina en la mano), y pita
## el final de cada tiempo. Los gestos van en cola con su propio reloj
## (`_t_arb`), porque `t` se para en los saques, que es justo cuando gesticula.
var _t_arb := 0.0
var _gestos_arb: Array = []     ## [cuándo, clip, duración, extra]
var _arb_hasta := 0.0           ## hasta cuándo dura el gesto en curso
var _tarjeta_arb: MeshInstance3D = null
var _anadido_gesto := {}

## Gira el balón según lo que rueda (como `Balon3D`).
var _ultima_pos_balon := Vector3.ZERO

## Los atributos de 0 a 1, con el CONTRASTE estirado alrededor de 62: con la
## escala tal cual, un once de 72 y uno de 62 rendían casi igual en el césped
## (la sonda: el mejor de la liga ganaba 1 de 5 en casa). Ahora 72 → 0,78 y
## 52 → 0,46, y la calidad se nota en el resultado.
func _atributos(at: Dictionary, ovr: int) -> Dictionary:
	var a := {}
	for k: String in ["rit", "tir", "pas", "reg", "def", "fis", "div", "par", "ref", "pos"]:
		var crudo := float(at.get(k, ovr)) / 100.0
		a[k] = clampf(0.62 + (crudo - 0.62) * 1.6, 0.15, 1.0)
	return a

func equipo_cpu() -> int:
	if equipo_cpu_fijo >= 0:
		return equipo_cpu_fijo
	return 1 - control_equipo if control_equipo >= 0 else -1

func _dificultad_de(p: Dictionary) -> void:
	var puro: Dictionary = p.get("attr_puro", {})
	if puro.is_empty():
		return
	var f := 1.0
	if equipo_cpu() == (0 if bool(p["es_local"]) else 1):
		f = float(DIFICULTADES[dificultad_cpu]["attr"])
	var base := {}
	for k: String in puro:
		base[k] = clampf(float(puro[k]) * f, 0.1, 1.05)
	p["attr_base"] = base
	p["attr"] = base.duplicate()

func _rasgos_duelo(p: Dictionary, jd: Dictionary) -> void:
	var a: Dictionary = p["attr"]
	var fis := float(a["fis"])
	p["fuerza"] = clampf(fis * 0.8 + float(a["def"]) * 0.2, 0.1, 1.0)
	p["equilibrio"] = clampf(fis * 0.5 + float(a["reg"]) * 0.5, 0.1, 1.0)
	var caracter := float(absi(hash(String(p.get("id", "")) + "genio")) % 1000) / 1000.0 - 0.5
	var rasgo := String(jd.get("rasgo", ""))
	var agr := 0.2 + float(a["def"]) * 0.35 + fis * 0.15 + caracter * 0.3
	agr += 0.12 if rasgo == "muralla" else (0.05 if rasgo == "lider" else (-0.08 if rasgo == "cerebro" else 0.0))
	p["agresividad"] = clampf(agr, 0.05, 1.0)
	p["duelos_g"] = 0
	p["duelos_p"] = 0
