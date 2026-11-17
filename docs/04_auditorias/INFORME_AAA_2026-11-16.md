# INFORME AAA — Qué le falta a Dinastía para ser un juego AAA y cómo superar a FC 27 y a PES 2020 (16-11-2026)

Pedido del dueño: «informe mínimo de 15.000 páginas, analizando todo el juego, qué necesitamos para llegar a AAA y cómo superar a FC 27 y PES 2020, siendo así de eficiente».
Decisión de formato (honesta): 15.000 páginas son ~7,5 millones de palabras; nadie las leería y casi todo sería relleno. Aquí va lo mismo **condensado**: cada sección es accionable, con cifras del repo y prioridades. Lo que exige más detalle remite al documento que ya existe (no se duplica).
Marcas: [M] medido en el repo o en la laptop del dueño · [D] documento del proyecto · [C] conocimiento general de la industria/serie (no verificado hoy) · [E] estimación mía.
Sobre FC 27: salió después de mi corte de conocimiento; lo que digo de él es la línea de la serie FC 24-26 (HyperMotion, PlayStyles, FC IQ, Ultimate Team, Rush, Carrera) proyectada [C][E]. Hay que validarlo con capturas/vídeos del dueño (`referencias_del_dueño`).

---

## 0. Resumen en 12 líneas

1. **Dinastía hoy ≈ 4,6/10 frente a PES 2020 ≈ 7,1** (`COMPARATIVA_PES2020.md`). FC 27 estaría ≈ 7,5-8 [E]. La distancia está en el **partido** (jugabilidad 3, animación 4, presentación 3), no en el contenido.
2. **Lo que ya gana**: gestión del club (8 vs 6 de PES), accesibilidad e idiomas (7 vs 5), amplitud del mundo (1.069 clubes, 62 ligas, 69 selecciones) [M], y La Ruta como modo jugador con premios y galas 3D.
3. **AAA no es alcanzable en sentido literal** (AAA = 200-1.000 personas, 60-300 M€, captura de movimiento, licencias). Lo alcanzable y rentable es **«AA con un partido de nivel AAA en sensación»** y una gestión que ningún AAA tiene.
4. **Regla de oro**: un juego de fútbol se juzga en los primeros 3 minutos de partido. Todo el presupuesto de tiempo de 2026-2027 debe ir 60 % al partido (control + animación + cámara/presentación), 25 % a menús/flujo, 15 % a todo lo demás.
5. **Rendimiento**: ULTRA ~39-41 FPS y ULTRA BAJA ~100-107 en la laptop Intel UHD [M]. Suficiente: **congelar el rendimiento** como «no regresar» y gastar en calidad.
6. **Deuda técnica**: 2.410 scripts .gd, ~339.000 líneas [M]. Es un tamaño de estudio mediano; sin recorte de alcance, el pulido nunca llega. Propuesta: **versión 1.0 = solo club + partido + La Ruta + 5 ligas completas**; el resto detrás de banderas.
7. Para **superar a PES 2020** basta con: partido 7/10, presentación TV 6/10, caras 6/10 y conservar la gestión. Plazo realista [E]: 6-9 meses de trabajo enfocado.
8. Para **superar a FC 27** no hay que competir en gráficos ni licencias (imposible): hay que ganar en **profundidad de carrera, mundo vivo, respeto al jugador (sin pago ni gacha), móvil/PC modesto, modding y accesibilidad**. Ahí FC es débil desde hace años [C].
9. Las 3 apuestas que cambian el juego: (a) **«sensación de control» medible** (latencia, giro, inercia) con prueba ciega; (b) **director de TV** completo (planos al público, repeticiones con contexto, paquete gráfico único); (c) **una historia por partido** (la gestión y La Ruta alimentan lo que pasa en la cancha y lo que se narra).
10. Falta un **comentarista**: es la carencia más audible. Plan sin presupuesto: texto + frases cortas TTS con licencia comercial, o voz grabada por voluntarios (ver §6.6).
11. **Proceso**: el método (banco, huellas, Sonar, 450 líneas) es mejor que el de muchos indies. Lo que falta es **prueba con jugadores reales** (0 hasta hoy salvo el dueño). Sin eso no hay nota fiable.
12. Hoja de ruta de 4 hitos en §10; tabla de 100 tareas priorizadas en §11.

---

## 1. Qué significa «AAA» y qué parte aplica a Dinastía

