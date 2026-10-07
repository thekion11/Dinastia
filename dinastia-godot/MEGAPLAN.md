# MEGAPLAN de Dinastía

Repaso hecho el 29-9-2026 contra estas fuentes:
- **Chat:** los 41 mensajes del usuario en esta sesión.
- **Memoria:** `CLAUDE.md`.
- **Instrucciones profundas:**
  - `instrucciones_extras.txt`;
  - compatibilidad táctil y móvil;
  - las 300 y las 750 ideas.
- **Informes:**
  - el informe externo (61/100);
  - `COMPARACION_INFORME.md`;
  - `AUDITORIA.md`.
- **Seguimiento del proyecto:** `LEEME.md`, `ROADMAP.md` y `MAPA_DE_METAS.md`.
- **Vídeos de referencia:**
  - `marca/referencia/ea_fc25_referencia.mp4`;
  - `ejemplo-partido.mp4` (Soccer Manager 2026).

Cada punto se comprobó **en el código** (con grep o ejecutándolo), no de memoria. En este proyecto, muchas cosas que figuraban como «pendientes» resultaron estar ya hechas.

Estados:
- ✅ está y funciona;
- 🟡 está en parte;
- ⬜ falta;
- 🔒 depende del dueño (PC real, licencias, permiso);
- ⛔ no se hace, con su motivo.

---

## 1. Lo pedido en el chat, uno por uno

| Pedido | Estado | Nota |
|---|---|---|
| Resolver el análisis en PDF «totalmente solo» | ✅ | Informe 61 → ≈71 estimado (`COMPARACION_INFORME.md`) |
| Caras con cubierta en el nombre; quitar el modelo «Ronaldo» | ✅ | |
| Tutorial inmersivo según el modo | ✅ | Mentor con misiones por modo |
| Movimientos físicos, jugadas prehechas, mejora visual general | ✅ | 333 movimientos por jugador |
| Mentor realista y personalizable | ✅ | |
| Modelo del presentador | 🔒 | En pausa a pedido del usuario |
| Realismo biológico y regates de fútbol | ✅ | |
| Caras reales de Wikipedia | ✅ | Solo en el pack real, con créditos |
| Infraestructura del estadio, cinemáticas, ciudad 3D, optimización, creador estilo Los Sims, ropa, mascotas 3D, mini animaciones, tipos de simulación, barra de ajustes desplegable, variantes de estadio, entrevistas, eventos | ✅ | Bloques B1-B16 del ROADMAP |
| Música libre en español | ⛔ | El usuario la descartó el 26-9 |
| Pantalla gigante con tabla, goleadores y resultado | ✅ | |
| Athletic Club: solo cantera local y apellidos por nacionalidad | ✅ | 🟡 falta el dato de **región de origen** del jugador |
| Banquillo mejorado, historia real y guiños (la Ruca, Superclásico, Clásico universitario) | ✅ | Con historia para todos los clubes |
| Escudos coherentes en la rueda de prensa; cambio de escudo como noticia | ✅ | |
| El clima de la ciudad es el del estadio e influye en jugadores y prensa | ✅ | |
| Presidentes de competiciones, accionistas y reuniones | ✅ | |
| Medios nuevos y minijuegos | ✅ | |
| Hablar con jugadores, exámenes, presentaciones y lesiones absurdas | ✅ | |
| Contratos según la ley de cada país (2026) | ✅ | México (reforma de 2026: de 48 a 40 h entre 2027 y 2030) y Egipto (Ley 14/2025) verificados el 7-10-2026 |
| Instalaciones con más niveles, trabajadores y eventos; cantera; otras ramas del club; días nacionales; globo terráqueo | ✅ | |
| Política y religión | 🟡 | A propósito: política ficticia y solo festividades del país |
| Ficha del jugador «simulado» | ✅ | ⛔ vida sentimental de personas reales (regla fija) |
| Menú propio de «Mi vida»; árbol de habilidades con esquema | ✅ | |
| Guiño de la historia al club real | ✅ | |
| 50+ diseños de camiseta, 5 colores, 30 botines, 20 de 3 colores y 20 de 2 colores, sponsors, diseñador a pantalla completa | ✅ | 130 diseños |
| 15 categorías de habilidades × 30 niveles que influyen en los resultados | ✅ | |
| Tiros, pases, barridas, atajadas, regates, expresiones, lesiones, árbitro, POV del árbitro, VAR por dentro | ✅ | |
| Recrear los estadios de TODOS los clubes | 🟡 | Hay forma y aforo del real; falta la tabla de guiños por club (E9) |
| Más idiomas | ✅ | 9. El usuario: «con esos idiomas estamos bien» |
| Tipografías y diseño; 40 % más rápido | ✅ | Hoy el refresco es 14 veces más rápido |
| Más escudos | ✅ | |
| Modos de juego faltantes | 🟡 | Ver sección 3 |
| IA futura v1 | ✅ | `MotorLibre` y el nuevo `MotorJugable` |
| Ciudad navegable | ✅ | |
| Personaje base modificable | ✅ | 🔒 cara por blendshapes (Blender en PC) |
| Trofeos con animación, 300 animaciones, 300 sonidos, foco en eventos, mini fondos de modos | ✅ | |
| Peatones con los modelos del vagabundo y del pack; mascotas; calles | ✅ | |
| Estadios extra basados en los reales | ✅ | |
| Calles que no cierran; casa tapada con enredadera; autos | ✅ | |
| Edificios del pack de ciudad y sistema de reputación | ✅ | |
| La ropa tapa los músculos; la mano del móvil | ✅ | |
| Mapa de metas; realismo de la casa; redes; cuenta del club; móvil con apps | ✅ | |
| Balón mejor y con variantes; la cinemática coincide con el club | ✅ | |
| Panel lateral con 9 menús; menú central que rota cada 10 minutos; panel de objetivos movible | ✅ | |
| Carrera de Jugador con control real | ✅ | v1 (ver sección 3) |
| Grada y público de verdad, butacas 3D en TODA la grada, mirando al campo | ✅ | 29-9 |
| Limpieza, comparación con el informe, auditoría y vídeo | ✅ | 29-9 |

