class_name Balance
extends RefCounted
## LAS PERILLAS DE BALANCE (M-388, 2-11-2026): los números que de verdad se tocan para equilibrar el juego, en un solo sitio. Cada módulo conserva su nombre
## de siempre como alias (`const X := Balance.X`), así que nada cambia donde se usan. Para equilibrar: editar AQUÍ y pasar `pruebas/igualdad_motor.tscn` (la huella
## cambia a propósito: actualizar `ESPERADO` diciéndolo) y `pruebas/ideas/eq_diez_temporadas.tscn`.

# ----- EL PARTIDO JUGABLE (`MotorJugable`): rozamiento del balón, faltas y tarjetas, giro y la tabla de dificultades de la CPU

## EL CÉSPED (13-10-2026): con 0,55/s + 1,1 m/s² el balón rodaba como en el
## barro -un pase de 20 m tardaba ~3 s y llegaba muerto- y la sonda medía el
## balón SIN dueño el 88 % del tiempo. Ahora frena como un césped cortado: un
## pase raso de 20 m tarda ~1,5 s y llega a ~11 m/s.
const ROCE_SUELO := 0.18      ## frenado proporcional al rodar (1/s)

const ROCE_FIJO := 0.7        ## frenado constante al rodar (m/s²)

## H-03 (2-11-2026): resistencia del aire CUADRÁTICA (a = K·|v|·v), como la real (K = 0,5·ρ·Cd·A/m; con ρ=1,2, A=0,038 m², m=0,43 kg y un Cd de 0,15 de balón liso sale
## ≈ 0,008; con el 0,25 de un balón con costuras sería 0,013). Antes era lineal (v·0,06: a 30 m/s frenaba 1,8 m/s² y ahora 7,2). 0,013 hundía la ventaja del equipo mejor
## (la sonda «el mejor gana al peor» pasaba de +2,0 a +0,2 goles); con 0,008 todo queda en rango (medido con 30 semillas en `rendimiento.md`). Lo que frena de más se compensa al lanzar
## (`compensa_arrastre`).
const ARRASTRE_CUAD := 0.008
## H-04: lo que se gasta el efecto (giro) del balón, por tiempo y no por fotograma: en el aire ~15 %/s; en el suelo, como el 3 % por fotograma a 60 Hz de antes (0,97^60).
const GIRO_AIRE := 0.15
const GIRO_SUELO := 0.97
## H-05: UNA sola gravedad (m/s²) para el partido, el balón suelto de la ciudad y las cuentas de física.
const GRAVEDAD := 9.81

const BOTE := 0.55

## FALTAS POR PUNTOS (20-10-2026, del vídeo que regaló el dueño): la sanción
## sale de CÓMO fue la entrada, no de una tirada. Cada factor suma su peso y el
## total decide: falta ≥ 1,0 · amarilla ≥ 4,0 · roja directa ≥ 7,0 (por detrás
## + a gran velocidad + último hombre = 7,3 → roja).
const PESO_FALTA := {"agarron": 1.4, "por_detras": 3.0, "empujon": 1.7, "gran_velocidad": 2.0,
	"deslizante": 2.6, "profesional": 2.3, "de_pie": 1.2, "hombro": 0.9, "agresiva": 2.4}

## Por debajo de 1,0 no hay falta (25-10-2026, lo que faltaba del vídeo): la
## carga de hombro limpia (0,9) es legal y el juego sigue; con algo más (por
## detrás, lanzado, un empujón) ya pasa del umbral. El criterio del árbitro
## (±0,4) solo decide la tarjeta, no si hubo falta.
const UMBRAL_FALTA := 1.0

const UMBRAL_AMARILLA := 4.0

const UMBRAL_ROJA := 7.0

## GIRO RÁPIDO (M-115, 19-10-2026): ≈690°/s, lo más rápido que gira el cuerpo
## de un futbolista al encararse a un pase (por debajo de los 720°/s que la
## sonda de física marca como imposibles). `_mirar` lo deja pedido `dur` s.
const GIRO_RAPIDO := 12.0