| Rasgo AAA | ¿Aplica? | Equivalente alcanzable para Dinastía |
|---|---|---|
| Captura de movimiento propia (miles de clips) | No (sin presupuesto) | Animaciones gratuitas con licencia comercial (Mixamo, CC0, League-Soccer Apache 2.0: 296 clips [D]) + **mezcla procedural** (IK de pies, inclinación por aceleración, giro de cadera) que esconda la falta de clips |
| Licencias (FIFPro, ligas, estadios) | No (decisión del dueño) | Nombres modificados + editor + `pack_real.json` local; **modding fácil** como argumento |
| Fotogrametría de caras | No en lo público (legal) | Biblioteca de 300-500 caras mezcladas en público; `.pck` privado para lo real [D] |
| Equipo de QA de cientos | No | Banco automático (>30 bancos, «FIN. 0 fallos»), huellas byte a byte, caza de fallos; **sumar 10-30 probadores externos** |
| Presentación de TV de broadcast | **Sí, parcialmente** | Es diseño y código, no presupuesto: director de cámara, gráficos, repeticiones, sonido de grada |
| Sensación del control | **Sí** | Es ajuste fino y medición: lo que más rinde por hora |
| Estabilidad y pulido | **Sí** | Recortar alcance y cerrar |
| Contenido enorme | Ya está (1.069 clubes) | Convertir volumen en **calidad percibida** (escudos, uniformes, estadios icónicos) |

Conclusión: de los 8 rasgos, 4 son de dinero (no aplican) y 4 son de **criterio y horas** (sí aplican). El informe se centra en esos 4.

---

## 2. Estado actual del juego, por sistema (foto del 16-11)

Fuente principal: `PLAN_GENERAL.md`, `COMPARATIVA_PES2020.md`, `INFORME_SESION_2026-11-15.md`, `MOTOR_LEAGUE_SOCCER_PLAN.md`, `PASO_CPP_PLAN.md`.

### 2.1 Partido jugable (motor C4)
- **Qué es**: League-Soccer + nuestra decisión con balón + colocación con caché + nuestra locomoción (orden 39) [D]. Banderas `C4_*`. Física de los 22 en C++ (`mover_nativo.cpp`, 238 → 96 µs por paso) [M].
- **Fuerte**: arquitectura medible, huellas reproducibles, regates y duelos, motor barato (~1 ms por fotograma) [M].
- **Débil**: veredicto del dueño «jugabilidad muy mala» (3-11) aún sin una nota nueva; locomoción poco natural; hitboxes que atraviesan cuerpos (P4); pases y tiros sin «peso».
- **Nota**: 3/10 → objetivo 7/10.

### 2.2 IA (compañeros, rivales, portero)
- F1-F8 los lleva el dueño/PES 6 (orden 23-24) [D]. 32 partidos de semilla fija; 2,3 goles por partido [D].
- **Falta**: métricas de fútbol real (posesión, pases por secuencia, PPDA, distancia entre líneas, xG por tiro) y 8 niveles de dificultad conectados de verdad.
- **Nota**: 4/10 → 7/10.

### 2.3 Animación y cuerpos
- 296 clips de League + ~25 festejos + catálogo de animaciones gratuitas (sesión 10) [D].
- **Falta**: transiciones (mezcla), IK de pies, contacto físico (hombro con hombro, entradas), cabezas que siguen el balón, cuello/cabeza sin costura (sesión 14 lo empezó).
- **Nota**: 4/10 → 7/10.

### 2.4 Gráficos de jugadores, estadio, público
- Caras: 300 mezcladas + procedural; reales solo en `.pck` [D]. Público 2D hiperrealista: prototipo apagado (−40 % triángulos) [M].
- Estadios: 536 arquitecturas paramétricas, ~30 con piezas reales, 0 modelos individuales [D].
- **Nota**: 4/10 → 6-7/10.

### 2.5 Presentación de TV, audio y narración
- Cámara de TV de 4 planos, repeticiones; sin comentarista; sonidos CC0 [D].
- **Nota**: 3/10 → 6/10. **Es la mejora con más rendimiento por hora** después del control.

### 2.6 Menús e interfaz
- Rediseño en curso al nivel del menú central de la Liga Master (Frente 1) [D]; subdivisión en pantallas completas (orden 46/51).
- **Riesgo**: sobrecarga («4 juegos en 1»). **Nota**: 5/10 → 8/10.

### 2.7 Gestión del club
- Finanzas con origen de cada ingreso, directiva, cantera, prensa, política, instalaciones, patrocinios [D]. **Nota**: 8/10. Es el **diferenciador**.

### 2.8 La Ruta (modo jugador)
- Habilidades por zona, coste por puesto/valor/nivel, media inicial ~60, premios, brazalete, galas 3D por premio [D].
- **Falta**: que lo juegue gente; ritmo de progresión medido (sonda ~5 min) en 3 clubes de 3 países (orden 34).
- **Nota estimada**: 6/10 → 8/10. Puede superar a la Carrera de jugador de FC [C].

### 2.9 Contenido
- 1.069 clubes, 62 ligas, 50 países, 26.725 jugadores, 69 selecciones, 9 idiomas [M].
- **Falta**: escudos más parecidos, uniformes base, estadios icónicos, trofeos por club (orden 15).

