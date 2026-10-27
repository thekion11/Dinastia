extends "res://ui/principal_p10.gd"
## [Capa 11/17 de `principal.gd`] _retrato, _nombres… y los puentes a `PantallaElegirClub` y `JornadaPartido`

## Puentes (fase 6, paso 4): elegir club vive en `PantallaElegirClub`.
func _al_elegir_club(indice: int) -> void: _ui_elegir_club._al_elegir_club(indice)
func _llenar_selector() -> void: _ui_elegir_club._llenar_selector()
func _tomar_club(id: String) -> void: _ui_elegir_club._tomar_club(id)
func _pintar_elegir_club(col: VBoxContainer) -> void: _ui_elegir_club._pintar_elegir_club(col)
func _abrir_elegir_club() -> void: _ui_elegir_club._abrir_elegir_club()

## Puentes (fase 6, paso 7): la jornada de partido vive en `JornadaPartido`.
func _modo_simulacion(comp: String) -> String: return _jornada._modo_simulacion(comp)
func _competicion_de_la_semana() -> String: return _jornada._competicion_de_la_semana()
func _apuntar_partido_en_curso(p: Partido) -> void: _jornada._apuntar_partido_en_curso(p)
func _seguir_tras_partido(p: Partido) -> void: _jornada._seguir_tras_partido(p)
func _cerrar_partido_dirigido(p: Partido) -> void: _jornada._cerrar_partido_dirigido(p)
func _perfil_con_clima(p: Partido) -> Dictionary: return _jornada._perfil_con_clima(p)
func _dirigir() -> void: _jornada._dirigir()
func _jugar_temporada() -> void: _jornada._jugar_temporada()

## Una fila de jugador que se puede pulsar. El botón va en la primera celda y
## ocupa el ancho: así toda la fila responde al clic sin tener que inventar un
## control nuevo ni capturar eventos a mano.
## EL RETRATO DE UN JUGADOR, EN UN SOLO SITIO. Antes cada pantalla lo montaba
## por su cuenta -cuatro trozos de código casi iguales- y por eso la mayoría
## simplemente no lo ponía: en cantera, enfermería, camarín, contratos,
## selección o el árbol genealógico un futbolista era una línea de texto.
##
## Y eso se notaba justo donde más duele: un jugador REAL con su foto de verdad
## encontrada en Commons aparecía con foto en el plantel y sin ella en la
## enfermería, como si fuera otra persona. `Cara.textura()` ya resuelve foto real
## primero y dibujo procedural después; lo único que faltaba era llamarla desde
## todas partes.
func _retrato(j: Jugador, tam: int = 26) -> TextureRect:
	var equipo: Club = mundo.clubes.get(j.club_id)
	var r := TextureRect.new()
	r.texture = Cara.textura(j, equipo.color1 if equipo else "#2b6b45",
		equipo.color2 if equipo else "#ffffff", tam)
	r.custom_minimum_size = Vector2(tam, tam)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _nombres(clubes: Array) -> String:
	var l: Array[String] = []
	for c: Club in clubes:
		l.append(c.nombre)
	return ", ".join(l)

func _nombres_jugadores(l: Array[Jugador]) -> String:
	var n: Array[String] = []
	for j in l:
		n.append(j.nombre)
	return ", ".join(n)