## 2. Las instrucciones profundas

- **Compatibilidad táctil, mouse, teclado y mando; ajustes de FPS, velocidad y calidad; adaptación a cualquier pantalla (portátil a TV)**
  - ✅ en el código.
  - 🔒 falta probarlo en dispositivos reales.
- **Guardado automático y manual** ✅.
- **Nombres y medias reales** ✅ solo en el pack real (regla legal).
- **Inicio profesional, elegir club con mapa del país, escudos mejores** ✅.
- **Logo con animación** ✅.
- **Personalizar el personaje antes de empezar** ✅.
- **«Se siente soso»**: el vídeo promo de hoy es la prueba de lo contrario, aunque quedan cosas del apartado 5.
- **Instrucciones extras** (roles, descanso, uniforme separado del menú, simulación, pizarra, presupuestos FC, 3D, posiciones, rostros, tutorial, instalaciones, árbol de habilidades, Mundial, copas de 3 continentes, editor +100, estadios estilo DSL, sponsors raros, camarillas, salud mental, representantes, funas, mercado a ciegas, invertir el salario, los 12 eventos especiales, árbitros con perfil, interinato, lenguaje corporal, retiro de leyendas, escuela táctica, fichajes comerciales, fondos buitre, Director de Cantera, aforos y ligas reales, satisfacción y exigencias del jugador) ✅.
  - La **escuela táctica** está en `pantalla_legado.gd`.
  - Los **fondos buitre** están en `FondoInversion`.
- ⛔ **Charla con IA conversacional en línea** (coste por uso y conexión): la charla escrita deduce el tono sin IA.
- ⛔ **Estadísticas y dorsales de FC 26**: los datos tienen licencia.
- 🟡 **«Jugar 10 temporadas × 3 como humano»**: hoy hay una simulación de 3 temporadas con 0 errores. Falta la prueba automática de **10 temporadas con 3 semillas** (ver fase 1).
- **Las 1.050 ideas (300 + 750)**: el ROADMAP las cruzó por bloques. Según `dinastia-pendientes` v3.1 están hechas salvo las marcadas ⛔ (monetización agresiva, datos con licencia, IA en línea).

## 3. Lo que falta de verdad

### Depende de ti o del dueño 🔒

1. **Probar en un PC real y en un Android:** FPS, builds de `entregas/` e instalación.
2. **Cambiar la contraseña del keystore**: la vieja sigue en el historial.
3. **Confirmar licencias 🟡** de modelos de Sketchfab, Meshy y otros (`LICENCIAS.md`).
4. **Permiso para «la cara 2D moldeada sobre el modelo 3D»**: con eso habría caras individuales en el campo, lo que más sube la nota visual.
5. **Presentador del sorteo** con el modelo propio (en pausa a tu pedido).
6. **Cara por blendshapes**: hace falta Blender en tu PC.

