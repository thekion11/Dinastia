# Método de trabajo: Cascada + Modelo V

Cada fase grande (del MEGAPLAN) se hace en **cascada**: no se empieza la siguiente hasta cerrar la compuerta de la anterior. Cada nivel de diseño tiene su **nivel de prueba** pareado (modelo en V), definido ANTES de escribir código.

```
Requisitos del dueño ─────────────────────────────► Aceptación (el dueño valida: vídeo/captura/juego real)
   Diseño del sistema (MEGAPLAN, fases) ─────────► Pruebas de sistema (especiales.sh, recorrido, huella_mundo)
      Diseño de módulos (clases, responsabilidades) ► Integración (mini_banco.sh por grupo)
         Código (< 450 líneas por script) ────────► Unitarias (banco.sh, comprobar_scripts)
```

## Cascada: fases y compuertas
1. **Requisitos** — el pedido del dueño se escribe con sus palabras en `02_vision/` y se parte en ítems con id (`M-nnn` en el catálogo). *Compuerta:* el dueño valida («sí/dale»).
2. **Diseño** — cifras y reglas decididas por escrito (p. ej. MEGAPLAN §9.1). *Compuerta:* decisiones registradas, sin «por decidir» bloqueante.
3. **Construcción** — bloques pequeños, commit + push por bloque. *Compuerta:* `herramientas/banco.sh` = «FIN. 0 fallos».
4. **Verificación** — `especiales.sh` (y `todo` antes de un cierre de fase), capturas en Forward+ con la cámara real. *Compuerta:* 0 errores, antes/después si es visual.
5. **Aceptación** — se enseña al dueño (vídeo/captura/lista). *Compuerta:* su visto bueno. Si lo rechaza, vuelve a 1 o 3 y se anota.
6. **Cierre** — el ítem pasa a HECHO en el plan del lunes; se BORRA de ahí (no se archiva ni se tacha).

## Trazabilidad requisito ↔ prueba
Cada ítem HECHO cita su prueba (escena o sección de banco). Un ítem sin prueba no es HECHO, es PARCIAL. Los ítems de solo-vista se prueban con captura (`pruebas/captura_*.tscn`) y se anotan.

## Reglas de higiene
- Tareas terminadas **salen** del plan (quedan solo en el historial de git).
- Idea postergada = fila en `PLAN_DEL_LUNES.md` con fase destino; cada auditoría revisa las que llevan > 2 fases sin moverse.
- Código nuevo nace < 450 líneas; documento nuevo se registra en `00_INDICE.md`.
- Nada irreversible (borrar ramas, reescribir historia, tocar LFS, keystore, licencias) sin orden explícita del dueño.
- **Lo completado se borra, no se tacha**: ni `~~tachado~~` ni filas «HECHO» en tableros o catálogos; la historia vive en git.
