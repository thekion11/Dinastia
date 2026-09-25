class_name EstadioPropio
extends RefCounted
## El estadio de TU club: el único del mundo que no sale de un hash.
##
## `Club.perfil_estadio()` deriva el recinto de cada club del hash de su id, y
## para los rivales está bien: así el estadio de Coquimbo es siempre el mismo
## partido tras partido. Pero el tuyo no puede ser una casualidad. Esta clase es
## la que te deja DISEÑARLO —forma, bandejas, techo, césped, butacas, focos,
## pantalla, vallas, la hora del día— y la que hace que cambiarlo cueste dinero,
## que es lo que separa un editor de skins de una decisión de club.
##
## EL CONTRATO CON EL VISOR 3D. `perfil()` devuelve exactamente las claves que
## consume `visor/stadium_builder.gd` y `visor/ambience.gd`:
##   build_pitch() -> cesped, cespedClaro, cespedOscuro, lineaCol, arcoCol,
##                    redCol, redTipo, corner, banquillo, tunel, escudoDonde
##   build()       -> forma, niveles, techo, asientoP, asiento1, asiento2,
##                    asiento3, vallas, focos, pantalla, bandejas (opcional),
##                    tramos (opcional), escudoDonde
##   altura_de()   -> niveles
##   Ambience      -> clima, focos
##   VistaEstadio  -> aforo, forma, niveles, techo
##   estadio.gd    -> sonidoGol (elige el efecto de `Sonido` en cada gol propio)
## Ni una clave de más ni una de menos respecto de lo que ya se lee ahí. Si el
## visor pide una clave que no está, no falla: pone su valor por defecto y el
## estadio sale distinto del que diseñaste, que es peor que un error.
##
## `bandejas` (16-9-2026, "el estadio por MÓDULOS", Fase 1 de 3 del ROADMAP:
## bandeja → componentes → tramo) es la ÚNICA clave opcional del contrato: solo
## aparece cuando `personalizar_bandejas` está activo, y solo entonces
## `StadiumBuilder.build()` la mira. Con el interruptor apagado -el caso de
## siempre, y el de CUALQUIER estadio rival- `perfil()` no cambia una sola
## clave respecto a como era antes de esta fase.
##
## `redTipo`/`corner`/`banquillo`/`tunel`/`escudoDonde` (16-9-2026, Fase 2:
## "Componentes") YA estaban en `ajustes`, ya se cobraban y ya se pintaban en
## el diseñador -pero `perfil()` nunca se las pasaba al visor, así que hasta
## esta fase no cambiaban nada en 3D. Los defaults que usa
## `StadiumBuilder` para estas 5 claves cuando faltan (siempre, para
## cualquier rival) son EXACTAMENTE el dibujo único que ya existía antes de
## esta fase -salvo `escudoDonde`, que no existía como dibujo: su default ahí
## es "sin", no el "cancha" de fábrica de `EST_DEF`, a propósito, para que
## nadie vea aparecer un escudo que nunca pidió.
##
## `tramos` (22-9-2026, Fase 3: "Tramo") es la SEGUNDA clave opcional del
## contrato, con el mismo criterio que `bandejas`: solo aparece cuando
## `personalizar_tramos` está activo. Es independiente de `personalizar_
## bandejas` -se puede mezclar patrones por tercios en una tribuna sin haber
## tocado el estilo global de ninguna, y viceversa-. El spike del 18-9
## (`LEEME.md`, "SPIKE CORRIDO CON PANTALLA REAL") confirmó que el corte se
## sostiene visualmente con una condición: `StadiumBuilder` tiene que generar
## la textura de esa tribuna con `uv1_scale.y=1` (sin repetir), no con el
## repetido-cada-20m de una tribuna de un solo patrón.
##
## EL AFORO NO ES SUYO. Lo gestiona `Instalaciones`: la obra "trib" da +15% por
## nivel y `aplicar()` lo escribe en `Club.estadio_aforo`. Aquí solo se LEE del
## club y se le aplica el factor de forma, que sí es una decisión de diseño (un
## óvalo cabe más gente que una herradura). Duplicar el aforo aquí sería la
## forma más rápida de que la taquilla y el estadio 3D dejaran de coincidir.

