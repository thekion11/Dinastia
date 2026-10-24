# MEJORAS ABIERTAS (limpiado el 24-10-2026)

Solo lo que falta: las filas HECHAS se borraron (quedan en el historial de git y en `docs/06_historial/`). Estados: PARCIAL = existe una parte (se dice qué falta) · PENDIENTE = no se encontró nada · 🔒 DUEÑO = builds, licencias, keystore, FPS en hardware real, música · SIN VERIFICAR.
Un PENDIENTE significa «no se encontró»: reverificar la fila antes de construir. Lista plana: `ideas_pendientes.csv` (regenerar con `python3 herramientas/tablero_ideas.py`). Tareas en curso: `TABLERO.md`.

## Los puntos abiertos, sección por sección

### A. Estadios y entorno (M-001 … M-032) · PENDIENTE 14 · PARCIAL 12

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-003 | P1 | Las formas no varían de forma continua | PENDIENTE | `RETRANQUEO_BANDEJA` sigue siendo constante; sin parámetros por club |
| M-004 | P1 | El «estadio real» sólo copia forma/niveles/techo/pista/focos/fachada | PENDIENTE | `ESTADIOS` de `herramientas/estadios_reales.py` sin color de pista/vallas, año ni pantalla |
| M-005 | P1 | Colores propios de butacas en 47 de 176 estadios reales | PENDIENTE | `ASIENTOS` sigue con 47 de 176 estadios |
| M-007 | P2 | Sin variación de entorno por país (palmeras, nieve, montaña de fondo) | PENDIENTE | sin fondo lejano por país/clima en el estadio |
| M-009 | P2 | Sin voladizo/cubierta visible en estadios sin techo | PARCIAL | techo «visera» y cerchas vistas desde fuera (`FachadaEstadio`); sin visera parcial con estructura por sector |
| M-010 | P2 | Sin carteles de pared (patrocinadores, fechas, escudo) fuera del campo | PENDIENTE | sin carteles en muros exteriores (la fachada tiene rótulos de puerta, no publicidad) |
| M-012 | P2 | Vallas LED con la misma rotación de marcas inventadas (30) | PENDIENTE | `VallasLed` sin catálogo ampliado; `Auspicio` tiene 38 marcas |
| M-013 | P2 | Banderas de esquina/córner genéricas | PARCIAL | banderines con tela y color del asiento del estadio (`_corners`); sin banderola del país ni viento |
| M-014 | P1 | Sin diferencia día/noche en el aspecto de la iluminación… | PARCIAL | 21-10: el haz de cada farola de la ciudad es un cono volumétrico falso con degradado y sin contorno (`visor/cono_farola.gdshader`); sin haces de los focos del estadio |
| M-015 | P2 | El césped usa 12 dibujos, asignación por hash | PENDIENTE | el dibujo de césped sigue por hash (`Club._CESPED`); no hay campo en estadios reales |
| M-016 | P2 | Sin campo de entrenamiento/calentamiento visible fuera del estadio | PENDIENTE | sin campo anexo con calentamiento |
| M-017 | P1 | Túnel de vestuario sólo en +Z | PENDIENTE | túnel fijo en la tribuna +Z (`tunel_x`) |
| M-018 | P2 | Banquillos de un solo diseño por preset | PENDIENTE | `EST_BANQUILLOS` sin ampliar |
| M-019 | P2 | Sin zona de prensa/cabinas de TV visibles en el graderío | PARCIAL | cabina de prensa en `estadio_extras.gd`; sin vidrio ni NPC de prensa dentro |
| M-020 | P2 | Sin palcos reales (`palcos` existe como instalación) | PARCIAL | palcos como pieza de `estadio_extras.gd` y `ClubDentro.PALCO`; sin interior con personas |
| M-022 | P2 | Sin sonido espacial por sector (cantos locales vs visitantes) | PENDIENTE | no existe ningún `AudioStreamPlayer3D` en el juego |
| M-023 | P3 | Sin clima visible en el estadio más allá de lluvia/niebla (nieve,… | PARCIAL | nieve, lluvia y niebla (`Precipitacion`, `Clima`); sin calima/polvo ni charcos que reflejan |
| M-024 | P2 | Sombras de la grada sobre el campo no cambian con la hora real del… | PARCIAL | `Ambience` usa la hora elegida para el estadio, no la hora/estación real del partido |
| M-025 | P2 | Poca variedad de torres de luz (4 esquinas) | PARCIAL | focos «corona/mixto/halo» además de torres; no 6/8 torres por forma |
| M-026 | P3 | Estadios sin nombre dibujado en fachada | PARCIAL | rótulos en las puertas de la fachada; sin nombre grande del estadio por tipografía de club |
| M-027 | P2 | Sin variación de terreno exterior (cerro, mar, río) según `rasgo` | PENDIENTE | el texto `rasgo` no elige fondo ni niebla |
| M-028 | P2 | El estadio propio y el rival usan caminos de construcción… | PARCIAL | `pruebas/captura_mismo_estadio.gd` (manual); no está en el banco |
| M-029 | P2 | Ampliaciones del estadio propio sin animación de obra detallada | PARCIAL | andamios, grúa torre y vallado (`estadio_extras.gd`, `EstadioPropio.obra`); sin polvo ni operarios |
| M-030 | P3 | Sin estadio nacional/selección con identidad propia | PENDIENTE | sin sedes de selección con arquitectura propia |
| M-031 | P2 | Sin mapa de estadios (galería) para ver todos los del juego | PENDIENTE | sin pantalla «Estadios del mundo» |
| M-032 | P2 | Sin ficha de estadio con datos reales (capacidad oficial, año,… | PARCIAL | aforo OFICIAL en la ficha (`ui/estadio.gd:544`); faltan año y superficie |

### B. Público y ambiente (M-033 … M-050) · PARCIAL 5 · PENDIENTE 5

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-035 | P1 | Sin bufandas/banderas/camisetas del club en la mano | PARCIAL | banda de bufandas y tifo en grada (`StadiumBuilder` «bufandas»/«tifo»); sin mallas en la mano |
| M-037 | P2 | Sin sector «barra brava»/torcida con comportamiento diferente (de… | PENDIENTE | sin sector ultra con bengalas/humo |
| M-038 | P2 | Hinchas sentados con piernas invisibles (se cortan en la cadera) | PENDIENTE | público horneado cortado en la cadera |
| M-039 | P2 | Tres niveles de detalle; el salto «cerca→medio→lejos» puede verse | PARCIAL | detalle por distancia por tramos de grada (16-10, 2,24→1,72 M tris); sin mezcla por dithering |
| M-041 | P2 | Sin niños, familias ni asistentes en sillas de ruedas | PENDIENTE | sin niños/familias/sillas de ruedas en grada |
| M-042 | P2 | Ocupación = reputación, no asistencia del partido | PARCIAL | ocupación = asistencia de `Finanzas` (depende del precio); no por sector |
| M-043 | P2 | Sin diferencia de público por competición (final vs liga) | PENDIENTE | sin decoración especial en finales |
| M-044 | P2 | Gol local: ceremonia de público única | PARCIAL | 20-10: además del confeti/bengalas, onda de saltos desde ese fondo, la ola con el partido decidido y la protesta; falta variar por sector |
| M-046 | P3 | Sin multitudes en accesos, tienda y museo del estadio | PENDIENTE | sin flujo de NPC antes/después del partido |
| M-048 | P2 | Fotógrafos/camarógrafos pocos y repetidos | PARCIAL | `visor/camarografos_siguen.gd` (giran con el balón, uno camina); siguen siendo pocos |

### C. Camisetas, escudos y marcas (M-051 … M-078) · PENDIENTE 17 · PARCIAL 3

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-054 | P1 | Ropa con volumen sólo en retratos (K-02) | PENDIENTE | `VestidorQ.ropa_aparte` sigue apagado en partido por coste |
| M-055 | P1 | Sin arrugas dinámicas según animación | PARCIAL | pliegues de tela estáticos (`pliegues()` en el shader); no dependen de la animación |
| M-056 | P2 | Sin sudor/barro/lluvia en la camiseta | PENDIENTE | sin uniform de barro/mojado |
| M-058 | P1 | 30 marcas de patrocinio (K-03) | PARCIAL | 38 marcas en `Auspicio` (antes 30); meta 70 |
| M-060 | P2 | Patrocinio fijo por club entre temporadas, sin contratos de IA que… | PENDIENTE | sin renovación/cambio de patrocinador de clubes IA |
| M-061 | P2 | Sin patrocinador en la parte trasera del pantalón ni en las medias | PENDIENTE | sin zonas `short_trasero`/`medias` |
| M-063 | P1 | Escudos reales sólo 26 (7 %) | PENDIENTE | `ESCUDOS` sigue con 26 clubes |
| M-064 | P2 | Falta ornamento reconocible (león, águila, estrella, castillo,… | PENDIENTE | sin biblioteca de símbolos (solo el almenado) |
| M-065 | P2 | Texto/iniciales ilegibles <24 px | PENDIENTE | sin prueba de legibilidad a 24 px |
| M-066 | P2 | Escudo sin variante monocroma (para periódico, marcador) | PENDIENTE | sin `Escudo.mono` |
| M-067 | P2 | Sin escudo animado en el marcador al gol | PENDIENTE | sin pulso del escudo en el marcador |
| M-068 | P1 | Diseño de camiseta por hash en el 63 % de clubes (ya hay tabla… | PENDIENTE | `CAMISETAS` con 63 clubes |
| M-069 | P2 | 12 diseños con reparto casi uniforme (C-06) | PENDIENTE | sin pesos en el reparto de diseños |
| M-070 | P2 | Sin segunda/tercera camiseta con diseño propio | PENDIENTE | sin tercera equipación |
| M-071 | P2 | Portero: color por contraste, sin diseño | PENDIENTE | portero solo por contraste; guantes como color de accesorio |
| M-074 | P2 | Medias/pantalón: diseño correcto pero sin franjas del fabricante | PENDIENTE | sin franjas del fabricante en medias/pantalón |
| M-075 | P2 | Dorsal sin fuente propia por club | PENDIENTE | dorsal en siete segmentos, una sola fuente |
| M-076 | P3 | Sin parches de competición (campeón, copa) | PENDIENTE | sin parches de competición |
| M-077 | P2 | Retrato con camiseta de volumen pero sin patrocinio en pecho visible | PENDIENTE | encuadre del retrato sin cambiar |
| M-078 | P2 | Foto real de equipación sólo con pack real (C-08) | PARCIAL | 2D y 3D con cuello/costuras desde el 14/17-10; diferencia con foto real sigue |

### D. Jugadores, caras, cuerpos y animaciones (M-079 … M-112) · PENDIENTE 14 · PARCIAL 11 · SIN 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-079 | P1 | Retrato real 13 % (base real) | PENDIENTE | 13 % con retrato real; descarga bloqueada por la red |
| M-080 | P2 | Fotos agachadas aún oscuras/deformadas | PENDIENTE | fotos agachadas sin re-detección (límite anotado en MOTOR_CARAS.md) |
| M-082 | P2 | Altura sólo por escala global | PENDIENTE | sin proporciones variables |
| M-083 | P2 | Sin tatuajes/cicatrices por jugador salvo civiles | PARCIAL | tatuaje solo en ropa civil (`equipacion_q.gdshader` `tatuaje`); no en jugadores |
| M-084 | P2 | Biblioteca de caras = 72 mezclas | PENDIENTE | biblioteca de 72 caras |
| M-085 | P2 | Envejecimiento visual de jugadores (canas, arrugas) no ligado a `edad` | PARCIAL | 21-10: canas desde los 32 en los inventados (`Cara.look_de`, a uno de cada cuatro casi nada); los reales llevan el color de su foto; arrugas pendientes |
| M-086 | P2 | Expresiones faciales limitadas a `Expresion` básica | PENDIENTE | `Expresion` sin emociones nuevas |
| M-087 | P2 | Sin parpadeo/respiración idle variados | PARCIAL | parpadeo en el DT/`Expresion`; sin respiración idle en jugadores |
| M-089 | P2 | Barbas/cejas por capas apagadas (manchas) | PENDIENTE | barba/cejas por capas siguen apagadas |
| M-090 | P2 | Guantes de portero sólo color | PENDIENTE | sin geometría de guante |
| M-091 | P1 | Botines: variedad añadida, pero sin modelos distintos por forma | PARCIAL | `VestidorQ._botin_de` varía modelo/color por dorsal; no hay mallas de bota alta/calcetín |
| M-092 | P2 | Cordones/tacos sin geometría | PENDIENTE | sin relieve de cordones/tacos |
| M-093 | P2 | Sin canilleras/vendas/cintas visibles | PENDIENTE | sin canilleras/vendas en partido |
| M-094 | P1 | Animación de caminata del DT: 6 estilos (✅) | PARCIAL | «Mi caminata» con 6 estilos para el DT; peatones y jugadores no |
| M-095 | P1 | 335 clips; muchos sin uso en partido | PENDIENTE | sin auditoría automática de clips usados |
| M-096 | P2 | Transiciones entre clips con mezcla fija 0,25 s | PENDIENTE | mezcla fija entre clips |
| M-097 | P2 | Retarget con pies que patinan | PARCIAL | IK de piernas solo en la ciudad (`AnimQuaternius._ik_pierna`); sin foot locking en partido |
| M-099 | P2 | Cuerpos sin colisión entre brazos/piernas (solapes sólo en XZ) | PARCIAL | cuerpos que se empujan y duelos en el motor (`MotorJugable._cuerpos`, 17-10), en 2D; sin cápsulas 3D |
| M-101 | P2 | Celebraciones por rasgo (ya) pero sólo 2/3 propias | PARCIAL | carrera al córner y abrazo (`_ia_celebracion`); sin 10 por rasgo ni coreografías |
| M-102 | P2 | Sin reacciones de banquillo coordinadas | PARCIAL | celebra el gol (`_banca_celebra`); 21-10: protesta la roja de uno de los suyos (`_banca_protesta`); falta la lesión |
| M-103 | P2 | Lesiones sin animación específica | PARCIAL | clip de dolor (`AnimQuaternius`); sin camilla ni médicos en campo |
| M-108 | P2 | Mascotas con animación limitada | SIN VERIFICAR | `MascotaQ` tiene animaciones propias; no se comprobó si son 6 ni si hay rutas |
| M-109 | P2 | Niños de ceremonia con una misma malla | PARCIAL | niños con cuerpos de peatones variados (`CeremoniaPartido`); sin comprobar variedad de malla |
| M-110 | P2 | Sin voces/murmullos de jugadores | PENDIENTE | sin voces de jugadores |
| M-111 | P3 | Sin modo foto con poses y expresión (existe `ModoFoto`) | PENDIENTE | `ModoFoto` sin poses ni editor de expresión |
| M-112 | P2 | Sin avatar del usuario en el estadio como jugador (carrera) con su… | PENDIENTE | la Carrera de Jugador no usa el cuerpo del creador |

### E. Partido: física, IA, controles, cámara, presentación (M-113 … M-166) · PARCIAL 15 · PENDIENTE 15 · SIN 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-119 | P1 | Penales: el portero «decide una vez» pero sin lectura del lanzador | PARCIAL | 20-10: en la TANDA el portero de la IA se tira más al lado natural del pie del lanzador (46/36/18) y, según sus reflejos (4-16 %), lee la carrera (`_lado_portero_tanda`); falta en los penales del partido |
| M-120 | P2 | Córners con 3 variantes | PARCIAL | receptor/2.º/3.er lanzador en córners (14-10); sin jugadas ensayadas de `CatalogoJugadas` |
| M-121 | P2 | Tiros libres: barrera simple | PARCIAL | barrera de 4 a 9,15 m fija |
| M-122 | P2 | Sin saque de banda largo/estratégico | PARCIAL | saque de banda largo del usuario (X); sin atributo |
| M-125 | P2 | Sin tácticas de medio campo (doble pivote, falso 9) | PENDIENTE | sin roles con comportamiento propio |
| M-126 | P2 | Cambios de IA por cansancio (60/70/80') fijos | PARCIAL | DT rival cambia en 60/70/80' y ajusta la pizarra según marcador (`_dt_rival`); minutos fijos |
| M-128 | P2 | Portero con salidas sólo en mano a mano | PARCIAL | colocación y achique del portero (14-10); sin salidas aéreas |
| M-129 | P2 | Sin lanzamientos de larga distancia ni centros desde banda con… | PARCIAL | los atributos pesan en el motor (`_atributos`); sin parámetro de precisión por tipo de envío |
| M-131 | P2 | Ayudas de asistencia (pase/tiro) con 3 niveles | PARCIAL | ayudas por pieza (asistido/manual, auto/semi/manual) en `Mando`; sin perfiles Arcade/Semi/Manual |
| M-134 | P2 | Sin cámaras de repetición cinematográficas (grúa, dron) | PARCIAL | cámaras «Dron orbital» y otras en el rig; la repetición no alterna planos |
| M-135 | P2 | Sin cámara de gol del cuarto árbitro/línea | PENDIENTE | sin cámara de línea de gol |
| M-140 | P2 | Descanso: charla de medio tiempo con opciones; sin vestuario 3D… | PENDIENTE | el descanso vuelve al camarín 2D (`prueba_descanso_3d`); sin cinemática de vestuario |
| M-142 | P2 | Rueda de prensa posterior no enlazada con incidentes del partido | SIN VERIFICAR | no se encontró tema de árbitro/VAR en `Prensa.resolver` |
| M-143 | P2 | Sin clima dinámico durante el partido (tormenta repentina) | PENDIENTE | sin cambio de clima en vivo |
| M-144 | P2 | Campo se desgasta (barro) sin visualización | PARCIAL | desgaste fijo en áreas y punto de penal (`cesped.gdshader`); no evoluciona |
| M-145 | P2 | Sin marcas de césped (pisadas, deslizamientos) | PENDIENTE | sin marcas de pisadas |
| M-146 | P2 | Balón con skins pero sin desgaste/mojado | PENDIENTE | balón sin desgaste/mojado |
| M-147 | P1 | Hitbox del balón vs cuerpo: 0 casos atravesando (sonda); pero… | PARCIAL | balón con altura y cabezazo en el motor; colisión por distancia, sin cápsulas |
| M-148 | P2 | Sin rebotes contra postes/larguero realistas con física propia | PARCIAL | poste y larguero detectados en el motor; rebote sin comprobar |
| M-150 | P2 | Sin balones adicionales (calentamiento, reserva) | PENDIENTE | sin balones decorativos |
| M-152 | P2 | Sin modo de entrenamiento libre (probar controles) | PENDIENTE | sin entrenamiento libre |
| M-153 | P2 | Sin modo multijugador local | PENDIENTE | sin multijugador local |
| M-154 | P3 | Sin online | PENDIENTE | fuera de alcance, sin documentar |
| M-155 | P2 | Penal de usuario con barra, sin variantes por pierna | PARCIAL | el zurdo usa clips en espejo; penal del usuario sin variante por pierna |
| M-156 | P2 | Sin decisión de capitán (protesta) | PENDIENTE | sin protesta del capitán |
| M-157 | P2 | Sin cantos/anuncios del estadio (megafonía con alineaciones) | PENDIENTE | sin megafonía |
| M-159 | P2 | Sin himno por país con partitura procedural | PARCIAL | un motivo genérico «himno» sintetizado; no por país |
| M-161 | P2 | Sin mini-partidos de selección con identidad | PENDIENTE | sin identidad de selección en el 3D |
| M-163 | P2 | Sin modo «Director técnico automático» configurable (IA del usuario) | PARCIAL | `MotorJugable.autopiloto`; sin perfil configurable |
| M-164 | P2 | Sin modo espectador con cámara libre | PENDIENTE | sin cámara libre en la UI |
| M-166 | P3 | Sin partidos de fútbol sala/playa/mujeres (género existe) | PENDIENTE | fuera de alcance, sin documentar |

### F. Ciudad, vehículos, metro, interiores (M-167 … M-206) · PENDIENTE 20 · PARCIAL 10 · SIN 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-167 | P1 | Calzadas = cajas de asfalto con marcas propias; Kenney sólo… | PENDIENTE | calzadas propias; losetas Kenney no usadas |
| M-168 | P2 | Sin rotondas | PENDIENTE | sin rotondas |
| M-170 | P2 | Sin semáforos peatonales con botón | PENDIENTE | sin botón peatonal |
| M-171 | P1 | Tráfico sin comportamiento complejo (adelantar, ceder en cruce) | PARCIAL | cola y frenado en rojo (`TraficoCiudad`); sin adelantar |
| M-173 | P2 | Sin sonido de motor/marchas/derrape | PARCIAL | 21-10: el motor del coche suena, sintetizado en vivo con revoluciones y 5 marchas (`visor/motor_coche_sonido.gd`); sin radio |
| M-174 | P2 | Interior de coche sin modelo (salpicadero 2D) | PARCIAL | salpicadero y volante 2D (`VolanteUI`) |
| M-176 | P2 | Sin tipos de vehículo (moto, bus conducible, camión) | PENDIENTE | solo coche conducible |
| M-177 | P2 | Sin gasolinera/aparcamiento/lavado | PENDIENTE | sin gasolinera/lavado |
| M-180 | P2 | Metro: sin vendedores/música/anuncios | PARCIAL | anuncios en el vagón (`MetroCiudad.ANUNCIOS`); sin vendedores ni música |
| M-182 | P2 | Sin tarjeta de transporte ni coste | PENDIENTE | máquinas de billetes decorativas; sin coste |
| M-183 | P2 | Peatones: 34 máx; sin rutinas por hora | PARCIAL | 21-10: de madrugada queda en la calle un tercio de la gente (los ocultos tampoco se mueven: `TraficoCiudad.faros`); faltan rutinas por persona |
| M-184 | P2 | Sin NPC con nombre y memoria (te reconocen) | PENDIENTE | sin vecinos con memoria |
| M-185 | P2 | Diálogos por oficio (hecho) pero sin ramas ni consecuencias | PENDIENTE | diálogos sin consecuencias |
| M-186 | P2 | Interiores: 15 salas; edificios entrables «la mayoría» sin… | PARCIAL | gimnasio, piscina, estación central, recreativos con muebles Kenney (15/16-10); 21-10: edificio del club con muebles de verdad del catálogo común `Modulos` (oficina del DT, despacho, sala de vídeo, prensa, comedor, enfermería); sin 3 variantes por arquetipo |
| M-187 | P2 | Casas sin habitantes ni rutinas | PARCIAL | vivienda con «la familia que vive allí» (`InteriorInstalacion` l.1057); sin horarios |
| M-188 | P2 | Sin tiendas con compra real (ropa, balones) | PENDIENTE | sin compra en tiendas |
| M-189 | P2 | Sin bares/restaurantes con minijuego | PENDIENTE | sin bar con minijuego |
| M-190 | P2 | Sin clima dinámico en la ciudad (lluvia con charcos, reflejos) | PARCIAL | charcos de luz de farola (`CiudadExpansion`); sin charcos de lluvia en la ciudad |
| M-191 | P2 | Sin ciclo día/noche más allá del slider | PARCIAL | ciclo día/noche automático (`_ciclo_activo`); sin reloj real |
| M-192 | P2 | Aceras/pavimentos: 3 texturas | SIN VERIFICAR | no se midió la variedad de aceras por barrio |
| M-193 | P2 | Sin vegetación variada (setos, flores) más allá de árboles | PARCIAL | setos de jardines y casas (`CiudadExpansion._setos_t`); sin flores |
| M-196 | P2 | Botes sin sonido/estela | PENDIENTE | sin estela de botes |
| M-197 | P2 | Autopista sin peajes ni estaciones | PENDIENTE | sin peajes |
| M-198 | P2 | Aeropuerto/estación de tren inexistentes (no hay viajes) | PENDIENTE | sin viajes/aeropuerto |
| M-199 | P2 | Sin señales de tráfico reales (límites, ceda) | PENDIENTE | sin límites de velocidad con multa |
| M-200 | P2 | Sin policía/multas | PENDIENTE | sin policía |
| M-201 | P2 | Sin accidentes/eventos aleatorios | PENDIENTE | sin eventos de calle |
| M-203 | P2 | Sin colisión/oclusión de sonido en interiores | PENDIENTE | sin filtro de sonido en interiores |
| M-204 | P2 | LOD de edificios lejanos con ventanas (cristal) pero sin siluetas… | PENDIENTE | sin impostores de edificios |
| M-205 | P2 | `ciudad_expansion.gd` 2.321 líneas y `city_builder.gd` 4.687 | PENDIENTE | `ciudad_expansion.gd` creció a 3.569 líneas |
| M-206 | P2 | Sin editor de ciudad más allá de terrenos/negocios | PENDIENTE | sin editor de ciudad |

### G. Gestión del club (M-207 … M-262) · PENDIENTE 18 · PARCIAL 21 · SIN 2

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-207 | P1 | Plantillas de 25 en todos los clubes (C-05) | PENDIENTE | plantillas de 25 |
| M-208 | P1 | Caja del club propio crece de forma casi monótona (prueba larga:… | PARCIAL | 20-10: el mantenimiento de instalaciones (M-227) es un coste que crece con el club; faltan crisis |
| M-209 | P2 | La prueba larga sólo comprueba que no hay errores, no el equilibrio | PARCIAL | `prueba_larga` comprueba medias en rango; sin métricas de equilibrio |
| M-210 | P1 | Mercado: precios por reputación sin burbujas ni crisis | PARCIAL | eras con precios (`Eras`, `_probar_eras_y_precios`); sin burbujas |
| M-211 | P2 | Cláusulas de rescisión: sin «cláusulazo» automático de IA | PARCIAL | el mercado reconoce pagos de cláusula (`Mercado` l.345); sin «clausulazo» de IA deliberado |
| M-213 | P2 | Sin agentes con personalidad reflejada en comisiones (hay 4 perfiles) | PARCIAL | perfiles de agente (`MesaAgente.PERFIL`); sin historial |
| M-214 | P2 | Cesiones con opción de compra obligatoria sin seguimiento de… | PENDIENTE | cesiones sin bonus por partidos |
| M-216 | P2 | Fichajes de IA entre clubes poco visibles | SIN VERIFICAR | no se comprobó la noticia semanal de traspasos de IA |
| M-217 | P2 | Sin fichajes libres por fin de contrato anticipados (precontrato) | PENDIENTE | sin precontratos |
| M-218 | P2 | Sin límite de fair play financiero explícito (hay aviso) | PARCIAL | tope salarial con administrador (`Insolvencia`); sin ratio salarial general |
| M-219 | P1 | `Banco` e `Insolvencia` existen pero con pocos eventos de gravedad | PARCIAL | administrador, tope salarial, venta de lo que sobra, refundación (`Insolvencia`); sin descenso administrativo |
| M-220 | P2 | Sin intereses variables según reputación y mercado | PARCIAL | préstamos con tasas por tipo (`Banco`); no dinámicas |
| M-221 | P2 | Impuestos y derechos de TV simplificados | SIN VERIFICAR | derechos de TV con multiplicador; no se comprobó el reparto por país |
| M-222 | P2 | Venta de entradas: precio único | PARCIAL | precio único por partido; sin sectores ni precio por rival |
| M-223 | P2 | Abonos/socios: modelo simple | PARCIAL | socios por temporada (`Reputacion`) y campaña de abonos (`Hinchada`); sin lista de espera |
| M-225 | P2 | `Comercial` zonas de patrocinio manual para el usuario; IA sin… | PENDIENTE | sin noticias de contratos comerciales de IA |
| M-229 | P2 | Academia: sin variedad de métodos pedagógicos | PENDIENTE | sin planes pedagógicos |
| M-230 | P2 | Cantera 1.422 líneas con representantes; pocos hitos narrativos | PARCIAL | `EventosCantera`: torneo, dejarlo, padres, convocatoria; sin lesión/mudanza |
| M-231 | P2 | Ojeadores con sesgo regional (ya) sin informes visuales (campo vs… | PARCIAL | ojeadores con personalidad que infla/recorta informes (`Ojeadores`); sin informe visual |
| M-232 | P2 | Staff de 6 puestos sin personalidad ni relaciones entre sí | PENDIENTE | staff sin química |
| M-233 | P2 | Entrenamiento 1.117 líneas; sesiones sin visualización 3D | PENDIENTE | sin escenas de entrenamiento |
| M-234 | P2 | Maestrías con efecto en partido poco visible | PENDIENTE | maestrías sin registro en el resumen |
| M-235 | P1 | Lesiones: duración y recaídas ok; sin prevención visible (carga… | PARCIAL | carga y riesgo en `Medico` (l.244-254); indicador por jugador sin confirmar |
| M-236 | P2 | Vestuario 1.436 líneas con grupos; sin conflictos con… | PENDIENTE | sin discusiones visibles en partido |
| M-239 | P2 | Junta/accionistas: sin asambleas jugables | PARCIAL | asamblea en insolvencia/federación; no jugable |
| M-241 | P1 | Prensa 2.541 líneas (la mayor del núcleo): `resolver` 476 líneas | PENDIENTE | `Prensa.resolver` sigue en una función |
| M-243 | P2 | Redes sociales: seguidores y comentarios; sin bots/trolls/tendencias | PARCIAL | tendencias y hashtags (`Redes.tendencia`); sin trolls |
| M-244 | P2 | Sin entrevistas en TV con escena 3D variada (existe rueda de… | PENDIENTE | un solo set de rueda de prensa |
| M-245 | P2 | Federación 999 líneas con reglas; votaciones sin presentación | PARCIAL | votaciones con señales (`Federacion`); pantalla de sesión sin comprobar |
| M-248 | P2 | Mundial de clubes/selecciones (1.012 líneas) con pocos modos | PARCIAL | convocatorias con efecto en el físico (`Selecciones`); sin concentraciones |
| M-249 | P2 | Hinchada con segmentos; sin rivalidades por barrio | PARCIAL | clásico con incidentes (`Prensa`); sin rivalidades por barrio |
| M-250 | P2 | Ciudad y club: terrenos/negocios; economía simplificada | PENDIENTE | negocios sin depender de la ocupación |
| M-251 | P2 | Gente del club (10 personas) sin crecimiento de relaciones | PENDIENTE | gente del club sin afinidad |
| M-252 | P2 | Trabajadores/instalaciones con eventos; sin huelgas/negociación | PARCIAL | huelga de hinchas y por sueldos impagos (`Prensa`); sin negociación laboral |
| M-253 | P2 | Licencia de entrenador: exámenes; sin cursos con coste y tiempo | PENDIENTE | licencia sin cursos |
| M-254 | P2 | Vida del DT (bienestar, casa, familia): sin impacto en rendimiento… | PARCIAL | estrés en `VidaDT`; efecto en rendimiento sin comprobar |
| M-257 | P2 | Historia del club generada; sin línea de tiempo interactiva | PENDIENTE | sin línea de tiempo |
| M-258 | P2 | Documental de temporada: guion fijo | PENDIENTE | documental con guion fijo |
| M-259 | P2 | Clima en partidos con efecto menor | PARCIAL | el clima reduce las llegadas (`Partido.clima`); sin efecto en balón ni desgaste |
| M-260 | P2 | Dificultad: 3 niveles simples | PENDIENTE | sin dificultad adaptativa |
| M-261 | P2 | Sin modo historia/campaña guiada | PENDIENTE | sin modo historia |

### H. Carrera de Jugador (M-263 … M-276) · PENDIENTE 8 · PARCIAL 2 · SIN 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-263 | P1 | Eventos únicos (13) y control real; pocos días de «vida» entre… | PENDIENTE | sin agenda semanal |
| M-265 | P2 | Avatar propio sin personalización de cuerpo | PENDIENTE | sin personalización del cuerpo |
| M-266 | P2 | Sin entrenador como NPC con diálogos sobre el jugador | PARCIAL | `relacion_dt` decide minutos; sin entrenador con diálogos |
| M-267 | P2 | Transferencias vistas desde el jugador: ofertas sin negociación… | PENDIENTE | la Carrera no usa `MesaAgente` |
| M-268 | P2 | Selección nacional: convocatorias sin escena | PARCIAL | convocatoria como evento; sin cinemática |
| M-269 | P2 | Lesiones del jugador: sin recuperación jugable (fisio) | PENDIENTE | sin rehabilitación jugable |
| M-270 | P2 | Retiro con paso a DT ok; sin homenaje | PENDIENTE | sin homenaje de retiro |
| M-271 | P2 | Sin contratos de imagen propios | PENDIENTE | sin contratos de imagen |
| M-272 | P2 | Fuera de juego, cambios, selección ✅; sin protestas/tarjetas del… | PENDIENTE | sin expediente disciplinario |
| M-273 | P2 | Rivales NPC por `Fama`; sin rivalidades nominales | PENDIENTE | sin rival de posición |
| M-276 | P2 | Pruebas: modo cubierto en `prueba_modos`; faltan casos extremos… | SIN VERIFICAR | no se comprobaron los casos extremos en `prueba_modos` |

### I. Interfaz, menús, accesibilidad (M-277 … M-312) · PARCIAL 13 · PENDIENTE 13 · SIN 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-277 | P1 | 274 textos en español directamente en `ui/` (I-02), concentrados… | PARCIAL | ✅ 15-10: 1.132 textos envueltos; quedan ~15 (M-447) |
| M-278 | P1 | `ui/principal.gd` 6.655 líneas (y 3 funciones >330) | PENDIENTE | `principal.gd` con 6.777 líneas |
| M-279 | P1 | 27 módulos de `visor/` y 8 de `nucleo/` sin referencia directa en… | PENDIENTE | los módulos siguen sin prueba directa |
| M-280 | P1 | 105 módulos de UI/visor sin referencia en banco/pruebas | PENDIENTE | sin prueba visual automática |
| M-283 | P2 | Sin subtítulos/indicadores visuales de sonido | PENDIENTE | sin avisos visuales de sonido |
| M-284 | P2 | Sin modo lectura de pantalla (TTS) | PENDIENTE | sin TTS |
| M-285 | P2 | Navegación por mando en menús (panel de controles sí) | PARCIAL | navegación con mando en el panel de controles; no en todos los menús |
| M-287 | P2 | Rendimiento de menús: refresco ya 14× más rápido; sin pruebas de… | PENDIENTE | sin medida de apertura de pantallas |
| M-289 | P2 | Menú lateral con 9 menús; Ciudad/Editar completados; Ajustes sólo… | PENDIENTE | Ajustes sigue con 3 tarjetas (`MenuLateral`) |
| M-290 | P2 | Tarjetas con dato vivo sólo en algunas (`Menu.dato`) | PARCIAL | `MenuLateral.dato` existe; no todas las tarjetas |
| M-292 | P2 | Sin favoritos/marcadores de jugadores o clubes | PARCIAL | favoritos de pestañas; sin seguimiento de jugadores/clubes |
| M-293 | P2 | Tablas con filtros limitados (plantel) | PARCIAL | filtros en plantel/libres |
| M-294 | P2 | Comparador de jugadores existe; sin comparativa de club/estadio | PARCIAL | comparador de jugadores; sin club/estadio |
| M-295 | P2 | Sin gráficos históricos (valor, forma) en ficha | SIN VERIFICAR | «crecimiento por temporada» en la ficha; sin gráficos verificados |
| M-296 | P2 | Notificaciones (`Aviso`) sin centro de notificaciones | PARCIAL | bandeja de correo; sin filtros |
| M-297 | P2 | Tutorial: ciudad y controles; falta tutorial de gestión (primer mes) | PENDIENTE | sin tutorial de gestión |
| M-299 | P2 | Sin confirmaciones consistentes para acciones destructivas… | PARCIAL | `CuadroDialogo` en despacho/principal; no uniforme en vender/despedir |
| M-300 | P2 | Sin deshacer en acciones de pizarra | PENDIENTE | sin deshacer en pizarra |
| M-302 | P2 | Sin tema claro/alto contraste | PENDIENTE | sin tema claro/alto contraste |
| M-303 | P2 | Cursor/hover sin feedback sonoro consistente en todos los… | PARCIAL | `BotonFx` en todos los botones; pestañas/listas sin sonido |
| M-304 | P2 | Animaciones de transición entre pantallas desiguales | PARCIAL | `Animar` en 16 archivos; sin sistema común de transición |
| M-305 | P2 | Tooltips escasos | PARCIAL | 103 tooltips |
| M-307 | P2 | Resoluciones: pensado 1280×720–1600×900; sin pruebas en 4:3, 21:9… | PENDIENTE | sin capturas por aspecto |
| M-308 | P2 | DPI alto: texto del `Label3D` en 3D no escala | PENDIENTE | `pixel_size` fijo |
| M-310 | P2 | Sin pantalla «Novedades» tras actualizar | PENDIENTE | sin «Novedades» |
| M-311 | P2 | Sin perfil de jugador (estadísticas globales) | PARCIAL | `PanelMeta` (álbum/museo global); sin perfil de estadísticas |
| M-312 | P2 | Sin modo «streamer» (ocultar datos sensibles/real) | PARCIAL | ajuste «Caras reales: FOTO / RECREACIÓN» (`Cara.usar_fotos`); sin modo streamer |

### J. Audio y música (M-313 … M-324) · PENDIENTE 7 · PARCIAL 3 · 🔒 2

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-313 | P2 | `Sonido._sintetizar` 1.000 líneas: efectos sintetizados sin editor | PENDIENTE | `_sintetizar` sigue monolítica |
| M-314 | P2 | Sin mezcla dinámica (ducking de música en diálogo/gol) | PENDIENTE | sin ducking |
| M-315 | P2 | Música (`Musica` 384 líneas, procedural): sin variaciones por mood… | PARCIAL | `Musica` con capas por estado |
| M-316 | P2 | Cantos de hinchada genéricos | PARCIAL | cánticos sintetizados; sin sincronía con el juego |
| M-317 | P2 | Sin comentarista | 🔒 DUEÑO | narración por voz = audios (decisión del dueño; COMPARACION_JUEGOS_2) |
| M-318 | P2 | Sin sonidos de pisadas por superficie en partido | PENDIENTE | sin pisadas |
| M-319 | P2 | Sin eco/reverb en túnel/vestuario/estadio | PARCIAL | sonido «eco_estadio»; sin reverb por zona |
| M-320 | P2 | Sonido del balón (patada) sin variación por tipo/potencia | PENDIENTE | sin variantes de patada por potencia |
| M-321 | P2 | Volúmenes por bus sin perfil «noche»/audífonos | PENDIENTE | sin presets de volumen |
| M-322 | P2 | Sin audio espacial en la ciudad (fuentes 3D) | PENDIENTE | sin audio espacial (0 `AudioStreamPlayer3D`) |
| M-323 | P3 | Sin música licenciada (decisión del dueño) | 🔒 DUEÑO | música licenciada: decisión del dueño |
| M-324 | P2 | Sin prueba que detecte clipping/silencios | PENDIENTE | sin prueba de clipping |

### K. Idiomas y textos (M-325 … M-336) · PENDIENTE 4 · PARCIAL 2

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-328 | P2 | Patrones numéricos (`patrones` 58) con plurales simples | PENDIENTE | sin reglas de plural por idioma |
| M-329 | P2 | Sin género gramatical (entrenadora/jugadora) en todos los idiomas | PARCIAL | `Genero` solo en español |
| M-330 | P2 | Formatos de fecha/número por idioma | PENDIENTE | sin `Idiomas.fecha/numero` |
| M-332 | P2 | Narración traducida (`narracion.json`) sin revisión nativa | PENDIENTE | sin revisión nativa |
| M-333 | P2 | Texto en imágenes (carteles del 3D) sin traducir | PARCIAL | textos de `visor/` envueltos en `Idiomas.t` (15-10); carteles dibujados sin comprobar |
| M-334 | P2 | Sin RTL (árabe, hebreo) aunque hay KSA/EGY/MAR | PENDIENTE | sin RTL |

### L. Rendimiento y optimización (M-337 … M-358) · 🔒 2 · PARCIAL 8 · PENDIENTE 9

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-337 | P0 | No hay perfil en hardware real (R-01) | 🔒 DUEÑO | perfil en hardware real |
| M-338 | P1 | Partido ALTO ≈ 2,3 M tris/700 llamadas | PARCIAL | partido ALTO 0,76 M tris / 630 llamadas (17-10); sin presupuesto por categoría escrito |
| M-339 | P1 | Césped en capas ≈ 230 k tris/57 llamadas | PENDIENTE | capas del césped hasta 46 m sin LOD extra |
| M-341 | P1 | Sombras: 4 cortes en ALTO; sin ahorro medible al bajar (probado),… | 🔒 DUEÑO | coste de sombras en GPU real |
| M-343 | P2 | Draw calls 700 | PARCIAL | sombras en 8 mallas por sector (741→691) y 630 llamadas; sin atlas |
| M-344 | P2 | Overdraw en grada por butacas y personas | PARCIAL | 21-10: oclusión en la CIUDAD (`OclusoresCiudad`, 1.120 paredes): −16 % de llamadas a pie de calle (12.128 → 10.192 en 4 calles, `medir_oclusion`); en la grada del estadio sigue sin `OccluderInstance3D` |
| M-345 | P2 | Culling por trozos para MultiMesh grandes | PENDIENTE | sin culling por trozos de MultiMesh |
| M-346 | P2 | Texturas con compresión (s3tc en PC); sin variantes móviles… | PARCIAL | 21-10: revisado: las texturas grandes de 3D ya están en VRAM (s3tc) y limitadas (ropa 4K → 1024); las 3.103 sin comprimir son caras reales, iconos 2D y paletas de Kenney, que se dejan sin pérdida a propósito; sin etc2/astc para móvil |
| M-347 | P2 | VRAM 539 MB en partido | PARCIAL | texturas del globo comprimidas (72→13 MB); VRAM del partido sin remedir |
| M-348 | P2 | Carga: `Precarga` existe; primera construcción de estadio larga | PENDIENTE | sin caché en disco de mallas generadas |
| M-349 | P2 | Generación de `Mundo` (384 clubes) y `Reales.aplicar`: medir… | PENDIENTE | sin `WorkerThreadPool` |
| M-350 | P2 | `avanzar_semana` 532 líneas: tiempo por semana desconocido | PENDIENTE | sin perfil por semana |
| M-351 | P2 | Hilos: ¿se usan para IA/ciudad? | PENDIENTE | sin hilos para tráfico/peatones (solo LOD del tráfico) |
| M-352 | P2 | GC/alloc en `_process` (Dictionary por jugador) | PENDIENTE | sin Packed arrays en el motor |
| M-353 | P2 | Valorar C#/GDExtension sólo si el motor domina CPU | PENDIENTE | sin medición previa |
| M-354 | P2 | `RendimientoAdaptativo` existe; documentar umbrales y probarlos | PARCIAL | `pruebas/probar_rendimiento_adaptativo.gd`; no está en el banco |
| M-355 | P2 | Sin modo batería/60→30 FPS en móvil | PARCIAL | límite de FPS 30/60/120 (`Principal.FPS_OPCIONES`); sin modo batería |
| M-356 | P2 | Memoria de la ciudad ×4 (2.640 m) | PENDIENTE | sin streaming por celdas |
| M-357 | P2 | Capturas pesadas en repo (`pruebas/capturas`) | PARCIAL | `.gitignore` de promo/lotes y JPG por defecto; resto en repo |

### M. Datos y contenido (M-359 … M-378) · PENDIENTE 13 · SIN 1 · PARCIAL 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-359 | P1 | Estadio real en 46 % de clubes (C-01) | PENDIENTE | 46 % |
| M-361 | P2 | `tablas.json` en una línea (D-04) | SIN VERIFICAR | no se revisó `tablas.json` |
| M-362 | P2 | `ESTADIO_CLUB` por nombre (frágil con leetspeak) | PENDIENTE | `ESTADIO_CLUB` por nombre |
| M-363 | P2 | Mapa ficticio→real (`CLUBES` en `base_ficticia.py`) sin prueba de… | PENDIENTE | sin prueba de cobertura |
| M-364 | P2 | Países: 23 con 16 clubes (Chile 32) | PENDIENTE | sin ligas nuevas |
| M-367 | P2 | Calendario con feriados (`Calendario` 350 líneas); sin zonas horarias | PENDIENTE | sin zonas horarias |
| M-368 | P2 | Jugadores históricos/leyendas sin mecánica de «cromo» | PENDIENTE | leyendas sin cromo |
| M-369 | P2 | Nombres de estadios ficticios sin apodos amplios (`GuinosEstadio`) | PENDIENTE | `GuinosEstadio` sin ampliar |
| M-370 | P2 | Historia de clubes (`historia_clubes.py`) por club; verificación… | PENDIENTE | sin prueba de coherencia |
| M-371 | P2 | Himnos y cánticos sin letra | PENDIENTE | himnos sin letra |
| M-372 | P2 | Retratos de DT/presidente generados; sin variedad étnica medida | PENDIENTE | sin estadística por país |
| M-373 | P2 | Bandera de cada país como pieza; verificar que son las correctas y… | PENDIENTE | sin prueba visual de banderas |
| M-376 | P2 | Premios individuales sin votación explicada | PENDIENTE | sin votación explicada |
| M-377 | P2 | Sin clima por país/estación realista | PARCIAL | `Clima.del_partido` por país/estación; sin tabla completa verificada |
| M-378 | P2 | Sin datos de ciudades (población, altura) para estadios | PENDIENTE | sin datos de ciudades |

### N. Código y arquitectura (M-379 … M-402) · PENDIENTE 17 · PARCIAL 1 · SIN 2

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-379 | P2 | 64 funciones > 120 líneas (Q-01): `Sonido._sintetizar` 1.000,… | PENDIENTE | funciones largas sin partir |
| M-380 | P2 | `pruebas/banco.gd` 8.029 líneas | PENDIENTE | `banco.gd` con 8.454 líneas |
| M-382 | P2 | Sin análisis estático | PENDIENTE | sin gdlint |
| M-383 | P2 | Tipado: muchos `Dictionary` sin forma (jugadores del motor) | PENDIENTE | sin `JugadorMotor` tipado |
| M-384 | P2 | `Mundo` 2.921 líneas, `Roles` 2.065, `Prensa` 2.541: acoplamiento alto | PENDIENTE | sin extraer servicios |
| M-385 | P2 | Autoloads con globals (`Datos`, `Sonido`…) | PENDIENTE | sin documentar autoloads |
| M-386 | P2 | Señales sin desconexión en liberación (posibles fugas) | PARCIAL | `auditoria_tecnica.gd` mide huérfanos en la pantalla principal; 21-10: el panel de objetivos pasa a señal (`vista_cambiada`) y respaldo cada 3 s, sin fallar con las pestañas prestadas a un menú |
| M-387 | P2 | Mensajes de error silenciosos (`return` sin aviso) | PENDIENTE | sin registro de errores |
| M-388 | P2 | Constantes mágicas (balance) dispersas | PENDIENTE | sin archivo de balance |
| M-391 | P2 | Duplicación entre `MatchPlayback` y `MotorJugable` | PENDIENTE | duplicación sin retirar |
| M-392 | P2 | `MotorLibre` prototipo (546 líneas) sin uso claro | PENDIENTE | `MotorLibre` sigue (545 líneas); 20-10: con la base ficticia da 12,5 goles de media entre iguales (su prueba fija ahora la base real para no depender del orden) |
| M-393 | P2 | Código de pruebas mezclado con herramientas (`herramientas/*.ps1`) | PENDIENTE | sin separar |
| M-394 | P2 | Herramientas `.exe`/`.cs` binarias en repo | PENDIENTE | `herramientas/*.exe` siguen en el repo |
| M-396 | P2 | Convenciones: mezcla de español/inglés en nombres | PENDIENTE | sin guía de estilo |
| M-397 | P2 | Comentarios muy extensos (valioso pero ruidoso) | PENDIENTE | sin ADRs |
| M-398 | P2 | Sin documentación de arquitectura actualizada (`LEEME.md`) | PENDIENTE | LEEME sin diagrama |
| M-399 | P2 | Versión de guardado (`VERSION`) con migración mínima | SIN VERIFICAR | no se revisaron migraciones |
| M-400 | P2 | Sin límites de memoria en historiales (noticias, prensa) | SIN VERIFICAR | no se revisaron topes de historiales |
| M-401 | P2 | Dependencia de nombres de nodo (`find_child`) frágil | PENDIENTE | sin cambio |
| M-402 | P2 | Duplicación de carga de JSON (`Datos` 212 tablas) | PENDIENTE | sin carga perezosa |

### O. Pruebas y herramientas (M-403 … M-418) · PARCIAL 3 · PENDIENTE 10

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-403 | P1 | 8 módulos de `nucleo/` sin referencia en pruebas:… | PARCIAL | Logros y Negociación cubiertos de forma indirecta (`_probar_logros`, `_probar_negociacion`); los otros 6 no |
| M-404 | P1 | 27 módulos de `visor/` sin referencia: `Ambience`, `Autopista`,… | PENDIENTE | solo `CameraRig` aparece en el banco |
| M-405 | P1 | Pruebas visuales manuales (242 capturas) | PENDIENTE | sin comparación de imágenes |
| M-406 | P2 | `Retrato3D` no se ejercita en headless | PENDIENTE | sin prueba con xvfb |
| M-407 | P2 | Sin pruebas de conducción/ciudad (V-06) | PENDIENTE | sin prueba de conducción |
| M-408 | P2 | Sin pruebas de minijuegos 3D | PARCIAL | `prueba_minijuegos_nuevos` (2D); minijuegos 3D sin prueba |
| M-409 | P2 | Sin pruebas de menús/UI de integración (abrir cada pantalla sin error) | PARCIAL | `_probar_carga_de_ui` en el banco; sin recorrido por pestañas |
| M-410 | P2 | Sin pruebas de rendimiento con umbrales | PENDIENTE | sin umbrales de rendimiento |
| M-413 | P2 | `auditoria_clubes`/`auditoria_datos` no están en el banco | PENDIENTE | auditorías fuera del banco |
| M-414 | P2 | Resultados de sondas (calidad/táctica/simetría) sin umbrales | PENDIENTE | sondas sin umbrales |
| M-416 | P2 | Sin CI en GitHub Actions | PENDIENTE | sin GitHub Actions |
| M-417 | P2 | `herramientas/banco.sh` sólo bash | PENDIENTE | sin unificar |
| M-418 | P2 | Sin informes de cobertura | PENDIENTE | sin cobertura |

### P. Repositorio, build y legal (M-419 … M-432) · 🔒 4 · PENDIENTE 7 · PARCIAL 2

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-419 | P1 | `.git` 5,5 GB con punteros LFS antiguos (D-03) | 🔒 DUEÑO | historial/LFS: decisión del dueño |
| M-420 | P1 | Builds públicos sin datos reales (caras, fotos): comprobar con… | PENDIENTE | sin prueba del .pck |
| M-421 | P1 | Derechos de imagen de jugadores reales (decisión del dueño) | 🔒 DUEÑO | derechos de imagen |
| M-422 | P2 | 8 presets de exportación; sin pruebas de compilación | PENDIENTE | sin CI de exportación |
| M-423 | P2 | Android: keystore del dueño (regla) | 🔒 DUEÑO | keystore |
| M-424 | P2 | Licencias de terceros (Kenney CC0, Quaternius, Anderson Rohr):… | PARCIAL | `LICENCIAS.md` con los kits Kenney (15-10); sin auditoría automática |
| M-425 | P2 | Créditos de fotos (`creditos_fotos.txt`) sólo para el pack real | PENDIENTE | créditos de fotos sin pantalla |
| M-426 | P2 | Archivos grandes sueltos (`.glb` >5 MB) | PENDIENTE | sin compresión de GLB grandes |
| M-427 | P2 | `pruebas/capturas` crece sin control | PARCIAL | carpetas promo/lotes ignoradas; capturas siguen en el repo |
| M-428 | P2 | `.zip` de terceros dentro de `recursos/` (punteros LFS) | 🔒 DUEÑO | archivos de terceros con LFS: decisión del dueño |
| M-429 | P2 | Versionado del juego sin número visible | PENDIENTE | sin versión visible |
| M-430 | P2 | Sin canal de reporte de errores | PENDIENTE | sin reporte de errores |
| M-432 | P2 | Sin política de contenido (religión/política ficticia) | PENDIENTE | sin lista en CI |

### Q. Móvil, táctil y mando (M-433 … M-442) · PARCIAL 2 · PENDIENTE 7

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-433 | P1 | Controles táctiles sólo en la ciudad (cruceta/E) | PARCIAL | 21-10: en PC ya no salen la cruceta ni «Salir» al pasear (estadio y ciudad) y la E solo aparece si hay algo con lo que interactuar (`ExploradorCiudad.es_tactil`); el partido sigue sin controles táctiles |
| M-435 | P2 | Sin gatillos analógicos para potencia de pase | PENDIENTE | sin gatillos analógicos |
| M-436 | P2 | Sin giroscopio para cámara en primera persona (móvil) | PENDIENTE | sin giroscopio |
| M-437 | P2 | Sin detección de dispositivo para cambiar iconos en tiempo real… | PARCIAL | `dispositivo_detectado` en panel de controles y `ControlFC`; guía del partido sin comprobar |
| M-438 | P2 | UI de móvil: botones pequeños | PENDIENTE | sin tamaño mínimo |
| M-439 | P2 | Orientación vertical no soportada | PENDIENTE | sin vertical |
| M-440 | P2 | Sin modo una mano | PENDIENTE | sin modo una mano |
| M-441 | P2 | Sin soporte de teclado en pantalla para nombres | PENDIENTE | sin teclado en pantalla |
| M-442 | P2 | Mando: botones reasignables guardados pero sin perfiles múltiples | PENDIENTE | sin perfiles de mando |

### R. Pasada 3 (M-443 … M-470) · PENDIENTE 25 · PARCIAL 1

| Id | Prio. | Punto | Estado | Evidencia / lo que falta |
|---|---|---|---|---|
| M-444 | P2 | Fuga de texturas GL al cerrar `prueba_carrera_flujo` | PENDIENTE | fuga de texturas sin arreglar (INFORME_INTERNO H-12) |
| M-445 | P2 | Pruebas que no caben en 5 min con render por software (`intro`,… | PENDIENTE | sin modo rápido del arnés (H-13) |
| M-447 | P1 | Las cadenas en español escritas directo en `ui/` (I-02): antes 573… | PARCIAL | ✅ 15-10 salvo 15 textos |
| M-448 | P2 | `auditoria_clubes` tarda ~8 min y `auditoria_datos` ~1 min | PENDIENTE | sin muestra |
| M-449 | P2 | Los informes (`AUDITORIA_CLUBES.csv`) se regeneran a mano | PENDIENTE | sin CI nocturno |
| M-450 | P2 | `pruebas/prueba_*` no tienen un índice de «qué cubre cada una» | PENDIENTE | sin índice de pruebas |
| M-451 | P2 | Duplicación del arnés (`_ok`, `_fallos`) en decenas de pruebas | PENDIENTE | sin `PruebaBase` |
| M-452 | P2 | Salida de pruebas sin código de retorno uniforme (algunas… | PENDIENTE | varias pruebas acaban con `quit()` sin código |
| M-453 | P2 | Pruebas ligadas al azar sin semilla fija en algunos casos (la IA… | PENDIENTE | sin semillas fijas generalizadas |
| M-454 | P2 | Capturas que cambian el estado de la máquina (ajustes de… | PENDIENTE | sin restaurar |
| M-455 | P2 | Pruebas que escriben en `user://ajustes.cfg` real (E-10) | PENDIENTE | sin ruta inyectable |
| M-456 | P2 | `auditoria_tecnica` solo carga las escenas de `escenas/` y `ui/` (4) | PENDIENTE | sin cambio |
| M-457 | P2 | Los nodos huérfanos se miden solo en la pantalla principal | PENDIENTE | sin cambio |
| M-458 | P2 | Sin comprobación de que cada `Label` traducible esté dentro de un… | PENDIENTE | sin cambio |
| M-459 | P2 | Cinco idiomas de los nueve nacieron con frases que luego se… | PENDIENTE | sin flujo único |
| M-460 | P2 | Las traducciones nuevas (552) están hechas a mano sin revisión nativa | PENDIENTE | sin marcar |
| M-461 | P2 | Las cadenas con `%s`/`%d` dependen del orden de argumentos; en… | PENDIENTE | sin placeholders con nombre |
| M-462 | P2 | Etiquetas de botón con emoji/caracteres (💾 ↺ ● ✔ ▸ ◯) pueden no… | PENDIENTE | sin prueba de glifos |
| M-463 | P2 | `Idiomas.t` devuelve la clave si falta (silencioso) | PENDIENTE | sin registro de clave faltante |
| M-464 | P2 | No existe un informe de «frases por pantalla»: no se sabe qué… | PENDIENTE | sin informe por pantalla |
| M-465 | P3 | Sin pruebas de rendimiento de la carga de idiomas (`idiomas.gd`… | PENDIENTE | sin carga perezosa |
| M-466 | P2 | `datos/idiomas_extra.json` se reescribe entero con cada ampliación… | PENDIENTE | un solo archivo |
| M-467 | P2 | Falta un chequeo de longitud de texto (alemán/finés largo) en botones | PENDIENTE | sin chequeo de longitud |
| M-468 | P2 | Plurales y géneros en las 69 frases nuevas (p. ej. «%d botones»)… | PENDIENTE | sin plurales |
| M-469 | P3 | Falta documentación del flujo de pruebas para colaboradores | PENDIENTE | sin sección en LEEME |
| M-470 | P2 | El banco no ejecuta `auditoria_tecnica`, `auditoria_datos` ni las… | PENDIENTE | banco sin auditorías |

## Ideas del dueño aún abiertas (de las 350 de `docs/02_vision/ideas_del_dueno/`)

**Ideas PENDIENTES** (no se encontró nada en el código):

- **Personalización visual**: 39. Colecciones especiales (edición aniversario, homenaje); 40. Personalización del logo del club en redes sociales; 42. Personalización del himno/cántico del club; 45. Diseño de banderines y merchandising.
- **Economía y Finanzas**: 118. Fondo de emergencia del club; 120. Bonos e incentivos fiscales por inversión en cantera.
- **Auspicios y Marketing**: 125. Sponsor de entrenamiento; 130. Colaboraciones con marcas para ediciones limitadas; 131. Sponsors regionales vs. internacionales; 133. Sponsors "sorpresa" que ofrecen tratos únicos; 135. Ferias/eventos de marca para aumentar reputación.
- **Fans y Comunidad**: 144. Fan zone fuera del estadio en días de partido; 145. Programa de fidelización de hinchas.
- **Medios y Prensa**: 162. Ranking de prensa sobre mejores DTs/presidentes; 164. Reportajes especiales sobre la cantera.
- **Premios y Reconocimientos**: 177. Mejor arquero del año; 179. Mejor presidente/dueño del año; 183. Premio al club más popular.
- **Rivalidades y Clásicos**: 204. Eventos especiales previos al clásico; 206. Fichajes polémicos entre rivales; 208. Comparación de logros con el rival histórico.
- **Legado e Historia del Club**: 211. Línea de tiempo histórica del club; 219. Leyendas como mentores de la cantera.
- **Extras y Sistemas Meta**: 231. Modo historia con objetivos guiados; 234. Guardado de partida en la nube; 238. Comparación con otros jugadores (si hay online); 240. Modo "carrera rápida" para partidas cortas; 250. Modo multijugador asíncrono (comparar ligas entre amigos).
- **Detalles de Ambientación**: 257. Impacto económico del club en la ciudad ficticia.
- **Sistemas de Jugadores (detalle extra)**: 269. Patrocinios personales de jugadores (compite con el club).
- **Eventos de Crisis y Oportunidad**: 272. Boom económico repentino de un sponsor; 275. Oferta de fusión con otro club (dilema); 279. Presión por bajar precios de entradas.
- **Progresión y Metas**: 283. Ranking histórico de mejores gestiones (leaderboard interno).
- **Toques Finales de Personalización**: 294. Personalización del bus del equipo.
- **Récords, Historia y Memoria del Club**: 318. Línea de tiempo navegable de temporadas anteriores; 324. Historial de presidentes/DTs anteriores y su legado.
- **Sala de Trofeos y Celebraciones**: 332. Exhibición temporal de un trofeo destacado en el estadio; 333. Ceremonia de entrega de camiseta homenaje en aniversarios; 334. Muro de campeones con fotos de planteles ganadores.
- **Más Ideas Adicionales**: 345. Resumen de prensa internacional si el club gana notoriedad; 348. Eventos climáticos que afectan la asistencia y el ánimo del público; 349. Modo "reconstrucción": heredar un club en crisis y sanearlo.

**Ideas PARCIALES**: 15, 34, 41, 43, 44, 50, 51, 52, 66, 67, 68, 71, 73, 80, 85, 90, 101, 114, 127, 128, 129, 132, 142, 147, 149, 152, 153, 154, 165, 176, 182, 184, 185, 191, 195, 199, 202, 205, 207, 209, 210, 215, 226, 229, 233, 237, 244, 246, 253, 256, 258, 259, 260, 263, 266, 268, 270, 273, 277, 278, 287, 288, 289, 290, 292, 293, 295, 296, 297, 299, 319, 320, 325, 327, 331, 335, 336, 337, 339, 340, 346, 350. Sin verificar: 2 (niveles de estadio «inhumanos»: hay topes de nivel, no se comprobó si el estadio los tiene).

## 4. TOP 25 PENDIENTES por impacto ÷ coste

Sin lo del dueño. **Impacto** = cuánto lo nota el jugador (3 alto, 2 medio, 1 bajo); **coste** estimado (1 poco: horas · 2 medio: un día o dos · 3 mucho). Orden por impacto ÷ coste y, a igualdad, por impacto. Incluye PENDIENTES y PARCIALES cuya parte que falta es la visible.

| # | Id | Qué | Impacto | Coste | Por qué / cómo |
|---:|---|---|---:|---:|---|
| 1 | M-072 | Árbitros con color por liga y contraste con los dos equipos (hoy siempre de negro) | 3 | 1 | se ve en cada plano del partido; tabla de 3 colores + regla de contraste en `PlayerSpawner.spawn_arbitros` |
| 2 | M-106 | Gestos del árbitro en el motor real (falta, ventaja, tarjeta, córner) | 3 | 1 | los clips `arbitro_*` ya existen y se usan en `MatchPlayback`; falta llamarlos desde `MotorJugable` |
| 3 | M-139 | Cartel del cuarto árbitro con el tiempo añadido | 2 | 1 | el añadido real ya se calcula (45'+1:23); falta el cartel 3D/2D |
| 4 | M-050 | Confeti, bengalas y humo de color en goles y salida | 2 | 1 | `GPUParticles3D` ya se usa en `Precipitacion`; engancharlo a la señal `gol` |
| 5 | M-149 | Red del arco que se ondula al gol | 2 | 1 | shader de vértice en la malla de la red, con impulso en el punto de entrada |
| 6 | M-118 | Línea de fuera de juego visible en la sala VAR | 2 | 1 | `margen_gol` ya da la posición; dibujar dos líneas en `SalaVAR` |
| 9 | M-434 | Vibración del mando en gol, choque y entrada | 2 | 1 | `Input.start_joy_vibration` en las señales del motor |
| 12 | M-057 | Fabricantes de ropa inventados con logo propio por club | 2 | 1 | hoy una sola «ala» genérica en el shader |
| 15 | M-123 | Línea defensiva común: subir/bajar y trampa del fuera de juego | 3 | 2 | último 40 % del punto 7 de la MEGA AUD. 2 |
| 16 | M-114 | Separar reposiciones y suavizar giros bruscos del balón y los cuerpos (con M-115) | 3 | 2 | la sonda ya mide los dos problemas |
| 17 | M-263 | Semana con agenda en la Carrera de Jugador (entreno, descanso, vida social) | 3 | 2 | hoy hay eventos sueltos entre partidos |
| 18 | M-040 | Personas del club y de la ciudad en las primeras filas | 2 | 2 | pendiente reconocido en MEGA AUD. 2 (punto 2 al 80 %) |
| 19 | M-033 | Variedad de ropa y peinado en los hinchas (torso y pelo por instancia) | 2 | 2 | hoy color por instancia + shader |
| 20 | M-036 | Público que reacciona al gol en onda desde el sector y hace la ola | 2 | 2 | con M-044; todo en `hinchada.gdshader` por uniformes |
| 21 | M-132 | Repetición manual de los últimos 10 s | 2 | 2 | `Repeticion` ya graba |
| 22 | M-173 | Sonido del motor del coche con RPM (y radio con sonidos propios) | 2 | 2 | conducción mejorada sin sonido; sin música con licencia |
| 23 | M-178 | Minimapa y GPS hacia el club en la ciudad (con M-179) | 2 | 2 | `camino_entre` ya calcula rutas |
| 24 | M-130 | Modo práctica / entrenamiento libre para aprender los controles FC (con M-152) | 2 | 2 | 65+ combinaciones sin lugar donde probarlas |
| 25 | M-275 | Quitar el país «XXX» del rival en la Carrera de Jugador | 1 | 1 | una línea (`carrera_jugador.gd:620`) y comprobar banderas |

Fuera del TOP por ser del dueño: perfil de FPS en hardware real (M-337, M-341), narración por voz (M-317), música (M-323), historial/LFS, derechos de imagen y keystore (M-419, M-421, M-423, M-428).

