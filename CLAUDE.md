# Memoria del proyecto Dinastía (para Claude)

Se lee al empezar cada sesión. Actualizar cuando el usuario pida algo nuevo.

## Reglas fijas
- Responder en español. Trabajar solo en la rama asignada; nada de PR salvo que se pida.
- Commit y push tras cada bloque. Sin identificadores de modelo en commits ni archivos.
- La contraseña del keystore NUNCA en el repo. Sin subidas a LFS.
- Datos reales solo en `pack_real.json`; el resto con nombres ficticios. Política ficticia.
  No atribuir religión ni romances a jugadores reales.
- Keystore, licencias, FPS, música y builds los maneja el usuario/dueño.
- «La cara 2D moldeada sobre el modelo 3D»: PERMISO DADO el 29-9 («dale con todo»).
  Después el usuario entregará un informe nuevo (el del 29-9 no es definitivo).
- «Ejecuta las tareas en primer plano»: comandos cortos y en pasos separados, no
  cadenas largas en segundo plano.
- El banco `pruebas/banco.gd` debe terminar en «FIN. 0 fallos» antes de subir.
  Lanzarlo con `herramientas/banco.sh` (código 0 = ok; corta en errores de sintaxis,
  cuelgues y «SCRIPT ERROR»). Corre EN PARALELO (4 procesos, `BANCO_PARTE=i/N`,
  reparto por `COSTES` en banco.gd): 162 s → ~83 s. `BANCO_PARTES=1` = en serie. Al
  final muestra las secciones más lentas; si una crece mucho, actualizar `COSTES`.
  Sección nueva en banco.gd = añadirla a `SECCIONES`.
  MINI BANCOS (20-10): `herramientas/mini_banco.sh <grupo|_probar_x>` (grupos en `GRUPOS` de banco.gd:
  partido, guardado, ciudad, estadio, gestion, competicion, textos; 7-30 s). Para probar lo tocado
  mientras se trabaja; también cazan pruebas que dependen del orden. Antes de SUBIR, el banco entero.
- (15-10) Lo visual se revisa en FORWARD+, que es lo que ve el jugador de PC: capturas
  con `herramientas/captura.sh res://pruebas/captura_x.tscn` (Forward+ por defecto,
  `--compat` solo para móvil/web/motor ligero; sin GPU necesita
  `apt-get install -y mesa-vulkan-drivers`). Las capturas nuevas se guardan en JPG
  (el script las convierte; `--png` para no hacerlo).
- Contenedor nuevo: `git lfs pull --include="dinastia-godot/**"` ANTES de abrir Godot;
  si se importa con punteros LFS, los modelos quedan `valid=false` (restaurar esos
  `.import`, borrar `.godot/imported` y reimportar).

## Lo que pidió en sus últimos mensajes (29-9-2026)
1. Terminar el plan en orden: traducción EN/PT (hecha) → más idiomas → limpieza →
   comparar con el informe (meta: nota ≥ 70) → auditoría → **vídeo promo**.
2. Vídeo promo: jugando de verdad, largo y detallado, mostrando cada función, y
   **dejarlo en el chat**. Es lo último antes del repaso.
3. Después del vídeo, **repaso real**: revisar todo el chat, la memoria, la carpeta
   «instruciones profundas», los informes, los vídeos comparativos y el LEEME;
   comparar uno a uno qué está, qué no y qué mejorar; armar un **MEGAPLAN** con lo
   faltante, mejoras, caza de bugs, originalidad y jugabilidad.
4. Partido jugable (Carrera de Jugador): **reutilizar materiales y contenido del modo
   entrenador**. El público, las bandejas (gradas) y los camarógrafos se veían
   horribles → corregido el 29-9 (grada con filas del lado correcto, hinchas de
   detalle, personal real, banca, árbitros, cámara que no se mete en la grada).
   Seguir puliendo si se ve algo feo.
5. Guardar en memoria lo que pide (este archivo).
6. (29-9, después) En AMBOS modos la grada y el público «se ven del asco», no parece
   infraestructura de verdad. Usar el **modelo 3D de butacas** (`assets/ciudad/
   asientos_lod.glb`) en la **totalidad de la grada**; dejar de poner la versión fea
   (textura con gente pintada + hinchas sueltos) en la zona de arriba. Las butacas
   estaban **al revés** (mirando hacia afuera): corregir.

## Pedidos anteriores ya hechos (no rehacer)
- Panel lateral izquierdo con 9 menús a pantalla completa (historia, gente, mi
  carrera, operaciones, mi vida, editar, ajustes, ciudad 3D, estadio 3D), con
  fondos animados únicos. La portada de fichas grandes en 3 columnas hacia abajo
  es «la definitiva». Sin riel horizontal y **sin la ficha del jugador** en esos
  menús. El ☰ no debe chocar con ellos.
- El menú central cambia de estética cada 10 minutos de juego.
- El panel de objetivos de la directiva se puede mover y lo muestra en el borde.
- Carrera de Jugador v1: eventos únicos, control real (mando y teclado), IA de NPC
  basada en las jugadas prehechas, el jugador tira córners, penales y faltas, y
  tiene una estética propia. «Ten muchísimo cuidado con ese modo».

## Hecho el 29-9 (tarde)
- Butacas 3D en toda la grada, mirando al campo (ambos modos).
- 9 idiomas: es, en, pt, fr, it, de, ca + polaco y turco nuevos (1402 frases c/u el 29-9; el 15-10: 2.574 frases fijas y 373 patrones en los 9, con la prueba `_probar_paridad_idiomas`).

## Pendientes
- Hecho 29-9: limpieza (capturas en pruebas/capturas), COMPARACION_INFORME.md (≈71/100),
  AUDITORIA.md (refresco 14x más rápido, fallo al cerrar arreglado).
- Hecho 29-9: VÍDEO PROMO (3:42) entregado en el chat (límite del chat: 30 MB).
  Guion: pruebas/video_promo.gd · montaje: herramientas/montar_promo.py.
- El usuario dijo que con 9 idiomas «estamos bien»: no sumar más.
- Hecho 29-9: REPASO y MEGAPLAN en `dinastia-godot/MEGAPLAN.md` (fases 1-6).
- Siguiente: esperar al usuario o empezar MEGAPLAN fase 1 (pulido).
- Carrera de Jugador: fuera de juego, más eventos, cambios, selección jugable.
- Hecho 29-9: cara 2D→3D (rasgos del retrato proyectados con la pose de reposo en
  `equipacion_q.gdshader`, capas que multiplican la piel, barba con ruido de pelo,
  ojos nuevos `visor/ojos_q.gdshader`, foto real calzada por ojos/boca con
  `datos/caras_reales_puntos.json`). Captura: pruebas/captura_cara_3d.gd.
- Pidió «consigue las caras de los jugadores faltantes en Wikipedia, libres»: la red
  de este entorno bloquea Wikimedia. Herramienta lista:
  `herramientas/caras_reales_faltantes.py` → luego `caras_reales_recortar.py` y
  `caras_reales_puntos.py`. Faltan ~906 de 2125.
- Hecho 29-9: RECREACIÓN de reales (piel por escala natural, pelo, barba y ojos
  sacados de la foto: `herramientas/caras_reales_rasgos.py` →
  `datos/caras_reales_rasgos.json`; sin marcas ni adornos inventados). Ajustes →
  «Caras reales: FOTO / RECREACIÓN» (`Cara.usar_fotos`, pref `pantalla/caras_foto`).
  Legal (explicado al usuario): la licencia libre cubre la foto, NO el derecho de
  imagen del jugador; para publicar/vender lo decide el dueño.
- Pidió (29-9): «los jugadores que tenemos sus caras deben ser igualitos en su
  personaje 3D». Hecho: con foto se esconden cejas y barba 3D, la foto se lleva
  al color de la piel del modelo, óvalo con cejas, fotos de tres cuartos en
  espejo (nariz en `caras_reales_puntos.json`, 8 valores), ojos más cerrados.
  30-9: MALLA DEFORMABLE por jugador (MediaPipe, Apache 2.0, pip + modelo de
  storage.googleapis.com): `herramientas/caras_reales_malla.py` → forma real de
  la cara (468 vért.) + píxeles EXACTOS de la foto (`datos/caras_reales_mallas.json`,
  1164 jugadores). `visor/cara_malla.gd` la cuelga del hueso Head; la cara del
  cuerpo se hunde (`hay_malla`). Colores exactos también en la recreación.
  Datos de caras reales excluidos de los builds públicos (export_presets.cfg).
- 30-9 PEDIDO: «hacele varias pasadas… de las cosas más importantes del juego…
  cada vez que termines me muestras y yo te digo si estamos o si deben mejorar».
  Pasada 1 hecha (caras_pasada1.png): recorte HD 384 px desde la foto original
  (`recursos/caras_reales_cara/`), anillo de frente, quitar luz de la foto,
  sRGB a mano (Compatibility no convertía), piel del cuerpo = color exacto de
  la foto (media recortada), exposición normalizada por foto, relleno de cámara,
  luz de piel (wrap), pelo 3D del color de la foto. Revisión:
  `pruebas/captura_caras_reales.gd` (CARAS=, MOMENTO=estudio|dia|tarde).
  Pasada 2 (pelo por capas, barba, cejas, pestañas: `visor/pelo_capas.gd`) a medias.
