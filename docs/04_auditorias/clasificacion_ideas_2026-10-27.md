# Clasificación de las ideas pendientes del plan (27-10-2026)

Fuente: `docs/PLAN_DEL_LUNES.md` §5, §6 y §7 tal como estaban el 27-10. Criterio: LANZAMIENTO = hace falta para lanzar el 15-12-2026; DESPUÉS = vale la pena, tras lanzar; DESCARTAR = repetida, superada por algo hecho, contraria a una decisión del dueño o sin aporte. Las «Existen: falta una prueba» y las «Declaradas hechas sin prueba» van en un bloque aparte «verificar»: LANZAMIENTO si tocan el partido o la primera hora, DESPUÉS el resto. En la duda entre DESPUÉS y DESCARTAR, DESPUÉS.

## 1. Resumen

| Sección | Filas | LANZAMIENTO | Verificar (LANZ.) | DESPUÉS | Verificar (DESP.) | DESCARTAR |
|---|---|---|---|---|---|---|
| §5 Mejoras del catálogo | 338 | 55 | 0 | 266 | 0 | 17 |
| §6 Pendientes | 43 | 0 | 0 | 35 | 0 | 8 |
| §6 Parciales | 82 | 2 | 0 | 77 | 0 | 3 |
| §6 Declaradas hechas sin prueba | 38 | 0 | 6 | 0 | 30 | 2 |
| §7 Existen sin prueba | 306 | 0 | 37 | 0 | 266 | 3 |
| §7 Parciales | 222 | 9 | 0 | 202 | 0 | 11 |
| §7 No existen | 172 | 2 | 0 | 151 | 0 | 19 |
| **Total** | **1201** | **68** | **43** | **731** | **296** | **63** |

Aparte: **20 decisiones de producto** (§7, final) sin clasificar: «Decide el dueño» (punto 5). Total revisado: 1201 filas + 20 = 1221.

Los encabezados del plan dan cifras viejas (F0 «33» tiene 23 filas, F1 «36» tiene 32, F6 pulido «82» tiene 79, «dueño (27)» tiene 26, «Existen (335)» tiene 306, «No existen (173)» tiene 172): se borraron filas hechas sin actualizar el título. Aquí se cuentan las filas reales.

**Estimación honesta del trabajo de LANZAMIENTO**

- Filas: 68 de construir o arreglar (P0: 4, P1: 26, P2: 38) + 43 de verificar jugando (escribir la prueba que dice «cómo probar» y mirarlo). Total 111.
- Ritmo de referencia: hoy 3 sesiones cerraron 30-40 filas o piezas en un día ≈ 10-13 por sesión-día, pero eran piezas pequeñas o medianas.
- Verificar (43): pruebas cortas, ~15 por sesión-día → **3 sesiones-día**.
- Filas pequeñas (traducciones, textos que prometen lo que no hay, glifos, confirmaciones, amarillas, créditos, privacidad, tamaños de botón; ~30): **3-4 sesiones-día**.
- Filas grandes, que son proyectos y no filas: dificultad de la CPU en 8 niveles + dificultades de gestión (M-260, 233), pasada final del motor con roles, portero y sonidos (M-125, M-128, M-131, M-022, M-096, M-097, M-318, M-320, 1064), policía/bomberos/incidentes (M-200, M-201, M-199), tráfico y edificios entrables (M-171, M-186, M-183), tutorial por capas (1040), controles táctiles del partido (M-433), migraciones de guardado (1094), balance económico (M-208) y la tanda de rendimiento (12 filas): **~20-25 sesiones-día**.
- **Total: ~26-32 sesiones-día** (≈ 9-11 días con 3 sesiones a la vez), sin contar lo que solo puede hacer el dueño (FPS en hardware real, sombras en GPU, keystore, licencias, derechos de imagen, música, revisión nativa de traducciones) ni el trabajo de lanzamiento que vive fuera de estas secciones (§2 fases 4-6, §3 semanas 6-9: prueba de 10 temporadas, recorrido pantalla por pantalla, «ciudad completa» con los recursos sin usar, museo interactivo, peluches, vehículos y butacas en Forward+). Con margen para lo que salga al jugar, cabe holgado antes del 15-12 si no se abren frentes de DESPUÉS.

## 2. LANZAMIENTO

### P0

**Rendimiento**
- M-337: Perfil de FPS en hardware real, PC modesto y móvil (dueño).

**Legal**
- M-420: Builds públicos sin caras ni fotos reales: prueba del .pck.
- M-421: Derechos de imagen de jugadores reales (dueño).
- M-424: Auditoría de licencias de terceros (Kenney, Quaternius, Anderson Rohr, Sketchfab, Meshy…).

### P1

**Partido**
- M-260: Dificultad de la CPU en 8 niveles (Practicante…Ultimate) más dificultades fuera del partido (orden del dueño).
- M-125: Roles por jugador (doble pivote, falso 9) con efecto en el motor: pasada final de táctica.

**Ciudad**
- M-200: Policía y multas (pieza E, aprobada por el dueño 27-10).

**Interfaz**
- M-438: Botones con tamaño mínimo en móvil.
- M-462: Iconos con emoji (💾 ↺ ● ✔ ▸) que pueden salir como cuadros: probar glifos o cambiarlos.

**Gestión**
- 233: Dificultades fuera del partido (finanzas, prensa, mercado) junto a las 8 de la CPU.
- M-217: Precontratos: el mercado los promete y no existen (hacerlos o quitar el texto).
- 956: Desafío «leyenda30» solo avisa: hacerlo cumplir o quitarlo.
- 971: «Sin recarga» solo avisa: bloquear de verdad la carga o quitarlo.
- 951: «Sin dinero» promete sin créditos y `Banco.pedir` no lo comprueba.

**Estabilidad**
- 1094: Migraciones de guardado entre versiones (que las partidas sobrevivan a las actualizaciones).
- M-422: Prueba de compilación de los presets de exportación (builds que no se rompen).

**Rendimiento**
- M-341: Coste real de las sombras en GPU (dueño).
- M-338: Presupuesto escrito de triángulos y llamadas por categoría en el partido.
- M-339: Césped en capas (230 k tris) sin LOD extra; unir con el pasto nuevo.

**Traducciones**
- M-277: Los ~15 textos en español sueltos en `ui/` (I-02).
- M-467: Chequeo de longitud de textos (alemán, finés) en botones.

**Legal**
- M-423: Keystore de Android (dueño; cambiar la contraseña).
- M-425: Pantalla de créditos de fotos y autores (las licencias libres lo exigen).
- M-323: Música licenciada o propia (dueño).
- 1098: Política de privacidad simple (la piden las tiendas).

### P2

**Partido**
- M-128: Portero con salidas aéreas y algo más seguro (pasada final del motor).
- M-131: Perfiles de ayuda Arcade / Semi / Manual (las ayudas sueltas ya existen).
- M-096: Mezcla entre clips del partido variable, no fija 0,25 s (movimiento natural).
- M-097: Pies que patinan en el partido: bloqueo de pies como en la ciudad.
- M-038: Hinchas de la grada cortados en la cadera: fallo visible desde la TV.
- M-022: Sonido por sector (cantos locales y visitantes): «más sonidos» de la pasada final.
- M-318: Pisadas en el partido (más sonidos).
- M-320: Patada con sonido según tipo y potencia (más sonidos).
- 1064: Volumen del público según asistencia y momento (más sonidos).

**Ciudad**
- M-186: Más edificios entrables y amueblados: «ciudad entera más completa».
- M-183: Rutinas de peatones por hora y barrio (semana 6 de la ruta).
- 327: Celebración de trofeo: vuelta olímpica y celebración 3D (fase 5, bloque 4 pendiente).

**Interfaz**
- M-302: Tema de alto contraste (accesibilidad pedida en «lanzable»).
- M-307: Probar 4:3, 21:9 y móvil: textos cortados o fuera de pantalla.
- M-437: Iconos del mando/teclado que cambian con el dispositivo también en la guía del partido.
- M-373: Comprobar que cada país muestra su bandera correcta (banderas detalladas).
- 1027: Confirmación antes de toda decisión irreversible.
- 1032: Barra de progreso al simular una temporada entera.

**Estabilidad**
- M-416: CI en GitHub Actions con la imagen Godot 4.7 (aprobado por el dueño).
- M-209: Prueba larga con métricas de equilibrio (semana 9: 10 temporadas en cada modo).
- M-386: Señales sin desconectar al liberar nodos: posibles fugas en sesiones largas.
- M-444: Fuga de texturas GL al cerrar `prueba_carrera_flujo`.
- M-430: Canal de reporte de errores dentro del juego.

**Rendimiento**
- M-343: Bajar draw calls del partido (630; sin atlas).
- M-344: Overdraw de butacas y público en la grada.
- M-345: Culling por trozos de los MultiMesh grandes.
- M-346: Texturas comprimidas para móvil (ETC2/ASTC) en el build de Android.
- M-347: Volver a medir la VRAM del partido (539 MB).
- M-348: Primera construcción del estadio larga: caché de mallas o carga más corta.
- M-350: Medir cuánto tarda `avanzar_semana` (lo que espera el jugador cada semana).
- M-354: Probar en el banco `RendimientoAdaptativo` y sus umbrales.

**Traducciones**
- M-458: Comprobar que todo `Label` visible pasa por `Idiomas.t`.
- M-463: Registrar las claves que faltan (hoy `Idiomas.t` calla).
- M-333: Carteles dibujados del 3D sin traducir.
- M-460: Revisión nativa de las traducciones hechas a mano (al menos una pasada por idioma).

### Verificar jugando (LANZAMIENTO): existen, falta la prueba

Escribir la prueba del campo «cómo probar» del plan y mirarlo en el partido o en la primera hora. Si no existe de verdad, pasa a construir con prioridad P1.

