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
- 9 idiomas: es, en, pt, fr, it, de, ca + polaco y turco nuevos (1402 frases c/u).

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
- Esperando al usuario: informe nuevo (después del MEGAPLAN; ahora va el 2.0).
- Mapa de metas: `dinastia-godot/MAPA_DE_METAS.md`. Informe base: INFORME_DINASTIA.md.
