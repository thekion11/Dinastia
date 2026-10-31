extends BaseIdea
## M-303 (28-10-2026): pestañas y listas con el mismo sonido de interfaz que los botones (`BotonFx`).
##   herramientas/ideas.sh fx_pestanas

func _probar() -> void:
	_titulo("M-303: SONIDO EN PESTAÑAS Y LISTAS")
	BotonFx.activar(get_tree())
	var tc := TabContainer.new()
	tc.add_child(Control.new())
	tc.add_child(Control.new())
	var il := ItemList.new()
	il.add_item("uno")
	var tr := Tree.new()
	add_child(tc)
	add_child(il)
	add_child(tr)
	_comprobar(tc.get_tab_bar().has_meta("_fx"), "la barra de un TabContainer queda enganchada")
	_comprobar(il.has_meta("_fx") and tr.has_meta("_fx"), "ItemList y Tree también")
	var antes := int(BotonFx._ultimo_ms.get("clic", -1000))
	BotonFx._ultimo_ms["clic"] = -1000
	il.item_selected.emit(0)
	_comprobar(int(BotonFx._ultimo_ms.get("clic", -1000)) > 0, "elegir en una lista hace «clic»")
	BotonFx._ultimo_ms["clic"] = antes
	tc.queue_free()
	il.queue_free()
	tr.queue_free()
