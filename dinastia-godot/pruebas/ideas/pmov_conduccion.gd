extends BaseIdea
## M-407 (27-10-2026): la CONDUCCIÓN en sí (`ExploradorCiudad._conducir`), sin ciudad. La forma del coche y
## sus choques ya los mide `pmov_coche_forma`; aquí, que acelera hasta su tope y no más, que frena antes de
## dar marcha atrás, que rueda suelto hasta pararse, que gira menos a
## mucha velocidad y nada parado, y que un golpe fuerte contra otro coche es multa (contra un muro, no).

const DT := 1.0 / 60.0

func _probar() -> void:
	_titulo("PMOV: CONDUCIR (ACELERAR, FRENAR, RODAR, GIRAR Y MULTAS)")
	_acelerar_y_tope()
	_frenar_y_marcha_atras()
	_rodar_suelto()
	_giro_segun_velocidad()
	_derrape()
	_multas()

func _explorador() -> ExploradorCiudad:
	var e := ExploradorCiudad.new()
	e.modo = "coche"
	e.cuerpo = Node3D.new()
	return e

func _soltar(e: ExploradorCiudad) -> void:
	e.cuerpo.free()
	e.free()

## `s` segundos con el mando en `mando` (x = volante, y = acelerador/freno).
func _durante(e: ExploradorCiudad, mando: Vector2, s: float) -> void:
	for i in int(s / DT):
		e._conducir(mando, DT)

func _acelerar_y_tope() -> void:
	_linea("· Acelerar")
	var e := _explorador()
	_durante(e, Vector2(0, 1), 1.0)
	var v1 := e.vel
	_comprobar(v1 > 4.0 and v1 < 10.0, "en un segundo a fondo pasa de 0 a %.1f m/s (%.0f km/h)" % [v1, v1 * 3.6])
	_durante(e, Vector2(0, 1), 1.0)
	var v2 := e.vel
	_comprobar(v2 - v1 < v1, "el segundo segundo gana menos que el primero (%.1f frente a %.1f): la potencia cae con la velocidad" % [v2 - v1, v1])
	_durante(e, Vector2(0, 1), 20.0)
	_comprobar(e.vel <= ExploradorCiudad.VEL_COCHE + 0.001 and e.vel > ExploradorCiudad.VEL_COCHE - 0.5, "a fondo mucho rato llega al tope y no lo pasa (%.2f de %.1f m/s)" % [e.vel, ExploradorCiudad.VEL_COCHE])
	_comprobar(e.rumbo == 0.0, "con el volante recto, el rumbo no se mueve")
	_soltar(e)

func _frenar_y_marcha_atras() -> void:
	_linea("· Frenar y marcha atrás")
	var e := _explorador()
	e.vel = 20.0
	var t := 0.0
	var a_ant := 0.0
	var salto := 0.0   ## el mayor cambio de deceleración de un fotograma a otro (el tirón)
	while e.vel > 0.5 and t < 6.0:
		var v0 := e.vel
		e._conducir(Vector2(0, -1), DT)
		var a := (v0 - e.vel) / DT
		salto = maxf(salto, absf(a - a_ant))
		a_ant = a
		t += DT
	var g := 20.0 / t / 9.81
	_comprobar(t > 2.0 and t < 3.0, "a 72 km/h, frenando a fondo, se para en %.2f s (antes 0,82 s)" % t)
	_comprobar(g > 0.6 and g < 1.05, "la frenada media es de %.2f g (antes ~2,4 g)" % g)
	_comprobar(salto < 1.0, "sin tirones: la deceleración cambia %.2f m/s² como mucho entre fotogramas" % salto)
	_comprobar(e.vel >= 0.0, "frenar no le hace saltar a marcha atrás de golpe (%.2f m/s)" % e.vel)
	_durante(e, Vector2(0, -1), 3.0)
	_comprobar(e.vel < -3.0 and e.vel >= -8.0, "ya parado, seguir frenando es marcha atrás, con tope de 8 m/s (%.2f)" % e.vel)
	_soltar(e)

