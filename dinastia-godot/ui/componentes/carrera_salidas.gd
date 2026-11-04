class_name CarreraSalidas
extends RefCounted
## TU PUESTO Y TUS SALIDAS (3-11-2026, orden 22: «¿cómo cambio de club?, ¿me pueden despedir?»). En «Mi carrera»:
##   · TU PUESTO: la confianza de la directiva y a cuánto estás del despido (por debajo de `UMBRAL_DESPIDO`).
##   · CLUBES QUE TE QUIEREN: hasta tres ofertas (las mismas reglas que tras un despido: tu prestigio + 18), con
##     «Firmar» (doble toque) para irte. Se eligen con una semilla de la semana: no gastan el azar del mundo y no
##     cambian al repintar.
##   · DIMITIR (doble toque): te quedas sin banco y eliges entre las ofertas, como tras un despido.
## Antes, cambiar de club solo era posible si te echaban, y nada en pantalla lo decía.

static var _confirmar := ""

## Las ofertas de esta semana: hasta 3 clubes alcanzables (rep <= prestigio + 18), estables durante la semana.
static func ofertas(m: Mundo) -> Array[Club]:
	var r := m.roles
	var salida: Array[Club] = []
	if r == null:
		return salida
	var alcanzables: Array = []
	for c: Club in m.clubes.values():
		if c.division > 0 and c.id != m.mi_club_id and c.rep <= r.prestigio + 18:
			alcanzables.append(c)
	alcanzables.sort_custom(func(a: Club, b: Club) -> bool:
		return hash([m.anio, m.semana, a.id]) < hash([m.anio, m.semana, b.id]))
	for c: Club in alcanzables.slice(0, 3):
		salida.append(c)
	return salida

static func pintar(p: Principal, padre: Node) -> void:
	var m := p.mundo
	if m.roles == null or m.roles.sin_club or m.directiva == null:
		return
	var d := m.directiva
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("TU PUESTO")
	padre.add_child(t)
	var margen := d.confianza - Directiva.UMBRAL_DESPIDO
	var col := Principal.COL_ROJO if margen <= 10 else (Principal.COL_ORO if margen <= 25 else Principal.COL_VERDE)
	p._dato("Confianza de la directiva", "%d / 100" % d.confianza, col, padre)
	var aviso := p._texto(11, col)
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.text = (Idiomas.t("Te despiden si baja de %d. Te quedan %d puntos: ganar sube la confianza, perder la baja.") % [Directiva.UMBRAL_DESPIDO + 1, margen]) \
		if d.puede_despedirte else Idiomas.t("Hoy no te pueden despedir (eres el dueño o el contrato te protege).")
	padre.add_child(aviso)
	var t2 := p._texto(11, Principal.COL_SUAVE)
	t2.text = Idiomas.t("CLUBES QUE TE QUIEREN")
	padre.add_child(t2)
	var lista := ofertas(m)
	if lista.is_empty():
		var nadie := p._texto(11, Principal.COL_SUAVE)
		nadie.text = Idiomas.t("Ningún club te busca por ahora: gana prestigio con títulos y buenas temporadas.")
		padre.add_child(nadie)
	for c: Club in lista:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		padre.add_child(fila)
		var esc := p._escudo(c, 24)
		esc.custom_minimum_size = Vector2(24, 24)
		fila.add_child(esc)
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = Idiomas.t("%s  ·  división %d  ·  reputación %d") % [c.nombre, c.division, c.rep]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		var b := Button.new()
		var id := c.id
		b.text = Idiomas.t("¿Seguro? Dejas tu club") if _confirmar == id else Idiomas.t("Firmar")
		b.tooltip_text = Idiomas.t("Dejas tu club ahora: lo que construiste se queda allí; tu prestigio y tu vitrina te acompañan.")
		b.pressed.connect(func() -> void:
			if _confirmar != id:
				_confirmar = id
				p._refrescar()
				return
			_confirmar = ""
			var problema := m.roles.aceptar_trabajo(id)
			if problema != "":
				p._escribir("[color=#e05555]%s.[/color]" % problema)
			else:
				Aviso.mostrar(p, "logro", "🤝", Idiomas.t("Nuevo club"), Idiomas.t("Firmaste con %s.") % m.mi_club().nombre)
			p._refrescar())
		fila.add_child(b)
	var bd := Button.new()
	bd.text = Idiomas.t("¿Seguro? Te quedas sin club") if _confirmar == "dimitir" else Idiomas.t("🚪 Dimitir")
	bd.tooltip_text = Idiomas.t("Te vas del club. Después eliges entre los clubes que te quieren, como tras un despido.")
	bd.pressed.connect(func() -> void:
		if _confirmar != "dimitir":
			_confirmar = "dimitir"
			p._refrescar()
			return
		_confirmar = ""
		m.roles.quedar_sin_banco()
		p._refrescar())
	padre.add_child(bd)
