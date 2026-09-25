class_name ClubDentro
extends RefCounted
## EL CLUB POR DENTRO: vestuario, sala de prensa, palco y lo digital.
##
## `vClubIn()` del HTML. Lo que no sale en la tabla: dónde se cambian, dónde te
## preguntan y dónde se sientan los que firman los cheques.
##
## POR QUÉ NO VA DENTRO DE `Instalaciones`. Parece lo mismo y no lo es. Las
## instalaciones son OBRAS: cuestan semanas, hay una en curso cada vez y suben
## de nivel una a una. Esto son ESPACIOS que se eligen: pagas y ya está, y
## puedes bajar de categoría si te hace falta la caja. Meter las dos cosas en la
## misma clase habría obligado a que la mitad de sus métodos preguntaran de qué
## tipo es cada cosa, que es la señal de que son dos clases.
##
## Cada espacio pega en un sitio distinto del juego, y eso es lo que hace que
## elegir importe cuando no llega para los tres:
##   · vestuario     → moral del plantel, semana a semana
##   · sala de prensa → cuánto ruido aguanta tu imagen (baja la funa)
##   · palco          → lo que te ofrecen los patrocinadores

## clave, nombre, descripción, coste base, bonificación.
const VESTUARIO := [
	["viejo", "El de toda la vida", "Bancas de madera y una ducha que va cuando quiere.", 0, 0],
	["digno", "Reformado", "Taquillas nuevas, suelo decente y agua caliente de verdad.", 240000, 2],
	["primera", "De primer nivel", "Hidromasaje, sala de charla con pantalla y zona de recuperación.", 900000, 5],
]
const SALA_PRENSA := [
	["mesa", "Una mesa y un mantel", "Dos micrófonos prestados y el escudo impreso en una lona.", 0, 0],
	["decente", "Sala propia", "Fondo de patrocinadores, luz decente y sitio para veinte.", 180000, 2],
	["television", "Plató de televisión", "Iluminación de estudio, pantalla y realización propia.", 720000, 5],
]
const PALCO := [
	["gradas", "Butacas de la tribuna", "El presidente se sienta con todos. Tiene su encanto.", 0, 0],
	["vip", "Palco cerrado", "Cristal, calefacción y catering para los invitados.", 320000, 2],
	["lujo", "Palco de honor", "Salón privado, ascensor propio y sitio donde se firman cosas.", 1100000, 6],
]

## Lo digital: se lanza una vez -con nombre propio- y CRECE cada semana con
## los resultados, igual que en el HTML (`procesoClubIn()` corre en el mismo
## proceso semanal que la cantera o la prensa, no en el cierre de mes). No es
## una renta plana: `crecer_digital()`, más abajo, hace lo que hacía
## `C.app.subs=round(C.app.subs*(1.004+forma*0.002)+R(-20,140))`.
const COSTE_APP := 260000.0
const COSTE_WEB := 120000.0

var vestuario: String = "viejo"
var sala_prensa: String = "mesa"
var palco: String = "gradas"
## {} = no lanzada. Lanzada: {"nombre", "subs", "desde"}.
var app: Dictionary = {}
## {} = no lanzada. Lanzada: {"dominio", "visitas", "desde"}.
var web: Dictionary = {}
## Los últimos resultados de LIGA de tu club -"G"/"E"/"P", como mucho 5-. Solo
## liga los mueve: `registrarPost()` del HTML solo empuja `forma` cuando
## `modo==='liga'`, copa y continental no cuentan para esto.
var forma: Array = []

static func _def(lista: Array, clave: String) -> Array:
	for f: Array in lista:
		if String(f[0]) == clave:
			return f
	return lista[0]

func bono_vestuario() -> int:
	return int(_def(VESTUARIO, vestuario)[4])

func bono_prensa() -> int:
	return int(_def(SALA_PRENSA, sala_prensa)[4])

func bono_palco() -> int:
	return int(_def(PALCO, palco)[4])

