#!/bin/bash
# PRUEBAS ESPECIALES (23-10-2026): lo que el banco NO ve. Cada una es una escena o un script aparte.
#   herramientas/especiales.sh            → las rápidas (≈2 min)
#   herramientas/especiales.sh todo       → con el recorrido de todas las pantallas y el balance a largo plazo (+9 min)
# Salida: una línea por prueba (OK / FALLO) y código 0 si todas pasan.
cd "$(dirname "$0")/.." || exit 1
FALLOS=0
LOG=$(mktemp)
# REPARTO (2-11-2026, CI): ESPECIALES_PARTE="i/N" corre solo cada N-ésima prueba (las demás se saltan),
# para repartir las especiales entre N máquinas a la vez. Sin la variable, corren todas.
PARTE_I=""; PARTE_N=1
if [[ -n "$ESPECIALES_PARTE" ]]; then PARTE_I=${ESPECIALES_PARTE%/*}; PARTE_N=${ESPECIALES_PARTE#*/}; fi
CONT=0
# REPARTO POR TIEMPO MEDIDO (5-11-2026): `especiales_reparto.txt` (lo genera herramientas/repartir_especiales.py con los registros del CI) dice en qué parte cae cada
# prueba para que todas tarden lo mismo. Vale solo si su «N» coincide con el de ESPECIALES_PARTE; una prueba que no esté en el archivo (nueva) sigue el reparto por turnos.
declare -A REPARTO=()
REPARTO_N=0
if [[ -f herramientas/especiales_reparto.txt ]]; then
  while IFS=$'\t' read -r RP RS RNOMBRE; do
    if [[ "$RP" == "#"* ]]; then [[ "$RP" =~ N=([0-9]+) ]] && REPARTO_N=${BASH_REMATCH[1]}; continue; fi
    REPARTO["$RNOMBRE"]=$RP
  done < herramientas/especiales_reparto.txt
fi

BLOQUE=""
pasa() {  # nombre, comando, patrón de éxito
  if [[ -n "$ESPECIALES_SOLO" ]] && [[ "$ESPECIALES_SOLO" != "$BLOQUE" ]]; then return; fi
  CONT=$((CONT + 1))
  if [[ -n "$PARTE_I" ]]; then
    if [[ "$PARTE_N" -eq "$REPARTO_N" ]] && [[ -n "${REPARTO[$1]+x}" ]]; then
      [[ "${REPARTO[$1]}" -ne "$PARTE_I" ]] && return
    elif [[ $((CONT % PARTE_N)) -ne "$PARTE_I" ]]; then return; fi
  fi
  if [[ -n "$ESPECIALES_LISTAR" ]]; then echo "LISTA $1"; return; fi   # (5-11) sin ejecutar: solo qué pruebas tocan a esta parte
  local t0=$(date +%s)
  ## (4-11, A4) Cada prueba con SU carpeta user:// vacía, como en el CI: con el guardado de un jugador (idioma, ajustes, partidas)
  ## las pruebas que ponen un idioma antes de abrir el juego medían otra cosa (el guardado manda) y pasaban sin probar lo que decían.
  XDG_DATA_HOME=$(mktemp -d) timeout 600 bash -c "$2" > "$LOG" 2>&1
  local seg=$(( $(date +%s) - t0 ))
  if grep -q "SCRIPT ERROR" "$LOG" || ! grep -qE "$3" "$LOG"; then
    FALLOS=$((FALLOS + 1)); printf 'FALLO  %-34s %3d s\n' "$1" "$seg"; grep -E "FALLO|SCRIPT ERROR" "$LOG" | head -3
  else
    printf 'OK     %-34s %3d s\n' "$1" "$seg"
  fi
}

