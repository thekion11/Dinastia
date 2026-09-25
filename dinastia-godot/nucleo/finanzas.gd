class_name Finanzas
extends RefCounted
## El dinero que entra y sale cada semana.
##
## Las fórmulas son las del HTML. La de la taquilla en particular tiene una
## forma que parece arbitraria y no lo es:
##
##     ocupacion = 0.28 + rep/230 + (confianza-50)/300 - (precio-6)*0.05 + socios/(aforo*4)
##
## Cada sumando es una palanca que el jugador puede mover, y todas tiran en
## direcciones distintas: subir el precio llena la caja por entrada pero vacía
## el estadio, y el estadio vacío baja la confianza, que a su vez vacía más el
## estadio. Es lo que impide que exista un precio "óptimo" que se pone una vez y
## ya está.

## Puntos por espectador y unidad de precio.
const PPE := 0.25

## Cada cuantas semanas se cierra el mes. El HTML usa `G.sem%4===0`.
const SEMANAS_DEL_MES := 4

signal movimiento(concepto: String, monto: int)

var _club: Club

## Lo que aportan las instalaciones a la ocupacion del estadio. Viene de fuera
## porque `Finanzas` no conoce las obras: es el `0.03*G.inst.cal` del HTML, y
## sin el, mejorar la calidad del estadio no llenaria una sola butaca mas.
var aporte_instalaciones: float = 0.0

## Honorarios semanales de los consejeros del directorio -viene de fuera
## porque `Finanzas` no conoce a `Directiva`, igual que con `aporte_obras`-.
var honorarios_consejeros: int = 0

## El consejero de marketing (`mkt`) sube esto un 10%: `bono_patrocinio=0.1`.
var bono_patrocinio: float = 0.0

## Si esta cuenta corre para este club: "oper" del HTML solo se le cobraba a
## `G.miClub`, nunca a la IA -los otros 383 clubes usan el ajuste de la
## directiva como correctivo (ver el comentario grande antes de `mes()`), y
## sumarles esta partida suelta sin re-calibrar ese correctivo habria vuelto a
## descuadrar la misma curva que costo esa depuracion-.
var aplica_operacion: bool = false

## Cuanto abarata la operacion la certificacion ecologica del huerto -
## "G.ciudad.eco.cert" del HTML-. Viene de fuera porque `Finanzas` no conoce a
## `Instalaciones`, igual que `aporte_instalaciones` un poco mas abajo.
var factor_operacion: float = 1.0

## El multiplicador de los derechos de television. Viene de fuera por lo mismo
## que el bono de marketing: `Finanzas` no conoce ni a la federacion ni a la
## prensa. Lo componen tres cosas que YA se calculaban y no las aplicaba nadie:
## el reparto que vota la asamblea (`Federacion.factor_tv()`), el modelo de
## contrato que elige el club (`Prensa.factor_tv()`) y, por partido, el plus del
## horario. Estuvieron meses siendo numeros que no movian una moneda.
var factor_tv: float = 1.0

func _init(club: Club, aporte_obras: float = 0.0, honorarios: int = 0, bono_mkt: float = 0.0) -> void:
	_club = club
	aporte_instalaciones = aporte_obras
	honorarios_consejeros = honorarios
	bono_patrocinio = bono_mkt

## Lo que deja cada espectador con el precio de entrada puesto.
static func ingreso_por_espectador(precio: float) -> float:
	return (precio + 2.0) * PPE

## Cuánta gente entra. El tope es el aforo; el suelo, un 12%: ni con el peor
## equipo y la entrada más cara se queda un estadio completamente vacío.
func asistencia(gano_el_ultimo: bool = false) -> int:
	var ocupacion := 0.28 \
		+ float(_club.rep) / 230.0 \
		+ (float(_club.confianza) - 50.0) / 300.0 \
		- (_club.precio_entrada - 6.0) * 0.05 \
		+ minf(0.25, float(_club.socios) / float(maxi(_club.estadio_aforo * 4, 1))) \
		+ aporte_instalaciones \
		+ (0.02 if gano_el_ultimo else 0.0)
	return int(round(float(_club.estadio_aforo) * clampf(ocupacion, 0.12, 0.99)))

