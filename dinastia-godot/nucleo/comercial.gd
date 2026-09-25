class_name Comercial
extends RefCounted
## LO QUE SE VENDE DEL CLUB: kits, proveedor, zonas de patrocinio y naming.
##
## `vIdentidadPlus()` del HTML. Es la pantalla más larga del juego y la que peor
## se entiende de un vistazo, así que conviene decir para qué está: aquí NO se
## decide cómo juega el equipo, se decide cuánto vale la camiseta.
##
## POR QUÉ ES UNA PANTALLA Y NO UN NÚMERO. Todo lo de aquí paga, y todo lo de
## aquí cuesta algo que no es dinero. Vender el nombre del estadio es lo más
## rentable que existe y lo que más duele a la hinchada. Cinco zonas de camiseta
## llenas dan una fortuna y convierten el uniforme en una valla publicitaria. El
## proveedor de primer nivel paga el doble y no lo firma cualquiera.
##
## LAS TABLAS -proveedores, zonas, premium, festejos, balones, tipografías- ya
## venían exportadas del HTML en `datos/tablas.json` y no las leía nadie.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)

var _ref: WeakRef

func _init(mundo: Mundo = null) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo if _ref != null else null

static func _tabla(n: String) -> Array:
	var t: Variant = Datos.tabla(n)
	return t as Array if t is Array else []

static func proveedores() -> Array: return _tabla("PROVEEDORES")
static func zonas() -> Array: return _tabla("ZONAS_SPONSOR")
static func premium() -> Array: return _tabla("PREMIUM")
static func festejos() -> Array: return _tabla("FESTEJOS")
static func balones() -> Array: return _tabla("BALON_SKINS")
static func tipografias() -> Array: return _tabla("TIPOGRAFIAS")

## Resuelve una piel de `BALON_SKINS` a los dos colores de verdad que necesita
## `Balon3D`. Existe aparte de `balones()` por la piel "club" -fila con los dos
## colores en blanco a propósito en la tabla-, que no es un color fijo sino
## "los que tenga el club": sin este paso, cada club con esa piel elegida se
## vería con el mismo balón gris en vez del suyo.
static func color_balon(clave: String, club: Club) -> Array:
	var claro := Color("#f8faf6")
	var oscuro := Color("#1a1a1a")
	for fila: Array in balones():
		if fila.size() < 4 or String(fila[0]) != clave:
			continue
		var c1 := String(fila[2])
		var c2 := String(fila[3])
		if c1 == "" and c2 == "":
			if club != null:
				claro = Color(club.color1)
				oscuro = Color(club.color2)
		else:
			claro = Color(c1)
			oscuro = Color(c2)
		break
	return [claro, oscuro]

# ---------------------------------------------------------------------------
#  LAS TRES CAMISETAS
# ---------------------------------------------------------------------------
#
# Titular, alternativa y de arquero. La de arquero existe por una razón que no es
# estética: en el campo tiene que distinguirse de las otras veintiuna.

var kits := {
	"titular": {"c1": "", "c2": "", "estilo": ""},
	"alt": {"c1": "#f2f2f2", "c2": "#1c2430", "estilo": "liso"},
	"por": {"c1": "#2fa06a", "c2": "#0d1b12", "estilo": "liso"},
}
var medias: String = ""
var pantalon: String = ""
var tipografia: String = "clasica"
var proveedor: String = "propia"

## El color efectivo de una camiseta. Vacío hereda del club, igual que en la
## pantalla de identidad básica.
func color_kit(cual: String, n: int, c: Club) -> String:
	var k: Dictionary = kits.get(cual, {})
	var v := String(k.get("c%d" % n, ""))
	if v != "":
		return v
	if c == null:
		return "#2b6b45" if n == 1 else "#ffffff"
	return c.color_kit1() if n == 1 else c.color_kit2()