signal reforma_hecha(cambios: Dictionary, coste: int, aviso: String)
signal movimiento(concepto: String, monto: int)
signal renombrado(nombre: String)

## Nombre del recinto. Vacío = "Estadio " + el nombre del club, igual que el
## `G.estadioNom||('Estadio '+...)` del HTML. Bautizarlo no cuesta nada: es lo
## único de esta pantalla que es solo tuyo.
var nombre: String = ""

## El diseño entero, con LAS MISMAS CLAVES que `G.est` en el HTML, sembrado de
## la tabla `EST_DEF` exportada. Es un diccionario y no treinta campos con
## nombre a propósito: el catálogo de opciones vive en `tablas.json`, así que si
## el juego añade mañana un tipo de techo aparece solo, sin tocar esta clase.
var ajustes: Dictionary = {}

## --- QUÉ CUESTA CADA REFORMA -----------------------------------------------
## El HTML no cobraba nada por rediseñar (era una maqueta: se tocaba un desplegable
## y el estadio cambiaba de alma gratis). Aquí sí se cobra, porque un estadio que
## se rehace gratis no es una decisión, es un menú de opciones.
##
## Los precios NO son inventados de cero: están anclados al catálogo de obras que
## ya está equilibrado en `Instalaciones.CATALOGO` —la tribuna vale 600.000 y la
## calidad del estadio 260.000—, y como todo coste operativo del juego pasan por
## `Eco.escalar()`, así que rehacer el recinto de un grande cuesta lo que su
## tamaño y no una cifra plana.
const PRECIO := {
	"obra": 480000.0,      ## mover el graderío de sitio: forma, pista, túnel
	"bandeja": 380000.0,   ## por cada bandeja NUEVA que se levanta
	"techo": 320000.0,
	"focos": 150000.0,
	"pantalla": 210000.0,
	"mobiliario": 70000.0,
	"vallas": 40000.0,
	"cesped": 60000.0,     ## resembrar: el patrón y el tono son la misma faena
	"butacas": 90000.0,    ## rebutacar el recinto entero
	"pintura": 0.0,        ## cal, redes, banderas y la hora del partido: gratis
	## Encender el modo "cada tribuna distinta" es una decisión de diseño, no un
	## interruptor gratis -si fuera pintura, cambiarlo y volver a apagarlo sería
	## una forma barata de esquivar el precio de una reforma real.
	"personalizacion": 90000.0,
	## Mismo criterio que "personalizacion" (bandejas) pero para "Mezclar
	## patrones por tercios" (tramos): una decisión más fina -12 campos contra
	## 8- así que vale más que el interruptor de bandejas, pero sigue muy por
	## debajo de una obra real (no se levanta ni un ladrillo, solo cambia la
	## textura de la grada).
	"personalizacion_tramos": 130000.0,
}

## A qué capítulo de obra pertenece cada opción del diseñador. Lo que no esté
## aquí es pintura, o sea gratis: es la respuesta segura si mañana aparece una
## opción nueva en el catálogo.
const CAPITULO := {
	"forma": "obra", "pista": "obra", "tunel": "obra",
	"niveles": "bandeja",
	"techo": "techo",
	"focos": "focos",
	"pantalla": "pantalla",
	"banquillo": "mobiliario",
	"vallas": "vallas",
	"cesped": "cesped", "cespedTono": "cesped",
	"asientoP": "butacas", "asiento1": "butacas", "asiento2": "butacas",
	"asiento3": "butacas", "mosaico": "butacas",
	"personalizar_bandejas": "personalizacion",
	"bandeja_sur_asientoP": "butacas", "bandeja_sur_techo": "techo",
	"bandeja_norte_asientoP": "butacas", "bandeja_norte_techo": "techo",
	"bandeja_este_asientoP": "butacas", "bandeja_este_techo": "techo",
	"bandeja_oeste_asientoP": "butacas", "bandeja_oeste_techo": "techo",
	"personalizar_tramos": "personalizacion_tramos",
	## Los 12 tercios son, en plata, la misma faena que rebutacar -eligen un
	## patrón de asiento, no levantan nada-, así que pagan el mismo capítulo
	## "butacas" que `asientoP`/`bandeja_<lado>_asientoP`.
	"tramo_sur_1": "butacas", "tramo_sur_2": "butacas", "tramo_sur_3": "butacas",
	"tramo_norte_1": "butacas", "tramo_norte_2": "butacas", "tramo_norte_3": "butacas",
	"tramo_este_1": "butacas", "tramo_este_2": "butacas", "tramo_este_3": "butacas",
	"tramo_oeste_1": "butacas", "tramo_oeste_2": "butacas", "tramo_oeste_3": "butacas",
}

