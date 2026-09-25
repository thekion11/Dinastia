class_name Staff
extends RefCounted
## El cuerpo técnico: seis puestos que se contratan y se pagan.
##
## Cada uno hace UNA cosa concreta y medible, y esa es la regla: si contratar a
## alguien no se nota en un número que el jugador pueda ver, es un botón de
## gastar dinero. En el HTML esto ya pasó varias veces —menús preciosos que no
## tocaban nada— y por eso aquí cada nivel entra por la puerta que ya existía:
## `Club.bonus_ataque` y `Club.bonus_defensa`, que el motor de partido lee desde
## el primer día.
##
## Los niveles van de 0 a 5. El coste crece más rápido que el efecto, para que
## llenar los seis puestos al máximo no sea la jugada obvia del primer año.

signal contratado(puesto: String, nivel: int, coste: int)

## puesto -> [nombre, qué hace, sueldo semanal base]
const PUESTOS := {
	"ayudante":  ["Ayudante de campo", "Mejora el ataque del equipo", 9000],
	"defensa":   ["Preparador defensivo", "Mejora la defensa del equipo", 9000],
	"fisico":    ["Preparador físico", "El plantel pierde menos forma cada semana", 8000],
	"medico":    ["Jefe médico", "Las lesiones duran menos", 11000],
	"ojeador":   ["Jefe de ojeadores", "Descubre el potencial real de jugadores jóvenes", 7000],
	"cantera":   ["Director de cantera", "Los canteranos suben con mejor techo", 7000],
	## El psicólogo llegó con la charla del entretiempo (`Vestuario.charla()`).
	## No toca ataque ni defensa: lo que hace es que el mensaje del entretiempo
	## cale mejor, sea cual sea el tono. Es barato a propósito -es el puesto que
	## menos se nota si nunca dirigís un partido en vivo.
	"psi":       ["Psicólogo deportivo", "Tus charlas del entretiempo calan mejor", 6000],
	## LOS SEIS QUE PEDÍAN LAS IDEAS 91-105 y no estaban. Cada uno hace UNA cosa
	## y se nota en un sitio distinto: si dos hicieran lo mismo, contratar sería
	## elegir el más barato y no habría decisión.
	"arqueros":  ["Entrenador de arqueros", "Tu portero para más y encaja menos", 6500],
	"nutri":     ["Nutricionista", "El plantel recupera físico más rápido cada semana", 5500],
	"seg":       ["Jefe de seguridad", "Menos riesgo de incidentes en tu estadio", 6000],
	"traductor": ["Traductor del club", "Los extranjeros se adaptan sin hundirse de moral", 4500],
	"cm":        ["Community manager", "El club gana seguidores todas las semanas", 4000],
	"utilero":   ["Utilero", "Pequeño empujón de moral: el vestuario funciona", 3000],
}
const NIVEL_MAX := 5

var niveles: Dictionary = {}

func _init() -> void:
	for k: String in PUESTOS:
		niveles[k] = 0

func nivel(puesto: String) -> int:
	return int(niveles.get(puesto, 0))

## Lo que cuesta subir un puesto un nivel. Crece con el cuadrado del nivel: el
## primer ayudante es barato, el quinto es una decisión.
func coste_subir(puesto: String, rep_club: int) -> int:
	var n := nivel(puesto) + 1
	if n > NIVEL_MAX:
		return -1
	var base: float = float(PUESTOS[puesto][2]) * float(n * n)
	return Eco.escalar(base * 6.0, float(rep_club))

func subir(puesto: String, c: Club) -> String:
	if not PUESTOS.has(puesto):
		return "ese puesto no existe"
	if nivel(puesto) >= NIVEL_MAX:
		return "ya está al máximo"
	var coste := coste_subir(puesto, c.rep)
	if coste > c.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [coste, c.saldo]
	c.mover_saldo(-coste)
	niveles[puesto] = nivel(puesto) + 1
	aplicar(c)
	contratado.emit(puesto, nivel(puesto), coste)
	return ""

## "for(const k in G.staff)if(G.staff[k]>0&&RF()<0.5)G.staff[k]=Math.max(0,G.staff[k]-1)"
## del HTML: la ocupación hostil de un dueño nuevo se lleva gente de tu cuerpo
## técnico al azar, puesto por puesto. Cada puesto con nivel tiene un 50% de
## perder un escalón -no arrasa con todo a la vez, que sería un reseteo total-.
func purgar_al_azar(c: Club) -> void:
	for k: String in PUESTOS:
		if nivel(k) > 0 and Azar.suerte(0.5):
			niveles[k] = nivel(k) - 1
	aplicar(c)

## El sueldo semanal del cuerpo técnico entero. Se paga con el resto, y por eso
## un staff grande aprieta la caja todos los meses, no solo el día que se ficha.
## `bonoStaff()` del HTML: una prima al cuerpo técnico, una vez por temporada.
## Sube la moral de TODO el plantel, y sube más cuanto mejor vayas: premiar a
## la gente cuando el equipo va primero es una fiesta; hacerlo yendo último se
## agradece pero no cambia el ambiente.
var anio_bono := 0

