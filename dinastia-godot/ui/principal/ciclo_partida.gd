extends RefCounted
## EL CICLO DE VIDA DE LA PARTIDA (fase 0: sale de `Principal`, capas 3, 7, 13,
## 16 y 17).
##
## Una sola responsabilidad: qué `Mundo` tiene la pantalla y cómo se cambia.
## Mundo nuevo, mundo que viene del asistente, cargar y guardar (la ranura
## principal, las tres de Ajustes y el autoguardado), el aviso de guardado
## recuperado del respaldo, el partido que quedó a medias y el deshacer.
##
## Interfaz: `nueva()`, `arrancar_con(m)`, `entrar_cargada(m)`, `guardar()`,
## `cargar()`, `guardar_en(r)`, `cargar_de(r)`, `autoguardar_si_toca()`,
## `apuntar_deshacer(motivo)`, `deshacer()` y `pila_deshacer`. Principal la
## posee (`_partida`) y conserva como puentes lo que se llama desde fuera:
## `_guardar()`, `_autoguardar_si_toca()`, `_deshacer()` y `_pila_deshacer`.
##
## El mundo sigue siendo `p.mundo` (lo leen todas las pantallas): esta clase lo
## cambia, no guarda una copia. `RefCounted`: no conecta señales del mundo.

var p: Principal

## Una sola ranura por ahora, con el nombre de tu club. Cuando haya menú de
## partidas se aprovecha `Partida.listar()`, que ya devuelve club, año y fecha.
const RANURA := "partida"

# DESHACER. El HTML guardaba `JSON.stringify(G)` antes de dos decisiones -responder
# a una oferta y rescindir a un jugador- y las devolvía con un `JSON.parse`. Aquí
# el retrato es `Partida.instantanea()`, que es exactamente el mismo diccionario
# que se escribe en el guardado, y volver atrás es reconstruir el mundo desde él.
# No es un "ctrl+z" general y no pretende serlo: son las dos decisiones que se
# toman con el dedo y se lamentan al segundo siguiente.
#
# TRES COMO MUCHO. Cada retrato es la partida entera; con diez, la memoria se
# llenaría de mundos muertos. El HTML también corta en tres.
const DESHACER_MAX := 3
var pila_deshacer: Array[Dictionary] = []

## EL AUTOGUARDADO SE VE (M-301, 20-10): un «💾 Partida guardada» discreto arriba
## a la derecha que se desvanece solo. Antes se guardaba sin que nadie lo supiera.
var _ind_guardado: Label

func _init(principal: Principal) -> void:
	p = principal

# --- entrar a un mundo --------------------------------------------------------

## El mundo completo -las 24 ligas, ~9.600 jugadores-, igual que genera el
## HTML siempre (`crear()` recorre TODO `PAISES_LIGAS`, nunca un subconjunto).
## Antes esta pantalla se conformaba con 3 países "porque no había nada que
## hacer con los otros 21", pero eso ya no es cierto: Selecciones y Cantera
## recorren el mundo entero buscando elegibles y candidatos, y las copas
## continentales necesitan clubes de muchos países para tener sentido. Y
## generarlo entero no cuesta lo que costaba en el navegador: 376 ms medidos
## aquí contra los "3,2 s" que el propio HTML dejó anotados en un comentario.
func nueva() -> void:
	var m := Mundo.new()
	p.mundo = m
	Escudo.limpiar_cache()
	Cara.limpiar_cache()
	m.generar([], 0)
	## Tomar el mando no es solo elegir club: es que la directiva te ponga un
	## objetivo y empiece a mirarte. Sin eso puedes acabar decimosexto veinte anos
	## seguidos y no pasa nada. Se abre esta escena directo -bancos, capturas- sin
	## pasar por el asistente: toca el primero de Chile, como siempre.
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	arrancar_con(m)