## Compra un espacio. Devuelve "" si se hizo, o el motivo por el que no.
##
## Bajar de categoría es GRATIS y no devuelve nada: es la salida de emergencia
## para quien se quedó sin caja. Poder recuperar el dinero convertiría esto en
## un depósito, y entonces comprar el palco de lujo no sería una decisión.
func elegir(que: String, clave: String, c: Club) -> String:
	var lista: Array = VESTUARIO
	var actual := vestuario
	match que:
		"prensa":
			lista = SALA_PRENSA
			actual = sala_prensa
		"palco":
			lista = PALCO
			actual = palco
	var nuevo := _def(lista, clave)
	var viejo := _def(lista, actual)
	if String(nuevo[0]) == actual:
		return "ya lo tienes"
	## Solo se paga al SUBIR: si el nuevo cuesta menos que el que tienes, es una
	## rebaja y no cuesta nada.
	if int(nuevo[3]) > int(viejo[3]):
		var coste := Eco.escalar(float(nuevo[3]), float(c.rep))
		if c.saldo < coste:
			return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
		c.mover_saldo(-coste)
	match que:
		"prensa": sala_prensa = String(nuevo[0])
		"palco": palco = String(nuevo[0])
		_: vestuario = String(nuevo[0])
	return ""

## `lanzarApp()`/`lanzarWeb()` del HTML. El nombre/dominio vacío no es un error:
## el HTML también cae a un nombre por defecto cuando el campo viene en blanco.
func lanzar_app(c: Club, nombre: String, anio: int) -> String:
	if not app.is_empty():
		return "ya lo tienes"
	var coste := Eco.escalar(COSTE_APP, float(c.rep))
	if c.saldo < coste:
		return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	var nom := nombre.strip_edges()
	if nom == "":
		nom = c.nombre + " Oficial"
	app = {"nombre": nom.substr(0, 28), "subs": int(round(float(c.socios) * 0.08)), "desde": anio}
	return ""

func lanzar_web(c: Club, dominio: String, anio: int) -> String:
	if not web.is_empty():
		return "ya lo tienes"
	var coste := Eco.escalar(COSTE_WEB, float(c.rep))
	if c.saldo < coste:
		return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	var dom := dominio.strip_edges().to_lower()
	if dom == "":
		dom = c.nombre.to_lower().replace(" ", "") + ".cl"
	web = {"dominio": dom.substr(0, 30), "visitas": int(round(float(c.socios) * 1.4)), "desde": anio}
	return ""

## Se llama tras CADA jornada de liga tuya -no copa, no continental, igual que
## `registrarPost()` del HTML, que solo empuja `forma` con `modo==='liga'`-.
## Se recorta a 5 aquí mismo porque nadie lee más que los últimos 5.
func registrar_resultado_liga(gano: bool, empate: bool) -> void:
	forma.append("G" if gano else ("E" if empate else "P"))
	if forma.size() > 5:
		forma = forma.slice(forma.size() - 5)

## `procesoClubIn()` del HTML: la app y la web crecen SOLAS cada semana, más
## rápido cuantas más de tus últimas 5 de liga fueron victorias. Devuelve lo
## que se cobró, para que quien llame lo deje escrito en el libro financiero
## -mismo patrón que `Instalaciones.ingresos_del_mes()`-.
func crecer_digital(c: Club, prensa) -> Array:
	if c == null:
		return []
	var victorias := 0
	for r in forma:
		if String(r) == "G":
			victorias += 1
	var movimientos: Array = []
	if not app.is_empty():
		var subs := maxi(0, int(round(float(app["subs"]) * (1.004 + float(victorias) * 0.002) \
			+ float(Azar.ent(-20, 140)))))
		app["subs"] = subs
		var ingreso := int(round(float(subs) * Eco.ECO * 0.9))
		c.mover_saldo(ingreso)
		movimientos.append({"concepto": "Suscripciones de la app oficial", "monto": ingreso})
	if not web.is_empty():
		var visitas := maxi(0, int(round(float(web["visitas"]) * (1.003 + float(victorias) * 0.0015) \
			+ float(Azar.ent(-100, 900)))))
		web["visitas"] = visitas
		var ingreso_w := int(round(float(visitas) * Eco.ECO * 0.02))
		c.mover_saldo(ingreso_w)
		movimientos.append({"concepto": "Publicidad en la web del club", "monto": ingreso_w})
		## La web también trae hinchas a las redes: "G.social.seg+=visitas*0.0008".
		if prensa != null:
			prensa.seguidores += int(round(float(visitas) * 0.0008))
	return movimientos

