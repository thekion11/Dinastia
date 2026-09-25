extends Node
## LAS SEIS FORMAS Y LOS TRES NIVELES, una foto de cada una (23-9-2026).
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_formas_estadio.tscn
##
## POR QUÉ EXISTE: la auditoría de arquitectura del 23-9 encontró que casi
## todos los fallos del estadio eran del mismo tipo -una medida en metros fija
## que solo cuadra con UNA forma y UN número de niveles-. Las capturas de este
## proyecto siempre se habían sacado con el mismo estadio ("cuenco" de 3
## niveles, el de Colo-Colo), así que ninguna de esas roturas se veía nunca:
## los focos flotando sobre el campo, el cubo colgando sobre el techo, la
## pantalla en el lado abierto de la herradura o la esquina metida 3,5 m dentro
## de la cancha solo salen en otras formas.
##
## Esto NO comprueba nada solo: deja seis fotos para mirar. La parte que sí se
## comprueba con números vive en el banco (`_probar_pantalla_y_vallas()`).

const FORMAS := ["cuenco", "ingles", "rect", "herradura", "caldera", "oval"]
## Se varían los niveles a la par de la forma: así las seis fotos cubren
## también los CINCO tamaños de graderío sin necesitar 30 capturas. El 5 va en
## el cuenco, que es la forma por defecto y la del estadio de 150.000.
const NIVELES := [5, 1, 2, 3, 1, 4]
## Y los tipos de pantalla y foco, que son justo los que tenían fallos ligados
## a la geometría.
const PANTALLAS := ["dos", "una", "todo", "dos", "cubo", "todo"]
const FOCOS := ["torres", "corona", "mixto", "corona", "halo", "torres"]

var _mundo: Mundo
var _cam: Camera3D
var _raiz: Node3D
var _i := -1
var _frame := 0
var _fallos := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	_cam = Camera3D.new()
	add_child(_cam)

func _montar(i: int) -> void:
	if _raiz != null:
		_raiz.queue_free()
	_raiz = Node3D.new()
	add_child(_raiz)
	var c: Club = _mundo.ligas[0].clubes[i % _mundo.ligas[0].clubes.size()]
	var perfil := c.perfil_estadio()
	perfil["forma"] = FORMAS[i]
	perfil["niveles"] = NIVELES[i]
	perfil["pantalla"] = PANTALLAS[i]
	perfil["focos"] = FOCOS[i]
	## El aforo tiene que justificar las bandejas: `niveles_de()` recorta por
	## aforo, así que sin esto la foto del "cuenco de 5" saldría con 2.
	perfil["aforo"] = NIVELES[i] * 30000
	Ambience.apply(_raiz, perfil, null, Calidad.elegida)
	StadiumBuilder.build_pitch(_raiz, perfil, c)
	StadiumBuilder.build(_raiz, perfil, int(perfil["aforo"]), 0.85, c._hash_id(), c)
	var g := StadiumBuilder.geom_de_forma(FORMAS[i])
	var alto := StadiumBuilder.altura_de(perfil, int(perfil["aforo"]))
	## Desde la esquina opuesta y por encima del borde de la grada: es el
	## encuadre que enseña a la vez el anillo de vallas, las cuatro tribunas,
	## los focos y la pantalla.
	_cam.fov = 64.0
	_cam.position = Vector3(float(g["dx"]) * 0.55, alto + 6.0, -float(g["dz"]) * 0.78)
	_cam.look_at(Vector3(0, 2.0, float(g["dz"]) * 0.45), Vector3.UP)
	_cam.current = true
	print("%s · %d niveles (alto %.1f) · pantalla '%s' · focos '%s'" % [
		FORMAS[i], NIVELES[i], alto, PANTALLAS[i], FOCOS[i]])
	_revisar_alturas(alto)

## La comprobación numérica que sí se puede hacer aquí: nada de lo que cuelga
## puede quedar por encima del plano del techo ni por debajo del césped.
func _revisar_alturas(alto: float) -> void:
	var techo := alto + 0.7
	for n in _raiz.find_children("PantallaMarcador", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n
		var caja := mi.get_aabb()
		var cima := mi.global_position.y + caja.size.y / 2.0
		var suelo := mi.global_position.y - caja.size.y / 2.0
		if cima > techo or suelo < 0.4:
			print("MAL: pantalla de %.1f a %.1f m con el techo en %.1f" % [suelo, cima, techo])
			_fallos += 1

func _process(_d: float) -> void:
	_frame += 1
	if _frame % 4 != 0:
		return
	if _i >= 0 and _i < FORMAS.size():
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/forma_%d_%s.png" % [_i + 1, FORMAS[_i]])
		print("captura: forma_%d_%s.png" % [_i + 1, FORMAS[_i]])
	_i += 1
	if _i >= FORMAS.size():
		print("FIN. %d fallos" % _fallos)
		get_tree().quit(_fallos)
		return
	_montar(_i)
