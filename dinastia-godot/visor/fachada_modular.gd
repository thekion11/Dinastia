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
## Con `entrada`, los módulos centrales llevan puerta de cristal y una marquesina al frente.
## Con `fino`, cada módulo es la mitad (3,2 m) y cada piso lleva DOS hileras de piezas: las ventanas miden ~3 × 2 m y no 6 × 6 m
## (en edificios de 4 o más pisos las ventanas de 6,4 m se veían estiradas, 27-10-2026).
static func montar(ex: CiudadExpansion, x: float, zf: float, y0: float, ancho: float, pisos: int, entrada := true, fino := false) -> void:
	var mod := MODULO * (0.5 if fino else 1.0)
	var hil := 2 if fino else 1
	var n := maxi(int(ancho / mod), 3)
	var x_ini := x - float(n - 1) * mod * 0.5
	var z := zf + FONDO * 0.5
	var alto := PISO / float(hil)
	var tam := Vector3(mod, alto / 0.625, FONDO)
	var mitad := 1 if fino else 0
	for i in n:
		var px := x_ini + float(i) * mod
		var central := entrada and absi(i - n / 2) <= 1 + 2 * mitad
		_pieza(ex, "building-door-window" if central else "building-window-large-left", Vector3(px, y0, z), tam)
		for r in range(1, pisos * hil):
			_pieza(ex, "building-windows-high-middle", Vector3(px, y0 + float(r) * alto, z), tam)
		_pieza(ex, "roof-flat-border-side", Vector3(px, y0 + float(pisos) * PISO, z), Vector3(mod, 3.0, FONDO))
	if entrada:
		PuertaVida.registrar(ex.b, Vector3(x, y0, zf + FONDO), Vector3(0, 0, 1))
		_pieza(ex, "roof-flat-awning-b", Vector3(x, y0 + PISO - 0.2, zf + 2.2), Vector3(mod * float(3 + 4 * mitad), 3.0, 3.2))
