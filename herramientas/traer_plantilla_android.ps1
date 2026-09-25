# ============================================================================
#  TRAER SOLO LA PLANTILLA DE ANDROID DE GODOT
# ============================================================================
#  Godot publica TODAS las plantillas de exportacion en un solo archivo de
#  1,22 GB (`.tpz`). De ahi solo hacen falta tres entradas para el APK:
#
#      android_debug.apk      la plantilla de depuracion
#      android_release.apk    la de release
#      android_source.zip     las fuentes para compilacion personalizada
#
#  BAJARSE 1,22 GB PARA SACAR ~130 MB no tiene sentido, y hay un techo de 1 GB
#  para lo que se descarga en este proyecto. Pero un `.tpz` es un ZIP normal y
#  el servidor de GitHub acepta peticiones por RANGO, asi que se puede leer el
#  indice del ZIP por el final y bajar solo los trozos que interesan.
#
#  COMO FUNCIONA UN ZIP LEIDO AL REVES:
#    1. Al final del archivo esta el "End Of Central Directory" (firma PK\5\6),
#       que dice donde empieza el indice y cuanto ocupa.
#    2. El indice ("central directory") tiene una ficha por archivo con su
#       nombre, su tamano y EN QUE BYTE empieza su cabecera local.
#    3. Con eso se pide por rango solo la cabecera local + los datos de las
#       tres entradas que hacen falta, y se descomprimen.
#
#  Es exactamente lo que hace un gestor de descargas cuando te deja sacar un
#  archivo suelto de un ZIP remoto, y aqui ahorra 1,1 GB de descarga.
# ============================================================================
param(
  [string]$Version = "4.7.2-stable",
  [switch]$Forzar
)

$ErrorActionPreference = "Stop"
$url     = "https://github.com/godotengine/godot/releases/download/$Version/Godot_v${Version}_export_templates.tpz"
# OJO: la URL lleva GUION (4.7.2-stable) y la carpeta de Godot lleva PUNTO
# (4.7.2.stable). Es la misma version escrita de dos maneras y no coinciden: si
# se deja el guion, Godot no encuentra la plantilla y no dice por que.
$carpetaVer = $Version -replace "-", "."
$destino = Join-Path $env:APPDATA "Godot\export_templates\$carpetaVer"
$quiero  = @("android_debug.apk", "android_release.apk", "android_source.zip")

New-Item -ItemType Directory -Force $destino | Out-Null

$faltan = @($quiero | Where-Object { $Forzar -or -not (Test-Path (Join-Path $destino $_)) })
if ($faltan.Count -eq 0) {
  Write-Host "  la plantilla de Android ya esta en $destino" -ForegroundColor Green
  exit 0
}
Write-Host "  faltan: $($faltan -join ', ')" -ForegroundColor Yellow

# --- 1. tamano total y soporte de rangos ------------------------------------
function Pedir-Rango([long]$desde, [long]$hasta) {
  $req = [System.Net.HttpWebRequest]::Create($url)
  $req.Method = "GET"
  $req.Timeout = 120000
  $req.ReadWriteTimeout = 600000
  $req.AddRange($desde, $hasta)
  $resp = $req.GetResponse()
  $ms = New-Object System.IO.MemoryStream
  $resp.GetResponseStream().CopyTo($ms)
  $resp.Close()
  return $ms.ToArray()
}

# Para los archivos GRANDES no se puede devolver un array de bytes.
# `android_source.zip` son 204 MB comprimidos, y tenerlos en memoria -mas la
# copia que hace ToArray()- revienta PowerShell 5.1 con OutOfMemoryException.
# Se escribe directo a disco segun va llegando.
function Bajar-A-Fichero([long]$desde, [long]$hasta, [string]$ruta, [bool]$inflar) {
  $req = [System.Net.HttpWebRequest]::Create($url)
  $req.Method = "GET"
  $req.Timeout = 120000
  $req.ReadWriteTimeout = 900000
  $req.AddRange($desde, $hasta)
  $resp = $req.GetResponse()
  $entrada = $resp.GetResponseStream()
  $fs = [System.IO.File]::Create($ruta)
  try {
    if ($inflar) {
      $inf = New-Object System.IO.Compression.DeflateStream($entrada, [System.IO.Compression.CompressionMode]::Decompress)
      $inf.CopyTo($fs, 1048576)
      $inf.Close()
    } else {
      $entrada.CopyTo($fs, 1048576)
    }
  } finally {
    $fs.Close()
    $resp.Close()
  }
}

