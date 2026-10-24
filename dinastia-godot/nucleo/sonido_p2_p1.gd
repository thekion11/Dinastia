extends "res://nucleo/sonido_p1.gd"
## [Capa 2/5 de `sonido.gd`] _sintetizar_g1

## [Capa 2/5 de `sonido.gd`] _sintetizar_g1

# --- síntesis ---------------------------------------------------------------

## Cada efecto es una receta de tonos y ruido sobre una envolvente. `sal` mueve
## la afinación y la duración un poco en cada variante.
## Parte 1 de 3 de `_sintetizar` (la norma de 450 líneas la partió por grupos de sonidos):
## devuelve el sonido si `nombre` es de este grupo y vacío si no.
func _sintetizar_g1(nombre: String, tono: float, largo: float) -> PackedFloat32Array:
	var m: PackedFloat32Array = PackedFloat32Array()
	match nombre:
		"silbato":
			## Dos armónicos muy juntos batiendo entre sí: es lo que hace que un
			## silbato suene a silbato y no a pitido de horno.
			m = _tono(2650.0 * tono, 0.34 * largo, 0.30, "seno")
			_mezclar(m, _tono(3980.0 * tono, 0.34 * largo, 0.16, "seno"))
			_mezclar(m, _ruido(0.34 * largo, 2400.0, 3600.0, 0.05))
		"pitido_final":
			m = _tono(2650.0 * tono, 1.10 * largo, 0.30, "seno")
			_mezclar(m, _tono(3980.0 * tono, 1.10 * largo, 0.16, "seno"))
		"gol":
			## Rugido: ruido grave que se abre, más una fanfarria de tres notas.
			m = _ruido(1.60 * largo, 300.0, 1500.0, 0.22)
			_mezclar(m, _tono(523.0 * tono, 0.9, 0.09, "sierra"), 0.05)
			_mezclar(m, _tono(659.0 * tono, 0.8, 0.09, "sierra"), 0.20)
			_mezclar(m, _tono(784.0 * tono, 1.0, 0.10, "sierra"), 0.36)
		"gol_rival":
			## El silencio incómodo: murmullo que se apaga y dos notas tristes.
			m = _ruido(1.20 * largo, 420.0, 140.0, 0.14)
			_mezclar(m, _tono(392.0 * tono, 0.16, 0.05, "sierra"), 0.05)
			_mezclar(m, _tono(311.0 * tono, 0.36, 0.05, "sierra"), 0.20)
		"roja":
			m = _tono(150.0 * tono, 0.35 * largo, 0.09, "sierra")
			_mezclar(m, _ruido(0.80 * largo, 900.0, 300.0, 0.08), 0.10)
		"amarilla":
			m = _tono(320.0 * tono, 0.18 * largo, 0.06, "cuadrada")
		"murmullo":
			## El ambiente de fondo. Ruido rosa muy filtrado y muy largo.
			m = _ruido(3.00, 200.0, 900.0, 0.05)
		"ovacion":
			m = _ruido(2.20 * largo, 500.0, 2200.0, 0.16)
		"poste":
			## Golpe seco y metálico: un tono alto que se apaga en nada.
			m = _tono(1180.0 * tono, 0.30 * largo, 0.20, "seno")
			_mezclar(m, _tono(2360.0 * tono, 0.16 * largo, 0.08, "seno"))
		"choque_coche":
			## Golpe de chapa: un ruido grave y seco, el crujido de la carrocería y
			## un tintineo metálico que se apaga.
			m = _ruido(0.32 * largo, 60.0, 700.0, 0.55)
			_mezclar(m, _ruido(0.18 * largo, 900.0, 3200.0, 0.18), 0.02)
			_mezclar(m, _tono(420.0 * tono, 0.40 * largo, 0.10, "seno"), 0.05)
		"claxon":
			## Dos notas a la vez (la bocina de dos tonos de un coche).
			m = _tono(415.0 * tono, 0.45 * largo, 0.16, "cuadrada")
			_mezclar(m, _tono(523.0 * tono, 0.45 * largo, 0.12, "cuadrada"))
		"clic":
			m = _tono(880.0 * tono, 0.05, 0.05, "cuadrada")
		"moneda":
			m = _tono(1320.0 * tono, 0.08, 0.06, "seno")
			_mezclar(m, _tono(1760.0 * tono, 0.10, 0.05, "seno"), 0.05)
		"ocasion":
			## El "uuuh" de la grada cuando la pelota pasa cerca. `nombre` no
			## lleva variacion de altura por jugada -eso lo pone el navegador
			## con R(0,140) en cada disparo, aqui ya lo cubren las variantes-.
			m = _ruido(0.72 * largo, 630.0 * tono, 1008.0 * tono, 0.10)
		"atajada":
			## Manotazo del arquero mas, casi siempre, el aplauso de la grada
			## detras -el HTML lo tiraba solo un 45% de las veces; aqui suena
			## siempre porque la variedad ya la dan las cuatro variantes-.
			m.resize(int(0.68 * largo * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.40 * largo, 800.0 * tono, 500.0, 0.07))
			_mezclar(m, _tono(300.0 * tono, 0.10, 0.03, "seno"))
			_mezclar(m, _ruido(0.50, 520.0, 900.0, 0.05), 0.18)
		"falta":
			m = _ruido(0.22 * largo, 2400.0 * tono, 2300.0, 0.085)
			_mezclar(m, _tono(220.0 * tono, 0.12, 0.025, "seno"), 0.06)
		"corner":
			m.resize(int(0.65 * largo * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.18 * largo, 2300.0 * tono, 2200.0, 0.07))
			_mezclar(m, _ruido(0.45, 520.0, 780.0, 0.05), 0.20)
		"trofeo":
			## El festejo mas largo del catalogo: fanfarria de cuatro notas +
			## rugido + dos "canticos" de tribuna a los 0.7s y a los 3s -los
			## `setTimeout(...,700)` y `...,3000)` del HTML-. Por eso el buffer
			## se reserva primero a los 5s finales: `_mezclar()` no alarga el
			## array de destino, solo escribe dentro de lo que ya exista, y si
			## se empezara por la fanfarria de 0.14s el cantico de los 3s se
			## recortaria en silencio sin que nada avisara.
			m.resize(int(5.0 * largo * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.14 * largo, 0.05, "cuadrada"))
			_mezclar(m, _tono(659.0 * tono, 0.14 * largo, 0.05, "cuadrada"), 0.14)
			_mezclar(m, _tono(784.0 * tono, 0.14 * largo, 0.05, "cuadrada"), 0.28)
			_mezclar(m, _tono(1047.0 * tono, 0.50 * largo, 0.05, "cuadrada"), 0.42)
			_mezclar(m, _ruido(2.40 * largo, 700.0, 240.0, 0.15))
			_mezclar(m, _cantico(1.3), 0.70)
			_mezclar(m, _cantico(1.3), 3.00)
		## De aqui para abajo: cinco efectos que el HTML nunca tuvo -no hay
		## `sfx('lesion')` ni `sfx('cambio')` ni nada parecido a fichaje o a
		## ascenso/descenso en `juego.js`-. Antes de esta sesion esos momentos
		## sonaban a silencio. Son composicion propia con el mismo instrumental
		## de siempre (osciladores + ruido filtrado), no un port de nada.
		"lesion":
			## Un golpe sordo y una caida de dos notas: preocupado, no tragico.
			m = _ruido(0.35 * largo, 260.0 * tono, 90.0, 0.10)
			_mezclar(m, _tono(200.0 * tono, 0.28 * largo, 0.07, "sierra"), 0.02)
			_mezclar(m, _tono(140.0 * tono, 0.30 * largo, 0.05, "sierra"), 0.16)
		"cambio":
			## Dos pitidos de pizarra, neutros: ni buena ni mala noticia.
			m = _tono(700.0 * tono, 0.09, 0.05, "cuadrada")
			_mezclar(m, _tono(900.0 * tono, 0.09, 0.05, "cuadrada"), 0.12)
		"fichaje":
			## Un arpegio corto que sube mas un brillo de ruido agudo: "trato
			## cerrado". Mas pequeno que "trofeo" -esto pasa cada semana, no
			## una vez al año-.
			m.resize(int(0.60 * largo * float(FRECUENCIA)))
			_mezclar(m, _tono(440.0 * tono, 0.12 * largo, 0.05, "seno"))
			_mezclar(m, _tono(554.0 * tono, 0.12 * largo, 0.05, "seno"), 0.10)
			_mezclar(m, _tono(659.0 * tono, 0.22 * largo, 0.06, "seno"), 0.20)
			_mezclar(m, _ruido(0.40 * largo, 1800.0, 2600.0, 0.04), 0.02)
		"logro":
			## El "tin-TON" de un logro desbloqueado, al estilo de las consolas:
			## dos notas limpias que SUBEN una quinta, con un brillo corto
			## encima. Tiene que reconocerse en medio milisegundo y no pisar lo
			## que este sonando: por eso es agudo, seco y corto -0,45 s contra
			## los 5 de "trofeo"-. Un logro no es un titulo; es un guino.
			m.resize(int(0.45 * largo * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.10 * largo, 0.03, "seno"))
			_mezclar(m, _tono(1318.0 * tono, 0.30 * largo, 0.04, "seno"), 0.09)
			_mezclar(m, _ruido(0.16 * largo, 3000.0, 5000.0, 0.03), 0.08)
		"ascenso":
			## Una subida de tres escalones mas una nota larga y un oleaje de
			## grada: mas grande que "fichaje", mas corto que "trofeo" -no hay
			## cantico, esto no es un titulo-.
			m.resize(int(1.6 * largo * float(FRECUENCIA)))
			_mezclar(m, _tono(392.0 * tono, 0.18 * largo, 0.06, "sierra"))
			_mezclar(m, _tono(494.0 * tono, 0.18 * largo, 0.06, "sierra"), 0.16)
			_mezclar(m, _tono(587.0 * tono, 0.18 * largo, 0.06, "sierra"), 0.32)
			_mezclar(m, _tono(784.0 * tono, 0.55 * largo, 0.08, "sierra"), 0.48)
			_mezclar(m, _ruido(1.10 * largo, 400.0, 1600.0, 0.12), 0.10)
		"descenso":
			## El espejo del ascenso: ruido que se apaga y tres escalones
			## bajando, largo porque es un golpe que se asienta, no un
			## sobresalto como "gol_rival".
			m.resize(int(1.6 * largo * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.30 * largo, 500.0, 160.0, 0.12))
			_mezclar(m, _tono(311.0 * tono, 0.30 * largo, 0.05, "sierra"), 0.05)
			_mezclar(m, _tono(262.0 * tono, 0.30 * largo, 0.05, "sierra"), 0.30)
			_mezclar(m, _tono(196.0 * tono, 0.50 * largo, 0.06, "sierra"), 0.60)
		## ---------------------------------------------------------------
		##  LA SEGUNDA TANDA
		## ---------------------------------------------------------------
		##
		## Veintiséis efectos más, todos con el mismo instrumental de siempre
		## —osciladores y ruido filtrado—. La razón de que existan es que medio
		## juego seguía siendo mudo: pasabas una semana, firmabas un contrato,
		## te llegaba un correo, guardabas la partida y no sonaba nada.
		##
		## LA REGLA DE LA INTERFAZ. Todo lo que va al bus INTERFAZ dura menos de
		## 0,2 s y suena bajo. Un clic que se oye es un clic que molesta a la
		## tercera vez, y en este juego se hacen miles.
		"menu_mover":
			## Un tic claro y corto, como el cursor de un menú de consola.
			m = _tono(1500.0 * tono, 0.035, 0.105, "seno")
			_mezclar(m, _tono(2250.0 * tono, 0.02, 0.038, "seno"))
		"menu_aceptar":
			## Dos notas que suben, brillantes.
			m.resize(int(0.16 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.06, 0.120, "seno"))
			_mezclar(m, _tono(1320.0 * tono, 0.09, 0.112, "seno"), 0.05)
		"menu_atras":
			## Las mismas, bajando y más apagadas.
			m.resize(int(0.16 * float(FRECUENCIA)))
			_mezclar(m, _tono(1100.0 * tono, 0.06, 0.098, "seno"))
			_mezclar(m, _tono(740.0 * tono, 0.09, 0.090, "seno"), 0.05)
		"menu_cambio":
			## Un ajuste que cambia: tres notas rápidas y un brillo.
			m.resize(int(0.26 * float(FRECUENCIA)))
			_mezclar(m, _tono(988.0 * tono, 0.05, 0.098, "seno"))
			_mezclar(m, _tono(1319.0 * tono, 0.05, 0.098, "seno"), 0.05)
			_mezclar(m, _tono(1976.0 * tono, 0.12, 0.075, "seno"), 0.1)
		"menu_seccion":
			## Pasar de sección: un soplido corto que sube y una nota.
			m.resize(int(0.2 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.12, 600.0, 3200.0, 0.05))
			_mezclar(m, _tono(1175.0 * tono, 0.08, 0.090, "seno"), 0.07)
		"clic_suave":
			## El clic de las pestañas: más apagado que "clic", porque cambiar de
			## pantalla se hace veinte veces por minuto.
			m = _tono(1180.0 * tono, 0.035, 0.028, "seno")
		"puerta":
			## Puerta corredera de cristal: el soplido de las hojas (ruido que
			## baja de agudo a grave) y un golpe sordo al llegar al tope.
			m.resize(int(0.75 * largo * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.6 * largo, 2600.0 * tono, 500.0, 0.10))
			_mezclar(m, _tono(95.0 * tono, 0.12, 0.10, "seno"), 0.58 * largo)
			_mezclar(m, _ruido(0.08, 900.0, 300.0, 0.06), 0.58 * largo)
		"paso":
			## Un paso de suela sobre baldosa: golpe grave muy corto y un roce.
			m = _tono(120.0 * tono, 0.07, 0.07, "seno")
			_mezclar(m, _ruido(0.06, 1800.0 * tono, 600.0, 0.05))
		"abrir":
			## Un panel que se abre: dos notas que SUBEN, muy cortas.
			m.resize(int(0.14 * float(FRECUENCIA)))
			_mezclar(m, _tono(660.0 * tono, 0.05, 0.030, "seno"))
			_mezclar(m, _tono(990.0 * tono, 0.06, 0.026, "seno"), 0.045)
		"cerrar":
			## Y el espejo: las mismas dos notas al revés.
			m.resize(int(0.14 * float(FRECUENCIA)))
			_mezclar(m, _tono(990.0 * tono, 0.05, 0.028, "seno"))
			_mezclar(m, _tono(660.0 * tono, 0.06, 0.024, "seno"), 0.045)
		"error":
			## El "no se puede": dos notas juntas y disonantes. No es un castigo,
			## es un aviso —por eso es corto y no grave—.
			m.resize(int(0.22 * float(FRECUENCIA)))
			_mezclar(m, _tono(220.0 * tono, 0.16, 0.055, "cuadrada"))
			_mezclar(m, _tono(233.0 * tono, 0.16, 0.045, "cuadrada"))
		"aviso":
			## El de una noticia que hay que mirar. Sube, y se queda arriba.
			m.resize(int(0.34 * float(FRECUENCIA)))
			_mezclar(m, _tono(784.0 * tono, 0.10, 0.045, "seno"))
			_mezclar(m, _tono(1047.0 * tono, 0.22, 0.040, "seno"), 0.09)
		"correo":
			## Un sobre que llega: golpe de papel y campanita.
			m.resize(int(0.36 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.09, 1800.0, 900.0, 0.045))
			_mezclar(m, _tono(1568.0 * tono, 0.24, 0.032, "seno"), 0.07)
		"guardado":
			## Tres notas que bajan, tranquilas: la partida está a salvo.
			m.resize(int(0.44 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.032, "seno"))
			_mezclar(m, _tono(784.0 * tono, 0.10, 0.030, "seno"), 0.09)
			_mezclar(m, _tono(587.0 * tono, 0.22, 0.032, "seno"), 0.18)
		"telefono":
			## El representante que llama. Dos ciclos del timbre de un fijo, que
			## es lo que se reconoce al instante como "te están llamando".
			m.resize(int(1.10 * float(FRECUENCIA)))
			for ciclo in 2:
				var t0f := float(ciclo) * 0.55
				for rep in 6:
					_mezclar(m, _tono(1000.0 * tono, 0.028, 0.030, "seno"), t0f + float(rep) * 0.036)
					_mezclar(m, _tono(1250.0 * tono, 0.028, 0.024, "seno"), t0f + float(rep) * 0.036)

		## ---------------------------------------------------------------
		##  LO QUE PASA EN EL CAMPO
		## ---------------------------------------------------------------
		"saque_inicial":
			## El pitido de arranque: uno solo, más largo que el de falta, con el
			## murmullo de la grada subiendo por detrás.
			m.resize(int(1.40 * float(FRECUENCIA)))
			_mezclar(m, _tono(2650.0 * tono, 0.50, 0.26, "seno"))
			_mezclar(m, _tono(3980.0 * tono, 0.50, 0.13, "seno"))
			_mezclar(m, _ruido(1.20, 300.0, 1400.0, 0.14), 0.18)
		"penal":
			## LA TENSIÓN. No es un golpe: es un silencio que se llena. Un
			## redoble grave que crece y no resuelve —lo que resuelve es lo que
			## suene después, "gol" o "atajada"—.
			m.resize(int(1.80 * float(FRECUENCIA)))
			for i in 26:
				var t0p := float(i) * 0.065
				_mezclar(m, _ruido(0.05, 110.0, 70.0, 0.03 + float(i) * 0.0035), t0p)
			_mezclar(m, _tono(98.0 * tono, 1.60, 0.05, "sierra"))
		"penal_fallado":
			## El "ooooh" que se corta en seco y el golpe del poste que no fue.
			m.resize(int(1.20 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.55, 700.0, 1100.0, 0.13))
			_mezclar(m, _ruido(0.60, 420.0, 120.0, 0.09), 0.45)
			_mezclar(m, _tono(174.0 * tono, 0.40, 0.05, "sierra"), 0.40)
		"travesano":
			## Como el poste pero más agudo y con más cola: el larguero canta.
			m = _tono(1560.0 * tono, 0.45 * largo, 0.20, "seno")
			_mezclar(m, _tono(3120.0 * tono, 0.24 * largo, 0.07, "seno"))
			_mezclar(m, _ruido(0.50, 600.0, 900.0, 0.06), 0.06)
		"remate_fuera":
			## El silbido del balón y el suspiro corto de la grada.
			m.resize(int(0.80 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.20, 3000.0, 800.0, 0.06))
			_mezclar(m, _ruido(0.55, 560.0, 300.0, 0.07), 0.16)
		"var":
			## El VAR: tres pitidos electrónicos iguales, fríos, sin grada. Es a
			## propósito la cosa menos futbolística del catálogo.
			m.resize(int(0.90 * float(FRECUENCIA)))
			for i in 3:
				_mezclar(m, _tono(1400.0 * tono, 0.10, 0.05, "cuadrada"), float(i) * 0.22)
		"segunda_amarilla":
			## Amarilla + roja pegadas: se oye la primera y se entiende la
			## segunda antes de leer nada.
			m.resize(int(0.90 * float(FRECUENCIA)))
			_mezclar(m, _tono(320.0 * tono, 0.16, 0.055, "cuadrada"))
			_mezclar(m, _tono(150.0 * tono, 0.34, 0.085, "sierra"), 0.22)
			_mezclar(m, _ruido(0.60, 900.0, 300.0, 0.07), 0.26)
		"fuera_de_juego":
			## Un pitido corto y el murmullo de protesta: nadie aplaude un fuera
			## de juego.
			m.resize(int(0.90 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.16, 2400.0, 2300.0, 0.075))
			_mezclar(m, _ruido(0.65, 380.0, 220.0, 0.07), 0.14)

		## ---------------------------------------------------------------
		##  LA GRADA
		## ---------------------------------------------------------------
		"tambor":
			## El bombo de la barra: cuatro golpes graves con su tiempo. Es el
			## sonido que hace que un estadio suene lleno aunque no haya nadie.
			m.resize(int(2.20 * float(FRECUENCIA)))
			for i in 8:
				_mezclar(m, _ruido(0.16, 90.0, 55.0, 0.16 if i % 2 == 0 else 0.09), float(i) * 0.26)
				_mezclar(m, _tono(62.0 * tono, 0.20, 0.10, "seno"), float(i) * 0.26)
		"trompeta":
			## Las tres notas de trompeta de tribuna. Desafinada a propósito: en
			## una grada nadie afina.
			m.resize(int(1.30 * float(FRECUENCIA)))
			_mezclar(m, _tono(392.0 * tono * 1.01, 0.30, 0.055, "sierra"))
			_mezclar(m, _tono(523.0 * tono * 0.99, 0.30, 0.055, "sierra"), 0.28)
			_mezclar(m, _tono(659.0 * tono, 0.55, 0.060, "sierra"), 0.56)
		"abucheo":
			## El silbido de la grada contra los suyos. Ruido agudo y largo, sin
			## nada de tono: no hay melodía en una pitada.
			m = _ruido(2.20 * largo, 1900.0, 2600.0, 0.13)
			_mezclar(m, _ruido(2.00, 700.0, 500.0, 0.06), 0.10)
		"aplauso":
			## Aplauso corto y educado. Es el de "buen intento", no el de gol.
			m = _ruido(0.90 * largo, 1400.0, 2000.0, 0.09)
		"cantico":
			## El cántico de tribuna, ya solo: existía dentro de "trofeo" y no se
			## podía tirar por su cuenta.
			m = _cantico(1.0)
		"bengala":
			## El siseo de una bengala: ruido agudo constante, sin ataque y sin
			## final —se enciende y ya está—.
			m = _ruido(2.60 * largo, 4200.0, 3400.0, 0.055)
		"lluvia_ambiente":
			## Fondo de partido pasado por agua. Muy filtrado y muy plano: si
			## tuviera forma, se notaría que se repite.
			m = _ruido(3.20, 2600.0, 3000.0, 0.045)
		"vestuario":
			## El eco de un vestuario vacío: un golpe de puerta y el zumbido de
			## los fluorescentes.
			m.resize(int(1.80 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.22, 240.0, 90.0, 0.10))
			_mezclar(m, _tono(100.0, 1.60, 0.018, "seno"), 0.05)
			_mezclar(m, _tono(150.0, 1.60, 0.010, "seno"), 0.05)
		"flashes":
			## Las cámaras de la sala de prensa: seis disparos irregulares.
			m.resize(int(1.30 * float(FRECUENCIA)))
			for i in 7:
				_mezclar(m, _ruido(0.045, 5200.0, 2200.0, 0.05), float(i) * 0.17 + float(i % 3) * 0.03)

		## ---------------------------------------------------------------
		##  LA GESTIÓN
		## ---------------------------------------------------------------
		"contrato":
			## El bolígrafo y el sello: firmar tiene que sonar a papel, no a
			## fanfarria. La fanfarria ya la tiene "fichaje".
			m.resize(int(0.70 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.30, 3200.0, 1400.0, 0.035))
			_mezclar(m, _ruido(0.10, 300.0, 120.0, 0.11), 0.34)
			_mezclar(m, _tono(523.0 * tono, 0.22, 0.030, "seno"), 0.40)
		"despido":
			## Te echaron. Una nota grave, larga y sola. Nada de ruido de grada:
			## esto no pasa en el campo.
			m.resize(int(2.20 * float(FRECUENCIA)))
			_mezclar(m, _tono(87.0 * tono, 1.90, 0.09, "sierra"))
			_mezclar(m, _tono(131.0 * tono, 1.10, 0.045, "seno"), 0.30)
		"dinero_entra":
			## Caja registradora corta: dos monedas que suben.
			m.resize(int(0.32 * float(FRECUENCIA)))
			_mezclar(m, _tono(1320.0 * tono, 0.09, 0.045, "seno"))
			_mezclar(m, _tono(1980.0 * tono, 0.16, 0.038, "seno"), 0.07)
		"dinero_sale":
			## Y las mismas dos, bajando.
			m.resize(int(0.32 * float(FRECUENCIA)))
			_mezclar(m, _tono(1320.0 * tono, 0.09, 0.040, "seno"))
			_mezclar(m, _tono(880.0 * tono, 0.16, 0.034, "seno"), 0.07)
		"sorteo":
			## El bombo girando: bolas de plástico chocando. Ruido corto repetido
			## catorce veces a destiempo, que es lo que suena a bombo.
			m.resize(int(1.80 * float(FRECUENCIA)))
			for i in 16:
				var tb := float(i) * 0.11 + float((i * 7) % 5) * 0.014
				_mezclar(m, _ruido(0.05, 1500.0 + float((i * 13) % 900), 700.0, 0.055), tb)
		"cronometro":
			## Los últimos minutos: un tictac que se acelera. No avisa de nada
			## que no sepas; lo que hace es que se te note en el cuerpo.
			m.resize(int(2.40 * float(FRECUENCIA)))
			var t0c := 0.0
			var paso_c := 0.34
			while t0c < 2.2:
				_mezclar(m, _tono(1700.0 * tono, 0.03, 0.045, "cuadrada"), t0c)
				t0c += paso_c
				paso_c = maxf(0.10, paso_c * 0.88)
	return m
