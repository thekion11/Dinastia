# EL GUION FRENTE AL CÓDIGO (auditoría del 28-10-2026)

Comprobación punto por punto de `PLAN_DEL_LUNES.md` §2 (fases 0-6 y diseños 2.2b-2.2h) contra el código. Hecho por el líder al cierre; lo que falta está también resumido en el plan, §2.5.


Fecha: 28-10-2026. Método: para cada punto del guion se buscó el código (rg en `nucleo/`, `ui/`, `visor/`,
`escenas/`, `pruebas/`) y se comprobó que está enganchado al flujo real del jugador (una pantalla o escena que el
juego abre), no solo a una prueba. Rutas relativas a `dinastia-godot/`. Los «límites honestos» que cada diseño
declara fuera de alcance se anotan como tales y no cuentan como fallo, salvo que el guion original los exigiera.

Leyenda: HECHO · PARCIAL (qué falta) · FALTA.

## Resumen por fase

| Fase | Cumplimiento | Nota |
|---|---|---|
| 1 — Entrada (etapas 0-6 del flujo) | ~95 % | todo el flujo existe y está encadenado por `OrquestadorEntrada` |
| 0 — Separar `Principal` + contratos + pruebas | ~65 % | `Principal` ya pesa 1.442 líneas; falta el contrato `abrir(contexto)` por pantalla y las pruebas f* fuera del banco |
| 2 — Prólogo 3D | ~75 % | 8 pasos reales; el recorrido salta 4 salas, sin gesto por tono, sin logro, y el menú central SIGUE abriendo la ciudad |
| 3 — Vida en 3D | ~80 % | reloj, jornada, comida, casa, móvil, avería y calabozo; `factor_riesgo` nunca entra en la semana |
| 4 — Personas en persona | ~80 % | citas, cuerpos en su hora, bonos, asamblea; la entrevista es 1 pregunta, el apoyo político no sale en la rueda |
| 5 — Club ampliado (+ museo que crece) | ~85 % | vestuario vivo, ramas, museo, vuelta olímpica; la rama no ofrece «visibilidad» ni celebra |
| 2.2g — Redes y subsuelo | ~85 % | construido y guardado; faltan cisterna, casas por sector, Forward+ |
| 2.2h — Dinero en la ciudad | ~70 % | cartera, cajeros, tienda, peluches, policía; sin auditoría de coches, sin tarjeta en mano, cajero sin «fuera de servicio» |
| 2.2e — Calidad visual | ~70 % | todas las pasadas tienen código y capturas; veredicto del dueño «MEJORAR» ×2; nada aplicado a los futbolistas del partido |
| 2.3 — Cifras de entrada al campeonato | 100 % | `nucleo/entrada_campeonato.gd` las aplica tal cual |
| 2.4 — Pendientes del traspaso | ~45 % | roles, red del arco y 4.º árbitro hechos; atropello, pilares, tribunas falsas no |

---

## 2.1 · 3.1 El flujo (etapas 0-9)

Entrada real: `project.godot` → `escenas/inicio.tscn` → `ui/inicio.gd:90 _nuevo_juego()` → `escenas/entrada.tscn`
(`ui/entrada/orquestador.gd:33 ETAPAS` = intro, idioma, modo, país, config, entrada, personaje) → `_finalizar()`
(`orquestador.gd:301`) → `OrquestadorMundo.preparar()` (`orquestador_mundo.gd:189-239`) → `escenas/prologo.tscn` o
`principal.tscn`.

| # | Punto del guion | Estado | Evidencia | Qué falta |
|---|---|---|---|---|
| 0 | Intro ≤ 5 s, pantalla completa, saltable tras la 1.ª vez | HECHO | `ui/entrada/intro.gd:29 TOPE_REAL := 5.0`, `:107 se_puede_saltar`, `:12-14` (1.ª vez no se salta); `orquestador.gd:125-127` solo si `not intro_vista()` | — |
| 1 | Idioma (9), logo animado en vez del vídeo | HECHO | `ui/entrada/idioma.gd:8` («los nueve idiomas de `Idiomas.NOMBRES`»); `orquestador.gd:159 aplicar_idioma` al momento; el logo animado ES la intro (`IntroMarca`) | — |
| 2 | Menú inicial: fondo cambia al pasar el cursor; logo arriba-dcha a los 20 s | HECHO | `ui/entrada/menu_modos.gd:24 SEG_LOGO := 20.0`, `:67-72` Timer, `:145 _fondo.mostrar(m)` al enfocar | — |
| 3 | Globo: país, nombre completo, bandera + 5 monumentos cada 30 s; al crear club no se muestran los demás | HECHO | `ui/entrada/pais.gd:7-9`, `pais_fondo.gd:3-6`; `pais.gd:244,259` (`crear` oculta la ficha de club) | fotos libres de monumentos (esperan Wikimedia, límite declarado) |
| 4 | Configuración obligatoria: casa, FPS, visual, mascota, instalaciones, densidad, personalización; confirmación | HECHO | `ui/entrada/config_club.gd:14-23 TITULOS` (nombre/colores, escudo, equipación, mascota, instalaciones, **Tu casa**, juego y gráficos, repasa y confirma); `config_club_pasos2.gd:120 _paso_casa`, `:178 FPS`, `:194 densidad`; `config_club.gd:139 _pedir_confirmacion`; butaca por nivel `ConfigClubDatos.asiento_nivel` | — |
| 5 | Entrada al campeonato (reemplazar / pagar) con cifras 2.3 | HECHO | `orquestador.gd:131` solo si `crea_club`; `orquestador_mundo.gd:257-277 EntradaCampeonato.aplicar`; cifras: ver §2.3 | — |
| 6 | Personaje: aspecto y datos; confirmación | HECHO | `ui/entrada/personaje.gd:260 _confirmar`, `:274 PersonajeConfirmacion.crear` | — |
| 7 | Prólogo 3D fuera del estadio, mentor enseña instalaciones (todas menos tu oficina) y a moverse | PARCIAL | ver §2.2b | 4 salas del edificio no se enseñan |
| 8 | Conocer a la gente y rueda de prensa; gestos según respuestas | PARCIAL | directiva `visor/prologo.gd:282-316`; prensa `visor/prologo_prensa.gd`; sala de prensa física planta 2 (`edificio_club_p1.gd:93`) | el gesto del DT es el mismo con los 3 tonos (`prologo_prensa.gd:106` solo reinicia el reloj del gesto; `prologo_pasos.gd:81-83` define «abiertas/cuello/juntas» pero nadie lo lee) |
| 9 | Oficina con PC funcional = menú central; una tecla lo cierra; seguir desde el PC o caminando | HECHO | `visor/pc_oficina.gd:112 encender` (capa, mundo 3D congelado), `:90-93` Esc, `:150` «Apagar», `:158 apagar` | guardar al salir del juego desde el PC (pendiente declarado) |
| R | Cada etapa pantalla completa, no superpuestas, obligatorias, con confirmación | HECHO | el orquestador monta una pantalla a la vez (`orquestador.gd:236 _montar`, `:262 _ir_a`) | — |
| R | **El menú central deja de dar acceso a la ciudad (queda el estadio 3D)** | FALTA | la pestaña «Ciudad» sigue (`ui/principal/construir_menu.gd:356`), con «🏙️ Ver la ciudad en 3D» (`ui/pantallas/pantalla_ciudad.gd:355-358`) y el menú lateral con «Pasear a pie» / «Conducir» (`ui/componentes/menu_lateral.gd:89-90,142-143`); ninguna guarda mira si `Principal` es la capa del `PcOficina` (0 referencias a `PcOficina` en `ui/`) | ocultar esas 3 entradas cuando `Principal` corre como capa del PC (si no, se construye una segunda ciudad encima de la congelada) |

