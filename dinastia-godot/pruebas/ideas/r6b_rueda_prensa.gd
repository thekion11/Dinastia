extends BaseIdea
## FASE 0, paso 6b: la rueda de prensa 2D salió de `Principal` a su clase
## (`ui/principal/rueda_prensa.gd`). Comprueba que Principal solo la abre, que
## responder la cierra (o repregunta en el mismo plató) y que la pregunta dura
## de la primera rueda de un club que compró su plaza llega a `Prensa`.
##
##   herramientas/ideas.sh r6b_rueda_prensa

const _Rueda := preload("res://ui/principal/rueda_prensa.gd")

func _probar() -> void:
	_titulo("FASE 0 (6b): rueda de prensa en su clase")
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	_abrir_y_responder(pr)
	_texto_libre(pr)
	pr.queue_free()
	_primera_rueda()

## Índice de la opción más tranquila (la que menos invita a repreguntar).
func _calma(e: Dictionary) -> int:
	var ops: Array = e.get("opciones", [])
	for i in ops.size():
		if String((ops[i] as Dictionary).get("tono", "")) == "calma":
			return i
	return 0

func _abrir_y_responder(pr: Principal) -> void:
	var prensa := pr.mundo.prensa
	prensa.abrir_rueda(true, false)
	_comprobar(prensa.hay_rueda(), "Prensa abre una rueda")
	pr._abrir_rueda_pantalla_completa(prensa.entrevista)
	var r := pr._rueda_pop as _Rueda
	_comprobar(r != null and r.get_parent() == pr, "Principal la abre: un nodo de la clase nueva, hijo de Principal")
	_comprobar(r != null and r.is_in_group(MentorVoz.GRUPO_TAPA), "tapa al mentor mientras dura")
	_comprobar(not is_instance_valid(pr._panel_obj) or not pr._panel_obj.visible, "el panel de objetivos no se ve durante la rueda")
	## 26-10: el plató 3D ocupa la pantalla y la interfaz va encima (franja
	## de TV abajo y columna de respuestas a la derecha, sin solaparse).
	_comprobar(r != null and r.get_node_or_null("Plato") is SubViewportContainer, "el camino normal es el plató 3D a pantalla completa")
	var col := r.get_node_or_null("Capa/Columna") as Control if r != null else null
	var franja := r.get_node_or_null("Capa/Franja") as Control if r != null else null
	_comprobar(col != null and franja != null, "hay franja de TV y columna de respuestas")
	if col != null and franja != null:
		_comprobar(col.get_global_rect().end.y <= franja.get_global_rect().position.y + 0.5, "la columna termina encima de la franja: no se pisan")
	_comprobar(r != null and r._pregunta.text == String(prensa.entrevista.get("pregunta", "")), "la pregunta en pantalla es la de Prensa")
	var nops := (prensa.entrevista.get("opciones", []) as Array).size()
	_comprobar(r != null and r._opciones.get_child_count() == nops, "un botón por opción (%d)" % nops)
	## Puente `_rueda_desde`: lo ajustan las capturas para simular titubeo.
	pr._rueda_desde = 1234
	_comprobar(r != null and r.desde == 1234 and pr._rueda_desde == 1234, "el puente _rueda_desde llega a la rueda")
	## Tocar una postura repinta solo ese bloque.
	var fila_vieja: Control = r._posturas if r != null else null
	var idx := fila_vieja.get_index() if fila_vieja != null else -1
	prensa.fijar_cuerpo("dubitativo")
	pr._repintar_posturas()
	_comprobar(r != null and r._posturas != fila_vieja and r._posturas.get_index() == idx, "repintar_posturas cambia solo el bloque de posturas, en su sitio")
	var vueltas := 0
	while pr._rueda_pop != null and vueltas < 5:
		pr._responder(_calma(prensa.entrevista))
		vueltas += 1
	_comprobar(pr._rueda_pop == null and not prensa.hay_rueda(), "responder la cierra (%d respuesta/s) y Prensa la da por cerrada" % vueltas)
	_comprobar(r == null or r.is_queued_for_deletion(), "el nodo de la rueda se libera al cerrar")
	pr._responder(0)   ## sin rueda abierta: no revienta
	_comprobar(pr._rueda_pop == null, "responder sin rueda no abre nada")

func _texto_libre(pr: Principal) -> void:
	var prensa := pr.mundo.prensa
	prensa.abrir_rueda(false, false)
	pr._abrir_rueda_pantalla_completa(prensa.entrevista)
	var r := pr._rueda_pop as _Rueda
	var vueltas := 0
	while r != null and pr._rueda_pop == r and vueltas < 5:
		r.tras_responder(prensa.responder_texto("Respeto al rival y a seguir trabajando", r.segundos()))
		vueltas += 1
	_comprobar(pr._rueda_pop == null, "responder con texto libre también la cierra")

## La primera rueda de un club que compró su plaza trae su pregunta dura, una vez.
func _primera_rueda() -> void:
	var m := _mundo(2501)
	var dura := EntradaCampeonato.pregunta_primera_rueda({"modo": EntradaCampeonato.MODO_CONFEDERACION})
	_comprobar(not dura.is_empty(), "hay pregunta dura para el club que paga su plaza")
	_comprobar(EntradaCampeonato.pregunta_primera_rueda({"modo": "reemplazar"}).is_empty(), "reemplazar un club no trae pregunta dura")
	m.prensa.pregunta_pendiente = dura
	m.prensa.abrir_rueda(true, false)
	## El periodista se la apropia: `_poner_periodista()` le quita el «Prensa: ».
	var hecha := String(dura["pregunta"]).trim_prefix("Prensa: ")
	_comprobar(String(m.prensa.entrevista.get("pregunta", "")) == hecha, "la primera rueda usa la pregunta pendiente")
	_comprobar(m.prensa.pregunta_pendiente.is_empty(), "y se gasta: no se repite")
	m.prensa.responder(0)
	m.prensa.abrir_rueda(true, false)
	_comprobar(String(m.prensa.entrevista.get("pregunta", "")) != hecha, "la segunda rueda ya es la de siempre")
