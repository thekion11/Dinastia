extends RefCounted
## [Capa 1/2 de `cara.gd`] _hash, _look_base, _piel_y_pelo_del_pais, _rasgos_reales_de, look_de, look_aleatorio … (+4)

## El retrato de cada futbolista, portado del HTML tal cual.
##
## Son 23 cortes de pelo, 8 barbas, 9 accesorios, 4 formas de rostro, 3 mentones,
## 4 narices, 3 bocas, 4 colores de iris, pecas, lunar y cicatriz. Todo dibujado
## con formas, sin una sola imagen. En el HTML esto es `caraSVG()`, y como no
## dibuja sino que CONSTRUYE UNA CADENA, se porta como lo que es y Godot la
## rasteriza con `Image.load_svg_from_string()`.
##
## LA TRAMPA DEL FLEQUILLO, que ya costó una vez: el pelo se dibuja a partir del
## ANCHO REAL del rostro (`RX`), no de un ancho fijo. Con un ancho fijo, en las
## caras anchas el pelo quedaba flotando por encima del cráneo y todos parecían
## calvos. Por eso `L0`, `R0` y `W` se recalculan para cada cara.
##
## El aspecto de un jugador es SIEMPRE el mismo: sale del hash de su id. Si se
## sorteara, el mismo futbolista tendría otra cara cada vez que se abre su ficha.

const CARAS_RX := [13.6, 15.0, 16.2, 14.4]
const CARAS_RY := [17.6, 17.0, 16.4, 17.2]
const OREJAS := [2.1, 2.6, 3.2]
const IRIS := ["#3b2a17", "#2b1d12", "#4a5f3a", "#3a5a72"]

const PIELES := ["#f5d0b0", "#f0c39b", "#e0ab80", "#d7a377", "#b97f4f", "#8a5a34", "#6b4529", "#4e3320"]
const PELOS := ["#231a14", "#3d2a19", "#6b4a2a", "#c8a05a", "#1a1a1a", "#4a3a2a", "#8a6a3a", "#d8d8d8"]

## Los 23 cortes. El orden es el del HTML y no se toca: el aspecto de cada
## jugador sale de un índice sobre esta lista, así que reordenarla le cambiaría
## la cara a todo el mundo.
const CORTES := [
	"corto", "afro", "rizado", "largo", "tupe", "crestas", "mullet", "trenzas",
	"mono", "flequillo", "rapado", "calvo", "fade", "rastas", "coleta", "melena",
	"pincho", "tazon", "undercut", "ondulado", "entradas", "mohicano", "samurai", "cortina",
]
## Los cortes que se le ponen a un jugador real recreado (no se sabe el suyo).
const CORTES_SOBRIOS := ["corto", "fade", "rapado", "undercut", "tupe", "flequillo", "ondulado", "entradas"]
const ACCESORIOS := ["", "", "", "", "cintillo", "vincha", "gafas", "tape", "aro", "cadena", "gorro", "tapa"]
## Lo que lee el jugador en el editor (clave → [rótulo, ayuda]): las claves son
## internas -«tazon», «tape», «mono» (moño)- y no se pueden cambiar sin
## cambiarle la cara a todo el mundo, así que el rótulo va aparte.
const NOMBRES_LOOK := {
	"corto": ["Corto", ""], "afro": ["Afro", ""], "rizado": ["Rizado", ""], "largo": ["Largo", ""],
	"tupe": ["Tupé", ""], "crestas": ["Crestas", ""], "mullet": ["Mullet", ""], "trenzas": ["Trenzas", ""],
	"mono": ["Moño", ""], "flequillo": ["Flequillo", ""], "rapado": ["Rapado", ""], "calvo": ["Calvo", ""],
	"fade": ["Degradado", ""], "rastas": ["Rastas", ""], "coleta": ["Coleta", ""], "melena": ["Melena", ""],
	"pincho": ["Pinchos", ""], "tazon": ["Tazón", ""], "undercut": ["Undercut", ""], "ondulado": ["Ondulado", ""],
	"entradas": ["Con entradas", ""], "mohicano": ["Mohicano", ""], "samurai": ["Samurái", ""],
	"cortina": ["Raya al medio", ""], "cintillo": ["Cinta fina", ""], "vincha": ["Cinta ancha", ""],
	"gafas": ["Gafas", ""], "tape": ["Tira nasal", ""], "aro": ["Pendientes", ""], "cadena": ["Cadena", ""],
	"gorro": ["Gorro de lana", ""], "tapa": ["Gorra", ""],
}

static var _cache: Dictionary = {}

## PIEL Y PELO SEGÚN EL PAÍS (21-10-2026, M-088): a los inventados la piel y el
## color de pelo les tocaban al azar, sin mirar de dónde son. Ahora salen con el
## mismo reparto aproximado por país que la grada (`OlaGrada.PIEL_SESGO`: más
## alto = más pieles claras) y una probabilidad de pelo rubio o castaño claro
## que solo existe en las pieles claras y cambia por país. Es una aproximación
## de población, no un molde: dentro de cada país sigue habiendo de todo.
const RUBIOS := {"GER": 0.32, "ENG": 0.26, "AUS": 0.22, "USA": 0.16, "FRA": 0.12, "ITA": 0.08, "ESP": 0.07,
	"ARG": 0.09, "URU": 0.09, "CHI": 0.06, "BRA": 0.05, "JPN": 0.0, "KOR": 0.0}
