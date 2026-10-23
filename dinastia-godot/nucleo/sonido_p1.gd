extends Node
## (Parte 1 de 3 de `sonido.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `sonido.gd`, conserva la clase.)

## (Sin `class_name`: este script ES el autoload `Sonido`, y Godot rechaza una
## clase global que se llame igual que un singleton — "Class Sonido hides an
## autoload singleton". El autoload ya da el nombre.)
## El sonido del juego, sintetizado. Ni un solo fichero de audio.
##
## En el HTML esto es Web Audio: osciladores, ruido filtrado y envolventes, todo
## generado en el momento. Aquí se hace lo mismo pero al revés en el tiempo: en
## vez de sintetizar en cada reproducción, se generan las ondas UNA VEZ al
## arrancar y se guardan como `AudioStreamWAV`. Sintetizar cuesta; reproducir un
## buffer ya hecho, no. Y en un partido a velocidad rápida suenan cincuenta
## silbatos por minuto.
##
## LA VARIACIÓN NO ES UN ADORNO. Cada efecto se desafina y se destempla un poco:
## un silbato idéntico cincuenta veces seguidas lo detecta el oído enseguida y
## suena a máquina. Con un 6% de deriva suena a estadio. Es el mismo truco del
## HTML y por eso de cada efecto se generan varias variantes que se van rotando.
##
## Cero dependencias de fichero significa además que esto sigue funcionando si
## un día el proyecto se empaqueta para Android o para web.

const FRECUENCIA := 22050
const VARIANTES := 4

## Los tres buses del HTML, para que se puedan bajar por separado: los efectos
## del partido, el ambiente del estadio y los clics de la interfaz.
enum Bus { EFECTOS, AMBIENTE, INTERFAZ }

var volumen := {Bus.EFECTOS: 0.8, Bus.AMBIENTE: 0.5, Bus.INTERFAZ: 0.35}
var encendido := true

var _bancos: Dictionary = {}       ## nombre -> Array[AudioStreamWAV]
var _voces: Array[AudioStreamPlayer] = []
var _siguiente := 0

## Ocho reproductores en rueda. Con uno solo, un gol durante el murmullo cortaría
## el murmullo; con ocho, se solapan como en un estadio de verdad.
const VOCES := 8

var _mutex := Mutex.new()
var _hilo: Thread = null
var _parar := false