### Se puede hacer aquí ⬜

1. **Carrera de Jugador v2:**
   - fuera de juego;
   - cambios (sales o entras del banco);
   - más eventos únicos;
   - convocatoria y partidos con la selección;
   - pasar de jugador a DT al retirarse, en la misma partida (ver originalidad).
2. **Estadios de todos los clubes (E9):**
   - una tabla de guiños por club (techo, color, detalle icónico, apodo del estadio);
   - hoy la forma y el aforo ya siguen al real.
3. **Modos a medias (E16):**
   - revisar Leyenda y Selección jugable en el menú de inicio;
   - cerrar lo que no llegue al final de una temporada.
4. **Plantillas fijas** para los 128 clubes que no están en el pack.
5. **Mini-juego de representantes**: la mecánica de agentes existe; falta la negociación como juego.
6. **Banderas en el estudio** del sorteo y la rueda de prensa (hoy no hay ninguna).
7. **Región de origen del jugador**: para la regla del Athletic Club, que hoy usa el país.
8. ✅ **Leyes laborales de México y Egipto**: verificadas el 7-10-2026 (México baja 2 h al año desde 2027; Egipto, Ley 14/2025, 48 h).
9. **Túnel navegable**: espera al modo caminar por el estadio.
10. **Traducir la narración** (noticias, prensa, vestuario), al menos al inglés.
11. **Paleta de vallas LED y formas nuevas** de estadio (B6).

## 4. Fallos y roces encontrados hoy

Arreglados hoy (ver `AUDITORIA.md`):
- refresco de 2-4 s por clic;
- fallo al cerrar el juego;
- dos ventanas exclusivas;
- la grada del revés;
- idioma pegado de las pruebas.

Pendientes, de menor a mayor esfuerzo:

1. **El panel de objetivos tapa la ficha del jugador** en 1280×720 (visto en el vídeo). Posición por defecto según el ancho de pantalla, o plegado automático a la derecha.
2. **Ordinales en francés y turco**: «1e» debería ser «1er», y en turco `to_upper()` de «i» debe dar «İ». Afecta a los títulos en mayúsculas.
3. **Etiquetas con nombre encima de los jugadores** en el partido 3D: se amontonan en las jugadas de área (visto en las capturas del partido). Ocultar las lejanas o apilarlas.
4. **Césped del partido plano y muy saturado** frente a FC (ver sección 5): corte a franjas más marcado y un verde menos fluorescente.
5. **La primera carga del estadio tarda 4,2 s** (modelos y shaders). Precargar en segundo plano mientras se ve la previa del partido.
6. **La ficha del jugador tarda 0,3-0,4 s** en repintarse, sin gráfica: es lo más lento que queda del refresco.
7. **La escena del sorteo es muy oscura**: le falta luz de relleno sobre el bombo y el presentador.
8. **Prueba de 10 temporadas × 3 semillas** automatizada en el banco, con los invariantes de hoy (dinero, medias, planteles, sueldos) más ascensos y descensos, jubilaciones y regens.
9. **Recorrido de pantallas en CI**: hoy tarda más de 10 minutos. Se corre en 4 tramos; convertirlo en una prueba nocturna.

## 5. Comparación con los vídeos de referencia

| Aspecto | EA FC (referencia) | Soccer Manager 2026 | Dinastía hoy | Qué hacer |
|---|---|---|---|---|
| Césped | Franjas de corte muy visibles, verde apagado y realista | — | Verde plano y saturado | Franjas + tono por clima y hora |
| Grada | Llena, con volumen y sombras | Foto de fondo | Llena, butacas 3D y público sentado (29-9) | Sombra del techo sobre la grada |
| Vallas | LED animadas | — | Vallas con sponsors | Animar las LED en el gol y en los cambios |
| Jugadores | Caras reales | Caras en las fichas de la formación | Cara 2D en fichas; 3D genérico en el campo | 🔒 cara 2D→3D |
| HUD | Mínimo: marcador y radar | Anillos de estadísticas y «Mánager adjunto» | Marcador, radar y banner de gol | Consejos del ayudante en el partido (ya hay mentor) |
| Táctica | — | Pizarra con cartas y cara de cada jugador | Pizarra con cara y media | ✅ a la par |
| Menús | — | Riel lateral naranja, fichas grandes | Riel lateral + 9 menús a pantalla completa | ✅ a la par |

