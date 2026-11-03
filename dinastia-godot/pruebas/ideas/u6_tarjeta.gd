extends BaseIdea
## U6 (3-11): pagar con TARJETA y PIN en la tienda de la gasolinera, la gasolinera y la expendedora. A partir de 100 € (o con «Pagar con tarjeta y PIN» en la caja) el comercio
## abre el teclado del PIN (`PanelPagoPin`, el mismo de `TecladoPin` que el cajero) en vez de negarse; el PIN malo resta intentos, tres bloquean y el bueno cobra con la tarjeta.

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _teclear(p: PanelPagoPin, pin: String) -> void:
	for ch in pin:
		p._tecla(ch)

func _ready() -> void:
	await get_tree().process_frame
	_titulo("U6 · PAGO CON TARJETA Y PIN")
	_m = _mundo(4242)
	_m.reloj.sincronizar(_m.anio, _m.semana)
	_m.prologo_visto = true
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	var perfil := _m.perfil_estadio_de(club)
	_vista.abrir(club, _m.obras, _m.ciudad, perfil)
	var est := TunelVestuario.datos(perfil, StadiumBuilder.niveles_de(perfil, int(perfil.get("aforo", 20000))))
	_vista.explorar("pie", CityBuilder.ESTADIO_EN + (est["puerta"] as Vector3) + Vector3(0, 0, 7.0))
	_e = _vista._explorador
	await _frames(2)
	_v = VidaCiudad.enganchar(_e, _vista, _m)
	var c := _m.roles.cartera
	_m.roles.patrimonio = 5000
	c.efectivo = 0
	c.pin = "1234"
	## 1) Un artículo de 150 € (más de 100): sin PIN no se cobra; se abre el teclado.
	var caro := {"id": "caro", "nombre": "Bebida energética", "precio": 150, "energia": 15, "hambre": 0}
	var cuenta0 := c.cuenta_eur(_m.roles)
	var msg := _v.comprar_surtido(caro)
	_comprobar(is_instance_valid(_v._panel_pin) and c.cuenta_eur(_m.roles) == cuenta0, "más de 100 €: abre el teclado del PIN y todavía no cobra (%s)" % msg)
	var pn: PanelPagoPin = _v._panel_pin
	_teclear(pn, "0000")
	_comprobar(is_instance_valid(pn) and c.fallos_pin == 1 and c.cuenta_eur(_m.roles) == cuenta0, "un PIN malo no cobra y resta un intento")
	var e0 := _m.necesidades.energia()
	_teclear(pn, "1234")
	_comprobar(not is_instance_valid(pn) or pn.is_queued_for_deletion(), "con el PIN bueno el teclado se cierra")
	_comprobar(c.cuenta_eur(_m.roles) == cuenta0 - 150 and c.fallos_pin == 0, "y cobra 150 € con la tarjeta (cuenta %d→%d)" % [cuenta0, c.cuenta_eur(_m.roles)])
	_comprobar(_m.necesidades.energia() > e0 or e0 >= 85, "y el producto llega (energía %d→%d)" % [e0, _m.necesidades.energia()])
	await _frames(1)
	## 2) Tres PIN malos bloquean la tarjeta.
	_v.comprar_surtido(caro)
	pn = _v._panel_pin
	_teclear(pn, "1111")
	_teclear(pn, "2222")
	_teclear(pn, "3333")
	_comprobar(c.bloqueada, "tres PIN malos bloquean la tarjeta")
	var cuenta1 := c.cuenta_eur(_m.roles)
	pn.salir()
	await _frames(1)
	_comprobar(_v.comprar_surtido(caro).contains("bloqueada") and c.cuenta_eur(_m.roles) == cuenta1, "bloqueada: ni teclado ni cobro, y avisa")
	c.desbloquear()
	## 3) «Pagar con tarjeta y PIN» en la caja: un bocadillo de 2 € con PIN en vez de efectivo.
	c.efectivo = 50
	var barato := {"id": "snack", "nombre": "Bocadillo envasado", "precio": 2, "energia": 3, "hambre": 10, "con_pin": true}
	_v.comprar_surtido(barato)
	_comprobar(is_instance_valid(_v._panel_pin) and c.efectivo == 50, "con «tarjeta y PIN» pide el PIN aunque lleves efectivo")
	pn = _v._panel_pin
	var cuenta2 := c.cuenta_eur(_m.roles)
	_teclear(pn, "1234")
	_comprobar(c.efectivo == 50 and c.cuenta_eur(_m.roles) == cuenta2 - 2, "y cobra de la cuenta, no del efectivo")
	await _frames(1)
	## 4) Sin PIN pedido, lo barato sigue pagándose como siempre (efectivo).
	var snack := {"id": "snack", "nombre": "Bocadillo envasado", "precio": 2, "energia": 3, "hambre": 10}
	_v.comprar_surtido(snack)
	_comprobar(not is_instance_valid(_v._panel_pin) and c.efectivo == 48, "lo barato sigue cobrándose del efectivo, sin teclado")
	## 5) Gasolinera: con «tarjeta y PIN» el surtidor pide el PIN antes de repostar (un depósito normal no llega a 100 €).
	var sr := _v._redes()
	var surt: Dictionary = sr.surtidor(0) if sr != null else {}
	_comprobar(not surt.is_empty(), "hay un surtidor para probar")
	if not surt.is_empty():
		_m.vida.combustible = 0.0
		c.efectivo = 500
		var cuenta3 := c.cuenta_eur(_m.roles)
		var r := _v.repostar("surtidor_0", "normal", "", true)
		_comprobar(is_instance_valid(_v._panel_pin) and _m.vida.combustible < 1.0 and c.cuenta_eur(_m.roles) == cuenta3 and c.efectivo == 500, "gasolinera con «tarjeta y PIN»: pide el PIN y no reposta antes (%s)" % r)
		_teclear(_v._panel_pin, "1234")
		_comprobar(_m.vida.combustible > 40.0 and c.cuenta_eur(_m.roles) < cuenta3 and c.efectivo == 500, "con el PIN bueno reposta y cobra de la cuenta, no del efectivo")
		await _frames(1)
		_m.vida.combustible = 0.0
		_v.repostar("surtidor_0", "normal")
		_comprobar(not is_instance_valid(_v._panel_pin) and _m.vida.combustible > 40.0 and c.efectivo < 500, "sin marcar la casilla, reposta con efectivo y sin teclado")
	## 6) Las frases nuevas están traducidas.
	var json := JSON.parse_string(FileAccess.get_file_as_string("res://datos/idiomas_extra.json")) as Dictionary
	for clave: String in ["Son %d €: teclea el PIN de la tarjeta.", "Pago con tarjeta", "Pagar con tarjeta y PIN"]:
		var ok := true
		for l: String in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
			ok = ok and (json[l] as Dictionary).has(clave) and String((json[l] as Dictionary)[clave]).count("%") == clave.count("%")
		_comprobar(ok, "traducida a los 8 idiomas: «%s»" % clave)
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
