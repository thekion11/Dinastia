class_name PersonajeDatos
extends RefCounted
## LOS DATOS DE TU PERSONAJE (MEGAPLAN fase 1, etapa 6 «Personaje», 25-10-2026).
## Lo que comparten la etapa de entrada (`PantallaPersonaje`) y el creador del
## menú (`CreadorPersonaje`): las listas de estilos, la validación, el azar
## COHERENTE y cómo se aplica lo elegido a la partida.
##
## El personaje viaja como un `Dictionary` plano (lo que emite la etapa):
##   {"nombre", "apellido", "nombre_completo", "edad", "nacionalidad" (código de
##    país: "CHI"), "mujer", "estilo", "comunicacion",
##    "aspecto" (el 3D de `PersonajeDT`, lo mismo que `Roles.look["p3d"]`),
##    "look" (los rasgos del retrato 2D que salen del 3D)}
## y `aplicar()` lo deja en `Roles`: nombre, aspecto 3D, retrato 2D, género y
## el perfil (edad, nacionalidad, estilos) en `Roles.look["perfil"]`.

const EDAD_MIN := 25
const EDAD_MAX := 80
const EDAD_DEFECTO := 42
const LARGO_MIN := 2
const LARGO_MAX := 20
const LARGO_COMPLETO_MAX := 32

## Tu idea de fútbol: las MISMAS claves que `DT_ESTILOS` (las de los DT del
## juego), para que tu estilo y el de los rivales hablen el mismo idioma.
const ESTILOS := [
	["ofensivo", "Ofensivo", "Todo al ataque, cueste lo que cueste."],
	["defensivo", "Defensivo", "Candado atrás y salida rápida."],
	["motivador", "Motivador", "Garra, corazón y arengas en el vestuario."],
	["pizarron", "Pizarrón", "Un laboratorio táctico: cada partido, un plan."],
]
## Cómo hablas ante la prensa y la grada (idea 50 del dueño).
const COMUNICACION := [
	["cercano", "Cercano", "Hablas claro y con cariño: la grada te siente de los suyos."],
	["sobrio", "Sobrio", "Pocas palabras y ninguna salida de tono."],
	["directo", "Directo", "Dices lo que piensas, aunque escueza."],
	["diplomatico", "Diplomático", "Nunca un titular de más: todo con mano izquierda."],
]

## Nombres de pila de mujer por zona (las bolsas del juego son de futbolistas
## hombres). Comunes y sueltos: con un apellido al azar no son nadie.
const NOMBRES_MUJER := {
	"hispano": ["Lucía", "Valentina", "Camila", "Sofía", "Martina", "Isidora", "Javiera", "Florencia",
		"Catalina", "Antonella", "Daniela", "Paula", "Carolina", "Andrea", "Fernanda", "Josefina",
		"Romina", "Mariana", "Gabriela", "Natalia"],
	"BRA": ["Ana", "Beatriz", "Larissa", "Juliana", "Fernanda", "Camila", "Letícia", "Mariana",
		"Gabriela", "Luana", "Bruna", "Patrícia"],
	"anglo": ["Emma", "Olivia", "Charlotte", "Amelia", "Grace", "Chloe", "Hannah", "Megan", "Sarah",
		"Jessica", "Lauren", "Emily"],
	"ITA": ["Giulia", "Chiara", "Francesca", "Martina", "Sara", "Alessia", "Federica", "Elena", "Silvia"],
	"GER": ["Anna", "Lena", "Laura", "Julia", "Katharina", "Sophie", "Lea", "Miriam", "Johanna"],
	"FRA": ["Camille", "Léa", "Manon", "Chloé", "Inès", "Juliette", "Clara", "Pauline", "Margaux"],
	"JPN": ["Yui", "Aoi", "Hina", "Sakura", "Rin", "Mio", "Yuna", "Haruka", "Nanami", "Misaki"],
	"KOR": ["Seo-yeon", "Ji-woo", "Ha-eun", "Min-seo", "Su-ah", "Ji-yoon", "Yu-na", "Da-eun"],
	"arabe": ["Nour", "Layla", "Yasmin", "Salma", "Mariam", "Amira", "Hana", "Rania", "Lina"],
	"RSA": ["Thandiwe", "Lerato", "Naledi", "Zanele", "Palesa", "Emma", "Chloe", "Ayanda"],
}
const ZONA := {"BRA": "BRA", "ENG": "anglo", "USA": "anglo", "AUS": "anglo", "ITA": "ITA", "GER": "GER",
	"FRA": "FRA", "JPN": "JPN", "KOR": "KOR", "KSA": "arabe", "EGY": "arabe", "MAR": "arabe", "RSA": "RSA"}

