# INFORME INTERNO · PUNTOS DE MEJORA (versión extendida)

Complemento de `INFORME_INTERNO.md` (hallazgos medidos y errores). Aquí van **todos los
puntos de mejora, uno por uno, con qué falta y cómo solucionarlo**. 14-10-2026.

**Cómo leerlo.** `M-nnn · Pn · [E]` Título. *Falta*: qué no está o está mal. *Cómo*: la
solución concreta.
- Prioridad: **P0** rompe o engaña al jugador · **P1** se nota mucho · **P2** pulido · **P3** futuro.
- Evidencia **[E]**: **M** medido con una herramienta del repo · **C** leído en el código ·
  **V** visto en una captura · **I** inferido (hay que comprobarlo antes de tocar).
- «Ya hecho hoy» se indica con ✅. No se repite lo ya registrado en `INFORME_INTERNO.md`
  (se cita su id: C-xx, S-xx, K-xx, M-xx…), salvo para ampliarlo.

Corrección a la pasada 1: **el recuento «65 TODO/FIXME» era falso** (casi todo eran
palabras «TODO» en español, «todos»). Marcadores de trabajo pendiente reales: **0**.
`Q-03` queda solo para los 16 `print()`.

---

## A. Estadios y entorno (M-001 … M-032)

- **M-001 · P0 · V** Exterior de estadio = caja gris con cuatro torres. *Falta*: fachada,
  accesos, rampas, escudo gigante, carteles, techo visto desde fuera. *Cómo*: generar la
  fachada según `fachada` (hormigón/ladrillo/metal/vidrio/membrana) con paneles repetidos en
  `MultiMesh`, vanos, columnas y una cornisa; el escudo del club en relieve sobre la entrada.
- **M-002 · P1 · M** Solo 6 formas de estadio para 384 clubes. *Cómo*: añadir `anfiteatro`
  (ladera), `una_grada`, `doble_anillo`, `esquinas_abiertas`, `pista_atletismo_ancha`.
- **M-003 · P1 · I** Las formas no varían de forma continua. *Cómo*: parámetros por club
  (pendiente de grada, altura de techo, retranqueo, ancho de córner) derivados del hash.
- **M-004 · P1 · C** El «estadio real» sólo copia forma/niveles/techo/pista/focos/fachada.
  *Cómo*: añadir al dato: color de pista, color de vallas, dibujo de césped, capacidad
  oficial, año, número de anillos de focos, presencia de pantalla gigante.
- **M-005 · P1 · M** Colores propios de butacas en 47 de 176 estadios reales. *Cómo*:
  ampliar `ASIENTOS` con los 129 restantes (investigar cada uno; los dudosos se dejan con el
  color del club y se marcan «aprox.»).
- **M-006 · P2 · I** Entorno vacío alrededor del estadio (sólo ciudad propia lo tiene).
  *Cómo*: en los estadios rivales, anillo de aparcamiento, árboles, vallas y farolas con kit
  Kenney (`kenney_cars_extra`, `kenney_comercial_extra`).
- **M-007 · P2 · I** Sin variación de entorno por país (palmeras, nieve, montaña de fondo).
  *Cómo*: fondo lejano por país/clima con 3–4 siluetas y `Ambience`.
- **M-008 · P2 · C** Tribunas «falsas» por falta de profundidad en el graderío. *Cómo*: añadir
  vomitorios, barandillas, pasillos, escalones con numeración, anillo de palcos y techo inferior
  con focos y cámaras.
- **M-009 · P2 · V** Sin voladizo/cubierta visible en estadios sin techo. *Cómo*: visera
  parcial por sector con estructura vista (cerchas) en vez de sólo bandeja.
- **M-010 · P2 · I** Sin carteles de pared (patrocinadores, fechas, escudo) fuera del campo.
  *Cómo*: textura de carteles de bajo coste en muros exteriores.
- **M-011 · P1 · C** Marcador/pantalla gigante estática. *Cómo*: contenido vivo (marcador,
  repetición, publicidad, mosaico) en el `SubViewport` ya existente.
- **M-012 · P2 · I** Vallas LED con la misma rotación de marcas inventadas (30). *Cómo*: 60–80
  marcas, orden por patrocinio del club.
- **M-013 · P2 · C** Banderas de esquina/córner genéricas. *Cómo*: colores del club y banderola
  del país, que ondean con el viento del clima.
- **M-014 · P1 · I** Sin diferencia día/noche en el aspecto de la iluminación artificial por
  estadio (halo, corona, torres: sí, pero sin bloom/lente). *Cómo*: conos volumétricos baratos
  (billboards) y reflejo en césped.
- **M-015 · P2 · M** El césped usa 12 dibujos, asignación por hash. *Cómo*: asignar por club
  real (Bernabéu: rayas; Camp Nou: damero…).
- **M-016 · P2 · I** Sin campo de entrenamiento/calentamiento visible fuera del estadio. *Cómo*:
  campo anexo con jugadores calentando (usa los de la banca).
- **M-017 · P1 · C** Túnel de vestuario sólo en +Z. *Cómo*: túnel según forma del estadio
  (lado de la tribuna principal) y salida con ceremonia coherente.
- **M-018 · P2 · C** Banquillos de un solo diseño por preset. *Cómo*: banquillos con
  calefacción, techo, asientos con colores del club (existe `EST_BANQUILLOS`: ampliar).
- **M-019 · P2 · I** Sin zona de prensa/cabinas de TV visibles en el graderío. *Cómo*: cabinas
  con vidrio y personas (usar los NPC de prensa).
- **M-020 · P2 · C** Sin palcos reales (`palcos` existe como instalación). *Cómo*: modelar
  palcos con vidrio, mobiliario y personas del club.
- **M-021 · P2 · I** Sin zona de aficionados visitantes diferenciada. *Cómo*: sector visitante
  con colores del rival y jaula/valla.
- **M-022 · P2 · I** Sin sonido espacial por sector (cantos locales vs visitantes). *Cómo*:
  3–4 `AudioStreamPlayer3D` por tribuna con volumen según ocupación.
- **M-023 · P3 · I** Sin clima visible en el estadio más allá de lluvia/niebla (nieve, polvo,
  calima). *Cómo*: partículas por clima y charcos que reflejan.
- **M-024 · P2 · C** Sombras de la grada sobre el campo no cambian con la hora real del
  partido (sol fijo). *Cómo*: orientación del sol por hora/estación aplicada a `Ambience`.
- **M-025 · P2 · I** Poca variedad de torres de luz (4 esquinas). *Cómo*: techo con corona de
  focos o 6/8 torres según forma.
- **M-026 · P3 · I** Estadios sin nombre dibujado en fachada. *Cómo*: rótulo con tipografía por
  club (fuentes `EST_FONT` ya definidas).
- **M-027 · P2 · I** Sin variación de terreno exterior (cerro, mar, río) según `rasgo`.
  *Cómo*: usar el texto `rasgo` («junto al mar», «a 3.600 m») para elegir fondo y niebla.
- **M-028 · P2 · M** El estadio propio y el rival usan caminos de construcción parecidos pero
  con asimetrías (galería sólo en la ciudad). *Cómo*: prueba automática que compare nodo a nodo
  (existe una manual) y la ejecute el banco.
- **M-029 · P2 · I** Ampliaciones del estadio propio sin animación de obra detallada.
  *Cómo*: grúa y andamio por capítulo con partículas de polvo y operarios.
- **M-030 · P3 · I** Sin estadio nacional/selección con identidad propia. *Cómo*: tabla de
  sedes de selección (Mundial) con arquitectura propia.
- **M-031 · P2 · I** Sin mapa de estadios (galería) para ver todos los del juego. *Cómo*:
  pantalla «Estadios del mundo» que usa el mismo generador a escala.
- **M-032 · P2 · I** Sin ficha de estadio con datos reales (capacidad oficial, año, superficie).
  *Cómo*: campo en `ESTADIO_CLUB` y UI en `pantalla_club_estadio`.

## B. Público y ambiente (M-033 … M-050)

- **M-033 · P1 · V** Los hinchas comparten malla por pose; sólo cambia color de camiseta.
  *Falta* ropa/pelo propios. *Cómo*: 3 variantes de torso (camiseta, chaqueta, bufanda) y 4
  peinados con `instance_custom_data` y `hinchada.gdshader`.
- **M-034 · P1 · I** Pelo/piel por azar sin población real. *Cómo*: distribución de tonos de
  piel por país (tabla) en vez de uniforme.
- **M-035 · P1 · I** Sin bufandas/banderas/camisetas del club en la mano. *Cómo*: 2 mallas
  pequeñas animadas por shader (onda) y densidad por «peña» de la hinchada.
- **M-036 · P2 · C** Animación del público: balanceo uniforme + saltos. *Cómo*: ola, canto
  coordinado por sector y reacción al gol con onda de saltos desde el sector del gol.
- **M-037 · P2 · I** Sin sector «barra brava»/torcida con comportamiento diferente (de pie,
  bengalas, tambores). *Cómo*: sector ultra con pose «de pie» y partículas de humo de color.
- **M-038 · P2 · I** Hinchas sentados con piernas invisibles (se cortan en la cadera). *Cómo*:
  aceptable por la butaca, pero comprobar vista cenital; añadir muslos de baja malla.
- **M-039 · P2 · M** Tres niveles de detalle; el salto «cerca→medio→lejos» puede verse.
  *Cómo*: mezclar por dithering/escala o añadir nivel intermedio.
- **M-040 · P2 · I** Sin personas del club/ciudad reconocibles en primeras filas (pedido).
  *Cómo*: 10–20 NPC reales (presidente, mascota, utilero, vecinos) en filas VIP con
  `PersonaRealista`.
- **M-041 · P2 · I** Sin niños, familias ni asistentes en sillas de ruedas. *Cómo*: mallas
  escaladas y accesibles en zonas de acceso.
- **M-042 · P2 · I** Ocupación = reputación, no asistencia del partido. *Cómo*: ocupación por
  sector según `Hinchada` y precio de entrada.
- **M-043 · P2 · I** Sin diferencia de público por competición (final vs liga). *Cómo*:
  decoración especial (mosaico, confeti) en finales.
- **M-044 · P2 · C** Gol local: ceremonia de público única. *Cómo*: 3–4 variantes de
  celebración por sector y retardo escalonado.