## De qué tabla salen las opciones válidas de cada campo. Sirve para dos cosas:
## llenar los desplegables de la interfaz y, sobre todo, no dejar que llegue al
## visor una forma que no sabe construir —`geom_de_forma()` caería en su rama
## por defecto y te dibujaría un cuenco donde pediste una herradura.
const CATALOGO_DE := {
	"forma": "EST_FORMAS", "techo": "EST_TECHOS", "asientoP": "EST_ASIENTOS",
	"cesped": "EST_CESPED", "cespedTono": "EST_TONOS", "focos": "EST_FOCOS",
	"pantalla": "EST_PANTALLAS", "clima": "EST_CLIMAS", "banderas": "EST_BANDERAS",
	"corner": "EST_CORNER", "banquillo": "EST_BANQUILLOS", "tunel": "EST_TUNELES",
	"escudoDonde": "EST_ESCUDOS", "redTipo": "EST_REDTIPO",
	"lineaCol": "EST_LINEAS", "arcoCol": "EST_ARCOS", "redCol": "EST_REDES",
	"sonidoGol": "EST_SONIDOS",
	"bandeja_sur_asientoP": "EST_ASIENTOS", "bandeja_sur_techo": "EST_TECHOS",
	"bandeja_norte_asientoP": "EST_ASIENTOS", "bandeja_norte_techo": "EST_TECHOS",
	"bandeja_este_asientoP": "EST_ASIENTOS", "bandeja_este_techo": "EST_TECHOS",
	"bandeja_oeste_asientoP": "EST_ASIENTOS", "bandeja_oeste_techo": "EST_TECHOS",
	## Los tercios eligen patrón de butaca, nunca techo -el spike confirmó que
	## techo/fachada/altura siguen siendo del recinto entero, ver el contrato
	## de `perfil()` más arriba-, así que los 12 comparten el mismo catálogo
	## que `asientoP`.
	"tramo_sur_1": "EST_ASIENTOS", "tramo_sur_2": "EST_ASIENTOS", "tramo_sur_3": "EST_ASIENTOS",
	"tramo_norte_1": "EST_ASIENTOS", "tramo_norte_2": "EST_ASIENTOS", "tramo_norte_3": "EST_ASIENTOS",
	"tramo_este_1": "EST_ASIENTOS", "tramo_este_2": "EST_ASIENTOS", "tramo_este_3": "EST_ASIENTOS",
	"tramo_oeste_1": "EST_ASIENTOS", "tramo_oeste_2": "EST_ASIENTOS", "tramo_oeste_3": "EST_ASIENTOS",
}

## Las 4 tribunas, en el mismo orden e índices que `visor/stadium_builder.gd`
## comenta en su array `stands` (0=sur 1=norte 2=este 3=oeste) -mismo nombre a
## los dos lados del contrato para no tener que traducir un índice a un lado.
const LADOS_BANDEJA := ["sur", "norte", "este", "oeste"]

