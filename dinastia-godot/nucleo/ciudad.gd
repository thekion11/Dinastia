class_name Ciudad
extends RefCounted
## EL CLUB Y SU CIUDAD: terrenos, negocios, vecinos, permisos y seguridad.
##
## `vCiudad()` del HTML. Es la parte del juego que ocurre fuera del campo y de la
## caja: el club no está en el vacío, está en un barrio que tiene opinión.
##
## POR QUÉ IMPORTA. Todo lo demás del juego escala con ganar partidos. Esto no:
## los negocios anexos ingresan TODAS las semanas del año, jueguen o no, y son la
## diferencia entre un club que sobrevive y uno que crece. Y tienen un freno que
## no es dinero —el permiso municipal, la relación con los vecinos— que hace que
## no baste con tener caja para construir.
##
## LAS CUATRO PALANCAS QUE SE CRUZAN:
##   · TERRENOS: sin el paño no hay negocio. El del centro es carísimo y es el
##     único donde cabe el centro comercial, que es la joya.
##   · VECINOS: deciden si te dan el permiso para ampliar el estadio. Se compran
##     con obra social y se pierden con conciertos.
##   · CÉSPED: los conciertos llenan la caja de golpe y destrozan el campo. Por
##     debajo de 60, los jugadores pierden precisión.
##   · SEGURIDAD: baja el riesgo de incidente, y un incidente cuesta puertas
##     cerradas o aforo reducido, que es taquilla que no vuelve.

## UNA SOLA CONVENCION EN TODA LA CLASE: las funciones que HACEN algo devuelven
## "" si se hizo, y el motivo por el que no si no se pudo. Lo que pasó se cuenta
## por `noticia`, nunca por el valor de vuelta. Mezclar las dos cosas -unas
## devolviendo "" y otras el texto del resultado- ya costó dos fallos del banco.
signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)

const PRECIO_TERRENO_BASE := 700000.0
const RENTA_NEGOCIO_BASE := 90000.0
const COSTE_PERMISO := 120000.0
const COSTE_OBRA_SOCIAL := 55000.0
const COSTE_RESIEMBRA_POR_PUNTO := 4000.0
const COSTE_PANELES := 380000.0
const COSTE_CERTIFICACION := 260000.0
const AHORRO_PANEL := 9000.0
const RENTA_CERTIFICADO := 40000.0
const PANELES_MAX := 3
const SEGURIDAD_MAX := 3
const CESPED_MINIMO_CONCIERTO := 60

var terrenos: Array = []
var negocios: Dictionary = {}
var vecinos: int = 55
var cesped: int = 100
var conciertos: int = 0
var paneles: int = 0
var certificado: bool = false
var seg_privada: int = 0
var seg_camaras: int = 0
var permiso: Dictionary = {}      ## {semanas, prob}
var permiso_ok: bool = false
var sancion: Dictionary = {}      ## {tipo, semanas}

## EL COLOR DEL ALUMBRADO PÚBLICO. De noche las farolas son lo único que dibuja
## el trazado de la ciudad, así que su color es una decisión de identidad, no un
## ajuste gráfico: elegirlo es elegir de qué color se ve TU ciudad a las 23:00.
## Lo pidió el usuario explícitamente. Ámbar de sodio por defecto, el de toda la
## vida, y se guarda con la partida como cualquier otra decisión.
const LUCES_POR_DEFECTO := "#ffb75e"
var luces: String = LUCES_POR_DEFECTO

## Los tonos con nombre, para no obligar a nadie a pelearse con un selector de
## color si solo quiere algo que quede bien. El último es "los del club", que se
## resuelve al pintar porque depende del escudo.
static func paletas_luces() -> Array:
	return [
		["#ffb75e", "Ámbar de sodio"],
		["#fff4dc", "Blanco cálido"],
		["#dff0ff", "Blanco frío"],
		["#7ee0ff", "Cian"],
		["#ff7ad1", "Magenta"],
		["#8affa0", "Verde neón"],
		["#ff6a4a", "Rojo brasa"],
	]

var _gestion_hecha: bool = false

var _ref: WeakRef

func _init(mundo: Mundo = null) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo if _ref != null else null

static func _tabla(n: String) -> Array:
	var t: Variant = Datos.tabla(n)
	return t as Array if t is Array else []

static func lista_terrenos() -> Array: return _tabla("TERRENOS")
static func lista_negocios() -> Array: return _tabla("NEGOCIOS")

static func def_terreno(clave: String) -> Array:
	for f: Array in lista_terrenos():
		if String(f[0]) == clave:
			return f
	return []

