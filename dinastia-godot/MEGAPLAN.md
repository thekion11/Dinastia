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
| Contratos según la ley de cada país (2026) | 🟡 | México y Egipto, por revisar |
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
8. **Leyes laborales de México y Egipto**: verificar el dato.
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

**Fase 3 — Carrera de Jugador v2 (3-4 días)** 🟡 EN CURSO (6-10-2026):
- ✅ Fuera de juego en el motor jugable: foto en cada pase o tiro (penúltimo rival, con tolerancia de 30 cm), se pita al recibir y saca el rival. No hay en saques de banda, córners ni saques de puerta, y un toque del rival lo anula. La IA no se queda en posición adelantada y el pasador lo ve según su visión. Medido: 2-4 por partido (antes de ajustar la IA, 10-13).
- ✅ Cambios:
  - Si empiezas en el banco, botón «IR AL BANCO»: el DT decide si entras y en qué minuto (antes cuanto mejor la relación) y juegas desde ahí.
  - Si eres titular, el DT puede sacarte pasada la hora (pesan su exigencia y tu nota) y entra el suplente de tu puesto.
  - Los minutos reales cuentan; en simulado, el suplente a veces entra un rato.
  - `pruebas/prueba_motor_jugable.tscn` con `CAMBIO=banco` y `CAMBIO=sale`.
- ⬜ Desgaste por tiempo jugado: hecho pero APAGADO, porque bajaba los tiros de 7-8 a 1-4 por partido. Falta ajustarlo.
- ⬜ Más eventos únicos, convocatoria y partidos con la selección, y paso de jugador a DT al retirarse.

**Fase 3 — plan original**
- Fuera de juego, cambios, eventos y selección.
- Transición de jugador a DT.

**Fase 4 — Contenido que falta (2-3 días)**
- Guiños de estadio por club (E9).
- Plantillas fijas de los 128 clubes.
- Banderas del estudio.
- Mini-juego de representantes.
- Modos a medias (E16).

**Fase 5 — Originalidad (en paralelo)**
- Documental de la temporada.
- Ciudad que responde al club.
- Modo foto.
- Dinastías familiares.

**Fase 6 — Lo que depende de ti 🔒**
- PC y Android reales, builds y keystore.
- Licencias.
- Cara 2D→3D (permiso).
- Presentador del sorteo.

**Cómo se mide:**
- Cada fase termina con el banco en 0 fallos, el recorrido de pantallas sin errores y capturas.
- La nota se recalcula con las 7 categorías del informe.
- Objetivo: **75/100 tras las fases 1-4** y **80+** con las 🔒 resueltas.