## Butacas por bandeja que el visor considera justificadas. Es el mismo número
## que usa `StadiumBuilder.niveles_de()`, y está aquí repetido a propósito: si
## el diseñador ofreciera una bandeja que el visor no va a dibujar, la pantalla
## de diseño estaría mintiendo.
const BUTACAS_POR_BANDEJA := 22000.0
## CINCO, NO TRES (23-9-2026). Pedido del usuario: *"habrá que hacerle más
## bandejas y variantes para cuando uno agrande el estadio (máximo 150.000)"*.
## El techo de aforo del juego cuadra con eso: `Instalaciones` da +15% por nivel
## de tribuna hasta el nivel 5 (×1,75) y la forma añade hasta ×1,14, así que un
## club grande llega a ~150.000. Con 22.000 butacas por bandeja, ese aforo pide
## siete bandejas; cinco es donde se corta, que es lo que tienen los estadios
## más grandes del mundo de verdad.
##
## Esto SOLO fue posible después de rehacer el graderío por bandejas en
## `StadiumBuilder`: con el modelo viejo -una rampa única de 11 m de fondo- una
## cuarta bandeja habría sido una pared de 65 grados. Ver `LEEME.md`, 23-9.
const NIVELES_MAX := 5

func _init() -> void:
	_sembrar()

## Arranca del EST_DEF exportado. Si por lo que sea no está la tabla, se usa un
## diseño mínimo que el visor sepa construir: quedarse sin estadio por una tabla
## que falta sería el peor de los fallos posibles.
func _sembrar() -> void:
	var def: Variant = Datos.tabla("EST_DEF")
	if def is Dictionary:
		ajustes = (def as Dictionary).duplicate(true)
	else:
		ajustes = {
			"forma": "cuenco", "niveles": 2, "techo": "anillo", "pista": false,
			"asientoP": "franjas", "asiento1": "", "asiento2": "", "asiento3": "#20272a",
			"cesped": "rayas", "cespedTono": "vivo", "lineaCol": "#ffffff",
			"arcoCol": "#ffffff", "redCol": "#ffffff", "focos": "torres",
			"pantalla": "dos", "clima": "noche", "banderas": "club", "vallas": true,
		}

# ============================================================================
# EL CONTRATO CON EL VISOR
# ============================================================================

## El diseño en el formato que consume el estadio 3D. Mismas claves que
## `Club.perfil_estadio()`, más los colores que aquel deja en su valor por
## defecto porque un rival no tiene diseñador.
##
## `personalizado: true` es la marca de que este recinto lo hizo alguien y no un
## hash: sirve para que la interfaz sepa cuándo enseñar el botón de rediseñar.
func perfil(mi: Club, obras: Instalaciones = null) -> Dictionary:
	var tono := _fila("EST_TONOS", String(ajustes.get("cespedTono", "vivo")))
	## Las butacas heredan los colores de la camiseta mientras no se elijan a
	## mano. Es lo que hace que un estadio recién tomado ya se vea del club y no
	## de un gris cualquiera.
	var a1 := String(ajustes.get("asiento1", ""))
	var a2 := String(ajustes.get("asiento2", ""))
	if a1 == "":
		a1 = mi.color1
	if a2 == "":
		a2 = mi.color2
	var p := {
		"personalizado": true,
		"forma": String(ajustes.get("forma", "cuenco")),
		"niveles": niveles_visibles(mi, obras),
		"techo": String(ajustes.get("techo", "anillo")),
		"cesped": String(ajustes.get("cesped", "rayas")),
		"cespedClaro": String(tono[2]) if tono.size() > 2 else "#2f8043",
		"cespedOscuro": String(tono[3]) if tono.size() > 3 else "#3b9c53",
		"lineaCol": String(ajustes.get("lineaCol", "#ffffff")),
		"arcoCol": String(ajustes.get("arcoCol", "#ffffff")),
		"redCol": String(ajustes.get("redCol", "#ffffff")),
		"asientoP": String(ajustes.get("asientoP", "franjas")),
		"asiento1": a1,
		"asiento2": a2,
		"asiento3": String(ajustes.get("asiento3", "#20272a")),
		"focos": String(ajustes.get("focos", "torres")),
		"pantalla": String(ajustes.get("pantalla", "dos")),
		"clima": String(ajustes.get("clima", "noche")),
		"vallas": bool(ajustes.get("vallas", true)),
		"banderas": String(ajustes.get("banderas", "club")),
		"aforo": aforo_efectivo(mi),
		"redTipo": String(ajustes.get("redTipo", "cuadrada")),
		"corner": String(ajustes.get("corner", "clasico")),
		"banquillo": String(ajustes.get("banquillo", "cristal")),
		"tunel": String(ajustes.get("tunel", "central")),
		"escudoDonde": String(ajustes.get("escudoDonde", "cancha")),
		## FALTABA (18-9-2026): "sonidoGol" esta en `CATALOGO_DE`/`CAPITULO`/
		## `PRECIO` desde antes de esta sesion -se puede elegir y pagar en la UI-
		## pero nunca llegaba hasta aqui, asi que el gol de CUALQUIER estadio
		## propio sonaba siempre al "bombo" por defecto de `Sonido`. El usuario
		## lo reporto como "el sonido es generico" viendo su propio estadio.
		"sonidoGol": String(ajustes.get("sonidoGol", "bombo")),
	}
	## `bandejas` es la única clave que se AÑADE condicionalmente: con el
	## interruptor apagado (el caso de siempre) `p` sale con exactamente las
	## mismas claves que antes de esta fase -ni una de más-, y con el
	## interruptor prendido se suma la vista derivada de las 4 tribunas.
	if bool(ajustes.get("personalizar_bandejas", false)):
		p["bandejas"] = _bandejas_personalizadas()
	## Igual que `bandejas`: solo se añade con su propio interruptor prendido,
	## y con él apagado `p` sale exactamente igual que antes de esta fase.
	if bool(ajustes.get("personalizar_tramos", false)):
		p["tramos"] = _tramos_personalizados()
	return p

