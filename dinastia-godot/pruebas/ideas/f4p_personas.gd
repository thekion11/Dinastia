extends BaseIdea
## f4p · PERSONAS EN PERSONA, EN 3D (fase 4, bloques 1-2): con la ciudad real, la
## cita marcada con «Ir» pone la flecha; la persona tiene cuerpo en su sitio solo en
## su hora; la E abre la charla y la respuesta resuelve la cita (lo de siempre con el
## bono) y la persona se va. Fuera de hora, nadie.

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad
var _c: CitasCiudad

func _ready() -> void:
	await get_tree().process_frame
	await _probar_async()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _probar_async() -> void:
	_titulo("f4p: personas en persona (3D)")
	_m = _mundo(4242)
	_m.reloj.sincronizar(_m.anio, _m.semana)
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	var perfil := _m.perfil_estadio_de(club)
	_vista.abrir(club, _m.obras, _m.ciudad, perfil)
	_vista.explorar("pie", Vector3(0, 0, -440))
	_e = _vista._explorador
	await _frames(2)
	_v = VidaCiudad.enganchar(_e, _vista, _m)
	_c = _v.citas_3d if _v != null else null
	_comprobar(_c != null and _c.hud != null and not _c.hud._saltar.visible, "la vida monta las citas 3D con su HUD (sin «Saltar prólogo»)")
	if _c == null:
		return
	## La cita de patrocinio de la primera semana, en el centro comercial.
	var pend := _m.citas.pendientes()
	_comprobar(not pend.is_empty(), "hay una cita pendiente (%d)" % pend.size())
	if pend.is_empty():
		return
	var ct: Dictionary = pend[0]
	var p := _c.punto_de(ct)
	_comprobar(p != Vector3.INF, "su sitio existe en la ciudad (%s → %s)" % [String(ct["tipo"]), str(p)])
	## Fuera de hora: nadie, y la flecha solo si está marcada con «Ir».
	_m.reloj.dia = int(ct["dia"])
	_m.reloj.minuto = (int(ct["hora"]) - 2) * 60
	_e.cuerpo.position = _e.buscar_libre(p + Vector3(6, 0, 6))
	_c._revisar_cuerpos()
	_comprobar(_c.cuerpos.is_empty(), "fuera de su hora la persona no está")
	_c._process(0.6)
	_comprobar(not _c.hud._flecha.visible, "sin «Ir» no hay flecha")
	_m.citas.objetivo = String(ct["id"])
	_c._process(0.6)
	_comprobar(_c.hud._flecha.visible and _c.hud._flecha.text.contains("m"), "con «Ir» la flecha marca los metros (%s)" % _c.hud._flecha.text)
	## En su hora: la persona aparece con nombre y cargo.
	_m.reloj.minuto = int(ct["hora"]) * 60 + 15
	_c._revisar_cuerpos()
	await _frames(2)
	_comprobar(_c.cuerpos.has(String(ct["id"])), "en su hora aparece con cuerpo")
	var per: PrologoMentor = _c.cuerpos.get(String(ct["id"]))
	_comprobar(per != null and per.nombre == String(ct["quien"]) and per.cargo == String(ct["cargo"]), "con su nombre y su cargo")
	if per == null:
		return
	## Acercarse: la E habla; la respuesta resuelve la cita.
	_e.cuerpo.position = per.position + Vector3(0, 0, 1.2)
	_c._buscar_cerca()
	_comprobar(_c.cerca_id == String(ct["id"]) and _e._aviso.text.contains(per.nombre), "a su lado la E ofrece hablar")
	var zona := String(ct["clave"]).split("|")[0]
	_comprobar(_c.usar() and is_instance_valid(_c.hud._directiva) and not _e.is_physics_processing(), "E abre la charla con las dos respuestas y el paseo se queda quieto")
	_c._responder(0)
	await _frames(1)
	_comprobar(_m.citas.por_id(String(ct["id"]))["estado"] == "hecha" and _m.comercial.zonas_firmadas.has(zona), "la respuesta resuelve la cita (zona firmada en persona)")
	_comprobar(_e.is_physics_processing() and not _c.cuerpos.has(String(ct["id"])) and _m.citas.objetivo == "", "y el paseo sigue, la persona se va y la flecha se apaga")
	_c._process(0.6)
	_comprobar(not _c.hud._flecha.visible, "sin cita marcada, sin flecha")
	## Una cita en el estadio apunta dentro del club.
	_m.junta.formar(club)
	_m.junta.pendiente = _m.junta._tema(club, _m.junta.accionistas[0])
	_m.citas.semana(_m, _m.semana)
	var cj := {}
	for x: Dictionary in _m.citas.pendientes():
		if x["tipo"] == "junta":
			cj = x
	_comprobar(not cj.is_empty() and _c.punto_de(cj) != Vector3.INF, "la cita con el presidente tiene sitio en el despacho")
	if not cj.is_empty():
		_m.citas.objetivo = String(cj["id"])
		_c._process(0.6)
		_comprobar(_c.hud._flecha.visible and _c.hud._flecha.text.contains(Idiomas.t("entra al estadio")), "desde la calle la flecha dice que entres al estadio")
		_m.reloj.dia = int(cj["dia"])
		_m.reloj.minuto = int(cj["hora"]) * 60
		_c._revisar_cuerpos()
		_comprobar(not _c.cuerpos.has(String(cj["id"])), "desde la calle no se ve al presidente en su despacho")
	## Fase 5, bloque 1: el vestuario con vida (laborables de 10 a 12, en la planta 0 del club).
	var vest := _c.vestuario
	_comprobar(vest != null, "las citas 3D montan el vestuario con vida")
	if vest != null:
		_e._entrar_al_estadio()
		_m.reloj.dia = 1
		_m.reloj.minuto = 10 * 60 + 30
		vest.revisar()
		await _frames(2)
		_comprobar(vest.cuerpos.size() == VestuarioVivo.CUANTOS, "en horario hay %d futbolistas junto a las taquillas" % VestuarioVivo.CUANTOS)
		if not vest.cuerpos.is_empty():
			var c0: Dictionary = vest.cuerpos[0]
			var jug: PrologoMentor = c0["nodo"]
			_comprobar(jug.nombre == Nombres.visible((c0["jugador"] as Jugador).nombre), "con el nombre de la plantilla (%s)" % jug.nombre)
			_e.cuerpo.position = jug.position + Vector3(0, 0, 1.0)
			vest._buscar_cerca()
			_comprobar(not vest.cerca.is_empty() and _c.usar(), "a su lado la E habla con él")
		_m.reloj.minuto = 14 * 60
		vest.revisar()
		_comprobar(vest.cuerpos.is_empty(), "fuera de horario el vestuario queda vacío")
		_e._salir_del_estadio()
	Principal.mundo_pregenerado = null
	Principal.mundo_a_cargar = null