## El camino compartido entre "Nueva partida directa" (arriba) y "vengo del
## asistente con un mundo ya generado y un club ya elegido"
## (`ui/eleccion_club.gd`, que deja `Principal.mundo_pregenerado`): aplicar
## dificultad y modo, conectar el registro, y pintar. Separado para no repetir
## estas seis líneas en dos sitios que tenían que estar siempre de acuerdo.
func arrancar_con(m: Mundo) -> void:
	p.mundo = m
	p._fin_partida_avisado = false
	## La dificultad: por ahora solo escala la caja inicial (el "plata" del
	## HTML, hasta 60% más en fácil o 45% menos en leyenda), que es lo que se
	## nota desde el primer minuto. Sigue sin escalar los premios de la
	## temporada ni las pretensiones salariales -"prem" y "pide" del HTML-,
	## que están repartidos en Finanzas y Mercado y quedan para otra tanda.
	var dif: Variant = Datos.tabla("DIF")
	if dif is Dictionary and (dif as Dictionary).has(Principal.dificultad_elegida):
		var plata := float((dif as Dictionary)[Principal.dificultad_elegida].get("plata", 1.0))
		m.mi_club().saldo = int(round(float(m.mi_club().saldo) * plata))
	## Los desafíos: "pobreza" pisaría la caja de la dificultad si fuera antes,
	## así que van después -es la letra pequeña ganándole a la general, como en
	## el HTML, donde `aplicarDesafios()` también corre después de fijar el
	## saldo por dificultad.
	if not Principal.desafios_elegidos.is_empty():
		m.desafios = Principal.desafios_elegidos.duplicate()
		m.aplicar_desafios()
		Principal.desafios_elegidos = []
	## El modo de carrera elegido en la pantalla previa. Si viene vacío -se
	## abrió esta escena directo, sin pasar por seleccion_modo.gd, como hacen
	## los bancos de prueba y las capturas- se queda el DT clásico de siempre.
	if Principal.modo_elegido != "":
		m.roles.arrancar(Principal.modo_elegido, Principal.dt_nombre_elegido)
		## FONDO DE INVERSIÓN (26-9-2026): el fondo arranca con su propia caja.
		if Principal.modo_elegido == "fondo" and m.mi_club() != null:
			m.fondo = FondoInversion.new()
			m.fondo.caja = int(round(Eco.ref_caja(70.0) * 2.5))
		Principal.modo_elegido = ""
	_adoptar(m)
	p._escribir("[color=#8ea595]Mundo nuevo.[/color] Semilla [color=#3fa06a]%d[/color]" % m.semilla)
	p._refrescar()

## Una partida ya leída del disco (la ranura principal, o la que deja la
## pantalla de inicio en `Principal.mundo_a_cargar`).
func entrar_cargada(m: Mundo) -> void:
	_adoptar(m)
	p._escribir("[color=#3fa06a]Partida cargada:[/color] %s, %d, semana %d." % [
		m.mi_club().nombre, m.anio, m.semana])
	_avisar_si_respaldo()
	p._refrescar()
	_resolver_partido_abandonado()

## Lo que hay que hacer SIEMPRE al cambiar de mundo: engancharle las noticias,
## soltar al jugador seleccionado (es del mundo viejo) y rehacer el selector de
## clubes. Antes eran cuatro líneas copiadas en cinco sitios, y cargar una
## ranura de Ajustes se saltaba las dos últimas: la ficha y el desplegable
## seguían enseñando el mundo de antes hasta el siguiente cambio de club.
func _adoptar(m: Mundo) -> void:
	p.mundo = m
	p._conectar_noticias()
	p._seleccionado = null
	p._llenar_selector()

# --- guardar y cargar ---------------------------------------------------------

func guardar() -> void:
	if Partida.guardar(p.mundo, RANURA):
		p._escribir("[color=#4caf6d]Partida guardada.[/color] %s, %d, semana %d." % [
			p.mundo.mi_club().nombre, p.mundo.anio, p.mundo.semana])
	else:
		p._escribir("[color=#e05555]No se pudo guardar.[/color]")

func cargar() -> void:
	var m := Partida.cargar(RANURA)
	if m == null:
		p._escribir("[color=#c9a227]No hay ninguna partida guardada todavía.[/color]")
		return
	entrar_cargada(m)

## Las tres ranuras de Ajustes (`_pintar_ranuras()`).
func guardar_en(nombre: String) -> void:
	if Partida.guardar(p.mundo, nombre):
		p._escribir("[color=#4caf6d]Guardado en %s.[/color] %s, %d, semana %d." % [
			nombre, p.mundo.mi_club().nombre, p.mundo.anio, p.mundo.semana])
	else:
		p._escribir("[color=#e05555]No se pudo guardar en %s.[/color]" % nombre)
	p._refrescar()