func estilo_kit(cual: String, c: Club) -> String:
	var k: Dictionary = kits.get(cual, {})
	var v := String(k.get("estilo", ""))
	if v != "":
		return v
	return Jersey.kit_de(c, c.kit_estilo) if c != null else "liso"

func fijar_kit(cual: String, campo: String, valor: String) -> void:
	if not kits.has(cual):
		return
	(kits[cual] as Dictionary)[campo] = valor

## El caché del proveedor. La marca propia no paga nada de entrada y se queda el
## margen entero: es la opción del club que no quiere deberle nada a nadie.
func multiplicador_proveedor() -> float:
	for f: Array in proveedores():
		if String(f[0]) == proveedor:
			return float(f[2])
	return 0.0

func renta_proveedor(c: Club) -> int:
	if c == null:
		return 0
	return int(round(float(Eco.escalar(240000.0, float(c.rep))) * multiplicador_proveedor()))

# ---------------------------------------------------------------------------
#  LAS CINCO ZONAS DE PATROCINIO
# ---------------------------------------------------------------------------
#
# Pecho, manga, espalda, short y ropa de entrenamiento. Son cinco contratos
# INDEPENDIENTES y todos ingresan a la vez, que es exactamente como funciona en
# el fútbol de verdad y por qué las camisetas modernas están como están.

var zonas_firmadas: Dictionary = {}   ## clave -> {marca, color, monto, anios, desde}
var ofertas_zona: Dictionary = {}     ## clave -> [{marca, color, monto, anios}]

## Cuántas ofertas llegan por zona. Dos: con una no hay elección y con cinco la
## pantalla se vuelve un listado.
const OFERTAS_POR_ZONA := 2

## `mult_rep`: el prestigio del DT (`Roles.multiplicador_sponsor()`), igual
## que en `Auspicio.generar_ofertas()`. Por defecto 1.0.
func generar_ofertas_zona(c: Club, mult_rep: float = 1.0) -> void:
	if c == null:
		return
	var marcas := Auspicio.marcas()
	if marcas.is_empty():
		return
	ofertas_zona.clear()
	var base := float(Auspicio.base_de(c))
	for z: Array in zonas():
		var clave := String(z[0])
		if zonas_firmadas.has(clave):
			continue
		var lista: Array = []
		for i in OFERTAS_POR_ZONA:
			var m: Array = marcas[Azar.ent(0, marcas.size() - 1)]
			lista.append({
				"marca": Nombres.limpiar(String(m[0])),
				"color": String(m[1]) if m.size() > 1 else "#e8b13a",
				## `generarOfertasZona()` del HTML, al pie de la letra: el sorteo es
				## `0.85+RF()*0.45` y el monto se redondea a decenas de mil. El
				## porte tenía `0.4` y sin redondear -una desviación chica pero
				## real, cazada al portar el bono de prestigio en esta misma
				## línea-. Cambiar la escala no consume más `Azar`: la liga no se
				## mueve por esto.
				"monto": int(round(base * float(z[2]) * (0.85 + Azar.f() * 0.45) * mult_rep / 10000.0)) * 10000,
				"anios": Azar.ent(1, 3),
			})
		ofertas_zona[clave] = lista

func firmar_zona(clave: String, i: int) -> String:
	var lista: Array = ofertas_zona.get(clave, [])
	if i < 0 or i >= lista.size():
		return "esa oferta ya no está"
	if zonas_firmadas.has(clave):
		return "esa zona ya está vendida"
	var o: Dictionary = lista[i]
	var m := _mundo()
	zonas_firmadas[clave] = {
		"marca": String(o["marca"]), "color": String(o["color"]),
		"monto": int(o["monto"]), "anios": int(o["anios"]),
		"desde": m.anio if m != null else 0,
	}
	ofertas_zona.erase(clave)
	noticia.emit("Zona vendida: %s" % _nombre_zona(clave),
		"%s ocupa %s por %s al año durante %d temporada(s)." % [
			String(o["marca"]), _nombre_zona(clave).to_lower(),
			Cesiones.dinero(int(o["monto"])), int(o["anios"])])
	return ""

