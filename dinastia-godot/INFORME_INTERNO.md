# INFORME INTERNO DE AUDITORÍA — Dinastía

Documento de trabajo (no para publicar). Se actualiza en cada pasada de auditoría.
**Los 442 puntos de mejora, uno por uno, están en `INFORME_MEJORAS.md`** (este documento tiene
los hallazgos medidos y los errores).

Regla del usuario (14-10-2026): **los errores se arreglan; los puntos de mejora se
registran** aquí con *qué falta* y *cómo solucionarlo*.

- Pasada 1: 14-10-2026 (esta versión). Pasada 2: ver §14 (hallazgos nuevos).
- Todo lo que dice «medido» sale de una herramienta del repositorio (se puede repetir:
  ver §15). Lo que dice «estimado» o «revisión visual» no es una medición.
- Decisión del usuario: **los patrocinadores son los inventados** (marcas ficticias).
  No es un defecto que no coincidan con los del club real; lo que se audita es que sean
  coherentes y estén bien repartidos (§5).

Leyenda de estado: ✅ arreglado · 🟡 parcial · 🔴 abierto · 💡 mejora registrada.
Prioridad: P0 rompe algo · P1 se nota mucho · P2 pulido · P3 futuro.

---

## 1. Resumen ejecutivo

1. **Los datos están limpios**: 0 hallazgos de integridad en 384 clubes / 9.600 jugadores
   en las dos bases (ids únicos, medias, edades, colores, dorsales, porteros, ligas pares).
2. **El banco termina en «FIN. 0 fallos»** con todo lo de hoy. Se corrigieron 3 errores
   reales encontrados auditando (E-01, E-02, E-03).
3. **Lo más débil hoy** (por impacto): (a) el **exterior de los estadios** (cajas grises
   con torres) y la poca variedad de formas (6); (b) **idiomas**: los 6 idiomas extra no
   tenían las mismas frases (§9; ✅ igualados el 15-10, con prueba en el banco); (c) **rendimiento no demostrado** sin GPU real (§8);
   (d) **sesgo de local** en el motor de partido (§6); (e) **patrocinio** concentrado en
   4 marcas y 16 % de clubes grandes sin camiseta patrocinada (§5); (f) **plantillas
   idénticas en tamaño** (25 en todos los clubes).
4. **Lo que ya respeta al club real** (medido): estadio con la arquitectura del real 46 %,
   colores propios de butacas 12 % (47 estadios), rasgos del escudo real 7 % (26 clubes),
   foto real de equipación 37 % (solo base real), plantilla fija 51 %, retrato real 13 %
   de los jugadores (solo base real; 383 de 384 clubes tienen ≥ 11).

---

## 2. Cifras del proyecto (medido)

| Dato | Valor |
|---|---|
| Scripts GDScript | 594 · 149.774 líneas |
| Archivos de `pruebas/` | 342 (14 `prueba_*`, 242 `captura_*`, sondas y auditorías) |
| Archivo más grande | `pruebas/banco.gd` 8.029 líneas; en juego: `ui/principal.gd` 6.655 |
| Funciones > 120 líneas (fuera de pruebas) | 64 (la mayor: `Sonido._sintetizar` 1.000; `Principal._conectar_noticias` 543; `Mundo.avanzar_semana` 532) |
| Marcadores `TODO/FIXME/HACK` reales | 0 (el «65» de la primera versión eran palabras «todo» en español) |
| `print()` fuera de pruebas | 16 |
| Referencias `res://` a recursos que no existen (código de juego) | **0** (de 1.138) |
| Assets | 260 MB (`assets/`) + 230 MB (`recursos/`), 200 `.glb` |
| Clubes / jugadores | 384 / 9.600 (23 países, 16 clubes por liga; Chile 32) |
| Repositorio | `.git` 5,5 GB; 17.549 archivos seguidos (2,65 GB); varios `.zip/.mp4` antiguos son punteros LFS (§11) |

---

## 3. Clubes: qué se respeta de cada club (medido por club)

Fuente: `pruebas/auditoria_clubes.tscn` → `AUDITORIA_CLUBES.csv` (una fila por club y
base) y `AUDITORIA_CLUBES.md`.

