# PLAN DEL LUNES — el único documento de lo pendiente (24-10-2026)

Aquí está TODO lo que falta: lo del dueño, las fases del guion, la ruta de lanzamiento, las mejoras de código, las 356 mejoras abiertas y tus ideas que no están hechas del todo. **Lo ya hecho se borra** (queda en el historial de git). Reglas de trabajo: `CLAUDE.md`; método: `docs/01_metodo/METODO.md`; auditoría con cifras: `docs/04_auditorias/MEGA_AUDITORIA_3.md`.

Cuando algo se termine: se borra de aquí (no se tacha) tras pasar su prueba (banco / especiales / captura con la cámara real).

## 1. Lunes 26-10 — del dueño

- [ ] **Borrar 8 ramas y la etiqueta `latest`** (el clon pesa 1,33 GiB hasta entonces). Con `git clone --single-branch --branch main` ya sale ligero.
  `git push origin --delete ccr-54306f57-jlcywg claude/godot-project-review-o1dvr1 claude/inspiring-allen-8vu29s claude/sweet-turing-tysv99 borrar-ccr-54306f57-jlcywg borrar-claude-godot-project-review-o1dvr1 borrar-claude-inspiring-allen-8vu29s borrar-claude-sweet-turing-tysv99` y `git push origin --delete latest`. La rama `respaldo-historia-2026-10-24` (= `main` antes de reescribir): dejarla 1-2 semanas y borrarla. GitHub conserva `refs/pull/*` con objetos viejos.
- [ ] **Quitar documentos y capturas viejos del historial de `main`**: ya reescrito en la rama de trabajo (530 rutas fuera, 802 → 682 MiB, árbol idéntico); falta empujarlo a `main` (el clasificador de permisos bloqueó el empuje forzado): añadir una regla de Bash o ejecutar tú, desde un clon espejo reescrito, `git push --force-with-lease=main:2f97059740f0b995ddc1b391ea3282eb26e345bd origin main:main`. Las ramas viejas y `respaldo-historia-2026-10-24` conservan todo lo borrado.
- [ ] Probar Foundry/Azure (200 USD, 30 días) y decidir si se usa.
- [ ] Abrir la red a Wikimedia/banderas (necesario para las caras que faltan: ~906 de 2.125 y escudos).
- [ ] CI `compilar.yml`: ruta y preset ya corregidos; falta imagen de Godot **4.7** (la 4.3 no abre el proyecto) y la configuración de exportación.
- [ ] **Perfil de FPS en hardware real** (M-337, P0): PC modesto (Intel UHD) y móvil; aquí solo hay render por software.
- [ ] Builds, keystore, licencias, derechos de imagen, música y voces (🔒). Cambiar la contraseña del keystore (la vieja sigue en el historial). Confirmar la fuente de los modelos 🟡 (Sketchfab, Meshy, mocap de Gumroad, Canva).
- [ ] Subir los binarios pesados (`recursos/`, `marca/`, `material/`) al Drive con `herramientas/drive_subir.ps1` y verificar. Respaldo de texto: `docs/05_referencia/RESPALDO_DRIVE.md`.
- [ ] Decidir: «el bloqueo» (modos que se desbloquean jugando) como opción en Ajustes, «Todo abierto» por defecto.

## 2. El guion: fases 0–6 (reestructuración)

**Calendario por fases** (cada una cierra con banco en 0 fallos + capturas con la cámara real)

| Fase | Contenido | Entregable |
|---|---|---|
| **0 — Cimientos** | colisiones (HECHO), prueba al banco, partir `banco.gd`, pasos 1-3 de 7.1, reloj único y necesidades | juego igual, código más ordenado |
| **1 — Entrada** | intro ≤ 5 s, idioma, menú inicial con fondos por modo y logo diferido, globo corregido, config. obligatoria, entrada al campeonato, personaje | las fases 0-5 como pantallas completas |
| **2 — Prólogo 3D** | aparición fuera del estadio, mentor guía, directivos con oficina, sala de prensa nueva, rueda de prensa con gestos, oficina con PC | de «Nuevo juego» hasta tu primer día |
| **3 — Vida** | casa y familia, jornada y horas extra, días libres, teléfono, citas, eventos de ciudad, transporte público, cárcel | un día completo jugable en 3D |
| **4 — Personas** | directiva, patrocinadores, políticos, entrevistas, fichajes en la ciudad, redes y fotos, elecciones | negociaciones en persona |
| **5 — Club ampliado** | vestuario con nombres, otros deportes, trofeos y celebraciones | |
| **6 — Pulido y auditoría** | pasos 4-7 de 7.1, limpieza del repo, vídeo | cierre y MEGAPLAN siguiente |

Cada fase tiene un documento de estado y se pasa a `main` con un PR cuando lo pidas.

---


### 2.1 El flujo y los sistemas nuevos

#### 3. La nueva estructura del juego (tu guion)

Hay dos formas de leerlo: **el flujo** (qué ve el jugador) y **los sistemas** (qué hay que
construir debajo). Primero el flujo.

#### 3.1 El flujo

| # | Etapa | Qué es | Notas |
|---|---|---|---|
| 0 | **Intro** | Animación de marca de ≤ 5 s antes de nada | pantalla completa, saltable tras la 1.ª vez |
| 1 | **Idioma** (interno: «menú inicial fase 0») | 9 idiomas | el vídeo de The Kion pasa a ser el logo animado |
| 2 | **Menú inicial** (fase 1) | Elegir modo; al pasar el cursor, el fondo cambia al estilo de ese modo | el logo animado aparece arriba a la derecha a los 20 s |
| 3 | **Globo** (fase 2) | Elegir país; nombre completo; fondo con bandera y 5 monumentos que rotan cada 30 s | si creas un club, no se muestran los demás |
| 4 | **Configuración del club** (fase 3) | Obligatoria: casa, FPS, visual, mascota, estilo de instalaciones, densidad de población y todo el submenú de personalización | confirmación al terminar |
| 5 | **Entrada al campeonato** (fase 4) | Reemplazar un club existente, o pagar a la confederación (menos presupuesto, peor reputación) | cifras por decidir (sección 9) |
| 6 | **Personaje** (fase 5) | Aspecto y datos | confirmación |
| 7 | **Prólogo 3D** | Aparece fuera del estadio; el mentor te enseña las instalaciones (todas menos tu oficina) y cómo moverte | es el tutorial de la ciudad |
| 8 | **Conocer a la gente y rueda de prensa** | Directivos con su oficina; sala de prensa nueva; te presentan y preguntan | gestos animados según tus respuestas |
| 9 | **Tu oficina** | PC funcional: ahí está el **menú central** actual; una tecla lo cierra | el juego se puede seguir desde el PC o caminando por el mundo |

Reglas de estructura que pides: cada etapa es **una pantalla propia a pantalla completa**,
con su estética, **no superpuestas**, **obligatorias** y con **confirmación al rellenar**. El
menú central deja de dar acceso a la ciudad (queda el estadio 3D), porque la ciudad pasa a
ser el mundo en el que vives.

#### 3.2 Qué existe ya para cada etapa

| Etapa | Pieza actual | Qué falta |
|---|---|---|
| Intro | nada | animación de marca, sonido, orquestador de arranque |
| Idioma / Inicio | `ui/inicio.gd` (883), portadas rotativas, `FondoParticulas` | separar en pantallas independientes; fondo según el modo bajo el cursor; logo animado diferido |
| Globo | `ui/globo_3d.gd` (425), `ui/mapa_pais.gd` | nombre completo, bandera y monumentos (imágenes libres: la red del entorno bloquea Wikimedia, ver sección 9), ocultar clubes al crear |
| Config. del club | ajustes repartidos en varios menús | una pantalla única y obligatoria |
| Entrada al campeonato | no existe | reglas de presupuesto y reputación, qué pasa con el club reemplazado y su plantilla |
| Personaje | `CreadorPersonaje` (482) | hacerlo etapa obligatoria con confirmación |
| Prólogo + mentor | `RecorridoClub`, `PersonalEstadio`, tutorial de la ciudad | guion del recorrido guiado físicamente |
| Rueda de prensa | `RuedaPrensaEscena3D` (897) ya es 3D | sala física en el estadio, gestos según lo que diga el jugador |
| Oficina + PC | `Principal` (el menú central) | objeto 3D que lo abre/cierra, aislarlo en una clase propia |

#### 3.3 Los sistemas nuevos (lo más grande)

| Sistema | Qué incluye | Depende de |
|---|---|---|
| **Reloj y agenda únicos** | un solo tiempo para menú central y mundo 3D; jornada laboral, horas extra, días libres, adelantar el día con el teléfono, esperar | base de todo lo demás |
| **Necesidades** | comer y dormir; si fallan, aumentan las posibilidades de que las cosas salgan mal | reloj |
| **Casa y familia** | dormir en casa, hablar con la familia, vida personal | reloj, necesidades |
| **Personas en persona** | directivos con oficina, jugadores, patrocinadores, políticos y funcionarios (ficticios), agentes, entrevistas de contratación en 3D, citas en la ciudad para fichar | reloj, diálogos |
| **Misiones y mensajes** | llegan por el PC o por el móvil; algunas exigen ir a un lugar de la ciudad | reloj |
| **Negociaciones** | en tu oficina, por mensaje o en 3D (mejor resultado en 3D) | personas |
| **Eventos de ciudad** | transporte público si el coche se avería, noche en la cárcel, llamar gente a tu oficina, incitarte a salir si juegas mucho desde el PC | reloj, ciudad |
| **Vestuario** | nombre de cada jugador en su taquilla y en la camiseta; futbolistas presentes a veces | datos de plantilla |
| **Otros deportes del club** | subequipos como personas reales: exigencias, celebraciones de título en el estadio, trofeo en la sala de trofeos | datos, estadio |
| **Redes y elecciones** | fotos con el teléfono y subirlas, interacciones, elecciones del club, convocar rueda de prensa | modo foto existente |

> **Reglas del proyecto que se mantienen:** política ficticia; no atribuir religión ni
> romances a jugadores reales; datos reales solo en `pack_real.json`.

---


### 2.2 Fase 0 real: separar `Principal` (validado por el dueño)

#### 7. Código menos delicado (cómo se hace y cómo se comprueba)

#### 7.1 Partir `principal.gd` sin romperlo
Método «estrangulador»: cada paso mueve un grupo de funciones a su propia clase, **sin
cambiar su comportamiento**, y el banco entero debe seguir en 0 fallos.

| Paso | Se extrae | Va a | Riesgo |
|---|---|---|---|
| 1 | `_conectar_noticias` (548 líneas) y titulares | `ui/menu/noticias_menu.gd` | bajo: es una conexión de señales |
| 2 | Ajustes: tipografía, idioma, FPS, música, acento, ranuras | `ui/pantallas/pantalla_ajustes.gd` (ya existe, absorbe) | medio |
| 3 | Estilos de menú, píldoras, rotación de estética cada 10 min | `ui/menu/estilos_menu.gd` | bajo |
| 4 | Elegir club (mapa, países, escudos) | pasa a ser la **fase 2** del nuevo menú inicial | se rehace de todos modos |
| 5 | Hubs contextuales y carril de chips | `ui/menu/hubs.gd` | medio |
| 6 | Estadio, finanzas, identidad, camarín (`_pintar_*`) | `ui/pantallas/*` (ya hay una por tema) | medio |
| 7 | Lo que queda: **`MenuCentral`**, la cáscara que abre el PC de la oficina | `ui/menu_central.gd` | alto: depende de 1-6 |

Meta: `Principal` pasa de 6.867 a < 1.500 líneas y las 157 variables de miembro se reparten
por clases. Cada paso es un commit pequeño con su banco.

#### 7.2 Contratos y aislamiento
- **Un contrato por pantalla:** `abrir(contexto)`, `cerrar()` y una señal; nada de que una
  pantalla lea las variables de otra.
- **Estado de partida único** (`Mundo` + `Partida`): las pantallas leen, no guardan copias.
- **Validar al entrar:** datos de guardado con esquema y versión; migraciones explícitas
  (importante cuando cambie la estructura, sección 9).
- **Guardias de nodos liberados:** el estrés de menús del 17-10 encontró 3 errores de este
  tipo; se generaliza el patrón (`is_instance_valid`) en las pantallas nuevas.
- **Cierre ordenado y autoguardado** antes de cada transición larga (intro → inicio →
  prólogo → oficina) para que un fallo no pierda la partida.

#### 7.3 Pruebas
- Añadir `prueba_colisiones_club` y las del nuevo flujo a grupos de `mini_banco.sh`.
- Partir `pruebas/banco.gd` (9.561 líneas) en un archivo por grupo (`partido`, `guardado`,
  `ciudad`, `estadio`, `gestion`, `competicion`, `textos`).
- Una prueba de **arranque completo** (intro → idioma → fases 1-5 → prólogo) con atajo de
  desarrollo para saltar etapas, para que el banco no se haga lento.

---


### 2.3 Fase 4: cifras validadas (entrar al campeonato)

#### 9.1 Propuesta para la fase 4 (entrar al campeonato) — cifras VALIDADAS por el dueño el 24-10
Sea B el presupuesto inicial que tendría un club de esa división.

| | **Reemplazar un club existente** | **Pagar a la confederación (club extra)** |
|---|---|---|
| Coste | ninguno | cuota de afiliación = 25 % de B, al contado |
| Presupuesto de partida | B | 0,75 × B |
| Reputación inicial | la del club reemplazado − 10 puntos («recién llegado») | la de un club recién creado − 20 puntos («compró su plaza») |
| División | la del club reemplazado | siempre la más baja (la liga pasa a tener un club más; calendario con descansos si queda impar) |
| Confianza de la directiva | 60 | 40 |
| Ánimo de la afición | normal | −15 el primer mes; se recupera en ~1 temporada con buenos resultados |
| El otro club | desaparece de la liga; sus jugadores quedan libres (puedes ficharlos) y su afición se reparte | no se toca |
| Prensa | «Nace un club sobre las cenizas de X» | «Un club compra su plaza»; preguntas duras en la primera rueda de prensa |

Efecto buscado: reemplazar es barato pero tiene coste moral y de plantilla; pagar es limpio con el resto de
la liga pero empiezas peor. Los dos son recuperables, ninguno es un castigo definitivo.


### 2.4 Pendientes del traspaso anterior

De `PENDIENTES.md` (traspaso al 21-10):
- **Fusionar a `main`**: lo hecho el 19-21-10 en la rama `ccr-54306f57-jlcywg` (PR #10 ya
  fusionado según el historial). Nada de la rama actual está en `main` aún.
- **Carrera de Jugador**: agenda semanal (M-263), dificultad de la CPU en ese modo (¡con
  cuidado!), más eventos.
- **Partido**: roles por jugador (PlayStyles), más desmarques de ruptura, cartel del 4.º
  árbitro con corte de cámara, red del arco.
- **Gente del club y ciudad en primeras filas** (M-040) y mejor variedad (M-033).
- **Rendimiento**: saber qué pone 1,34 M de triángulos en pantalla; texturas sin comprimir
  (3.103); oclusión en más zonas; medir FPS en hardware real (🔒 dueño).
- **Hallazgos del vídeo de gameplay del 21-10**: pocas ocasiones a ritmo normal, de noche
  calzada negra y conos de luz triangulares, malabares muy básico.
- **Ciudad**: pilares de puente y rotondas con el kit de carreteras; sustituir calzadas
  (decisión consciente de no hacerlo por riesgo con semáforos).
- **Estadios por fuera**: tribunas «falsas», patrocinadores reales y más escudos.
- **Peatones**: atropello sin daño ni reacción; subir al autobús y tomar coches del tráfico
  (dijiste «no por ahora»; con el nuevo guion del transporte público vuelve a tener sentido).
- **Esperando al dueño (🔒)**: builds, keystore, licencias, derechos de imagen, música y voces.


## 3. Ruta de lanzamiento (semanas 2–9 del plan de ruta)

Marca «verificar» lo que la memoria del proyecto dice haber hecho en parte (táctica en vivo, porteros, ceremonia, repeticiones): comprobar con el motor real antes de dejarlo o borrarlo.

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


### Qué falta para un juego lanzable


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


También abiertos del ROADMAP: juegos mentales en el túnel antes de salir a la cancha (B4); medir FPS en el PC modesto.


### Detectados en pruebas y aún sin cerrar

