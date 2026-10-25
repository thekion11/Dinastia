class_name Necesidades
extends RefCounted
## LAS NECESIDADES DEL DT (fase 0 del guion, 25-10-2026). Plan del lunes §2.1:
## *«comer y dormir; si fallan, aumentan las posibilidades de que las cosas salgan
## mal»*. Dependen del `Reloj`: no hay hambre ni sueño sin horas que pasen.
##
## Son dos, las que pide el plan:
##   - ENERGÍA (100 = descansado, 0 = no se tiene en pie): baja estando despierto
##     -más trabajando, más aún con horas extra- y sube durmiendo.
##   - HAMBRE (0 = recién comido, 100 = famélico): sube con las horas -despacio
##     durmiendo- y baja comiendo.
## El estrés y la familia NO se duplican aquí: viven semana a semana en `VidaDT`
## desde septiembre, y la fase 3 («casa y familia») es la que las unirá al reloj.
##
## Efectos (leídos por quien decida algo con azar; hoy nadie los aplica todavía a
## la simulación semanal, a propósito: la fase 0 deja el juego igual):
##   - `factor_riesgo()` ≥ 1: multiplica la probabilidad de que algo salga mal.
##   - `factor_rendimiento()` ≤ 1: lo bien que sale lo que hagas trabajando.
## Topes: las dos van de 0 a 100 y no se salen. Con la energía a 0 estando
## despierto se emite `agotamiento` (una vez por episodio).
##
## Por dentro van en MILÉSIMAS de punto y con tasas enteras por minuto: así un día
## partido en tramos da lo mismo que de una vez, y no hay redondeos de coma
## flotante entre máquinas. Nada consume `Azar`.

## `necesidad` es "energia" o "hambre"; `nivel` 0 = bien, 1 = aviso, 2 = grave.
signal estado_cambiado(necesidad: String, nivel: int)
## La energía llegó a 0 sin dormir: el cuerpo dice basta (la fase 3 decidirá qué pasa).
signal agotamiento()

const ESCALA := 1000          ## milésimas por punto
const MAXIMO := 100 * ESCALA

## actividad -> [energía, hambre] en milésimas de punto POR MINUTO. Calibradas
## para que un día de `Reloj.RUTINA` (8 h de sueño, 3 comidas, 8,5 h de jornada)
## quede casi a la par: la energía pierde ~60 puntos en el día y los recupera
## durmiendo; el hambre no pasa de ~38 entre comidas.
const TASAS := {
	"libre": [-55, 83],
	"trabajo": [-75, 94],
	"horas_extra": [-100, 100],
	"partido": [-90, 100],
	"viaje": [-60, 83],
	"descanso": [-25, 83],
	"comer": [-30, -3334],      ## media hora de comida deja el hambre a cero
	"dormir": [127, 42],
}
## Umbrales en puntos: [aviso, grave].
const ENERGIA_UMBRALES := [30, 10]   ## por debajo de… cansado / agotado
const HAMBRE_UMBRALES := [60, 85]    ## por encima de… hambriento / famélico
## Cómo queda el DT tras una semana que no se vivió hora a hora (la de siempre,
## avanzada desde el menú): se da por hecha con rutina, y es el lunes 08:00 recién
## desayunado y descansado.
const ENERGIA_RUTINA := 95 * ESCALA
const HAMBRE_RUTINA := 2500
## Lo que aumenta el riesgo y baja el rendimiento cuando cada necesidad falla del todo.
const RIESGO_ENERGIA := 0.5
const RIESGO_HAMBRE := 0.3
const RENDIMIENTO_ENERGIA := 0.15
const RENDIMIENTO_HAMBRE := 0.10

var energia_m: int = ENERGIA_RUTINA
var hambre_m: int = HAMBRE_RUTINA
## Para emitir `estado_cambiado` solo al cruzar un umbral, y `agotamiento` una vez.
var _nivel_energia: int = 0
var _nivel_hambre: int = 0
var _agotado: bool = false

## Escucha al reloj: cada tramo de tiempo y cada semana nueva.
func seguir_a(reloj: Reloj) -> void:
	if not reloj.tiempo_pasado.is_connected(pasar):
		reloj.tiempo_pasado.connect(pasar)
	if not reloj.semana_cambiada.is_connected(_al_cambiar_semana):
		reloj.semana_cambiada.connect(_al_cambiar_semana)

## ------------------------------------------------------------- LECTURAS ---

func energia() -> int:
	return energia_m / ESCALA

func hambre() -> int:
	return hambre_m / ESCALA

func nivel_energia() -> int:
	return _nivel_de_energia(energia_m)