| Aspecto | Base ficticia | Base real |
|---|---|---|
| Estadio con la arquitectura del real | 176 (46 %) | 172 → **176 tras E-03** |
| Estadio con colores propios de butacas | 47 (12 %) | 46 → 47 tras E-03 |
| Escudo con los colores del club | 384 (100 %) | 384 |
| Escudo con rasgos del escudo real | 26 (7 %) | 26 |
| Camiseta con foto real de equipación | 0 | 141 (37 %) |
| Camiseta con diseño propio (no liso) | 350 (91 %) | 350 |
| Con patrocinador en la camiseta | 323 (84 %) | 323 |
| Plantilla fija (≥ 11 jugadores reales) | 195 (51 %) | 195 |
| Jugadores con retrato real | 0 | 1.242 de 9.600 (13 %) |

Hallazgos:

- **C-01 (P1, 💡) Estadio real solo en 46 % de los clubes.** El resto usa 16 estilos
  genéricos (`EST_PRESETS`). *Qué falta*: arquitectura para los otros 208 clubes (casi
  todos inventados sin real equivalente). *Cómo*: ampliar `herramientas/estadios_reales.py`
  con los clubes reales que faltan y, para los inventados, derivar el estilo de su
  *ciudad/país* (altura, clima, estadio típico) en lugar de solo del hash.
- **C-02 (P1, 🟡) Colores de estadio** solo en 47. *Cómo*: ampliar `ASIENTOS` (misma
  tabla) con más estadios; para el resto el uniforme es una aproximación válida. Además
  añadir `cespedTono` y color de pista/vallas/techo por estadio real.
- **C-03 (P1, 🟡) Escudos**: 26 con rasgos reales y **11 con la misma forma+patrón**
  («círculo con aro» en 8 clubes por mis asignaciones de hoy). 188 combinaciones
  distintas para 384 clubes. *Cómo*: (1) diferenciar los 8 «círculo con aro» (forma u
  ornamento distintos); (2) ampliar `ESCUDOS` a los ~100 clubes más reconocibles;
  (3) añadir elementos reconocibles (estrellas, corona, ave, león) como símbolos
  dibujados, no solo emoji; (4) revisar que cada escudo sea legible a 24 px.
- **C-04 (P1, 🔴→✅ parcial) Camiseta con diseño propio 91 %**, pero el diseño sale del
  hash, **no se parece a la camiseta real** salvo en el 37 % con foto (solo base real).
  *Cómo*: tabla `camiseta` por club real (River: banda diagonal; Boca: franja horizontal;
  Barça/Atlético/Milan/Juve: rayas verticales; Flamengo: aros…) dentro de
  `ESTADIO_CLUB`, leída por `DisenosKit.kit_de_club` (igual que `escudo`).
- **C-05 (P2, 🔴) Plantilla de 25 en los 384 clubes.** Real: 22–32. *Cómo*: variar
  23–30 según reputación y cantera; ajustar los chequeos que asuman 25.
- **C-06 (P2, 🔴) 34 clubes con camiseta «lisa»** (9 %). Aceptable, pero 12 diseños
  repartidos casi uniformes (30–36 clubes cada uno) no reflejan que la mayoría de
  equipos reales son lisos o con rayas. *Cómo*: pesos por diseño (liso/rayas/aros más
  frecuentes; arlequín/degradé raros).
- **C-07 (P2, 🔴) Retratos reales**: en la base real, 13 % de los jugadores; los demás
  usan recreación/biblioteca. *Cómo*: continuar `caras_reales_faltantes.py` (red del
  entorno bloquea Wikimedia: pedir permiso de red).
- **C-08 (P2, 💡) Foto real de equipación solo si hay pack real**: la base pública
  (ficticia) **nunca** la tiene (decisión legal correcta). Pendiente que el diseño
  procedural se acerque lo suficiente (C-04).

---

## 4. Estadios

- **S-01 (P0/P1, 🔴) Exterior «falso».** Capturas `estadio_real_*.png`: por fuera cada
  estadio es una caja gris con cuatro torres y un bloque; no hay fachada, rampas,
  accesos, techo visible ni entorno. *Cómo*: fachada por `fachada` (hormigón, ladrillo,
  metal, vidrio, membrana — ya está en los datos y no se dibuja con detalle), arcos de
  entrada, rampas helicoidales, carteles, árboles y aparcamiento; techo visto desde
  fuera; usar piezas Kenney (`kenney_comercial_extra`) para el entorno.
