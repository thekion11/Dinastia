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
- **ORDEN VIGENTE (30-9, último mensaje)**: 1) dejar bien las caras (piel, ojos,
  colores); 2) cuando estén bien: orejas, pelo, barba, cejas, pestañas; 3) recién
  después, el MEGAPLAN. Los jugadores SIN foto quedan EN PAUSA (no buscar caras ahora).
- **MEGAPLAN EN PAUSA** hasta terminar bien las caras reales (orden del usuario 30-9).
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
- Esperando al usuario: túnel, informe nuevo.
- Mapa de metas: `dinastia-godot/MAPA_DE_METAS.md`. Informe base: INFORME_DINASTIA.md.