## DIFICULTAD DE LA CPU (20-10-2026, pedido del dueño). Como en FC: solo toca al
## equipo que maneja la CPU frente al tuyo. Cada nivel cambia la calidad de sus jugadores (`attr`),
## la presión y el error de sus tiros y pases (`error`, en `GestoTecnico.factor`).
## (La «pausa» NO es dificultad: pensar más con el balón hace que conduzca y tire MÁS; contra el nivel
## más bajo la CPU tiraba 7 veces. Queda en 1,0 para todos.)
## (4-11) ESCALONES IGUALADOS tras medir 30 partidos por nivel (docs/04_auditorias/MEGA_AUDITORIA_4/partido.md): antes Cadete→Debutante valía ~2,5 goles y Debutante→Semiprofesional ~0,2.
const DIFICULTADES := {   ## 8 categorías del dueño (27-10); «debutante» = el motor calibrado de siempre (antes «profesional»)
	"practicante": {"nombre": "Practicante", "vista": 0.5, "attr": 0.72, "pausa": 1.0, "presion": -1, "error": 1.35},
	"cadete": {"nombre": "Cadete", "vista": 0.2, "attr": 0.90, "pausa": 1.0, "presion": -1, "error": 1.12},
	"debutante": {"nombre": "Debutante", "attr": 1.0, "pausa": 1.0, "presion": 0, "error": 1.0},
	"semiprofesional": {"nombre": "Semiprofesional", "vista": -0.04, "attr": 1.045, "pausa": 1.0, "presion": 0, "error": 0.93},
	"profesional": {"nombre": "Profesional", "vista": -0.08, "attr": 1.07, "pausa": 1.0, "presion": 1, "error": 0.89},
	"experto": {"nombre": "Experto", "vista": -0.14, "attr": 1.10, "pausa": 1.0, "presion": 1, "error": 0.85},
	"maestro": {"nombre": "Maestro", "vista": -0.2, "attr": 1.13, "pausa": 1.0, "presion": 1, "error": 0.81},
	"ultimate": {"nombre": "Ultimate", "vista": -0.34, "attr": 1.20, "pausa": 1.0, "presion": 1, "error": 0.72},
}

const ORDEN_DIFICULTAD := ["practicante", "cadete", "debutante", "semiprofesional", "profesional", "experto", "maestro", "ultimate"]

# ----- EL PARTIDO SIMULADO (`Partido`): ocasiones, conversión, atajadas, arenga y la «ley del ex»

const BASE_ATAQUE := 0.048

const EXPONENTE := 1.6

const REPARTO := 1.9

## Cuánto pesa la diferencia de calidad (ver `_probabilidad`).
const SENSIBILIDAD := 3.2

## De cada ataque que se genera, este porcentaje termina dentro. Es el `r<0.30`
## del HTML, y es facil de pasar por alto al portar: la formula de arriba NO da
## goles, da LLEGADAS. Portandola como si diera goles salian ocho por partido en
## vez de dos y medio. Lo caza la prueba de "goles por partido" del banco, que
## esta puesta justo para esto.
##
## 3-11-2026 (calibración, orden del líder): 0,30 → **0,28**. El partido simulado daba ~2,92 goles por partido en la primera temporada (6 semillas × CHI, ARG, ESP;
## `pruebas/zz_medir_goles.tscn`) cuando las ligas reales andan en 2,4-2,9. Se bisecó (7e98acbe, 26-10: 2,62; 7e27a84b, 1-11: 2,60) hasta `1b176389` (1-11, idea 378):
## desde el minuto 60 la IA que va perdiendo se vuelca (`ofensivo`) y la débil que gana se cierra (`cerrojo`) -una función buena, no se toca- y eso sumó +0,32 goles
## por partido (sin ella, hoy, 2,63). Con 0,28 queda en 2,70. Se baja la conversión y no las llegadas (`BASE_ATAQUE`) porque deja intactos los remates y el xG por llegada
## (media 0,27: `0,09 + f^0,25 · 0,22`, la auditoría del 26-10), y los goles pasan a ser ~1,05 veces el xG en vez de ~1,13. Sube la mitad que el 0,30 de antes en la
## cuota de atajadas (entre CONVERSION y R_ATAJADA): los tiros a puerta (gol + atajada, hasta R_ATAJADA) no cambian.
const CONVERSION := 0.267