- **M-045 · P2 · I** Sin reacción del público a decisiones (silbidos al árbitro, VAR). *Cómo*:
  evento `reaccion_publico(tipo)` que cambia pose y sonido.
- **M-046 · P3 · I** Sin multitudes en accesos, tienda y museo del estadio. *Cómo*: flujo de
  NPC en el estadio propio antes y después del partido.
- **M-047 · P2 · M** Colores de hincha con 14 tonos (hoy). *Cómo*: paleta por club
  (local, visitante, neutros), 60 % club.
- **M-048 · P2 · I** Fotógrafos/camarógrafos pocos y repetidos. *Cómo*: 6–8 con rutas.
- **M-049 · P2 · I** Sin aficionados que se levantan/siguen el balón con la cabeza. *Cómo*:
  rotación de cabeza hacia el balón en las 3 primeras filas (cheap por shader).
- **M-050 · P3 · I** Sin streamers de papel, confeti ni bengalas. *Cómo*: `GPUParticles3D`
  con eventos del motor (gol, saque inicial).

## C. Camisetas, escudos y marcas (M-051 … M-078)

- **M-051 · P1 · V** El escudo en la camiseta mide ~8 cm y es plano. *Cómo*: tamaño 9–10 cm
  con relieve (normal), y variante bordada con hilo (rugosidad distinta).
- **M-052 · P1 · V** Camiseta pintada sin tejido. *Cómo*: normal map de malla de poliéster +
  textura de microagujeros en zona lateral.
- **M-053 · P1 · I** Cuello y puños sólo por color. *Cómo*: geometría ligera de cuello (V/
  redondo/polo) y puños en `RopaSeparada` por LOD.
- **M-054 · P1 · C** Ropa con volumen sólo en retratos (K-02). *Cómo*: activar por distancia
  (≤ 15 m) con `visibility_range` y ocultar la pintada duplicada.
- **M-055 · P1 · I** Sin arrugas dinámicas según animación. *Cómo*: blend shapes de 3 poses
  (correr, estirar, caer) o normal maps animados.
- **M-056 · P2 · I** Sin sudor/barro/lluvia en la camiseta. *Cómo*: uniform `mojado`/`barro`
  según clima y minutos jugados.
- **M-057 · P1 · C** Marca de ropa genérica (tick). *Cómo*: 6–8 fabricantes inventados con
  logo propio, uno por club, reflejado en camiseta, pantalón, medias y balón.
- **M-058 · P1 · M** 30 marcas de patrocinio (K-03). *Cómo*: 70 marcas con categoría, color y
  logotipo procedural (`Marca`).
- **M-059 · P1 · M** Reparto de marcas sesgado (arreglado el hash hoy, ✅). *Cómo*: añadir
  prueba que compruebe que ninguna marca supera 2× la media.
- **M-060 · P2 · I** Patrocinio fijo por club entre temporadas, sin contratos de IA que
  cambien. *Cómo*: renovar/cambiar patrocinador de clubes IA cada 2–4 años con noticia.
- **M-061 · P2 · I** Sin patrocinador en la parte trasera del pantalón ni en las medias.
  *Cómo*: zonas `short_trasero` y `medias` (existe `short`).
- **M-062 · P1 · M** Escudos: 188 combinaciones únicas para 384 clubes (C-03). *Cómo*: ampliar
  `ESCUDOS`, y para el resto exigir unicidad forma+patrón+símbolo por liga (hash con
  reintento).
- **M-063 · P1 · V** Escudos reales sólo 26 (7 %). *Cómo*: subir a ~120 con rasgos
  documentados en `estadios_reales.py` (nunca el dibujo oficial).
- **M-064 · P2 · V** Falta ornamento reconocible (león, águila, estrella, castillo,
  balón, barco). *Cómo*: biblioteca de 40 símbolos vectoriales simples en `escudo.gd`.
- **M-065 · P2 · I** Texto/iniciales ilegibles <24 px. *Cómo*: prueba que rasterice a 24 px y
  mida contraste.
- **M-066 · P2 · I** Escudo sin variante monocroma (para periódico, marcador). *Cómo*:
  `Escudo.mono(c)`.
- **M-067 · P2 · I** Sin escudo animado en el marcador al gol. *Cómo*: pulso y brillo.
- **M-068 · P1 · M** Diseño de camiseta por hash en el 63 % de clubes (ya hay tabla para 66).
  *Cómo*: ampliar `CAMISETAS` y, para inventados, derivar del color y de la *cultura* del país
  (rayas en ESP/ITA, lisas en ENG, banda en ARG…).
- **M-069 · P2 · M** 12 diseños con reparto casi uniforme (C-06). *Cómo*: pesos.
- **M-070 · P2 · I** Sin segunda/tercera camiseta con diseño propio. *Cómo*: tercera por tabla
  y generador (inversión + patrón alterno).
- **M-071 · P2 · C** Portero: color por contraste, sin diseño. *Cómo*: 6 diseños de portero y
  guantes.
- **M-072 · P2 · I** Árbitros siempre iguales. *Cómo*: 3 colores de árbitro por liga (regla
  de contraste con ambos equipos).
- **M-073 · P2 · I** Sin brazalete de capitán visible a distancia. *Cómo*: aumento de contraste
  + marca en rótulo.
- **M-074 · P2 · C** Medias/pantalón: diseño correcto pero sin franjas del fabricante. *Cómo*:
  detalles laterales (tres rayas inventadas por fabricante).
- **M-075 · P2 · I** Dorsal sin fuente propia por club. *Cómo*: 5 fuentes de número.
- **M-076 · P3 · I** Sin parches de competición (campeón, copa). *Cómo*: parche manga
  según títulos.
- **M-077 · P2 · V** Retrato con camiseta de volumen pero sin patrocinio en pecho visible.
  *Cómo*: encuadre un poco más abierto y mayor resolución del sponsor.
- **M-078 · P2 · I** Foto real de equipación sólo con pack real (C-08). *Cómo*: mantener; pero
  acercar el procedural con detalles comunes (cuello, tira) para que no se note la diferencia.

## D. Jugadores, caras, cuerpos y animaciones (M-079 … M-112)

- **M-079 · P1 · M** Retrato real 13 % (base real). *Cómo*: continuar descarga de faltantes
  (permitir red a Wikimedia), pipeline ya hecho.
- **M-080 · P2 · I** Fotos agachadas aún oscuras/deformadas. *Cómo*: re-detección con otra
  malla (MediaPipe en modo estático alto) y corrección de exposición local.
- **M-081 · P1 · C** Todos con el mismo cuerpo base. *Cómo*: 3–4 somatotipos con escala
  de hombros/cintura/piernas por puesto (blend shapes o escala por hueso).
- **M-082 · P2 · I** Altura sólo por escala global. *Cómo*: proporciones de torso/piernas
  variables.
- **M-083 · P2 · I** Sin tatuajes/cicatrices por jugador salvo civiles. *Cómo*: capas de
  decal por jugador (hash) y por país.
- **M-084 · P2 · M** Biblioteca de caras = 72 mezclas. *Cómo*: ampliar a ~300 por etnia/edad
  con la malla ya existente (MOTOR_CARAS).
- **M-085 · P2 · I** Envejecimiento visual de jugadores (canas, arrugas) no ligado a `edad`.
  *Cómo*: mapa de edad en el shader de piel y pelo.
- **M-086 · P2 · I** Expresiones faciales limitadas a `Expresion` básica. *Cómo*: blend shapes
  de 8 emociones y disparadores por evento (gol, falta, lamento).
- **M-087 · P2 · I** Sin parpadeo/respiración idle variados. *Cómo*: capas aditivas.
- **M-088 · P1 · I** Pelo con 30 cortes pero poca variación de color/aspecto por país. *Cómo*:
  tabla por país (probabilidades).
- **M-089 · P2 · I** Barbas/cejas por capas apagadas (manchas). *Cómo*: revisar con la
  biblioteca de barbas modernas o mallas de pelo corto.
- **M-090 · P2 · I** Guantes de portero sólo color. *Cómo*: geometría de guante.
- **M-091 · P1 · M** Botines: variedad añadida, pero sin modelos distintos por forma. *Cómo*:
  3 mallas de botín (clásico, calcetín, bota alta).
- **M-092 · P2 · I** Cordones/tacos sin geometría. *Cómo*: texturas de relieve.
- **M-093 · P2 · I** Sin canilleras/vendas/cintas visibles. *Cómo*: accesorios aleatorios
  (`acc_*` ya existe: aplicar a jugadores del partido).
- **M-094 · P1 · C** Animación de caminata del DT: 6 estilos (✅). *Falta* para jugadores y
  NPC. *Cómo*: estilos por personalidad (confiado, cansado, apurado) en `PeatonQ`.
- **M-095 · P1 · C** 335 clips; muchos sin uso en partido. *Cómo*: auditoría automática de
  clips usados por el motor y plan para los 100 que faltan (regates, gestos, discusión).
- **M-096 · P2 · I** Transiciones entre clips con mezcla fija 0,25 s. *Cómo*: tiempos por par
  de estados y *inertialization*.
- **M-097 · P2 · I** Retarget con pies que patinan. *Cómo*: IK de pies (existe `Skeleton`
  IK?: comprobar) y *foot locking*.
- **M-098 · P2 · I** Sin IK de mirada (cabeza sigue balón). *Cómo*: `LookAtModifier3D`.
- **M-099 · P2 · I** Cuerpos sin colisión entre brazos/piernas (solapes sólo en XZ).
  *Cómo*: cápsulas en 3D para pecho/pierna.
- **M-100 · P2 · I** Sin respiración/cansancio visible (manos a rodillas). *Cómo*: capa
  aditiva por energía.
- **M-101 · P2 · C** Celebraciones por rasgo (ya) pero sólo 2/3 propias. *Cómo*: ampliar a
  10 por rasgo y coreografías grupales (3 variantes).
- **M-102 · P2 · I** Sin reacciones de banquillo coordinadas. *Cómo*: eventos para gol,
  tarjeta, lesión.
- **M-103 · P2 · I** Lesiones sin animación específica. *Cómo*: 3 clips (tobillo, muscular,
  golpe) y camilla/médicos.
- **M-104 · P2 · I** Cambios de jugador sin animación (entra/sale). *Cómo*: panel de cambio
  con palmada y cartel.
