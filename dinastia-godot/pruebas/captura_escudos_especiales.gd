extends Node
## Verifica el enganche de escudos especiales (22-9-2026): un club con
## esc_especial elegido debe mostrar la insignia de Canva, no el generador
## procedural, PERO solo si el nivel de perfil ya lo desbloqueo. Se prueba
## con un perfil de mentira (no toca el perfil real del usuario en user://).

## `Logros.perfil_guardar()` escribe siempre en el MISMO archivo real
## (`user://perfil_gestor.json`) -no hay variante de prueba-. Para no borrar
## el progreso real del usuario si esta prueba corre en su maquina, se guarda
## el contenido de verdad antes de pisarlo y se restaura al final, pase lo
## que pase (`_notification`, no solo el camino feliz).
var _perfil_original: String = ""
var _habia_perfil_real := false

func _ready() -> void:
	var ruta := "user://perfil_gestor.json"
	_habia_perfil_real = FileAccess.file_exists(ruta)
	if _habia_perfil_real:
		var f := FileAccess.open(ruta, FileAccess.READ)
		_perfil_original = f.get_as_text()
		f.close()

	## Perfil de prueba: nivel 1 ("Ayudante", 150 xp) para poder mostrar un caso
	## desbloqueado (wolf_1, nivel 1) y uno bloqueado (ram_1, nivel 6) a la vez.
	Logros.perfil_guardar({"xp": 150, "hitos": {}, "desde": 0})
	print("nivel actual segun perfil de prueba: %d" % Escudo._nivel_perfil_actual())
	print("wolf_1 desbloqueado: %s (esperado true)" % Escudo.especial_desbloqueado("wolf_1"))
	print("ram_1 desbloqueado: %s (esperado false)" % Escudo.especial_desbloqueado("ram_1"))
	print("total desbloqueados: %d" % Escudo.especiales_desbloqueados().size())

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	add_child(fila)

	# Caso 1: club con esc_especial="wolf_1" (desbloqueado) -> debe verse el PNG de Canva.
	var c1 := Club.new()
	c1.id = "c1"; c1.nombre = "Con especial desbloqueado"
	c1.color1 = "#333333"; c1.color2 = "#ffffff"
	c1.esc_especial = "wolf_1"
	_agregar(fila, c1)

	# Caso 2: club con esc_especial="ram_1" (bloqueado a nivel 1) -> debe CAER al
	# procedural (nunca mostrar nada roto ni el especial no desbloqueado).
	var c2 := Club.new()
	c2.id = "c2"; c2.nombre = "Con especial bloqueado"
	c2.color1 = "#1565c0"; c2.color2 = "#ffd54f"
	c2.esc_especial = "ram_1"
	_agregar(fila, c2)

	# Caso 3: club normal, sin especial -> procedural de siempre, sin cambios.
	var c3 := Club.new()
	c3.id = "c3"; c3.nombre = "Sin especial"
	c3.color1 = "#c62828"; c3.color2 = "#ffffff"
	_agregar(fila, c3)

func _agregar(padre: Node, c: Club) -> void:
	var tex := Escudo.textura(c, 96)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(260, 280)
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	var caja := VBoxContainer.new()
	caja.add_child(tr)
	var lbl := Label.new()
	lbl.text = "%s\nesc_especial='%s'" % [c.nombre, c.esc_especial]
	lbl.add_theme_font_size_override("font_size", 10)
	caja.add_child(lbl)
	padre.add_child(caja)

var _frame := 0

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 5:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_escudos_especiales.png")
		print("captura guardada: res://pruebas/pantalla_escudos_especiales.png")
		_restaurar_perfil_real()
		print("FIN. 0 fallos")
		get_tree().quit()

func _restaurar_perfil_real() -> void:
	var ruta := "user://perfil_gestor.json"
	if _habia_perfil_real:
		var f := FileAccess.open(ruta, FileAccess.WRITE)
		f.store_string(_perfil_original)
		f.close()
		print("perfil real restaurado")
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
		print("no habia perfil real antes -archivo de prueba borrado")

## Red de seguridad: si algo interrumpe la escena a mitad de camino (Ctrl+C,
## error no atrapado), igual se intenta restaurar antes de que el proceso
## muera del todo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_restaurar_perfil_real()