### 3.2 Qué existía / qué faltaba
| Pieza | Estado | Evidencia |
|---|---|---|
| Guion del recorrido guiado | PARCIAL | `visor/prologo_pasos.gd:16-54` (8 pasos) |
| Sala de prensa física + gestos | PARCIAL | sala sí (`edificio_club_p1.gd:93`); gestos por tono no |
| Objeto 3D que abre/cierra `Principal`; aislarlo | HECHO | `visor/pc_oficina.gd`; `Principal` 1.442 líneas (`cat ui/principal.gd ui/principal_p*.gd`) |

### 3.3 Los sistemas nuevos
| Sistema | Estado | Evidencia | Qué falta |
|---|---|---|---|
| Reloj y agenda únicos | HECHO | `nucleo/reloj.gd` (`RUTINA` :61), `visor/vida_ciudad_p1.gd:19 SEG_POR_MINUTO := 6.0`, `vida_ciudad.gd:297 _avanzar_semana_3d → mundo.avanzar_semana()` | «esperar» en un banco |
| Necesidades (si fallan, más probabilidad de que salga mal) | PARCIAL | `nucleo/necesidades.gd:109 factor_riesgo`, `:121 probabilidad_de_fallo` | **nadie llama a `probabilidad_de_fallo`/`factor_riesgo` fuera de `necesidades.gd`** (rg en nucleo/ui/visor: 0 usos) → el hambre y el sueño no cambian ningún resultado |
| Casa y familia | HECHO | `visor/casa_dt.gd` (cama, sofá, mesa `:32-34`; dormitorio `:97`; familia `:120`) | cocina como sala; la vivienda de `VidaDT` no cambia la casa 3D |
| Personas en persona | HECHO | `nucleo/citas.gd`, `visor/citas_ciudad.gd` | sedes propias por marca; cuerpo genérico |
| Misiones y mensajes (PC o móvil; algunas exigen ir a un lugar) | HECHO | `citas.gd:173-175 m.movil.recibir(... "Agenda del móvil → Ir")` | «llamar gente a tu oficina» como acción del jugador: 0 resultados |
| Negociaciones (mejor en 3D) | PARCIAL | `nucleo/negociacion.gd:118-122,162,171` | `MesaAgente` sin el favor (0 resultados «favor» en `mesa_agente.gd`) |
| Eventos de ciudad (avería → transporte público, calabozo, llamar gente, incitar a salir del PC) | PARCIAL | avería `vida_ciudad_p1.gd:113`; calabozo `vida_ciudad.gd:339` | «llamar gente a tu oficina» y «incitarte a salir si juegas mucho desde el PC»: 0 resultados |
| Vestuario (nombre en taquilla y camiseta; futbolistas presentes a veces) | HECHO | `visor/tunel_vestuario.gd:236-255` (taquillas con camiseta, dorsal y nombre), `visor/vestuario_vivo.gd:9-11` | — |
| Otros deportes como personas, celebraciones en el estadio, trofeo en la sala | PARCIAL | cita «rama» `citas.gd:34,120-127`; museo cuenta ramas `edificio_club_p1.gd:60-68` | la rama no celebra en el estadio ni en el museo (límite declarado) |
| Redes y elecciones (fotos, interacciones, elecciones, convocar rueda) | HECHO | `telefono.gd:138 publicar "paseo"`, `nucleo/redes_p1.gd:282 responder`, `citas.gd:32,112-118` asamblea, `:347 convocar_rueda` | — |

---

## 2.2 Fase 0 — separar `Principal`, contratos y pruebas