- **S-02 (P1, 🟡) Pocas formas**: 6 (`rect` 104, `oval` 90, `cuenco` 81, `ingles` 47,
  `herradura` 40, `caldera` 22) para 384 clubes. *Cómo*: añadir formas (esquinas
  abiertas, una sola grada, anfiteatro en ladera, doble anillo), y parámetros continuos
  (pendiente de gradas, profundidad, altura de techo) por club.
- **S-03 (P1, ✅ parcial) Público**: ahora personas reales en TODAS las filas (3 niveles
  de detalle, 8 poses sentadas). Pendiente: ropa/pelo propios por hincha, bufandas y
  banderas, torcidas con movimiento coordinado, personas del club/ciudad en primeras filas.
- **S-04 (P2, ✅) Colores de butacas del estadio real** en 47 estadios (E-03 los hace
  llegar también a 4 más de la base real).
- **S-05 (P2, 💡) Estadio vacío/lleno**: la ocupación sale de la reputación pero no hay
  filas vacías «de verdad» por asistencia (se ve siempre casi lleno). *Cómo*: densidad
  por sector según asistencia real del partido.
- **S-06 (P2, 💡) Variedad de césped y pintura de campo** por estadio real (12 dibujos ya
  existen; asignarlos por club real).

---

## 5. Camisetas, escudos y patrocinadores (medido + revisión visual)

- **K-01 (✅) Escudo del club en la camiseta 3D** (antes: escudete genérico). Uniform
  `escudo_tex` en `equipacion_q.gdshader`; probado con 8 clubes
  (`pruebas/captura_camisetas_3d_clubes.tscn`). 💡 Mejora: escudo más grande y con
  relieve/bordado (normal map), y que se vea desde la cámara de TV (hoy mide ~8 cm).
- **K-02 (✅) Camiseta con volumen en retratos** (ropa «Peasant» separada). 🟡 En
  partido sigue pintada. *Cómo*: activar `VestidorQ.ropa_aparte` solo en planos de
  cámara cercana (ceremonia, goles, repeticiones) o por LOD; medir coste.
- **K-03 (P1, 🔴) Patrocinio concentrado.** Solo **30 marcas distintas**; 4 de ellas
  (Lácteos del Sur 68, Yerba Mate El Sapo 68, Cripto Winner 67, Barbería Los Bigotes 65)
  cubren más de la mitad. *Cómo*: subir a 60–80 marcas inventadas con logotipo propio,
  reparto por *categoría* (banca, bebida, aerolínea, tecnología) según reputación y país.
- **K-04 (P1, 🔴) 61 clubes (16 %) sin patrocinador en el pecho**, con reputación media
  72: un club grande sin patrocinio no es creíble. *Cómo*: en `SponsorKit.de_club`,
  `pecho` siempre para `rep ≥ 70` (y probabilidad alta bajo 70).
- **K-05 (P2, 💡) Fabricante de ropa**: hoy es un «tick» genérico; añadir 6–8 marcas
  inventadas (cada club con la suya) para que la camiseta tenga identidad.
- **K-06 (P2, 💡) Tercera equipación y portero**: el portero elige color por contraste
  (bien); falta tercera camiseta cuando chocan las dos primeras (hay inversión simple).
- **K-07 (P2, 🟡) Textura de tela**: la camiseta pintada no tiene normal map de tejido
  ni arrugas; solo `RopaSeparada` da volumen. *Cómo*: normal map de tela + AO bakeado.

---

## 6. Partido (motor real, física, cámara)

Medido con `pruebas/sonda_motor_dt.tscn` y `sonda_fisica_partido.tscn`:

