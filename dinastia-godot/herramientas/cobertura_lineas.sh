#!/bin/bash
# COBERTURA DE LÍNEAS (18-11-2026): instrumenta `nucleo/` (o las carpetas que se pasen), corre el banco en partes con el código
# instrumentado, escribe docs/04_auditorias/cobertura_lineas_AAAA-MM-DD.md y RESTAURA el código con git al terminar (o al cortar).
#   herramientas/cobertura_lineas.sh              → nucleo/
#   herramientas/cobertura_lineas.sh nucleo ui    → varias carpetas
# Exige que `nucleo/`, `ui/`, `visor/` y `pruebas/banco.gd` no tengan cambios sin guardar (se restauran con `git checkout`).
cd "$(dirname "$0")/.." || exit 1
DIRS=("${@:-nucleo}")
if [[ -n "$(git status --porcelain -- nucleo ui visor minijuegos pruebas/banco.gd pruebas/cob_lineas.gd)" ]]; then
  echo "Hay cambios sin guardar en el código: commit o stash antes (el script restaura con git checkout)."; exit 1
fi
export COB_TMP="${COB_TMP:-${TMPDIR:-/tmp}/cobertura_lineas}"
rm -rf "$COB_TMP"; mkdir -p "$COB_TMP"
restaurar() {
  git checkout -- nucleo ui visor minijuegos pruebas/banco.gd 2> /dev/null
  rm -f pruebas/cob_lineas.gd pruebas/cob_lineas.gd.uid
  timeout 600 godot --headless --import --path . > /dev/null 2>&1
  echo "Código restaurado."
}
trap restaurar EXIT
python3 -I herramientas/cobertura_lineas.py instrumentar "${DIRS[@]}" || exit 1
sed -i 's|^\tget_tree().quit(0 if _fallos.is_empty() else 1)|\tCobLineas.volcar()\n&|' pruebas/banco.gd
grep -q "CobLineas.volcar" pruebas/banco.gd || { echo "No se pudo enganchar banco.gd"; exit 1; }
timeout 900 godot --headless --import --path . > "$COB_TMP/import.txt" 2>&1
if grep -aq "SCRIPT ERROR\|Parse Error" "$COB_TMP/import.txt"; then grep -a "SCRIPT ERROR\|Parse Error" "$COB_TMP/import.txt" | head -5; echo "El código instrumentado no compila: ver $COB_TMP/import.txt"; fi
NUCLEOS=$(nproc 2> /dev/null || echo 1)
N="${BANCO_PARTES:-$(( NUCLEOS < 6 ? NUCLEOS : 6 ))}"
export COB_SALIDA="$COB_TMP/volcado"
for ((i = 0; i < N; i++)); do
  BANCO_PARTE="$i/$N" XDG_DATA_HOME="$COB_TMP/xdg$i" timeout 3000 godot --headless --path . res://pruebas/banco.tscn > "$COB_TMP/parte$i.txt" 2>&1 &
done
wait
for ((i = 0; i < N; i++)); do
  echo "parte $i: $(sed 's/\x1b\[[0-9;]*m//g' "$COB_TMP/parte$i.txt" | grep -a '===== FIN' | tail -1)"
done
python3 -I herramientas/cobertura_lineas.py informe "$COB_TMP"/volcado.*