## El pulso semanal: el vestuario sostiene la moral y la sala de prensa amortigua
## la funa. Los dos efectos son PEQUEÑOS y constantes, que es lo que hace que se
## noten en una temporada entera y no en una semana suelta.
func semana(c: Club, prensa) -> void:
	if c == null:
		return
	var b := bono_vestuario()
	if b > 0:
		for j in c.plantilla:
			j.moral = clampi(j.moral + (1 if Azar.suerte(float(b) * 0.12) else 0), 10, 99)
	if prensa != null and bono_prensa() > 0 and prensa.funa > 0:
		prensa.funa = maxi(0, prensa.funa - (1 if Azar.suerte(float(bono_prensa()) * 0.1) else 0))

func a_dic() -> Dictionary:
	return {"vestuario": vestuario, "prensa": sala_prensa, "palco": palco, "app": app, "web": web,
		"forma": forma, "ct_ropa": ct_ropa, "ct_c1": ct_color1, "ct_c2": ct_color2, "frase": frase}

func desde_dic(d: Dictionary) -> void:
	vestuario = String(d.get("vestuario", "viejo"))
	sala_prensa = String(d.get("prensa", "mesa"))
	palco = String(d.get("palco", "gradas"))
	## Guardados viejos traían `app`/`web` como booleano: se leen igual -`{}` si
	## no había nada, y si había `true` se lanza con los valores por defecto de
	## un club recién llegado a esto, ya que el guardado viejo no tenía nombre
	## ni contador que rescatar-.
	var app_vieja: Variant = d.get("app", {})
	if app_vieja is bool:
		app = {"nombre": "App Oficial", "subs": 0, "desde": 0} if app_vieja else {}
	else:
		app = app_vieja if app_vieja is Dictionary else {}
	var web_vieja: Variant = d.get("web", {})
	if web_vieja is bool:
		web = {"dominio": "", "visitas": 0, "desde": 0} if web_vieja else {}
	else:
		web = web_vieja if web_vieja is Dictionary else {}
	forma = d.get("forma", [])
	ct_ropa = String(d.get("ct_ropa", "chandal"))
	ct_color1 = String(d.get("ct_c1", ""))
	ct_color2 = String(d.get("ct_c2", ""))
	frase = String(d.get("frase", ""))

# ---------------------------------------------------------------------------
#  EL UNIFORME DEL CUERPO TÉCNICO Y LA FRASE DE LA PARED
# ---------------------------------------------------------------------------
#
# Ninguna de las dos mueve un número, y las dos son de las cosas que hacen que
# un club se sienta tuyo. El uniforme sale en el banquillo; la frase se lee en el
# túnel antes de cada partido —en el HTML lo prometía el texto y no pasaba en
# ninguna pantalla; aquí sale de verdad en la previa.

## clave, nombre, color principal por defecto, color secundario por defecto.
const CT_ROPA := [
	["traje", "Traje del club", "#1c2430", "#c9a227"],
	["chandal", "Chándal técnico", "#1e4030", "#e8ede9"],
	["polo", "Polo y pantalón", "#2b3a45", "#dfe6e2"],
	["abrigo", "Abrigo largo", "#2a2320", "#8a6b4a"],
	["casual", "Casual moderno", "#33363b", "#d9d9d9"],
]

## Lo que cabe en una pared. Sesenta caracteres es el límite del HTML y es el
## correcto: una frase que no cabe en un vistazo antes de salir no la lee nadie.
const FRASE_MAX := 60

var ct_ropa: String = "chandal"
## Vacíos significa "los del propio uniforme": así un club recién tomado ya viste
## de sus colores sin que haya que elegir nada.
var ct_color1: String = ""
var ct_color2: String = ""
var frase: String = ""

func def_ropa(clave: String = "") -> Array:
	var k := clave if clave != "" else ct_ropa
	for f: Array in CT_ROPA:
		if String(f[0]) == k:
			return f
	return CT_ROPA[1]

func color_ct1(c: Club) -> String:
	if ct_color1 != "":
		return ct_color1
	return c.color1 if c != null else String(def_ropa()[2])

func color_ct2(c: Club) -> String:
	if ct_color2 != "":
		return ct_color2
	return c.color2 if c != null else String(def_ropa()[3])

## Cambiar de prenda borra los colores a mano: elegir "abrigo largo" y que
## conserve el verde chillón del chándal anterior no es lo que nadie espera.
func vestir(clave: String) -> void:
	for f: Array in CT_ROPA:
		if String(f[0]) == clave:
			ct_ropa = clave
			ct_color1 = ""
			ct_color2 = ""
			return

func escribir_frase(texto: String) -> void:
	frase = texto.strip_edges().substr(0, FRASE_MAX)
