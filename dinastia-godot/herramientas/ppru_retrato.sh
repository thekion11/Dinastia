#!/bin/bash
# PRUEBA DEL RETRATO 3D CON PANTALLA (ppru, 26-10-2026; plan M-406).
#   herramientas/ppru_retrato.sh              → código 0 = «FIN. 0 fallos»
#   PPRU_GUARDAR=/tmp/capturas/ppru herramientas/ppru_retrato.sh   → además guarda los retratos en JPG
# `pruebas/ideas/ppru_retrato3d` necesita renderizar de verdad: con `ideas.sh` (headless) solo avisa.
# Aquí corre bajo xvfb con Forward+ (lavapipe sin GPU) a través de `captura.sh` (su cerrojo de
# capturas) y del candado de Godot (`turno.sh`), y exige pantalla (PPRU_EXIGIR_PANTALLA=1).
# Tarda ~30-60 s sin GPU. Registro: /tmp/ppru_retrato.txt
cd "$(dirname "$0")/.." || exit 1
LOG=/tmp/ppru_retrato.txt
export PPRU_EXIGIR_PANTALLA=1
RESOLUCION=640x360 timeout 300 "$PWD/herramientas/turno.sh" herramientas/captura.sh res://pruebas/ideas/ppru_retrato3d.tscn --png > "$LOG" 2>&1
sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "  ok \|FALLO\|jugadores:\|SCRIPT ERROR\|SHADER ERROR\|===== FIN"
sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -aq "FIN. 0 fallos" && ! grep -aq "SCRIPT ERROR\|SHADER ERROR" "$LOG"
