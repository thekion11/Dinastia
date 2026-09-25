class_name CatalogoJugadas
extends RefCounted
## Catálogo de 60 jugadas prehechas (documento técnico maestro).
##
## El núcleo SOLO describe la jugada: código, nombre y fases. El visor
## (`ReproductorJugadas` + `MatchPlayback`) la dramatiza. El resultado del
## partido sigue saliendo de `nucleo/partido.gd`.
##
## Coordenadas: las del visor real, NO las del documento (allí X era el largo).
## Aquí X = ancho (±34 m, banda a banda) y Z = largo (±52.5 m, arco a arco).
## El local ataca hacia -Z. Los impulsos del documento se remapearon.

const IDS_ATQ: Array[String] = [
	"ATQ-01", "ATQ-02", "ATQ-03", "ATQ-04", "ATQ-05",
	"ATQ-06", "ATQ-07", "ATQ-08", "ATQ-09", "ATQ-10",
	"ATQ-11", "ATQ-12", "ATQ-13", "ATQ-14", "ATQ-15",
]
const IDS_DEF: Array[String] = [
	"DEF-01", "DEF-02", "DEF-03", "DEF-04", "DEF-05",
	"DEF-06", "DEF-07", "DEF-08", "DEF-09", "DEF-10",
	"DEF-11", "DEF-12", "DEF-13", "DEF-14", "DEF-15",
]
const IDS_POR: Array[String] = [
	"POR-01", "POR-02", "POR-03", "POR-04", "POR-05",
	"POR-06", "POR-07", "POR-08", "POR-09", "POR-10",
	"POR-11", "POR-12", "POR-13", "POR-14", "POR-15",
]
const IDS_REG: Array[String] = [
	"REG-01", "REG-02", "REG-03", "REG-04", "REG-05",
	"REG-06", "REG-07", "REG-08", "REG-09", "REG-10",
	"REG-11", "REG-12", "REG-13", "REG-14", "REG-15",
]

const NOMBRES := {
	"ATQ-01": "Cutback por banda",
	"ATQ-02": "Tiki-taka del tercer hombre",
	"ATQ-03": "Desmarque de ruptura interior",
	"ATQ-04": "Pared frontal 1-2",
	"ATQ-05": "Cambio de orientación diagonal",
	"ATQ-06": "Centro tocado al segundo palo",
	"ATQ-07": "Conducción interior y tiro con rosca",
	"ATQ-08": "Contragolpe relámpago 3 vs 2",
	"ATQ-09": "Pivoteo de espaldas y remate",
	"ATQ-10": "Córner en corto y centro tenso",
	"ATQ-11": "Tiro libre lateral con bote pronto",
	"ATQ-12": "Pase de la muerte raso",
	"ATQ-13": "Volea de empeine tras despeje",
	"ATQ-14": "Desborde individual y tiro cruzado",
	"ATQ-15": "Vaselina / chip shot",
	"DEF-01": "Bloque bajo con basculación",
	"DEF-02": "Presión tras pérdida",
	"DEF-03": "Trampa del fuera de juego",
	"DEF-04": "Entrada deslizante limpia",
	"DEF-05": "Anticipación e intercepción",
	"DEF-06": "Temporización en 1 vs 1",
	"DEF-07": "Doble marca en vértice de banda",
	"DEF-08": "Despeje aéreo orientado",
	"DEF-09": "Falta táctica inteligente",
	"DEF-10": "Bloqueo de remate con el cuerpo",
	"DEF-11": "Cobertura cruzada por desborde",
	"DEF-12": "Sombra defensiva sobre el mediapunta",
	"DEF-13": "Duelo hombro con hombro",
	"DEF-14": "Presión asimétrica a pierna inhábil",
	"DEF-15": "Repliegue intensivo tras córner",
	"POR-01": "Parada a mano cambiada a la escuadra",
	"POR-02": "Blocaje en dos tiempos",
	"POR-03": "Despeje de puños en tráfico",
	"POR-04": "Achique en cruz (K-shape)",
	"POR-05": "Desvío con la bota a contrapié",
	"POR-06": "Estirada rápida al poste",
	"POR-07": "Captura aérea en el punto penal",
	"POR-08": "Saque de brazo tensor (jabalina)",
	"POR-09": "Saque largo de volea tensada",
	"POR-10": "Intervención de portero-líbero",
	"POR-11": "Parada refleja a quemarropa",
	"POR-12": "Despeje de emergencia ante cesión",
	"POR-13": "Palmada de salvamento sobre el larguero",
	"POR-14": "Parada de penal al poste",
	"POR-15": "Doble parada consecutiva",
	"REG-01": "Fuera de juego milimétrico",
	"REG-02": "Fuera de juego por interferencia visual",
	"REG-03": "Falta en salto aéreo",
	"REG-04": "Entrada a destiempo al tobillo",
	"REG-05": "Ley de la ventaja y regresión",
	"REG-06": "Penalti por derribo en mano a mano",
	"REG-07": "Penalti por mano separada en barrera",
	"REG-08": "Amarilla por cortar ataque (SPA)",
	"REG-09": "Roja por ocasión manifiesta (DOGSO)",
	"REG-10": "Falta por juego peligroso",
	"REG-11": "Fuera de juego en segunda jugada",
	"REG-12": "Fuera de juego pasivo habilitado",
	"REG-13": "Carga ilegal al portero",
	"REG-14": "Obstrucción sin balón",
	"REG-15": "Amonestación por pérdida de tiempo",
}

