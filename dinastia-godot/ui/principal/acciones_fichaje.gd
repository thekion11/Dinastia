class_name AccionesFichaje
extends RefCounted
## (fase 6, paso 7 del plan §7.1: sale de `Principal`, ui/principal_p7.gd, el 27-10-2026). `p` es la pantalla principal;
## sus miembros se usan como `p.x` y `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _reconvertir(j: Jugador, pe: String) -> void:
	var posd: Dictionary = (Datos.tabla("POSD") as Dictionary).get(pe, {})
	var r := j.reconvertir(pe)
	if r.is_empty():
		return
	p._partida.apuntar_deshacer("reconvertir a %s de %s" % [j.nombre, pe])
	var d := int(r["despues"]) - int(r["antes"])
	p._escribir("[color=#c9a227]🔁 Reconversión:[/color] %s pasa a jugar de %s. Su media queda en %d (%s%d). Necesita %d semana(s) para asentarse en el puesto." % [
		j.nombre, String(posd.get("n", pe)).to_lower(), r["despues"], "+" if d >= 0 else "", d, int(r["semanas"])])
	(p as Principal)._refrescar()
	(p as Principal)._ver_ficha(j)
func _listar_transferible(j: Jugador) -> void:
	p.mundo.mercado.listar_transferible(j)
	p._escribir("[color=#c9a227]En venta:[/color] %s queda listado como transferible. Se lo tomó mal, pero a partir de ahora van a llegar ofertas por él." % j.nombre)
	(p as Principal)._refrescar()
## Doble toque: la primera pulsación solo arma la confirmación y repinta el
## botón con la advertencia -"vista.confResc" del HTML-. La segunda, con el
## mismo jugador todavía armado, ejecuta de verdad.
func _rescindir(j: Jugador, total: int) -> void:
	if p._confirmar_rescision_id != j.id:
		p._confirmar_rescision_id = j.id
		(p as Principal)._ver_ficha(j)
		return
	p._confirmar_rescision_id = ""
	var mio := p.mundo.mi_club()
	if mio == null or total > mio.saldo:
		return
	p._partida.apuntar_deshacer("rescindir a %s" % j.nombre)
	## Y queda apuntado que fue tuyo: si lo ficha un rival, el dia que se crucen
	## juega con la cuenta pendiente encima.
	Partido.marcar_ex(j, mio.id)
	## El golpe de moral a la plantilla, con más peso si era capitán -HTML añade
	## también "ídolo" (`j.idolo>=62`), que Godot no tiene portado todavía; el
	## capitanazgo solo es una aproximación honesta, no el mismo cálculo-. Se
	## mide ANTES de soltarlo: una vez fuera del club ya no es capitán de nadie.
	var pesado := j.capitan
	mio.mover_saldo(-total)
	mio.soltar(j)
	j.club_id = ""
	j.transferible = false
	j.capitan = false
	var golpe := Azar.ent(7, 13) if pesado else Azar.ent(1, 4)
	var clan: Dictionary = p.mundo.vestuario.clan_de(j) if p.mundo.vestuario != null else {}
	var miembros: Array = clan.get("miembros", [])
	for x in mio.plantilla:
		var cerca: bool = miembros.has(x.id)
		x.moral = clampi(x.moral - golpe * (2 if cerca else 1), 10, 99)
	if not clan.is_empty():
		clan["humor"] = clampi(int(clan.get("humor", 0)) - Azar.ent(10, 25), -100, 100)
	## El agente no olvida quién le rompió un contrato: la misma confianza que
	## `Cantera` ya consulta al ofertar por cualquiera de sus representados.
	if p.mundo.cantera != null:
		var nombre_agente := String(p.mundo.cantera.agente_de(j).get("nombre", ""))
		if nombre_agente != "":
			p.mundo.cantera.confianza_agentes[nombre_agente] = p.mundo.cantera.confianza_de(nombre_agente) - 2
	if p.mundo.prensa != null:
		p.mundo.prensa.animo = clampi(p.mundo.prensa.animo - (Azar.ent(8, 16) if pesado else Azar.ent(1, 4)), 0, 100)
		if pesado:
			p.mundo.prensa.funa = clampi(p.mundo.prensa.funa + Azar.ent(10, 20), 0, 100)
	p._escribir("[color=#e05555][b]Rescindido:[/b][/color] %s deja el club. Finiquito y comisión: %s." % [j.nombre, p._dinero(total)])
	p._seleccionado = null
	(p as Principal)._refrescar()
