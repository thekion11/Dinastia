class_name JornadaCelebracion
extends RefCounted
## LOS FESTEJOS POR TIPO DE TÍTULO (10-11): al levantar un título (`Logros.titulo_celebrado`, su fecha) se abre `EventoCelebracion` con la
## escena de su tipo (`TipoTitulo`); en la liga se puede pasar desde ahí a la vuelta olímpica 3D de siempre (`_ver_vuelta_olimpica`). Al
## cerrar la liga, el ascenso o la salvación tienen el suyo, más sobrio (`fin_de_liga`). Sin pantalla (banco) no se muestra nada.
static var _abierto := false

static func ofrecer(pr: Principal, titulo: String, tipo := "") -> void:
	if _abierto or DisplayServer.get_name() == "headless" or pr.mundo == null or pr.mundo.mi_club() == null:
		return
	if tipo == "":
		tipo = TipoTitulo.de(pr.mundo, titulo)
	_abierto = true
	var ev := EventoCelebracion.mostrar(pr, titulo, tipo, rival_del_pasillo(pr.mundo))
	var op: String = await ev.elegido
	ev.queue_free()
	_abierto = false
	if op == "vuelta":
		pr._vistas._ver_vuelta_olimpica(titulo)

## Al terminar la liga: ascenso o salvación (si tocan), una vez por temporada.
static func fin_de_liga(pr: Principal) -> void:
	if pr.mundo == null or pr.mundo.prensa == null:
		return
	var tipo := TipoTitulo.de_fin_de_liga(pr.mundo)
	var clave := "festejo_%s:%d" % [tipo, pr.mundo.anio]
	if tipo == "" or pr.mundo.prensa.eventos_vistos.has(clave):
		return
	pr.mundo.prensa.eventos_vistos.append(clave)
	await ofrecer(pr, Idiomas.t("Ascenso") if tipo == "ascenso" else Idiomas.t("Permanencia"), tipo)

## El rival que hace el pasillo: el segundo de tu liga (o cualquiera).
static func rival_del_pasillo(m: Mundo) -> Club:
	var l := m.liga_de(m.mi_club())
	if l == null:
		return null
	for f: Dictionary in l.tabla():
		if f["club"] != m.mi_club():
			return f["club"]
	return null
