class_name MandoFC
extends RefCounted
## EL ESQUEMA DEL MANDO TÁCTIL AL ESTILO FC MOBILE (11-11-2026, pedido del dueño; especificación en `docs/04_auditorias/MANDO_TACTIL_FC_2026-11-11.md`).
## SIEMPRE 4 botones en las MISMAS 4 posiciones que cambian de función y de color con la posesión; esto es solo DATOS y la tabla de gestos (sin nodos):
##   SP  grande, abajo a la derecha   CON balón: SPRINT Y REGATE (verde)    SIN balón: SPRINT Y ENTRADA (blanco)
##   PA  mediano, abajo a la izquierda            PASE (azul cian)                     CAMBIAR (azul cian)
##   AH  mediano, arriba a la izquierda           AL HUECO (amarillo)                  2.º DEFENSOR (amarillo)
##   TI  mediano, arriba a la derecha             TIRO (rojo)                          BARRIDA (naranja)
## No hay lógica de juego: cada gesto se traduce a las acciones del InputMap que YA existen (`Mando.MAPA`), las mismas que usan el mando físico y el teclado
## (modificadores: `jugar_cambiar` = LB, `jugar_mod` = RB, `jugar_regate` = LT). `ControlesTactiles` las pulsa; aquí solo se dice cuáles.
## Gestos (ids): "arriba", "abajo", "izquierda", "derecha" (deslizar desde el botón) y el toque (`toque`). `mant` = acciones que se MANTIENEN pulsadas
## mientras el dedo sigue en el botón; `pulso` = acciones que se pulsan juntas un instante (0,08-0,4 s) y se sueltan.

const IDS: Array[String] = ["SP", "PA", "AH", "TI"]
const DIRS: Array[String] = ["arriba", "abajo", "izquierda", "derecha"]
const VEC := {"arriba": Vector2.UP, "abajo": Vector2.DOWN, "izquierda": Vector2.LEFT, "derecha": Vector2.RIGHT}

## id: [radio (px del lienzo a escala 1), desplazamiento del centro desde la esquina inferior (horizontal), ídem en vertical (sesión 8), color CON balón, color SIN balón, etiqueta CON, etiqueta SIN]
## Distancias entre bordes ≥ 27 px a escala 1 (≥ 2 mm en el peor caso) y Pase y Tiro ≥ 10 mm también en vertical (`_probar_mando_tactil_fc` del banco).
const BOTON := {
	"SP": [72.0, Vector2(100, 112), Vector2(100, 112), Color(0.30, 0.85, 0.40), Color(1.0, 1.0, 1.0), "Sprint\ny regate", "Sprint\ny entrada"],
	"PA": [58.0, Vector2(256, 94), Vector2(256, 94), Color(0.30, 0.78, 1.0), Color(0.30, 0.78, 1.0), "Pase", "Cambiar"],
	"AH": [56.0, Vector2(256, 252), Vector2(256, 252), Color(1.0, 0.85, 0.25), Color(1.0, 0.85, 0.25), "Al hueco", "2.º\ndefensor"],
	"TI": [58.0, Vector2(100, 270), Vector2(100, 270), Color(1.0, 0.30, 0.30), Color(1.0, 0.55, 0.20), "Tiro", "Barrida"],
}
const ANCHO_ARCO := 316.0   ## lo que entra el arco hacia el centro (borde del botón más lejano), px a escala 1
const ALTO_ARCO := 330.0    ## y lo que sube desde la esquina

static func radio(id: String) -> float:
	return float((BOTON[id] as Array)[0])

static func offset(id: String, vertical: bool) -> Vector2:
	return (BOTON[id] as Array)[2 if vertical else 1]

static func color(id: String, con_balon: bool) -> Color:
	return (BOTON[id] as Array)[3 if con_balon else 4]

## La etiqueta (sin traducir; vacía no hay) en este momento. `suelto_propio`: balón suelto en tu mitad (la Barrida pasa a ser Despeje).
static func etiqueta(id: String, con_balon: bool, suelto_propio := false) -> String:
	if id == "TI" and not con_balon and suelto_propio:
		return "Despeje"
	return String((BOTON[id] as Array)[5 if con_balon else 6])