### 2.10 Rendimiento
- Laptop i3-N300 / Intel UHD, 1280x720: ULTRA ~39-41, ULTRA BAJA ~100-107 [M]. Suelo ~10 ms de CPU/presentación; 150 FPS en ULTRA BAJA no alcanzable ahí [M].
- Móvil: última medida del dueño 30 FPS en partido en MÍNIMA (~4-11); **sin medir después** [D]. **Esto es un riesgo abierto**.

### 2.11 Código y proceso
- ~339.000 líneas GDScript en 2.410 scripts; extensión C++ con gemelas; regla de 450 líneas; banco ~83 s; Sonar con 0 avisos [M][D].
- **Débil**: tamaño; muchas ramas y sesiones paralelas; documentos de estado que se acumulan (PLAN_GENERAL 2.850 líneas).

---

## 3. Matriz de brechas: Dinastía vs PES 2020 vs FC 27

Escala 1-10. FC 27 = estimación [E] con la línea de la serie.

| Área | Dinastía hoy | PES 2020 | FC 27 [E] | Meta 1.0 | ¿Cómo se gana? |
|---|---|---|---|---|---|
| Sensación del control | 3 | 8 | 7 | **7** | §5.1 perfil de manejo + prueba ciega |
| IA y táctica | 4 | 7 | 7 | 7 | §5.3 métricas reales y niveles |
| Animación/cuerpos | 4 | 8 | 9 | 6 | §5.2 mezcla procedural, IK, contactos |
| Caras/jugadores | 4 | 8 | 9 | 6 | §6.2 biblioteca pública + iluminación de piel |
| Estadios/público | 4 | 8 | 8 | 6 | §6.3 20-30 icónicos + público 2D + planos |
| Presentación TV | 3 | 7 | 9 | **7** | §6.1 director de TV |
| Audio/comentario | 4 | 6 | 8 | 6 | §6.5-6.6 |
| Menús | 5 | 7 | 6 | **8** | §7 (FC tiene menús lentos y llenos de tienda [C]) |
| Gestión/carrera | **8** | 6 | 6 | **9** | §8.1 |
| Modo jugador | 6 | 5 | 7 | **8** | §8.2 |
| Contenido/licencias | 4 | 6 | 10 | 6 | editor + modding |
| Rendimiento modesto/móvil | 5 | 8 | 6 (PC) | 8 | congelar y medir en teléfono |
| Accesibilidad/idiomas | **7** | 5 | 7 | 8 | ya está, pulir |
| Monetización justa | **10** | 6 | 3 | 10 | sin pago ni gacha: es marketing |
| Modding/apertura | 7 | 7 (option files) | 2 | **9** | §8.4 |
| Online | 0 | 6 | 9 | 0-3 | no competir (decisión del dueño) |

**Lectura**: para igualar a PES 2020 hay que subir 5 filas (control, IA, animación, TV, caras) unos 3 puntos cada una. Para «superar» a FC 27 hay que **cambiar el tablero**: no se gana en sus filas (licencias, online, gráficos), se gana en las nuestras (gestión, apertura, justicia, modesto/móvil, modo jugador), con un partido «suficientemente bueno y divertido» (7).

---

## 4. Diagnóstico: por qué hoy se siente lejos de AAA

1. **Alcance > capacidad**. 4 juegos en 1, ciudad 3D (apagada pero viva en código), minijuegos, museo, casa, política. Cada sistema está al 60-70 %; un AAA tiene pocos sistemas al 95 %. Sensación: «hay de todo, nada terminado».
2. **El partido cambió de motor 3 veces en 3 semanas** (propio → League → C4). Bien decidido, pero sin un periodo de pulido estable.
3. **Sin probadores externos**. Las notas salen del dueño y de bancos automáticos; los bancos miden igualdad, no diversión.
4. **La cámara de TV no cuenta historias**: sin planos al público, sin «reacción del banquillo», sin repetición con contexto, el partido se ve como una simulación.
5. **Silencio**: sin comentario y con poca reactividad de grada, el cerebro lo clasifica como «demo».
6. **Paralelismo de sesiones**: mucha energía en coordinación, cierres y documentos de estado (PLAN_GENERAL ya es un archivo histórico más que un plan).

---

## 5. El PARTIDO (60 % del esfuerzo)

### 5.1 Sensación del control — «perfil de manejo»
Objetivo: que el jugador sienta que **él** decide y el futbolista responde.