## Los 207 sonidos del catálogo.
const NOMBRES := ["silbato", "gol", "gol_rival", "roja", "amarilla",
	"murmullo", "ovacion", "poste", "clic", "moneda", "pitido_final",
	"ocasion", "atajada", "falta", "corner", "trofeo",
	"lesion", "cambio", "fichaje", "ascenso", "descenso", "logro",
	## La segunda tanda: la interfaz, el campo, la grada y la gestion.
	"clic_suave", "abrir", "cerrar", "error", "aviso", "correo", "guardado",
	## Los del menú de controles (14-10-2026): moverse, aceptar, volver,
	## cambiar un ajuste y pasar de sección.
	"menu_mover", "menu_aceptar", "menu_atras", "menu_cambio", "menu_seccion",
	"telefono", "saque_inicial", "penal", "penal_fallado", "travesano",
	"remate_fuera", "var", "segunda_amarilla", "fuera_de_juego",
	"tambor", "trompeta", "abucheo", "aplauso", "cantico", "bengala",
	"lluvia_ambiente", "vestuario", "flashes", "contrato", "despido",
	"dinero_entra", "dinero_sale", "sorteo", "cronometro", "himno",
	"fin_temporada",
	## Y los que pedia el LEEME: uno propio por evento.
	"clausula", "lesion_grave", "oferta", "contrato_vence", "obra",
	"venta", "ronda_superada",
	## Los ocho sonidos de gol que se eligen en el diseño del estadio
	## (`EST_SONIDOS`): mismas claves que guarda `EstadioPropio`.
	"gol_bombo", "gol_sirena", "gol_campana", "gol_organo",
	"gol_explosion", "gol_sintetico", "gol_tambores", "gol_silencio",
	## TERCERA TANDA (21-9-2026), a pedido explícito del usuario: "que sean
	## cerca de 200 sonidos" -de 65 a unos 200 situaciones distintas, no
	## solo más variantes de las mismas-. Organizado en los mismos bloques
	## que ya usaba el catálogo, cada uno nuevo con su propia receta, no
	## una reetiquetada de otra.
	## --- Más momentos de partido ---
	"saque_banda", "saque_puerta", "fuera_de_banda", "rebote", "palo_doble",
	"atajada_punos", "atajada_pies", "gol_cabeza", "gol_chilena", "gol_falta",
	"gol_penal", "autogol", "mano_penal", "simulacion", "var_anulado",
	"medio_tiempo", "reanudacion", "calentamiento", "salida_tunel",
	"presentacion_alineaciones", "despeje", "entrada_dura",
	"recuperacion_balon", "pase_largo", "control_balon",
	## --- Más grada ---
	"ola_mexicana", "silbido_agudo", "coro_rival", "pitos_arbitro",
	"bocina_vuvuzela", "tambor_visitante", "suspiro_grada", "alarido_atajada",
	"tension_publico", "silbidos_impaciencia", "ultimo_minuto",
	"descuento_anunciado", "grada_de_pie", "bufanda_alzada",
	"pancarta_desplegada", "humo_bengala", "cornetin", "campanas_iglesia",
	"animador_grada", "eco_estadio", "lluvia_fuerte", "viento_fuerte",
	"trueno", "multitud_entrando", "multitud_saliendo",
	## --- Más gestión / carrera ---
	"entrenamiento", "sesion_tactica", "rueda_prensa_pregunta",
	"rueda_prensa_aplauso", "scouting_informe", "oferta_rechazada",
	"oferta_aceptada", "renovacion", "prestamo", "veto_fichaje",
	"mercado_cierra", "premio_individual", "capitania", "retiro_jugador",
	"debut_juvenil", "ascenso_juvenil", "sancion_directiva",
	"reunion_directiva", "patrocinio_nuevo", "inauguracion_obra",
	"entrada_taquilla", "aumento_socios", "huelga_hinchas",
	"elecciones_club", "votacion_ganada", "votacion_perdida", "premio_liga",
	"descenso_administrativo", "multa", "cesion_jugador",
	"renovacion_rechazada", "agente_llamada", "rumor_fichaje",
	"medico_parte", "alta_medica", "baja_medica", "entrenamiento_lesion",
	"objetivo_cumplido", "objetivo_fallado", "mejora_instalaciones",
	## --- Más interfaz ---
	"seleccionar", "deseleccionar", "arrastrar", "soltar", "desbloqueo",
	"nivel_subido", "notificacion", "confirmar", "cancelar", "deslizar",
	## --- Más festejos y momentos de gol ---
	"celebracion_grupal", "celebracion_individual", "festejo_banco",
	"festejo_hinchada_extra", "remontada", "gol_agonico", "hat_trick",
	"doblete", "gol_rapido", "gol_confirmado_var",
	## --- Clima y ambiente ---
	"niebla_ambiente", "calor_extremo", "frio_extremo", "noche_estadio",
	"dia_soleado",
	## --- Más árbitro y disciplina ---
	"tarjeta_banco", "protesta_jugador", "protesta_masiva",
	"amonestacion_verbal", "tiempo_anadido", "ventaja", "libre_indirecto",
	"mano_fuera_area", "fuera_terreno_juego", "calambre",
	## --- Más estilo de juego ---
	"pase_corto", "centro", "regate", "tiro_potente", "tiro_flojo",
	"paso_atras", "presion_alta", "contragolpe", "posesion_larga",
	"cambio_ritmo",
	## --- Recorridos a pie (etapa 1, 8-10-2026): se pedían y no existían ---
	"puerta", "paso",
	## --- Coches (21-10-2026): el choque y el claxon de la ciudad ---
	"choque_coche", "claxon"]