## 6. Jugabilidad: mejoras propuestas

1. **Partido del DT más interactivo:**
   - dar órdenes en vivo con gestos desde la banda (el `PersonajeDT` ya está en el área técnica);
   - «¡Presión!», «Calma», «Todos arriba» cambian el `MotorLibre`.
2. **Unir los dos motores:**
   - el `MotorJugable` de la Carrera de Jugador (física del balón, reglas, IA de 21) como tercer tipo de simulación del modo DT: «ver el partido jugado de verdad»;
   - es lo que pedías como «IA futura».
3. **Mando en el modo DT:**
   - tomar el control de un jugador cualquiera en un momento clave (penal, tiro libre), estilo «momentos» de FC;
   - reutiliza el apuntado ya hecho.
4. **Consecuencias visibles:** cada decisión de la semana (prensa, charla, vestuario) aparece como una línea en el informe previo al partido: «el 9 está molesto porque lo criticaste».
5. **Temporada con ritmo:**
   - semana de clásico con cuenta atrás, entrenamiento especial y hinchada con tifo;
   - la pantalla gigante lo anuncia.
6. **Dificultad dinámica** para nuevos jugadores: el mentor sugiere y no bloquea.

## 7. Originalidad: lo que nadie más tiene

1. **Una vida entera en una partida:** empiezas como jugador (Carrera de Jugador), te retiras, sacas la licencia C y dirige tu personaje en la misma partida, con tu historia de jugador como currículum. Ningún manager une los dos modos.
2. **Dinastías familiares:** tus hijos (el linaje ya existe) llegan a la cantera del club que construiste. Con la carrera unificada, puedes dirigir a tu propio hijo.
3. **El documental de la temporada:** al final de cada año, un resumen automático con los momentos (goles, fichajes, crisis) montado con las cinemáticas que ya hay. Se usa el mismo sistema del vídeo promo de hoy.
4. **La ciudad responde al club:** si ganas, la ciudad se llena de banderas del club; si desciendes, persianas cerradas y grafitis. Ya hay ciudad 3D y reputación: falta el enlace visual.
5. **Tribuna como termómetro real:** las publicaciones de la hinchada citan jugadas concretas del último partido, no plantillas.
6. **Modo foto** en estadio, casa y ciudad, con el filtro del club, para compartir.

## 8. Orden de trabajo propuesto

**Fase 1 — Pulido y confianza (1-2 días)** ✅ HECHA el 5-10-2026:
- Ordinales en francés («1er») y catalán (1r, 2n, 3r, 4t, 5è) y mayúsculas turcas («İ»), comprobados en el banco.
- Panel de objetivos: en pantallas de menos de 1500 px arranca plegado y abajo a la derecha.
- Rótulos del partido 3D: si dos se pisan, queda el del jugador más cerca del balón.
- Sorteo: luz de relleno, cristal visible en Compatibility y colisionador con forma de cuenco (se escapaban 43 de 46 bolas).
- `pruebas/prueba_larga.tscn` (10 temporadas × 3 semillas, unos 3 minutos). Encontró y se arreglaron dos fallos:
  - chicos por encima de su potencial;
  - canteranos fugados que iban siempre a un grande lleno (un club con 51 jugadores y 8 porteros).

**Fase 1 — plan original**
- Sección 4: puntos 1, 2, 3, 7 y 8.
- Los roces visuales del vídeo.

**Fase 2 — El partido se ve como uno de verdad (2-3 días)** ✅ HECHA el 5-10-2026:
- Césped: verdes de césped real (menos saturados), al menos un 22 % entre franjas y franjas de unos 6 m. Los cortes «circulos» y «liso» salían planos por un nombre que no casaba.
- Techo: la losa entre la cámara y el campo ya no tapa la vista (con techo de anillo tapaba medio campo) y su sombra sobre la grada se mantiene.
- Vallas LED: en el gol («¡GOOOL!» + club) y en los cambios («CAMBIO», quién entra y quién sale) todo el anillo parpadea con los colores del club.
- Carga del estadio: con cachés de cara y pelo, la 2.ª apertura pasa de 5,6 a 3,6 s (`pruebas/medir_carga_estadio.tscn`). La 1.ª sigue en unos 9,6 s en este entorno sin tarjeta gráfica; lo que más cuesta es crear los modelos de los jugadores.
- Etiquetas de nombre sin amontonar (hecho en la fase 1).