| Sonda | Resultado |
|---|---|
| Calidad (N=4) | mejor de local 1,75–1,00 (tiros 9,8–4,8); peor de local 0,50–4,25 → **gana el mejor** |
| Táctica (N=3) | ofensiva 1,67–0,33 (tiros 7,0–2,3); defensiva 1,00–0,67 (tiros 2,7–12,3) → **la pizarra cambia los tiros** |
| Simetría (N=6, mismo once) | **2,00–1,33 a favor del local** |
| Física (240 fotogramas) | solapes 0,12 %; balón hundido 0; balón atravesando cuerpo 0; **68 teletransportes** del balón y 465 giros > 720°/s |

- **M-01 (P1, 🔴) Sesgo de local**: con el mismo once a los dos lados el local mete
  +0,67 goles y +1,6 tiros (N pequeña, pero repetido en táctica: 2,33–0,33 con pizarras
  iguales). *Cómo*: ampliar la sonda (N ≥ 30, semillas distintas); revisar
  `_orientar_formaciones`, el saque inicial (¿siempre saca el local?) y la posición de la
  cámara/césped que favorezca el sentido de ataque; luego calibrar con ventaja de campo
  explícita (≈ +0,2 goles) y no implícita.
- **M-02 (P1, 🔴) Teletransportes y giros bruscos**: los 68 «saltos» del balón y los giros
  de 720°/s suelen ser reposiciones (saque de centro, gol) mezcladas con movimiento real.
  *Cómo*: que la sonda excluya los fotogramas de estado `gol/saque`; limitar giro por
  fotograma en `_aplicar_movimiento` (inercia angular) y suavizar el cambio de objetivo.
- **M-03 (P1, 🔴) Duelos sin consecuencias**: las entradas son animaciones; no hay
  contacto con empuje, faltas por contacto real ni balón dividido. *Cómo*: zona de
  contacto (círculo de 0,8 m), probabilidad de pérdida por fuerza/agilidad, falta si la
  entrada llega por detrás.
- **M-04 (P2, 💡) IA**: apoyos y marcaje correctos pero sin *trampa de fuera de juego* de
  la línea defensiva, ni coberturas, ni basculación del bloque. *Cómo*: nivel de línea
  (`tactica.linea`) que sube/baja con el balón; defensores comparten la misma Z.
- **M-05 (P1, ✅ parcial) VAR**: 1 de 5 goles se revisa en la sala y el partido se
  pausa. **Siempre confirma**: *Cómo*: decidir antes de contar el gol (fuera de juego,
  mano, falta previa) con 8–10 % de anulación y rehacer marcador/estadísticas.
- **M-06 (P2, ✅) Cámara**: sacudida y golpe de zoom (gol, tarjeta, remate); botines
  distintos; celebración: el goleador la hace por su rasgo, los compañeros que están a
  < 34 m corren a abrazarlo, el rival lamenta (40 %). 💡 Falta que la cámara TV haga
  zoom automático al área (planeado en la línea de «cámara inteligente»).
- **M-07 (P2, 💡) Ritmo**: FC 26 ≈ 11 s/s frente a ≈ 54 s/s nuestro a ×1
  (`COMPARACION_FC26_VIDEO.md`). Hay preset de ritmo (corto/normal/largo); falta el
  preset «Realista» y reducir cinemáticas al 16 %.

---

## 7. Ciudad, vehículos y menús

- **V-01 (✅) Conducción**: curva de potencia, freno, marcha atrás, freno de mano,
  inclinación, cámaras de capó e interior (volante 2D). 💡 Falta interior modelado,
  sonido de motor por marchas, daños y colisiones con NPC/vehículos con física real.
- **V-02 (🟡) Carretera Kenney**: solo accesorios (farolas, postes, carteles, obras).
  *Cómo*: probar losetas (`road-*`) en una calle de prueba con semáforos desactivados y
  luego sustituir calzadas por tramos; rotondas (`road-roundabout`).
- **V-03 (✅) Menús Ciudad 3D y Editar** completos; 💡 Falta que cada tarjeta muestre un
  dato vivo (hora de la ciudad, tráfico, nivel de obras) como las otras.
- **V-04 (✅) Fondo del menú Ciudad** nuevo (cielo, luna, tres capas de edificios, tráfico).
- **V-05 (P2, 💡) Minijuegos**: +2 (Malabares, Reflejos). Falta variedad 3D y tabla de
  récords compartida; el bot de prueba del vídeo no es jugable en móvil (táctil).
