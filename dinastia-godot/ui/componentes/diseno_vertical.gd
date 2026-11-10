class_name DisenoVertical
extends RefCounted
## DISEÑO PROPIO PARA EL MÓVIL DE PIE (10-11-2026, orden 36, sesión 8). El menú está dibujado para un lienzo ancho (filas de botones, tres
## columnas, riel a la izquierda). De pie, el lienzo es de `EscalaMovil.ANCHO_VERTICAL` px: aquí vive lo que lo recoloca SIN tocar el
## horizontal ni el PC: la barra de abajo (`MenuLateral`), las filas que se deslizan de lado y las columnas que se apilan.
## Nada de esto hace nada si `EscalaMovil.es_vertical()` es falso. No nombra clases del partido ni de la ciudad (regla de memoria del menú).

static func activo() -> bool:
	return EscalaMovil.es_vertical()

## Una fila ancha (días, próximos partidos, botones de acción) pasa a deslizarse de lado en vez de empujar la pantalla. Devuelve el
## contenedor que cuelga del padre (la fila misma si no es de pie). La fila se añade aquí: no hay que añadirla antes.
static func fila_deslizable(padre: Control, fila: BoxContainer) -> Control:
	if not activo():
		padre.add_child(fila)
		return fila
	var d := ScrollContainer.new()
	d.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	d.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(d)
	d.add_child(fila)
	return d

## Columnas lado a lado → una debajo de otra, dentro de un desplazamiento vertical. `altos` = alto mínimo de cada columna (0 = el natural).
## Devuelve el desplazamiento (que toma el lugar de `columnas` en su padre).
static func apilar(columnas: HBoxContainer, altos: Array = []) -> Control:
	if not activo():
		return columnas
	var padre := columnas.get_parent()
	var pos := columnas.get_index()
	var vertical := ScrollContainer.new()
	vertical.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## (una HBoxContainer no puede cambiar de orientación: se pasa su contenido a una VBoxContainer)
	var pila := VBoxContainer.new()
	pila.add_theme_constant_override("separation", 12)
	pila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.remove_child(columnas)
	padre.add_child(vertical)
	padre.move_child(vertical, pos)
	vertical.add_child(pila)
	var hijos := columnas.get_children()
	for i in hijos.size():
		var c := hijos[i] as Control
		columnas.remove_child(c)
		pila.add_child(c)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_FILL
		c.size_flags_stretch_ratio = 1.0
		var alto := float(altos[i]) if i < altos.size() else 0.0
		c.custom_minimum_size.y = maxf(c.custom_minimum_size.y, alto)
	var hueco := Control.new()   ## aire al final: la chapa 🎯 flota abajo a la derecha y no debe tapar el último botón
	hueco.custom_minimum_size.y = 64.0
	pila.add_child(hueco)
	columnas.queue_free()
	return vertical