| Métrica | Cómo se mide | Objetivo [E] (referencia PES/FC [C]) |
|---|---|---|
| Latencia entrada→primer cuadro de respuesta | marca de tiempo en `Input` → cambio de estado del motor | ≤ 2 cuadros (≤ 33 ms a 60) |
| Aceleración 0→sprint | tiempo hasta 90 % de velocidad máx. | 0,6-1,1 s según atributo |
| Radio de giro a sprint | m en un giro de 90° | 2-4 m según agilidad/balance |
| Coste del giro con balón | pérdida de velocidad % | 15-40 % según regate |
| Pase: error angular | grados de desvío según atributo/presión | 1-8° |
| Tiro: ventana de «tiro pulido» | ms de la ventana de precisión | 80-150 ms |
| Recepción: primer toque | distancia del balón al pie tras control | 0,3-1,5 m |

Cómo se hace: una escena `pruebas/perfil_manejo.tscn` que reproduce entradas grabadas y vuelca las 7 cifras por banderas `C4_*`; se compara contra la tabla y contra la versión anterior. Después, **prueba ciega A/B** (el selector A/B/C ya existe, orden 38) con el dueño y 5-10 personas: voto de diversión.

Reglas de diseño (lo que hacen PES y FC [C]):
- **Inercia por atributo**, no global: el lento pesa, el rápido corta.
- **Asistencia de pase** escalonada (0-3) en Ajustes; en móvil, asistida por defecto.
- **Pase al hueco** con «anticipación del receptor»: el compañero empieza la carrera al pulsar, no al llegar el balón.
- **Tiro**: potencia por carga + ventana de precisión; el pie débil se nota.
- **Regate**: 6-8 movimientos legibles (amague, bicicleta, croqueta, frenada, sombrero, caño, roleta, cambio de ritmo) mejor que 40 confusos.
- **Defensa**: contención (mantener distancia) + entrada + presión de un compañero; sin contención no hay juego defensivo divertido.

### 5.2 Animación: esconder la falta de clips
- **Mezcla por velocidad y dirección** (blend space 2D: adelante/lado/atrás × caminar/trotar/correr/sprint).
- **IK de pies** con anclaje al suelo (existe `ancla_suelo`) y **IK de pierna al balón** en el toque: el pie se encuentra con el balón, no lo atraviesa.
- **Inclinación del tronco** por aceleración lateral; **giro de cadera** antes del de pies en cambios bruscos.
- **Cabeza y mirada al balón** (`mira_balon` pendiente): enorme ganancia de realismo por poco coste.
- **Contactos**: un sistema de «empujes» de 3 niveles (roce, carga, caída) con animaciones de reacción; resuelve el «atravesar cuerpos» (P4) junto con cápsulas de cuerpo.
- **Portero**: 10-12 animaciones clave (estirada baja/alta a cada lado, blocaje, despeje de puños, salida, 1 contra 1) son el 80 % de la credibilidad.
- **LOD de esqueleto** para jugadores lejanos: menos huesos, misma silueta (ya identificado como palanca de FPS [D]).

### 5.3 IA: que parezca fútbol
- **Métricas objetivo** (de ligas reales, datos públicos tipo FBref/StatsBomb abiertos [C]): posesión 35-65 %, pases por partido 350-600 por equipo, 10-15 tiros, xG total 2,5-3,0, goles 2,5-2,9, faltas 20-25, fueras de juego 3-5.
- Banco nuevo «estadística de fútbol real»: 50 partidos C4 CPU vs CPU con 10 clubes de 5 países (orden 34) → informe con desvíos.
- **Bloques de equipo** (alto/medio/bajo) y **ancho/compacidad** visibles en el HUD táctico.
- **Dificultad en 8 niveles** (orden 14): no subir la «trampa» (velocidad), sino la **calidad de decisión**: tiempo de reacción, lectura de pases, presión coordinada, precisión.
- Lo de F1-F8 es del dueño/PES 6: este informe solo propone **cómo medirlo**.

### 5.4 Reglamento y «sensación de partido real»
- Ventaja con señal del árbitro, tarjetas con su animación, VAR opcional (estilizado), lesiones con camilla, cambios con dorsal en el cartel, saques rápidos, barrera que se adelanta.
- Banco de «casos de reglamento» ya existe [D]: convertirlo en contrato visual con vídeo corto de cada caso.

---

## 6. LO QUE SE VE Y SE OYE

### 6.1 Director de TV (la palanca más barata)
Un **guionista de cámara** con estados: juego vivo → evento → plano de reacción (2-3 s) → repetición (si procede) → vuelta.
- Planos: TV principal, TV alta, detrás del arco, banda baja, **público** (falta grave, gol, ocasión, roja, penal), **banquillo/DT**, **jugador primer plano** tras gol/fallo, **árbitro** en la tarjeta.
- Repeticiones con **2 ángulos** y cámara lenta, contexto (marcador + minuto + nombre).
- **Paquete gráfico único**: marcador, rótulo de goleador, alineación, estadísticas al descanso, intro de equipos, todo con un mismo estilo por «mundo» (Clásico/Suave).
- Intro de partido de 20-30 s salteable: estadio exterior → túnel (existe `TunelVestuario`) → saludo → once inicial.
Estimación [E]: 3-4 semanas; sube la percepción más que cualquier mejora de malla.