static func def_negocio(clave: String) -> Array:
	for f: Array in lista_negocios():
		if String(f[0]) == clave:
			return f
	return []

# ---------------------------------------------------------------------------
#  TERRENOS
# ---------------------------------------------------------------------------

func tiene_terreno(clave: String) -> bool:
	return terrenos.has(clave)

func precio_terreno(clave: String, c: Club) -> int:
	var d := def_terreno(clave)
	if d.is_empty():
		return 0
	return int(round(float(Eco.escalar(PRECIO_TERRENO_BASE, float(c.rep))) * float(d[2])))

func comprar_terreno(clave: String, c: Club) -> String:
	if tiene_terreno(clave):
		return "ese terreno ya es tuyo"
	var d := def_terreno(clave)
	if d.is_empty():
		return "ese terreno no existe"
	var p := precio_terreno(clave, c)
	if c.saldo < p:
		return "cuesta %s y no hay caja" % Cesiones.dinero(p)
	c.mover_saldo(-p)
	movimiento.emit("Compra de terreno: %s" % String(d[1]), -p)
	terrenos.append(clave)
	noticia.emit("Terreno comprado", "%s. %s" % [String(d[1]), String(d[3])])
	return ""

# ---------------------------------------------------------------------------
#  NEGOCIOS ANEXOS
# ---------------------------------------------------------------------------
#
# Ingresan todas las semanas del año, jueguen o no. Es lo que separa a un club
# que sobrevive de uno que crece.

func tiene_negocio(clave: String) -> bool:
	return bool(negocios.get(clave, false))

func construir_negocio(clave: String, c: Club) -> String:
	var n := def_negocio(clave)
	if n.is_empty():
		return "ese negocio no existe"
	if tiene_negocio(clave):
		return "ya está construido"
	var terr: Variant = n[3]
	if terr != null and String(terr) != "" and not tiene_terreno(String(terr)):
		var dt := def_terreno(String(terr))
		return "antes hace falta el terreno: %s" % (String(dt[1]) if not dt.is_empty() else String(terr))
	var p := Eco.escalar(float(n[2]), float(c.rep))
	if c.saldo < p:
		return "cuesta %s y no hay caja" % Cesiones.dinero(p)
	c.mover_saldo(-p)
	movimiento.emit("Obra: %s" % String(n[1]), -p)
	negocios[clave] = true
	var m := _mundo()
	## Dos negocios hacen algo más que ingresar, y por eso valen lo que valen:
	## la escuela trae socios y la clínica acorta las lesiones de verdad.
	if clave == "escuela":
		c.socios += Azar.ent(400, 1100)
	elif clave == "clinica" and m != null and m.obras != null:
		## La clinica abierta al publico sube un nivel de rehabilitacion GRATIS.
		## Es el unico sitio del juego donde una obra sale sin pasar por la cola
		## de albañiles, y es a lo que se le paga.
		m.obras.niveles["rehab"] = mini(5, m.obras.nivel("rehab") + 1)
	noticia.emit("Inaugurado: %s" % String(n[1]),
		"%s. Suma %s a la semana, llueva o truene." % [String(n[4]),
			Cesiones.dinero(Eco.escalar(RENTA_NEGOCIO_BASE * float(n[5]), float(c.rep)))])
	return ""

## Lo que rentan los negocios cada semana. El ánimo de la hinchada lo mueve: con
## la gente enchufada se llena el restaurante y el hotel.
func renta_negocios(c: Club, animo: int) -> int:
	var s := 0.0
	for n: Array in lista_negocios():
		if tiene_negocio(String(n[0])):
			s += float(Eco.escalar(RENTA_NEGOCIO_BASE * float(n[5]), float(c.rep)))
	if certificado:
		s += float(Eco.escalar(RENTA_CERTIFICADO, float(c.rep)))
	return int(round(s * (1.0 + float(animo) / 300.0)))

# ---------------------------------------------------------------------------
#  MUNICIPALIDAD Y VECINOS
# ---------------------------------------------------------------------------

func pedir_permiso(c: Club) -> String:
	if not permiso.is_empty():
		return "ya hay una solicitud en trámite"
	if permiso_ok:
		return "ya tienes el permiso vigente"
	var coste := Eco.escalar(COSTE_PERMISO, float(c.rep))
	if c.saldo < coste:
		return "la tramitación cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento.emit("Tramitación municipal y estudio de impacto", -coste)
	var m := _mundo()
	var prestigio := m.roles.prestigio if m != null and m.roles != null else 50
	var prob := clampf(0.30 + float(vecinos) / 180.0 + (0.15 if certificado else 0.0) \
		+ float(prestigio - 50) / 300.0, 0.1, 0.92)
	permiso = {"semanas": Azar.ent(3, 7), "prob": prob}
	noticia.emit("Solicitud presentada",
		"El municipio estudia tu ampliación. Resolución estimada en unas semanas. La opinión del barrio pesa: hoy está en %d de 100." % vecinos)
	return ""

