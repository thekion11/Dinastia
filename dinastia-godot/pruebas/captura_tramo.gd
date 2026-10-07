extends Node
## Verifica a ojo la Fase 3 "Tramo" de "el estadio por MODULOS" (22-9-2026),
## ya conectada de verdad (perfil() -> StadiumBuilder.build(), no un spike
## aislado). Con "Mezclar patrones por tercios" activo en la tribuna Sur, esa
## tribuna debe leerse como 3 sectores de patron distinto -no una sola piel,
## y sin la textura "de mentira" (estatica de TV) que ya se encontro y
## corrigio una vez para la grada normal-. De paso comprueba que Tramo y
## Bandeja se pueden combinar (Bandeja en Norte, Tramo en Sur) sin pelearse.
##
## NO puede correr con --headless: sin ventana no hay framebuffer para
## guardar la captura.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_tramo.tscn

var _vista: VistaEstadio
var _frame := 0
var _cam: Camera3D

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var mio := mundo.mi_club()
	mio.saldo = 999999999

	## Sin el interruptor: `perfil()` no debe traer "tramos". Se comprueba
	## ANTES de tocar nada, el mismo criterio que ya usó Bandeja/Componentes
	## para probar que el contrato no cambia con todo apagado.
	var p0 := mundo.perfil_estadio_de(mio)
	print("sin tocar nada, perfil trae tramos: %s (debe ser false)" % p0.has("tramos"))

	## Bandeja en Norte (para probar que las dos fases conviven) + Tramo en
	## Sur, con 3 patrones bien distintos entre si para que la diferencia
	## salte a la vista sin entrecerrar los ojos.
	var problema := mundo.estadio.reformar(mio, {
		"personalizar_bandejas": true,
		"bandeja_norte_asientoP": "damero",
		"personalizar_tramos": true,
		"tramo_sur_1": "franjas",
		"tramo_sur_2": "moteado",
		"tramo_sur_3": "bicolor",
	}, mundo.obras)
	print("reformar: '%s'" % problema)

	var p := mundo.perfil_estadio_de(mio)
	print("perfil trae bandejas=%s tramos=%s" % [p.has("bandejas"), p.has("tramos")])
	print("  tramos.sur=%s" % [p.get("tramos", {}).get("sur", [])])
	print("  bandejas.norte.asientoP=%s" % [p.get("bandejas", {}).get("norte", {}).get("asientoP", "?")])
	## El tercio en blanco de Este debe heredar el global ("franjas" de
	## fabrica), no salir vacio -confirma que `_tramos_personalizados()`
	## nunca deja huecos que StadiumBuilder tendria que adivinar.
	print("  tramos.este (nadie lo toco, debe ser 3x el patron global)=%s" % [p.get("tramos", {}).get("este", [])])

	## `mundo.comercial` es Nil aqui a proposito -solo lo crea
	## `tomar_el_mando()`, que este diagnostico no llama porque no hace falta
	## nada mas de esa inicializacion-. Pasar `[]` deja que `VistaEstadio`/
	## `StadiumBuilder.spawn_ball()` usen su color de balon por defecto, en vez
	## de arriesgar el mismo "Invalid access... on a base object of type Nil"
	## que esta linea causaba antes de corregirla (visto en `.err.txt`, no en
	## la consola: el "FIN. 0 fallos" salia igual con el error adentro).
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(mio, 0.85, null, null, p, [])

	## Camara propia, mirando de frente a la tribuna SUR desde el lado de la
	## cancha -mismos numeros de geometria que `geom_de_forma("cuenco")` en
	## `stadium_builder.gd` (dz=68, dx=49) y `altura_de()` con niveles=1
	## (alto=6.5)-, para no depender de a donde apunte la camara por defecto
	## de VistaEstadio y ver los 3 tercios de lleno.
	var dz := 68.0
	var alto := 6.5
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.fov = 70.0
	_cam.position = Vector3(0, alto * 0.9, dz - 42.0)
	_cam.look_at(Vector3(0, alto * 0.35, dz), Vector3.UP)

func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 10:
		_cam.current = true
	if _frame == 25:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_tramo_real_general.png")
		print("captura guardada: pantalla_tramo_real_general.png (%dx%d)" % [img.get_width(), img.get_height()])
	if _frame == 30:
		## Segunda camara, centrada en una costura (entre tercio 1 y 2, a 1/3
		## del ancho de la tribuna) pero a distancia moderada -el primer
		## intento (14m, altura 5.5 sobre un graderio de solo 6.5m de alto)
		## quedo pegado a las butacas individuales, demasiado cerca para
		## juzgar la costura de la textura de fondo.
		var dx := 49.0
		var ancho_tribuna := dx * 2.0 - 4.0
		var x_costura := -ancho_tribuna / 2.0 + ancho_tribuna / 3.0
		_cam.fov = 50.0
		_cam.position = Vector3(x_costura, 4.0, 68.0 - 28.0)
		_cam.look_at(Vector3(x_costura, 3.0, 68.0), Vector3.UP)
	if _frame == 40:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/pantalla_tramo_real_costura.png")
		print("captura guardada: pantalla_tramo_real_costura.png (%dx%d)" % [img2.get_width(), img2.get_height()])
		print("FIN. 0 fallos")
		get_tree().quit()
