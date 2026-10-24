extends "res://nucleo/estadio_propio_p1.gd"
## [Capa 2/3 de `estadio_propio.gd`] factor_forma, aforo_efectivo, niveles_maximos, niveles_visibles, _bandejas_personalizadas, _tramos_personalizados … (+16)

# ============================================================================
# AFORO Y BANDEJAS: LO QUE EL LADRILLO PERMITE
# ============================================================================

## El factor de aforo que aporta la FORMA del recinto, acotado por el propio
## catálogo entre 0,84 (herradura) y 1,14 (óvalo). Un óvalo olímpico cabe más
## gente que cuatro tribunas sueltas, y esa es la contrapartida de elegir un
## recinto compacto.
func factor_forma() -> float:
	var f := _fila("EST_FORMAS", String(hecho().get("forma", "cuenco")))
	return float(f[5]) if f.size() > 5 else 1.0

## El aforo REAL con el que se llena el estadio: el del club —que ya trae el
## +15% por nivel de tribuna que escribió `Instalaciones.aplicar()`— por el
## factor de la forma. Es el `capEfectivo()` del HTML, y el aforo base sigue
## siendo de Instalaciones: aquí solo se le aplica lo que la forma añade o quita.
func aforo_efectivo(mi: Club) -> int:
	return int(round(float(mi.estadio_aforo) * factor_forma()))

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
	return clampi(int(hecho().get("niveles", 1)), 1, niveles_maximos(mi, obras))

