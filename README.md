# Dinastía

Juego de gestión y carrera de fútbol hecho en **Godot 4.7.2** (GDScript). Partido 3D con motor real, ciudad y estadio recorribles, Carrera de Jugador, 9 idiomas. Datos reales solo en `pack_real.json`; el resto es ficticio.

## Dónde está cada cosa
| Ruta | Contenido |
|---|---|
| `dinastia-godot/` | El juego (proyecto Godot) |
| `docs/` | Toda la documentación, con jerarquía numerada: empieza por [`docs/00_INDICE.md`](docs/00_INDICE.md) |
| `herramientas/` | Scripts de apoyo (partir scripts, auditoría, historial, Drive) |
| `material/`, `recursos/`, `marca/` | Originales de packs, recursos y marca |
| `CLAUDE.md` | Reglas y órdenes vigentes para el asistente |

## Probar
```
dinastia-godot/herramientas/banco.sh        # banco completo: debe acabar en «FIN. 0 fallos»
dinastia-godot/herramientas/especiales.sh   # lo que el banco no ve
```
Antes de abrir Godot: `git lfs pull --include="dinastia-godot/**"`. Clonar ligero: `git clone --single-branch --branch main <url>`.

## Método y estado
[Cascada + Modelo V](docs/01_metodo/METODO.md) · [Plan del lunes (todo lo pendiente)](docs/PLAN_DEL_LUNES.md) · [Última auditoría](docs/04_auditorias/MEGA_AUDITORIA_3.md)

## Normas
Ningún script de más de 450 líneas. Sin archivos nuevos en LFS. Licencias de terceros: [`docs/05_referencia/LICENCIAS.md`](docs/05_referencia/LICENCIAS.md).
