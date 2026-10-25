extends "res://nucleo/sonido_p2_p4.gd"
## [Capa 6/7 de `sonido.gd`] recetas de la interfaz y `_sintetizar` (el despacho)

# --- La interfaz -------------------------------------------------------------------------

## La segunda tanda de efectos nació de que medio juego seguía mudo: pasabas una semana,
## firmabas un contrato, te llegaba un correo, guardabas la partida y no sonaba nada.
##
## LA REGLA DE LA INTERFAZ. Todo lo que va al bus INTERFAZ dura menos de 0,2 s y suena
## bajo. Un clic que se oye es un clic que molesta a la tercera vez, y en este juego se
## hacen miles. (Las excepciones son avisos de algo que pasó: correo, teléfono, logro.)

func _receta_clic(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(880.0 * alto, 0.05, 0.05, "cuadrada")

## El clic de las pestañas: más apagado que "clic", porque cambiar de
## pantalla se hace veinte veces por minuto.
func _receta_clic_suave(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(1180.0 * alto, 0.035, 0.028, "seno")

## Un tic claro y corto, como el cursor de un menú de consola.
func _receta_menu_mover(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(1500.0 * alto, 0.035, 0.105, "seno")
	_mezclar(m, _tono(2250.0 * alto, 0.02, 0.038, "seno"))
	return m

## Dos notas que suben, brillantes.
func _receta_menu_aceptar(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.16)
	_mezclar(m, _tono(880.0 * alto, 0.06, 0.120, "seno"))
	_mezclar(m, _tono(1320.0 * alto, 0.09, 0.112, "seno"), 0.05)
	return m

## Las mismas, bajando y más apagadas.
func _receta_menu_atras(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.16)
	_mezclar(m, _tono(1100.0 * alto, 0.06, 0.098, "seno"))
	_mezclar(m, _tono(740.0 * alto, 0.09, 0.090, "seno"), 0.05)
	return m

## Un ajuste que cambia: tres notas rápidas y un brillo.
func _receta_menu_cambio(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.26)
	_mezclar(m, _tono(988.0 * alto, 0.05, 0.098, "seno"))
	_mezclar(m, _tono(1319.0 * alto, 0.05, 0.098, "seno"), 0.05)
	_mezclar(m, _tono(1976.0 * alto, 0.12, 0.075, "seno"), 0.1)
	return m

## Pasar de sección: un soplido corto que sube y una nota.
func _receta_menu_seccion(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.2)
	_mezclar(m, _ruido(0.12, 600.0, 3200.0, 0.05))
	_mezclar(m, _tono(1175.0 * alto, 0.08, 0.090, "seno"), 0.07)
	return m

## Un panel que se abre: dos notas que SUBEN, muy cortas.
func _receta_abrir(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.14)
	_mezclar(m, _tono(660.0 * alto, 0.05, 0.030, "seno"))
	_mezclar(m, _tono(990.0 * alto, 0.06, 0.026, "seno"), 0.045)
	return m

## Y el espejo: las mismas dos notas al revés.
func _receta_cerrar(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.14)
	_mezclar(m, _tono(990.0 * alto, 0.05, 0.028, "seno"))
	_mezclar(m, _tono(660.0 * alto, 0.06, 0.024, "seno"), 0.045)
	return m

## El "no se puede": dos notas juntas y disonantes. No es un castigo,
## es un aviso —por eso es corto y no grave—.
func _receta_error(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.22)
	_mezclar(m, _tono(220.0 * alto, 0.16, 0.055, "cuadrada"))
	_mezclar(m, _tono(233.0 * alto, 0.16, 0.045, "cuadrada"))
	return m

## El de una noticia que hay que mirar. Sube, y se queda arriba.
func _receta_aviso(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.34)
	_mezclar(m, _tono(784.0 * alto, 0.10, 0.045, "seno"))
	_mezclar(m, _tono(1047.0 * alto, 0.22, 0.040, "seno"), 0.09)
	return m

## Un sobre que llega: golpe de papel y campanita.
func _receta_correo(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.36)
	_mezclar(m, _ruido(0.09, 1800.0, 900.0, 0.045))
	_mezclar(m, _tono(1568.0 * alto, 0.24, 0.032, "seno"), 0.07)
	return m

## Tres notas que bajan, tranquilas: la partida está a salvo.
func _receta_guardado(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.44)
	_mezclar(m, _tono(880.0 * alto, 0.10, 0.032, "seno"))
	_mezclar(m, _tono(784.0 * alto, 0.10, 0.030, "seno"), 0.09)
	_mezclar(m, _tono(587.0 * alto, 0.22, 0.032, "seno"), 0.18)
	return m

## El representante que llama. Dos ciclos del timbre de un fijo, que
## es lo que se reconoce al instante como "te están llamando".
func _receta_telefono(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.10)
	for ciclo in 2:
		var t0f := float(ciclo) * 0.55
		for rep in 6:
			_mezclar(m, _tono(1000.0 * alto, 0.028, 0.030, "seno"), t0f + float(rep) * 0.036)
			_mezclar(m, _tono(1250.0 * alto, 0.028, 0.024, "seno"), t0f + float(rep) * 0.036)
	return m

func _receta_moneda(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(1320.0 * alto, 0.08, 0.06, "seno")
	_mezclar(m, _tono(1760.0 * alto, 0.10, 0.05, "seno"), 0.05)
	return m

## El "tin-TON" de un logro desbloqueado, al estilo de las consolas:
## dos notas limpias que SUBEN una quinta, con un brillo corto
## encima. Tiene que reconocerse en medio milisegundo y no pisar lo
## que este sonando: por eso es agudo, seco y corto -0,45 s contra
## los 5 de "trofeo"-. Un logro no es un titulo; es un guino.
func _receta_logro(alto: float, largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.45 * largo)
	_mezclar(m, _tono(880.0 * alto, 0.10 * largo, 0.03, "seno"))
	_mezclar(m, _tono(1318.0 * alto, 0.30 * largo, 0.04, "seno"), 0.09)
	_mezclar(m, _ruido(0.16 * largo, 3000.0, 5000.0, 0.03), 0.08)
	return m

func _receta_seleccionar(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(1000.0 * alto, 0.04, 0.04, "seno")

func _receta_deseleccionar(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(700.0 * alto, 0.04, 0.03, "seno")

func _receta_arrastrar(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(500.0 * alto, 0.05, 0.025, "seno")

func _receta_soltar(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(650.0 * alto, 0.06, 0.03, "seno")

func _receta_desbloqueo(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.40)
	_mezclar(m, _tono(880.0 * alto, 0.10, 0.04, "seno"))
	_mezclar(m, _tono(1318.0 * alto, 0.20, 0.04, "seno"), 0.09)
	return m

func _receta_nivel_subido(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.50)
	_mezclar(m, _tono(659.0 * alto, 0.10, 0.04, "seno"))
	_mezclar(m, _tono(988.0 * alto, 0.30, 0.04, "seno"), 0.09)
	return m

func _receta_notificacion(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(1047.0 * alto, 0.08, 0.04, "seno")

func _receta_confirmar(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(880.0 * alto, 0.06, 0.04, "seno")

func _receta_cancelar(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(440.0 * alto, 0.08, 0.04, "cuadrada")

func _receta_deslizar(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(0.10, 2000.0, 1200.0, 0.025)

# --- El despacho -------------------------------------------------------------------

## Cada efecto es una receta de tonos y ruido sobre una envolvente, en su propia función
## `_receta_<nombre>(alto, largo)`: LA TABLA DE DESPACHO ES EL NOMBRE. Antes eran tres
## `match` de ~380 líneas (25-10-2026, fase 0: se partieron receta a receta sin cambiar
## una sola muestra; lo vigila `pruebas/ideas/f0s_huellas_sonido`). Un sonido nuevo es
## un nombre en `NOMBRES` y una función `_receta_` en la capa de su grupo.
##
## `sal` mueve la afinación (`alto`) y la duración (`largo`) un poco en cada variante.
func _sintetizar(nombre: String, sal: float) -> AudioStreamWAV:
	var alto := 0.94 + sal * 0.12      ## multiplicador de altura
	var largo := 0.90 + sal * 0.20     ## multiplicador de duración
	var receta := "_receta_" + nombre
	if not has_method(receta):
		return _a_wav(PackedFloat32Array())
	var m: PackedFloat32Array = call(receta, alto, largo)
	return _a_wav(m)