## Una gestión vecinal al mes. Si se pudieran hacer las tres cada semana, la
## relación con el barrio dejaría de ser un recurso y sería un trámite.
func gestion_vecinal(que: String, c: Club) -> String:
	if _gestion_hecha:
		return "ya hiciste una gestión este mes"
	match que:
		"obra":
			var coste := Eco.escalar(COSTE_OBRA_SOCIAL, float(c.rep))
			if c.saldo < coste:
				return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
			c.mover_saldo(-coste)
			movimiento.emit("Obra social en el barrio", -coste)
			vecinos = clampi(vecinos + Azar.ent(10, 20), 0, 100)
			var m := _mundo()
			if m != null and m.roles != null:
				m.roles.sumar_prestigio(1)
			_gestion_hecha = true
			noticia.emit("Obra en el barrio",
				"Cancha de barrio, luminarias y una plaza. Los vecinos lo notaron: la relación mejora.")
			return ""
		"reunion":
			_gestion_hecha = true
			## Es gratis y por eso puede salir mal: una reunión vecinal no se
			## controla, es la única de las tres que se puede volver en contra.
			if Azar.suerte(0.6):
				vecinos = clampi(vecinos + Azar.ent(5, 12), 0, 100)
				noticia.emit("Reunión vecinal",
					"Salió bien: el barrio queda más tranquilo y la relación mejora.")
			else:
				vecinos = clampi(vecinos - Azar.ent(2, 7), 0, 100)
				noticia.emit("Reunión vecinal",
					"Terminó a gritos. Había más quejas acumuladas de las que parecía.")
			return ""
		"entradas":
			_gestion_hecha = true
			vecinos = clampi(vecinos + Azar.ent(6, 13), 0, 100)
			c.socios += Azar.ent(80, 260)
			noticia.emit("Entradas para el barrio",
				"Repartiste localidades entre las juntas vecinales. Barato y efectivo.")
			return ""
	return "esa gestión no existe"

# ---------------------------------------------------------------------------
#  CONCIERTOS Y CÉSPED
# ---------------------------------------------------------------------------
#
# Un concierto llena la caja de golpe y destroza el campo. Es la decisión más
# honesta de la pantalla: dinero hoy contra rendimiento el domingo.

func arrendar_estadio(c: Club) -> String:
	if cesped < CESPED_MINIMO_CONCIERTO:
		return "el césped está destrozado: primero hay que repararlo"
	var bruto := int(round(float(c.estadio_aforo) * Finanzas.ingreso_por_espectador(9.0) * 1.8))
	c.mover_saldo(bruto)
	movimiento.emit("Arriendo del estadio para un concierto", bruto)
	conciertos += 1
	cesped = clampi(cesped - Azar.ent(18, 32), 0, 100)
	vecinos = clampi(vecinos - Azar.ent(2, 8), 0, 100)
	noticia.emit("Concierto en el estadio",
		"Se llenó: %s limpios para la caja. El césped quedó para el arrastre (%d de 100) y los vecinos protestan por el ruido." % [
			Cesiones.dinero(bruto), cesped])
	return ""

func coste_resiembra(c: Club) -> int:
	return int(round(float(Eco.escalar(COSTE_RESIEMBRA_POR_PUNTO, float(c.rep))) * float(100 - cesped)))

func reparar_cesped(c: Club) -> String:
	if cesped >= 100:
		return "el césped está impecable"
	var coste := coste_resiembra(c)
	if c.saldo < coste:
		return "repararlo cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento.emit("Resiembra y recuperación del césped", -coste)
	cesped = 100
	noticia.emit("Césped como nuevo",
		"Resiembra completa. El campo vuelve a estar en condiciones para jugar.")
	return ""

## Lo que un campo destrozado le quita a la precisión de los jugadores. Es el
## único efecto del césped y se nota justo donde tiene que notarse: en el pase.
func penalizacion_cesped() -> float:
	if cesped >= CESPED_MINIMO_CONCIERTO:
		return 1.0
	return 1.0 - float(CESPED_MINIMO_CONCIERTO - cesped) * 0.004

# ---------------------------------------------------------------------------
#  SOSTENIBILIDAD
# ---------------------------------------------------------------------------

