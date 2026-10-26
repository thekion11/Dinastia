# 03 — Propuesta: qué agregar o mejorar en Dinastía (26-10-2026)

Sale de `01_recursos_libres.md` (recursos libres) y `02_otros_juegos.md` (mercado). Es una **propuesta**: el dueño decide qué entra en `docs/PLAN_DEL_LUNES.md`, y no se cambió código.

**Leyenda**
- Prioridad: **alta** bloquea el lanzamiento o la primera impresión; **media** se nota en la primera semana; **baja** es pulido.
- Esfuerzo: **S** es menos de 1 día; **M** de 1 a 5 días; **L** más de una semana.
- «Ya en el plan» remite a la sección donde la idea ya aparece, para no duplicarla. Lo nuevo va marcado ✚.

## A. Para el lanzamiento

| # | Qué | Prioridad | Esfuerzo | Archivo o sistema | Por qué (evidencia) | En el plan |
|---|---|---|---|---|---|---|
| 1 | **Presupuesto de clics**: medir las 10 tareas más frecuentes (once, fichar, renovar, entrenar, avanzar semana, táctica, prensa…) y fijar un tope (≤ 2 clics o 1 atajo) en el PC de la oficina y en el menú central | alta | M | `ui/principal*.gd`, `ui/componentes/menu_lateral.gd`; prueba nueva en `pruebas/` | FM25 se canceló por la interfaz y FM26 cayó al 21-29 % en Steam por «el doble de clics», las ventanas emergentes y la lentitud (02 §1). Pasar el menú central a un PC 3D (§2.1) es justo ese riesgo | ✚ (completa §10 «Onboarding medido») |
| 2 | **Atajos de teclado en todo el menú central**, editables, y una vista «densa» de tablas | alta | M | `ui/principal_p2.gd` (ya lee teclas), `nucleo/mando.gd`, `ui/componentes/panel_controles*.gd` | FM26 tuvo que devolverlos por parche; FM27 los vende como novedad (02 §1) | ✚ (§10 «reasignar teclas» solo cubre accesibilidad) |
| 3 | **Fuentes propias con cobertura completa**: Inter + Noto Emoji + Noto Sans Symbols 2 + Barlow Condensed + Bebas Neue (~4,3 MB, OFL, fuera de LFS) | alta | S | `ui/tema.gd`, `ui/principal_p2.gd:325` (`TIPOGRAFIAS`) y `:337` (`REPUESTO_SIMBOLOS`), `ui/principal_p4.gd` (`_fuente_de`) | Hoy se piden Impact, Arial Narrow y Georgia, y los 1.106 emojis-icono dependen de fuentes del sistema que **no existen en Android ni en Web**. Juntas cubren el 100 % de los caracteres de los 9 idiomas (01 §H) | ✚ |
| 4 | **Explicar el porqué**: tras cada partido, 3 causas (momentum, forma, clima, táctica rival); en finanzas, cada ingreso y gasto con su origen y no el año partido en 12 | alta | M | `nucleo/partido_p1.gd` (momentum, clima), `ui/componentes/resumen_partido.gd`, `nucleo/finanzas.gd`, `ui/componentes/panel_finanzas*.gd` | Top Eleven: «partidos amañados». UPFGM: «finanzas negativas sin explicación» (02 §6, §12). La sesión 2 vio el flujo de caja «casi en rampa» (§9) | parcial (§9 flujo de caja) |
| 5 | **Vida privada regulable**: Ajustes «Vida: completa / ligera / apagada». Ligera = sin hambre ni sueño punitivos; apagada = el PC hace de todo | alta | S | `nucleo/necesidades.gd`, `nucleo/reloj.gd`, `ui/pantallas/pantalla_ajustes*.gd` | We Are Football es el precedente más cercano y la hace **opcional** (02 §10). New Star Soccer recibe críticas por lo repetitivo de la parte de vida (02 §4) | ✚ (cerca de «el bloqueo», §0) |
| 6 | **Hinchada y banquillo animados**: Mesh2Motion (CC0) + plugin VAT (MIT, funciona en Compatibility) | alta | M | `herramientas/hornear_publico.gd`, `visor/stadium_builder_p5.gd`/`p6.gd`, `visor/hinchada.gdshader`, `visor/festejo_grada.gd`, `visor/personaje_dt*.gd` | Lo visible del partido es lo que más castiga el género (WAF, Kicker, 02 §8 y §10). Mismo esqueleto UE5 que ya usamos; funciona en móvil (01 §B-C) | parcial (semana 4 «espectáculo») |
| 7 | **Quitar los 🟡 de licencias** con recursos libres verificados: MPFB2 → `persona_realista.glb`; KayKit City Builder → `complejo_residencial.glb`, `farola.obj`, `estadio.obj`; CMU → tiros y protestas de `anims_futbol/` | alta | M-L | `visor/persona_realista.gd`, `visor/city_builder*.gd`, `visor/anim_futbol*.gd`, `visor/retarget_futbol_q.gd`; `docs/05_referencia/LICENCIAS.md` | Sin esto no se puede vender (LICENCIAS «Pendiente antes de vender» 2-3). `persona_realista` es además el escaneo de una persona real (derecho de imagen) | parcial (§1 «confirmar 🟡») |
| 8 | **CI con Godot 4.7.2**: `barichello/godot-ci:4.7.2-stable` (etiqueta verificada) o `chickensoft-games/setup-godot`, que corra `banco.sh` | alta | S | `.github/workflows/compilar.yml`, `dinastia-godot/herramientas/banco.sh` | Orden del lunes (§1). La imagen 4.3 no abre el proyecto | sí (§1) |
| 9 | **Silbato real y percusión** de VCSL (CC0) como `audio/ui/silbato.ogg` y capas del bombo | alta | S | `nucleo/sonido.gd:20-30` (ya carga `.ogg` si existe), `AJUSTE_DB` | Es el sonido que más se repite en el partido. Entra en la excepción LFS ya autorizada (orden 7) | ✚ |
| 10 | **Registro de errores visible** + «copiar informe» | alta | S | nuevo `user://registro.txt`; `nucleo/partida_archivo.gd` (avisar si el guardado se corrompe) | Soporte que no contesta y errores sin datos (Top Eleven, Anstoss, 02 §6 y §8) | sí (§10) |
| 11 | **Pruebas con 3-5 jugadores ajenos** en la primera hora | alta | S (del dueño) | — | FM25 detectó su problema así (02 §1); Anstoss salió sin hacerlo | sí (§10) |
| 12 | **Monetización: pago único** en PC; en móvil, demo y desbloqueo único (modelo Retro Goal). Nada de monedas premium, esperas ni gacha | alta | — (decisión) | — | Gacha y esperas de pago se castigan siempre: Top Eleven, OSM, eFootball, NSS en Android, Club Soccer Director 3/10. Pago único: Football Chairman 4,7-4,8, New Star Manager en consola (02) | decisión del dueño (§7, 20 decisiones) |
| 13 | **Eventos inesperados con contexto**: catálogo de ~40 (intoxicación, morriña, cambio de dueño, recorte, oferta loca, jugador en la discoteca), cada uno con condiciones («no si está lesionado largo») y efectos que duran | alta | M | ampliar `nucleo/lesiones_absurdas.gd` (57 líneas) a un `nucleo/imprevistos.gd`; llamada en `nucleo/mundo_p5_p2.gd:53` | FC 26 consiguió «un poco de vida» con ~40 eventos, y su queja (el agente que se queja de un lesionado) es justo la falta de contexto (02 §2) | ✚ |
| 14 | **Ocasiones jugables en el partido del DT** (estilo New Star Manager): en las 3-6 llegadas claras, pausa y eliges pase, conducción o tiro con la cámara a pie de campo; el resto se simula | alta | L | `nucleo/partido*.gd` (señales de llegada), `nucleo/motor_libre.gd` (`tomar_control`), `ui/partido_vivo*.gd`, `visor/control_partido.gd` | Es la forma más barata y más querida de unir gestión y juego (New Star Manager ~88 % en Steam, Retro Goal, Soccer Club Life, 02 §4). Las piezas ya existen | ✚ |
| 15 | **Antialiased Line2D + Debug Menu** (MIT, ~220 KB) | media | S | `ui/radar_partido.gd`, `ui/componentes/radar_atributos.gd`, `pizarra_tactica.gd`, `minimapa_ciudad.gd`; `ui/componentes/contador_fps.gd` | Líneas con dientes de sierra en los radares; mejor herramienta para medir FPS en hardware real (M-337) | ✚ |
| 16 | **Ayuda «¿por qué?» en la ficha**: la curva de edad (sube hasta 21-23, baja desde 28-30) y los minutos que necesita para crecer | media | S | `ui/pantallas/pantalla_ficha*.gd`, `nucleo/entrenamiento*.gd` | Hattrick: reglas legibles que se recuerdan 20 años (02 §9) | parcial (§10 «glosario») |
| 17 | **Torneo del modo carrera de jugador más corto**: equilibrar la duración de partido elegible (3, 6, 10 min) con el banco | media | S | `nucleo/carrera_jugador*.gd`, `visor/motor_jugable*.gd` | FTG: marcadores abultados según la duración (02 §11) | ✚ |