- **Roles por jugador** (como los PlayStyles de FC 26) con efecto en el motor.
- **Red del arco**: onda más ancha y lenta (17-10), techo sin asomar por el larguero. **Cartel del cuarto árbitro**: 20-10 a tamaño real (0,92 × 0,62 m), dígitos con halo, mango y por encima de la cabeza. Desde la toma abierta de TV sigue siendo pequeño (como en la tele de verdad, que corta a un primer plano): pendiente un corte de cámara al cartel.
- Faltas por puntos (vídeo del 20-10): agarrón 1,4 · por detrás 3,0 · empujón 1,7 · a gran velocidad 2,0 · deslizante 2,6 · falta profesional 2,3 · de pie 1,2 · carga de hombro 0,9 · agresiva 2,4; falta ≥ 1,0, amarilla ≥ 4,0, roja ≥ 7,0 (comprobar si `_probar_faltas_puntos` lo cubre entero).
- Roles por jugador (como los PlayStyles de FC 26) con efecto en el motor; desmarques de ruptura; peatones: atropello con reacción, subir al autobús y tomar coches del tráfico.
- Pocas ocasiones a ritmo normal; de noche calzada negra y conos de luz; malabares muy básico (verificar tras los arreglos del 21-10).

## 4. Mejoras de código

- [ ] 143 funciones de más de 100 líneas (21 de más de 200). Las mayores: `Principal._construir` 403, `Sonido._sintetizar_g1/g2` ~384, `Banco._probar_tanda_c_1` 382, `Mundo.avanzar_semana_1` 379, `Principal._conectar_noticias_1` 376, `Prensa.resolver_1` 372, `StadiumBuilder.build_1` 365. Partir por responsabilidad, no por tamaño.
- [ ] Capas `_pN` (233 archivos): repartir por responsabilidad real hasta que la herencia en cadena ya no haga falta (`docs/05_referencia/indice_de_capas.md`).
- [ ] `ui/principal.gd`: de objeto gigante en 19 capas a clases con interfaz mínima (ver 2.2).
- [ ] Texturas: 3.103 sin comprimir; comprimir en VRAM `caras_reales_*` y `assets/characters`; bajar a 2048 las 23 de ≥ 2048 px (T_Peasant_*, tierra 4k); 38 duplicados exactos (reapuntar `.import`). Medir antes/después en Forward+.
- [ ] 60 `_process`: revisar los que sondean y pasar a señales; oclusión en más zonas de la ciudad.
- [ ] 53 escenas de prueba sin ninguna mención: decidir cuáles se borran; 27 módulos de `visor/` y 8 de `nucleo/` sin prueba directa.
- [ ] 37 TODO y 2 XXX; 16 `print` de depuración (dejarlos solo tras bandera).
- [ ] `pruebas/estres_menus.tscn` no termina en headless (¿ya pasaba antes?).
- [ ] Colisiones de la ciudad fuera del club (peatones, mobiliario, edificios): revisar como en `ColisionClub`.
- [ ] 506 frases visibles sin traducir en 8 idiomas (`docs/05_referencia/textos_sin_traducir.txt`); la prueba de paridad debe exigir 0.
- [ ] Pruebas visuales automáticas (comparación de imágenes) en vez de capturas manuales; `MotorLibre` es prototipo (el juego usa `MotorJugable`).
- [ ] C++/GDExtension solo si el perfil en hardware real lo pide.
- [ ] Guardado: copias automáticas y aviso si se corrompe; versión con migración; topes de memoria en historiales (M-399/M-400).

## 5. Mejoras abiertas del catálogo (356)

Prioridad P0–P3 · estado · qué falta. Reverificar la fila antes de construir (algunas pueden estar ya hechas: el TOP anterior tenía hechos sin marcar).


### F0 cimientos (33)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-403 | P1 | PARCIAL | 8 módulos de `nucleo/` sin referencia en pruebas:… | Logros y Negociación cubiertos de forma indirecta (`_probar_logros`, `_probar_negociacion`); los otros 6 no |
| M-404 | P1 | PENDIENTE | 27 módulos de `visor/` sin referencia: `Ambience`, `Autopista`,… | solo `CameraRig` aparece en el banco |
| M-405 | P1 | PENDIENTE | Pruebas visuales manuales (242 capturas) | sin comparación de imágenes |
| M-379 | P2 | PENDIENTE | 64 funciones > 120 líneas (Q-01): `Sonido._sintetizar` 1.000,… | funciones largas sin partir |
| M-380 | P2 | PENDIENTE | `pruebas/banco.gd` 8.029 líneas | `banco.gd` con 8.454 líneas |
| M-382 | P2 | PENDIENTE | Sin análisis estático | sin gdlint |
| M-383 | P2 | PENDIENTE | Tipado: muchos `Dictionary` sin forma (jugadores del motor) | sin `JugadorMotor` tipado |
| M-384 | P2 | PENDIENTE | `Mundo` 2.921 líneas, `Roles` 2.065, `Prensa` 2.541: acoplamiento alto | sin extraer servicios |
| M-385 | P2 | PENDIENTE | Autoloads con globals (`Datos`, `Sonido`…) | sin documentar autoloads |
| M-386 | P2 | PARCIAL | Señales sin desconexión en liberación (posibles fugas) | `auditoria_tecnica.gd` mide huérfanos en la pantalla principal; 21-10: el panel de objetivos pasa a señal (`vista_cambiada`) y respaldo cada 3 s, sin fallar con las pestañas prestadas a un menú |
| M-387 | P2 | PENDIENTE | Mensajes de error silenciosos (`return` sin aviso) | sin registro de errores |
| M-388 | P2 | PENDIENTE | Constantes mágicas (balance) dispersas | sin archivo de balance |
| M-391 | P2 | PENDIENTE | Duplicación entre `MatchPlayback` y `MotorJugable` | duplicación sin retirar |
| M-392 | P2 | PENDIENTE | `MotorLibre` prototipo (546 líneas) sin uso claro | `MotorLibre` sigue (545 líneas); 20-10: con la base ficticia da 12,5 goles de media entre iguales (su prueba fija ahora la base real para no depender del orden) |
| M-393 | P2 | PENDIENTE | Código de pruebas mezclado con herramientas (`herramientas/*.ps1`) | sin separar |
| M-394 | P2 | PENDIENTE | Herramientas `.exe`/`.cs` binarias en repo | `herramientas/*.exe` siguen en el repo |
| M-396 | P2 | PENDIENTE | Convenciones: mezcla de español/inglés en nombres | sin guía de estilo |
| M-397 | P2 | PENDIENTE | Comentarios muy extensos (valioso pero ruidoso) | sin ADRs |
| M-398 | P2 | PENDIENTE | Sin documentación de arquitectura actualizada (`LEEME.md`) | LEEME sin diagrama |
| M-399 | P2 | SIN VERIFICAR | Versión de guardado (`VERSION`) con migración mínima | no se revisaron migraciones |
| M-400 | P2 | SIN VERIFICAR | Sin límites de memoria en historiales (noticias, prensa) | no se revisaron topes de historiales |
| M-401 | P2 | PENDIENTE | Dependencia de nombres de nodo (`find_child`) frágil | sin cambio |
| M-402 | P2 | PENDIENTE | Duplicación de carga de JSON (`Datos` 212 tablas) | sin carga perezosa |
| M-406 | P2 | PENDIENTE | `Retrato3D` no se ejercita en headless | sin prueba con xvfb |
| M-407 | P2 | PENDIENTE | Sin pruebas de conducción/ciudad (V-06) | sin prueba de conducción |
| M-408 | P2 | PARCIAL | Sin pruebas de minijuegos 3D | `prueba_minijuegos_nuevos` (2D); minijuegos 3D sin prueba |
| M-409 | P2 | PARCIAL | Sin pruebas de menús/UI de integración (abrir cada pantalla sin error) | `_probar_carga_de_ui` en el banco; sin recorrido por pestañas |
| M-410 | P2 | PENDIENTE | Sin pruebas de rendimiento con umbrales | sin umbrales de rendimiento |
| M-413 | P2 | PENDIENTE | `auditoria_clubes`/`auditoria_datos` no están en el banco | auditorías fuera del banco |
| M-414 | P2 | PENDIENTE | Resultados de sondas (calidad/táctica/simetría) sin umbrales | sondas sin umbrales |
| M-416 | P2 | PENDIENTE | Sin CI en GitHub Actions | sin GitHub Actions |
| M-417 | P2 | PENDIENTE | `herramientas/banco.sh` sólo bash | sin unificar |
| M-418 | P2 | PENDIENTE | Sin informes de cobertura | sin cobertura |

### F1 entrada al juego (36)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-277 | P1 | PARCIAL | 274 textos en español directamente en `ui/` (I-02), concentrados… | ✅ 15-10: 1.132 textos envueltos; quedan ~15 (M-447) |
| M-278 | P1 | PENDIENTE | `ui/principal.gd` 6.655 líneas (y 3 funciones >330) | `principal.gd` con 6.777 líneas |
| M-279 | P1 | PENDIENTE | 27 módulos de `visor/` y 8 de `nucleo/` sin referencia directa en… | los módulos siguen sin prueba directa |
| M-280 | P1 | PENDIENTE | 105 módulos de UI/visor sin referencia en banco/pruebas | sin prueba visual automática |
| M-433 | P1 | PARCIAL | Controles táctiles sólo en la ciudad (cruceta/E) | 21-10: en PC ya no salen la cruceta ni «Salir» al pasear (estadio y ciudad) y la E solo aparece si hay algo con lo que interactuar (`ExploradorCiudad.es_tactil`); el partido sigue sin controles táctil |
| M-283 | P2 | PENDIENTE | Sin subtítulos/indicadores visuales de sonido | sin avisos visuales de sonido |
| M-284 | P2 | PENDIENTE | Sin modo lectura de pantalla (TTS) | sin TTS |
| M-285 | P2 | PARCIAL | Navegación por mando en menús (panel de controles sí) | navegación con mando en el panel de controles; no en todos los menús |
| M-287 | P2 | PENDIENTE | Rendimiento de menús: refresco ya 14× más rápido; sin pruebas de… | sin medida de apertura de pantallas |
| M-289 | P2 | PENDIENTE | Menú lateral con 9 menús; Ciudad/Editar completados; Ajustes sólo… | Ajustes sigue con 3 tarjetas (`MenuLateral`) |
| M-290 | P2 | PARCIAL | Tarjetas con dato vivo sólo en algunas (`Menu.dato`) | `MenuLateral.dato` existe; no todas las tarjetas |
| M-292 | P2 | PARCIAL | Sin favoritos/marcadores de jugadores o clubes | favoritos de pestañas; sin seguimiento de jugadores/clubes |
| M-293 | P2 | PARCIAL | Tablas con filtros limitados (plantel) | filtros en plantel/libres |
| M-294 | P2 | PARCIAL | Comparador de jugadores existe; sin comparativa de club/estadio | comparador de jugadores; sin club/estadio |
| M-295 | P2 | SIN VERIFICAR | Sin gráficos históricos (valor, forma) en ficha | «crecimiento por temporada» en la ficha; sin gráficos verificados |
| M-296 | P2 | PARCIAL | Notificaciones (`Aviso`) sin centro de notificaciones | bandeja de correo; sin filtros |
| M-297 | P2 | PENDIENTE | Tutorial: ciudad y controles; falta tutorial de gestión (primer mes) | sin tutorial de gestión |
| M-299 | P2 | PARCIAL | Sin confirmaciones consistentes para acciones destructivas… | `CuadroDialogo` en despacho/principal; no uniforme en vender/despedir |
| M-300 | P2 | PENDIENTE | Sin deshacer en acciones de pizarra | sin deshacer en pizarra |
| M-302 | P2 | PENDIENTE | Sin tema claro/alto contraste | sin tema claro/alto contraste |
| M-303 | P2 | PARCIAL | Cursor/hover sin feedback sonoro consistente en todos los… | `BotonFx` en todos los botones; pestañas/listas sin sonido |
| M-304 | P2 | PARCIAL | Animaciones de transición entre pantallas desiguales | `Animar` en 16 archivos; sin sistema común de transición |
| M-305 | P2 | PARCIAL | Tooltips escasos | 103 tooltips |
| M-307 | P2 | PENDIENTE | Resoluciones: pensado 1280×720–1600×900; sin pruebas en 4:3, 21:9… | sin capturas por aspecto |
| M-308 | P2 | PENDIENTE | DPI alto: texto del `Label3D` en 3D no escala | `pixel_size` fijo |
| M-310 | P2 | PENDIENTE | Sin pantalla «Novedades» tras actualizar | sin «Novedades» |
| M-311 | P2 | PARCIAL | Sin perfil de jugador (estadísticas globales) | `PanelMeta` (álbum/museo global); sin perfil de estadísticas |
| M-312 | P2 | PARCIAL | Sin modo «streamer» (ocultar datos sensibles/real) | ajuste «Caras reales: FOTO / RECREACIÓN» (`Cara.usar_fotos`); sin modo streamer |
| M-435 | P2 | PENDIENTE | Sin gatillos analógicos para potencia de pase | sin gatillos analógicos |
| M-436 | P2 | PENDIENTE | Sin giroscopio para cámara en primera persona (móvil) | sin giroscopio |
| M-437 | P2 | PARCIAL | Sin detección de dispositivo para cambiar iconos en tiempo real… | `dispositivo_detectado` en panel de controles y `ControlFC`; guía del partido sin comprobar |
| M-438 | P2 | PENDIENTE | UI de móvil: botones pequeños | sin tamaño mínimo |
| M-439 | P2 | PENDIENTE | Orientación vertical no soportada | sin vertical |
| M-440 | P2 | PENDIENTE | Sin modo una mano | sin modo una mano |
| M-441 | P2 | PENDIENTE | Sin soporte de teclado en pantalla para nombres | sin teclado en pantalla |
| M-442 | P2 | PENDIENTE | Mando: botones reasignables guardados pero sin perfiles múltiples | sin perfiles de mando |

