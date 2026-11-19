class_name PrologoDT
extends "res://visor/prologo_p1.gd"
## (Parte 2 de 2 de `prologo.gd`.)

## La primera vez que enciendes el PC el prólogo queda hecho y la partida se guarda.
func _al_encender_pc() -> void:
	if _guardado_al_encender:
		return
	_guardado_al_encender = true
	mundo.prologo_visto = true
	var pr := pc.principal()
	if pr != null and pr.get("_partida") != null:
		pr.get("_partida").guardar_en("partida")
	terminado.emit()

# ----------------------------------------------------------------- salir

func _saltar() -> void:
	if mundo != null:
		mundo.prologo_visto = true
	_a_principal()

func _a_principal() -> void:
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file(ESCENA_PRINCIPAL)

# ------------------------------------------------------- los planos (18-11)

## Al llegar a una sala del recorrido: su plano de establecimiento (no en las pruebas rápidas ni con SIN_PLANOS=1) y luego el saludo y el mentor.
func _al_llegar() -> void:
	var p: Dictionary = PrologoPasos.PASOS[paso_i]
	var clave := String(p["clave"])
	if not rapido and PrologoPlanos.tiene(clave) and OS.get_environment("SIN_PLANOS") == "":
		var fuera := clave == "puerta"   ## la fachada: plano desde la calle hacia la puerta del club
		var r := Rect2(Vector2(puerta.x, puerta.z), Vector2.ONE * 2.0) if fuera else _rect_zona(String(p["zona"]), int(p["planta"]))
		if clave == "campo":   ## la banda: la zona de la lista queda entera, pero hace falta una cámara aparte (`poses_banda`)
			r = _rect_zona(String(p["zona"]), int(p["planta"]))
		if r.get_area() > 1.0:
			if dialogo.visible:
				dialogo.cerrar()   ## el plano va limpio: ni el cuadro de diálogo de antes ni la flecha (`_plano` la esconde)
			var pl := PrologoPlanos.new()
			_plano = pl
			add_child(pl)
			var y0 := CityBuilder.ESTADIO_EN.y + RecorridoClub.y_de(int(p["planta"]))
			var semilla := hash(Nombres.visible(club.nombre) + clave)
			var fijas: Array[Transform3D] = []
			if clave == "campo":
				fijas = PrologoPlanos.poses_banda(r, y0, CityBuilder.ESTADIO_EN, semilla)
			elif fuera:
				fijas = PrologoPlanos.poses_fachada(puerta, semilla, PrologoMentor.obstaculos + PrologoPlanos.copas_cerca(vista._raiz3d, puerta))
			hud.visible = false   ## sin la tarjeta de controles ni la flecha durante el plano
			await pl.rodar(explorador, r, y0, semilla, "Entrada del club" if fuera else String(p["zona"]), Nombres.visible(club.nombre), Color(club.color1), fijas)
			pl.queue_free()
			_plano = null
			hud.visible = true
	if not is_inside_tree():
		return
	_meter_saludo()
	_hablar()

## El suelo de la sala `zona` (la zona más grande con ese nombre en la planta) en x-z del mundo.
func _rect_zona(zona: String, planta: int) -> Rect2:
	var mejor := Rect2()
	for z: Dictionary in est["zonas"]:
		if String(z["nombre"]) == zona and int(z.get("planta", 0)) == planta and (z["r"] as Rect2).get_area() > mejor.get_area():
			mejor = z["r"]
	return Rect2(mejor.position + Vector2(CityBuilder.ESTADIO_EN.x, CityBuilder.ESTADIO_EN.z), mejor.size)
