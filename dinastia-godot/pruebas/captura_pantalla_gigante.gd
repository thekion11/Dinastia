extends Node
## Verificación visual de la tanda del 23-9-2026: la pantalla gigante con
## paneles en rotación y las vallas LED del perímetro con marca de verdad.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_pantalla_gigante.tscn
##
## TRES BUGS DE VERIFICACIÓN QUE ESTA PRUEBA ARREGLA (los dos primeros venían
## de `captura_marcador_pantalla.gd`, del 22-9; el tercero se encontró aquí):
##
##   1. Activaba su cámara dentro de `_ready()`, ANTES de que `VistaEstadio.
##      abrir()` construyera el `CameraRig` -que crea 9 cámaras y activa una-.
##      La del rig ganaba siempre y la captura salía enfocando el césped. Es el
##      "bug en el ENCUADRE de la cámara de la propia prueba" que `LEEME.md`
##      dejó anotado sin diagnosticar. Aquí la cámara se reclama en cada paso,
##      porque además cada gol manda el rig a "Tele Dinámica" (eso SÍ es el
##      comportamiento bueno del juego).
##   2. Forzaba goles con `partido.gol.emit(...)` a secas. Emitir la señal NO
##      sube el marcador: `Partido._anotar()` hace `goles_local += 1` y LUEGO
##      emite. La pantalla mostraba "0 - 0" con toda la razón y la prueba lo
##      daba por bueno.
##   3. Cambiaba el panel y guardaba la captura EN EL MISMO PASO. El PNG sale
##      del frame YA renderizado, así que se fotografiaba el panel anterior:
##      la primera vuelta sacó el cartel de gol creyendo que era el marcador.
##      Aquí cada cambio y su foto van en pasos distintos.
##
## Y además vuelca la textura del `SubViewport` A DISCO directamente
## (`pgt_*.png`): es evidencia del CONTENIDO independiente del encuadre 3D,
## el mismo método que resolvió el lío de la pantalla azul el 22-9.

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _cam: Camera3D
var _liga: Liga
var _guion: Array[Callable] = []
var _paso := 0
var _frame := 0
var _fallos := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	## Dos jornadas jugadas de verdad: sin esto la tabla está a cero y no hay
	## ni un goleador, así que los dos paneles que dependen de datos de liga no
	## entrarían en la rotación y esta prueba no los vería nunca.
	_liga = _mundo.ligas[0]
	_liga.jugar_jornada()
	_liga.jugar_jornada()

	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	_vista.datos_pantalla = _datos(par[0], _liga)
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)
	print("partido: %s vs %s   (abrev %s / %s)" % [par[0].nombre, par[1].nombre,
		PantallaEstadio.abreviatura(par[0]), PantallaEstadio.abreviatura(par[1])])

	_cam = Camera3D.new()
	add_child(_cam)
	_armar_guion()