## B. Después del lanzamiento

| # | Qué | Prioridad | Esfuerzo | Archivo o sistema | Por qué |
|---|---|---|---|---|---|
| 18 | **Táctica con y sin balón** + roles por jugador + visualizador en la pizarra | alta | L | `nucleo/tactica.gd` (hoy 6 perillas de 3 niveles), `nucleo/roles*.gd`, `ui/componentes/pizarra_tactica.gd`, `nucleo/motor_libre.gd` | Es lo único de FM26 que todos elogian (02 §1). Los roles ya se piden en el plan (§3 «Detectados») |
| 19 | **Mercado de entrenadores**: los clubes de la IA echan y contratan DT; «termómetro de presión» de la liga | media | M | `nucleo/mundo_p7.gd` (cierre de temporada), `nucleo/prensa*.gd` (`ranking_entrenadores`), `nucleo/junta.gd` | FC 26 «Manager Market» (02 §2). No se encontró en el código que los DT de la IA cambien de club: verificar |
| 20 | **Tablón de necesidades de la liga**: cada club publica qué perfil busca y tú ofreces a los tuyos | media | M | `nucleo/mercado*.gd`, `ui/componentes/panel_mercado*.gd` | FM26 Requirements y Pitch Opportunities (02 §1) |
| 21 | **Planificador de plantilla** con avisos de carencias y contratos que vencen en la portada | media | M | nuevo en `ui/pantallas/pantalla_plantel*.gd`; datos en `nucleo/contratos.gd` | FM Squad Planner y el centro de fichajes de FM26 (02 §1); hoy no existe |
| 22 | **Torneo juvenil 5 contra 5** cada dos meses, con el motor 3D | media | M | `nucleo/academia.gd`, `nucleo/cantera*.gd`, `visor/motor_jugable*.gd` | FC 25 Rush; el modo cantera gana un momento jugable (02 §2) |
| 23 | **Charlas con reacción graduada** (leve, media, grave según la personalidad) y **objetivos individuales** por jugador | media | M | `nucleo/charlas.gd`, `nucleo/vestuario*.gd`, `nucleo/jugador.gd` | FM24 (02 §1) |
| 24 | **Retos «¿Y si…?» rotativos sin conexión** (empezar en la jornada 20, 15.º) | media | M | `nucleo/retos.gd` (hoy 5), `ui/entrada/menu_modos_retos.gd` | FC 26 Manager Live; ya en la ruta como «retos semanales» (semana 6) |
| 25 | **Narración con voz pregrabada** (frases cortas por idioma) con Piper, solo voces de linaje limpio | media | M | `nucleo/sonido.gd`, `ui/partido_vivo_p1.gd` (`_escribir`) | Hoy la narración es solo texto. **No hay voz turca apta** (01 §F); la voz del sistema (`DisplayServer.tts_speak`) puede cubrir accesibilidad a coste cero |
| 26 | **Fuentes de datos para el mundo**: CLDR (países en 9 idiomas), Natural Earth y GeoNames (ciudades y regiones), faker (bolsas de nombres) | media | M | `nucleo/regiones.gd` (hoy ESP y EUS), `datos/bolsas_nombres.json`, `ui/entrada/personaje_datos.gd:74`, `herramientas/base_ficticia.py` | Más países jugables sin escribir a mano; reduce las ~506 frases pendientes en nombres de país |
| 27 | **Iconos SVG** (Tabler + Lucide) en lugar de emojis, por pantallas | media | M | 182 archivos con emojis en `ui/` y `visor/` | Se ven igual en todas las plataformas y se tiñen con el tema |
| 28 | **Música con muestras** (Meta Piano CC0) dentro de la composición dinámica | baja | M | `nucleo/musica.gd` (`_nota`) | Sube el timbre sin romper la decisión de «cero ficheros». Hay que preguntar por LFS |
| 29 | Cielo (Sky3D), agua (Foam Water), esparcido (ProtonScatter), carreteras (Road Generator), peatones con Beehave o `NavigationAgent3D` RVO | media | M cada uno | `visor/cielo.gdshader`, `visor/agua.gdshader`, `visor/ciudad_expansion_p5.gd`, `visor/trafico_ciudad*.gd`, `visor/peaton_q.gd` | Semanas 5-6 de la ruta («look GTA» y peatones que esquiven, §8) |
| 30 | **Exportar e importar la partida** (archivo) y que la partida siga entre versiones | media | S | `nucleo/partida_archivo.gd` | Soccer Manager y FM Mobile lo venden; ZenGM lo usa (02 §6, §12). Ya en §10 |
| 31 | **Accesibilidad con lector de pantalla** en los menús | baja | L | `ui/tema.gd`, `ui/componentes/*` | Football Chairman es accesible por completo con VoiceOver (02 §7) |