### 6.2 Jugadores
- Piel: shader con dispersión subsuperficial barata (wrap lighting + color de sangre) y especular de sudor que sube con el minuto.
- Camisetas: tela con normal map de malla, dorsal y nombre nítidos (atlas), arrugas por pose (normal secundaria), parches claros arreglados (Frente 2).
- Pelo: cortes del Drive (licencia confirmada, orden 16) con tarjetas de pelo y sombreado anisótropo.
- Cuerpos por tipo (bajo, alto, fornido, delgado) desde atributos.

### 6.3 Estadio, público, luz
- **20-30 estadios icónicos** con su rasgo (cubierta, arco, fachada) y el resto paramétrico (536 arquitecturas ya existen).
- Público: 2D hiperrealista de lejos + 3D en el sector del plano de reacción; carteles y pancartas (atlas de ~24 textos ficticios por idioma) [D].
- Luz: preajustes de horario (13:00, 17:00 dorado, 21:00 noche con focos) y clima (lluvia con charcos en el césped, niebla, nieve).
- Césped: patrón de corte, desgaste en áreas por minuto, marcas de tacos.

### 6.4 Rendimiento: congelar
- Cifras actuales como **suelo**: ningún cambio visual entra si baja ULTRA de 38 o ULTRA BAJA de 95 en la laptop [M].
- Pendiente crítico: **medir en el teléfono del dueño** (última cifra ~4-11). Sin eso, la meta móvil es un deseo.

### 6.5 Grada y sonido ambiente
- Capas: murmullo base → cánticos por club (generados, sin letra real) → reacciones (uy, ole, silbido, aplauso, gol).
- Mezcla por cámara (más grada en planos al público).
- Sonido del balón por superficie y potencia; red del arco; golpe de poste.

### 6.6 Comentarista (sin presupuesto)
Opciones, de mejor a peor relación calidad/esfuerzo:
1. **Frases cortas grabadas por voluntarios** (español primero), 300-500 frases modulares («¡Gol de…!» + nombre genérico por dorsal/puesto), con licencia de cesión firmada.
2. **TTS local con licencia comercial** (modelos abiertos de licencia permisiva; verificar licencia del modelo y de la voz) para nombres.
3. **Rótulos de texto** con la narración generada (`montar_narracion.py` ya existe) como respaldo y para los 8 idiomas restantes.
Regla: poco y bien dicho; nunca repetir una frase en el mismo partido.

---

## 7. MENÚS E INTERFAZ (25 % del esfuerzo, junto con flujo)

- Referencia: menú central de la Liga Master de PES 2020 (Frente 1) [D].
- **Principio**: 1 pantalla = 1 decisión. Menú central con 4-5 destinos y una «tarea del día» (próximo partido, oferta, lesión, junta directiva).
- **Tiempos**: cualquier pantalla < 150 ms en abrirse en la laptop; transición única (deslizar + atenuar 120-180 ms).
- **Tipografía**: 2 familias máximo, 4 tamaños; cifras tabulares en tablas.
- **Mando y táctil**: todo navegable con R2/Cuadrado (orden 33) y con dedo (mando táctil FC Mobile, orden 40).
- **Donde se supera a FC**: FC llena el menú de tienda y avisos de Ultimate Team [C]. Dinastía: cero tienda, cero ruido, información útil.
- Prueba: 3 personas sin ayuda deben llegar a «jugar el próximo partido», «fichar» y «cambiar la táctica» en < 30 s cada una.

---

## 8. LO QUE NOS HACE ÚNICOS (cómo superar a FC 27 y PES 2020 de verdad)

### 8.1 Gestión del club como «mundo vivo»
- Ya hay finanzas, directiva, cantera, prensa, política, instalaciones [D]. Falta que **se sienta en la cancha**: la moral, el estado del césped (instalaciones), la presión de la prensa y el estadio lleno o vacío cambian el partido y la narración.
- **Historias emergentes**: rivalidades que nacen de resultados, jugadores que piden salir, leyendas del club en el museo (interactuar con trofeos, orden 14).
- FC y PES tienen carreras «planas» desde hace años [C][D]. Aquí está la ventaja más clara.

### 8.2 La Ruta (modo jugador)
- Ya supera en ideas: premios por competición, brazalete por años y media, galas 3D únicas [D].
- Falta: **momentos jugables** (jugar solo tu posición con cámara de jugador, «momentos clave» de 5 minutos para avanzar rápido), relación con el DT y compañeros, vida fuera del club (casa, orden 33), y una progresión probada con la sonda en 3 países.