## "" si se puede fichar/ceder a `j`, o el motivo exacto por el que no -el rol
## primero (ver `Roles.motivo_bloqueo`), y si el rol deja, los desafíos
## activos: "cantera" lo cierra del todo, "local" solo si `j` es extranjero.
## Un solo sitio para las tres puertas -ficha, clausulazo, ceder- que antes
## repetían la misma condición cada una a su manera.
func _motivo_fichaje_bloqueado(j: Jugador) -> String:
	## LA VENTANA DE MERCADO, la primera puerta de todas. Va aqui porque este es
	## el unico punto por el que pasan la ficha, el clausulazo y las cesiones: si
	## se comprobara en cada pantalla, tarde o temprano una se quedaria sin
	## comprobar y se ficharia en marzo.
	## EL EXPEDIENTE DE FAIR PLAY cierra el mercado de PAGO, no el mercado
	## entero: se puede seguir fichando libres, que es exactamente lo que hace un
	## club sancionado de verdad.
	if p.mundo.federacion != null and not p.mundo.federacion.puede_pagar_traspaso() and j != null and j.club_id != "":
		return "Sancionado por fair play financiero: esta ventana solo puedes fichar agentes libres."
	## EN MORA CON EL BANCO. `Banco.estado()` ya prometía "Fichajes inhibidos"
	## a partir de la cuarta semana en rojo, y nada lo hacía cumplir: se podía
	## fichar con normalidad con un veedor concursal encima. Misma frontera
	## que el fair play de arriba -bloquea el mercado de PAGO, no los libres-.
	if p.mundo.banco != null and p.mundo.banco.en_mora() and j != null and j.club_id != "":
		return "En mora con el banco (%d semanas en rojo): esta ventana solo puedes fichar agentes libres." % p.mundo.banco.semanas_en_rojo
	if not p.mundo.mercado_abierto():
		return "Mercado cerrado. Vuelve a abrir en %d semanas: hasta entonces, la plantilla es la que hay." % p.mundo.semanas_hasta_mercado()
	if p.mundo.roles != null and not p.mundo.roles.puede_fichar():
		return String(p.mundo.roles.motivo_bloqueo("fichar"))
	if p.mundo.tiene_desafio("cantera"):
		return "Desafío «solo canteranos»: el mercado te queda vetado. Todo refuerzo tiene que salir de tu academia."
	if p.mundo.tiene_desafio("local") and j != null and j.pais != p.mundo.mi_club().pais:
		return "Desafío «un solo país»: no puedes fichar extranjeros."
	return ""
## El intento de fichaje pasa por las tres puertas en orden y cuenta cuál se
## cerró. Decir solo "no se pudo" sería inútil: lo que hace que la siguiente
## oferta sea mejor es saber si falló el precio, la ficha o las ganas.
func _intentar_fichar(j: Jugador, monto: int, sueldo: int) -> void:
	var mio := p.mundo.mi_club()
	if monto > mio.saldo:
		p._escribir("[color=#e05555]No hay caja: piden %s y tienes %s.[/color]" % [p._dinero(monto), p._dinero(mio.saldo)])
		return
	if not p.mundo.mercado.club_acepta(j, monto):
		p._escribir("[color=#e05555]%s rechaza los %s por %s.[/color]" % [
			p.mundo.clubes[j.club_id].nombre, p._dinero(monto), j.nombre])
		return
	if not p.mundo.mercado.jugador_firma(j, mio, sueldo):
		p._escribir("[color=#c9a227]%s no firma: el club aceptó, pero él no se ve aquí.[/color]" % j.nombre)
		return
	p.mundo.mercado.fichar(j, mio, monto, sueldo, 3)
	Sonido.toca("fichaje")
	p._escribir("[color=#4caf6d]FICHADO: %s por %s (%s/semana).[/color]" % [
		j.nombre, p._dinero(monto), p._dinero(sueldo)])
	(p as Principal)._refrescar()
func _pedir_informe_medico(j: Jugador) -> void:
	var mio := p.mundo.mi_club()
	var problema := p.mundo.medico.informe(j, mio, p.mundo.anio)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo pedir el informe: %s.[/color]" % problema)
		return
	(p as Principal)._refrescar()
	(p as Principal)._ver_ficha(j)