**Partido**
- 143: Mosaicos y coreografías en el estadio
- 251: Clima que afecta partidos y asistencia
- 352: Velocidad de simulación configurable (x1, x2, x4, saltar a evento)
- 353: Botón "saltar al próximo gol" para partidas rápidas
- 355: Barra de momentum que muestra qué equipo domina el partido
- 357: Probabilidad de gol en vivo (xG) como estadística opcional
- 358: Eventos aleatorios de partido (palo, gol anulado, revisión de VAR)
- 360: Cambios en vivo con vista rápida del banco de suplentes
- 361: Instrucciones en vivo (presionar, retrasar líneas, perder tiempo)
- 362: Charla de entretiempo con varios tonos y efecto real en la moral
- 363: Indicador de fatiga por jugador en tiempo real
- 371: Modo "solo resultado" para quienes simulan temporadas rápido
- 376: Ocasiones claras falladas para generar tensión sin gol
- 378: IA rival que reacciona a tu táctica a mitad de partido
- 383: Roles por posición (lateral ofensivo, pivote, falso 9, mediapunta)
- 385: Altura de la línea defensiva
- 386: Intensidad de presión (bloque alto, medio, bajo)
- 387: Ritmo de circulación de balón
- 388: Amplitud del ataque
- 389: Tipo de salida (juego corto desde el arquero vs. pelotazo largo)
- 390: Criterio de remate (buscar tiro lejano o el pase extra)
- 391: Marcaje al hombre o por zona
- 392: Trampa del fuera de juego activable
- 801: Árbitros con perfiles distintos (permisivo, tarjetero, casero)
- 1036: Alerta si intentas avanzar con alineación inválida
- 1062: Sonido ambiente de estadio durante el partido
- 1063: Silbato, murmullo y explosión de gol como capas separadas
- 1067: Sonido distintivo para el gol propio y para el gol rival

**Primera hora**
- 25: Auditorio para conferencias de prensa
- 26: Oficinas administrativas del club
- 46: Editor de apariencia del personaje
- 326: Sala de trofeos visual con vitrina por cada título
- 771: Conferencias de prensa con preguntas y opciones de respuesta
- 942: Modo sin conexión totalmente funcional
- 944: Compatibilidad garantizada con dispositivos de gama baja
- 946: Modo carrera clásico con club a elección
- 948: Modo club creado desde cero en la última división
- 985: Tutorial narrativo integrado a la primera temporada
- 1024: Escalado de texto para accesibilidad
- 1025: Paletas alternativas para daltonismo
- 1029: Autoguardado configurable
- 1030: Guardado manual con varias ranuras
- 1097: Sin recolección innecesaria de datos personales

## 3. DESPUÉS

### Gestión deportiva (78)