## El tono medio de los futbolistas de cada país (índice en PIELES, de 0 claro a
## 7 oscuro). La grada usa su propio sesgo (`OlaGrada.PIEL_SESGO`); con él los
## chilenos salían casi blancos, y la mayoría son mestizos de tono medio.
const TONO_MEDIO := {"CHI": 2.8, "ARG": 1.8, "URU": 1.9, "PAR": 2.9, "BOL": 3.6, "PER": 3.6, "ECU": 3.6,
	"COL": 3.7, "VEN": 3.6, "MEX": 3.2, "BRA": 4.0, "USA": 3.0, "ESP": 1.7, "ITA": 1.7, "GER": 1.3,
	"ENG": 2.0, "FRA": 3.0, "JPN": 1.7, "KOR": 1.5, "AUS": 1.7, "KSA": 3.4, "EGY": 3.8, "MAR": 3.6, "RSA": 5.2}
const PELOS_OSCUROS := ["#231a14", "#3d2a19", "#1a1a1a", "#4a3a2a", "#6b4a2a", "#231a14"]

## "CARA REAL": las fotos con licencia libre que ya bajó
## `herramientas/caras_reales_buscar.ps1` a `recursos/caras_reales/`,
## catalogadas en `datos/caras_reales_reporte.json` -esa búsqueda barre 2.125
## futbolistas reales contra Wikidata/Commons y sigue corriendo sola en
## segundo plano-. Un jugador real (`Jugador.real`, lo marca `Reales.gd`) con
## foto ya encontrada usa su cara de verdad, recortada al cuadrado central
## para que quepa en el mismo hueco que la cara procedural; el resto -y
## cualquier real al que la búsqueda todavía no le haya encontrado nada- se
## queda con el retrato de siempre. Nunca al revés: un jugador que NO es real
## jamás hereda la foto de otra persona.
##
## RETRATOS (25-9-2026): `herramientas/caras_reales_recortar.py` busca la cara
## en cada foto con un detector neuronal (YuNet, de OpenCV) y guarda cabeza y
## hombros a 256x256 en `recursos/caras_reales_256/`, indexados en
## `datos/caras_reales_recortes.json`. Antes se recortaba el cuadrado central
## de la foto de prensa entera y, en las fotos de cuerpo completo, la cara
## quedaba del tamaño de un botón; además se decodificaban fotos de 3.000 px
## en cada lista. Si el índice de retratos no está, se usa el reporte viejo.
const RUTA_RETRATOS := "res://datos/caras_reales_recortes.json"
const RUTA_REPORTE_FOTOS := "res://datos/caras_reales_reporte.json"
static var _indice_fotos: Dictionary = {}
static var _creditos_fotos: Dictionary = {}   ## nombre -> "autor · licencia"
static var _indice_fotos_listo := false

## La foto real de un jugador, ya recortada a cuadrado, o null si no es real o
## si la búsqueda todavía no le encontró ninguna.
## AJUSTES → «Caras reales»: true = la foto (si la hay); false = solo la
## recreación procedural. Lo guarda `Principal._guardar_preferencias()`.
static var usar_fotos := true
const RUTA_RASGOS_REALES := "res://datos/caras_reales_rasgos.json"
static var _rasgos_reales: Dictionary = {}
static var _rasgos_reales_listos := false

## ─── LA CARA 2D MOLDEADA SOBRE EL MODELO 3D (29-9-2026) ───────────────────
## El retrato de la ficha, proyectado de frente sobre la cabeza del jugador del
## partido (`equipacion_q.gdshader`, bloque «cara»). Se proyecta con la pose de
## reposo del modelo, no con su atlas UV: los ojos del retrato (26,33) y (38,33)
## caen sobre los ojos del modelo y la boca (32, 44.5) sobre su boca. Aquí solo
## van los rasgos (sin fondo, pelo, orejas ni hombros): la piel es la del
## modelo, teñida al tono del jugador, y las cejas y el pelo son mallas propias.
## CAPAS: estos colores MULTIPLICAN la piel (sombras, labios, mejillas, pecas),
## así sirven igual para una piel clara que para una oscura; la barba es otra
## capa (`textura_barba`) que se pinta encima con el color del pelo.
const PUNTOS_FOTOS := "res://datos/caras_reales_puntos.json"
static var _puntos_fotos: Dictionary = {}
static var _puntos_listos := false

## djb2 sobre el id: el mismo jugador, siempre la misma cara.
static func _hash(s: String) -> int:
	var h := 5381
	for i in s.length():
		h = ((h << 5) + h + s.unicode_at(i)) & 0x7FFFFFFF
	return h

