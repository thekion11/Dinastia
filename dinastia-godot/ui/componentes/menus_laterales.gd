class_name MenusLaterales
extends RefCounted
## LOS MENÚS DEL PANEL LATERAL (datos de `MenuLateral`; separados el 3-11-2026 para que `menu_lateral.gd` no pase de 450 líneas).

## Cada menú: icono, nombre, estilo del fondo (`fondo_menu.gdshader`), sus tres
## colores y sus submenús -chips de siempre ({tab, secc, label}) o acciones-.
const MENUS := [
	## 3-11 (orden 22 U6): el día a día (plantel, plata y competiciones) solo se abría tocando zonas de la
	## pantalla central (los HUBS de `principal_p1.gd`); el dueño no lo encontraba. Ahora también aquí.
	{"id": "plantel", "icono": "👔", "nombre": "Plantel", "estilo": 8, "ficha": true,
		"lema": "Tus jugadores: el once, la pizarra y cómo llegan al partido.",
		"colores": ["#07130c", "#113a22", "#9be7b4"], "subs": [
		{"tab": "Mi plantel", "label": "Mi plantel", "icono": "👥", "desc": "Fichas, forma, moral y el once."},
		{"accion": "plantilla_pes", "label": "Plantilla detallada", "icono": "📊", "desc": "Lista por líneas, atributos en barras y comparar dos jugadores."},
		{"tab": "Táctica", "label": "Táctica", "icono": "📋", "desc": "Dibujo, pizarra, roles y balón parado."},
		{"tab": "Entrenar", "label": "Entrenamiento", "icono": "🏋️", "desc": "Sesiones, cargas y habilidades."},
		{"tab": "Enfermería", "label": "Enfermería", "icono": "🩺", "desc": "Lesionados, plazos y riesgo."},
		{"tab": "Cantera", "label": "Cantera", "icono": "🌱", "desc": "Academia, camada del año y los que suben."},
		{"tab": "Contratos", "label": "Contratos", "icono": "📝", "desc": "Renovaciones, cláusulas y salidas."}]},
	## 3-11 (rediseño del menú central, pedido del dueño): el ⚽ de la barra de arriba pasa a su propio menú.
	{"id": "partido", "icono": "⚽", "nombre": "Partido", "estilo": 8,
		"lema": "El próximo partido, el rival y el calendario.",
		"colores": ["#07130c", "#0f3320", "#b6f0c4"], "subs": [
		{"tab": "Partido", "label": "Próximo partido", "icono": "⚽", "desc": "El rival, cómo llega y la previa."},
		{"tab": "Calendario", "label": "Calendario", "icono": "📅", "desc": "Todos los partidos de la temporada."},
		{"tab": "Táctica", "label": "Táctica", "icono": "📋", "desc": "El once, el dibujo y las órdenes."}]},
	{"id": "dinero", "icono": "💰", "nombre": "Dinero", "estilo": 2,
		"lema": "La caja del club: lo que entra, lo que sale y lo que se mueve en el mercado.",
		"colores": ["#05110d", "#0b231c", "#5fe0b8"], "subs": [
		{"tab": "Finanzas", "label": "Finanzas", "icono": "💵", "desc": "Presupuesto, banco, fondo de inversión y tu puesto."},
		{"tab": "Mercado", "label": "Mercado de fichajes", "icono": "🔁", "desc": "Comprar, vender y ceder."},
		{"tab": "Libres", "label": "Jugadores libres", "icono": "🆓", "desc": "Sin club y sin traspaso."}]},
	{"id": "competiciones", "icono": "🏆", "nombre": "Competiciones", "estilo": 0,
		"lema": "Las tablas, las copas y el resto del mundo.",
		"colores": ["#140d07", "#2a1d10", "#e0a95a"], "subs": [
		{"tab": "Clubes", "label": "Ligas y clubes", "icono": "📊", "desc": "Tablas, rivales y el resto de ligas."},
		{"tab": "Copa", "label": "Copa", "icono": "🏆", "desc": "El cuadro de la copa nacional."},
		{"tab": "Continental", "label": "Continental", "icono": "🌎", "desc": "El torneo de clubes del continente."},
		{"tab": "Selección", "label": "Selección", "icono": "🎌", "desc": "Convocatorias y torneos de selecciones."},
		{"accion": "elegir_club", "label": "Ver otro club", "icono": "🌎", "desc": "El mapa de países con sus clubes: elige cuál mirar."},
		{"accion": "palmares_mundo", "label": "Palmarés del mundo", "icono": "🌍", "desc": "Los campeones de ligas, copas y supercopas de todos los países."}]},
	{"id": "historia", "icono": "📜", "nombre": "Historia", "estilo": 0,
		"lema": "Lo que el club fue y lo que tú estás escribiendo.",
		"colores": ["#140d07", "#2a1d10", "#e0a95a"], "subs": [
		{"tab": "Legado", "label": "Historia del club", "icono": "🏛️", "desc": "Fundación, épocas doradas, clásicos y tu legado."},
		{"accion": "documental", "label": "Documental de la temporada", "icono": "🎬", "desc": "Tu año contado como una película."},
		{"accion": "capitulos", "label": "Capítulos de cada temporada", "icono": "📚", "desc": "Los documentales de todos tus años, guardados."},
		{"tab": "Récords", "secc": "records", "label": "Récords", "icono": "📈", "desc": "Goleadores, rachas y marcas de todos los tiempos."},
		{"tab": "Récords", "secc": "memoria", "label": "Memoria", "icono": "🕯️", "desc": "El salón de la fama y los que ya no están."},
		{"tab": "Récords", "secc": "rivales", "label": "Rivales", "icono": "⚔️", "desc": "Clásicos, cara a cara y cuentas pendientes."},
		{"tab": "Récords", "secc": "vitrina", "label": "Vitrina", "icono": "🏆", "desc": "Cada trofeo, con su año y su historia."},
		{"tab": "Cantera", "label": "Linaje", "icono": "🌱", "desc": "Las generaciones que salieron de casa."},
		{"tab": "Logros", "label": "Logros", "icono": "🎖️", "desc": "Lo que conseguiste como gestor."},
		{"tab": "Desafíos", "label": "Desafíos", "icono": "🎯", "desc": "Retos de temporada con premio."},
		{"tab": "Premios", "label": "Premios", "icono": "🥇", "desc": "Balones de oro, mejores DT y equipos ideales."},
		{"accion": "album", "label": "Álbum y museo", "icono": "📒", "desc": "Cromos y títulos de todas tus carreras."}]},
	{"id": "gente", "icono": "👥", "nombre": "Gente", "estilo": 1,
		"lema": "Las personas que hacen el club, dentro y fuera del campo.",
		"colores": ["#1a0f0c", "#2e1a14", "#ff9f5a"], "subs": [
		{"tab": "Club", "secc": "staff", "label": "Personal del club", "icono": "🧑‍💼", "desc": "Cuerpo técnico, médicos, ojeadores y analistas."},
		{"tab": "Gente", "secc": "personas", "label": "La gente del club", "icono": "🤝", "desc": "Utileros, cocineros, la señora del kiosco..."},
		{"tab": "Gente", "secc": "identidad", "label": "Identidad visual", "icono": "🎨", "desc": "Colores, escudo, apodo y tipografía."},
		{"tab": "Gente", "secc": "kits", "label": "Equipación", "icono": "👕", "desc": "El diseñador de camisetas, a pantalla completa."},
		{"tab": "Gente", "secc": "interno", "label": "El club por dentro", "icono": "🏢", "desc": "Palco, prensa, vestuario, la app y la web del club."},
		{"tab": "Camarín", "label": "Camarín", "icono": "🚪", "desc": "Clima del vestuario, camarillas y capitanes."}]},
	{"id": "carrera", "icono": "🎓", "nombre": "Mi Carrera", "estilo": 2,
		"lema": "Tu camino como entrenador: rol, habilidades y reputación.",
		"colores": ["#0f0d06", "#211b0b", "#f2c84b"], "subs": [
		{"tab": "Club", "secc": "carrera", "label": "Mi carrera", "icono": "🧭", "desc": "Tu puesto, los clubes que te quieren, dimitir y el siguiente escalón."},
		{"tab": "Club", "secc": "directorio", "label": "Directorio y consejeros", "icono": "🎩", "desc": "La directiva, su confianza en ti y hasta dos consejeros que te ayudan."},
		{"tab": "Habilidades", "label": "Árbol de habilidades", "icono": "🌳", "desc": "Aprende técnicas y sube de nivel."},
		{"tab": "Correo", "label": "Correo", "icono": "✉️", "desc": "Mensajes del club, agentes y la federación."},
		{"tab": "Federación", "label": "Normas y federación", "icono": "⚖️", "desc": "Reglamento, licencias, votaciones y árbitros."}]},
	{"id": "operaciones", "icono": "📊", "nombre": "Operaciones", "estilo": 3,
		"lema": "La hinchada, los medios y los números del día a día.",
		"colores": ["#061218", "#0b2230", "#3fd0ff"], "subs": [
		{"tab": "Estadio", "label": "Hinchada y socios", "icono": "📣", "desc": "Ánimo, socios, peñas y días del hincha."},
		{"tab": "Redes", "secc": "redes", "label": "Feed de redes", "icono": "📱", "desc": "Lo que se dice del club en Tribuna."},
		{"tab": "Redes", "secc": "prensa", "label": "Sala de prensa", "icono": "🎙️", "desc": "Periodistas, medios propios y derechos de TV."},
		{"tab": "Redes", "secc": "debate", "label": "El ruido de fuera", "icono": "📺", "desc": "Mesas de debate y portadas."},
		{"tab": "Comparar", "label": "Comparar", "icono": "⚖️", "desc": "Jugadores cara a cara."}]},
	{"id": "vida", "icono": "🌅", "nombre": "Mi Vida", "estilo": 4,
		"lema": "Lo que pasa cuando se apagan los focos.",
		"colores": ["#1b0f1f", "#0d0a18", "#ff7e5f"], "subs": [
		{"tab": "Vida", "secc": "bienestar", "label": "Bienestar", "icono": "🧘", "desc": "Estrés, descanso y salud del entrenador."},
		{"tab": "Vida", "secc": "hogar", "label": "Casa y auto", "icono": "🏡", "desc": "Dónde vives y en qué te mueves."},
		{"tab": "Vida", "secc": "familia", "label": "Familia", "icono": "👨‍👩‍👧", "desc": "Los tuyos, sus planes y sus quejas."},
		{"accion": "casa", "label": "Ver tu casa", "icono": "🛋️", "desc": "Tu terraza en 3D, con café y paisaje."},
		{"accion": "movil", "label": "Abrir el móvil", "icono": "📲", "desc": "Tribuna, mensajes, banco y tus fotos."},
		{"accion": "minijuegos", "label": "Minijuegos", "icono": "🎮", "desc": "Penales, tiros libres y la trivia del club."}]},
	{"id": "editar", "icono": "✏️", "nombre": "Editar", "estilo": 5, "ficha": false,
		"lema": "El mundo a tu medida: ligas, clubes y jugadores.",
		"colores": ["#06162e", "#0b2447", "#8fd3ff"], "subs": [
		{"tab": "Editor", "label": "Editor del mundo", "icono": "🛠️", "desc": "Competiciones, clubes, jugadores y CSV."},
		{"accion": "mi_personaje", "label": "Mi personaje", "icono": "🧍", "desc": "Cara, pelo, ropa y tu forma de caminar."},
		{"tab": "Gente", "secc": "identidad", "label": "Identidad visual", "icono": "🎨", "desc": "Colores, escudo, apodo y tipografía."},
		{"tab": "Gente", "secc": "kits", "label": "Equipación", "icono": "👕", "desc": "Camiseta, pantalón, medias y botines del club."},
		{"tab": "Estadio", "label": "Diseño del estadio", "icono": "📐", "desc": "Estilos completos y colores por sección."},
		{"accion": "casa", "label": "Decorar mi casa", "icono": "🛋️", "desc": "Muebles y rincones de tu hogar en 3D."}]},
	## 3-11 (rediseño): el glosario y las normas dejan el central y tienen menú propio.
	{"id": "reglas", "icono": "📖", "nombre": "Reglas", "estilo": 6, "ficha": false,
		"lema": "Qué significa cada cosa y qué dice el reglamento.",
		"colores": ["#0c0e12", "#1a1f2a", "#c8d4e8"], "subs": [
		{"tab": "Glosario", "label": "Glosario", "icono": "📖", "desc": "Cada término del juego, explicado."},
		{"tab": "Federación", "label": "Normas y federación", "icono": "⚖️", "desc": "Reglamento, licencias, votaciones y árbitros."}]},
	{"id": "ajustes", "icono": "⚙️", "nombre": "Ajustes", "estilo": 6, "ficha": false,
		"lema": "Cómo se ve, cómo suena y cómo se juega.",
		"colores": ["#0c0e12", "#171b22", "#a8b4c8"], "subs": [
		{"tab": "Ajustes", "secc": "pantalla", "label": "Dispositivo", "icono": "🖥️", "desc": "Pantalla, calidad gráfica, mando y fotogramas."},
		{"tab": "Ajustes", "secc": "audio", "label": "Sonido", "icono": "🔊", "desc": "Música, efectos y el ruido del estadio."},
		{"tab": "Ajustes", "secc": "aspecto", "label": "Interfaz", "icono": "🖌️", "desc": "Paletas, fondos y estilo del menú."},
		{"tab": "Ajustes", "secc": "juego", "label": "Juego", "icono": "🎮", "desc": "Idioma, moneda, velocidad del partido, comodidades y vida del DT."},
		{"tab": "Ajustes", "secc": "acceso", "label": "Accesibilidad", "icono": "♿", "desc": "Texto, colores, contraste, avisos de sonido y teclas."},
		{"tab": "Ajustes", "secc": "partida", "label": "Partida y guardado", "icono": "💾", "desc": "Guardar, cargar, otro mundo, ranuras, autoguardado, informe de fallos y créditos."}]},
	{"id": "ciudad", "icono": "🏙️", "nombre": "Ciudad 3D", "estilo": 7, "ficha": false,
		"lema": "La ciudad que rodea tu estadio.",
		"colores": ["#070a16", "#141a33", "#ffd27a"], "subs": [
		{"tab": "Ciudad", "label": "Diseño de la ciudad", "icono": "🗺️", "desc": "Terrenos, negocios, conciertos y el municipio."},
		{"accion": "ver_estadio", "label": "Entrar al estadio", "icono": "🏟️", "desc": "El mismo estadio que se juega, para recorrerlo."}]},
	{"id": "estadio", "icono": "🏟️", "nombre": "Estadio 3D", "estilo": 8, "ficha": false,
		"lema": "Tu casa: cada tribuna, cada foco, cada butaca.",
		"colores": ["#060d09", "#1f6b38", "#e8f4ff"], "subs": [
		{"tab": "Estadio", "label": "Diseño del estadio", "icono": "📐", "desc": "Estilos completos y colores por sección."},
		{"tab": "Club", "secc": "infra", "label": "Infraestructura", "icono": "🏗️", "desc": "Obras, ciudad deportiva y academia."},
		{"accion": "ver_estadio", "label": "Verlo en 3D", "icono": "👁️", "desc": "Tu estadio tal y como se juega."}]},
]

## (9-11, «solo club») Entradas al mundo abierto, fuera del menú mientras `InterruptorCiudad.activa` sea falso.
## Se conservan aquí para volver a añadirlas al menú «Ciudad» el día que la ciudad regrese.
const SUBS_MUNDO_ABIERTO := [
	{"accion": "ciudad_pie", "label": "Pasear a pie", "icono": "🚶", "desc": "Calles, parques, edificios por dentro y vecinos con quien charlar."},
	{"accion": "ciudad_coche", "label": "Conducir", "icono": "🚗", "desc": "Tu coche, con cámara de capó e interior y freno de mano."}]

static func menu_por_id(id: String) -> Dictionary:
	for m: Dictionary in MENUS:
		if String(m["id"]) == id:
			return m
	return {}