**Fase 2 — plan original**
- Césped con franjas.
- Sombra del techo sobre la grada.
- LED animadas.
- Precarga del estadio.
- Etiquetas de nombre.

**Fase 3 — Carrera de Jugador v2 (3-4 días)** ✅ HECHA el 7-10-2026:
- **Fuera de juego** en el motor jugable:
  - en cada pase o tiro se toma una foto de quién está adelantado (penúltimo rival, con 30 cm de tolerancia);
  - se pita al recibir y saca el rival;
  - no hay fuera de juego en saques de banda, córners ni saques de puerta, y un toque del rival lo anula;
  - la IA vuelve a estar habilitada y el pasador ve el fuera de juego según su visión;
  - medido: 2-4 por partido.
- **Cambios:**
  - «IR AL BANCO» si eres suplente: el DT decide si entras y cuándo (antes cuanto mejor la relación).
  - Siendo titular, el DT puede sacarte pasada la hora: pesan su exigencia, tu nota y tu desgaste.
  - Si no hay un balón parado, el árbitro detiene el juego para el cambio.
  - Los minutos reales cuentan.
- **Desgaste del partido:** de 1 a ~0,6 en 90' según el físico. Es la barra de aguante y lo que mira el DT. No frena a los jugadores (cuando frenaba, los tiros bajaban de 7-8 a 1-4).
- **13 eventos únicos nuevos**, cada uno nacido de algo que te pasa:
  - debut, primer gol, mentor veterano, cesión si no juegas, jugador del mes, brazalete;
  - lesión larga, polémica en redes, reencuentro con un ex club, oferta del extranjero;
  - licencia de entrenador, pensar en el retiro, el niño que pide tu camiseta.
- **Selección jugable:**
  - convocatoria por nacionalidad en cada fecha FIFA (los mejores de tu país en tu línea);
  - partido con la selección en el motor jugable o simulado, contra un rival con la fuerza de su país;
  - internacionalidades y goles.
- **Una vida entera en una partida:**
  - al retirarte (lo anuncias, o a los 38 años) ves tu carrera resumida y hasta tres clubes de tu país te ofrecen el banquillo según tu fama;
  - diriges en el mismo mundo con tu nombre, y la partida de entrenador previa queda de respaldo.
- Pruebas: banco (eventos, convocatoria, selección, retiro y paso a DT, guardado) y `prueba_motor_jugable` (`CAMBIO=banco|sale`, 3 semillas). Capturas: `pruebas/captura_carrera_fase3.tscn`.

**Fase 3 — plan original**
- Fuera de juego, cambios, eventos y selección.
- Transición de jugador a DT.

**Fase 4 — Contenido que falta (2-3 días)** ✅ HECHA el 7-10-2026:
- **Guiños de estadio (E9):** el rasgo de los 176 estadios reales (`ESTADIO_CLUB`) ya no es solo texto, ahora se dibuja (`visor/guinos_estadio.gd`):
  - cordillera, cerro o volcán de fondo, con nieve en las cumbres altas;
  - río, lago o mar junto al estadio (con el agua animada del juego);
  - desierto con dunas, bosque alrededor;
  - cuatro torres rojas, torres de rampas, una torre sola, techo en arco, burbujas o carpas, y un muro de edificios.
  - Cada estadio tiene un **apodo** genérico, nunca el nombre oficial («El Mirador», «La Caldera», «Las Torres»…). Sale en el rótulo del estadio: 111 de 176 tienen uno.
  - Capturas: `pruebas/capturas/estadio_guino_0..7.png` (`GUINOS=1 … captura_estadios_reales.tscn`).
- **Plantillas fijas:** la plantilla inicial de **todos** los clubes se siembra con el nombre del club, no con la semilla ni con su id.
  - El mismo club trae a la misma gente en cada partida, cargues los países que cargues (probado: 48 de 48).
  - Esto incluye los clubes sin tabla de reales.
  - Lo que llega después (canteranos, regens, resultados) sigue variando con la semilla.
  - De paso se corrigió el **motor libre**: tiraba 100-200 veces por partido y salían 9-6. Ahora tira 10-40 veces. La prueba pasaba solo por la plantilla de una semilla concreta.
- **Banderas del estudio:** 24 banderas nacionales dibujadas en código más la del club (`visor/banderas.gd`, shader con espejo).
  - En el sorteo, mástiles con los países del bombo.
  - En la sala de prensa, la del país y la del club.