## Cada entrada es un frame. Las esperas están puestas a propósito: un cambio
## de panel no se ve en el PNG hasta el frame siguiente (bug 3 de arriba).
func _armar_guion() -> void:
	_guion = [
		func() -> void:
			_comprobar()
			_mirar_pantalla()
			_pant().mostrar(PantallaEstadio.Pagina.MARCADOR),
		_esperar,
		func() -> void:
			_guardar("pg_1_marcador_0_0")
			_volcar("pgt_1_marcador"),
		func() -> void: _gol(true, 23),
		_esperar,
		func() -> void:
			if _marcador_dice() == "1 - 0":
				print("OK: el marcador de la pantalla subió a 1 - 0 con el gol real")
			else:
				_mal("la pantalla dice '%s' con el partido 1-0" % _marcador_dice())
			_guardar("pg_2_gol_takeover")
			_volcar("pgt_2_gol"),
		func() -> void:
			_gol(false, 41)
			_partido.posesion_local = 63.0
			_partido.remates_local = 7
			_partido.remates_visita = 3
			_partido.tiros_puerta_local = 4
			_partido.tiros_puerta_visita = 1
			_partido.corners_local = 5
			_partido.corners_visita = 2
			_partido.faltas_local = 8
			_partido.faltas_visita = 11
			_partido.minuto = 67,
		func() -> void: _pant().mostrar(PantallaEstadio.Pagina.MARCADOR),
		_esperar,
		func() -> void:
			_guardar("pg_3_marcador_1_1")
			_volcar("pgt_3_marcador_1_1"),
		func() -> void: _pant().mostrar(PantallaEstadio.Pagina.ESTADISTICAS),
		_esperar,
		func() -> void:
			_guardar("pg_4_estadisticas")
			_volcar("pgt_4_estadisticas"),
		func() -> void: _pant().mostrar(PantallaEstadio.Pagina.GOLES),
		_esperar,
		func() -> void: _volcar("pgt_5_goles"),
		func() -> void: _pant().mostrar(PantallaEstadio.Pagina.TABLA),
		_esperar,
		func() -> void:
			_guardar("pg_6_tabla")
			_volcar("pgt_6_tabla"),
		func() -> void: _pant().mostrar(PantallaEstadio.Pagina.PICHICHI),
		_esperar,
		func() -> void: _volcar("pgt_7_goleadores"),
		_mirar_vallas,
		_esperar,
		func() -> void: _guardar("pg_8_vallas_cerca"),
		_mirar_general,
		_esperar,
		func() -> void:
			_guardar("pg_9_general")
			_comprobar_techo()
			_comprobar_anuncios_por_club()
			print("FIN. %d fallos" % _fallos)
			get_tree().quit(_fallos),
	]

func _esperar() -> void:
	pass

func _mal(txt: String) -> void:
	print("MAL: " + txt)
	_fallos += 1

func _pant() -> PantallaEstadio:
	return _vista._pantalla

## La misma forma de datos que arma `principal.gd::_datos_pantalla_estadio()`.
func _datos(local: Club, liga: Liga) -> Dictionary:
	var filas: Array = []
	for f: Dictionary in liga.tabla():
		var c: Club = f["club"]
		filas.append({"id": c.id, "nombre": c.nombre, "pts": int(f["pts"]),
			"pj": int(f["pj"]), "dif": int(f["dif"])})
	var tiradores: Array = []
	for c: Club in liga.clubes:
		for j: Jugador in c.plantilla:
			if j.goles > 0:
				tiradores.append({"nombre": j.nombre, "club": c.nombre, "goles": j.goles})
	tiradores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["goles"]) > int(b["goles"]))
	return {
		"tabla": filas, "goleadores": tiradores.slice(0, 8),
		"liga": liga.nombre, "jornada": liga.jornada_actual,
		"recinto": "Estadio " + Nombres.limpiar(local.nombre),
	}

## El encuadre NO se calcula a mano: se saca de la malla real. La versión a ojo
## daba por hecho un "cuenco" de 3 niveles y con otra forma apuntaba a
## cualquier parte -misma clase de suposición que el bug 1 de arriba-.
func _malla_pantalla() -> MeshInstance3D:
	var pant := _vista._raiz3d.find_children("PantallaMarcador*", "MeshInstance3D", true, false)
	return pant[0] as MeshInstance3D if not pant.is_empty() else null

func _mirar_pantalla() -> void:
	var m := _malla_pantalla()
	var p := m.global_position if m != null else Vector3(0, 14.0, 62.0)
	var hacia := -signf(p.z) if absf(p.z) > 0.1 else -1.0
	_cam.fov = 34.0
	_cam.position = p + Vector3(0.0, 0.0, hacia * 30.0)
	_cam.look_at(p, Vector3.UP)
	_cam.current = true
	print("camara pantalla: %s  ->  malla en %s" % [_cam.position, p])

## Una valla del lateral, de cerca y en ángulo -como la ve una cámara de TV-.
func _mirar_vallas() -> void:
	_cam.fov = 48.0
	_cam.position = Vector3(20.0, 3.4, 8.0)
	_cam.look_at(Vector3(37.0, 0.9, -14.0), Vector3.UP)
	_cam.current = true

