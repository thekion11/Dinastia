# Mega auditoría 4 — gestion


## Repaso 5 (cruzado, hecho por la sesión Ciudad, 4-11)
Método: sonda `pruebas/ideas/a4_gestion_cruzado.tscn` (en `especiales.sh`): invariantes cada 4 semanas (jugador en un solo lugar, `club_id` coherente, rangos de edad/ovr/pot/forma/moral/físico/sueldo/contrato/goles/lesión/sanción, finanzas finitas y rangos de confianza/reputación/socios/aforo/entradas, plantel ≥ 11, tablas: Σgf = Σgc, pts = victorias×puntos + empates − sanción, pj = g+e+p). Corridas: 2 semillas × 70 semanas × Chile+Argentina; 10 temporadas (520 semanas, `LARGO=1`, 131 muestras); 6 casos absurdos (plantel vacío, saldo ±2 000 M, todos ovr 1, sin libres, 3 jugadores) × 6 semanas. Más los bancos especializados economía, mercado_contratos y calendario_competiciones: 0 fallos.

- [A4-GESTION-001] (repaso 5, gravedad: bajo) Falso positivo propio, no fallo del juego: con 10 temporadas el invariante «pts = 3g + e» saltó 84 veces porque la insolvencia resta puntos (`Liga.sancionar`, que ya los anota en `sancion` de la fila). Cómo reproducirlo: `LARGO=1` con la versión anterior de la sonda. `pruebas/ideas/a4_gestion_cruzado.gd:80`. Estado: arreglado (la sonda descuenta `sancion`; commit de esta rama).

Resultado: 0 fallos reales en 10 temporadas y casos extremos; no se encontró nada crítico, alto ni medio. Fuera de alcance de esta sonda (no repasado a fondo): federación y carrera del jugador con guardado a mitad (cubiertos por el banco `guardado`), ofertas/traspasos con mercado saturado.
Prueba al límite del área: `dinastia-godot/pruebas/ideas/a4_gestion_limite.tscn` (8 temporadas con guardado cada dos años, integridad,
caja −250 M, todos lesionados y sancionados, club con 48 jugadores y otro vacío, año 2099).

- [A4-GES-001] (repaso 3, gravedad: alto) Tras CERRAR UNA TEMPORADA (`jugar_temporada` + `nueva_temporada`), guardar y cargar NO devuelve el
  mismo mundo (temporadas 2, 4, 6 y 8). El banco `guardado` solo lo probaba dentro de la primera temporada. Reproducir: `a4_gestion_limite`.
  Causa: `Citas.desde_dic` guardaba las citas por REFERENCIA y `semana()` las caducaba en el sitio, estropeando los datos cargados.
  Arreglo: copia profunda al cargar (`nucleo/citas.gd`). Estado: ARREGLADO (8 temporadas con guardado exacto; en `especiales.sh`).
- [A4-GES-002] (repaso 3, gravedad: alto, cambia el juego) Quedaban OFERTAS RECIBIDAS por jugadores que ya NO eran del club (vendidos
  o libres al cerrar la temporada): se podía aceptar y VENDER a un jugador ajeno. Arreglo: `Mercado.a_dic` no guarda esas ofertas y
  `responder_oferta` no hace nada si el jugador ya no es tuyo (`nucleo/mercado_p1.gd`). Estado: ARREGLADO.
- [A4-GES-003] (repaso 3, gravedad: medio, cambia cifras) La FICHA MENTAL (ansiedad/confianza) se creaba con `Azar` al LEERLA
  (`factor_animo` en el partido): al cargar una partida salía distinta y además consumía azar según el orden de lectura. Arreglo:
  la ficha inicial sale de un hash del id del jugador y leer no la crea (`nucleo/vestuario_p1.gd`). `igualdad_mundo` → 31094042.
  Estado: ARREGLADO.
- [A4-GES-004] (repaso 3, gravedad: bajo) El EDITOR no llegaba a la media pedida cerca del suelo de 20 (6 vueltas de `_cuadrar_media`
  no bastaban: los atributos topan en 20); fallo intermitente del banco según el azar. Arreglo: 40 vueltas (`nucleo/editor.gd`). ARREGLADO.
- [A4-GES-005] (repaso 1, gravedad: alto) NEGOCIACIÓN: cuando un club RIVAL se lleva al jugador en plena mesa («rival_traspaso» /
  «rival_firma»), solo se cambiaba `jugador.club_id`: el jugador SEGUÍA en el plantel del club viejo y no aparecía en el del rival
  (dos fuentes de verdad distintas; el club viejo lo seguía alineando). Además, si el jugador cambiaba de club mientras la mesa
  seguía abierta, cerrar el fichaje lo dejaba en DOS planteles. Arreglo: `_se_lo_lleva` (soltar + fichar de verdad) y la mesa se
  rompe si el jugador ya no está en el club con el que hablabas (`nucleo/negociacion.gd`). Prueba en `a4_gestion_limite`. ARREGLADO.
- [A4-GES-006] (repaso 2, gravedad: bajo) `clau_descenso_entreno` (banco `plantel_cantera`) fallaba según el ORDEN del azar: con 12
  juveniles la media del plan por defecto saltaba de +3,6 a +2,8 (suelo 3,0) solo porque A4-GES-003 dejó de gastar azar al leer
  la ficha mental. Arreglo: 6 semillas (24 juveniles). Cifras con la muestra grande: plan por defecto +3,4 (el dueño pidió +4-6) y
  buen plan +5,7 con un máximo de +11 (pidió ≤ +8; el freno de `Entrenamiento.freno_temporada` es probabilístico y la curva anual
  `ProgresoJugador.anual` suma aparte). Queda como DEUDA DE CALIBRACIÓN (no es un fallo de código). Prueba: ARREGLADA.
- Sin hallazgos: integridad del mundo en 8 temporadas (un club por jugador, club_id, libres, contratos, sueldos, edades, medias, cajas,
  planteles, ligas y divisiones); caja a −250 M seis semanas; club con todos lesionados y sancionados (saca 11); club con 48 jugadores y
  otro vacío; año 2099.