static func todos_los_ids() -> Array[String]:
	var out: Array[String] = []
	out.append_array(IDS_ATQ)
	out.append_array(IDS_DEF)
	out.append_array(IDS_POR)
	out.append_array(IDS_REG)
	return out

static func obtener_definicion(id: String) -> Dictionary:
	if not NOMBRES.has(id):
		return {}
	var familia := id.substr(0, 3)
	var n := int(id.substr(4, 2))
	var d := {
		"codigo": id,
		"nombre": String(NOMBRES[id]),
		"familia": familia,
		"fases": _fases_de(id, familia, n),
		"inicio": INICIOS.get(id, {}),
		"ambiente": AMBIENTE.has(id),
	}
	return d

## LAS JUGADAS QUE SE PUEDEN VER EN CUALQUIER RATO DEL PARTIDO (25-9-2026).
## Construcción, defensa y saques del portero: ninguna termina en remate ni en
## falta, así que se pueden escenificar entre sucesos sin inventar nada que la
## simulación no decidió. Los ataques se usan también, pero sin su fase final
## de remate (`ReproductorJugadas` la salta en modo ambiente).
const AMBIENTE := {
	"ATQ-02": true, "ATQ-03": true, "ATQ-04": true, "ATQ-05": true, "ATQ-06": true,
	"ATQ-08": true, "ATQ-09": true, "ATQ-12": true, "ATQ-14": true,
	"DEF-01": true, "DEF-02": true, "DEF-04": true, "DEF-05": true, "DEF-06": true,
	"DEF-07": true, "DEF-08": true, "DEF-10": true, "DEF-11": true, "DEF-12": true,
	"DEF-13": true, "DEF-14": true, "DEF-15": true,
	"POR-07": true, "POR-08": true, "POR-09": true, "POR-10": true, "POR-12": true,
}

static func ambientales() -> Array[String]:
	var out: Array[String] = []
	for k: String in AMBIENTE:
		out.append(k)
	return out