**No recomendado**
- Multijugador: Anstoss y Sociable Soccer lo prometieron y lo pagaron caro (02 §5 y §8); el plan ya lo deja fuera.
- Servicio en vivo con temporizadores.
- Cartas o gacha.
- Licencias reales: ya resuelto con el pack aparte.

---

## C. 10 ideas que nos harían únicos

Ninguno de los 21 juegos revisados junta gestión de club, vida en una ciudad 3D y partido 3D. Estas ideas exprimen esa mezcla; cada una nombra la pieza del código en que se apoya.

1. **La negociación en persona cambia el resultado y se nota.** En la oficina, el café o el restaurante de la ciudad, el lugar, la hora y tu estado (cansancio por `necesidades.gd`) modifican la oferta. Que se vea en la cifra («+6 % por cerrar en persona»).
   - Base: `nucleo/negociacion.gd`, `nucleo/mesa_agente.gd`, `visor/explorador_ciudad*.gd`; ya en el guion (§2.1, «mejor resultado en 3D»).
2. **La ciudad responde a tus resultados.** Tras ganar el clásico: bocinas, camisetas por la calle, el kiosco con tu portada, gente que te para. Tras una racha mala: pintadas, silbidos al pasar, el taxista que opina.
   - Base: `visor/ciudad_animo.gd`, `ui/componentes/portada_periodico.gd`, `nucleo/hinchada.gd`, `herramientas/dialogos_ciudad.py`.
