# Plan de ruta detallado (13-10-2026 → 15-12-2026, 9 semanas)

Reglas de cada semana: banco «FIN. 0 fallos», capturas antes/después en
`pruebas/capturas/`, este documento al día, commit y push por bloque.
Base: `COMPARACION_MODO_PARTIDO.md`, informe «Análisis Técnico y de Diseño».

## 0. Respuestas a lo que preguntaste

**¿Accedí al gameplay de los otros juegos?** Solo a lo que publican (notas
oficiales y prensa). No puedo ver vídeos ni jugarlos desde aquí. Lo más
concreto que encontré de FC 26 ([Pitch Notes de EA](https://www.ea.com/es/games/ea-sports-fc/fc-26/news/pitch-notes-fc26-gameplay-deep-dive),
[TheSixthAxis](https://www.thesixthaxis.com/2025/07/22/ea-sports-fc-26-deep-dive-explains-the-gameplay-changes/)):
- pases y tiros más rápidos de responder y con más opciones; menos rebotes al rival al defender;
- desmarques y apoyos mejores, en ataque y en defensa;
- portero que elige su posición con aprendizaje automático (solo al colocarse, no al parar);
- pases al hueco rehechos, con mejor elección del receptor;
- preset Competitive (pases más rápidos, más control directo) frente a Authentic (defensas que guardan la posición).

**GTA V frente a nuestra ciudad.** Lo que más pesa en el aspecto de Los Santos es la
**luz**: Rockstar dedicó unos 4 años a su sistema de iluminación
([Fstoppers](https://fstoppers.com/can-gta-5-can-teach-us-to-be-better-photographers)),
y los mods de realismo tocan lo mismo: luz, clima, reflejos y la farola de luz
cálida ([Mein-MMO](https://mein-mmo.de/en/gta-5-wow-photorealism-mod-shines-a-new-light-on-los-santos,129185/),
[FiveMX](https://fivemx.com/realism-beyond/), [GTA5-Mods](https://www.gta5-mods.com/cs/misc/maxedwhitestreetlights)).
Sobre densidad y objetos no encontré fuentes de Rockstar.
- *Alcanzable a nuestra escala:* paleta de color coherente por barrio (no blanco puro),
  suciedad y desgaste en fachadas y asfalto (texturas de mezcla), farolas cálidas,
  hora dorada y niebla de distancia bien ajustadas, reflejos falsos en cristales
  (cubemap barato), más objetos pequeños por manzana (cables, toldos, aires
  acondicionados, grafitis, carteles), tráfico y peatones más densos con LOD.
- *No alcanzable:* fotogrametría, iluminación global en tiempo real, miles de
  objetos únicos hechos a mano y un equipo de cientos de artistas.
- Lo que más cambia hoy: nuestros edificios son blanco liso y el césped es verde
  saturado → eso es lo primero (semana 5).

**¿Qué era «el bloqueo»?** El informe proponía que no todo esté abierto desde el
principio: por ejemplo, la Carrera de Jugador, la ciudad 3D o el modo foto se
«desbloquean» al cumplir hitos (ganar 5 partidos, primera temporada…), para dar
sensación de progreso. Propuesta: hacerlo **opcional** en Ajustes («Todo abierto» /
«Desbloquear jugando»), con «Todo abierto» por defecto.

## 1. Qué falta para un juego lanzable

| Área | Estado | Falta |
|---|---|---|
| Estabilidad | banco verde, sin cuelgues conocidos | prueba larga de 10 temporadas en cada modo, sin errores en la consola |
| Rendimiento | medido en triángulos y CPU | FPS en un móvil y un PC de gama baja reales (🔒 del dueño) |
| Tutorial | existe (970 líneas) | más corto, por capas, que se pueda saltar y repetir, con indicaciones sobre la pantalla |
| Partido jugable | básico completo | táctica en vivo, porteros, presets, cinemáticas, ayudas |
| Interfaz | mucha información | coherencia de estilo, diálogos (hecho el 13-10), accesibilidad (texto grande, daltónicos) |
| Audio | 🔒 música del dueño | efectos de interfaz y ambiente revisados |
| Guardado | funciona | copias de seguridad automáticas y aviso si se corrompe |
| Legal | política ficticia | licencias de recursos y caras reales (🔒 del dueño) |
| Tienda | — | iconos, capturas, descripción, clasificación por edad (🔒 del dueño) |

## 2. Semana por semana

### Semana 1 (13-10 → 19-10) — Presentación y personajes
- [x] Cuadro de diálogo nuevo (placa con nombre, letra a letra, turnos) en la ciudad.
- [x] Teléfono: medio realista (isla, carcasa con sombra, dock) y medio informe (parte del club).
- [x] Personaje del jugador con menos músculo (base esbelta).
- [x] Mismo estilo de diálogo en el estadio (personal, portero, ascensor, decorar). Interiores: semana 6 (aún no hablan).
- [x] Menos músculo en futbolistas (peatones: pendiente, por coste por fotograma).
- [x] Tutorial: negrita real (las letras se montaban).
- [x] Expresiones: parpadeo y gestos de ojos (alegre, sorpresa, enfado, triste) en el DT, el personal del estadio y el goleador. Ojos reales también con la cara clásica.
- [x] Personalización: color de ojos, 14 tonos de piel, gafas redondas y deportivas, pendientes, cadena. Pendiente: más ropa y tatuajes.
- [x] Ciudad sin textos fijos: ⚙ Ajustes de la ciudad, tutorial propio y móvil en la mano con la velocidad.
- [x] Pasadas 2-4 (noche del 13-10): ropa de calle rehecha (la holgura del shader nunca se aplicaba;
  paleta apagada, tela con costuras, vaqueros, cinturón, escote correcto, músculos alisados, zapatos
  mates), pieles sin recortes (manos y caras ya no se queman), material propio para cuerpo de mujer,
  cejas de mujer teñidas, manos relajadas, brazos junto al cuerpo, paso formal, manga corta y tatuajes,
  plano de conversación (ciudad, estadio, interiores), nombres y oficios acordes, 4 oficios nuevos en
  9 idiomas, gente alrededor (reciclaje de peatones), humo del menú quitado de las vistas 3D, rueda de
  prensa con tu personaje 3D, decisiones/junta/móvil con botones en píldora, Mensajes tipo app.

### Semana 2 (20-10 → 26-10) — Partido I: táctica en vivo
- [ ] Panel en pausa y atajos en vivo: formación, mentalidad (defensiva ↔ ofensiva), presión, línea defensiva.
- [ ] La IA cambia de verdad: altura del bloque, distancia entre líneas, quién sube.
- [ ] Prueba en el banco: con presión alta se recupera más arriba (medido).

### Semana 3 (27-10 → 2-11) — Partido II: porteros, pases y presets
- [ ] Portero que se coloca según el ángulo del tiro y sale a los centros.
- [ ] Tiro bajo, pase al hueco con elección del receptor, menos rebotes al defender.
- [ ] Preset Arcade / Realista.
- [ ] Recorrido de la etapa 5 (física): balón, choques, objetos que no se atraviesan.

### Semana 4 (3-11 → 9-11) — Partido III: espectáculo
- [ ] Salida del túnel, himno, foto de equipo, saque inicial con cámara de TV.
- [ ] Prórroga completa y tanda con presentación.
- [ ] Repeticiones con varios ángulos y cámara lenta.
- [ ] Ayudas del modo jugable (indicador de pase, cámara «Be a Pro» ajustable).

### Semana 5 (10-11 → 16-11) — Ciudad hacia «look GTA» posible
- [ ] Paleta por barrio y desgaste en fachadas y asfalto.
- [ ] Farolas cálidas, hora dorada, niebla y cielo revisados.
- [ ] Objetos pequeños por manzana: cables, aires, toldos, grafitis, carteles.
- [ ] Tejados distintos por tipo, patios y jardines (etapa 6).

### Semana 6 (17-11 → 23-11) — Interacción y vida
- [ ] Interacción con objetos: sentarse en bancos, máquinas expendedoras, puertas que se abren, balón suelto en el parque.
- [ ] NPC: más oficios y charlas por barrio y hora, esquivar entre peatones, paraguas con lluvia.
- [ ] Retos semanales tipo «Manager Live».

### Semana 7 (24-11 → 30-11) — Tutorial y primera hora de juego
- [ ] Tutorial por capas: 3 minutos obligatorios, el resto como misiones opcionales.
- [ ] Indicaciones sobre la pantalla (flechas, resaltado) en vez de texto largo.
- [ ] Desbloqueo opcional de modos (ver «el bloqueo»).
- [ ] Pruebas de la primera hora: qué ve un jugador nuevo, sin perderse.

### Semana 8 (1-12 → 7-12) — Ultra pulido de todo
- [ ] Recorrido pantalla por pantalla: textos cortados, colores, tamaños, traducciones.
- [ ] Recorrido de cada etapa 1–6 con capturas.
- [ ] Accesibilidad: tamaño de letra global, modo daltónico, subtítulos.
- [ ] Guardado con copias automáticas.

### Semana 9 (8-12 → 15-12) — Auditoría y lanzamiento
- [ ] Auditoría completa y prueba larga de 10 temporadas.
- [ ] Optimización de gama baja.
- [ ] Lista para el dueño: builds, licencias, tienda (🔒).

Fuera de alcance: multijugador online (requiere servidor).
