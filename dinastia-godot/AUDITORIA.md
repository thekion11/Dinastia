# Auditoría (29-9-2026)

Qué se revisó, qué se encontró y qué se arregló. Todo se ejecutó en el servidor sin gráfica: los tiempos son de CPU y en un PC real deberían ser más bajos.

## Pruebas pasadas

| Prueba | Resultado |
|---|---|
| Banco (`pruebas/banco.gd`) | FIN, 0 fallos |
| Recorrido de pantallas (106 pantallas, más de 500 botones, en 4 tramos con `RECORRIDO_TRAMO`) | 0 errores de script, salida limpia |
| Motor jugable (partido con piloto automático) | 0 fallos |
| Flujo de la Carrera de Jugador (crear, jugar, guardar, cargar) | Sin errores |
| Rendimiento adaptativo (5 escalones) | 0 fallos |
| Descanso en el 3D | OK |
| Simulación larga: 100 semanas y 3 cambios de temporada desde la pantalla principal | 0 errores de script y 0 valores imposibles (dinero, medias, planteles, sueldos) |

## Fallos encontrados y arreglados

1. **Cada clic tardaba 2-4 segundos.**
   - Causa: `_refrescar` repintaba las ~40 pantallas del juego en cada refresco, se vieran o no. Además, `_ver_ficha` repintaba el entrenamiento entero en cada clic de la ficha.
   - Arreglo: pintado diferido (`_perezoso`). Lo que no está a la vista queda pendiente y se pinta el cuadro en que aparece.
   - Resultado: de ~3.500 ms a ~250 ms por refresco, unas 14 veces menos.
2. **El juego fallaba al cerrarse** (señal 11, «segmentation fault»).
   - Causa: la traducción de «entrenadora» (`Genero`) es un script registrado en el servidor de traducciones y nunca se quitaba. Al salir, el servidor la liberaba cuando GDScript ya estaba apagado.
   - Arreglo: `Genero.desinstalar()` desde el nuevo autoload `Cierre`. Ese autoload también vacía las 73 cachés estáticas de texturas, mallas y materiales.
3. **Dos ventanas exclusivas a la vez** al reabrir «Elegir club».
   - Causa: la ventana anterior solo se marcaba para borrar al final del cuadro.
   - Arreglo: ahora se saca del árbol en el acto.
4. **Las capturas de idiomas dejaban el juego en turco** para la siguiente sesión.
   - Arreglo: ahora restauran el castellano y lo guardan al terminar.
5. **El recorrido se colgaba en «Elegir club».**
   - Causa: pulsaba los 32 clubes en un solo cuadro, algo que un jugador no puede hacer.
   - Arreglo: el recorrido ya no pulsa botones dentro de ventanas emergentes.

## Lo que queda anotado (no bloquea)

- **«2 resources still in use at exit»** al salir: son avisos de Godot, no un fallo.
- **Pantalla principal sin gráfica:** tarda ~1,4 s por semana simulada, repintado incluido. Falta medirlo en un PC real (lo hace el dueño).
- **Construir un estadio de 47.000 butacas:** 4,2 s la primera vez (carga modelos y shaders) y 0,25 s las siguientes.
- **Grada completa:** +30 % de triángulos (3,59 M). El rendimiento adaptativo tiene un escalón para aligerarla.
- **Archivos subidos por el usuario:** `datos/tablas.json.bak` y `test_shark.png` siguen en el repositorio. No se tocaron. El primero tiene datos reales y ya está excluido de los builds.

---

## Auditoría del bucle · 12-10-2026 (tras las etapas 3, 4 y 5)

| Comprobación | Resultado |
|---|---|
| Banco (`herramientas/banco.sh`) | FIN. 0 fallos |
| `prueba_modos` | FIN MODOS. 0 fallos |
| Frases sin traducir (9 idiomas) | 0 de 65 literales; la narración va aparte |
| Registro de la ciudad 3D y de la entrada con portero | sin errores ni avisos (solo el V-Sync del servidor) |
| Registro del partido al cerrar | 3 scripts y 9 objetos «sin soltar» **solo si la prueba sale en seco con el partido abierto** (`medir_partido`); el cierre normal ya no fuga. Pendiente: confirmar con una prueba que abre y cierra. |
| CPU de la ciudad sin gráfica | 7–9 ms por fotograma |
| CPU del partido sin gráfica | 3,8 ms por fotograma |
| Carga del estadio | 1.ª apertura 5,6 s, 2.ª 0,5 s |

Hallazgos de esta pasada y arreglados: biblioteca de animación armada 105 veces
(2,9 s de la ciudad); texturas del escaneo y de la Tierra sin compresión de
VRAM; calidad gráfica que no se guardaba; ciudad sin ajuste automático de
calidad; mobiliario atravesable; movimiento brusco (sin aceleración ni
deslizamiento).

Límites honestos: `-s` (scripts sueltos) se cuelga en este entorno, hay que
envolverlos en una escena; los FPS reales dependen de la máquina del dueño (aquí
el render es por software), por eso se miden llamadas de dibujo, triángulos y CPU.
