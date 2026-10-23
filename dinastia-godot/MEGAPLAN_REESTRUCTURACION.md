# MEGAPLAN DE LA REESTRUCTURACIÓN · 23-10-2026

Nace del mensaje del dueño del 23-10 («el juego carece de una verdadera integración con un
sentido humano y de estilo propio»). Reúne en un solo sitio: (1) la nueva estructura del
juego, (2) los pendientes que ya había (`PENDIENTES.md`), (3) los puntos de mejora
(`ESTADO_MEJORAS.md`, `COMPARACION_JUEGOS_2.md`), (4) la limpieza del repo y (5) cómo hacer
el código menos delicado. **Aquí no se promete nada que no esté medido**: cada cifra sale de
mirar el repositorio el 23-10.

Estado de este documento: PLAN. Lo único ya hecho es la sección 2 (colisiones).

---

## 1. ¿Está mal que un archivo pase de 500 líneas?

**No, 500 no es una regla; es una señal.** Lo que importa es cuántas responsabilidades
mezcla un archivo y cuánto se rompe cuando se toca. Medido hoy:

- 662 scripts `.gd`, 169.598 líneas. **75 pasan de 500** y **29 de 1.000**.
- Los grandes que NO son problema: datos o generados (`nucleo/dialogos_ciudad.gd` lo genera
  una herramienta), el banco de pruebas y los constructores de mundo (`city_builder`,
  `stadium_builder`: una receta larga y lineal).
- **El que sí es problema: `ui/principal.gd`, 6.867 líneas, 169 funciones y 157 variables de
  miembro.** Es un «objeto dios»: hoy mezcla el menú central de doble nivel, los hubs, las
  píldoras y estilos, elegir club, el autoguardado, ajustes (tipografía, idioma, FPS, música),
  las noticias (`_conectar_noticias` sola mide 548 líneas), la prensa, el estadio y las
  finanzas. Cualquier cambio roza algo que no tiene que ver. **Ese es el miedo que describes
  y tiene razón de ser.**
- Otros candidatos a partir con cuidado: `visor/motor_jugable.gd` (4.578; es el motor del
  partido, se parte por fases: IA, física, reglas), `ui/componentes/interior_instalacion.gd`
  (2.760: una sala por archivo), `nucleo/prensa.gd` (2.539), `ui/estadio.gd` (2.358),
  `nucleo/mundo.gd` (2.980) y `visor/explorador_ciudad.gd` (1.983).

**Regla propuesta (a validar contigo):**
- Código nuevo: una responsabilidad por archivo, objetivo < 600 líneas.
- Archivo existente: no crece; si hay que añadir algo grande, se extrae primero.
- Excepciones declaradas: datos, generados, banco y constructores lineales.
- Meta de cierre: ningún script de lógica o interfaz > 1.500 líneas. `principal.gd` < 1.500.

**Aclaración honesta sobre «un fallo no debe tumbar el juego».** GDScript no tiene
`try/catch`. Un error de script aborta *esa función* y el juego sigue, pero lo que se
rompe a medias suele dejar el estado inconsistente y provoca fallos en cascada. La protección
real es de diseño: datos validados al entrar, comprobaciones de nodos liberados
(`is_instance_valid`), cada pantalla en su propia clase con una interfaz mínima, guardado
automático y pruebas que cierran cada hueco. Ver sección 7.

---

## 2. Fallas: colisiones del club a pie — ARREGLADO (23-10)

**Lo que veías** («barreras invisibles ilógicas, paredes que se atraviesan, personas que se
atraviesan») **tenía tres causas reales:**
1. `ExploradorEstadio.zona_en(p, _radio)` **ignoraba el radio**: solo miraba si el centro del
   cuerpo estaba en una zona, así que el cuerpo entraba hasta 0,45 m en las paredes.
2. Los muebles «sólidos» del edificio del club llevaban un `StaticBody3D`, pero **el
   personaje se mueve por posición, nada los consultaba**: eran decorado.
3. **No existía ninguna comprobación contra la gente del club**: ni el jugador ni el
   personal se esquivaban.

**Qué hace ahora** (`visor/colision_club.gd`, usado por `ExploradorEstadio` y por
`ExploradorCiudad` dentro del estadio):
- Cada paso se parte en trozos de ≤ 0,15 m (nada atraviesa una pared fina ni a velocidad de
  carrera).
- Cada trozo exige que el cuerpo ENTERO (círculo de 0,3 m) quepa en las zonas, que no
  toque un mueble o pared con colisión (consulta al motor de física) y que no se meta en una
  persona del personal. Si choca, desliza por cada eje; si tampoco, se para.