func escalones_contratados() -> int:
	var n := 0
	for k: String in niveles:
		n += int(niveles[k])
	return n

func coste_bono(rep_club: int) -> int:
	return maxi(Eco.escalar(120000, rep_club), sueldo_semanal(rep_club) * 6)

func repartir_bono(c: Club, anio: int, puesto: int, equipos: int) -> Dictionary:
	if escalones_contratados() == 0:
		return {"error": "todavía no tienes cuerpo técnico al que premiar"}
	if anio_bono == anio:
		return {"error": "el bono de este año ya está repartido"}
	var coste := coste_bono(c.rep)
	if c.saldo < coste:
		return {"error": "caja insuficiente: hacen falta %d" % coste}
	c.mover_saldo(-coste)
	anio_bono = anio
	var sube := 2
	if puesto <= 1:
		sube = 5
	elif puesto <= 3:
		sube = 4
	elif puesto <= int(ceil(float(equipos) / 2.0)):
		sube = 3
	for j in c.plantilla:
		j.moral = clampi(j.moral + sube, 10, 99)
	return {"ok": true, "coste": coste, "moral": sube, "escalones": escalones_contratados()}

## EL DESCUENTO DEL CONTABLE viene de fuera: `Staff` no conoce el arbol del
## entrenador. `Entrenamiento.factor_sueldo_staff()` llevaba meses devolviendo un
## 0,85 que no leia nadie, asi que gastar un punto en «Contable» no ahorraba nada.
var factor_sueldos: float = 1.0

func sueldo_semanal(rep_club: int) -> int:
	var s := 0
	for k: String in PUESTOS:
		if nivel(k) > 0:
			s += Eco.escalar(float(PUESTOS[k][2]) * float(nivel(k)), float(rep_club))
	return int(round(float(s) * factor_sueldos))

## Vuelca los niveles en los dos bonificadores que lee el motor de partido.
##
## Se llama al contratar y al cargar una partida. Se escribe SIEMPRE el valor
## completo, no se acumula sobre lo que hubiera: acumulando, cargar dos veces la
## misma partida dejaba el equipo con el doble de bonificación.
func aplicar(c: Club) -> void:
	c.bonus_ataque = 1.0 + 0.015 * float(nivel("ayudante"))
	c.bonus_defensa = 1.0 + 0.015 * float(nivel("defensa")) + bono_portero()

## Cuánta forma menos se pierde por semana gracias al preparador físico.
func aguante() -> int:
	return nivel("fisico")

## Semanas que se le quitan a una lesión gracias al jefe médico. Nunca la deja en
## cero: un cinco de médico acelera, no cura por decreto.
func descuento_lesion(semanas: int) -> int:
	return maxi(1, semanas - nivel("medico"))

## Probabilidad semanal de que el ojeador traiga un informe.
func ojo() -> float:
	return 0.10 * float(nivel("ojeador"))

## Cuánto techo extra tienen los canteranos que suben.
func techo_cantera() -> int:
	return nivel("cantera")

## Lo que el entrenador de arqueros le suma al portero. Va a la DEFENSA del
## equipo y no a los atributos del jugador: el portero es el unico puesto donde
## el entrenador especialista se nota en el resultado y no en la ficha.
func bono_portero() -> float:
	return 0.012 * float(nivel("arqueros"))

## Fisico que recupera de mas el plantel cada semana por el nutricionista.
func recuperacion_fisica() -> int:
	return nivel("nutri")

## Cuanto baja el riesgo de incidente el jefe de seguridad. Es el `G.staff.seg`
## del HTML, que `riesgo_incidente()` ya restaba y que aqui no existia.
func bono_seguridad() -> float:
	return 0.010 * float(nivel("seg"))

## Cuanto amortigua el traductor el bajon de moral de un extranjero recien
## llegado. Con un traductor de nivel 3 casi no se nota el cambio de pais.
func adaptacion_extranjeros() -> float:
	return clampf(1.0 - 0.22 * float(nivel("traductor")), 0.2, 1.0)

## Seguidores que suma el community manager cada semana, en tanto por uno.
func empuje_redes() -> float:
	return 0.004 * float(nivel("cm"))

## El empujon de moral del utilero. Es pequeño a proposito: es el puesto barato
## que se contrata cuando ya esta todo lo demas.
func bono_utilero() -> int:
	return 1 if nivel("utilero") >= 3 else 0

func a_dic() -> Dictionary:
	var d := niveles.duplicate()
	## El año del último bono viaja con los niveles, en la misma bolsa. Sin
	## esto, guardar y cargar dejaba repartir el bono dos veces el mismo año.
	d["_anio_bono"] = anio_bono
	return d

func desde_dic(d: Dictionary) -> void:
	anio_bono = int(d.get("_anio_bono", 0))
	for k: String in PUESTOS:
		niveles[k] = int(d.get(k, 0))
