class_name CaraDT
extends RefCounted
## El retrato del entrenador. Mismo motor que `Cara` -SVG construido como
## cadena, rasterizado con `Image.load_svg_from_string()`- pero con dos
## diferencias reales frente al futbolista:
##
## 1. NO SALE DE UN HASH. La cara de un jugador tiene que ser siempre la
##    misma -sale de su id-, pero el DT es EL PERSONAJE DEL JUGADOR: se
##    elige a mano desde el principio, como el nombre. Por eso `Roles.look`
##    guarda el `Dictionary` completo -no solo las claves tocadas, como
##    `Jugador.look`- y `look_por_defecto()` es el punto de partida, no una
##    base que se pueda recalcular.
## 2. TRAE TRAJE, no equipación. `DT_TRAJES` es la mesa de vestuario del
##    cuerpo técnico: chándal del club, traje y corbata, abrigo largo...
##
## PORTADO TAL CUAL de `caraDT(L,sz)` en el HTML, doce cortes con forma
## propia entre los 23 -los mismos que ya tenía `DT_PELOS`, nunca se habían
## dibujado en Godot- más los modificadores que llevan 23 cortes a 552
## combinaciones: `vol` (escala vertical más que horizontal, o el pelo
## parece un casco), `raya` (un trazo del color de la piel DENTRO del pelo,
## de y=14 a y=24 -más arriba y asoma como un pincho sobre casi cualquier
## corte-) y `lados` (rapa las sienes).

## Los 23 cortes que el DT sabe llevar. MISMO ORDEN que el HTML -no se
## reordena esta lista jamás.
const CORTES := ["corto", "rapado", "calvo", "largo", "tupe", "entradas", "coleta", "melena",
	"pincho", "cortina", "moño", "rizado", "afro", "rastas", "fade", "undercut", "mohicano",
	"flequillo", "trenzas", "ondulado", "tazon", "crestas", "mullet"]

## [id, nombre, color1, color2]. El color se puede sobreescribir sin perder
## el CORTE de la prenda -eso es lo que de verdad cambia el estilo-.
const TRAJES := [
	["traje", "Traje y corbata", "#1c2430", "#c9a227"],
	["chandal", "Chándal del club", "#1e4030", "#e8ede9"],
	["polo", "Polo y pantalón", "#2b3a45", "#dfe6e2"],
	["abrigo", "Abrigo largo", "#2a2320", "#8a6b4a"],
	["sudadera", "Sudadera con capucha", "#33363b", "#d9d9d9"],
	["camisa", "Camisa arremangada", "#e8ede9", "#4a5a52"],
]
const VOLS := ["Ajustado", "Normal", "Voluminoso"]

static func look_por_defecto() -> Dictionary:
	return {"piel": Cara.PIELES[2], "pelo": "corto", "pelo_c": Cara.PELOS[1], "barba": 1,
		"ojos": 1, "edad": 44, "traje": "chandal", "gafas": false, "vol": 1, "raya": 0,
		"lados": false, "barba_c": "", "ojos_c": "", "ropa_c": "", "ropa_c2": ""}

## djb2 sobre el nombre -mismo patrón que `Cara._hash()`-: una sal distinta
## por rasgo, no un hash desplazado (esa trampa ya costó "24 jugadores con dos
## cortes de pelo entre todos", ver `dinastia-migracion-godot`).
static func _hash(s: String) -> int:
	var h := 5381
	for i in s.length():
		h = ((h << 5) + h + s.unicode_at(i)) & 0x7FFFFFFF
	return h

## EL DT EMPLEADO (14-9-2026). Cuando el jugador no es él mismo el entrenador
## -ayudante de campo, director deportivo, dueño con banco delegado-,
## `Roles.dt_empleado` solo trae nombre/estilo/sintonía, sin ningún aspecto:
## nadie personaliza a un entrenador que no eres tú. Pero la rueda de prensa
## la da ÉL, no el jugador -mostrar tu propia cara ahí sería que el dueño del
## club diera la conferencia técnica en tu lugar-. Determinístico por nombre,
## igual que `Cara.look_de()` lo es por id: el mismo empleado siempre sale
## igual, sin gastar `Azar` en algo puramente cosmético.
static func look_de_nombre(nombre: String) -> Dictionary:
	var l := look_por_defecto()
	l["piel"] = Cara.PIELES[_hash(nombre + "piel") % Cara.PIELES.size()]
	l["pelo"] = CORTES[_hash(nombre + "corte") % CORTES.size()]
	l["pelo_c"] = Cara.PELOS[_hash(nombre + "peloC") % Cara.PELOS.size()]
	l["barba"] = _hash(nombre + "barba") % 8
	l["ojos"] = _hash(nombre + "ojos") % 4
	l["traje"] = String((TRAJES[_hash(nombre + "traje") % TRAJES.size()] as Array)[0])
	l["gafas"] = (_hash(nombre + "gafas") % 5) == 0
	l["vol"] = _hash(nombre + "vol") % 3
	l["raya"] = _hash(nombre + "raya") % 4
	l["lados"] = (_hash(nombre + "lados") % 4) == 0
	l["edad"] = 34 + _hash(nombre + "edad") % 30
	return l

