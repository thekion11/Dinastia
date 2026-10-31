class_name MesaAgente
extends RefCounted
## EL MINI-JUEGO DE REPRESENTANTES (MEGAPLAN fase 4). La guerra de agentes
## (`Cantera.sortear_guerra_agentes`) ya existía, pero era un sí o un no: el
## representante pedía y tú elegías entre dos botones. Aquí se SIENTA a la
## mesa y se regatea por rondas:
##
##  · Lo que pide empieza en el 100 % de su exigencia (la mejora entera, la
##    comisión entera...). Debajo esconde un MÍNIMO que no se ve: lo que de
##    verdad aceptaría. Sale de su perfil (el tiburón aprieta, el formador
##    cede), de la confianza que te tiene y del bono de agentes del DT.
##  · Cada ronda cuesta PACIENCIA (las tazas de café). Si se le acaba, se
##    levanta de la mesa y es peor que haberle dicho que no.
##  · Ofrecer por debajo de su mínimo le hace bajar un poco; ofrecer muy por
##    debajo lo ofende y gasta una taza extra. Ofrecer por encima del mínimo
##    puede cerrar el trato o provocar una contraoferta a medio camino.
##  · Un FAROL por mesa: si cuela, se le hunden el mínimo y lo que pide; si
##    no, se enfada (dos tazas menos y el mínimo sube). Al mediático le asusta
##    más la prensa; al tiburón no le asusta nada.
##  · Cada ronda deja una SEÑAL (lo que se le nota): cuánto margen le queda.
##    El tiburón a veces disimula y la señal miente.
##
## El trato cerrado se aplica a ESCALA con `Cantera.resolver_agente(op, f)`:
## una mejora pactada al 60 % sube el sueldo un 18 % y no un 30 %.
##
## TEXTOS (s3, 26-10-2026): todo lo que dice la mesa sale YA traducido, de
## plantillas fijas traducidas con `Idiomas.t` y luego con sus cifras. Antes devolvía la frase
## castellana con las cifras dentro y la interfaz la traducía entera con
## patrones de regex: con cualquier cambio de redacción se quedaba en castellano.

const PERFIL := {
	"tiburon": {"minimo": 74, "paciencia": 3, "farol": 0.28, "emoji": "🦈"},
	"mediatico": {"minimo": 60, "paciencia": 4, "farol": 0.62, "emoji": "📺"},
	"discreto": {"minimo": 55, "paciencia": 4, "farol": 0.48, "emoji": "🕶️"},
	"formador": {"minimo": 44, "paciencia": 5, "farol": 0.52, "emoji": "🎓"},
}
## Lo que se le puede soltar de farol, según lo que exige.
const FAROLES := {
	"canterano": "Decirle que ya hablaste con otra agencia",
	"mejora": "Insinuar que lo pones en venta",
	"comision": "Decirle que la llamada quedó grabada",
	"exclusiva": "Decirle que otra agencia ofrece mejor trato",
}

var tipo := ""
var agente := ""
var perfil := "discreto"
var pide := 100
var minimo := 55
var paciencia := 4
var paciencia_max := 4
var ronda := 0
var estado := "abierta"   ## abierta / acuerdo / plantado / se_fue
var acordado := 0         ## % pactado cuando hay acuerdo
var farol_usado := false
var ultima := ""          ## lo último que dijo, con su señal
var _rng := RandomNumberGenerator.new()

## `confianza`: -10..10 (`Cantera.confianza_de`). `bono`: 0..~0,3 del DT.
func _init(exigencia: Dictionary, confianza: int = 0, bono: float = 0.0, semilla: int = 0) -> void:
	tipo = String(exigencia.get("tipo", "mejora"))
	agente = String(exigencia.get("agente", "El representante"))
	perfil = String(exigencia.get("perfil", "discreto"))
	if not PERFIL.has(perfil):
		perfil = "discreto"
	_rng.seed = semilla if semilla != 0 else hash(agente + tipo + str(exigencia.get("pid", "")))
	var p: Dictionary = PERFIL[perfil]
	minimo = clampi(int(p["minimo"]) - confianza * 2 - int(bono * 60.0) + _rng.randi_range(-8, 8), 20, 95)
	paciencia_max = clampi(int(p["paciencia"]) + confianza / 4, 2, 6)
	paciencia = paciencia_max
	ultima = _saludo()

## (§2.5, 30-10) El favor del agente de la semana (cita en persona, `Citas.favor_agente`): como en
## `Negociacion`, pide un 5 % menos y cede antes (su mínimo baja 5 puntos).
var con_favor := false
func aplicar_favor() -> void:
	con_favor = true
	pide = 95
	minimo = maxi(20, minimo - 5)

func emoji() -> String:
	return String(PERFIL[perfil]["emoji"])

func texto_farol() -> String:
	return Idiomas.t(String(FAROLES.get(tipo, "Tirarte un farol")))

## Las tres ofertas que se le pueden poner delante, en % de su exigencia.
func ofertas() -> Array[int]:
	var salida: Array[int] = []
	for d in [12, 30, 50]:
		var o := clampi(pide - d, 0, 100)
		if not salida.has(o):
			salida.append(o)
	return salida

