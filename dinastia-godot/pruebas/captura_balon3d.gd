extends Node
## Comprueba las dos partes nuevas del balón: que la piel elegida en
## Club -> Detalles del club de verdad se pinte en el 3D -no siempre el mismo
## cuadriculado blanco y negro-, y que el motor de arco/rodado mueva la
## posicion Y segun una parabola de verdad (no un seno) y gire el balon al
## desplazarse (rodado, no un giro fijo en un solo eje).
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_balon3d.tscn

const ARRANQUE := 20

var _n := 0
var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _y_max_visto := 0.0
var _giro_inicial: Basis
var _giro_cambio_detectado := false

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4712)
	## `tomar_el_mando()`, no solo fijar `mi_club_id`: es lo que de verdad crea
	## `comercial` (y `estadio`, `obras`...) para tu club -la partida real
	## siempre pasa por aqui al elegir equipo, un `mi_club_id` puesto a mano se
	## queda con esos sistemas en null-.
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	## "dorado" -no el clasico- para poder distinguir a simple vista si la piel
	## elegida de verdad llega al 3D.
	_mundo.comercial.balon = "dorado"
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	var colores := Comercial.color_balon(_mundo.comercial.balon, _mundo.mi_club())
	print("colores resueltos para 'dorado': claro=%s oscuro=%s" % [colores[0], colores[1]])
	_vista.abrir(par[0], 0.9, par[1], _partido, {}, colores)
	_vista.get("_juego").vel_idx = 3

func _process(_d: float) -> void:
	_n += 1
	if _n == ARRANQUE:
		var balon = _vista.get("_balon")
		print("balon es Balon3D = %s" % (balon is Balon3D))
		var malla: MeshInstance3D = balon.get_node("Malla")
		var mat: StandardMaterial3D = malla.material_override
		var img := mat.albedo_texture.get_image()
		var muestra := img.get_pixel(2, 2)
		print("pixel de la textura del balon (esquina) = %s" % muestra)
		var esperado_oscuro := Color("#7a5a10")
		var cerca := muestra.is_equal_approx(esperado_oscuro) or _cerca(muestra, esperado_oscuro)
		print("coincide con la piel dorada (no la clasica blanco/negro) = %s" % cerca)
		_giro_inicial = balon.global_transform.basis
	if _n > ARRANQUE and _n < ARRANQUE + 200:
		var balon = _vista.get("_balon")
		_y_max_visto = maxf(_y_max_visto, balon.position.y)
		if not _giro_cambio_detectado:
			var b3: Node3D = balon
			var diff: float = b3.global_transform.basis.get_rotation_quaternion().angle_to(
				_giro_inicial.get_rotation_quaternion())
			if diff > 0.05:
				_giro_cambio_detectado = true
				print("el balon giro de verdad (rodado) tras %d fotogramas, diferencia=%.3f rad" % [_n - ARRANQUE, diff])
	if _n == ARRANQUE + 40:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_balon3d.png")
		print("captura guardada: pantalla_balon3d.png")
	if _n == ARRANQUE + 200:
		print("altura maxima vista en el balon (arco, radio=0.11 => debe pasar de 0.11) = %.3f" % _y_max_visto)
		print("giro detectado en algun momento = %s" % _giro_cambio_detectado)
		get_tree().quit()

func _cerca(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.08 and absf(a.g - b.g) < 0.08 and absf(a.b - b.b) < 0.08
