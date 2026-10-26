# Auditoría de la ciudad (26-10-2026) — PARCIAL

> **Estado: parcial.** Se guardó a mitad de trabajo por petición de la sesión líder. Solo análisis y capturas:
> no se ha cambiado la ciudad. Lo que falta está al final («Pendiente»).

## Cómo se hizo
- Guion `dinastia-godot/pruebas/ideas/f6c_captura_ciudad.tscn`: una toma **aérea** (cámara orbital, 120 m de alto)
  y otra **a pie** (cámara del paseo, a 30 m del borde de la manzana, mirando hacia ella) por cada tipo de manzana
  de `CiudadExpansion`: los usos especiales por su nombre y un ejemplar de cada barrio y distrito
  (`barrio_<zona>_<uso>`). 11:00 de la mañana, Forward+ (lavapipe), 1600×900, JPG.
  `herramientas/captura.sh res://pruebas/ideas/f6c_captura_ciudad.tscn` (`ZONAS=cine,hospital` para elegir).
- Sin pantalla (headless) el guion no hace nada y termina en «FIN. 0 fallos»: `ideas.sh todo` lo salta.

## Hallazgos ya confirmados (código + captura)

### Centro comercial (`ciudad_expansion_p7.gd`, rama `"centro_comercial"`)
Es **una sola caja** de 16 m de alto (90 % del ancho × 55 % del fondo) con material «claro», una tira de vidrio
de 0,2 m de grosor pegada a la cara delantera y un parche de asfalto. Sin fachada, sin entrada, sin rótulo en la
fachada, sin aparcamiento marcado, sin cubierta ni escaparates: es lo que se ve como «bloque gris».

### Cine (`cine`)
Caja oscura (morado) con una tira rosa en la fachada: legible desde el aire («Cine»), pero a pie es una pared lisa
sin marquesina, cartelera ni taquilla.

### Plaza Mayor (`plaza_mayor`)
Losa gris lisa de ~110 m con fuente azul, cuatro árboles sueltos y un quiosco; el cartel «LAUTARO FC» (valla) está
en un lateral. Mucha superficie vacía; sin bancos, farolas ni soportales. Los edificios del contorno son los
genéricos de «comercial».

### Coherencia / defectos de herramienta
- Los usos de manzana se repiten: `gasolinera` ×3, `parque` ×5 (los de ESPECIALES); el guion fotografía el primero.
- Las manzanas corrientes («comercial», «torres», «pisos», «casas», «industrial») son anillos de casas con patio verde
  (`_patio_de_manzana`) o torres blancas de ventanas idénticas: de lejos se repiten.

## Pendiente (siguiente commit)
1. Recorrido completo por todas las zonas (guion listo; ~35 zonas × 2 tomas) y capturas en `capturas_ciudad/`.
2. Por zona: vacíos / desentonan / incoherencias (calles que no llevan a nada, aceras cortadas, semáforos sin cruce).
3. Lista priorizada de mejoras con pieza de `assets/kenney/INVENTARIO.md` o de `Modulos`, y horas estimadas.