func nivel_hambre() -> int:
	return _nivel_de_hambre(hambre_m)

## Cuánto falla cada una, de 0 (bien) a 1 (en el fondo): lo que mueve los efectos.
func falta_energia() -> float:
	var umbral := float(ENERGIA_UMBRALES[0] * ESCALA)
	return clampf((umbral - float(energia_m)) / umbral, 0.0, 1.0)

func exceso_hambre() -> float:
	var umbral := float(HAMBRE_UMBRALES[0] * ESCALA)
	return clampf((float(hambre_m) - umbral) / (float(MAXIMO) - umbral), 0.0, 1.0)

## Multiplicador de la probabilidad de que algo salga mal (1.0 a 1.8).
func factor_riesgo() -> float:
	return 1.0 + RIESGO_ENERGIA * falta_energia() + RIESGO_HAMBRE * exceso_hambre()

## Lo bien que sale el trabajo (0.75 a 1.0).
func factor_rendimiento() -> float:
	return 1.0 - RENDIMIENTO_ENERGIA * falta_energia() - RENDIMIENTO_HAMBRE * exceso_hambre()

## Una probabilidad base ajustada por el estado del DT (con tope en 1).
func probabilidad_de_fallo(base: float) -> float:
	return clampf(base * factor_riesgo(), 0.0, 1.0)

## ------------------------------------------------------------ EVOLUCIÓN ---

## Hace pasar `minutos` haciendo `actividad` (lo llama el reloj en cada tramo).
## Una actividad desconocida cuenta como "libre".
func pasar(minutos: int, actividad: String = "libre") -> void:
	if minutos <= 0:
		return
	var tasa: Array = TASAS.get(actividad, TASAS["libre"])
	energia_m = clampi(energia_m + int(tasa[0]) * minutos, 0, MAXIMO)
	hambre_m = clampi(hambre_m + int(tasa[1]) * minutos, 0, MAXIMO)
	if energia_m == 0 and actividad != "dormir":
		if not _agotado:
			_agotado = true
			agotamiento.emit()
	elif energia() > ENERGIA_UMBRALES[1]:
		_agotado = false
	_revisar_umbrales()

## Comer algo al paso (una barrita, un café con algo): quita hambre sin gastar tiempo.
func picar(puntos: int) -> void:
	hambre_m = clampi(hambre_m - maxi(puntos, 0) * ESCALA, 0, MAXIMO)
	_revisar_umbrales()

## La semana avanzó. Si se saltó más de un día sin vivirlo (el avance de semana de
## siempre), se da por vivida con rutina; si fue solo la noche del domingo al
## lunes, se duerme.
func _al_cambiar_semana(_semana: int, _anio: int, minutos_saltados: int) -> void:
	if minutos_saltados >= Reloj.MINUTOS_DIA:
		energia_m = ENERGIA_RUTINA
		hambre_m = HAMBRE_RUTINA
		_agotado = false
		_revisar_umbrales()
	else:
		pasar(minutos_saltados, "dormir")

func _nivel_de_energia(e: int) -> int:
	if e <= ENERGIA_UMBRALES[1] * ESCALA:
		return 2
	return 1 if e <= ENERGIA_UMBRALES[0] * ESCALA else 0

func _nivel_de_hambre(h: int) -> int:
	if h >= HAMBRE_UMBRALES[1] * ESCALA:
		return 2
	return 1 if h >= HAMBRE_UMBRALES[0] * ESCALA else 0

func _revisar_umbrales() -> void:
	var ne := _nivel_de_energia(energia_m)
	if ne != _nivel_energia:
		_nivel_energia = ne
		estado_cambiado.emit("energia", ne)
	var nh := _nivel_de_hambre(hambre_m)
	if nh != _nivel_hambre:
		_nivel_hambre = nh
		estado_cambiado.emit("hambre", nh)

## ------------------------------------------------------------- GUARDADO ---

func a_dic() -> Dictionary:
	return {"en": energia_m, "ha": hambre_m, "ago": _agotado}

## Silencioso (los niveles se recalculan sin emitir). Un guardado sin necesidades
## (anterior a la fase 0) arranca con la rutina.
func desde_dic(d: Dictionary) -> void:
	energia_m = clampi(int(d.get("en", ENERGIA_RUTINA)), 0, MAXIMO)
	hambre_m = clampi(int(d.get("ha", HAMBRE_RUTINA)), 0, MAXIMO)
	_agotado = bool(d.get("ago", false))
	_nivel_energia = _nivel_de_energia(energia_m)
	_nivel_hambre = _nivel_de_hambre(hambre_m)
