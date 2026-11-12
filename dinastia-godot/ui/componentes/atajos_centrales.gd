class_name AtajosCentrales
extends RefCounted
## LOS ATAJOS DE TECLADO DEL MENÚ (s3, 26-10-2026; rehecho el 3-11-2026, rediseño del menú central, etapa 5). El central ya no tiene pestañas: cada sección vive en un menú del panel
## lateral (`MenusLaterales.MENUS`). CADA menú y CADA submenú puede tener su tecla; se generan de esa misma tabla (si se añade un menú o un submenú, ya tiene su atajo, sin tecla hasta
## que se le dé una). Los atajos NO se ven en pantalla: solo existen, y se ven y se cambian en Ajustes → Accesibilidad (teclas, `TeclasInterfaz`). No hacen nada mientras se escribe en un
## campo de texto ni con Ctrl/Alt/Meta (Ctrl+Q/E cambian de menú).
##
## Teclas de fábrica (letras con sentido, sin chocar con WASD ni con Q/E, que son «pestaña anterior/siguiente» y se mueven por los submenús):
##   P plantel · T táctica · M mercado · F dinero (finanzas) · C competiciones · J próximo partido (jornada) · B estadio · H historia · G gente · R carrera · O operaciones
##   V vida · L calendario · X correo · Y glosario · N pasar un día · F3 buscar · F5 guardar. El resto de menús y submenús, sin tecla.

## Tecla de fábrica por clave: «menu:<id>» o «sub:<id>:<submenú>» (ver `_clave_sub`); lo que no está aquí no tiene tecla.
const DEFECTOS := {
	"menu:plantel": KEY_P, "sub:plantel:Táctica": KEY_T, "sub:dinero:Mercado": KEY_M, "menu:dinero": KEY_F, "menu:competiciones": KEY_C,
	"menu:partido": KEY_J, "menu:estadio": KEY_B, "menu:historia": KEY_H, "menu:gente": KEY_G, "menu:carrera": KEY_R, "menu:operaciones": KEY_O,
	"menu:vida": KEY_V, "sub:partido:Calendario": KEY_L, "sub:carrera:Correo": KEY_X, "sub:reglas:Glosario": KEY_Y,
}

## Las órdenes que no abren un menú: [acción, nombre, tecla de fábrica, destino].
const GENERALES := [
	["dinastia_un_dia", "Pasar un día", KEY_N, "dia"],
	["dinastia_buscar", "Buscar un jugador o un club", KEY_F3, "buscar"],
	["dinastia_guardar", "Guardar la partida", KEY_F5, "guardar"],
]

## Lo mismo que antes de este cambio (1-9 y 0 por pestañas): acción vieja → clave nueva. Las usa `TeclasInterfaz.cargar` para no perder las teclas que alguien ya había cambiado.
const MIGRACION := {
	"dinastia_ir_plantel": "menu:plantel", "dinastia_ir_tactica": "sub:plantel:Táctica", "dinastia_ir_entrenar": "sub:plantel:Entrenar",
	"dinastia_ir_mercado": "sub:dinero:Mercado", "dinastia_ir_finanzas": "sub:dinero:Finanzas", "dinastia_ir_calendario": "sub:partido:Calendario",
	"dinastia_sub_operaciones_estadio": "sub:operaciones:Estadio.hinchada",   ## (12-11) «Hinchada y socios» tiene ya su pantalla
	"dinastia_sub_historia_cantera": "sub:historia:Cantera.linaje",   ## (12-11) «Linaje» abre ahora su pantalla de Cantera: la tecla que tuviera, con ella
	"dinastia_ir_correo": "sub:carrera:Correo", "dinastia_ir_contratos": "sub:plantel:Contratos", "dinastia_ir_prensa": "sub:operaciones:Redes.prensa",
}

## [{accion, nombre, grupo, tecla, destino, clave}] (se arma una vez). `grupo`: el nombre del menú (o «General»); `nombre`: «El menú entero» o el submenú.
static var _catalogo: Array = []

static func _norm(s: String) -> String:
	var t := s.to_lower()
	for par: Array in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ñ", "n"], ["ü", "u"]]:
		t = t.replace(String(par[0]), String(par[1]))
	var fuera := ""
	for c in t:
		fuera += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") else "_"
	return fuera

