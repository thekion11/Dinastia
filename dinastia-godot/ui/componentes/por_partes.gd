class_name PorPartes
extends RefCounted
## LISTAS LARGAS ARMADAS POR PARTES (15-11-2026, meta del dueño: que los menús no tarden). Una lista de N elementos se arma en una caja
## PROPIA: los primeros `por_fotograma` al momento (lo que se ve al entrar) y el resto en los fotogramas siguientes, siempre al final de
## esa caja, así el orden es el de siempre aunque después de la caja haya más cosas. Sin pantalla (pruebas) se arma entero al momento,
## para que las comprobaciones vean la lista completa. `crear.call(caja, i)` añade a `caja` lo del elemento `i`.
## Ojo: Godot ya no DIBUJA lo que queda fuera de la pantalla; lo que cuesta es CREAR y COLOCAR los nodos, y eso es lo que se reparte aquí.

static func llenar(padre: Container, n: int, crear: Callable, por_fotograma := 12) -> VBoxContainer:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override("separation", padre.get_theme_constant("separation") if padre is BoxContainer else 4)
	padre.add_child(caja)
	var al_momento := n if DisplayServer.get_name() == "headless" else mini(n, por_fotograma)
	for i in al_momento:
		crear.call(caja, i)
	if al_momento < n:
		_resto(caja, al_momento, n, crear, por_fotograma)
	return caja

static func _resto(caja: VBoxContainer, desde: int, n: int, crear: Callable, por_fotograma: int) -> void:
	var i := desde
	while i < n:
		if not is_instance_valid(caja) or not caja.is_inside_tree():
			return
		await caja.get_tree().process_frame
		if not is_instance_valid(caja) or not caja.is_inside_tree() or caja.is_queued_for_deletion():
			return
		var hasta := mini(n, i + por_fotograma)
		while i < hasta:
			crear.call(caja, i)
			i += 1