## "🎲 Aleatorio": mismo motivo que `Cara.look_aleatorio()` para NO usar
## `Azar` -es una herramienta manual del editor, tocar el generador
## compartido correría la secuencia determinista del resto de la partida.
static func look_aleatorio() -> Dictionary:
	var l := look_por_defecto()
	l["piel"] = Cara.PIELES[randi() % Cara.PIELES.size()]
	l["pelo"] = CORTES[randi() % CORTES.size()]
	l["pelo_c"] = Cara.PELOS[randi() % Cara.PELOS.size()]
	l["barba"] = randi() % 8
	l["ojos"] = randi() % 4
	l["traje"] = String((TRAJES[randi() % TRAJES.size()] as Array)[0])
	l["gafas"] = randf() < 0.2
	l["vol"] = randi() % 3
	l["raya"] = randi() % 4
	l["lados"] = randf() < 0.25
	return l

static var _cache: Dictionary = {}

## Volumen: 0.86/1/1.16, y la vertical se estira un 35% más que la horizontal
## -si escalara igual en las dos direcciones el pelo parece un casco-.
static func _pelo_svg(pelo: String, pc: String) -> String:
	match pelo:
		"calvo":
			return '<path d="M19 26c0-9 6-14 13-14s13 5 13 14c-3-5-7-7-13-7s-10 2-13 7z" fill="%s" opacity=".5"/>' % pc
		"corto":
			return '<path d="M17 26c0-12 7-17 15-17s15 5 15 17c-3-6-8-8-15-8s-12 2-15 8z" fill="%s"/>' % pc
		"rapado":
			return '<path d="M18 25c0-10 6-15 14-15s14 5 14 15c-3-4-8-6-14-6s-11 2-14 6z" fill="%s" opacity=".82"/>' % pc
		"largo":
			return '<path d="M16 27c0-12 7-18 16-18s16 6 16 18c-3-6-8-8-16-8s-13 2-16 8z" fill="%s"/>' % pc
		"tupe":
			return ('<path d="M18 24c0-11 6-16 14-16s14 5 14 16c-4-7-10-9-14-4-4-5-10-3-14 4z" fill="%s"/>' +
				'<rect x="28" y="6" width="10" height="8" rx="4" fill="%s"/>') % [pc, pc]
		"entradas":
			return '<path d="M18 27q1-8 6-9 3 4 3 9 1-6 5-6t5 6q0-5 3-9 5 1 6 9-4-7-14-7t-14 7z" fill="%s"/>' % pc
		"coleta":
			return '<path d="M17 26c0-12 7-17 15-17s15 5 15 17c-3-6-8-8-15-8s-12 2-15 8z" fill="%s"/>' % pc
		"melena":
			return '<path d="M16 27c0-12 7-18 16-18s16 6 16 18c-3-6-8-8-16-8s-13 2-16 8z" fill="%s"/>' % pc
		"pincho":
			var puntas := ""
			for i in 5:
				puntas += '<path d="M%d 13l1.8-6 2 6z" fill="%s"/>' % [20 + i * 6, pc]
			return '<path d="M18 26c0-10 6-15 14-15s14 5 14 15c-3-6-8-8-14-8s-11 2-14 8z" fill="%s"/>%s' % [pc, puntas]
		"cortina":
			return '<path d="M17 27c0-13 7-18 15-18s15 5 15 18c-1-6-3-9-5-10-2 4-5 6-10 6s-8-2-10-6c-2 1-4 4-5 10z" fill="%s"/>' % pc
		"moño":
			return '<path d="M18 26q1-15 14-15t14 15q-4-6-14-6t-14 6z" fill="%s"/>' % pc
		"rizado":
			var bucles := ""
			var xs := [21, 27, 33, 39, 45]
			for i in xs.size():
				bucles += '<circle cx="%d" cy="%d" r="4" fill="%s"/>' % [xs[i], 13 + (i % 2) * 3, pc]
			return ('<path d="M17 27c0-13 7-18 15-18s15 5 15 18c-2-4-4-6-6-5-2-3-6-4-9-2-3-2-7-1-9 2-2-1-4 1-6 5z" fill="%s"/>%s') % [pc, bucles]
		"afro":
			return '<path d="M17 27q2-9 15-9t15 9q-4-5-15-5t-15 5z" fill="%s"/>' % pc
		"rastas":
			return '<path d="M16 26c0-12 7-17 16-17s16 5 16 17c-3-6-8-8-16-8s-13 2-16 8z" fill="%s"/>' % pc
		"fade":
			return ('<path d="M18 24c0-11 6-16 14-16s14 5 14 16c-3-4-8-6-14-6s-11 2-14 6z" fill="%s"/>' +
				'<path d="M18 24q3-3 14-3t14 3v4q-3-3-14-3t-14 3z" fill="%s" opacity=".35"/>') % [pc, pc]
		"undercut":
			return ('<path d="M20 23c0-11 5-15 12-15s12 4 12 15c-3-5-7-7-12-7s-9 2-12 7z" fill="%s"/>' +
				'<path d="M17.5 27q2-4 3-4v6q-2 0-3-2zM46.5 27q-2-4-3-4v6q2 0 3-2z" fill="%s" opacity=".4"/>') % [pc, pc]
		"mohicano":
			return ('<path d="M28 24c0-13 2-18 4-18s4 5 4 18q-4-3-8 0z" fill="%s"/>' +
				'<path d="M18 27q2-4 4-4v6q-2 0-4-2zM46 27q-2-4-4-4v6q2 0 4-2z" fill="%s" opacity=".45"/>') % [pc, pc]
		"flequillo":
			## EL MECHÓN SE QUEDA SOBRE LA FRENTE -misma trampa que ya pagó
			## `Cara`: con y=35 cruzaría los ojos (y=33) como un antifaz.
			return ('<path d="M16 27c0-13 7-18 16-18s16 5 16 18c-2-7-6-10-16-10s-14 3-16 10z" fill="%s"/>' +
				'<path d="M17 21q6 6 15 6t15-6v4q-6 5-15 5t-15-5z" fill="%s"/>') % [pc, pc]
		"trenzas":
			var lineas := ""
			for x in [21, 26, 32, 38, 43]:
				lineas += '<path d="M%d 11v14" stroke="%s" stroke-width="2.2" stroke-linecap="round" opacity=".55"/>' % [x, pc]
			return '<path d="M17 26c0-12 7-17 15-17s15 5 15 17c-3-6-8-8-15-8s-12 2-15 8z" fill="%s"/>%s' % [pc, lineas]
		"ondulado":
			return '<path d="M16 27c0-13 7-18 16-18s16 5 16 18c-2-3-4-2-6 0-2-3-4-2-5 0-2-3-4-3-5 0-2-2-4-3-6 0-2-2-4-3-6 0-1-2-3-3-4 0z" fill="%s"/>' % pc
		"tazon":
			return '<path d="M15 25q0-16 17-16t17 16q-2 4-17 4t-17-4z" fill="%s"/>' % pc
		"crestas":
			return '<path d="M18 26c0-11 6-16 14-16s14 5 14 16c-3-5-7-6-9-4v-8h-10v8c-2-2-6-1-9 4z" fill="%s"/>' % pc
		"mullet":
			return '<path d="M17 26c0-12 7-18 15-18s15 6 15 18c-3-6-6-8-8-5-4-4-10-4-14 0-2-3-5-1-8 5z" fill="%s"/>' % pc
	return '<path d="M17 26c0-12 7-17 15-17s15 5 15 17c-3-6-8-8-15-8s-12 2-15 8z" fill="%s"/>' % pc