- 30-9: el usuario dio por BUENAS las caras («sí, me convence») → EN CURSO el PUNTO 2:
  orejas, pelo, barba, cejas y pestañas (mismo método: pasadas + surtido variado).
  Pasada 1 de pelo (pelo_pasada1.png): largo/gorro medidos, melena con el pelo
  largo del pack, afro con volumen, cuero por capas con nacimiento suave, orejas
  con relieve. Barba/cejas por capas APAGADAS (se veían manchas; la textura va mejor).
  Pasada 2 (pelo_pasada2.png, 2-10): cortes por forma (`PeloCapas.corte_de`: afro,
  tupé, degradado, rapado, normal en domo), mechones y brillo; gorro sin franja.
- 3-10 PEDIDO: «sí, una pasada» (pasada 3 de pelo: caras oscuras de fotos agachadas,
  pelo rizado largo) + «los pelos y las caras que estás creando, GUÁRDALAS para que
  los personajes sean MODULARES (como el personaje que crea el jugador) y tener más
  variantes; reciclar para tener más alternativas». → biblioteca de piezas (caras =
  formas MEZCLADAS de varios reales, nunca la cara de uno en otro; pelos = cortes
  medidos) usada por el creador de personaje y los jugadores ficticios.
- 5-10 HECHO: pasada 3 de pelo (cabeza agachada: piel de la franja clara + ganancia
  x1,5; corte melena_rizada; anillo sin manchas en las sienes) y BIBLIOTECA MODULAR
  (`visor/biblioteca_caras.gd`, `herramientas/biblioteca_caras.py`): 72 caras
  mezcla de 4 reales + 44 cortes medidos; ficticios sin foto y creador de personaje
  («Cara», «Corte medido»). Fuera de los builds públicos. Límite honesto: fotos
  agachadas (Ayoze, Adrián Mora) mejoran pero siguen algo oscuras y deformadas.
- 5-10 ÚLTIMA PASADA (pedida: «Última pasada»): exposición de piel recalibrada
  midiendo (pieles medias/oscuras ya no se hunden), borde de la cara pegado al
  cráneo, calvos limpios, sin pelo en la oreja, pelo y ojos sin reflejo azul del
  cielo. Detalle en `herramientas/MOTOR_CARAS.md`. Tras esto: esperar veredicto;
  si lo da por bueno, sigue el MEGAPLAN.
- 5-10: el usuario APROBÓ la última pasada («Si, dale») → caras y punto 2 CERRADOS.
  EN CURSO: MEGAPLAN (`dinastia-godot/MEGAPLAN.md`). Fases 1 y 2 HECHAS (5-10). Fase 3 HECHA (7-10: fuera de juego, cambios,
  desgaste separado de la velocidad, 13 eventos, selección jugable, retiro y paso a DT).
  7-10: el usuario pidió pasar la fase 3 a main y SEGUIR con la fase 4 (contenido).
  Fase 4 HECHA (7-10): guiños de estadio + apodo, plantillas fijas por nombre de club,
  banderas, mesa de representantes (`nucleo/mesa_agente.gd`), Carrera de Jugador en
  prueba_modos; nota ≈74. Fase 4 aún NO está en main (PR nuevo si lo pide).
  7-10: fase 4 FUSIONADA a main (PR #3); rama reiniciada desde main. EN CURSO fase 5.
  Fase 5 hecho: ciudad que responde (`visor/ciudad_animo.gd`). Pendiente: documental,
  modo foto, dinastías familiares.
  7-10 PEDIDOS: «en la ciudad faltan edificios y cosas 3D que tenemos» → distritos de
  manzanas (`_distritos` en city_builder: norte con torres, este, ensanche sur); casi
  todo el kit ya se usaba (solo cono/tractor sueltos). «A la ciudad le falta mejorar
  las instalaciones y coherencia» → pasada 1: forma propia por instalación (`FORMAS`,
  `_cuerpo_instalacion`), campus con paseos, paleta única clara.
  7-10 PEDIDO GRANDE (ciudad): ×4, bote y río, instalaciones, carreteras y metro a
  futuro, personas, semáforos y luces de colores, casa gigante con seto, «ciudad
  utilizable» (conducir/caminar/NPC). HECHO: `visor/ciudad_expansion.gd` (2640 m,
  red vial en DATOS con `camino_entre`, zonas, 20+ instalaciones, puentes, puerto,
  botes, metro trazado con bocas, 2 líneas de bus que paran, peatones), semáforos
  con ciclo (`visor/semaforos.gd`) y coches que frenan en rojo y hacen cola
  (`TraficoCiudad`), farolas/ventanas/guirnaldas de noche, Casa Grande en finca 2x2
  con seto (el 26-9 se había quitado la casa por error). Río movido a x=-470.
  Minijuegos: no se perdieron (penales escondido); sala en Mi Vida → penales +
  tiro libre + trivia del club (nuevos).
  7-10 NOCHE (usuario dormido, «sigue y termina el megaplan»): HECHO inventario de
  modelos (0 sin usar), metro funcional (L1 elevada, L2 rayos X), autopista, ciudad
  interactiva (conducir/pasear, NPC, E para entrar, táctil), minijuegos de ciudad,
  estatua del ídolo, murales, eólico; FASE 5 CERRADA (documental, ciudad responde,
  modo foto, dinastías, Tribuna real); 129 titulares EN/PT. Nota ≈77. Fase 6 = 🔒
  del dueño (builds, keystore, licencias; presentador en pausa). Nada fusionado a
  main desde el PR #3: lo nuevo está en la rama (PR nuevo si lo pide).
  OJO banco: si el script tiene error de sintaxis se queda colgado; comprobar
  que aparece «===== FIN».
  7-10 PEDIDO: «que la línea de metro funcione, que nuestro personaje la use, usable
  por dentro; minijuegos 3D con animaciones; ¿qué pasó con los edificios?; ¿metro y
  carretera respetan la calle?». HECHO: metro usable (`metro_ciudad.gd` +
  estados calle/anden/tren en `explorador_ciudad.gd`: bocas → andén → subir → ventana
  (C) → bajar; estaciones subterráneas alicatadas; bajo tierra sin niebla/sol y
  cámara dentro del vestíbulo). Captura: `pruebas/captura_metro_usable.tscn`.
  MINIJUEGOS 3D (`visor/mini3d.gd` + `minijuegos_ciudad.gd`, `minijuego_penales.gd`,
  `minijuego_tiro_libre.gd`): autógrafos, pesca, karting (3 rivales), penales y tiro
  libre, con personas animadas. Deportistas: `Mini3D._deportista` (NO revestir un
  PeatonQ: las prendas aparte se suman). Captura: `pruebas/captura_minijuegos_3d.tscn`.
  Edificios: patios verdes en el interior de manzana (`_patio_de_manzana`). Revisión
  aérea: L1 sobre el bulevar x=660, L2 bajo z=-660, rampas en el eje de la avenida
  (ensanchadas a 16 m). Pendiente de caza: aviso «material is null» al construir
  la ciudad (ya existía antes).
  7-10 PEDIDO (ciudad 2.2, luego volver al MEGAPLAN): revisar el aviso técnico;
  casas de distintos colores; decoraciones; instalaciones POR DENTRO con NPC
  trabajando; lo que tiene una ciudad real (alcantarillado, detalles); metro con
  decoración y nombre por estación; nombres de calles y de parques; puente más
  bonito; vehículos más realistas y PROPORCIONADOS; repasar toda la ciudad.
  HECHO (7-10): aviso «material is null» (estatua del ídolo con prendas sueltas +
  fugas de nodos); casas de colores con puerta/ventanas/chimenea/buzón y kit teñido
  (`CityBuilder.tenir`); mobiliario urbano (alcantarillas, sumideros, papeleras,
  bancos, hidrantes, reciclaje, bolardos, STOP/ceda, kioscos, bicis, terrazas,
  vallas); 50 calles con nombre (`nombre_calle_en`, placas, HUD); parques con
  nombre y juegos; estaciones con tema (`MetroCiudad.TEMAS`) y tótems; INTERIORES
  (`ui/componentes/interior_instalacion.gd`, 15 salas, E en la puerta o «Ver por
  dentro»); puente de piedra con arcos; vehículos a medidas reales
  (`CityBuilder.MEDIDAS_REALES`) y autobús procedural (`CityBuilder.autobus`);
  rótulos de comercios. Capturas: captura_interiores, captura_paseo,
  captura_vehiculos. No se pudo descargar modelos (red bloqueada).
  7-10 (usuario: «Sigue») vuelta al MEGAPLAN: NARRACIÓN TRADUCIDA a EN y PT
  (`herramientas/extraer_narracion.py` → `datos/narracion_plantillas.json`;
  traducciones a mano en `datos/narracion_traducida.json`; `montar_narracion.py`
  → `datos/narracion.json`, que carga `Idiomas._cargar_narracion`). Para añadir
  frases nuevas: volver a extraer, traducir lo que falte, montar. Se quitaron dos
  motivos de retiro con religión/política. Nota ≈78. Lo que queda del MEGAPLAN es
  🔒 del dueño (hardware, builds, keystore, licencias).
  7-10 PEDIDO: «las leyes deben ser por cada país según el equipo» y «se puede
  incumplir la ley a cambio de multas (más dinámico) y optimizar». HECHO:
  `nucleo/leyes_pais.gd` (24 países: cupos plantel/cancha, criterio extranjero/
  extracomunitario/no formado, min nacionales GER, fichajes no UE ITA, juveniles
  CHI/BOL), `Club.ley_politica` cumplir/incumplir (Federación), multas crecientes
  y -3 pts desde la 3.ª alineación indebida (`Federacion.revisar_leyes_pais`).
  (Carrera de Jugador v2: fuera de juego, cambios, eventos, selección, paso a DT). El
  usuario pidió el documento del MEGAPLAN (entregado el 5-10).
  Prueba larga nocturna: `godot --headless --path . res://pruebas/prueba_larga.tscn`.
- **6-10 ORDEN DEL USUARIO**: «Sigue con todo el megaplan, yo iré revisando, pero NO
  PARES, y cada fase la debes hacer con EXCELENCIA». Hacer las fases 3→6 seguidas, con
  capturas y pruebas por fase; al cerrar cada fase, actualizar MEGAPLAN.md y pasarle
  el documento.
- (Histórico) **ORDEN VIGENTE (30-9)**: 1) dejar bien las caras (piel, ojos,
  colores); 2) cuando estén bien: orejas, pelo, barba, cejas, pestañas; 3) recién
  después, el MEGAPLAN. Los jugadores SIN foto quedan EN PAUSA (no buscar caras ahora).