- **M-105 · P2 · I** Sin tarjetas con ceremonia de árbitro detallada. *Cómo*: `arbitro_*` ya
  existe; sumar protesta de jugadores.
- **M-106 · P1 · I** Árbitro con sólo gestos básicos. *Cómo*: señales (ventaja, mano, fuera de
  juego) enlazadas al motor.
- **M-107 · P2 · I** Asistentes de línea sin carrera real. *Cómo*: seguir la línea del
  penúltimo defensor.
- **M-108 · P2 · I** Mascotas con animación limitada. *Cómo*: 6 clips y rutas.
- **M-109 · P2 · I** Niños de ceremonia con una misma malla. *Cómo*: variaciones.
- **M-110 · P2 · I** Sin voces/murmullos de jugadores. *Cómo*: sonidos breves sintetizados
  por acción (hipo, grito, ánimo).
- **M-111 · P3 · I** Sin modo foto con poses y expresión (existe `ModoFoto`). *Cómo*: tomar
  poses del catálogo y editor de expresión.
- **M-112 · P2 · I** Sin avatar del usuario en el estadio como jugador (carrera) con su propio
  cuerpo. *Cómo*: usar `CreadorPersonaje` en partido de Carrera.

## E. Partido: física, IA, controles, cámara, presentación (M-113 … M-166)

- **M-113 · P1 · M** Sesgo de local (M-01). *Cómo*: sonda N≥30 y calibración explícita.
- **M-114 · P1 · M** Teletransportes del balón en sonda (M-02). *Cómo*: separar reposiciones.
- **M-115 · P1 · M** Giros >720°/s (465). *Cómo*: limitar velocidad angular y suavizar.
- **M-116 · P1 · C** Sin duelos con contacto (M-03). *Cómo*: zonas de contacto y empuje.
- **M-117 · P1 · C** Faltas sin lógica de contacto real (sólo azar). *Cómo*: falta si el
  defensor llega con velocidad/ángulo/golpe al pie.
- **M-118 · P1 · C** Fuera de juego sólo por posición en el instante (✅ base). *Cómo*: línea
  visible, asistente y VAR con replay de línea.
- **M-119 · P1 · I** Penales: el portero «decide una vez» pero sin lectura del lanzador.
  *Cómo*: sesgo por hábito del lanzador y fintas.
- **M-120 · P2 · C** Córners con 3 variantes. *Cómo*: jugadas ensayadas (corto, segundo palo)
  de `CatalogoJugadas`.
- **M-121 · P2 · I** Tiros libres: barrera simple. *Cómo*: barrera variable, saltos, rosca por
  atributo.
- **M-122 · P2 · I** Sin saque de banda largo/estratégico. *Cómo*: jugadores con atributo.
- **M-123 · P1 · C** IA: no hay trampa de fuera de juego, cobertura ni basculación (M-04).
  *Cómo*: línea defensiva común con subida/bajada.
- **M-124 · P1 · I** Pressing por zonas sin gatillos. *Cómo*: gatillo (mal control, pase
  atrás) para activar presión.
- **M-125 · P2 · I** Sin tácticas de medio campo (doble pivote, falso 9). *Cómo*: roles con
  comportamiento (`slot_code`) y pizarra.