3. **El vestuario como lugar.** Entras antes del partido y ves quién está aislado, quién bromea, el capitán hablando con el joven. La charla se da en 3D mirando a la cara a quien eliges.
   - Base: `visor/tunel_vestuario.gd`, `nucleo/vestuario*.gd`, `nucleo/charlas.gd`, `visor/expresion.gd`.
4. **Ocasiones jugables a pie de campo para el DT** (fila 14): pausa en la llegada clara, eliges el pase desde la banda con la cámara 3D y lo ves ocurrir. New Star Manager lo hace en 2D; nadie lo hace en 3D con gestión profunda.
5. **Un mismo reloj para todo.** Si te quedas en la oficina hasta las 23:00 preparando el partido, el plan sale mejor, pero llegas cansado a la rueda de prensa del día siguiente. La disyuntiva tiempo-vida-club que ningún FM tiene.
   - Base: `nucleo/reloj.gd`, `nucleo/necesidades.gd`, `nucleo/carrera_jugador_agenda.gd`.
6. **Dinastía de verdad: generaciones.** Retirarte y seguir como presidente, o que tu hijo o tu canterano estrella sea DT. La sala de trofeos y el documental heredan la historia familiar.
   - Base: `nucleo/meta.gd`, `nucleo/historia_club.gd`, `ui/componentes/documental_temporada.gd`, `ui/pantallas/pantalla_legado*.gd`, `nucleo/roles*.gd` (dueño y fondo). El nombre del juego lo pide.