## Los tres cortes que llevan una segunda pieza DETRÁS del rostro -coleta,
## melena y moño necesitan algo que asome por detrás de la cabeza, o se
## verían igual que un corte corto normal.
static func _pelo_atras_svg(pelo: String, pc: String) -> String:
	match pelo:
		"largo":
			return '<path d="M12 27c0-14 8-20 20-20s20 6 20 20v22c-4 2-6-6-6-14-3 5-25 5-28 0 0 8-2 16-6 14z" fill="%s"/>' % pc
		"coleta":
			return '<path d="M46 27q7 1 7.5 8t-4 10q2-7-1-11t-5-5z" fill="%s"/>' % pc
		"melena":
			return '<path d="M13 27c0-14 8-20 19-20s19 6 19 20v19c-3 2-4-7-5-12-5 5-23 5-28 0-1 5-2 14-5 12z" fill="%s"/>' % pc
		"moño":
			return '<ellipse cx="32" cy="8" rx="5.4" ry="4.4" fill="%s"/>' % pc
		"afro":
			return '<ellipse cx="32" cy="20" rx="21" ry="16" fill="%s"/>' % pc
		"rastas":
			var mechones := ""
			var xs := [14, 20, 26, 38, 44, 50]
			for i in xs.size():
				mechones += '<rect x="%d" y="20" width="4" height="%d" rx="2" fill="%s"/>' % [xs[i] - 2, 26 + (i % 3) * 7, pc]
			return mechones
		"mullet":
			return '<path d="M17 26q-1 13 3 22 3-8 2-22zM47 26q1 13-3 22-3-8-2-22z" fill="%s"/>' % pc
	return ""

