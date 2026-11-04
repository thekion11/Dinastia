# Mega auditoría 4 — interfaz


## Repaso 5 cruzado (sesión PES 6, 4-11) — interfaz al límite
Prueba nueva: `pruebas/auditoria_interfaz_limite.tscn` (en `especiales.sh`): 110 aperturas/cierres de menú lateral con pulsación doble, los 9 idiomas con un menú abierto, texto al 160 %, ventanas 2400×1080 y 1280×720.
- Resultado: sin hallazgos reales. Nodos estables tras las primeras vueltas (4348 → 4309; las pantallas perezosas se construyen y se guardan en las ~30 primeras), 0 huérfanos, ninguna pantalla apilada por pulsación doble, cambio de idioma sin romper el menú, 0 textos fuera de la ventana al 160 % y en ambas resoluciones.
- Nota de método: los textos dentro de un `SubViewport` (mini-mapas «PD», «LF») se miden en su propia textura, no contra la ventana; se excluyen para evitar falsos avisos.
- [A4-INT-X01] (repaso 5, gravedad: bajo) La memoria de ObjectDB al salir avisa de ~12.800 instancias y 104 recursos sin liberar (solo al cerrar el programa). Reproducir: ejecutar la prueba y mirar el final. Estado: abierto (informativo, no crece en uso).