- El personal **cede el paso**: se queda quieto si el jugador queda a menos de 1 m en su camino.
- Si el personaje ya empieza dentro de algo (un hueco mal puesto) puede salir.

**Prueba:** `pruebas/prueba_colisiones_club.tscn` (código de salida 0 = bien). Mide: (1) el
cuerpo nunca sale de las zonas contra una pared; (2) 7.830 pasos al azar en todas las
plantas sin terminar dentro de un mueble; (3) las 10 personas del personal no se
atraviesan; (4) **desde el punto de salida de cada planta se llega al centro de cada sala,
del túnel, del campo y de la calle con el cuerpo entero** (búsqueda en rejilla de 0,25 m),
que es lo que delata una barrera invisible. Resultado: 0 fallos. Mini bancos `ciudad` y
`estadio` en verde.

**Sin cubrir todavía (hay que revisarlo en pantalla, no se puede por pruebas):**
- Zonas de la ciudad fuera del club (fachadas, vallas, interiores de casas): usan otro
  sistema de círculos y rectángulos (`ExploradorCiudad._choca_circulos`); no se tocó.
- Peatones y coches de la ciudad: son obstáculos móviles con su propia cesión de paso.
- Un fallo visual como «una pared se ve pero deja pasar» puede ser un hueco en el modelo,
  no en la colisión. Si lo ves, dime la sala y el sitio.
- La prueba no está aún en `banco.gd` (es una escena aparte, igual que `prueba_partido_motor`);
  añadirla a un grupo de mini banco es el paso siguiente (sección 8, fase 0).

---

## 3. La nueva estructura del juego (tu guion)

Hay dos formas de leerlo: **el flujo** (qué ve el jugador) y **los sistemas** (qué hay que
construir debajo). Primero el flujo.

### 3.1 El flujo

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

### 3.2 Qué existe ya para cada etapa

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

### 3.3 Los sistemas nuevos (lo más grande)

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

## 4. Pendientes que ya existían (se incorporan)

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

## 5. Puntos de mejora (de `ESTADO_MEJORAS.md`, 470 puntos + 350 ideas)

Estado contado el 21-10: **HECHO 114 · PARCIAL 115 · PENDIENTE 223** (de 452 con fila).
Pendientes por sección (el 17-10, referencia): A. Estadios 19 · B. Público 12 · C.
Camisetas/escudos 21 · D. Jugadores/caras 19 · E. Partido 28 · F. Ciudad 26 · G. Gestión 26
· H. Carrera 9 · I. Interfaz 15 · J. Audio 7 · K. Idiomas 6 · L. Rendimiento 12 · M. Datos 13 ·
N. Código 19.

**Cómo se enlazan con la reestructuración** (para no hacerlos dos veces):
- G (gestión) y H (carrera) → se rehacen dentro de «personas en persona» y «agenda».
- I (interfaz) → las fases 0-5 del menú inicial las cierran en gran parte.
- N (código) → sección 7 de este documento.
- F (ciudad) → la ciudad deja de ser un visor y pasa a ser el hogar del jugador.
- A-E, J-M → siguen su camino, no bloquean la reestructuración.

---

## 6. Limpieza del repositorio (medida el 23-10)

| Qué | Peso | Seguimiento | Veredicto |
|---|---:|---|---|
| `.git` (historia) | 1,2 GB | — | el verdadero peso; solo baja reescribiendo la historia (abajo) |
| `entregas/` (builds Windows y web) | 375 MB, 2.218 archivos | en git | **sacar del repo**: los builds son del dueño; van a Releases o a otro sitio |
| `dinastia-godot/pruebas/capturas/` | 394 MB, 857 archivos | en git | conservar solo la última por prueba; el resto, ignorado |
| `dinastia-godot/recursos/` | 230 MB, 9.612 archivos | en git | revisar qué es regenerable (caras, mallas); los datos de caras reales ya van fuera de los builds |
| `dinastia-godot/assets/` | 165 MB | en git (parte LFS) | mantener |
| `marca/` | 20 MB | en git | revisar con el dueño |
| `_extraido_mocap_soccer/` | 14 MB | en git | sobra si el pack original sigue en tu poder; mover a `docs/origen/` si quieres conservarlo |
| `_extraido_universal_animation_library/` | 0,9 MB | en git | **conservar** `License.txt` (lo cita `LICENCIAS.md`) |
| `_docs_extract/` | 2,1 MB | en git | **son tus informes técnicos extraídos** (arquitectura, maestro): moverlos a `docs/informes/`, no borrar |
| `test_shark.png` | 92 KB | en git | lo subiste tú (AUDITORIA.md); preguntar |
| `JUGAR DINASTIA.exe`, `Universal Base Characters[Standard].zip` | punteros LFS | en git | lanzador y fuente de personaje: conservar |
| `dinastia-godot/*.md` (31 documentos, `LEEME.md` 608 KB) | ~1 MB | en git | consolidar en `docs/` con un índice |

