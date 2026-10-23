class_name Mercado
extends "res://nucleo/mercado_p1.gd"
## (Parte 2 de 2 de `mercado.gd`.)

func desde_dic(d: Dictionary) -> void:
	ofertas_recibidas.clear()
	var m := _mundo()
	if m == null:
		return
	for o: Dictionary in d.get("ofertas_recibidas", []):
		var club: Club = m.clubes.get(String(o.get("club_id", "")))
		var j := _jugador_por_id(String(o.get("jugador_id", "")))
		## Entre que se guardó y se volvió a cargar no ha pasado nada -es la misma
		## sesión-, pero si algún día un guardado viejo apunta a alguien que ya no
		## está (retirado, vendido a un club que ya no existe), se descarta la
		## oferta en vez de reventar la carga por ella.
		if club == null or j == null:
			continue
		ofertas_recibidas.append({"jugador": j, "club": club, "monto": int(o.get("monto", 0)),
			"semana": int(o.get("semana", 0)), "clausula": bool(o.get("clausula", false))})

# ---------------------------------------------------------------------------
#  LA MESA DE NEGOCIACIÓN
# ---------------------------------------------------------------------------

## `abrirNegociacion()` del HTML: las puertas que hay que pasar ANTES de
## sentarse -rol, ventana de mercado, cupo de extranjeros, "no me quiere
## hablar hasta la semana X" tras una mesa rota-. Devuelve "" si se abrió.
func abrir_negociacion(j: Jugador) -> String:
	var m := _mundo()
	var mio := m.mi_club()
	if j == null or mio == null or j.club_id == mio.id:
		return "ese jugador ya es tuyo"
	if m.roles != null and not m.roles.puede_fichar():
		return String(m.roles.motivo_bloqueo("fichar"))
	if m.tiene_desafio("cantera"):
		return "Desafío «solo canteranos»: el mercado te queda vetado."
	if m.tiene_desafio("local") and j.pais != mio.pais:
		return "Desafío «un solo país»: no puedes fichar extranjeros."
	if j.no_negociar_hasta > 0 and m.semana < j.no_negociar_hasta:
		return "%s no se sienta a hablar de él hasta la semana %d" % [
			(m.clubes.get(j.club_id) as Club).nombre if m.clubes.has(j.club_id) else "Su club", j.no_negociar_hasta]
	## Si diriges un club con filosofía de cantera, la respetas tú también.
	if not Regiones.admite(mio, j):
		var mot := Regiones.motivo(mio)
		return mot[0].to_upper() + mot.substr(1)
	if m.federacion != null:
		var motivo_ext := m.federacion.puede_fichar_extranjero(mio, j)
		if motivo_ext != "":
			return motivo_ext
	negociacion = Negociacion.new(m, j)
	return ""

func cerrar_negociacion() -> void:
	negociacion = null
