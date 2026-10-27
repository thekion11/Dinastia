# Autoloads (singletons globales)

Se cargan en este orden (`dinastia-godot/project.godot`, sección `[autoload]`) y viven toda la partida.
Los archivos no llevan `class_name`, porque Godot no admite una clase global con el nombre de un singleton.
Cada script cuenta en su cabecera el porqué de sus decisiones. Aquí está el mapa.
La columna «usado en» es el número de scripts que lo llaman, contado el 27-10-2026.

| Orden | Nombre | Archivo | Para qué | API principal | Usado en |
|---|---|---|---|---|---|
| 1 | `Registro` | `nucleo/registro.gd` | Registro de fallos del jugador. Engancha un `Logger` del motor y guarda todos los `push_error`/`push_warning` en `user://`. Va primero para oír también los fallos de los demás autoloads. | `nota`, `apuntar`, `depurar`, `informe`, `datos_sistema` | 9 |
| 2 | `Datos` | `nucleo/datos.gd` | Las 212 tablas de datos (clubes, ligas, nombres…) exportadas del HTML. Cambia entre la base ficticia y el `pack_real.json` (fuera de los builds públicos). | `cargar`, `usar_base_real`, `hay_pack_real`, señal `base_cambiada` | 124 |
| 3 | `Azar` | `nucleo/azar.gd` | El azar del juego, con semilla, para que el banco compare ejecuciones. Lo visual que no debe mover la partida usa un RNG propio o un hash. | `sembrar`, `ent`, `f`, `uno`, `suerte`, `campana`, `barajar` | 92 |
| 4 | `Eco` | `nucleo/economia.gd` | Economía portada del HTML con sus constantes equilibradas. El dinero interno va en puntos: 1 punto = `Eco.ECO` = 12 € de pantalla. | `dinero`, `dinero_euros`, `escalar`, `factor_club`, `factor_edad`, `elegir_moneda` | 102 |
| 5 | `Sonido` | `nucleo/sonido.gd` (7 capas) | Efectos sintetizados por receta. Si existe `audio/ui/<nombre>.ogg` (Kenney, CC0), se usa la grabación. Tiene buses de efectos y ambiente. | `toca(nombre, bus)`, `banco`, `catalogo`, `ficha` | 72 |
| 6 | `Musica` | `nucleo/musica.gd` | Seis piezas generadas, sin ficheros de audio, con ambientación por situación. | `poner`, `ambientar`, `parar`, `aplicar_volumen` | 10 |
| 7 | `Idiomas` | `nucleo/idiomas.gd` (2 capas) | Traducción a 9 idiomas: `datos/idiomas_extra.json`, `Idiomas.t` para todo texto de la interfaz y retraducción de árboles ya construidos. Los textos nuevos entran con `herramientas/sumar_traducciones.py`. | `t`, `traducir_arbol`, `retraducir_arbol`, `mayusculas`, `cobertura` | 324 |
| 8 | `Cierre` | `nucleo/cierre.gd` | Cierre limpio. Vacía en `_exit_tree` las cachés `static var` de texturas y materiales mientras el servidor de render sigue vivo; si no, había un «segmentation fault» al salir. | (ninguna: actúa solo) | 1 |
| 9 | `AntialiasedLine2DTexture` | `addons/antialiased_line2d/texture.gd` | Textura de borde suave del addon Antialiased Line2D (MIT), usada por `ui/componentes/trazo_suave.gd`. | — | — |

## Reglas

- Un autoload nuevo solo si de verdad es global y vive toda la partida. Si no, una clase con `static func` (como `Tema`, `Animar`, `RetosSemana`).
- No guardar en un autoload estado de la partida: ese estado va en `Mundo` y se guarda con `Partida`. Las excepciones son la base activa (`Datos`), la semilla (`Azar`) y la moneda (`Eco`), que se restauran al cargar.
- El banco fija la base real al empezar (`pruebas/banco.gd`). Solo algunas secciones siembran `Azar` (estadio, varios), y el mundo no es determinista dentro de un mismo proceso: una prueba que dependa del orden de las demás, o de un sorteo sin sembrar, es un fallo de la prueba.