func _rodar_suelto() -> void:
	_linea("· Rodar suelto")
	var e := _explorador()
	e.vel = 15.0
	_durante(e, Vector2.ZERO, 1.0)
	_comprobar(e.vel < 15.0 and e.vel > 8.0, "sin pedales rueda y pierde velocidad poco a poco (15 → %.1f m/s en 1 s)" % e.vel)
	_durante(e, Vector2.ZERO, 10.0)
	_comprobar(is_zero_approx(e.vel), "y al final se para del todo (%.3f)" % e.vel)
	_soltar(e)

## Girar el volante a tope medio segundo a una velocidad dada: cuánto gira el coche.
func _giro_a(v: float) -> float:
	var e := _explorador()
	e.vel = v
	e._volante = 1.0
	for i in int(0.5 / DT):
		e._conducir(Vector2(1, 0), DT)
		e.vel = v
	var r := absf(e.rumbo)
	_soltar(e)
	return r

func _giro_segun_velocidad() -> void:
	_linea("· Girar")
	var parado := _giro_a(0.0)
	var lento := _giro_a(8.0)
	var rapido := _giro_a(ExploradorCiudad.VEL_COCHE)
	_comprobar(is_zero_approx(parado), "parado, girar el volante no gira el coche (%.3f rad)" % parado)
	_comprobar(lento > 0.5, "a 29 km/h gira con ganas (%.2f rad en medio segundo)" % lento)
	_comprobar(rapido < lento * 0.7 and rapido > 0.1, "a 94 km/h gira menos (%.2f rad) que a 29 (%.2f): no se vuelca" % [rapido, lento])
	var e := _explorador()
	e.vel = -5.0
	e._volante = 1.0
	_durante(e, Vector2(1, 0), 0.3)
	var atras := e.rumbo
	_soltar(e)
	var e2 := _explorador()
	e2.vel = 5.0
	e2._volante = 1.0
	_durante(e2, Vector2(1, 0), 0.3)
	_comprobar(signf(atras) == -signf(e2.rumbo) and absf(atras) > 0.05, "marcha atrás, el mismo volante gira al otro lado (%.2f frente a %.2f)" % [atras, e2.rumbo])
	_soltar(e2)

func _multas() -> void:
	_linea("· Golpes y multas")
	var e := _explorador()
	e._golpe_coche(12.0, true)
	_comprobar(e.multas == 0, "chocar contra un muro a 43 km/h no es multa")
	e._t_golpe = -10.0
	e._golpe_coche(12.0, false)
	_comprobar(e.multas == 1, "chocar contra otro coche a 43 km/h es una multa por conducción temeraria")
	e._golpe_coche(12.0, false)
	_comprobar(e.multas == 1, "el mismo golpe (medio segundo) no se cobra dos veces")
	e._t_golpe = -10.0
	e._golpe_coche(5.0, false)
	_comprobar(e.multas == 1, "un roce a 18 km/h no es multa")
	_soltar(e)

## Mejora B (31-10): con el freno de mano a buena velocidad y el volante girado, el coche derrapa (la
## trayectoria se queda atrás del morro) y pierde velocidad; sin freno de mano, apenas cruza.
func _derrape() -> void:
	_linea("· Derrape")
	var e := _explorador()
	e.vel = 18.0
	e._volante = 1.0
	e.freno_mano_prueba = true
	var max_d := 0.0
	for i in int(0.6 / DT):
		e._conducir(Vector2(1, 0), DT)
		max_d = maxf(max_d, e.deriva)
	var v_derrape := e.vel
	e.freno_mano_prueba = false
	for i in int(1.0 / DT):
		e._conducir(Vector2(0, 0), DT)
	_comprobar(max_d > 0.3 and e.deriva < 0.05, "con freno de mano el coche cruza (%.2f rad) y al soltarlo recupera la trayectoria (%.2f)" % [max_d, e.deriva])
	var e2 := _explorador()
	e2.vel = 18.0
	e2._volante = 1.0
	var max_n := 0.0
	for i in int(0.6 / DT):
		e2._conducir(Vector2(1, 0), DT)
		max_n = maxf(max_n, e2.deriva)
	_comprobar(max_n < 0.15 and v_derrape < 18.0, "sin freno de mano apenas cruza (%.2f rad); el derrape cuesta velocidad (%.1f m/s)" % [max_n, v_derrape])
	_soltar(e)
	_soltar(e2)
