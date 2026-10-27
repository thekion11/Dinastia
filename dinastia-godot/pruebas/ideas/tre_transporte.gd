extends BaseIdea
## TRANSPORTE (27-10-2026): gente esperando de pie en los andenes (móvil / llamada / quieto), viaducto de hormigón con manchas y
## autobuses que paran en las marquesinas haciendo subir y bajar pasajeros.

func _probar() -> void:
	_titulo("TRANSPORTE · ANDENES CON GENTE, VIADUCTO Y PARADAS DE AUTOBÚS")
	var raiz := Node3D.new()
	add_child(raiz)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var d := Mini3D.persona(raiz, rng, Vector3.ZERO)
	_comprobar(not d.is_empty(), "nace una persona del pack para esperar en el andén")
	if not d.is_empty():
		_comprobar(PeatonVida.en_anden(d, 0.1) == 0 and FutbolistaQ.esqueleto_de(d["nodo"]).find_child("Movil", false, false) != null, "de pie y con el 10 % de azar mira el móvil (lleva el móvil en la mano)")
		var d2 := Mini3D.persona(raiz, rng, Vector3(2, 0, 0))
		_comprobar(PeatonVida.en_anden(d2, 0.9) == 2 and FutbolistaQ.esqueleto_de(d2["nodo"]).find_child("Movil", false, false) == null, "con el 90 % se queda quieto, sin móvil")
		var d3 := Mini3D.persona(raiz, rng, Vector3(4, 0, 0))
		_comprobar(PeatonVida.en_anden(d3, 0.6) == 1 and FutbolistaQ.esqueleto_de(d3["nodo"]).find_child("Movil", false, false) != null, "y con el 60 % habla por teléfono")
	## El viaducto del metro lleva hormigón texturado.
	var metro := MetroCiudad.new()
	add_child(metro)
	metro._viaducto(Vector3(0, 0, 0), Vector3(0, 0, 120), Color(0.8, 0.2, 0.2))
	var con_textura := 0
	for mm in metro.find_children("*", "MultiMeshInstance3D", true, false):
		var m := (mm as MultiMeshInstance3D).material_override as StandardMaterial3D
		if m != null and m.albedo_texture != null and m.uv1_triplanar:
			con_textura += 1
	_comprobar(con_textura >= 1, "los pilares del viaducto son de hormigón con manchas (triplanar)")
	## Las paradas del autobús: el punto de la marquesina cae sobre la ruta y el autobús para donde toca.
	var t := TraficoCiudad.new()
	add_child(t)
	var id := t.agregar_ruta(PackedVector3Array([Vector3(0, 0.25, 0), Vector3(200, 0.25, 0), Vector3(200, 0.25, 200), Vector3(0, 0.25, 200)]))
	var s := t.s_mas_cercano(id, Vector3(100, 0, 4))
	_comprobar(absf(s - 100.0) < 1.0, "la marquesina a 4 m de la ruta cae en s=%.0f" % s)
	var bus := Node3D.new()
	t.agregar_vehiculo(bus, id, 60.0, 9.0, 0.0, 0.0)
	t.agregar_paradas_al_ultimo([s], 10.0)
	var espero := false
	for k in 600:
		t._process(0.1)
		if float((t._vehiculos[0] as Dictionary).get("espera", 0.0)) > 0.0:
			espero = true
			break
	_comprobar(espero and absf(bus.position.x - 100.0) < 6.0, "el autobús para junto a la marquesina (x=%.0f)" % bus.position.x)
	## Cuando para, suben y bajan pasajeros: cambia quién está sentado en los bancos de al lado.
	var gs := GenteSentada.new()
	gs._eventos.append(Vector3(100, 0, 0))
	_comprobar(gs.visitas_cerca(Vector3(105, 0, 3)) == 1 and gs.visitas_cerca(Vector3(160, 0, 0)) == 0, "la parada cuenta para los bancos a menos de 16 m")
	var cambian := 0
	for i in 200:
		if GenteSentada.hay_alguien(i, 12, 0) != GenteSentada.hay_alguien(i, 12, 1):
			cambian += 1
	_comprobar(cambian > 40, "tras una parada, sube o baja gente en %d de cada 200 asientos" % cambian)
	gs.free()
	## El mapa del transporte: tres vistas con las líneas numeradas y las estaciones por su nombre.
	var b := CityBuilder.new()
	add_child(b)
	var ex := CiudadExpansion.new(b)
	ex.armar_red()
	ex.armar_bloques()
	ex.armar_transporte()
	var mapa := MapaTransporte.crear(ex, 0)
	add_child(mapa)
	var rutas := mapa._rutas_bus()
	var nums: Array = []
	for r: Dictionary in rutas:
		nums.append(String(r["numero"]))
	_comprobar(nums == ["5", "10", "22", "7", "3"], "cinco líneas de autobús numeradas (%s)" % ", ".join(nums))
	_comprobar(MapaTransporte.color_linea("10") != MapaTransporte.color_linea("22") and ex.lineas_metro.size() == 2, "cada línea tiene su color y hay dos de metro")
	for m in 3:
		mapa.modo = m
		mapa.size = Vector2(1600, 900)
		mapa._draw()
	_comprobar(true, "las tres vistas (completo, autobuses, metro) se dibujan sin error")
	var tr := MetroCiudad.NOMBRES
	_comprobar(tr["Línea 1"][1] == "Transbordo" and tr["Línea 2"][5] == "Transbordo", "«Transbordo» está en el cruce real de las dos líneas (x=660 y z=-660)")
