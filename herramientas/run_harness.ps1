# Banco de pruebas automatico de DINASTIA.
# Se ejecuta solo: no necesita rutas de ninguna sesion, se ubica desde su propia carpeta.
#   .\run_harness.ps1
param(
  [string]$Salida = (Join-Path $PSScriptRoot "salida"),
  [int]$Budget = 900000,
  # Que script inyectar. Por defecto el banco de pruebas; con -Script perfilar.js
  # se usa el mismo montaje (UTF-8 sin BOM, URL bien concatenada, perfil de Chrome
  # aparte, nombre unico por PID) para medir tiempos en vez de buscar errores.
  # Duplicar este fichero para el perfilador habria significado duplicar tambien
  # todas sus trampas ya resueltas.
  [string]$Script = "harness.js"
)
# 'Continue' y NO 'Stop': PowerShell 5.1 envuelve cada linea que Chrome escribe en stderr
# en un ErrorRecord. Chrome suelta avisos suyos que no tienen NADA que ver con el juego
# (por ejemplo "gcm mcs_client Authentication Failed: wrong_secret") y con 'Stop' abortaban
# el banco de pruebas entero sin llegar a volcar el resultado. Aparecen o no segun el dia,
# asi que el fallo era intermitente y desconcertante.
$ErrorActionPreference = 'Continue'
# Archivado el 14-9-2026 a "archivo-html-original\" (el motor activo es Godot desde
# el 2-9-2026): sigue leyendose desde ahi como TEXTO -la copia de prueba se sigue
# escribiendo en la raiz del proyecto mas abajo, para que sus rutas relativas a
# recursos\ funcionen igual que siempre-.
$juego   = Join-Path (Split-Path $PSScriptRoot -Parent) "archivo-html-original\dinastia-futbol-manager base.html"
$harness = Join-Path $PSScriptRoot $Script
if (-not (Test-Path $Salida)) { New-Item -ItemType Directory -Path $Salida | Out-Null }
# El fichero de prueba se escribe en la RAIZ del proyecto, no en salida\: desde que
# las texturas y las equipaciones viven en recursos\ como ficheros reales, el juego
# usa rutas relativas y solo funcionan si el HTML esta a la misma altura que esa
# carpeta. Se borra al terminar.
$test    = Join-Path (Split-Path $PSScriptRoot -Parent) "_test_harness.html"
# Nombre unico por pasada: si se lanzan dos harness a la vez (o uno anterior sigue vivo),
# el segundo se estrellaba con "el proceso no puede obtener acceso al archivo" y no volcaba
# ningun resultado, dando la falsa impresion de que el juego estaba roto.
$dom     = Join-Path $Salida ("harness_dom_" + $PID + ".html")
$res     = Join-Path $Salida "harness_resultado.txt"

# UTF-8 sin BOM en las dos puntas: con Get-Content/Set-Content se rompen las enes y las tildes
$utf8 = New-Object System.Text.UTF8Encoding($false)
$html = [System.IO.File]::ReadAllText($juego, [Text.Encoding]::UTF8)
$js   = [System.IO.File]::ReadAllText($harness, [Text.Encoding]::UTF8)
$inyec = "<script>" + $js + "</script></body>"
$html = $html -replace '</body>', $inyec
[System.IO.File]::WriteAllText($test, $html, $utf8)

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$url = 'file:///' + ($test -replace '\\','/' -replace ' ','%20')
# Perfil propio y desechable: sin esto, el headless comparte el perfil por defecto con el
# Chrome del usuario y las dos instancias se estorban (y cerrar una puede tumbar la otra).
$perfil = Join-Path $env:TEMP "dinastia_chrome_perfil"
& $chrome "--headless=new" "--disable-gpu" "--no-sandbox" "--allow-file-access-from-files" "--user-data-dir=$perfil" "--virtual-time-budget=$Budget" "--dump-dom" $url 2>$null |
  Out-File -FilePath $dom -Encoding utf8

$txt = [System.IO.File]::ReadAllText($dom, [Text.Encoding]::UTF8)
$m = [regex]::Match($txt, '(?s)<pre id="RESULTADO">(.*?)</pre>')
if ($m.Success) {
  $r = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
  [System.IO.File]::WriteAllText($res, $r, $utf8)
  Write-Output $r
} else {
  Write-Output "SIN RESULTADO -- el harness no llego a volcar. Tamano del DOM: $($txt.Length)"
  $err = [regex]::Matches($txt, 'Uncaught[^<]{0,200}')
  foreach ($e in $err) { Write-Output $e.Value }
}

# El HTML de prueba vive en la raiz del proyecto (para que las rutas de recursos\
# funcionen), asi que hay que quitarlo de en medio al acabar.
Remove-Item $test -Force -ErrorAction SilentlyContinue
