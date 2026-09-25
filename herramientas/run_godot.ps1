# ============================================================================
#  LANZADOR DEL PROYECTO GODOT
# ============================================================================
#  El equivalente de run_harness.ps1 para la version en Godot. Tres modos:
#
#    .\run_godot.ps1              banco de pruebas headless (temporadas enteras)
#    .\run_godot.ps1 -Jugar       abre el juego en una ventana
#    .\run_godot.ps1 -Captura     abre, juega una temporada y guarda una captura
#
#  Devuelve el codigo de salida del banco: 0 si no hay fallos, 1 si los hay.
#
#  TRAMPA YA PAGADA: la primera vez que se ejecuta un proyecto de Godot hay que
#  IMPORTARLO. Sin ese paso no existe .godot\global_script_class_cache.cfg, y
#  entonces ninguna clase con `class_name` esta declarada: el banco fallaba con
#  "Identifier Mundo not declared in the current scope" en cuarenta lineas
#  seguidas, que parece un error de codigo y no lo es. Aqui se comprueba y se
#  importa solo si hace falta.
#
#  SEGUNDA TRAMPA: la captura NO puede correr con --headless. Sin ventana no hay
#  framebuffer y la imagen sale negra o nula. Hay que arrancar con
#  --rendering-driver opengl3 y una ventana de verdad. El visor 3D de este mismo
#  proyecto ya se topo con esto.
# ============================================================================
param(
  [switch]$Jugar,
  [switch]$Captura,
  [switch]$Reimportar,
  [string]$Escena = "res://pruebas/banco.tscn",
  [int]$Ancho = 1600,
  [int]$Alto = 900,
  # Fichero donde dejar la salida del banco. Ver "TERCERA TRAMPA" mas abajo:
  # con esto la salida va a disco directa, sin tuberia que se pueda atascar.
  [string]$Salida = "",
  [int]$TopeSegundos = 540
)

$raiz    = Split-Path -Parent $PSScriptRoot
$proyecto = Join-Path $raiz "dinastia-godot"
$godot   = Join-Path $PSScriptRoot "godot\Godot_v4.7.2-stable_win64_console.exe"

if (-not (Test-Path $godot))    { throw "no encuentro Godot en $godot" }
if (-not (Test-Path $proyecto)) { throw "no encuentro el proyecto en $proyecto" }

# QUINTA TRAMPA, YA INTENTADA Y DESCARTADA: se probo aislar el `user://` de
# las pruebas con `--user-data-dir` -asi no comparten "preferencias.cfg" con
# el juego de verdad-, pero ESTE BUILD (Godot_v4.7.2-stable_win64) no trae esa
# opcion (`--help` no la lista) y pasarsela cuelga el proceso entero, sin
# ningun mensaje de error: parecia la solucion correcta y era peor que el
# problema. El arreglo real quedo en `pruebas/captura.gd`, que ahora guarda y
# devuelve el idioma real al terminar -ver el comentario ahi para el porque.

$cache = Join-Path $proyecto ".godot\global_script_class_cache.cfg"
if ($Reimportar -or -not (Test-Path $cache)) {
  Write-Host "importando el proyecto (registra las clases con class_name)..." -ForegroundColor Cyan
  & $godot --headless --path $proyecto --import | Out-Null
  if (-not (Test-Path $cache)) { throw "la importacion no genero la cache de clases" }
}

if ($Jugar) {
  & $godot --path $proyecto --rendering-driver opengl3 --resolution "$($Ancho)x$($Alto)"
  exit $LASTEXITCODE
}

if ($Captura) {
  & $godot --path $proyecto --rendering-driver opengl3 --resolution "$($Ancho)x$($Alto)" --position 0,0 `
           res://pruebas/captura.tscn
  $img = Join-Path $proyecto "pruebas\pantalla.png"
  if (Test-Path $img) { Write-Host "captura: $img" -ForegroundColor Green }
  else { Write-Host "no se genero la captura" -ForegroundColor Red }
  exit $LASTEXITCODE
}

# ---------------------------------------------------------------------------
#  EL BANCO
# ---------------------------------------------------------------------------
#  TERCERA TRAMPA, y la mas cara en tiempo perdido: `& $godot ... *> fichero`
#  manda la salida por una TUBERIA de PowerShell. Si algo abre ese fichero
#  mientras se escribe -un `Get-Content` para "ver como va", por ejemplo-, el
#  escritor se bloquea, la tuberia se llena y Godot se queda parado esperando a
#  poder escribir. El sintoma engana del todo: el proceso figura vivo, pero
#  consume 15% de CPU y no avanza nunca. Se perdieron dos tandas de 25 minutos
#  creyendo que el banco "tardaba mucho".
#
#  Con -Salida se usa Start-Process, que redirige a disco SIN tuberia: el
#  fichero se puede leer mientras corre sin bloquear nada, y ademas se obtiene
#  un codigo de salida de verdad y un tope de tiempo.
if ($Salida) {
  $dir = Split-Path -Parent $Salida
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  $err = [System.IO.Path]::ChangeExtension($Salida, ".err.txt")
  # El proyecto vive en "Proyecto x": sin comillas, Godot recibe "C:\...\Proyecto"
  # y aborta con "Invalid project path". Ya paso una vez.
  $lista = @("--headless", "--path", "`"$proyecto`"", $Escena)
  $t0 = Get-Date
  $p = Start-Process -FilePath $godot -ArgumentList $lista -NoNewWindow -PassThru `
                     -RedirectStandardOutput $Salida -RedirectStandardError $err
  if (-not $p.WaitForExit($TopeSegundos * 1000)) {
    $p.Kill()
    Write-Host "el banco se colgo: pasaron $TopeSegundos s sin terminar" -ForegroundColor Red
    exit 2
  }
  # CUARTA TRAMPA: con Start-Process -PassThru, `$p.ExitCode` sale VACIO si solo
  # se espero con la sobrecarga con tope -no termina de recoger el proceso-. El
  # sintoma es el peor posible: el banco pasa con 0 fallos y el script anuncia
  # "el banco encontro fallos (codigo )". Una prueba que miente al reves.
  # Se remata con el WaitForExit() sin argumentos, y si aun asi viene vacio se
  # cae al VEREDICTO DEL PROPIO BANCO, que lo escribe el en su ultima linea.
  $p.WaitForExit()
  $codigo = $p.ExitCode
  $seg = [int]((Get-Date) - $t0).TotalSeconds
  if ($null -eq $codigo -or $codigo -eq "") {
    $fin = Select-String -Path $Salida -Pattern "FIN\. (\d+) " -Encoding utf8 | Select-Object -Last 1
    if ($fin) { $codigo = [int]$fin.Matches[0].Groups[1].Value }
    else {
      Write-Host "no se pudo leer ni el codigo de salida ni el veredicto del banco" -ForegroundColor Red
      exit 3
    }
  }
  Write-Host ""
  if ($codigo -eq 0) { Write-Host "banco OK (0 fallos) en $seg s -> $Salida" -ForegroundColor Green }
  else { Write-Host "el banco encontro $codigo fallo(s) en $seg s -> $Salida" -ForegroundColor Red }
  exit $codigo
}

& $godot --headless --path $proyecto $Escena
$codigo = $LASTEXITCODE
Write-Host ""
if ($codigo -eq 0) { Write-Host "banco OK (0 fallos)" -ForegroundColor Green }
else { Write-Host "el banco encontro fallos (codigo $codigo)" -ForegroundColor Red }
exit $codigo
