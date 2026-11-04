# Mega auditoría 4 — gestion


## Repaso 5 (cruzado, hecho por la sesión Ciudad, 4-11)
Método: sonda `pruebas/ideas/a4_gestion_cruzado.tscn` (en `especiales.sh`): invariantes cada 4 semanas (jugador en un solo lugar, `club_id` coherente, rangos de edad/ovr/pot/forma/moral/físico/sueldo/contrato/goles/lesión/sanción, finanzas finitas y rangos de confianza/reputación/socios/aforo/entradas, plantel ≥ 11, tablas: Σgf = Σgc, pts = victorias×puntos + empates − sanción, pj = g+e+p). Corridas: 2 semillas × 70 semanas × Chile+Argentina; 10 temporadas (520 semanas, `LARGO=1`, 131 muestras); 6 casos absurdos (plantel vacío, saldo ±2 000 M, todos ovr 1, sin libres, 3 jugadores) × 6 semanas. Más los bancos especializados economía, mercado_contratos y calendario_competiciones: 0 fallos.

- [A4-GESTION-001] (repaso 5, gravedad: bajo) Falso positivo propio, no fallo del juego: con 10 temporadas el invariante «pts = 3g + e» saltó 84 veces porque la insolvencia resta puntos (`Liga.sancionar`, que ya los anota en `sancion` de la fila). Cómo reproducirlo: `LARGO=1` con la versión anterior de la sonda. `pruebas/ideas/a4_gestion_cruzado.gd:80`. Estado: arreglado (la sonda descuenta `sancion`; commit de esta rama).

Resultado: 0 fallos reales en 10 temporadas y casos extremos; no se encontró nada crítico, alto ni medio. Fuera de alcance de esta sonda (no repasado a fondo): federación y carrera del jugador con guardado a mitad (cubiertos por el banco `guardado`), ofertas/traspasos con mercado saturado.
