extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), A4-M3D-014 (decisión del dueño): los comercios de la ciudad abren de 8:00 a 20:00 por el reloj del juego.
##   · Fuera de horario: el aviso dice CERRADO y la E no entra ni compra; dentro, el aviso de siempre y la E entra.
##   · Gasolinera, cajeros y expendedoras (24 h), hotel y peña del club no se cierran.
##   · Las pruebas sueltas sin vida/mundo no se cierran.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")

func _esperar(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _probar() -> void:
	_titulo("A4 MUNDO_3D: horario de comercios de 8:00 a 20:00")
	_comprobar(ComercioCiudad.abierto_a(8.0) and ComercioCiudad.abierto_a(19.99) and not ComercioCiudad.abierto_a(20.0) and not ComercioCiudad.abierto_a(7.99) and not ComercioCiudad.abierto_a(0.0), "abre a las 8:00 y cierra a las 20:00")
	_comprobar(ComercioCiudad.es_comercio("edificio_farmacia") and ComercioCiudad.es_comercio("deportes_1") and ComercioCiudad.es_comercio("banco_0") and ComercioCiudad.es_comercio("peluches_2"), "farmacia, deportes, banco y peluches son comercios")
	_comprobar(not ComercioCiudad.es_comercio("tienda_0") and not ComercioCiudad.es_comercio("edificio_hotel") and not ComercioCiudad.es_comercio("edificio_pena") and not ComercioCiudad.es_comercio("cajero_1") and not ComercioCiudad.es_comercio("edificio_vivienda"), "gasolinera, hotel, peña, cajeros y viviendas no se cierran")
	_comprobar(not ComercioCiudad.cerrado(null, "edificio_farmacia"), "sin explorador (pruebas sueltas) no se cierra")
	AjustesCiudad.guardar("tutorial_visto", true)
	var c: Dictionary = await Comun.abrir(self)
	var vc: Node = c["vc"]
	vc.set("_ciclo_activo", false)
	vc.call("explorar", "pie")
	var e: ExploradorCiudad = vc.get("_explorador")
	await _esperar(8)
	var vida: VidaCiudad = VidaCiudad.enganchar(e, vc, c["m"])
	var reloj: Reloj = vida.mundo.reloj
	var m: Mundo = c["m"]
	## Una hora fuera de horario y otra dentro, movendo el reloj del juego (minuto del día).
	var minuto_antes: int = reloj.minuto
	reloj.minuto = 22 * 60
	e._cerca = {"tipo": "lugar", "k": "edificio_farmacia", "n": "Farmacia"}
	_comprobar(ComercioCiudad.cerrado(e, "edificio_farmacia"), "a las 22:00 la farmacia está cerrada")
	_comprobar(ComercioCiudad.aviso(e, "edificio_farmacia", "Farmacia").contains("CERRADO"), "el aviso lo dice")
	var antes := e.estado
	e.call("_usar")
	await _esperar(2)
	_comprobar(String(e.estado) == String(antes) and not is_instance_valid(e._int_raiz), "con la farmacia cerrada la E no entra (%s)" % e.estado)
	_comprobar(not ComercioCiudad.cerrado(e, "tienda_0") and not ComercioCiudad.cerrado(e, "edificio_hotel"), "la gasolinera y el hotel siguen abiertos de noche")
	reloj.minuto = 11 * 60
	_comprobar(not ComercioCiudad.cerrado(e, "edificio_farmacia") and ComercioCiudad.aviso(e, "edificio_farmacia", "Farmacia") == "E: Farmacia", "a las 11:00 abierta y con el aviso de siempre")
	e.call("_usar")
	await _esperar(3)
	_comprobar(String(e.estado) == "interior", "a las 11:00 la E entra en la farmacia (%s)" % e.estado)
	e.call("_salir_del_edificio")
	reloj.minuto = minuto_antes
	(c["vc"] as Node).free()
