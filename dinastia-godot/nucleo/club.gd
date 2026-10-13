class_name Club
extends RefCounted
## Un club: su gente, su dinero y su pizarra.
##
## En el HTML la plantilla de un club se sacaba con `plantelDe(clubId)`, que
## recorria los ~11.000 jugadores del mundo filtrando por club. Se llamaba tanto
## que era el 93% del tiempo de ejecucion del juego entero, y hubo que ponerle un
## indice por encima con invalidacion manual en 56 sitios. Aqui el problema no
## existe: cada club TIENE su plantilla. No hay indice que mantener ni que
## invalidar, porque no hay busqueda.

signal fichaje(j: Jugador)
signal baja(j: Jugador)
signal saldo_cambio(antes: int, ahora: int)

var id: String = ""
var nombre: String = ""
var pais: String = "CHI"
var rep: int = 70
var saldo: int = 0
var estadio_aforo: int = 20000
## El nombre del estadio. Vacío significa "Estadio <nombre del club>", que es lo
## que se enseñaba antes: se guarda solo si lo cambias, para que renombrar sea
## una decisión tuya y no un campo más que rellenar al empezar.
var estadio_nombre: String = ""
var division: int = 1
## Palancas del club que mueven la taquilla y que el jugador puede tocar.
## Arrancan en el punto neutro de las formulas del HTML: precio 6 y confianza 50
## dejan la ocupacion en manos de la reputacion y los socios, que es lo que
## corresponde a un club recien tomado.
var precio_entrada: float = 6.0
var confianza: int = 50
var socios: int = 0
## Los dos colores de la camiseta, tal como vienen en la tabla de clubes
## (fila[1] y fila[2]). Hacen falta para teñir las equipaciones en 3D; sin
## ellos los 22 jugadores salen todos del mismo color.
var color1: String = "#2b6b45"
var color2: String = "#ffffff"
var plantilla: Array[Jugador] = []
var tactica: Tactica = Tactica.new()

## Bonificadores que en el HTML salian del staff, del arbol de habilidades del DT
## y de los roles del vestuario. Esos sistemas todavia no estan portados, asi que
## viven aqui como dos numeros neutros: el simulador ya los aplica, y cuando se
## porte cada sistema solo tiene que escribir en ellos. Asi no hay que volver a
## tocar el motor de partido.
var bonus_ataque: float = 1.0
var bonus_defensa: float = 1.0

func _init(_id: String = "", _nombre: String = "") -> void:
	id = _id
	nombre = _nombre

func plantel() -> Array[Jugador]:
	return plantilla

func disponibles() -> Array[Jugador]:
	return plantilla.filter(func(j: Jugador) -> bool: return j.disponible())

## Fichajes que ocupan cupo por temporada (año -> cuántos), para las ligas
## que limitan los fichajes extracomunitarios por temporada (Italia).
var fichajes_cupo: Dictionary = {}
## «cumplir»: el once se corrige solo a las reglas de la liga y el mercado no
## deja pasarse del cupo. «incumplir»: tú decides y la federación multa.
var ley_politica := "cumplir"
var cupo_cache: Dictionary = {}

func fichar(j: Jugador) -> void:
	if j.club_id == id:
		return
	if int(LeyesPais.reglas(pais).get("no_ue_temp", 0)) > 0 and LeyesPais.ocupa_cupo(j, pais):
		var k := str(LeyesPais.anio_actual)
		fichajes_cupo[k] = int(fichajes_cupo.get(k, 0)) + 1
	j.club_id = id
	if not plantilla.has(j):
		plantilla.append(j)
	fichaje.emit(j)

func soltar(j: Jugador) -> void:
	var i := plantilla.find(j)
	if i < 0:
		return
	plantilla.remove_at(i)
	baja.emit(j)

func mover_saldo(delta: int) -> void:
	var antes := saldo
	saldo += delta
	saldo_cambio.emit(antes, saldo)

func masa_salarial() -> int:
	var s := 0
	for j in plantilla:
		s += j.sueldo
	return s

func media() -> float:
	if plantilla.is_empty():
		return 0.0
	var s := 0
	for j in plantilla:
		s += j.ovr
	return float(s) / float(plantilla.size())

## El once que ha elegido el entrenador a mano, por id de jugador. Si está
## vacío, o si alguno de los elegidos ya no puede jugar, se arma solo.
##
## Guardar ids y no jugadores es a propósito: un once guardado tiene que
## sobrevivir a que vendas a uno de los once, y con referencias directas el
## jugador vendido seguiría saliendo a la cancha con la camiseta de tu club.
var once_elegido: Array[String] = []

