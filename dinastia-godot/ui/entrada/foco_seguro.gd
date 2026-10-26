class_name FocoSeguro
## Da el foco al control en el siguiente cuadro, pero solo si sigue vivo y dentro del
## árbol: las pantallas de la entrada pueden cerrarse en el mismo cuadro en que se crean.

static func dar(c: Control) -> void:
	(func() -> void:
		if is_instance_valid(c) and c.is_inside_tree():
			c.grab_focus()).call_deferred()
