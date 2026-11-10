class_name MundialClubes
extends Continental
## EL MUNDIAL DE CLUBES (sesión 6, 10-11): 32 clubes en 8 grupos de 4 a una vuelta; los dos primeros pasan a octavos y de
## ahí todo a partido único (la final, en cancha neutral). Lo juegan los campeones continentales del año anterior más los
## mejor clasificados de cada confederación (`FifaClubes`): se juega en las primeras semanas de la temporada, y si tu club
## participa, dirigirás sus partidos en directo igual que los de cualquier otro continental (`ya_jugado`).
##
## Con menos clubes de los previstos (un mundo de pocos países) se achica solo: 16 (4 grupos), 8 (2 grupos) o, con menos
## de 8, eliminación directa con «byes» (sembrada: el cabeza de serie contra el más débil). Eso es todo lo que hacía el
## Mundial de Clubes de antes, que sigue funcionando igual con sus seis campeones.

## El premio del HTML: una cifra FIJA como todas las de este juego, que no se escala al tamaño del club. 1.800.000 le
## cambian la década a un campeón de Oceanía y a uno de Europa le vienen bien. Esa asimetría es el punto.
const PREMIO_CAMPEON := 1800000

func _init(nombre_torneo: String = "Mundial de Clubes") -> void:
	super(nombre_torneo)
	clave = "mundial"
	premio = PREMIO_CAMPEON

## Monta el torneo con estos clubes en el formato que les quepa. Los grupos se sortean por BOMBOS de reputación: cada grupo
## recibe un club de cada bombo (el orden de llegada es el reparto de grupos de `Continental`: «uno para cada grupo por turnos»).
func preparar(clubes: Array[Club]) -> void:
	var n := clubes.size()
	var por_rep: Array[Club] = clubes.duplicate()
	por_rep.sort_custom(PlazasConti.mas_reputado)
	if n < 8:
		## Sembrado de eliminación directa: el mejor contra el peor, el segundo contra el penúltimo… y el que sobra, al final.
		var orden: Array[Club] = []
		var i := 0
		var j := por_rep.size() - 1
		while i <= j:
			orden.append(por_rep[i])
			if i != j:
				orden.append(por_rep[j])
			i += 1
			j -= 1
		preparar_con(orden, FormatosConti.BYES)
		return
	var id := "mundial" if n >= 32 else ("mundial16" if n >= 16 else "mundial8")
	var total := FormatosConti.plazas(id)
	var grupos_n := total / 4
	var sorteo: Array[Club] = []
	for bombo in 4:
		var b: Array = por_rep.slice(bombo * grupos_n, (bombo + 1) * grupos_n)
		Azar.barajar(b)
		for c: Club in b:
			sorteo.append(c)
	preparar_con(sorteo, id)