**Código muerto.** Se buscó cada script de `nucleo/`, `visor/` y `ui/`: **ninguno huérfano**
(todo se referencia por nombre de clase o ruta). No hay scripts que borrar. Sí hay 391
escenas de prueba en `pruebas/` que conviene agrupar por tema.

**Contradicción a resolver:** `CLAUDE.md` dice «sin subidas a LFS» y `.gitattributes` ya
manda a LFS `*.zip`, `*.exe`, `*.glb`, etc. (278 archivos hoy). Hay que decidir si LFS se
acepta o se quita.

**Reescribir la historia** (lo pediste el 14-10 y sigue en espera): quitar de TODAS las
versiones viejas los binarios sobrantes (capturas, builds, modelos antiguos, mallas), nunca
código. Se haría con `git filter-repo` en un clon aparte. **Consecuencias que tienes que
aprobar:** cambian todos los identificadores de commit, los PR y ramas abiertos dejan de
valer y todo el mundo tiene que volver a clonar. Antes: fusionar la rama a `main`.

**Qué NO haré sin tu OK:** borrar `entregas/`, capturas, `marca/`, los informes extraídos o
reescribir la historia.

---

## 7. Código menos delicado (cómo se hace y cómo se comprueba)

### 7.1 Partir `principal.gd` sin romperlo
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

### 7.2 Contratos y aislamiento
- **Un contrato por pantalla:** `abrir(contexto)`, `cerrar()` y una señal; nada de que una
  pantalla lea las variables de otra.
- **Estado de partida único** (`Mundo` + `Partida`): las pantallas leen, no guardan copias.
- **Validar al entrar:** datos de guardado con esquema y versión; migraciones explícitas
  (importante cuando cambie la estructura, sección 9).
- **Guardias de nodos liberados:** el estrés de menús del 17-10 encontró 3 errores de este
  tipo; se generaliza el patrón (`is_instance_valid`) en las pantallas nuevas.
- **Cierre ordenado y autoguardado** antes de cada transición larga (intro → inicio →
  prólogo → oficina) para que un fallo no pierda la partida.

### 7.3 Pruebas
- Añadir `prueba_colisiones_club` y las del nuevo flujo a grupos de `mini_banco.sh`.
- Partir `pruebas/banco.gd` (9.561 líneas) en un archivo por grupo (`partido`, `guardado`,
  `ciudad`, `estadio`, `gestion`, `competicion`, `textos`).
- Una prueba de **arranque completo** (intro → idioma → fases 1-5 → prólogo) con atajo de
  desarrollo para saltar etapas, para que el banco no se haga lento.

---

## 8. Calendario por fases (cada una cierra con banco en 0 fallos + capturas con la cámara real)

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

## 9. Lo que necesito que decidas

1. **Partidas guardadas:** ¿se pueden invalidar al cambiar la estructura, o hace falta
   migración? (La migración cuesta más pero evita perder carreras.)
2. **Fase 4 (entrar al campeonato):** cuánto presupuesto y reputación se pierde al pagar a la
   confederación, y qué pasa con la plantilla del club reemplazado. Puedo proponer cifras.
3. **Modo «saltar» de desarrollo** para pruebas: ¿lo dejo oculto?
4. **Monumentos y banderas de Wikipedia:** la red de este entorno bloquea Wikimedia. Hay que
   abrir el acceso (como hiciste con Drive) o aportar las imágenes. Las banderas pueden
   dibujarse por código; los monumentos son fotos y necesitan licencia libre y atribución.
5. **Limpieza:** ¿quito `entregas/` del repo, agrupo las capturas y mueves tú los informes
   extraídos? ¿Hacemos ya la reescritura de la historia, antes de la fase 1?
6. **LFS:** ¿se acepta (como ya está configurado) o se quita?
7. **Regla de líneas** de la sección 1: ¿la aceptas?
8. **Azure y Foundry:** si vas a usar el crédito, cuándo empezamos; este plan encaja bien en
   30 días solo si se hace por fases.
