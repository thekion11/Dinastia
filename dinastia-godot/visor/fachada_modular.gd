class_name FachadaModular
extends RefCounted
## LA «PLANTILLA DE FACHADA» DE LOS EDIFICIOS SINGULARES (27-10-2026, P1-5 de la auditoría de la ciudad). Los singulares eran
## cajas lisas; esta plantilla les pone cara con las piezas modulares de Kenney (`assets/kenney/edificios_modulares/`, CC0):
## planta baja de escaparates (con la entrada y su marquesina en el centro), pisos de ventanas altas y cornisa. Las piezas miden
## 1 × 0,625 × 1 y se escalan sin deformar la textura de color: MODULO m de ancho y PISO m de alto, y poco fondo (la fachada es
## una piel delante del volumen). Mira al +Z; `ex` es la expansión de la ciudad (de ella salen `_malla_kit` y `b`).
const KIT := "res://assets/kenney/edificios_modulares/%s.glb"
const MODULO := 6.4
const PISO := 4.0
const FONDO := 1.6

static func _pieza(ex: CiudadExpansion, nombre: String, pos: Vector3, tam: Vector3, giro := 0.0) -> void:
	var k: Dictionary = ex._malla_kit(KIT % nombre)
	if k.is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.mesh = k["malla"]
	## El AABB de las piezas va de y=0 hacia arriba y centrado en x/z.
	mi.transform = Transform3D(Basis(Vector3.UP, giro).scaled(tam), pos)
	ex.b.add_child(mi)

## Viste la cara sur del volumen: `x` centro, `zf` plano de la pared, `y0` suelo, `ancho` del edificio, `pisos` de alto.
## Con `entrada`, los tres módulos centrales llevan puerta de cristal y una marquesina al frente.
static func montar(ex: CiudadExpansion, x: float, zf: float, y0: float, ancho: float, pisos: int, entrada := true) -> void:
	var n := maxi(int(ancho / MODULO), 3)
	var x_ini := x - float(n - 1) * MODULO * 0.5
	var z := zf + FONDO * 0.5
	var tam := Vector3(MODULO, PISO / 0.625, FONDO)
	for i in n:
		var px := x_ini + float(i) * MODULO
		var central := entrada and absi(i - n / 2) <= 1
		_pieza(ex, "building-door-window" if central else "building-window-large-left", Vector3(px, y0, z), tam)
		for p in range(1, pisos):
			_pieza(ex, "building-windows-high-middle", Vector3(px, y0 + float(p) * PISO, z), tam)
		_pieza(ex, "roof-flat-border-side", Vector3(px, y0 + float(pisos) * PISO, z), Vector3(MODULO, 3.0, FONDO))
	if entrada:
		PuertaVida.registrar(ex.b, Vector3(x, y0, zf + FONDO), Vector3(0, 0, 1))
		_pieza(ex, "roof-flat-awning-b", Vector3(x, y0 + PISO - 0.2, zf + 2.2), Vector3(MODULO * 3.0, 3.0, 3.2))