func cargar_de(nombre: String) -> void:
	var m := Partida.cargar(nombre)
	if m == null:
		p._escribir("[color=#c9a227]Esa ranura está vacía.[/color]")
		return
	_adoptar(m)
	p._escribir("[color=#4caf6d]Partida cargada de %s.[/color]" % nombre)
	_avisar_si_respaldo()
	p._refrescar()
	_resolver_partido_abandonado()

## El interruptor de Ajustes → Guardado (`p._autoguardado`). Silencioso a
## propósito -uno por semana durante toda una carrera sería puro ruido en el
## registro-, en la misma ranura que ya usa el botón "Guardar".
func autoguardar_si_toca() -> void:
	if p._autoguardado and Partida.guardar(p.mundo, RANURA):
		_indicador_guardado()

## Si el guardado principal estaba roto y se recuperó la copia (guardado
## seguro, 20-10-2026), se le dice al jugador en vez de callarlo.
func _avisar_si_respaldo() -> void:
	if Partida.cargada_de_respaldo:
		p._escribir("[color=#c9a227]El último guardado estaba dañado: se recuperó la copia anterior.[/color]")
		Partida.cargada_de_respaldo = false

## Si la última vez se cerró el juego con un partido dirigido a medias, se
## completa desde el marcador que había (sin repetirlo desde el 0-0).
func _resolver_partido_abandonado() -> void:
	var d := PartidoPendiente.pendiente(p.mundo)
	if d.is_empty():
		return
	var mio := p.mundo.mi_club()
	if mio == null or (String(d["local"]) != mio.id and String(d["visita"]) != mio.id):
		PartidoPendiente.cerrar()
		return
	var pt := PartidoPendiente.resolver(p.mundo, d)
	if pt == null:
		return
	p._escribir("[color=#c9a227]%s[/color]" % (Idiomas.t("El partido quedó a medias (%d-%d en el %d'): se completó desde ese marcador.") % [int(d["gl"]), int(d["gv"]), int(d["minuto"])]))
	p._seguir_tras_partido(pt)

## El «💾 Partida guardada» cuelga de Principal (esta clase no es un nodo).
func _indicador_guardado() -> void:
	if not p.is_inside_tree():
		return
	if not is_instance_valid(_ind_guardado):
		_ind_guardado = Label.new()
		_ind_guardado.name = "IndicadorGuardado"
		_ind_guardado.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ind_guardado.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_ind_guardado.offset_left = -240.0
		_ind_guardado.offset_right = -20.0
		_ind_guardado.offset_top = 62.0
		_ind_guardado.offset_bottom = 84.0
		_ind_guardado.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_ind_guardado.add_theme_font_size_override("font_size", 13)
		_ind_guardado.add_theme_color_override("font_color", Color(0.75, 0.9, 0.75))
		_ind_guardado.z_index = 50
		p.add_child(_ind_guardado)
	_ind_guardado.text = "💾 " + Idiomas.t("Partida guardada")
	_ind_guardado.modulate.a = 1.0
	var tw := _ind_guardado.create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(_ind_guardado, "modulate:a", 0.0, 0.8)

# --- deshacer -------------------------------------------------------------------

## Guarda el estado ANTES de hacer algo. `motivo` es lo que se le enseña al
## jugador cuando lo deshaga.
func apuntar_deshacer(motivo: String) -> void:
	if p.mundo == null:
		return
	pila_deshacer.append({"motivo": motivo, "estado": Partida.instantanea(p.mundo)})
	while pila_deshacer.size() > DESHACER_MAX:
		pila_deshacer.pop_front()

func deshacer() -> void:
	if pila_deshacer.is_empty():
		p._escribir("[color=#c9a227]No hay nada que deshacer.[/color]")
		return
	var u: Dictionary = pila_deshacer.pop_back()
	var m := Partida.desde_instantanea(u["estado"])
	if m == null:
		p._escribir("[color=#e05555]No se pudo deshacer.[/color]")
		return
	_adoptar(m)
	p._escribir("[color=#3fa06a]Deshecho:[/color] %s." % String(u["motivo"]))
	p._refrescar()