| Punto | Estado | Evidencia | Qué falta |
|---|---|---|---|
| 7.1 `Principal` < 1.500 líneas con puentes | HECHO | 1.442 líneas en `ui/principal.gd` + `principal_p1..p17.gd`; `ui/pantallas/*`, `ui/principal/*`, `ui/menu/hubs.gd`, `ui/menu/estilos_menu.gd`, `ui/pantallas/pantalla_ajustes.gd` existen | renombrar la cáscara a `MenuCentral` (paso de fase 6) |
| 7.2 Un contrato por pantalla `abrir(contexto)`/`cerrar()`/señal | PARCIAL | solo 1 de 19 pantallas de `ui/pantallas/` define `func abrir(`; las demás pintan sobre `p._lista_*` de `Principal` (p. ej. `pantalla_ciudad.gd:43-168`) | repartir las ~105 variables (declarado como pendiente en el plan) |
| 7.2 Estado único `Mundo` + `Partida` | HECHO | las pantallas leen `p.mundo` | — |
| 7.2 Validar al entrar: esquema + versión + migraciones | HECHO | `nucleo/partida_p1.gd:26 VERSION := 2`, `partida.gd:259-265 PartidaArchivo.migrar` | — |
| 7.2 Guardias de nodos liberados en pantallas nuevas | PARCIAL | 4 `is_instance_valid` en `ui/pantallas/*`; muchos en `ui/entrada/*` y `visor/pc_oficina.gd` | generalizar |
| 7.2 Autoguardado antes de cada transición larga (intro → inicio → prólogo → oficina) | PARCIAL | prólogo guarda al encender el PC (`visor/prologo.gd:353`), semana (`avance_semana.gd:218`) y jornada (`jornada_partido.gd:48`) | `OrquestadorEntrada._finalizar` (`orquestador.gd:301`) no guarda antes de cambiar de escena; `orquestador_mundo.gd` solo guarda preferencias (`:135-156`) |
| 7.3 `prueba_colisiones_club` y las del nuevo flujo en `mini_banco.sh` | PARCIAL | está en `herramientas/especiales.sh:33`, no en `mini_banco.sh`/`banco.gd` | — |
| 7.3 Prueba de arranque completo con atajo para saltar etapas | PARCIAL | `pruebas/ideas/f1o_flujo.gd` (orquestador entero con sustitutos, sin fundidos); `f2p_prologo`, `f3v_vida`, `f3c_casa`, `f4p_*`, `f5c_club` existen | **ninguna prueba f0/f1/f2/f3/f4/f5 corre en el banco ni en `especiales.sh`** (rg «f1o|f2p|f3v|f4p|f5c» en `pruebas/banco/*.gd`, `herramientas/*.sh`: 0); el banco corre `pruebas/ideas_a*.gd`, que son otras «ideas» |

---

## 2.2b Fase 2 — Prólogo 3D

Flujo: `OrquestadorMundo.preparar` devuelve `PROLOGO` para los modos con club (`orquestador_mundo.gd:239,243-245`; tutorial,
retos, continuar y carrera-m quedan fuera; `PROLOGO=0` lo apaga). «Continuar»/«Abrir partida» con prólogo visto entran en
3D (`ui/inicio_p2.gd:191-197` → `VidaCiudad.arranque_3d` → `PrologoDT.directo`).

| # | Paso | Estado | Evidencia | Qué falta |
|---|---|---|---|---|
| — | Saltar con confirmación; `prologo_visto`; autoguardado | HECHO | `visor/prologo.gd:73 hud.saltar_confirmado`, `:117` Esc pregunta, `:346-353` marca y `guardar_en("partida")`, `:358 _saltar`; guardado `partida_p1.gd:287` | — |
| 1 | Llegada: plano 4 s, acera frente a la puerta, mentor y portero | HECHO | `prologo.gd:19 SEG_PRESENTACION := 4.0`, `:124 Tutorial.mentor_de`; `prologo_pasos.gd:16-27` (llegada, puerta: «el portero abre a quien conoce») | — |
| 2 | Moverse: 4 tarjetas (moverse, correr, cámara, E) con teclas reales; aro + flecha; cumplir al llegar | HECHO | `prologo_pasos.gd:21 ["mover","correr"]`, `:27,38 ["usar"]`, `:129-138 Mando.corto_de`; cámara/V en texto `:24`; `prologo_hud.gd:4-5,12-13` flecha y tarjeta; `prologo.gd:20 RADIO_LLEGADA := 1.8` | la cámara no va como tarjeta (texto) |
| 3 | Recorrido: vestuario, túnel, campo, −1 enfermería y utilería, +1 presidente y sala de vídeo, +2 prensa y comedor; personal saluda | PARCIAL | pasos reales: vestuario, campo, enfermería, presidente, prensa, oficina (`prologo_pasos.gd:28-54`); las salas existen en `edificio_club_p1.gd:91-93` | **no se enseñan túnel, utilería, sala de vídeo ni comedor**; el personal no saluda al pasar (0 `PersonalEstadio` en `prologo*.gd`); el mentor no busca camino (límite declarado) |
| 4 | Directiva: presidente + 2 directivos con cuerpo; pregunta ambiciosa/prudente, confianza ±3 | HECHO | `prologo.gd:282-316` (accionistas de la `Junta` con cuerpo), `prologo_pasos.gd:69-71` (+3 / +1) | el guion decía ±3; el plan lo fijó en +3/+1 (validado) |
| 5 | Prensa física → rueda de presentación, 3 preguntas, gesto por tono | PARCIAL | `visor/prologo_prensa.gd` (3 tonos, relación ±2) | **sin pose distinta por tono** (límite declarado, pero el guion §3.1 lo exige) |
| 6 | Tu oficina: PC interactivo, E abre `Principal` como capa, Esc/Apagar vuelve | HECHO | `prologo.gd:330 _entregar_oficina`, `visor/pc_oficina.gd:112,158`, segunda vez como partida cargada (`pc_oficina.gd:13`) | — |
| 7 | Cierre: autoguardado, logro «Primer día», siguiente carga en la oficina | PARCIAL | autoguardado y `prologo_visto` `prologo.gd:346-353`; arranque en oficina `vida_ciudad_p1.gd:119` | **logro «Primer día» no existe** (0 resultados en `nucleo/logros*.gd`; `Logros` no tiene alta de logros sueltos) |
| R | Nada superpuesto; mentor y directivos ficticios; textos con `Idiomas.t`; scripts < 450 | HECHO | `prologo.gd`, `prologo_mentor.gd`, `prologo_pasos.gd`, `pc_oficina.gd`, `prologo_hud.gd`, `prologo_prensa.gd` | — |
| P | Prueba `f2p_prologo` + captura | HECHO (fuera del banco) | `pruebas/ideas/f2p_prologo.gd`, `f2p_captura_prologo.gd`; `docs/04_auditorias/capturas_fase2/` | meterla en el banco/especiales |