- (Histórico, ya levantado el 5-10) MEGAPLAN en pausa hasta terminar las caras.
  «Ten cuidado con los colores y respeta estas instrucciones.»
- 30-9 VEREDICTO Y ORDEN DEL USUARIO (seguir al pie de la letra):
  1. «Físicamente tus jugadores están bien, el tema son los TONOS DE PIEL»: se ven
     sucios y muy saturados. Analizar la cara y los colores para REPLICARLOS
     (piel limpia), no pegar la foto tal cual.
  2. Cuidado con los OJOS: algunos parecen con estrabismo. Mejorar las OREJAS.
     (Repetido tras la auditoría: «claramente aún las caras no están bien, pero vas
     avanzando»; sigue viéndose SUCIO y SATURADO.)
  3. Construir un MOTOR que recuerde lo aprendido (colores, formas: cara, pelo,
     ojos, cejas, pestañas, barba) para facilitar las mejoras.
  4. Orden: primero dejar bien el paso 1 (cara/piel), luego aplicarlo a TODOS,
     luego conseguir las caras que faltan, y recién después el paso 2 (pelo etc.).
  6. «Implementarlo a TODOS, auditar por lotes, no mentirse». Hecho 30-9: motor
     (`herramientas/motor_caras.py`, `MOTOR_CARAS.md`), piel replicada para los
     1146, auditoría automática + 96 hojas de lotes. Límite honesto: caras en
     sombra dentro de fotos bien expuestas salen más oscuras (≈8 % en lo revisado).
  5. Mostrar en cada pasada jugadores DISTINTOS (surtido variado:
     `herramientas/caras_variadas.py`) para ver que el nivel se repite.
- 7-10: todo lo hecho hasta la fase 3 (parte) se FUSIONÓ a `main` (pull request #1,
  pedido del usuario). Lo nuevo sigue en la rama asignada; para pasarlo a main, nuevo PR.
- 7-10: el usuario YA TIENE un informe nuevo («no es tan nuevo»): se usa DESPUÉS de
  terminar el MEGAPLAN. Ahora: seguir con lo que no depende de él (B6 LED/formas
  de estadio, narración en fr/it/de/ca/pl/tr, cupos PAR/VEN, nacimiento vascos).
- 7-10 HECHO: B6 (7 paletas LED + colores propios de fondo/letra; formas «dos» y
  «principal») y NARRACIÓN en los 9 idiomas (fr/it/de/ca/pl/tr en
  `datos/narracion_traducida_mas.json`, se monta con `montar_narracion.py`).
- 7-10: MEGAPLAN CERRADO (todo lo que no es 🔒). SIGUIENTE: el INFORME NUEVO del
  usuario (pedírselo) y, si lo indica, el túnel.
- 7-10 HECHO: TÚNEL DE VERDAD (`visor/tunel_vestuario.gd`: hueco en la tribuna +Z,
  pasillo con colisión, pórtico, vestuario detrás) y RECORRER A PIE
  (`visor/explorador_estadio.gd`, botón en el cajón de VistaEstadio).
  Captura: `pruebas/captura_tunel_recorrido.tscn`.
- **7-10 PEDIDO GRANDE: «ESTADIO INTERACTIVO 2.0»** (palabras del usuario): el estadio
  se recorre JUNTO A LA CIUDAD (entrar y salir del estadio desde la ciudad); todos
  los lugares creados en el estadio deben estar FÍSICAMENTE dentro, además de todo
  lo que tiene un estadio: PISOS NEGATIVOS, OFICINA DEL DT…; si sancionan al DT y
  solo puede ver el partido, verlo desde la grada: recorrer con el personaje y
  SENTARSE EN LAS TRIBUNAS; el PERSONAL del club con presencia física, DIÁLOGOS en
  persona, interacción y RUTINAS; todas las habitaciones PERSONALIZABLES (colores,
  decoración, poner en las paredes las FOTOS sacadas con el modo foto, oficina con
  objetos propios); NOMBRES de los jugadores correspondientes (taquillas).
  Plan por fases en `dinastia-godot/ESTADIO_INTERACTIVO_2.md`.
  8-10 AÑADIDO: «cada uno [la gente del club] debe tener su LUGAR DE TRABAJO
  dentro del estadio» y «a futuro deben CONECTARSE las instalaciones del club con
  el estadio, podría ser SUBTERRÁNEO» (galería desde los sótanos).
- 8-10 HECHO 2.0 fase 6: GALERÍA SUBTERRÁNEA (`visor/galeria_club.gd`): planta −2 →
  pasillo con cinta rodante bajo la avenida → escalera mecánica y caseta junto al
  complejo; solo en la ciudad. Captura `pruebas/captura_galeria.tscn`. Fase 7 (pulido) HECHA: 2.0 CERRADO.
  SIGUIENTE: pedir al usuario el INFORME NUEVO.
- 8-10 PEDIDO: «el estadio al entrar, al jugar y fuera del 3D debe ser EL MISMO; solo
  cambia cuando el usuario lo cambia, y eso TARDA tiempo de construcción»; «la entrada
  es poco realista: PORTERO que abra, diálogo y animación»; «¿esos palos blancos y
  negros son personas?». HECHO: la ciudad construye el estadio con la semilla y el
  club del partido (comparado nodo a nodo: idéntico salvo la galería);
  `EstadioPropio.obra` (ajustes = proyecto, `hecho()` = lo construido, semanas por
  capítulo en `SEMANAS_OBRA`, pintura al momento, andamios «reforma», aviso al
  terminar); `visor/entrada_club.gd` (puertas correderas, pórtico, marquesina,
  garita) + portero en `PersonalEstadio` + `RecorridoClub.dialogo_portero`;
  hinchas de pie (no cápsulas); hormigón y copas ya no salen negros. Capturas:
  captura_entrada, captura_mismo_estadio.
- **8-10 PEDIDO: 5 ETAPAS MÁS** («1 ultra pulido, 2 más realismo en las texturas y
  personajes, 3 optimización mediante código, 4 realismo visual en infraestructura y
  personajes, 5 mejora físicas, movimientos más naturales, que no se puedan atravesar
  los objetos, y más físicas»). Plan y estado en `dinastia-godot/ETAPAS_FINALES.md`
  (con la lista de cosas raras). Hacerlas EN ORDEN, cada una con capturas antes/
  después, banco y modos en verde, y el documento al día.
- 8-10 PEDIDO (hecho): partículas del menú de inicio «más bonitas» y el fondo (portada)
  «cambiando cada 30 segundos por sus variantes» → `FondoParticulas` ("motas"/"bokeh",
  aditivas, teñidas por `TINTE` de cada portada) y `_rotar_portada` en `ui/inicio.gd`.