func instalar_paneles(c: Club) -> String:
	if paneles >= PANELES_MAX:
		return "la cubierta solar ya está al máximo"
	var coste := Eco.escalar(COSTE_PANELES, float(c.rep)) * (paneles + 1)
	if c.saldo < coste:
		return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento.emit("Paneles solares en la cubierta", -coste)
	paneles += 1
	vecinos = clampi(vecinos + 4, 0, 100)
	noticia.emit("Cubierta solar nivel %d" % paneles,
		"Menos gasto energético y beneficios tributarios. El club ahorra %s a la semana." % \
			Cesiones.dinero(Eco.escalar(AHORRO_PANEL, float(c.rep)) * paneles))
	return ""

func certificar(c: Club) -> String:
	if certificado:
		return "el estadio ya está certificado"
	if paneles < 2:
		return "hacen falta al menos dos niveles de cubierta solar"
	var coste := Eco.escalar(COSTE_CERTIFICACION, float(c.rep))
	if c.saldo < coste:
		return "la certificación cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento.emit("Certificación ecológica del estadio", -coste)
	certificado = true
	var m := _mundo()
	if m != null and m.roles != null:
		m.roles.sumar_prestigio(3)
	noticia.emit("Estadio certificado",
		"Sello verde: exención tributaria, mejor imagen y auspiciadores que solo firman con clubes certificados.")
	return ""

func ahorro_energetico(c: Club) -> int:
	return Eco.escalar(AHORRO_PANEL, float(c.rep)) * paneles

# ---------------------------------------------------------------------------
#  SEGURIDAD Y SANCIONES
# ---------------------------------------------------------------------------

func nivel_seguridad(que: String) -> int:
	return seg_privada if que == "privada" else seg_camaras

func mejorar_seguridad(que: String, c: Club) -> String:
	var niv := nivel_seguridad(que)
	if niv >= SEGURIDAD_MAX:
		return "ya está al máximo"
	var coste := Eco.escalar(200000.0 if que == "privada" else 260000.0, float(c.rep)) * (niv + 1)
	if c.saldo < coste:
		return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento.emit("%s nivel %d" % ["Seguridad privada" if que == "privada" else "Sistema de cámaras", niv + 1], -coste)
	if que == "privada":
		seg_privada = niv + 1
	else:
		seg_camaras = niv + 1
	noticia.emit("Seguridad reforzada",
		"%s Menos riesgo de incidentes y de sanción." % [
			"Más personal en accesos y anillo perimetral." if que == "privada" \
				else "Cámaras de alta definición y protocolo antiviolencia."])
	return ""

## La probabilidad de que pase algo en un partido. Sube con el mal ambiente y la
## funa; baja con la seguridad que hayas pagado.
func riesgo_incidente(animo: int, funa: int) -> float:
	## El jefe de seguridad del cuerpo tecnico tambien cuenta: es el `G.staff.seg`
	## del HTML, que aqui no existia como puesto y ahora si.
	var m := _mundo()
	var jefe := m.staff.bono_seguridad() if m != null and m.staff != null else 0.0
	return clampf(0.05 + float(100 - animo) / 600.0 + float(funa) / 900.0 \
		- float(seg_privada) * 0.012 - float(seg_camaras) * 0.014 - jefe, 0.004, 0.14)

func sancionar(tipo: String) -> void:
	sancion = {"tipo": tipo, "semanas": 1 if tipo == "cerradas" else Azar.ent(2, 4)}
	if tipo == "cerradas":
		noticia.emit("PARTIDO A PUERTAS CERRADAS",
			"El tribunal cierra el estadio un partido por los incidentes. Cero taquilla y el equipo juega en un silencio irreal.")
	else:
		noticia.emit("AFORO REDUCIDO",
			"El estadio funcionará al 40%% de aforo durante %d semanas. El golpe a la taquilla se va a notar." % int(sancion["semanas"]))

## Lo que la sanción le hace a la taquilla del domingo.
func factor_aforo() -> float:
	if sancion.is_empty():
		return 1.0
	return 0.0 if String(sancion["tipo"]) == "cerradas" else 0.4

# ---------------------------------------------------------------------------
#  LA SUBVENCIÓN MUNICIPAL
# ---------------------------------------------------------------------------
#
# Se cobra al cerrar la temporada y sale de lo que el club le devuelve al barrio:
# la relación vecinal, los negocios abiertos, las academias y el sello verde.

const SUBVENCION_BASE := 60000.0

