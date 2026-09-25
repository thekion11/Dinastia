class_name Regiones
extends RefCounted
## REGIONES DE ORIGEN Y CLUBES CON FILOSOFÍA DE CANTERA (26-9-2026, plan maestro C3).
##
## Pedido: *"el Athletic Club de Bilbao solo ficha jugadores de la ciudad de
## Bilbao, eso debe integrarse en el mercado, y el Bilbao depende de la cantera y
## usa apellidos de los canteranos según su nacionalidad"*.
##
## LA REGLA REAL. El Athletic no ficha solo a gente de la ciudad de Bilbao: ficha
## a jugadores nacidos o formados en EUSKAL HERRIA -País Vasco, Navarra y el País
## Vasco francés-. Esa es la que se implementa.
##
## LO QUE HABÍA ANTES (22-9) Y SE CORRIGE. Como `Jugador` no tenía región, la
## regla se aproximaba por "mismo país": el Athletic podía fichar a cualquier
## español. Y para dar "sabor vasco" se llenó la bolsa de nombres de España con
## apellidos vascos -13 de 18-, así que casi TODOS los españoles del juego eran
## Etxeberria o Agirre, que es otra incoherencia. Ahora:
##   - `Jugador.region` existe ("EUS" o vacío) y se guarda con la partida;
##   - un ~9 % de los españoles nace en Euskal Herria (por hash, sin `Azar`);
##   - los apellidos salen de la bolsa que toca: española general o vasca;
##   - el Athletic (y su equivalente de la base ficticia, "Abando AC": Abando es
##     un barrio de Bilbao) solo ficha a quien cumple la regla, la IA y tú;
##   - su cantera es toda de allí y rinde más: es de lo que vive.

## nombre limpio del club -> {pais, region}
const CLUBES_CANTERA := {
	"Ath. Bilbao": {"pais": "ESP", "region": "EUS"},
	"Abando AC": {"pais": "ESP", "region": "EUS"},
}
const NOMBRE_REGION := {"EUS": "Euskal Herria"}
## Cuántos de cada 100 españoles nacen en Euskal Herria (≈ su peso de población).
const PCT_VASCOS := 9

const NOMBRES_ESP := ["Pablo", "Sergio", "Álvaro", "Hugo", "Mario", "Daniel", "Adrián", "Javier",
	"Carlos", "Alejandro", "David", "Raúl", "Rubén", "Marcos", "Iván", "Diego", "Jorge", "Pedro",
	"Manuel", "Antonio", "Pau", "Marc", "Gonzalo", "Nacho", "Álex", "Víctor", "Óscar", "Samuel",
	"Rodrigo", "Martín", "Lucas", "Héctor", "Andrés", "Fermín", "Borja", "Aleix"]
const APELLIDOS_ESP := ["García", "Fernández", "González", "Rodríguez", "López", "Martínez",
	"Sánchez", "Pérez", "Gómez", "Martín", "Jiménez", "Ruiz", "Hernández", "Díaz", "Moreno",
	"Muñoz", "Álvarez", "Romero", "Alonso", "Gutiérrez", "Navarro", "Torres", "Domínguez",
	"Vázquez", "Ramos", "Gil", "Ramírez", "Serrano", "Blanco", "Molina", "Morales", "Suárez",
	"Ortega", "Delgado", "Castro", "Ortiz", "Rubio", "Marín", "Sanz", "Iglesias", "Medina",
	"Garrido", "Cortés", "Castillo", "Santos", "Lozano", "Guerrero", "Cano", "Prieto", "Méndez",
	"Calvo", "Gallego", "Vidal", "Pascual", "Herrero", "Soler", "Vicente", "Montero"]
const NOMBRES_EUS := ["Iker", "Unai", "Aitor", "Xabi", "Mikel", "Jon", "Ander", "Asier", "Gorka",
	"Iñigo", "Oier", "Julen", "Ibai", "Eneko", "Beñat", "Ekain", "Aimar", "Oihan", "Urko", "Iñaki",
	"Koldo", "Endika", "Markel", "Unax", "Peio", "Josu", "Aritz", "Xabier"]
const APELLIDOS_EUS := ["Etxeberria", "Olabarria", "Ibarguren", "Larrazabal", "Urrutia", "Elorza",
	"Agirre", "Mendizabal", "Uriarte", "Garmendia", "Azkona", "Arrieta", "Goikoetxea", "Aranburu",
	"Larrañaga", "Otxoa", "Bengoetxea", "Iturbe", "Zabala", "Arregi", "Lasa", "Eizagirre",
	"Olaizola", "Etxebarria", "Uribe", "Gorostiza", "Arana", "Beitia", "Egaña", "Urkiza",
	"Ansotegi", "Zubiaurre", "Oiarzabal", "Irazusta", "Amorebieta", "Lekue"]

## La filosofía de este club, o vacío si ficha a quien quiera.
static func filosofia(c: Club) -> Dictionary:
	if c == null:
		return {}
	return CLUBES_CANTERA.get(Nombres.limpiar(c.nombre), {})

## ¿Puede este club fichar a este jugador?
static func admite(c: Club, j: Jugador) -> bool:
	var f := filosofia(c)
	if f.is_empty() or j == null:
		return true
	## La región, NO la nacionalidad: cuenta dónde nació o se formó. Un chico
	## nacido en Bilbao que juega con otra selección (el caso real de más de un
	## jugador del Athletic) sí entra; un español de otra región, no.
	return j.region == String(f["region"])

## El motivo, para enseñarlo cuando no se puede.
static func motivo(c: Club) -> String:
	var f := filosofia(c)
	if f.is_empty():
		return ""
	return "la filosofía del club solo admite jugadores nacidos o formados en %s" % String(NOMBRE_REGION.get(String(f["region"]), String(f["region"])))

## La región de un jugador que nace ahora. Los de un club de cantera, de su
## tierra; los españoles, vascos en su proporción; el resto, sin región.
static func region_para(pais: String, id: String, club: Club = null) -> String:
	var f := filosofia(club)
	if not f.is_empty():
		return String(f["region"])
	if pais == "ESP" and absi(("reg" + id).hash()) % 100 < PCT_VASCOS:
		return "EUS"
	return ""

## Las bolsas de nombre de un país y región, o vacío si no hay propias.
static func bolsas(pais: String, region: String) -> Array:
	if pais != "ESP":
		return []
	if region == "EUS":
		return [NOMBRES_EUS, APELLIDOS_EUS]
	return [NOMBRES_ESP, APELLIDOS_ESP]
