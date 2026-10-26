class_name PartidoPendiente
extends RefCounted
## EL PARTIDO QUE SE ABANDONA A MEDIAS (17-10-2026, caza de bugs). Antes, si ibas
## perdiendo y cerrabas el juego en mitad de un partido dirigido, al cargar se
## volvía a jugar desde el 0-0 (el guardado solo se hace al avanzar la semana),
## y se podía repetir hasta ganar. Ahora, al empezar, se apunta el partido en
## `user://partido_en_curso.cfg` y se va poniendo al día (marcador y minuto);
## al terminarlo se borra. Si al cargar la partida sigue ahí y es de esta misma
## semana, el partido se completa solo DESDE ese marcador, con un azar fijo para
## ese partido: recargar diez veces da diez veces el mismo resultado.

const RUTA := "user://partido_en_curso.cfg"

static func abrir(m: Mundo, p: Partido) -> void:
	_escribir(m, p)

static func actualizar(m: Mundo, p: Partido) -> void:
	if FileAccess.file_exists(RUTA):
		_escribir(m, p)

static func cerrar() -> void:
	if FileAccess.file_exists(RUTA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))

static func _escribir(m: Mundo, p: Partido) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("p", "anio", m.anio)
	cfg.set_value("p", "semana", m.semana)
	cfg.set_value("p", "local", p.local.id)
	cfg.set_value("p", "visita", p.visita.id)
	cfg.set_value("p", "gl", p.goles_local)
	cfg.set_value("p", "gv", p.goles_visita)
	cfg.set_value("p", "minuto", p.minuto)
	## La táctica de antes del plan y el cambio que saltó: el guardado tiene
	## la de antes, así que al completar el partido hay que saber si el plan
	## ya estaba puesto, y devolverla y contar la racha al final.
	cfg.set_value("p", "previa", p.tactica_previa)
	cfg.set_value("p", "plan_act", p.plan_activado)
	cfg.save(RUTA)

## Lo apuntado si es de la semana en curso de este mundo; vacío si no.
static func pendiente(m: Mundo) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return {}
	if int(cfg.get_value("p", "anio", -1)) != m.anio or int(cfg.get_value("p", "semana", -1)) != m.semana:
		return {}
	return {"local": String(cfg.get_value("p", "local", "")), "visita": String(cfg.get_value("p", "visita", "")),
		"gl": int(cfg.get_value("p", "gl", 0)), "gv": int(cfg.get_value("p", "gv", 0)),
		"minuto": int(cfg.get_value("p", "minuto", 0)),
		"previa": cfg.get_value("p", "previa", {}), "plan_act": cfg.get_value("p", "plan_act", {})}

## Completa el partido apuntado desde su marcador y minuto. Devuelve el Partido
## terminado (o null si ya no cuadra con el mundo).
static func resolver(m: Mundo, d: Dictionary) -> Partido:
	var a: Club = m.clubes.get(String(d.get("local", "")))
	var b: Club = m.clubes.get(String(d.get("visita", "")))
	if a == null or b == null:
		cerrar()
		return null
	var p := Partido.new(a, b)
	p.preparar()
	p.goles_local = int(d["gl"])
	p.goles_visita = int(d["gv"])
	## Archivos de antes del 25-10 no traen estas dos claves: {} = sin plan.
	var previa: Variant = d.get("previa", {})
	var act: Variant = d.get("plan_act", {})
	p.tactica_previa = (previa as Dictionary).duplicate(true) if previa is Dictionary else {}
	p.plan_activado = (act as Dictionary).duplicate(true) if act is Dictionary else {}
	## Ya pitado el final (se cerró en la charla de después): ese es el resultado.
	if int(d["minuto"]) >= 90:
		p.minuto = 90
		p.terminado_ya = true
		p._devolver_tactica()
		p.guardar_si_es_mio()
		cerrar()
		return p
	p.minuto = clampi(int(d["minuto"]), 0, 89)
	## Pasado el 60 el plan ya se decidió (saltara o no): no se vuelve a mirar.
	if p.minuto >= 60:
		p._plan_aplicado = true
		p._reaplicar_plan()
	## El azar de este partido sale de quién juega y cuándo: siempre el mismo.
	Azar.sembrar(absi(hash("%s|%s|%d|%d" % [a.id, b.id, m.anio, m.semana])) + 1)
	while not p.terminado_ya:
		p.simular_minuto()
	p._cerrar_notas()
	p.guardar_si_es_mio()
	Azar.sembrar(0)
	cerrar()
	return p
