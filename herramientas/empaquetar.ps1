# ============================================================================
#  EMPAQUETAR DINASTIA PARA ENTREGAR
# ============================================================================
#    .\empaquetar.ps1                    -> pregunta el formato
#    .\empaquetar.ps1 -Formato completo  -> .exe con TODO (fotos y camisetas)
#    .\empaquetar.ps1 -Formato ligero    -> .exe pequeno, para mandar por chat
#    .\empaquetar.ps1 -Formato web       -> pagina jugable en el navegador
#    .\empaquetar.ps1 -Formato apk       -> APK firmado para Android
#    .\empaquetar.ps1 -Formato zip       -> el ligero comprimido y listo
#    .\empaquetar.ps1 -Formato todos     -> los cinco
#    .\empaquetar.ps1 -Servir            -> levanta la web en localhost:8060
#
#  LOS DOS .EXE Y POR QUE SON DOS
#
#  El juego trae 1.048 fotos de futbolistas reales (117 MB) y 1.102 fotos de
#  camisetas reales (170 MB). Con todo dentro son casi 300 MB y NO CABE en
#  ningun chat. Sin nada de eso el juego funciona igual -las caras se dibujan
#  y las camisetas se generan por color y estampado-, solo que no se ven las
#  reales. Asi que hay dos entregas y se elige:
#
#    completo  ~250 MB  para ti, para probar de verdad, con todo el material.
#    ligero     ~60 MB  para mandar. Caras dibujadas y camisetas procedurales.
#
#  LAS CAMISETAS REALES VIVEN FUERA DEL PROYECTO (`Proyecto x\recursos\
#  equipaciones`), porque `KitTextureFactory` las busca al lado del ejecutable.
#  Por eso el formato "completo" COPIA esa carpeta junto al .exe: si se manda
#  solo el .exe, el juego arranca igual pero con camisetas dibujadas.
#
#  LA TRAMPA QUE YA SE PAGO. Las fotos de las caras se leen con `FileAccess` a
#  bytes crudos, no con `load()`. Godot, al exportar, sustituye cada imagen por
#  su version importada (`.ctex`) y el .jpg original NO viaja: en el .exe las
#  caras reales desaparecian sin un solo error. Se arreglo poniendo esos 1.048
#  archivos en modo `keep` en su `.import`, que ademas bajo el .exe de 452 MB a
#  234 MB porque dejo de meter una textura por cada foto que nadie leia.
#
#  ANDROID. Ya funciona. El SDK y el JDK estan en `herramientas\android` y la
#  plantilla se trajo con `traer_plantilla_android.ps1`, que baja SOLO las tres
#  entradas de Android del .tpz oficial -426 MB en vez de 1.222- leyendo el
#  indice del ZIP remoto por rangos HTTP.
# ============================================================================
param(
  [ValidateSet("completo", "ligero", "web", "apk", "zip", "todos", "")]
  [string]$Formato = "",
  [switch]$Servir,
  [string]$Version = ""
)

$ErrorActionPreference = "Stop"
$raiz     = Split-Path -Parent $PSScriptRoot
$proyecto = Join-Path $raiz "dinastia-godot"
$godot    = Join-Path $raiz "herramientas\godot\Godot_v4.7.2-stable_win64_console.exe"
$entregas = Join-Path $raiz "entregas"
$kits     = Join-Path $raiz "recursos\equipaciones"

if (-not (Test-Path $godot)) { throw "No encuentro el motor en $godot" }
if (-not (Test-Path (Join-Path $proyecto "export_presets.cfg"))) {
  throw "Falta export_presets.cfg en $proyecto"
}
if ($Version -eq "") { $Version = "v" + (Get-Date -Format "yyyyMMdd") }

if ($Formato -eq "" -and -not $Servir) {
  Write-Host ""
  Write-Host "  EN QUE FORMATO QUIERES EL JUEGO?" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "   1) completo   .exe con TODO: 1.048 caras reales y 1.102 camisetas."
  Write-Host "                 ~250 MB + la carpeta de camisetas al lado."
  Write-Host "                 Es el que hay que usar para probar de verdad."
  Write-Host ""
  Write-Host "   2) ligero     .exe pequeno, ~124 MB. Mismo juego, pero las caras"
  Write-Host "                 se dibujan y las camisetas se generan por color."
  Write-Host ""
  Write-Host "   3) web        Pagina para el navegador, ~58 MB. Sirve en movil."
  Write-Host "                 Se sube a cualquier hosting; carga mas lento."
  Write-Host ""
  Write-Host "   4) apk        Para Android, ~47 MB. Firmado: se instala en"
  Write-Host "                 cualquier telefono con 'origenes desconocidos'."
  Write-Host ""
  Write-Host "   5) zip        El ligero comprimido (~55 MB), para adjuntar."
  Write-Host ""
  Write-Host "   6) todos      Los cinco."
  Write-Host ""
  $r = Read-Host "  Numero (1-6)"
  switch ($r) {
    "1" { $Formato = "completo" }
    "2" { $Formato = "ligero" }
    "3" { $Formato = "web" }
    "4" { $Formato = "apk" }
    "5" { $Formato = "zip" }
    "6" { $Formato = "todos" }
    default { $Formato = "ligero" }
  }
}