## Un partido en casa. Devuelve lo recaudado y deja constancia.
## `factor_horario` es lo que hace que elegir la hora del partido sea una
## decisión y no un adorno: un lunes por la noche llena un tercio menos el
## estadio pero paga más derechos de televisión. Lo pasa `Mundo`, que es quien
## sabe qué horario está elegido.
## El precio que se cobra HOY. Normalmente es el del club; con precios
## dinamicos encendidos, `Mundo` lo sustituye por el que sale de la reputacion
## del rival antes de llamar aqui. Viene de fuera por lo mismo que el factor de
## television: `Finanzas` no sabe contra quien se juega.
var precio_de_hoy: float = 0.0

func taquilla(gano_el_ultimo: bool = false, factor_horario: float = 1.0) -> int:
	var gente := int(round(float(asistencia(gano_el_ultimo)) * factor_horario))
	var precio: float = precio_de_hoy if precio_de_hoy > 0.0 else _club.precio_entrada
	var monto := int(round(float(gente) * ingreso_por_espectador(precio)))
	_club.mover_saldo(monto)
	movimiento.emit("Taquilla (%d espectadores)" % gente, monto)
	return monto

## Los sueldos del mes: la masa salarial semanal por las cuatro semanas.
func pagar_sueldos() -> int:
	var monto := _club.masa_salarial() * SEMANAS_DEL_MES
	_club.mover_saldo(-monto)
	movimiento.emit("Sueldos del plantel", -monto)
	return monto

## Publicidad y patrocinios. Depende de la reputación y del peso económico de la
## liga: el mismo club en Inglaterra factura mucho más que en Bolivia. Segunda
## división cobra un tercio.
func patrocinio_base() -> int:
	return int(round(180000.0 \
		* pow(Eco.factor_club(float(_club.rep)), 0.8) \
		* pow(Eco.tier_pais(_club.pais) / Eco.tier_pais("CHI"), 0.5) \
		* (0.35 if _club.division == 2 else 1.0) \
		* (1.0 + bono_patrocinio)))

func patrocinio() -> int:
	var monto := patrocinio_base()
	_club.mover_saldo(monto)
	movimiento.emit("Publicidad y patrocinios", monto)
	return monto

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
func derechos_tv_base() -> int:
	var base := 58000.0 if _club.division == 2 else 300000.0
	return int(round(base \
		* pow(Eco.factor_club(float(_club.rep)), 0.85) \
		* pow(Eco.tier_pais(_club.pais) / Eco.tier_pais("CHI"), 0.6)))

func derechos_tv() -> int:
	var monto := int(round(float(derechos_tv_base()) * factor_tv))
	_club.mover_saldo(monto)
	movimiento.emit("Derechos de televisión", monto)
	return monto

## Cuotas de socios. La masa social paga todos los meses juegue quien juegue, y
## es lo que sostiene a los clubes grandes en las malas rachas.
func cuotas_socios_base() -> int:
	return int(round(float(_club.socios) * 2.0))

func cuotas_socios() -> int:
	var monto := cuotas_socios_base()
	_club.mover_saldo(monto)
	movimiento.emit("Cuotas de socios", monto)
	return monto

## Gastos de estructura: la parte del club que no son sueldos de futbolistas
## (cuerpo técnico, mantenimiento, viajes). Escala con el tamaño del club.
func estructura_base() -> int:
	return Eco.escalar(48000.0, float(_club.rep)) * SEMANAS_DEL_MES \
		+ honorarios_consejeros * SEMANAS_DEL_MES

## LA PROYECCION NO COBRA. Estas cuatro funciones `_base()` existen porque las
## de arriba mueven el saldo, y `proyeccion_anual()` las llamaba para ESTIMAR:
## abrir la pantalla de Finanzas le pagaba al club un mes de television, de
## patrocinio y de cuotas, y le cobraba un mes de estructura, en CADA repintado.
## Mirar las cuentas cambiaba las cuentas.
func estructura() -> int:
	var monto := estructura_base()
	_club.mover_saldo(-monto)
	movimiento.emit("Cuerpo técnico y estructura", -monto)
	return monto

## LA SEMANA: solo la taquilla del domingo.
##
## Todo lo demás va al cierre de mes. Es como está en el HTML y no es un detalle
## de contabilidad: le da al juego un pulso. Hay semanas en las que solo entra lo
## de la puerta y un día del mes en el que se paga todo de golpe, y ese día es
## cuando un club mal llevado descubre que no llega.
func semana(jugo_en_casa: bool, gano_el_ultimo: bool = false, factor_horario: float = 1.0) -> Dictionary:
	var entra := 0
	if jugo_en_casa:
		entra = taquilla(gano_el_ultimo, factor_horario)
	return {"entra": entra, "sale": 0, "neto": entra}

