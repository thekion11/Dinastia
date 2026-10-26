extends "res://ui/principal/noticias_p1.gd"
## [Capa 2/2 de `noticias.gd`] _conectar_2, conectar
## Ver la cabecera de `noticias_p1.gd`.

## Tramo 2 de 2 de `conectar()` (la norma de 450 líneas lo trocea).
func _conectar_2() -> void:
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
	if p.mundo.roles != null and not p.mundo.roles.has_meta("_ui_conectado_carrera"):
		p.mundo.roles.set_meta("_ui_conectado_carrera", true)
		p.mundo.roles.noticia_carrera.connect(func(titulo: String, texto: String) -> void:
			p._escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			p._anotar(titulo, texto))
	## LO COMERCIAL: zonas de camiseta, naming del estadio y palcos. Cada firma
	## y cada contrato que caduca son noticia: si pasaran callados, la pantalla
	## estaria llena de contratos que aparecen y desaparecen solos.
	## LA CIUDAD: permisos que se resuelven, sanciones que caducan y negocios que
	## se inauguran. El permiso tarda semanas y llega solo: sin aviso, el jugador
	## no se entera de que ya puede ampliar el estadio.
	if p.mundo.ciudad != null:
		p.mundo.ciudad.noticia.connect(func(titulo: String, texto: String) -> void:
			p._escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			p._anotar(titulo, texto)
			Aviso.mostrar(p, "contrato", "🏙️", titulo, texto, "patrocinio_nuevo"))
		p.mundo.ciudad.movimiento.connect(p.mundo._anotar_movimiento)
	if p.mundo.junta != null and not p.mundo.junta.movimiento.is_connected(p.mundo._anotar_movimiento):
		p.mundo.junta.movimiento.connect(p.mundo._anotar_movimiento)
	if p.mundo.comercial != null:
		p.mundo.comercial.noticia.connect(func(titulo: String, texto: String) -> void:
			p._escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			p._anotar(titulo, texto))
		p.mundo.comercial.movimiento.connect(p.mundo._anotar_movimiento)
	## `eras` es del MUNDO, no de tu club -se crea una vez en `generar()` y su
	## propio comentario dice que no se recrea al tomar el mando-, así que
	## necesita el mismo candado que `mercado`, `copa` y `cesiones`.
	if p.mundo.eras != null and not p.mundo.eras.has_meta("_ui_conectado"):
		p.mundo.eras.set_meta("_ui_conectado", true)
		p.mundo.eras.noticia.connect(func(titulo: String, texto: String) -> void:
			p._escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			p._anotar(titulo, texto)
			Aviso.mostrar(p, "logro", "🌍", titulo, texto))
	if p.mundo.auspicio != null:
		p.mundo.auspicio.noticia.connect(func(titulo: String, texto: String) -> void:
			p._escribir("[color=#e0a832][b]%s.[/b][/color] %s" % [titulo, texto])
			p._anotar(titulo, texto)
			Aviso.mostrar(p, "contrato", "👕", titulo, texto, "patrocinio_nuevo"))
	if p.mundo.entrenamiento != null:
		p.mundo.entrenamiento.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			p._escribir("[color=#3fa06a][b]%s[/b][/color] %s" % [titulo, cuerpo])
			p._anotar(titulo, cuerpo))
		## Otra señal muda: cada diez semanas ganas un punto para tu árbol y no
		## te enterabas de nada. Un punto sin gastar es de las pocas cosas del
		## juego que no caducan, así que merece aviso propio y no solo registro.
		p.mundo.entrenamiento.punto_dt_ganado.connect(func(total: int) -> void:
			Aviso.mostrar(p, "nivel", "🎓", "Punto de entrenador",
				"Tienes %d punto(s) para gastar en tus habilidades, en Club › Legado." % total))
		## `progreso` se emite cada vez que el entrenamiento semanal sube o baja el
		## OVR de un jugador -menores de 24 progresando, veteranos de 31+ apagándose-
		## y hasta hoy (14-9-2026) nadie la escuchaba: la única forma de enterarse
		## era abrir la ficha de cada jugador y comparar el número a ojo. Sin
		## `Aviso` modal a propósito -puede dispararse varias veces la misma
		## semana- , va al registro como el resto de novedades del plantel.
		p.mundo.entrenamiento.progreso.connect(func(j: Jugador, antes: int, ahora: int) -> void:
			if ahora == antes:
				return
			if ahora > antes:
				p._anotar("📈 %s mejora" % j.nombre, "Sube de %d a %d de media." % [antes, ahora])
			else:
				p._anotar("📉 %s decae" % j.nombre, "Baja de %d a %d de media." % [antes, ahora]))
	if p.mundo.prensa != null:
		p.mundo.prensa.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			p._escribir("[color=#8ea595][b]%s[/b][/color] %s" % [titulo, cuerpo])
			p._anotar(titulo, cuerpo))
		## EL MENTOR COMENTA (C1): su cara y dos frases sobre lo que acaba de
		## pasar, fuera del tutorial.
		if p.mundo.junta != null:
			p.mundo.junta.noticia.connect(func(titulo: String, cuerpo: String) -> void:
				p._escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
				p._anotar(titulo, cuerpo))
		p.mundo.prensa.mentor_dice.connect(func(titulo: String, texto: String) -> void:
			MentorVoz.decir(p, p.mundo, titulo, texto))
		## LA PORTADA DEL LUNES, COMO PERIÓDICO (C20): si la semana dejó una
		## portada nueva, se abre sola (se puede desactivar en la propia hoja).
		p.mundo.semana_avanzada.connect(func(_s: int, _a: int) -> void:
			## Una ventana detrás de otra: el periódico primero y la
			## entrevista al paso cuando se cierra (antes salían apiladas).
			p.call_deferred("_portada_nueva"))
		for con_mentor: Object in [p.mundo.calendario, p.mundo.politica, p.mundo.vida]:
			if con_mentor != null:
				con_mentor.mentor.connect(func(titulo: String, texto: String) -> void:
					MentorVoz.decir(p, p.mundo, titulo, texto))
		for fuente: Object in [p.mundo.fondo, p.mundo.redes, p.mundo.mercado_av, p.mundo.insolvencia, p.mundo.trabajadores, p.mundo.eventos_cantera, p.mundo.calendario, p.mundo.politica, p.mundo.contratos, p.mundo.vida, p.mundo.maestria]:
			if fuente != null:
				fuente.noticia.connect(func(titulo: String, cuerpo: String) -> void:
					p._escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
					p._anotar(titulo, cuerpo))
				if fuente.has_signal("movimiento"):
					fuente.movimiento.connect(p.mundo._anotar_movimiento)
		if p.mundo.licencia != null:
			p.mundo.licencia.noticia.connect(func(titulo: String, cuerpo: String) -> void:
				p._escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
				p._anotar(titulo, cuerpo)
				Aviso.mostrar(p, "nivel", "🎓", titulo, cuerpo))
		if p.mundo.charlas != null:
			p.mundo.charlas.noticia.connect(func(titulo: String, cuerpo: String) -> void:
				p._escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [titulo, cuerpo])
				p._anotar(titulo, cuerpo))
	if p.mundo.vestuario != null:
		p.mundo.vestuario.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			p._escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [titulo, cuerpo])
			p._anotar(titulo, cuerpo))
		## `clan_enfadado`/`rol_incumplido`: el castigo de moral/ansiedad SIEMPRE se
		## aplica, pero `noticia` (arriba) solo sale un 45%/18% de las veces -a
		## propósito, representa que la interna se filtra a la prensa o no-. Hasta
		## hoy (14-9-2026) esas dos señales no tenían NINGÚN canal propio, así que
		## el otro 55%/82% de las veces la moral bajaba sin que nada lo explicara.
		## Van solo al correo -no al registro ni a un Aviso modal-, porque cuando SÍ
		## coincide con la filtración mediática ya se cuenta por partida doble.
		p.mundo.vestuario.clan_enfadado.connect(func(clan: Dictionary, lider: Jugador) -> void:
			p._anotar("😠 Camarilla de %s enfadada" % lider.nombre,
				"«%s» baja el ánimo por tener a %s fuera del once. Moral y ansiedad del grupo, afectadas." % [
					String(clan.get("nombre", "")), lider.nombre]))
		p.mundo.vestuario.rol_incumplido.connect(func(j: Jugador, ratio: float) -> void:
			p._anotar("😞 %s, descontento con su rol" % j.nombre,
				"Lleva %d%% de titularidades, por debajo de lo prometido. Pierde moral." % int(round(ratio * 100.0))))
	## El pulso de la carrera -Roles- no tenia NINGUN gancho hasta hoy: ni
	## tras_partido() ni tras_jornada() ni tras_temporada() se llamaban nunca,
	## asi que el interinato no se resolvia solo, un ayudante no ascendia nunca
	## y el prestigio no se movia. Son justo los eventos que hacen que dirigir
	## de interino o de ayudante SE SIENTA distinto de dirigir de DT.
	## Mismo `roles` reutilizado, clave propia para este segundo bloque -ver
	## el comentario de `roles.noticia_carrera` más arriba-.
	if p.mundo.roles != null and not p.mundo.roles.has_meta("_ui_conectado_rol"):
		p.mundo.roles.set_meta("_ui_conectado_rol", true)
		p.mundo.roles.aviso.connect(func(titulo: String, texto: String) -> void:
			p._escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, texto])
			p._anotar(titulo, texto))
		p.mundo.roles.ascenso.connect(func(nuevo_rol: String) -> void:
			p._escribir("[color=#4caf6d][b]Asciendes.[/b][/color] Tu nuevo cargo: %s." % nuevo_rol.capitalize())
			p._anotar("Asciendes.", "Tu nuevo cargo: %s." % nuevo_rol.capitalize()))
		p.mundo.roles.interinato_resuelto.connect(func(salvado: bool) -> void:
			if salvado:
				p._escribir("[color=#4caf6d][b]Salvaste al club.[/b][/color] El interinato termina y vuelves a tener proyecto.")
				p._anotar("Salvaste al club.", "El interinato termina y vuelves a tener proyecto.")
			else:
				p._escribir("[color=#e05555][b]No alcanzó.[/b][/color] Se acaban tus cinco fechas de interino sin salvar al club.")
				p._anotar("No alcanzó.", "Se acaban tus cinco fechas de interino sin salvar al club."))
		p.mundo.roles.sin_banco.connect(func(club: String) -> void:
			p._escribir("[color=#8ea595][b]Sin banco.[/b][/color] Ya no diriges en %s." % club)
			p._anotar("Sin banco.", "Ya no diriges en %s." % club))

## Conecta todas las noticias del mundo actual (`p.mundo`).
func conectar() -> void:
	_conectar_1()
	_conectar_2()
