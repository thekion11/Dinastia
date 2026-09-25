class_name Jugador
extends RefCounted
## Un futbolista.
##
## En el HTML esto era un diccionario suelto y unas quince funciones globales
## que lo recibian por parametro (`genAtributos(j)`, `calcEco(j)`, `factorEdad(j)`,
## `aptitud(j,pos)`...). Aqui es una clase: el dato y lo que se puede hacer con
## el viajan juntos, no hay forma de llamar a `calcEco` con medio jugador, y el
## autocompletado del editor dice que existe y que no.
##
## Las FORMULAS son las mismas del HTML, no una version nueva. Portar, no
## reescribir: el equilibrio economico del juego costo una depuracion entera y
## no se toca al mudar de motor.

## Se emite cuando el jugador se lesiona, para que se entere quien quiera
## (la interfaz, el parte medico, el DT) sin que el simulador conozca a nadie.
signal lesionado(semanas: int)
signal marco_gol
signal cambio_media(antes: int, ahora: int)

var id: String = ""
var nombre: String = ""
var pais: String = "CHI"
## Región de origen dentro del país ("EUS" = Euskal Herria), o vacío. Solo
## importa para los clubes con filosofía de cantera (`Regiones`, C3).
var region: String = ""
var club_id: String = ""
var club_formacion: String = ""

var pos: String = "MED"        ## grupo: POR/DEF/MED/DEL
var pos_e: String = "MC"       ## demarcacion concreta: DFC, MCO, ED...
var pos_sec: Array[String] = []

var edad: int = 24
var ovr: int = 60
var pot: int = 60
var atributos: Dictionary = {}   ## rit/tir/pas/reg/def/fis, o div/par/saq/ref/vel/pos si es portero
var rasgo: String = ""

## LO QUE EL EDITOR HAYA CAMBIADO DE SU CARA. Vacio significa "la que le tocó":
## `Cara.look_de()` la saca de un hash del id, y esto solo pisa las claves que
## se hayan tocado a mano. Asi el editor no tiene que escribir los quince rasgos
## para cambiar un corte de pelo, y un jugador sin editar sigue costando cero.
var look: Dictionary = {}

## LA MEDIA CON LA QUE EMPEZO LA TEMPORADA. Se guarda para poder decir «este
## chico ha subido cuatro puntos este ano», que es la unica forma de ver si tu
## academia y tu plan de entrenamiento sirven de algo: mirando la media de hoy
## no se distingue a un canterano que crece de uno que se estanco.
var ovr_al_empezar: int = 0

## EL HISTORIAL DE TEMPORADAS, `histG`+`histOvr` del HTML fundidos en uno.
## Cada entrada: {"anio","club","pj","goles","ovr"} -club, partidos y goles de
## ESA temporada, con la media con la que se cerró-. En el HTML eran dos listas
## separadas (`histG` hasta 6 años, `histOvr` hasta 12) y la segunda arrastraba
## un desfase: se rellenaba en un bucle que corría DESPUÉS del que ya había
## puesto `pj`/`goles` a cero, así que "CRECIMIENTO POR TEMPORADA" mostraba
## siempre "0 PJ · 0 goles" junto al ovr (se ve comparando `juego.js:3337` con
## `juego.js:3407` contra el orden real de ejecución). Aquí se toma todo junto,
## en el momento en que los datos todavía son los de la temporada que se
## cierra -ver `Mundo.cerrar_temporada()`-, así que el número que se muestra es
## el bueno y no hace falta mantener dos listas para lo mismo.
var historial: Array = []

func registrar_temporada(anio: int, club_nombre: String) -> void:
	historial.append({"anio": anio, "club": club_nombre, "pj": partidos, "goles": goles, "ovr": ovr})
	if historial.size() > 12:
		historial.pop_front()

var forma: int = 60
var moral: int = 70
var fisico: int = 100
var lesion: int = 0            ## semanas que le quedan fuera
var suspension: int = 0
var amarillas: int = 0
## Semanas que le quedan rindiendo por debajo tras una reconversion de puesto
## -j.adapt del HTML-. Solo es un contador para avisar en la ficha: la
## penalizacion de -4% que el HTML aplica en `fuerzaJug()` no esta portada
## porque el calculo de fuerza de Godot (`Partido.fuerza()`) ya no pasa la
## aptitud de posicion jugador a jugador, sino que la resuelve antes, al armar
## el once (`Club.once()`); meterla aqui tambien duplicaria el castigo.
var adapt: int = 0
## Ano hasta el cual no pide salida tras una prima de fidelidad -j.fidelidad
## del HTML-. 0 = sin clausula.
var fidelidad_hasta: int = 0