func fijar_once(jugadores: Array[Jugador]) -> void:
	once_elegido.clear()
	for j in jugadores:
		once_elegido.append(j.id)

func limpiar_once() -> void:
	once_elegido.clear()

## El once manual, si sigue siendo válido. Devuelve vacío si falta alguien,
## si hay lesionados o si no está en la plantilla: en cuanto algo no cuadra se
## prefiere que lo arme el automático a sacar a diez.
func _once_manual() -> Array[Jugador]:
	if once_elegido.size() != 11:
		return []
	var salida: Array[Jugador] = []
	for id in once_elegido:
		var encontrado: Jugador = null
		for j in plantilla:
			if j.id == id:
				encontrado = j
				break
		if encontrado == null or not encontrado.disponible():
			return []
		salida.append(encontrado)
	return salida

## Arma el once llenando ranura por ranura con el mejor para ese puesto.
##
## Portado con su red de seguridad incluida: si la enfermeria se llevo a media
## plantilla se relaja el filtro en dos pasos (primero los no sancionados,
## despues cualquiera). En el HTML esto no estaba al principio y un club sin once
## dejaba el partido a medias y reventaba la simulacion de la jornada entera.
func once(f: String = "") -> Array[Jugador]:
	## Manda lo que haya elegido el entrenador. Solo si no hay once manual, o si
	## dejo de ser valido, se arma el automatico.
	var manual := _once_manual()
	if not manual.is_empty():
		## Si el club decidió incumplir, sale el once que eligió (y paga).
		return manual if ley_politica == "incumplir" else LeyesPais.ajustar_once(self, manual)
	var forma := f if f != "" else tactica.formacion
	var forms: Dictionary = Datos.tabla("FORMS")
	var def: Dictionary = forms.get(forma, forms.get("4-3-3", {}))
	var ranuras: Array = def.get("s", [])

	var libres := disponibles()
	if libres.size() < 7:
		libres = plantilla.filter(func(j: Jugador) -> bool: return j.suspension <= 0)
	if libres.is_empty():
		libres = plantilla.duplicate()

	var elegidos: Array[Jugador] = []
	var usados := {}
	## Los porteros primero: si se reparten al final, el mejor arquero ya se fue
	## de central y la ranura de porteria se llena con quien sobre.
	var orden: Array = []
	for i in ranuras.size():
		orden.append(i)
	orden.sort_custom(func(a: int, b: int) -> bool:
		return _es_puesto_portero(ranuras[a]) and not _es_puesto_portero(ranuras[b]))

	var asignado := {}
	for i: int in orden:
		var puesto: String = ranuras[i][0]
		var mejor: Jugador = null
		var mejor_v := -1.0
		for j in libres:
			if usados.has(j.id):
				continue
			if _es_puesto_portero_str(puesto) != j.es_portero():
				continue
			## LA FAMILIARIDAD CON EL PUESTO. Antes solo se miraban los atributos, y
			## por eso el once automático ponía a un extremo veloz de lateral por
			## delante de un lateral de verdad: el extremo tiene el ritmo que pide la
			## posición. Pero saber jugar ahí es otra cosa, y el pizarrón nuevo lo
			## dejó a la vista -salía media plantilla en rojo-.
			##
			## No es un veto: un extremo MUY superior sigue ganando el puesto. Solo
			## deja de ser gratis sacarlo de su sitio.
			var encaja := 1.0
			if j.pos_e != puesto:
				encaja = 0.94 if j.pos_sec.has(puesto) else 0.86
			var v := float(j.media_en(puesto)) * encaja * (0.7 + 0.003 * j.forma) * (0.9 + 0.002 * j.moral)
			if v > mejor_v:
				mejor_v = v
				mejor = j
		if mejor != null:
			usados[mejor.id] = true
			asignado[i] = mejor
	## Segunda vuelta sin el filtro de porteria, para las ranuras que quedaron
	## vacias porque no habia nadie de ese perfil.
	for i in ranuras.size():
		if asignado.has(i):
			continue
		for j in libres:
			if usados.has(j.id):
				continue
			usados[j.id] = true
			asignado[i] = j
			break
	for i in ranuras.size():
		if asignado.has(i):
			elegidos.append(asignado[i])
	## Las reglas de la liga de este club (cupo en cancha, juveniles).
	return LeyesPais.ajustar_once(self, elegidos)