- **M-126 · P2 · I** Cambios de IA por cansancio (60/70/80') fijos. *Cómo*: por forma, tarjetas,
  marcador y rival.
- **M-127 · P2 · I** Sin gestión de tiempo (perder tiempo, acelerar). *Cómo*: instrucción
  `instr_tiempo` más profunda.
- **M-128 · P2 · I** Portero con salidas sólo en mano a mano. *Cómo*: cierre de ángulo
  dinámico y salidas aéreas.
- **M-129 · P2 · I** Sin lanzamientos de larga distancia ni centros desde banda con calidad
  distinta. *Cómo*: parámetro `precisión` por atributo.
- **M-130 · P2 · C** Controles FC mapeados (65+ combinaciones) sin tutorial interactivo.
  *Cómo*: modo práctica con retos por mecánica.
- **M-131 · P2 · I** Ayudas de asistencia (pase/tiro) con 3 niveles. *Cómo*: perfiles
  «Arcade/Semi/Manual» con presets.
- **M-132 · P2 · I** Sin repetición manual del usuario. *Cómo*: botón de replay de las
  últimas 10 s con cámara libre (`Repeticion` ya graba).
- **M-133 · P1 · C** Cámara TV sin zoom automático al área. *Cómo*: ya tiene FOV por área;
  añadir plano cerrado en penales y córners.
- **M-134 · P2 · I** Sin cámaras de repetición cinematográficas (grúa, dron). *Cómo*:
  3 planos de repetición alternativos.
- **M-135 · P2 · I** Sin cámara de gol del cuarto árbitro/línea. *Cómo*: cámara fija en el
  arco con latencia.
- **M-136 · P2 · C** HUD del partido con FC-style indicadores; sin heatmap/estadísticas a
  pedido. *Cómo*: panel `Tab` con xG, mapa de pases, posesión por zonas.
- **M-137 · P2 · I** Sin xG ni xA. *Cómo*: modelo simple por distancia/ángulo/tipo y mostrarlo
  en el resumen.
- **M-138 · P1 · I** Ritmo del partido ≈ 54 s/s vs 11 s/s (M-07). *Cómo*: preset
  «Realista» y condensar cinemáticas.
- **M-139 · P2 · I** Tiempo añadido con base real pero sin descuentos por lesión visibles.
  *Cómo*: cartel del cuarto árbitro.
- **M-140 · P2 · C** Descanso: charla de medio tiempo con opciones; sin vestuario 3D dinámico.
  *Cómo*: cinemática breve en el vestuario con la plantilla.
- **M-141 · P2 · I** Resumen de partido sin mapa de calor ni valoraciones por jugador
  detalladas. *Cómo*: `resumen_partido` con puntuaciones y momentos clave.
- **M-142 · P2 · I** Rueda de prensa posterior no enlazada con incidentes del partido.
  *Cómo*: temas dinámicos (árbitro, VAR, lesión).
- **M-143 · P2 · I** Sin clima dinámico durante el partido (tormenta repentina). *Cómo*: cambio
  de clima en vivo con efectos.
- **M-144 · P2 · I** Campo se desgasta (barro) sin visualización. *Cómo*: textura de desgaste
  por zonas (áreas, bandas).
- **M-145 · P2 · I** Sin marcas de césped (pisadas, deslizamientos). *Cómo*: decals simples.
- **M-146 · P2 · I** Balón con skins pero sin desgaste/mojado. *Cómo*: uniform.
- **M-147 · P1 · M** Hitbox del balón vs cuerpo: 0 casos atravesando (sonda); pero colisión
  balón-pierna es por distancia 2D. *Cómo*: cápsulas 3D en pies y cabeza.
- **M-148 · P2 · I** Sin rebotes contra postes/larguero realistas con física propia. *Cómo*:
  `poste` ya cuenta; modelar rebote con coeficientes y giro.
- **M-149 · P2 · I** Red del arco rígida. *Cómo*: shader de ondulación al gol.
- **M-150 · P2 · I** Sin balones adicionales (calentamiento, reserva). *Cómo*: balones decorativos.
- **M-151 · P2 · C** Muro de pruebas: `sonda_fisica` no distingue reposiciones. *Cómo*: arreglar
  (M-114) y añadirla al banco con umbrales.
- **M-152 · P2 · I** Sin modo de entrenamiento libre (probar controles). *Cómo*: campo vacío con
  portero y conos.
- **M-153 · P2 · I** Sin modo multijugador local. *Cómo*: dos mandos con `MotorJugable.usuario`
  doble.
- **M-154 · P3 · I** Sin online. *Cómo*: fuera de alcance; documentarlo.
- **M-155 · P2 · I** Penal de usuario con barra, sin variantes por pierna. *Cómo*: zurdo/diestro.
- **M-156 · P2 · I** Sin decisión de capitán (protesta). *Cómo*: `capitan` habla con árbitro.
- **M-157 · P2 · I** Sin cantos/anuncios del estadio (megafonía con alineaciones). *Cómo*: voz
  sintetizada o textos con sonido.
- **M-158 · P2 · I** Presentación: 180 s en FC; aquí variable. *Cómo*: omitible y configurable
  por partido (ya hay ajustes).
- **M-159 · P2 · I** Sin himno por país con partitura procedural. *Cómo*: melodías cortas.
- **M-160 · P2 · I** Sin saludo protocolar/pre-partido (capitanes, sorteo de campo). *Cómo*:
  ceremonia de sorteo con moneda.
- **M-161 · P2 · I** Sin mini-partidos de selección con identidad. *Cómo*: ver selecciones.
- **M-162 · P2 · C** Estadísticas del motor (tiros, pases) sin exportar. *Cómo*: CSV por partido
  para análisis.
- **M-163 · P2 · I** Sin modo «Director técnico automático» configurable (IA del usuario).
  *Cómo*: autopiloto con perfil.
- **M-164 · P2 · I** Sin modo espectador con cámara libre. *Cómo*: cámara libre ya posible;
  exponer en UI.
- **M-165 · P2 · I** Sin reglas especiales (prórroga, penales, gol de oro por competición).
  *Cómo*: `Copa` ya tiene final; añadir prórroga jugable.
- **M-166 · P3 · I** Sin partidos de fútbol sala/playa/mujeres (género existe). *Cómo*: fuera
  de alcance; documentar.

## F. Ciudad, vehículos, metro, interiores (M-167 … M-206)

- **M-167 · P1 · C** Calzadas = cajas de asfalto con marcas propias; Kenney sólo accesorios
  (V-02). *Cómo*: losetas `road-*` por tramo y cruce.
- **M-168 · P2 · I** Sin rotondas. *Cómo*: `road-roundabout` en 2–3 cruces de avenida.
- **M-169 · P2 · C** Puente sin pilares Kenney. *Cómo*: `bridge-pillar` bajo cada vano.
- **M-170 · P2 · I** Sin semáforos peatonales con botón. *Cómo*: interacción E.
- **M-171 · P1 · I** Tráfico sin comportamiento complejo (adelantar, ceder en cruce). *Cómo*:
  máquina de estados por vehículo.
- **M-172 · P1 · I** Colisiones del coche del usuario con NPC/vehículos sólo círculos. *Cómo*:
  daño, rebote y multa.
- **M-173 · P2 · I** Sin sonido de motor/marchas/derrape. *Cómo*: `AudioStreamGenerator` con
  RPM.
- **M-174 · P2 · I** Interior de coche sin modelo (salpicadero 2D). *Cómo*: modelar cabina
  simple con volante 3D y retrovisor.
- **M-175 · P2 · I** Sin faros ni luces de freno encendidos por hora. *Cómo*: emisión por
  material y conos de luz.
- **M-176 · P2 · I** Sin tipos de vehículo (moto, bus conducible, camión). *Cómo*: tabla de
  parámetros por vehículo.
- **M-177 · P2 · I** Sin gasolinera/aparcamiento/lavado. *Cómo*: minijuegos de ciudad.
- **M-178 · P2 · I** Sin minimapa. *Cómo*: `SubViewport` cenital en HUD o móvil.
- **M-179 · P2 · I** GPS/ruta al club. *Cómo*: ruta por `camino_entre` ya existente.
- **M-180 · P2 · I** Metro: sin vendedores/música/anuncios. *Cómo*: NPC y audio por estación.
- **M-181 · P2 · I** Sin pasajeros que suben/bajan reales en tren. *Cómo*: NPC en puertas.
- **M-182 · P2 · I** Sin tarjeta de transporte ni coste. *Cómo*: economía menor en `Mi Vida`.
- **M-183 · P2 · C** Peatones: 34 máx; sin rutinas por hora. *Cómo*: horario (trabajo, comida,
  descanso) y puntos de interés.
- **M-184 · P2 · I** Sin NPC con nombre y memoria (te reconocen). *Cómo*: 30 vecinos fijos
  con estado.
- **M-185 · P2 · I** Diálogos por oficio (hecho) pero sin ramas ni consecuencias. *Cómo*:
  eventos con efecto en ánimo/hinchada.
- **M-186 · P2 · I** Interiores: 15 salas; edificios entrables «la mayoría» sin mobiliario
  único. *Cómo*: 3 variantes de interior por arquetipo.
- **M-187 · P2 · I** Casas sin habitantes ni rutinas. *Cómo*: familia con horarios.
- **M-188 · P2 · I** Sin tiendas con compra real (ropa, balones). *Cómo*: `Comercial` conectar
  a tiendas físicas.
- **M-189 · P2 · I** Sin bares/restaurantes con minijuego. *Cómo*: cafetería con eventos.
- **M-190 · P2 · I** Sin clima dinámico en la ciudad (lluvia con charcos, reflejos). *Cómo*:
  ya hay precipitación; añadir charcos y reflejos baratos (SSR off).
- **M-191 · P2 · I** Sin ciclo día/noche más allá del slider. *Cómo*: reloj real y farolas
  automáticas (hay `_ciclo_activo`).
- **M-192 · P2 · I** Aceras/pavimentos: 3 texturas. *Cómo*: variación por barrio.
- **M-193 · P2 · I** Sin vegetación variada (setos, flores) más allá de árboles. *Cómo*:
  más mallas y MultiMesh.
- **M-194 · P2 · I** Cielo sin nubes dinámicas. *Cómo*: capas de nubes con ruido.
- **M-195 · P2 · I** Agua del río/mar plana. *Cómo*: shader de olas y espuma.
- **M-196 · P2 · I** Botes sin sonido/estela. *Cómo*: partículas de estela.
- **M-197 · P2 · I** Autopista sin peajes ni estaciones. *Cómo*: props.
- **M-198 · P2 · I** Aeropuerto/estación de tren inexistentes (no hay viajes). *Cómo*: viaje
  rápido a partidos de visita con cinemática.
- **M-199 · P2 · I** Sin señales de tráfico reales (límites, ceda). *Cómo*: props ya en parte
  (STOP/ceda); límites de velocidad con multa.
- **M-200 · P2 · I** Sin policía/multas. *Cómo*: NPC y evento.
- **M-201 · P2 · I** Sin accidentes/eventos aleatorios. *Cómo*: pequeño sistema de eventos
  de calle.
- **M-202 · P2 · C** Galería subterránea sólo en la ciudad. *Cómo*: documentar; OK.
- **M-203 · P2 · I** Sin colisión/oclusión de sonido en interiores. *Cómo*: bus con filtro
  paso bajo dentro.
- **M-204 · P2 · I** LOD de edificios lejanos con ventanas (cristal) pero sin siluetas
  diferenciadas. *Cómo*: billboard por tipo.
- **M-205 · P2 · M** `ciudad_expansion.gd` 2.321 líneas y `city_builder.gd` 4.687. *Cómo*:
  dividir por barrios/sistemas (Q-01).
- **M-206 · P2 · I** Sin editor de ciudad más allá de terrenos/negocios. *Cómo*: colocar
  edificios con cuadrícula.

## G. Gestión del club (M-207 … M-262)

Módulos revisados: `Mercado`, `MercadoAvanzado`, `Negociacion`, `Cesiones`, `Contratos`,
`Finanzas`, `Banco`, `Insolvencia`, `Comercial`, `Auspicio`, `Instalaciones`, `Academia`,
`Cantera`, `Ojeadores`, `Staff`, `Entrenamiento`, `Maestria`, `Medico`, `Vestuario`,
`Directiva`, `Junta`, `Politica`, `Prensa`, `Redes`, `Federacion`, `LeyesPais`, `Continental`,
`Selecciones`, `Hinchada`, `Ciudad`, `Gente`, `Trabajadores`.

- **M-207 · P1 · M** Plantillas de 25 en todos los clubes (C-05). *Cómo*: 22–32 por reputación y
  cantera; revisar chequeos que dependan de 25.
- **M-208 · P1 · M** Caja del club propio crece de forma casi monótona (prueba larga: la caja pasa de 13–25 M a 56–78 M
  en 10 años en las semillas vistas). *Falta*: tensión económica a largo plazo. *Cómo*: costes de
  vida del club (inflación de salarios, mantenimiento de estadio, impuestos por ciudad) que
  crezcan con el éxito; eventos de crisis.
- **M-209 · P2 · M** La prueba larga sólo comprueba que no hay errores, no el equilibrio.
  *Cómo*: extender con métricas (títulos por club, quiebras, salarios medios, edad media)
  y alertas si salen de rangos.
- **M-210 · P1 · I** Mercado: precios por reputación sin burbujas ni crisis. *Cómo*: ciclos de
  mercado (años de gasto/ajuste) ligados a `Eras`.
- **M-211 · P2 · I** Cláusulas de rescisión: sin «cláusulazo» automático de IA. *Cómo*: IA que
  pague cláusulas cuando le conviene.
- **M-212 · P2 · I** Negociación 346 líneas sin pruebas directas (módulo `Negociacion` sin
  referencias en banco). *Cómo*: pruebas de aceptación/rechazo y contraofertas.
- **M-213 · P2 · I** Sin agentes con personalidad reflejada en comisiones (hay 4 perfiles).
  *Cómo*: historial con cada agente y trato preferente.
- **M-214 · P2 · I** Cesiones con opción de compra obligatoria sin seguimiento de rendimiento.
  *Cómo*: bonus por partidos y recuperación.
- **M-215 · P2 · I** Mercado de invierno y verano sin ventanas diferenciadas (¿existe?). *Cómo*:
  comprobar `Calendario` y mostrar cuenta atrás.
- **M-216 · P2 · I** Fichajes de IA entre clubes poco visibles. *Cómo*: noticias de traspasos
  relevantes (top 10 por valor) cada semana.
- **M-217 · P2 · I** Sin fichajes libres por fin de contrato anticipados (precontrato). *Cómo*:
  firma desde los 6 meses restantes.
- **M-218 · P2 · I** Sin límite de fair play financiero explícito (hay aviso). *Cómo*: sanciones
  graduales y regla de ratio salarial.
- **M-219 · P1 · C** `Banco` e `Insolvencia` existen pero con pocos eventos de gravedad. *Cómo*:
  escalera de crisis (embargo de jugadores, descenso administrativo, venta forzosa).
- **M-220 · P2 · I** Sin intereses variables según reputación y mercado. *Cómo*: tasa dinámica.
- **M-221 · P2 · I** Impuestos y derechos de TV simplificados. *Cómo*: tabla por país con
  reparto proporcional a ranking.
- **M-222 · P2 · I** Venta de entradas: precio único. *Cómo*: precios por sector y por rival
  (clásico).
- **M-223 · P2 · I** Abonos/socios: modelo simple. *Cómo*: renovación, lista de espera,
  reclamos por mal servicio.
- **M-224 · P2 · I** Tienda/merchandising ligado a ventas de camisetas por ídolo. *Cómo*:
  ventas por jugador estrella.
- **M-225 · P2 · I** `Comercial` zonas de patrocinio manual para el usuario; IA sin
  negociación visible. *Cómo*: noticias de contratos de IA.
- **M-226 · P2 · I** Naming del estadio sin historia (renombrar cada contrato). *Cómo*: nombre
  histórico/comercial con transición.
- **M-227 · P2 · I** Instalaciones: 19 obras; sin mantenimiento ni desgaste. *Cómo*: nivel de
  conservación y costes.
- **M-228 · P2 · I** Obras sin imprevistos (retrasos, sobrecostes, permisos). *Cómo*: eventos
  y barras de riesgo.
- **M-229 · P2 · I** Academia: sin variedad de métodos pedagógicos. *Cómo*: planes de
  formación con efecto en atributos.
- **M-230 · P2 · I** Cantera 1.422 líneas con representantes; pocos hitos narrativos. *Cómo*:
  historias de juveniles (lesión, mudanza, sueño) con elecciones.
- **M-231 · P2 · I** Ojeadores con sesgo regional (ya) sin informes visuales (campo vs
  vídeo). *Cómo*: informes con rasgos y confianza.
- **M-232 · P2 · I** Staff de 6 puestos sin personalidad ni relaciones entre sí. *Cómo*:
  química y conflictos.
- **M-233 · P2 · I** Entrenamiento 1.117 líneas; sesiones sin visualización 3D. *Cómo*:
  mini-escenas de entrenamiento (rondos, tiros).
- **M-234 · P2 · I** Maestrías con efecto en partido poco visible. *Cómo*: iconos y registro
  en el resumen.
- **M-235 · P1 · I** Lesiones: duración y recaídas ok; sin prevención visible (carga acumulada).
  *Cómo*: indicador de riesgo por jugador.
- **M-236 · P2 · I** Vestuario 1.436 líneas con grupos; sin conflictos con consecuencias en
  campo (discusión visible). *Cómo*: eventos en partido.
- **M-237 · P2 · I** Capitanías: elección sin votación. *Cómo*: voto de plantel.
- **M-238 · P1 · I** Directiva: objetivos con confianza; despido sin cinemática. *Cómo*:
  escena de despido y salida del club.
- **M-239 · P2 · I** Junta/accionistas: sin asambleas jugables. *Cómo*: minijuego de asamblea.
- **M-240 · P2 · C** `Politica` ficticia (decisión legal): mantener sin real. *Cómo*:
  revisar contenidos con una lista de palabras prohibidas en CI.
- **M-241 · P1 · I** Prensa 2.541 líneas (la mayor del núcleo): `resolver` 476 líneas. *Cómo*:
  dividir por tipo de pregunta y añadir pruebas por rama.
- **M-242 · P2 · I** Titulares dinámicos: 129 sólo en EN/PT (I-01). *Cómo*: traducir.
- **M-243 · P2 · I** Redes sociales: seguidores y comentarios; sin bots/trolls/tendencias.
  *Cómo*: eventos de tendencia con picos.
- **M-244 · P2 · I** Sin entrevistas en TV con escena 3D variada (existe rueda de prensa 3D).
  *Cómo*: más sets (estudio, pasillo).
- **M-245 · P2 · I** Federación 999 líneas con reglas; votaciones sin presentación. *Cómo*:
  pantalla de sesión.
- **M-246 · P2 · I** `LeyesPais` (cupos) ok; sin visualización de «alineación indebida» en el
  once. *Cómo*: icono rojo en la pizarra.
- **M-247 · P2 · I** Competiciones continentales (620 líneas) sin sorteo animado por fases.
  *Cómo*: reutilizar `Sorteo3D`.
- **M-248 · P2 · I** Mundial de clubes/selecciones (1.012 líneas) con pocos modos. *Cómo*:
  concentraciones y bajas por selección.
- **M-249 · P2 · I** Hinchada con segmentos; sin rivalidades por barrio. *Cómo*: clásicos con
  historia (`HistoriaClub`).
- **M-250 · P2 · I** Ciudad y club: terrenos/negocios; economía simplificada. *Cómo*: ingresos
  por negocios dependientes de ocupación del estadio.
- **M-251 · P2 · I** Gente del club (10 personas) sin crecimiento de relaciones. *Cómo*:
  afinidad y misiones.
- **M-252 · P2 · I** Trabajadores/instalaciones con eventos; sin huelgas/negociación. *Cómo*:
  eventos laborales.
- **M-253 · P2 · I** Licencia de entrenador: exámenes; sin cursos con coste y tiempo. *Cómo*:
  calendario de cursos.
- **M-254 · P2 · I** Vida del DT (bienestar, casa, familia): sin impacto en rendimiento
  fuerte. *Cómo*: modificadores por estrés/sueño.
- **M-255 · P2 · I** Retos/logros: 1.132 líneas (`Logros`) **sin referencias en banco**.
  *Cómo*: pruebas de desbloqueo por tipo.
- **M-256 · P2 · I** Álbum/museo sin colecciones jugables. *Cómo*: cromos con rarezas.
- **M-257 · P2 · I** Historia del club generada; sin línea de tiempo interactiva. *Cómo*:
  timeline con hitos y fotos.
- **M-258 · P2 · I** Documental de temporada: guion fijo. *Cómo*: más capítulos por eventos.
- **M-259 · P2 · I** Clima en partidos con efecto menor. *Cómo*: efecto en balón y desgaste.
- **M-260 · P2 · I** Dificultad: 3 niveles simples. *Cómo*: dificultad adaptativa por
  racha.
- **M-261 · P2 · I** Sin modo historia/campaña guiada. *Cómo*: escenarios iniciales (rescatar
  un club en crisis).
- **M-262 · P2 · I** Sin editor de escenarios compartible. *Cómo*: exportar/importar mundo
  (editor ya existe; CSV).

## H. Carrera de Jugador (M-263 … M-276)

- **M-263 · P1 · C** Eventos únicos (13) y control real; pocos días de «vida» entre partidos.
  *Cómo*: semana con agenda (entreno, descanso, vida social).
- **M-264 · P1 · I** Misma ceremonia y gol que en el modo DT: pendiente. *Cómo*: reutilizar
  `CeremoniaPartido` y carta de gol.
- **M-265 · P2 · I** Avatar propio sin personalización de cuerpo. *Cómo*: somatotipo y
  proporciones.
- **M-266 · P2 · I** Sin entrenador como NPC con diálogos sobre el jugador. *Cómo*: relación y
  minutos.
- **M-267 · P2 · I** Transferencias vistas desde el jugador: ofertas sin negociación personal.
  *Cómo*: mesa con agente (ya hay `MesaAgente`).
- **M-268 · P2 · I** Selección nacional: convocatorias sin escena. *Cómo*: cinemática de
  llamada.
- **M-269 · P2 · I** Lesiones del jugador: sin recuperación jugable (fisio). *Cómo*:
  minijuego de rehabilitación.
- **M-270 · P2 · I** Retiro con paso a DT ok; sin homenaje. *Cómo*: ceremonia de despedida.
- **M-271 · P2 · I** Sin contratos de imagen propios. *Cómo*: patrocinios personales.
- **M-272 · P2 · I** Fuera de juego, cambios, selección ✅; sin protestas/tarjetas del usuario
  con consecuencias personales. *Cómo*: expediente disciplinario.
- **M-273 · P2 · I** Rivales NPC por `Fama`; sin rivalidades nominales. *Cómo*: rival de
  posición con comparativa.
- **M-274 · P2 · I** Sin vida privada coherente con regla (no romances de reales). *Cómo*:
  mantener sólo personajes ficticios.
- **M-275 · P2 · C** `carrera_jugador.gd` usa país «XXX» para el rival (línea 620). *Cómo*:
  usar un código real o `""` y comprobar que no rompe banderas.
- **M-276 · P2 · I** Pruebas: modo cubierto en `prueba_modos`; faltan casos extremos
  (retiro con ofertas vacías). *Cómo*: ampliar.

## I. Interfaz, menús, accesibilidad (M-277 … M-312)

- **M-277 · P1 · M** 274 textos en español directamente en `ui/` (I-02), concentrados en
  `pantalla_club_vida` (28), `principal` (25), `pantalla_plantel` (22), `pantalla_cantera` (19),
  `pantalla_legado` (18), `pantalla_opciones` (15), `pantalla_ficha` (13),
  `minijuegos_ciudad` (13), `pantalla_gente` (11), `pantalla_ajustes` (11), `panel_finanzas` (10),
  `pantalla_identidad` (9). *Cómo*: envolverlos con `Idiomas.t` por archivo, empezando por los
  de más texto visible.
- **M-278 · P1 · M** `ui/principal.gd` 6.655 líneas (y 3 funciones >330). *Cómo*: partir por
  pestaña/pantalla y por «conectar noticias».
- **M-279 · P1 · M** 27 módulos de `visor/` y 8 de `nucleo/` sin referencia directa en
  pruebas (lista en §N). *Cómo*: una prueba mínima por módulo (instanciar, usar, liberar).
- **M-280 · P1 · I** 105 módulos de UI/visor sin referencia en banco/pruebas. *Cómo*: capturas
  automáticas comparables (diff de imagen) en una tanda «visual».
- **M-281 · P2 · I** Sin modo daltónico. *Cómo*: paletas deuteranopia/protanopia/tritanopia
  en `Tema` y distintivos de forma además de color (rojo/verde del estado).
- **M-282 · P2 · I** Sin escala de interfaz/ fuente ajustable global. *Cómo*: `content_scale`
  y selector 80–150 %.
- **M-283 · P2 · I** Sin subtítulos/indicadores visuales de sonido. *Cómo*: avisos para
  silbato/gol.
- **M-284 · P2 · I** Sin modo lectura de pantalla (TTS). *Cómo*: `DisplayServer.tts_speak`
  en elementos enfocados.
- **M-285 · P2 · I** Navegación por mando en menús (panel de controles sí). *Cómo*:
  foco en todos los menús y atajos LB/RB.
- **M-286 · P2 · I** Sin atajos de teclado documentados globalmente. *Cómo*: panel de atajos.
- **M-287 · P2 · I** Rendimiento de menús: refresco ya 14× más rápido; sin pruebas de
  fluidez. *Cómo*: medir tiempo de apertura por pantalla en CI.
- **M-288 · P2 · I** Fondos animados únicos (9) con coste en GPU baja. *Cómo*: modo «fondo
  estático» al activar motor ligero.
- **M-289 · P2 · I** Menú lateral con 9 menús; Ciudad/Editar completados; Ajustes sólo 3
  tarjetas. *Cómo*: añadir Controles, Accesibilidad, Idioma, Cuenta/Guardado.
- **M-290 · P2 · I** Tarjetas con dato vivo sólo en algunas (`Menu.dato`). *Cómo*: ampliar a
  todas.
- **M-291 · P2 · I** Sin buscador global (jugadores, clubes, pantallas). *Cómo*: `Ctrl+K`.
- **M-292 · P2 · I** Sin favoritos/marcadores de jugadores o clubes. *Cómo*: lista
  «seguimiento».
- **M-293 · P2 · I** Tablas con filtros limitados (plantel). *Cómo*: filtros por puesto, edad,
  contrato.
- **M-294 · P2 · I** Comparador de jugadores existe; sin comparativa de club/estadio. *Cómo*:
  ampliar.
- **M-295 · P2 · I** Sin gráficos históricos (valor, forma) en ficha. *Cómo*: sparklines.
- **M-296 · P2 · I** Notificaciones (`Aviso`) sin centro de notificaciones. *Cómo*: bandeja
  con filtros.
- **M-297 · P2 · I** Tutorial: ciudad y controles; falta tutorial de gestión (primer mes).
  *Cómo*: guía por hitos.
- **M-298 · P2 · I** Pantalla de carga con consejos (`consejos_carga.py`). *Cómo*: ampliar y
  traducir.
- **M-299 · P2 · I** Sin confirmaciones consistentes para acciones destructivas (vender,
  despedir). *Cómo*: `CuadroDialogo` uniforme.
- **M-300 · P2 · I** Sin deshacer en acciones de pizarra. *Cómo*: historial de táctica.
- **M-301 · P2 · I** Sin guardado automático visible. *Cómo*: indicador y ranuras.
- **M-302 · P2 · I** Sin tema claro/alto contraste. *Cómo*: paleta alternativa.
- **M-303 · P2 · I** Cursor/hover sin feedback sonoro consistente en todos los controles (sí en
  botones). *Cómo*: sonar en pestañas y listas.
- **M-304 · P2 · I** Animaciones de transición entre pantallas desiguales. *Cómo*: sistema
  común (`Animar`).
- **M-305 · P2 · I** Tooltips escasos. *Cómo*: ayuda contextual con `?`.
- **M-306 · P2 · I** Sin glosario (términos de fútbol/gestión). *Cómo*: ayuda en pantalla.
- **M-307 · P2 · I** Resoluciones: pensado 1280×720–1600×900; sin pruebas en 4:3, 21:9 ni
  móvil vertical. *Cómo*: capturas por aspecto en la prueba visual.
- **M-308 · P2 · I** DPI alto: texto del `Label3D` en 3D no escala. *Cómo*: `pixel_size` por
  resolución.
- **M-309 · P2 · I** Sin pantalla de créditos/licencias dentro del juego. *Cómo*: leer
  `LICENCIAS.md` y créditos de fotos.
- **M-310 · P2 · I** Sin pantalla «Novedades» tras actualizar. *Cómo*: changelog en menú.
- **M-311 · P2 · I** Sin perfil de jugador (estadísticas globales). *Cómo*: `Meta` ya guarda
  parte; UI.
- **M-312 · P2 · I** Sin modo «streamer» (ocultar datos sensibles/real). *Cómo*: ajuste para
  ocultar fotos reales.

## J. Audio y música (M-313 … M-324)

- **M-313 · P2 · C** `Sonido._sintetizar` 1.000 líneas: efectos sintetizados sin editor.
  *Cómo*: tabla declarativa de efectos y caché en disco.
- **M-314 · P2 · I** Sin mezcla dinámica (ducking de música en diálogo/gol). *Cómo*: buses con
  compresor y automatización.
- **M-315 · P2 · I** Música (`Musica` 384 líneas, procedural): sin variaciones por mood
  (partido, gestión, ciudad). *Cómo*: capas y transiciones.
- **M-316 · P2 · I** Cantos de hinchada genéricos. *Cómo*: 5 patrones rítmicos con
  sincronización al juego.
- **M-317 · P2 · I** Sin comentarista. *Cómo*: frases cortas con TTS o clips; encadenar
  eventos del motor.
- **M-318 · P2 · I** Sin sonidos de pisadas por superficie en partido. *Cómo*: césped/barro.
- **M-319 · P2 · I** Sin eco/reverb en túnel/vestuario/estadio. *Cómo*: `AudioEffectReverb` por zona.
- **M-320 · P2 · I** Sonido del balón (patada) sin variación por tipo/potencia. *Cómo*: 5
  variantes por intensidad.
- **M-321 · P2 · I** Volúmenes por bus sin perfil «noche»/audífonos. *Cómo*: presets.
- **M-322 · P2 · I** Sin audio espacial en la ciudad (fuentes 3D). *Cómo*: tráfico, parques,
  estaciones.
- **M-323 · P3 · I** Sin música licenciada (decisión del dueño). *Cómo*: mantener procedural.
- **M-324 · P2 · I** Sin prueba que detecte clipping/silencios. *Cómo*: medir RMS de los
  efectos generados.

## K. Idiomas y textos (M-325 … M-336)

- **M-325 · P1 · M** Frases distintas por idioma (I-01): en/pt 1.531, fr/it/de/ca 1.402,
  pl/tr 1.699. *Cómo*: completar a la unión (1.699) y prueba que falle por menos claves.
- **M-326 · P1 · M** 297 frases faltan en fr/it/de/ca (incluye 129 titulares). *Cómo*: traducir
  por lotes con revisión.
- **M-327 · P2 · M** 168 frases faltan en en/pt. *Cómo*: traducir.
- **M-328 · P2 · C** Patrones numéricos (`patrones` 58) con plurales simples. *Cómo*: reglas de
  plural por idioma (pl y tr difieren).
- **M-329 · P2 · I** Sin género gramatical (entrenadora/jugadora) en todos los idiomas. *Cómo*:
  `Genero` extender a fr/it/pt/de.
- **M-330 · P2 · I** Formatos de fecha/número por idioma. *Cómo*: `Idiomas.fecha/numero`.
- **M-331 · P2 · I** Nombres de personas por país (bolsas) sin pruebas de duplicados masivos.
  *Cómo*: estadística de nombres repetidos por liga.
- **M-332 · P2 · I** Narración traducida (`narracion.json`) sin revisión nativa. *Cómo*:
  revisión por hablantes y marcar «auto».
- **M-333 · P2 · I** Texto en imágenes (carteles del 3D) sin traducir. *Cómo*: `Label3D` con
  `Idiomas.t`.
- **M-334 · P2 · I** Sin RTL (árabe, hebreo) aunque hay KSA/EGY/MAR. *Cómo*: documentar o
  añadir ar.
- **M-335 · P2 · I** Fuentes: cobertura de glifos para pl/tr/ar. *Cómo*: prueba con
  cadenas de cada idioma.
- **M-336 · P2 · I** `CLAUDE.md` afirma «1.402 frases c/u» (I-04). *Cómo*: actualizar.

## L. Rendimiento y optimización (M-337 … M-358)

- **M-337 · P0 · M** No hay perfil en hardware real (R-01). *Cómo*: ejecutar sondas en gama
  baja y guardar; objetivo explícito de FPS por modo.
- **M-338 · P1 · M** Partido ALTO ≈ 2,3 M tris/700 llamadas. *Cómo*: presupuesto por
  categoría (jugadores ≤ 200 k, grada ≤ 300 k, estadio estático ≤ 500 k).
- **M-339 · P1 · M** Césped en capas ≈ 230 k tris/57 llamadas. *Cómo*: LOD por distancia y
  reducir capas a >30 m (hoy hasta 46).
- **M-340 · P1 · M** 22 jugadores con pelo por capas, cejas, pestañas (ver `Optimizar.informe`). *Cómo*: fusionar pelo/pestañas en LOD lejano y apagar pestañas a >20 m.
- **M-341 · P1 · I** Sombras: 4 cortes en ALTO; sin ahorro medible al bajar (probado), pero
  costo GPU real desconocido. *Cómo*: medir en GPU real; si pesa, 2 cortes + sombras de
  contacto.
- **M-342 · P1 · I** Público real +8 % de triángulos (S-03). *Cómo*: mezclar `lejos` con
  *impostors* a >60 m.
- **M-343 · P2 · M** Draw calls 700. *Cómo*: fusión estática por sector y atlas de materiales.
- **M-344 · P2 · I** Overdraw en grada por butacas y personas. *Cómo*: oclusión (`OccluderInstance3D`)
  en los muros.
- **M-345 · P2 · I** Culling por trozos para MultiMesh grandes. *Cómo*: dividir por sectores
  (sólo ganará si la cámara no ve todo).
- **M-346 · P2 · I** Texturas con compresión (s3tc en PC); sin variantes móviles (etc2/astc).
  *Cómo*: importación por plataforma.
- **M-347 · P2 · I** VRAM 539 MB en partido. *Cómo*: reducir texturas 4K y compartir atlas.
- **M-348 · P2 · I** Carga: `Precarga` existe; primera construcción de estadio larga. *Cómo*:
  caché de mallas generadas (disco) y construcción asíncrona.
- **M-349 · P2 · I** Generación de `Mundo` (384 clubes) y `Reales.aplicar`: medir tiempo y
  paralelizar. *Cómo*: `WorkerThreadPool`.
- **M-350 · P2 · I** `avanzar_semana` 532 líneas: tiempo por semana desconocido. *Cómo*:
  perfilar con la prueba larga (3 semillas en 218 s ≈ 7 s por temporada) y vigilarlo.
- **M-351 · P2 · I** Hilos: ¿se usan para IA/ciudad? *Cómo*: separar tráfico y peatones.
- **M-352 · P2 · I** GC/alloc en `_process` (Dictionary por jugador). *Cómo*: estructuras
  tipadas/Packed arrays en el motor.
- **M-353 · P2 · I** Valorar C#/GDExtension sólo si el motor domina CPU. *Cómo*: medir
  `TIME_PROCESS` en gama baja antes de decidir.
- **M-354 · P2 · I** `RendimientoAdaptativo` existe; documentar umbrales y probarlos. *Cómo*:
  prueba que simule FPS bajo y compruebe cambios.
- **M-355 · P2 · I** Sin modo batería/60→30 FPS en móvil. *Cómo*: ajuste de FPS.
- **M-356 · P2 · I** Memoria de la ciudad ×4 (2.640 m). *Cómo*: streaming por celdas.
- **M-357 · P2 · I** Capturas pesadas en repo (`pruebas/capturas`). *Cómo*: ignorar y
  regenerar.
- **M-358 · P2 · I** Sin telemetría local de FPS por pantalla. *Cómo*: overlay de depuración.

## M. Datos y contenido (M-359 … M-378)

- **M-359 · P1 · M** Estadio real en 46 % de clubes (C-01). *Cómo*: ver M-002/M-004.
- **M-360 · P1 · M** 4 clubes sin estadio en base real (✅ E-03).
- **M-361 · P2 · M** `tablas.json` en una línea (D-04). *Cómo*: formato legible o dividir.
- **M-362 · P2 · I** `ESTADIO_CLUB` por nombre (frágil con leetspeak). *Cómo*: clave por id
  estable de club.
- **M-363 · P2 · I** Mapa ficticio→real (`CLUBES` en `base_ficticia.py`) sin prueba de
  cobertura. *Cómo*: prueba que liste clubes reales sin entrada.
- **M-364 · P2 · I** Países: 23 con 16 clubes (Chile 32). *Cómo*: añadir países/ligas
  (PAR/VEN/CRC) y divisiones inferiores.
- **M-365 · P2 · I** Copas nacionales sólo `Copa` genérica. *Cómo*: copas por país con
  nombre.
- **M-366 · P2 · I** Árbitros con datos mínimos. *Cómo*: perfiles y estilos.
- **M-367 · P2 · I** Calendario con feriados (`Calendario` 350 líneas); sin zonas horarias.
  *Cómo*: horarios por país.
- **M-368 · P2 · I** Jugadores históricos/leyendas sin mecánica de «cromo». *Cómo*: ligar al
  álbum.
- **M-369 · P2 · I** Nombres de estadios ficticios sin apodos amplios (`GuinosEstadio`).
  *Cómo*: más guiños.
- **M-370 · P2 · I** Historia de clubes (`historia_clubes.py`) por club; verificación
  cruzada. *Cómo*: prueba de coherencia (fechas).
- **M-371 · P2 · I** Himnos y cánticos sin letra. *Cómo*: textos originales.
- **M-372 · P2 · I** Retratos de DT/presidente generados; sin variedad étnica medida. *Cómo*:
  estadística por país.
- **M-373 · P2 · I** Bandera de cada país como pieza; verificar que son las correctas y
  vectoriales. *Cómo*: prueba visual.
- **M-374 · P2 · I** Divisas: ¿hay multi-moneda? *Cómo*: moneda por país con cambio.
- **M-375 · P2 · I** Sin calendario de selecciones fechas FIFA. *Cómo*: ventanas.
- **M-376 · P2 · I** Premios individuales sin votación explicada. *Cómo*: puntos visibles.
- **M-377 · P2 · I** Sin clima por país/estación realista. *Cómo*: tabla de clima.
- **M-378 · P2 · I** Sin datos de ciudades (población, altura) para estadios. *Cómo*: tabla.

## N. Código y arquitectura (M-379 … M-402)

- **M-379 · P2 · M** 64 funciones > 120 líneas (Q-01): `Sonido._sintetizar` 1.000,
  `Principal._conectar_noticias` 543, `Mundo.avanzar_semana` 532, `Prensa.resolver` 476,
  `StadiumBuilder.build` 445, `Principal._construir` 443, `Principal._ver_ficha` 330,
  `DisenosKit.color_en` 330, `Principal._pintar_estadio` 289, `Principal._acento_de` 276,
  `StadiumBuilder._butacas` 269, `MotorJugable._control_usuario` 265. *Cómo*: partir cada una
  en pasos con nombre, empezando por las que corren cada semana/fotograma.
- **M-380 · P2 · M** `pruebas/banco.gd` 8.029 líneas. *Cómo*: dividir por tandas en archivos.
- **M-381 · P2 · M** 16 `print()` en código de juego. *Cómo*: sustituir por `Registro`
  con niveles.
- **M-382 · P2 · I** Sin análisis estático. *Cómo*: `gdlint`/`gdformat` en pre-commit.
- **M-383 · P2 · I** Tipado: muchos `Dictionary` sin forma (jugadores del motor). *Cómo*:
  `class_name JugadorMotor` tipado.
- **M-384 · P2 · I** `Mundo` 2.921 líneas, `Roles` 2.065, `Prensa` 2.541: acoplamiento alto.
  *Cómo*: extraer servicios.
- **M-385 · P2 · I** Autoloads con globals (`Datos`, `Sonido`…). *Cómo*: documentar y evitar
  nuevos.
- **M-386 · P2 · I** Señales sin desconexión en liberación (posibles fugas). *Cómo*: prueba
  de fugas de nodos (`Performance.OBJECT_ORPHAN_NODE_COUNT`) tras abrir/cerrar pantallas.
- **M-387 · P2 · I** Mensajes de error silenciosos (`return` sin aviso). *Cómo*: registro.
- **M-388 · P2 · I** Constantes mágicas (balance) dispersas. *Cómo*: archivo de balance.
- **M-389 · P2 · I** `class_name` nuevos exigen `--import` (aprendido hoy). *Cómo*: documentar
  en `LEEME` y en `banco.sh` ejecutar `--import` antes.
- **M-390 · P2 · I** Un error de sintaxis deja el banco colgado. *Cómo*: `--check-only` previo
  y tiempo límite en `banco.sh` (ya vigila arranque).
- **M-391 · P2 · I** Duplicación entre `MatchPlayback` y `MotorJugable`. *Cómo*: retirar
  rutas muertas cuando el motor real es el predeterminado.
- **M-392 · P2 · I** `MotorLibre` prototipo (546 líneas) sin uso claro. *Cómo*: decidir
  eliminar o integrar.
- **M-393 · P2 · I** Código de pruebas mezclado con herramientas (`herramientas/*.ps1`).
  *Cómo*: separar por SO.
- **M-394 · P2 · I** Herramientas `.exe`/`.cs` binarias en repo. *Cómo*: moverlas a releases.
- **M-395 · P2 · I** Scripts Python sin entorno declarado. *Cómo*: `requirements.txt`.
- **M-396 · P2 · I** Convenciones: mezcla de español/inglés en nombres. *Cómo*: guía de estilo.
- **M-397 · P2 · I** Comentarios muy extensos (valioso pero ruidoso). *Cómo*: ADRs por
  sistema y comentarios cortos.
- **M-398 · P2 · I** Sin documentación de arquitectura actualizada (`LEEME.md`). *Cómo*:
  diagrama de módulos.
- **M-399 · P2 · I** Versión de guardado (`VERSION`) con migración mínima. *Cómo*: pruebas
  de carga de guardados antiguos.
- **M-400 · P2 · I** Sin límites de memoria en historiales (noticias, prensa). *Cómo*:
  topes y compresión.
- **M-401 · P2 · I** Dependencia de nombres de nodo (`find_child`) frágil. *Cómo*: grupos y
  referencias exportadas.
- **M-402 · P2 · I** Duplicación de carga de JSON (`Datos` 212 tablas). *Cómo*: carga
  perezosa por tabla.

## O. Pruebas y herramientas (M-403 … M-418)

- **M-403 · P1 · M** 8 módulos de `nucleo/` sin referencia en pruebas: `CatalogoJugadas`,
  `DialogosCiudad`, `EventosCantera`, `Genero`, `Gente`, `Logros` (1.132 líneas),
  `Negociacion`, `Precarga`. *Cómo*: una prueba por módulo en el banco.
- **M-404 · P1 · M** 27 módulos de `visor/` sin referencia: `Ambience`, `Autopista`, `Banderas`,
  `BibliotecaCaras`, `CamarografosSiguen`, `CameraRig`, `CaraMalla`, `CeremoniaPartido`,
  `Expresion`, `KitTextureFactory`, `MascotaQ`, `Mini3D`, `PeatonQ`, `PeloCapas`, `PeloQ`,
  `PersonaRealista`, `PersonajeDT`, `Precipitacion`, `RendimientoAdaptativo`,
  `ReproductorJugadas`, `RetargetFutbolQ`, `Retrato3D`, `RopaSeparada`, `Texturas`,
  `TraficoCiudad`, `VallasLed`. *Cómo*: pruebas de instanciación y de contrato.
- **M-405 · P1 · I** Pruebas visuales manuales (242 capturas). *Cómo*: comparar imágenes
  contra una referencia aprobada (diff con tolerancia).
- **M-406 · P2 · I** `Retrato3D` no se ejercita en headless. *Cómo*: prueba con `xvfb`.
- **M-407 · P2 · I** Sin pruebas de conducción/ciudad (V-06). *Cómo*: `prueba_conduccion`.
- **M-408 · P2 · I** Sin pruebas de minijuegos 3D. *Cómo*: instanciar y simular entradas.
- **M-409 · P2 · I** Sin pruebas de menús/UI de integración (abrir cada pantalla sin error).
  *Cómo*: recorrido automático por las pestañas con conteo de errores.
- **M-410 · P2 · I** Sin pruebas de rendimiento con umbrales. *Cómo*: `medir_partido` con
  tope de triángulos en el banco.
- **M-411 · P2 · I** Sin pruebas de idioma (V. I-01). *Cómo*: prueba de claves.
- **M-412 · P2 · I** Sin fuzzing de guardados. *Cómo*: cargar partidas truncadas.
- **M-413 · P2 · I** `auditoria_clubes`/`auditoria_datos` no están en el banco. *Cómo*:
  añadirlas como tanda rápida (la de datos tarda ≈ 1 min).
- **M-414 · P2 · I** Resultados de sondas (calidad/táctica/simetría) sin umbrales. *Cómo*:
  fallar si el mejor no gana ≥ 60 % o si el local gana > 58 % con equipos iguales.
- **M-415 · P2 · I** Tiempo del banco largo y frágil al correr en paralelo. *Cómo*: cola de
  tandas y bloqueo de ejecución.
- **M-416 · P2 · I** Sin CI en GitHub Actions. *Cómo*: workflow con Godot headless para banco
  y auditorías.
- **M-417 · P2 · I** `herramientas/banco.sh` sólo bash. *Cómo*: equivalente PowerShell ya
  existe (`run_godot.ps1`); unificar.
- **M-418 · P2 · I** Sin informes de cobertura. *Cómo*: contar funciones llamadas por el banco
  con un trazador simple.

## P. Repositorio, build y legal (M-419 … M-432)

- **M-419 · P1 · M** `.git` 5,5 GB con punteros LFS antiguos (D-03). *Cómo*: decisión del
  dueño; documentar y evitar `git lfs pull` en la nube.
- **M-420 · P1 · I** Builds públicos sin datos reales (caras, fotos): comprobar con prueba
  que lista el contenido de la exportación. *Cómo*: script que abra el `.pck`.
- **M-421 · P1 · I** Derechos de imagen de jugadores reales (decisión del dueño). *Cómo*:
  mantener ajuste «Recreación» por defecto en builds públicos.
- **M-422 · P2 · M** 8 presets de exportación; sin pruebas de compilación. *Cómo*: job de CI
  que exporte Linux/Windows.
- **M-423 · P2 · I** Android: keystore del dueño (regla). *Cómo*: documentar el flujo sin
  guardar contraseñas.
- **M-424 · P2 · I** Licencias de terceros (Kenney CC0, Quaternius, Anderson Rohr): `LICENCIAS.md`
  al día. *Cómo*: auditoría automática de carpetas `assets/` vs licencias.
- **M-425 · P2 · I** Créditos de fotos (`creditos_fotos.txt`) sólo para el pack real. *Cómo*:
  mostrar en pantalla de créditos.
- **M-426 · P2 · I** Archivos grandes sueltos (`.glb` >5 MB). *Cómo*: simplificar o
  comprimir (Meshopt/Draco).
- **M-427 · P2 · I** `pruebas/capturas` crece sin control. *Cómo*: `.gitignore` y
  carpeta externa.
- **M-428 · P2 · I** `.zip` de terceros dentro de `recursos/` (punteros LFS). *Cómo*:
  mover a almacenamiento externo.
- **M-429 · P2 · I** Versionado del juego sin número visible. *Cómo*: `version.cfg` y pantalla.
- **M-430 · P2 · I** Sin canal de reporte de errores. *Cómo*: botón que guarde un `.log` y
  capturas.
- **M-431 · P2 · I** Privacidad: sin datos personales (OK). *Cómo*: mantener; documentar.
- **M-432 · P2 · I** Sin política de contenido (religión/política ficticia). *Cómo*: lista
  de verificación en CI (M-240).

## Q. Móvil, táctil y mando (M-433 … M-442)

- **M-433 · P1 · I** Controles táctiles sólo en la ciudad (cruceta/E). *Cómo*: joystick virtual
  y botones para el partido (5 botones + gatillos).
- **M-434 · P2 · I** Sin vibración (rumble) en mando. *Cómo*: `Input.start_joy_vibration` en
  gol/colisión/entrada.
- **M-435 · P2 · I** Sin gatillos analógicos para potencia de pase. *Cómo*: leer ejes de
  gatillo.
- **M-436 · P2 · I** Sin giroscopio para cámara en primera persona (móvil). *Cómo*:
  `Input.get_gyroscope`.
- **M-437 · P2 · I** Sin detección de dispositivo para cambiar iconos en tiempo real (hay
  `dispositivo_detectado`). *Cómo*: refrescar guía al cambiar.
- **M-438 · P2 · I** UI de móvil: botones pequeños. *Cómo*: tamaño mínimo 48 dp.
- **M-439 · P2 · I** Orientación vertical no soportada. *Cómo*: layout alternativo en gestión.
- **M-440 · P2 · I** Sin modo una mano. *Cómo*: disposición configurable.
- **M-441 · P2 · I** Sin soporte de teclado en pantalla para nombres. *Cómo*: `LineEdit`
  nativo en móvil.
- **M-442 · P2 · I** Mando: botones reasignables guardados pero sin perfiles múltiples.
  *Cómo*: perfiles.

## R. Pasada 3 (M-443 … M-470)

- **M-443 · P1 · M** La IA del motor no amaga (0 en un partido de prueba). *Falta*: fintas de
  la IA visibles. *Cómo*: subir el umbral de `presion < 1.8` a ~2,6 m, probar antes de pasar
  si hay rival al frente y repetir la sonda de calidad (N ≥ 8) para no romper la calibración.
- **M-444 · P2 · M** Fuga de texturas GL al cerrar `prueba_carrera_flujo`. *Cómo*: liberar
  `Retrato3D`/`Portada` (cachés estáticas) al salir con `NOTIFICATION_WM_CLOSE_REQUEST`.
- **M-445 · P2 · M** Pruebas que no caben en 5 min con render por software (`intro`,
  `regates`, `repeticion`) o se cuelgan en headless (`descanso_3d`). *Cómo*: modo «rápido»
  del arnés (menos fotogramas, tiempo simulado) y marcar las que exigen pantalla.
- **M-446 · P1 · M** 69 claves nuevas sin traducir (✅ arregladas); el patrón se repetirá con
  cada pantalla nueva. *Cómo*: **prueba del banco** que extraiga las claves de `Idiomas.t(` del
  código y falle si falta en algún idioma (el script de la pasada 3 ya lo hace).
- **M-447 · P1 · I** Las 274 cadenas en español escritas directo en `ui/` (I-02) siguen
  pendientes; la prueba anterior solo cubre las que ya pasan por `Idiomas.t`. *Cómo*: ídem,
  buscar `.text = "…"` con tildes y exigir envoltorio.
- **M-448 · P2 · M** `auditoria_clubes` tarda ~8 min y `auditoria_datos` ~1 min. *Cómo*:
  ejecutar con una muestra (`N` clubes) en el banco y completa solo de noche.
- **M-449 · P2 · I** Los informes (`AUDITORIA_CLUBES.csv`) se regeneran a mano. *Cómo*: tarea
  de CI nocturna que los publique como artefacto y abra una incidencia si empeora un %.
- **M-450 · P2 · M** `pruebas/prueba_*` no tienen un índice de «qué cubre cada una». *Cómo*:
  cabecera estándar (módulo, modo headless sí/no, duración) y tabla generada en `LEEME`.
- **M-451 · P2 · I** Duplicación del arnés (`_ok`, `_fallos`) en decenas de pruebas. *Cómo*:
  clase base `PruebaBase` con `_ok`, resumen y salida con código.
- **M-452 · P2 · I** Salida de pruebas sin código de retorno uniforme (algunas `quit(0)` con
  fallos). *Cómo*: `quit(_fallos > 0 ? 1 : 0)` en todas para que CI las use.
- **M-453 · P2 · I** Pruebas ligadas al azar sin semilla fija en algunos casos (la IA usa `_rng`).
  *Cómo*: semilla por prueba y registro de la semilla al fallar.
- **M-454 · P2 · I** Capturas que cambian el estado de la máquina (ajustes de ceremonia, intro).
  *Cómo*: restaurar en `_exit_tree`.
- **M-455 · P2 · M** Pruebas que escriben en `user://ajustes.cfg` real (E-10). *Cómo*: ruta de
  ajustes inyectable (`CajonAjustes.RUTA` sobreescribible) y una carpeta `user://pruebas/`.
- **M-456 · P2 · I** `auditoria_tecnica` solo carga las escenas de `escenas/` y `ui/` (4).
  *Cómo*: recorrer también las que crean pantallas en código (instanciar cada `PanelX.abrir`).
- **M-457 · P2 · I** Los nodos huérfanos se miden solo en la pantalla principal. *Cómo*: medir
  tras abrir y cerrar el estadio 3D, la ciudad, la casa y el teléfono (los más pesados).
- **M-458 · P2 · I** Sin comprobación de que cada `Label` traducible esté dentro de un árbol
  que se pasa por `traducir_arbol`. *Cómo*: recorrido de pantallas en un idioma ajeno que
  busque textos con tilde del español.
- **M-459 · P2 · I** Cinco idiomas de los nueve nacieron con frases que luego se añadieron
  solo a algunos (en/pt/pl/tr). *Cómo*: un único flujo (`herramientas/extraer…` → traducir →
  `montar…`) para todas las frases nuevas.
- **M-460 · P2 · I** Las traducciones nuevas (552) están hechas a mano sin revisión nativa.
  *Cómo*: marcar con fecha/«auto» y pedir revisión (especialmente fr/it/de/pl/tr).
- **M-461 · P2 · I** Las cadenas con `%s`/`%d` dependen del orden de argumentos; en algunos
  idiomas el orden natural cambia. *Cómo*: placeholders con nombre (`{club}`) en las frases
  con más de un argumento.
- **M-462 · P2 · I** Etiquetas de botón con emoji/caracteres (💾 ↺ ● ✔ ▸ ◯) pueden no estar en
  todas las fuentes. *Cómo*: prueba de glifos por idioma y sustitutos.
- **M-463 · P2 · I** `Idiomas.t` devuelve la clave si falta (silencioso). *Cómo*: en modo
  depuración, registrar la clave faltante una vez.
- **M-464 · P2 · I** No existe un informe de «frases por pantalla»: no se sabe qué pantalla
  está más sin traducir. *Cómo*: contar claves y literales por archivo (ya calculado para `ui/`).
- **M-465 · P3 · I** Sin pruebas de rendimiento de la carga de idiomas (`idiomas.gd` 655
  líneas, `idiomas_extra.json` ~1 MB). *Cómo*: carga perezosa por idioma.
- **M-466 · P2 · M** `datos/idiomas_extra.json` se reescribe entero con cada ampliación (diffs
  grandes). *Cómo*: un archivo por idioma.
- **M-467 · P2 · I** Falta un chequeo de longitud de texto (alemán/finés largo) en botones.
  *Cómo*: capturas en de/pl con comprobación de recorte.
- **M-468 · P2 · I** Plurales y géneros en las 69 frases nuevas (p. ej. «%d botones») no están
  tratados. *Cómo*: formas con regla de plural (`patrones`).
- **M-469 · P3 · I** Falta documentación del flujo de pruebas para colaboradores. *Cómo*:
  sección en `LEEME.md` con el orden (import → banco → auditorías → capturas).
- **M-470 · P2 · I** El banco no ejecuta `auditoria_tecnica`, `auditoria_datos` ni las pruebas
  nuevas. *Cómo*: añadirlas como tandas rápidas (datos ≈ 1 min, técnica ≈ 20 s).

---

**Total de puntos registrados: 470** (M-001 … M-470), más los 40 de `INFORME_INTERNO.md`.

### Cómo se priorizaron

1. **P0** (2): exterior de estadio (M-001) y perfil en hardware real (M-337).
2. **P1** (75): lo que se nota a simple vista o afecta a la coherencia (idiomas,
   patrocinio, escudos y camisetas, sesgo de local, retratos reales, cobertura de pruebas).
3. **P2/P3** (381 y 12): pulido y futuro.

### Hallazgos que desmienten supuestos (importante)

- «Hay 65 TODO»: **falso** (palabra «todo»).
- «Los ojos pesan mucho» (pasada anterior): **sobrestimado**; un ojo tiene ~768 triángulos y
  22 jugadores son ~17 k; el coste del pelo/pestañas por capas y el césped en capas es
  mayor (M-339, M-340).
- «Cada idioma tiene 1.402 frases»: **falso** (I-01).
- «Los patrocinadores no coinciden con los reales»: **no es defecto** (decisión del usuario),
  pero sí lo eran el reparto sesgado y los clubes grandes sin patrocinio (✅ corregidos).

### Reparto por evidencia

Medido (M): 51 · Código revisado (C): 39 · Visto en captura (V): 8 · Inferido (I): 372. Los **inferidos** deben comprobarse antes de tocar nada.