## Vista derivada de las 4 tribunas. Solo se llama cuando `personalizar_bandejas`
## ya está activo (ver `perfil()`). Cada campo en blanco ("") de una tribuna
## hereda el valor global, la misma convención que ya usan `asiento1`/`asiento2`
## heredando el color de camiseta más arriba.
func _bandejas_personalizadas() -> Dictionary:
	var salida := {}
	for lado: String in LADOS_BANDEJA:
		var asientoP := String(ajustes.get("bandeja_%s_asientoP" % lado, ""))
		var techo := String(ajustes.get("bandeja_%s_techo" % lado, ""))
		salida[lado] = {
			"asientoP": asientoP if asientoP != "" else String(ajustes.get("asientoP", "franjas")),
			"techo": techo if techo != "" else String(ajustes.get("techo", "anillo")),
		}
	return salida

## Vista derivada de los 3 tercios de cada tribuna. Solo se llama cuando
## `personalizar_tramos` ya está activo (ver `perfil()`). Cada tercio en
## blanco ("") no hereda el global directamente -hereda el patrón YA
## resuelto de esa tribuna (su propia `bandeja_<lado>_asientoP` si la tiene,
## si no el `asientoP` general)-, así que activar tramos sobre una tribuna
## que ya tenía un estilo propio de Bandeja no la vacía de vuelta al global.
func _tramos_personalizados() -> Dictionary:
	var salida := {}
	for lado: String in LADOS_BANDEJA:
		var base := String(ajustes.get("bandeja_%s_asientoP" % lado, ""))
		if base == "":
			base = String(ajustes.get("asientoP", "franjas"))
		var patrones: Array = []
		for n in [1, 2, 3]:
			var v := String(ajustes.get("tramo_%s_%d" % [lado, n], ""))
			patrones.append(v if v != "" else base)
		salida[lado] = patrones
	return salida

## El nombre del recinto, ya limpio de leetspeak si sale del nombre del club.
func nombre_de(mi: Club) -> String:
	if nombre != "":
		return nombre
	return "Estadio " + Nombres.limpiar(mi.nombre)

func renombrar(nuevo: String) -> void:
	nombre = nuevo.strip_edges()
	renombrado.emit(nombre)

# ============================================================================
# AFORO Y BANDEJAS: LO QUE EL LADRILLO PERMITE
# ============================================================================

## El factor de aforo que aporta la FORMA del recinto, acotado por el propio
## catálogo entre 0,84 (herradura) y 1,14 (óvalo). Un óvalo olímpico cabe más
## gente que cuatro tribunas sueltas, y esa es la contrapartida de elegir un
## recinto compacto.
func factor_forma() -> float:
	var f := _fila("EST_FORMAS", String(ajustes.get("forma", "cuenco")))
	return float(f[5]) if f.size() > 5 else 1.0