func _es_puesto_portero(ranura: Variant) -> bool:
	return _es_puesto_portero_str(String(ranura[0]))

func _es_puesto_portero_str(puesto: String) -> bool:
	var posd: Dictionary = Datos.tabla("POSD")
	if posd == null or not posd.has(puesto):
		return false
	return String(posd[puesto].get("g", "")) == "POR"

## --- EL ESTADIO ------------------------------------------------------------
## El recinto de cada club, para el visor 3D.
##
## En el HTML esto lo calculaba `perfilEstadio()` y llegaba a Godot dentro de un
## JSON que había que exportar a mano cada vez. Aquí lo produce el propio club,
## que es quien tiene el dato: ya no hay puente ni fichero intermedio.
##
## La elección es ESTABLE, no aleatoria: sale del hash del id del club. Así el
## estadio del rival es siempre el mismo estadio, partido tras partido y partida
## tras partida. Si se sorteara, cada visita a Coquimbo sería a un recinto
## distinto y el mundo dejaría de parecer un mundo.
##
## Y el tamaño manda sobre el gusto: un club de 8.000 butacas no puede tener tres
## bandejas por mucha reputación que tenga.
const _FORMAS := ["cuenco", "ingles", "oval", "herradura", "rect"]
const _CESPED := ["rayas", "damero", "circulos", "liso"]
const _ASIENTOS := ["franjas", "liso", "moteado", "degradado"]

func perfil_estadio() -> Dictionary:
	var h := _hash_id()
	var p := {
		"personalizado": false,
		"forma": _FORMAS[h % _FORMAS.size()],
		"niveles": 3 if rep >= 80 else (2 if rep >= 62 else 1),
		"techo": "anillo" if rep >= 78 else ("parcial" if rep >= 60 else "sin"),
		"cesped": _CESPED[(h >> 3) % _CESPED.size()],
		"asientoP": _ASIENTOS[(h >> 5) % _ASIENTOS.size()],
		"focos": "mixto" if rep >= 70 else "torres",
		"pantalla": "dos" if rep >= 82 else ("una" if rep >= 58 else "sin"),
		"vallas": rep < 78,
		"aforo": estadio_aforo,
		## Las butacas, de los colores del club (29-9-2026): sin esto todos los
		## rivales salían con el verde por defecto del visor.
		"asiento1": color1,
		"asiento2": color2,
	}
	## MÁS VARIANTES DE ESTADIO PARA LOS RIVALES (25-9-2026). Hasta hoy todos
	## los rivales compartían techo, focos, banderas, tono de césped, banquillo
	## y red: solo cambiaban la forma y los asientos. Ahora cada club toma uno
	## de los estilos completos (`EST_PRESETS`: la caldera, la catedral, la
	## nave futurista, el estadio de montaña...), siempre el mismo para el mismo
	## club, y su REPUTACIÓN lo recorta: un club chico no tiene techo total ni
	## anillo de pantallas. El clima no se toca -lo pone la hora del partido- y
	## el túnel tampoco.
	var presets: Variant = Datos.tabla("EST_PRESETS")
	if presets is Array and not (presets as Array).is_empty():
		## Hash aparte y bien mezclado: con `h >> 7` los ids seguidos (c1, c2...)
		## caían casi todos en el mismo estilo (se vio: dos formas en todo el mundo).
		var he := absi(("estilo_estadio:" + id).hash())
		var fila: Array = (presets as Array)[he % (presets as Array).size()]
		var e: Dictionary = fila[3] if fila.size() > 3 and fila[3] is Dictionary else {}
		for k in ["forma", "asientoP", "cespedTono", "banderas", "corner", "redTipo", "banquillo"]:
			if e.has(k):
				p[k] = e[k]
		if rep >= 70:
			for k in ["techo", "focos", "pantalla", "cesped"]:
				if e.has(k):
					p[k] = e[k]
			p["niveles"] = mini(int(p["niveles"]) + 1, maxi(1, int(e.get("niveles", p["niveles"]))))
		elif rep >= 60 and String(e.get("techo", "sin")) in ["sin", "parcial", "visera"]:
			p["techo"] = e["techo"]
	## SU ESTADIO DE VERDAD (26-9-2026, `herramientas/estadios_reales.py`): si
	## el club representa a uno real, su estadio copia la arquitectura del real
	## -forma, bandejas, techo, pista, focos y fachada-, gane o no reputación.
	## La caldera de tres bandejas, el óvalo con pista, la herradura al cerro,
	## el techo retráctil... Los demás siguen con los estilos genéricos.
	var reales: Variant = Datos.tabla("ESTADIO_CLUB")
	if reales is Dictionary and (reales as Dictionary).has(nombre):
		var r: Dictionary = (reales as Dictionary)[nombre]
		for k in ["forma", "niveles", "techo", "pista", "focos", "fachada", "rasgo"]:
			if r.has(k):
				p[k] = r[k]
		p["real"] = true
		## El apodo del estadio (genérico, nunca el oficial): sale en el rótulo.
		var ap := GuinosEstadio.apodo(p)
		if ap != "":
			p["apodo"] = ap
	return p