## Vista derivada de las 4 tribunas. Solo se llama cuando `personalizar_bandejas`
## ya está activo (ver `perfil()`). Cada campo en blanco ("") de una tribuna
## hereda el valor global, la misma convención que ya usan `asiento1`/`asiento2`
## heredando el color de camiseta más arriba.
func _bandejas_personalizadas() -> Dictionary:
	var salida := {}
	for lado: String in LADOS_BANDEJA:
		var asientoP := String(hecho().get("bandeja_%s_asientoP" % lado, ""))
		var techo := String(hecho().get("bandeja_%s_techo" % lado, ""))
		salida[lado] = {
			"asientoP": asientoP if asientoP != "" else String(hecho().get("asientoP", "franjas")),
			"techo": techo if techo != "" else String(hecho().get("techo", "anillo")),
			## B6: los colores de las butacas de ESTA tribuna ("" = los globales).
			"col1": String(hecho().get("bandeja_%s_col1" % lado, "")),
			"col2": String(hecho().get("bandeja_%s_col2" % lado, "")),
			## El color de cada anillo de esta tribuna, de abajo arriba ("" =
			## el de la tribuna).
			"niveles": [1, 2, 3, 4, 5].map(func(n: int) -> String: return String(hecho().get("anillo_%s_%d" % [lado, n], ""))),
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
		var base := String(hecho().get("bandeja_%s_asientoP" % lado, ""))
		if base == "":
			base = String(hecho().get("asientoP", "franjas"))
		var patrones: Array = []
		for n in [1, 2, 3]:
			var v := String(hecho().get("tramo_%s_%d" % [lado, n], ""))
			patrones.append(v if v != "" else base)
		salida[lado] = patrones
	return salida

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
	var tono := _fila("EST_TONOS", String(hecho().get("cespedTono", "vivo")))
	## Las butacas heredan los colores de la camiseta mientras no se elijan a
	## mano. Es lo que hace que un estadio recién tomado ya se vea del club y no
	## de un gris cualquiera.
	var a1 := String(hecho().get("asiento1", ""))
	var a2 := String(hecho().get("asiento2", ""))
	if a1 == "":
		a1 = mi.color1
	if a2 == "":
		a2 = mi.color2
	var p := {
		"personalizado": true,
		"forma": String(hecho().get("forma", "cuenco")),
		"niveles": niveles_visibles(mi, obras),
		"techo": String(hecho().get("techo", "anillo")),
		"cesped": String(hecho().get("cesped", "rayas")),
		"cespedClaro": String(tono[2]) if tono.size() > 2 else "#2f8043",
		"cespedOscuro": String(tono[3]) if tono.size() > 3 else "#3b9c53",
		"lineaCol": String(hecho().get("lineaCol", "#ffffff")),
		"arcoCol": String(hecho().get("arcoCol", "#ffffff")),
		"redCol": String(hecho().get("redCol", "#ffffff")),
		"asientoP": String(hecho().get("asientoP", "franjas")),
		"asiento1": a1,
		"asiento2": a2,
		"asiento3": String(hecho().get("asiento3", "#20272a")),
		"focos": String(hecho().get("focos", "torres")),
		"pantalla": String(hecho().get("pantalla", "dos")),
		"clima": String(hecho().get("clima", "noche")),
		"vallas": bool(hecho().get("vallas", true)),
		"banderas": String(hecho().get("banderas", "club")),
		"aforo": aforo_efectivo(mi),
		"redTipo": String(hecho().get("redTipo", "cuadrada")),
		"corner": String(hecho().get("corner", "clasico")),
		"banquillo": String(hecho().get("banquillo", "cristal")),
		"tunel": String(hecho().get("tunel", "central")),
		"escudoDonde": String(hecho().get("escudoDonde", "cancha")),
		## FALTABA (18-9-2026): "sonidoGol" esta en `CATALOGO_DE`/`CAPITULO`/
		## `PRECIO` desde antes de esta sesion -se puede elegir y pagar en la UI-
		## pero nunca llegaba hasta aqui, asi que el gol de CUALQUIER estadio
		## propio sonaba siempre al "bombo" por defecto de `Sonido`. El usuario
		## lo reporto como "el sonido es generico" viendo su propio estadio.
		"sonidoGol": String(hecho().get("sonidoGol", "bombo")),
		## B6: las secciones. Los colores vacíos se resuelven aquí, no en el
		## visor: el visor no sabe de camisetas.
		"fachada": String(hecho().get("fachada", "hormigon")),
		"fachadaCol": String(hecho().get("fachadaCol", "")),
		"techoCol": String(hecho().get("techoCol", "")),
		"luzFocos": String(hecho().get("luzFocos", "neutra")),
		"luzClub": mi.color1,
		"banquilloCol": String(hecho().get("banquilloCol", "")),
		"superficie": String(hecho().get("superficie", "natural")),
		"exterior": true,
	}
	## `bandejas` es la única clave que se AÑADE condicionalmente: con el
	## interruptor apagado (el caso de siempre) `p` sale con exactamente las
	## mismas claves que antes de esta fase -ni una de más-, y con el
	## interruptor prendido se suma la vista derivada de las 4 tribunas.
	if bool(hecho().get("personalizar_bandejas", false)):
		p["bandejas"] = _bandejas_personalizadas()
	## Igual que `bandejas`: solo se añade con su propio interruptor prendido,
	## y con él apagado `p` sale exactamente igual que antes de esta fase.
	if bool(hecho().get("personalizar_tramos", false)):
		p["tramos"] = _tramos_personalizados()
	## Vallas y estructura de los focos: solo si se eligió un color (así un
	## estadio sin tocar sigue con exactamente las mismas claves).
	for k: String in ["vallaCol", "focosCol"]:
		if String(hecho().get(k, "")) != "":
			p[k] = String(hecho()[k])
	if String(hecho().get("ledPaleta", "marcas")) != "marcas":
		p["ledPaleta"] = String(hecho()["ledPaleta"])
	## Colores propios de las LED: mandan sobre la paleta elegida.
	for k: String in ["ledFondo", "ledTinta"]:
		if String(hecho().get(k, "")) != "":
			p[k] = String(hecho()[k])
	return p

## El nombre del recinto, ya limpio de leetspeak si sale del nombre del club.
func nombre_de(mi: Club) -> String:
	if nombre != "":
		return nombre
	return "Estadio " + Nombres.visible(mi.nombre)

func renombrar(nuevo: String) -> void:
	nombre = nuevo.strip_edges()
	renombrado.emit(nombre)

## Contrapartida de lo anterior: cuanto más compacto y cerrado, más ruido. Es un
## ajuste al punto de equilibrio del ánimo de la hinchada, de -6 a +8, y es lo
## que hace que elegir una caldera de 20.000 en vez de un óvalo de 30.000 sea una
## decisión y no un error.
func ambiente() -> int:
	var f := _fila("EST_FORMAS", String(hecho().get("forma", "cuenco")))
	var a := (1.10 - float(f[5])) * 46.0 if f.size() > 5 else 0.0
	if bool(hecho().get("pista", false)):
		a -= 3.5
	## Sin fondos el ruido se escapa por los dos lados: su factor de aforo es
	## bajo por tener menos grada, no por ser compacto, así que no suma ruido.
	if String(hecho().get("forma", "")) == "dos":
		a = -6.0
	if String(hecho().get("techo", "sin")) != "sin":
		a += 2.0
	if int(hecho().get("niveles", 1)) >= 3:
		a += 1.0
	var banderas := String(hecho().get("banderas", "club"))
	if banderas == "tifo" or banderas == "bufandas":
		a += 1.5
	return clampi(int(round(a)), -6, 8)

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

# ============================================================================
# UTILIDADES
# ============================================================================

func _catalogo(campo: String) -> String:
	if CATALOGO_DE.has(campo):
		return String(CATALOGO_DE[campo])
	return String(CATALOGO_B6.get(campo, ""))

## ¿Este valor cabe en este campo? Un desplegable de la interfaz nunca mandará
## basura, pero un guardado viejo o un preset de una versión anterior sí.
func es_valido(campo: String, valor: Variant) -> bool:
	if campo == "niveles":
		return valor is int or valor is float
	var cat := _catalogo(campo)
	if cat != "":
		for fila: Array in _tabla(cat):
			if fila.size() > 0 and String(fila[0]) == String(valor):
				return true
		return false
	## Los campos sin catálogo son interruptores o texto libre (los colores de
	## butaca, que salen de la camiseta, y el texto del mosaico).
	if ajustes.get(campo) is bool:
		return valor is bool
	return true

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
	## La obra: lo construido se congela hasta que termine. La pintura pasa
	## también a lo construido (no espera a nadie).
	var sem := semanas_de(cambios)
	if sem > 0:
		if not en_obras():
			obra = {"antes": ajustes.duplicate(true), "semanas": sem, "total": sem, "capitulos": []}
		else:
			obra["semanas"] = maxi(int(obra["semanas"]), sem)
			obra["total"] = maxi(int(obra["total"]), int(obra["semanas"]))
	for campo: String in cambios:
		var v: Variant = cambios[campo]
		var cap := "bandeja" if campo == "niveles" else String(CAPITULO.get(campo, "pintura"))
		if en_obras():
			if int(SEMANAS_OBRA.get(cap, 0)) == 0:
				(obra["antes"] as Dictionary)[campo] = v
			elif not (cap in (obra["capitulos"] as Array)):
				(obra["capitulos"] as Array).append(cap)
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
	if sem > 0:
		var txt := "Reforma en obras: %d semana(s). Hasta entonces se juega en el estadio de siempre." % int(obra["semanas"])
		aviso = txt if aviso == "" else aviso + " " + txt
	reforma_hecha.emit(aplicados, coste, aviso)
	return ""

## Las opciones de un campo, listas para pintar un desplegable: clave, nombre y
## la descripción cuando el catálogo la trae.
func opciones(campo: String) -> Array:
	var salida: Array = []
	var cat := _catalogo(campo)
	if cat == "":
		return salida
	for fila: Array in _tabla(cat):
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
	for p: Array in _tabla("EST_PRESETS") + PRESETS_B6:
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
	return {"nombre": nombre, "ajustes": ajustes, "real_de": real_de, "obra": obra.duplicate(true)}

func asegurar_real(c: Club) -> void:
	if c == null or real_de == c.id:
		return
	real_de = c.id
	var reales: Variant = Datos.tabla("ESTADIO_CLUB")
	if not (reales is Dictionary) or not (reales as Dictionary).has(c.nombre):
		return
	var r: Dictionary = (reales as Dictionary)[c.nombre]
	for k in ["forma", "niveles", "techo", "pista", "focos", "fachada"]:
		if r.has(k):
			ajustes[k] = r[k]