## El aforo REAL con el que se llena el estadio: el del club —que ya trae el
## +15% por nivel de tribuna que escribió `Instalaciones.aplicar()`— por el
## factor de la forma. Es el `capEfectivo()` del HTML, y el aforo base sigue
## siendo de Instalaciones: aquí solo se le aplica lo que la forma añade o quita.
func aforo_efectivo(mi: Club) -> int:
	return int(round(float(mi.estadio_aforo) * factor_forma()))

## Contrapartida de lo anterior: cuanto más compacto y cerrado, más ruido. Es un
## ajuste al punto de equilibrio del ánimo de la hinchada, de -6 a +8, y es lo
## que hace que elegir una caldera de 20.000 en vez de un óvalo de 30.000 sea una
## decisión y no un error.
func ambiente() -> int:
	var f := _fila("EST_FORMAS", String(ajustes.get("forma", "cuenco")))
	var a := (1.10 - float(f[5])) * 46.0 if f.size() > 5 else 0.0
	if bool(ajustes.get("pista", false)):
		a -= 3.5
	if String(ajustes.get("techo", "sin")) != "sin":
		a += 2.0
	if int(ajustes.get("niveles", 1)) >= 3:
		a += 1.0
	var banderas := String(ajustes.get("banderas", "club"))
	if banderas == "tifo" or banderas == "bufandas":
		a += 1.5
	return clampi(int(round(a)), -6, 8)

## Cuántas bandejas puedes tener. Manda lo más restrictivo de dos cosas:
##
##  1. EL LADRILLO, que es la regla del HTML (`estNivMax`): sin tribunas
##     construidas, una bandeja; con una o dos, dos; con tres o más, tres. La
##     estética sigue al ladrillo y no al revés.
##  2. EL AFORO, con el mismo criterio que usa `StadiumBuilder.altura_de()`.
##     Aquí está la trampa que hay que evitar: el visor YA recorta las bandejas
##     por aforo cuando dibuja. Si el diseñador te dejara elegir tres en un
##     estadio de 8.000, pagarías por una bandeja, la pantalla diría tres y el
##     estadio 3D seguiría teniendo una. Se recorta antes de cobrar.
func niveles_maximos(mi: Club, obras: Instalaciones = null) -> int:
	var por_ladrillo := NIVELES_MAX
	if obras != null:
		## Una bandeja por cada escalón de la obra "Tribunas", que llega a 5.
		## Antes esto se cortaba en 3 aunque la obra siguiera subiendo: los
		## niveles 4 y 5 de tribuna daban aforo pero no daban bandeja, así que
		## el ladrillo dejaba de verse. Ahora el diseño acompaña a la obra hasta
		## el final.
		var trib := clampi(obras.nivel("trib"), 0, 5)
		por_ladrillo = clampi(trib + 1, 1, NIVELES_MAX) if trib < 5 else NIVELES_MAX
	var por_aforo := clampi(
		int(floor(float(aforo_efectivo(mi)) / BUTACAS_POR_BANDEJA)) + 1, 1, NIVELES_MAX)
	return mini(por_ladrillo, por_aforo)

## Las bandejas que se van a ver de verdad: las diseñadas, recortadas por lo que
## el club puede sostener.
func niveles_visibles(mi: Club, obras: Instalaciones = null) -> int:
	return clampi(int(ajustes.get("niveles", 1)), 1, niveles_maximos(mi, obras))

# ============================================================================
# REFORMAR: LO QUE CUESTA CAMBIAR DE IDEA
# ============================================================================

