class_name Instalaciones
extends RefCounted
## El ladrillo del club: 19 obras que se construyen, tardan semanas y se notan.
##
## Es el sistema que convierte el dinero en algo que no sean fichajes. Un club
## que solo ficha es un club que gasta; uno que construye es un club que crece,
## y esa diferencia es la mitad de lo que hace largo a un manager.
##
## DOS REGLAS QUE VIENEN DEL HTML Y NO SE TOCAN:
##
## 1. **Las obras NO son instantáneas.** Cada una tarda sus semanas (`SEMANAS`).
##    En el HTML esto se cambió a propósito en la v2.5: cuando eran instantáneas,
##    el primer día de la temporada se compraba todo y el sistema desaparecía.
##    Ahora hay que decidir QUÉ construyes primero, que es la decisión de verdad.
##
## 2. **Cada nivel tiene que notarse en un número que el jugador pueda ver.**
##    Aquí no hay ni una obra decorativa: cada una entra por una puerta concreta
##    -aforo, ocupación, ingresos mensuales, lesiones, cantera- y esas puertas
##    están todas listadas abajo en `efecto()`. Una obra que no mueve nada es un
##    botón de gastar dinero, y este proyecto ya pagó ese error varias veces.

signal obra_iniciada(clave: String, nivel: int, coste: int, semanas: int)
signal obra_terminada(clave: String, nivel: int)
## M-228 (20-10): lo que salió mal en una obra (retraso o sobrecoste), para la prensa.
var ultimos_imprevistos: Array[String] = []
## Las obras que ya tuvieron su imprevisto (uno como mucho por obra).
var imprevistos: Dictionary = {}

## El nivel máximo de cada obra. Cinco es suficiente: con el coste creciendo al
## cuadrado, el quinto nivel de una tribuna ya es una decisión de club.
const NIVEL_MAX := 10
## DE 5 A 10 NIVELES (26-9-2026, plan maestro C10). Las tribunas se quedan en 5:
## cada nivel es +15 % de aforo y el estadio ya llega a sus cinco bandejas y
## ~150.000 personas con eso. El resto sube a 10, pero de 6 a 10 cada nivel
## rinde la MITAD (`_ef()`): la inversión se nota sin que el centro médico
## acabe curando una rotura en una semana.
const NIVEL_MAX_DE := {"trib": 5}

func maximo(clave: String) -> int:
	return int(NIVEL_MAX_DE.get(clave, NIVEL_MAX))

## El nivel "efectivo": completo hasta 5, la mitad por encima.
func _ef(clave: String) -> float:
	var n := float(nivel(clave))
	var base := n if n <= 5.0 else 5.0 + (n - 5.0) * 0.5
	## EL PERSONAL CUENTA (26-9-2026): un equipo bueno y contento rinde más
	## que la obra sola, uno flojo o quemado menos, y una avería resta hasta
	## que se arregla (`Trabajadores.semana()` lo fija cada semana).
	return base * float(factor_personal.get(clave, 1.0))

## instalación -> multiplicador del personal (0,75-1,15). Vacío = 1.
var factor_personal: Dictionary = {}

## Las seis de siempre y las trece que se añadieron después, en un solo
## catálogo: clave, nombre, qué hace y coste base. El coste base es del HTML.
const CATALOGO := {
	"trib":      ["Tribunas", "+15% de aforo por nivel", 600000],
	"cal":       ["Calidad del estadio", "Césped, luces y accesos: mejor asistencia", 260000],
	"med":       ["Centro médico", "Recuperación de lesiones más rápida", 220000],
	"ct":        ["Centro de entrenamiento", "Acelera el desarrollo de tus jugadores", 320000],
	"acad":      ["Academia juvenil", "Camadas de cantera de mejor nivel", 320000],
	"com":       ["Tienda y museo", "Ingresos mensuales por cada socio", 260000],
	"gim":       ["Gimnasio y recuperación", "Menos lesiones musculares y mejor físico", 240000],
	"resid":     ["Residencia de canteranos", "Retiene juveniles y mejora su progreso", 280000],
	"video":     ["Sala de video y análisis", "Mejor lectura del rival en la previa", 180000],
	"rehab":     ["Centro de rehabilitación", "Acorta las lesiones largas", 300000],
	"museo":     ["Museo del club", "Ingresos por turismo y reputación", 220000],
	"park":      ["Estacionamientos y accesos", "Más ingresos por día de partido", 160000],
	"pren":      ["Sala de prensa moderna", "Mejora tu imagen ante los medios", 140000],
	"cocina":    ["Comedor y nutrición", "El plantel se recupera mejor cada semana", 150000],
	"piscina":   ["Piscina de recuperación", "Descarga las piernas: el plantel llega más entero", 200000],
	"guarderia": ["Guardería y zona familiar", "Los jugadores con hijos entrenan tranquilos", 120000],
	"bienestar": ["Espacio de bienestar", "Capilla y acompañamiento: baja la ansiedad del vestuario", 110000],
	"esports":   ["Sala de juegos y e-sports", "Los juveniles se quedan en el club", 100000],
	"huerto":    ["Huerto y zona sustentable", "Comida propia e imagen ecológica", 90000],
}