## EL CIERRE DE MES, cada cuatro semanas.
##
## OJO CON LAS UNIDADES, que aquí ya hubo un error: el patrocinio, la televisión
## y las cuotas son cifras MENSUALES, mientras que `sueldo` es semanal y por eso
## se multiplica por cuatro. Cobrando las mensuales todas las semanas, cada club
## ganaba 32 millones cada siete días y el mundo entero nadaba en dinero; sin
## ellas, perdía cinco millones y quebraba en tres meses. Las dos versiones
## pasaban el resto de las pruebas sin quejarse.
##
## Primero lo que entra y después lo que sale, para que un club justo de caja
## cobre antes de pagar la nómina, que es como funciona de verdad.
func mes() -> Dictionary:
	var ing_pat := patrocinio()
	var ing_tv := derechos_tv()
	var entra := ing_pat + ing_tv + cuotas_socios()
	var sale := pagar_sueldos() + estructura()
	if aplica_operacion:
		sale += operacion(ing_tv, ing_pat)
	return {"entra": entra, "sale": sale, "neto": entra - sale}

## "Operación, viajes, seguridad e impuestos" del HTML: mantenimiento del
## estadio, viajes, seguridad, servicios e impuestos. El 42% de lo que dejaron
## television y patrocinio ESTE mes -no una cifra aparte-, recortado un 12% con
## la certificación ecológica del huerto. Sin esto, portado solo con sueldos y
## estructura, el club se quedaba con un 42% de la television y el patrocinio
## que el HTML nunca le dejaba.
func operacion(ingreso_tv: int, ingreso_patrocinio: int) -> int:
	var monto := int(round(float(ingreso_tv + ingreso_patrocinio) * 0.42 * factor_operacion))
	if monto <= 0:
		return 0
	_club.mover_saldo(-monto)
	movimiento.emit("Operación, viajes, seguridad e impuestos", -monto)
	return monto

## LA DIRECTIVA CUADRA LAS CUENTAS. Solo para los clubes de la IA.
##
## Hace falta por un desajuste real de las curvas del juego, que conviene tener
## escrito porque no se ve a simple vista: los ingresos crecen con la reputación
## a razón de 1,113 por punto (van con `factorClub^0.85`), mientras que los
## sueldos crecen a 1,087 (van con `valor^0.66`, y el valor con la media, que
## sigue a la reputación). Las dos curvas se cruzan en el club medio: por encima,
## el club gana dinero solo; por debajo, lo pierde solo.
##
## En el HTML esto no se nota porque SOLO se lleva la contabilidad de tu club;
## los otros 383 tienen la caja puesta en `refCaja(rep)` y no la mueve nadie
## salvo los fichajes. Aquí se simulan todos, así que el desajuste sale a flote:
## sin esto, en tres temporadas Colo-Colo triplicaba su caja y Cobreloa acababa
## con 86 millones en rojo.
##
## Lo que hace es lo que hace una directiva de verdad: si el club está en rojo lo
## rescata, y si acumula de más se reparte el excedente. Solo corrige una parte
## cada mes, así que un club sigue notando durante un tiempo si vendió bien o
## fichó mal; lo que no puede es quebrar ni volverse infinito.
##
## A TU club no se le aplica: ahí la caja es tuya y las consecuencias también.
## `contabilidad()` del HTML: la proyección del ejercicio entero, para poder
## mirar el año de un vistazo en vez de deducirlo del cierre de mes.
##
## NO INVENTA NÚMEROS: multiplica las mismas partidas que ya cobra y paga
## `mes()` por los meses que tiene una temporada. Si mañana cambia una fórmula
## del motor, esta proyección cambia con ella -que es justo lo que se le pide a
## una previsión: mentir menos que una tabla escrita a mano-.
const MESES_TEMPORADA := 10