# 1. Tamaño del código (norma de 450 líneas)
if [[ -n "$PARTE_I" ]] && [[ "$PARTE_I" != "0" ]]; then :  # (solo la parte 0 hace la norma de líneas)
else
python3 ../herramientas/revisar_lineas.py --todos > "$LOG" 2>&1
if grep -q "pasan de 450 líneas: 0" "$LOG"; then echo "OK     norma de 450 líneas"; else FALLOS=$((FALLOS + 1)); echo "FALLO  norma de 450 líneas"; head -5 "$LOG"; fi
fi
# 2. Todos los scripts compilan (el banco solo ve los que toca)
pasa "todos los scripts compilan" "godot --headless --path . --script res://pruebas/comprobar_scripts.gd" "FIN. 0 fallos"
# 2b. Las auditorías de datos y de clubes (base ficticia y real; ~9 s cada una; catálogo M-413, 27-10-2026) y la técnica
#     (shaders, escenas de juego y nodos huérfanos al abrir y cerrar la principal; M-470, 31-10)
pasa "auditoría de datos" "godot --headless --path . res://pruebas/auditoria_datos.tscn" "0 hallazgos"
pasa "auditoría técnica" "godot --headless --path . res://pruebas/auditoria_tecnica.tscn" "FIN AUDITORÍA TÉCNICA. 0 fallos"
pasa "auditoría de clubes" "godot --headless --path . res://pruebas/auditoria_clubes.tscn" "FIN. 0 fallos"
# 2c. Las partidas guardadas de versiones viejas siguen abriendo (1094, 27-10)
pasa "partidas viejas abren" "godot --headless --path . res://pruebas/ideas/sav_fosiles.tscn" "FIN. 0 fallos"
pasa "simular temporada con barra" "godot --headless --path . res://pruebas/ideas/sim_temporada_barra.tscn" "FIN. 0 fallos"
# 3. Colisiones del club (paredes, muebles, gente, barreras invisibles)
pasa "colisiones del club" "godot --headless --path . res://pruebas/prueba_colisiones_club.tscn" "FIN. 0 fallos"
# 4. Partido con el motor real (acta = césped) y control del equipo
pasa "partido con motor real" "godot --headless --path . res://pruebas/prueba_partido_motor.tscn" "0 fallos"
pasa "control del equipo" "godot --headless --path . res://pruebas/prueba_control_equipo.tscn" "0 fallos"
pasa "repetición del gol" "godot --headless --path . res://pruebas/prueba_repeticion.tscn" "REPETICIÓN: 0 fallos"
# 5. Modos de juego y menú de la ciudad a pie
pasa "modos de juego" "godot --headless --path . res://pruebas/prueba_modos.tscn" "0 fallos"
pasa "menú ciudad a pie" "godot --headless --path . res://pruebas/prueba_menu_ciudad_pie.tscn" "0 fallos"
# 5b. Las texturas de ruido en segundo plano son las de NoiseTexture2D, byte a byte (30-10)
pasa "ruidos en segundo plano" "godot --headless --path . res://pruebas/probar_ruidos_fondo.tscn" "FIN. 0 fallos"
pasa "textura del balón" "godot --headless --path . --script res://pruebas/probar_balon_textura.gd" "FIN. 0 fallos"
pasa "textura del césped" "godot --headless --path . res://pruebas/probar_cesped_textura.tscn" "FIN. 0 fallos"
pasa "texturas en disco (asfalto)" "godot --headless --path . res://pruebas/probar_imagen_en_disco.tscn" "FIN. 0 fallos"
pasa "extensión C++ = GDScript" "godot --headless --path . res://pruebas/probar_nativo.tscn" "FIN. 0 fallos"
pasa "caché horneada del build" "godot --headless --path . --script res://pruebas/probar_cache_horneada.gd" "FIN. 0 fallos"
pasa "estadio y ciudad por partes" "godot --headless --path . res://pruebas/probar_por_partes.tscn" "FIN. 0 fallos"
# 5b. Pruebas viejas que nadie lanzaba y siguen pasando (reutilizadas el 27-10, orden 14 del dueño)
pasa "calidad adaptativa (escalones)" "godot --headless --path . res://pruebas/probar_rendimiento_adaptativo.tscn" "probar_rendimiento_adaptativo: 0 fallos"
pasa "contador de FPS" "godot --headless --path . res://pruebas/prueba_contador_fps.tscn" "FIN CONTADOR FPS. 0 fallos"
pasa "dominadas" "godot --headless --path . res://pruebas/prueba_dominadas.tscn" "DOMINADAS: 0 fallos"
pasa "minijuego retro 5v5" "godot --headless --path . res://pruebas/ideas/m5_retro5v5.tscn" "FIN. 0 fallos"
pasa "barrida, saque de mano, caídas y bloqueos" "godot --headless --path . res://pruebas/ideas/p4_saque_barrida.tscn" "FIN. 0 fallos"
pasa "A4 cruzado: partido simulado con equipos absurdos y tarjetas reales" "godot --headless --path . res://pruebas/ideas/a4_partido_cruzado.tscn" "FIN. 0 fallos"
pasa "A4 gestión al límite (8 temporadas, guardado exacto, absurdos)" "godot --headless --path . res://pruebas/ideas/a4_gestion_limite.tscn" "FIN. 0 fallos"
pasa "fallos de League-Soccer (posesión, menos de siete, libres)" "godot --headless --path . res://pruebas/ideas/fallos_terceros.tscn" "FIN. 0 fallos"
pasa "la pizarra se nota (simulado y 3D)" "godot --headless --path . res://pruebas/ideas/j4_pizarra.tscn" "FIN. 0 fallos"
pasa "el partido simulado tiene vida" "godot --headless --path . res://pruebas/ideas/j4_partido_vivo.tscn" "FIN. 0 fallos"
pasa "el partido reacciona (clima, arenga, riesgo, plan)" "godot --headless --path . res://pruebas/ideas/j4_partido_reacciones.tscn" "FIN. 0 fallos"
pasa "sonidos de sistema (todos existen, buses, silencio)" "godot --headless --path . res://pruebas/ideas/s7_sonidos_sistema.tscn" "FIN. 0 fallos"
pasa "minijuegos 3D (penales y tiro libre)" "godot --headless --path . res://pruebas/ideas/m4_minijuegos_3d.tscn" "FIN. 0 fallos"
pasa "el entrenamiento se nota" "godot --headless --path . res://pruebas/ideas/j9_entrenamiento.tscn" "FIN. 0 fallos"
pasa "portero de la Carrera" "godot --headless --path . res://pruebas/ideas/cpor_portero.tscn" "FIN. 0 fallos"
pasa "penales en partido: ~75 % marcados (sonda)" "godot --headless --path . res://pruebas/ideas/sonda_penales.tscn" "FIN. 0 fallos"
pasa "aviso de amarillas antes de la sanción (U6)" "godot --headless --path . res://pruebas/ideas/u6_amarillas.tscn" "FIN. 0 fallos"
pasa "coste del viaje y del día de partido desglosado (U6)" "godot --headless --path . res://pruebas/ideas/u6_viaje.tscn" "FIN. 0 fallos"
pasa "pago con tarjeta y PIN en tienda, gasolinera y expendedora (U6)" "godot --headless --path . res://pruebas/ideas/u6_tarjeta.tscn" "FIN. 0 fallos"
pasa "salida de equipos y sorteo sin cuerpos cruzados (U6)" "godot --headless --path . res://pruebas/ideas/ceremonia_cruces.tscn" "FIN. 0 fallos"
pasa "ahorro en los menús: fondos congelados en MÍNIMA (3-11)" "godot --headless --path . res://pruebas/ideas/ahorro_menus.tscn" "FIN. 0 fallos"
pasa "ruido de registros: arreglos (3-11)" "godot --headless --path . res://pruebas/ideas/ruido_arreglos.tscn" "FIN. 0 fallos"
pasa "siglas y códigos cortos (3-11)" "godot --headless --path . res://pruebas/ideas/codigos_siglas.tscn" "FIN. 0 fallos"
pasa "cifras del partido simulado contra el fútbol real (3-11)" "godot --headless --path . res://pruebas/ideas/cifras_partido.tscn" "FIN. 0 fallos"
pasa "el menú no carga el estadio ni el partido 3D (3-11)" "godot --headless --path . res://pruebas/ideas/mem_menu_estadio.tscn" "FIN. 0 fallos"
pasa "guardado: autoguardado en segundo plano y pregunta al salir (3-11)" "godot --headless --path . res://pruebas/ideas/gua_autoguardado_salir.tscn" "FIN. 0 fallos"
pasa "atajos de teclado por menú y submenú (3-11)" "godot --headless --path . res://pruebas/ideas/ate_atajos_menus.tscn" "FIN. 0 fallos"
pasa "ate_ayuda_en_menu" "godot --headless --path . res://pruebas/ideas/ate_ayuda_en_menu.tscn" "(^|[^0-9])0 fallos"
pasa "aud4_idiomas_cache" "godot --headless --path . res://pruebas/ideas/aud4_idiomas_cache.tscn" "FIN. 0 fallos"
pasa "aud4_carteles_3d" "godot --headless --path . res://pruebas/ideas/aud4_carteles_3d.tscn" "FIN. 0 fallos"
pasa "aud4_movil_toque" "godot --headless --path . res://pruebas/ideas/aud4_movil_toque.tscn" "FIN. 0 fallos"
pasa "aud4_movil_flujo" "godot --headless --path . res://pruebas/ideas/aud4_movil_flujo.tscn" "FIN. 0 fallos"
pasa "aud4_teclado_solo" "godot --headless --path . res://pruebas/ideas/aud4_teclado_solo.tscn" "FIN. 0 fallos"
pasa "aud4_movil_partido" "godot --headless --path . res://pruebas/ideas/aud4_movil_partido.tscn" "FIN. 0 fallos"
pasa "aud4_movil_modales" "godot --headless --path . res://pruebas/ideas/aud4_movil_modales.tscn" "FIN. 0 fallos"
pasa "aud4_primer_contacto" "godot --headless --path . res://pruebas/ideas/aud4_primer_contacto.tscn" "FIN. 0 fallos"
pasa "aud4_tutorial_movil" "godot --headless --path . res://pruebas/ideas/aud4_tutorial_movil.tscn" "FIN. 0 fallos"
pasa "aud4_prologo_movil" "godot --headless --path . res://pruebas/ideas/aud4_prologo_movil.tscn" "FIN. 0 fallos"
pasa "aud4_arranque_movil" "godot --headless --path . res://pruebas/ideas/aud4_arranque_movil.tscn" "FIN. 0 fallos"
pasa "aud4_sonido_perezoso" "godot --headless --path . res://pruebas/ideas/aud4_sonido_perezoso.tscn" "FIN. 0 fallos"
pasa "aud4_interfaz_limite" "godot --headless --path . res://pruebas/ideas/aud4_interfaz_limite.tscn" "FIN. 0 fallos"
pasa "aud4_largo_plazo_ui" "LIMITE_S=120 godot --headless --path . res://pruebas/ideas/aud4_largo_plazo_ui.tscn" "FIN. 0 fallos"
pasa "act_actualizador" "godot --headless --path . res://pruebas/ideas/act_actualizador.tscn" "FIN. 0 fallos"
pasa "caché en disco del audio sintetizado (R5)" "godot --headless --path . res://pruebas/ideas/r5_cache_audio.tscn" "FIN. 0 fallos"
pasa "arena de pruebas (cada modo monta lo que dice)" "godot --headless --path . res://pruebas/ideas/arena_humo.tscn" "FIN. 0 fallos"
pasa "triángulo sobre el jugador controlado (P2)" "godot --headless --path . res://pruebas/ideas/p2_triangulo.tscn" "FIN. 0 fallos"
pasa "pasos y guardia del portero" "godot --headless --path . res://pruebas/ideas/pani_pasos.tscn" "FIN. 0 fallos"
pasa "minijuegos nuevos" "godot --headless --path . res://pruebas/prueba_minijuegos_nuevos.tscn" "FIN MINIJUEGOS NUEVOS. 0 fallos"
pasa "igualdad del mundo simulado (balance)" "godot --headless --path . res://pruebas/igualdad_mundo.tscn" "FIN. 0 fallos"
pasa "interpolación de la física del partido" "godot --headless --path . res://pruebas/ideas/int_partido.tscn" "FIN. 0 fallos"
pasa "igualdad del motor con usuario" "godot --headless --path . res://pruebas/igualdad_motor.tscn" "FIN. 0 fallos"
pasa "motor jugable (unidad)" "godot --headless --path . res://pruebas/prueba_motor_jugable.tscn" "FIN MOTOR. 0 fallos"
# 5c. Movimiento suave y vida de la ciudad (27-10, orden del líder: que el tirón de los vehículos no vuelva a romperse sin que se note; ~1 min)
pasa "tráfico, metro y bus suaves" "godot --headless --path . res://pruebas/ideas/pmov_suavidad_trafico.tscn" "FIN. 0 fallos"
pasa "fugas en sesiones largas, partido táctil (auditoría 4: 24 partidos 3D jugados, abandonados, en pausa y cerrados con atrás: nodos, objetos, memoria, señales, voces)" "godot --headless --path . res://pruebas/auditoria_fugas_limite.tscn" "FIN. 0 fallos"
pasa "guardado antes y después del partido de la carrera, partidos abandonados, carrera del jugador (auditoría 4)" "godot --headless --path . res://pruebas/auditoria_guardado_partido_limite.tscn" "FIN. 0 fallos"
pasa "fotogramas malos al límite (auditoría 4: pasos grandes, 5 FPS y tirones = mismo estado que a 60 FPS, repetición con cambio)" "godot --headless --path . res://pruebas/auditoria_fps_malos_limite.tscn" "FIN. 0 fallos"
pasa "reglas del partido al límite (auditoría 4: 7 y 6 jugadores, lesionado sin cambios, portero lesionado, cambio en tanda y descanso, banco vacío)" "godot --headless --path . res://pruebas/auditoria_reglas_3d_limite.tscn" "FIN. 0 fallos"
pasa "atrás en el tutorial y el prólogo, música en segundo plano (auditoría 4, menú táctil)" "godot --headless --path . res://pruebas/auditoria_atras_pantallas_limite.tscn" "FIN. 0 fallos"
pasa "partido táctil al límite en el móvil (auditoría 4: 50 pausas con giro y calidad, segundo plano en descanso, tanda y repetición)" "godot --headless --path . res://pruebas/auditoria_partido_movil_limite.tscn" "FIN. 0 fallos"
pasa "tráfico: derecha y adelantar" "godot --headless --path . res://pruebas/ideas/tra_adelantar_y_derecha.tscn" "FIN. 0 fallos"
pasa "emergencias y sirenas" "godot --headless --path . res://pruebas/ideas/emerg_servicios.tscn" "FIN. 0 fallos"
pasa "vida de la app fuera del partido, menú táctil (auditoría 4: segundo plano pausa el árbol, atrás cierra ventana/pantalla/pregunta, poca memoria)" "godot --headless --path . res://pruebas/auditoria_vida_global_limite.tscn" "FIN. 0 fallos"
pasa "el tráfico cede a las sirenas" "godot --headless --path . res://pruebas/ideas/emerg_cede_paso.tscn" "FIN. 0 fallos"
pasa "estación y trenes" "godot --headless --path . res://pruebas/ideas/tre_estacion.tscn" "FIN. 0 fallos"
pasa "vida de la app en el móvil al límite, partido táctil (auditoría 4: segundo plano, atrás, foco, girar, poca memoria, delta de 10 minutos)" "godot --headless --path . res://pruebas/auditoria_vida_app_limite.tscn" "FIN. 0 fallos"
pasa "teleférico" "godot --headless --path . res://pruebas/ideas/tre_teleferico.tscn" "FIN. 0 fallos"
pasa "aspecto de los clubes" "godot --headless --path . res://pruebas/ideas/asp_clubes.tscn" "FIN. 0 fallos"
pasa "partido en vivo al límite (auditoría 4: 9 idiomas sin marcas sueltas, velocidades con saltos absurdos, descanso, saltos al final)" "godot --headless --path . res://pruebas/auditoria_partido_vivo_limite.tscn" "FIN. 0 fallos"
pasa "sonido al límite (auditoría 4: 400 efectos, volúmenes 0/NaN/1e9, nombres que no existen, música)" "godot --headless --path . res://pruebas/auditoria_sonido_limite.tscn" "FIN. 0 fallos"
pasa "trofeos por competición" "godot --headless --path . res://pruebas/ideas/tro_recetas.tscn" "FIN. 0 fallos"
pasa "arbitros y VAR al límite (auditoría 4: márgenes absurdos, tarjetas repetidas, gol anulado tras el final, expulsión doble)" "godot --headless --path . res://pruebas/auditoria_arbitro_limite.tscn" "FIN. 0 fallos"
pasa "dificultad_cpu en el partido jugable de la carrera (el rival es la CPU con el nivel guardado)" "godot --headless --path . res://pruebas/dificultad_partido_jugable.tscn" "FIN. 0 fallos"
pasa "carrera del jugador al límite (auditoría 4: puestos, atributos 1 y 99, lesión grave, club sin plantel, retiro, guardado roto)" "godot --headless --path . res://pruebas/auditoria_carrera_limite.tscn" "FIN. 0 fallos"
pasa "minijuegos 2D al límite (auditoría 4: teclas dobles, idioma y calidad a mitad, Escape, sin mundo)" "godot --headless --path . res://pruebas/auditoria_minijuegos_limite.tscn" "FIN. 0 fallos"
pasa "app Red del móvil" "godot --headless --path . res://pruebas/ideas/red_app.tscn" "FIN. 0 fallos"
pasa "palmarés en la historia del club" "godot --headless --path . res://pruebas/ideas/pal_clubes.tscn" "FIN. 0 fallos"
pasa "partido jugable 3D al límite con mando táctil (auditoría 4: toques al azar, pausas, calidad a mitad, expulsiones hasta 5, gol en cada calidad)" "godot --headless --path . res://pruebas/auditoria_partido3d_limite.tscn" "FIN. 0 fallos"
pasa "Países Bajos real y ficticio" "godot --headless --path . res://pruebas/ideas/c1_paises_bajos.tscn" "FIN. 0 fallos"
pasa "controles táctiles del partido" "godot --headless --path . res://pruebas/ideas/tac_controles.tscn" "FIN. 0 fallos"
pasa "partido al límite (auditoría 4: pasos de tiempo absurdos, actas, tarjetas amarillas y notas)" "godot --headless --path . res://pruebas/auditoria_partido_limite.tscn" "FIN. 0 fallos"
pasa "interfaz al límite (auditoría 4: 100 aperturas de menú, idioma a mitad, texto 160 %, 2400x1080 y 1280x720)" "godot --headless --path . res://pruebas/auditoria_interfaz_limite.tscn" "FIN. 0 fallos"
pasa "HUD y cámara del partido en el móvil (mide mm de letra y distancia de cámara)" "godot --headless --path . res://pruebas/ideas/tac_hud.tscn" "FIN. 0 fallos"
# 6. Todas las pantallas y botones de la interfaz (lento)
# 5d. ESCENAS DE PRUEBA REUTILIZADAS (2-11-2026, orden 14 del dueño: «ver qué se puede reutilizar antes de borrar»). Eran escenas que nadie
#     lanzaba (ni banco, ni especiales, ni CI ni documentos); se corrieron una por una y las que pasan quedan aquí. Cada una cuesta ~10 s
#     (casi todo es el arranque de Godot): en el CI se reparten entre las partes de `ESPECIALES_PARTE`. `ESPECIALES_SOLO=reutilizadas` corre solo este bloque.
BLOQUE=reutilizadas
pasa "ciudad: construir y soltar 5 veces sin fugas (A4-M3D-001)" "godot --headless --path . res://pruebas/ideas/a4_m3d_ciclos.tscn" "FIN. 0 fallos"
pasa "estadio: construir y soltar 5 veces sin fugas (A4-M3D-002)" "godot --headless --path . res://pruebas/ideas/a4_m3d_estadio_ciclos.tscn" "FIN. 0 fallos"
pasa "ciudad en marcha 600 fotogramas sin acumular nada (A4-M3D)" "godot --headless --path . res://pruebas/ideas/a4_m3d_tiempo.tscn" "FIN. 0 fallos"
pasa "carteles 3D perezosos: existen los cercanos y solo esos (A4-REND-004)" "godot --headless --path . res://pruebas/ideas/a4_rotulos_perezosos.tscn" "FIN. 0 fallos"
pasa "banco_inicio" "XDG_DATA_HOME=\$(mktemp -d) godot --headless --path . res://pruebas/banco_inicio.tscn" "(^|[^0-9])0 fallos"
pasa "bug_semilla" "godot --headless --path . res://pruebas/ideas/bug_semilla.tscn" "(^|[^0-9])0 fallos"
pasa "cierre_anio_deudas" "godot --headless --path . res://pruebas/ideas/cierre_anio_deudas.tscn" "(^|[^0-9])0 fallos"
pasa "clau_descenso_entreno" "godot --headless --path . res://pruebas/ideas/clau_descenso_entreno.tscn" "(^|[^0-9])0 fallos"
pasa "cpor_portero" "godot --headless --path . res://pruebas/ideas/cpor_portero.tscn" "(^|[^0-9])0 fallos"
pasa "desa_leyenda" "godot --headless --path . res://pruebas/ideas/desa_leyenda.tscn" "(^|[^0-9])0 fallos"
pasa "desa_sin_dinero" "godot --headless --path . res://pruebas/ideas/desa_sin_dinero.tscn" "(^|[^0-9])0 fallos"
pasa "desa_sin_red" "godot --headless --path . res://pruebas/ideas/desa_sin_red.tscn" "(^|[^0-9])0 fallos"
pasa "disc_amarillas" "godot --headless --path . res://pruebas/ideas/disc_amarillas.tscn" "(^|[^0-9])0 fallos"
pasa "ent1_unico_camino" "godot --headless --path . res://pruebas/ideas/ent1_unico_camino.tscn" "(^|[^0-9])0 fallos"
pasa "exim_exportar_importar" "godot --headless --path . res://pruebas/ideas/exim_exportar_importar.tscn" "(^|[^0-9])0 fallos"
pasa "f0d_tablas" "godot --headless --path . res://pruebas/ideas/f0d_tablas.tscn" "(^|[^0-9])0 fallos"
pasa "f0m_nucleo" "godot --headless --path . res://pruebas/ideas/f0m_nucleo.tscn" "(^|[^0-9])0 fallos"
pasa "f0m_visor_datos" "godot --headless --path . res://pruebas/ideas/f0m_visor_datos.tscn" "(^|[^0-9])0 fallos"
pasa "f0m_visor_estadio" "godot --headless --path . res://pruebas/ideas/f0m_visor_estadio.tscn" "(^|[^0-9])0 fallos"
pasa "f0p_principal" "godot --headless --path . res://pruebas/ideas/f0p_principal.tscn" "(^|[^0-9])0 fallos"
pasa "f0r_reloj" "godot --headless --path . res://pruebas/ideas/f0r_reloj.tscn" "(^|[^0-9])0 fallos"
pasa "f1e_entrada_campeonato" "godot --headless --path . res://pruebas/ideas/f1e_entrada_campeonato.tscn" "(^|[^0-9])0 fallos"
pasa "f1e_pantalla_entrada" "godot --headless --path . res://pruebas/ideas/f1e_pantalla_entrada.tscn" "(^|[^0-9])0 fallos"
pasa "f1m_modos" "godot --headless --path . res://pruebas/ideas/f1m_modos.tscn" "(^|[^0-9])0 fallos"
pasa "f1p_personaje" "godot --headless --path . res://pruebas/ideas/f1p_personaje.tscn" "(^|[^0-9])0 fallos"
pasa "f9_galeria_kit" "godot --headless --path . res://pruebas/ideas/f9_galeria_kit.tscn" "(^|[^0-9])0 fallos"
pasa "fnt_idioma_vivo" "godot --headless --path . res://pruebas/ideas/fnt_idioma_vivo.tscn" "(^|[^0-9])0 fallos"
pasa "fz0_globo_crear" "godot --headless --path . res://pruebas/ideas/fz0_globo_crear.tscn" "(^|[^0-9])0 fallos"
pasa "m414_simetria" "godot --headless --path . res://pruebas/ideas/m414_simetria.tscn" "(^|[^0-9])0 fallos"
pasa "m462_glifos" "godot --headless --path . res://pruebas/ideas/m462_glifos.tscn" "(^|[^0-9])0 fallos"
pasa "mc_contratos" "godot --headless --path . res://pruebas/ideas/mc_contratos.tscn" "(^|[^0-9])0 fallos"
pasa "mer_precontratos" "godot --headless --path . res://pruebas/ideas/mer_precontratos.tscn" "(^|[^0-9])0 fallos"
pasa "onb_arranque" "godot --headless --path . res://pruebas/ideas/onb_arranque.tscn" "(^|[^0-9])0 fallos"
pasa "p3_grada_colores" "godot --headless --path . res://pruebas/ideas/p3_grada_colores.tscn" "(^|[^0-9])0 fallos"
pasa "p6_pasto_drive" "godot --headless --path . res://pruebas/ideas/p6_pasto_drive.tscn" "(^|[^0-9])0 fallos"
pasa "p6_rotulos_cartel" "godot --headless --path . res://pruebas/ideas/p6_rotulos_cartel.tscn" "(^|[^0-9])0 fallos"
pasa "p6_boton_e_minimapa" "godot --headless --path . res://pruebas/ideas/p6_boton_e_minimapa.tscn" "(^|[^0-9])0 fallos"
pasa "p6_mando_tactil" "godot --headless --path . res://pruebas/ideas/p6_mando_tactil.tscn" "(^|[^0-9])0 fallos"
pasa "p6_zonas_vista" "godot --headless --path . res://pruebas/ideas/p6_zonas_vista.tscn" "(^|[^0-9])0 fallos"
pasa "p6_entorno_oclusion" "godot --headless --path . res://pruebas/ideas/p6_entorno_oclusion.tscn" "(^|[^0-9])0 fallos"
pasa "a4_partido_ligero (agregado aparte de la calidad, orden 32)" "godot --headless --path . res://pruebas/ideas/a4_partido_ligero.tscn" "FIN. 0 fallos"
pasa "p6_peaje" "godot --headless --path . res://pruebas/ideas/p6_peaje.tscn" "(^|[^0-9])0 fallos"
pasa "p6_alcance_e" "godot --headless --path . res://pruebas/ideas/p6_alcance_e.tscn" "(^|[^0-9])0 fallos"
pasa "p6_resolucion3d" "godot --headless --path . res://pruebas/ideas/p6_resolucion3d.tscn" "(^|[^0-9])0 fallos"
pasa "a4_recorrido_mapa" "godot --headless --path . res://pruebas/ideas/a4_recorrido_mapa.tscn" "(^|[^0-9])0 fallos"
pasa "a4_peatones_limite" "godot --headless --path . res://pruebas/ideas/a4_peatones_limite.tscn" "(^|[^0-9])0 fallos"
pasa "a4_interiores_limite" "godot --headless --path . res://pruebas/ideas/a4_interiores_limite.tscn" "(^|[^0-9])0 fallos"
pasa "a4_camara_estadio (la cámara del partido ve el campo en 6 estadios reformados, rayos por triángulo)" "godot --headless --path . res://pruebas/ideas/a4_camara_estadio.tscn" "(^|[^0-9])0 fallos"
pasa "a4_ciudad_noche (de noche, 6 sirenas, 6 min: sin atascos, gente ni buses parados)" "godot --headless --path . res://pruebas/ideas/a4_ciudad_noche.tscn" "(^|[^0-9])0 fallos"
pasa "a4_sirena_movimiento (vehículo de emergencia con sirena en medio del tráfico: no atraviesa a nadie)" "godot --headless --path . res://pruebas/ideas/a4_sirena_movimiento.tscn" "(^|[^0-9])0 fallos"
pasa "a4_lluvia_cambios (lluvia y paraguas con 172 peatones de noche, 20 cambios de clima: sin duplicados, sin restos, sin crecer)" "godot --headless --path . res://pruebas/ideas/a4_lluvia_cambios.tscn" "(^|[^0-9])0 fallos"
pasa "a4_museo_limite (museo con 220 hitos: vitrinas y rótulos sin pisarse, ampliar, 20 entradas y la animación cortada)" "godot --headless --path . res://pruebas/ideas/a4_museo_limite.tscn" "(^|[^0-9])0 fallos"
pasa "a4_pasajeros_limite (gente de bus y teleférico: bus lleno, bus que se va, 60 paradas)" "godot --headless --path . res://pruebas/ideas/a4_pasajeros_limite.tscn" "(^|[^0-9])0 fallos"
pasa "a4_comercios_horario (comercios de 8:00 a 20:00 por el reloj del juego: cerrado no entra ni compra)" "godot --headless --path . res://pruebas/ideas/a4_comercios_horario.tscn" "(^|[^0-9])0 fallos"
pasa "a4_metro_museo (metro por dentro y museo ampliado, sin pantalla)" "godot --headless --path . res://pruebas/ideas/a4_metro_museo.tscn" "(^|[^0-9])0 fallos"
pasa "a4_gestion_cruzado" "godot --headless --path . res://pruebas/ideas/a4_gestion_cruzado.tscn" "(^|[^0-9])0 fallos"
pasa "a4_gestion_cesiones" "godot --headless --path . res://pruebas/ideas/a4_gestion_cesiones.tscn" "(^|[^0-9])0 fallos"
pasa "a4_gestion_mercado_fed" "godot --headless --path . res://pruebas/ideas/a4_gestion_mercado_fed.tscn" "(^|[^0-9])0 fallos"
pasa "a4_noticias_idiomas" "godot --headless --path . res://pruebas/ideas/a4_noticias_idiomas.tscn" "(^|[^0-9])0 fallos"
pasa "a4_gestion_directiva" "godot --headless --path . res://pruebas/ideas/a4_gestion_directiva.tscn" "(^|[^0-9])0 fallos"
pasa "a4_gestion_prensa" "godot --headless --path . res://pruebas/ideas/a4_gestion_prensa.tscn" "(^|[^0-9])0 fallos"
pasa "a4_gestion_entrenamiento" "godot --headless --path . res://pruebas/ideas/a4_gestion_entrenamiento.tscn" "(^|[^0-9])0 fallos"
pasa "a4_gestion_estadio" "godot --headless --path . res://pruebas/ideas/a4_gestion_estadio.tscn" "(^|[^0-9])0 fallos"
pasa "a4_gestion_museo_cantera" "godot --headless --path . res://pruebas/ideas/a4_gestion_museo_cantera.tscn" "(^|[^0-9])0 fallos"
pasa "a4_gestion_selecciones" "godot --headless --path . res://pruebas/ideas/a4_gestion_selecciones.tscn" "(^|[^0-9])0 fallos"
# a4_limite_mundo (partido en 3 de ~190, ~190 y ~150 s para caber holgado en los 600 s) necesita pantalla virtual (opengl3): el contenedor del CI no trae xvfb-run (A4, 4-11), como el bloque 6a
if command -v xvfb-run >/dev/null; then
pasa "a4_limite_mundo (1/3 calidad: fugas al reabrir)" "A4_PARTE=1 xvfb-run -a godot --rendering-driver opengl3 --resolution 640x360 --path . res://pruebas/ideas/a4_limite_mundo.tscn" "(^|[^0-9])0 fallos"
pasa "a4_metro_museo 1/2 (metro por dentro, con pantalla: ~250 s)" "A4_PARTE=1 xvfb-run -a godot --rendering-driver opengl3 --resolution 640x360 --path . res://pruebas/ideas/a4_metro_museo.tscn" "(^|[^0-9])0 fallos"
pasa "a4_metro_museo 2/2 (museo ampliado, con pantalla: ~120 s)" "A4_PARTE=2 xvfb-run -a godot --rendering-driver opengl3 --resolution 640x360 --path . res://pruebas/ideas/a4_metro_museo.tscn" "(^|[^0-9])0 fallos"
pasa "a4_limite_mundo (2/3 calidad y horas)" "A4_PARTE=2 xvfb-run -a godot --rendering-driver opengl3 --resolution 640x360 --path . res://pruebas/ideas/a4_limite_mundo.tscn" "(^|[^0-9])0 fallos"
pasa "a4_limite_mundo (3/3 estadios y tráfico)" "A4_PARTE=3 xvfb-run -a godot --rendering-driver opengl3 --resolution 640x360 --path . res://pruebas/ideas/a4_limite_mundo.tscn" "(^|[^0-9])0 fallos"
pasa "a4_estadio_reformas (estadio propio: 6 reformas, reabrir, nombres; con pantalla ~115 s)" "xvfb-run -a godot --rendering-driver opengl3 --resolution 640x360 --path . res://pruebas/ideas/a4_estadio_reformas.tscn" "(^|[^0-9])0 fallos"
pasa "a4_grada_alta (la grada crece con el aforo >30 000 solo en calidad ALTA; con pantalla ~60 s)" "xvfb-run -a godot --rendering-driver opengl3 --resolution 640x360 --path . res://pruebas/ideas/a4_grada_alta.tscn" "(^|[^0-9])0 fallos"
fi
pasa "p6_calidad_minima" "godot --headless --path . res://pruebas/ideas/p6_calidad_minima.tscn" "(^|[^0-9])0 fallos"
pasa "p6_idiomas_perezoso" "godot --headless --path . res://pruebas/ideas/p6_idiomas_perezoso.tscn" "(^|[^0-9])0 fallos"
pasa "p6_ropero" "godot --headless --path . res://pruebas/ideas/p6_ropero.tscn" "(^|[^0-9])0 fallos"
pasa "p6_metro_publicidad" "godot --headless --path . res://pruebas/ideas/p6_metro_publicidad.tscn" "(^|[^0-9])0 fallos"
pasa "p6_banderas_grada" "godot --headless --path . res://pruebas/ideas/p6_banderas_grada.tscn" "(^|[^0-9])0 fallos"
pasa "p6_bus_dt" "godot --headless --path . res://pruebas/ideas/p6_bus_dt.tscn" "(^|[^0-9])0 fallos"
pasa "p6_camiseta_rapida" "godot --headless --path . res://pruebas/ideas/p6_camiseta_rapida.tscn" "(^|[^0-9])0 fallos"
pasa "p6_carga_diferida" "godot --headless --path . res://pruebas/ideas/p6_carga_diferida.tscn" "(^|[^0-9])0 fallos"
pasa "p6_celebracion_trofeo" "godot --headless --path . res://pruebas/ideas/p6_celebracion_trofeo.tscn" "(^|[^0-9])0 fallos"
pasa "p6_cierre_ciudad" "godot --headless --path . res://pruebas/ideas/p6_cierre_ciudad.tscn" "(^|[^0-9])0 fallos"
pasa "p6_escala_movil" "godot --headless --path . res://pruebas/ideas/p6_escala_movil.tscn" "(^|[^0-9])0 fallos"
pasa "p6_habitantes_casa" "godot --headless --path . res://pruebas/ideas/p6_habitantes_casa.tscn" "(^|[^0-9])0 fallos"
pasa "p6_pantalla_carga" "godot --headless --path . res://pruebas/ideas/p6_pantalla_carga.tscn" "(^|[^0-9])0 fallos"
pasa "p6_pasajeros_teleferico" "godot --headless --path . res://pruebas/ideas/p6_pasajeros_teleferico.tscn" "(^|[^0-9])0 fallos"
pasa "p6_peatones_cruce" "godot --headless --path . res://pruebas/ideas/p6_peatones_cruce.tscn" "(^|[^0-9])0 fallos"
pasa "p6_rutina_peatones" "godot --headless --path . res://pruebas/ideas/p6_rutina_peatones.tscn" "(^|[^0-9])0 fallos"
pasa "p6_salas_comercio" "godot --headless --path . res://pruebas/ideas/p6_salas_comercio.tscn" "(^|[^0-9])0 fallos"
pasa "p6_semaforo_peatonal" "godot --headless --path . res://pruebas/ideas/p6_semaforo_peatonal.tscn" "(^|[^0-9])0 fallos"
pasa "p6_senales_velocidad" "godot --headless --path . res://pruebas/ideas/p6_senales_velocidad.tscn" "(^|[^0-9])0 fallos"
pasa "p6_tarjeta_transporte" "godot --headless --path . res://pruebas/ideas/p6_tarjeta_transporte.tscn" "(^|[^0-9])0 fallos"
pasa "f0m_visor_ciudad" "godot --headless --path . res://pruebas/ideas/f0m_visor_ciudad.tscn" "(^|[^0-9])0 fallos"
pasa "pc_primer_contrato" "godot --headless --path . res://pruebas/ideas/pc_primer_contrato.tscn" "(^|[^0-9])0 fallos"
pasa "pcam_encuadre" "godot --headless --path . res://pruebas/ideas/pcam_encuadre.tscn" "(^|[^0-9])0 fallos"
pasa "pcam_repeticion" "godot --headless --path . res://pruebas/ideas/pcam_repeticion.tscn" "(^|[^0-9])0 fallos"
pasa "pcar_agenda" "godot --headless --path . res://pruebas/ideas/pcar_agenda.tscn" "(^|[^0-9])0 fallos"
pasa "pcar_avisos_idioma" "godot --headless --path . res://pruebas/ideas/pcar_avisos_idioma.tscn" "(^|[^0-9])0 fallos"
pasa "pcar_tiro" "godot --headless --path . res://pruebas/ideas/pcar_tiro.tscn" "(^|[^0-9])0 fallos"
pasa "pciu_luces_calle" "godot --headless --path . res://pruebas/ideas/pciu_luces_calle.tscn" "(^|[^0-9])0 fallos"
pasa "pint_charla" "godot --headless --path . res://pruebas/ideas/pint_charla.tscn" "(^|[^0-9])0 fallos"
pasa "pint_vestuario" "godot --headless --path . res://pruebas/ideas/pint_vestuario.tscn" "(^|[^0-9])0 fallos"
pasa "plan_costumbre" "godot --headless --path . res://pruebas/ideas/plan_costumbre.tscn" "(^|[^0-9])0 fallos"
pasa "pmot_control" "godot --headless --path . res://pruebas/ideas/pmot_control.tscn" "(^|[^0-9])0 fallos"
pasa "pmot_faltas" "godot --headless --path . res://pruebas/ideas/pmot_faltas.tscn" "(^|[^0-9])0 fallos"
pasa "pmov_peatones_esquivan" "godot --headless --path . res://pruebas/ideas/pmov_peatones_esquivan.tscn" "(^|[^0-9])0 fallos"
pasa "r6b_rueda_prensa" "godot --headless --path . res://pruebas/ideas/r6b_rueda_prensa.tscn" "(^|[^0-9])0 fallos"
pasa "red_apagon" "godot --headless --path . res://pruebas/ideas/red_apagon.tscn" "(^|[^0-9])0 fallos"
pasa "reg_registro" "godot --headless --path . res://pruebas/ideas/reg_registro.tscn" "(^|[^0-9])0 fallos"
pasa "s2p_peticiones" "godot --headless --path . res://pruebas/ideas/s2p_peticiones.tscn" "(^|[^0-9])0 fallos"
pasa "s3f_fisica" "godot --headless --path . res://pruebas/ideas/s3f_fisica.tscn" "(^|[^0-9])0 fallos"
pasa "s3p_salida_centros" "godot --headless --path . res://pruebas/ideas/s3p_salida_centros.tscn" "(^|[^0-9])0 fallos"
pasa "s6_paises_lote1" "godot --headless --path . res://pruebas/ideas/s6_paises_lote1.tscn" "(^|[^0-9])0 fallos"
pasa "s6r_retos_semana" "godot --headless --path . res://pruebas/ideas/s6r_retos_semana.tscn" "(^|[^0-9])0 fallos"
pasa "s7b_bloqueo_modos" "godot --headless --path . res://pruebas/ideas/s7b_bloqueo_modos.tscn" "(^|[^0-9])0 fallos"
pasa "s7d_doble_toque" "godot --headless --path . res://pruebas/ideas/s7d_doble_toque.tscn" "(^|[^0-9])0 fallos"
pasa "s7m_mentor_mes" "godot --headless --path . res://pruebas/ideas/s7m_mentor_mes.tscn" "(^|[^0-9])0 fallos"
pasa "s7t_tutorial_capas" "godot --headless --path . res://pruebas/ideas/s7t_tutorial_capas.tscn" "(^|[^0-9])0 fallos"
pasa "s7x_desafios_dificultad" "godot --headless --path . res://pruebas/ideas/s7x_desafios_dificultad.tscn" "(^|[^0-9])0 fallos"
pasa "trad_prensa" "godot --headless --path . res://pruebas/ideas/trad_prensa.tscn" "(^|[^0-9])0 fallos"
pasa "trad_tutorial" "godot --headless --path . res://pruebas/ideas/trad_tutorial.tscn" "(^|[^0-9])0 fallos"
pasa "tut_guia_visible" "godot --headless --path . res://pruebas/ideas/tut_guia_visible.tscn" "(^|[^0-9])0 fallos"
pasa "tre_coches" "godot --headless --path . res://pruebas/ideas/tre_coches.tscn" "(^|[^0-9])0 fallos"
pasa "zz_alt" "godot --headless --path . res://pruebas/ideas/zz_alt.tscn" "(^|[^0-9])0 fallos"
pasa "timing_disparo_jugadas" "godot --headless --path . res://pruebas/timing_disparo_jugadas.tscn" "(^|[^0-9])0 fallos"
# 5d. PRUEBAS POR SISTEMA (5-11, rama sonar/bancos): `pruebas/so/LISTA.txt`; cada una imprime «OK|FALLO <nombre> [<sistema>]» y sabe qué espera de su sistema.
#     Las que necesitan pantalla (xvfb, Vulkan o OpenGL) van en el bloque «todo». Todas a la vez: `python3 herramientas/pruebas_so.py` (Windows/macOS también).
#     LISTA.txt y estas líneas deben coincidir: `python3 herramientas/pruebas_so.py --sincronia`.
BLOQUE=so
pasa "so: com_idiomas_nueve_sin_vacios" "godot --headless --path . res://pruebas/so/com_idiomas_nueve_sin_vacios.tscn" "^OK com_idiomas_nueve_sin_vacios "
pasa "so: com_idiomas_cambio_en_vivo" "godot --headless --path . res://pruebas/so/com_idiomas_cambio_en_vivo.tscn" "^OK com_idiomas_cambio_en_vivo "
pasa "so: com_guardado_ida_vuelta" "godot --headless --path . res://pruebas/so/com_guardado_ida_vuelta.tscn" "^OK com_guardado_ida_vuelta "
pasa "so: com_arranque_autoloads" "godot --headless --path . res://pruebas/so/com_arranque_autoloads.tscn" "^OK com_arranque_autoloads "
pasa "so: com_entrada_por_sistema" "godot --headless --path . res://pruebas/so/com_entrada_por_sistema.tscn" "^OK com_entrada_por_sistema "
pasa "so: err_guardado_danado" "godot --headless --path . res://pruebas/so/err_guardado_danado.tscn" "^OK err_guardado_danado "
pasa "so: err_instantanea_invalida" "godot --headless --path . res://pruebas/so/err_instantanea_invalida.tscn" "^OK err_instantanea_invalida "
pasa "so: err_pck_y_pack_ausentes" "godot --headless --path . res://pruebas/so/err_pck_y_pack_ausentes.tscn" "^OK err_pck_y_pack_ausentes "
pasa "so: err_entradas_invalidas" "godot --headless --path . res://pruebas/so/err_entradas_invalidas.tscn" "^OK err_entradas_invalidas "
pasa "so: err_rafaga_entrada" "godot --headless --path . res://pruebas/so/err_rafaga_entrada.tscn" "^OK err_rafaga_entrada "
pasa "so: err_poca_memoria" "godot --headless --path . res://pruebas/so/err_poca_memoria.tscn" "^OK err_poca_memoria "
pasa "so: est_calendario_liga" "godot --headless --path . res://pruebas/so/est_calendario_liga.tscn" "^OK est_calendario_liga "
pasa "so: est_economia_invariantes" "godot --headless --path . res://pruebas/so/est_economia_invariantes.tscn" "^OK est_economia_invariantes "
pasa "so: est_datos_coherencia" "godot --headless --path . res://pruebas/so/est_datos_coherencia.tscn" "^OK est_datos_coherencia "
pasa "so: est_datos_tablas_vs_codigo" "godot --headless --path . res://pruebas/so/est_datos_tablas_vs_codigo.tscn" "^OK est_datos_tablas_vs_codigo "
pasa "so: est_partido_simulado_reglas" "godot --headless --path . res://pruebas/so/est_partido_simulado_reglas.tscn" "^OK est_partido_simulado_reglas "
pasa "so: int_nativo_por_sistema" "godot --headless --path . res://pruebas/so/int_nativo_por_sistema.tscn" "^OK int_nativo_por_sistema "
pasa "so: int_paquetes_y_parches" "godot --headless --path . res://pruebas/so/int_paquetes_y_parches.tscn" "^OK int_paquetes_y_parches "
pasa "so: int_flujo_menu_a_guardado" "godot --headless --path . res://pruebas/so/int_flujo_menu_a_guardado.tscn" "^OK int_flujo_menu_a_guardado "
pasa "so: fun_azar_puro" "godot --headless --path . res://pruebas/so/fun_azar_puro.tscn" "^OK fun_azar_puro "
pasa "so: fun_calendario_fechas" "godot --headless --path . res://pruebas/so/fun_calendario_fechas.tscn" "^OK fun_calendario_fechas "
pasa "so: fun_formato_y_demarcaciones" "godot --headless --path . res://pruebas/so/fun_formato_y_demarcaciones.tscn" "^OK fun_formato_y_demarcaciones "
pasa "so: fun_nativo_datos_aleatorios" "godot --headless --path . res://pruebas/so/fun_nativo_datos_aleatorios.tscn" "^OK fun_nativo_datos_aleatorios "
pasa "so: int_actualizador_por_sistema" "godot --headless --path . res://pruebas/so/int_actualizador_por_sistema.tscn" "^OK int_actualizador_por_sistema "
pasa "so: vis_pantallas_sin_vacios" "godot --headless --path . res://pruebas/so/vis_pantallas_sin_vacios.tscn" "^OK vis_pantallas_sin_vacios "
pasa "so: vis_referencias_integras" "godot --headless --path . res://pruebas/so/vis_referencias_integras.tscn" "^OK vis_referencias_integras "
pasa "so: ren_menu_y_mundo_memoria" "godot --headless --path . res://pruebas/so/ren_menu_y_mundo_memoria.tscn" "^OK ren_menu_y_mundo_memoria "
pasa "so: ren_peso_archivos" "godot --headless --path . res://pruebas/so/ren_peso_archivos.tscn" "^OK ren_peso_archivos "
pasa "so: ren_sin_tiempo_en_headless" "godot --headless --path . res://pruebas/so/ren_sin_tiempo_en_headless.tscn" "^OK ren_sin_tiempo_en_headless "
pasa "so: est_propiedades_semillas" "godot --headless --path . res://pruebas/so/est_propiedades_semillas.tscn" "^OK est_propiedades_semillas "
# 5e. ESCENAS SIN LANZAR que ya pasan (5-11, rama sonar/bancos2, prioridad 3 de la líder): 87 de las ~100 que tenían comprobaciones y nadie ejecutaba, en lotes de 10.
#     Las que fallaban o no terminaban están anotadas en PLAN_GENERAL.md («FALLOS DETECTADOS») con su evidencia; no se han quitado ni tocado.
BLOQUE=reutilizadas2
pasa "r2: detector_atraviesa" "godot --headless --path . res://pruebas/detector_atraviesa.tscn" "(^|[^0-9])0 fallos"
# lote 1
pasa "r2: caminar_de_verdad" "godot --headless --path . res://pruebas/caminar_de_verdad.tscn" "(^|[^0-9])0 fallos"
pasa "r2: cant_estabilidad" "godot --headless --path . res://pruebas/ideas/cant_estabilidad.tscn" "(^|[^0-9])0 fallos"
pasa "r2: car_precalentar" "godot --headless --path . res://pruebas/ideas/car_precalentar.tscn" "(^|[^0-9])0 fallos"
pasa "r2: e1_butacas" "godot --headless --path . res://pruebas/ideas/e1_butacas.tscn" "(^|[^0-9])0 fallos"
pasa "r2: e2_zancas_pasillos" "godot --headless --path . res://pruebas/ideas/e2_zancas_pasillos.tscn" "(^|[^0-9])0 fallos"
pasa "r2: e3_torre_focos" "godot --headless --path . res://pruebas/ideas/e3_torre_focos.tscn" "(^|[^0-9])0 fallos"
pasa "r2: eco_medicion" "godot --headless --path . res://pruebas/ideas/eco_medicion.tscn" "(^|[^0-9])0 fallos"
pasa "r2: eq_crisis_caja" "godot --headless --path . res://pruebas/ideas/eq_crisis_caja.tscn" "(^|[^0-9])0 fallos"
pasa "r2: f0_cimientos" "godot --headless --path . res://pruebas/ideas/f0_cimientos.tscn" "(^|[^0-9])0 fallos"
pasa "r2: f0b_huella" "godot --headless --path . res://pruebas/ideas/f0b_huella.tscn" "(^|[^0-9])0 fallos"
pasa "r2: f0e_resolver" "godot --headless --path . res://pruebas/ideas/f0e_resolver.tscn" "(^|[^0-9])0 fallos"
# lote 2
pasa "r2: f0m_visor_personas" "godot --headless --path . res://pruebas/ideas/f0m_visor_personas.tscn" "(^|[^0-9])0 fallos"
pasa "r2: f0m_visor_piezas" "godot --headless --path . res://pruebas/ideas/f0m_visor_piezas.tscn" "(^|[^0-9])0 fallos"
pasa "r2: f0r_necesidades" "godot --headless --path . res://pruebas/ideas/f0r_necesidades.tscn" "(^|[^0-9])0 fallos"
pasa "r2: f0s_huellas_sonido" "godot --headless --path . res://pruebas/ideas/f0s_huellas_sonido.tscn" "(^|[^0-9])0 fallos"
pasa "r2: f1g_pais" "godot --headless --path . res://pruebas/ideas/f1g_pais.tscn" "(^|[^0-9])0 fallos"
pasa "r2: fcp_crear_partida" "godot --headless --path . res://pruebas/ideas/fcp_crear_partida.tscn" "(^|[^0-9])0 fallos"
pasa "r2: foto_brazos" "godot --headless --path . res://pruebas/ideas/foto_brazos.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p1_movimiento_natural" "godot --headless --path . res://pruebas/ideas/p1_movimiento_natural.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p2_inclinacion" "godot --headless --path . res://pruebas/ideas/p2_inclinacion.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p2_postura" "godot --headless --path . res://pruebas/ideas/p2_postura.tscn" "(^|[^0-9])0 fallos"
# lote 3
pasa "r2: p3_arbitros" "godot --headless --path . res://pruebas/ideas/p3_arbitros.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p3_banquillo_tour" "godot --headless --path . res://pruebas/ideas/p3_banquillo_tour.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p3_clips_ual" "godot --headless --path . res://pruebas/ideas/p3_clips_ual.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p3_escaleras" "godot --headless --path . res://pruebas/ideas/p3_escaleras.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p3_escaparates" "godot --headless --path . res://pruebas/ideas/p3_escaparates.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p3_grupo" "godot --headless --path . res://pruebas/ideas/p3_grupo.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p3_puertas" "godot --headless --path . res://pruebas/ideas/p3_puertas.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p3_sentados" "godot --headless --path . res://pruebas/ideas/p3_sentados.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p3_ual2" "godot --headless --path . res://pruebas/ideas/p3_ual2.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p4_contacto" "godot --headless --path . res://pruebas/ideas/p4_contacto.tscn" "(^|[^0-9])0 fallos"
# lote 4
pasa "r2: p4_hitbox" "godot --headless --path . res://pruebas/ideas/p4_hitbox.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p4_pelo_drive" "godot --headless --path . res://pruebas/ideas/p4_pelo_drive.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p4_pelo_mujer" "godot --headless --path . res://pruebas/ideas/p4_pelo_mujer.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p5_futbolistas_acabado" "godot --headless --path . res://pruebas/ideas/p5_futbolistas_acabado.tscn" "(^|[^0-9])0 fallos"
pasa "r2: p5_paradero_red" "godot --headless --path . res://pruebas/ideas/p5_paradero_red.tscn" "(^|[^0-9])0 fallos"
pasa "r2: pest_estadio" "godot --headless --path . res://pruebas/ideas/pest_estadio.tscn" "(^|[^0-9])0 fallos"
pasa "r2: pmov_ceder" "godot --headless --path . res://pruebas/ideas/pmov_ceder.tscn" "(^|[^0-9])0 fallos"
pasa "r2: pmov_choque_coches" "godot --headless --path . res://pruebas/ideas/pmov_choque_coches.tscn" "(^|[^0-9])0 fallos"
pasa "r2: pmov_coche_forma" "godot --headless --path . res://pruebas/ideas/pmov_coche_forma.tscn" "(^|[^0-9])0 fallos"
pasa "r2: pmov_conduccion" "godot --headless --path . res://pruebas/ideas/pmov_conduccion.tscn" "(^|[^0-9])0 fallos"
# lote 5
pasa "r2: pmov_sonda_colision" "godot --headless --path . res://pruebas/ideas/pmov_sonda_colision.tscn" "(^|[^0-9])0 fallos"
pasa "r2: r7_medicion_bloqueo" "godot --headless --path . res://pruebas/ideas/r7_medicion_bloqueo.tscn" "(^|[^0-9])0 fallos"
pasa "r2: red_redes_3d" "godot --headless --path . res://pruebas/ideas/red_redes_3d.tscn" "(^|[^0-9])0 fallos"
pasa "r2: rend_plantel_fijas" "godot --headless --path . res://pruebas/ideas/rend_plantel_fijas.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s3_accesibilidad" "godot --headless --path . res://pruebas/ideas/s3_accesibilidad.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s3_atajos_clics" "godot --headless --path . res://pruebas/ideas/s3_atajos_clics.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s3_defectos_visuales" "godot --headless --path . res://pruebas/ideas/s3_defectos_visuales.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s3_nombres_competicion" "godot --headless --path . res://pruebas/ideas/s3_nombres_competicion.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s3_peatones_esquivan" "godot --headless --path . res://pruebas/ideas/s3_peatones_esquivan.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s3_primera_hora" "godot --headless --path . res://pruebas/ideas/s3_primera_hora.tscn" "(^|[^0-9])0 fallos"
# lote 6
pasa "r2: s3_rotacion_menus" "godot --headless --path . res://pruebas/ideas/s3_rotacion_menus.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s3_textos_nucleo" "godot --headless --path . res://pruebas/ideas/s3_textos_nucleo.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s3_visual_metrica" "godot --headless --path . res://pruebas/ideas/s3_visual_metrica.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s3g_gesto_tecnico" "godot --headless --path . res://pruebas/ideas/s3g_gesto_tecnico.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s4p_vida_imprevistos" "godot --headless --path . res://pruebas/ideas/s4p_vida_imprevistos.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s5_causas" "godot --headless --path . res://pruebas/ideas/s5_causas.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s5_detalles" "godot --headless --path . res://pruebas/ideas/s5_detalles.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s5_rueda" "godot --headless --path . res://pruebas/ideas/s5_rueda.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s5_tactica_roles" "godot --headless --path . res://pruebas/ideas/s5_tactica_roles.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s6_colision" "godot --headless --path . res://pruebas/ideas/s6_colision.tscn" "(^|[^0-9])0 fallos"
# lote 7
pasa "r2: s6_lluvia_ciudad" "godot --headless --path . res://pruebas/ideas/s6_lluvia_ciudad.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s6_mercado_dt" "godot --headless --path . res://pruebas/ideas/s6_mercado_dt.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s6_panel_plan" "godot --headless --path . res://pruebas/ideas/s6_panel_plan.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s6_paraguas" "godot --headless --path . res://pruebas/ideas/s6_paraguas.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s6_planificador" "godot --headless --path . res://pruebas/ideas/s6_planificador.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s6_porque" "godot --headless --path . res://pruebas/ideas/s6_porque.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s6_recursos" "godot --headless --path . res://pruebas/ideas/s6_recursos.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s6_tablon" "godot --headless --path . res://pruebas/ideas/s6_tablon.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s7_pasajeros" "godot --headless --path . res://pruebas/ideas/s7_pasajeros.tscn" "(^|[^0-9])0 fallos"
pasa "r2: s8_museo_vitrinas" "godot --headless --path . res://pruebas/ideas/s8_museo_vitrinas.tscn" "(^|[^0-9])0 fallos"
# lote 8
pasa "r2: sav_guardado" "godot --headless --path . res://pruebas/ideas/sav_guardado.tscn" "(^|[^0-9])0 fallos"
pasa "r2: sui_grabados" "godot --headless --path . res://pruebas/ideas/sui_grabados.tscn" "(^|[^0-9])0 fallos"
pasa "r2: tac_presets" "godot --headless --path . res://pruebas/ideas/tac_presets.tscn" "(^|[^0-9])0 fallos"
pasa "r2: tre_transporte" "godot --headless --path . res://pruebas/ideas/tre_transporte.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uiaj_ajustes" "godot --headless --path . res://pruebas/ideas/uiaj_ajustes.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uiaj_mando" "godot --headless --path . res://pruebas/ideas/uiaj_mando.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uico_competicion" "godot --headless --path . res://pruebas/ideas/uico_competicion.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uico_textos" "godot --headless --path . res://pruebas/ideas/uico_textos.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uifi_asuntos" "godot --headless --path . res://pruebas/ideas/uifi_asuntos.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uifi_gestion" "godot --headless --path . res://pruebas/ideas/uifi_gestion.tscn" "(^|[^0-9])0 fallos"
# lote 9
pasa "r2: uiid_identidad" "godot --headless --path . res://pruebas/ideas/uiid_identidad.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uipl_textos" "godot --headless --path . res://pruebas/ideas/uipl_textos.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uite_movil_navegacion" "godot --headless --path . res://pruebas/ideas/uite_movil_navegacion.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uite_movil_textos" "godot --headless --path . res://pruebas/ideas/uite_movil_textos.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uite_traducciones" "godot --headless --path . res://pruebas/ideas/uite_traducciones.tscn" "(^|[^0-9])0 fallos"
pasa "r2: uitm_lenguaje" "godot --headless --path . res://pruebas/ideas/uitm_lenguaje.tscn" "(^|[^0-9])0 fallos"
pasa "r2: vat_hinchada" "godot --headless --path . res://pruebas/ideas/vat_hinchada.tscn" "(^|[^0-9])0 fallos"
BLOQUE=""
if [[ "$1" = "todo" ]]; then
  # Reutilizadas lentas (> 45 s cada una)
  pasa "estres_tirolibre" "godot --headless --path . res://pruebas/estres_tirolibre.tscn" "(^|[^0-9])0 fallos"
  pasa "cop_prorroga_tanda" "godot --headless --path . res://pruebas/ideas/cop_prorroga_tanda.tscn" "(^|[^0-9])0 fallos"
  pasa "p4_mobiliario_bajo" "godot --headless --path . res://pruebas/ideas/p4_mobiliario_bajo.tscn" "(^|[^0-9])0 fallos"