static func _barba_svg(bd: int, color: String) -> String:
	match bd:
		1: return '<path d="M18 34c1 12 7 20 14 20s13-8 14-20c-2 10-8 13-14 13s-12-3-14-13z" fill="%s" opacity=".9"/>' % color
		2: return '<path d="M26 44h12c-1 4-3 6-6 6s-5-2-6-6z" fill="%s" opacity=".9"/>' % color
		3: return '<path d="M26 41.5q6-3 12 0-1.4 2.8-6 2.8t-6-2.8z" fill="%s" opacity=".92"/>' % color
		4: return ('<path d="M19 35c1 11 6 19 13 19s12-8 13-19c-1 8-6 11-13 11s-12-3-13-11z" fill="%s" opacity=".55"/>' +
			'<path d="M26 43.5h12c-1 4.4-3 6.4-6 6.4s-5-2-6-6.4z" fill="%s" opacity=".9"/>') % [color, color]
		5: return '<path d="M18 35c1 11 7 19 14 19s13-8 14-19c-2 9-8 12-14 12s-12-3-14-12z" fill="%s" opacity=".32"/>' % color
		6: return '<path d="M18 33c0 14 5 21 14 21s14-7 14-21c0 12-2 20-14 27-12-7-14-15-14-27z" fill="%s" opacity=".92"/>' % color
		7: return '<path d="M18.5 30h3v10l-3 2zM42.5 30h3v12l-3-2z" fill="%s" opacity=".85"/>' % color
	return ""

