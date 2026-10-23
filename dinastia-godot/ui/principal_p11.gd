extends "res://ui/principal_p11_p1.gd"
## [Capa 12/19 de `principal.gd`] _conectar_noticias_2, _conectar_noticias

## Tramo 2 de 2 de `_conectar_noticias` (la norma de 450 líneas la troceó).
func _conectar_noticias_2():
	## EL AUSPICIO. La pretemporada abre el mercado de marcas y sin aviso pasaria
	## desapercibido: es el unico ingreso grande del club que hay que ir a firmar.
	## LAS EPOCAS DORADAS. Una generacion entera de un pais entero, con fecha de
	## caducidad: si pasara sin aviso, no habria forma de aprovecharla.
	## LA CARRERA POR DENTRO: el rival personal que aparece solo, la leyenda que
	## se queda de por vida y los dividendos de tus clubes. Sin aviso, las tres
	## pasarian en silencio en una pestana que no se mira cada semana.
	## `roles` se crea una sola vez en `generar()` -`tomar_el_mando()` reusa el
	## mismo objeto, solo le cambia el capítulo (ver `roles.rol_cambiado` un
	## poco más arriba, que ya se guarda con `is_connected`)-: mismo candado
	## aquí, con clave propia para no chocar con el otro bloque de `roles` más
	## abajo (aviso/ascenso/interinato), que se guarda aparte.
	if mundo.roles != null and not mundo.roles.has_meta("_ui_conectado_carrera"):
		mundo.roles.set_meta("_ui_conectado_carrera", true)
		mundo.roles.noticia_carrera.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto))
	## LO COMERCIAL: zonas de camiseta, naming del estadio y palcos. Cada firma
	## y cada contrato que caduca son noticia: si pasaran callados, la pantalla
	## estaria llena de contratos que aparecen y desaparecen solos.
	## LA CIUDAD: permisos que se resuelven, sanciones que caducan y negocios que
	## se inauguran. El permiso tarda semanas y llega solo: sin aviso, el jugador
	## no se entera de que ya puede ampliar el estadio.
	if mundo.ciudad != null:
		mundo.ciudad.noticia.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto)
			Aviso.mostrar(self, "contrato", "🏙️", titulo, texto, "patrocinio_nuevo"))
		mundo.ciudad.movimiento.connect(mundo._anotar_movimiento)
	if mundo.junta != null and not mundo.junta.movimiento.is_connected(mundo._anotar_movimiento):
		mundo.junta.movimiento.connect(mundo._anotar_movimiento)
	if mundo.comercial != null:
		mundo.comercial.noticia.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto))
		mundo.comercial.movimiento.connect(mundo._anotar_movimiento)
	## `eras` es del MUNDO, no de tu club -se crea una vez en `generar()` y su
	## propio comentario dice que no se recrea al tomar el mando-, así que
	## necesita el mismo candado que `mercado`, `copa` y `cesiones`.
	if mundo.eras != null and not mundo.eras.has_meta("_ui_conectado"):
		mundo.eras.set_meta("_ui_conectado", true)
		mundo.eras.noticia.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto)
			Aviso.mostrar(self, "logro", "🌍", titulo, texto))
	if mundo.auspicio != null:
		mundo.auspicio.noticia.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#e0a832][b]%s.[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto)
			Aviso.mostrar(self, "contrato", "👕", titulo, texto, "patrocinio_nuevo"))
	if mundo.entrenamiento != null:
		mundo.entrenamiento.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#3fa06a][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
		## Otra señal muda: cada diez semanas ganas un punto para tu árbol y no
		## te enterabas de nada. Un punto sin gastar es de las pocas cosas del
		## juego que no caducan, así que merece aviso propio y no solo registro.
		mundo.entrenamiento.punto_dt_ganado.connect(func(total: int) -> void:
			Aviso.mostrar(self, "nivel", "🎓", "Punto de entrenador",
				"Tienes %d punto(s) para gastar en tus habilidades, en Club › Legado." % total))
		## `progreso` se emite cada vez que el entrenamiento semanal sube o baja el
		## OVR de un jugador -menores de 24 progresando, veteranos de 31+ apagándose-
		## y hasta hoy (14-9-2026) nadie la escuchaba: la única forma de enterarse
		## era abrir la ficha de cada jugador y comparar el número a ojo. Sin
		## `Aviso` modal a propósito -puede dispararse varias veces la misma
		## semana- , va al registro como el resto de novedades del plantel.
		mundo.entrenamiento.progreso.connect(func(j: Jugador, antes: int, ahora: int) -> void:
			if ahora == antes:
				return
			if ahora > antes:
				_anotar("📈 %s mejora" % j.nombre, "Sube de %d a %d de media." % [antes, ahora])
			else:
				_anotar("📉 %s decae" % j.nombre, "Baja de %d a %d de media." % [antes, ahora]))
	if mundo.prensa != null:
		mundo.prensa.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#8ea595][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
		## EL MENTOR COMENTA (C1): su cara y dos frases sobre lo que acaba de
		## pasar, fuera del tutorial.
		if mundo.junta != null:
			mundo.junta.noticia.connect(func(titulo: String, cuerpo: String) -> void:
				_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
				_anotar(titulo, cuerpo))
		mundo.prensa.mentor_dice.connect(func(titulo: String, texto: String) -> void:
			MentorVoz.decir(self, mundo, titulo, texto))
		## LA PORTADA DEL LUNES, COMO PERIÓDICO (C20): si la semana dejó una
		## portada nueva, se abre sola (se puede desactivar en la propia hoja).
		mundo.semana_avanzada.connect(func(_s: int, _a: int) -> void:
			## Una ventana detrás de otra: el periódico primero y la
			## entrevista al paso cuando se cierra (antes salían apiladas).
			call_deferred("_portada_nueva"))
		for con_mentor: Object in [mundo.calendario, mundo.politica, mundo.vida]:
			if con_mentor != null:
				con_mentor.mentor.connect(func(titulo: String, texto: String) -> void:
					MentorVoz.decir(self, mundo, titulo, texto))
		for fuente: Object in [mundo.fondo, mundo.redes, mundo.mercado_av, mundo.insolvencia, mundo.trabajadores, mundo.eventos_cantera, mundo.calendario, mundo.politica, mundo.contratos, mundo.vida, mundo.maestria]:
			if fuente != null:
				fuente.noticia.connect(func(titulo: String, cuerpo: String) -> void:
					_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
					_anotar(titulo, cuerpo))
				if fuente.has_signal("movimiento"):
					fuente.movimiento.connect(mundo._anotar_movimiento)
		if mundo.licencia != null:
			mundo.licencia.noticia.connect(func(titulo: String, cuerpo: String) -> void:
				_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
				_anotar(titulo, cuerpo)
				Aviso.mostrar(self, "nivel", "🎓", titulo, cuerpo))
		if mundo.charlas != null:
			mundo.charlas.noticia.connect(func(titulo: String, cuerpo: String) -> void:
				_escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [titulo, cuerpo])
				_anotar(titulo, cuerpo))
	if mundo.vestuario != null:
		mundo.vestuario.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			_escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [titulo, cuerpo])
			_anotar(titulo, cuerpo))
		## `clan_enfadado`/`rol_incumplido`: el castigo de moral/ansiedad SIEMPRE se
		## aplica, pero `noticia` (arriba) solo sale un 45%/18% de las veces -a
		## propósito, representa que la interna se filtra a la prensa o no-. Hasta
		## hoy (14-9-2026) esas dos señales no tenían NINGÚN canal propio, así que
		## el otro 55%/82% de las veces la moral bajaba sin que nada lo explicara.
		## Van solo al correo -no al registro ni a un Aviso modal-, porque cuando SÍ
		## coincide con la filtración mediática ya se cuenta por partida doble.
		mundo.vestuario.clan_enfadado.connect(func(clan: Dictionary, lider: Jugador) -> void:
			_anotar("😠 Camarilla de %s enfadada" % lider.nombre,
				"«%s» baja el ánimo por tener a %s fuera del once. Moral y ansiedad del grupo, afectadas." % [
					String(clan.get("nombre", "")), lider.nombre]))
		mundo.vestuario.rol_incumplido.connect(func(j: Jugador, ratio: float) -> void:
			_anotar("😞 %s, descontento con su rol" % j.nombre,
				"Lleva %d%% de titularidades, por debajo de lo prometido. Pierde moral." % int(round(ratio * 100.0))))
	## El pulso de la carrera -Roles- no tenia NINGUN gancho hasta hoy: ni
	## tras_partido() ni tras_jornada() ni tras_temporada() se llamaban nunca,
	## asi que el interinato no se resolvia solo, un ayudante no ascendia nunca
	## y el prestigio no se movia. Son justo los eventos que hacen que dirigir
	## de interino o de ayudante SE SIENTA distinto de dirigir de DT.
	## Mismo `roles` reutilizado, clave propia para este segundo bloque -ver
	## el comentario de `roles.noticia_carrera` más arriba-.
	if mundo.roles != null and not mundo.roles.has_meta("_ui_conectado_rol"):
		mundo.roles.set_meta("_ui_conectado_rol", true)
		mundo.roles.aviso.connect(func(titulo: String, texto: String) -> void:
			_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, texto])
			_anotar(titulo, texto))
		mundo.roles.ascenso.connect(func(nuevo_rol: String) -> void:
			_escribir("[color=#4caf6d][b]Asciendes.[/b][/color] Tu nuevo cargo: %s." % nuevo_rol.capitalize())
			_anotar("Asciendes.", "Tu nuevo cargo: %s." % nuevo_rol.capitalize()))
		mundo.roles.interinato_resuelto.connect(func(salvado: bool) -> void:
			if salvado:
				_escribir("[color=#4caf6d][b]Salvaste al club.[/b][/color] El interinato termina y vuelves a tener proyecto.")
				_anotar("Salvaste al club.", "El interinato termina y vuelves a tener proyecto.")
			else:
				_escribir("[color=#e05555][b]No alcanzó.[/b][/color] Se acaban tus cinco fechas de interino sin salvar al club.")
				_anotar("No alcanzó.", "Se acaban tus cinco fechas de interino sin salvar al club."))
		mundo.roles.sin_banco.connect(func(club: String) -> void:
			_escribir("[color=#8ea595][b]Sin banco.[/b][/color] Ya no diriges en %s." % club)
			_anotar("Sin banco.", "Ya no diriges en %s." % club))

func _conectar_noticias() -> void:
	_conectar_noticias_1()
	_conectar_noticias_2()
