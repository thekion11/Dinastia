extends Node3D
## SPIKE de la Fase 3 "Tramo" de "el estadio por MODULOS" (16-9-2026). Antes
## de comprometer forma de datos, EST_DEF nuevo, UI o persistencia: generar
## la rampa de UNA tribuna con 3 patrones de butaca distintos por tercio
## (izquierda/centro/derecha) y mirar la captura real. Dos preguntas que solo
## una imagen contesta: ¿se lee como 3 sectores de verdad, o como textura
## rota? ¿la inclinacion de la rampa distorsiona la costura entre tercios?
##
## Aislado a proposito -una sola rampa, no el estadio entero- para que el
## unico factor en pantalla sea la textura y su UV, no el resto del recinto.
## No toca `EST_DEF`, `perfil()` ni la UI: `_make_stand_texture_tramos()` solo
## se llama desde aqui, con datos harcodeados.
##
## NO puede correr con --headless: sin ventana no hay framebuffer.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/spike_tramo.tscn

var _frame := 0

func _ready() -> void:
	## Mismas proporciones que una rampa real de `StadiumBuilder.build()`:
	## alto=13 (graderio de 2 niveles tipico), fondo=11 m, largo=90 m de tribuna.
	var alto := 13.0
	var fondo := 11.0
	var subida := alto - 1.5
	var ang := atan2(subida, fondo)
	var largo_rake := sqrt(fondo * fondo + subida * subida)
	var largo_tribuna := 90.0

	var tex := StadiumBuilder._make_stand_texture_tramos(
		["franjas", "damero", "moteado"],
		[
			[Color("#2b6b45"), Color("#ffffff"), Color("#20272a")],  ## izquierda: verde/blanco
			[Color("#c23b3b"), Color("#101010"), Color("#20272a")],  ## centro: rojo/negro
			[Color("#1a5fa8"), Color("#f4d13c"), Color("#20272a")],  ## derecha: azul/amarillo
		], 42, 0.85)

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 1.0
	## SEGUNDA PRUEBA (18-9-2026): la primera corrida uso el mismo repetido
	## "cada ~20m" que usa una tribuna de UN solo patron -asi no se estira sobre
	## los 90m-, pero para "tercios" eso repite el corte de 3 franjas ~4,5
	## veces a lo largo, multiplicando 2 costuras reales en ~13 costuras
	## falsas: se ve como ruido, no como 3 sectores. Aqui SIN repetir
	## (uv1_scale.y=1) para ver la otra punta del problema: sin repetir, cada
	## patron dentro de su tercio se estira a ~30m en vez de ~20m -mas grande,
	## menos "grano de asiento"-, pero como minimo la lectura de 3 sectores
	## deberia ser limpia. Las dos capturas juntas contestan la pregunta real.
	mat.uv1_scale = Vector3(1.0, 1.0, 1.0)

	var deck := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(largo_rake, 0.4, largo_tribuna)
	deck.mesh = dm
	deck.position = Vector3(0, (1.5 + alto) / 2.0, 0)
	## BUG REAL ENCONTRADO (18-9-2026, primera vez que esto corre con pantalla
	## de verdad): con `size = (largo_rake, 0.4, largo_tribuna)` -X=ancho de la
	## rampa subiendo el graderio, Z=largo de la tribuna, la MISMA convencion
	## que usa `StadiumBuilder.build()` para una tribuna lateral- el giro que
	## inclina la rampa tiene que ser sobre el eje Z (`Vector3(0,0,ang)`, ver
	## `stadium_builder.gd:734`), no sobre X. Girar sobre X -lo que tenia esto-
	## es la formula de una tribuna DE FONDO (X=ancho de cancha, Z=rampa), un
	## eje mezclado de las dos convenciones: el resultado no era una rampa
	## inclinada de 90 m de largo, era una tira angosta parada de canto.
	deck.rotation = Vector3(0, 0, ang)
	deck.material_override = mat
	add_child(deck)

	## Suelo neutro y luz de verdad -sin esto la rampa flota en negro y no se
	## lee la inclinacion, que es justo lo que hay que juzgar.
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(140, 140)
	suelo.mesh = pm
	var suelo_mat := StandardMaterial3D.new()
	suelo_mat.albedo_color = Color(0.25, 0.35, 0.22)
	suelo.material_override = suelo_mat
	add_child(suelo)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, -35, 0)
	sol.light_energy = 1.3
	sol.shadow_enabled = true
	add_child(sol)

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.68, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.7)
	env.ambient_light_energy = 0.6
	we.environment = env
	add_child(we)

	## Dos camaras: una de frente a toda la rampa (ve los 3 tercios juntos, la
	## que importa para juzgar la costura) y otra mas cerca de una de las dos
	## uniones (para ver si la textura se rompe justo en el borde).
	##
	## BUG REAL ENCONTRADO Y CORREGIDO (18-9-2026, al fin correr esto con
	## pantalla real por primera vez): los tres tercios van a lo largo del eje
	## Z de la caja (`largo_tribuna`, ver `uv1_scale.y`), pero la camara
	## original estaba puesta y mirando A LO LARGO de ese mismo eje Z -veia la
	## tribuna DE CANTO (la cara angosta de `largo_rake`~11m), no de frente-.
	## El resultado no mostraba los 3 tercios en absoluto, solo una franja
	## vertical angosta. Ahora la camara se pone en X, mirando hacia el centro
	## en Z, para ver la cara larga de frente. Ademas `look_at()` se llama
	## DESPUES de `add_child()` -llamarlo antes tira "Node not inside tree" y
	## deja la camara con la orientacion por defecto, mismo bug ya encontrado
	## una vez en `diagnostico_postura.gd`-.
	var cam1 := Camera3D.new()
	add_child(cam1)
	cam1.position = Vector3(largo_tribuna * 0.62, alto * 0.75, 0)
	cam1.look_at(Vector3(0, alto * 0.4, 0), Vector3.UP)
	cam1.current = true
	var cam2 := Camera3D.new()
	add_child(cam2)
	cam2.position = Vector3(22.0, alto * 0.55, largo_tribuna / 6.0)
	cam2.look_at(Vector3(0, alto * 0.45, largo_tribuna / 6.0), Vector3.UP)
	self.set_meta("cam2", cam2)

func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 15:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_tramo_general_sinrepetir.png")
		print("captura guardada: pantalla_tramo_general_sinrepetir.png (%dx%d)" % [img.get_width(), img.get_height()])
		var cam2: Camera3D = get_meta("cam2")
		cam2.current = true
	if _frame == 30:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/pantalla_tramo_costura_sinrepetir.png")
		print("captura guardada: pantalla_tramo_costura_sinrepetir.png (%dx%d)" % [img2.get_width(), img2.get_height()])
		print("FIN. 0 fallos")
		get_tree().quit()