### F3 vida en 3D (42)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-167 | P1 | PENDIENTE | Calzadas = cajas de asfalto con marcas propias; Kenney sólo… | calzadas propias; losetas Kenney no usadas |
| M-171 | P1 | PARCIAL | Tráfico sin comportamiento complejo (adelantar, ceder en cruce) | cola y frenado en rojo (`TraficoCiudad`); sin adelantar |
| M-263 | P1 | PENDIENTE | Eventos únicos (13) y control real; pocos días de «vida» entre… | sin agenda semanal |
| M-168 | P2 | PENDIENTE | Sin rotondas | sin rotondas |
| M-170 | P2 | PENDIENTE | Sin semáforos peatonales con botón | sin botón peatonal |
| M-173 | P2 | PARCIAL | Sin sonido de motor/marchas/derrape | 21-10: el motor del coche suena, sintetizado en vivo con revoluciones y 5 marchas (`visor/motor_coche_sonido.gd`); sin radio |
| M-174 | P2 | PARCIAL | Interior de coche sin modelo (salpicadero 2D) | salpicadero y volante 2D (`VolanteUI`) |
| M-176 | P2 | PENDIENTE | Sin tipos de vehículo (moto, bus conducible, camión) | solo coche conducible |
| M-177 | P2 | PENDIENTE | Sin gasolinera/aparcamiento/lavado | sin gasolinera/lavado |
| M-180 | P2 | PARCIAL | Metro: sin vendedores/música/anuncios | anuncios en el vagón (`MetroCiudad.ANUNCIOS`); sin vendedores ni música |
| M-182 | P2 | PENDIENTE | Sin tarjeta de transporte ni coste | máquinas de billetes decorativas; sin coste |
| M-183 | P2 | PARCIAL | Peatones: 34 máx; sin rutinas por hora | 21-10: de madrugada queda en la calle un tercio de la gente (los ocultos tampoco se mueven: `TraficoCiudad.faros`); faltan rutinas por persona |
| M-184 | P2 | PENDIENTE | Sin NPC con nombre y memoria (te reconocen) | sin vecinos con memoria |
| M-185 | P2 | PENDIENTE | Diálogos por oficio (hecho) pero sin ramas ni consecuencias | diálogos sin consecuencias |
| M-186 | P2 | PARCIAL | Interiores: 15 salas; edificios entrables «la mayoría» sin… | gimnasio, piscina, estación central, recreativos con muebles Kenney (15/16-10); 21-10: edificio del club con muebles de verdad del catálogo común `Modulos` (oficina del DT, despacho, sala de vídeo, pr |
| M-187 | P2 | PARCIAL | Casas sin habitantes ni rutinas | vivienda con «la familia que vive allí» (`InteriorInstalacion` l.1057); sin horarios |
| M-188 | P2 | PENDIENTE | Sin tiendas con compra real (ropa, balones) | sin compra en tiendas |
| M-189 | P2 | PENDIENTE | Sin bares/restaurantes con minijuego | sin bar con minijuego |
| M-190 | P2 | PARCIAL | Sin clima dinámico en la ciudad (lluvia con charcos, reflejos) | charcos de luz de farola (`CiudadExpansion`); sin charcos de lluvia en la ciudad |
| M-191 | P2 | PARCIAL | Sin ciclo día/noche más allá del slider | ciclo día/noche automático (`_ciclo_activo`); sin reloj real |
| M-192 | P2 | SIN VERIFICAR | Aceras/pavimentos: 3 texturas | no se midió la variedad de aceras por barrio |
| M-193 | P2 | PARCIAL | Sin vegetación variada (setos, flores) más allá de árboles | setos de jardines y casas (`CiudadExpansion._setos_t`); sin flores |
| M-196 | P2 | PENDIENTE | Botes sin sonido/estela | sin estela de botes |
| M-197 | P2 | PENDIENTE | Autopista sin peajes ni estaciones | sin peajes |
| M-198 | P2 | PENDIENTE | Aeropuerto/estación de tren inexistentes (no hay viajes) | sin viajes/aeropuerto |
| M-199 | P2 | PENDIENTE | Sin señales de tráfico reales (límites, ceda) | sin límites de velocidad con multa |
| M-200 | P2 | PENDIENTE | Sin policía/multas | sin policía |
| M-201 | P2 | PENDIENTE | Sin accidentes/eventos aleatorios | sin eventos de calle |
| M-203 | P2 | PENDIENTE | Sin colisión/oclusión de sonido en interiores | sin filtro de sonido en interiores |
| M-204 | P2 | PENDIENTE | LOD de edificios lejanos con ventanas (cristal) pero sin siluetas… | sin impostores de edificios |
| M-205 | P2 | PENDIENTE | `ciudad_expansion.gd` 2.321 líneas y `city_builder.gd` 4.687 | `ciudad_expansion.gd` creció a 3.569 líneas |
| M-206 | P2 | PENDIENTE | Sin editor de ciudad más allá de terrenos/negocios | sin editor de ciudad |
| M-265 | P2 | PENDIENTE | Avatar propio sin personalización de cuerpo | sin personalización del cuerpo |
| M-266 | P2 | PARCIAL | Sin entrenador como NPC con diálogos sobre el jugador | `relacion_dt` decide minutos; sin entrenador con diálogos |
| M-267 | P2 | PENDIENTE | Transferencias vistas desde el jugador: ofertas sin negociación… | la Carrera no usa `MesaAgente` |
| M-268 | P2 | PARCIAL | Selección nacional: convocatorias sin escena | convocatoria como evento; sin cinemática |
| M-269 | P2 | PENDIENTE | Lesiones del jugador: sin recuperación jugable (fisio) | sin rehabilitación jugable |
| M-270 | P2 | PENDIENTE | Retiro con paso a DT ok; sin homenaje | sin homenaje de retiro |
| M-271 | P2 | PENDIENTE | Sin contratos de imagen propios | sin contratos de imagen |
| M-272 | P2 | PENDIENTE | Fuera de juego, cambios, selección ✅; sin protestas/tarjetas del… | sin expediente disciplinario |
| M-273 | P2 | PENDIENTE | Rivales NPC por `Fama`; sin rivalidades nominales | sin rival de posición |
| M-276 | P2 | SIN VERIFICAR | Pruebas: modo cubierto en `prueba_modos`; faltan casos extremos… | no se comprobaron los casos extremos en `prueba_modos` |

### F4 personas (56)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-207 | P1 | PENDIENTE | Plantillas de 25 en todos los clubes (C-05) | plantillas de 25 |
| M-208 | P1 | PARCIAL | Caja del club propio crece de forma casi monótona (prueba larga:… | 20-10: el mantenimiento de instalaciones (M-227) es un coste que crece con el club; faltan crisis |
| M-210 | P1 | PARCIAL | Mercado: precios por reputación sin burbujas ni crisis | eras con precios (`Eras`, `_probar_eras_y_precios`); sin burbujas |
| M-219 | P1 | PARCIAL | `Banco` e `Insolvencia` existen pero con pocos eventos de gravedad | administrador, tope salarial, venta de lo que sobra, refundación (`Insolvencia`); sin descenso administrativo |
| M-235 | P1 | PARCIAL | Lesiones: duración y recaídas ok; sin prevención visible (carga… | carga y riesgo en `Medico` (l.244-254); indicador por jugador sin confirmar |
| M-241 | P1 | PENDIENTE | Prensa 2.541 líneas (la mayor del núcleo): `resolver` 476 líneas | `Prensa.resolver` sigue en una función |
| M-359 | P1 | PENDIENTE | Estadio real en 46 % de clubes (C-01) | 46 % |
| M-209 | P2 | PARCIAL | La prueba larga sólo comprueba que no hay errores, no el equilibrio | `prueba_larga` comprueba medias en rango; sin métricas de equilibrio |
| M-211 | P2 | PARCIAL | Cláusulas de rescisión: sin «cláusulazo» automático de IA | el mercado reconoce pagos de cláusula (`Mercado` l.345); sin «clausulazo» de IA deliberado |
| M-213 | P2 | PARCIAL | Sin agentes con personalidad reflejada en comisiones (hay 4 perfiles) | perfiles de agente (`MesaAgente.PERFIL`); sin historial |
| M-214 | P2 | PENDIENTE | Cesiones con opción de compra obligatoria sin seguimiento de… | cesiones sin bonus por partidos |
| M-216 | P2 | SIN VERIFICAR | Fichajes de IA entre clubes poco visibles | no se comprobó la noticia semanal de traspasos de IA |
| M-217 | P2 | PENDIENTE | Sin fichajes libres por fin de contrato anticipados (precontrato) | sin precontratos |
| M-218 | P2 | PARCIAL | Sin límite de fair play financiero explícito (hay aviso) | tope salarial con administrador (`Insolvencia`); sin ratio salarial general |
| M-220 | P2 | PARCIAL | Sin intereses variables según reputación y mercado | préstamos con tasas por tipo (`Banco`); no dinámicas |
| M-221 | P2 | SIN VERIFICAR | Impuestos y derechos de TV simplificados | derechos de TV con multiplicador; no se comprobó el reparto por país |
| M-222 | P2 | PARCIAL | Venta de entradas: precio único | precio único por partido; sin sectores ni precio por rival |
| M-223 | P2 | PARCIAL | Abonos/socios: modelo simple | socios por temporada (`Reputacion`) y campaña de abonos (`Hinchada`); sin lista de espera |
| M-225 | P2 | PENDIENTE | `Comercial` zonas de patrocinio manual para el usuario; IA sin… | sin noticias de contratos comerciales de IA |
| M-229 | P2 | PENDIENTE | Academia: sin variedad de métodos pedagógicos | sin planes pedagógicos |
| M-230 | P2 | PARCIAL | Cantera 1.422 líneas con representantes; pocos hitos narrativos | `EventosCantera`: torneo, dejarlo, padres, convocatoria; sin lesión/mudanza |
| M-231 | P2 | PARCIAL | Ojeadores con sesgo regional (ya) sin informes visuales (campo vs… | ojeadores con personalidad que infla/recorta informes (`Ojeadores`); sin informe visual |
| M-232 | P2 | PENDIENTE | Staff de 6 puestos sin personalidad ni relaciones entre sí | staff sin química |
| M-233 | P2 | PENDIENTE | Entrenamiento 1.117 líneas; sesiones sin visualización 3D | sin escenas de entrenamiento |
| M-234 | P2 | PENDIENTE | Maestrías con efecto en partido poco visible | maestrías sin registro en el resumen |
| M-236 | P2 | PENDIENTE | Vestuario 1.436 líneas con grupos; sin conflictos con… | sin discusiones visibles en partido |
| M-239 | P2 | PARCIAL | Junta/accionistas: sin asambleas jugables | asamblea en insolvencia/federación; no jugable |
| M-243 | P2 | PARCIAL | Redes sociales: seguidores y comentarios; sin bots/trolls/tendencias | tendencias y hashtags (`Redes.tendencia`); sin trolls |
| M-244 | P2 | PENDIENTE | Sin entrevistas en TV con escena 3D variada (existe rueda de… | un solo set de rueda de prensa |
| M-245 | P2 | PARCIAL | Federación 999 líneas con reglas; votaciones sin presentación | votaciones con señales (`Federacion`); pantalla de sesión sin comprobar |
| M-248 | P2 | PARCIAL | Mundial de clubes/selecciones (1.012 líneas) con pocos modos | convocatorias con efecto en el físico (`Selecciones`); sin concentraciones |
| M-249 | P2 | PARCIAL | Hinchada con segmentos; sin rivalidades por barrio | clásico con incidentes (`Prensa`); sin rivalidades por barrio |
| M-250 | P2 | PENDIENTE | Ciudad y club: terrenos/negocios; economía simplificada | negocios sin depender de la ocupación |
| M-251 | P2 | PENDIENTE | Gente del club (10 personas) sin crecimiento de relaciones | gente del club sin afinidad |
| M-252 | P2 | PARCIAL | Trabajadores/instalaciones con eventos; sin huelgas/negociación | huelga de hinchas y por sueldos impagos (`Prensa`); sin negociación laboral |
| M-253 | P2 | PENDIENTE | Licencia de entrenador: exámenes; sin cursos con coste y tiempo | licencia sin cursos |
| M-254 | P2 | PARCIAL | Vida del DT (bienestar, casa, familia): sin impacto en rendimiento… | estrés en `VidaDT`; efecto en rendimiento sin comprobar |
| M-257 | P2 | PENDIENTE | Historia del club generada; sin línea de tiempo interactiva | sin línea de tiempo |
| M-258 | P2 | PENDIENTE | Documental de temporada: guion fijo | documental con guion fijo |
| M-259 | P2 | PARCIAL | Clima en partidos con efecto menor | el clima reduce las llegadas (`Partido.clima`); sin efecto en balón ni desgaste |
| M-260 | P2 | PENDIENTE | Dificultad: 3 niveles simples | sin dificultad adaptativa |
| M-261 | P2 | PENDIENTE | Sin modo historia/campaña guiada | sin modo historia |
| M-361 | P2 | SIN VERIFICAR | `tablas.json` en una línea (D-04) | no se revisó `tablas.json` |
| M-362 | P2 | PENDIENTE | `ESTADIO_CLUB` por nombre (frágil con leetspeak) | `ESTADIO_CLUB` por nombre |
| M-363 | P2 | PENDIENTE | Mapa ficticio→real (`CLUBES` en `base_ficticia.py`) sin prueba de… | sin prueba de cobertura |
| M-364 | P2 | PENDIENTE | Países: 23 con 16 clubes (Chile 32) | sin ligas nuevas |
| M-367 | P2 | PENDIENTE | Calendario con feriados (`Calendario` 350 líneas); sin zonas horarias | sin zonas horarias |
| M-368 | P2 | PENDIENTE | Jugadores históricos/leyendas sin mecánica de «cromo» | leyendas sin cromo |
| M-369 | P2 | PENDIENTE | Nombres de estadios ficticios sin apodos amplios (`GuinosEstadio`) | `GuinosEstadio` sin ampliar |
| M-370 | P2 | PENDIENTE | Historia de clubes (`historia_clubes.py`) por club; verificación… | sin prueba de coherencia |
| M-371 | P2 | PENDIENTE | Himnos y cánticos sin letra | himnos sin letra |
| M-372 | P2 | PENDIENTE | Retratos de DT/presidente generados; sin variedad étnica medida | sin estadística por país |
| M-373 | P2 | PENDIENTE | Bandera de cada país como pieza; verificar que son las correctas y… | sin prueba visual de banderas |
| M-376 | P2 | PENDIENTE | Premios individuales sin votación explicada | sin votación explicada |
| M-377 | P2 | PARCIAL | Sin clima por país/estación realista | `Clima.del_partido` por país/estación; sin tabla completa verificada |
| M-378 | P2 | PENDIENTE | Sin datos de ciudades (población, altura) para estadios | sin datos de ciudades |

### F5 club ampliado / pulido (26)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-003 | P1 | PENDIENTE | Las formas no varían de forma continua | `RETRANQUEO_BANDEJA` sigue siendo constante; sin parámetros por club |
| M-004 | P1 | PENDIENTE | El «estadio real» sólo copia forma/niveles/techo/pista/focos/fachada | `ESTADIOS` de `herramientas/estadios_reales.py` sin color de pista/vallas, año ni pantalla |
| M-005 | P1 | PENDIENTE | Colores propios de butacas en 47 de 176 estadios reales | `ASIENTOS` sigue con 47 de 176 estadios |
| M-014 | P1 | PARCIAL | Sin diferencia día/noche en el aspecto de la iluminación… | 21-10: el haz de cada farola de la ciudad es un cono volumétrico falso con degradado y sin contorno (`visor/cono_farola.gdshader`); sin haces de los focos del estadio |
| M-017 | P1 | PENDIENTE | Túnel de vestuario sólo en +Z | túnel fijo en la tribuna +Z (`tunel_x`) |
| M-007 | P2 | PENDIENTE | Sin variación de entorno por país (palmeras, nieve, montaña de fondo) | sin fondo lejano por país/clima en el estadio |
| M-009 | P2 | PARCIAL | Sin voladizo/cubierta visible en estadios sin techo | techo «visera» y cerchas vistas desde fuera (`FachadaEstadio`); sin visera parcial con estructura por sector |
| M-010 | P2 | PENDIENTE | Sin carteles de pared (patrocinadores, fechas, escudo) fuera del campo | sin carteles en muros exteriores (la fachada tiene rótulos de puerta, no publicidad) |
| M-012 | P2 | PENDIENTE | Vallas LED con la misma rotación de marcas inventadas (30) | `VallasLed` sin catálogo ampliado; `Auspicio` tiene 38 marcas |
| M-013 | P2 | PARCIAL | Banderas de esquina/córner genéricas | banderines con tela y color del asiento del estadio (`_corners`); sin banderola del país ni viento |
| M-015 | P2 | PENDIENTE | El césped usa 12 dibujos, asignación por hash | el dibujo de césped sigue por hash (`Club._CESPED`); no hay campo en estadios reales |
| M-016 | P2 | PENDIENTE | Sin campo de entrenamiento/calentamiento visible fuera del estadio | sin campo anexo con calentamiento |
| M-018 | P2 | PENDIENTE | Banquillos de un solo diseño por preset | `EST_BANQUILLOS` sin ampliar |
| M-019 | P2 | PARCIAL | Sin zona de prensa/cabinas de TV visibles en el graderío | cabina de prensa en `estadio_extras.gd`; sin vidrio ni NPC de prensa dentro |
| M-020 | P2 | PARCIAL | Sin palcos reales (`palcos` existe como instalación) | palcos como pieza de `estadio_extras.gd` y `ClubDentro.PALCO`; sin interior con personas |
| M-022 | P2 | PENDIENTE | Sin sonido espacial por sector (cantos locales vs visitantes) | no existe ningún `AudioStreamPlayer3D` en el juego |
| M-024 | P2 | PARCIAL | Sombras de la grada sobre el campo no cambian con la hora real del… | `Ambience` usa la hora elegida para el estadio, no la hora/estación real del partido |
| M-025 | P2 | PARCIAL | Poca variedad de torres de luz (4 esquinas) | focos «corona/mixto/halo» además de torres; no 6/8 torres por forma |
| M-027 | P2 | PENDIENTE | Sin variación de terreno exterior (cerro, mar, río) según `rasgo` | el texto `rasgo` no elige fondo ni niebla |
| M-028 | P2 | PARCIAL | El estadio propio y el rival usan caminos de construcción… | `pruebas/captura_mismo_estadio.gd` (manual); no está en el banco |
| M-029 | P2 | PARCIAL | Ampliaciones del estadio propio sin animación de obra detallada | andamios, grúa torre y vallado (`estadio_extras.gd`, `EstadioPropio.obra`); sin polvo ni operarios |
| M-031 | P2 | PENDIENTE | Sin mapa de estadios (galería) para ver todos los del juego | sin pantalla «Estadios del mundo» |
| M-032 | P2 | PARCIAL | Sin ficha de estadio con datos reales (capacidad oficial, año,… | aforo OFICIAL en la ficha (`ui/estadio.gd:544`); faltan año y superficie |
| M-023 | P3 | PARCIAL | Sin clima visible en el estadio más allá de lluvia/niebla (nieve,… | nieve, lluvia y niebla (`Precipitacion`, `Clima`); sin calima/polvo ni charcos que reflejan |
| M-026 | P3 | PARCIAL | Estadios sin nombre dibujado en fachada | rótulos en las puertas de la fachada; sin nombre grande del estadio por tipografía de club |
| M-030 | P3 | PENDIENTE | Sin estadio nacional/selección con identidad propia | sin sedes de selección con arquitectura propia |

### F6 pulido (82)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-035 | P1 | PARCIAL | Sin bufandas/banderas/camisetas del club en la mano | banda de bufandas y tifo en grada (`StadiumBuilder` «bufandas»/«tifo»); sin mallas en la mano |
| M-054 | P1 | PENDIENTE | Ropa con volumen sólo en retratos (K-02) | `VestidorQ.ropa_aparte` sigue apagado en partido por coste |
| M-055 | P1 | PARCIAL | Sin arrugas dinámicas según animación | pliegues de tela estáticos (`pliegues()` en el shader); no dependen de la animación |
| M-058 | P1 | PARCIAL | 30 marcas de patrocinio (K-03) | 38 marcas en `Auspicio` (antes 30); meta 70 |
| M-063 | P1 | PENDIENTE | Escudos reales sólo 26 (7 %) | `ESCUDOS` sigue con 26 clubes |
| M-068 | P1 | PENDIENTE | Diseño de camiseta por hash en el 63 % de clubes (ya hay tabla… | `CAMISETAS` con 63 clubes |
| M-079 | P1 | PENDIENTE | Retrato real 13 % (base real) | 13 % con retrato real; descarga bloqueada por la red |
| M-091 | P1 | PARCIAL | Botines: variedad añadida, pero sin modelos distintos por forma | `VestidorQ._botin_de` varía modelo/color por dorsal; no hay mallas de bota alta/calcetín |
| M-094 | P1 | PARCIAL | Animación de caminata del DT: 6 estilos (✅) | «Mi caminata» con 6 estilos para el DT; peatones y jugadores no |
| M-095 | P1 | PENDIENTE | 335 clips; muchos sin uso en partido | sin auditoría automática de clips usados |
| M-447 | P1 | PARCIAL | Las cadenas en español escritas directo en `ui/` (I-02): antes 573… | ✅ 15-10 salvo 15 textos |
| M-037 | P2 | PENDIENTE | Sin sector «barra brava»/torcida con comportamiento diferente (de… | sin sector ultra con bengalas/humo |
| M-038 | P2 | PENDIENTE | Hinchas sentados con piernas invisibles (se cortan en la cadera) | público horneado cortado en la cadera |
| M-039 | P2 | PARCIAL | Tres niveles de detalle; el salto «cerca→medio→lejos» puede verse | detalle por distancia por tramos de grada (16-10, 2,24→1,72 M tris); sin mezcla por dithering |
| M-041 | P2 | PENDIENTE | Sin niños, familias ni asistentes en sillas de ruedas | sin niños/familias/sillas de ruedas en grada |
| M-042 | P2 | PARCIAL | Ocupación = reputación, no asistencia del partido | ocupación = asistencia de `Finanzas` (depende del precio); no por sector |
| M-043 | P2 | PENDIENTE | Sin diferencia de público por competición (final vs liga) | sin decoración especial en finales |
| M-044 | P2 | PARCIAL | Gol local: ceremonia de público única | 20-10: además del confeti/bengalas, onda de saltos desde ese fondo, la ola con el partido decidido y la protesta; falta variar por sector |
| M-048 | P2 | PARCIAL | Fotógrafos/camarógrafos pocos y repetidos | `visor/camarografos_siguen.gd` (giran con el balón, uno camina); siguen siendo pocos |
| M-056 | P2 | PENDIENTE | Sin sudor/barro/lluvia en la camiseta | sin uniform de barro/mojado |
| M-060 | P2 | PENDIENTE | Patrocinio fijo por club entre temporadas, sin contratos de IA que… | sin renovación/cambio de patrocinador de clubes IA |
| M-061 | P2 | PENDIENTE | Sin patrocinador en la parte trasera del pantalón ni en las medias | sin zonas `short_trasero`/`medias` |
| M-064 | P2 | PENDIENTE | Falta ornamento reconocible (león, águila, estrella, castillo,… | sin biblioteca de símbolos (solo el almenado) |
| M-065 | P2 | PENDIENTE | Texto/iniciales ilegibles <24 px | sin prueba de legibilidad a 24 px |
| M-066 | P2 | PENDIENTE | Escudo sin variante monocroma (para periódico, marcador) | sin `Escudo.mono` |
| M-067 | P2 | PENDIENTE | Sin escudo animado en el marcador al gol | sin pulso del escudo en el marcador |
| M-069 | P2 | PENDIENTE | 12 diseños con reparto casi uniforme (C-06) | sin pesos en el reparto de diseños |
| M-070 | P2 | PENDIENTE | Sin segunda/tercera camiseta con diseño propio | sin tercera equipación |
| M-071 | P2 | PENDIENTE | Portero: color por contraste, sin diseño | portero solo por contraste; guantes como color de accesorio |
| M-074 | P2 | PENDIENTE | Medias/pantalón: diseño correcto pero sin franjas del fabricante | sin franjas del fabricante en medias/pantalón |
| M-075 | P2 | PENDIENTE | Dorsal sin fuente propia por club | dorsal en siete segmentos, una sola fuente |
| M-077 | P2 | PENDIENTE | Retrato con camiseta de volumen pero sin patrocinio en pecho visible | encuadre del retrato sin cambiar |
| M-078 | P2 | PARCIAL | Foto real de equipación sólo con pack real (C-08) | 2D y 3D con cuello/costuras desde el 14/17-10; diferencia con foto real sigue |
| M-080 | P2 | PENDIENTE | Fotos agachadas aún oscuras/deformadas | fotos agachadas sin re-detección (límite anotado en MOTOR_CARAS.md) |
| M-082 | P2 | PENDIENTE | Altura sólo por escala global | sin proporciones variables |
| M-083 | P2 | PARCIAL | Sin tatuajes/cicatrices por jugador salvo civiles | tatuaje solo en ropa civil (`equipacion_q.gdshader` `tatuaje`); no en jugadores |
| M-084 | P2 | PENDIENTE | Biblioteca de caras = 72 mezclas | biblioteca de 72 caras |
| M-085 | P2 | PARCIAL | Envejecimiento visual de jugadores (canas, arrugas) no ligado a `edad` | 21-10: canas desde los 32 en los inventados (`Cara.look_de`, a uno de cada cuatro casi nada); los reales llevan el color de su foto; arrugas pendientes |
| M-086 | P2 | PENDIENTE | Expresiones faciales limitadas a `Expresion` básica | `Expresion` sin emociones nuevas |
| M-087 | P2 | PARCIAL | Sin parpadeo/respiración idle variados | parpadeo en el DT/`Expresion`; sin respiración idle en jugadores |
| M-089 | P2 | PENDIENTE | Barbas/cejas por capas apagadas (manchas) | barba/cejas por capas siguen apagadas |
| M-090 | P2 | PENDIENTE | Guantes de portero sólo color | sin geometría de guante |
| M-092 | P2 | PENDIENTE | Cordones/tacos sin geometría | sin relieve de cordones/tacos |
| M-093 | P2 | PENDIENTE | Sin canilleras/vendas/cintas visibles | sin canilleras/vendas en partido |
| M-096 | P2 | PENDIENTE | Transiciones entre clips con mezcla fija 0,25 s | mezcla fija entre clips |
| M-097 | P2 | PARCIAL | Retarget con pies que patinan | IK de piernas solo en la ciudad (`AnimQuaternius._ik_pierna`); sin foot locking en partido |
| M-099 | P2 | PARCIAL | Cuerpos sin colisión entre brazos/piernas (solapes sólo en XZ) | cuerpos que se empujan y duelos en el motor (`MotorJugable._cuerpos`, 17-10), en 2D; sin cápsulas 3D |
| M-101 | P2 | PARCIAL | Celebraciones por rasgo (ya) pero sólo 2/3 propias | carrera al córner y abrazo (`_ia_celebracion`); sin 10 por rasgo ni coreografías |
| M-102 | P2 | PARCIAL | Sin reacciones de banquillo coordinadas | celebra el gol (`_banca_celebra`); 21-10: protesta la roja de uno de los suyos (`_banca_protesta`); falta la lesión |
| M-103 | P2 | PARCIAL | Lesiones sin animación específica | clip de dolor (`AnimQuaternius`); sin camilla ni médicos en campo |
| M-108 | P2 | SIN VERIFICAR | Mascotas con animación limitada | `MascotaQ` tiene animaciones propias; no se comprobó si son 6 ni si hay rutas |
| M-109 | P2 | PARCIAL | Niños de ceremonia con una misma malla | niños con cuerpos de peatones variados (`CeremoniaPartido`); sin comprobar variedad de malla |
| M-110 | P2 | PENDIENTE | Sin voces/murmullos de jugadores | sin voces de jugadores |
| M-112 | P2 | PENDIENTE | Sin avatar del usuario en el estadio como jugador (carrera) con su… | la Carrera de Jugador no usa el cuerpo del creador |
| M-444 | P2 | PENDIENTE | Fuga de texturas GL al cerrar `prueba_carrera_flujo` | fuga de texturas sin arreglar (INFORME_INTERNO H-12) |
| M-445 | P2 | PENDIENTE | Pruebas que no caben en 5 min con render por software (`intro`,… | sin modo rápido del arnés (H-13) |
| M-448 | P2 | PENDIENTE | `auditoria_clubes` tarda ~8 min y `auditoria_datos` ~1 min | sin muestra |
| M-449 | P2 | PENDIENTE | Los informes (`AUDITORIA_CLUBES.csv`) se regeneran a mano | sin CI nocturno |
| M-450 | P2 | PENDIENTE | `pruebas/prueba_*` no tienen un índice de «qué cubre cada una» | sin índice de pruebas |
| M-451 | P2 | PENDIENTE | Duplicación del arnés (`_ok`, `_fallos`) en decenas de pruebas | sin `PruebaBase` |
| M-452 | P2 | PENDIENTE | Salida de pruebas sin código de retorno uniforme (algunas… | varias pruebas acaban con `quit()` sin código |
| M-453 | P2 | PENDIENTE | Pruebas ligadas al azar sin semilla fija en algunos casos (la IA… | sin semillas fijas generalizadas |
| M-454 | P2 | PENDIENTE | Capturas que cambian el estado de la máquina (ajustes de… | sin restaurar |
| M-455 | P2 | PENDIENTE | Pruebas que escriben en `user://ajustes.cfg` real (E-10) | sin ruta inyectable |
| M-456 | P2 | PENDIENTE | `auditoria_tecnica` solo carga las escenas de `escenas/` y `ui/` (4) | sin cambio |
| M-457 | P2 | PENDIENTE | Los nodos huérfanos se miden solo en la pantalla principal | sin cambio |
| M-458 | P2 | PENDIENTE | Sin comprobación de que cada `Label` traducible esté dentro de un… | sin cambio |
| M-459 | P2 | PENDIENTE | Cinco idiomas de los nueve nacieron con frases que luego se… | sin flujo único |
| M-460 | P2 | PENDIENTE | Las traducciones nuevas (552) están hechas a mano sin revisión nativa | sin marcar |
| M-461 | P2 | PENDIENTE | Las cadenas con `%s`/`%d` dependen del orden de argumentos; en… | sin placeholders con nombre |
| M-462 | P2 | PENDIENTE | Etiquetas de botón con emoji/caracteres (💾 ↺ ● ✔ ▸ ◯) pueden no… | sin prueba de glifos |
| M-463 | P2 | PENDIENTE | `Idiomas.t` devuelve la clave si falta (silencioso) | sin registro de clave faltante |
| M-464 | P2 | PENDIENTE | No existe un informe de «frases por pantalla»: no se sabe qué… | sin informe por pantalla |
| M-466 | P2 | PENDIENTE | `datos/idiomas_extra.json` se reescribe entero con cada ampliación… | un solo archivo |
| M-467 | P2 | PENDIENTE | Falta un chequeo de longitud de texto (alemán/finés largo) en botones | sin chequeo de longitud |
| M-468 | P2 | PENDIENTE | Plurales y géneros en las 69 frases nuevas (p. ej. «%d botones»)… | sin plurales |
| M-470 | P2 | PENDIENTE | El banco no ejecuta `auditoria_tecnica`, `auditoria_datos` ni las… | banco sin auditorías |
| M-046 | P3 | PENDIENTE | Sin multitudes en accesos, tienda y museo del estadio | sin flujo de NPC antes/después del partido |
| M-076 | P3 | PENDIENTE | Sin parches de competición (campeón, copa) | sin parches de competición |
| M-111 | P3 | PENDIENTE | Sin modo foto con poses y expresión (existe `ModoFoto`) | `ModoFoto` sin poses ni editor de expresión |
| M-465 | P3 | PENDIENTE | Sin pruebas de rendimiento de la carga de idiomas (`idiomas.gd`… | sin carga perezosa |
| M-469 | P3 | PENDIENTE | Falta documentación del flujo de pruebas para colaboradores | sin sección en LEEME |

### F6 pulido (motor) (31)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-119 | P1 | PARCIAL | Penales: el portero «decide una vez» pero sin lectura del lanzador | 20-10: en la TANDA el portero de la IA se tira más al lado natural del pie del lanzador (46/36/18) y, según sus reflejos (4-16 %), lee la carrera (`_lado_portero_tanda`); falta en los penales del part |
| M-147 | P1 | PARCIAL | Hitbox del balón vs cuerpo: 0 casos atravesando (sonda); pero… | balón con altura y cabezazo en el motor; colisión por distancia, sin cápsulas |
| M-120 | P2 | PARCIAL | Córners con 3 variantes | receptor/2.º/3.er lanzador en córners (14-10); sin jugadas ensayadas de `CatalogoJugadas` |
| M-121 | P2 | PARCIAL | Tiros libres: barrera simple | barrera de 4 a 9,15 m fija |
| M-122 | P2 | PARCIAL | Sin saque de banda largo/estratégico | saque de banda largo del usuario (X); sin atributo |
| M-125 | P2 | PENDIENTE | Sin tácticas de medio campo (doble pivote, falso 9) | sin roles con comportamiento propio |
| M-126 | P2 | PARCIAL | Cambios de IA por cansancio (60/70/80') fijos | DT rival cambia en 60/70/80' y ajusta la pizarra según marcador (`_dt_rival`); minutos fijos |
| M-128 | P2 | PARCIAL | Portero con salidas sólo en mano a mano | colocación y achique del portero (14-10); sin salidas aéreas |
| M-129 | P2 | PARCIAL | Sin lanzamientos de larga distancia ni centros desde banda con… | los atributos pesan en el motor (`_atributos`); sin parámetro de precisión por tipo de envío |
| M-131 | P2 | PARCIAL | Ayudas de asistencia (pase/tiro) con 3 niveles | ayudas por pieza (asistido/manual, auto/semi/manual) en `Mando`; sin perfiles Arcade/Semi/Manual |
| M-134 | P2 | PARCIAL | Sin cámaras de repetición cinematográficas (grúa, dron) | cámaras «Dron orbital» y otras en el rig; la repetición no alterna planos |
| M-135 | P2 | PENDIENTE | Sin cámara de gol del cuarto árbitro/línea | sin cámara de línea de gol |
| M-140 | P2 | PENDIENTE | Descanso: charla de medio tiempo con opciones; sin vestuario 3D… | el descanso vuelve al camarín 2D (`prueba_descanso_3d`); sin cinemática de vestuario |
| M-142 | P2 | SIN VERIFICAR | Rueda de prensa posterior no enlazada con incidentes del partido | no se encontró tema de árbitro/VAR en `Prensa.resolver` |
| M-143 | P2 | PENDIENTE | Sin clima dinámico durante el partido (tormenta repentina) | sin cambio de clima en vivo |
| M-144 | P2 | PARCIAL | Campo se desgasta (barro) sin visualización | desgaste fijo en áreas y punto de penal (`cesped.gdshader`); no evoluciona |
| M-145 | P2 | PENDIENTE | Sin marcas de césped (pisadas, deslizamientos) | sin marcas de pisadas |
| M-146 | P2 | PENDIENTE | Balón con skins pero sin desgaste/mojado | balón sin desgaste/mojado |
| M-148 | P2 | PARCIAL | Sin rebotes contra postes/larguero realistas con física propia | poste y larguero detectados en el motor; rebote sin comprobar |
| M-150 | P2 | PENDIENTE | Sin balones adicionales (calentamiento, reserva) | sin balones decorativos |
| M-152 | P2 | PENDIENTE | Sin modo de entrenamiento libre (probar controles) | sin entrenamiento libre |
| M-153 | P2 | PENDIENTE | Sin modo multijugador local | sin multijugador local |
| M-155 | P2 | PARCIAL | Penal de usuario con barra, sin variantes por pierna | el zurdo usa clips en espejo; penal del usuario sin variante por pierna |
| M-156 | P2 | PENDIENTE | Sin decisión de capitán (protesta) | sin protesta del capitán |
| M-157 | P2 | PENDIENTE | Sin cantos/anuncios del estadio (megafonía con alineaciones) | sin megafonía |
| M-159 | P2 | PARCIAL | Sin himno por país con partitura procedural | un motivo genérico «himno» sintetizado; no por país |
| M-161 | P2 | PENDIENTE | Sin mini-partidos de selección con identidad | sin identidad de selección en el 3D |
| M-163 | P2 | PARCIAL | Sin modo «Director técnico automático» configurable (IA del usuario) | `MotorJugable.autopiloto`; sin perfil configurable |
| M-164 | P2 | PENDIENTE | Sin modo espectador con cámara libre | sin cámara libre en la UI |
| M-154 | P3 | PENDIENTE | Sin online | fuera de alcance, sin documentar |
| M-166 | P3 | PENDIENTE | Sin partidos de fútbol sala/playa/mujeres (género existe) | fuera de alcance, sin documentar |

### F6 pulido (rendimiento) (17)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-338 | P1 | PARCIAL | Partido ALTO ≈ 2,3 M tris/700 llamadas | partido ALTO 0,76 M tris / 630 llamadas (17-10); sin presupuesto por categoría escrito |
| M-339 | P1 | PENDIENTE | Césped en capas ≈ 230 k tris/57 llamadas | capas del césped hasta 46 m sin LOD extra |
| M-343 | P2 | PARCIAL | Draw calls 700 | sombras en 8 mallas por sector (741→691) y 630 llamadas; sin atlas |
| M-344 | P2 | PARCIAL | Overdraw en grada por butacas y personas | 21-10: oclusión en la CIUDAD (`OclusoresCiudad`, 1.120 paredes): −16 % de llamadas a pie de calle (12.128 → 10.192 en 4 calles, `medir_oclusion`); en la grada del estadio sigue sin `OccluderInstance3D |
| M-345 | P2 | PENDIENTE | Culling por trozos para MultiMesh grandes | sin culling por trozos de MultiMesh |
| M-346 | P2 | PARCIAL | Texturas con compresión (s3tc en PC); sin variantes móviles… | 21-10: revisado: las texturas grandes de 3D ya están en VRAM (s3tc) y limitadas (ropa 4K → 1024); las 3.103 sin comprimir son caras reales, iconos 2D y paletas de Kenney, que se dejan sin pérdida a pr |
| M-347 | P2 | PARCIAL | VRAM 539 MB en partido | texturas del globo comprimidas (72→13 MB); VRAM del partido sin remedir |
| M-348 | P2 | PENDIENTE | Carga: `Precarga` existe; primera construcción de estadio larga | sin caché en disco de mallas generadas |
| M-349 | P2 | PENDIENTE | Generación de `Mundo` (384 clubes) y `Reales.aplicar`: medir… | sin `WorkerThreadPool` |
| M-350 | P2 | PENDIENTE | `avanzar_semana` 532 líneas: tiempo por semana desconocido | sin perfil por semana |
| M-351 | P2 | PENDIENTE | Hilos: ¿se usan para IA/ciudad? | sin hilos para tráfico/peatones (solo LOD del tráfico) |
| M-352 | P2 | PENDIENTE | GC/alloc en `_process` (Dictionary por jugador) | sin Packed arrays en el motor |
| M-353 | P2 | PENDIENTE | Valorar C#/GDExtension sólo si el motor domina CPU | sin medición previa |
| M-354 | P2 | PARCIAL | `RendimientoAdaptativo` existe; documentar umbrales y probarlos | `pruebas/probar_rendimiento_adaptativo.gd`; no está en el banco |
| M-355 | P2 | PARCIAL | Sin modo batería/60→30 FPS en móvil | límite de FPS 30/60/120 (`Principal.FPS_OPCIONES`); sin modo batería |
| M-356 | P2 | PENDIENTE | Memoria de la ciudad ×4 (2.640 m) | sin streaming por celdas |
| M-357 | P2 | PARCIAL | Capturas pesadas en repo (`pruebas/capturas`) | `.gitignore` de promo/lotes y JPG por defecto; resto en repo |

### F6 pulido (traducciones) (6)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-328 | P2 | PENDIENTE | Patrones numéricos (`patrones` 58) con plurales simples | sin reglas de plural por idioma |
| M-329 | P2 | PARCIAL | Sin género gramatical (entrenadora/jugadora) en todos los idiomas | `Genero` solo en español |
| M-330 | P2 | PENDIENTE | Formatos de fecha/número por idioma | sin `Idiomas.fecha/numero` |
| M-332 | P2 | PENDIENTE | Narración traducida (`narracion.json`) sin revisión nativa | sin revisión nativa |
| M-333 | P2 | PARCIAL | Texto en imágenes (carteles del 3D) sin traducir | textos de `visor/` envueltos en `Idiomas.t` (15-10); carteles dibujados sin comprobar |
| M-334 | P2 | PENDIENTE | Sin RTL (árabe, hebreo) aunque hay KSA/EGY/MAR | sin RTL |

### dueño (27)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-337 | P0 | 🔒 DUEÑO | No hay perfil en hardware real (R-01) | perfil en hardware real |
| M-341 | P1 | 🔒 DUEÑO | Sombras: 4 cortes en ALTO; sin ahorro medible al bajar (probado),… | coste de sombras en GPU real |
| M-419 | P1 | 🔒 DUEÑO | `.git` 5,5 GB con punteros LFS antiguos (D-03) | historial/LFS: decisión del dueño |
| M-420 | P1 | PENDIENTE | Builds públicos sin datos reales (caras, fotos): comprobar con… | sin prueba del .pck |
| M-421 | P1 | 🔒 DUEÑO | Derechos de imagen de jugadores reales (decisión del dueño) | derechos de imagen |
| M-313 | P2 | PENDIENTE | `Sonido._sintetizar` 1.000 líneas: efectos sintetizados sin editor | `_sintetizar` sigue monolítica |
| M-314 | P2 | PENDIENTE | Sin mezcla dinámica (ducking de música en diálogo/gol) | sin ducking |
| M-315 | P2 | PARCIAL | Música (`Musica` 384 líneas, procedural): sin variaciones por mood… | `Musica` con capas por estado |
| M-316 | P2 | PARCIAL | Cantos de hinchada genéricos | cánticos sintetizados; sin sincronía con el juego |
| M-317 | P2 | 🔒 DUEÑO | Sin comentarista | narración por voz = audios (decisión del dueño; COMPARACION_JUEGOS_2) |
| M-318 | P2 | PENDIENTE | Sin sonidos de pisadas por superficie en partido | sin pisadas |
| M-319 | P2 | PARCIAL | Sin eco/reverb en túnel/vestuario/estadio | sonido «eco_estadio»; sin reverb por zona |
| M-320 | P2 | PENDIENTE | Sonido del balón (patada) sin variación por tipo/potencia | sin variantes de patada por potencia |
| M-321 | P2 | PENDIENTE | Volúmenes por bus sin perfil «noche»/audífonos | sin presets de volumen |
| M-322 | P2 | PENDIENTE | Sin audio espacial en la ciudad (fuentes 3D) | sin audio espacial (0 `AudioStreamPlayer3D`) |
| M-324 | P2 | PENDIENTE | Sin prueba que detecte clipping/silencios | sin prueba de clipping |
| M-422 | P2 | PENDIENTE | 8 presets de exportación; sin pruebas de compilación | sin CI de exportación |
| M-423 | P2 | 🔒 DUEÑO | Android: keystore del dueño (regla) | keystore |
| M-424 | P2 | PARCIAL | Licencias de terceros (Kenney CC0, Quaternius, Anderson Rohr):… | `LICENCIAS.md` con los kits Kenney (15-10); sin auditoría automática |
| M-425 | P2 | PENDIENTE | Créditos de fotos (`creditos_fotos.txt`) sólo para el pack real | créditos de fotos sin pantalla |
| M-426 | P2 | PENDIENTE | Archivos grandes sueltos (`.glb` >5 MB) | sin compresión de GLB grandes |
| M-427 | P2 | PARCIAL | `pruebas/capturas` crece sin control | carpetas promo/lotes ignoradas; capturas siguen en el repo |
| M-428 | P2 | 🔒 DUEÑO | `.zip` de terceros dentro de `recursos/` (punteros LFS) | archivos de terceros con LFS: decisión del dueño |
| M-429 | P2 | PENDIENTE | Versionado del juego sin número visible | sin versión visible |
| M-430 | P2 | PENDIENTE | Sin canal de reporte de errores | sin reporte de errores |
| M-432 | P2 | PENDIENTE | Sin política de contenido (religión/política ficticia) | sin lista en CI |
| M-323 | P3 | 🔒 DUEÑO | Sin música licenciada (decisión del dueño) | música licenciada: decisión del dueño |

## 6. Tus ideas 1–350: lo que NO está hecho del todo

De las 350, **124 se dieron por hechas y comprobadas** (hay implementación y una prueba del banco que la toca) y se borraron. Criterio honesto: una prueba automática no mide si está *bien* hecha a tu nivel de exigencia; si alguna borrada no te convence, dilo y vuelve a esta lista. Abajo: lo abierto.


### Pendientes (no se encontró nada) (43)


**3. Personalización visual**
- 39. Colecciones especiales (edición aniversario, homenaje)
- 40. Personalización del logo del club en redes sociales
- 42. Personalización del himno/cántico del club
- 45. Diseño de banderines y merchandising

**9. Economía y Finanzas**
- 118. Fondo de emergencia del club
- 120. Bonos e incentivos fiscales por inversión en cantera

**10. Auspicios y Marketing**
- 125. Sponsor de entrenamiento
- 130. Colaboraciones con marcas para ediciones limitadas
- 131. Sponsors regionales vs. internacionales
- 133. Sponsors "sorpresa" que ofrecen tratos únicos
- 135. Ferias/eventos de marca para aumentar reputación

**11. Fans y Comunidad**
- 144. Fan zone fuera del estadio en días de partido
- 145. Programa de fidelización de hinchas

**13. Medios y Prensa**
- 162. Ranking de prensa sobre mejores DTs/presidentes
- 164. Reportajes especiales sobre la cantera

**15. Premios y Reconocimientos**
- 177. Mejor arquero del año
- 179. Mejor presidente/dueño del año
- 183. Premio al club más popular

**17. Rivalidades y Clásicos**
- 204. Eventos especiales previos al clásico
- 206. Fichajes polémicos entre rivales
- 208. Comparación de logros con el rival histórico

**18. Legado e Historia del Club**
- 211. Línea de tiempo histórica del club
- 219. Leyendas como mentores de la cantera

**20. Extras y Sistemas Meta**
- 231. Modo historia con objetivos guiados
- 234. Guardado de partida en la nube
- 238. Comparación con otros jugadores (si hay online)
- 240. Modo "carrera rápida" para partidas cortas
- 250. Modo multijugador asíncrono (comparar ligas entre amigos)

**21. Detalles de Ambientación**
- 257. Impacto económico del club en la ciudad ficticia

**22. Sistemas de Jugadores (detalle extra)**
- 269. Patrocinios personales de jugadores (compite con el club)

**23. Eventos de Crisis y Oportunidad**
- 272. Boom económico repentino de un sponsor
- 275. Oferta de fusión con otro club (dilema)
- 279. Presión por bajar precios de entradas

**24. Progresión y Metas**
- 283. Ranking histórico de mejores gestiones (leaderboard interno)

**25. Toques Finales de Personalización**
- 294. Personalización del bus del equipo

**27. Récords, Historia y Memoria del Club**
- 318. Línea de tiempo navegable de temporadas anteriores
- 324. Historial de presidentes/DTs anteriores y su legado

**28. Sala de Trofeos y Celebraciones**
- 332. Exhibición temporal de un trofeo destacado en el estadio
- 333. Ceremonia de entrega de camiseta homenaje en aniversarios
- 334. Muro de campeones con fotos de planteles ganadores

**29. Más Ideas Adicionales**
- 345. Resumen de prensa internacional si el club gana notoriedad
- 348. Eventos climáticos que afectan la asistencia y el ánimo del público
- 349. Modo "reconstrucción": heredar un club en crisis y sanearlo

### Parciales (existe una parte) (82)


**1. Infraestructura y Estadio**
- 15. Accesos para hinchada visitante (afecta seguridad/incidentes)

**3. Personalización visual**
- 34. Diseñador de camiseta de arquero
- 41. Personalización de la mascota del club
- 43. Personalización de la bandera del club
- 44. Personalización de uniforme del cuerpo técnico

**4. Personaje (DT / Presidente / Dueño)**
- 50. Frases/estilo de comunicación personalizable
- 51. Relaciones personales con jugadores clave
- 52. Rivalidad personal con otro DT/presidente

**5. Plantilla y Jugadores**
- 66. Cláusulas de bonos por objetivos
- 67. Elección de número de camiseta
- 68. Jugadores "ícono" con historia especial

**6. Cantera y Formación Juvenil**
- 71. Categorías juveniles (sub-15, sub-17, sub-20)
- 73. Academias asociadas en otras ciudades/países
- 80. Historial de canteranos que llegaron a ser estrellas

**7. Fichajes y Negociación**
- 85. Fichajes sorpresa (oportunidades limitadas en el tiempo)
- 90. Traspasos con jugador + dinero incluido

**8. Cuerpo Técnico y Staff**
- 101. Personal de relaciones públicas

**9. Economía y Finanzas**
- 114. Recortes de gastos en momentos de crisis

**10. Auspicios y Marketing**
- 127. Sponsors temáticos con personalidad propia
- 128. Renovación o pérdida de sponsors según resultados
- 129. Campañas publicitarias especiales
- 132. Penalizaciones por incumplir contrato de sponsor

**11. Fans y Comunidad**
- 142. Cánticos personalizados de la hinchada

**12. Redes Sociales**
- 147. Publicaciones oficiales del club que puedes redactar
- 149. Trolls y críticos recurrentes en redes
- 152. Crisis de imagen por un comentario mal manejado
- 153. Cuenta oficial de jugadores (reacciones a decisiones tuyas)
- 154. Memes generados por la comunidad del juego

**13. Medios y Prensa**
- 165. Cobertura internacional si el club gana relevancia

**15. Premios y Reconocimientos**
- 176. Balón de Oro del juego
- 182. Premio al fair play
- 184. Premio a la mejor hinchada
- 185. Premio al estadio más impresionante

**16. Eventos Narrativos y Decisiones**
- 191. Sponsor que exige una decisión ética incómoda
- 195. Escándalo de arbitraje que genera indignación
- 199. Conflicto entre cuerpo técnico y directiva

**17. Rivalidades y Clásicos**
- 202. Rivalidad regional/de ciudad
- 205. Presión extra de la afición en el clásico
- 207. Robo de un canterano por el club rival
- 209. "Guerra" de sponsors entre clubes rivales
- 210. Ranking de rivalidad según intensidad de eventos

**18. Legado e Historia del Club**
- 215. Homenajes a ídolos fallecidos o retirados

**19. Roles de Juego (DT / Presidente / Dueño)**
- 226. Elecciones internas si eres presidente (reelección)
- 229. Modo sandbox sin presión de despido

**20. Extras y Sistemas Meta**
- 233. Dificultad ajustable (finanzas, presión mediática, etc.)
- 237. Estadísticas exportables de tu carrera
- 244. Notificaciones push de eventos importantes
- 246. Sistema de logros ocultos/easter eggs

**21. Detalles de Ambientación**
- 253. Horarios de partido elegibles (afecta asistencia/TV)
- 256. Turismo deportivo si el club crece mucho
- 258. Relación con el gobierno local
- 259. Alianzas con otros clubes (amistosos, intercambio de canteranos)
- 260. Torneo de veteranos con ex-jugadores del club

**22. Sistemas de Jugadores (detalle extra)**
- 263. Jugadores con doble nacionalidad (elegibilidad)
- 266. Sistema de lesiones crónicas vs. agudas
- 268. Jugadores con marca personal (redes propias)
- 270. Jugadores "problema" que requieren gestión especial

**23. Eventos de Crisis y Oportunidad**
- 273. Caída de un sponsor por escándalo externo
- 277. Oferta de venta total del club (si eres dueño)
- 278. Escándalo de dopaje a resolver

**24. Progresión y Metas**
- 287. Estadísticas comparativas año a año
- 288. Certificaciones del club (sustentable, formativo, etc.)
- 289. Ranking de mejores canteras a nivel ficticio-continental
- 290. Hitos de asistencia al estadio (lleno histórico)

**25. Toques Finales de Personalización**
- 292. Personalización de la sala de prensa
- 293. Personalización del palco presidencial
- 295. Personalización del avión/transporte para giras
- 296. Personalización de la app oficial del club (ficticia)
- 297. Personalización del sitio web del club (ficticio)
- 299. Personalización de la ceremonia de presentación de fichajes

**27. Récords, Historia y Memoria del Club**
- 319. Resumen anual automático al cerrar cada temporada
- 320. Archivo de planteles históricos por temporada
- 325. Comparador de generaciones (equipo actual vs. el mejor histórico)

**28. Sala de Trofeos y Celebraciones**
- 327. Animación/celebración especial al ganar un trofeo
- 331. Evento especial de "gala de campeones" con invitados históricos
- 335. Fuegos artificiales/mosaico especial configurable para festejos grandes

**29. Más Ideas Adicionales**
- 336. Modo "día a día" con calendario navegable (entrenamientos, viajes, medios)
- 337. Sistema de fatiga por viajes largos en torneos internacionales
- 339. Reuniones de directorio con actas resumidas
- 340. Contrato de imagen del club con una liga de videojuegos ficticia (guiño meta)
- 346. Cláusula de fidelidad: bono si un jugador no pide salir en X años
- 350. Estadísticas de eficiencia de tu gestión (ROI de fichajes, cantera, etc.)

### Declaradas hechas pero sin prueba que las compruebe (38): verificar jugando; las que no existan pasan a pendientes


**1. Infraestructura y Estadio**
- 1. Ampliación de estadio por sectores (norte, sur, palcos)
- 2. Nivel máximo de estadio sin límite realista ("niveles inhumanos")

**2. Ciudad Deportiva / Instalaciones**
- 17. Canchas auxiliares para categorías juveniles
- 25. Auditorio para conferencias de prensa
- 26. Oficinas administrativas del club

**4. Personaje (DT / Presidente / Dueño)**
- 46. Editor de apariencia del personaje
- 54. Nivel de carisma que afecta negociaciones

**5. Plantilla y Jugadores**
- 62. Relación entre compañeros (química de vestuario)

**6. Cantera y Formación Juvenil**
- 75. Riesgo de perder canteranos a otros clubes

**7. Fichajes y Negociación**
- 88. Jugadores que piden ser vendidos

**11. Fans y Comunidad**
- 136. Nivel de aprobación general de la afición
- 143. Mosaicos y coreografías en el estadio

**12. Redes Sociales**
- 148. Tendencias/hashtags según eventos del club

**13. Medios y Prensa**
- 159. Rumores de fichajes filtrados por la prensa

**15. Premios y Reconocimientos**
- 178. Mejor DT del año

**16. Eventos Narrativos y Decisiones**
- 188. Escándalo mediático de un jugador
- 190. Oferta irrechazable por un jugador clave
- 194. Jugador que pide salir por motivos personales
- 196. Incidente de seguridad en el estadio
- 197. Petición de la comunidad local (obra social)
- 198. Oferta de inversión extranjera con condiciones

**18. Legado e Historia del Club**
- 218. Leyendas contratables como embajadores

**20. Extras y Sistemas Meta**
- 241. Accesibilidad: modo daltónico, texto ajustable
- 243. Modo offline completo
- 245. Resumen semanal tipo "informe de gestión"

**21. Detalles de Ambientación**
- 251. Clima que afecta partidos y asistencia
- 255. Eventos comunitarios fuera del fútbol (caridad)

**22. Sistemas de Jugadores (detalle extra)**
- 262. Prestigio internacional del jugador
- 265. Reconversión de jugador a manager/staff al retirarse
- 267. Rendimiento afectado por vida personal (eventos)

**23. Eventos de Crisis y Oportunidad**
- 276. Terreno disponible para expandir la ciudad deportiva

**25. Toques Finales de Personalización**
- 291. Personalización del vestuario (colores, mobiliario)

**27. Récords, Historia y Memoria del Club**
- 317. Efemérides: "un día como hoy" con hechos pasados del club

**28. Sala de Trofeos y Celebraciones**
- 326. Sala de trofeos visual con vitrina por cada título
- 328. Celebración de aniversario del club (ej. cada 5 o 10 años)
- 329. Celebración especial al llegar a un hito de trofeos (ej. 100)
- 330. Placas conmemorativas de hitos históricos

**29. Más Ideas Adicionales**
- 341. Sistema de fair play entre hinchadas (premia buena conducta)

## 7. Tus ideas 351–1100: sin auditar

Nunca se compararon con el código. Auditar por bloques (cada una: ¿existe?, ¿tiene prueba?, ¿se ve bien?) y borrar las hechas. Orden sugerido: partido (351-), gestión, ciudad, resto.


**30. Simulación de Partido (motor y experiencia)**
- 351. Motor 2D cenital con fichas de color en vez de modelos 3D (bajo costo, alta legibilidad)
- 352. Velocidad de simulación configurable (x1, x2, x4, saltar a evento)
- 353. Botón "saltar al próximo gol" para partidas rápidas
- 354. Relator de texto con tono configurable (sobrio, exagerado, humorístico)
- 355. Barra de momentum que muestra qué equipo domina el partido
- 356. Cadenas de jugada: la simulación encadena 3 a 5 acciones antes de resolver
- 357. Probabilidad de gol en vivo (xG) como estadística opcional
- 358. Eventos aleatorios de partido (palo, gol anulado, revisión de VAR)
- 359. Interrupciones: invasión de cancha, corte de luz, lluvia intensa
- 360. Cambios en vivo con vista rápida del banco de suplentes
- 361. Instrucciones en vivo (presionar, retrasar líneas, perder tiempo)
- 362. Charla de entretiempo con varios tonos y efecto real en la moral
- 363. Indicador de fatiga por jugador en tiempo real
- 364. Riesgo de lesión visible al forzar a un jugador tocado
- 365. Aviso de "amonestado bajo presión" antes de una posible expulsión
- 366. Tanda de penales con elección de palo y orden de ejecutantes
- 367. Especialistas designados para penales, córners y tiros libres
- 368. Rendimiento diferenciado por altitud, clima y desgaste de viaje
- 369. Efecto medible del público según ocupación real del estadio
- 370. Cancha en mal estado que reduce precisión de pases
- 371. Modo "solo resultado" para quienes simulan temporadas rápido
- 372. Relato del partido guardable y compartible como texto
- 373. Comparativa post-partido contra el promedio de la liga
- 374. Nota de rendimiento por jugador (1 a 10) con justificación breve
- 375. Detección automática de "partido histórico" archivado en el club
- 376. Ocasiones claras falladas para generar tensión sin gol
- 377. Dificultad de la IA rival ajustada por liga y presupuesto
- 378. IA rival que reacciona a tu táctica a mitad de partido
- 379. Modo espectador para ver partidos de otros equipos
- 380. Resultados de la fecha actualizándose mientras juegas tu partido

**31. Táctica y Sistema de Juego**
- 381. Editor de formación con arrastrar y soltar
- 382. Formaciones guardadas como presets con nombre propio
- 383. Roles por posición (lateral ofensivo, pivote, falso 9, mediapunta)
- 384. Instrucciones individuales por jugador
- 385. Altura de la línea defensiva
- 386. Intensidad de presión (bloque alto, medio, bajo)
- 387. Ritmo de circulación de balón
- 388. Amplitud del ataque
- 389. Tipo de salida (juego corto desde el arquero vs. pelotazo largo)
- 390. Criterio de remate (buscar tiro lejano o el pase extra)
- 391. Marcaje al hombre o por zona
- 392. Trampa del fuera de juego activable
- 393. Editor simple de jugadas ensayadas de córner
- 394. Editor de jugadas ensayadas de tiro libre
- 395. Saque lateral largo como arma táctica
- 396. Plan A / Plan B / Plan C activables según el marcador
- 397. Cambio táctico automático por minuto (ej. cerrar desde el 80)
- 398. Familiaridad táctica: el equipo tarda semanas en asimilar un sistema
- 399. Penalización si el sistema no calza con las cualidades del plantel
- 400. Análisis previo del rival con puntos débiles sugeridos
- 401. Recomendación del ayudante técnico (activable o desactivable)
- 402. Contra-táctica diseñada para un rival concreto
- 403. Modo espejo: copiar la táctica de un equipo que admires
- 404. Índice de compatibilidad jugador-rol
- 405. Jugadores que rinden mejor o peor en un rol específico
- 406. Táctica de emergencia con diez jugadores tras una expulsión
- 407. Plan de partido para jugar con ventaja numérica
- 408. Identidad de juego del club definida a largo plazo
- 409. Hinchada que exige un estilo (ofensivo, aguerrido, de toque)
- 410. DT con estilo propio que choca o encaja con la identidad del club
- 411. Evolución táctica por era: el fútbol de moda cambia con los años
- 412. Estadística de eficacia por cada táctica utilizada
- 413. Pizarra táctica para explicar el plan en la charla previa
- 414. Rotación planificada para calendarios congestionados
- 415. Alineación automática sugerida según frescura y rival

**32. Entrenamiento y Desarrollo**
- 416. Plan semanal de entrenamiento con bloques por día
- 417. Balance entre carga física, trabajo táctico y técnica individual
- 418. Riesgo de sobrecarga y lesiones por entrenar demasiado fuerte
- 419. Entrenamiento individual asignable a un jugador puntual
- 420. Reconversión de posición (lateral a central, extremo a lateral)
- 421. Entrenamiento de habilidades específicas (penales, cabeceo, tiro libre)
- 422. Curva de aprendizaje según edad: los jóvenes progresan más rápido
- 423. Techo de crecimiento visible solo mediante ojeadores confiables
- 424. Explosión tardía: jugadores que despegan entre los 24 y 26
- 425. Jugadores que se estancan si no acumulan minutos
- 426. Pretemporada con efecto sobre el estado físico de todo el año
- 427. Microciclo de recuperación tras partidos seguidos
- 428. Sesiones a puertas cerradas o abiertas al público
- 429. Concentración previa a partidos importantes
- 430. Campamento de altura para mejorar resistencia
- 431. Trabajo mental con psicólogo deportivo
- 432. Entrenamiento de liderazgo para formar futuros capitanes
- 433. Entrenador de arqueros con línea de desarrollo propia
- 434. Cantera entrenada bajo una filosofía definida por el club
- 435. Informe semanal de progreso entregado por el staff
- 436. Jugadores que se quejan si el entrenamiento es muy duro o muy blando
- 437. Disciplina individual que determina cuánto aprovecha el entrenamiento
- 438. Trabajo extra voluntario de los jugadores más profesionales
- 439. Pérdida de ritmo competitivo por parón de liga
- 440. Entrenamiento adaptado a la superficie de la próxima cancha rival
- 441. Video-análisis grupal antes de rivales difíciles
- 442. Índice de calidad de instalaciones que multiplica el progreso
- 443. Veteranos que ya no mejoran pero transmiten experiencia
- 444. Declive físico realista según edad y posición
- 445. Historial gráfico de evolución de atributos por jugador

**33. Scouting y Red de Ojeadores**
- 446. Red de ojeadores contratables con especialidad regional
- 447. Costo mensual por ojeador y por región cubierta
- 448. Informes con rango de incertidumbre en vez de números exactos
- 449. Ojeadores con distinto nivel de precisión y sesgos propios
- 450. Ojeador que exagera sus hallazgos para justificar su sueldo
- 451. Asignación de un ojeador a un torneo juvenil específico
- 452. Descubrimiento de joyas en ligas menores o mercados exóticos
- 453. Base de datos que se va revelando a medida que investigas
- 454. Filtros de búsqueda avanzados (edad, valor, contrato, posición)
- 455. Lista de seguimiento con alertas automáticas
- 456. Alerta de jugador que entra en su último año de contrato
- 457. Alerta de jugador descontento en otro club
- 458. Alerta de cláusula de rescisión anormalmente baja
- 459. Competencia con otros clubes por el mismo objetivo
- 460. Rumores de mercado que pueden resultar falsos
- 461. Informe de personalidad además del informe de habilidad
- 462. Informe médico previo al fichaje, con costo asociado
- 463. Informe de situación familiar que afecta la disposición a mudarse
- 464. Invitar a un jugador libre a entrenar a prueba
- 465. Descubrimiento por casualidad durante un amistoso
- 466. Ojeador que renuncia si ignoras sistemáticamente sus informes
- 467. Ranking interno de objetivos por prioridad
- 468. Presupuesto de scouting separado del de fichajes
- 469. Análisis de datos como alternativa moderna al ojeo tradicional
- 470. Departamento de análisis con modelo estadístico propio del club
- 471. Conflicto interno entre el ojeador tradicional y el analista de datos
- 472. Torneos juveniles internacionales como escaparate de talento
- 473. Convenios con clubes menores por derecho de primera opción
- 474. Scouting de entrenadores y staff, no solo de jugadores
- 475. Informe de "jugadores similares" para reemplazar una salida

**34. Regens, Hijos de Jugadores y Linaje**
- 476. Sistema de regens: nuevas generaciones que reemplazan a los retirados
- 477. Hijos de jugadores históricos que heredan el apellido
- 478. Herencia parcial de atributos del padre con variación aleatoria
- 479. Probabilidad alta de que el hijo juegue en la posición del padre
- 480. Hijo que debuta en el club donde su padre fue leyenda
- 481. Presión mediática específica sobre el hijo de una leyenda
- 482. Riesgo narrativo de que el hijo nunca alcance el nivel del padre
- 483. Caso excepcional: el hijo supera al padre y se vuelve ícono
- 484. Nietos de jugadores en partidas de muy largo plazo
- 485. Hermanos futbolistas con bonificación de química en cancha
- 486. Gemelos con atributos casi idénticos
- 487. Padre retirado que presiona al club para que su hijo juegue
- 488. Ex-jugador que regresa como DT del club donde brilló
- 489. Regens generados con nacionalidad ponderada por la fuerza del país
- 490. Nombres realistas por país y por época de nacimiento
- 491. Época dorada: oleada de talento en un país cada cierto tiempo
- 492. Decadencia futbolística de un país si su liga colapsa
- 493. Regens de élite: dos o tres por generación con potencial de leyenda
- 494. Rareza de potencial (común, prometedor, excepcional, generacional)
- 495. Cantidad y calidad de regens condicionada por la inversión en cantera
- 496. País pequeño que produce un talento generacional como historia épica
- 497. Historia de origen del regen (barrio humilde, academia de élite, refugiado)
- 498. Biografía breve autogenerada para cada regen
- 499. Avatar generado proceduralmente en estilo minimalista
- 500. Rasgos físicos heredados visibles en el avatar del hijo
- 501. Apodos automáticos para regens destacados
- 502. Etiqueta mediática "el nuevo [leyenda]" con la presión que implica
- 503. Regen prometedor que se pierde por indisciplina
- 504. Regen que sufre una lesión grave y trunca su carrera
- 505. Regen que emigra demasiado joven y no se desarrolla
- 506. Doble nacionalidad asignada a ciertos regens
- 507. Regens que eligen selección nacional entre dos opciones
- 508. Árbol genealógico navegable de familias futbolísticas
- 509. Registro histórico de dinastías formadas en tu club
- 510. Bonificación de afinidad al fichar al hijo de un ídolo del club
- 511. Reacción hostil de la hinchada al fichar al hijo de un ídolo rival
- 512. Padrinazgo: un ídolo del club apadrina al hijo de otro
- 513. Evento: el padre retirado pide un cargo en la cantera
- 514. Estadística de cuántos regens de tu cantera llegaron a la élite
- 515. Modo legado familiar: mantener una misma familia tres generaciones

**35. Lesiones y Medicina Deportiva**
- 516. Catálogo amplio de lesiones con tiempos de recuperación distintos
- 517. Diferenciación entre lesiones musculares, articulares y óseas
- 518. Recaídas si se apura el regreso a las canchas
- 519. Porcentaje de recuperación visible, no solo días restantes
- 520. Rasgo de jugador propenso a lesionarse
- 521. Historial médico que afecta el valor de mercado
- 522. Seguro médico contratable para todo el plantel
- 523. Costo de operaciones y clínicas de calidad variable
- 524. Segunda opinión médica con pronóstico distinto
- 525. Médico del club con nivel de competencia propio y mejorable
- 526. Kinesiólogo que acorta los plazos de recuperación
- 527. Riesgo de lesión aumentado por cancha en mal estado
- 528. Riesgo de lesión aumentado por calendario congestionado
- 529. Lesión sufrida durante una gira de selección nacional
- 530. Lesión larga que obliga a un fichaje de emergencia
- 531. Ventana de fichaje de emergencia por lesión grave (regla configurable)
- 532. Retiro forzado por lesión crónica
- 533. Jugador que se infiltra para jugar, con riesgo posterior
- 534. Costo reputacional si abusas de las infiltraciones
- 535. Fatiga acumulada como variable distinta de la forma física
- 536. Índice de carga de trabajo por jugador durante el mes
- 537. Descanso programado como herramienta preventiva
- 538. Alerta médica previa: "no recomiendo que juegue"
- 539. Enfermedades no deportivas que arruinan una semana de trabajo
- 540. Brote en el plantel que obliga a jugar con juveniles
- 541. Estadística de días perdidos por lesión en la temporada
- 542. Comparativa de tu departamento médico contra el resto de la liga
- 543. Rehabilitación con progreso visible semana a semana
- 544. Regreso triunfal tras lesión larga como evento narrativo
- 545. Nutricionista que reduce la incidencia de lesiones blandas

**36. Vestuario, Psicología y Dinámica de Grupo**
- 546. Jerarquía de vestuario visible (líderes, influyentes, periféricos)
- 547. Grupos internos y camarillas dentro del plantel
- 548. Conflictos entre jugadores que debes mediar
- 549. Jugador que pide hablar contigo en privado
- 550. Jugador que se queja por falta de minutos
- 551. Jugador que pide expresamente salir del club
- 552. Jugador que exige renovación tras un buen semestre
- 553. Jugador que se ofende si queda fuera de la lista de un torneo
- 554. Reacción del vestuario ante un fichaje muy caro
- 555. Reacción del vestuario ante la venta de un referente
- 556. Elección de capitán y vicecapitán con efecto real en el grupo
- 557. Consejo de capitanes que negocia contigo condiciones internas
- 558. Moral colectiva separada de la moral individual
- 559. Efecto acumulativo de las rachas de derrotas en el ánimo
- 560. Charla motivacional con distintos tonos y resultados variables
- 561. Jugadores que responden mejor al elogio o a la exigencia
- 562. Perfil psicológico oculto que se descubre con el tiempo
- 563. Jugador conflictivo pero determinante como dilema permanente
- 564. Multas internas por indisciplina
- 565. Reglamento interno del club configurable por ti
- 566. Fiestas y escándalos extradeportivos con consecuencias
- 567. Jugador con problemas personales que necesita apoyo del club
- 568. Apoyo psicológico que recupera a un jugador hundido
- 569. Extranjero que no se adapta al país y pide volver
- 570. Barrera idiomática que dificulta la integración
- 571. Clases de idioma financiadas por el club
- 572. Compañero del mismo país que facilita la adaptación
- 573. Actividades de integración del plantel
- 574. Efecto de tus declaraciones públicas sobre el ánimo interno
- 575. Jugador que se siente traicionado si lo criticas en prensa
- 576. Defensa pública de un jugador que dispara su moral
- 577. Rebelión de vestuario capaz de costarte el puesto
- 578. Jugador que se convierte en tu aliado dentro del grupo
- 579. Índice de confianza del plantel hacia tu gestión
- 580. Renovación generacional del liderazgo del vestuario

**37. Mercado de Fichajes Avanzado**
- 581. Ventanas de mercado con fechas distintas según el país
- 582. Mercado de invierno más caro y con menos opciones
- 583. Jugadores libres disponibles durante todo el año
- 584. Cesiones con opción de compra y con obligación de compra
- 585. Cesión con porcentaje del sueldo pagado por el club de destino
- 586. Intercambio de jugadores más diferencia en dinero
- 587. Porcentaje de futura venta como moneda de negociación
- 588. Cláusula de no alinear al cedido contra el club dueño
- 589. Cláusula que impide la reventa a un rival directo
- 590. Pago en cuotas a varios años y su efecto en el flujo de caja
- 591. Bonos por partidos jugados, goles marcados y títulos ganados
- 592. Derechos de formación y mecanismo de solidaridad
- 593. Terceros propietarios del pase como dilema normativo
- 594. Guerra de ofertas entre varios clubes por el mismo jugador
- 595. Jugador que rechaza tu club por falta de proyecto deportivo
- 596. Jugador que acepta menos dinero para jugar torneo internacional
- 597. Jugador que solo aceptará ir a un club grande
- 598. Presión del agente para subir su comisión
- 599. Último día de mercado con ofertas frenéticas de última hora
- 600. Fichaje caído tras la revisión médica
- 601. Fichaje caído por problema de visa o cupo de extranjeros
- 602. Cupo de extranjeros configurable por liga
- 603. Límite de plantel y exigencia de jugadores formados en casa
- 604. Lista de inscritos por torneo con decisiones difíciles
- 605. Mercado inflado por un club recién comprado por un magnate
- 606. Burbuja de precios que crece con el paso de los años
- 607. Valor de mercado dinámico según rendimiento y contrato
- 608. Bonificación reputacional por operaciones rentables
- 609. Rechazo automático de ofertas por debajo de un monto fijado
- 610. Paciencia del club vendedor como contador visible en la negociación
- 611. Renovación preventiva para no perder a un jugador gratis
- 612. Precontrato con jugador en su último semestre
- 613. Agente libre estrella disponible cada cierto tiempo
- 614. Traspaso récord del club registrado como hito histórico
- 615. Historial completo de operaciones con balance neto acumulado

**38. Agentes, Representantes y Zonas Grises**
- 616. Agentes con cartera propia de jugadores
- 617. Nivel de confianza construido con cada agente
- 618. Agente que te ofrece jugadores en exclusiva si le caes bien
- 619. Agente que te bloquea operaciones si lo tratas mal
- 620. Superagente que controla a media liga
- 621. Comisiones negociables y su impacto en el presupuesto
- 622. Agente que filtra información a la prensa
- 623. Oferta de retorno por comisión como decisión ética con riesgo
- 624. Investigación federativa por operaciones sospechosas
- 625. Sanción por incumplir el fair play financiero
- 626. Denuncia anónima que dispara una auditoría
- 627. Contabilidad paralela como opción arriesgada y sancionable
- 628. Reputación limpia como ventaja concreta en negociaciones
- 629. Presión de un dirigente para fichar a un representado suyo
- 630. Fichaje impuesto directamente por el dueño del club
- 631. Rechazar un fichaje impuesto y ganarte un enemigo interno
- 632. Intermediario que infla artificialmente el precio de una operación
- 633. Agente que representa al comprador y al vendedor a la vez
- 634. Cláusula secreta que se revela tiempo después
- 635. Filtración de un contrato completo a la prensa
- 636. Escándalo de amaño de partidos dentro de tu liga
- 637. Jugador de tu plantel implicado en apuestas
- 638. Programa interno de integridad del club
- 639. Ranking de transparencia con efecto sobre los auspiciadores
- 640. Delación compensada dentro de un caso federativo

**39. Economía Avanzada, Deuda e Insolvencia**
- 641. Estado de resultados mensual y anual del club
- 642. Balance con activos, pasivos y patrimonio
- 643. Flujo de caja proyectado a doce meses
- 644. Diferencia explícita entre resultado contable y caja disponible
- 645. Amortización del valor de los pases en libros
- 646. Plusvalía contable generada por venta de jugadores
- 647. Deuda bancaria con tasa e intereses visibles
- 648. Líneas de crédito y capacidad máxima de endeudamiento
- 649. Renegociación de deuda con los acreedores del club
- 650. Convenio de pago con proveedores
- 651. Mora en el pago de sueldos y sus consecuencias inmediatas
- 652. Jugadores habilitados a rescindir por sueldos impagos
- 653. Sanción deportiva por deuda: resta de puntos
- 654. Prohibición de fichar mientras exista deuda pendiente
- 655. Descenso administrativo por insolvencia
- 656. Procedimiento de reorganización para salvar al club
- 657. Liquidación del club como final de partida alternativo
- 658. Administrador externo designado que limita tus decisiones
- 659. Junta de acreedores que vota el destino del club
- 660. Venta forzada de activos: estadio, ciudad deportiva, terrenos
- 661. Venta del estadio con arriendo posterior como maniobra financiera
- 662. Aporte de capital de emergencia del dueño
- 663. Aumento de capital con dilución de los accionistas actuales
- 664. Emisión de bonos del club comprados por los propios hinchas
- 665. Financiamiento colectivo de hinchas para un fichaje puntual
- 666. Fondo de inversión que compra un porcentaje del club
- 667. Multipropiedad: red de clubes bajo un mismo dueño
- 668. Club satélite donde ceder juveniles
- 669. Presupuesto anual que debe aprobar el directorio
- 670. Reasignación de presupuesto entre fichajes y salarios
- 671. Tope salarial interno autoimpuesto
- 672. Escalas salariales y conflictos internos por desigualdad
- 673. Impuestos por país y su efecto en el sueldo neto ofrecido
- 674. Régimen tributario especial para atraer extranjeros
- 675. Inflación y devaluación de la moneda local
- 676. Ingresos en moneda extranjera por torneos internacionales
- 677. Auditoría anual con informe público
- 678. Panel de indicadores financieros (liquidez, endeudamiento, cobertura)
- 679. Calificación de riesgo del club que encarece o abarata el crédito
- 680. Premio anual a la gestión financiera sostenible

**40. Propiedad, Directorio y Política Interna**
- 681. Elección entre club de socios o sociedad anónima deportiva
- 682. Elecciones de presidente cada cierto número de años
- 683. Campaña electoral con promesas que después debes cumplir
- 684. Voto de censura del directorio
- 685. Padrón de socios que crece o decrece según tu gestión
- 686. Cuota social como ingreso estable y predecible
- 687. Asamblea anual de socios con preguntas incómodas
- 688. Accionistas con intereses distintos: deportivo contra financiero
- 689. Oferta de compra hostil sobre el club
- 690. Vender tu participación y retirarte como final alternativo
- 691. Dueño extranjero que quiere cambiar la identidad del club
- 692. Conflicto por modificar el escudo o los colores tradicionales
- 693. Traslado del club a otra ciudad como decisión polémica
- 694. Fusión con otro club
- 695. Refundación tras la quiebra, partiendo en la última división
- 696. Club filial en otra ciudad o país
- 697. Directorio con miembros de personalidad definida
- 698. Director deportivo con autonomía delegable
- 699. Delegar o no las negociaciones, con efecto en tu carga de trabajo
- 700. Objetivos de temporada negociados con el directorio
- 701. Paciencia del directorio como barra siempre visible
- 702. Despido y búsqueda posterior de un nuevo cargo
- 703. Ofertas de otros clubes en plena temporada
- 704. Cláusula de salida en tu propio contrato
- 705. Indemnización por despido
- 706. Reputación profesional que abre o cierra puertas
- 707. Entrevista de trabajo con un club interesado
- 708. Elegir entre club grande con presión o proyecto largo sin prisa
- 709. Historial de cargos con estadísticas completas de tu carrera
- 710. Salón de la fama de dirigentes y entrenadores del mundo del juego

**41. Infraestructura Urbana y Entorno**
- 711. Mapa de la ciudad con terrenos comprables
- 712. Ubicación del estadio que afecta la asistencia promedio
- 713. Conexión de transporte público hacia el estadio
- 714. Barrio del club que se desarrolla junto con el éxito deportivo
- 715. Negociación con la municipalidad por permisos de construcción
- 716. Oposición vecinal a la ampliación del estadio
- 717. Estudio de impacto ambiental obligatorio
- 718. Estadio compartido con otro club de la misma ciudad
- 719. Arriendo del estadio para conciertos y eventos masivos
- 720. Ingresos por eventos no deportivos
- 721. Daño al césped por eventos y su costo de reparación
- 722. Estadio provisional mientras construyes el definitivo
- 723. Mudanza temporal a otra ciudad durante la obra
- 724. Hotel del club como negocio anexo
- 725. Restaurante y bar temático del club
- 726. Clínica deportiva abierta al público general
- 727. Escuela de fútbol comercial con franquicias
- 728. Centro comercial anexo al estadio
- 729. Paneles solares y sostenibilidad con beneficios tributarios
- 730. Certificación ecológica del estadio
- 731. Seguridad privada y control de accesos
- 732. Sistema de cámaras y protocolo antiviolencia
- 733. Multas por incidentes ocurridos en el estadio
- 734. Sanción de partido a puertas cerradas
- 735. Aforo reducido temporal y su golpe económico

**42. Hinchada, Barras y Cultura Popular**
- 736. Segmentación de la hinchada en grupos con demandas distintas
- 737. Hinchas históricos frente a hinchas nuevos atraídos por el éxito
- 738. Índice de conexión emocional entre hinchada y equipo
- 739. Protestas por el precio de las entradas
- 740. Protestas por la venta de un ídolo
- 741. Banderazo de apoyo antes de un partido clave
- 742. Recibimiento masivo al bus del equipo
- 743. Mosaico organizado por la hinchada
- 744. Barra organizada con demandas y riesgo de violencia
- 745. Decisión estratégica de negociar o enfrentar a la barra
- 746. Incidentes que derivan en sanciones para el club
- 747. Hinchada que viaja masivamente a un partido decisivo
- 748. Programa de socios con beneficios por antigüedad
- 749. Abonos de temporada con distintos planes y coberturas
- 750. Precios dinámicos según el atractivo del partido
- 751. Entradas populares a precio social como decisión de imagen
- 752. Día del hincha con actividades dentro del estadio
- 753. Peñas o filiales del club en otras ciudades
- 754. Filiales internacionales si el club se globaliza
- 755. Encuesta de satisfacción a los hinchas
- 756. Cánticos que aparecen dedicados a jugadores destacados
- 757. Ídolo popular al que la hinchada protege aunque rinda poco
- 758. Jugador señalado por la hinchada tras un error decisivo
- 759. Silbatina en el estadio que afecta el rendimiento del equipo
- 760. Proceso de recuperación de la confianza tras una crisis
- 761. Documental sobre la hinchada producido por el club
- 762. Museo con exhibición participativa de objetos de hinchas
- 763. Colecta solidaria organizada por el club
- 764. Programa social en barrios vulnerables
- 765. Rama de fútbol femenino como área gestionable
- 766. Rama de futsal o fútbol playa como apuesta menor
- 767. Deporte adaptado y su impacto en la imagen institucional
- 768. Voluntariado de jugadores en la comunidad
- 769. Índice de reputación social del club
- 770. Premio a la mejor institución del año

**43. Prensa, Medios y Narrativa**
- 771. Conferencias de prensa con preguntas y opciones de respuesta
- 772. Periodistas con línea editorial y sesgos definidos
- 773. Periodista que te tiene manía y busca desgastarte
- 774. Periodista aliado al que puedes filtrar información
- 775. Titulares generados según resultados y declaraciones
- 776. Guerra mediática con un DT rival
- 777. Declaración pública que motiva o desmotiva al plantel
- 778. Silencio de prensa como estrategia deliberada
- 779. Multa federativa por declaraciones desafortunadas
- 780. Entrevista larga en un programa deportivo
- 781. Programa de debate donde se discute tu gestión
- 782. Encuesta de opinión pública sobre tu continuidad
- 783. Rumor falso de tu despido publicado en portada
- 784. Filtración de la alineación antes del partido
- 785. Investigación periodística sobre las finanzas del club
- 786. Crisis de imagen que exige un plan de comunicación
- 787. Vocero del club habilitado para hablar en tu lugar
- 788. Departamento de comunicaciones mejorable por niveles
- 789. Documental tras bambalinas: ingresos a cambio de exposición
- 790. Cámaras en el vestuario como decisión rentable pero riesgosa
- 791. Biografía autorizada de un ídolo del club
- 792. Podcast oficial del club
- 793. Canal de streaming propio con suscriptores
- 794. Derechos de TV negociados individualmente o en bloque
- 795. Horarios de partido impuestos por la televisión
- 796. Presión por jugar en horarios incómodos para el hincha
- 797. Cobertura internacional al firmar a una estrella
- 798. Reacción de la prensa extranjera ante un fichaje sorpresivo
- 799. Archivo navegable de portadas históricas del club
- 800. Narrador de temporada que resume la campaña como relato

**44. Árbitros, Reglamento y Disciplina**
- 801. Árbitros con perfiles distintos (permisivo, tarjetero, casero)
- 802. Designación arbitral conocida antes del partido
- 803. Historial de resultados con cada árbitro
- 804. Reclamo formal por una designación arbitral
- 805. VAR activable o no según la competencia
- 806. Errores arbitrales que generan polémica y narrativa
- 807. Sanción por reclamar públicamente contra el arbitraje
- 808. Expulsión del DT y prohibición de dirigir el partido siguiente
- 809. Tribunal de disciplina con casos y apelaciones
- 810. Apelación de tarjeta roja con probabilidad de éxito variable
- 811. Suspensión automática por acumulación de amarillas
- 812. Amnistía de amarillas al llegar a determinada fase
- 813. Castigo largo por agresión dentro del campo
- 814. Denuncia por insultos discriminatorios
- 815. Protocolo antidiscriminación con partido suspendido
- 816. Control antidopaje aleatorio
- 817. Jugador que da positivo y el impacto deportivo y de imagen
- 818. Defensa legal del club en un caso de dopaje
- 819. Reglamento de competencia consultable dentro del juego
- 820. Cambios de reglas entre temporadas
- 821. Regla de cinco cambios activable
- 822. Reglas experimentales aplicadas en ligas menores
- 823. Gol de visitante como criterio configurable
- 824. Criterios de desempate configurables
- 825. Puntos de fair play como criterio de desempate
- 826. Sanción por alineación indebida
- 827. Pérdida de puntos por incumplimiento administrativo
- 828. Protesta formal contra un resultado
- 829. Fallo del tribunal que modifica la tabla de posiciones
- 830. Historial disciplinario del club por temporada

**45. Federaciones, Licencias y Política Deportiva**
- 831. Licencia de club exigida para competir
- 832. Requisitos de infraestructura mínima por división
- 833. Requisitos financieros para obtener la licencia
- 834. Auditoría federativa anual
- 835. Voto del club en las asambleas de la liga
- 836. Alianzas políticas con otros clubes
- 837. Presidente de la liga con agenda propia
- 838. Reforma del formato del torneo sometida a votación
- 839. Creación de una superliga separatista como decisión polémica
- 840. Sanción por participar en una liga no reconocida
- 841. Reparto de derechos de TV votado entre clubes
- 842. Lucha por una mayor tajada de los ingresos centrales
- 843. Calendario definido por la federación con conflictos de fechas
- 844. Fecha FIFA que te deja sin jugadores clave
- 845. Reclamo por lesión de un jugador en la selección
- 846. Compensación económica por cesión a la selección
- 847. Cupos obligatorios de juveniles en cancha
- 848. Bonificación federativa por dar minutos a canteranos
- 849. Cambio de formato de ascensos y descensos entre temporadas
- 850. Playoffs de descenso con máxima tensión
- 851. Repechaje internacional por un cupo
- 852. Sistema de licencias que impide ascender pese al mérito deportivo
- 853. Corrupción federativa como trama de fondo de la partida
- 854. Investigación internacional que sacude a la federación
- 855. Cambio de asociación continental en casos excepcionales
- 856. Torneo continental nuevo creado a mitad de partida
- 857. Ranking de coeficientes de países que define cupos
- 858. Aporte de tu club al coeficiente nacional
- 859. Diplomacia con federaciones extranjeras para amistosos
- 860. Gira internacional que requiere aprobación federativa

**46. Selecciones Nacionales**
- 861. Modo seleccionador nacional paralelo o alternativo
- 862. Convocatorias con lista preliminar y lista definitiva
- 863. Jugadores nacionalizados por años de residencia
- 864. Disputa entre dos selecciones por un mismo jugador
- 865. Eliminatorias organizadas por confederación
- 866. Repechaje intercontinental
- 867. Copa del mundo simulada cada cuatro años
- 868. Torneos continentales con formatos propios
- 869. Selecciones juveniles vinculadas a la absoluta
- 870. Torneo olímpico con reglas de edad
- 871. Conflicto club-selección por un jugador clave
- 872. Jugador que vuelve lesionado o agotado de la selección
- 873. Prestigio del club según cantidad de seleccionados
- 874. Vitrina mundialista que dispara el precio de tus jugadores
- 875. Ojear durante un mundial y fichar a la revelación
- 876. Retiro de la selección de un veterano emblemático
- 877. Debut de un canterano tuyo en la selección mayor
- 878. Historial de seleccionados formados en tu club
- 879. Ranking mundial de selecciones dinámico
- 880. Naturalización masiva en países pequeños como dilema
- 881. Amistosos internacionales que generan ingresos
- 882. DT de selección que compite contigo por la atención de un jugador
- 883. Oferta para dirigir una selección mientras diriges un club
- 884. Doble cargo permitido o prohibido según el país
- 885. Legado como seleccionador registrado en el salón de la fama

**47. Competencias y Formatos**
- 886. Editor de competencias personalizado
- 887. Crear tu propia liga con reglas a medida
- 888. Definir número de equipos, ascensos y descensos
- 889. Formatos: todos contra todos, apertura y clausura, playoffs
- 890. Copas de eliminación directa
- 891. Copa nacional con participación de equipos amateurs
- 892. Cenicienta de copa que llega inesperadamente lejos
- 893. Supercopa entre campeones
- 894. Copa de la liga como torneo secundario
- 895. Torneos de verano y amistosos de pretemporada
- 896. Copa internacional de clubes
- 897. Mundial de clubes con formato ampliado
- 898. Torneos regionales de carácter histórico
- 899. Torneos ficticios desbloqueables por logros
- 900. Sistema de sorteo con bombos y restricciones
- 901. Sorteo transmitido en vivo como evento del juego
- 902. Cabezas de serie definidos por coeficiente
- 903. Fase de grupos con múltiples criterios de clasificación
- 904. Eliminatoria a partido único en cancha neutral
- 905. Final única en sede predefinida con años de anticipación
- 906. Definición por penales con estadísticas históricas propias
- 907. Premios económicos crecientes por fase alcanzada
- 908. Cupos internacionales asignados por posición en la liga
- 909. Tabla anual y tabla acumulada funcionando en paralelo
- 910. Calendario visual con todas las competencias superpuestas

**48. Datos, Editor y Comunidad**
- 911. Base de datos editable desde el propio juego
- 912. Editor de ligas, clubes y jugadores sin salir de la partida
- 913. Importación de paquetes de datos creados por la comunidad
- 914. Exportación de tu base para compartirla con otros
- 915. Verificación de compatibilidad entre versiones de datos
- 916. Editor de escudos con formas y capas
- 917. Editor de camisetas con patrones predefinidos
- 918. Editor de estadios simplificado
- 919. Nombres genéricos por defecto con opción de renombrar todo
- 920. Herramienta de renombrado masivo
- 921. Plantillas de datos por país descargables
- 922. Actualización de plantillas al inicio de cada temporada real
- 923. Sistema de parche de datos separado del programa principal
- 924. Editor de nombres de competencias
- 925. Editor de reglas de competencias existentes
- 926. Editor de calendario y fechas
- 927. Editor de finanzas iniciales de cada club
- 928. Editor de atributos con validación de rangos
- 929. Generador aleatorio de mundo ficticio completo
- 930. Modo mundo alternativo sin ningún dato real
- 931. Bloqueo opcional de edición para partidas competitivas
- 932. Registro de cambios aplicados a la base de datos
- 933. Copias de seguridad automáticas de la base
- 934. Sincronización en la nube entre dispositivos
- 935. Tabla de clasificación global de gestores en línea
- 936. Compartir capturas de logros con formato propio
- 937. Muro o foro de comunidad integrado
- 938. Desafíos semanales creados por la comunidad
- 939. Sistema de valoración de paquetes de datos
- 940. Créditos automáticos a los autores de los datos
- 941. Herramientas de moderación para contenido de la comunidad
- 942. Modo sin conexión totalmente funcional
- 943. Peso reducido de la aplicación como ventaja competitiva
- 944. Compatibilidad garantizada con dispositivos de gama baja
- 945. Guardado en la nube con recuperación de partidas

**49. Modos de Juego y Desafíos**
- 946. Modo carrera clásico con club a elección
- 947. Modo empezar desde abajo con un club amateur
- 948. Modo club creado desde cero en la última división
- 949. Modo salvar al club con quiebra inminente
- 950. Modo solo canteranos: prohibido fichar
- 951. Modo sin dinero: presupuesto cero toda la partida
- 952. Modo un solo país: sin extranjeros permitidos
- 953. Modo trotamundos: obligado a cambiar de club cada dos años
- 954. Modo clásico eterno: ganar todos los derbis de la temporada
- 955. Modo invicto: la partida termina con la primera derrota
- 956. Modo leyenda: treinta temporadas en el mismo club
- 957. Modo dinastía familiar centrado en hijos y nietos
- 958. Modo presidente: solo decisiones institucionales
- 959. Modo dueño: solo decisiones financieras
- 960. Modo DT puro: sin control sobre el dinero
- 961. Modo director deportivo: solo fichajes y cantera
- 962. Escenarios históricos recreados como desafío
- 963. Escenario: remontar diez puntos en ocho fechas
- 964. Escenario: evitar el descenso con el peor plantel de la liga
- 965. Escenario: ganar una copa con un club chico
- 966. Escenario: alcanzar una meta de ventas en una temporada
- 967. Escenario: formar cinco seleccionados en diez años
- 968. Modo rápido de una sola temporada
- 969. Modo largo de cincuenta temporadas
- 970. Modo caja de arena con recursos infinitos
- 971. Modo realista con carrera irreversible
- 972. Dificultad ajustable por sistema (finanzas, mercado, IA rival)
- 973. Modificadores activables al iniciar la partida
- 974. Puntaje de partida calculado según la dificultad elegida
- 975. Ranking local de mejores puntajes
- 976. Multijugador por turnos en el mismo dispositivo
- 977. Multijugador en línea con varios gestores en la misma liga
- 978. Liga privada para jugar con amigos
- 979. Modo cooperativo: dos personas gestionando el mismo club
- 980. Modo espectador de una liga completamente simulada
- 981. Modo solo simulación: ver evolucionar el mundo sin intervenir
- 982. Reinicio de temporada con la misma semilla
- 983. Semilla de partida compartible entre jugadores
- 984. Modo sin recarga de partida guardada
- 985. Tutorial narrativo integrado a la primera temporada

**50. Progresión Meta y Rejugabilidad**
- 986. Sistema de logros con recompensas cosméticas
- 987. Desbloqueo de estadios, escudos y camisetas por logros
- 988. Nivel de perfil de gestor que persiste entre partidas
- 989. Árbol de mejoras de perfil, opcional y desactivable
- 990. Colección de cromos de jugadores legendarios de tus partidas
- 991. Museo global que reúne lo logrado en todas tus carreras
- 992. Estadísticas acumuladas de todas tus partidas
- 993. Récords personales por carrera
- 994. Desafíos diarios cortos independientes de la carrera
- 995. Recompensa por completar temporadas consecutivas
- 996. Sistema de prestigio al reiniciar con pequeñas ventajas
- 997. Hitos narrativos que cierran capítulos de tu carrera
- 998. Final de carrera con evaluación completa de tu legado
- 999. Epílogo generado según las decisiones tomadas
- 1000. Salón de la fama personal del jugador
- 1001. Comparación de tu carrera con la de otros usuarios
- 1002. Resumen de vida al momento de retirarte
- 1003. Placa conmemorativa por cantidad de temporadas dirigidas
- 1004. Historial de todos los clubes dirigidos con su balance
- 1005. Metas autoimpuestas configurables por el usuario
- 1006. Mundo distinto en cada partida nueva
- 1007. Eventos históricos aleatorios que cambian entre partidas
- 1008. Fuerza variable de las ligas en cada mundo generado
- 1009. Cartas de evento que aparecen una sola vez por partida
- 1010. Nueva partida con el mundo heredado de la anterior

**51. Interfaz y Calidad de Vida**
- 1011. Navegación por pestañas inferiores fijas
- 1012. Botón de continuar siempre en la misma posición
- 1013. Bandeja de entrada unificada con notificaciones agrupadas
- 1014. Filtro de notificaciones por importancia
- 1015. Marcar mensajes como leídos en bloque
- 1016. Buscador global de jugadores, clubes y competencias
- 1017. Historial de navegación con botón de volver atrás
- 1018. Favoritos para acceso rápido a pantallas frecuentes
- 1019. Comparador de jugadores lado a lado
- 1020. Tablas ordenables por cualquier columna
- 1021. Columnas configurables por el usuario
- 1022. Vista compacta y vista detallada intercambiables
- 1023. Modo oscuro y modo claro
- 1024. Escalado de texto para accesibilidad
- 1025. Paletas alternativas para daltonismo
- 1026. Gestos de deslizamiento para cambiar de pestaña
- 1027. Confirmación previa a decisiones irreversibles
- 1028. Deshacer la última acción no crítica
- 1029. Autoguardado configurable
- 1030. Guardado manual con varias ranuras
- 1031. Carga inmediata de la última partida al abrir la app
- 1032. Indicador de progreso claro en simulaciones largas
- 1033. Retomar exactamente en la pantalla donde quedaste
- 1034. Resumen del día al avanzar el calendario
- 1035. Panel de tareas pendientes antes de continuar
- 1036. Alerta si intentas avanzar con alineación inválida
- 1037. Sugerencias contextuales desactivables
- 1038. Glosario integrado de términos del juego
- 1039. Ayuda contextual desplegable en cada pantalla
- 1040. Tutorial por capas que se activa al usar cada sistema
- 1041. Modo experto que oculta toda la ayuda
- 1042. Pantalla de inicio personalizable con widgets
- 1043. Widget de próximo partido
- 1044. Widget de finanzas resumidas
- 1045. Widget de tabla de posiciones
- 1046. Widget de lesionados y suspendidos
- 1047. Notificaciones opcionales del próximo partido
- 1048. Sincronización de partida entre teléfono y tablet
- 1049. Rendimiento fluido en dispositivos de gama baja
- 1050. Consumo de batería optimizado por diseño

**52. Audio, Estética y Presentación**
- 1051. Estilo visual plano de alto contraste, legible al sol
- 1052. Íconos simples y consistentes en toda la aplicación
- 1053. Paleta que se adapta automáticamente a los colores del club
- 1054. Tipografía condensada, legible en pantallas pequeñas
- 1055. Tablas tratadas como elemento estético central, no como relleno
- 1056. Ilustraciones vectoriales para los eventos narrativos
- 1057. Avatares minimalistas generados a partir de atributos
- 1058. Cancha 2D con fichas en los colores reales del club
- 1059. Animaciones cortas y funcionales, nunca bloqueantes
- 1060. Transiciones suaves entre pantallas
- 1061. Vibración breve en decisiones importantes
- 1062. Sonido ambiente de estadio durante el partido
- 1063. Silbato, murmullo y explosión de gol como capas separadas
- 1064. Volumen del público según asistencia y momento del partido
- 1065. Música de menú discreta y desactivable
- 1066. Cántico del club reproducido en momentos clave
- 1067. Sonido distintivo para el gol propio y para el gol rival
- 1068. Modo silencioso completo para jugar en público
- 1069. Pantalla de carga con datos curiosos del club
- 1070. Portada de diario animada para las noticias importantes
- 1071. Tarjetas visuales para los resúmenes de temporada
- 1072. Estética de cuaderno de gestión en la parte administrativa
- 1073. Gráficos limpios para finanzas y evolución de jugadores
- 1074. Celebración sobria pero satisfactoria al ganar un título
- 1075. Identidad visual propia que no imite a los juegos de referencia

**53. Monetización y Modelo Indie**
- 1076. Juego base pagado sin anuncios como opción premium
- 1077. Versión gratuita con anuncios no intrusivos
- 1078. Anuncios solo en pantallas de carga, nunca durante decisiones
- 1079. Compra única para eliminar anuncios de forma permanente
- 1080. Sin mecánicas de pagar para ganar
- 1081. Sin cajas de recompensa ni azar pagado
- 1082. Expansiones honestas de contenido (nuevas ligas, nuevos modos)
- 1083. Paquetes cosméticos sin ventaja deportiva
- 1084. Apoyo voluntario al desarrollador con recompensa simbólica
- 1085. Precio accesible pensado para Latinoamérica
- 1086. Precio regional ajustado por país
- 1087. Demo gratuita con una temporada completa
- 1088. Comunicación clara de qué se paga y qué no
- 1089. Hoja de ruta pública de actualizaciones
- 1090. Beta abierta con comunidad de prueba
- 1091. Registro de cambios detallado en cada actualización
- 1092. Canal de reporte de errores dentro del juego
- 1093. Encuestas a jugadores para priorizar funciones
- 1094. Compromiso de que las partidas guardadas sobrevivan a las actualizaciones
- 1095. Compatibilidad hacia atrás de las bases de datos
- 1096. Sin necesidad de conexión permanente para jugar
- 1097. Sin recolección innecesaria de datos personales
- 1098. Política de privacidad simple y legible
- 1099. Código de conducta para la comunidad
- 1100. Compromiso de dejar el juego jugable aunque se detenga el desarrollo