---

## 2.2c Fase 3 — Vida en 3D

| # | Bloque | Estado | Evidencia | Qué falta |
|---|---|---|---|---|
| 1 | Reloj vivo: la luz ES el reloj; 1 min real = 10 min; esperar ×6; dormir → 08:00; móvil con día y hora | PARCIAL | `vida_ciudad_p1.gd:19 SEG_POR_MINUTO := 6.0`, `:185` luz = reloj, `:203 etiqueta_hora`; `casa_dt.gd:24 HORA_LEVANTARSE`; Agenda `telefono_p3.gd:124-128` | «esperar en un banco ×6» (no hay bancos usables por el DT; solo `esperar_hasta` para dormir, `vida_ciudad.gd:346`) |
| 2 | Jornada 09-18, horas extra (+preparación, +estrés), fin de semana libre | HECHO | `vida_ciudad_p1.gd:153-180` | no distingue día de partido (límite declarado) |
| 3 | Comer (comedor planta 2, casa, kiosco), dormir; energía < 20 → `factor_riesgo` en la semana y médico avisa; energía 0 → despiertas en casa | PARCIAL | comedor `vida_ciudad_p1.gd:25,248-253`; interiores `vida_ciudad.gd:271 usar_interior`; médico `:209`; desmayo `:214-235` (+6 estrés, titular) | **`factor_riesgo`/`probabilidad_de_fallo` no se usan en `Mundo` ni en el partido** (0 llamadas): el riesgo nunca «entra en la semana» |
| 4 | Casa: salón, cocina, dormitorio; pareja/hijos/mascota con cuerpo y frases; cama/mesa/sofá | PARCIAL | `casa_dt.gd:32-34,82-83,97-120` | sin cocina como sala; la Casa Grande para todos (vivienda de `VidaDT` no cambia el 3D; límite declarado) |
| 5 | Teléfono: app Agenda (día, hora, próximo evento), Adelantar 1 h / mañana / partido con rutina; mensajes que piden ir a un sitio | HECHO | `telefono_p3.gd:128-170,195 _adelantar` (`["1h","manana","partido"]`), `telefono_p1.gd:28` app «agenda»; mensajes `citas.gd:173-175` | — |
| 6 | Transporte: coche según `VidaDT.transporte` («micro» = sin coche), avería por hash → público; 3 multas → calabozo (−3 confianza, titular) | HECHO | `vida_ciudad_p1.gd:107-116` (micro, avería 1/8), `:154 multas >= 3`; `vida_ciudad.gd:337-353 _calabozo` | sin comisaría 3D (fundido; límite declarado) |
| 7 | Arranque: tras el prólogo cada carga en la oficina; lunes 08:00 en casa; «ir directo» desde el móvil; «Vida apagada» = oficina | PARCIAL | `vida_ciudad_p1.gd:118-124 arranque_3d` (apagada → PC; oficina/casa); `ui/inicio_p2.gd:191-197`; Ajustes → Vida `ui/pantallas/pantalla_ajustes_vida.gd:7-11` | «ir directo al club» desde el móvil: 0 resultados en `telefono*.gd` |
| — | Dormir el domingo avanza la semana con la misma huella | HECHO | `vida_ciudad.gd:294-301 _avanzar_semana_3d → mundo.avanzar_semana()` | — |
| P | Pruebas `f3v_vida`, `f3c_casa`, captura | HECHO (fuera del banco) | `pruebas/ideas/f3v_vida.gd`, `f3c_casa.gd`, `f3v_captura_vida.gd` | meterlas en el banco |

---

## 2.2d Fase 4 — Personas en persona

Enlace: `Mundo` crea las citas cada semana (`nucleo/mundo_p5.gd:77 citas.semana(self)`, `mundo_p2.gd:404` la primera) y
descuenta afinidad (`mundo_p5.gd:79`); se guardan (`partida_p1.gd:324,326`). La Agenda del móvil lleva a la cita 3D
(`telefono_p3.gd:146-160` botón «Ir»/«Guiando» → `m.citas.objetivo` → flecha `visor/citas_ciudad.gd:123-144`).