## Romper un contrato cuesta el 60% de lo que quedaba por cobrar: no es gratis
## cambiar de opinión, y ese es el precio de haber firmado con el que más pagaba.
func romper_zona(clave: String, c: Club) -> String:
	if not zonas_firmadas.has(clave):
		return "esa zona no está vendida"
	var z: Dictionary = zonas_firmadas[clave]
	var penalizacion := int(round(float(int(z["monto"])) * 0.6))
	if c.saldo < penalizacion:
		return "romperlo cuesta %s y no hay caja" % Cesiones.dinero(penalizacion)
	c.mover_saldo(-penalizacion)
	movimiento.emit("Ruptura del contrato de %s" % _nombre_zona(clave), -penalizacion)
	zonas_firmadas.erase(clave)
	return ""

static func _nombre_zona(clave: String) -> String:
	for z: Array in zonas():
		if String(z[0]) == clave:
			return String(z[1])
	return clave

## Lo que entra por semana de las cinco zonas juntas. El contrato es anual y se
## reparte en las 42 semanas de la temporada, igual que el auspicio principal.
func renta_zonas() -> int:
	var total := 0
	for k: String in zonas_firmadas:
		total += int((zonas_firmadas[k] as Dictionary)["monto"])
	return int(round(float(total) / float(Auspicio.SEMANAS_TEMPORADA)))

# ---------------------------------------------------------------------------
#  NAMING RIGHTS DEL ESTADIO
# ---------------------------------------------------------------------------
#
# Lo más rentable que existe y lo que más duele. Se cobra todos los años y el
# estadio deja de llamarse como se llamaba: la hinchada lo paga en ánimo el día
# que se firma, no el día que se anuncia.

var naming: Dictionary = {}          ## {marca, color, monto, anios, desde, nombre_viejo}
var ofertas_naming: Array = []

const GOLPE_ANIMO_NAMING := -6

func generar_ofertas_naming(c: Club) -> void:
	if c == null or not naming.is_empty():
		return
	var marcas := Auspicio.marcas()
	if marcas.is_empty():
		return
	ofertas_naming.clear()
	var base := float(Auspicio.base_de(c)) * 1.4
	for i in 3:
		var m: Array = marcas[Azar.ent(0, marcas.size() - 1)]
		var limpia := Nombres.limpiar(String(m[0]))
		ofertas_naming.append({
			"marca": limpia,
			"color": String(m[1]) if m.size() > 1 else "#e8b13a",
			"monto": int(round(base * (0.8 + Azar.f() * 0.6))),
			"anios": Azar.ent(5, 12),
			"nombre": "%s Arena" % limpia.split(" ")[0],
		})

func firmar_naming(i: int, c: Club) -> String:
	if not naming.is_empty():
		return "el estadio ya lleva el nombre de una marca"
	if i < 0 or i >= ofertas_naming.size():
		return "esa oferta ya no está"
	var o: Dictionary = ofertas_naming[i]
	var m := _mundo()
	naming = {
		"marca": String(o["marca"]), "color": String(o["color"]),
		"monto": int(o["monto"]), "anios": int(o["anios"]),
		"desde": m.anio if m != null else 0,
		"nombre": String(o["nombre"]),
		"nombre_viejo": m.estadio.nombre_de(c) if m != null and m.estadio != null else "",
	}
	ofertas_naming.clear()
	if m != null and m.estadio != null:
		m.estadio.renombrar(String(o["nombre"]))
	if m != null and m.prensa != null:
		m.prensa.mover_animo(GOLPE_ANIMO_NAMING)
	noticia.emit("El estadio cambia de nombre",
		"Firmaste los derechos de nombre con %s: %s al año durante %d temporadas. El recinto pasa a llamarse «%s». En la calle no ha caído bien." % [
			String(o["marca"]), Cesiones.dinero(int(o["monto"])), int(o["anios"]), String(o["nombre"])])
	return ""