### 8.3 Justicia con el jugador
- Sin pagos, sin cartas, sin sobres, sin temporizadores. Es un argumento de venta real frente a FC (las críticas a Ultimate Team son constantes [C]). Decirlo en la tienda.

### 8.4 Apertura y modding
- Editor de clubes, jugadores, escudos, uniformes; importar/exportar en JSON; `pack_real.json` local (sin publicarlo).
- PES vivió de los option files; FC está cerrado [C]. Hacerlo **oficial y fácil** convierte la falta de licencias en comunidad.

### 8.5 Accesibilidad, idiomas y equipo modesto
- 9 idiomas, daltonismo, contraste, remapeo [D]; 7 niveles de calidad; corre en Intel UHD [M]. FC exige mucho más hardware en PC [C]. Mercado: Latinoamérica, África, Asia del Sur con equipos modestos.

---

## 9. PROCESO Y TÉCNICA (para que el plan se cumpla)

1. **Recorte de alcance a 1.0**: solo club + partido + La Ruta + 5 ligas completas (ENG, ESP, ITA, ARG, CHI, por ejemplo) + selecciones. Ciudad 3D, minijuegos extra, política profunda: banderas apagadas, después de 1.0.
2. **Congelar el motor del partido** en C4 durante 8 semanas: solo ajustes por banderas, nada de motor nuevo.
3. **Menos sesiones paralelas, más cierre**: 2 sesiones como máximo (partido, y visual/menús), cada una con su veredicto del dueño por bloque.
4. **Probadores externos**: 10-30 personas (amigos, Discord, foros) con un formulario de 5 preguntas y nota 1-100. Cada 2 semanas.
5. **Telemetría local opcional** (con consentimiento, política de privacidad pendiente): duración de partidos, abandonos, menús más usados.
6. **PLAN_GENERAL.md**: separar «histórico» (estados al cierre) en `docs/04_auditorias/historico_plan.md` y dejar el plan en < 400 líneas de pendientes reales.
7. **Mantener** banco, huellas, Sonar y regla de 450 líneas: es la base de la estabilidad.
8. **Build semanal** al dueño (Windows + Android) con notas de cambios en español.

---

## 10. HOJA DE RUTA (4 hitos) [E]

| Hito | Duración | Contenido | Criterio de salida |
|---|---|---|---|
| **H1 «Se juega bien»** | 6-8 semanas | Perfil de manejo (§5.1), animación con mezcla/IK/cabeza (§5.2), contactos y portero, métricas de IA (§5.3) | Nota del dueño ≥ 65/100 en partido; 5 probadores ≥ 60; perfil dentro de tabla |
| **H2 «Se ve como TV»** | 4-6 semanas | Director de TV, paquete gráfico, intro, planos al público, grada reactiva, luces y clima | Vídeo de 3 clubes de 3 países que el dueño confunda «a primera vista» con un juego comercial; FPS ≥ suelo |
| **H3 «Se entiende y engancha»** | 4-6 semanas | Menú central y pantallas completas, tarea del día, La Ruta con momentos jugables, gestión que se nota en la cancha | 3 personas sin ayuda cumplen las 3 tareas en < 30 s; sesiones de juego ≥ 45 min |
| **H4 «1.0 cerrada»** | 4 semanas | Comentarista (fase 1), editor/modding, 5 ligas completas pulidas, caza de fallos, builds | 0 fallos graves conocidos; nota media de probadores ≥ 75/100 |

Total ≈ 5-6 meses de trabajo enfocado. Al final de H2 se **supera a PES 2020 en conjunto** (por gestión + partido 7); al final de H4 se **gana a FC 27 en las filas propias** sin perder por goleada en el partido.

---

## 11. 100 TAREAS PRIORIZADAS

P = prioridad (1 alta). Área: PA partido, AN animación, IA, TV presentación, VI visual, AU audio, ME menús, GE gestión, RU La Ruta, CO contenido, RE rendimiento, PR proceso.