## Lo que costaría este paquete de cambios, ya escalado al tamaño del club.
##
## Se cobra POR CAPÍTULO DE OBRA y no por opción tocada: cambiar el patrón de las
## butacas y sus tres colores es una sola faena —rebutacar—, y cobrarla cuatro
## veces castigaría al que se molesta en dejarlo bonito. Las bandejas son la
## excepción: cada una nueva se paga aparte, porque cada una es una grada.
func presupuesto(mi: Club, cambios: Dictionary, obras: Instalaciones = null) -> int:
	var capitulos := {}
	var bandejas := 0
	for campo: String in cambios:
		if not ajustes.has(campo):
			continue
		if _mismo(ajustes[campo], cambios[campo]):
			continue
		if campo == "niveles":
			## Solo se cobran las bandejas que de verdad se van a levantar: las
			## que el ladrillo no permita se recortan antes, y quitar una no se
			## cobra porque no se demuele nada, se cierra al público.
			var destino := clampi(int(cambios[campo]), 1, niveles_maximos(mi, obras))
			bandejas = maxi(0, destino - int(ajustes.get("niveles", 1)))
			continue
		capitulos[String(CAPITULO.get(campo, "pintura"))] = true
	var total := 0.0
	for k: String in capitulos:
		total += float(PRECIO.get(k, 0.0))
	total += float(PRECIO["bandeja"]) * float(bandejas)
	if total <= 0.0:
		return 0
	return Eco.escalar(total, float(mi.rep))

## Aplica un paquete de cambios y lo cobra. Devuelve "" si se hizo, o el motivo
## por el que no.
##
## `cambios` son claves de `ajustes` con su valor nuevo. Se valida el paquete
## entero contra los catálogos antes de tocar nada: media reforma aplicada y
## media rechazada dejaría un estadio que no es ni el viejo ni el nuevo.
func reformar(mi: Club, cambios: Dictionary, obras: Instalaciones = null) -> String:
	if mi == null or cambios.is_empty():
		return "no hay nada que cambiar"
	for campo: String in cambios:
		if not ajustes.has(campo):
			return "«%s» no es una opción del diseñador" % campo
		if not es_valido(campo, cambios[campo]):
			return "«%s» no admite ese valor" % campo

	var coste := presupuesto(mi, cambios, obras)
	if coste > mi.saldo:
		return "no hay caja: la reforma cuesta %d y tienes %d" % [coste, mi.saldo]

	var aviso := ""
	var tope := niveles_maximos(mi, obras)
	var aplicados := {}
	for campo: String in cambios:
		var v: Variant = cambios[campo]
		if campo == "niveles":
			var pedidas := int(v)
			v = clampi(pedidas, 1, tope)
			if pedidas > tope:
				## No se refusa la reforma entera por esto, pero tampoco se
				## clava una bandeja fantasma: se hace lo que se puede y se dice.
				aviso = "Se quedó en %d bandeja(s): para más hay que subir la tribuna en Obras." % tope
		ajustes[campo] = v
		aplicados[campo] = v

	if coste > 0:
		mi.mover_saldo(-coste)
		movimiento.emit("Reforma del estadio", -coste)
	reforma_hecha.emit(aplicados, coste, aviso)
	return ""

## ¿Este valor cabe en este campo? Un desplegable de la interfaz nunca mandará
## basura, pero un guardado viejo o un preset de una versión anterior sí.
func es_valido(campo: String, valor: Variant) -> bool:
	if campo == "niveles":
		return valor is int or valor is float
	if CATALOGO_DE.has(campo):
		for fila: Array in _tabla(String(CATALOGO_DE[campo])):
			if fila.size() > 0 and String(fila[0]) == String(valor):
				return true
		return false
	## Los campos sin catálogo son interruptores o texto libre (los colores de
	## butaca, que salen de la camiseta, y el texto del mosaico).
	if ajustes.get(campo) is bool:
		return valor is bool
	return true

## Las opciones de un campo, listas para pintar un desplegable: clave, nombre y
## la descripción cuando el catálogo la trae.
func opciones(campo: String) -> Array:
	var salida: Array = []
	if not CATALOGO_DE.has(campo):
		return salida
	for fila: Array in _tabla(String(CATALOGO_DE[campo])):
		if fila.is_empty():
			continue
		salida.append({
			"clave": String(fila[0]),
			"nombre": String(fila[1]) if fila.size() > 1 else String(fila[0]),
			"desc": String(fila[2]) if fila.size() > 2 and fila[2] is String else "",
		})
	return salida

# ============================================================================
# ESTILOS COMPLETOS
# ============================================================================

