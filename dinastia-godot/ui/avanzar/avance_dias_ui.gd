class_name AvanceDiasUI
extends RefCounted
## EL BOTÓN «AVANZAR» NUEVO (paso 3, 17-11-2026). Reemplaza al avance por semanas del menú central: lleva el avance DÍA A DÍA con `AvanceDias`, abre la pantalla
## `PantallaAvanzar`, atiende lo que hay en la parada (eventos importantes a pantalla completa, avisos con campana roja en el mosaico) y, en un día de partido,
## deja «Jugar partido» y «Saltar partido» donde estaba Avanzar. Todo lo de arriba conserva el menú central tal cual: solo cambian los botones de la fila.
## La semana real sigue corriéndola `AvanceSemana._avanzar_semana` (con `partido_obliga` apagado mientras rueda, porque el sábado de partido ya se detuvo antes).

var p: Principal
var _est: Dictionary = {}
var _mundo_id := 0
var _abs_vista := -999
var _arrastre: Array = []       ## eventos del domingo de la semana que cerró el partido: salen en la siguiente parada
var _arrastre_unix := 0
var en_curso := false
## Pruebas y banco: sin pantalla (no hay ventana) el avance corre igual, pero no abre nada.
static var sin_pantalla := false

func _init(principal: Principal) -> void:
	p = principal

func _abs() -> int:
	return p.mundo.anio * 60 + p.mundo.semana

func _estado() -> Dictionary:
	if p.mundo.get_instance_id() != _mundo_id:
		_mundo_id = p.mundo.get_instance_id()
		_est = DisparadoresDia.nuevo_estado()
		_abs_vista = -999
		_arrastre = []
		CampanasMenu.limpiar()
	return _est

func _con_pantalla() -> bool:
	return not sin_pantalla and DisplayServer.get_name() != "headless"

## ¿Hoy hay partido tuyo sin jugar? (sábado de la semana en curso)
func partido_hoy() -> bool:
	if p.mundo == null:
		return false
	_estado()
	return p._dia_semana == EventosFecha.DIA_PARTIDO and _abs() == _abs_vista and p._avance._tiene_partido_pendiente()

## Qué botones se ven: «Avanzar» (nada de partido hoy), «Jugar partido» y «Saltar partido» (día de partido) o «Temporada siguiente» (liga terminada).
func actualizar_botones() -> void:
	var caja: Variant = p._guia.nodos.get("avanzar_caja")
	if not is_instance_valid(caja) or p.mundo == null:
		return
	var fin := not p.mundo.temporada_en_curso()
	var hoy := partido_hoy()
	for nombre: String in ["avanzar", "jugar", "saltar", "temporada"]:
		var b: Variant = p._guia.nodos.get("b_" + nombre)
		if is_instance_valid(b):
			(b as Button).visible = (nombre == "avanzar" and not hoy and not fin) or (nombre in ["jugar", "saltar"] and hoy) or (nombre == "temporada" and fin)

## EL BOTÓN «AVANZAR».
func pulsar() -> void:
	if p.mundo == null or en_curso:
		return
	var m := p.mundo
	if not m.temporada_en_curso():
		p._escribir("[color=#e05555]%s[/color]" % Idiomas.t("La temporada está terminada. Pulsa «Temporada siguiente»."))
		return
	if partido_hoy():
		actualizar_botones()
		return
	en_curso = true
	AvanceSemana.dias_en_curso = true
	var est := _estado()
	CampanasMenu.limpiar()
	var dia := p._dia_semana if _abs() == _abs_vista else -1
	var unix0 := Calendario.unix_de(m.anio, m.semana, dia)
	var res: Dictionary
	if not _arrastre.is_empty():   ## el domingo que quedó atrás al jugar o saltar el partido
		res = {"dia": 6, "eventos": _arrastre, "plan": EventosDia.plan_de_parada(_arrastre), "pasados": [{"dia": 6, "mes": 1, "dia_mes": 1}], "fin": false}
		unix0 = _arrastre_unix - 86400
		_arrastre = []
		dia = -1
	else:
		var rodar := func() -> void:
			var antes := AvanceSemana.partido_obliga
			AvanceSemana.partido_obliga = false
			p._avance._avanzar_semana()
			AvanceSemana.partido_obliga = antes
		res = AvanceDias.avanzar(m, est, dia, rodar)
	p._dia_semana = int(res["dia"])
	_abs_vista = _abs()
	if _con_pantalla():
		var pantalla: Variant = load("res://ui/avanzar/pantalla_avanzar.gd").mostrar(p, m, unix0, res)
		await pantalla.cerrado
		pantalla.queue_free()
	var plan: Dictionary = res["plan"]
	for ev: Dictionary in plan["pantallas"]:
		await _pantalla_de(ev)
	CampanasMenu.anotar(plan["avisos"])
	en_curso = false
	AvanceSemana.dias_en_curso = false
	p._refrescar()
	if _con_pantalla():
		Callable(load("res://ui/principal/jornada_eventos.gd"), "ofrecer").call_deferred(p)   ## lo que aún atiende el avance semanal (club con diálogo, fecha FIFA)

## Un evento importante a pantalla completa. La memoria y la independencia usan su pantalla de reflexión; el resto, la tarjeta genérica.
func _pantalla_de(ev: Dictionary) -> void:
	if not _con_pantalla():
		return
	if String(ev.get("subtipo", "")) in ["memoria", "independencia"]:
		var clave := DiasMemoria.clave_de(String(ev.get("pais", "")), p.mundo.anio, String(ev.get("nombre", "")))
		DiasMemoria.marcar(p.mundo, {"clave": clave})
		var refl := EventoReflexion.mostrar(p, {"tipo": String(ev["subtipo"]), "nombre": ev["nombre"], "pais": ev["pais"], "dia": ev["dia_mes"], "mes": ev["mes"], "texto": ev["texto"], "reflexion": ev["reflexion"]})
		await refl.elegido
		refl.queue_free()
		return
	if String((ev.get("causa", {}) as Dictionary).get("id", "")) == "oferta_seleccion":
		await load("res://ui/principal/jornada_seleccion.gd").ofrecer_cargo(p)
		return
	if String(ev.get("tipo", "")) == "fin":
		return   ## el cierre de temporada lo abre `AvanceSemana` (despedida y resumen) al refrescar
	var t: Variant = load("res://ui/avanzar/evento_dia_pantalla.gd").mostrar(p, ev, p.mundo)
	await t.elegido
	t.queue_free()

## «Jugar partido»: el partido de hoy con el menú de siempre (en el paso 6 se rehace como menú del partido).
func jugar() -> void:
	if partido_hoy():
		_guardar_domingo()
		p._dirigir()

## «Saltar partido»: se simula con el resultado en pantalla (la semana corre como si se hubiera avanzado sin jugar).
func saltar() -> void:
	if not partido_hoy():
		return
	_guardar_domingo()
	var antes := AvanceSemana.partido_obliga
	AvanceSemana.partido_obliga = false
	p._avance._avanzar_semana()
	AvanceSemana.partido_obliga = antes
	p._dia_semana = 0
	p._refrescar()

## Lo que pasa el domingo (mercado que cierra, fechas del país) no se pierde porque el partido ya hizo correr la semana.
func _guardar_domingo() -> void:
	var m := p.mundo
	_arrastre = []
	for ev: Dictionary in EventosDia.del_dia(m, 0, 6):
		if String(ev.get("clase", "")) != EventosDia.PARTIDO and String(ev.get("tipo", "")) != "fin":
			_arrastre.append(ev)
	_arrastre_unix = Calendario.unix_de(m.anio, m.semana, 6)