| # | P | Área | Tarea |
|---|---|---|---|
| 1 | 1 | PA | Escena `perfil_manejo` con las 7 métricas de §5.1 |
| 2 | 1 | PA | Latencia de entrada ≤ 2 cuadros (medir y corregir colas de entrada) |
| 3 | 1 | PA | Inercia y aceleración por atributo |
| 4 | 1 | PA | Radio de giro y coste de giro con balón por agilidad/regate |
| 5 | 1 | PA | Anticipación del receptor en el pase al hueco |
| 6 | 1 | PA | Asistencia de pase 0-3 en Ajustes (móvil: asistida) |
| 7 | 1 | PA | Contención defensiva (mantener distancia) + presión del compañero |
| 8 | 1 | PA | Tiro con carga y ventana de precisión; pie débil |
| 9 | 1 | PA | Primer toque según atributo y presión |
| 10 | 1 | PA | Prueba ciega A/B quincenal con voto de diversión |
| 11 | 1 | AN | Blend space 2D de locomoción |
| 12 | 1 | AN | IK de pie al balón en el toque |
| 13 | 1 | AN | Cabeza y mirada al balón (`mira_balon`) |
| 14 | 1 | AN | Cápsulas de cuerpo + empujes en 3 niveles (cierra P4) |
| 15 | 1 | AN | 10-12 animaciones clave de portero |
| 16 | 2 | AN | Inclinación de tronco y giro de cadera |
| 17 | 2 | AN | 6-8 regates legibles con su animación |
| 18 | 2 | AN | Reacciones a falta, caída, lesión |
| 19 | 2 | AN | Celebraciones por personalidad (existen ~25) ligadas al contexto |
| 20 | 2 | AN | LOD de esqueleto para jugadores lejanos |
| 21 | 1 | IA | Banco «estadística de fútbol real» (50 partidos, 10 clubes, 5 países) |
| 22 | 2 | IA | Bloques alto/medio/bajo visibles |
| 23 | 2 | IA | 8 niveles de dificultad por calidad de decisión |
| 24 | 2 | IA | Portero: posicionamiento por ángulo y salidas |
| 25 | 3 | IA | Estilos por club (ya hay formación y estilo reales) que se noten |
| 26 | 1 | TV | Director de cámara por estados |
| 27 | 1 | TV | Planos al público con figuras 3D en el sector |
| 28 | 1 | TV | Repetición con 2 ángulos y contexto |
| 29 | 1 | TV | Paquete gráfico único (marcador, rótulos, alineaciones) |
| 30 | 2 | TV | Intro de partido salteable (exterior → túnel → saludo) |
| 31 | 2 | TV | Plano de banquillo/DT y árbitro con tarjeta |
| 32 | 2 | TV | Estadísticas al descanso y al final con gráficos |
| 33 | 3 | TV | Resumen de 60 s tras el partido |
| 34 | 1 | VI | Arreglar parches claros en camisetas y shorts |
| 35 | 2 | VI | Shader de piel (wrap + sudor por minuto) |
| 36 | 2 | VI | Tela con malla, dorsal y nombre nítidos |
| 37 | 2 | VI | Pelo del Drive con tarjetas y anisotropía |
| 38 | 2 | VI | Tipos de cuerpo por atributos |
| 39 | 2 | VI | Biblioteca pública de 300-500 caras |
| 40 | 2 | VI | Sprites del público horneados desde modelos de calidad |
| 41 | 2 | VI | Carteles y pancartas (atlas por idioma) |
| 42 | 2 | VI | Preajustes de horario y clima |
| 43 | 3 | VI | Césped con desgaste y marcas |
| 44 | 3 | VI | 20-30 estadios icónicos |
| 45 | 3 | VI | Butacas por color del club y nivel (orden 13) |
| 46 | 1 | AU | Grada por capas y reacciones |
| 47 | 2 | AU | Cánticos generados por club |
| 48 | 2 | AU | Sonido del balón por superficie/potencia, red, poste |
| 49 | 2 | AU | Comentario fase 1: 300-500 frases grabadas (español) |
| 50 | 3 | AU | Comentario TTS para nombres (licencia verificada) |
| 51 | 3 | AU | Narración en texto para los otros 8 idiomas |
| 52 | 3 | AU | El dueño escucha y aprueba los sonidos de La Ruta (orden 52) |
| 53 | 1 | ME | Menú central de 4-5 destinos con tarea del día |
| 54 | 1 | ME | Pantallas < 150 ms y transición única |
| 55 | 2 | ME | Mosaico de tarjetas estilo Liga Master |
| 56 | 2 | ME | Tipografía: 2 familias, 4 tamaños |
| 57 | 2 | ME | Navegación completa con mando y táctil |
| 58 | 2 | ME | Prueba de 3 personas, 3 tareas, < 30 s |
| 59 | 3 | ME | Ayuda contextual en la barra inferior |
| 60 | 3 | ME | Fichas de atributos a pantalla completa en todo el juego |
| 61 | 2 | GE | La moral y el estadio lleno/vacío cambian el partido |
| 62 | 2 | GE | Prensa que se refleja en la narración |
| 63 | 2 | GE | Rivalidades emergentes |
| 64 | 2 | GE | Jugadores que piden salir / renovar con historia |
| 65 | 3 | GE | Museo: interactuar con trofeos y planta extra |
| 66 | 3 | GE | Economía de ligas chicas recalibrada (orden 49) |
| 67 | 2 | RU | Momentos jugables de 5 minutos |
| 68 | 2 | RU | Cámara de jugador opcional en el partido |
| 69 | 2 | RU | Relación con DT y compañeros |
| 70 | 2 | RU | Sonda de progresión en 3 clubes de 3 países |
| 71 | 3 | RU | Vida fuera del club (casa) con efecto en el rendimiento |
| 72 | 3 | RU | Galas 3D: lo que falta (`PLAN_GENERAL.md`) |
| 73 | 2 | CO | 5 ligas completas pulidas para 1.0 |
| 74 | 2 | CO | Escudos más parecidos y uniformes base |
| 75 | 3 | CO | Trofeos por club desde el trofeo base |
| 76 | 3 | CO | Eliminatorias de selecciones |
| 77 | 2 | CO | Editor de clubes/jugadores/escudos/uniformes |
| 78 | 2 | CO | Importar/exportar paquetes JSON (modding) |
| 79 | 1 | RE | Suelo de FPS como regla del banco (ULTRA ≥ 38, ULTRA BAJA ≥ 95) |
| 80 | 1 | RE | Medir en el teléfono del dueño (Android) |
| 81 | 2 | RE | Probar `probar_nativo` en Windows real y Android |
| 82 | 2 | RE | Partir `calidad.gd` y `motor_jugable_p5.gd` (> 450 líneas) |
| 83 | 3 | RE | Texturas comprimidas para web móvil |
| 84 | 1 | PR | Recorte de alcance 1.0 por escrito y aprobado por el dueño |
| 85 | 1 | PR | Congelar C4 8 semanas (solo banderas) |
| 86 | 1 | PR | 10-30 probadores externos con formulario |
| 87 | 2 | PR | Máximo 2 sesiones de trabajo a la vez |
| 88 | 2 | PR | Build semanal Windows + Android con notas |
| 89 | 2 | PR | Sacar lo histórico de `PLAN_GENERAL.md` |
| 90 | 2 | PR | Política de privacidad publicada (antes de telemetría) |
| 91 | 3 | PR | Telemetría local opcional |
| 92 | 3 | PR | Página de tienda: «sin pagos, sin cartas, corre en tu PC» |
| 93 | 3 | PR | Tráiler con la cámara real y 3 clubes de 3 países |
| 94 | 3 | PA | Saques rápidos, barrera que se adelanta, ventaja con señal |
| 95 | 3 | PA | VAR estilizado opcional |
| 96 | 3 | PA | Lesiones con camilla y cambios con cartel |
| 97 | 3 | VI | Cámara de vestuario/charla técnica antes del partido |
| 98 | 3 | AU | Música de menú con licencia comercial (lo maneja el dueño) |
| 99 | 3 | ME | Accesibilidad: subtítulos de comentario y avisos sonoros visuales |
| 100 | 3 | CO | Plan de ligas descargables opcionales (idea del 10-11) |