## El aspecto de un jugador, derivado de su id. No se guarda en `Jugador` a
## propósito: es información de presentación, se puede recalcular siempre igual,
## y meterla en el guardado serían dieciséis campos más por cada uno de los
## 8.448 futbolistas del mundo.
## UN HASH POR ATRIBUTO, no un hash desplazado.
##
## El primer intento sacaba los quince rasgos del mismo número corriéndolo a
## la derecha (`h >> 6`, `h >> 10`...). No funciona: los ids son correlativos
## ("j1", "j2", "j3"), sus hashes quedan muy cerca unos de otros, y al tirar
## los bits bajos los altos apenas cambian. Resultado: **24 jugadores con dos
## cortes de pelo entre todos**. Se veía como si el generador estuviera roto,
## y el generador estaba bien; lo que estaba mal era de dónde salían los
## números. Con una sal distinta por rasgo, cada uno recorre su lista entera.
##
## Recibe la SEMILLA, no el jugador -`look_de()` le pasa `j.id`, y "🎲
## Aleatorio" del editor (`look_aleatorio()`, más abajo) una cadena al azar,
## igual que el HTML rehace `lookDe({id: j.id+Math.random(), ...})`-.
static func _look_base(semilla: String) -> Dictionary:
	return {
		"piel": PIELES[_hash(semilla + "piel") % PIELES.size()],
		"peloC": PELOS[_hash(semilla + "peloC") % PELOS.size()],
		"pelo": CORTES[_hash(semilla + "corte") % CORTES.size()],
		"barba": _hash(semilla + "barba") % 8,
		"ceja": _hash(semilla + "ceja") % 3,
		"ojos": _hash(semilla + "ojos") % 4,
		"acc": ACCESORIOS[_hash(semilla + "acc") % ACCESORIOS.size()],
		"nariz": _hash(semilla + "nariz") % 4,
		"boca": _hash(semilla + "boca") % 3,
		"menton": _hash(semilla + "menton") % 3,
		"orejas": _hash(semilla + "orejas") % 3,
		"cara": _hash(semilla + "cara") % 4,
		"pecas": (_hash(semilla + "pecas") % 11) == 0,
		"lunar": (_hash(semilla + "lunar") % 13) == 0,
		"cicatriz": (_hash(semilla + "cica") % 29) == 0,
	}
static func _piel_y_pelo_del_pais(base: Dictionary, j: Jugador) -> void:
	var sesgo := float(OlaGrada.PIEL_SESGO.get(j.pais, 1.5))
	## `String.hash()` y no `_hash` (djb2): con la misma cola de texto, djb2 da
	## números correlacionados entre sí y los rubios salían a un cuarto.
	## Tono medio del país (índice en PIELES: Argentina ≈1,3, Chile ≈2, Brasil
	## ≈4,2, Sudáfrica ≈5) y, alrededor, una campana de ±1,2 tonos: predomina el
	## tono medio y sigue habiendo de todo.
	var medio := float(TONO_MEDIO.get(j.pais, 7.0 * pow(0.5, sesgo)))
	var campana := 0.0
	for k in 3:
		campana += float(absi((j.id + "piel_pais%d" % k).hash()) % 10000) / 10000.0
	var ip := clampi(int(round(medio + (campana / 3.0 - 0.5) * 7.0)), 0, PIELES.size() - 1)
	base["piel"] = PIELES[ip]
	var claro := ip <= 2
	var r := float(absi((j.id + "pelo_pais").hash()) % 10000) / 10000.0
	var rubio := float(RUBIOS.get(j.pais, 0.06))
	if claro and r < rubio:
		base["peloC"] = "#c8a05a" if r < rubio * 0.55 else "#8a6a3a"
	else:
		base["peloC"] = PELOS_OSCUROS[absi((j.id + "pelo_osc").hash()) % PELOS_OSCUROS.size()]

static func _rasgos_reales_de() -> Dictionary:
	if not _rasgos_reales_listos:
		_rasgos_reales_listos = true
		if FileAccess.file_exists(RUTA_RASGOS_REALES):
			var jp := JSON.new()
			if jp.parse(FileAccess.get_file_as_string(RUTA_RASGOS_REALES)) == OK and jp.data is Dictionary:
				_rasgos_reales = jp.data
	return _rasgos_reales

