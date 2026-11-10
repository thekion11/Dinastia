class_name JornadaEventos
extends RefCounted
## LOS EVENTOS DEL CLUB CON DIÁLOGO (10-11): al llegar su fecha (lo dispara `AvanceSemana` al pintar la semana; nunca un menú suelto), si
## `EventosClub.pendiente` trae uno, se abre a pantalla completa (`EventoDialogo`), se aplica la respuesta y se avisa de lo que movió.
## Sin pantalla (banco) no se muestra: el núcleo se prueba aparte.
static var _abierto := false

static func ofrecer(pr: Principal) -> void:
	if _abierto or DisplayServer.get_name() == "headless" or pr.mundo == null or pr._rueda_pop != null:
		return
	var ev := EventosClub.pendiente(pr.mundo)
	if ev.is_empty():
		return
	_abierto = true
	var esc := EventoDialogo.mostrar(pr, ev)
	var op: String = await esc.elegido
	esc.queue_free()
	_abierto = false
	var r := EventosClub.aplicar(pr.mundo, ev, int(op))
	Aviso.mostrar(pr, "vida", "💬", String(ev.get("lugar", "")), "%s %+d · %s %+d" % [Idiomas.t("Moral del plantel"), int(r["moral"]),
		Idiomas.t("confianza de la directiva"), int(r["confianza"])])
	pr._refrescar()
