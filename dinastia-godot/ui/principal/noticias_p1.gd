extends Node
## [Capa 1/2 de `noticias.gd`] _init, _conectar_1
##
## LAS NOTICIAS DEL MUNDO (fase 0: sale de `Principal`, capas 11 y 12). Una sola
## responsabilidad: escuchar las señales `noticia`, `aviso`, `movimiento`... de
## los sistemas del núcleo y llevarlas al registro (`p._escribir`), al correo
## (`p._anotar`) y, si merece interrumpir, a un `Aviso`.
##
## Interfaz: `conectar()`, que se puede llamar tantas veces como haga falta (al
## cargar, al cambiar de club, al deshacer): los sistemas que sobreviven al
## cambio de club llevan su candado `_ui_conectado*` para no duplicar avisos.
## Principal la posee (`_noticias`) y conserva `_conectar_noticias()` como puente.
##
## Es un `Node` hijo de Principal por el mismo motivo que `sorteos.gd`: las
## lambdas quedan atadas a este nodo y Godot las desconecta al liberarlo. Leen
## `p.mundo` en el momento de dispararse (no una copia), igual que antes.

var p: Principal

func _init(principal: Principal = null) -> void:
	p = principal
	name = "Noticias"

## La selección avisa de lo suyo (prenómina, convocatoria, lesión de gira,
## nacionalización) por señal en vez de por estado que alguna pantalla mire cada
## semana -no tiene pestaña de despacho propia como Prensa-, así que sin esto
## esas noticias pasaban de verdad pero nadie se enteraba nunca.
## Tramo 1 de 2 de `conectar()` (la norma de 450 líneas lo trocea).
func _conectar_1() -> void:
	## `Directiva.despedido` se emite desde `mover_confianza()` -tras_partido(),
	## en mundo.gd linea 997- en cuanto la confianza toca fondo, que puede pasar
	## a MITAD de temporada por una mala racha, no solo al cerrarla. El banco de
	## pruebas ya comprobaba "una racha de derrotas acaba en despido", pero
	## nadie escuchaba la señal aquí: el despido ocurría de verdad dentro del
	## motor y el jugador seguía dirigiendo un club que ya lo había echado,
	## semana tras semana, sin un solo aviso -y `nueva_temporada()` tampoco lo
	## contaba nunca, porque se salta el veredicto de directiva si
	## `despedido_ya` ya estaba puesto (mundo.gd linea 715)-. Mismo aviso que ya
	## usa el cierre de temporada, para que se sienta igual de definitivo.
	if p.mundo.directiva != null:
		p.mundo.directiva.despedido.connect(func(motivo: String) -> void:
			p._escribir("[color=#e05555][b]ESTÁS DESPEDIDO.[/b][/color] La directiva pierde la paciencia (%s) y te destituye a mitad de temporada. Elige tu próximo club entre las ofertas de abajo." % motivo)
			p._anotar("ESTÁS DESPEDIDO.", "La directiva pierde la paciencia (%s) y te destituye a mitad de temporada." % motivo)
			## El momento más definitivo del juego: si algo merece interrumpir,
			## es que te acaben de echar. Con pantalla, en persona: el presidente
			## te lo dice en su despacho (`EscenaDespido`, M-238); sin pantalla
			## (banco) sigue el aviso de siempre.
			if DisplayServer.get_name() != "headless":
				EscenaDespido.mostrar(p, p.mundo, motivo)
			else:
				Aviso.mostrar(p, "alerta", "🚪", "ESTÁS DESPEDIDO",
					"La directiva te destituye tras la %s. Elige tu próximo club entre las ofertas de abajo." % motivo, "despido")
			## `Roles.gd` lo deja escrito en su propio comentario -"lo llama quien
			## atienda `Directiva.despedido`, DESPUÉS de comprobar
			## `le_pueden_echar()`"- y nadie lo llamaba NUNCA, ni siquiera al
			## vender el club: toda la pantalla de "sin banco" -ofertas de otros
			## clubes, `_pintar_sin_banco()`, ya escrita y probada- era
			## inalcanzable. `despedido` solo se emite con `puede_despedirte` ya
			## en true (sincronizado desde `le_pueden_echar()` en `mundo.gd`), así
			## que la comprobación que pide el comentario ya está hecha antes de
			## llegar aquí.
			p.mundo.roles.quedar_sin_banco())
	## `Banco.liquidado`: "el único sistema del juego que puede TERMINAR una
	## partida sin que pierdas un partido" -según su propio comentario de
	## cabecera- y NADIE la escuchaba (hallazgo de la auditoría de conectores
	## del 13-9-2026): doce semanas con la caja en rojo liquidaban el club
	## por dentro y el jugador seguía dirigiéndolo como si nada, sin aviso ni
	## consecuencia en pantalla. Mismo tratamiento que un despido -tiene el
	## mismo peso narrativo, "tu etapa aquí se acaba"- reusando
	## `quedar_sin_banco()`, que ya deja la pantalla de ofertas probada.
	if p.mundo.banco != null:
		p.mundo.banco.liquidado.connect(func() -> void:
			p._escribir("[color=#e05555][b]EL CLUB SE LIQUIDA.[/b][/color] La deuda pudo más: la asociación toma el control y tu etapa aquí se acaba. Elige tu próximo club entre las ofertas de abajo.")
			p._anotar("EL CLUB SE LIQUIDA.", "La deuda pudo más: la asociación liquida el club y tu etapa aquí se acaba.")
			Aviso.mostrar(p, "alerta", "💀", "EL CLUB SE LIQUIDA",
				"La deuda pudo más: la asociación toma el control y tu etapa aquí se acaba. Elige tu próximo club entre las ofertas de abajo.", "descenso_administrativo")
			p.mundo.roles.quedar_sin_banco())
	## Cambios de ley y avisos de la regla de la liga (7-10-2026: la señal
	## existía pero nadie la escuchaba).
	if p.mundo.contratos != null and not p.mundo.contratos.noticia.is_connected(p._noticia_contratos):
		p.mundo.contratos.noticia.connect(p._noticia_contratos)
	if p.mundo.selecciones != null:
		p.mundo.selecciones.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			p._escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
			p._anotar(titulo, cuerpo))
	if p.mundo.cantera != null:
		p.mundo.cantera.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			p._escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [titulo, cuerpo])
			p._anotar(titulo, cuerpo))
	if p.mundo.academia != null:
		p.mundo.academia.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			p._escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [titulo, cuerpo])
			p._anotar(titulo, cuerpo))
		p.mundo.academia.movimiento.connect(p.mundo._anotar_movimiento)
	if p.mundo.ojeadores != null:
		## El modelo de datos y las academias hablan por su propia senal: son
		## hallazgos y llegadas, no informes de ojeo, y se leen distinto.
		p.mundo.ojeadores.noticia_ojeo.connect(func(titulo: String, cuerpo: String) -> void:
			p._escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, cuerpo])
			p._anotar(titulo, cuerpo))
		p.mundo.ojeadores.movimiento_ojeo.connect(p.mundo._anotar_movimiento)
		p.mundo.ojeadores.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			p._escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
			p._anotar(titulo, cuerpo))
	if p.mundo.logros != null:
		p.mundo.logros.logro_desbloqueado.connect(func(_clave: String, icono: String, titulo: String, descripcion: String) -> void:
			p._escribir("[color=#c9a227][b]%s Logro: %s[/b][/color] %s" % [icono, titulo, descripcion])
			p._anotar("%s Logro: %s" % [icono, titulo], descripcion)
			## Y el aviso deslizante con su sonido. Una línea más en el registro
			## se pierde entre las quince de la semana: un logro que no se
			## celebra no es un logro, es una fila de una tabla.
			Aviso.mostrar(p, "logro", icono, titulo, descripcion))
		p.mundo.logros.record_batido.connect(func(clave: String, _ficha: Dictionary) -> void:
			p._escribir("[color=#c9a227][b]Nuevo récord del club:[/b][/color] %s" % Nombres.limpiar(clave).capitalize())
			p._anotar("Nuevo récord del club:", Nombres.limpiar(clave).capitalize())
			Aviso.mostrar(p, "record", "📈", "Nuevo récord del club", Nombres.limpiar(clave).capitalize()))
		p.mundo.logros.efemeride_nueva.connect(func(_anio: int, texto: String) -> void:
			p._escribir("[color=#8ea595]%s[/color]" % texto)
			p._anotar("Un día como hoy", texto))
		p.mundo.logros.perfil_subio_de_nivel.connect(func(_nivel: int, nombre: String, lema: String) -> void:
			p._escribir("[color=#4caf6d][b]Subes de nivel: %s.[/b][/color] %s" % [nombre, lema])
			p._anotar("Subes de nivel: %s." % nombre, lema)
			Aviso.mostrar(p, "nivel", "⭐", "Subes de nivel: %s" % nombre, lema))
		p.mundo.logros.canterano_debuta.connect(func(j: Jugador) -> void:
			p._escribir("[color=#4caf6d][b]Debut de la casa:[/b][/color] %s se estrena con el primer equipo." % j.nombre)
			p._anotar("Debut de la casa:", "%s se estrena con el primer equipo." % j.nombre))
		## Antes solo sonaba la fanfarria: `celebrar_titulo()` la llama para la
		## liga, la copa nacional Y los continentales, pero solo la liga tenía
		## una línea propia en el registro (`_nueva_temporada()`, más abajo, con
		## el premio). Ganar la copa o una Champions/Libertadores -que además se
		## corona A MITAD DE TEMPORADA, según su propio comentario en
		## `mundo.gd:avanzar_semana()`, no al cerrar el año- pasaba con un solo
		## efecto de sonido y nada en el registro: había que entrar a Logros a
		## enterarse de qué se había ganado.
		p.mundo.logros.titulo_celebrado.connect(func(nombre: String) -> void:
			p._escribir("[color=#c9a227][b]🏆 ¡CAMPEÓN![/b][/color] %s." % nombre)
			p._anotar("🏆 ¡CAMPEÓN!", "%s." % nombre)
			## El aviso ya toca "trofeo" por su tipo: llamarlo aquí además lo
			## haría sonar dos veces.
			Aviso.mostrar(p, "titulo", "🏆", nombre, "Lo levantaste tú. Queda en la vitrina para siempre."))
		## La gala se calculaba entera y se guardaba sin que nadie la anunciara:
		## el jugador podía ganar el premio a mejor entrenador del año y no
		## enterarse jamás. Ahora avisa, y el detalle está en la pestaña Premios.
		p.mundo.logros.premios_entregados.connect(func(acta: Dictionary) -> void:
			var ganados: Array = acta.get("ganados", [])
			var cuerpo_gala := "Se entregan los premios de la temporada %d. " % int(acta.get("anio", 0))
			cuerpo_gala += ("Tu club se lleva: %s." % ", ".join(PackedStringArray(ganados))) if not ganados.is_empty() else "Tu club se va de vacío."
			p._escribir("[color=#c9a227][b]🎬 Gala de fin de año.[/b][/color] %s" % cuerpo_gala)
			p._anotar("🎬 Gala de fin de año.", cuerpo_gala))
	## `mercado` se crea una sola vez por partida en `Mundo.generar()` -no lo
	## recrea `tomar_el_mando()`-, así que si tomas otro club (despido, oferta
	## aceptada, "trotamundos") `_conectar_noticias()` vuelve a pasar por aquí
	## sobre el MISMO objeto: sin este candado cada oferta y cada traspaso de
	## la IA se habría anotado y sonado una vez más por cada club que tomaste.
	if p.mundo.mercado != null and not p.mundo.mercado.has_meta("_ui_conectado"):
		p.mundo.mercado.set_meta("_ui_conectado", true)
		p.mundo.mercado.oferta_recibida.connect(func(j: Jugador, c: Club, monto: int) -> void:
			Sonido.toca("moneda")
			p._escribir("[color=#c9a227][b]📨 Oferta por %s.[/b][/color] %s ofrece %s. Respóndela en Mercado." % [
				j.nombre, c.nombre, p._dinero(monto)])
			p._anotar("📨 Oferta por %s." % j.nombre, "%s ofrece %s. Respóndela en Mercado." % [c.nombre, p._dinero(monto)])
			Aviso.mostrar(p, "mercado", "📨", "Oferta por %s" % j.nombre,
				"%s ofrece %s. Tienes que responder." % [c.nombre, p._dinero(monto)], "oferta"))
		## Los traspasos entre dos clubes de la IA -`_buscar_objetivo()` nunca
		## elige al tuyo como comprador ni como vendedor-: la señal existía desde
		## siempre pero no la escuchaba nadie, así que el mercado se movía en
		## silencio. Los tuyos no pasan por aquí: `_intentar_fichar()` y
		## `responder_oferta()` ya escriben su propio aviso.
		p.mundo.mercado.traspaso.connect(func(j: Jugador, de: Club, a: Club, _monto: int) -> void:
			## TU FICHAJE SE PRESENTA (C7): la tarjeta con su cara y tu camiseta.
			if a == p.mundo.mi_club():
				PresentacionFichaje.mostrar.call_deferred(p, p.mundo, j, de)
				return
			if de == p.mundo.mi_club():
				return
			p._escribir("[color=#8ea595]🔁 %s pasa de %s a %s.[/color]" % [
				j.nombre, de.nombre if de else "?", a.nombre]))
	## `Mundo._informes_de_ojeo()` existía desde antes de esta tanda y ya
	## marcaba `ojeados[j.id]`, pero la señal no la escuchaba nadie: el ojeador
	## trabajaba en silencio y el informe no se veía en ningún sitio. Esto es
	## una versión reducida de la "RED DE OJEADORES CON NOMBRE Y SESGO" del
	## HTML -un ojeador de carne y hueso por país, con su propio sesgo y sus
	## renuncias-, que sigue sin portar: no hay pantalla dedicada ("Ojeadores"
	## en el menú del HTML) ni ojeadores individuales, solo el aviso de que
	## llegó un informe.
	## Esta va directo en `mundo`, no en un sub-sistema: `mundo` en sí es el
	## MISMO objeto durante toda la partida -solo cambia al cargar otra o
	## empezar de cero-, así que también hay que guardarla con candado o se
	## duplica cada vez que cambias de club sin salir de la partida.
	if not p.mundo.has_meta("_ui_conectado_ojeo"):
		p.mundo.set_meta("_ui_conectado_ojeo", true)
		p.mundo.informe_de_ojeo.connect(func(j: Jugador, club_suyo: Club) -> void:
			var cuerpo_oj := "%s · %s · %d años · media %d con proyección %d." % [club_suyo.nombre, j.pos_e, j.edad, j.ovr, j.pot]
			p._escribir("[color=#c9a227][b]🔎 Informe de ojeo: %s.[/b][/color] %s" % [j.nombre, cuerpo_oj])
			p._anotar("🔎 Informe de ojeo: %s." % j.nombre, cuerpo_oj))
	## LOS INGRESOS DE COPA. `Copa.campeon_proclamado` y `ronda_terminada` se
	## emitían desde siempre sin que nadie las escuchara: el premio entraba en la
	## caja en silencio y avanzar de ronda -que es lo que da el dinero- no se
	## notaba. Aquí solo interesa TU club: los otros 383 también cobran.
	## `copa` tampoco se recrea al cambiar de club dentro de la misma partida
	## -solo `_montar_copa()` la crea, y solo si es null-: mismo candado que
	## `mercado` arriba, para no celebrar el mismo título o la misma ronda dos
	## veces si cambias de club a mitad de temporada.
	if p.mundo.copa != null and not p.mundo.copa.has_meta("_ui_conectado"):
		p.mundo.copa.set_meta("_ui_conectado", true)
		p.mundo.copa.campeon_proclamado.connect(func(campeon: Club) -> void:
			if campeon == p.mundo.mi_club():
				Aviso.mostrar(p, "dinero", "🏆", "Campeón de %s" % p.mundo.copa.nombre,
					"Además del título, entran %s de premio." % p._dinero(Copa.PREMIO)))
		p.mundo.copa.ronda_terminada.connect(func(nombre_ronda: String, resultados: Array) -> void:
			for r: Dictionary in resultados:
				var gano: Club = r.get("pasa")
				if gano == p.mundo.mi_club():
					Aviso.mostrar(p, "dinero", "🎟️", "Pasas de ronda",
						"%s superada. Cada eliminatoria que se gana es taquilla y premio." % nombre_ronda, "ronda_superada")
					return)
	## Lo mismo para Champions/Libertadores -mismo bug, sin arreglar hasta hoy
	## (14-9-2026): ver `_conectar_mi_continental()`, llamada desde
	## `_conectar_sorteos()` mas abajo porque comparten el mismo ciclo de vida
	## (hay que reconectar tras cada resorteo, no solo la primera vez).
	## `Instalaciones.avanzar_semana()` devuelve las obras que acaban de
	## terminar, y `Mundo.avanzar_semana()` (línea 540) las reemite como
	## `obra_lista` con un comentario explícito: "para que la noticia de 'obra
	## terminada' salga la misma semana en que termina". La intención estaba
	## escrita desde que se creó la señal; nadie la conectó nunca. Construir un
	## nivel de instalación cuesta semanas y millones y hoy no avisa de nada:
	## solo se nota si el jugador entra a mirar la pestaña Club por su cuenta.
	## Misma razón que `informe_de_ojeo`: señal del propio `mundo`, candado
	## propio para no avisar la misma obra terminada dos veces.
	if not p.mundo.has_meta("_ui_conectado_obra"):
		p.mundo.set_meta("_ui_conectado_obra", true)
		p.mundo.obra_lista.connect(func(clave: String) -> void:
			var nombre_obra: String = String(Instalaciones.CATALOGO[clave][0]) if Instalaciones.CATALOGO.has(clave) else clave
			var cuerpo_obra := "%s llega a nivel %d." % [nombre_obra, p.mundo.obras.nivel(clave)]
			if clave == "reforma_estadio":
				cuerpo_obra = "Termina la reforma del estadio: desde hoy se juega en el estadio nuevo."
			p._escribir("[color=#c9a227][b]🏗️ Obra terminada:[/b][/color] %s" % cuerpo_obra)
			p._anotar("🏗️ Obra terminada:", cuerpo_obra)
			## Una obra son semanas de espera y millones: cuando por fin termina, se
			## avisa. Es de lo poco que el jugador PIDIÓ que pasara y luego olvidó.
			Aviso.mostrar(p, "dinero", "🏗️", "Obra terminada", cuerpo_obra, "inauguracion_obra"))
	## `procesoLibres()` del HTML: rarísima vez (4%) aparece un agente libre de
	## calidad. Es lo bastante especial para tener su propio aviso -no el
	## genérico de "hay agentes libres nuevos", que sería ruido cada semana-.
	## Misma razón otra vez: candado propio para el agente libre de lujo.
	if not p.mundo.has_meta("_ui_conectado_libre"):
		p.mundo.set_meta("_ui_conectado_libre", true)
		p.mundo.libre_estrella.connect(func(j: Jugador) -> void:
			var cuerpo_le := "%s (%d años, media %d) quedó sin club. %s. No estará mucho tiempo disponible." % [
				j.nombre, j.edad, j.ovr, j.motivo_libre]
			p._escribir("[color=#c9a227][b]⭐ Agente libre de lujo en el mercado.[/b][/color] %s" % cuerpo_le)
			p._anotar("⭐ Agente libre de lujo en el mercado.", cuerpo_le))
	## `Medico.revisar_semana()` corre cada semana desde `Mundo.avanzar_semana()`
	## -linea 492- pero devuelve una lista que nadie recogia, "para que la
	## interfaz lo cuente sin tener que rastrear a nadie" segun su propio
	## comentario, y ademas ninguna de sus cuatro señales estaba conectada: la
	## enfermeria solo se veia entrando a la pestaña a mirar, nunca avisaba de
	## nada por su cuenta.
	if p.mundo.medico != null:
		p.mundo.medico.lesion_nueva.connect(func(j: Jugador, semanas: int, tipo: String, causa: String) -> void:
			if j.club_id == p.mundo.mi_club_id:
				var cuerpo_l := "%s (%s), %d semana%s fuera." % [tipo, causa, semanas, "" if semanas == 1 else "s"]
				p._escribir("[color=#e05555]🩹 %s se lesiona: %s[/color]" % [j.nombre, cuerpo_l])
				p._anotar("🩹 %s se lesiona" % j.nombre, cuerpo_l)
				## Solo las GRAVES interrumpen. Un tirón de dos semanas es
				## rutina; perder a alguien un mes y medio cambia la temporada,
				## y es justo lo que se pasa por alto leyendo el registro.
				if semanas >= 6:
					Aviso.mostrar(p, "alerta", "🚑", "Lesión grave: %s" % j.nombre,
						"%s. Se pierde %d semanas." % [tipo, semanas], "medico_parte")
				## LA VENTANA DE EMERGENCIA. `Roles.gd` lo deja escrito en su propio
				## comentario -"quien lleve las lesiones la abre llamando a
				## abrir_emergencia()"- y nadie la llamaba: perder a un titular 12+
				## semanas con el mercado cerrado nunca destrababa el fichaje de
				## emergencia que el motor ya sabe conceder (banner, consumo con
				## `usar_emergencia()`, gatillo en `puede_fichar()`, todo ya escrito
				## y sin nadie que lo encendiera). Mismo umbral y misma doble
				## condición del HTML (`ventanaEmergencia()`): titular del once, o
				## un nivel cercano al del club aunque no lo fuera.
				if semanas >= 12 and not p.mundo.mercado_abierto() and p.mundo.roles != null:
					var mio := p.mundo.mi_club()
					if mio != null and (mio.once().has(j) or j.ovr >= mio.rep - 6):
						p.mundo.roles.abrir_emergencia(j.id))
		p.mundo.medico.recaida.connect(func(j: Jugador, semanas: int, tipo: String) -> void:
			if j.club_id == p.mundo.mi_club_id:
				var cuerpo_r := "vuelve a caer de %s, %d semana%s más." % [tipo, semanas, "" if semanas == 1 else "s"]
				p._escribir("[color=#e05555]🩹 Recaída de %s:[/color] %s" % [j.nombre, cuerpo_r])
				p._anotar("🩹 Recaída de %s" % j.nombre, cuerpo_r))
		p.mundo.medico.recuperado.connect(func(j: Jugador) -> void:
			if j.club_id == p.mundo.mi_club_id:
				p._escribir("[color=#4caf6d]✅ %s recibe el alta médica.[/color]" % j.nombre)
				p._anotar("✅ Alta médica", "%s recibe el alta médica." % j.nombre))
		p.mundo.medico.informe_listo.connect(func(j: Jugador, informe: Dictionary) -> void:
			var cuerpo_i := "Riesgo: %s. Lesiones graves: %d." % [String(informe.get("riesgo", "?")), int(informe.get("graves", 0))]
			p._escribir("[color=#c9a227][b]🩺 Informe médico de %s.[/b][/color] %s" % [j.nombre, cuerpo_i])
			p._anotar("🩺 Informe médico de %s." % j.nombre, cuerpo_i))
	## Estas cinco emiten `noticia` desde hace tiempo -44 sitios entre las
	## cinco- y hasta hoy no las escuchaba nadie: pasaban de verdad y no se
	## veían en ninguna pantalla.
	##
	## OJO: `federacion` NO se recrea al tomar el mando de otro club -lo dice
	## su propio comentario en `Mundo`-, asi que `_conectar_noticias()` pasa por
	## aqui mas de una vez sobre el MISMO objeto. Eso SI se comprobaba para
	## `movimiento` (con `is_connected`, porque es un metodo con nombre, siempre
	## el mismo Callable) pero NO para `noticia`: cada `func(...)` de abajo es un
	## Callable NUEVO en cada paso, asi que `is_connected` nunca lo hubiera
	## encontrado y Godot tampoco avisa con error -son lambdas distintas, no la
	## misma conexion repetida-. El resultado real, encontrado en la auditoria
	## del 14-9-2026: cada vez que tomabas otro club (despido, oferta aceptada,
	## "trotamundos"), cada noticia de la federacion -votaciones, licencia,
	## tribunal, control antidopaje- se imprimia una vez mas de las que tocaba.
	## Mismo candado que ya usan `cesiones`, `mercado`, `eras` y `roles` aqui
	## abajo para el mismo problema.
	if p.mundo.federacion != null and not p.mundo.federacion.has_meta("_ui_conectado"):
		p.mundo.federacion.set_meta("_ui_conectado", true)
		p.mundo.federacion.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			p._escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
			p._anotar(titulo, cuerpo))
		## El dinero de la federacion -multas del cupo juvenil, bonificaciones por
		## minutos de sub-21- YA va al libro: `Mundo.tomar_el_mando()` conecta
		## `federacion.movimiento` a `_anotar_movimiento` con su propio candado
		## `is_connected()` (es una de las "siete fuentes" del libro, junto a
		## estadio/cesiones/cantera/prensa/selecciones). Repetir la conexión aquí
		## -encontrado 14-9-2026- no duplicaba el dinero -Godot rechaza la segunda
		## conexion sin conectarla-, pero SÍ imprimía un ERROR real en cada
		## partida nueva desde el primer segundo, siempre. Quitado: no hace falta,
		## el núcleo ya lo tiene cubierto.
		## `castigo_directiva`/`escandalo` (auditoría 14-9-2026): el propio
		## comentario de cabecera de `Federacion` pide conectarlas -"no son suyas,
		## solo dice cuánto se mueven y por qué"- y nadie lo hacía: licencia
		## denegada, dopaje, incumplir el cupo juvenil y el fair play financiero no
		## le movían un punto a la confianza de la directiva ni a la funa de la
		## hinchada, pese a que el texto de la propia noticia ya lo prometía
		## ("la hinchada... te lo van a cobrar"). El texto ya lo cuenta `noticia`;
		## aquí solo se aplica el número, sin aviso aparte, igual que hace
		## `movimiento` con la caja.
		p.mundo.federacion.castigo_directiva.connect(func(delta: int, motivo: String) -> void:
			if p.mundo.directiva != null:
				p.mundo.directiva.mover_confianza(delta, motivo))
		p.mundo.federacion.escandalo.connect(func(funa: int, motivo: String) -> void:
			if p.mundo.prensa != null:
				p.mundo.prensa._mover_funa(funa))
	## `cesiones` vive desde `generar()`, igual que `federacion` -ver el
	## comentario de `federacion.movimiento` más abajo-, así que sus tres
	## señales necesitan el mismo candado o se duplican al cambiar de club.
	if p.mundo.cesiones != null and not p.mundo.cesiones.has_meta("_ui_conectado"):
		p.mundo.cesiones.set_meta("_ui_conectado", true)
		p.mundo.cesiones.noticia.connect(func(titulo: String, cuerpo: String) -> void:
			p._escribir("[color=#3fa06a][b]%s[/b][/color] %s" % [titulo, cuerpo])
			p._anotar(titulo, cuerpo))
		## QUE ALGUIEN PAGUE LA CLÁUSULA DE UNO DE LOS TUYOS es de las peores
		## noticias que puede recibir un entrenador, y hasta ahora era una línea
		## gris entre otras quince. Merece interrumpir.
		p.mundo.cesiones.clausula_pagada.connect(func(j: Jugador, de: Club, a: Club, monto: int) -> void:
			if de == p.mundo.mi_club():
				Aviso.mostrar(p, "alerta", "💥", "Te pagaron la cláusula",
					"%s se va a %s por %s. No hubo nada que negociar." % [j.nombre, a.nombre, p._dinero(monto)])
			elif a == p.mundo.mi_club():
				Aviso.mostrar(p, "mercado", "✍️", "Clausulazo",
					"%s es tuyo: pagaste su cláusula de %s." % [j.nombre, p._dinero(monto)], "oferta_aceptada"))
		## Y las plusvalías: dinero que entra sin hacer nada, porque te guardaste
		## un porcentaje al vender. Es la recompensa de una decisión vieja.
		p.mundo.cesiones.vendido.connect(func(j: Jugador, comprador: Club, neto: int) -> void:
			Aviso.mostrar(p, "dinero", "💰", "Venta cerrada",
				"%s se va a %s. Entran %s." % [j.nombre, comprador.nombre, p._dinero(neto)], "venta"))
	## `estadio` -como `federacion` y `cesiones`- vive desde que se crea el Mundo,
	## no se recrea al cambiar de club: mismo candado por el mismo motivo.
	## `reforma_hecha` (14-9-2026): `reformar()` siempre devuelve "" en éxito, así
	## que cuando el jugador pide más bandejas de las que `Instalaciones` permite
	## hoy, la reforma se aplicaba RECORTADA -"se quedó en N bandeja(s)"- y pagaba
	## el coste completo sin que la interfaz dijera una palabra del recorte: el
	## aviso solo viajaba dentro de esta señal, sin conectar.
	if p.mundo.estadio != null and not p.mundo.estadio.has_meta("_ui_conectado"):
		p.mundo.estadio.set_meta("_ui_conectado", true)
		p.mundo.estadio.reforma_hecha.connect(func(_aplicados: Dictionary, _coste: int, aviso: String) -> void:
			if aviso != "":
				p._escribir("[color=#c9a227]🏟️ %s[/color]" % aviso)
				p._anotar("🏟️ Reforma recortada", aviso))
	p._sorteos.conectar()
	## EL BANCO. La deuda es el único sistema que puede terminar la partida sin
	## perder un partido, así que sus avisos van con marco propio y sonido: si
	## pasaran como una línea más del registro, el jugador llegaría a la semana
	## doce sin haberse enterado de nada.
	if p.mundo.banco != null:
		p.mundo.banco.aviso.connect(func(titulo: String, texto: String) -> void:
			p._escribir("[color=#e05555][b]%s.[/b][/color] %s" % [titulo, texto])
			p._anotar(titulo, texto)
			Aviso.mostrar(p, "alerta", "🏦", titulo, texto))
		## El libro de movimientos lo lleva `Mundo`, no la pantalla: es el mismo
		## sitio donde se anotan taquilla, sueldos y fichajes.
		p.mundo.banco.movimiento.connect(p.mundo._anotar_movimiento)
	## LA HINCHADA (13-9-2026, hallazgo de la auditoría de conectores): tenía
	## sus dos señales -campañas de abonos, la barra plantándose, encuestas a
	## los socios- escritas y disparándose de verdad desde hace tiempo, y
	## NINGUNA llegaba a la pantalla -mismo patrón que ya se vio con
	## selecciones/cantera/logros/cesiones en sesiones anteriores: el motor
	## corría solo y en silencio-. Se crea de nuevo en cada `tomar_el_mando()`
	## (igual que `banco`/`ciudad`/`comercial`, arriba), así que no hace falta
	## candado.
	if p.mundo.hinchada != null:
		p.mundo.hinchada.noticia.connect(func(titulo: String, texto: String) -> void:
			p._escribir("[color=#c9a227][b]%s.[/b][/color] %s" % [titulo, texto])
			p._anotar(titulo, texto))
		p.mundo.hinchada.movimiento.connect(p.mundo._anotar_movimiento)