static func look_de(j: Jugador) -> Dictionary:
	var base := _look_base(j.id)
	## LA RECREACIÓN (29-9-2026): un jugador real (con la base real) toma la
	## piel, el color de pelo y la barba de su foto
	## (`herramientas/caras_reales_rasgos.py`), así su cara procedural se le
	## parece aunque no se enseñe la foto.
	if j.real and Datos.base_real:
		var r: Variant = _rasgos_reales_de().get(Nombres.limpiar(j.nombre))
		## Sin rasgos viejos: la piel y el pelo medidos para su cara 3D.
		if not (r is Dictionary):
			var e := CaraMalla.entrada(Nombres.limpiar(j.nombre))
			if String(e.get("s", "")) != "":
				r = {"piel": String(e["s"])}
				if e.get("h") is Dictionary:
					r["peloC"] = String(e["h"].get("c", "#2e2118"))
					if bool(e["h"].get("calvo", false)):
						r["pelo"] = "calvo"
		if r is Dictionary:
			for k: String in (r as Dictionary):
				base[k] = r[k]
			## A una persona real no se le inventan marcas ni adornos, y el
			## corte (que la foto no dice) sale de los habituales.
			base["acc"] = ""
			## Pelo que la foto no dejó ver (fondo, gorra): castaño oscuro, el
			## más común, antes que un color al azar (salían rubios de mentira).
			if not (r as Dictionary).has("peloC"):
				base["peloC"] = "#2e2118"
			base["pecas"] = false
			base["lunar"] = false
			base["cicatriz"] = false
			if String((r as Dictionary).get("pelo", "")) == "":
				base["pelo"] = CORTES_SOBRIOS[_hash(j.id + "corte") % CORTES_SOBRIOS.size()]
	else:
		_piel_y_pelo_del_pais(base, j)
	## CANAS CON LA EDAD (M-085, 20-10): a los inventados (no a los reales, que
	## llevan el color de su foto) les salen canas desde los 32, más con los años
	## y no a todos igual (a uno de cada cuatro casi nada).
	if not (j.real and Datos.base_real) and j.edad >= 32 and base.has("peloC"):
		var vel := 0.25 if _hash(j.id + "canas") % 4 == 0 else 1.0
		var k := clampf(float(j.edad - 31) / 9.0 * vel, 0.0, 0.65)
		base["peloC"] = "#" + Color(String(base["peloC"])).lerp(Color("#a3a19c"), k).to_html(false)
	## Y encima, lo que el editor haya cambiado a mano. Solo las claves tocadas:
	## cambiar el corte de pelo no debe reescribir la nariz.
	for k: String in j.look:
		base[k] = j.look[k]
	return base

## "🎲 Aleatorio" (`edAleatorio()` del HTML): un aspecto ENTERO nuevo, de una
## vez, no rasgo a rasgo. No usa `Azar` -el generador determinista de la
## partida-: es una herramienta manual del editor que no corre nunca durante
## la simulación, y tocar ese generador compartido aquí correría la secuencia
## de números que sí tiene que ser reproducible para el resto del motor.
static func look_aleatorio() -> Dictionary:
	return _look_base(str(randi()) + str(randf()))

## Aclara u oscurece un color, para los mechones y las trenzas. Es el `e3tint`
## del HTML.
static func _tinte(hex: String, f: float) -> String:
	var c := Color(hex)
	return c.lightened(f).to_html(false)

# --- las piezas -------------------------------------------------------------