## Los ocho estilos listos para usar del juego: la caldera, la catedral inglesa,
## la arena moderna, el coloso olímpico, el potrero de barrio... Cada uno es un
## paquete de cambios, así que se paga como cualquier reforma.
func presets() -> Array:
	var salida: Array = []
	for p: Array in _tabla("EST_PRESETS"):
		if p.size() < 4:
			continue
		salida.append({
			"clave": String(p[0]), "nombre": String(p[1]), "desc": String(p[2]),
			"cambios": (p[3] as Dictionary).duplicate(),
		})
	return salida

func preset(clave: String) -> Dictionary:
	for p: Dictionary in presets():
		if String(p["clave"]) == clave:
			return p
	return {}

func coste_preset(mi: Club, clave: String, obras: Instalaciones = null) -> int:
	var p := preset(clave)
	if p.is_empty():
		return 0
	return presupuesto(mi, p["cambios"] as Dictionary, obras)

## Aplica un estilo entero. Devuelve "" si se hizo, o el motivo por el que no.
func aplicar_preset(mi: Club, clave: String, obras: Instalaciones = null) -> String:
	var p := preset(clave)
	if p.is_empty():
		return "ese estilo no existe"
	return reformar(mi, p["cambios"] as Dictionary, obras)

## Un diseño al azar, para el botón de "sorpréndeme". PROPONE, no aplica: en el
## HTML esto se aplicaba solo y era gratis, pero aquí una reforma cuesta dinero y
## nadie debe pagar una obra que no ha visto. La interfaz enseña la propuesta,
## el jugador mira el presupuesto y decide.
##
## Usa `Azar` y no el generador de Godot: con semilla, el mismo botón en la misma
## partida propone lo mismo, que es lo que hace repetible el banco de pruebas.
func aleatorio(mi: Club, obras: Instalaciones = null) -> Dictionary:
	var d := {}
	for campo: String in CATALOGO_DE:
		if not ajustes.has(campo):
			continue
		var filas := _tabla(String(CATALOGO_DE[campo]))
		if filas.is_empty():
			continue
		var fila: Variant = Azar.uno(filas)
		if fila is Array and not (fila as Array).is_empty():
			d[campo] = String((fila as Array)[0])
	d["niveles"] = clampi(Azar.ent(1, NIVELES_MAX), 1, niveles_maximos(mi, obras))
	d["pista"] = Azar.suerte(0.2)
	return d

# ============================================================================
# GUARDADO
# ============================================================================

func a_dic() -> Dictionary:
	return {"nombre": nombre, "ajustes": ajustes}

func desde_dic(d: Dictionary) -> void:
	nombre = String(d.get("nombre", ""))
	var guardado: Dictionary = d.get("ajustes", {})
	## Se rellenan las claves que falten con las de fábrica, exactamente como
	## hace `initEst()` en el HTML. Un guardado de una versión anterior no tiene
	## las opciones nuevas, y sin este paso el visor recibiría un diccionario con
	## agujeros y dibujaría medio estadio con los valores por defecto sin avisar.
	_sembrar()
	for k: String in guardado:
		if ajustes.has(k):
			ajustes[k] = guardado[k]

# ============================================================================
# UTILIDADES
# ============================================================================

func _tabla(nombre_tabla: String) -> Array:
	var t: Variant = Datos.tabla(nombre_tabla)
	return t if t is Array else []

## Una fila del catálogo por su clave, con la primera como red de seguridad: es
## el `EST_TONOS.find(...)||EST_TONOS[0]` del HTML, y existe porque un tono que
## ya no está en la tabla no puede dejar el césped sin color.
func _fila(nombre_tabla: String, clave: String) -> Array:
	var filas := _tabla(nombre_tabla)
	for f: Array in filas:
		if f.size() > 0 and String(f[0]) == clave:
			return f
	if filas.is_empty():
		return []
	return filas[0] as Array

## Compara respetando el tipo. Sin esto, un `false` guardado y un `"false"` del
## desplegable parecerían cambios distintos y se cobraría una reforma que no
## cambia nada.
func _mismo(a: Variant, b: Variant) -> bool:
	if a is bool or b is bool:
		return bool(a) == bool(b)
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	return String(a) == String(b)