- **V-06 (P2, 💡) Sin pruebas automáticas de conducción ni de ciudad**: solo capturas.
  *Cómo*: `prueba_conduccion` (aceleración, frenada, colisión) en headless.

---

## 8. Rendimiento

- Medido (`pruebas/medir_partido.tscn`, ALTO, llvmpipe): ≈ 2,3–2,4 M triángulos,
  ≈ 700 llamadas de dibujo, 830 objetos. En un servidor sin GPU los milisegundos no son
  comparables; **no se puede afirmar un FPS real ni el −50 %** que pidió el usuario.
- Probado: bajar cortes/distancia de sombra → sin cambio en el contador (revertido).
  El público real subió el coste (+20 %) y se compensó (ahora ≈ +8 %).
- **R-01 (P0, 🔴) Falta un perfil con GPU real o hardware bajo.** *Cómo*: ejecutar
  `medir_partido` y `diagnostico_fps_partido` en la máquina del usuario (gama baja) y
  guardar los resultados en `ETAPAS_FINALES.md`; decidir C#/GDExtension solo si el CPU
  domina (`TIME_PROCESS`).
- **R-02 (P1, 💡) Candidatos medidos por el árbol de nodos** (`ARBOL=1`, lectura ruidosa):
  césped en capas (≈ 230 k tris/57 llamadas), jugadores con pelo/pestañas, grada.
  *Cómo*: LOD por distancia en jugadores (malla de 2.000 tris a > 40 m), apagar
  pestañas/cejas lejos, instanciar pelos con MultiMesh, fusionar mallas estáticas de la
  grada por sector (culling por trozos).
- **R-03 (P2, 💡) Funciones enormes** (§12) con coste de CPU en `_process`: medir con
  el profiler antes de tocar.

---

## 9. Idiomas

Medido el día del informe (solo `datos/idiomas_extra.json`):

| Idioma | Frases | Faltan respecto a la unión (1.699) |
|---|---|---|
| en, pt | 1.531 | 168 |
| fr, it, de, ca | 1.402 | 297 |
| pl, tr | 1.699 | 0 |

**Remedido el 15-10-2026 con TODOS los catálogos** que usa `Idiomas.t`: la tabla del
esqueleto (`Idiomas.TABLA`, 309 filas con columna para en…ca), `idiomas_extra.json`
(con los diálogos de la ciudad que mete `herramientas/dialogos_ciudad.py`), las
directas y los patrones de la narración (`datos/narracion.json`) y los patrones
numéricos. Contar solo `idiomas_extra.json` engañaba: a en/pt «les faltaban» las
filas que tienen en `TABLA`, y a fr…tr los titulares con icono que ya estaban en
la narración. La diferencia REAL era menor:

| Catálogo | Frases castellanas | Faltaban (antes) | Faltan (ahora) |
|---|---|---|---|
| Frases fijas (unión de TABLA + extra + narración) | 2.573 → 2.574 | fr/it/de/ca/pl/tr: **36** cada uno; en/pt: 0 | **0** en los 8 |
| Patrones (`idiomas_extra` 58 + narración 313 → 315) | 371 → 373 | fr/it/de/ca/pl/tr: **2** cada uno | **0** |
| Narración, plantillas del extractor (1.104) | — | **17** «sin traducir» en los 8 (`montar_narracion.py`) | **0** (2 reales traducidas, 15 que no se muestran o son nombres propios, ahora declaradas) |
| `Idiomas.t("…")` escritas en el código | 258 | 0 | 0 |
| Diálogos de vecinos (`DialogosCiudad`) | 72 | 0 | 0 |

- **I-01 (✅ 15-10) Los idiomas tienen las mismas frases.** Lo que faltaba: 36 títulos de
  evento SIN icono («Asado del club», «Moción de censura», «Tope salarial»,
  «Representantes»…; con icono ya estaban en la narración, pero `t()` busca también la
  forma sin icono), los patrones «Representantes: …» y «… cuelga las botas…», y en la
  narración «{1} {2} (moral %+d).» (el extractor no entendía `%+d`) y «Colonia {1} {2}».
  Traducido a los 8 idiomas; «Terapia deportiva» añadida para los gastos (se traduce por
  tramos « · »). **Prueba**: `_probar_paridad_idiomas` en el banco falla si un idioma
  tiene menos frases que la unión castellana, si un patrón no tiene plantilla en los 8,
  si una frase de `Idiomas.t("…")` del código queda sin traducir (M-446) o si una
  traducción pierde un `%s`/`%d`; con los datos de antes daba 7 fallos.
  Queda (no es paridad): revisión nativa (M-332) y los textos escritos sin `Idiomas.t`
  (I-02).