- **8-10 ORDEN VIGENTE (bucle, «no paras hasta que yo te interrumpa»)**:
  1) terminar el repaso (2.ª pasada de la etapa 1); 2) etapas 2→5 de
  `ETAPAS_FINALES.md` UNA POR UNA; 3) AUDITORÍA COMPLETA; 4) OPTIMIZACIÓN COMPLETA
  del código: medir FPS con un perfil de HARDWARE DE GAMA BAJA, trucos de peso y
  velocidad, y cambiar de lenguaje (C#/GDExtension) si de verdad hace falta;
  5) volver a empezar el ciclo. Commits pequeños y frecuentes; banco solo (sin
  otras pruebas a la vez, que se corta).
- 8/12-10 AVANCE del bucle: etapa 3 (optimización: `visor/optimizar.gd`, cifras en
  ETAPAS_FINALES.md, motor ligero en Ajustes, `herramientas/banco.sh`), etapa 4
  (aceras/zócalos/peatones con accesorios) y etapa 5 (colisión con círculos, deslizar,
  ceder el paso) con una primera pasada. SIGUE: AUDITORÍA COMPLETA → optimización
  completa (gama baja) → repetir ciclo (pendientes en ETAPAS_FINALES.md).
- **13-10 PEDIDO**: ETAPA 6 «casas y edificios, uno por uno, cada uno distinto, poder
  entrar en la mayoría» (plan en ETAPAS_FINALES.md) y AMPLIAR la etapa 1: recorrido y
  jugabilidad en el estadio, nivel de animaciones, cinemáticas, partidos, VISIÓN EN
  PRIMERA PERSONA, mejores diálogos con más variedad, NPCs con vida. El usuario
  entregará el INFORME tras esta pasada por las fases.
- 13-10 HECHO (pasada 2 de las 6 etapas): entrar CAMINANDO a edificios y casas
  (`ExploradorCiudad._entrar_en_edificio`, `InteriorInstalacion.en_mundo`), 5
  arquetipos de casa, `fachada_torre.gdshader`, primera persona (V), diálogos por
  oficio (`herramientas/dialogos_ciudad.py` genera `nucleo/dialogos_ciudad.gd` y
  las traducciones; no editar a mano). Detalle y pendientes: ETAPAS_FINALES.md.
- Esperando al usuario: informe nuevo (después del MEGAPLAN; ahora va el 2.0).
- Mapa de metas: `dinastia-godot/MAPA_DE_METAS.md`. Informe base: INFORME_DINASTIA.md.
- 13-10 PEDIDO: comparar modo partido con FC 26, FC Mobile, DLS, Soccer Manager 2027 y
  seguir un plan de ruta de ≥2 meses. HECHO: `dinastia-godot/COMPARACION_MODO_PARTIDO.md`
  y `PLAN_DE_RUTA.md` (9 semanas, detallado: GTA V, qué falta para lanzar, «el bloqueo» =
  desbloquear modos jugando, opcional). 13-10 pedidos: teléfono medio realista/medio
  informe (HECHO), diálogos con mejor estética (HECHO: `CuadroDialogo`), menos músculo
  (HECHO: `PersonajeDT.BASE_ESBELTA`, `adelgazar`), más personalización, expresiones,
  tutorial, ultra pulido. EN CURSO: semana 1 del plan.
- 13-10 PEDIDO (hecho): en la ciudad 3D NADA de texto fijo arriba/abajo; controles en
  ⚙ «Ajustes de la ciudad» (`AjustesCiudad`, opción de ayudas, apagada) y en el
  TUTORIAL DE LA CIUDAD (1.ª vez); velocidad en un MÓVIL EN LA MANO al correr/conducir/
  metro (`MovilMano`); el botón E brilla si hay algo cerca. Permiso dado para
  DESCARGAR contenido externo si hace falta (solo licencias libres). La red del entorno
  bloquea polyhaven/ambientcg/quaternius (el usuario puede permitirlos en Network access).
- 13-10 (noche) PEDIDO: «la ropa es horrible»; seguir con la semana 1 y PULIR HASTA LAS 12:00
  de su hora (UTC−3 = 15:00 UTC), con pasadas sucesivas. Hecho: ver PLAN_DE_RUTA semana 1.
  Claves: `equipacion_q.gdshader` (escala_holgura, piel_obj, muneca, manga_corta, tatuaje,
  tela civil), `VestidorQ._alisado` (también hacia dentro), `PersonajeDT.adelgazar`,
  `AnimQuaternius._relajar_dedos/_brazos_al_cuerpo`, `TraficoCiudad.reciclar_peatones`.
- 13-10 PEDIDO: «ve qué más se puede pulir» / «sigue». HECHO: cristal de torres lejanas,
  periódico (letras limpias, TRADUCIDO entero: `PortadaPeriodico.titular_traducido`),
  ficha del estadio con el aforo oficial, ventanas de prensa de una en una, tabla de
  competición a todo lo ancho con DG, respuestas de prensa coherentes, peatones (sin
  zapatillas marrón, sin cejas dobles en mujeres, `PeloQ.color_cejas`, gafas a la altura,
  escote sin babero). Prueba de caras de peatones: `CARA=i captura_peatones_fila.tscn`.
- 13-10 (tarde) FÍSICA DEL PARTIDO 3D (pedido: «las físicas siguen siendo de lo peor»):
  `pruebas/sonda_fisica_partido.tscn` mide solapes, velocidades, giros y balón
  (FOTOGRAMAS=n; ~0,5 s por fotograma en xvfb, 600 = 20 s de juego). HECHO: esprint en
  plena jugada (~7 m/s), balón con roce al rodar y pases rasos que frenan, tope de
  velocidad del balón (18 raso / 24 aire / 30 gol), cuerpos que no se atraviesan
  (`MatchPlayback._resolver_choques`). Pendiente: aceleraciones/giros bruscos, disputas
  por el balón, portero (semana 3).
- 13-10 PEDIDO: acercar el partido a FC 26 con un VÍDEO de una partida que el usuario
  dará: está en su Drive (carpeta 1N8kbMPGpPm4Z5t2GudinzJsufdolBwIw, MP4 de 67 MB; el
  conector de Drive no sirve para bajarlo: base64 no cabe). El usuario está cambiando
  «Network access» del entorno «Default» a Personalizado con `drive.usercontent.google.com`
  y `drive.google.com`; el vídeo debe estar compartido «cualquiera con el enlace». Con
  él: bajar, sacar fotogramas (OpenCV ya está) y comparar números con la sonda.
  Alternativas: clip corto en la rama o capturas en el chat.
- 13-10: plataforma Aura (tryaura.dev): solo Unreal/Unity, sin Godot → NO se usa. No hace
  falta conector ni nivel especial de modelo; lo que falta es ver el vídeo.
- 13-10 (noche) VÍDEO DE FC 26 VISTO segundo a segundo (red ya abierta; descarga por
  drive.usercontent.google.com con el id del MP4, 67 MB, vertical 576x1024, 13:45).
  Informe en `dinastia-godot/COMPARACION_FC26_VIDEO.md` (presentación, entorno, animaciones,
  cámaras, interfaz, transiciones, ritmo, física y orden de 8 pasadas). Datos clave: reloj
  FC 26 ≈ 11 s/s (partido de 8-10 min) vs Dinastía ≈ 54 s/s a ×1; 16 % del partido son
  cinemáticas; presentación de ~180 s. El usuario aclaró: «no es solo el partido, es todo:
  animaciones, visualización, entorno». Esperar su visto bueno del orden antes de empezar
  la pasada 1 (preset de ritmo «Realista»). Todo con marcas y nombres ficticios.