- **Mini-juego de representantes:** la presión del agente ya no es un sí o un no. Con «🤝 Sentarse a negociar» se regatea por rondas (`nucleo/mesa_agente.gd`, `ui/componentes/mesa_agente_ui.gd`):
  - El agente pide el 100 % y esconde un mínimo según su perfil: el tiburón aprieta y el formador cede. También influyen la confianza que te tiene y el bono de agentes del DT.
  - Cada ronda gasta una taza de paciencia. Ofrecer muy poco lo ofende. Si se le acaba la paciencia se levanta de la mesa, y eso es peor que un no.
  - Tienes un farol por mesa: si cuela, baja mucho; si no, se enfada.
  - Cada ronda deja una señal de cuánto margen le queda. El tiburón a veces disimula.
  - El trato se aplica a escala: una mejora pactada al 50 % sube el sueldo un 15 %, no un 30 %.
  - Medido en 300 mesas: el formador cierra de media al 64 % y el tiburón al 84 %.
  - Capturas: `pruebas/capturas/mesa_agente_1/2.png`.
- **Modos hasta el final (E16):** `pruebas/prueba_modos.tscn` juega los 11 modos de entrenador y ahora también la **Carrera de Jugador**: una temporada entera, la siguiente, los eventos y el guardado. 0 fallos.
  - Ya no queda ninguna tarjeta «en desarrollo» en el menú.
  - «Leyenda» es una dificultad.
  - La selección jugable llegó en la fase 3.
- Banco: 0 fallos, con pruebas nuevas de guiños, plantillas fijas y la mesa.

**Nota recalculada tras las fases 1-4** (estimación propia, mismas 7 categorías y pesos que en `COMPARACION_INFORME.md`):

| Categoría | Peso | Antes (29-9) | Ahora | Por qué sube |
|---|---|---|---|---|
| Arquitectura | 15 % | 72 | 73 | Prueba larga de 10 temporadas y prueba de los 12 modos. |
| Jugabilidad | 20 % | 74 | 78 | Fuera de juego, cambios, selección, de jugador a DT y la mesa de agentes. |
| Visual / 3D | 15 % | 64 | 70 | Caras reales en el campo, pelo por cortes, césped, techo, LED, guiños y banderas. |
| Rendimiento | 10 % | 70 | 70 | Sin medir en un PC real. |
| Contenido | 20 % | 80 | 83 | Plantillas fijas, 13 eventos y 176 estadios con guiño. |
| Pulido | 10 % | 60 | 64 | Los roces del vídeo arreglados. La narración sigue solo en castellano. |
| Originalidad | 10 % | 68 | 71 | Una vida entera en una partida y el regateo con representantes. |
| **Total** | | **≈71** | **≈74** | |

Cuenta: 10,95 + 15,6 + 10,5 + 7,0 + 16,6 + 6,4 + 7,1 = **74,2**.

Se queda **a un punto de la meta de 75**. Lo que más falta en pulido es traducir la narración (punto 10 de la lista) y probar en hardware real (🔒). La fase 5 (originalidad) es la siguiente.

**Fase 4 — plan original**
- Guiños de estadio por club (E9).
- Plantillas fijas de los 128 clubes.
- Banderas del estudio.
- Mini-juego de representantes.
- Modos a medias (E16).

**Fase 5 — Originalidad** ✅ HECHA el 7-10-2026:
- **Documental de la temporada** (`ui/componentes/documental_temporada.gd`): al cerrar el año, la temporada contada como una película.
  - Franjas de cine, zoom lento y narración que se escribe sola.
  - Capítulos con datos reales: fichajes, goleador, mayor goleada, racha, peor derrota y veredicto.
  - Se vuelve a ver en Historia → «Documental de la temporada».
- **La ciudad responde al club** (`visor/ciudad_animo.gd`): según el puesto, la racha y el título o el descenso:
  - en la euforia, pancartas en las fachadas y banderas en el anillo;
  - en la crisis, persianas y grafitis genéricos;
  - el color de la escena también cambia.
- **Modo foto** (`ui/componentes/modo_foto.gd`) en la ciudad, el estadio y la casa:
  - 6 filtros: natural, club, blanco y negro, sepia, cine y vintage;
  - marco con escudo y pie;
  - las fotos se guardan en la app de Fotos del móvil.
- **Dinastías familiares**:
  - el hijo de tu jugador retirado (Carrera de Jugador → DT) llega a la cantera que diriges, con tu apellido y un techo heredado;
  - en el modo entrenador, tus hijos crecen y a los 16 entran en tu cantera («el hijo del míster»).