var goles: int = 0
var asistencias: int = 0
var partidos: int = 0

## Las notas de los ultimos partidos. Se guardan las ocho ultimas, como en el
## HTML: con mas, un mal mes queda enterrado bajo el buen ano anterior y la
## media deja de decir como esta el jugador AHORA.
var notas: Array[float] = []

var valor: int = 0
var sueldo: int = 0
var anios_contrato: int = 1
var dorsal: int = 0
var capitan: bool = false
## Un jugador que pidio salir vale menos y quiere irse mas: lo usan las tres
## puertas del mercado.
var pide_salir: bool = false
## Lo pusiste tu, desde su ficha: "en venta". El sorteo semanal de ofertas lo
## mete tres veces en la bolsa en vez de una -listarTransferible() del HTML-.
var transferible: bool = false
## Semana a partir de la cual su club vuelve a sentarse a hablar de el, tras
## romperse una negociacion -j.noNegociar del HTML-. 0 = sin restriccion.
var no_negociar_hasta: int = 0
## Es un futbolista real de verdad, con nombre y club de la vida real -lo puso
## `Reales.aplicar()`, no el sorteo-. `j.real` del HTML: sirve para no
## reescribirlo con otro real por error y para saber a quien buscarle una foto
## de verdad en vez de dibujarle una cara procedural.
var real: bool = false

## Solo mientras `club_id == ""` -un agente libre-: por qué quedó sin equipo
## (`j.motivo` de `nuevoLibre()` en el HTML) y cuántas veces te dijo que no
## -a la segunda, sale de la bolsa (`ficharLibre()`)-.
var motivo_libre: String = ""
var rechazos_libre: int = 0

## Media ponderada segun la demarcacion. Un central con 90 de ritmo y 40 de
## marca no es un central de 90: los pesos de POSD deciden.
func media_en(demarcacion: String) -> int:
	var posd: Dictionary = Datos.tabla("POSD")
	if posd == null or not posd.has(demarcacion):
		return ovr
	var pesos: Dictionary = posd[demarcacion]["p"]
	var suma := 0.0
	var peso_total := 0.0
	for k: String in pesos:
		if atributos.has(k):
			suma += float(atributos[k]) * float(pesos[k])
			peso_total += float(pesos[k])
	if peso_total <= 0.0:
		return ovr
	return int(round(suma / peso_total))

func es_portero() -> bool:
	return pos_e == "POR"

func disponible() -> bool:
	return lesion <= 0 and suspension <= 0

## Reparte los atributos alrededor de la media respetando los pesos de la
## demarcacion. El truco portado del HTML: se sortea una desviacion por
## atributo y luego se resta la media PONDERADA de esas desviaciones, para que
## el jugador siga valiendo `ovr` en su puesto por mucho que se le muevan las
## piezas. Sin esa resta, repartir al azar inflaba la media real.
func generar_atributos() -> void:
	var posd: Dictionary = Datos.tabla("POSD")
	var clave := pos_e if (posd != null and posd.has(pos_e)) else "MC"
	var pesos: Dictionary = posd[clave]["p"]
	var desv := {}
	var acumulado := 0.0
	for k: String in pesos:
		var v := Azar.ent(-15, 15)
		desv[k] = v
		acumulado += float(v) * float(pesos[k])
	atributos = {}
	for k: String in pesos:
		atributos[k] = clampi(int(round(float(ovr) + float(desv[k]) - acumulado)), 22, 99)
	_sesgo_por_rasgo()

func _sesgo_por_rasgo() -> void:
	match rasgo:
		"veloz": _subir("rit", 7)
		"killer": _subir("tir", 7)
		"muralla": _subir("def", 6)
		"cerebro": _subir("pas", 6)
		"fragil": _subir("fis", -8)

func _subir(k: String, n: int) -> void:
	if atributos.has(k):
		atributos[k] = clampi(int(atributos[k]) + n, 22, 99)