## Un tono con envolvente exponencial de caída, que es la que suena natural: el
## sonido arranca de golpe y se apaga deprisa al principio y despacio al final.
func _tono(hz: float, dur: float, vol: float, forma: String) -> PackedFloat32Array:
	var n := int(dur * float(FRECUENCIA))
	var m := PackedFloat32Array()
	m.resize(n)
	var paso := hz * TAU / float(FRECUENCIA)
	for i in n:
		var t := float(i) / float(n)
		var env: float = exp(-5.0 * t)
		var f := float(i) * paso
		var s := 0.0
		match forma:
			"seno": s = sin(f)
			"cuadrada": s = 1.0 if sin(f) >= 0.0 else -1.0
			"sierra": s = fmod(f / TAU, 1.0) * 2.0 - 1.0
			_: s = sin(f)
		m[i] = s * env * vol
	return m

func _mezclar(destino: PackedFloat32Array, fuente: PackedFloat32Array, retraso: float = 0.0) -> void:
	var off := int(retraso * float(FRECUENCIA))
	for i in fuente.size():
		var k := i + off
		if k < destino.size():
			destino[k] = clampf(destino[k] + fuente[i], -1.0, 1.0)

## Ruido con un barrido de filtro entre dos frecuencias. El filtro es un paso
## bajo de un polo: no es un biquad como el del navegador, pero para ruido de
## grada la diferencia no se oye y cuesta una décima parte.
func _ruido(dur: float, f0: float, f1: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * float(FRECUENCIA))
	var m := PackedFloat32Array()
	m.resize(n)
	var estado := 0.0
	var rng := RandomNumberGenerator.new()
	## Semilla fija: el mismo efecto suena igual en cada partida. La variación
	## viene de las cuatro variantes, no de que cada reproducción sea distinta.
	rng.seed = int(f0) * 7919 + int(f1)
	for i in n:
		var t := float(i) / float(n)
		var corte: float = lerpf(f0, f1, t)
		var a: float = clampf(corte / float(FRECUENCIA) * 6.28, 0.02, 0.95)
		estado += a * (rng.randf_range(-1.0, 1.0) - estado)
		## Ataque rápido y caída larga: el ruido de una grada sube de golpe.
		var env: float = minf(t / 0.12, 1.0) * exp(-3.2 * t)
		m[i] = estado * env * vol
	return m

## El "sol-sol-la-sol-do-si" de la tribuna (`cantico()` en juego.js), con
## palmas entre nota y nota. Solo lo usa "trofeo" -es el unico sitio del HTML
## donde se llama-, pero como aporte propio de este porte tambien podria
## engancharse a cualquier festejo futuro sin sintetizar nada nuevo.
func _cantico(intensidad: float) -> PackedFloat32Array:
	var base := [196.0, 196.0, 220.0, 196.0, 262.0, 247.0]
	var vol := 0.030 * intensidad
	var m: PackedFloat32Array = PackedFloat32Array()
	m.resize(int(2.1 * float(FRECUENCIA)))
	for i in base.size():
		var t0 := float(i) * 0.34
		for arm in [1, 2, 3]:
			var forma := "sierra" if arm == 1 else "seno"
			_mezclar(m, _tono(base[i] * float(arm), 0.30, vol / (float(arm) * 1.6), forma), t0)
		_mezclar(m, _ruido(0.09, 2200.0, 2600.0, 0.05 * intensidad), t0 + 0.02)
	return m

## El bombo del HTML (`bombo(t0,vol)` dentro de `sfxGol()`): un seno grave de
## 58 Hz y un golpe de ruido corto. El HTML le hace un glissando hacia 32 Hz;
## `_tono()` no barre frecuencia, y a esa altura el oído no lo distingue.
func _bombo(m: PackedFloat32Array, t0: float, vol: float) -> void:
	_mezclar(m, _tono(58.0, 0.28, vol, "seno"), t0)
	_mezclar(m, _ruido(0.08, 300.0, 90.0, 0.05), t0)

## Los pasa a 16 bits, que es lo que quiere `AudioStreamWAV`.
func _a_wav(m: PackedFloat32Array) -> AudioStreamWAV:
	var datos := PackedByteArray()
	datos.resize(m.size() * 2)
	for i in m.size():
		var v := int(clampf(m[i], -1.0, 1.0) * 32767.0)
		datos.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = FRECUENCIA
	w.stereo = false
	w.data = datos
	return w