## Cortes que se ven raros con traje formal y gorra o que no pegan con la
## edad se reparten con pesos, no se prohíben: el azar propone, tú decides.
const CORTES_MUJER := ["melena", "largo", "coleta", "ondulado", "rizado", "afro", "flequillo", "corto", "fade", "rastas", "samurai"]
## Ropa con la que va (o no) cada cosa: lo mismo que respeta `PersonajeDT._vestir`.
const CON_CORBATA := ["traje", "abrigo"]
const CON_MANGA_CORTA := ["polo", "camisa", "rayas", "vaqueros"]

static var _bolsas: Dictionary = {}

## Los países del juego {código: nombre}, en el orden de la tabla.
static func paises() -> Dictionary:
	var t: Variant = Datos.tabla("PAIS_SELECCION")
	return t if t is Dictionary and not (t as Dictionary).is_empty() else {"CHI": "Chile"}

static func nombre_pais(codigo: String) -> String:
	return Idiomas.t(String(paises().get(codigo, codigo)))

static func _par(lista: Array, clave: String, cual: int) -> String:
	for e: Array in lista:
		if String(e[0]) == clave:
			return Idiomas.t(String(e[cual]))
	return ""

static func nombre_estilo(clave: String) -> String:
	return _par(ESTILOS, clave, 1)

static func nombre_comunicacion(clave: String) -> String:
	return _par(COMUNICACION, clave, 1)

## Un personaje vacío pero válido de forma (lo que la etapa enseña al abrir).
static func nuevo(pais: String = "CHI") -> Dictionary:
	return {"nombre": "", "apellido": "", "nombre_completo": "", "edad": EDAD_DEFECTO,
		"nacionalidad": pais if paises().has(pais) else "CHI", "mujer": false,
		"estilo": "pizarron", "comunicacion": "cercano", "aspecto": PersonajeDT.BASE.duplicate(), "look": {}}

## Limpia espacios de más ("  ana   maría " -> "Ana María"): con mayúscula
## inicial en cada palabra, que es como sale en la prensa.
static func pulir_nombre(s: String) -> String:
	var partes := PackedStringArray()
	for p: String in s.strip_edges().split(" ", false):
		partes.append(p.substr(0, 1).to_upper() + p.substr(1))
	return " ".join(partes)