## Lo que tarda cada obra, en semanas. Sale de la tabla `INST_SEMANAS` del HTML;
## las que no estaban allí tardan cuatro, que es la media de las que sí.
const SEMANAS := {
	"trib": 8, "cal": 4, "med": 5, "ct": 6, "acad": 6, "com": 4,
	"gim": 4, "resid": 6, "video": 3, "rehab": 5, "museo": 4,
	"park": 3, "pren": 3, "cocina": 3,
	"piscina": 4, "guarderia": 3, "bienestar": 3, "esports": 3, "huerto": 3,
}
const SEMANAS_POR_DEFECTO := 4

var niveles: Dictionary = {}
## Las obras en marcha: clave -> semanas que faltan. Solo puede haber una de
## cada, pero varias distintas a la vez: es un club, no un albañil.
var obras: Dictionary = {}
## La última asistencia registrada, que es de donde salen los ingresos de
## estacionamiento. La escribe quien juegue el partido en casa.
var ultima_asistencia: int = 0

func _init() -> void:
	for k: String in CATALOGO:
		niveles[k] = 0

func nivel(clave: String) -> int:
	return int(niveles.get(clave, 0))

## Si TODAS las instalaciones están al tope. Lo pide el logro oculto "Imperio",
## que es el más largo del juego: son diecinueve obras a nivel cinco.
func todo_al_maximo() -> bool:
	for k: String in CATALOGO:
		if nivel(k) < maximo(k):
			return false
	return true

func en_obra(clave: String) -> bool:
	return obras.has(clave)

func semanas_de(clave: String) -> int:
	return int(SEMANAS.get(clave, SEMANAS_POR_DEFECTO))

## Lo que cuesta subir un nivel. Crece con el CUADRADO del nivel y escala con el
## tamaño del club: una tribuna para 60.000 no vale lo que una para 8.000.
func coste(clave: String, rep_club: int) -> int:
	if not CATALOGO.has(clave):
		return -1
	var n := nivel(clave)
	if n >= maximo(clave):
		return -1
	var base: float = float(CATALOGO[clave][2])
	var mult: float = pow(Eco.factor_club(float(rep_club)), 0.62)
	return int(round(base * float(n + 1) * float(n + 1) * mult / 1000.0) * 1000.0)

## Empieza una obra. Devuelve "" si arrancó, o el motivo por el que no.
func iniciar(clave: String, c: Club) -> String:
	if not CATALOGO.has(clave):
		return "esa obra no existe"
	if nivel(clave) >= maximo(clave):
		return "ya está al máximo"
	if en_obra(clave):
		return "ya hay una obra en marcha ahí"
	## DESBLOQUEO POR REPUTACIÓN (26-9-2026, idea 284): un club local no
	## construye un centro de nivel mundial. El tope sube con el nivel del club.
	var tope := Reputacion.tope_instalaciones(c.rep)
	if nivel(clave) >= tope:
		return "hace falta más reputación: un club %s llega hasta el nivel %d" % [Reputacion.nombre_nivel(c.rep).get_slice(" ", 1).to_lower(), tope]
	var precio := coste(clave, c.rep)
	if precio > c.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [precio, c.saldo]
	## Se paga POR ADELANTADO, como en una obra de verdad. Cobrar al terminar
	## permitiría empezar diez obras sin un peso y decidir después.
	c.mover_saldo(-precio)
	var plazo := semanas_de(clave)
	obras[clave] = plazo
	obra_iniciada.emit(clave, nivel(clave) + 1, precio, plazo)
	return ""