func subvencion_anual(c: Club) -> int:
	var m := _mundo()
	var n_negocios := 0
	for k: String in negocios:
		if bool(negocios[k]):
			n_negocios += 1
	var academias := m.ojeadores.academias.size() if m != null and m.ojeadores != null else 0
	var ramas := m.hinchada.ramas.size() if m != null and m.hinchada != null else 0
	var f := float(vecinos) / 100.0 * 1.4 + float(n_negocios) * 0.10 \
		+ float(academias) * 0.08 + float(ramas) * 0.02 + (0.3 if certificado else 0.0)
	return int(round(float(Eco.escalar(SUBVENCION_BASE, float(c.rep))) * clampf(f, 0.0, 3.0)))

func cobrar_subvencion(c: Club) -> int:
	var monto := subvencion_anual(c)
	if monto <= 0:
		return 0
	c.mover_saldo(monto)
	movimiento.emit("Subvención municipal al deporte de base", monto)
	noticia.emit("Subvención municipal",
		"El municipio ingresa %s por el deporte de base, los negocios abiertos y la relación con el barrio." % Cesiones.dinero(monto))
	return monto

# ---------------------------------------------------------------------------
#  EL PULSO
# ---------------------------------------------------------------------------

func semana(c: Club, animo: int) -> void:
	if c == null:
		return
	var ing := renta_negocios(c, animo)
	if ing > 0:
		c.mover_saldo(ing)
		movimiento.emit("Negocios del club (hotel, tienda, escuela…)", ing)
	var ahorro := ahorro_energetico(c)
	if ahorro > 0:
		c.mover_saldo(ahorro)
		movimiento.emit("Ahorro energético y beneficio tributario", ahorro)
	## El césped se recupera solo, despacio: tres puntos por semana. Un concierto
	## quita hasta 32, así que dos seguidos dejan el campo inservible durante un
	## mes largo, que es exactamente el freno que tiene que tener.
	cesped = clampi(cesped + 3, 0, 100)
	## Y la relación vecinal deriva con el ambiente del club.
	if Azar.suerte(0.4):
		vecinos = clampi(vecinos + (1 if animo > 70 else -1), 0, 100)
	_resolver_permiso()
	_resolver_sancion()

func mes() -> void:
	_gestion_hecha = false

func _resolver_permiso() -> void:
	if permiso.is_empty():
		return
	permiso["semanas"] = int(permiso["semanas"]) - 1
	if int(permiso["semanas"]) > 0:
		return
	var aprobado := Azar.suerte(float(permiso["prob"]))
	permiso = {}
	if aprobado:
		permiso_ok = true
		noticia.emit("Permiso APROBADO",
			"El municipio autoriza la ampliación. Ya puedes subir las tribunas por encima del nivel 5.")
	else:
		vecinos = clampi(vecinos - 5, 0, 100)
		noticia.emit("Permiso RECHAZADO",
			"La comisión falló en contra: informe de impacto vial desfavorable y oposición vecinal. Puedes volver a intentarlo.")

func _resolver_sancion() -> void:
	if sancion.is_empty():
		return
	sancion["semanas"] = int(sancion["semanas"]) - 1
	if int(sancion["semanas"]) > 0:
		return
	sancion = {}
	noticia.emit("Sanción cumplida", "El estadio vuelve a abrir con normalidad.")

func a_dic() -> Dictionary:
	return {
		"terrenos": terrenos.duplicate(), "negocios": negocios.duplicate(),
		"vecinos": vecinos, "cesped": cesped, "conciertos": conciertos,
		"paneles": paneles, "cert": certificado,
		"seg_p": seg_privada, "seg_c": seg_camaras,
		"permiso": permiso.duplicate(), "permiso_ok": permiso_ok,
		"sancion": sancion.duplicate(), "gestion": _gestion_hecha,
		"luces": luces,
	}

func desde_dic(d: Dictionary) -> void:
	terrenos = (d.get("terrenos", []) as Array).duplicate()
	negocios = (d.get("negocios", {}) as Dictionary).duplicate()
	vecinos = int(d.get("vecinos", 55))
	cesped = int(d.get("cesped", 100))
	conciertos = int(d.get("conciertos", 0))
	paneles = int(d.get("paneles", 0))
	certificado = bool(d.get("cert", false))
	seg_privada = int(d.get("seg_p", 0))
	seg_camaras = int(d.get("seg_c", 0))
	permiso = (d.get("permiso", {}) as Dictionary).duplicate()
	permiso_ok = bool(d.get("permiso_ok", false))
	sancion = (d.get("sancion", {}) as Dictionary).duplicate()
	_gestion_hecha = bool(d.get("gestion", false))
	luces = String(d.get("luces", LUCES_POR_DEFECTO))