static func _caracteres_validos(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		var letra := String.chr(c).to_lower() != String.chr(c).to_upper()
		if not letra and not String.chr(c) in [" ", "-", "'", "’", "."]:
			return false
	return true

## Los errores del personaje, por campo ({} si está todo bien). Los textos ya
## salen traducidos: la etapa los enseña tal cual junto al campo.
static func validar(p: Dictionary) -> Dictionary:
	var e := {}
	for campo: String in ["nombre", "apellido"]:
		var v := String(p.get(campo, "")).strip_edges()
		if v == "":
			e[campo] = Idiomas.t("Escribe tu nombre.") if campo == "nombre" else Idiomas.t("Escribe tu apellido.")
		elif v.length() < LARGO_MIN:
			e[campo] = Idiomas.t("Demasiado corto.")
		elif v.length() > LARGO_MAX:
			e[campo] = Idiomas.t("Demasiado largo (máximo %d letras).") % LARGO_MAX
		elif not _caracteres_validos(v):
			e[campo] = Idiomas.t("Solo letras, espacios, guiones y apóstrofos.")
	var completo := completo_de(p)
	if not e.has("nombre") and not e.has("apellido"):
		if completo.length() > LARGO_COMPLETO_MAX:
			e["apellido"] = Idiomas.t("Nombre y apellido no caben en la prensa: acórtalos.")
		elif Nombres.vetado(completo):
			## Mismo veto que los nombres al azar: tu personaje es ficticio.
			e["apellido"] = Idiomas.t("Es el nombre de una persona real: elige otro.")
	var edad := int(p.get("edad", 0))
	if edad < EDAD_MIN or edad > EDAD_MAX:
		e["edad"] = Idiomas.t("La edad va de %d a %d años.") % [EDAD_MIN, EDAD_MAX]
	if not paises().has(String(p.get("nacionalidad", ""))):
		e["nacionalidad"] = Idiomas.t("Elige tu nacionalidad.")
	if _par(ESTILOS, String(p.get("estilo", "")), 0) == "":
		e["estilo"] = Idiomas.t("Elige tu estilo.")
	if _par(COMUNICACION, String(p.get("comunicacion", "")), 0) == "":
		e["comunicacion"] = Idiomas.t("Elige cómo hablas.")
	return e

static func completo_de(p: Dictionary) -> String:
	return ("%s %s" % [pulir_nombre(String(p.get("nombre", ""))), pulir_nombre(String(p.get("apellido", "")))]).strip_edges()

## El personaje listo para emitir: nombres pulidos, nombre completo, género
## sacado del cuerpo y el retrato 2D derivado del 3D.
static func cerrar(p: Dictionary) -> Dictionary:
	var r := p.duplicate(true)
	r["nombre"] = pulir_nombre(String(r.get("nombre", "")))
	r["apellido"] = pulir_nombre(String(r.get("apellido", "")))
	r["nombre_completo"] = completo_de(r)
	var asp := PersonajeDT.aspecto(r.get("aspecto", {}))
	r["aspecto"] = asp
	r["mujer"] = String(asp["cuerpo"]) == "female"
	var l := {}
	look_2d(asp, l)
	l["edad"] = int(r.get("edad", EDAD_DEFECTO))
	r["look"] = l
	return r

## El retrato 2D (fichas, prensa) sigue al 3D: mismo pelo, piel, barba y gafas.
## Una entrenadora no puede salir con barba en su ficha.
static func look_2d(asp: Dictionary, l: Dictionary) -> void:
	if String(asp["pelo"]) in CaraDT.CORTES:
		l["pelo"] = String(asp["pelo"])
	l["pelo_c"] = "#" + String(asp["color_pelo"])
	l["piel"] = "#" + String(asp["piel"])
	l["barba"] = 1 if bool(asp["barba"]) and String(asp["cuerpo"]) == "male" else 0
	l["gafas"] = String(asp["gafas"]) != ""

## Deja el aspecto 3D en `Roles` (lo que hacía «Guardar» en el creador).
static func aplicar_aspecto(roles: Roles, asp: Dictionary) -> void:
	var a := PersonajeDT.aspecto(asp)
	roles.look["p3d"] = a.duplicate()
	look_2d(a, roles.look)
	Genero.fijar(String(a["cuerpo"]) == "female")
	PersonajeDT.del_usuario = a.duplicate()

## Deja el personaje entero en la partida. `anio`: el año de la partida, para
## que la edad pueda crecer con las temporadas (edad + anio actual - anio).
static func aplicar(p: Dictionary, roles: Roles, anio: int = 0) -> void:
	var c := cerrar(p)
	roles.nombre = String(c["nombre_completo"]) if String(c["nombre_completo"]) != "" else roles.nombre
	aplicar_aspecto(roles, c["aspecto"])
	roles.look["edad"] = int(c["edad"])
	roles.look["perfil"] = {"nombre": c["nombre"], "apellido": c["apellido"], "edad": c["edad"],
		"nacionalidad": c["nacionalidad"], "estilo": c["estilo"], "comunicacion": c["comunicacion"],
		"anio": anio}

## Lo guardado en `Roles`, de vuelta como personaje (para reabrir la etapa).
static func de_roles(roles: Roles) -> Dictionary:
	var p := nuevo()
	var perfil: Dictionary = roles.look.get("perfil", {})
	for k: String in perfil:
		p[k] = perfil[k]
	if String(p["nombre"]) == "" and roles.nombre != "":
		var partes := roles.nombre.split(" ", false, 1)
		p["nombre"] = partes[0]
		p["apellido"] = partes[1] if partes.size() > 1 else ""
	p["aspecto"] = PersonajeDT.aspecto(roles.aspecto_3d())
	return p

# -----------------------------------------------------------------------------
#  EL AZAR COHERENTE
# -----------------------------------------------------------------------------

static func _bolsa(pais: String) -> Array:
	if _bolsas.is_empty():
		var j: Variant = null
		if FileAccess.file_exists("res://datos/bolsas_nombres.json"):
			j = JSON.parse_string(FileAccess.get_file_as_string("res://datos/bolsas_nombres.json"))
		_bolsas = (j as Dictionary).get("bolsas", {"_": []}) if j is Dictionary else {"_": []}
	return _bolsas.get(pais, _bolsas.get("_GENERAL", []))

## Nombres y apellidos del país: los mismos sitios de donde salen los de los
## futbolistas del juego (`Mundo._sortear_nombre`).
static func _pools(pais: String) -> Array:
	var n: Array = []
	var a: Array = []
	var pools: Variant = Datos.tabla("POOLS_EU")
	if pools is Dictionary and (pools as Dictionary).has(pais):
		var par: Array = (pools as Dictionary)[pais]
		n = par[0]
		a = par[1]
	elif pais == "ARG" or pais == "URU":
		n = Datos.tabla("NOMBRES_EXT") if Datos.tiene("NOMBRES_EXT") else []
		a = Datos.tabla("APELLIDOS_EXT") if Datos.tiene("APELLIDOS_EXT") else []
	if n.is_empty() or a.is_empty():
		n = Datos.tabla("NOMBRES") if Datos.tiene("NOMBRES") else ["Andrés"]
		a = Datos.tabla("APELLIDOS") if Datos.tiene("APELLIDOS") else ["Rojas"]
	var extra := _bolsa(pais)
	if extra.size() >= 2:
		n = n + (extra[0] as Array)
		a = a + (extra[1] as Array)
	return [n, a]

## Un nombre y apellido del país y del género, que no sea el de nadie real.
static func nombre_al_azar(pais: String, mujer: bool, rng: RandomNumberGenerator) -> Array:
	var pl := _pools(pais)
	var mujeres: Array = NOMBRES_MUJER.get(ZONA.get(pais, "hispano"), NOMBRES_MUJER["hispano"])
	var par := ["", ""]
	for _i in 8:
		var pila: Array = mujeres if mujer else pl[0]
		par = [String(pila[rng.randi() % pila.size()]), String((pl[1] as Array)[rng.randi() % (pl[1] as Array).size()])]
		if not Nombres.vetado("%s %s" % par):
			break
	return [Nombres.limpiar(par[0]), Nombres.limpiar(par[1])]

## Un aspecto al azar que no choca consigo mismo ni con la edad: sin barba en
## una mujer, corbata solo con traje o abrigo, manga corta solo donde la hay,
## nada de gorra con traje, canas y entradas más probables con los años y, en
## un hombre, a veces una cara de la biblioteca modular con su corte medido.
## `mujer`: -1 al azar, 0 hombre, 1 mujer.
static func aspecto_coherente(rng: RandomNumberGenerator, mujer: int = -1, edad: int = EDAD_DEFECTO) -> Dictionary:
	var a := PersonajeDT.aleatorio(rng)
	var es_mujer := (rng.randf() < 0.25) if mujer < 0 else mujer == 1
	a["cuerpo"] = "female" if es_mujer else "male"
	a["altura"] = snappedf(rng.randf_range(1.58, 1.76) if es_mujer else rng.randf_range(1.68, 1.95), 0.01)
	if es_mujer:
		a["barba"] = false
		a["pelo"] = CORTES_MUJER[rng.randi() % CORTES_MUJER.size()]
		a["cara"] = -1
		a["corte_med"] = ""
	else:
		a["barba"] = rng.randf() < 0.4
		if edad >= 50 and rng.randf() < 0.35:
			a["pelo"] = ["calvo", "rapado", "corto"][rng.randi() % 3]
		if BibliotecaCaras.hay() and rng.randf() < 0.6:
			var n := BibliotecaCaras.del_tono(Color(String(a["piel"]))).size()
			a["cara"] = rng.randi() % maxi(n, 1)
			var pelos := BibliotecaCaras.pelos()
			a["corte_med"] = String(pelos[rng.randi() % pelos.size()]) if not pelos.is_empty() and rng.randf() < 0.45 else ""
		else:
			a["cara"] = -1
			a["corte_med"] = ""
	## Las canas, por edad (las mismas franjas que el retrato 2D de `CaraDT`).
	var canas := 0.55 if edad >= 55 else (0.25 if edad >= 45 else 0.0)
	if rng.randf() < canas:
		a["color_pelo"] = "9a9a9a" if rng.randf() < 0.6 else "e8e8e4"
	elif String(a["color_pelo"]) in ["9a9a9a", "e8e8e4"] and edad < 45:
		a["color_pelo"] = ["0e0b09", "2a1c12", "4a3020", "7a5230"][rng.randi() % 4]
	var ropa := String(a["ropa"])
	a["corbata"] = ropa in CON_CORBATA and rng.randf() < 0.7
	a["manga_corta"] = ropa in CON_MANGA_CORTA and rng.randf() < 0.35
	if ropa in ["traje", "abrigo"]:
		a["gorra"] = false
		if String(a["gafas"]) == "deportivas":
			a["gafas"] = "ver"
	## El tatuaje se ve en el antebrazo: sin manga corta no luce.
	if not bool(a["manga_corta"]):
		a["tatuaje"] = 0
	return a

## Un personaje entero al azar del país `pais` (el resto, coherente con él).
static func al_azar(pais: String, rng: RandomNumberGenerator, mujer: int = -1) -> Dictionary:
	var p := nuevo(pais)
	p["edad"] = clampi(int(round(rng.randfn(46.0, 9.0))), EDAD_MIN + 7, EDAD_MAX - 12)
	p["aspecto"] = aspecto_coherente(rng, mujer, int(p["edad"]))
	p["mujer"] = String(p["aspecto"]["cuerpo"]) == "female"
	var np := nombre_al_azar(String(p["nacionalidad"]), bool(p["mujer"]), rng)
	p["nombre"] = np[0]
	p["apellido"] = np[1]
	p["estilo"] = String(ESTILOS[rng.randi() % ESTILOS.size()][0])
	p["comunicacion"] = String(COMUNICACION[rng.randi() % COMUNICACION.size()][0])
	return p