func _enviar_oferta_negociacion() -> void:
	var n := p.mundo.mercado.negociacion
	if n == null:
		return
	var j := n.jugador
	var res := n.enviar_oferta()
	p._negociacion_ultimo = res
	var tipo := String(res.get("tipo", ""))
	match tipo:
		"sin_caja":
			p._escribir("[color=#e05555]%s[/color] %s" % [Idiomas.t("No te alcanza:"),
				Idiomas.t("la parte fija más la comisión cuesta %s.") % p._dinero(int(res.get("hace_falta", 0)))])
		"club_pide_mas":
			## Plantillas con `Idiomas.t` (s3): `prefiere` y `motivo` ya llegan traducidos del núcleo.
			p._escribir("[color=#c9a227]%s[/color] %s" % [
				Idiomas.t("↩️ Contraoferta de %s.") % ((p.mundo.clubes.get(j.club_id) as Club).nombre if p.mundo.clubes.has(j.club_id) else Idiomas.t("el club")),
				Idiomas.t("Faltan unos %s y prefieren %s.") % [p._dinero(int(res.get("falta", 0))), String(res.get("prefiere", ""))]])
		"rota":
			p._escribir("[color=#e05555]❌ Negociación rota.[/color] El club se levantó de la mesa por %s." % j.nombre)
			p.mundo.mercado.cerrar_negociacion()
		"rival_traspaso", "rival_firma":
			var rc: Club = res.get("club")
			p._escribir("[color=#e05555]💥 Fichaje perdido:[/color] %s cerró el traspaso de %s por %s mientras seguías negociando." % [
				rc.nombre if rc else "otro club", j.nombre, p._dinero(int(res.get("precio", 0)))])
			p.mundo.mercado.cerrar_negociacion()
		"jugador_no":
			p._escribir("[color=#c9a227]%s[/color] %s" % [Idiomas.t("%s todavía no firma.") % j.nombre, String(res.get("motivo", ""))])
		"jugador_rota":
			p._escribir("[color=#e05555]%s[/color] %s %s" % [Idiomas.t("❌ %s dice que no.") % j.nombre, String(res.get("motivo", "")),
				Idiomas.t("No se sienta a hablar de él por un tiempo.")])
			p.mundo.mercado.cerrar_negociacion()
		"cerrado":
			var r: Dictionary = res.get("resumen", {})
			Sonido.toca("fichaje")
			p._escribir("[color=#4caf6d][b]✅ Fichaje cerrado:[/b][/color] %s firma por %d temporadas con ficha de %s/semana." % [
				j.nombre, int(r.get("anios", n.anios)), p._dinero(int(r.get("sueldo", n.sueldo)))])
			p.mundo.mercado.cerrar_negociacion()
			p._negociacion_ultimo = {}
	p._refrescar()

## "TU CARRERA" de `vDirectorio()`: el prestigio y la vitrina te siguen de club
## en club -a diferencia de `Directiva.trofeos`, que se quedan en el que
## dejas-, más las dos escaleras (ayudante→DT, DT→director→dueño) y lo que
## trae cada peldaño: un entrenador empleado que puedes cambiar, o -siendo
## dueño- meter capital propio y vender el club. Toda esta lógica ya estaba
## escrita y probada en `Roles`; no había ninguna pantalla que la mostrara.

# ---------------------------------------------------------------------------
#  HANDLERS DE SEÑALES — PanelMercado
#  Los conecta _construir(); los ejecuta Principal porque son los únicos
#  que tienen acceso a `mundo` para modificarlo.
# ---------------------------------------------------------------------------
## Ajusta el rol prometido en la negociación activa. La señal `"__clausula__"`
## es el caso especial de alternar la cláusula de rescisión.
func _al_ajustar_rol_neg(rol: String) -> void:
	if p.mundo == null or p.mundo.mercado.negociacion == null:
		return
	if rol == "__clausula__":
		p.mundo.mercado.negociacion.alternar_clausula()
	else:
		p.mundo.mercado.negociacion.ajustar_rol(rol)
	p._refrescar()
## Ajusta un campo numérico de la negociación activa (fijo, cuotas, bonos…).
func _al_ajustar_campo_neg(campo: String, delta: int) -> void:
	if p.mundo == null or p.mundo.mercado.negociacion == null:
		return
	p.mundo.mercado.negociacion.ajustar(campo, delta)
	p._refrescar()