## Valor de mercado y sueldo. Exponencial sobre la media, pivotando en 70.
func tasar() -> void:
	var base: float = Eco.VALOR_PIVOTE * pow(Eco.CURVA_JUG, float(ovr) - Eco.OVR_PIVOTE)
	var v := base * Eco.factor_edad(edad, ovr, pot)
	if rasgo == "fragil": v *= 0.88
	if rasgo == "killer" or rasgo == "lider": v *= 1.06
	if anios_contrato <= 1: v *= 0.72   ## en su ultimo ano vale menos
	valor = int(max(300.0, round(v / 100.0) * 100.0))
	## El sueldo crece con el valor pero mas despacio que el, o los grandes
	## quebrarian solos.
	sueldo = int(max(30.0, round(1.361 * pow(float(valor), 0.66) / 10.0) * 10.0))

func lesionar(semanas: int) -> void:
	lesion = max(lesion, semanas)
	lesionado.emit(semanas)

func anotar() -> void:
	goles += 1
	marco_gol.emit()

func ajustar_media(delta: int) -> void:
	if delta == 0:
		return
	var antes := ovr
	ovr = clampi(ovr + delta, 40, 96)
	if ovr != antes:
		tasar()
		cambio_media.emit(antes, ovr)

## Cuanto ha crecido -o caido- esta temporada. Cero si acaba de llegar.
func crecimiento_temporada() -> int:
	return 0 if ovr_al_empezar <= 0 else ovr - ovr_al_empezar

func _to_string() -> String:
	return "%s (%s, %d, %d)" % [nombre, pos_e, edad, ovr]

func anotar_nota(n: float) -> void:
	notas.append(n)
	if notas.size() > 8:
		notas.remove_at(0)

## La media de las ultimas notas, o 0 si todavia no ha jugado lo suficiente para
## que signifique algo. Devolver 6 por defecto seria peor: pondria a los que no
## juegan por delante de los que juegan mal.
func media_notas(minimo: int = 3) -> float:
	if notas.size() < minimo:
		return 0.0
	var s := 0.0
	for n in notas:
		s += n
	return s / float(notas.size())

# ---------------------------------------------------------------------------
#  RECONVERSION DE POSICION -aptitud()/mediaEnPos()/reconvertir() del HTML-
# ---------------------------------------------------------------------------
#  Cuanto rendiria este jugador en un puesto que no es el suyo, y el gesto
#  permanente de cambiarselo. No tocan la fuerza que ve el partido -esa la
#  resuelve `Club.once()` con su propio factor de familiaridad, ya depurado y
#  verificado con el banco-: esto es la ficha ("prueba a este central de
#  lateral") y la reconversion misma, que sí es la misma decision del HTML.

## El pie con el que juega. El HTML lo sortea al crear al jugador y lo guarda
## -70/76% diestro-; Godot no lleva ese campo, asi que sale de un hash estable
## de su id con la misma proporcion, para no inventar un campo persistido
## nuevo solo para un matiz de un 6% en la aptitud de los laterales.
##
## MEZCLADO, NO SUMADO. La primera version sumaba `unicode_at(i)` sin mas, y
## para ids correlativos ("j1","j2","j3"...) eso crece tan despacio -los
## digitos van de 48 a 57- que el resultado se queda pegado muy por debajo de
## 76 durante miles de jugadores seguidos: se probo sobre un mundo generado de
## verdad y salio 100% diestro, cuando tenia que rondar el 76%. Es la MISMA
## trampa que ya paso una vez con `Cara.look_de()` -documentada ahi mismo,
## "24 jugadores con dos cortes de pelo entre todos"-, aqui sin arreglar
## todavia. Con una mezcla multiplicativa (djb2, la misma que usa `Escudo.
## _hash()`/`Cara._hash()`) el bit bajo SI depende de todos los caracteres.
func pie() -> String:
	var h := 5381
	for i in id.length():
		h = ((h << 5) + h + id.unicode_at(i)) & 0x7FFFFFFF
	return "D" if h % 100 < 76 else "I"

