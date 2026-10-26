extends BaseIdea
## FASE 0: `Principal` partida en clases (`ui/principal/`). Comprueba que cada
## responsabilidad separada hace lo mismo que hacía dentro de Principal y que
## los puentes de siempre (los que llaman pantallas, componentes y pruebas)
## siguen llevando a ella.
##
##   herramientas/ideas.sh f0p_principal

const RANURA_PRUEBA := "f0p_prueba"

func _probar() -> void:
	_titulo("FASE 0: Principal separada en clases")
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	_comprobar(pr.mundo != null and pr.mundo.mi_club() != null, "Principal arranca con un mundo y un club (ciclo_partida.nueva)")
	_estructura(pr)
	_noticias(pr)
	_sorteos(pr)
	_preferencias(pr)
	_partida(pr)
	_tutorial(pr)
	pr.queue_free()

func _estructura(pr: Principal) -> void:
	_comprobar(pr._sorteos != null and pr._sorteos.get_parent() == pr, "los sorteos son un nodo hijo de Principal")
	_comprobar(pr._noticias != null and pr._noticias.get_parent() == pr, "las noticias son un nodo hijo de Principal")
	_comprobar(pr._prefs != null and pr._partida != null and pr._guia != null, "preferencias, ciclo de partida y guía existen")

## Volver a conectar (como al cambiar de club) no duplica las noticias de los
## sistemas que sobreviven al cambio: una emisión, una fila en el correo.
func _noticias(pr: Principal) -> void:
	## Segunda pasada sobre el MISMO mundo, como al tomar otro club.
	pr._conectar_noticias()
	var m := pr.mundo
	var antes := pr._bandeja.size()
	m.roles.aviso.emit("Prueba f0p", "cuerpo")
	_comprobar(pr._bandeja.size() == antes + 1, "roles.aviso tras reconectar: una fila (sin duplicar)")
	antes = pr._bandeja.size()
	m.cesiones.noticia.emit("Prueba f0p", "cuerpo")
	_comprobar(pr._bandeja.size() == antes + 1, "cesiones.noticia: una fila")

## Un sorteo donde no juega tu club no se encola; uno donde sí, te toca.
func _sorteos(pr: Principal) -> void:
	var mio := pr.mundo.mi_club()
	var otros: Array[Club] = []
	for c: Club in pr.mundo.clubes.values():
		if c != mio and otros.size() < 2:
			otros.append(c)
	pr._encolar_sorteo({"tipo": "cruces", "clave": "copa", "ronda": "Octavos", "parejas": [[otros[0], otros[1]]]})
	_comprobar(pr._sorteos.pendientes() == 0 and not pr._sorteos.abierto(), "un sorteo ajeno no abre cinemática ni se encola")
	_comprobar(pr._sorteos._me_toca({"tipo": "cruces", "parejas": [[otros[0], mio]]}), "una eliminatoria con tu club sí te toca")
	_comprobar(pr._sorteos._me_toca({"tipo": "grupos", "grupos": [[otros[0]], [mio, otros[1]]]}), "un grupo con tu club sí te toca")
	pr._conectar_sorteos()
	pr._conectar_mi_continental()
	_comprobar(pr.mundo.copa == null or pr.mundo.copa.has_meta("_ui_conectado_sorteo"), "la copa queda con su candado de sorteo")

## Ida y vuelta por el archivo, y la firma que evita escribirlo sin cambios.
## Se deja el archivo del jugador como estaba.
func _preferencias(pr: Principal) -> void:
	var ruta := Principal.PREFS
	var habia := FileAccess.file_exists(ruta)
	var original := FileAccess.get_file_as_string(ruta) if habia else ""
	var escala := pr._escala_texto
	var dalt := pr._daltonico
	pr._escala_texto = 1.3
	pr._daltonico = not dalt
	pr._guardar_preferencias()
	_comprobar(FileAccess.file_exists(ruta), "guardar escribe el archivo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	pr._guardar_preferencias()
	_comprobar(not FileAccess.file_exists(ruta), "sin cambios no se vuelve a escribir (la firma)")
	pr._escala_texto = 1.0
	pr._guardar_preferencias()
	_comprobar(FileAccess.file_exists(ruta), "un cambio sí se escribe")
	pr._escala_texto = 1.3
	pr._daltonico = dalt
	pr._prefs._firma = ""
	pr._guardar_preferencias()
	pr._escala_texto = 0.9
	pr._daltonico = not dalt
	pr._cargar_preferencias()
	_comprobar(is_equal_approx(pr._escala_texto, 1.3) and pr._daltonico == dalt, "cargar recupera lo guardado")
	pr._escala_texto = escala
	pr._daltonico = dalt
	if habia:
		var f := FileAccess.open(ruta, FileAccess.WRITE)
		f.store_string(original)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	pr._prefs._firma = ""

## Deshacer por el puente de siempre, y cargar una ranura suelta al jugador
## seleccionado del mundo viejo (antes se quedaba enganchado).
func _partida(pr: Principal) -> void:
	var viejo := pr.mundo
	pr._partida.apuntar_deshacer("prueba f0p")
	_comprobar(pr._pila_deshacer.size() == 1, "la pila de deshacer se ve por el puente `_pila_deshacer`")
	pr._seleccionado = viejo.mi_club().plantilla[0]
	pr._deshacer()
	_comprobar(pr.mundo != viejo and pr.mundo != null, "deshacer cambia de mundo")
	_comprobar(pr._pila_deshacer.is_empty(), "deshacer vacía la pila")
	_comprobar(pr._seleccionado == null or not viejo.mi_club().plantilla.has(pr._seleccionado), "tras deshacer la ficha no es del mundo viejo")
	_comprobar(pr.mundo.copa == null or pr.mundo.copa.has_meta("_ui_conectado"), "el mundo nuevo tiene sus noticias conectadas")
	pr._partida.guardar_en(RANURA_PRUEBA)
	var antes := pr.mundo
	pr._seleccionado = antes.mi_club().plantilla[0]
	pr._partida.cargar_de(RANURA_PRUEBA)
	_comprobar(pr.mundo != antes and pr.mundo.mi_club().id == antes.mi_club().id, "cargar una ranura trae la partida guardada")
	_comprobar(pr._seleccionado == null or not antes.mi_club().plantilla.has(pr._seleccionado), "cargar una ranura suelta la ficha del mundo viejo")
	Partida.borrar(RANURA_PRUEBA)

func _tutorial(pr: Principal) -> void:
	_comprobar(pr.tutorial_objetivo("estado") == pr._sub, "tutorial_objetivo resuelve los controles con variable propia")
	_comprobar(pr.tutorial_objetivo("guardar") is Button, "tutorial_objetivo encuentra los nodos que registra _construir")
	_comprobar(pr.tutorial_objetivo("no_existe") == null, "una clave desconocida no señala nada")
	var titulo := pr._pestanas.get_tab_title(pr._pestanas.current_tab)
	_comprobar(pr.tutorial_hecho("tab:" + titulo), "tutorial_hecho reconoce la pestaña abierta")
	pr.tutorial_accion("tab:Finanzas")
	_comprobar(pr.tutorial_hecho("tab:Finanzas"), "tutorial_accion lleva a la pestaña pedida")
