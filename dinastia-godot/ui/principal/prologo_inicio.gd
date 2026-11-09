class_name PrologoInicio
extends RefCounted
## EL PRÓLOGO AL EMPEZAR (9-11): con la ciudad 3D apagada, el prólogo es la animación fija (`PrologoAnimado`, sin vídeo, saltable). Lo lanza `AvanceSemana._refrescar` una
## sola vez cuando la partida lo tiene pendiente (partida nueva, o «Continuar» si no llegó a verse). Sin pantalla (banco) no se muestra y queda pendiente.
static func ofrecer(pr: Principal) -> void:
	var m := pr.mundo
	if DisplayServer.get_name() == "headless" or m == null or m.prologo_visto or not m.prologo_pendiente or InterruptorCiudad.activa:
		return
	var v := PrologoAnimado.mostrar(pr)
	await v.terminado
	v.queue_free()
	m.prologo_visto = true
	m.prologo_pendiente = false
