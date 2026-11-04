# Pasada final de la IA del partido (3-11, rama experimental `ccr-454350d9-9chain`, PR #128)

Las 8 mejoras F1-F8 que `terceros_ia_motor_2026-11-01.md` dejó para la «pasada final del motor». Todas escritas aparte (ideas de League-Soccer, Apache 2.0),
cada una en su módulo `visor/motor_*.gd`, con su sección en el banco (`pruebas/banco/partido_p3.gd`) y una bandera para apagarla (`SIN_…=1` = lo de antes).

| # | Módulo | Qué hace | Apagar |
|---|---|---|---|
| F1 | `motor_colocacion.gd` | El bloque mira un balón con retardo (1,8-3,8 s) y recuerda la posesión (sesgo suavizado): con balón se alarga, sin él se junta | `SIN_COLOCACION` |
| F2 | `motor_roles.gd` | Reparto de puestos por línea con el algoritmo húngaro (cada 0,5 s, histéresis 5 m) | `SIN_ROLES_DIN` |
| F3 | `motor_apoyo.gd` | Campo de fuerzas del apoyo: anillo de pase 12 m, repulsión de compañeros y rivales, salida de la línea tapada | `SIN_APOYO` |
| F4 | `motor_marcaje.gd` | Un marcador estable para cada uno de los 3 rivales más peligrosos | `SIN_MARCAJE` |
| F5 | `motor_carreras.gd` | Un solo delantero a la vez corre al hueco (2,8-5 s) y luego descansa; los demás mantienen la forma | `SIN_CARRERAS` |
| F6 | `motor_tiro_limpio.gd` | Tres puntos del arco puntuados por portero y defensas en la línea; apunta al mejor y ajusta las ganas de tirar | `SIN_TIRO_LIMPIO` |
| F7 | `motor_parada.gd` (`destino`) | El portero se desliza hacia el cruce previsto mientras espera la parada | `SIN_ANTICIPA` |
| F8 | `motor_mente.gd` | La CPU ve a los rivales con retardo según su dificultad (Practicante 0,5 s, Cadete 0,3 s; resto 0) | `SIN_MENTE` |

Además (misma rama): la física del balón del modo `disparar()` (`fisica_balon_vs_real_2026-11-03.md`).

## Verificación
Banco completo «FIN. 0 fallos» con F1-F8; F2 y F3 se añadieron después (sección propia en 0 fallos; el CI del PR corre el banco entero).

## Lo que NO se ha medido (hay que hacerlo con calma)
- Goles y tiros por partido en 32 partidos con todo encendido y todo apagado (cifra de referencia ≈2,3 goles; F4-F6 pueden subirla o bajarla).
- A ojo con la cámara real del partido: forma del bloque, carreras, apoyo, portero. Sin pantalla ni GPU en el contenedor no se pudo mirar.
- Los niveles altos de dificultad (Maestro, Ultimate) solo tienen mejores atributos y menos error; F8 no los hace «leer mejor».