7. **La prensa con memoria y humor.** Los periodistas recuerdan lo que dijiste («en agosto prometió el título») y te lo sacan en la rueda de prensa 3D. Los periódicos del kiosco recogen escándalos con tono satírico, como New Star Soccer, pero ligados a frases tuyas reales.
   - Base: `nucleo/prensa*.gd` (8 capas), `ui/rueda_prensa_escena3d*.gd`.
8. **Tu móvil es la interfaz rápida.** Contestar al agente, aceptar una oferta o mirar el once desde cualquier sitio de la ciudad sin volver al PC. Resuelve el riesgo de clics del menú central en 3D (fila 1) y es nativo del concepto.
   - Base: `nucleo/movil.gd`, `ui/componentes/telefono*.gd`, `ui/componentes/movil_mano.gd`.
9. **La hinchada como personaje colectivo.** Una peña con nombre y líder que te pide cosas (bajar el precio, fichar al ídolo local, no vender al capitán). Si cumples, el tifo en la grada lleva tu cara; si no, la pancarta es contra ti. Se ve en el estadio 3D.
   - Base: `nucleo/hinchada.gd`, `visor/festejo_grada.gd`, `visor/ola_grada.gd`, `visor/vallas_led.gd`.
10. **El mundo político y de barrio ficticio pesa en el club.** El alcalde (ficticio) recalifica el terreno del estadio nuevo a cambio de apoyo en las elecciones; el barrio protesta por el tráfico de los días de partido. Decisiones con coste moral, siempre con política ficticia (regla del proyecto).
   - Base: `nucleo/politica.gd`, `nucleo/leyes_pais.gd`, `nucleo/estadio_propio*.gd`, `nucleo/junta.gd`.

## D. Lo que se recomienda al dueño decidir primero

1. Pasar las filas 1-14 (o las que elija) a `docs/PLAN_DEL_LUNES.md` como tareas.
2. **Monetización** (fila 12): pago único.
3. **Banderas detalladas** (flag-icons, MIT) o seguir con las dibujadas (`visor/banderas.gd` dice «sin símbolos oficiales detallados»).
4. **LFS** para música con muestras, sonidos fuera de `audio/ui/` y modelos nuevos `.glb`: hoy fallan las subidas desde el contenedor (orden 7).
5. Voz: si se quiere narración hablada, aceptar que el turco quede sin voz o con la del sistema.

Fuentes: las de `01_recursos_libres.md` y `02_otros_juegos.md`.
