# Pantallas de gestión en el teléfono: auditoría (10-11-2026)

Encargo de la líder (orden 26: el MÓVIL es uno de los puntos más débiles). Es lo mismo que se hizo con el HUD del partido
(`controles_tactiles_movil_2026-11-10.md`), ahora en las pantallas de gestión.

## Cómo se midió
`pruebas/auditoria_gestion_movil.tscn` (en `especiales.sh`, con pantalla). Simula un teléfono de 400 ppp (6,5" a 2400×1080, en
horizontal, como fija el proyecto) con el zoom de interfaz del móvil (`EscalaMovil.ZOOM_MOVIL` = 1,5), en ALEMÁN, el idioma de
textos más largos. Recorre 9 pantallas: el menú (Inicio), plantel, táctica, mercado, finanzas, competiciones (la pestaña y la ficha),
selección y ajustes. Cada una va con un club de un país distinto (CHI, ARG, BRA, orden 34). Comprueba:
- **letra:** cada texto visible mide al menos 1,8 mm de alto (11 pt de Apple ≈ 1,8 mm; 12 sp de Material ≈ 1,9 mm);
- **toque:** botones, desplegables, casillas, campos y deslizadores visibles miden al menos 7 mm de alto Y de ancho (Apple 44 pt,
  Material 48 dp);
- **solapes:** dos controles que se tocan no se pisan;
- **textos cortados:** los que se recortan con «…» o sin más y no caben ni encogidos (`TextoQueCabe`), y los que el código recorta
  a mano;
- **fuera de pantalla:** nada se sale por los lados.

Con `FOTOS=1` guarda `gm_<pantalla>.jpg`; `SOLO=Inicio,Táctica` lanza solo esas.

## Hallazgos (antes): 16 fallos
| pantalla | letra mínima | toques < 7 mm | otros |
|---|---|---|---|
| Inicio | 1,4 mm (26 textos < 1,8) | 4: «⤢» 4,0 mm de ancho, «📅» 4,9, cajón 🎯 4,4 | fila de próximos cortada a mano («Kondor-Pokal · Gru…»); el cajón de objetivos tapaba el «⤢» y el texto de «Was passiert» |
| Plantel | 1,6 mm (35) | 5: cabeceras «POS» 5,4 mm, «POT», «GES ▾» 6,6, «⤢» | |
| Táctica | 1,4 mm (21) | 2 («⤢») | **5 fichas de la pizarra pisadas**: en un 4-2-3-1 el DC y el MCO quedaban a ~52 px y la ficha mide 78, el nombre de uno bajo la cara del otro |
| Mercado | 1,4 mm (19) | 1: el campo de búsqueda, 6,9 mm de alto | |
| Finanzas | 1,6 mm (12) | | |
| Competiciones | 1,6 mm (41) | **32 de 42**: los botones de país «ARG», «AUS»… de 5,1-5,6 mm de ancho | |
| Ficha de competición | 1,6 mm (11) | | |
| Selección | 1,6 mm (12) | | |
| Ajustes | 1,6 mm (16) | 5: «JA» 4,1 mm, «▶» 4,3, deslizadores de 6,3 mm de alto | |

Con el zoom del móvil, la letra normal (14 px) ya medía unos 2 mm, pero los rótulos, cabeceras, pastillas y filas de 10-12 px
quedaban en 1,4-1,7 mm.

## Arreglos
- **Letra mínima en el móvil** (`EscalaMovil._letra`, la misma red de seguridad que ya ponía 7 mm de alto a los botones): ningún texto
  por debajo de 1,8 mm. Sube solo lo que no llega y nunca por encima de la letra normal (`Tema.TAM_CUERPO`): si el jugador baja el
  «Tamaño de la interfaz», manda su elección. `TextoQueCabe` tampoco encoge por debajo de ese mínimo. En PC no cambia nada (sin
  puntos por pulgada).
- **Toques de 7 mm también de ancho** (botones), y de alto en los cuadros de texto y los deslizadores. En PC no cambia nada.
- **Pizarra de Táctica** (`PizarraTactica.alto_para`): el campo mide `ALTO` (380) o más, hasta 680, si dos fichas casi en la misma
  columna quedarían a menos de una ficha en vertical. **Cambia también en PC**: las formaciones con líneas muy juntas (4-2-3-1, 4-1-2-1-2)
  tienen un campo más alto, con desplazamiento, en vez de fichas pisadas.
- **Fila de próximos** (`TarjetaEvento`, `FilaProximos`): en el móvil no hay tooltip con el texto entero, así que el texto largo baja a
  una segunda línea en vez de cortarse a 18 caracteres. Caben 4 eventos en vez de 5, sin ensanchar la pantalla: con 5 sacaba por la
  derecha el dinero y la fecha.
- **Objetivos de la directiva** (`ObjetivoDirectiva`): en el móvil, en dos líneas en vez de cortados.
- **Cajón de objetivos** (🎯): en el móvil el contenido del Inicio deja su hueco a la derecha, así que ya no tapa el «⤢» ni el texto de
  «Was passiert».
- **«Plantel y cuerpo del equipo»**: en el móvil, «👔 Kader ▸» (corto), porque el largo cortaba el título de la columna («ERSTE LI»).
- `EscalaMovil.es_tactil()`: móvil, o pantalla de la que se conocen los puntos por pulgada (las pruebas que simulan un teléfono). Así
  la prueba y el teléfono ven lo mismo.

Resultado: **0 fallos en las 9 pantallas**. Letra mínima de 1,9 mm en todas; 0 toques pequeños, 0 solapes, 0 cortados, 0 fuera.
Siguen en verde el banco, `aud4_movil_partido`, `aud4_movil_modales`, `aud4_movil_toque`, `aud4_movil_flujo`, `p6_escala_movil`,
`uite_movil_*`, `tac_hud`, `j4_pizarra`, `tac_deshacer`, `tut_capas` y `ate_ayuda_en_menu`.

## 2.ª parte: la cabecera compacta (aprobada por la líder, solo en el móvil)
En horizontal el teléfono tiene 480 px lógicos de alto. En los menús, la cabecera grande («Zurück», «KADER» en 36 px) y el botón
«Übersicht: alle Bereiche» se comían ~40 %, y lo que se trabaja quedaba en el 61 % del alto: en el plantel se veía UN jugador de la
lista. Ahora, en lo táctil (`EscalaMovil.es_tactil`), `PantallaMenu` pone en una sola línea el volver, el icono, el título con la
sección, «Übersicht» y el nombre del club; sin la banda, con márgenes de 6 px. En el plantel se ven tres jugadores.
- **Interruptor** en Ajustes → Pantalla: «Cabecera compacta en el móvil», encendido por defecto. Solo aparece en lo táctil, se guarda
  en las preferencias (`pantalla/cabecera_compacta`) y con NO vuelve la cabecera grande. Textos en los 9 idiomas.
- **En PC no cambia nada.**
- **Prueba** (`auditoria_gestion_movil`): en los menús, el contenido tiene al menos el 75 % del alto, y en Ajustes está el interruptor.
  Con `CABECERA=grande` (el interruptor en NO) mide el antes: **61 %**. Con la compacta: **86 %**, con 0 fallos en el resto de criterios.

## Pendiente
- La pizarra de un 4-2-3-1 en el móvil sigue pidiendo desplazarse para ver las 11 fichas (campo de 680 px para que no se pisen).
