class_name CiudadBanco
extends RefCounted
## LA SUCURSAL BANCARIA (27-10-2026, pieza B de `PLAN_DEL_LUNES.md` §2.2h): una ventanilla bajo los soportales de la plaza mayor (mostrador, cristal y rótulo del
## banco propio, «Banco Andino»). E ante ella abre `PanelCajero` en modo ventanilla: sin PIN, desbloquea la tarjeta, restablece el PIN (el banco te identifica) y ve los
## movimientos. Sin azar: nada toca `_rng`.
static func montar(ex: CiudadExpansion, x: float, y: float, z_pared: float) -> void:
	var b := ex.b
	var madera := b._mat_simple(Color(0.45, 0.3, 0.18), 0.6)
	var cristal := b._mat_simple(Color(0.6, 0.8, 0.9), 0.1)
	var azul := b._mat_simple(Color(0.1, 0.22, 0.45), 0.5)
	b._caja_en(Vector3(x, y + 0.55, z_pared + 3.0), Vector3(3.2, 1.1, 0.8), madera)             ## mostrador
	b._caja_en(Vector3(x, y + 1.6, z_pared + 3.0), Vector3(3.2, 1.0, 0.05), cristal)            ## cristal de la ventanilla
	b._caja_en(Vector3(x, y + 4.4, z_pared + 1.75), Vector3(5.4, 1.2, 0.25), azul)              ## panel del rótulo
	b._rotulo(Vector3(x, y + 4.4, z_pared + 1.95), Idiomas.t("BANCO ANDINO"), Color(1, 1, 1), 30)
	b.puntos_clic.append({"k": "banco_%d" % (absi(hash(Vector2(x, z_pared))) % 100000), "n": Idiomas.t("Ventanilla del banco"),
		"pos": Vector3(x, 0.0, z_pared + 4.6), "estado": "ciudad", "radio": 9.0, "alcance": 2.5})