- **La Tribuna como termómetro real:** los hinchas citan goles, minutos y resultados de tu último partido.
- **Y además, la estatua del ídolo:** en la Plaza Mayor hay una estatua de bronce de la última leyenda del club, o de su capitán.

**La ciudad 2.0 (7-10-2026, pedidos del usuario durante la fase 5):**
- **Tamaño:** 2.640 m de lado, más de 4 veces la superficie anterior (`visor/ciudad_expansion.gd`).
- **Red vial en datos:** 1.027 tramos, avenidas cada tres calles y un bulevar alrededor del núcleo. Incluye `camino_entre`, la base para conducir, caminar y mover NPC.
- **Zonas:** centro de torres, comercio y oficinas, casas con jardín, industria y puerto.
- **Instalaciones de ciudad:**
  - ayuntamiento y Plaza Mayor, estación central, mercado, cine;
  - hospital, comisaría, bomberos, escuela, instituto, universidad;
  - centro comercial, gasolineras, cocheras, granja, desguace;
  - Villa moderna y parques con lago.
- **El río:** 33 tramos de puente, puerto con veleros y botes que pasan bajo los puentes. Se movió a x = −470 para no pisar el anillo exterior.
- **Semáforos con ciclo real** en 326 cruces (`visor/semaforos.gd`). Los coches frenan en rojo y hacen cola.
- **Transporte:**
  - dos líneas de bus que paran en 28 marquesinas;
  - **metro**: la línea 1 elevada con viaducto, estaciones y trenes que paran y dan la vuelta; la línea 2 subterránea, visible en rayos X; paneles de próximo tren (`visor/metro_ciudad.gd`);
  - **autopista** elevada alrededor de la ciudad, con enlaces y carreteras al horizonte (`visor/autopista.gd`).
- **La Casa Grande** vuelve, en su finca de 2×2 manzanas rodeada de seto. El 26-9 se había quitado la casa por error.
- **Ciudad interactiva** (`visor/explorador_ciudad.gd`):
  - conducir y pasear, con choques contra manzanas y río y subida a los puentes;
  - hablar con los peatones (te comentan cómo va el club);
  - entrar a los lugares;
  - teclado, mando y controles táctiles.
- **Minijuegos:**
  - en la ciudad: autógrafos en la Plaza Mayor, pesca en el puerto, contrarreloj en el karting, trivia en la universidad y el cine, penales en los parques;
  - sala en Mi Vida: penales, tiro libre (nuevo) y trivia del club (nueva).
- **Identidad y noche:** murales del club, parque eólico con aspas girando, depósito de agua, farolas con charco de luz, ventanas encendidas y guirnaldas de colores.
- **Inventario automático:** **todos** los modelos de `assets/ciudad` aparecen en la ciudad, 0 sin usar (`pruebas/prueba_ciudad_modelos.tscn`).
- **Instalaciones del club:** cada una con su arquitectura (naves con bóveda, piscina de cristal, torre, clínica, templo, escuela en L, pabellón, medios, tienda) y un campus con paseos.
- **Narración:** 129 titulares de noticias traducidos al inglés y al portugués (punto 10, primera parte).
- **Límite honesto:**
  - la ciudad tarda unos 3-5 s en construirse en este entorno sin tarjeta gráfica (unos 13.600 nodos); falta medirla en un PC real;
  - la línea 2 del metro se ve solo en rayos X;
  - los cuerpos de las noticias siguen en castellano.

**Caza de fallos de cierre (7-10-2026):**
- **Prueba larga:** en 10 temporadas aparecían clubes con 6-7 porteros o sin delanteros. Estaba roto desde la fase 4.
  - Tope de 3 porteros en la camada, los hermanos y los hijos de leyenda.
  - La IA ficha con sentido de puesto: no compra un cuarto portero ni deja al vendedor sin mínimos.
  - La cantera repone una línea vacía aunque el plantel esté lleno.
  - Vuelve a 0 fallos con 3 semillas.
- **Metro:** el tren no paraba en las estaciones (las daba por pasadas a menos de 0,5 m). Lo cazó el banco.
- **Recorrido de pantallas:** 106 pantallas y 492 botones sin errores. Banco, prueba de modos y prueba larga en 0 fallos.

**Nota recalculada tras las fases 1-5** (estimación propia, mismas categorías y pesos):

