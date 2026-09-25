# Captura una imagen de la escena de PARTIDO del visor 3D sin abrir el editor.
# Uso:  .\captura_partido.ps1 [camara] [frames] [nombreSalida]
# OJO: no se puede pasar --headless (el renderizador dummy devuelve una textura
# nula y la captura sale vacia). Hace falta opengl3 con ventana real.
param([int]$Cam = 0, [int]$Frames = 40, [string]$Salida = "captura_partido.png")
$raiz   = Split-Path -Parent $PSScriptRoot
$godot  = Join-Path $raiz "herramientas\godot\Godot_v4.7.2-stable_win64_console.exe"
$visor  = Join-Path $raiz "visor3d"
& $godot --path $visor --rendering-driver opengl3 --resolution 1280x720 `
    --script res://scripts/captura_partido.gd -- $Cam $Frames "res://$Salida"
$img = Join-Path $visor $Salida
if (Test-Path $img) { "OK  $img  $((Get-Item $img).Length) bytes" } else { "SIN CAPTURA" }