## LOS PENALES (3-11-2026, orden del líder): medido con `pruebas/zz_medir_stats.tscn` el partido simulado daba 0,00 penales por partido (solo el árbitro «estricto» los cobraba, 0,004 por llegada);
## el fútbol real: ~0,25-0,3, convertidos ~76 %. `P_PENAL` es la probabilidad base de que una llegada acabe en falta dentro del área (con ~9,6 llegadas por partido: ~0,29 penales),
## `PENAL_PERFIL` la escala por el perfil del árbitro (el estricto pita más, el permisivo menos). Cada penal convertido es un gol que no pasa por `CONVERSION` (y la llegada ya no es un
## remate normal): `CONVERSION` baja de 0,28 a 0,267 para que los goles sigan en ~2,7 por partido.
const P_PENAL := 0.03

## LA VENTAJA DE CAMPO (3-11-2026, orden del líder): factor sobre la probabilidad de llegada por minuto del que juega en casa y del que visita (1,0 en cancha neutral). Con 1,08/0,94 la victoria
## local salía al 39,8 % (fútbol real ~45 %, empates ~25 %, visita ~30 %). Con 1,18/0,86 (suma 2,04, como antes: el total de llegadas no sube) sale 46,3 % local, 26,6 % empates, 27,1 % visita y
## 2,72 goles (medido con `zz_medir_stats`, 2.880 partidos).
const BONO_LOCAL := 1.18
const BONO_VISITA := 0.86
const CONVERSION_PENAL := 0.77
const PENAL_PERFIL := {"estricto": 1.6, "tarjetero": 1.2, "permisivo": 0.6}

## LAS ESTADÍSTICAS DE RELLENO DEL PARTIDO SIMULADO (3-11-2026, orden del líder): córners, faltas y fueras de juego son solo contadores que se enseñan en las pantallas del partido (no
## deciden nada), una tirada por minuto y lado. Eran las del HTML (córners 0,10/0,09, faltas 0,16/0,17, fueras 0,05/0,05 por minuto) y daban 17,1 córners, 29,6 faltas y 9,0 fueras por
## partido (medido con `pruebas/zz_medir_stats.tscn`, 2.880 partidos). El fútbol real: ~10 córners, ~22-24 faltas y ~4 fueras de juego. Se mantiene la ventaja de campo en detalle (el
## local saca más córners y comete menos faltas). Cambiar el umbral no cambia cuántas tiradas se hacen: los resultados de los partidos no se mueven.
const P_CORNER_LOCAL := 0.062
const P_CORNER_VISITA := 0.052
const P_FALTA_LOCAL := 0.120
const P_FALTA_VISITA := 0.130
const P_FUERA := 0.022

## LAS TARJETAS DEL PARTIDO SIMULADO (3-11-2026, orden del líder): medido con `pruebas/zz_medir_stats.tscn` (2.880 partidos) daba 2,74 amarillas y 0,22 rojas por partido; el fútbol real
## ~3,5-4 amarillas y ~0,1-0,2 rojas. `P_AMARILLA` es la tirada por minuto (por el perfil del árbitro y el VAR de la liga: `_incidencias`); la roja llega con la SEGUNDA amarilla con
## probabilidad `P_ROJA_SEGUNDA` (también en `_tarjeta_arbitral`). Subir las amarillas arrastra a las rojas (más segundas amarillas), por eso baja también la segunda.
const P_AMARILLA := 0.045   ## A4-PAR-L01 (4-11): 0,040 → 0,045; la 2.ª amarilla ya cuenta en el partido y el amonestado se cuida (3,26 → ~3,6)
const P_ROJA_SEGUNDA := 0.09   ## ya no la usa el simulado (A4-PAR-L01); se queda por si la lee alguna prueba vieja

## Los mismos cortes de `ataque()` en juego.js (linea ~2139 y ~2144), sobre el
## mismo `r` que decide el gol: entre CONVERSION y R_ATAJADA para la atajada,
## entre R_ATAJADA y R_POSTE para el palo, el resto para el fallo.
const R_ATAJADA := 0.55

const R_POSTE := 0.62