func proyeccion_anual(partidos_en_casa: int, ingreso_tienda_mes: int = 0) -> Dictionary:
	var ingresos := {
		"Derechos de televisión": int(round(float(derechos_tv_base()) * factor_tv)) * MESES_TEMPORADA,
		"Patrocinio": patrocinio_base() * MESES_TEMPORADA,
		"Cuotas de socios": cuotas_socios_base() * MESES_TEMPORADA,
		"Taquilla": int(round(float(asistencia()) * ingreso_por_espectador(_club.precio_entrada))) * partidos_en_casa,
		"Tienda del club": ingreso_tienda_mes * MESES_TEMPORADA,
	}
	var gastos := {
		"Sueldos del plantel": _club.masa_salarial() * SEMANAS_DEL_MES * MESES_TEMPORADA,
		"Honorarios del directorio": honorarios_consejeros * SEMANAS_DEL_MES * MESES_TEMPORADA,
		"Estructura": estructura_base() * MESES_TEMPORADA,
	}
	if aplica_operacion:
		var oper_mes := int(round(
			(float(round(float(derechos_tv_base()) * factor_tv)) + float(patrocinio_base())) \
			* 0.42 * factor_operacion))
		gastos["Operación, viajes, seguridad e impuestos"] = oper_mes * MESES_TEMPORADA
	var total_ing := 0
	for k: String in ingresos:
		total_ing += int(ingresos[k])
	var total_gas := 0
	for k2: String in gastos:
		total_gas += int(gastos[k2])
	## El porcentaje de masa salarial sobre ingresos es LA cifra que mira
	## cualquiera que entienda de esto: por encima del 70% el club va camino de
	## un problema aunque la caja de hoy se vea bien.
	var pct_salarial := 0
	if total_ing > 0:
		pct_salarial = int(round(float(gastos["Sueldos del plantel"]) * 100.0 / float(total_ing)))
	return {
		"ingresos": ingresos, "gastos": gastos,
		"total_ingresos": total_ing, "total_gastos": total_gas,
		"resultado": total_ing - total_gas, "pct_salarial": pct_salarial,
	}

func ajuste_de_directiva(fuerza: float = 0.25) -> int:
	var referencia := Eco.ref_caja(float(_club.rep))
	var desvio := referencia - float(_club.saldo)
	var monto := int(round(desvio * fuerza))
	## El arrastre proporcional no basta por sí solo: al club más chico de la
	## Primera B el agujero mensual le crecía más rápido de lo que un 25% podía
	## corregir, y acababa la tercera temporada con seis millones en rojo. Por
	## debajo de cero, la directiva pone lo que falta hasta un colchón mínimo.
	## Es lo que impide que medio mundo esté en quiebra técnica en dos años y no
	## pueda fichar a nadie.
	var suelo := int(referencia * 0.05)
	if _club.saldo + monto < suelo:
		monto = suelo - _club.saldo
	if monto == 0:
		return 0
	_club.mover_saldo(monto)
	movimiento.emit("Ajuste de la directiva" if monto > 0 else "Reparto de excedente", monto)
	return monto

# ---------------------------------------------------------------------------
#  CAMPAÑAS Y GUERRA DE MARCAS (`vSponsor()`)
# ---------------------------------------------------------------------------
#
# Las campañas NO dan dinero directo, y eso es lo que las hace interesantes:
# mueven socios, ánimo y seguidores, que son las cosas que después sí acaban
# dando dinero. Una por temporada, para que elegir cuál duela.
#
# Estas son estáticas y no tocan estado propio: `Finanzas` se construye por club
# y por semana -no sobrevive de una a otra-, así que lo que hay que recordar
# (qué campaña se lanzó este año) lo guarda `Mundo`.

## clave, nombre, descripción, coste base, y qué mueve.
const CAMPANAS := [
	["abonos", "Campaña de abonos", "Vallas, radio y puerta a puerta para vender carnets", 120000,
		{"socios": 0.14, "animo": 4}],
	["cantera", "«Del barrio al primer equipo»", "Pone el foco en la cantera y en la identidad", 90000,
		{"animo": 7}],
	["internacional", "Campaña internacional", "Busca hinchas fuera del país para vender camisetas", 260000,
		{"seguidores": 0.22}],
	["familia", "«Ven con los tuyos»", "Entradas familiares y actividades para niños", 70000,
		{"socios": 0.08}],
	["leyendas", "«Los que vistieron esta camiseta»", "Nostalgia pura con los ídolos históricos", 140000,
		{"animo": 10, "socios": 0.05}],
]

static func def_campana(clave: String) -> Array:
	for f: Array in CAMPANAS:
		if String(f[0]) == clave:
			return f
	return []