| # | Bloque | Estado | Evidencia | Qué falta |
|---|---|---|---|---|
| 1 | Citas {quién, dónde, día, hora, asunto, tipo} de junta/comercial/mercado/política/rueda; mensaje + Agenda; máx. 3/semana y 1 por persona; caducan el domingo | HECHO | `citas.gd:15 MAX_SEMANA := 3`, `:24-35 TIPOS`, `:71-141 semana()` (caduca `:79`), `:165-175 _nueva` (mensaje al móvil) | la «entrevista en el plató» en semana de rueda no es una cita (la rueda sigue en el PC) |
| 2 | Persona con cuerpo solo en su horario; fuera de hora, vacío y el móvil lo dice | HECHO | `citas_ciudad.gd:12-13` (2,2 m / 90 m), `:91-97 en_hora`; `citas.gd:17 DURACION := 2` | sede propia por marca (centro comercial fijo; límite declarado) |
| 3 | Negociar en persona: −5 % pedido, +10 puntos; por PC como hoy; una por cita | PARCIAL | `negociacion.gd:118-122,162,171` (`con_favor_agente`) | `MesaAgente` (cantera) no aplica el favor (0 «favor» en `nucleo/mesa_agente.gd`, `ui/componentes/mesa_agente_ui.gd`) |
| 4 | Entrevista de contratación: 3 preguntas en tu oficina, 3 tonos, ±2 moral y grupo del `Vestuario`; «Saltar» | PARCIAL | `citas.gd:29-30,157-163 entrevista()`, `:42 MORAL_ENTREVISTA := [2,-1,1]`, `:229-232` opciones; se dispara en `Negociacion._cerrar_fichaje` | **una sola pregunta** (no 3); no elige el grupo del vestuario; también para staff: no (solo `Jugador`) |
| 5 | Patrocinador en persona +5 %; votación: apoyo = declaración en la rueda (+gobierno, −2 prensa crítica) | PARCIAL | `citas.gd:19 BONO_PATROCINIO`, `comercial.gd:166 firmar_zona`; política `citas.gd:~308 gob["apoyo_club"]`, `_mover_relacion(..., -2)` | **`apoyo_club` no se lee en ningún otro sitio** (0 resultados en `nucleo/prensa*.gd`, `politica.gd`): no hay declaración en la rueda ni efecto con el gobierno |
| 6 | Fotos del `ModoFoto` → Redes con hashtags; «Convocar rueda» (1 extra/semana); elecciones cada 4 temporadas o confianza < 25, asamblea con 3 discursos, perder = otro presidente | HECHO | `telefono.gd:130-138 publicar "paseo"`; `telefono_p3.gd:171-177`, `citas.gd:347 convocar_rueda`; asamblea `citas.gd:32,39-40,112-118,224-227,335+` | la asamblea usa la «Sala de prensa» como salón de actos (no hay salón de actos) |
| 7 | Rutinas: directivos en su horario, personal saluda por nombre y recuerda la última charla (afinidad 0-100) | HECHO | `nucleo/afinidad_club.gd:11-57`, `visor/recorrido_club_charla.gd:43-53`, `mundo_p5.gd:79` | directivos en el palco los sábados: sin evidencia |
| P | Pruebas `f4p_citas`, `f4p_personas`, `f4r_rutinas`, captura | HECHO (fuera del banco) | `pruebas/ideas/f4p_*.gd`, `f4r_rutinas.gd` | meterlas en el banco |

---

## 2.2f Fase 5 — Club ampliado (y 2.2f-bis museo que crece)

| # | Bloque | Estado | Evidencia | Qué falta |
|---|---|---|---|---|
| 1 | Vestuario con vida: laborables 10-12, 3-5 futbolistas junto a su taquilla, nombre y dorsal, E = frase por moral, clip de charla | HECHO | `visor/vestuario_vivo.gd:9-11 (10-12, 4)`, `:68-78` (dorsal más bajo, chándal, «dorsal · puesto»), `:107-113` frase por moral; cuelga de `CitasCiudad` (`citas_ciudad.gd:22`) | cara por nombre, posiciones aproximadas (límite declarado) |
| 2 | Ramas como personas: cita semana 5, pide presupuesto (10 %) **o visibilidad**; aceptar +0,06 fuerza | PARCIAL | `citas.gd:34,37-38,120-127`, `:~295 bono_rama`; `hinchada.gd:315,329` | **sin la opción «visibilidad (un partido en el estadio)»**; el bono no tiene efecto visible salvo el puesto |
| 3 | Museo cuenta títulos de ramas; copa + placa con el año | HECHO | `visor/edificio_club_p1.gd:60-73` (hitos del palmarés + `palmares_ramas`), `:415 SalasClub.museo(... hitos)` | — |
| 4 | Celebraciones: cita «celebración» en el museo (copa, foto a Tribuna); vuelta olímpica con confeti; título de rama celebra y sale en portada | PARCIAL | cita `citas.gd:35,130-134,296-300` (+3 ánimo, publica «victoria»); **vuelta olímpica HECHA** (`visor/celebracion_trofeo.gd`, lanzada desde `ui/principal/noticias_p1.gd:147 → vistas_menu.gd:330-348 _ver_vuelta_olimpica`, apagable en Ajustes) | la rama no celebra ni sale en portada |
| bis | Museo que crece: vitrinas hasta 6, planta 3 con el nivel 5, andamios en obra, animación de encendido | HECHO | `visor/museo_ampliado.gd:3-9`, `museo_ampliado_anim.gd`, `edificio_club_p1.gd:130-131,391`, `edificio_club_salas.gd:51-64`; vitrinas interactivas `visor/museo_vitrinas.gd`, `visor/visor_trofeo.gd` | veredicto del dueño («mejorarlo más») |
| P | Pruebas `f5c_club`, `f5d_captura_museo`, `s8_museo_vitrinas`, `p6_celebracion_trofeo` | HECHO (fuera del banco) | `pruebas/ideas/` | meterlas en el banco |

---

## 2.2g Redes de la ciudad y subsuelo

