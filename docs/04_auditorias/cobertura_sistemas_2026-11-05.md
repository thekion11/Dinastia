# Cobertura de pruebas por sistema (5-11-2026)

Fallo estructural: `banco.sh` y `especiales.sh` solo corrían en Ubuntu (Godot headless, x86_64). Windows, Android y Web
solo se EXPORTABAN (`compilar.yml`); nadie ejecutaba el juego en ellos. Único antecedente: «C++ en ARM» (`probar_nativo`).
Flujo nuevo, aparte y sin bloquear compilaciones: `.github/workflows/plataformas.yml` (manual y en `push` si cambia `dinastia-godot/**`).

| Sistema | Qué se probaba | Qué se añadió | Huecos |
|---|---|---|---|
| Linux x86_64 | banco completo, especiales, comprobar_scripts, `probar_nativo` | nada (sin cambios) | sin pantalla real salvo `xvfb` en algunas especiales |
| Linux ARM64 | `probar_nativo` | nada | solo la extensión C++ |
| **Windows** | solo exportación | `windows-latest`: Godot 4.7.2 (con SHA-512), LFS, importación, `probar_nativo` con la `.dll` y mini banco (grupos `guardado`, `textos`, `competicion`, `lanzamiento`) con Git Bash | banco entero y especiales no corren en Windows (ver portabilidad); sin GPU/ventana real |
| **Web** | solo exportación | export Web propio + Chromium (Playwright-core, Chrome del runner) hasta ver `DINASTIA_MENU_LISTO` sin errores de consola; captura JPG como artefacto | solo el menú: no se juega ni se entra en partido; WebGL por SwiftShader (no mide rendimiento) |
| Android | solo exportación (APK arm64) | nada (no viable, abajo) | ninguna ejecución; solo la señal `DINASTIA_MENU_LISTO` ya emite a logcat para cuando haya dispositivo |
| macOS | nada | nada | **sin preset de exportación** en `export_presets.cfg` (solo Windows, WindowsLigero, Web, Android, Linux); no se crea (orden) |

## Android: por qué no
El APK solo lleva `arm64-v8a` (`architectures/*` en el preset) y la extensión C++ solo existe para arm64. Los runners
`ubuntu-latest` emulan x86_64 con KVM; un arm64 no corre ahí (la traducción ARM de las imágenes de emulador no es fiable
y haría el humo lento y frágil), y los runners ARM (`ubuntu-24.04-arm`) no ofrecen KVM anidado para el emulador.
Opciones futuras: exportar además `x86_64` solo para CI (requiere compilar la extensión x86_64 de Android) o usar una
granja de dispositivos. Cuando exista un dispositivo, basta `adb logcat | grep DINASTIA_MENU_LISTO`.

## Portabilidad de los scripts a Windows (Git Bash)
| Construcción | ¿Portable? | Acción |
|---|---|---|
| `nproc` (banco.sh) | sí en Git Bash; ya tiene `|| echo 1` | ninguna |
| `find … -newer … -print -quit` | sí (findutils de Git for Windows) | ninguna |
| `/tmp/...` como registro por defecto | funciona en Git Bash, pero no es una ruta de Godot/Windows | ahora `${TMPDIR:-/tmp}` (Linux igual) |
| Fin de línea CRLF (`core.autocrlf=true` por defecto en Windows) | **NO**: rompe `#!/bin/bash` y `\r` en variables | `*.sh text eol=lf` en `.gitattributes` + `core.autocrlf false` en el job |
| `godot` en el PATH | en Windows el binario se llama `.exe` | el job copia la versión *console* como `godot.exe` |
| `timeout`, `mktemp`, `sed`, `date +%s` | sí (coreutils de Git for Windows) | ninguna |
| `taskset`, `xvfb-run`, `LP_NUM_THREADS` (hw_modesto, especiales con pantalla) | **NO** | no se ejecutan en Windows; quedan solo en Linux |
| `banco.sh` (kill, subprocesos en paralelo, `XDG_DATA_HOME` por parte) | sin probar; `user://` en Windows ignora `XDG_DATA_HOME`, así que las partes pisarían los guardados | solo se usa `mini_banco.sh` (un proceso) |
| `especiales.sh` | usa muchos `/tmp/...` fijos y `xvfb-run` | pendiente (PLAN_GENERAL) |

## Estado de la verificación
Ver el final de este documento («Resultado de las ejecuciones»).