New-Item -ItemType Directory -Force $entregas | Out-Null

function Exportar([string]$preset, [string]$destino) {
  New-Item -ItemType Directory -Force (Split-Path -Parent $destino) | Out-Null
  Write-Host ""
  Write-Host "  exportando [$preset] ..." -ForegroundColor Yellow
  # --headless para que no abra ventana; --export-release para que salga sin la
  # marca de "debug" ni la consola de errores encima del juego.
  $salida = Join-Path $env:TEMP "empaquetar_$preset.txt"
  Start-Process -FilePath $godot -Wait -NoNewWindow -RedirectStandardOutput $salida `
    -ArgumentList @("--headless", "--path", "`"$proyecto`"", "--export-release", $preset, "`"$destino`"") | Out-Null
  if (-not (Test-Path $destino)) {
    if (Test-Path $salida) { Write-Host (Get-Content $salida -Raw) }
    throw "La exportacion de [$preset] no genero $destino"
  }
  $mb = [math]::Round((Get-Item $destino).Length / 1MB, 1)
  Write-Host ("  listo: {0} ({1} MB)" -f $destino, $mb) -ForegroundColor Green
}


# Igual que `Exportar` pero en modo depuracion. Se usa SOLO para el APK: es el
# unico formato donde la firma de release de Godot 4.7 no sale y la de debug si,
# y un APK firmado en debug se instala igual de bien en un telefono.
function Exportar-Debug([string]$preset, [string]$destino) {
  New-Item -ItemType Directory -Force (Split-Path -Parent $destino) | Out-Null
  Write-Host ""
  Write-Host "  exportando [$preset] ..." -ForegroundColor Yellow
  $salida = Join-Path $env:TEMP "empaquetar_$preset.txt"
  Start-Process -FilePath $godot -Wait -NoNewWindow -RedirectStandardOutput $salida `
    -ArgumentList @("--headless", "--path", "`"$proyecto`"", "--export-debug", $preset, "`"$destino`"") | Out-Null
  if (-not (Test-Path $destino)) {
    if (Test-Path $salida) { Write-Host (Get-Content $salida -Raw) }
    throw "La exportacion de [$preset] no genero $destino"
  }
  $mb = [math]::Round((Get-Item $destino).Length / 1MB, 1)
  Write-Host ("  listo: {0} ({1} MB)" -f $destino, $mb) -ForegroundColor Green
}

function Peso([string]$ruta) {
  if (-not (Test-Path $ruta)) { return 0 }
  $b = (Get-ChildItem $ruta -Recurse -File | Measure-Object -Property Length -Sum).Sum
  return [math]::Round($b / 1MB, 1)
}

$hechos = @()

if ($Formato -eq "completo" -or $Formato -eq "todos") {
  $dir = Join-Path $entregas "windows"
  Exportar "Windows" (Join-Path $dir "DINASTIA.exe")
  # LAS CAMISETAS REALES VAN AL LADO DEL .EXE, no dentro: `KitTextureFactory`
  # las busca por ruta relativa al ejecutable. Sin esta copia el juego arranca
  # igual pero dibuja las camisetas en vez de usar las fotos.
  if (Test-Path $kits) {
    $destinoKits = Join-Path $dir "recursos\equipaciones"
    Write-Host "  copiando camisetas reales..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force (Split-Path -Parent $destinoKits) | Out-Null
    Copy-Item $kits $destinoKits -Recurse -Force
    Write-Host ("  camisetas: {0} MB" -f (Peso $destinoKits)) -ForegroundColor Green
  } else {
    Write-Host "  AVISO: no encuentro $kits; el completo saldra sin camisetas reales" -ForegroundColor Yellow
  }
  $hechos += ("{0}   ({1} MB en total)" -f $dir, (Peso $dir))
}

if ($Formato -eq "ligero" -or $Formato -eq "zip" -or $Formato -eq "todos") {
  $dirL = Join-Path $entregas "windows-ligero"
  Exportar "WindowsLigero" (Join-Path $dirL "DINASTIA.exe")
  $hechos += ("{0}   ({1} MB)" -f $dirL, (Peso $dirL))
}

