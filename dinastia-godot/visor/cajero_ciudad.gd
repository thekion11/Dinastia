class_name CajeroCiudad
extends RefCounted
## LOS CAJEROS AUTOMÁTICOS DE LA CIUDAD (27-10-2026, pieza B de `PLAN_DEL_LUNES.md` §2.2h). `montar` pone un cajero (cuerpo, pantalla verde, teclado,
## ranura) con su punto `cajero_<n>`; `servicio` es el gancho de la E (aparte de `SubsueloCiudad.servicio` para no tocar el archivo de las redes) y abre
## `PanelCajero` con la cartera del DT. Dos bancos inventados: el propio (sin comisión) y uno ajeno (2 € por retirada). Sin azar: nada toca `_rng`.
const BANCOS := [{"nombre": "Banco Andino", "comision": 0}, {"nombre": "Caja Costera", "comision": 2}]

static func banco_de(k: String) -> Dictionary:
	return BANCOS[absi(k.hash()) % BANCOS.size()]

## `pos` en el suelo, `giro` hacia dónde mira la pantalla (0 → +Z).
static func montar(ex: CiudadExpansion, pos: Vector3, giro: float) -> void:
	var b := ex.b
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = giro
	n.name = "Cajero"
	var k := "cajero_%d" % (absi(hash(Vector2(pos.x, pos.z))) % 100000)
	var azul := b._mat_simple(Color(0.1, 0.22, 0.45), 0.5)
	var gris := b._mat_simple(Color(0.2, 0.2, 0.22), 0.4)
	var verde := b._mat_simple(Color(0.2, 0.9, 0.5), 0.3, 1.4)
	var casco := _caja(Vector3(0.0, 1.05, 0.0), Vector3(0.9, 2.1, 0.7), azul)
	n.add_child(casco)
	n.add_child(_caja(Vector3(0.0, 1.6, 0.36), Vector3(0.62, 0.42, 0.04), verde))      ## pantalla
	n.add_child(_caja(Vector3(0.0, 1.15, 0.4), Vector3(0.5, 0.22, 0.12), gris))        ## teclado
	n.add_child(_caja(Vector3(0.22, 1.3, 0.37), Vector3(0.18, 0.05, 0.03), gris))      ## ranura de la tarjeta
	n.add_child(_caja(Vector3(0.0, 0.75, 0.37), Vector3(0.4, 0.1, 0.03), gris))        ## salida del dinero
	n.add_child(_caja(Vector3(0.0, 2.0, 0.0), Vector3(0.96, 0.22, 0.76), verde))           ## cabecera luminosa con el nombre del banco
	var rot := Label3D.new()
	rot.text = Idiomas.t(String(banco_de(k)["nombre"]))
	rot.font_size = 40
	rot.pixel_size = 0.0035
	rot.modulate = Color(0.05, 0.15, 0.1)
	rot.outline_size = 0
	rot.position = Vector3(0.0, 2.0, 0.385)
	n.add_child(rot)
	b.add_child(n)
	b.puntos_clic.append({"k": k, "n": Idiomas.t("Cajero automático"), "pos": pos, "estado": "ciudad", "radio": 8.0, "alcance": 3.0})

static func _caja(centro: Vector3, tam: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = centro
	return mi

## La E ante un cajero: abre el panel. true si era un cajero.
static func servicio(e, k: String) -> bool:
	if not k.begins_with("cajero_"):
		return false
	return e.vida != null and e.vida.usar_cajero(k)