## Le ofreces `oferta` (% de lo que exigía al principio).
func regatear(oferta: int) -> String:
	if estado != "abierta":
		return ultima
	ronda += 1
	paciencia -= 1
	oferta = clampi(oferta, 0, 100)
	if oferta >= minimo:
		## Por encima de su mínimo: cuanto más cerca de lo que pide, más fácil
		## que firme ya; si no, parte la diferencia.
		var cerca := 1.0 - float(pide - oferta) / maxf(1.0, float(pide - minimo) + 1.0)
		if oferta >= pide - 4 or _rng.randf() < 0.35 + 0.5 * cerca:
			return _cerrar(oferta, Idiomas.t("«Trato hecho.» Te da la mano sin soltarla del todo."))
		pide = maxi(minimo, int(round(float(pide + oferta) / 2.0)))
		ultima = Idiomas.t("«Ni para ti ni para mí: %d %%.» %s") % [pide, senal()]
	else:
		var hueco := minimo - oferta
		if hueco > 28:
			paciencia -= 1
			pide = maxi(minimo, pide - _rng.randi_range(1, 3))
			ultima = Idiomas.t("«¿Me estás tomando el pelo?» Se le endurece la cara. %s") % senal()
		else:
			pide = maxi(minimo, pide - _rng.randi_range(4, 9))
			ultima = Idiomas.t("«Así no.» Baja a %d %%. %s") % [pide, senal()]
	_revisar_paciencia()
	return ultima

## El farol: una vez por mesa.
func farol() -> String:
	if estado != "abierta" or farol_usado:
		return ultima
	farol_usado = true
	ronda += 1
	var p := float(PERFIL[perfil]["farol"])
	if _rng.randf() < p:
		minimo = maxi(15, minimo - 20)
		pide = maxi(minimo, pide - 20)
		ultima = Idiomas.t("Se le borra la sonrisa. «Bueno, bueno... hablemos.» Baja a %d %%. %s") % [pide, senal()]
	else:
		paciencia -= 2
		minimo = mini(100, minimo + 10)
		pide = maxi(pide, minimo)
		ultima = Idiomas.t("Se ríe en tu cara. «Eso no te lo crees ni tú.» %s") % senal()
	_revisar_paciencia()
	return ultima

## Le das lo que pide ahora mismo.
func ceder() -> String:
	if estado != "abierta":
		return ultima
	return _cerrar(pide, Idiomas.t("«Sabía que nos íbamos a entender.»"))

## Te levantas tú: es un no.
func plantarse() -> String:
	if estado != "abierta":
		return ultima
	estado = "plantado"
	ultima = Idiomas.t("Te levantas. %s recoge sus papeles sin mirarte.") % Idiomas.t(agente)
	return ultima

## Lo que se le nota. Con margen de sobra sonríe; sin margen repite la cifra.
## El tiburón, una de cada tres veces, enseña la señal contraria.
func senal() -> String:
	var margen := pide - minimo
	var nivel := 0 if margen <= 6 else (1 if margen <= 20 else 2)
	if perfil == "tiburon" and _rng.randf() < 0.33:
		nivel = 2 - nivel
	var s := Idiomas.t(["(Repite la cifra sin pestañear: ya no tiene margen.)",
		"(Duda y se acomoda la corbata.)",
		"(Se le escapa una media sonrisa: tiene sitio.)"][nivel])
	if paciencia == 1:
		s += " " + Idiomas.t("(Mira el reloj.)")
	return s

## El % pactado en tanto por uno (0..1), o -1 si no hubo trato.
func fraccion() -> float:
	return float(acordado) / 100.0 if estado == "acuerdo" else -1.0

## Lo que significa un % en esta exigencia, para enseñarlo en el botón.
func detalle(pct: int) -> String:
	match tipo:
		"mejora":
			return Idiomas.t("+%d %% de sueldo") % int(round(30.0 * float(pct) / 100.0))
		"comision":
			return Idiomas.t("%d %% de la comisión") % pct
		"canterano":
			return Idiomas.t("su chico, con el %d %% del sueldo que pide") % pct
		_:
			return Idiomas.t("exclusiva con un compromiso del %d %%") % pct

func _cerrar(pct: int, frase: String) -> String:
	estado = "acuerdo"
	acordado = pct
	ultima = frase
	return ultima

func _revisar_paciencia() -> void:
	if paciencia <= 0 and estado == "abierta":
		estado = "se_fue"
		ultima = Idiomas.t("%s se levanta de la mesa. «Cuando quieras hablar en serio, ya sabes dónde estoy.»") % Idiomas.t(agente)

func _saludo() -> String:
	match perfil:
		"tiburon":
			return Idiomas.t("Se sienta sin quitarse las gafas de sol. «No vine a perder el tiempo.»")
		"mediatico":
			return Idiomas.t("Deja el móvil grabando encima de la mesa. «Hablemos, que la prensa espera.»")
		"formador":
			return Idiomas.t("Trae una carpeta llena de informes. «Lo mío es cuidar a los chicos.»")
		_:
			return Idiomas.t("Pide un café y espera a que hables tú.")
