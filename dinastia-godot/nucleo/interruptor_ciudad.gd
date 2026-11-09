class_name InterruptorCiudad
extends RefCounted
## (9-11, orden 33 del dueño: «solo club») Interruptor de la CIUDAD 3D de mundo abierto.
## Apagada por defecto: el juego base es el club y sus instalaciones. NO se ha borrado nada: la ciudad sigue en el
## código (`CargaCiudad`) como recurso, y con `activa = true` el paseo y la conducción vuelven a abrirse.
## Las pruebas que necesitan la ciudad lo encienden a mano. Al INSTALAR el juego la ciudad ya no se exporta.
static var activa := false

## Aviso común cuando alguien intenta entrar al mundo abierto con la ciudad apagada.
static func avisar_apagada(padre: Node) -> void:
	Aviso.mostrar(padre, "vida", "🏙️", Idiomas.t("La ciudad 3D está apagada"),
		Idiomas.t("Por ahora el juego es solo el club y sus instalaciones."))