## El plano general, para ver el anillo entero y la pantalla en su sitio.
## DESDE DENTRO DEL CUENCO, no desde fuera: la primera versión ponía la cámara
## en z=84, o sea por detrás de la tribuna sur (que empieza en dz-5,5=62,5 y
## acaba en 73,5), así que la foto salía mirando el techo y la fachada exterior
## -parecía un estadio roto y solo era una cámara mal puesta-.
func _mirar_general() -> void:
	var perfil: Dictionary = _vista._perfil
	var alto := StadiumBuilder.altura_de(perfil, int(perfil.get("aforo", 20000)))
	_cam.fov = 62.0
	_cam.position = Vector3(0.0, alto * 0.85, -46.0)
	_cam.look_at(Vector3(0.0, alto * 0.45, 40.0), Vector3.UP)
	_cam.current = true

func _guardar(nombre: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://pruebas/%s.png" % nombre)
	var activa := get_viewport().get_camera_3d()
	print("captura: %s.png  (camara %s)" % [nombre,
		activa.global_position if activa != null else "NINGUNA"])

## El contenido de la pantalla tal cual, sin pasar por el 3D. Si el PNG de la
## escena y este no coinciden, el problema está en el encuadre o en la malla,
## no en el diseño del panel -y al revés-.
func _volcar(nombre: String) -> void:
	var p := _pant()
	if p == null:
		return
	var img := p.get_texture().get_image()
	if img == null:
		_mal("el SubViewport de la pantalla no devolvió imagen")
		return
	img.save_png("res://pruebas/%s.png" % nombre)

## Igual que `Partido._anotar()`: sube el contador y DESPUÉS emite.
func _gol(es_local: bool, minuto: int) -> void:
	var c: Club = _partido.local if es_local else _partido.visita
	var once: Array[Jugador] = _partido.once_local if es_local else _partido.once_visita
	if es_local:
		_partido.goles_local += 1
	else:
		_partido.goles_visita += 1
	_partido.minuto = minuto
	var autor: Jugador = once[0] if not once.is_empty() else null
	_partido.gol.emit(c, autor, minuto, null)

func _comprobar() -> void:
	var raiz: Node3D = _vista._raiz3d
	var pantallas := raiz.find_children("PantallaMarcador*", "MeshInstance3D", true, false)
	if pantallas.is_empty():
		_mal("no hay ninguna malla PantallaMarcador")
	else:
		var vivas := 0
		for p: MeshInstance3D in pantallas:
			var m := p.material_override
			if m is StandardMaterial3D and (m as StandardMaterial3D).albedo_texture is ViewportTexture:
				vivas += 1
		if vivas == pantallas.size():
			print("OK: %d pantalla(s) con la textura del SubViewport en vivo" % vivas)
		else:
			_mal("solo %d de %d pantallas tienen textura viva" % [vivas, pantallas.size()])
	var led := raiz.find_child("VallasLed", true, false)
	if led == null:
		_mal("no existe el nodo VallasLed")
	else:
		var rotulos := 0
		for h in led.get_children():
			if h is Label3D:
				rotulos += 1
		if rotulos >= 40:
			print("OK: %d vallas LED con rótulo" % rotulos)
		else:
			_mal("solo %d rótulos de valla" % rotulos)
	if _pant() == null:
		_mal("VistaEstadio no montó la PantallaEstadio")
	## Los trapos de la hinchada. Se cuentan porque la primera versión SÍ se
	## creaba y no se veía ninguno -quedaban enterrados entre las butacas 3D-,
	## y sin un número a la vista es imposible distinguir "no se crearon" de
	## "se crearon y están tapados".
	## OJO CON EL ASTERISCO: Godot le pone un sufijo a los hermanos que
	## comparten nombre ("TelonHinchada2", "TelonHinchada3"), y `find_children`
	## hace coincidencia EXACTA sin comodín. Buscando el nombre pelado salían 4
	## de 12 -uno por tribuna- y parecía que faltaban ocho.
	var telones := raiz.find_children("TelonHinchada*", "MeshInstance3D", true, false)
	if telones.size() >= 9:
		var alturas: Array[String] = []
		for t: MeshInstance3D in telones.slice(0, 4):
			alturas.append("%.1f m" % t.global_position.y)
		print("OK: %d telones de hinchada (los primeros, a %s)" % [
			telones.size(), ", ".join(alturas)])
	else:
		_mal("solo %d telones de hinchada (se esperaban 3 por tribuna)" % telones.size())

## EL BUG DE ARQUITECTURA DEL 23-9: la pantalla asomaba por encima del graderío
## y el techo le pasaba por delante, partiéndola con una banda negra. Se
## comprueba con números, no a ojo: el borde de arriba del marco tiene que
## quedar por debajo de la cubierta (`alto + 0.4`) y el de abajo sobre el
## césped.
func _comprobar_techo() -> void:
	var m := _malla_pantalla()
	if m == null:
		return
	var perfil: Dictionary = _vista._perfil
	var alto := StadiumBuilder.altura_de(perfil, int(perfil.get("aforo", 20000)))
	var aabb := m.get_aabb()
	var cima := m.global_position.y + aabb.size.y / 2.0
	var suelo := m.global_position.y - aabb.size.y / 2.0
	if cima < alto + 0.4 and suelo > 0.5:
		print("OK: la pantalla (%.1f..%.1f m) cuelga bajo el techo (%.1f m) y sobre el césped" % [
			suelo, cima, alto + 0.4])
	else:
		_mal("la pantalla va de %.1f a %.1f m y el techo está en %.1f: se cruzan" % [
			suelo, cima, alto + 0.4])

## PEDIDO EXPLÍCITO DEL USUARIO (23-9): "eso de Colo-Colo está bien puesto pero
## debes agregar que eso es una variante por club". Lo era ya -el nombre sale
## de `mi.nombre` y las marcas del hash del club-, pero "lo era" no basta: se
## comprueba con DOS clubes distintos y se imprimen los dos juegos de anuncios.
func _comprobar_anuncios_por_club() -> void:
	var a: Club = _liga.clubes[0]
	var b: Club = _liga.clubes[1]
	var la := _textos(StadiumBuilder._anuncios_de(a.perfil_estadio(), a))
	var lb := _textos(StadiumBuilder._anuncios_de(b.perfil_estadio(), b))
	print("vallas de %s: %s" % [a.nombre, ", ".join(la)])
	print("vallas de %s: %s" % [b.nombre, ", ".join(lb)])
	if la == lb:
		_mal("dos clubes distintos anuncian exactamente lo mismo")
	elif not la.has(a.nombre.to_upper()) or not lb.has(b.nombre.to_upper()):
		_mal("las vallas no llevan el nombre de su propio club")
	else:
		print("OK: cada club tiene su propio juego de vallas, con su nombre")

func _textos(anuncios: Array) -> Array:
	var l: Array = []
	for x: Dictionary in anuncios:
		l.append(String(x.get("texto", "")))
	return l

func _marcador_dice() -> String:
	var p := _pant()
	return p._lbl_marcador.text if p != null and p._lbl_marcador != null else "?"

func _process(_d: float) -> void:
	_frame += 1
	## Los primeros frames son para que el rig ya haya elegido su cámara.
	if _frame < 6:
		return
	## Cada gol manda el `CameraRig` a "Tele Dinámica" -el comportamiento bueno
	## del juego-, y eso le roba el plano a la cámara de la prueba. Se vuelve a
	## reclamar en cada frame en vez de confiar en que nadie la toque.
	if _paso > 0 and _cam != null:
		_cam.current = true
	if _paso >= _guion.size():
		return
	_guion[_paso].call()
	_paso += 1