## Lo que identifica a un submenú dentro de su menú: la acción, o la pestaña y su sección («Redes.prensa»).
## (12-11) Las pestañas que se partieron en pantallas (Finanzas, Partido, Táctica…) conservan su nombre de siempre en su PRIMERA pantalla
## (`PRIMERA`): así la tecla de fábrica (T = Táctica), la migración de teclas viejas y las teclas que alguien ya había cambiado siguen valiendo.
const PRIMERA := {"Finanzas": "cuentas", "Partido": "previa", "Táctica": "pizarra", "Entrenar": "semana", "Cantera": "academia", "Clubes": "tablas", "Estadio": "diseno", "Legado": "club", "Federación": "reglamento", "Camarín": "clima"}
static func _clave_sub(sub: Dictionary) -> String:
	if sub.has("accion"):
		return String(sub["accion"])
	var tab := String(sub.get("tab", ""))
	var secc := String(sub.get("secc", ""))
	return tab + ("." + secc if secc != "" and String(PRIMERA.get(tab, "")) != secc else "")

static func catalogo() -> Array:
	if not _catalogo.is_empty():
		return _catalogo
	for m: Dictionary in MenusLaterales.MENUS:
		var id := String(m["id"])
		var clave := "menu:" + id
		_catalogo.append({"accion": "dinastia_menu_" + id, "nombre": "El menú entero", "grupo": String(m["nombre"]), "tecla": int(DEFECTOS.get(clave, 0)),
			"destino": {"menu": id, "sub": -1}, "clave": clave})
		var subs: Array = m["subs"]
		for k in subs.size():
			var sub: Dictionary = subs[k]
			var ck := "sub:%s:%s" % [id, _clave_sub(sub)]
			_catalogo.append({"accion": "dinastia_sub_%s_%s" % [id, _norm(_clave_sub(sub))], "nombre": String(sub["label"]), "grupo": String(m["nombre"]),
				"tecla": int(DEFECTOS.get(ck, 0)), "destino": {"menu": id, "sub": k}, "clave": ck})
	for g: Array in GENERALES:
		_catalogo.append({"accion": g[0], "nombre": g[1], "grupo": "General", "tecla": int(g[2]), "destino": g[3], "clave": "general:" + String(g[0])})
	return _catalogo

## La acción del catálogo para una clave de `MIGRACION` («menu:…» o «sub:…»), o "".
static func accion_de_clave(clave: String) -> String:
	for e: Dictionary in catalogo():
		if String(e["clave"]) == clave:
			return String(e["accion"])
	return ""

## Mete las acciones en el InputMap (si no estaban) con su tecla por defecto, si la tienen.
static func registrar() -> void:
	for e: Dictionary in catalogo():
		var accion := String(e["accion"])
		if InputMap.has_action(accion):
			continue
		InputMap.add_action(accion)
		if int(e["tecla"]) != 0:
			var ev := InputEventKey.new()
			ev.physical_keycode = int(e["tecla"]) as Key
			InputMap.action_add_event(accion, ev)

## [acción, nombre, grupo] de todos, para la lista de teclas reasignables (en el orden del panel lateral).
static func lista() -> Array:
	var out: Array = []
	for e: Dictionary in catalogo():
		out.append([e["accion"], e["nombre"], e["grupo"]])
	return out

## Si `ev` es un atajo, lo ejecuta en la pantalla principal `p` y devuelve true.
static func manejar(p: Principal, ev: InputEvent) -> bool:
	if not (ev is InputEventKey) or not (ev as InputEventKey).pressed or (ev as InputEventKey).echo:
		return false
	var k := ev as InputEventKey
	if k.ctrl_pressed or k.alt_pressed or k.meta_pressed:
		return false
	## Escribiendo en un campo (buscador, móvil, nombres), las teclas son letras.
	var foco := p.get_viewport().gui_get_focus_owner()
	if foco is LineEdit or foco is TextEdit:
		return false
	for e: Dictionary in catalogo():
		var accion := String(e["accion"])
		if not InputMap.has_action(accion) or not ev.is_action_pressed(accion):
			continue
		var destino: Variant = e["destino"]
		if destino is Dictionary:
			if p._menu_lateral == null or p.mundo == null:
				return false
			p._menu_lateral.abrir_menu(String(destino["menu"]), int(destino["sub"]))
		elif destino == "dia":
			p._avanzar_dia()
		elif destino == "buscar":
			var b: LineEdit = p.get("_buscador")
			if b != null:
				b.grab_focus()
		elif destino == "guardar":
			p._guardar()
		return true
	return false
