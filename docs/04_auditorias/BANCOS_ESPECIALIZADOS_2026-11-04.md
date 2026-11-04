# Bancos especializados (megarreforma pedida por el dueño, 3-11-2026)

Pedido: «más de 30 bancos especiales, modulares y ultra detallados, aunque tarden más», más uno EXTRA de rendimiento.

## Fase 1 (hecha, 4-11): 33 bancos + rendimiento = 34
- `python3 dinastia-godot/herramientas/bancos_especiales.py --lista` — los 33 bancos por área y cuántas pruebas tiene cada uno.
- `python3 dinastia-godot/herramientas/bancos_especiales.py <banco> [...]` — corre uno o varios; `--todos` todos; `--sin_banco` lo que no cae en ninguno (debe dar 0).
- Cada banco junta las secciones del banco que son de su área (`BANCO_SOLO=a,b,c`, un solo proceso) y las pruebas especiales de su área.
- `python3 dinastia-godot/herramientas/banco_rendimiento.py` — el banco extra de rendimiento (7 secciones contra topes en `banco_rendimiento.json`).
- `banco.sh` y `especiales.sh` siguen igual (el CI no cambia): los bancos especializados son una forma más fina de correr y ampliar lo mismo.

Áreas: arranque · determinismo · datos_mundo · calendario_competiciones · partido_reglas · partido_ia · partido_fisica ·
partido_porteros · partido_jugable · partido_presentacion · plantel_cantera · mercado_contratos · economia · club_directiva ·
vestuario_moral · entrenamiento_lesiones · prensa_redes · carrera_dt · guardado · idiomas · menu_navegacion ·
accesibilidad_tutorial · estadio_3d · ciudad_construccion · ciudad_vida · ciudad_transporte · personajes_3d · audio ·
minijuegos · mundo_largo_plazo · calidad_grafica · codigo_y_auditorias · ideas_documento (+ rendimiento).

## Fase 2 (en curso): ULTRA DETALLE por banco
Cada banco suma su escena propia `dinastia-godot/pruebas/bancos/<banco>.tscn/.gd` (extiende BaseIdea, «FIN. N fallos»), que el lanzador
corre sola si existe. Criterio: comprobaciones finas y numéricas (rangos reales, invariantes, ida y vuelta, casos límite), aunque tarden.
Bancos más flojos hoy (pocas pruebas para su peso): partido_porteros (0 secciones), club_directiva (0 especiales), minijuegos, audio,
guardado, personajes_3d, partido_fisica, determinismo. Orden propuesto: guardado → idiomas → menu_navegacion → partido_reglas →
economia → … (los del partido, coordinados con la sesión PES 6, que es dueña de la IA y la física).
