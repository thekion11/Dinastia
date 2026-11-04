extends BaseIdea
## R2 (3-11): en MÍNIMO el entorno exterior del estadio se oculta mientras la cámara está dentro del recinto y baja, y vuelve al salir o subir; en otros niveles o con un lado abierto no se monta.

func _probar() -> void:
	_titulo("P6: ENTORNO DEL ESTADIO TAPADO POR LAS GRADAS (MINIMO Y MEDIO)")
	var raiz := Node3D.new()
	add_child(raiz)
	var e := Node3D.new()
	e.name = "EntornoEstadio"
	raiz.add_child(e)
	var antes := Calidad.elegida
	Calidad.elegida = Calidad.ALTO
	EntornoOclusion.montar(e, 100.0, 120.0, {})
	_comprobar(raiz.get_node_or_null("EntornoOclusion") == null, "en ALTO no se monta (en MÍNIMO y MEDIO sí: orden 32)")
	Calidad.elegida = Calidad.MINIMO
	EntornoOclusion.montar(e, 100.0, 120.0, {"abiertas": [0]})
	_comprobar(raiz.get_node_or_null("EntornoOclusion") == null, "con un lado abierto no se monta")
	EntornoOclusion.montar(e, 100.0, 120.0, {})
	var o := raiz.get_node_or_null("EntornoOclusion") as EntornoOclusion
	_comprobar(o != null, "en MÍNIMO y estadio cerrado se monta")
	if o != null:
		_comprobar(o.tapado(Vector3(0, 12, 0)), "cámara dentro y baja: el entorno queda tapado")
		_comprobar(not o.tapado(Vector3(0, 80, 0)), "cámara alta: se ve")
		_comprobar(not o.tapado(Vector3(150, 12, 0)), "cámara fuera del recinto: se ve")
	Calidad.elegida = antes