## Avanza una semana de obra. Devuelve las que acaban de terminar.
func avanzar_semana(c: Club) -> Array[String]:
	var listas: Array[String] = []
	ultimos_imprevistos.clear()
	for clave: String in obras.keys():
		_imprevisto(clave, c)
		obras[clave] = int(obras[clave]) - 1
		if int(obras[clave]) <= 0:
			obras.erase(clave)
			niveles[clave] = nivel(clave) + 1
			listas.append(clave)
			obra_terminada.emit(clave, nivel(clave))
	if not listas.is_empty():
		aplicar(c)
	return listas

## IMPREVISTOS DE OBRA (M-228, 20-10): como en las de verdad, alguna se
## retrasa (lluvias, un permiso) o sale más cara (los cimientos). Uno como mucho
## por obra, ~1 de cada 4 obras en total. Sin azar guardado: sale del nombre de
## la obra, las semanas que le quedan y lo construido, así que cargar la partida
## y volver a jugar la semana da lo mismo.
func _imprevisto(clave: String, c: Club) -> void:
	var marca := "%s_%d" % [clave, nivel(clave) + 1]
	if imprevistos.has(marca) or int(obras[clave]) <= 1:
		return
	var h := absi(hash("%s|%d|%d" % [clave, int(obras[clave]), construido()])) % 100
	if h >= 7:
		return
	imprevistos[marca] = true
	var nombre := String(CATALOGO[clave][0]) if CATALOGO.has(clave) else clave
	if h < 4:
		obras[clave] = int(obras[clave]) + 1
		ultimos_imprevistos.append("Obra «%s»: se retrasa una semana por lluvias y un permiso que no llegó." % nombre)
	else:
		var extra := int(round(float(maxi(coste(clave, c.rep), 0)) * 0.08 / 1000.0) * 1000.0)
		if extra > 0:
			c.mover_saldo(-extra)
		ultimos_imprevistos.append("Obra «%s»: problemas en los cimientos, cuesta un 8 %% más." % nombre)

## MANTENIMIENTO (M-227, 20-10): lo construido hay que cuidarlo. Cada mes se
## paga un 0,3 % del valor de cada nivel levantado (escalado con el tamaño del
## club, como el precio de la obra). Antes, una vez hecha, la obra no costaba
## nada más y la caja del club propio solo crecía.
func mantenimiento_del_mes(rep_club: int) -> int:
	var mult: float = pow(Eco.factor_club(float(rep_club)), 0.62)
	var total := 0.0
	for k: String in niveles:
		if CATALOGO.has(k):
			total += float(CATALOGO[k][2]) * float(niveles[k]) * 0.003 * mult
	return int(round(total / 100.0) * 100.0)

## Vuelca en el club lo que depende del ladrillo.
##
## Se escribe SIEMPRE el valor completo, nunca se acumula: acumulando, cargar
## dos veces la misma partida dejaba el aforo al doble. Es la misma trampa que
## `Staff.aplicar()`.
func aplicar(c: Club) -> void:
	c.estadio_aforo = int(round(float(_aforo_base(c)) * (1.0 + 0.15 * float(nivel("trib")))))

## El aforo de fábrica del club, sin tribunas construidas. Se guarda la primera
## vez que se aplica, porque `Club.estadio_aforo` ya viene modificado después.
var _aforo_original: int = 0

func _aforo_base(c: Club) -> int:
	if _aforo_original <= 0:
		_aforo_original = c.estadio_aforo
	return _aforo_original

func fijar_aforo_base(n: int) -> void:
	_aforo_original = n

# --- lo que aporta cada obra ------------------------------------------------
#
# Todas las puertas por las que las instalaciones tocan el juego, juntas y a la
# vista. Si mañana alguien añade una obra, este es el sitio donde tiene que
# aparecer, o no servirá para nada.

