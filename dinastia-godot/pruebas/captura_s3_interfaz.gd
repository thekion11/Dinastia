extends Node
## s3 (26-10-2026): defectos visuales que anotó la sesión 2, vistos en la interfaz real.
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_s3_interfaz.tscn
## s3_caras_1: nada más abrir «Mi plantel», mientras se generan los retratos 3D (marcador).
## s3_caras_2: con la cola de `Retrato3D` vacía (imprime cuánto tardó).
## s3_identidad: la identidad visual del club (miniaturas de forma, escudo) con su club.
## s3_finanzas: la pantalla de finanzas (flujo de caja y cifras junto a la barra).
## FINANZAS=1 salta directamente a finanzas (con BAJAR=px baja en su lista).
var _n := 0
var _p: Node
var _t0 := 0
var _fase := 0
var _paleta_antes := ""

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)
	print("FOTO ", nombre)

func _chip(tab: String, secc: String, label: String) -> void:
	_p.call("_ir_a_chip", {"tab": tab, "secc": secc, "label": label})

func _process(_d: float) -> void:
	_n += 1
	if _n < 8:
		return
	match _fase:
		0:
			## CONTRASTE=1: con la paleta de contraste alto. ACCESO=1: la sección de
			## accesibilidad de Ajustes (contraste, teclas de la interfaz).
			if OS.get_environment("CONTRASTE") != "":
				_paleta_antes = _p._paleta
				_p._paleta = "contraste"
				_p._aplicar_aspecto()
				_p._refrescar()
			if OS.get_environment("ACCESO") != "":
				_p._secc_ajustes = "acceso"
				_chip("Ajustes", "acceso", "Accesibilidad")
				_fase = 2
				_n = 8
				return
			if OS.get_environment("FINANZAS") != "":
				_fase = 5
				_n = 0
				return
			_p.call("_ir_a_pestana", "Mi plantel")
			_t0 = Time.get_ticks_msec()
			_fase = 1
			_n = 8
		1:
			if _n == 12:
				print("cola de retratos al abrir: %d" % Retrato3D._cola.size())
				_foto("s3_caras_1")
			elif _n > 12 and (Retrato3D._cola.is_empty() or _n > 900):
				print("cola vacía tras %d fotogramas y %.1f s" % [_n - 12, (Time.get_ticks_msec() - _t0) / 1000.0])
				_foto("s3_caras_2")
				_chip("Gente", "identidad", "Identidad Visual")
				_fase = 2
				_n = 8
		2:
			if _n == 14 and OS.get_environment("ACCESO") != "":
				var sc2 := (_p.get("_lista_ajustes") as Node).get_parent()
				while sc2 != null and not (sc2 is ScrollContainer):
					sc2 = sc2.get_parent()
				for l in (_p.get("_lista_ajustes") as Node).find_children("*", "Label", true, false):
					if sc2 != null and String((l as Label).text) == Idiomas.t("Paleta para daltonismo"):
						(sc2 as ScrollContainer).scroll_vertical = int((l as Control).get_parent().position.y) - 20
			elif _n == 14:
				## Baja hasta la rejilla de formas del escudo.
				var sc := (_p.get("_lista_gente") as Node).get_parent()
				while sc != null and not (sc is ScrollContainer):
					sc = sc.get_parent()
				if sc != null:
					(sc as ScrollContainer).scroll_vertical = int(OS.get_environment("BAJAR")) if OS.get_environment("BAJAR") != "" else 760
			elif _n == 40:
				_foto("s3_acceso" if OS.get_environment("ACCESO") != "" else "s3_identidad")
				_fase = 5
				_n = 7
		5:
			if _n == 8:
				## Fuera el periódico que se abre solo tras los partidos jugados.
				for n in get_tree().root.find_children("*", "", true, false):
					if n is PortadaPeriodico:
						n.queue_free()
				_chip("Finanzas", "finanzas", "Finanzas")
			elif _n == 20:
				var sc := (_p.get("_lista_finanzas") as Node).get_parent()
				while sc != null and not (sc is ScrollContainer):
					sc = sc.get_parent()
				if sc != null and OS.get_environment("BAJAR") == "flujo":
					for l in (_p.get("_lista_finanzas") as Node).find_children("*", "Label", true, false):
						if String((l as Label).text).contains("FLUJO"):
							(sc as ScrollContainer).scroll_vertical = int((l as Control).position.y) - 40
				elif sc != null and OS.get_environment("BAJAR") != "":
					(sc as ScrollContainer).scroll_vertical = int(OS.get_environment("BAJAR"))
			elif _n == 36:
				_foto("s3_finanzas")
				## La paleta de contraste no se queda en las preferencias de la máquina.
				if _paleta_antes != "":
					_p._paleta = _paleta_antes
					_p._guardar_preferencias()
				print("FIN. 0 fallos")
				get_tree().quit()
