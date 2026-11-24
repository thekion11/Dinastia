extends "res://pruebas/banco/varios_p5.gd"
## [Capa 6b de `varios.gd`] _revisar_paso: revisa un paso del guion del tutorial.
const OBJETIVOS := ["estado", "grupos", "chips", "plantel", "ficha", "dinero", "partido",
	"tabla", "registro", "avanzar", "guardar"]
const SIMPLES := ["grupo", "ficha", "grupo_club", "plantel", "dinero", "partido", "menu"]

## Un paso del guion: misiones con forma de cumplirse, objetivos válidos y «hecho»/«mostrar».
## Devuelve 1 si el paso es una misión (para contarlas).
func _revisar_paso(modo: String, p: Dictionary, m: Mundo, malos: Array[String]) -> int:
	var cuenta := 0
	if p.has("mision"):
		cuenta += 1
		if not p.has("hecho"):
			malos.append("%s: misión sin forma de cumplirse (%s)" % [modo, p["mision"]])
	## (3-11, rediseño del menú central) También «riel» y «menu:<id>» (el botón del riel de ese menú).
	var obj := String(p.get("objetivo", ""))
	if obj.begins_with("menu:") and not MenusLaterales.menu_por_id(obj.substr(5)).is_empty():
		pass
	elif p.has("objetivo") and obj != "riel" and not OBJETIVOS.has(obj):
		malos.append("%s: objetivo %s" % [modo, p["objetivo"]])
	for k in ["hecho", "mostrar"]:
		if not p.has(k):
			continue
		var v := String(p[k])
		var ok := SIMPLES.has(v)
		if v.begins_with("tab:"):
			ok = Tutorial.PESTANAS.has(v.substr(4))
		elif v.begins_with("chip:"):
			ok = Tutorial.CHIPS.has(v.substr(5))
		elif v.begins_with("ficha:"):
			ok = false
			for j: Jugador in m.mi_club().plantilla:
				if j.id == v.substr(6):
					ok = true
		if not ok:
			malos.append("%s: %s %s" % [modo, k, v])
	return cuenta