## Recuperar el nombre cuesta el 60% de lo que se cobra al año. Es caro a
## propósito: la marcha atrás tiene que doler tanto como para pensárselo antes.
func romper_naming(c: Club) -> String:
	if naming.is_empty():
		return "el estadio no lleva ningún nombre vendido"
	var coste := int(round(float(int(naming["monto"])) * 0.6))
	if c.saldo < coste:
		return "recuperar el nombre cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento.emit("Rescate de los derechos de nombre", -coste)
	var m := _mundo()
	if m != null and m.estadio != null:
		m.estadio.renombrar(String(naming.get("nombre_viejo", "")))
	if m != null and m.prensa != null:
		m.prensa.mover_animo(5)
	noticia.emit("El estadio recupera su nombre",
		"Pagaste por romper el contrato. El recinto vuelve a llamarse como siempre y la hinchada lo celebra.")
	naming = {}
	return ""

func renta_naming() -> int:
	if naming.is_empty():
		return 0
	return int(round(float(int(naming["monto"])) / float(Auspicio.SEMANAS_TEMPORADA)))

# ---------------------------------------------------------------------------
#  ESTADIO PREMIUM
# ---------------------------------------------------------------------------
#
# Cuatro mejoras que no son ladrillo -eso son las Obras- sino ESPECTÁCULO: techo
# retráctil, pantallas, palcos VIP y show de luces. Cada nivel cuesta más que el
# anterior y renta todas las semanas.

var extras: Dictionary = {}    ## clave -> nivel

func nivel_premium(clave: String) -> int:
	return int(extras.get(clave, 0))

func def_premium(clave: String) -> Array:
	for f: Array in premium():
		if String(f[0]) == clave:
			return f
	return []

func coste_premium(clave: String, c: Club) -> int:
	var d := def_premium(clave)
	if d.is_empty():
		return 0
	return Eco.escalar(float(d[3]), float(c.rep)) * (nivel_premium(clave) + 1)

func mejorar_premium(clave: String, c: Club) -> String:
	var d := def_premium(clave)
	if d.is_empty():
		return "esa mejora no existe"
	if nivel_premium(clave) >= int(d[2]):
		return "%s ya está al máximo" % String(d[1])
	var coste := coste_premium(clave, c)
	if c.saldo < coste:
		return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento.emit("%s nivel %d" % [String(d[1]), nivel_premium(clave) + 1], -coste)
	extras[clave] = nivel_premium(clave) + 1
	noticia.emit("%s: nivel %d" % [String(d[1]), nivel_premium(clave)], String(d[4]))
	return ""

## Lo que rentan los palcos y las pantallas cada semana.
func renta_premium(c: Club) -> int:
	if c == null:
		return 0
	var n := nivel_premium("vip") * 3 + nivel_premium("pantalla") * 2
	return Eco.escalar(9000.0, float(c.rep)) * n

## El techo retráctil salva la taquilla cuando llueve: un 6% de asistencia por
## nivel. Es el `bonoEstadioPremium()` del HTML.
func factor_techo() -> float:
	return 1.0 + float(nivel_premium("techo")) * 0.06

## Y las luces y las pantallas suben el ambiente de la grada.
func bono_ambiente() -> int:
	return nivel_premium("luces") + nivel_premium("pantalla")

# ---------------------------------------------------------------------------
#  LOS DETALLES
# ---------------------------------------------------------------------------
#
# Lema, festejo de campeón, balón, color del bus, avión propio y césped. Ninguno
# cambia un resultado salvo el avión, y por eso están todos juntos al final: son
# las cosas que hacen que el club sea ESE club y no otro.

const COSTE_AVION := 2600000.0

var lema: String = ""
var festejo: String = "confeti"
var balon: String = "clasico"
var bus: String = "#1c2430"
var avion: bool = false
var cesped: String = "natural"