## El SVG completo, 64×64 -mismo lienzo que `Cara`-. `L` es el `Dictionary`
## de `Roles.look` ya combinado con `look_por_defecto()` (ver `look()` más
## abajo, que hace el merge igual que `Cara.look_de()` para el jugador).
static func svg_de(l: Dictionary) -> String:
	var t0: Array = TRAJES[0]
	for fila: Array in TRAJES:
		if String(fila[0]) == String(l.get("traje", "")):
			t0 = fila
			break
	## El traje trae sus dos colores en la tabla, pero se pueden sobreescribir
	## sin perder el CORTE de la prenda -lo que de verdad da el estilo-.
	var ropa_c := String(l.get("ropa_c", ""))
	var ropa_c2 := String(l.get("ropa_c2", ""))
	var t2 := ropa_c if ropa_c != "" else String(t0[2])
	var t3 := ropa_c2 if ropa_c2 != "" else String(t0[3])

	var piel := String(l.get("piel", Cara.PIELES[2]))
	var pc := String(l.get("pelo_c", Cara.PELOS[1]))
	var edad := int(l.get("edad", 44))
	## A partir de los 45 el pelo encanece solo, y a los 52 ya sale gris del
	## todo -mismo umbral que el HTML, "cano" no es un campo que se elija-.
	var cano := 0.55 if edad >= 52 else (0.28 if edad >= 45 else 0.0)
	var pelo_col := "#b9bcb8" if cano > 0.0 else pc
	var barba_col := String(l.get("barba_c", "")) if String(l.get("barba_c", "")) != "" else pelo_col
	var ojo_col := String(l.get("ojos_c", "")) if String(l.get("ojos_c", "")) != "" else "#2b1d12"

	var pelo := String(l.get("pelo", "corto"))
	var pelo_svg := _pelo_svg(pelo, pelo_col)
	var pelo_atras := _pelo_atras_svg(pelo, pelo_col)

	## MODIFICADORES: de 23 cortes a 552 combinaciones -23 × 3 volúmenes × 4
	## rayas × 2 laterales-.
	var vol_val: float = [0.86, 1.0, 1.16][clampi(int(l.get("vol", 1)), 0, 2)]
	if not is_equal_approx(vol_val, 1.0):
		var escala_y: float = 1.0 + (vol_val - 1.0) * 1.35
		pelo_svg = '<g transform="translate(32 27) scale(%.3f %.3f) translate(-32 -27)">%s</g>' % [vol_val, escala_y, pelo_svg]
	var raya := int(l.get("raya", 0))
	if raya != 0 and pelo != "calvo" and pelo != "rapado":
		## La raya va DENTRO del pelo, del nacimiento hacia la frente -de
		## y=14 a y=10 arrancaba por encima de casi todos los cortes y
		## asomaba como un pincho.
		var rx: int = [0, 25, 32, 39][clampi(raya, 0, 3)]
		pelo_svg += '<path d="M%d 14q1.3 5 0 10" stroke="%s" stroke-width="1.9" fill="none" opacity=".7" stroke-linecap="round"/>' % [rx, piel]
	if bool(l.get("lados", false)):
		pelo_svg += '<path d="M17.6 24q2.4-5 4-5v11q-2.6-1-4-6zM46.4 24q-2.4-5-4-5v11q2.6-1 4-6z" fill="%s" opacity=".95"/>' % piel

	var barba_svg := _barba_svg(int(l.get("barba", 0)), barba_col)
	var gafas_svg := ""
	if bool(l.get("gafas", false)):
		gafas_svg = '<g stroke="#2a2a2a" stroke-width="1.5" fill="none"><circle cx="26" cy="33" r="5"/><circle cx="38" cy="33" r="5"/><path d="M31 33h2M21 32l-3-1M43 32l3-1"/></g>'
	var arrugas_svg := ""
	if edad >= 50:
		arrugas_svg = '<path d="M22 28q3-1.5 5 0M37 28q3-1.5 5 0" stroke="#00000030" stroke-width="1" fill="none"/>'

	return ('<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">' +
		'<defs><linearGradient id="dtp" x1="0" y1="0" x2="1" y2="1">' +
		'<stop offset="0" stop-color="%s"/><stop offset="1" stop-color="#00000030"/></linearGradient></defs>' +
		'<rect width="64" height="64" rx="12" fill="%s" opacity=".3"/>' +
		'<path d="M10 64c2-13 10-17 22-17s20 4 22 17z" fill="%s" stroke="%s" stroke-width="1.3"/>' +
		'<path d="M27 47l5 8 5-8 -5-3z" fill="%s" opacity=".9"/>' +
		'<rect x="27" y="41" width="10" height="8" fill="%s"/>' +
		'%s' +
		'<ellipse cx="32" cy="33" rx="15" ry="17" fill="%s"/>' +
		'<ellipse cx="32" cy="33" rx="15" ry="17" fill="url(#dtp)" opacity=".32"/>' +
		'<ellipse cx="17.5" cy="34" rx="2.6" ry="4" fill="%s"/><ellipse cx="46.5" cy="34" rx="2.6" ry="4" fill="%s"/>' +
		'%s%s' +
		'<ellipse cx="26" cy="33" rx="2.9" ry="2.1" fill="#fff"/><circle cx="26" cy="33" r="1.5" fill="%s"/><circle cx="26" cy="33" r="0.7" fill="#120c08"/>' +
		'<ellipse cx="38" cy="33" rx="2.9" ry="2.1" fill="#fff"/><circle cx="38" cy="33" r="1.5" fill="%s"/><circle cx="38" cy="33" r="0.7" fill="#120c08"/>' +
		'<path d="M22.5 28.5q3.5-2 7 0M34.5 28.5q3.5-2 7 0" stroke="%s" stroke-width="1.8" fill="none" stroke-linecap="round"/>' +
		'%s' +
		'<path d="M32 36l-2 4h4z" fill="#00000022"/>' +
		'<path d="M28 43q4 2 8 0" stroke="#7d3f36" stroke-width="1.6" fill="none" stroke-linecap="round"/>' +
		'%s</svg>') % [
			piel, t2, t2, t3, t3, piel,
			pelo_atras, piel, piel, piel,
			pelo_svg, barba_svg,
			ojo_col, ojo_col, pelo_col,
			arrugas_svg, gafas_svg,
		]

## El retrato ya rasterizado. Se cachea por el look ENTERO -a diferencia de
## `Cara`, que cachea por id de jugador, aquí no hay id: la clave es el
## propio contenido, así que dos DT con el mismo aspecto comparten textura.
static func textura(l: Dictionary, alto_px: int = 64) -> Texture2D:
	var clave := "%s_%d" % [JSON.stringify(l), alto_px]
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(l), float(alto_px) * 3.0 / 64.0) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t
