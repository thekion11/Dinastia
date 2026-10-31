extends BaseIdea
## P2 «MEJORAR» (31-10-2026): quien gira corriendo se inclina hacia dentro de la curva (DT en la ciudad y futbolistas); andando, no.

const DT := 1.0 / 30.0

## Balanceo al que llega tras `n` fotogramas con giro y velocidad fijos.
func _tras(giro: float, vel: float, n := 60, desde := 0.0) -> float:
	var z := desde
	for i in n:
		z = MovimientoNatural.inclinacion(z, giro, vel, DT)
	return z

func _probar() -> void:
	_titulo("P2: INCLINACIÓN AL GIRAR CORRIENDO")
	var andando := _tras(2.6, 1.7)
	_comprobar(absf(andando) < 0.005, "andando (1,7 m/s) girando a tope no se inclina (%.1f°)" % rad_to_deg(andando))
	var corriendo := _tras(2.6, 5.0)
	_comprobar(absf(corriendo) > deg_to_rad(6.0) and absf(corriendo) <= MovimientoNatural.INCLINA_MAX + 0.001,
		"corriendo (5 m/s) girando a tope se inclina entre 6° y el tope (%.1f°)" % rad_to_deg(absf(corriendo)))
	_comprobar(absf(_tras(2.6, 6.4)) <= MovimientoNatural.INCLINA_MAX + 0.001, "el sprint del partido no pasa del tope (%.1f°)" % rad_to_deg(absf(_tras(2.6, 6.4))))
	var suave := _tras(1.0, 5.0)
	_comprobar(absf(suave) < absf(corriendo), "una curva abierta inclina menos (%.1f° contra %.1f°)" % [rad_to_deg(absf(suave)), rad_to_deg(absf(corriendo))])
	## Hacia DENTRO: girando a la izquierda (rotation.y sube; el cuerpo mira a +Z y su izquierda es +X), la cabeza va hacia +X.
	var n := Node3D.new()
	n.rotation = Vector3(0.0, 0.0, corriendo)
	var arriba := n.transform.basis * Vector3.UP
	_comprobar(arriba.x > 0.05, "girando a la izquierda la cabeza se va a la izquierda, dentro de la curva (x = %.2f)" % arriba.x)
	n.free()
	_comprobar(signf(_tras(-2.6, 5.0)) == -signf(corriendo), "y al girar a la derecha, a la derecha")
	## Sin giro vuelve a ponerse recto, sin saltos.
	var recto := _tras(0.0, 5.0, 30, corriendo)
	var salto := absf(MovimientoNatural.inclinacion(corriendo, 0.0, 5.0, DT) - corriendo)
	_comprobar(absf(recto) < deg_to_rad(0.5), "al dejar de girar se endereza en 1 s (%.2f°)" % rad_to_deg(recto))
	_comprobar(salto < deg_to_rad(2.0), "sin saltos de un fotograma a otro (%.2f°)" % rad_to_deg(salto))
