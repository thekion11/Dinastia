class_name JornadaEventos
extends RefCounted
## LOS EVENTOS DEL CLUB CON DIÁLOGO (10-11): al llegar su fecha (lo dispara `AvanceSemana` al pintar la semana; nunca un menú suelto), si
## `EventosClub.pendiente` trae uno, se abre a pantalla completa (`EventoDialogo`), se aplica la respuesta y se avisa de lo que movió.
## Sin pantalla (banco) no se muestra: el núcleo se prueba aparte.
static var _abierto := false

static func ofrecer(pr: Principal) -> void:
	if _abierto or JornadaCelebracion._abierto or DisplayServer.get_name() == "headless" or pr.mundo == null or pr._rueda_pop != null:   ## (10-11) nunca encima de un festejo
		return
	if await JornadaSeleccion.ofrecer_cargo(pr):   ## (10-11) primero, si te llama una selección
		return
	var ev := EventosClub.pendiente(pr.mundo)
	if ev.is_empty():
		return
	_abierto = true
	var esc := EventoDialogo.mostrar(pr, ev)
	esc.tree_exiting.connect(func() -> void:   ## (10-11, caza de fallos) liberada sin elegir: no bloquear los eventos para siempre
		_abierto = false)
	var op: String = await esc.elegido
	esc.queue_free()
	_abierto = false
	var r := EventosClub.aplicar(pr.mundo, ev, int(op))
	Aviso.mostrar(pr, "vida", "💬", String(ev.get("lugar", "")), "%s %+d · %s %+d" % [Idiomas.t("Moral del plantel"), int(r["moral"]),
		Idiomas.t("confianza de la directiva"), int(r["confianza"])])
	pr._refrescar()
