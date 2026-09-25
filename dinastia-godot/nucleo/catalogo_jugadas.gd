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
	return {
		"codigo": id,
		"nombre": String(NOMBRES[id]),
		"familia": familia,
		"fases": _fases_de(id, familia, n),
	}

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
		"ATQ-07":
			return [
				{"duracion": 1.1, "es_peligro": false,
					"impulso_balon": Vector3(-9.0, 0.4, -11.0), "spin_balon": Vector3(0.0, -10.0, 0.0),
					"destinos": {"EI": Vector3(-18.0, 0, -30.0)}},
				{"duracion": 0.9, "es_peligro": true,
					"impulso_balon": Vector3(6.0, 7.2, -18.0), "spin_balon": Vector3(2.0, 22.0, 0.0),
					"destinos": {"EI": Vector3(-11.0, 0, -38.0)}},
			]
		"ATQ-15":
			return [
				{"duracion": 0.8, "es_peligro": true,
					"impulso_balon": Vector3(1.0, 9.5, -11.0), "spin_balon": Vector3(8.0, 0.0, 0.0),
					"destinos": {"DC": Vector3(2.0, 0, -44.0), "POR": Vector3(0.0, 0, 46.0)}},
			]
		"DEF-03":
			return [
				{"duracion": 0.9, "es_peligro": false,
					"impulso_balon": Vector3(3.0, 0.2, 10.0),
					"destinos": {"DFC": Vector3(0.0, 0, -8.0), "LD": Vector3(16.0, 0, -6.0),
						"LI": Vector3(-16.0, 0, -6.0)}},
			]
		"POR-01":
			return [
				{"duracion": 0.7, "es_peligro": true,
					"impulso_balon": Vector3(4.5, 8.0, 16.0), "spin_balon": Vector3(0.0, -8.0, 0.0),
					"destinos": {"POR": Vector3(0.0, 0, 50.5)}},
			]
		"REG-01":
			return [
				{"duracion": 1.0, "es_peligro": true,
					"impulso_balon": Vector3(2.0, 0.5, -18.0),
					"destinos": {"DC": Vector3(3.0, 0, -48.0), "DFC": Vector3(2.0, 0, -46.5)}},
			]
	var lado: float = 1.0 if (n % 2) == 0 else -1.0
	match familia:
		"ATQ":
			return [
				{"duracion": 1.15, "es_peligro": n >= 10,
					"impulso_balon": Vector3(lado * (6.0 + n), 0.25 + n * 0.04, -10.0 - n * 0.3),
					"spin_balon": Vector3(0.0, lado * 7.0, 0.0)},
				{"duracion": 0.75, "es_peligro": true,
					"impulso_balon": Vector3(-lado * 8.0, 2.4 + n * 0.15, -12.0),
					"spin_balon": Vector3(0.0, 10.0, 0.0)},
			]
		"DEF":
			return [
				{"duracion": 1.0, "es_peligro": false,
					"impulso_balon": Vector3(-lado * 5.0, 0.2, 8.0 + n * 0.4),
					"spin_balon": Vector3(0.0, -lado * 5.0, 0.0)},
			]
		"POR":
			return [
				{"duracion": 0.85, "es_peligro": true,
					"impulso_balon": Vector3(lado * (2.0 + n * 0.2), 4.0 + n * 0.2, 14.0),
					"spin_balon": Vector3(0.0, -lado * 9.0, 0.0)},
			]
		_:
			return [
				{"duracion": 1.05, "es_peligro": n <= 7,
					"impulso_balon": Vector3(lado * 4.0, 0.6, -9.0),
					"spin_balon": Vector3(0.0, lado * 4.0, 0.0)},
			]