## djb2, el mismo que usa el HTML para que un club dé siempre el mismo recinto.
func _hash_id() -> int:
	var h := 5381
	for i in id.length():
		h = ((h << 5) + h + id.unicode_at(i)) & 0x7FFFFFFF
	return h

func _to_string() -> String:
	return "%s (%s, rep %d, %d jugadores)" % [nombre, pais, rep, plantilla.size()]

## LA IDENTIDAD VISUAL SEPARADA (`vIdentidad()` del HTML).
##
## `color1` y `color2` son el color INSTITUCIONAL del club. Todo lo demás lo
## hereda de ahí mientras esté vacío, y ese es el punto de la pantalla: el
## uniforme no arrastra el color del escudo ni el del menú, pero por defecto se
## parecen todos porque salen del mismo sitio.
##
## Vacío = heredado. Es la diferencia entre "no lo he tocado" y "lo he puesto
## igual a propósito", y hace que el botón de "volver a los colores del club"
## signifique algo.
var kit_color1: String = ""
var kit_color2: String = ""
var kit_estilo: String = ""
## LA EQUIPACIÓN COMPLETA DEL DISEÑADOR (26-9-2026): diseño, 5 colores,
## ribete, números, pantalón, medias, botines y accesorios. Vacío = la de
## siempre (`DisenosKit.kit_de_club()` la arma con los colores del club).
var kit_x: Dictionary = {}
var esc_color1: String = ""
var esc_color2: String = ""
var esc_forma: String = ""
var esc_patron: String = ""
var esc_simbolo: String = ""
## Escudo ESPECIAL (22-9-2026): id de una de las insignias de
## `Escudo.ESPECIALES`, coleccionables por nivel de perfil de gestor. Vacio
## (el default) = el generador procedural de siempre. Si trae un id pero
## `Escudo.especial_desbloqueado()` da falso -por ejemplo, se bajo de nivel en
## un perfil nuevo tras reinstalar-, `Escudo.textura()` cae solo al
## procedural: nunca revienta por pedir algo que ya no esta desbloqueado.
var esc_especial: String = ""
var ui_acento: String = ""

func color_kit1() -> String:
	return kit_color1 if kit_color1 != "" else color1

func color_kit2() -> String:
	return kit_color2 if kit_color2 != "" else color2

func color_escudo1() -> String:
	return esc_color1 if esc_color1 != "" else color1

func color_escudo2() -> String:
	return esc_color2 if esc_color2 != "" else color2

func color_acento() -> String:
	return ui_acento if ui_acento != "" else color1

## Todo igualado al color del club: borra las separaciones de golpe.
func igualar_identidad() -> void:
	kit_color1 = ""
	kit_color2 = ""
	esc_color1 = ""
	esc_color2 = ""
	ui_acento = ""

func identidad_a_dic() -> Dictionary:
	return {
		"kit_c1": kit_color1, "kit_c2": kit_color2, "kit_est": kit_estilo, "kit_x": kit_x,
		"esc_c1": esc_color1, "esc_c2": esc_color2,
		"esc_f": esc_forma, "esc_p": esc_patron, "esc_s": esc_simbolo,
		"esc_e": esc_especial,
		"ui": ui_acento,
	}

func identidad_desde_dic(d: Dictionary) -> void:
	kit_color1 = String(d.get("kit_c1", ""))
	kit_color2 = String(d.get("kit_c2", ""))
	kit_estilo = String(d.get("kit_est", ""))
	kit_x = (d.get("kit_x", {}) as Dictionary).duplicate(true)
	esc_color1 = String(d.get("esc_c1", ""))
	esc_color2 = String(d.get("esc_c2", ""))
	esc_forma = String(d.get("esc_f", ""))
	esc_patron = String(d.get("esc_p", ""))
	esc_simbolo = String(d.get("esc_s", ""))
	esc_especial = String(d.get("esc_e", ""))
	ui_acento = String(d.get("ui", ""))