## Con quién empieza el balón: `rol` (a los pies de ese jugador) o `balon` (un
## punto del campo, cuando lo tiene el rival).
const INICIOS := {
	"ATQ-02": {"rol": "MC"}, "ATQ-03": {"rol": "MC"}, "ATQ-04": {"rol": "MC"}, "ATQ-05": {"rol": "LI"},
	"ATQ-06": {"rol": "ED"}, "ATQ-08": {"rol": "MC"}, "ATQ-09": {"rol": "DFC"}, "ATQ-10": {"balon": Vector3(33.0, 0, -52.0)},
	"ATQ-11": {"balon": Vector3(24.0, 0, -36.0)}, "ATQ-12": {"rol": "EI"}, "ATQ-13": {"balon": Vector3(2.0, 0, -44.0)},
	"ATQ-14": {"rol": "ED"},
	"DEF-01": {"balon": Vector3(18.0, 0, 20.0)}, "DEF-02": {"balon": Vector3(4.0, 0, -10.0)},
	"DEF-04": {"balon": Vector3(10.0, 0, 20.0)}, "DEF-05": {"balon": Vector3(-10.0, 0, 10.0)},
	"DEF-06": {"balon": Vector3(12.0, 0, 24.0)}, "DEF-07": {"balon": Vector3(28.0, 0, 26.0)},
	"DEF-08": {"balon": Vector3(24.0, 0, 40.0)}, "DEF-09": {"balon": Vector3(0.0, 0, -4.0)},
	"DEF-10": {"balon": Vector3(-6.0, 0, 30.0)}, "DEF-11": {"balon": Vector3(-24.0, 0, 26.0)},
	"DEF-12": {"balon": Vector3(4.0, 0, 6.0)}, "DEF-13": {"balon": Vector3(20.0, 0, 12.0)},
	"DEF-14": {"balon": Vector3(8.0, 0, -12.0)}, "DEF-15": {"balon": Vector3(30.0, 0, 48.0)},
	"POR-02": {"balon": Vector3(0.0, 0, 30.0)}, "POR-03": {"balon": Vector3(26.0, 0, 46.0)},
	"POR-04": {"balon": Vector3(2.0, 0, 30.0)}, "POR-05": {"balon": Vector3(-4.0, 0, 34.0)},
	"POR-06": {"balon": Vector3(4.0, 0, 38.0)}, "POR-07": {"balon": Vector3(24.0, 0, 40.0)},
	"POR-08": {"rol": "POR"}, "POR-09": {"rol": "POR"}, "POR-10": {"balon": Vector3(0.0, 0, 20.0)},
	"POR-11": {"balon": Vector3(0.0, 0, 44.0)}, "POR-12": {"rol": "DFC"}, "POR-13": {"balon": Vector3(-8.0, 0, 30.0)},
	"POR-14": {"balon": Vector3(0.0, 0, 41.5)}, "POR-15": {"balon": Vector3(3.0, 0, 38.0)},
}