## Acciones que se mantienen desde que el dedo toca el botón. `gestos`: modo con gestos (Gestos o Ambos); sin él, cada botón hace SOLO su función básica.
static func al_tocar(id: String, con_balon: bool, gestos: bool, suelto_propio := false) -> Array:
	match id:
		"SP":
			return ["jugar_sprint"] if con_balon else ["jugar_sprint", "jugar_pase"]   ## sin balón: correr y contener/presionar al que la lleva
		"PA":
			return [] if (con_balon and gestos) else (["jugar_pase"] if con_balon else ["jugar_cambiar"])
		"AH":
			return [] if (con_balon and gestos) else (["jugar_filtrado"] if con_balon else ["jugar_mod"])
		"TI":
			if con_balon:
				return ["jugar_tiro"]   ## mantener = cargar el tiro (la fuerza va con lo que se mantiene)
			return ["jugar_tiro"] if suelto_propio else ["jugar_centro"]
	return []

## Qué pasa al LEVANTAR el dedo sin haber deslizado (el toque): acciones que se pulsan un instante; vacío = ya lo hizo `al_tocar`.
static func al_soltar_toque(id: String, con_balon: bool, gestos: bool, ms_tocado: int) -> Dictionary:
	match id:
		"SP":
			if con_balon and ms_tocado < 200:
				return {"pulso": ["jugar_regate"], "dur": 0.1}   ## toque corto = regate; mantener = correr
			if not con_balon and ms_tocado < 200:
				return {"pulso": ["jugar_tiro"], "dur": 0.1}   ## sin balón, tocar = entrada
		"PA":
			if con_balon and gestos:
				return {"pulso": ["jugar_pase"], "dur": 0.08}
		"AH":
			if con_balon and gestos:
				return {"pulso": ["jugar_filtrado"], "dur": 0.08}
	return {}

## Qué se hace al DESLIZAR desde el botón en `dir` (se dispara al pasar el umbral, una vez por toque). Devuelve {"mant": […], "pulso": […], "dur": s}:
## `mant` se añade a lo mantenido hasta levantar el dedo; vacío = ese gesto no hace nada aquí.
static func al_deslizar(id: String, con_balon: bool, en_banda: bool, dir: String) -> Dictionary:
	if con_balon:
		match id:
			"SP":
				match dir:
					"arriba", "abajo":
						return {"pulso": ["jugar_fili_arriba"], "dur": 0.12}   ## finta hacia delante / adelantar el balón (con el sprint puesto es el «knock-on»)
					"derecha":
						return {"pulso": ["jugar_fili_derecha"], "dur": 0.12}
					"izquierda":
						return {"pulso": ["jugar_regate"], "dur": 0.4}   ## parada en seco (proteger el balón y frenar)
			"PA":
				if en_banda:
					match dir:
						"arriba":
							return {"pulso": ["jugar_centro"], "dur": 0.08}
						"derecha":
							return {"pulso": ["jugar_mod", "jugar_centro"], "dur": 0.08}   ## centro tenso y bajo
						"izquierda":
							return {"pulso": ["jugar_cambiar", "jugar_centro"], "dur": 0.08}   ## centro bombeado
				match dir:
					"arriba":
						return {"pulso": ["jugar_pase_largo"], "dur": 0.08}   ## pase elevado
					"abajo":
						return {"pulso": ["jugar_cambiar", "jugar_pase"], "dur": 0.08}   ## pase y correr (la pared)
			"AH":
				if dir == "arriba":
					return {"pulso": ["jugar_cambiar", "jugar_filtrado"], "dur": 0.08}   ## al hueco elevado (bombeado)
			"TI":
				match dir:
					"abajo":
						return {"mant": ["jugar_mod"]}   ## tiro colocado (rosca)
					"arriba":
						return {"mant": ["jugar_cambiar"]}   ## vaselina
					"izquierda":
						return {"pulso": ["jugar_pase"], "dur": 0.08}   ## amago de tiro (Pase durante la carga la cancela: el Tiro sigue pulsado, no dispara)
	else:
		if id == "AH" and dir == "abajo":
			return {"mant": ["jugar_filtrado"]}   ## sale el portero
	return {}

## Las direcciones con función en este momento (para dibujar los triangulitos del aro).
static func triangulos(id: String, con_balon: bool, en_banda: bool) -> Array:
	var r: Array = []
	for d: String in DIRS:
		if not al_deslizar(id, con_balon, en_banda, d).is_empty():
			r.append(d)
	return r

## La dirección dominante de un arrastre (vacío si no pasa del umbral).
static func direccion(delta: Vector2, umbral: float) -> String:
	if delta.length() < umbral:
		return ""
	if absf(delta.x) > absf(delta.y):
		return "derecha" if delta.x > 0.0 else "izquierda"
	return "abajo" if delta.y > 0.0 else "arriba"