## LAS ARENGAS. `impulsos` guarda hasta qué minuto le dura el subidón a cada
## jugador al que le hayas gritado desde la banda.
const ARENGA_BOOST := 1.12

const ARENGA_MINUTOS := 18

## Cuánto se agranda un ex contra su antiguo club. Un 12% es mucho para un solo
## jugador y es exactamente el punto: la ley del ex no es una superstición del
## fútbol, es que ese día juega distinto.
const LEY_DEL_EX := 1.12

# ----- LA ECONOMÍA SEMANAL (`Finanzas`): puntos por euro, mes, taquilla, día de partido y reparto de la tele

## Puntos por espectador y unidad de precio.
const PPE := 0.25

## Cada cuantas semanas se cierra el mes. El HTML usa `G.sem%4===0`.
const SEMANAS_DEL_MES := 4

## LA TAQUILLA REAL (26-10, decidido por el dueño: ×3,5). Con PPE 0,25 la taquilla era el 4 % de los ingresos
## del chico (0,10 M) y el 4,6 % del grande (1,09 M); en el fútbol real el día de partido pesa un 10-15 % en un
## club chico chileno y un 20-25 % en Colo-Colo. Con ×3,5 queda en ~13 % y ~15 %.
const FACTOR_TAQUILLA := 3.5

## El día de partido ya no es un % plano: sale de precios reales y del aforo (`Viajes.dia_de_partido_*`); los viajes
## se pagan aparte y la operación mensual los descuenta (`Finanzas.OPERACION_SIN_VIAJES`).

## Derechos de televisión. Es la entrada más grande de un club moderno, y el
## salto de Primera a Segunda es brutal a propósito (300.000 contra 58.000): es
## lo que hace que descender sea una catástrofe económica y no un disgusto
## deportivo.
##
## Sin esto, portado el juego solo con taquilla y sueldos, TODOS los clubes
## perdían más de cinco millones por semana y el mundo entero quebraba en tres
## meses. La taquilla nunca pagó una plantilla.
## Lo que la television paga ANTES de multiplicadores. Sale aparte porque el
## plus del horario se cobra sobre esta cifra limpia, no sobre la ya ajustada.
## EL REPARTO SOLIDARIO (26-10, decidido por el dueño: 0,5). Con el reparto solo por
## reputación el grande de Chile cobra 9,4 veces lo que el chico (20,5 M contra 2,2 M al año), y el chico
## pierde 1,1-1,7 M por año también en Primera. En el fútbol real es mucho más plano: Premier 1,6-1,8 veces
## del primero al último, LaLiga con tope de 3,5, el CDF chileno casi a partes iguales. Con 0,5 la mitad de la
## tele se reparte a partes iguales (la MEDIA de su liga, que fija `Mundo` con `fijar_medias_tv`) y la otra
## mitad por reputación. Ojo: la cuota del «club medio» (rep 70) no sirve de parte igual: la media de la
## Primera chilena es 0,64 M/mes, el doble de la del rep 70, porque la arrastran los tres grandes.
const REPARTO_TV_IGUAL := 0.5   ## activado el 26-10 (decisión del dueño)

## PENALES EN PARTIDO (2-11, sonda `pruebas/ideas/sonda_penales.tscn`: objetivo ~75 % marcados, ~17-20 % parados, el resto fuera o al palo).
## A dónde apunta la IA (fracción del arco; 1 = el palo), cuánto del error de un tiro cualquiera conserva (quieto y a 11 m) y la parte fija de la
## probabilidad de que el portero pare cuando adivinó el lado (`PenalPortero`).
const PENAL_IA_X := 1.0
const PENAL_ERROR := 0.8
const PENAL_PARA := 0.38


## EL CAMPO Y EL CUERPO, UNA SOLA VEZ (M-391, 3-11): `MatchPlayback` (el partido simulado en 3D) y `MotorJugable` (el jugable) los declaraban cada uno
## por su lado. El campo mide 105 × 68 m (el motor jugable usa la MITAD de cada medida, centrado en el origen); el cuerpo de un jugador, 0,31 m de radio.
const CAMPO_LARGO := 105.0
const CAMPO_ANCHO := 68.0
const RADIO_CUERPO := 0.31
