# Memoria del proyecto Dinastía (para Claude)

Se lee al empezar cada sesión. Actualizar cuando el usuario pida algo nuevo.

## Reglas fijas
- Responder en español. Trabajar solo en la rama asignada; nada de PR salvo que se pida.
- Commit y push tras cada bloque. Sin identificadores de modelo en commits ni archivos.
- La contraseña del keystore NUNCA en el repo. Sin subidas a LFS.
- Datos reales solo en `pack_real.json`; el resto con nombres ficticios. Política ficticia.
  No atribuir religión ni romances a jugadores reales.
- Keystore, licencias, FPS, música y builds los maneja el usuario/dueño.
- «La cara 2D moldeada sobre el modelo 3D»: NO tocar sin permiso explícito.
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
- Esperando al usuario: túnel, cara 2D→3D (necesita permiso).
- Mapa de metas: `dinastia-godot/MAPA_DE_METAS.md`. Informe base: INFORME_DINASTIA.md.