## Devuelve [pelo_delante, pelo_detras]. El volumen va DETRÁS del rostro y solo
## el flequillo delante: si todo fuera delante, el pelo taparía los ojos.
static func _pelo(corte: String, pc: String, rx: float, top: float, k1: String, k2: String) -> Array:
	var l0 := 32.0 - rx - 1.2
	var r0 := 32.0 + rx + 1.2
	var w := rx * 2.0 + 2.4
	var delante := ""
	var detras := ""
	match corte:
		"afro":
			detras = '<ellipse cx="32" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>' % [top + 8.0, rx + 6.5, rx + 3.4, pc] \
				+ '<circle cx="%.1f" cy="%.1f" r="5.4" fill="%s"/><circle cx="%.1f" cy="%.1f" r="5.4" fill="%s"/>' % [l0 - 3.0, top + 5.0, pc, r0 + 3.0, top + 5.0, pc] \
				+ '<circle cx="%.1f" cy="%.1f" r="4.8" fill="%s"/><circle cx="%.1f" cy="%.1f" r="4.8" fill="%s"/>' % [l0 - 2.0, top + 15.0, pc, r0 + 2.0, top + 15.0, pc]
			delante = '<path d="M%.1f %.1fq%.1f -12 %.1f 0q-%.1f 3.6 -%.1f 0z" fill="%s"/>' % [l0 + 0.6, top + 15.5, rx - 0.6, w - 1.2, rx - 0.6, w - 1.2, pc]
		"rizado":
			detras = '<ellipse cx="32" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>' % [top + 10.0, rx + 2.6, rx - 0.6, pc] \
				+ '<circle cx="%.1f" cy="%.1f" r="4" fill="%s"/><circle cx="%.1f" cy="%.1f" r="4" fill="%s"/><circle cx="32" cy="%.1f" r="5" fill="%s"/>' % [l0 + 1.0, top + 7.0, pc, r0 - 1.0, top + 7.0, pc, top + 1.5, pc]
			delante = '<path d="M%.1f %.1fc0-11 %.1f-15 %.1f-15s%.1f 4 %.1f 15c-2.6-5-7-6.6-7-3.4-1.8-4.2-6-5-8.6-2.6-2.6-2.6-6.8-1.8-8.6 2.6 0-3.4-4.4-1.6-7 3.4z" fill="%s"/>' % [l0 + 0.4, top + 13.0, rx * 0.55, rx - 0.4, rx - 0.4, rx - 0.4, pc]
		"largo":
			detras = '<path d="M%.1f %.1fc0-14 %.1f-18 %.1f-18s%.1f 4 %.1f 18v28c-4 2.4-6.4-7-6.4-16-3.4 5.6-%.1f 5.6-%.1f 0 0 9-2.4 18.4-6.4 16z" fill="%s"/>' % [l0 - 3.4, top + 12.0, rx * 0.64, rx + 3.4, rx + 3.4, rx + 3.4, w - 5.2, w - 5.2, pc]
			delante = '<path d="M%.1f %.1fc0-12 %.1f-16 %.1f-16s%.1f 4 %.1f 16c-3-6.4-8-8.4-%.1f-8.4s-%.1f 2-%.1f 8.4z" fill="%s"/>' % [l0, top + 12.6, rx * 0.6, rx, rx, rx, rx, rx - 3.0, rx + 3.0, pc]
		"tupe":
			delante = '<path d="M%.1f %.1fc0-11 %.1f-15 %.1f-15s%.1f 4 %.1f 15c-4-7-10-9-%.1f-4-4-5-10-3-%.1f 4z" fill="%s"/><rect x="28" y="%.1f" width="10" height="9" rx="4.5" fill="%s"/>' % [l0 + 2.0, top + 10.0, rx * 0.5, rx - 2.0, rx - 2.0, rx - 2.0, rx - 2.0, rx - 2.0, pc, top - 2.0, pc]
		"crestas":
			delante = '<path d="M%.1f %.1fc0-11 %.1f-15 %.1f-15s%.1f 4 %.1f 15c-3-4-6-5-9-3v-9h-10v9c-3-2-6-1-9 3z" fill="%s"/>' % [l0 + 2.0, top + 11.0, rx * 0.5, rx - 2.0, rx - 2.0, rx - 2.0, pc]
		"mullet":
			detras = '<path d="M%.1f %.1fc-1 12 1 21 4.4 23.5 2-6.6 2-16.5 1-23.5zM%.1f %.1fc1 12-1 21-4.4 23.5-2-6.6-2-16.5-1-23.5z" fill="%s"/>' % [l0 - 0.8, top + 13.0, r0 + 0.8, top + 13.0, pc]
			delante = '<path d="M%.1f %.1fc0-12 %.1f-17 %.1f-17s%.1f 5 %.1f 17c-3-6-8-8-8-4-4-5-%.1f-5-%.1f 0 0-4-5-2-8 4z" fill="%s"/>' % [l0, top + 12.0, rx * 0.6, rx, rx, rx, w - 14.0, w - 14.0, pc]
		"trenzas":
			for i in 7:
				detras += '<rect x="%.1f" y="%.1f" width="3" height="%d" rx="1.5" fill="%s" opacity="%.2f"/>' % [
					l0 + 1.0 + float(i) * (w - 4.0) / 6.4, top + 2.0, 20 + ((i * 5) % 6), pc, 0.66 + float((i * 7) % 5) * 0.06]
			delante = '<path d="M%.1f %.1fc0-12 %.1f-16 %.1f-16s%.1f 4 %.1f 16z" fill="%s"/>' % [l0 + 1.0, top + 12.0, rx * 0.55, rx - 1.0, rx - 1.0, rx - 1.0, pc]
			for i in 5:
				delante += '<path d="M%.1f %.1f q0.6 -7 %.1f -9" stroke="#%s" stroke-width="0.8" fill="none" opacity=".5"/>' % [
					l0 + 2.5 + float(i) * (w - 5.0) / 4.5, top + 13.0,
					rx - 1.0 - float(i) * (w - 5.0) / 4.5 + 1.5, _tinte(pc, 0.22)]
		"mono":
			detras = '<circle cx="32" cy="%.1f" r="5.4" fill="%s"/>' % [top - 1.4, pc]
			delante = '<path d="M%.1f %.1fc0-12 %.1f-16 %.1f-16s%.1f 4 %.1f 16c-3-5-7-7-%.1f-7s-%.1f 2-%.1f 7z" fill="%s"/>' % [l0 + 1.0, top + 11.5, rx * 0.55, rx - 1.0, rx - 1.0, rx - 1.0, rx - 1.0, rx - 4.0, rx + 2.0, pc]
		"flequillo":
			delante = '<path d="M%.1f %.1fc0-12 %.1f-17 %.1f-17s%.1f 5 %.1f 17c-2-8-7-10-10-6-3-4-9-4-12 0-3-4-8-2-10 6z" fill="%s"/>' % [l0, top + 12.0, rx * 0.6, rx, rx, rx, pc]
		"rapado":
			delante = '<path d="M%.1f %.1fc0-10 %.1f-14 %.1f-14s%.1f 4 %.1f 14c-3-4-8-6-%.1f-6s-%.1f 2-%.1f 6z" fill="%s" opacity=".85"/>' % [l0 + 1.0, top + 10.0, rx * 0.5, rx - 1.0, rx - 1.0, rx - 1.0, rx - 1.0, rx - 4.0, rx + 2.0, pc]
		"calvo":
			delante = '<path d="M%.1f %.1fc1-5 5-8 %.1f-8" stroke="%s" stroke-width="2" fill="none" opacity=".35"/>' % [l0 + 3.0, top + 13.0, rx - 3.0, pc]
		"fade":
			delante = '<path d="M%.1f %.1fc0-11 %.1f-15 %.1f-15s%.1f 4 %.1f 15c-3-7-8-9-%.1f-9s-%.1f 2-%.1f 9z" fill="%s"/>' % [l0 + 1.0, top + 12.0, rx * 0.55, rx - 1.0, rx - 1.0, rx - 1.0, rx - 1.0, rx - 4.0, rx + 2.0, pc] \
				+ '<path d="M%.1f %.1fq%.1f -3 %.1f 0v3q-%.1f 3 -%.1f 0z" fill="%s" opacity=".35"/>' % [l0 + 1.0, top + 12.5, rx - 1.0, w - 3.0, rx - 1.0, w - 3.0, pc]
		"rastas":
			for i in 8:
				detras += '<path d="M%.1f %.1f q%.1f 11 %.1f %d" stroke="%s" stroke-width="3" fill="none" stroke-linecap="round" opacity="%.2f"/>' % [
					l0 + 0.5 + float(i) * (w - 1.0) / 7.4, top + 8.0,
					2.4 if i % 2 else -2.4, -1.6 if i % 2 else 1.6,
					20 + ((i * 5) % 9), pc, 0.74 + float((i * 7) % 4) * 0.06]
			delante = '<path d="M%.1f %.1fc0-12 %.1f-16 %.1f-16s%.1f 4 %.1f 16z" fill="%s"/>' % [l0, top + 12.0, rx * 0.6, rx, rx, rx, pc]
		"coleta":
			detras = '<path d="M%.1f %.1fq7.5 1.5 8 8t-4.5 11q2-7.5-1.5-11.5t-5-4.5z" fill="%s"/>' % [r0 - 1.0, top + 13.0, pc]
			delante = '<path d="M%.1f %.1fc0-12 %.1f-16 %.1f-16s%.1f 4 %.1f 16c-3-6-7-8-%.1f-8s-%.1f 2-%.1f 8z" fill="%s"/>' % [l0 + 1.0, top + 11.5, rx * 0.55, rx - 1.0, rx - 1.0, rx - 1.0, rx - 1.0, rx - 4.0, rx + 2.0, pc] \
				+ '<rect x="%.1f" y="%.1f" width="3.4" height="2.6" rx="1.3" fill="%s"/>' % [r0 - 2.6, top + 12.0, k2]
		"melena":
			detras = '<path d="M%.1f %.1fc0-14 %.1f-18 %.1f-18s%.1f 4 %.1f 18c0 12 1.2 18.5-1.4 23.5-2.6-4-2.6-11-4-16-5 5-%.1f 5-%.1f 0-1.4 5-1.4 12-4 16-2.6-5-1.4-11.5-1.4-23.5z" fill="%s"/>' % [l0 - 3.6, top + 12.0, rx * 0.64, rx + 3.6, rx + 3.6, rx + 3.6, w - 4.8, w - 4.8, pc]
			delante = '<path d="M%.1f %.1fc0-12 %.1f-16.4 %.1f-16.4s%.1f 4.4 %.1f 16.4c-3-6.4-8-8.4-%.1f-8.4s-%.1f 2-%.1f 8.4z" fill="%s"/>' % [l0, top + 12.4, rx * 0.6, rx, rx, rx, rx, rx - 3.0, rx + 3.0, pc] \
				+ '<path d="M%.1f %.1fq4-4 9-3M%.1f %.1fq-4-4-9-3" stroke="#%s" stroke-width="1" fill="none" opacity=".5"/>' % [l0 + 2.0, top + 16.0, r0 - 2.0, top + 16.0, _tinte(pc, 0.25)]
		"pincho":
			delante = '<path d="M%.1f %.1fc0-10 %.1f-14 %.1f-14s%.1f 4 %.1f 14c-3-6-8-8-%.1f-8s-%.1f 2-%.1f 8z" fill="%s"/>' % [l0 + 1.0, top + 12.0, rx * 0.5, rx - 1.0, rx - 1.0, rx - 1.0, rx - 1.0, rx - 4.0, rx + 2.0, pc]
			for i in 6:
				delante += '<path d="M%.1f %.1f l1.6-%d l1.8 %d z" fill="%s"/>' % [
					l0 + 2.0 + float(i) * (w - 4.0) / 5.0, top + 2.0, 5 + ((i * 3) % 4), 5 + ((i * 3) % 4), pc]
		"tazon":
			delante = '<path d="M%.1f %.1fc0-12 %.1f-16 %.1f-16s%.1f 4 %.1f 16q-%.1f 3 -%.1f 0z" fill="%s"/>' % [l0 - 0.8, top + 13.0, rx * 0.6, rx + 0.8, rx + 0.8, rx + 0.8, rx + 0.8, w + 1.6, pc]
		"undercut":
			delante = '<path d="M%.1f %.1fq1-13 %.1f-13 8 0 %.1f 6-3 5-9 5-8 0-%.1f 2z" fill="%s"/>' % [l0 + 2.0, top + 13.0, rx - 2.0, rx - 1.0, rx - 2.0, pc] \
				+ '<path d="M%.1f %.1fq%.1f -2 %.1f 0v2q-%.1f 2 -%.1f 0z" fill="%s" opacity=".3"/>' % [l0 + 2.0, top + 13.5, rx - 2.0, w - 4.0, rx - 2.0, w - 4.0, pc]
		"ondulado":
			delante = '<path d="M%.1f %.1fc0-12 %.1f-17 %.1f-17s%.1f 5 %.1f 17c-2-4-4-2-6-5-2 3-5 1-7-2-2 3-5 5-7 2-2 3-4 1-6 5z" fill="%s"/>' % [l0, top + 12.0, rx * 0.6, rx, rx, rx, pc] \
				+ '<path d="M%.1f %.1fq4-3 8 0t8 0" stroke="%s" stroke-width="2.6" fill="none" stroke-linecap="round"/>' % [l0 + 3.0, top + 8.0, pc]
		"entradas":
			delante = '<path d="M%.1f %.1fq1-8 6-9 3 4 3 9 1-6 6-6t6 6q0-5 3-9 5 1 6 9-3-6-%.1f-6t-%.1f 6z" fill="%s"/>' % [l0 + 1.0, top + 14.0, rx - 1.0, rx - 1.0, pc]
		"mohicano":
			delante = '<path d="M%.1f %.1fc0-9 %.1f-12 %.1f-12s%.1f 3 %.1f 12z" fill="%s" opacity=".32"/>' % [l0 + 1.0, top + 13.0, rx * 0.5, rx - 1.0, rx - 1.0, rx - 1.0, pc] \
				+ '<path d="M29 %.1fq0-13 3-14t3 14z" fill="%s"/>' % [top + 13.0, pc]
			for i in 4:
				delante += '<path d="M%.1f %.1f l0.9-4 l1 4z" fill="%s"/>' % [29.6 + float(i) * 1.5, top - 1.0 + float(i) * 0.4, pc]
		"samurai":
			detras = '<ellipse cx="32" cy="%.1f" rx="4.8" ry="4" fill="%s"/>' % [top - 2.2, pc]
			delante = '<path d="M%.1f %.1fc0-9 %.1f-12 %.1f-12s%.1f 3 %.1f 12z" fill="%s" opacity=".38"/>' % [l0 + 2.0, top + 13.0, rx * 0.5, rx - 2.0, rx - 2.0, rx - 2.0, pc] \
				+ '<path d="M%.1f %.1fq1-10 %.1f-10t%.1f 10q-3-5-%.1f-5t-%.1f 5z" fill="%s"/>' % [l0 + 3.0, top + 12.0, rx - 3.0, rx - 3.0, rx - 3.0, rx - 1.0, pc] \
				+ '<rect x="29.6" y="%.1f" width="4.8" height="1.8" rx="0.9" fill="%s"/>' % [top - 0.2, k1]
		"cortina":
			detras = '<path d="M%.1f %.1fc0-13 %.1f-17 %.1f-17s%.1f 4 %.1f 17v11q-2 2-3-1v-10h-%.1fv10q-1 3-3 1z" fill="%s"/>' % [l0 - 1.0, top + 12.0, rx * 0.6, rx + 1.0, rx + 1.0, rx + 1.0, w - 2.0, pc]
			delante = '<path d="M%.1f %.1fc0-13 %.1f-17 %.1f-17s%.1f 4 %.1f 17c-1-6-3-9-5-10-2 4-4 6-7 6-3 0-5-2-7-6-2 1-4 4-5 10z" fill="%s"/>' % [l0, top + 12.0, rx * 0.6, rx, rx, rx, pc]
		_:
			delante = '<path d="M%.1f %.1fc0-12 %.1f-16 %.1f-16s%.1f 4 %.1f 16c-3-6-8-8-%.1f-8s-%.1f 2-%.1f 8z" fill="%s"/>' % [l0, top + 11.0, rx * 0.6, rx, rx, rx, rx, rx - 3.0, rx + 3.0, pc]
	return [delante, detras]