- **I-02 (P1, 🟡 casi cerrado, 15-10) Textos en español escritos directamente en `ui/` y `visor/`.**
  *Antes*: 573 líneas `.text = "…"` con tilde sin `Idiomas.t` en `ui/` (con el criterio ampliado
  —`text`, `tooltip_text`, `placeholder_text`, `title`, `dialog_text`, `_boton/_dato/Tema.rotulo/
  add_item`— 1.136 líneas en `ui/`+`visor/`); 1.071 textos distintos, de los que **732 no tenían
  traducción** en algún idioma (721 en ninguno). La cifra de 274 era la de una medición anterior.
  *Hecho*: 1.132 textos envueltos en `Idiomas.t(…)` en 64 archivos (las plantillas con `%s/%d` se
  traducen enteras: `Idiomas.t("Jornada %d") % n`), y **746 frases nuevas × 8 idiomas** en
  `datos/idiomas_extra.json` (se comprobó el orden de los marcadores `%s/%d/%.1f/%%` en cada una).
  Los plurales «semana%s», «punto%s», «jugador%s»… pasaron a dos frases (singular/plural), que en
  castellano se leen igual. *Después*: con el criterio del informe quedan 86 líneas y con el
  ampliado 146; casi todas son datos (`String(dic["nombre"])`, titulares, nombres de clubes) que
  pasan por el traductor de pantalla o la narración, no textos fijos. `_probar_paridad_idiomas`:
  1.338 frases de `Idiomas.t("…")` en el código, 0 sin traducir.
  *Pendiente*: 15 textos fijos en archivos que otras sesiones estaban tocando (`ui/ciudad_vista.gd`
  8, `ui/componentes/interior_instalacion.gd` 3, `visor/metro_ciudad.gd` 3,
  `visor/ciudad_expansion.gd` 1); `visor/explorador_ciudad.gd:856` («E: hablar con %s») no se
  envolvió porque la línea 1423 compara `_aviso.text.begins_with("E: hablar")` (las líneas 810 y
  1418 ya salen traducidas, así que esa comparación falla fuera del castellano: bug aparte); y
  `principal.gd:3575` compara una etiqueta con «FICHA DEL JUGADOR» (mismo problema si el
  traductor de pantalla la cambia).
- **I-03 (✅) Menús nuevos y minijuegos** de hoy traducidos en 8 idiomas.
- **I-04 (P2, 🔴) `CLAUDE.md` dice «1.402 frases cada idioma»**: ya no es cierto
  (ver tabla); I-01 está resuelta: la cifra real es 2.574 frases fijas + 373 patrones
  en cada uno de los 8 idiomas. Falta cambiar la línea de `CLAUDE.md` (memoria del
  usuario: se deja a la sesión principal).

---

## 10. Jugadores y caras

- **J-01 (✅) Todo retrato es el modelo 3D** (`Retrato3D`), con su camiseta, ahora con
  escudo y volumen; en `--headless` se usa el retrato 2D (sin pantalla no se puede
  renderizar) → las pruebas no ejercitan `Retrato3D` (💡 añadir prueba con pantalla en
  CI visual).
- **J-02 (P2, 🔴) Retrato real 13 %** (ver C-07) y fotos agachadas aún oscuras.
- **J-03 (P2, 💡) Variación de cuerpo**: todos los futbolistas comparten el mismo
  esqueleto/musculatura «superhéroe»; `BASE_ESBELTA` existe solo para el DT/civiles.
  *Cómo*: 3–4 somatotipos por puesto (portero alto, extremo ligero, central ancho).
- **J-04 (P2, ✅) Nombre ↔ cara ↔ ficha** correspondientes (mismo `id`, mismo
  `Puente3D.jugador`); hay prueba de caras por lotes (`auditoria_caras.py`).