func escribir_lema(t: String) -> void:
	lema = t.strip_edges().substr(0, 60)

func comprar_avion(c: Club) -> String:
	if avion:
		avion = false
		return "El club vuelve a volar en línea regular."
	var coste := Eco.escalar(COSTE_AVION, float(c.rep))
	if c.saldo < coste:
		return "el avión cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento.emit("Compra del avión del club", -coste)
	avion = true
	noticia.emit("Avión del club",
		"El plantel deja de volar en línea regular: menos fatiga en los viajes largos.")
	return "El plantel deja de volar en línea regular."

## Lo que el avión ahorra de fatiga en un viaje internacional.
func alivio_de_viaje() -> int:
	return 3 if avion else 0

# ---------------------------------------------------------------------------

## Todo lo comercial junto, por semana. Lo cobra `Mundo`.
func renta_semanal(c: Club) -> int:
	return renta_zonas() + renta_naming() + renta_premium(c) \
		+ int(round(float(renta_proveedor(c)) / float(Auspicio.SEMANAS_TEMPORADA)))

## El cierre de temporada: caducan los contratos que se acaban y llegan ofertas
## nuevas. Sin esto, un contrato firmado el primer año duraría para siempre.
func cierre_de_temporada(c: Club) -> void:
	var m := _mundo()
	if m == null:
		return
	for k: String in zonas_firmadas.keys():
		var z: Dictionary = zonas_firmadas[k]
		if m.anio - int(z["desde"]) >= int(z["anios"]):
			zonas_firmadas.erase(k)
			noticia.emit("Contrato terminado: %s" % _nombre_zona(k),
				"%s no renueva. La zona queda libre para quien pague más." % String(z["marca"]))
	if not naming.is_empty() and m.anio - int(naming["desde"]) >= int(naming["anios"]):
		if m.estadio != null:
			m.estadio.renombrar(String(naming.get("nombre_viejo", "")))
		noticia.emit("Se acaba el naming",
			"El contrato de los derechos de nombre llega a su fin. El estadio vuelve a llamarse como siempre.")
		naming = {}
	generar_ofertas_zona(c, m.roles.multiplicador_sponsor() if m.roles != null else 1.0)
	generar_ofertas_naming(c)

func a_dic() -> Dictionary:
	return {
		"kits": kits.duplicate(true), "medias": medias, "pantalon": pantalon,
		"tipografia": tipografia, "proveedor": proveedor,
		"zonas": zonas_firmadas.duplicate(true), "ofertas_zona": ofertas_zona.duplicate(true),
		"naming": naming.duplicate(true), "ofertas_naming": ofertas_naming.duplicate(true),
		"extras": extras.duplicate(), "lema": lema, "festejo": festejo,
		"balon": balon, "bus": bus, "avion": avion, "cesped": cesped,
	}

func desde_dic(d: Dictionary) -> void:
	if d.has("kits"):
		kits = (d["kits"] as Dictionary).duplicate(true)
	medias = String(d.get("medias", ""))
	pantalon = String(d.get("pantalon", ""))
	tipografia = String(d.get("tipografia", "clasica"))
	proveedor = String(d.get("proveedor", "propia"))
	zonas_firmadas = (d.get("zonas", {}) as Dictionary).duplicate(true)
	ofertas_zona = (d.get("ofertas_zona", {}) as Dictionary).duplicate(true)
	naming = (d.get("naming", {}) as Dictionary).duplicate(true)
	ofertas_naming = (d.get("ofertas_naming", []) as Array).duplicate(true)
	extras = (d.get("extras", {}) as Dictionary).duplicate()
	lema = String(d.get("lema", ""))
	festejo = String(d.get("festejo", "confeti"))
	balon = String(d.get("balon", "clasico"))
	bus = String(d.get("bus", "#1c2430"))
	avion = bool(d.get("avion", false))
	cesped = String(d.get("cesped", "natural"))