| Punto | Estado | Evidencia | Qué falta |
|---|---|---|---|
| Modelo por horas, 25 sectores; luz/agua/drenaje/gas; avanzado por `VidaCiudad` con el clima | HECHO | `nucleo/redes_ciudad.gd:1-14`, `visor/vida_ciudad_p1.gd:177 redes.hora_cambiada(hora, clima)`, `ciudad_expansion.gd:7` | — |
| Gasolineras: E = 45 l, 63 €, 10 min; sin corriente no hay bomba | HECHO | `vida_ciudad.gd:32-48 usar_surtidor`, `redes_ciudad.gd:40,377-382` | — |
| Subsuelo (5 tapas, colector, galerías, sala de control, cuarto olvidado) | HECHO | `visor/subsuelo_ciudad*.gd`, `subsuelo_mando.gd`, `explorador_ciudad_p1.gd:242`, `_p3.gd:87`, `_p4.gd:179` | revisar en Forward+ (declarado) |
| Centro de mando (3 pantallas), acometidas por edificio, evento «Apagón de tormenta» | HECHO | `visor/panel_mando.gd`, `nucleo/evento_apagon.gd`, titulares `vida_ciudad_p1.gd:277-279` | — |
| Redes guardadas en la partida; móvil avisa | HECHO | `partida_p1.gd:325`, `partida.gd:297-299` | — |
| Coche con depósito real, aviso < 15 % | HECHO | `nucleo/vida_dt.gd:74-78,320` | — |
| Mapa del transporte (N), buses con número, coches, cerro + teleférico, cabina, tren | HECHO | `explorador_ciudad_p5.gd:394 KEY_N`, `visor/mapa_transporte.gd`, `teleferico*.gd`, `mirador_cerro.gd`, `cabina_coche.gd`, `tren_detalle.gd` | retrovisores/ventanillas, vista del conductor del metro (declarados) |
| Estación Central con trenes, pasajeros; vía de salida | HECHO | `visor/estacion_central.gd`, `pasajeros_estacion.gd`, `via_estacion.gd:1-2` (vía que sale de la ciudad, 27-10) | «vía real fuera de la ciudad» queda cubierta a medias (bajo tierra hasta el anillo) |
| Cuadrillas en averías; sonido ambiente del subsuelo | HECHO | `RedesCiudadVista._cuadrillas`; sonidos reutilizados | sonidos propios |
| Apagón visible en ventanas por sector | PARCIAL | `ciudad_expansion.gd:209-217 textura_luz` + `fachada_torre.gdshader` (torres y lejanos) | casas y piezas del kit no siguen al sector (declarado) |
| Camión cisterna | FALTA | solo en comentarios (`redes_ciudad.gd:14,284`); la «cisterna» de `ciudad_industrial.gd` es un depósito fijo | — |
| Cables con caída | HECHO | `ciudad_expansion.gd:48,60,394 _cable_entre` (combados) | — |

---

## 2.2h Dinero en la ciudad

| Pieza | Estado | Evidencia | Qué falta |
|---|---|---|---|
| A. Cartera (efectivo, cuenta, tarjeta, PIN, límite, movimientos; guardado; pantalla del móvil; objeto en la mano) | PARCIAL | `nucleo/cartera_dt.gd:9-13,67-118`; guardado `roles_p4.gd:363,406`; filas en la app «Banco» `ui/componentes/telefono_cartera.gd`, `telefono.gd:6,17` | **tarjeta física en la mano**: 0 resultados; no hay pantalla «Cartera» propia (va dentro de «Banco») |
| B. Cajeros y banco (retirar/ingresar/PIN, comisión, bloqueo; sucursal; cajeros en hospital/universidad/estación/estadio; «fuera de servicio» sin corriente) | PARCIAL | `visor/cajero_ciudad.gd` (3 puestos: `ciudad_gasolinera.gd:35`, `ciudad_plaza.gd:51`, `ciudad_expansion_p7.gd:106`), `ui/componentes/panel_cajero.gd`, `visor/ciudad_banco.gd:3-5` (ventanilla «Banco Andino»); `vida_ciudad.gd:100-127` | faltan cajeros de hospital, universidad, estación y estadio; sin edificio de banco; **sin «fuera de servicio» sin corriente** (0 resultados) |
| C. Gasolinera por arriba (surtidor cobra a la cartera; tienda con caja; elegir combustible, dos precios) | PARCIAL | `vida_ciudad.gd:33-69 usar_surtidor` (efectivo o tarjeta), `:171 usar_tienda`, `ui/componentes/panel_tienda.gd`, `visor/gasolinera_tienda.gd` | **un solo combustible / un solo precio** (`redes_ciudad.gd:40 PRECIO_LITRO`) |
| Expendedoras y balón suelto | HECHO | `visor/expendedora_ciudad.gd`, `nucleo/expendedora.gd`, `visor/balon_suelto.gd`, `vida_ciudad.gd:129 usar_expendedora` | aviso «E: comprar» en calle/estadio (declarado) |
| D. Peluches (una sala, 3 máquinas funcionales, moneda de 1 €, garra, álbum, logros, modelos reales) | HECHO | `nucleo/peluches.gd:6-22` (15 modelos en `assets/peluches/*.glb`, presentes), `ui/componentes/panel_peluches.gd`, `ui/componentes/vista_garra3d.gd`, `visor/peluches_ciudad.gd`, `ciudad_arcade.gd:27` | ver la sala en la ciudad entera (declarado) |
| E. Policía y bomberos (incidentes, vehículos salen, multa por rojo) | HECHO | `visor/servicios_vida.gd:3-8`, `nucleo/incidentes_ciudad.gd:10,18-34` (robo/incendio/accidente), `vida_ciudad_p1.gd:60,99`, `ciudad_expansion_p7.gd:30` | más detalle (peatones mirando, sospechoso); tráfico que cede: hay prueba `emerg_cede_paso` |
| F. Coches mejor: AUDITORÍA del coche y peatones, luego 3 mejoras del dueño | FALTA | 0 documentos de auditoría del coche en `docs/04_auditorias/` (solo la mención del plan) | hacer la auditoría |
| Decisiones 3-5 del dueño (fichas/monedas, zona, subir peluches) | HECHO | peluches con moneda de 1 € del efectivo (`panel_peluches.gd`), modelos subidos fuera de LFS | — |

---

## 2.2e Calidad visual (pasadas con veredicto del dueño)