# 6a. Presupuesto de triángulos y llamadas de dibujo del partido (M-338): con pantalla virtual; ~5 min
if command -v xvfb-run >/dev/null; then
pasa "troceo de la grada sin butacas perdidas" "xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/prueba_troceo_grada.tscn" "FIN. 0 fallos"
pasa "presupuesto del partido" "xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/presupuesto_partido.tscn" "FIN. 0 fallos"
pasa "presupuesto del recorrido (menú, estadio, ciudad)" "herramientas/presupuesto.sh" "FIN. 0 fallos"
fi
  # Balance del mundo a largo plazo (10 temporadas x 3 semillas, ~3,5 min) y rendimiento en 20 (~1,5 min)
  pasa "balance en 10 temporadas" "godot --headless --path . res://pruebas/ideas/eq_diez_temporadas.tscn" "FIN. 0 fallos"
  pasa "rendimiento en 20 temporadas" "EQ_MODO=rendimiento godot --headless --path . res://pruebas/ideas/eq_diez_temporadas.tscn" "FIN. 0 fallos"
  pasa "deriva a 30 temporadas (2 países; A4)" "DERIVA_TEMP=30 godot --headless --path . res://pruebas/ideas/a4_deriva_larga.tscn" "FIN. 0 fallos"
  # El motor del partido nota la calidad y la pizarra (sonda_motor_dt con umbrales, M-414; 6 partidos por escenario (10 en la pizarra, A4-PARTIDO-005: con 6 el ruido de los tiros daba falsos fallos), ~10 min)
  pasa "motor: el mejor gana al peor" "ESCENARIO=calidad N=6 godot --headless --path . res://pruebas/sonda_motor_dt.tscn" "UMBRALES: 0 fallos"
  pasa "motor: la pizarra se nota" "ESCENARIO=tactica N=10 godot --headless --path . res://pruebas/sonda_motor_dt.tscn" "UMBRALES: 0 fallos"
  # M-467: todas las pantallas en alemán; los textos se encogen (TextoQueCabe) y no quedan más de 4 cortados (~3 min)
  pasa "textos largos en alemán" "RECORRIDO_IDIOMA=de RECORRIDO_LARGOS=/tmp/largos_de.json RECORRIDO_CORTADOS_MAX=4 godot --headless --path . res://pruebas/recorrido_pantallas.tscn" "FIN LARGOS. 0 fallos"
  pasa "paneles más anchos que su hueco (móvil, alemán)" "RECORRIDO_ANCHO=1 RECORRIDO_ANCHO_MAX=0 RECORRIDO_IDIOMA=de RECORRIDO_MOVIL=2400x1080 RECORRIDO_LARGOS=/tmp/ancho_de.json godot --headless --path . res://pruebas/recorrido_pantallas.tscn" "FIN ANCHO. 0 fallos"
  pasa "paneles más anchos que su hueco (móvil, francés)" "RECORRIDO_ANCHO=1 RECORRIDO_ANCHO_MAX=0 RECORRIDO_IDIOMA=fr RECORRIDO_MOVIL=2400x1080 RECORRIDO_LARGOS=/tmp/ancho_fr.json godot --headless --path . res://pruebas/recorrido_pantallas.tscn" "FIN ANCHO. 0 fallos"
  pasa "controles sin foco o sin nombre para el lector (todas las pantallas)" "RECORRIDO_ACCESO=1 RECORRIDO_ACCESO_MAX=0 RECORRIDO_LARGOS=/tmp/acceso.json godot --headless --path . res://pruebas/recorrido_pantallas.tscn" "FIN ACCESO. 0 fallos"
  # M-463: en alemán no queda castellano sin traducir (las siglas POR/DEF/MED/DEL y el formato del editor ya no cuentan)
  pasa "sin castellano en alemán" "RECORRIDO_IDIOMA=de RECORRIDO_CASTELLANO_MAX=0 godot --headless --path . res://pruebas/recorrido_pantallas.tscn" "FIN CASTELLANO. 0 fallos"
  pasa "apertura de pantallas (M-287, tope 2 s sin GPU)" "RECORRIDO_MS_MAX=2000 godot --headless --path . res://pruebas/recorrido_pantallas.tscn" "FIN TIEMPOS. 0 fallos"
  # M-333: los rótulos 3D de la ciudad entera, en inglés, pasan por Idiomas.t
  pasa "carteles 3D traducidos" "godot --headless --path . res://pruebas/ideas/idi_carteles3d.tscn" "FIN. 0 fallos"
  pasa "módulos del visor sin prueba (M-404)" "godot --headless --path . res://pruebas/ideas/vis_sueltos.tscn" "FIN. 0 fallos"
  pasa "clips del futbolista: pedidos y sin uso (M-095)" "godot --headless --path . res://pruebas/ideas/p3_clips_partido.tscn" "FIN. 0 fallos"
  # El guion, fases 1-5 (auditoría del 28-10: estas pruebas existían y no las corría nadie; ~3 min)
  for F in f0_contratos f1o_flujo f2p_prologo f3v_vida f3c_casa f4p_citas f4p_personas f4r_rutinas f5c_club; do
    pasa "guion: $F" "godot --headless --path . res://pruebas/ideas/$F.tscn" "FIN. 0 fallos"
  done
  # M-283, M-300, M-296, M-311, M-290: avisos de sonido, deshacer en la pizarra, bandeja por temas, resumen de carrera, datos de tarjetas
  pasa "avisos visuales de sonido" "godot --headless --path . res://pruebas/ideas/acc_avisos_sonido.tscn" "FIN. 0 fallos"
  pasa "lectura de pantalla" "godot --headless --path . res://pruebas/ideas/acc_lector.tscn" "FIN. 0 fallos"
  pasa "deshacer en la pizarra" "godot --headless --path . res://pruebas/ideas/tac_deshacer.tscn" "FIN. 0 fallos"
  pasa "bandeja por temas" "godot --headless --path . res://pruebas/ideas/ban_temas.tscn" "FIN. 0 fallos"
  pasa "resumen de carrera" "godot --headless --path . res://pruebas/ideas/leg_resumen.tscn" "FIN. 0 fallos"
  pasa "datos de las tarjetas" "godot --headless --path . res://pruebas/ideas/men_datos.tscn" "FIN. 0 fallos"
  pasa "seguir clubes" "godot --headless --path . res://pruebas/ideas/seg_clubes.tscn" "FIN. 0 fallos"
  pasa "sonido en pestañas y listas" "godot --headless --path . res://pruebas/ideas/fx_pestanas.tscn" "FIN. 0 fallos"
  # M-420: los presets públicos (paquete exportado) no llevan archivos ni nombres de lo real (~3 min)
  pasa "builds públicos sin datos reales" "python3 herramientas/revisar_build_publico.py" "FIN BUILD PÚBLICO. 0 fallos"
  pasa "ceremonia de carrera" "godot --headless --path . res://pruebas/prueba_carrera_ceremonia.tscn" "FIN. 0 fallos"
  pasa "práctica" "godot --headless --path . res://pruebas/prueba_practica.tscn" "FIN PRÁCTICA. 0 fallos"
  pasa "recorrido de todas las pantallas" "godot --headless --path . res://pruebas/recorrido_pantallas.tscn" "RECORRIDO: [0-9]+ pantallas"
  # 20 pantallas clave contra sus referencias (pruebas/visual/visual.gd; ~1,5 min). Necesita Vulkan
  # (lavapipe sin GPU); sin él se salta. Tras un cambio visual QUERIDO: herramientas/visual.sh referencias.
  if ls /usr/share/vulkan/icd.d/*.json > /dev/null 2>&1; then
    pasa "pruebas visuales (20 pantallas)" "RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/visual/visual.tscn" "FIN. 0 fallos"
  else
    echo "SALTADA pruebas visuales (sin Vulkan: apt-get install -y mesa-vulkan-drivers)"
  fi
  # pruebas por sistema que necesitan pantalla (5-11): partido con la cámara real en Compatibilidad y Forward+, pantallas del menú, presupuesto con hw_modesto
  pasa "so: vis_partido_forward" "python3 herramientas/pruebas_so.py vis_partido_forward" "^OK +vis_partido_forward "
  pasa "so: vis_partido_compat" "python3 herramientas/pruebas_so.py vis_partido_compat" "^OK +vis_partido_compat "
  pasa "so: vis_menu_pantallas" "python3 herramientas/pruebas_so.py vis_menu_pantallas" "^OK +vis_menu_pantallas "
  pasa "so: ren_partido_presupuesto" "python3 herramientas/pruebas_so.py ren_partido_presupuesto" "^OK +ren_partido_presupuesto "
fi
rm -f "$LOG"
[[ "$FALLOS" -eq 0 ]] && echo "ESPECIALES: todo en orden" || echo "ESPECIALES: $FALLOS con fallos"
exit $([[ "$FALLOS" -eq 0 ]] && echo 0 || echo 1)