## Las ocho barbas. El 0 es sin barba.
static func _barba(bi: int, pc: String, rx: float) -> String:
	var l0 := 32.0 - rx - 1.2
	match bi:
		1: return '<path d="M%.1f 33c1 13 7 21 %.1f 21s%.1f -8 %.1f -21c-2 10-8 13-%.1f 13s-%.1f -3-%.1f -13z" fill="%s" opacity=".9"/>' % [l0 + 2.0, rx - 2.0, rx - 3.0, rx - 2.0, rx - 2.0, rx - 4.0, rx - 2.0, pc]
		2: return '<path d="M26.5 43.5h11c-1 4.5-3 6.5-5.5 6.5s-4.5-2-5.5-6.5z" fill="%s" opacity=".9"/>' % pc
		3: return '<path d="M26.4 40.2q5.6-3 11.2 0-1.4 2.9-5.6 2.9t-5.6-2.9z" fill="%s" opacity=".95"/>' % pc
		4: return '<path d="M%.1f 34c0.6 12 6.5 20 %.1f 20s%.1f -8 %.1f -20c-1 8-5 11-%.1f 11s-%.1f -3-%.1f -11z" fill="%s" opacity=".55"/>' % [l0 + 2.5, rx - 2.5, rx - 3.5, rx - 2.5, rx - 2.5, rx - 4.5, rx - 2.5, pc] \
			+ '<path d="M26.5 43h11c-1 4.6-3 6.6-5.5 6.6s-4.5-2-5.5-6.6z" fill="%s" opacity=".9"/>' % pc \
			+ '<path d="M26.6 41.2q5.4-2.6 10.8 0-1.2 2.4-5.4 2.4t-5.4-2.4z" fill="%s" opacity=".9"/>' % pc
		5: return '<path d="M%.1f 34c1 12 7 20 %.1f 20s%.1f -8 %.1f -20c-2 9-8 12-%.1f 12s%.1f -3-%.1f -12z" fill="%s" opacity=".33"/>' % [l0 + 2.0, rx - 2.0, rx - 3.0, rx - 2.0, rx - 2.0, -(rx - 4.0), rx - 2.0, pc]
		6: return '<path d="M%.1f 32c0 14 5 22 %.1f 22s%.1f -6 %.1f -22c0 12-2 20-%.1f 26-%.1f-6-%.1f-14-%.1f-26z" fill="%s" opacity=".92"/>' % [l0 + 1.5, rx - 1.5, rx - 3.0, rx - 1.5, rx - 1.5, rx - 4.0, rx - 1.5, rx - 1.5, pc] \
			+ '<path d="M26.6 41.2q5.4-2.6 10.8 0-1.2 2.4-5.4 2.4t-5.4-2.4z" fill="%s"/>' % pc
		7: return '<path d="M%.1f 30h2.6v9l-2.6 2zM%.1f 30h2.6v11l-2.6-2z" fill="%s" opacity=".85"/>' % [32.0 - rx + 0.6, 32.0 + rx - 3.2, pc]
	return ""