| Pasada | Estado | Evidencia | Qué falta |
|---|---|---|---|
| C1 Auditoría de la ciudad | HECHO | `docs/04_auditorias/ciudad_26_10.md`, `capturas_ciudad/` | — |
| C2 Construcción y coherencia | PARCIAL | `capturas_ciudad_c2/`, `visor/fachada_modular.gd`, `detalle_fachada.gd`, `paradero_red.gd`, `estacion_central.gd` | `recursos_sin_usar.md`: 635 piezas Kenney sin usar (cierre 28-10); huecos de la ciudad entera |
| P1 Anatomía | HECHO (pasadas 1-3) | `visor/personaje_dt_p1_p1.gd:108 ANATOMIA`, `:116 HOMBROS_FUERA`; `anim_quaternius.gd:179 _piernas_naturales`; `visor/postura_q.gd`; `pruebas/sonda_movimiento.tscn` | veredicto «MEJORAR» ×2; no aplicado a los futbolistas del partido |
| P2 Movimiento natural | HECHO (pasada 1) | `explorador_ciudad_p1.gd:164 VEL_NATURAL_CLIP`, `visor/movimiento_natural.gd`, `mirada_balon.gd` | inclinación del torso al girar corriendo; veredicto |
| P3 Más animaciones | HECHO | `gente_sentada.gd`, `puerta_vida.gd`, `escalera_vida.gd`, `grupo_vida.gd`, `escaparate_vida.gd`, `paraguas_vida.gd`, `peaton_vida.gd`, `banquillo_tour.gd`, `pasajeros_bus.gd` | clips propios de puerta/escalón; capturas Forward+ |
| P4 Profundidad y calidad | PARCIAL | piel/ropa en shader, `peaton_q.gd:121-122` (fade de LOD y sombra de contacto), `pelo_drive.gd`, `mochila_q.gd`, `pelo_capas.gd` | pelo con mechones; futbolistas del partido; Forward+ en PC del dueño |
| Compuerta: veredicto del dueño | FALTA | «MEJORAR» (27-10) dos veces, sin pasada nueva desde entonces (cierre 28-10) | nueva pasada completa P1-P4 con antes/después |

---

## 2.3 Cifras de entrada al campeonato

| Cifra | Estado | Evidencia |
|---|---|---|
| Cuota 25 % de B; presupuesto 0,75 B / B | HECHO | `nucleo/entrada_campeonato.gd:46 CUOTA_AFILIACION := 0.25`, `:165-174 presupuesto = b - cuota`, `:88 presupuesto_base` (sobre la liga entera) |
| Reputación −10 (reemplazar) / −20 (confederación) | HECHO | `:134 rep_reemplazo = reemplazado.rep - REP_MENOS_REEMPLAZAR`, `:167 rep_confederacion()` |
| Confianza 60 / 40; ánimo −15 | HECHO | `:47-49` |
| El otro club desaparece, jugadores libres, afición repartida; liga impar con descansos | HECHO | `:224-235` (bolsa de libres), `:155 socios_repartidos`, `:177 descansos: n % 2 == 1` |
| Prensa: «Nace un club sobre las cenizas de X» / «Un club compra su plaza» + pregunta dura | HECHO | `:157,178,182,215` |

---

## 2.4 Pendientes del traspaso anterior