| Categoría | Peso | Tras la fase 4 | Ahora | Por qué |
|---|---|---|---|---|
| Arquitectura | 15 % | 73 | 75 | Red vial en datos, inventario automático y más pruebas. El núcleo sigue siendo el portado del HTML. |
| Jugabilidad | 20 % | 78 | 81 | Ciudad recorrible, 8 minijuegos, mesa de agentes y dinastías. |
| Visual / 3D | 15 % | 70 | 76 | Ciudad 2.0 y 2.2: metro usable, minijuegos e interiores en 3D, puentes de piedra, mobiliario urbano y vehículos a escala. |
| Rendimiento | 10 % | 70 | 69 | La ciudad pesa más y sigue sin medirse en un PC real. |
| Contenido | 20 % | 83 | 88 | Ciudad con nombres, comercios e interiores; minijuegos, documental y dinastías. |
| Pulido | 10 % | 64 | 72 | Narración entera en inglés y portugués; aviso técnico y fugas arreglados. Falta el hardware real. |
| Originalidad | 10 % | 71 | 79 | Documental, ciudad que responde, modo foto, estatua del ídolo, Tribuna real y una vida entera en una partida. |
| **Total** | | **≈74** | **≈78** | |

Cuenta: 11,25 + 16,2 + 11,4 + 6,9 + 17,6 + 7,2 + 7,9 = **78,45**. Se pasa la meta de 75. La narración ya está traducida; para 80+ hacen falta las 🔒 (medir en un PC y un Android reales, builds y licencias).

**Ciudad 2.1 (7-10-2026, tarde)**
- Metro usable: entrar por la boca, esperar en el andén, subir, viajar dentro del vagón (asientos, barras, puertas que se abren, rótulo LED), mirar por la ventana y bajar en otra estación. Estaciones subterráneas con su vestíbulo.
- Minijuegos en 3D con animaciones: autógrafos, pesca, karting contra tres rivales, penales y tiro libre con barrera.
- Patios verdes dentro de las manzanas. Revisión aérea: el metro y la autopista siguen las avenidas.

**Ciudad 2.2 (7-10-2026, noche)**
- Aviso técnico al reconstruir la ciudad arreglado (y fugas de nodos).
- Casas de colores con fachada detallada; edificios del kit teñidos; comercios con rótulo (farmacia con cruz verde).
- Mobiliario urbano completo: alcantarillas, sumideros, papeleras, bancos, hidrantes, reciclaje, bolardos, señales, kioscos, aparcabicis, terrazas y vallas.
- 50 calles con nombre (placas y HUD), parques con nombre, fuente y juegos, estaciones de metro con tema propio.
- Instalaciones por dentro: 15 salas con gente trabajando.
- Puentes de piedra con arcos; vehículos a medidas reales y autobús de 12 m.

**Narración traducida (7-10-2026, punto 10 de «Se puede hacer aquí»)** ✅
- Inglés y portugués para las noticias (títulos y cuerpos), la prensa (preguntas, respuestas, titulares, tertulianos), el vestuario, las charlas, las redes y la Carrera de Jugador: 1.064 frases y plantillas.
- Herramientas: `herramientas/extraer_narracion.py` saca las plantillas del código (nombres y cifras pasan a ser huecos) y `herramientas/montar_narracion.py` arma `datos/narracion.json`.
- El traductor gana dos pasos: los textos de varias oraciones se traducen frase a frase, y el registro de la portada (texto enriquecido) también se traduce.
- Se cambiaron dos motivos de retiro que atribuían religión o política a un jugador (podía ser real).
- Los otros seis idiomas siguen con la narración en castellano.

**Fase 5 — plan original**
- Documental de la temporada.
- Ciudad que responde al club.
- Modo foto.
- Dinastías familiares.

**Fase 6 — Lo que depende de ti 🔒** (estado al 7-10-2026):
- PC y Android reales, builds y keystore: 🔒 del dueño. Ya hay controles táctiles en la ciudad.
- Licencias: 🔒 del dueño. Todo lo nuevo de la fase 5 está hecho en código, sin modelos de terceros nuevos.
- Cara 2D→3D: ✅ hecha con el permiso del 29-9 (malla deformable por jugador y motor de caras).
- Presentador del sorteo: en pausa a pedido del usuario.

**Cómo se mide:**
- Cada fase termina con el banco en 0 fallos, el recorrido de pantallas sin errores y capturas.
- La nota se recalcula con las 7 categorías del informe.
- Objetivo: **75/100 tras las fases 1-4** y **80+** con las 🔒 resueltas.