## Una fase: cuánto dura, adónde corre cada rol y qué pasa con el balón -un
## pase al pie de otro rol (`pase_a`), un envío a un punto (`balon_a`), un
## remate a puerta (`remate`)- y qué gesto hace alguien (`accion`).
static func _f(dur: float, destinos: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var d := {"duracion": dur, "destinos": destinos, "es_peligro": bool(extra.get("remate", false))}
	for k: String in extra:
		d[k] = extra[k]
	return d

static func _fases_de(id: String, familia: String, n: int) -> Array:
	match id:
		"ATQ-01":
			return [
				{"duracion": 1.4, "es_peligro": false,
					"impulso_balon": Vector3(10.0, 0.3, -14.0), "spin_balon": Vector3(0.0, 8.0, 0.0),
					"destinos": {"ED": Vector3(22.0, 0, -28.0), "LD": Vector3(24.0, 0, -18.0),
						"DC": Vector3(6.0, 0, -36.0)}},
				{"duracion": 0.85, "es_peligro": true,
					"impulso_balon": Vector3(-16.0, 0.2, -7.0), "spin_balon": Vector3(0.0, -4.0, 0.0),
					"destinos": {"ED": Vector3(23.0, 0, -40.0), "LD": Vector3(25.0, 0, -38.0),
						"DC": Vector3(2.0, 0, -44.0)}},
				{"duracion": 0.7, "es_peligro": true,
					"impulso_balon": Vector3(-3.0, 5.4, -15.0), "spin_balon": Vector3(0.0, 14.0, 2.0),
					"destinos": {"DC": Vector3(1.5, 0, -47.0)}},
			]
		"ATQ-02":
			return [
				_f(1.0, {"DC": Vector3(2, 0, -22), "ED": Vector3(14, 0, -24)}, {"pase_a": "DC"}),
				_f(0.9, {"MC": Vector3(4, 0, -20)}, {"pase_a": "MC"}),
				_f(1.2, {"ED": Vector3(18, 0, -38), "DC": Vector3(0, 0, -40)}, {"pase_a": "ED", "altura": 0.1}),
				_f(0.8, {"ED": Vector3(15, 0, -44)}, {"remate": true}),
			]
		"ATQ-03":
			return [
				_f(1.0, {"DC": Vector3(-6, 0, -32), "EI": Vector3(-16, 0, -26)}),
				_f(1.1, {"DC": Vector3(-5, 0, -41)}, {"pase_a": "DC", "altura": 0.1}),
				_f(0.8, {}, {"remate": true}),
			]
		"ATQ-04":
			return [
				_f(0.8, {"DC": Vector3(4, 0, -26)}, {"pase_a": "DC"}),
				_f(0.9, {"MC": Vector3(3, 0, -35)}, {"pase_a": "MC"}),
				_f(0.8, {}, {"remate": true}),
			]
		"ATQ-05":
			return [
				_f(1.6, {"ED": Vector3(26, 0, -26)}, {"pase_a": "ED", "altura": 4.0}),
				_f(1.0, {"ED": Vector3(24, 0, -36), "DC": Vector3(4, 0, -40)}),
				_f(0.8, {"DC": Vector3(2, 0, -43)}, {"pase_a": "DC", "altura": 0.15}),
				_f(0.8, {}, {"remate": true}),
			]
		"ATQ-06":
			return [
				_f(1.0, {"DC": Vector3(-3, 0, -44), "EI": Vector3(-10, 0, -42)}),
				_f(1.1, {"EI": Vector3(-9, 0, -45)}, {"pase_a": "EI", "altura": 3.2}),
				_f(0.8, {}, {"remate": true, "cabeza": true}),
			]
		"ATQ-07":
			return [
				{"duracion": 1.1, "es_peligro": false,
					"impulso_balon": Vector3(-9.0, 0.4, -11.0), "spin_balon": Vector3(0.0, -10.0, 0.0),
					"destinos": {"EI": Vector3(-18.0, 0, -30.0)}},
				{"duracion": 0.9, "es_peligro": true,
					"impulso_balon": Vector3(6.0, 7.2, -18.0), "spin_balon": Vector3(2.0, 22.0, 0.0),
					"destinos": {"EI": Vector3(-11.0, 0, -38.0)}},
			]
		"ATQ-08":
			return [
				_f(1.2, {"ED": Vector3(18, 0, -10), "EI": Vector3(-18, 0, -10), "DC": Vector3(0, 0, -6)}, {"pase_a": "ED", "altura": 0.2}),
				_f(1.3, {"ED": Vector3(20, 0, -30), "DC": Vector3(2, 0, -32), "EI": Vector3(-14, 0, -30)}),
				_f(0.8, {"DC": Vector3(1, 0, -40)}, {"pase_a": "DC"}),
				_f(0.8, {}, {"remate": true}),
			]
		"ATQ-09":
			return [
				_f(1.4, {"DC": Vector3(0, 0, -30), "MC": Vector3(4, 0, -22)}, {"pase_a": "DC", "altura": 2.6}),
				_f(0.8, {"MC": Vector3(3, 0, -26)}, {"pase_a": "MC"}),
				_f(0.8, {}, {"remate": true}),
			]
		"ATQ-10":
			return [
				_f(0.7, {"MC": Vector3(26, 0, -46), "ED": Vector3(32, 0, -51)}, {"pase_a": "MC"}),
				_f(0.8, {"MC": Vector3(24, 0, -42), "DC": Vector3(2, 0, -45)}),
				_f(0.9, {"DC": Vector3(1, 0, -46)}, {"pase_a": "DC", "altura": 1.4}),
				_f(0.8, {}, {"remate": true, "cabeza": true}),
			]
		"ATQ-11":
			return [
				_f(1.0, {"DC": Vector3(-2, 0, -46), "DFC": Vector3(3, 0, -45)}),
				_f(1.0, {"DFC": Vector3(2, 0, -46)}, {"pase_a": "DFC", "altura": 2.8}),
				_f(0.8, {}, {"remate": true}),
			]
		"ATQ-12":
			return [
				_f(1.2, {"EI": Vector3(-14, 0, -47), "DC": Vector3(0, 0, -42)}),
				_f(0.7, {"DC": Vector3(1, 0, -43)}, {"pase_a": "DC", "altura": 0.05}),
				_f(0.7, {}, {"remate": true}),
			]
		"ATQ-13":
			return [
				_f(1.2, {"MC": Vector3(0, 0, -34)}, {"pase_a": "MC", "altura": 3.0}),
				_f(0.8, {}, {"remate": true}),
			]
		"ATQ-14":
			return [
				_f(1.3, {"ED": Vector3(17, 0, -40)}),
				_f(0.9, {"ED": Vector3(14, 0, -43)}),
				_f(0.8, {}, {"remate": true}),
			]
		"ATQ-15":
			return [
				{"duracion": 0.8, "es_peligro": true,
					"impulso_balon": Vector3(1.0, 9.5, -11.0), "spin_balon": Vector3(8.0, 0.0, 0.0),
					"destinos": {"DC": Vector3(2.0, 0, -44.0), "POR": Vector3(0.0, 0, 46.0)}},
			]
		"DEF-01":
			return [
				_f(1.5, {"DFC": Vector3(6, 0, 36), "LD": Vector3(16, 0, 33), "LI": Vector3(-6, 0, 36), "MC": Vector3(8, 0, 26)}, {"balon_a": Vector3(-16, 0, 22), "altura": 0.2}),
				_f(1.5, {"DFC": Vector3(-4, 0, 36), "LD": Vector3(6, 0, 36), "LI": Vector3(-16, 0, 33), "MC": Vector3(-8, 0, 26)}),
			]
		"DEF-02":
			return [
				_f(1.2, {"MC": Vector3(4, 0, -9), "ED": Vector3(8, 0, -12), "DC": Vector3(2, 0, -14)}, {"accion": {"MC": "marcar"}}),
				_f(0.9, {}, {"pase_a": "ED"}),
			]
		"DEF-03":
			return [
				{"duracion": 0.9, "es_peligro": false,
					"impulso_balon": Vector3(3.0, 0.2, 10.0),
					"destinos": {"DFC": Vector3(0.0, 0, -8.0), "LD": Vector3(16.0, 0, -6.0),
						"LI": Vector3(-16.0, 0, -6.0)}},
			]
		"DEF-04":
			return [
				_f(0.9, {"LD": Vector3(10, 0, 21)}),
				_f(1.2, {}, {"accion": {"LD": "falta_barrida"}, "balon_a": Vector3(15, 0, 27), "altura": 0.1}),
			]
		"DEF-05":
			return [
				_f(0.9, {"MC": Vector3(-3, 0, 15)}, {"balon_a": Vector3(-3, 0, 15.5), "altura": 0.1}),
				_f(1.3, {"ED": Vector3(18, 0, -4)}, {"pase_a": "ED", "altura": 0.3}),
			]
		"DEF-06":
			return [
				_f(1.6, {"LD": Vector3(12, 0, 28)}, {"accion": {"LD": "marcar"}}),
				_f(1.2, {"LD": Vector3(13, 0, 31)}, {"accion": {"LD": "marcar"}, "balon_a": Vector3(15, 0, 30), "altura": 0.05}),
			]
		"DEF-07":
			return [
				_f(1.5, {"LD": Vector3(27, 0, 28), "MC": Vector3(24, 0, 24)}, {"accion": {"LD": "marcar", "MC": "marcar"}}),
				_f(0.8, {}, {"pase_a": "MC"}),
			]
		"DEF-08":
			return [
				_f(1.0, {"DFC": Vector3(0, 0, 42)}, {"balon_a": Vector3(0, 0, 42), "altura": 3.0}),
				_f(1.9, {"ED": Vector3(22, 0, 6)}, {"pase_a": "ED", "altura": 7.0}),
			]
		"DEF-09":
			return [
				_f(0.8, {"MC": Vector3(1, 0, -3)}),
				_f(1.2, {}, {"accion": {"MC": "falta_empujon"}}),
			]
		"DEF-10":
			return [
				_f(0.7, {"DFC": Vector3(-5, 0, 34)}),
				_f(0.5, {}, {"balon_a": Vector3(-5, 0, 34.5), "altura": 0.3}),
				_f(1.0, {"LI": Vector3(-20, 0, 26)}, {"pase_a": "LI"}),
			]
		"DEF-11":
			return [
				_f(1.3, {"DFC": Vector3(-16, 0, 34), "LI": Vector3(-22, 0, 30)}),
				_f(0.8, {}, {"balon_a": Vector3(-17, 0, 35), "altura": 0.2}),
				_f(1.1, {"MC": Vector3(-8, 0, 22)}, {"pase_a": "MC", "altura": 0.4}),
			]
		"DEF-12":
			return [
				_f(1.6, {"MC": Vector3(0, 0, 18), "DFC": Vector3(0, 0, 26)}, {"accion": {"MC": "marcar"}, "balon_a": Vector3(-6, 0, 8), "altura": 0.1}),
				_f(1.2, {"MC": Vector3(-5, 0, 17)}, {"accion": {"MC": "marcar"}}),
			]
		"DEF-13":
			return [
				_f(1.2, {"LD": Vector3(20, 0, 13)}, {"accion": {"LD": "falta_empujon"}}),
				_f(1.0, {"MC": Vector3(10, 0, 8)}, {"pase_a": "MC"}),
			]
		"DEF-14":
			return [
				_f(1.4, {"ED": Vector3(10, 0, -14), "MC": Vector3(4, 0, -8), "DC": Vector3(-4, 0, -16)}, {"balon_a": Vector3(-6, 0, -6), "altura": 0.1}),
				_f(1.2, {"ED": Vector3(2, 0, -10), "MC": Vector3(-4, 0, -6), "DC": Vector3(-8, 0, -12)}),
			]
		"DEF-15":
			return [
				_f(2.0, {"DFC": Vector3(0, 0, 40), "LD": Vector3(12, 0, 38), "LI": Vector3(-12, 0, 38), "MC": Vector3(0, 0, 30),
					"ED": Vector3(16, 0, 20), "EI": Vector3(-16, 0, 20)}, {"balon_a": Vector3(0, 0, 10), "altura": 6.0}),
			]
		"POR-01":
			return [
				{"duracion": 0.7, "es_peligro": true,
					"impulso_balon": Vector3(4.5, 8.0, 16.0), "spin_balon": Vector3(0.0, -8.0, 0.0),
					"destinos": {"POR": Vector3(0.0, 0, 50.5)}},
			]
		"POR-02":
			return [
				_f(0.9, {"POR": Vector3(0, 0, 50.5)}, {"balon_a": Vector3(1, 0, 50.8), "altura": 0.6, "accion": {"POR": "atajar_bajo"}}),
				_f(1.2, {"DFC": Vector3(6, 0, 40)}, {"pase_a": "DFC"}),
			]
		"POR-03":
			return [
				_f(1.0, {"POR": Vector3(0, 0, 48)}, {"balon_a": Vector3(0, 0, 48), "altura": 3.0}),
				_f(1.0, {}, {"balon_a": Vector3(4, 0, 30), "altura": 4.0}),
			]
		"POR-04":
			return [
				_f(0.9, {"POR": Vector3(1, 0, 44)}, {"balon_a": Vector3(1, 0, 44.5), "altura": 0.1, "accion": {"POR": "atajar_bajo"}}),
				_f(1.1, {"DFC": Vector3(8, 0, 38)}, {"pase_a": "DFC"}),
			]
		"POR-05":
			return [
				_f(0.6, {}, {"balon_a": Vector3(-2, 0, 51), "altura": 0.2, "accion": {"POR": "atajar_izq"}}),
				_f(0.6, {}, {"balon_a": Vector3(-10, 0, 54), "altura": 0.2}),
			]
		"POR-06":
			return [
				_f(0.7, {}, {"balon_a": Vector3(3.2, 0, 52), "altura": 0.8, "accion": {"POR": "atajar_der"}}),
				_f(0.5, {}, {"balon_a": Vector3(6, 0, 54), "altura": 0.3}),
			]
		"POR-07":
			return [
				_f(1.1, {"POR": Vector3(0, 0, 45.5)}, {"balon_a": Vector3(0, 0, 45), "altura": 4.0}),
				_f(1.7, {"ED": Vector3(22, 0, 10)}, {"pase_a": "ED", "altura": 1.6, "gesto": "saque_banda"}),
			]
		"POR-08":
			return [
				_f(1.0, {"ED": Vector3(24, 0, 14)}),
				_f(1.6, {}, {"pase_a": "ED", "altura": 1.8, "gesto": "saque_banda"}),
			]
		"POR-09":
			return [
				_f(1.0, {"DC": Vector3(0, 0, -6), "ED": Vector3(18, 0, -2)}),
				_f(2.6, {}, {"pase_a": "DC", "altura": 12.0}),
			]
		"POR-10":
			return [
				_f(1.2, {"POR": Vector3(2, 0, 33)}, {"balon_a": Vector3(2, 0, 34), "altura": 0.2}),
				_f(1.2, {"LD": Vector3(20, 0, 24)}, {"pase_a": "LD"}),
			]
		"POR-11":
			return [
				_f(0.45, {}, {"balon_a": Vector3(0.5, 0, 51.5), "altura": 1.4, "accion": {"POR": "atajar_der"}}),
				_f(0.8, {}, {"balon_a": Vector3(-6, 0, 44), "altura": 0.5}),
			]
		"POR-12":
			return [
				_f(1.0, {"POR": Vector3(0, 0, 47)}, {"pase_a": "POR"}),
				_f(2.2, {"ED": Vector3(26, 0, 0)}, {"pase_a": "ED", "altura": 8.0}),
			]
		"POR-13":
			return [
				_f(0.8, {}, {"balon_a": Vector3(0, 0, 52), "altura": 2.4, "accion": {"POR": "atajar_izq"}}),
				_f(0.5, {}, {"balon_a": Vector3(0, 0, 55), "altura": 3.0}),
			]
		"POR-14":
			return [
				_f(0.55, {}, {"balon_a": Vector3(3.4, 0, 52.4), "altura": 0.4, "accion": {"POR": "atajar_der"}}),
				_f(0.6, {}, {"balon_a": Vector3(8, 0, 56), "altura": 0.2}),
			]
		"POR-15":
			return [
				_f(0.5, {}, {"balon_a": Vector3(2, 0, 52), "altura": 0.6, "accion": {"POR": "atajar_der"}}),
				_f(0.5, {}, {"balon_a": Vector3(-3, 0, 48), "altura": 0.3}),
				_f(0.6, {}, {"balon_a": Vector3(-2.8, 0, 52), "altura": 0.5, "accion": {"POR": "atajar_izq"}}),
			]
		"REG-01":
			return [
				{"duracion": 1.0, "es_peligro": true,
					"impulso_balon": Vector3(2.0, 0.5, -18.0),
					"destinos": {"DC": Vector3(3.0, 0, -48.0), "DFC": Vector3(2.0, 0, -46.5)}},
			]
	## El reglamento: son escenas para ilustrar una norma (la ficha del
	## glosario), no se mezclan con el partido. Plantilla simple.
	var lado: float = 1.0 if (n % 2) == 0 else -1.0
	return [
		{"duracion": 1.05, "es_peligro": n <= 7,
			"impulso_balon": Vector3(lado * 4.0, 0.6, -9.0),
			"spin_balon": Vector3(0.0, lado * 4.0, 0.0)},
	]
