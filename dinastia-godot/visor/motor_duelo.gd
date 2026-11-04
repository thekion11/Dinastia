class_name MotorDuelo
extends RefCounted
## CALIBRACIÓN DE LA ENTRADA (03-11-2026, ciclo 10 de la sesión líder: «el 65 % de las pérdidas son robos al portador»). `_entrada` se intentaba cada vez que un rival estaba
## a menos de ≈1,25 m del portador y tenía la entrada disponible (cada 1,0 s): del orden de 50-80 intentos por equipo en un partido, 3-4 veces más que la realidad (≈16-20
## entradas por equipo y partido en la liga inglesa, StatMuse 2025-26). Dos perillas por variable de entorno, 1,0 = como antes:
##  · `ENTRADA_K`: multiplica la probabilidad de éxito de la entrada;
##  · `ENTRADA_ENF`: multiplica el tiempo entre dos entradas del mismo defensor (menos intentos).
static var K := float(OS.get_environment("ENTRADA_K")) if OS.get_environment("ENTRADA_K") != "" else 1.0
static var ENF := float(OS.get_environment("ENTRADA_ENF")) if OS.get_environment("ENTRADA_ENF") != "" else 1.0