$req = [System.Net.HttpWebRequest]::Create($url)
$req.Method = "GET"; $req.AddRange(0, 0)
$resp = $req.GetResponse()
$rango = $resp.Headers["Content-Range"]
$resp.Close()
if (-not $rango) { throw "El servidor no acepta descargas por rango; habria que bajar los 1,22 GB enteros." }
$total = [long]($rango -split "/")[1]
Write-Host ("  archivo remoto: {0} MB" -f [math]::Round($total/1MB,0))

# --- 2. leer el final para encontrar el indice ------------------------------
# 64 KB bastan: el EOCD esta como mucho a 65.557 bytes del final (22 de
# cabecera + 65.535 de comentario, que es el maximo que admite el formato).
$cola = Pedir-Rango ([long]($total - 65557)) ([long]($total - 1))
$firma = @(0x50,0x4B,0x05,0x06)
$pos = -1
for ($i = $cola.Length - 22; $i -ge 0; $i--) {
  if ($cola[$i] -eq $firma[0] -and $cola[$i+1] -eq $firma[1] -and
      $cola[$i+2] -eq $firma[2] -and $cola[$i+3] -eq $firma[3]) { $pos = $i; break }
}
if ($pos -lt 0) { throw "No encuentro el indice del ZIP (EOCD)" }
$dirTam  = [BitConverter]::ToUInt32($cola, $pos + 12)
$dirIni  = [BitConverter]::ToUInt32($cola, $pos + 16)
$nEntradas = [BitConverter]::ToUInt16($cola, $pos + 10)
Write-Host ("  indice: {0} entradas, {1} KB" -f $nEntradas, [math]::Round($dirTam/1KB,0))

# --- 3. leer el indice y localizar las tres entradas ------------------------
$dir = Pedir-Rango ([long]$dirIni) ([long]($dirIni + $dirTam - 1))
$p = 0
$encontradas = @{}
while ($p -lt $dir.Length - 46) {
  if (-not ($dir[$p] -eq 0x50 -and $dir[$p+1] -eq 0x4B -and $dir[$p+2] -eq 0x01 -and $dir[$p+3] -eq 0x02)) { break }
  $metodo   = [BitConverter]::ToUInt16($dir, $p + 10)
  $compTam  = [BitConverter]::ToUInt32($dir, $p + 20)
  $crudoTam = [BitConverter]::ToUInt32($dir, $p + 24)
  $nomLen   = [BitConverter]::ToUInt16($dir, $p + 28)
  $extLen   = [BitConverter]::ToUInt16($dir, $p + 30)
  $comLen   = [BitConverter]::ToUInt16($dir, $p + 32)
  $offset   = [BitConverter]::ToUInt32($dir, $p + 42)
  $nombre   = [System.Text.Encoding]::UTF8.GetString($dir, $p + 46, $nomLen)
  $corto    = Split-Path $nombre -Leaf
  if ($faltan -contains $corto) {
    $encontradas[$corto] = @{ offset = [long]$offset; comp = [long]$compTam; crudo = [long]$crudoTam; metodo = $metodo }
  }
  $p += 46 + $nomLen + $extLen + $comLen
}
foreach ($f in $faltan) {
  if (-not $encontradas.ContainsKey($f)) { throw "El .tpz no trae $f" }
}

# --- 4. bajar solo esas entradas y descomprimir -----------------------------
$totalMB = 0
foreach ($nombre in $encontradas.Keys) {
  $e = $encontradas[$nombre]
  Write-Host ("  bajando {0} ({1} MB comprimido)..." -f $nombre, [math]::Round($e.comp/1MB,1)) -ForegroundColor Yellow
  # La cabecera local repite nombre y extra con longitudes PROPIAS, que pueden
  # no coincidir con las del indice: hay que leerla para saber donde empiezan
  # de verdad los datos. Saltarse esto es el error clasico y saca basura.
  $cab = Pedir-Rango $e.offset ($e.offset + 29)
  $nomLenL = [BitConverter]::ToUInt16($cab, 26)
  $extLenL = [BitConverter]::ToUInt16($cab, 28)
  $iniDatos = $e.offset + 30 + $nomLenL + $extLenL
  $salida = Join-Path $destino $nombre
  Bajar-A-Fichero $iniDatos ($iniDatos + $e.comp - 1) $salida ($e.metodo -ne 0)
  $mb = [math]::Round((Get-Item $salida).Length/1MB, 1)
  $totalMB += $mb
  Write-Host ("  listo: {0} ({1} MB)" -f $salida, $mb) -ForegroundColor Green
}

Write-Host ""
Write-Host ("  PLANTILLA DE ANDROID LISTA en {0}  ({1} MB bajados de {2} MB)" -f `
  $destino, [math]::Round($totalMB,0), [math]::Round($total/1MB,0)) -ForegroundColor Cyan