## Los accesorios. Los que van con los colores del club usan su equipación, que
## es lo que hace que un jugador se vea de SU equipo y no de uno cualquiera.
static func _accesorio(a: String, rx: float, top: float, k1: String, k2: String) -> String:
	var l0 := 32.0 - rx - 1.2
	var w := rx * 2.0 + 2.4
	match a:
		"cintillo":
			return '<path d="M%.1f %.1fq%.1f -2.2 %.1f 0v3.1q-%.1f 2.2 -%.1f 0z" fill="%s" stroke="#00000044" stroke-width=".5"/>' % [l0 + 0.5, top + 11.5, rx, w - 1.0, rx, w - 1.0, k2]
		"vincha":
			return '<path d="M%.1f %.1fq%.1f -3 %.1f 0v6.2q-%.1f 3 -%.1f 0z" fill="%s" stroke="#00000055" stroke-width=".6"/>' % [l0 - 0.4, top + 10.4, rx, w + 0.8, rx, w + 0.8, k1] \
				+ '<path d="M%.1f %.1fq%.1f -3 %.1f 0" stroke="%s" stroke-width="1.4" fill="none"/>' % [l0 - 0.4, top + 13.0, rx, w + 0.8, k2]
		"gafas":
			return '<g stroke="#1e1e22" stroke-width="1.4" fill="#2a2a3055"><circle cx="26" cy="33" r="4.6"/><circle cx="38" cy="33" r="4.6"/><path d="M30.6 33h2.8" fill="none"/><path d="M21.4 32l-3.4-1" fill="none"/><path d="M42.6 32l3.4-1" fill="none"/></g>'
		"tape":
			return '<path d="M30 35.6h4v5.4h-4z" fill="#f0e6da" stroke="#00000022" stroke-width=".4" transform="rotate(-8 32 38)"/>'
		"aro":
			return '<circle cx="%.1f" cy="37.4" r="1.5" fill="none" stroke="#e4c76a" stroke-width="1"/><circle cx="%.1f" cy="37.4" r="1.5" fill="none" stroke="#e4c76a" stroke-width="1"/>' % [32.0 - rx - 1.0, 32.0 + rx + 1.0]
		"cadena":
			return '<path d="M24 51q8 6 16 0" stroke="#e4c76a" stroke-width="1.5" fill="none" stroke-linecap="round"/><circle cx="32" cy="54.4" r="1.5" fill="#e4c76a"/>'
		"gorro":
			return '<path d="M%.1f %.1fq0 -13 %.1f -13t%.1f 13z" fill="%s" stroke="#00000033" stroke-width=".6"/>' % [l0 - 0.6, top + 13.5, rx + 0.6, rx + 0.6, k1] \
				+ '<path d="M%.1f %.1fq%.1f 2.6 %.1f 0v3.6q-%.1f 2.8 -%.1f 0z" fill="%s"/>' % [l0 - 1.4, top + 12.6, rx + 1.4, w + 2.8, rx + 1.4, w + 2.8, k2] \
				+ '<circle cx="32" cy="%.1f" r="2.6" fill="%s"/>' % [top - 1.6, k2]
		"tapa":
			return '<path d="M%.1f %.1fq0 -11 %.1f -11t%.1f 11z" fill="%s" stroke="#00000033" stroke-width=".6"/>' % [l0 + 1.0, top + 12.0, rx - 1.0, rx - 1.0, k1] \
				+ '<path d="M%.1f %.1fq%.1f 3.4 %.1f 0v2.2q-%.1f 2.6 -%.1f 0z" fill="%s"/>' % [l0 - 2.0, top + 11.6, rx + 2.0, w + 4.0, rx + 2.0, w + 4.0, k2]
	return ""
