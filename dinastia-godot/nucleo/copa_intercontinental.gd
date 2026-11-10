class_name CopaIntercontinental
extends Continental
## LA COPA INTERCONTINENTAL (sesión 6, 10-11), en el molde de la FIFA: el campeón de Asia y el de África juegan la Challenger
## Cup; el de la Libertadores y el de Concacaf, el Derbi de las Américas; los dos ganadores se ven en una semifinal y el
## ganador juega la final contra el campeón de Europa, que espera. Todo a partido único.
##
## La lista llega en ese orden —Asia, África, América del Sur, Concacaf y, al final, Europa— porque `Continental` pasa sin
## jugar al último cuando sobra uno (un «bye»), y eso es justo lo que le pasa a Europa dos veces seguidas.

const PREMIO_CAMPEON := 900000

func _init(nombre_torneo: String = "Copa Intercontinental") -> void:
	super(nombre_torneo)
	clave = "interc"
	premio = PREMIO_CAMPEON

func preparar(clubes: Array[Club]) -> void:
	preparar_con(clubes, FormatosConti.BYES)