| Punto | Estado | Evidencia |
|---|---|---|
| Fusionar a `main` | HECHO (PR #12, #13 según orden 11) | — |
| Partido: roles por jugador (PlayStyles) | PARCIAL | `nucleo/rol_tactico.gd` existe; el motor jugable no lo usa (cierre 28-10) |
| Más desmarques de ruptura | FALTA | solo una mención en `nucleo/catalogo_jugadas.gd` |
| Cartel del 4.º árbitro con corte de cámara | HECHO | `visor/cuarto_arbitro.gd`, `visor/camera_rig.gd:207-210 inserto_cartel` |
| Red del arco | HECHO | `visor/red_arco.gd` + `red_arco.gdshader` |
| Gente del club en primeras filas (M-040) y variedad (M-033) | PARCIAL | `BanquilloTour`, hinchada VAT; sin evidencia de «gente del club» en la grada |
| Rendimiento: 1,34 M triángulos, texturas sin comprimir, oclusión, FPS reales | PARCIAL | `visor/oclusores_ciudad.gd`, `docs/04_auditorias/rendimiento.md`; FPS reales esperan al dueño |
| Ciudad: pilares de puente y rotondas con el kit | FALTA | 0 «pilar» en `visor/puente3d.gd`; rotonda sin tráfico (cierre) |
| Estadios por fuera: tribunas falsas, patrocinadores, escudos | FALTA | 0 resultados «falsa» en `fachada_estadio*.gd`, `entorno_estadio*.gd` |
| Peatones: atropello con reacción; subir al bus; tomar coches | PARCIAL | subir al bus HECHO (`visor/pasajeros_bus.gd`); atropello: 0 resultados «atropell» en `visor/`/`nucleo/`; tomar coches: no |

---

## LO QUE FALTA DEL GUION (ordenado por importancia para el jugador; horas = sesión de trabajo)

| # | Falta | Por qué importa | Dónde | Horas |
|---|---|---|---|---|
| 1 | **Cerrar el acceso a la ciudad desde el menú central cuando es la capa del PC** (pestaña Ciudad → «Ver la ciudad en 3D», menú lateral «Pasear a pie»/«Conducir») | regla explícita del guion §3.1; hoy desde la oficina puede abrirse una segunda ciudad encima de la congelada | `ui/pantallas/pantalla_ciudad.gd:355-358`, `ui/componentes/menu_lateral.gd:89-90,142`, `ui/principal/vistas_menu.gd:31,66,270`; marcar `Principal` como capa en `visor/pc_oficina.gd:112` | 2 |
| 2 | **Las necesidades no cambian nada**: `factor_riesgo`/`probabilidad_de_fallo` nunca se llaman | es el sentido del sistema «comer y dormir» (3.3) y del bloque 3 de la fase 3 | engancharlo en `nucleo/mundo_p5.gd` (semana: lesiones, errores de staff) y/o `nucleo/partido*.gd` (errores del equipo); prueba en `f0r_necesidades` | 3 |
| 3 | **Pruebas de las fases 0-5 fuera del banco** (`f0_*`, `f1*`, `f2p`, `f3v`, `f3c`, `f4p_*`, `f4r`, `f5c`) | el método exige banco en 0 fallos por fase; hoy pueden romperse sin que nadie lo vea | sumarlas a `herramientas/especiales.sh` (una línea cada una) o como sección de `pruebas/banco/varios.gd` | 2 |
| 4 | **Recorrido del prólogo incompleto**: túnel, utilería, sala de vídeo y comedor; personal que saluda en su puesto | el guion dice «todas las instalaciones menos tu oficina» | `visor/prologo_pasos.gd:28-54` (4 pasos nuevos con 1-2 frases), `PersonalEstadio` saludando al entrar | 3 |
| 5 | **Gesto del DT por tono** en la rueda de presentación (abiertas / mano al cuello / manos juntas) | pedido en §3.1 etapa 8 «gestos animados según tus respuestas» | `visor/prologo_prensa.gd:103-106` + `ui/rueda_prensa_escena3d_p1.gd` (clips UAL con `AnimExtra.asegurar`) | 3 |
| 6 | **Entrevista de contratación de 3 preguntas** (hoy 1), grupo del vestuario al que entra, también para staff | bloque 4 de la fase 4 | `nucleo/citas.gd:29-30,157-163,229-232,~283` | 3 |
| 7 | **Apoyo político sin efecto**: `apoyo_club` no se lee; falta la declaración en la rueda y la relación con el gobierno | bloque 5 de la fase 4 | `nucleo/prensa_p*.gd` (pregunta/declaración en la siguiente rueda), `nucleo/politica.gd` | 2 |
| 8 | **Favor del agente en `MesaAgente`** (cantera) | bloque 3 de la fase 4, declarado pendiente | `nucleo/mesa_agente.gd` (−5 % / +0,10 si `citas.favor_agente == semana`) | 1 |
| 9 | **Logro «Primer día»** (y alta de logros sueltos en `Logros`) | cierre del prólogo (paso 7) | `nucleo/logros*.gd` + `visor/prologo.gd:346` | 2 |
| 10 | **Autoguardado antes de las transiciones largas** (al salir del orquestador, al salir del juego desde el PC) | 7.2; hoy un cierre tras el personaje pierde lo elegido | `ui/entrada/orquestador.gd:301 _finalizar`, `visor/pc_oficina.gd:178` | 1,5 |
| 11 | **Auditoría del coche y los peatones** (pieza F) antes de las 3 mejoras del dueño | el plan la exige antes de diseñar más | `visor/motor_jugable*`, `trafico_ciudad*`; informe en `docs/04_auditorias/` | 3 |
| 12 | **Pasada visual nueva P1-P4** con antes/después para el veredicto (y aplicar postura, mochilas y pelo a los futbolistas del partido) | dos «MEJORAR» del dueño sin pasada nueva | `visor/futbolista_q.gd`, `retarget_futbol_q.gd`, `postura_q.gd`, `pelo_drive.gd` | 6 |
| 13 | **Rama: opción «visibilidad» y celebración de título de rama** en museo y portada | bloques 2 y 4 de la fase 5 | `nucleo/citas.gd:120-127,~295`, `ui/principal/noticias_p1.gd` | 3 |
| 14 | **Cajeros que faltan** (hospital, universidad, estación, estadio), «fuera de servicio» sin corriente, edificio de banco | pieza B | `visor/cajero_ciudad.gd`, `ciudad_servicios.gd`, `estacion_central.gd`, `edificio_club*.gd`; leer `redes.modelo` en `vida_ciudad.gd:100` | 3 |
| 15 | **Dos combustibles con precio desde las existencias** y tarjeta física en la mano (pantalla «Cartera») | piezas A y C | `nucleo/redes_ciudad.gd:40,377`, `visor/vida_ciudad.gd:33`, `ui/componentes/movil_mano.gd` | 3 |
| 16 | «Esperar en un banco ×6», «ir directo al club» desde el móvil, cocina en casa | bloques 1, 4 y 7 de la fase 3 (comodidad) | `visor/gente_sentada.gd` (asiento para el DT), `telefono_p3.gd`, `visor/casa_dt.gd` | 3 |
| 17 | Contrato `abrir(contexto)`/`cerrar()` en las 18 pantallas que no lo tienen; más `is_instance_valid` | 7.2 (deuda, no visible para el jugador) | `ui/pantallas/*.gd`, `ui/principal_p1.gd` (105 variables) | 8 |
| 18 | «Incitarte a salir si juegas mucho desde el PC» y «llamar gente a tu oficina» | eventos de ciudad de 3.3 | `visor/pc_oficina.gd` (contador de horas en el PC → mensaje del móvil), `nucleo/citas.gd` (cita a petición) | 3 |
| 19 | Camión cisterna, casas/kit con apagón por sector, sonidos propios del subsuelo, Forward+ | 2.2g pendientes declarados | `visor/redes_ciudad_vista.gd`, `casa_kenney.gdshader` | 4 |
| 20 | 2.4: atropello con reacción, pilares de puente, tribunas falsas, desmarques de ruptura | traspaso anterior | `visor/trafico_ciudad*.gd`, `puente3d.gd`, `fachada_estadio*.gd`, `nucleo/partido*.gd` | 6 |

Total estimado: ~65 h de sesión; los 10 primeros (~22 h) cierran lo que el guion exige y hoy falta de verdad.