- 13/14-10 PEDIDO (Opus alto, «sorpréndeme»): «ya no solo jugadas predeterminadas, que
  cambios y tácticas cambien el resultado, controlar a mis jugadores como en el vídeo, y
  todo lo visual (animaciones, entorno)». HECHO:
  · MOTOR REAL en el partido del DT (`MotorJugable` + `Partido.motor_externo`, ajuste
    «⚽ Motor real» en ⚙, por defecto SÍ): el acta sale del césped (`gol_externo`,
    `remate_externo`, `tarjeta_externa`, `fijar_estadisticas`); al salir del 3D el
    Partido vuelve a sortear solo. Calibrado con `pruebas/sonda_motor_dt.tscn`
    (ESCENARIO=calidad|tactica|cambios|simetria|diag, N, MITAD): ~2,5 goles, ~80 %
    de pases, calidad gana (mejor de local 9/1/2), pizarra ofensiva 6/3/1 vs
    defensiva 2/3/5. Arreglos clave: formaciones invertidas (`_orientar_formaciones`),
    césped que frenaba de más, pase al hueco y regate de la IA, portero que decide
    UNA vez por tiro, atributos con contraste. Prueba del acta:
    `pruebas/prueba_partido_motor.tscn`.
  · Panel «Táctica y cambios» en pausa (Esc) `ui/componentes/panel_dt_partido.gd`;
    DT rival que cambia cansados (60/70/80') y ajusta pizarra; ritmo corto/normal/
    largo (2,7/4/6 s por minuto); control de todo el equipo como en FC (Q cambia,
    cursor amarillo, stick relativo a la cámara de TV).
  · Animaciones según la jugada (`_golpeo_anim`: 333 clips disponibles), conducir,
    recorrer atrás, portero en guardia, controles con pecho/pie.
  · CEREMONIA (`visor/ceremonia_partido.gd`): filas con niños de la mano, mascota,
    lona con escudo, cartas de alineación, himno. Capturas `captura_ceremonia`.
  · REALIZACIÓN DEL GOL: carrera al córner y abrazo, goleador/banquillo/grada,
    barrido con escudo, repetición que acaba en el gol (`Repeticion.congelar`).
    Captura `captura_gol_motor`. Tiempo añadido real (45' +1:23).
  Pendiente de esta línea: disputas cuerpo a cuerpo, más pulido visual del entorno.
  HECHO 16-10: TRANSMISIÓN INTELIGENTE (`CameraRig._transmision`: cierra en área/
  ocasión/córner, abre en contras y balones largos, anticipa, zona muerta,
  amortiguador crítico con topes; pistas que pone `VistaEstadio._pistas_camara`
  leyendo el motor) y ESTADÍSTICAS A PEDIDO (`jugar_estadisticas` = T / Select,
  `PanelEstadisticas` con mapa de tiros y de calor, botón en la pausa y en ⚙;
  `EstadisticasVivo` = tiros con xG, tarjetas, calor; `RotuloEstadisticas` en
  17'/descanso/65'). Prueba en banco `_probar_transmision_y_estadisticas` y en
  `prueba_partido_motor`; captura `pruebas/captura_camara_tv.tscn`.

- 14-10 PEDIDO: «la prioridad es lo visual, las físicas, ver jugar a la CPU y poder jugar
  en serio el partido, como en el vídeo» → motor real en el partido del DT (acta = césped),
  cámara «Transmisión», `visor/cesped.gdshader`, inercia y conducción por toques,
  ceremonia, cine de gol, panel de táctica/cambios. Prueba: `prueba_control_equipo.tscn`.
- 14-10 PEDIDO (hecho): «el control debe ser configurable» → `nucleo/mando.gd`
  (esquemas wasd/clásico, reasignar teclas y botones, ayudas pase/tiro/cambio/dirección,
  `user://controles.cfg`) + `ui/componentes/panel_controles.gd` (⚙ del estadio, pausa
  de la Carrera de Jugador y Ajustes). La guía en pantalla usa `Mando.corto_de`.
  SIGUE: duelos/contacto, más animaciones, CPU vs CPU creíble. HECHO 16-10: misma
  ceremonia y gol en la Carrera de Jugador (`visor/cine_gol.gd` compartido con el DT,
  `CeremoniaPartido` con estilo; `PartidoJugable.con_ceremonia`; prueba
  `pruebas/prueba_carrera_ceremonia.tscn`, con pantalla saca las fotos).
- 14-10 PEDIDO (hecho): «¿qué le pasa al portero?», «el césped no debería ser plano»,
  «los NPC cámaras deberían seguir la jugada», barra de energía y nombres como FC, «carta
  con la cara del modelo 3D al marcar» y CONTROLES FC 26 según el manual que pasó (todas las
  combinaciones + filigranas; menú mejor y con sonido al recorrer/aceptar). HECHO:
  · Portero: `MotorJugable.colocacion_portero` (bisectriz, profundidad por distancia),
    achique en el mano a mano, `portero_lateral_der/izq` (AnimFutbol), estirada sin
    teletransporte. Sonda: ~2,9 goles y 71 % de paradas. Captura `captura_portero.tscn`.
  · Césped con volumen: `visor/cesped_capas.gdshader` + `CespedCapas` (ULTRA 14 capas,
    ALTO 10, MEDIO 0; sigue a la cámara, se apaga a 18 m); color común en
    `cesped_comun.gdshaderinc`. Captura `captura_cesped.tscn`.
  · `visor/camarografos_siguen.gd` (giran con el balón; el de la banda camina).
  · `ui/componentes/indicador_fc.gd` (nombre, barra fina, triángulo) y barras continuas
    en los rótulos (`PlayerSpawner.poner_energia`). `ui/componentes/carta_goleador.gd`
    (banda + escudo + retrato 3D en SubViewport), sustituye al cartel «GOL DE» con motor.
  · Controles FC: `nucleo/mando.gd` (RB `jugar_mod`, filigranas stick der./numpad,
    R3 sombrero, cruceta/F1-F4 tácticas rápidas), `visor/control_fc.gd` (21 filigranas
    con estrellas, reconocedor de gestos, 35+ combinaciones), motor: rosca/vaselina/
    potente, pase tenso, pared, bombeados, centros, contener, 2.º presiona, falta táctica,
    salida del portero, jockey, proteger, cambio con stick der., panenka. Tácticas rápidas
    escriben en la pizarra del club (`tactica_rapida`). Pantalla de controles con
    pestañas (Botones/Ayudas/Combinaciones/Filigranas). Sonido en TODOS los botones al
    pasar y pulsar (`BotonFx._sonar`). Prueba: `prueba_control_equipo.tscn`.
- 14-10 VEREDICTO: la pantalla de controles «sigue siendo muy básica» (pequeña, sin colores
  del juego, sin animación al bajar/subir ni al cambiar, sin sonido, sin «¿seguro que quieres
  guardar?», sin fondo animado) + «¿viste la nueva estructura de los controles?» (su manual
  de FC 26 en 7 partes, PS/Xbox) + «que esté dibujado el mando y qué parte es cada una».
  HECHO (2.ª versión): `ui/componentes/panel_controles.gd` a pantalla completa con fondo vivo
  (shader + FondoParticulas), menú lateral con las 7 partes (+ Asignar, Ayudas), tabla
  PlayStation/Xbox/Teclado, selector dorado que se desliza, filas escalonadas, destello al
  cambiar, diálogos de guardar/descartar/restaurar, sonidos `menu_*` (Sonido), navegación con
  mando (LB/RB secciones). `ui/componentes/dibujo_mando.gd` (mando PS/Xbox o teclado con
  etiquetas y botones que laten). `visor/control_fc.gd`: MANUAL por partes con «fichas»,
  25 filigranas (McGeady, knock-on, flair rainbow, heel lane change…). Motor: cambios firmes,
  bloqueo L3+R3, pase elegante, presión de dos (doble RB), portero palo largo (doble Y) y
  manual (R3), saque de manos, receptor/2.º/3.er lanzador, círculo de serenidad, saques de
  banda del usuario, cámara lenta del tiro potente. Vídeo: `pruebas/video_controles.tscn`
  (--write-movie) → `pruebas/capturas/controles_video.mp4` (ffmpeg de imageio-ffmpeg).
- 14-10 PEDIDO: «el modelo del control es básico, te adjunto uno [Kenney Input Prompts 1.5]; la idea
  es poder girarlo como un globo terráqueo; la caja guárdala en el repositorio». HECHO: el zip son
  ICONOS 2D (CC0), no un modelo 3D; se guardaron los PNG de Xbox, PlayStation y teclado en
  `dinastia-godot/assets/iconos_botones/` (+ licencia; el .zip NO se sube: *.zip va a LFS y LFS
  está prohibido). Mando 3D procedural `ui/componentes/mando_giratorio.gd` (PS o Xbox, iconos de
  Kenney en cada botón y etiqueta, arrastrar = girar con inercia, rueda = zoom, doble clic =
  vista inicial, se mece solo, piezas elegidas laten en dorado, etiquetas con línea que se apagan
  si quedan de espaldas). `DibujoMando` lo contiene; el teclado sigue en 2D.
- 14-10: el usuario dio OTRO REGALO «para después»: Kenney City Kit Roads 2.2 (CC0), guardado en
  `dinastia-godot/assets/ciudad/kenney_roads/` (95 GLB + texturas, sin LFS, regla en .gitattributes).
  AÚN SIN USAR: cuando lo pida, integrarlo a la red vial de la ciudad (`ciudad_expansion.gd`).
- 14-10: el usuario dijo que el mando 3D «se ve mal estéticamente»: el cuerpo pasó de elipsoides a una
  malla fusionada con norma-p (`_malla_cuerpo` en `mando_giratorio.gd`) con barniz y cielo de estudio.
- 14-10: «asociarlo con los colores» (hecho): un color por botón (`ControlFC.color_pieza`; ABXY con los
  de su mando), en el aro del botón 3D, en la línea y placa de su etiqueta y en las fichas de cada fila.
  Diagnóstico del «se ve mal»: era modelo Y ensamblaje (bordes dentados de la cuadrícula, cuerpo globo,
  botones flotantes). Ahora el cuerpo es una malla polar con silueta exacta (`_malla_cuerpo`), mate, con
  meseta y borde redondeado. Revisión: `pruebas/captura_mando_grande.tscn` (DISP=ps|xbox).
- 14-10: «¿se perdieron los diseños de pasto?» NO: los 12 (rayas, rayasH, damero, damGrande, circulos,
  diagonal, espiga, cruz, abanico, rombos, mitades, liso) siguen en `StadiumBuilder._make_grass_texture`
  y en el diseñador (EST_CESPED); el sorteo de clubes solo usaba 4 → ahora 12 (`Club._CESPED`, con
  «rayas» más frecuente). BUG propio de ese día: `cesped.gdshader` leía el dibujo con mipmaps y de lejos
  se fundía en dos bloques → ahora `filter_nearest` + `textureLod` (`cesped_comun.gdshaderinc`); verde de
  transmisión más profundo (brillo 0,64 y saturación). Revisión: `pruebas/captura_disenos_cesped.tscn`.
- 14-10: el usuario se molestó: «¿no le habías puesto volumen al césped? Siento que pierdes cosas del
  juego». Causa: las capas (`CespedCapas`) solo se veían a <18 m y la cámara de transmisión está a
  25-50 m, y el detalle del shader se apagaba a 25-70 m. Ahora capas hasta 46 m (parche 80 m, ALTO 8 /
  ULTRA 12) + mechones de 30-60 cm y parches grandes que no se apagan (`cesped.gdshader`). Prueba de
  regresión en `prueba_control_equipo.tscn` («césped: las capas de volumen existen»). REGLA: tras tocar
  algo visual, comprobarlo con la CÁMARA DE TRANSMISIÓN del partido real, no solo de cerca; y no
  quitar ni apagar nada sin decirlo (si algo cambia de sitio o se pierde, avisar).
- **14-10 PEDIDO GRANDE «MEGA AUDITORÍA 2» (palabras del usuario, EN ORDEN DE TRABAJO)**: «lo que nos falta es seguir
  MEJORANDO LO QUE TENEMOS, solo eso; dejar de lado por ahora el PLAN DE RUTA». Lista: (1) NOMBRE y CARA de cada
  jugador deben corresponder al jugador real (enlace nombre↔cara↔ficha) y NO deben existir otras caras que no sean
  las versiones 3D (nada de retratos 2D sueltos: todo es el render del modelo 3D); (2) el PÚBLICO del estadio =
  PERSONAS REALES (modelos 3D de gente, optimizado, incluso personas del club o de la ciudad); (3) CAMISETAS y
  ESCUDOS de los clubes repasados para parecerse más a los reales; (4) cada MOVIMIENTO CON EL BALÓN ligado a los
  controles, analizado y creado POR CÓDIGO; (5) mejor FÍSICA del partido y HITBOX; (6) más MODELOS 3D de fuera y
  más ANIMACIONES; distintos tipos de CAMINATA del personaje; (7) INTELIGENCIA de los jugadores; (8) efectos de
  CÁMARA, CELEBRACIONES, que se NOTEN los BOTINES, que el VAR se USE; (9) AUDITORÍA REAL de cada parte del juego
  (qué falta y puntos de mejora); (10) CONDUCCIÓN de vehículos mejorada + CÁMARA POR DENTRO; (11) MENÚS incompletos
  (ciudad, personalizar); (12) más MINI ANIMACIONES y MÁS JUEGOS dentro del juego; (13) USAR LA CARRETERA
  (Kenney City Kit Roads, ya en assets/ciudad/kenney_roads) y mejorar objetos MUEBLES e INMUEBLES; (14) OPTIMIZAR
  el juego como MÍNIMO un 50 %; (15) otra MEGA AUDITORÍA de todo → anotar puntos débiles → volver a hacer un VÍDEO
  tipo gameplay y SUBIRLO AL DRIVE. Trabajar por bloques con commit y push, banco en 0 fallos, y verificar con la
  CÁMARA REAL del partido (no solo de cerca). Documento: `dinastia-godot/MEGA_AUDITORIA_2.md`.
- 14-10 MEGA AUDITORÍA 2, punto 2 (público = personas reales) HECHO: `herramientas/hornear_publico.gd`
  hornea el modelo humano del juego en 6 poses (piel por CPU, cortado en cadera, 2 niveles) →
  `assets/ciudad/publico/hincha_<pose>_<cerca|medio>.res`; `StadiumBuilder._montar_horneados` los usa
  en la bandeja baja (cerca = filas de detalle, medio = resto de bandeja 0 en ALTO); el resto sigue con
  el maniquí barato. `hinchada.gdshader` ganó `lado_max` (piel/pelo solo cerca del eje de la cabeza).
  Captura: `pruebas/captura_publico_real.tscn`. Pendiente: NPC del club/ciudad en primeras filas.
- 14-10 MEGA AUDITORÍA 2, punto 3 (camisetas/escudos) HECHO en 2D: `Jersey.svg_de` rehecho (estampado
  recortado a la silueta, cuello, puños, costuras, sombra de tela, marca y escudo en el pecho) y
  `Escudo.svg_de` con aro de borde (`_borde_de`) y sombra. Hoja: `pruebas/captura_camisetas_escudos.tscn`.
  Pendiente: revisar la camiseta procedural del 3D (`KitTextureFactory`) con el mismo criterio.
- 14-10 MEGA AUD. 2, puntos 8 (parcial): VAR en el 3D con motor (1 de 5 goles con VAR en la liga abre
  la sala VAR y pausa el motor; el gol siempre se confirma) y botines variados por jugador sin diseño de
  club (`VestidorQ._botin_de`). Pendiente de 4-8: caminatas del personaje, IA, efectos de cámara.
- 14-10 MEGA AUD. 2 punto 6 (parcial): «MI CAMINATA» (formal/normal/animado/cansado/agachado/trote; clips
  Walk/Crouch_Fwd/Jog_Fwd en `AnimQuaternius.CLIP_CAMINATA`, selector en ⚙ Ajustes de la ciudad,
  `ExploradorCiudad.ESTILOS_CAMINATA`). Medido con `medir_partido` (ALTO): público real +440k tris
  → recortado a 4 filas cerca + 8 medio (2,41 M vs 2,23 M sin ellas). Pendiente: más modelos 3D externos
  (la red bloquea descargas: pedir permiso de red) y más animaciones.
- 14-10 MEGA AUD. 2 punto 10 HECHO: conducción (`ExploradorCiudad._conducir`: curva de potencia, S frena
  fuerte/marcha atrás, ESPACIO freno de mano, volante suave, cabeceo y balanceo) y cámaras de coche con
  V (tercera / capó / interior con volante y cuentakilómetros `VolanteUI`). Captura:
  `pruebas/captura_conduccion.tscn`.
- 14-10 MEGA AUD. 2 punto 13 (parcial): carretera Kenney EN USO como accesorios (`CiudadExpansion._kenney_calles`:
  brazos de farola curva en avenidas, postes con cable en barrios, carteles colgantes en cruces, vallas/luces/
  vallado de las obras), ×9–14. NO se sustituyeron las calzadas (siguen siendo lotes de asfalto con marcas
  propias) — decisión consciente por riesgo con semáforos/tráfico. Pendiente: pilares de puente, rotondas.
- 14-10 MEGA AUD. 2 punto 11 HECHO: menús «Ciudad 3D» (volar, pasear a pie, conducir, entrar al estadio) y
  «Editar» (mundo, mi personaje, identidad, equipación, estadio, casa) completados en `MenuLateral.MENUS`;
  acciones `ciudad_pie/ciudad_coche` (`Principal._ver_ciudad_explorando`). Prueba: `prueba_menu_ciudad_pie`.
- 14-10 MEGA AUD. 2 punto 12 (parcial): 2 minijuegos nuevos en la Sala (Mi Vida → Minijuegos): MALABARES
  (`ui/componentes/minijuego_malabares.gd`) y REFLEJOS DEL PORTERO (`minijuego_reflejos.gd`), récords en
  `user://minijuegos.cfg`. Prueba: `prueba_minijuegos_nuevos`. Tras crear clases nuevas: `godot --headless
  --import` para refrescar la caché de clases.
- 14-10 MEGA AUD. 2 punto 8 (más): efectos de cámara (`CameraRig.impacto` = sacudida, `golpe_de_zoom`;
  gol/tarjeta/remate en `Estadio._montar_motor`). Optimización: se probó bajar cortes/distancia de sombra
  en ALTO → sin ahorro medible de triángulos (revertido); `medir_partido` ganó ARBOL=1 y lista de luces.
  Cifra honesta: partido ALTO ≈2,3 M tris/700 llamadas bajo llvmpipe; el ≥50 % NO está demostrado.
- 14-10 MEGA AUD. 2 puntos 9 y 15: `dinastia-godot/MEGA_AUDITORIA_2.md` (estado real de los 15 puntos; el ≥50 % de
  optimización NO está demostrado). Vídeo de novedades (≈40 s, 8 MB) entregado por el chat; NO se subió al Drive:
  el conector exige el archivo en base64 dentro de la llamada y 8 MB no caben. Guion `pruebas/video_novedades.gd`,
  montaje `herramientas/montar_novedades.py` (los .avi/.mp4 nunca al repo).
- 14-10 PEDIDOS (tras MEGA AUD. 2): «¿qué hacemos con el resto de las filas?» → personas reales en TODAS las filas
  (poses sentadas, 8 poses × 3 niveles cerca/medio/lejos; `herramientas/hornear_publico.gd`). Fondo del menú Ciudad
  3D rehecho (`fondo_menu.gdshader` estilo 7). «Compara qué se respeta con cada club» → `pruebas/auditoria_clubes.tscn`
  (AUDITORIA_CLUBES.md/.csv): estadio real 46 %, colores de estadio 12 %, escudo con rasgos reales 7 %, foto de
  equipación 37 % (solo base real), diseño propio 91 %, patrocinador del club real 0 % (los de la IA salen del azar
  determinista: PENDIENTE), retrato real 13 % (base real). HECHO: escudo REAL del club en la camiseta 3D (uniform
  `escudo_tex`), colores de butacas de 47 estadios y rasgos de escudo de 26 clubes (`estadios_reales.py` ASIENTOS/
  ESCUDOS → `estadios_colores.py` parchea los JSON), retratos con la camiseta de volumen (`VestidorQ.ropa_aparte`).
  El «modelo» de camiseta = la ropa Peasant (RopaSeparada), apagada en partido por coste. Pendiente: estadios por
  fuera son cajas grises (tribunas «falsas»), patrocinadores reales, más escudos.
- **14/15-10 (sesión de revisión) PEDIDOS Y ESTADO**:
  · `main` estaba desfasado (43 commits de sweet-turing sin fusionar) → UNIFICADO con el
    PR #5 (fusionado por pedido del usuario). Ramas viejas: lo vigente está en `main`.
  · Banco: `herramientas/banco.sh` robusto. `prueba_control_equipo`: sus 3 fallos eran
    de la PRUEBA (balón fuera → «saque», donde Q y el tiro no actúan), no del juego;
    arreglada, 0 fallos.
  · Renderizador: el usuario pidió fijar la revisión en Forward+ («para que no vuelva a
    ocurrir») y capturas en JPG → regla arriba.
  · Pidió REESCRIBIR EL HISTORIAL para bajar el peso del repo: quitar SOLO versiones
    viejas de binarios (capturas PNG, modelos, mallas de caras), nunca código; luego
    volver a clonar. Se hace después de fusionar los kits.
  · Regaló 12 kits Kenney CC0 (muebles, edificios modulares, mini arcade, comida, kit de
    edificios, montaña rusa, tren, suburbano, mini mercado, industrial, comercial 2.1,
    carreteras) → se guardan en `assets/kenney/` (sin LFS) con `INVENTARIO.md`; se usan
    después (interiores, «cada edificio distinto», tren/metro, tiendas, parque).
  · Ideas de OPTIMIZACIÓN que dio (no es plan obligado, «por si se necesita»): nada pesado
    en `_process` (349 scripts lo tienen), señales en vez de revisar cada fotograma,
    física a 30-45 Hz (poco efecto: el partido calcula su propia física), lightmaps en
    escenarios fijos, COMPRIMIR TEXTURAS (3087 de 3149 sin comprimir), y C++/GDExtension
    solo si tras medir hace falta. Python solo se usa en herramientas, no en el juego.
  · Orden vigente sigue siendo la MEGA AUDITORÍA 2 (mejorar lo que hay).
  · HALLAZGO (no arreglado): en `_probar_motor_libre`, «con el bono del club se generan
    más ocasiones» solo pasa porque los jugadores llegan con estado de los partidos
    anteriores de la misma sección; con jugadores frescos da xG 56,0 vs 59,6 (falla).
    `MotorLibre` es el prototipo (el juego usa `MotorJugable`); la prueba no se tocó.
- 17-10: VAR que ANULA goles (1 de cada 3 revisados: `Partido.anular_gol_externo`, `MotorJugable.anular_gol`,
  `EstadisticasVivo.anular_gol`, panel rojo en `SalaVAR`). OPTIMIZACIÓN del partido: 1,80 M → 0,76 M tris
  (−58 %), 690 → 630 llamadas. REGLA: al rehacer una malla (`VestidorQ._con_reposo*`) copiar sus LOD con
  `VestidorQ.lods_de()`. AVISO dado: a >30 m no se dibujan cejas 3D y a >20 m las pestañas (también peatones).
- 17-10 (tarde): hechos prórroga+tanda 3D, informe del rival (2.ª versión con estética, formación,
  nota media y cara del mentor), moral explicada en el Camarín, VAR con fuera de juego real,
  arreglos del partido (árbitros de color, gestos, cuarto árbitro, red, confeti, línea VAR),
  vibración del mando, país real de la selección rival, GPS en el móvil. ESTADO REAL de las 470
  mejoras y las 300 ideas en `dinastia-godot/ESTADO_MEJORAS.md` (con TOP 25). Comparación con
  otros juegos: `COMPARACION_JUEGOS_2.md`.
  USO: el 17-10 el usuario enseñó su límite semanal al 86 % (se restablece el viernes 00:00):
  AHORRAR — sin agentes nuevos, trabajo pequeño y solo lo pedido hasta el restablecimiento.
  TRASPASO: `dinastia-godot/PENDIENTES.md` (qué falta, cómo, y qué falta fusionar; respaldos en
  `dinastia-godot/parches_pendientes/`). Mantenerlo al día en cada bloque.
- 17-10: TODO fusionado a `main` con el PR #7 (pedido del usuario). La revisión automática horaria quedó PAUSADA (pedido).
- 19/20-10: pidió revisar el avance («dale mejora», «sigue»). HECHO en la rama `ccr-54306f57-jlcywg`
  (PR abierto el 20-10): línea defensiva común + trampa (M-123), notas de partidos mirados, prueba del
  bono robusta, física M-114/115 (saques sin patinar, giros continuos, balón sin saltos, tope de
  aceleración `MotorJugable.A_MAX`=18), ojos hasta 35 m. OJO: `medir_partido` y la sonda de física
  medían la CEREMONIA hasta el 19-10 (ya la saltan); en juego real: 493 llamadas, 1,34 M tris.
  Contenedor: Godot 4.7.2 hay que bajarlo. NO usar `pkill -f <patrón>` (mata la propia orden):
  matar por PID.
- 20-10 VÍDEO REGALADO (faltas por puntos) — APRENDIDO, a implementar en el motor: cada factor de la
  entrada suma (agarrón 1,4 · por detrás 3,0 · empujón 1,7 · a gran velocidad 2,0 · deslizante 2,6 ·
  falta profesional/último hombre 2,3 · de pie 1,2 · carga de hombro 0,9 · agresiva 2,4) y la suma
  decide: falta ≥ 1,0, amarilla ≥ 4,0, roja ≥ 7,0 (por detrás + rápida + profesional = 7,3 → roja).
  Usa velocidad y posición reales de cada jugador (quién es el último defensor).
- 20-10 PEDIDOS: (1) faltas por puntos; (2) mejorar el banco con MINI BANCOS por situación;
  (3) pruebas especiales en las que YO JUEGO de verdad (inyectando el mando) como experimento;
  (4) valorar C++ (GDExtension) para que el juego corra más rápido. Unreal 5: desaconsejado (explicado).
- 20-10 HECHO: dificultad de la CPU en el partido 3D (6 niveles, botón en ⚙; ver PENDIENTES 2.10),
  más chispa (+10 % tiros medido con 48 partidos; con 18 el ruido es ±25 %: medir siempre con muchos),
  vallas LED en MultiMesh y mascota fundida (504 → 419 llamadas), «Claude juega» (`claude_juega.tscn`).
- 20-10 PULIDO (pedido: «pulir lo que ya tenemos»): cartel del 4.º árbitro a tamaño real, cambio con
  cartel y palmada también en la Carrera (`PartidoJugable._escena_cambio`), la OLA y la ONDA de la grada
  (`visor/ola_grada.gd` + `hinchada.gdshader`). Los bancos cortan también con «SHADER ERROR».
- 20-10 PEDIDO: «me interesa más pulir lo de los más de 300 puntos» (ESTADO_MEJORAS.md). HECHA una pasada
  (sección 0 del documento): HECHO 49 → 94 filas. Bolsas de nombres en `datos/bolsas_nombres.json`
  (tocayos 10 % → 1 %). Banco: 4 secciones nuevas (palabras prohibidas, capitán votado, glifos, tocayos).
  OJO: `_probar_motor_libre` dependía de la base que dejaba la prueba anterior (ahora la fija).
- 21-10 («Sigue»): 2.ª pasada de la lista (A-F). HECHO 94 → 102. Claves: `visor/mirada_balon.gd` (LookAt al balón,
  eje +Z comprobado con `captura_mirada`), `PlayerSpawner.poner_brazalete` (copia del material), capitán en todos
  los clubes al generar (`Mundo._capitan_si_falta`) y cinta heredada en `Puente3D.once`, sector visitante
  (`est.visita1/2` → `sector_visita`), faros (`TraficoCiudad.faros`).
- 21-10 PEDIDO: «descarta la optimización (ya está bien); la tribuna sigue viéndose mal, ¿la estructura del estadio
  es modular y navegable?, la gente no se ve tan real». HECHO: pasillos con escalera y barandilla en todas las
  bandejas + escaleras de acceso desde el césped, cinta LED en el peto (`visor/cinta_led.gdshader`), público con
  volumen/bufandas/gorras (`hinchada.gdshader`, `OlaGrada.colores_club`), nivel medio de personas que NUNCA se
  llenaba (bloques sin cabeza desde la 5.ª fila), subir CAMINANDO a la butaca (`camino_a_butaca`). Revisión:
  `pruebas/captura_diagnostico_grada.tscn` (6 tomas) y `captura_sentarse.tscn`. Pendiente: el exterior (cajas,
  esquinas abiertas). OJO: sin pantalla, los MultiMesh no guardan posiciones (no probar eso en el banco).
- 21-10 HECHO exterior: `visor/entorno_estadio.gd` (solo partido y Carrera; la ciudad ya tiene lo suyo) y esquinas
  cerradas en «rect»/«principal». Captura `pruebas/captura_exterior.tscn` (FORMA=, SUFIJO=_antes).
  SIGUIENTE (pedido): fusionar a main y hacer un VÍDEO de gameplay real CON SONIDO, más largo y detallado,
  probando cada mecánica y variable (duración de referencia: la de un gameplay real).
- 21-10 HECHO: VÍDEO DE GAMEPLAY con sonido en 3 partes (<29 MB c/u, entregadas en el chat): 1 partido entero
  (ritmo normal, 8:23, bot con el mando), 2 resto del juego (7:38), 3 CPU vs CPU 1.ª parte con gol (4:08).
  Guiones: `pruebas/video_partido.tscn` (hereda de claude_juega; CEREMONIA=1 RITMO= SIN_MANDO= MITADES=),
  `pruebas/video_gameplay.tscn` (VG_TRAMO=gestion|estadio|ciudad|carrera|mini); montaje
  `herramientas/montar_gameplay.py <carpeta> [partes]`. ~0,4-0,5 s por fotograma: lanzar con setsid (>2 h).
  HALLAZGOS para evaluar: pocas ocasiones a ritmo normal (CPU vs CPU 2-3 tiros por equipo y mitad; el partido
  del bot 0-0 con 1 tiro), controles táctiles visibles en PC al pasear, público de cerca como maniquíes,
  aviso del presidente tapa la prensa, malabares muy básico, de noche la calzada negra y conos de luz triangulares.
  ESPERANDO la evaluación del usuario.
- 21-10 INFORME del usuario («Auditoría técnica estructural», 16 puntos, nota 74/100) ANALIZADO contra el código:
  falso o ya resuelto: ciudad y partido NO conviven (cada visor se crea y se libera con queue_free al cerrar),
  datos en `Mundo` + guardado JSON seguro, sin RigidBody (todo por código), 235 señales, sin NavMesh en el campo.
  Útil y pendiente: oclusión en la ciudad (0 OccluderInstance3D), compresión de texturas (3103 sin comprimir,
  17 imágenes >2048), medir FPS en hardware real con el profiler (lo maneja el dueño), .pck aparte para la
  ciudad (builds = dueño), algún panel que sondea en `_process` (p. ej. panel_objetivos). «Feature creep»
  de la ciudad = decisión de diseño del dueño. ESPERANDO qué quiere aplicar (había descartado optimizar).
- 21-10 PEDIDO (tras el informe): «reusar TODOS los objetos y poder separar y unir de forma modular»; punto 16
  (.pck aparte) RECHAZADO; seguir con los hallazgos; «falta de profundidad en diseño»; aceptó mi propuesta
  (oclusión, texturas, señales). HECHO: `visor/modulos.gd` (catálogo común de piezas Kenney/Quaternius:
  tomar/devolver, unir/separar, a_datos/de_datos, teñir, listar; banco `_probar_modulos`), edificio del club
  amueblado con él + 7 objetos de deco nuevos, `visor/oclusores_ciudad.gd` (−16 % llamadas a pie de calle,
  `pruebas/medir_oclusion.tscn`), panel de objetivos por señal, ritmos 4/5,5/7,5 s/min + `MotorJugable.prisa`
  (≈2,6 goles y 15 tiros en «normal»), sin táctiles en PC, mentor no tapa la prensa, `cono_farola.gdshader`,
  malabares con racha, manos del público. Reevaluación: `dinastia-godot/REEVALUACION_INFORME_21_10.md` (≈78).
- 21-10: el usuario RECHAZA los puntos 1-3 del informe (la ciudad se queda: es parte del juego). «Sigue puliendo».
  HECHO: fabricantes con logo en la camiseta 3D (M-057, `DisenosKit.marca_de`, `marca_forma`), motor del coche
  sintetizado (M-173, `visor/motor_coche_sonido.gd`), PRÁCTICA LIBRE en la sala de minijuegos (M-130,
  `VistaEstadio.abrir_practica`, `MotorJugable.empezar_practica`, `pruebas/prueba_practica.tscn`), ropa variada en
  la grada (M-033), cuerpo por físico (M-081, `PersonajeDT.cuerpo_futbolista`), gatillos de presión (M-124).
  ESTADO_MEJORAS: HECHO 110 · PARCIAL 115 · PENDIENTE 227. OJO: en el motor, NO usar los dict de jugador como
  clave de Dictionary (cambian y la búsqueda falla): usar p["id"].
- 21-10 («Sigue»): HECHO directiva en el palco (M-040, `VistaEstadio.poner_directiva`, `_a_la_butaca` también para el
  DT sancionado, que flotaba), choques del coche con golpe/claxon/multa (M-172), piel y pelo por país en los
  inventados (M-088, `Cara.TONO_MEDIO`/`RUBIOS`; usar `String.hash()`, djb2 con la misma cola correlaciona),
  formas de estadio por tamaño + «estrecho» y «asimetrico» (M-002). ESTADO_MEJORAS: HECHO 114 · PARCIAL 115 · PEND. 223.
- **23-10 PEDIDO GRANDE (analizado, aún sin construir): REESTRUCTURACIÓN.** El dueño quiere más «sentido humano
  y estilo propio»: intro ≤ 5 s → idioma → menú inicial (fases 1-5 como pantallas completas, obligatorias, con
  confirmación: modo con fondo según el cursor, globo con bandera y monumentos, configuración del club, entrada al
  campeonato, personaje) → prólogo 3D guiado por el mentor → rueda de prensa → oficina con PC que abre el menú
  central (la ciudad deja de abrirse desde ahí) → vida en 3D (jornada, casa y familia, necesidades, personas,
  eventos). Plan completo: `dinastia-godot/MEGAPLAN_REESTRUCTURACION.md` (flujo, sistemas, pendientes, limpieza
  del repo, partir `principal.gd` de 6.867 líneas, fases 0-6 y decisiones por tomar). Pidió no hacer nada más
  por ahora salvo: arreglar fallas, megaplan, pendientes, mejoras y limpieza. HECHO 23-10: colisiones del club
  (`visor/colision_club.gd`, prueba `pruebas/prueba_colisiones_club.tscn`). Azure/Foundry (200 USD, 30 días):
  analizado, a decidir. NO borrar `entregas/`, capturas, `marca/` ni los informes de `_docs_extract/` sin su OK;
  reescribir la historia sigue en espera. Godot 4.7.2 se baja de GitHub releases (linux.x86_64.zip).
- 23-10 DECISIONES: partidas guardadas invalidables; cifras de la fase 4 las propone Claude (MEGAPLAN §9.1);
  limpieza hecha (`entregas/` fuera, 476 capturas sin uso fuera, informes en `docs/informes_extraidos/`);
  reescribir la historia SOLO con un «sí, empuja» explícito (§9.3); regla de líneas aceptada (código nuevo < 600,
  lógica < 1.500); el dueño abrirá la red para Wikimedia/banderas; **el resto del megaplan está PAUSADO hasta la
  semana del 26-10** (empieza por la fase 0).
- 23-10 (tarde): la NORMA DE CÓDIGO vale para TODO el juego (medir con `herramientas/revisar_lineas.py`; hoy 61 scripts > 600 y
  14 > 1.500). LFS: el dueño eligió la opción B (sacar del árbol los packs fuente; lista en `docs/lfs_fuera_del_juego.csv`) PERO
  falta que confirme que conserva los originales antes de quitarlos. ENSAYO de reescritura hecho en clon espejo (1,33 GiB → 804 MiB,
  árbol idéntico; `herramientas/reescribir_historia.py`); NO se ha subido nada. El repo local de la sesión es superficial
  (`shallow`): para la historia completa clonar con `--mirror`.
- 23-10 (noche) DECISIONES: NORMA = 450 líneas máx. por script en TODO el juego (87 archivos la pasan, ~68.000 líneas a mover; ver
  MEGAPLAN §10.1). LFS: los originales de `docs/lfs_fuera_del_juego.csv` SOLO están en GitHub → NO se quita ni se mueve nada de LFS
  y NO se reescribe la historia de forma que se pierdan sus punteros (la regla «sin subidas a LFS» = no subir archivos NUEVOS a LFS).

