# Atajos de teclado por menú y submenú (3-11-2026, rediseño del menú central, etapa 5)
El central ya no tiene pestañas: cada sección se abre en su menú del panel lateral. Los atajos 1-9/0 de pestañas se sustituyen por UN atajo posible por cada menú (14) y cada submenú (72), generado de `MenusLaterales.MENUS` (si se añade un menú o submenú ya tiene su atajo, sin tecla hasta que se le dé una).

## Teclas de fábrica (letras con sentido)
P plantel · T táctica · M mercado · **F** dinero (finanzas) · C competiciones · **J** próximo partido (jornada) · **B** estadio · H historia · G gente · R carrera · O operaciones · V vida · L calendario · X correo · Y glosario · N pasar un día · F3 buscar · F5 guardar. El resto, sin tecla.
**Cambios respecto a la lista del encargo:** D (dinero) → **F**, A (partido) → **J** y E (estadio) → **B**: A y D son WASD (mover en el partido y en la ciudad) y E es «pestaña siguiente» (junto a Q «anterior»: con un menú abierto mueven por sus submenús), así que ninguna de fábrica toca W, A, S, D, Q, E, flechas, Espacio, Intro ni Esc (lo comprueba la prueba).

## Cómo funcionan
- `AtajosCentrales` (`ui/componentes/atajos_centrales.gd`): `catalogo()` (acción `dinastia_menu_<id>` / `dinastia_sub_<id>_<submenú>`, nombre, grupo, tecla de fábrica, destino), `registrar()` (InputMap), `manejar()`: abre `p._menu_lateral.abrir_menu(id, sub)`. Los submenús que son acciones (móvil, casa, minijuegos…) también valen.
- **Valen con un menú del panel lateral abierto** (cambiar de menú con una tecla): `AtajosMenu._input` los atiende antes del filtro de capas modales y solo calla ante OTRA capa encima (un partido, un diálogo, un minijuego) o escribiendo en un campo, o con Ctrl/Alt/Meta (Ctrl+Q/E siguen cambiando de menú).
- **No se ven en pantalla.** Solo en **Ajustes → Accesibilidad → Teclas**: todos los menús y submenús, agrupados por menú, con su tecla («sin tecla» si no tienen), «Cambiar» y «Quitar» (`TeclasInterfaz.reasignar/quitar`; reasignar quita la tecla de la que la tenía). «Restaurar las teclas de fábrica» las devuelve. Se quitó la lista de atajos de Ajustes → Dispositivo.
- **Migración:** `TeclasInterfaz.cargar` pasa las teclas VIEJAS que alguien había cambiado (`dinastia_ir_*`) a su menú/submenú de ahora (`AtajosCentrales.MIGRACION`) y las descarta si ya no existen («ir a inicio»).
- El mando se deja como estaba (L1/R1, L2/R2).

## Pruebas
`pruebas/ideas/ate_atajos_menus.tscn` (en `especiales.sh`): una acción por menú y submenú (14 + 72); sin teclas repetidas ni chocando con WASD/Q/E; **pulsa cada tecla de fábrica desde otro menú y comprueba que abre su menú y su submenú**; «sin tecla» no hace nada; asignar F9 a «Enfermería» y quitarla; quitar la P y restaurar; la capa modal ajena calla; migración (F7 del mercado viejo → submenú Mercado); Dispositivo ya no enseña atajos; Accesibilidad los lista todos con «Cambiar» y «Quitar». `s3_atajos_clics` actualizada (presupuesto de clics, N, F3, escribir, reasignar).