if ($Formato -eq "web" -or $Formato -eq "todos") {
  $web = Join-Path $entregas "web"
  Exportar "Web" (Join-Path $web "index.html")
  $hechos += ("{0}   ({1} MB)  -  probar con: .\empaquetar.ps1 -Servir" -f $web, (Peso $web))
}

if ($Formato -eq "apk" -or $Formato -eq "todos") {
  $apk = Join-Path $entregas "android\DINASTIA.apk"
  # SE FIRMA CON EL KEYSTORE DE DEPURACION, y no es un atajo: un APK firmado en
  # debug se instala en cualquier telefono igual que uno de release. La unica
  # diferencia es que no vale para subirlo a Google Play, y esto no va a Play.
  #
  # La firma de release de Godot 4.7 exige los tres campos del keystero en el
  # preset -almacen, usuario y contrasena- y se niega aunque esten los tres
  # puestos; la de debug sale de los ajustes del editor y funciona. Cuando haya
  # que publicar en Play se resuelve, pero para mandar el juego no hace falta.
  Exportar-Debug "Android" $apk
  $hechos += ("{0}   ({1} MB)  -  firmado, se instala en cualquier movil" -f $apk, (Peso (Split-Path $apk)))
}

if ($Formato -eq "zip" -or $Formato -eq "todos") {
  $zip = Join-Path $entregas ("DINASTIA-$Version.zip")
  if (Test-Path $zip) { Remove-Item $zip -Force }
  Compress-Archive -Path (Join-Path $entregas "windows-ligero\*") -DestinationPath $zip
  $hechos += ("{0}   ({1} MB)" -f $zip, ([math]::Round((Get-Item $zip).Length / 1MB, 1)))
}

if ($hechos.Count -gt 0) {
  Write-Host ""
  Write-Host "  ENTREGAS EN: $entregas" -ForegroundColor Cyan
  foreach ($h in $hechos) { Write-Host "    $h" }
  Write-Host ""
}

# --- servidor local para probar la version web ------------------------------
#
# La web exportada NO se puede abrir con doble clic: el navegador bloquea el
# wasm y los modulos cuando la pagina viene de `file://`, y lo unico que se ve
# es una pantalla negra sin ningun error visible. Hace falta un servidor, aunque
# sea local, y por eso viene uno aqui: no hay que instalar Python ni nada.
#
# Se sirve SIN cabeceras de aislamiento a proposito: el preset web va con hilos
# desactivados (`thread_support=false`), que es justo el modo que no las
# necesita. Activarlos obligaria a servir con COOP/COEP y la pagina dejaria de
# funcionar en cualquier hosting estatico sencillo.
if ($Servir) {
  $web = Join-Path $entregas "web"
  if (-not (Test-Path (Join-Path $web "index.html"))) {
    throw "No hay version web todavia. Lanza primero: .\empaquetar.ps1 -Formato web"
  }
  $puerto = 8060
  $tipos = @{
    ".html" = "text/html"; ".js" = "text/javascript"; ".wasm" = "application/wasm";
    ".pck"  = "application/octet-stream"; ".png" = "image/png"; ".svg" = "image/svg+xml";
    ".json" = "application/json"; ".ico" = "image/x-icon"; ".css" = "text/css";
    ".ogg"  = "audio/ogg"; ".wav" = "audio/wav"; ".woff2" = "font/woff2";
    ".jpg"  = "image/jpeg"; ".webp" = "image/webp";
  }
  $oyente = New-Object System.Net.HttpListener
  $oyente.Prefixes.Add("http://localhost:$puerto/")
  $oyente.Start()
  Write-Host ""
  Write-Host "  servidor en http://localhost:$puerto   (Ctrl+C para parar)" -ForegroundColor Cyan
  Start-Process "http://localhost:$puerto/index.html"
  try {
    while ($oyente.IsListening) {
      $ctx = $oyente.GetContext()
      $ruta = $ctx.Request.Url.LocalPath.TrimStart("/")
      if ($ruta -eq "") { $ruta = "index.html" }
      $archivo = Join-Path $web $ruta
      if (Test-Path $archivo -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($archivo).ToLower()
        $ctx.Response.ContentType = if ($tipos.ContainsKey($ext)) { $tipos[$ext] } else { "application/octet-stream" }
        $bytes = [System.IO.File]::ReadAllBytes($archivo)
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $ctx.Response.StatusCode = 404
      }
      $ctx.Response.OutputStream.Close()
    }
  } finally {
    $oyente.Stop()
  }
}