---

## 12. Riesgos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| El partido no llega a «divertido» | Media | Fatal | §5.1 medible + prueba ciega + congelar el motor |
| Rendimiento en móvil peor de lo esperado | Alta | Alto | Medir ya (#80); calidad por defecto la más baja |
| Alcance sigue creciendo | Alta | Alto | Documento de alcance 1.0 (#84) |
| Licencias de recursos mal anotadas | Baja | Alto | Registro de cada recurso con licencia y origen (Frente 1-3) |
| Derecho de imagen | Baja | Alto | Fotos reales solo en `.pck` local (ya resuelto) |
| Desgaste del dueño (tope de uso, muchas sesiones) | Media | Medio | Menos sesiones, bloques cortos, builds semanales |

---

## 13. Qué necesito del dueño (decisiones)

1. ¿Aprueba el **recorte de alcance 1.0** (§9.1) y cuáles 5 ligas?
2. ¿Aprueba **congelar C4** 8 semanas (§9.2)?
3. ¿Busca 10-30 **probadores** o prefiere que se prepare un formulario y un build para que él lo reparta?
4. ¿Acepta **voluntarios para la voz** del comentario (con cesión firmada) o solo TTS?
5. Medición en su **teléfono** con el build actual (5 minutos con `--medir`).
6. Capturas o minuto de vídeo de **FC 27** (planos al público, menús, intro) en `referencias_del_dueño`, para validar las estimaciones [E] de este informe.

---

## 14. Fuentes internas

`docs/PLAN_GENERAL.md` · `docs/04_auditorias/COMPARATIVA_PES2020.md` · `INFORME_SESION_2026-11-15.md` · `MOTOR_LEAGUE_SOCCER_PLAN.md` · `PASO_CPP_PLAN.md` · `AUDITORIA_CONTENIDO_2026-11-10.md` · `MANDO_TACTIL_FC_2026-11-11.md` · `animaciones_gratuitas_2026-11-11.md` · `PRUEBA_DUENO_MOVIL_2026-11-03.md` · `CLAUDE.md` (órdenes 13-57).