---

## 11. Datos y repositorio

- **D-01 (✅) Integridad de datos**: 0 hallazgos (`pruebas/auditoria_datos.tscn`).
- **D-02 (E-03 ✅) Cuatro clubes de la base real sin su estadio** por claves con y sin
  cubierta de leetspeak.
- **D-03 (P1, 🔴) `.git` pesa 5,5 GB**: hay punteros LFS antiguos (zips de 130–300 MB,
  `marca/*.mp4`, `entregas/*.zip` con `index.wasm` de 38 MB). La regla actual prohíbe
  subir LFS, pero la historia ya lo tiene. *Cómo*: decisión del dueño (reescribir
  historia con `git filter-repo` o mantener); mientras, no clonar con LFS en la nube.
- **D-04 (P2, 💡) `tablas.json` se reescribe entero en cada parche** (una sola línea de
  521 kB): los diffs son ilegibles. *Cómo*: guardarlo con una clave por línea
  (`indent`) y ordenar claves; o dividir por tabla.
- **D-05 (P2, 💡) `AUDITORIA_CLUBES.csv` (100 kB)** se versiona: regenerarlo en CI en vez
  de subirlo cada vez.

---

## 12. Calidad de código

- **Q-01 (P2, 💡) 64 funciones de más de 120 líneas** (§2). *Cómo*: partir las que
  corren cada fotograma o cada semana (`Mundo.avanzar_semana`, `Principal._construir`)
  en pasos con nombre; `Sonido._sintetizar` (1.000 líneas) en una tabla de efectos.
- **Q-02 (P2, 💡) `pruebas/banco.gd` 8.029 líneas en un solo archivo**: un error de
  sintaxis lo deja colgado (ver CLAUDE.md). *Cómo*: dividir por tandas con un
  `banco.sh` que compruebe la sintaxis (`--check-only`) antes de lanzar.
- **Q-03 (P2, 🔴) 16 `print()` fuera de pruebas**: sustituir por un registro con niveles. (No hay `TODO` reales.)
- **Q-04 (P2, 💡) Sin análisis estático**: añadir `gdlint`/`gdformat` al flujo.
- **Q-05 (P1, ✅) Avisos del banco**: ver E-01 y E-02.

---

## 13. Errores encontrados (pasada 1) y estado

| Id | Gravedad | Dónde | Qué pasaba | Estado |
|---|---|---|---|---|
| E-01 | P2 | `casa_escena3d._cortar` | `look_at` con la escena aún fuera del árbol → 5 `ERROR: Node not inside tree` en el banco | ✅ `look_at_from_position` |
| E-02 | P3 | `casa_escena3d._dt` | `add_child` del móvil con `owner` del `.glb` → 5 avisos «owner inconsistent» | ✅ `owner = null` antes de re-colgar |
| E-03 | P1 | `Club.perfil_estadio` | 4 clubes de la base real (Audax Italiano, D. Iquique, Osasuna, Orlando Pirates) perdían estadio real, colores y escudo por clave sin leetspeak | ✅ `Club.fila_estadio_real()` busca también por nombre limpio |
| E-04 | P1 | `banco.gd` | el test «butacas de un rival = colores del club» fallaba con los colores propios de estadio | ✅ test actualizado |
| E-05 | P2 | `auditoria_clubes.gd` | el formato `%` en una cabecera Markdown rompía el informe | ✅ |

---

## 14. Pasadas 2 y 3 (nuevas auditorías) — hallazgos

**Pasada 2 (prueba larga y datos).** `prueba_larga` (10 temporadas × 3 semillas, 218 s):
0 errores. `auditoria_datos`: 0 hallazgos. Sondas del motor: ver §6.

**Pasada 3 (14-10-2026, «dale auditoría»).** Herramientas nuevas:
`pruebas/auditoria_tecnica.tscn` (shaders, escenas, nodos huérfanos) y la comprobación
estática «claves de `Idiomas.t` sin traducción».

