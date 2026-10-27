extends BaseIdea
## p3 · GENTE SENTADA Y SENTARSE DE VERDAD (calidad visual P3, pasada 2, 27-10-2026): la
## ciudad registra asientos (bancos de acera y de parada); con la vida enganchada, cerca de
## un banco hay gente sentada con el clip «sentado» y la raíz a la altura del asiento, que se
## va al alejarte; y el DT, al sentarse en el sofá, encadena «sentarse» → «sentado» y se queda
## así hasta dar un paso.

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad

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
	_titulo("p3: gente sentada y sentarse de verdad")
	_m = _mundo(4242)
	_m.reloj.sincronizar(_m.anio, _m.semana)
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	_vista.abrir(club, _m.obras, _m.ciudad, _m.perfil_estadio_de(club))
	_vista.explorar("pie", Vector3(0, 0, -440))
	_e = _vista._explorador
	await _frames(2)
	var asientos: Array = _e.cb.asientos
	_comprobar(asientos.size() >= 20, "la ciudad registra asientos públicos (%d)" % asientos.size())
	_v = VidaCiudad.enganchar(_e, _vista, _m)
	var gs := _v.sentados if _v != null else null
	_comprobar(gs != null, "la vida monta la gente sentada")
	if gs == null or asientos.is_empty():
		return
	## Junto a un banco con alguien a esta hora.
	var i_ok := -1
	for i in asientos.size():
		if gs.ocupado(i):
			i_ok = i
			break
	_comprobar(i_ok >= 0, "a esta hora hay asientos ocupados")
	if i_ok < 0:
		return
	var p: Vector3 = asientos[i_ok]["p"]
	_e.cuerpo.position = p + Vector3(3.0, -0.79, 0)
	gs.revisar()
	await _frames(2)
	_comprobar(gs.cuerpos.has(i_ok) and gs.cuerpos.size() <= GenteSentada.MAXIMO, "cerca del banco se sienta gente (%d, tope %d)" % [gs.cuerpos.size(), GenteSentada.MAXIMO])
	if gs.cuerpos.has(i_ok):
		var d: Dictionary = gs.cuerpos[i_ok]["d"]
		var n: Node3D = d["nodo"]
		_comprobar((d["anim"] as AnimationPlayer).current_animation == "sentado", "con el clip «sentado»")
		_comprobar(n.position.y < p.y - 0.3 and n.position.y > p.y - 1.2, "con la cadera a la altura del asiento (raíz a %.2f bajo el asiento)" % (p.y - n.position.y))
	_e.cuerpo.position = p + Vector3(200.0, 0, 0)
	gs.revisar()
	_comprobar(not gs.cuerpos.has(i_ok), "al alejarte, se va")
	## El DT en el sofá: sentarse y quedarse sentado.
	_e._gesto_propio("sentarse", "sentado")
	_comprobar(_e._anim != null and _e._anim.current_animation == "sentarse" and _e._anim.get_queue().has("sentado"), "«sentarse» encadena «sentado»")
	_comprobar(_e._anim != null and _e._anim.get_animation("sentarse").loop_mode == Animation.LOOP_NONE, "y el clip de sentarse no se repite")
	_comprobar(_e._t_gesto_propio > 1000.0, "el gesto dura hasta que te muevas")
	_e._gesto_propio("saludo_mano")
	_comprobar(_e._t_gesto_propio <= 3.0, "un gesto suelto sigue durando lo que su clip")
	Principal.mundo_pregenerado = null
	Principal.mundo_a_cargar = null