## Aporte a la ocupación del estadio. Es el `0.03*G.inst.cal` que le falta a la
## curva de `Finanzas.asistencia()`, y va aparte porque `finanzas.gd` no conoce
## las instalaciones.
func aporte_ocupacion() -> float:
	return 0.03 * _ef("cal")

## Ingresos del cierre de mes que no existen sin ladrillo.
func ingresos_del_mes(c: Club) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	if nivel("com") > 0:
		salida.append({"concepto": "Tienda y museo",
			"monto": int(round(float(c.socios) * 0.6 * float(nivel("com")) * factor_idolo(c)))})
	if nivel("museo") > 0:
		salida.append({"concepto": "Museo y turismo deportivo",
			"monto": int(round(float(c.socios) * 0.9 * float(nivel("museo"))))})
	if nivel("park") > 0:
		salida.append({"concepto": "Estacionamientos",
			"monto": int(round(float(ultima_asistencia) * 0.09 * float(nivel("park"))))})
	return salida

## LAS CAMISETAS DEL ÍDOLO (M-224, 20-10): la tienda vende más cuanto mejor es la
## estrella del plantel (la de más media): con un 75 o menos, lo normal; con un
## 90, un 60 % más. Así fichar a un crack también se nota en la caja.
static func factor_idolo(c: Club) -> float:
	var mejor := 0
	for j: Jugador in c.plantilla:
		mejor = maxi(mejor, j.ovr)
	return 1.0 + clampf(float(mejor - 75) * 0.04, 0.0, 0.8)

## Semanas que se le quitan a una lesión. Se suman el centro médico y el de
## rehabilitación, y el gimnasio ayuda a partir del nivel 3.
func descuento_lesion() -> int:
	return int(_ef("med") + _ef("rehab")) + (1 if nivel("gim") >= 3 else 0)

## Forma que se deja de perder cada semana: comedor y piscina.
func aguante() -> int:
	return int(floor((_ef("cocina") + _ef("piscina")) / 2.0))

## Cuánto más rápido progresan tus jugadores con el centro de entrenamiento.
func ritmo_de_progreso() -> float:
	return 1.0 + 0.12 * _ef("ct")

## Techo extra de los canteranos: academia y residencia.
func techo_cantera() -> int:
	return int(_ef("acad")) + int(floor(_ef("resid") / 2.0))

## Cuántos juveniles se quedan en vez de irse: residencia y sala de juegos.
func retencion_juvenil() -> float:
	return clampf(0.08 * (_ef("resid") + _ef("esports")), 0.0, 0.6)

## Menos ansiedad en el vestuario: bienestar y guardería.
func calma_del_vestuario() -> int:
	return int(_ef("bienestar") + _ef("guarderia"))

## Mejor lectura del rival en la previa: la sala de video.
func lectura_del_rival() -> int:
	return int(_ef("video"))

## Imagen ante los medios: sala de prensa.
func imagen_en_prensa() -> int:
	return int(_ef("pren"))

## Certificación ecológica: el huerto abarata la operación un 12%, igual que el
## `G.ciudad.eco.cert` del HTML.
func abarata_operacion() -> float:
	return 0.88 if nivel("huerto") >= 3 else 1.0

## Cuántas obras hay levantadas, para poder enseñar el progreso del club de un
## vistazo sin sumar diecinueve números a mano.
func construido() -> int:
	var n := 0
	for k: String in niveles:
		n += int(niveles[k])
	return n

func a_dic() -> Dictionary:
	return {"niveles": niveles, "obras": obras, "aforo_base": _aforo_original,
		"ultima_asistencia": ultima_asistencia, "imprevistos": imprevistos}

func desde_dic(d: Dictionary) -> void:
	var n: Dictionary = d.get("niveles", {})
	for k: String in CATALOGO:
		niveles[k] = int(n.get(k, 0))
	obras = d.get("obras", {}).duplicate()
	_aforo_original = int(d.get("aforo_base", 0))
	ultima_asistencia = int(d.get("ultima_asistencia", 0))
	imprevistos = (d.get("imprevistos", {}) as Dictionary).duplicate()