| Id | Gravedad | Hallazgo | Estado |
|---|---|---|---|
| E-06 | P1 | **69 textos con `Idiomas.t` sin traducción en NINGÚN idioma**: la pantalla de controles (manual, ayudas, filigranas, diálogos de guardar), el panel de táctica y cambios, la ceremonia («En vivo desde», «Cualquier tecla para saltar»), la carta del goleador (GOLES/TIROS), la galería del club y el tutorial de la ciudad salían en español en los 8 idiomas | ✅ 69 × 8 idiomas = 552 traducciones añadidas |
| E-07 | P2 | `prueba_intro` obsoleta: desde el 13-10 la **ceremonia** sustituye al vuelo corto, así que «arranca la presentación» fallaba | ✅ la prueba apaga la ceremonia mientras corre (no verificada de extremo a extremo: tarda > 7 min en software) |
| E-08 | P2 | `prueba_regates` obsoleta: miraba a `MatchPlayback` (que con el motor real no mueve a nadie) y la ceremonia retenía el partido | ✅ ahora mira a `MotorJugable` y apaga la ceremonia: «conduce con el mocap de regate» pasa (198 fotogramas) |
| E-09 | P2 | `prueba_repeticion` obsoleta (4,2 s grabados por la ceremonia) y con `resize` sobre imagen nula en `--headless` | ✅ ceremonia apagada y guarda contra imagen nula (no verificada, lenta) |
| E-10 | P3 | Las pruebas que apagan la ceremonia escriben en `user://ajustes.cfg`: si se matan a medias (timeout) el ajuste queda en `false` (me pasó una vez y lo restauré) | 🟡 ver M-455 (config de pruebas aparte) |
| H-11 | P1 | **La IA no amaga**: 0 fintas en un partido de prueba completo; la condición exige un rival a < 1,8 m y llega tarde en la cadena de decisiones | 🔴 registrado como M-443; la prueba lo avisa («AVISO») en vez de fallar |
| H-12 | P3 | `prueba_carrera_flujo` termina con «Texture with GL ID … leaked» (≈ 350 kB × 2) al cerrar | 🔴 M-444 |
| H-13 | P3 | `prueba_descanso_3d` se cuelga en `--headless` (necesita pantalla) y `prueba_intro/regates/repeticion` no caben en 5 min con render por software | 🔴 M-445 |
| H-14 | — | Sin hallazgos: 19 shaders cargan, 0 nodos huérfanos tras 3 aperturas/cierres de la pantalla principal, 0 avisos/errores en un partido real con gol | ✅ |

Estado de las 14 pruebas sueltas (`prueba_*`) tras la pasada: ✅ `modos`, `motor_jugable`,
`partido_motor`, `control_equipo`, `dominadas`, `ciudad_modelos`, `menu_ciudad_pie`,
`minijuegos_nuevos`, `carrera_flujo` (con la fuga GL al salir), `larga`; 🟡 `regates`
(pasa conducir y dominadas; el amague queda como aviso); ⚠ sin verificar por lentitud:
`intro`, `repeticion`; ⚠ `descanso_3d` (cuelga en headless).

---

## 15. Cómo repetir cada medición

| Qué | Comando |
|---|---|
| Banco | `bash herramientas/banco.sh` (solo, sin otras pruebas) |
| Clubes (md+csv) | `godot --headless --path . res://pruebas/auditoria_clubes.tscn` |
| Integridad de datos | `godot --headless --path . res://pruebas/auditoria_datos.tscn` |
| Motor de partido | `ESCENARIO=calidad|tactica|cambios|simetria N=4 godot --headless --path . res://pruebas/sonda_motor_dt.tscn` |
| Física del partido | `FOTOGRAMAS=240 xvfb-run … res://pruebas/sonda_fisica_partido.tscn` |
| Coste de render | `xvfb-run … --rendering-driver vulkan res://pruebas/medir_partido.tscn -- alto` |
| Camisetas 3D de 8 clubes | `captura_camisetas_3d_clubes.tscn` (APARTE=1 para ropa con volumen) |
| Hoja de camisetas y escudos 2D | `captura_camisetas_escudos.tscn` |
| Público (poses) | `captura_poses_publico.tscn`, `captura_publico_real.tscn` |
| Conducción | `captura_conduccion.tscn` |
| Menús | `captura_menu_lateral.tscn` |
| Estadios reales | `captura_estadios_reales.tscn` |