## Version ponderada de su media EN ese puesto, antes de aplicar la aptitud
## -ovrEnPos() del HTML-. Un portero jugando de campo (o al reves) rinde un
## 55% de su media: no hay atributos que pesar.
func ovr_en_puesto(pe: String) -> int:
	var posd: Variant = Datos.tabla("POSD")
	if not (posd is Dictionary) or not (posd as Dictionary).has(pe):
		return ovr
	var d: Dictionary = (posd as Dictionary)[pe]
	var es_por := String(d.get("g", "")) == "POR"
	var tiene_por := atributos.has("div")
	if es_por != tiene_por:
		return int(round(float(ovr) * 0.55))
	var pesos: Dictionary = d.get("p", {})
	if pesos.is_empty():
		return ovr
	var suma := 0.0
	for k: String in pesos:
		suma += float(atributos.get(k, ovr)) * float(pesos[k])
	return int(round(suma))

## Cuanto castiga jugar en un puesto que no es el suyo (0.60-1.00) -aptitud()
## del HTML-: 1 en el natural, 0.975 en uno secundario ya asignado, 0.60 entre
## portero y jugador de campo, 0.93 en un puesto adyacente (`POS_ADY`), 0.90
## mismo grupo y mismo lado, 0.84 mismo grupo otro lado, 0.79 el resto. Un
## lateral a pie cambiado paga un 0.94 extra encima de cualquiera de estos.
func aptitud_en(pe: String) -> float:
	var posd: Variant = Datos.tabla("POSD")
	if pe == "" or not (posd is Dictionary) or not (posd as Dictionary).has(pe):
		return 1.0
	var tabla: Dictionary = posd as Dictionary
	var d: Dictionary = tabla[pe]
	var n: Dictionary = tabla.get(pos_e, tabla.get("MC", {}))
	var lado := 1.0
	if String(d.get("d", "")) == "LAT" and d.has("b") and String(d["b"]) != pie():
		lado = 0.94
	if pos_e == pe:
		return 1.0 * lado
	if pos_sec.has(pe):
		return 0.975 * lado
	if String(d.get("g", "")) == "POR" or String(n.get("g", "")) == "POR":
		return 0.60
	var pos_ady: Variant = Datos.tabla("POS_ADY")
	var vecinos: Array = (pos_ady as Dictionary).get(pos_e, []) if pos_ady is Dictionary else []
	if vecinos.has(pe):
		return 0.93 * lado
	if String(d.get("g", "")) == String(n.get("g", "")):
		return (0.90 if String(d.get("d", "")) == String(n.get("d", "")) else 0.84) * lado
	return 0.79 * lado

## Media efectiva jugando en un puesto dado -mediaEnPos() del HTML-.
func media_en_puesto(pe: String) -> int:
	if pe == "":
		return ovr
	return clampi(int(round(float(ovr_en_puesto(pe)) * aptitud_en(pe))), 20, 99)

## Reconversion permanente -reconvertir() del HTML-: cambia de puesto para
## siempre, recalcula la media EN el puesto nuevo (con una penalizacion de 1-3
## puntos si la aptitud no supera 0.9, igual que el original) y deja unas
## semanas de adaptacion. Vacio si el puesto no existe, ya es el suyo, o cruza
## la frontera portero/jugador de campo -esa reconversion no existe ni en el
## HTML-. Devuelve el antes/despues para el aviso de la interfaz.
func reconvertir(pe: String) -> Dictionary:
	var posd: Variant = Datos.tabla("POSD")
	if pe == pos_e or not (posd is Dictionary) or not (posd as Dictionary).has(pe):
		return {}
	var tabla: Dictionary = posd as Dictionary
	var d: Dictionary = tabla[pe]
	var n: Dictionary = tabla.get(pos_e, {})
	if (String(d.get("g", "")) == "POR") != (String(n.get("g", "")) == "POR"):
		return {}
	var antes := ovr
	if not pos_sec.has(pos_e):
		pos_sec.append(pos_e)
		if pos_sec.size() > 2:
			pos_sec.remove_at(0)
	var apt := aptitud_en(pe)
	pos_e = pe
	pos = String(d.get("g", pos))
	pos_sec.erase(pe)
	ovr = clampi(ovr_en_puesto(pe) - (0 if apt > 0.9 else Azar.ent(1, 3)), 20, 97)
	adapt = Azar.ent(3, 8)
	tasar()
	return {"antes": antes, "despues": ovr, "semanas": adapt}