- M-207: Plantillas de 25 en todos los clubes
- M-235: Lesiones: duración y recaídas ok; sin prevención visible (carga
- M-359: Estadio real en 46 % de clubes
- M-229: Academia: sin variedad de métodos pedagógicos
- M-230: Cantera 1.422 líneas con representantes; pocos hitos narrativos
- M-231: Ojeadores con sesgo regional (ya) sin informes visuales (campo vs
- M-232: Staff de 6 puestos sin personalidad ni relaciones entre sí
- M-233: Entrenamiento 1.117 líneas; sesiones sin visualización 3D
- M-234: Maestrías con efecto en partido poco visible
- M-248: Mundial de clubes/selecciones (1.012 líneas) con pocos modos
- M-253: Licencia de entrenador: exámenes; sin cursos con coste y tiempo
- M-261: Sin modo historia/campaña guiada
- 269: Patrocinios personales de jugadores (compite con el club)
- 345: Resumen de prensa internacional si el club gana notoriedad
- 66: Cláusulas de bonos por objetivos
- 67: Elección de número de camiseta
- 68: Jugadores "ícono" con historia especial
- 71: Categorías juveniles (sub-15, sub-17, sub-20)
- 73: Academias asociadas en otras ciudades/países
- 80: Historial de canteranos que llegaron a ser estrellas
- 101: Personal de relaciones públicas
- 263: Jugadores con doble nacionalidad (elegibilidad)
- 266: Sistema de lesiones crónicas vs. agudas
- 268: Jugadores con marca personal (redes propias)
- 270: Jugadores "problema" que requieren gestión especial
- 337: Sistema de fatiga por viajes largos en torneos internacionales
- 339: Reuniones de directorio con actas resumidas
- 340: Contrato de imagen del club con una liga de videojuegos ficticia (guiño meta)
- 346: Cláusula de fidelidad: bono si un jugador no pide salir en X años
- 350: Estadísticas de eficiencia de tu gestión (ROI de fichajes, cantera, etc.)
- 427: Microciclo de recuperación tras partidos seguidos
- 431: Trabajo mental con psicólogo deportivo
- 432: Entrenamiento de liderazgo para formar futuros capitanes
- 433: Entrenador de arqueros con línea de desarrollo propia
- 434: Cantera entrenada bajo una filosofía definida por el club
- 435: Informe semanal de progreso entregado por el staff
- 437: Disciplina individual que determina cuánto aprovecha el entrenamiento
- 444: Declive físico realista según edad y posición
- 478: Herencia parcial de atributos del padre con variación aleatoria
- 488: Ex-jugador que regresa como DT del club donde brilló
- 489: Regens generados con nacionalidad ponderada por la fuerza del país
- 490: Nombres realistas por país y por época de nacimiento
- 493: Regens de élite: dos o tres por generación con potencial de leyenda
- 494: Rareza de potencial (común, prometedor, excepcional, generacional)
- 496: País pequeño que produce un talento generacional como historia épica
- 503: Regen prometedor que se pierde por indisciplina
- 504: Regen que sufre una lesión grave y trunca su carrera
- 505: Regen que emigra demasiado joven y no se desarrolla
- 506: Doble nacionalidad asignada a ciertos regens
- 509: Registro histórico de dinastías formadas en tu club
- 515: Modo legado familiar: mantener una misma familia tres generaciones
- 523: Costo de operaciones y clínicas de calidad variable
- 527: Riesgo de lesión aumentado por cancha en mal estado
- 528: Riesgo de lesión aumentado por calendario congestionado
- 533: Jugador que se infiltra para jugar, con riesgo posterior
- 545: Nutricionista que reduce la incidencia de lesiones blandas
- 424: Explosión tardía: jugadores que despegan entre los 24 y 26
- 425: Jugadores que se estancan si no acumulan minutos
- 428: Sesiones a puertas cerradas o abiertas al público
- 436: Jugadores que se quejan si el entrenamiento es muy duro o muy blando
- 438: Trabajo extra voluntario de los jugadores más profesionales
- 439: Pérdida de ritmo competitivo por parón de liga
- 440: Entrenamiento adaptado a la superficie de la próxima cancha rival
- 487: Padre retirado que presiona al club para que su hijo juegue
- 500: Rasgos físicos heredados visibles en el avatar del hijo
- 501: Apodos automáticos para regens destacados
- 507: Regens que eligen selección nacional entre dos opciones
- 510: Bonificación de afinidad al fichar al hijo de un ídolo del club
- 511: Reacción hostil de la hinchada al fichar al hijo de un ídolo rival
- 512: Padrinazgo: un ídolo del club apadrina al hijo de otro
- 513: Evento: el padre retirado pide un cargo en la cantera
- 514: Estadística de cuántos regens de tu cantera llegaron a la élite
- 522: Seguro médico contratable para todo el plantel
- 526: Kinesiólogo que acorta los plazos de recuperación
- 534: Costo reputacional si abusas de las infiltraciones
- 536: Índice de carga de trabajo por jugador durante el mes
- 538: Alerta médica previa: "no recomiendo que juegue"
- 544: Regreso triunfal tras lesión larga como evento narrativo

### Economía y club (78)

- M-210: Mercado: precios por reputación sin burbujas ni crisis
- M-219: Banco e Insolvencia existen pero con pocos eventos de gravedad
- M-211: Cláusulas de rescisión: sin «cláusulazo» automático de IA
- M-213: Sin agentes con personalidad reflejada en comisiones (hay 4 perfiles)
- M-214: Cesiones con opción de compra obligatoria sin seguimiento de
- M-216: Fichajes de IA entre clubes poco visibles
- M-218: Sin límite de fair play financiero explícito (hay aviso)
- M-220: Sin intereses variables según reputación y mercado
- M-221: Impuestos y derechos de TV simplificados
- M-222: Venta de entradas: precio único
- M-223: Abonos/socios: modelo simple
- M-225: Comercial zonas de patrocinio manual para el usuario; IA sin
- M-250: Ciudad y club: terrenos/negocios; economía simplificada
- 118: Fondo de emergencia del club
- 120: Bonos e incentivos fiscales por inversión en cantera
- 125: Sponsor de entrenamiento
- 130: Colaboraciones con marcas para ediciones limitadas
- 131: Sponsors regionales vs. internacionales
- 133: Sponsors "sorpresa" que ofrecen tratos únicos
- 135: Ferias/eventos de marca para aumentar reputación
- 257: Impacto económico del club en la ciudad ficticia
- 272: Boom económico repentino de un sponsor
- 275: Oferta de fusión con otro club (dilema)
- 279: Presión por bajar precios de entradas
- 114: Recortes de gastos en momentos de crisis
- 127: Sponsors temáticos con personalidad propia
- 128: Renovación o pérdida de sponsors según resultados
- 129: Campañas publicitarias especiales
- 132: Penalizaciones por incumplir contrato de sponsor
- 253: Horarios de partido elegibles (afecta asistencia/TV)
- 256: Turismo deportivo si el club crece mucho
- 258: Relación con el gobierno local
- 259: Alianzas con otros clubes (amistosos, intercambio de canteranos)
- 260: Torneo de veteranos con ex-jugadores del club
- 273: Caída de un sponsor por escándalo externo
- 277: Oferta de venta total del club (si eres dueño)
- 278: Escándalo de dopaje a resolver
- 641: Estado de resultados mensual y anual del club
- 644: Diferencia explícita entre resultado contable y caja disponible
- 648: Líneas de crédito y capacidad máxima de endeudamiento
- 651: Mora en el pago de sueldos y sus consecuencias inmediatas
- 652: Jugadores habilitados a rescindir por sueldos impagos
- 660: Venta forzada de activos: estadio, ciudad deportiva, terrenos
- 666: Fondo de inversión que compra un porcentaje del club
- 671: Tope salarial interno autoimpuesto
- 672: Escalas salariales y conflictos internos por desigualdad
- 677: Auditoría anual con informe público
- 678: Panel de indicadores financieros (liquidez, endeudamiento, cobertura)
- 683: Campaña electoral con promesas que después debes cumplir
- 687: Asamblea anual de socios con preguntas incómodas
- 692: Conflicto por modificar el escudo o los colores tradicionales
- 695: Refundación tras la quiebra, partiendo en la última división
- 699: Delegar o no las negociaciones, con efecto en tu carga de trabajo
- 700: Objetivos de temporada negociados con el directorio
- 704: Cláusula de salida en tu propio contrato
- 705: Indemnización por despido
- 708: Elegir entre club grande con presión o proyecto largo sin prisa
- 710: Salón de la fama de dirigentes y entrenadores del mundo del juego
- 645: Amortización del valor de los pases en libros
- 646: Plusvalía contable generada por venta de jugadores
- 650: Convenio de pago con proveedores
- 659: Junta de acreedores que vota el destino del club
- 661: Venta del estadio con arriendo posterior como maniobra financiera
- 663: Aumento de capital con dilución de los accionistas actuales
- 665: Financiamiento colectivo de hinchas para un fichaje puntual
- 669: Presupuesto anual que debe aprobar el directorio
- 670: Reasignación de presupuesto entre fichajes y salarios
- 673: Impuestos por país y su efecto en el sueldo neto ofrecido
- 674: Régimen tributario especial para atraer extranjeros
- 675: Inflación y devaluación de la moneda local
- 676: Ingresos en moneda extranjera por torneos internacionales
- 679: Calificación de riesgo del club que encarece o abarata el crédito
- 680: Premio anual a la gestión financiera sostenible
- 681: Elección entre club de socios o sociedad anónima deportiva
- 689: Oferta de compra hostil sobre el club
- 691: Dueño extranjero que quiere cambiar la identidad del club
- 693: Traslado del club a otra ciudad como decisión polémica
- 707: Entrevista de trabajo con un club interesado

### Modos, meta e historia (66)

- M-265: Avatar propio sin personalización de cuerpo
- M-266: Sin entrenador como NPC con diálogos sobre el jugador
- M-267: Transferencias vistas desde el jugador: ofertas sin negociación
- M-268: Selección nacional: convocatorias sin escena
- M-269: Lesiones del jugador: sin recuperación jugable (fisio)
- M-270: Retiro con paso a DT ok; sin homenaje
- M-271: Sin contratos de imagen propios
- M-272: Fuera de juego, cambios, selección ✅; sin protestas/tarjetas del
- M-273: Rivales NPC por Fama; sin rivalidades nominales
- M-276: Pruebas: modo cubierto en prueba_modos; faltan casos extremos
- 177: Mejor arquero del año
- 179: Mejor presidente/dueño del año
- 183: Premio al club más popular
- 219: Leyendas como mentores de la cantera
- 234: Guardado de partida en la nube
- 283: Ranking histórico de mejores gestiones (leaderboard interno)
- 324: Historial de presidentes/DTs anteriores y su legado
- 176: Balón de Oro del juego
- 182: Premio al fair play
- 184: Premio a la mejor hinchada
- 185: Premio al estadio más impresionante
- 215: Homenajes a ídolos fallecidos o retirados
- 226: Elecciones internas si eres presidente (reelección)
- 237: Estadísticas exportables de tu carrera
- 244: Notificaciones push de eventos importantes
- 246: Sistema de logros ocultos/easter eggs
- 287: Estadísticas comparativas año a año
- 288: Certificaciones del club (sustentable, formativo, etc.)
- 289: Ranking de mejores canteras a nivel ficticio-continental
- 290: Hitos de asistencia al estadio (lleno histórico)
- 319: Resumen anual automático al cerrar cada temporada
- 320: Archivo de planteles históricos por temporada
- 325: Comparador de generaciones (equipo actual vs. el mejor histórico)
- 947: Modo empezar desde abajo con un club amateur
- 954: Modo clásico eterno: ganar todos los derbis de la temporada
- 957: Modo dinastía familiar centrado en hijos y nietos
- 958: Modo presidente: solo decisiones institucionales
- 964: Escenario: evitar el descenso con el peor plantel de la liga
- 968: Modo rápido de una sola temporada
- 980: Modo espectador de una liga completamente simulada
- 981: Modo solo simulación: ver evolucionar el mundo sin intervenir
- 983: Semilla de partida compartible entre jugadores
- 986: Sistema de logros con recompensas cosméticas
- 987: Desbloqueo de estadios, escudos y camisetas por logros
- 989: Árbol de mejoras de perfil, opcional y desactivable
- 992: Estadísticas acumuladas de todas tus partidas
- 996: Sistema de prestigio al reiniciar con pequeñas ventajas
- 999: Epílogo generado según las decisiones tomadas
- 1000: Salón de la fama personal del jugador
- 1003: Placa conmemorativa por cantidad de temporadas dirigidas
- 1007: Eventos históricos aleatorios que cambian entre partidas
- 1008: Fuerza variable de las ligas en cada mundo generado
- 1009: Cartas de evento que aparecen una sola vez por partida
- 960: Modo DT puro: sin control sobre el dinero
- 962: Escenarios históricos recreados como desafío
- 963: Escenario: remontar diez puntos en ocho fechas
- 965: Escenario: ganar una copa con un club chico
- 966: Escenario: alcanzar una meta de ventas en una temporada
- 967: Escenario: formar cinco seleccionados en diez años
- 969: Modo largo de cincuenta temporadas
- 976: Multijugador por turnos en el mismo dispositivo
- 979: Modo cooperativo: dos personas gestionando el mismo club
- 982: Reinicio de temporada con la misma semilla
- 994: Desafíos diarios cortos independientes de la carrera
- 995: Recompensa por completar temporadas consecutivas
- 1005: Metas autoimpuestas configurables por el usuario

### Partido (61)

- M-119: Penales: el portero «decide una vez» pero sin lectura del lanzador
- M-147: Hitbox del balón vs cuerpo: 0 casos atravesando (sonda); pero
- M-120: Córners con 3 variantes
- M-121: Tiros libres: barrera simple
- M-122: Sin saque de banda largo/estratégico
- M-126: Cambios de IA por cansancio (60/70/80') fijos
- M-129: Sin lanzamientos de larga distancia ni centros desde banda con
- M-134: Sin cámaras de repetición cinematográficas (grúa, dron)
- M-135: Sin cámara de gol del cuarto árbitro/línea
- M-140: Descanso: charla de medio tiempo con opciones; sin vestuario 3D
- M-142: Rueda de prensa posterior no enlazada con incidentes del partido
- M-143: Sin clima dinámico durante el partido (tormenta repentina)
- M-144: Campo se desgasta (barro) sin visualización
- M-145: Sin marcas de césped (pisadas, deslizamientos)
- M-146: Balón con skins pero sin desgaste/mojado
- M-148: Sin rebotes contra postes/larguero realistas con física propia
- M-150: Sin balones adicionales (calentamiento, reserva)
- M-152: Sin modo de entrenamiento libre (probar controles)
- M-153: Sin modo multijugador local
- M-155: Penal de usuario con barra, sin variantes por pierna
- M-156: Sin decisión de capitán (protesta)
- M-157: Sin cantos/anuncios del estadio (megafonía con alineaciones)
- M-159: Sin himno por país con partitura procedural
- M-161: Sin mini-partidos de selección con identidad
- M-163: Sin modo «Director técnico automático» configurable (IA del usuario)
- M-164: Sin modo espectador con cámara libre
- M-166: Sin partidos de fútbol sala/playa/mujeres (género existe)
- 351: Motor 2D cenital con fichas de color en vez de modelos 3D (bajo costo, alta legibilidad)
- 356: Cadenas de jugada: la simulación encadena 3 a 5 acciones antes de resolver
- 359: Interrupciones: invasión de cancha, corte de luz, lluvia intensa
- 364: Riesgo de lesión visible al forzar a un jugador tocado
- 366: Tanda de penales con elección de palo y orden de ejecutantes
- 367: Especialistas designados para penales, córners y tiros libres
- 368: Rendimiento diferenciado por altitud, clima y desgaste de viaje
- 369: Efecto medible del público según ocupación real del estadio
- 370: Cancha en mal estado que reduce precisión de pases
- 374: Nota de rendimiento por jugador (1 a 10) con justificación breve
- 375: Detección automática de "partido histórico" archivado en el club
- 377: Dificultad de la IA rival ajustada por liga y presupuesto
- 384: Instrucciones individuales por jugador
- 396: Plan A / Plan B / Plan C activables según el marcador
- 397: Cambio táctico automático por minuto (ej. cerrar desde el 80)
- 399: Penalización si el sistema no calza con las cualidades del plantel
- 401: Recomendación del ayudante técnico (activable o desactivable)
- 402: Contra-táctica diseñada para un rival concreto
- 408: Identidad de juego del club definida a largo plazo
- 410: DT con estilo propio que choca o encaja con la identidad del club
- 415: Alineación automática sugerida según frescura y rival
- 354: Relator de texto con tono configurable (sobrio, exagerado, humorístico)
- 365: Aviso de "amonestado bajo presión" antes de una posible expulsión
- 372: Relato del partido guardable y compartible como texto
- 373: Comparativa post-partido contra el promedio de la liga
- 379: Modo espectador para ver partidos de otros equipos
- 380: Resultados de la fecha actualizándose mientras juegas tu partido
- 381: Editor de formación con arrastrar y soltar
- 395: Saque lateral largo como arma táctica
- 398: Familiaridad táctica: el equipo tarda semanas en asimilar un sistema
- 403: Modo espejo: copiar la táctica de un equipo que admires
- 406: Táctica de emergencia con diez jugadores tras una expulsión
- 407: Plan de partido para jugar con ventaja numérica
- 409: Hinchada que exige un estilo (ofensivo, aguerrido, de toque)

### Competiciones y reglamento (58)

- 824: Criterios de desempate configurables
- 828: Protesta formal contra un resultado
- 829: Fallo del tribunal que modifica la tabla de posiciones
- 830: Historial disciplinario del club por temporada
- 836: Alianzas políticas con otros clubes
- 840: Sanción por participar en una liga no reconocida
- 842: Lucha por una mayor tajada de los ingresos centrales
- 843: Calendario definido por la federación con conflictos de fechas
- 845: Reclamo por lesión de un jugador en la selección
- 849: Cambio de formato de ascensos y descensos entre temporadas
- 853: Corrupción federativa como trama de fondo de la partida
- 856: Torneo continental nuevo creado a mitad de partida
- 857: Ranking de coeficientes de países que define cupos
- 860: Gira internacional que requiere aprobación federativa
- 861: Modo seleccionador nacional paralelo o alternativo
- 868: Torneos continentales con formatos propios
- 873: Prestigio del club según cantidad de seleccionados
- 875: Ojear durante un mundial y fichar a la revelación
- 878: Historial de seleccionados formados en tu club
- 879: Ranking mundial de selecciones dinámico
- 880: Naturalización masiva en países pequeños como dilema
- 887: Crear tu propia liga con reglas a medida
- 888: Definir número de equipos, ascensos y descensos
- 889: Formatos: todos contra todos, apertura y clausura, playoffs
- 891: Copa nacional con participación de equipos amateurs
- 892: Cenicienta de copa que llega inesperadamente lejos
- 897: Mundial de clubes con formato ampliado
- 900: Sistema de sorteo con bombos y restricciones
- 906: Definición por penales con estadísticas históricas propias
- 910: Calendario visual con todas las competencias superpuestas
- 812: Amnistía de amarillas al llegar a determinada fase
- 814: Denuncia por insultos discriminatorios
- 815: Protocolo antidiscriminación con partido suspendido
- 821: Regla de cinco cambios activable
- 822: Reglas experimentales aplicadas en ligas menores
- 823: Gol de visitante como criterio configurable
- 825: Puntos de fair play como criterio de desempate
- 851: Repechaje internacional por un cupo
- 852: Sistema de licencias que impide ascender pese al mérito deportivo
- 854: Investigación internacional que sacude a la federación
- 855: Cambio de asociación continental en casos excepcionales
- 858: Aporte de tu club al coeficiente nacional
- 859: Diplomacia con federaciones extranjeras para amistosos
- 864: Disputa entre dos selecciones por un mismo jugador
- 865: Eliminatorias organizadas por confederación
- 866: Repechaje intercontinental
- 869: Selecciones juveniles vinculadas a la absoluta
- 870: Torneo olímpico con reglas de edad
- 876: Retiro de la selección de un veterano emblemático
- 877: Debut de un canterano tuyo en la selección mayor
- 882: DT de selección que compite contigo por la atención de un jugador
- 883: Oferta para dirigir una selección mientras diriges un club
- 884: Doble cargo permitido o prohibido según el país
- 885: Legado como seleccionador registrado en el salón de la fama
- 898: Torneos regionales de carácter histórico
- 899: Torneos ficticios desbloqueables por logros
- 902: Cabezas de serie definidos por coeficiente
- 909: Tabla anual y tabla acumulada funcionando en paralelo

### Hinchada, prensa y redes (56)

- M-241: Prensa 2.541 líneas (la mayor del núcleo): resolver 476 líneas
- M-236: Vestuario 1.436 líneas con grupos; sin conflictos con
- M-243: Redes sociales: seguidores y comentarios; sin bots/trolls/tendencias
- M-244: Sin entrevistas en TV con escena 3D variada (existe rueda de
- M-245: Federación 999 líneas con reglas; votaciones sin presentación
- M-249: Hinchada con segmentos; sin rivalidades por barrio
- M-252: Trabajadores/instalaciones con eventos; sin huelgas/negociación
- M-257: Historia del club generada; sin línea de tiempo interactiva
- M-258: Documental de temporada: guion fijo
- 144: Fan zone fuera del estadio en días de partido
- 145: Programa de fidelización de hinchas
- 162: Ranking de prensa sobre mejores DTs/presidentes
- 164: Reportajes especiales sobre la cantera
- 204: Eventos especiales previos al clásico
- 206: Fichajes polémicos entre rivales
- 208: Comparación de logros con el rival histórico
- 142: Cánticos personalizados de la hinchada
- 147: Publicaciones oficiales del club que puedes redactar
- 152: Crisis de imagen por un comentario mal manejado
- 153: Cuenta oficial de jugadores (reacciones a decisiones tuyas)
- 154: Memes generados por la comunidad del juego
- 165: Cobertura internacional si el club gana relevancia
- 202: Rivalidad regional/de ciudad
- 205: Presión extra de la afición en el clásico
- 207: Robo de un canterano por el club rival
- 209: "Guerra" de sponsors entre clubes rivales
- 210: Ranking de rivalidad según intensidad de eventos
- 738: Índice de conexión emocional entre hinchada y equipo
- 744: Barra organizada con demandas y riesgo de violencia
- 751: Entradas populares a precio social como decisión de imagen
- 754: Filiales internacionales si el club se globaliza
- 757: Ídolo popular al que la hinchada protege aunque rinda poco
- 759: Silbatina en el estadio que afecta el rendimiento del equipo
- 760: Proceso de recuperación de la confianza tras una crisis
- 761: Documental sobre la hinchada producido por el club
- 762: Museo con exhibición participativa de objetos de hinchas
- 764: Programa social en barrios vulnerables
- 774: Periodista aliado al que puedes filtrar información
- 779: Multa federativa por declaraciones desafortunadas
- 782: Encuesta de opinión pública sobre tu continuidad
- 784: Filtración de la alineación antes del partido
- 785: Investigación periodística sobre las finanzas del club
- 788: Departamento de comunicaciones mejorable por niveles
- 796: Presión por jugar en horarios incómodos para el hincha
- 740: Protestas por la venta de un ídolo
- 742: Recibimiento masivo al bus del equipo
- 745: Decisión estratégica de negociar o enfrentar a la barra
- 747: Hinchada que viaja masivamente a un partido decisivo
- 756: Cánticos que aparecen dedicados a jugadores destacados
- 758: Jugador señalado por la hinchada tras un error decisivo
- 763: Colecta solidaria organizada por el club
- 768: Voluntariado de jugadores en la comunidad
- 770: Premio a la mejor institución del año
- 783: Rumor falso de tu despido publicado en portada
- 791: Biografía autorizada de un ídolo del club
- 798: Reacción de la prensa extranjera ante un fichaje sorpresivo

### Mercado y agentes (50)

- 85: Fichajes sorpresa (oportunidades limitadas en el tiempo)
- 90: Traspasos con jugador + dinero incluido
- 447: Costo mensual por ojeador y por región cubierta
- 452: Descubrimiento de joyas en ligas menores o mercados exóticos
- 454: Filtros de búsqueda avanzados (edad, valor, contrato, posición)
- 455: Lista de seguimiento con alertas automáticas
- 456: Alerta de jugador que entra en su último año de contrato
- 460: Rumores de mercado que pueden resultar falsos
- 463: Informe de situación familiar que afecta la disposición a mudarse
- 467: Ranking interno de objetivos por prioridad
- 472: Torneos juveniles internacionales como escaparate de talento
- 591: Bonos por partidos jugados, goles marcados y títulos ganados
- 592: Derechos de formación y mecanismo de solidaridad
- 597: Jugador que solo aceptará ir a un club grande
- 599: Último día de mercado con ofertas frenéticas de última hora
- 601: Fichaje caído por problema de visa o cupo de extranjeros
- 604: Lista de inscritos por torneo con decisiones difíciles
- 607: Valor de mercado dinámico según rendimiento y contrato
- 615: Historial completo de operaciones con balance neto acumulado
- 618: Agente que te ofrece jugadores en exclusiva si le caes bien
- 619: Agente que te bloquea operaciones si lo tratas mal
- 621: Comisiones negociables y su impacto en el presupuesto
- 624: Investigación federativa por operaciones sospechosas
- 627: Contabilidad paralela como opción arriesgada y sancionable
- 629: Presión de un dirigente para fichar a un representado suyo
- 635: Filtración de un contrato completo a la prensa
- 451: Asignación de un ojeador a un torneo juvenil específico
- 457: Alerta de jugador descontento en otro club
- 458: Alerta de cláusula de rescisión anormalmente baja
- 464: Invitar a un jugador libre a entrenar a prueba
- 465: Descubrimiento por casualidad durante un amistoso
- 473: Convenios con clubes menores por derecho de primera opción
- 474: Scouting de entrenadores y staff, no solo de jugadores
- 581: Ventanas de mercado con fechas distintas según el país
- 582: Mercado de invierno más caro y con menos opciones
- 588: Cláusula de no alinear al cedido contra el club dueño
- 589: Cláusula que impide la reventa a un rival directo
- 596: Jugador que acepta menos dinero para jugar torneo internacional
- 600: Fichaje caído tras la revisión médica
- 605: Mercado inflado por un club recién comprado por un magnate
- 609: Rechazo automático de ofertas por debajo de un monto fijado
- 614: Traspaso récord del club registrado como hito histórico
- 626: Denuncia anónima que dispara una auditoría
- 632: Intermediario que infla artificialmente el precio de una operación
- 633: Agente que representa al comprador y al vendedor a la vez
- 634: Cláusula secreta que se revela tiempo después
- 636: Escándalo de amaño de partidos dentro de tu liga
- 638: Programa interno de integridad del club
- 639: Ranking de transparencia con efecto sobre los auspiciadores
- 640: Delación compensada dentro de un caso federativo

### Estadio y club 3D (45)

- M-003: Las formas no varían de forma continua
- M-004: El «estadio real» sólo copia forma/niveles/techo/pista/focos/fachada
- M-014: Sin diferencia día/noche en el aspecto de la iluminación
- M-017: Túnel de vestuario sólo en +Z
- M-007: Sin variación de entorno por país (palmeras, nieve, montaña de fondo)
- M-009: Sin voladizo/cubierta visible en estadios sin techo
- M-010: Sin carteles de pared (patrocinadores, fechas, escudo) fuera del campo
- M-012: Vallas LED con la misma rotación de marcas inventadas (30)
- M-013: Banderas de esquina/córner genéricas
- M-015: El césped usa 12 dibujos, asignación por hash
- M-016: Sin campo de entrenamiento/calentamiento visible fuera del estadio
- M-018: Banquillos de un solo diseño por preset
- M-019: Sin zona de prensa/cabinas de TV visibles en el graderío
- M-020: Sin palcos reales (palcos existe como instalación)
- M-024: Sombras de la grada sobre el campo no cambian con la hora real del
- M-025: Poca variedad de torres de luz (4 esquinas)
- M-027: Sin variación de terreno exterior (cerro, mar, río) según rasgo
- M-028: El estadio propio y el rival usan caminos de construcción
- M-029: Ampliaciones del estadio propio sin animación de obra detallada
- M-031: Sin mapa de estadios (galería) para ver todos los del juego
- M-032: Sin ficha de estadio con datos reales (capacidad oficial, año,
- M-023: Sin clima visible en el estadio más allá de lluvia/niebla (nieve,
- M-026: Estadios sin nombre dibujado en fachada
- M-030: Sin estadio nacional/selección con identidad propia
- M-035: Sin bufandas/banderas/camisetas del club en la mano
- M-037: Sin sector «barra brava»/torcida con comportamiento diferente (de
- M-039: Tres niveles de detalle; el salto «cerca→medio→lejos» puede verse
- M-041: Sin niños, familias ni asistentes en sillas de ruedas
- M-042: Ocupación = reputación, no asistencia del partido
- M-043: Sin diferencia de público por competición (final vs liga)
- M-044: Gol local: ceremonia de público única
- M-048: Fotógrafos/camarógrafos pocos y repetidos
- M-046: Sin multitudes en accesos, tienda y museo del estadio
- 332: Exhibición temporal de un trofeo destacado en el estadio
- 333: Ceremonia de entrega de camiseta homenaje en aniversarios
- 334: Muro de campeones con fotos de planteles ganadores
- 15: Accesos para hinchada visitante (afecta seguridad/incidentes)
- 331: Evento especial de "gala de campeones" con invitados históricos
- 335: Fuegos artificiales/mosaico especial configurable para festejos grandes
- 713: Conexión de transporte público hacia el estadio
- 717: Estudio de impacto ambiental obligatorio
- 712: Ubicación del estadio que afecta la asistencia promedio
- 718: Estadio compartido con otro club de la misma ciudad
- 722: Estadio provisional mientras construyes el definitivo
- 723: Mudanza temporal a otra ciudad durante la obra

### Interfaz y accesibilidad (41)

- M-280: 105 módulos de UI/visor sin referencia en banco/pruebas
- M-283: Sin subtítulos/indicadores visuales de sonido
- M-284: Sin modo lectura de pantalla (TTS)
- M-285: Navegación por mando en menús (panel de controles sí)
- M-287: Rendimiento de menús: refresco ya 14× más rápido; sin pruebas de
- M-289: Menú lateral con 9 menús; Ciudad/Editar completados; Ajustes sólo
- M-290: Tarjetas con dato vivo sólo en algunas (Menu.dato)
- M-292: Sin favoritos/marcadores de jugadores o clubes
- M-293: Tablas con filtros limitados (plantel)
- M-294: Comparador de jugadores existe; sin comparativa de club/estadio
- M-295: Sin gráficos históricos (valor, forma) en ficha
- M-296: Notificaciones (Aviso) sin centro de notificaciones
- M-300: Sin deshacer en acciones de pizarra
- M-303: Cursor/hover sin feedback sonoro consistente en todos los
- M-304: Animaciones de transición entre pantallas desiguales
- M-305: Tooltips escasos
- M-308: DPI alto: texto del Label3D en 3D no escala
- M-311: Sin perfil de jugador (estadísticas globales)
- M-312: Sin modo «streamer» (ocultar datos sensibles/real)
- M-435: Sin gatillos analógicos para potencia de pase
- M-436: Sin giroscopio para cámara en primera persona (móvil)
- M-439: Orientación vertical no soportada
- M-440: Sin modo una mano
- M-441: Sin soporte de teclado en pantalla para nombres
- M-442: Mando: botones reasignables guardados pero sin perfiles múltiples
- 1012: Botón de continuar siempre en la misma posición
- 1013: Bandeja de entrada unificada con notificaciones agrupadas
- 1016: Buscador global de jugadores, clubes y competencias
- 1020: Tablas ordenables por cualquier columna
- 1022: Vista compacta y vista detallada intercambiables
- 1028: Deshacer la última acción no crítica
- 1031: Carga inmediata de la última partida al abrir la app
- 1034: Resumen del día al avanzar el calendario
- 1037: Sugerencias contextuales desactivables
- 1039: Ayuda contextual desplegable en cada pantalla
- 1042: Pantalla de inicio personalizable con widgets
- 1046: Widget de lesionados y suspendidos
- 1017: Historial de navegación con botón de volver atrás
- 1021: Columnas configurables por el usuario
- 1026: Gestos de deslizamiento para cambiar de pestaña
- 1033: Retomar exactamente en la pantalla donde quedaste

### Personajes y equipaciones (41)

- M-054: Ropa con volumen sólo en retratos
- M-055: Sin arrugas dinámicas según animación
- M-058: 30 marcas de patrocinio
- M-079: Retrato real 13 % (base real)
- M-091: Botines: variedad añadida, pero sin modelos distintos por forma
- M-094: Animación de caminata del DT: 6 estilos (✅)
- M-095: 335 clips; muchos sin uso en partido
- M-056: Sin sudor/barro/lluvia en la camiseta
- M-060: Patrocinio fijo por club entre temporadas, sin contratos de IA que
- M-061: Sin patrocinador en la parte trasera del pantalón ni en las medias
- M-064: Falta ornamento reconocible (león, águila, estrella, castillo,
- M-065: Texto/iniciales ilegibles <24 px
- M-067: Sin escudo animado en el marcador al gol
- M-069: 12 diseños con reparto casi uniforme
- M-070: Sin segunda/tercera camiseta con diseño propio
- M-071: Portero: color por contraste, sin diseño
- M-074: Medias/pantalón: diseño correcto pero sin franjas del fabricante
- M-075: Dorsal sin fuente propia por club
- M-077: Retrato con camiseta de volumen pero sin patrocinio en pecho visible
- M-078: Foto real de equipación sólo con pack real
- M-080: Fotos agachadas aún oscuras/deformadas
- M-082: Altura sólo por escala global
- M-083: Sin tatuajes/cicatrices por jugador salvo civiles
- M-084: Biblioteca de caras = 72 mezclas
- M-085: Envejecimiento visual de jugadores (canas, arrugas) no ligado a edad
- M-086: Expresiones faciales limitadas a Expresion básica
- M-087: Sin parpadeo/respiración idle variados
- M-089: Barbas/cejas por capas apagadas (manchas)
- M-090: Guantes de portero sólo color
- M-092: Cordones/tacos sin geometría
- M-093: Sin canilleras/vendas/cintas visibles
- M-099: Cuerpos sin colisión entre brazos/piernas (solapes sólo en XZ)
- M-101: Celebraciones por rasgo (ya) pero sólo 2/3 propias
- M-102: Sin reacciones de banquillo coordinadas
- M-103: Lesiones sin animación específica
- M-108: Mascotas con animación limitada
- M-109: Niños de ceremonia con una misma malla
- M-110: Sin voces/murmullos de jugadores
- M-112: Sin avatar del usuario en el estadio como jugador (carrera) con su
- M-076: Sin parches de competición (campeón, copa)
- M-111: Sin modo foto con poses y expresión (existe ModoFoto)

### Código y pruebas (35)

- M-404: Módulos de visor/ sin prueba directa
- M-379: 64 funciones > 120 líneas: Sonido._sintetizar 1.000,
- M-382: Sin análisis estático
- M-383: Tipado: muchos Dictionary sin forma (jugadores del motor)
- M-384: Mundo 2.921 líneas, Roles 2.065, Prensa 2.541: acoplamiento alto
- M-387: Mensajes de error silenciosos (return sin aviso)
- M-388: Constantes mágicas (balance) dispersas
- M-391: Duplicación entre MatchPlayback y MotorJugable
- M-392: MotorLibre prototipo (546 líneas) sin uso claro
- M-393: Código de pruebas mezclado con herramientas (herramientas/*.ps1)
- M-394: Herramientas .exe/.cs binarias en repo
- M-396: Convenciones: mezcla de español/inglés en nombres
- M-397: Comentarios muy extensos (valioso pero ruidoso)
- M-398: Sin documentación de arquitectura actualizada (LEEME.md)
- M-401: Dependencia de nombres de nodo (find_child) frágil
- M-402: Duplicación de carga de JSON (Datos 212 tablas)
- M-406: Retrato3D no se ejercita en headless
- M-408: Sin pruebas de minijuegos 3D
- M-410: Pruebas de rendimiento con umbrales
- M-417: herramientas/banco.sh sólo bash
- M-418: Sin informes de cobertura
- M-445: Pruebas que no caben en 5 min con render por software (intro,
- M-448: auditoria_clubes tarda ~8 min y auditoria_datos ~1 min
- M-449: Los informes (AUDITORIA_CLUBES.csv) se regeneran a mano
- M-450: pruebas/prueba_* no tienen un índice de «qué cubre cada una»
- M-451: Duplicación del arnés (_ok, _fallos) en decenas de pruebas
- M-452: Salida de pruebas sin código de retorno uniforme (algunas
- M-453: Pruebas ligadas al azar sin semilla fija en algunos casos (la IA
- M-454: Capturas que cambian el estado de la máquina (ajustes de
- M-455: Pruebas que escriben en user://ajustes.cfg real
- M-456: auditoria_tecnica solo carga las escenas de escenas/ y ui/ (4)
- M-457: Los nodos huérfanos se miden solo en la pantalla principal
- M-470: El banco no ejecuta auditoria_tecnica, auditoria_datos ni las
- M-465: Sin pruebas de rendimiento de la carga de idiomas (idiomas.gd
- M-469: Falta documentación del flujo de pruebas para colaboradores

### Datos del mundo y editor (27)

- M-361: tablas.json en una línea
- M-362: ESTADIO_CLUB por nombre (frágil con leetspeak)
- M-363: Mapa ficticio→real (CLUBES en base_ficticia.py) sin prueba de
- M-364: Países: 23 con 16 clubes (Chile 32)
- M-367: Calendario con feriados (Calendario 350 líneas); sin zonas horarias
- M-368: Jugadores históricos/leyendas sin mecánica de «cromo»
- M-369: Nombres de estadios ficticios sin apodos amplios (GuinosEstadio)
- M-370: Historia de clubes (historia_clubes.py) por club; verificación
- M-371: Himnos y cánticos sin letra
- M-372: Retratos de DT/presidente generados; sin variedad étnica medida
- M-376: Premios individuales sin votación explicada
- M-377: Sin clima por país/estación realista
- M-378: Sin datos de ciudades (población, altura) para estadios
- 913: Importación de paquetes de datos creados por la comunidad
- 915: Verificación de compatibilidad entre versiones de datos
- 920: Herramienta de renombrado masivo
- 925: Editor de reglas de competencias existentes
- 927: Editor de finanzas iniciales de cada club
- 933: Copias de seguridad automáticas de la base
- 936: Compartir capturas de logros con formato propio
- 940: Créditos automáticos a los autores de los datos
- 921: Plantillas de datos por país descargables
- 922: Actualización de plantillas al inicio de cada temporada real
- 926: Editor de calendario y fechas
- 931: Bloqueo opcional de edición para partidas competitivas
- 932: Registro de cambios aplicados a la base de datos
- 934: Sincronización en la nube entre dispositivos

### Personas y narrativa (24)

- 50: Frases/estilo de comunicación personalizable
- 51: Relaciones personales con jugadores clave
- 52: Rivalidad personal con otro DT/presidente
- 191: Sponsor que exige una decisión ética incómoda
- 195: Escándalo de arbitraje que genera indignación
- 199: Conflicto entre cuerpo técnico y directiva
- 549: Jugador que pide hablar contigo en privado
- 552: Jugador que exige renovación tras un buen semestre
- 553: Jugador que se ofende si queda fuera de la lista de un torneo
- 555: Reacción del vestuario ante la venta de un referente
- 558: Moral colectiva separada de la moral individual
- 559: Efecto acumulativo de las rachas de derrotas en el ánimo
- 562: Perfil psicológico oculto que se descubre con el tiempo
- 567: Jugador con problemas personales que necesita apoyo del club
- 570: Barrera idiomática que dificulta la integración
- 573: Actividades de integración del plantel
- 575: Jugador que se siente traicionado si lo criticas en prensa
- 576: Defensa pública de un jugador que dispara su moral
- 579: Índice de confianza del plantel hacia tu gestión
- 580: Renovación generacional del liderazgo del vestuario
- 554: Reacción del vestuario ante un fichaje muy caro
- 557: Consejo de capitanes que negocia contigo condiciones internas
- 571: Clases de idioma financiadas por el club
- 578: Jugador que se convierte en tu aliado dentro del grupo

### Ciudad y vida 3D (20)

- M-168: Sin rotondas
- M-170: Sin semáforos peatonales con botón
- M-173: Sin sonido de motor/marchas/derrape
- M-176: Sin tipos de vehículo (moto, bus conducible, camión)
- M-177: Sin gasolinera/aparcamiento/lavado
- M-180: Metro: sin vendedores/música/anuncios
- M-182: Sin tarjeta de transporte ni coste
- M-184: Sin NPC con nombre y memoria (te reconocen)
- M-185: Diálogos por oficio (hecho) pero sin ramas ni consecuencias
- M-187: Casas sin habitantes ni rutinas
- M-188: Sin tiendas con compra real (ropa, balones)
- M-189: Sin bares/restaurantes con minijuego
- M-192: Aceras/pavimentos: 3 texturas
- M-196: Botes sin sonido/estela
- M-197: Autopista sin peajes ni estaciones
- M-198: Aeropuerto/estación de tren inexistentes (no hay viajes)
- M-203: Sin colisión/oclusión de sonido en interiores
- M-204: LOD de edificios lejanos con ventanas (cristal) pero sin siluetas
- M-205: ciudad_expansion.gd 2.321 líneas y city_builder.gd 4.687
- M-206: Sin editor de ciudad más allá de terrenos/negocios

### Audio y presentación (15)

- M-313: Sonido._sintetizar 1.000 líneas: efectos sintetizados sin editor
- M-314: Sin mezcla dinámica (ducking de música en diálogo/gol)
- M-315: Música (Musica 384 líneas, procedural): sin variaciones por mood
- M-316: Cantos de hinchada genéricos
- M-317: Sin comentarista
- M-319: Sin eco/reverb en túnel/vestuario/estadio
- M-321: Volúmenes por bus sin perfil «noche»/audífonos
- M-322: Sin audio espacial en la ciudad (fuentes 3D)
- M-324: Sin prueba que detecte clipping/silencios
- 1056: Ilustraciones vectoriales para los eventos narrativos
- 1057: Avatares minimalistas generados a partir de atributos
- 1061: Vibración breve en decisiones importantes
- 1066: Cántico del club reproducido en momentos clave
- 1069: Pantalla de carga con datos curiosos del club
- 1073: Gráficos limpios para finanzas y evolución de jugadores

### Personalización y estética (15)

- 39: Colecciones especiales (edición aniversario, homenaje)
- 40: Personalización del logo del club en redes sociales
- 42: Personalización del himno/cántico del club
- 45: Diseño de banderines y merchandising
- 294: Personalización del bus del equipo
- 34: Diseñador de camiseta de arquero
- 41: Personalización de la mascota del club
- 43: Personalización de la bandera del club
- 44: Personalización de uniforme del cuerpo técnico
- 292: Personalización de la sala de prensa
- 293: Personalización del palco presidencial
- 295: Personalización del avión/transporte para giras
- 296: Personalización de la app oficial del club (ficticia)
- 297: Personalización del sitio web del club (ficticio)
- 299: Personalización de la ceremonia de presentación de fichajes

### Traducciones (9)

- M-459: Cinco idiomas de los nueve nacieron con frases que luego se
- M-461: Las cadenas con %s/%d dependen del orden de argumentos; en
- M-464: No existe un informe de «frases por pantalla»: no se sabe qué
- M-466: datos/idiomas_extra.json se reescribe entero con cada ampliación
- M-468: Plurales y géneros en las 69 frases nuevas (p. ej. «%d botones»)
- M-328: Patrones numéricos (patrones 58) con plurales simples
- M-329: Sin género gramatical (entrenadora/jugadora) en todos los idiomas
- M-330: Formatos de fecha/número por idioma
- M-332: Narración traducida (narracion.json) sin revisión nativa

### Rendimiento (6)

- M-349: Generación de Mundo (384 clubes) y Reales.aplicar: medir
- M-351: Hilos: ¿se usan para IA/ciudad?
- M-352: GC/alloc en _process (Dictionary por jugador)
- M-353: Valorar C#/GDExtension sólo si el motor domina CPU
- M-355: Sin modo batería/60→30 FPS en móvil
- M-356: Memoria de la ciudad ×4 (2.640 m)

### Legal y repositorio (6)

- M-419: .git 5,5 GB con punteros LFS antiguos
- M-426: Archivos grandes sueltos (.glb >5 MB)
- M-428: .zip de terceros dentro de recursos/ (punteros LFS)
- M-432: Sin política de contenido (religión/política ficticia)
- 1095: Compatibilidad hacia atrás de las bases de datos
- 1093: Encuestas a jugadores para priorizar funciones

### Verificar con prueba automática (DESPUÉS) (296)

Existen según la auditoría del 24-10; falta la prueba del banco («cómo probar» en el plan). No tocan el partido ni la primera hora.

**Gestión deportiva** (46)
- 62 Relación entre compañeros (química de vestuario); 75 Riesgo de perder canteranos a otros clubes; 262 Prestigio internacional del jugador; 265 Reconversión de jugador a manager/staff al retirarse; 267 Rendimiento afectado por vida personal (eventos); 341 Sistema de fair play entre hinchadas (premia buena conducta); 420 Reconversión de posición (lateral a central, extremo a…; 421 Entrenamiento de habilidades específicas (penales, cabeceo…; 422 Curva de aprendizaje según edad: los jóvenes progresan más…; 423 Techo de crecimiento visible solo mediante ojeadores…; 441 Video-análisis grupal antes de rivales difíciles; 442 Índice de calidad de instalaciones que multiplica el…; 443 Veteranos que ya no mejoran pero transmiten experiencia; 476 Sistema de regens: nuevas generaciones que reemplazan a los…; 477 Hijos de jugadores históricos que heredan el apellido; 479 Probabilidad alta de que el hijo juegue en la posición del…; 480 Hijo que debuta en el club donde su padre fue leyenda; 481 Presión mediática específica sobre el hijo de una leyenda; 482 Riesgo narrativo de que el hijo nunca alcance el nivel del…; 483 Caso excepcional: el hijo supera al padre y se vuelve ícono; 484 Nietos de jugadores en partidas de muy largo plazo; 485 Hermanos futbolistas con bonificación de química en cancha; 486 Gemelos con atributos casi idénticos; 491 Época dorada: oleada de talento en un país cada cierto…; 492 Decadencia futbolística de un país si su liga colapsa; 495 Cantidad y calidad de regens condicionada por la inversión…; 497 Historia de origen del regen (barrio humilde, academia de…; 498 Biografía breve autogenerada para cada regen; 499 Avatar generado proceduralmente en estilo minimalista; 502 Etiqueta mediática "el nuevo [leyenda]" con la presión que…; 508 Árbol genealógico navegable de familias futbolísticas; 516 Catálogo amplio de lesiones con tiempos de recuperación…; 517 Diferenciación entre lesiones musculares, articulares y…; 520 Rasgo de jugador propenso a lesionarse; 521 Historial médico que afecta el valor de mercado; 525 Médico del club con nivel de competencia propio y mejorable; 529 Lesión sufrida durante una gira de selección nacional; 530 Lesión larga que obliga a un fichaje de emergencia; 531 Ventana de fichaje de emergencia por lesión grave (regla…; 532 Retiro forzado por lesión crónica; 535 Fatiga acumulada como variable distinta de la forma física; 537 Descanso programado como herramienta preventiva; 539 Enfermedades no deportivas que arruinan una semana de…; 541 Estadística de días perdidos por lesión en la temporada; 542 Comparativa de tu departamento médico contra el resto de la…; 543 Rehabilitación con progreso visible semana a semana

**Competiciones y reglamento** (42)
- 802 Designación arbitral conocida antes del partido; 803 Historial de resultados con cada árbitro; 804 Reclamo formal por una designación arbitral; 805 VAR activable o no según la competencia; 806 Errores arbitrales que generan polémica y narrativa; 807 Sanción por reclamar públicamente contra el arbitraje; 808 Expulsión del DT y prohibición de dirigir el partido…; 813 Castigo largo por agresión dentro del campo; 817 Jugador que da positivo y el impacto deportivo y de imagen; 818 Defensa legal del club en un caso de dopaje; 819 Reglamento de competencia consultable dentro del juego; 826 Sanción por alineación indebida; 827 Pérdida de puntos por incumplimiento administrativo; 831 Licencia de club exigida para competir; 832 Requisitos de infraestructura mínima por división; 833 Requisitos financieros para obtener la licencia; 834 Auditoría federativa anual; 837 Presidente de la liga con agenda propia; 844 Fecha FIFA que te deja sin jugadores clave; 846 Compensación económica por cesión a la selección; 847 Cupos obligatorios de juveniles en cancha; 848 Bonificación federativa por dar minutos a canteranos; 850 Playoffs de descenso con máxima tensión; 862 Convocatorias con lista preliminar y lista definitiva; 863 Jugadores nacionalizados por años de residencia; 867 Copa del mundo simulada cada cuatro años; 871 Conflicto club-selección por un jugador clave; 872 Jugador que vuelve lesionado o agotado de la selección; 874 Vitrina mundialista que dispara el precio de tus jugadores; 881 Amistosos internacionales que generan ingresos; 886 Editor de competencias personalizado; 890 Copas de eliminación directa; 893 Supercopa entre campeones; 894 Copa de la liga como torneo secundario; 895 Torneos de verano y amistosos de pretemporada; 896 Copa internacional de clubes; 901 Sorteo transmitido en vivo como evento del juego; 903 Fase de grupos con múltiples criterios de clasificación; 904 Eliminatoria a partido único en cancha neutral; 905 Final única en sede predefinida con años de anticipación; 907 Premios económicos crecientes por fase alcanzada; 908 Cupos internacionales asignados por posición en la liga

**Mercado y agentes** (41)
- 88 Jugadores que piden ser vendidos; 446 Red de ojeadores contratables con especialidad regional; 448 Informes con rango de incertidumbre en vez de números…; 449 Ojeadores con distinto nivel de precisión y sesgos propios; 450 Ojeador que exagera sus hallazgos para justificar su sueldo; 453 Base de datos que se va revelando a medida que investigas; 459 Competencia con otros clubes por el mismo objetivo; 461 Informe de personalidad además del informe de habilidad; 462 Informe médico previo al fichaje, con costo asociado; 466 Ojeador que renuncia si ignoras sistemáticamente sus…; 468 Presupuesto de scouting separado del de fichajes; 469 Análisis de datos como alternativa moderna al ojeo…; 470 Departamento de análisis con modelo estadístico propio del…; 471 Conflicto interno entre el ojeador tradicional y el…; 475 Informe de "jugadores similares" para reemplazar una salida; 583 Jugadores libres disponibles durante todo el año; 584 Cesiones con opción de compra y con obligación de compra; 585 Cesión con porcentaje del sueldo pagado por el club de…; 586 Intercambio de jugadores más diferencia en dinero; 587 Porcentaje de futura venta como moneda de negociación; 590 Pago en cuotas a varios años y su efecto en el flujo de caja; 593 Terceros propietarios del pase como dilema normativo; 594 Guerra de ofertas entre varios clubes por el mismo jugador; 595 Jugador que rechaza tu club por falta de proyecto deportivo; 598 Presión del agente para subir su comisión; 602 Cupo de extranjeros configurable por liga; 603 Límite de plantel y exigencia de jugadores formados en casa; 608 Bonificación reputacional por operaciones rentables; 610 Paciencia del club vendedor como contador visible en la…; 611 Renovación preventiva para no perder a un jugador gratis; 613 Agente libre estrella disponible cada cierto tiempo; 616 Agentes con cartera propia de jugadores; 617 Nivel de confianza construido con cada agente; 620 Superagente que controla a media liga; 622 Agente que filtra información a la prensa; 623 Oferta de retorno por comisión como decisión ética con…; 625 Sanción por incumplir el fair play financiero; 628 Reputación limpia como ventaja concreta en negociaciones; 630 Fichaje impuesto directamente por el dueño del club; 631 Rechazar un fichaje impuesto y ganarte un enemigo interno; 637 Jugador de tu plantel implicado en apuestas

**Hinchada, prensa y redes** (32)
- 136 Nivel de aprobación general de la afición; 148 Tendencias/hashtags según eventos del club; 159 Rumores de fichajes filtrados por la prensa; 736 Segmentación de la hinchada en grupos con demandas distintas; 737 Hinchas históricos frente a hinchas nuevos atraídos por el…; 739 Protestas por el precio de las entradas; 741 Banderazo de apoyo antes de un partido clave; 746 Incidentes que derivan en sanciones para el club; 749 Abonos de temporada con distintos planes y coberturas; 750 Precios dinámicos según el atractivo del partido; 752 Día del hincha con actividades dentro del estadio; 753 Peñas o filiales del club en otras ciudades; 755 Encuesta de satisfacción a los hinchas; 765 Rama de fútbol femenino como área gestionable; 766 Rama de futsal o fútbol playa como apuesta menor; 767 Deporte adaptado y su impacto en la imagen institucional; 769 Índice de reputación social del club; 772 Periodistas con línea editorial y sesgos definidos; 773 Periodista que te tiene manía y busca desgastarte; 775 Titulares generados según resultados y declaraciones; 776 Guerra mediática con un DT rival; 777 Declaración pública que motiva o desmotiva al plantel; 780 Entrevista larga en un programa deportivo; 781 Programa de debate donde se discute tu gestión; 787 Vocero del club habilitado para hablar en tu lugar; 789 Documental tras bambalinas: ingresos a cambio de exposición; 790 Cámaras en el vestuario como decisión rentable pero riesgosa; 794 Derechos de TV negociados individualmente o en bloque; 795 Horarios de partido impuestos por la televisión; 797 Cobertura internacional al firmar a una estrella; 799 Archivo navegable de portadas históricas del club; 800 Narrador de temporada que resume la campaña como relato

**Economía y club** (26)
- 255 Eventos comunitarios fuera del fútbol (caridad); 276 Terreno disponible para expandir la ciudad deportiva; 642 Balance con activos, pasivos y patrimonio; 643 Flujo de caja proyectado a doce meses; 647 Deuda bancaria con tasa e intereses visibles; 649 Renegociación de deuda con los acreedores del club; 653 Sanción deportiva por deuda: resta de puntos; 654 Prohibición de fichar mientras exista deuda pendiente; 656 Procedimiento de reorganización para salvar al club; 657 Liquidación del club como final de partida alternativo; 658 Administrador externo designado que limita tus decisiones; 664 Emisión de bonos del club comprados por los propios hinchas; 667 Multipropiedad: red de clubes bajo un mismo dueño; 668 Club satélite donde ceder juveniles; 684 Voto de censura del directorio; 685 Padrón de socios que crece o decrece según tu gestión; 686 Cuota social como ingreso estable y predecible; 688 Accionistas con intereses distintos: deportivo contra…; 696 Club filial en otra ciudad o país; 697 Directorio con miembros de personalidad definida; 698 Director deportivo con autonomía delegable; 701 Paciencia del directorio como barra siempre visible; 702 Despido y búsqueda posterior de un nuevo cargo; 703 Ofertas de otros clubes en plena temporada; 706 Reputación profesional que abre o cierra puertas; 709 Historial de cargos con estadísticas completas de tu carrera

**Estadio y club 3D** (25)
- 1 Ampliación de estadio por sectores (norte, sur, palcos); 2 Nivel máximo de estadio sin límite realista ("niveles…; 17 Canchas auxiliares para categorías juveniles; 328 Celebración de aniversario del club (ej. cada 5 o 10 años); 329 Celebración especial al llegar a un hito de trofeos (ej.…; 330 Placas conmemorativas de hitos históricos; 711 Mapa de la ciudad con terrenos comprables; 714 Barrio del club que se desarrolla junto con el éxito…; 715 Negociación con la municipalidad por permisos de…; 716 Oposición vecinal a la ampliación del estadio; 719 Arriendo del estadio para conciertos y eventos masivos; 720 Ingresos por eventos no deportivos; 721 Daño al césped por eventos y su costo de reparación; 724 Hotel del club como negocio anexo; 725 Restaurante y bar temático del club; 726 Clínica deportiva abierta al público general; 727 Escuela de fútbol comercial con franquicias; 728 Centro comercial anexo al estadio; 729 Paneles solares y sostenibilidad con beneficios tributarios; 730 Certificación ecológica del estadio; 731 Seguridad privada y control de accesos; 732 Sistema de cámaras y protocolo antiviolencia; 733 Multas por incidentes ocurridos en el estadio; 734 Sanción de partido a puertas cerradas; 735 Aforo reducido temporal y su golpe económico

**Modos, meta e historia** (24)
- 178 Mejor DT del año; 218 Leyendas contratables como embajadores; 245 Resumen semanal tipo "informe de gestión"; 317 Efemérides: "un día como hoy" con hechos pasados del club; 949 Modo salvar al club con quiebra inminente; 950 Modo solo canteranos: prohibido fichar; 952 Modo un solo país: sin extranjeros permitidos; 953 Modo trotamundos: obligado a cambiar de club cada dos años; 955 Modo invicto: la partida termina con la primera derrota; 959 Modo dueño: solo decisiones financieras; 961 Modo director deportivo: solo fichajes y cantera; 970 Modo caja de arena con recursos infinitos; 973 Modificadores activables al iniciar la partida; 974 Puntaje de partida calculado según la dificultad elegida; 988 Nivel de perfil de gestor que persiste entre partidas; 990 Colección de cromos de jugadores legendarios de tus partidas; 991 Museo global que reúne lo logrado en todas tus carreras; 993 Récords personales por carrera; 997 Hitos narrativos que cierran capítulos de tu carrera; 998 Final de carrera con evaluación completa de tu legado; 1002 Resumen de vida al momento de retirarte; 1004 Historial de todos los clubes dirigidos con su balance; 1006 Mundo distinto en cada partida nueva; 1010 Nueva partida con el mundo heredado de la anterior

**Personas y narrativa** (21)
- 54 Nivel de carisma que afecta negociaciones; 188 Escándalo mediático de un jugador; 190 Oferta irrechazable por un jugador clave; 194 Jugador que pide salir por motivos personales; 196 Incidente de seguridad en el estadio; 197 Petición de la comunidad local (obra social); 198 Oferta de inversión extranjera con condiciones; 546 Jerarquía de vestuario visible (líderes, influyentes…; 550 Jugador que se queja por falta de minutos; 551 Jugador que pide expresamente salir del club; 556 Elección de capitán y vicecapitán con efecto real en el…; 560 Charla motivacional con distintos tonos y resultados…; 561 Jugadores que responden mejor al elogio o a la exigencia; 563 Jugador conflictivo pero determinante como dilema permanente; 564 Multas internas por indisciplina; 565 Reglamento interno del club configurable por ti; 566 Fiestas y escándalos extradeportivos con consecuencias; 569 Extranjero que no se adapta al país y pide volver; 572 Compañero del mismo país que facilita la adaptación; 574 Efecto de tus declaraciones públicas sobre el ánimo interno; 577 Rebelión de vestuario capaz de costarte el puesto

**Datos del mundo y editor** (12)
- 911 Base de datos editable desde el propio juego; 912 Editor de ligas, clubes y jugadores sin salir de la partida; 914 Exportación de tu base para compartirla con otros; 916 Editor de escudos con formas y capas; 917 Editor de camisetas con patrones predefinidos; 918 Editor de estadios simplificado; 919 Nombres genéricos por defecto con opción de renombrar todo; 923 Sistema de parche de datos separado del programa principal; 924 Editor de nombres de competencias; 928 Editor de atributos con validación de rangos; 929 Generador aleatorio de mundo ficticio completo; 930 Modo mundo alternativo sin ningún dato real

**Partido** (9)
- 393 Editor simple de jugadas ensayadas de córner; 394 Editor de jugadas ensayadas de tiro libre; 400 Análisis previo del rival con puntos débiles sugeridos; 404 Índice de compatibilidad jugador-rol; 405 Jugadores que rinden mejor o peor en un rol específico; 411 Evolución táctica por era: el fútbol de moda cambia con los…; 412 Estadística de eficacia por cada táctica utilizada; 413 Pizarra táctica para explicar el plan en la charla previa; 414 Rotación planificada para calendarios congestionados

**Interfaz y accesibilidad** (9)
- 1011 Navegación por pestañas inferiores fijas; 1015 Marcar mensajes como leídos en bloque; 1018 Favoritos para acceso rápido a pantallas frecuentes; 1019 Comparador de jugadores lado a lado; 1038 Glosario integrado de términos del juego; 1041 Modo experto que oculta toda la ayuda; 1043 Widget de próximo partido; 1044 Widget de finanzas resumidas; 1045 Widget de tabla de posiciones

**Audio y presentación** (8)
- 1053 Paleta que se adapta automáticamente a los colores del club; 1054 Tipografía condensada, legible en pantallas pequeñas; 1059 Animaciones cortas y funcionales, nunca bloqueantes; 1065 Música de menú discreta y desactivable; 1068 Modo silencioso completo para jugar en público; 1070 Portada de diario animada para las noticias importantes; 1071 Tarjetas visuales para los resúmenes de temporada; 1074 Celebración sobria pero satisfactoria al ganar un título

**Personalización y estética** (1)
- 291 Personalización del vestuario (colores, mobiliario)

## 4. DESCARTAR (63)

Al borrarlas del plan, la que queda viva es la que se cita.

- M-279 (27 módulos de visor/ y 8 de nucleo/ sin…): superada por M-404 (medida del 27-10).
- M-167 (Calzadas = cajas de asfalto con marcas propias…): contradice decisión: no sustituir calzadas (semáforos).
- M-263 (Eventos únicos (13) y control real; pocos días de…): superada por Agenda y Citas (fases 3-4).
- M-174 (Interior de coche sin modelo (salpicadero 2D)): superada: cabina 3D del coche (27-10).
- M-190 (Sin clima dinámico en la ciudad (lluvia con…): superada: lluvia, charcos y suelo mojado (27-10).
- M-191 (Sin ciclo día/noche más allá del slider): superada: reloj vivo de la fase 3.
- M-193 (Sin vegetación variada (setos, flores) más allá…): superada: arriates con flores (semana 5).
- M-239 (Junta/accionistas: sin asambleas jugables): superada: asamblea de socios jugable (fase 4).
- M-251 (Gente del club (10 personas) sin crecimiento de…): superada: afinidad del personal (`afinidad_club.gd`).
- M-254 (Vida del DT (bienestar, casa, familia): sin…): superada: necesidades y factor de riesgo (fase 3).
- M-259 (Clima en partidos con efecto menor): superada: clima en gestos, agarre y balón (27-10).
- M-005 (Colores propios de butacas en 47 de 176 estadios…): superada: butacas por nivel con color del club.
- M-447 (Las cadenas en español escritas directo en ui/…): duplicada de M-277 (textos sueltos en ui/).
- M-154 (Sin online): contradice: online fuera de alcance.
- M-357 (Capturas pesadas en repo (pruebas/capturas)): hecha: capturas borradas del repo (26-10).
- M-334 (Sin RTL (árabe, hebreo) aunque hay KSA/EGY/MAR): contradice: 9 idiomas, no sumar más.
- M-427 (pruebas/capturas crece sin control): hecha: capturas borradas del repo (26-10).
- 211 (Línea de tiempo histórica del club): duplicada de M-257 (línea de tiempo).
- 231 (Modo historia con objetivos guiados): duplicada de M-261 (modo historia).
- 238 (Comparación con otros jugadores (si hay online)): contradice: online fuera de alcance.
- 240 (Modo "carrera rápida" para partidas cortas): duplicada de 968 (modo de una temporada).
- 250 (Modo multijugador asíncrono (comparar ligas entre…): contradice: necesita servidor (online fuera de alcance).
- 318 (Línea de tiempo navegable de temporadas anteriores): duplicada de M-257 (línea de tiempo).
- 348 (Eventos climáticos que afectan la asistencia y el…): duplicada de 251 (clima y asistencia).
- 349 (Modo "reconstrucción": heredar un club en crisis…): superada por 949 (salvar al club, existe).
- 149 (Trolls y críticos recurrentes en redes): duplicada de M-243 (trolls en redes).
- 229 (Modo sandbox sin presión de despido): superada por 970 (caja de arena, existe).
- 336 (Modo "día a día" con calendario navegable…): superada: reloj y Agenda del móvil (fase 3).
- 241 (Accesibilidad: modo daltónico, texto ajustable): duplicada de 1024 y 1025 (accesibilidad).
- 243 (Modo offline completo): duplicada de 942 (sin conexión).
- 1049 (Rendimiento fluido en dispositivos de gama baja): duplicada de 944 (gama baja).
- 1080 (Sin mecánicas de pagar para ganar): ya se cumple: sin pago (decisión 26-10).
- 1096 (Sin necesidad de conexión permanente para jugar): duplicada de 942 (sin conexión).
- 445 (Historial gráfico de evolución de atributos por…): duplicada de M-295 (gráficos en la ficha).
- 655 (Descenso administrativo por insolvencia): duplicada de M-219 (descenso administrativo).
- 682 (Elecciones de presidente cada cierto número de…): superada: elecciones cada 4 temporadas (fase 4).
- 972 (Dificultad ajustable por sistema (finanzas…): duplicada de 233 (dificultad por sistema).
- 984 (Modo sin recarga de partida guardada): duplicada de 971 (sin recarga).
- 1023 (Modo oscuro y modo claro): duplicada de M-302 (tema claro/contraste).
- 1050 (Consumo de batería optimizado por diseño): duplicada de M-355 (modo batería).
- 1052 (Íconos simples y consistentes en toda la…): duplicada de M-462 (iconos con emoji).
- 1058 (Cancha 2D con fichas en los colores reales del…): duplicada de 351 (vista 2D con fichas).
- 1060 (Transiciones suaves entre pantallas): duplicada de M-304 (transiciones).
- 1081 (Sin cajas de recompensa ni azar pagado): ya se cumple: sin pago (decisión 26-10).
- 606 (Burbuja de precios que crece con el paso de los…): duplicada de M-210 (burbujas de precios).
- 612 (Precontrato con jugador en su último semestre): duplicada de M-217 (precontratos).
- 694 (Fusión con otro club): duplicada de 275 (fusión con otro club).
- 743 (Mosaico organizado por la hinchada): duplicada de 143 (mosaicos).
- 748 (Programa de socios con beneficios por antigüedad): duplicada de 145 (fidelización de hinchas).
- 935 (Tabla de clasificación global de gestores en línea): contradice: online fuera de alcance.
- 937 (Muro o foro de comunidad integrado): contradice: online fuera de alcance.
- 938 (Desafíos semanales creados por la comunidad): contradice: online fuera de alcance.
- 939 (Sistema de valoración de paquetes de datos): contradice: necesita servidor de comunidad.
- 941 (Herramientas de moderación para contenido de la…): contradice: necesita servidor de comunidad.
- 945 (Guardado en la nube con recuperación de partidas): duplicada de 234 (guardado en la nube).
- 975 (Ranking local de mejores puntajes): duplicada de 283 (ranking interno).
- 977 (Multijugador en línea con varios gestores en la…): contradice: online fuera de alcance.
- 978 (Liga privada para jugar con amigos): contradice: online fuera de alcance.
- 1001 (Comparación de tu carrera con la de otros usuarios): contradice: online fuera de alcance.
- 1014 (Filtro de notificaciones por importancia): duplicada de M-296 (filtros de notificaciones).
- 1047 (Notificaciones opcionales del próximo partido): duplicada de 244 (notificaciones).
- 1048 (Sincronización de partida entre teléfono y tablet): duplicada de 934 (sincronizar dispositivos).
- 1092 (Canal de reporte de errores dentro del juego): duplicada de M-430 (reporte de errores).

## 5. Decide el dueño (20 decisiones de producto, sin clasificar)

- 943: Peso reducido de la aplicación como ventaja competitiva.
- 1051: Estilo visual plano de alto contraste, legible al sol.
- 1055: Tablas como elemento estético central.
- 1072: Estética de cuaderno de gestión en la parte administrativa.
- 1075: Identidad visual propia que no imite a los juegos de referencia.
- 1076: Juego base pagado sin anuncios como opción premium.
- 1077: Versión gratuita con anuncios no intrusivos.
- 1078: Anuncios solo en pantallas de carga.
- 1079: Compra única para quitar anuncios.
- 1082: Expansiones de contenido (ligas, modos).
- 1083: Paquetes cosméticos sin ventaja deportiva.
- 1084: Apoyo voluntario al desarrollador con recompensa simbólica.
- 1085: Precio accesible pensado para Latinoamérica.
- 1086: Precio regional por país.
- 1087: Demo gratuita con una temporada completa.
- 1088: Comunicación clara de qué se paga y qué no.
- 1089: Hoja de ruta pública de actualizaciones.
- 1090: Beta abierta con comunidad de prueba.
- 1099: Código de conducta para la comunidad.
- 1100: Compromiso de dejar el juego jugable aunque se detenga el desarrollo.

Contexto para decidir: el dueño ya fijó «por ahora sin pago» (26-10), así que 1076-1079, 1083-1084 y 1087 piden primero el modelo de venta; 1085-1086 y 1088 dependen de ese modelo; 1089, 1090 y 1099 son de comunidad tras lanzar; 943, 1051, 1055, 1072, 1075 y 1100 son principios que el juego ya puede declarar.

## 6. Recuento

Filas leídas del plan: 1201 (§5: 338; §6: 163; §7: 700) + 20 decisiones = 1221.
Clasificadas: LANZAMIENTO 68 + verificar-LANZAMIENTO 43 + DESPUÉS 731 + verificar-DESPUÉS 296 + DESCARTAR 63 = 1201; + 20 «decide el dueño». Ninguna fila sin clasificar ni repetida en dos grupos.
