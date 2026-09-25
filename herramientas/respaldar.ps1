# ============================================================================
#  RESPALDO FECHADO DEL PROYECTO
# ============================================================================
#    .\respaldar.ps1 -Nombre "godot-agentes-libres"
#    .\respaldar.ps1 -Nombre "godot-lo-que-sea" -Version "v4.02"
#
#  COPIA lo que cambia entre una tanda y otra: el codigo, los datos, la
#  documentacion y las capturas que prueban que algo funciona.
#
#  NO COPIA -y esta es la razon de que exista este script-:
#
#    dinastia-godot\.godot       344 MB  cache de importacion de Godot. Se
#                                        regenera sola con `run_godot.ps1
#                                        -Reimportar`. Copiarla es copiar algo
#                                        que el motor puede rehacer en 20 s.
#    herramientas\android        708 MB  el SDK de Android. Identico en cada
#                                        respaldo, y ya vive en el proyecto.
#    herramientas\godot          173 MB  el motor portable. Idem.
#    herramientas\rclone          81 MB  herramienta descargada. Idem.
#    herramientas\salida          56 MB  volcados de prueba, desechables.
#
#  LO QUE COSTO APRENDERLO (7-9-2026): dos respaldos hechos a lo bruto -copiar
#  las dos carpetas enteras- pesaron 1.523 MB CADA UNO en vez de los ~130 MB de
#  los anteriores. Entre los dos se comieron 2,7 GB de un disco que tenia 4,4 GB
#  libres. Con este script pesan 161 MB. La regla en una linea: un respaldo
#  guarda lo que NO se puede volver a generar.
# ============================================================================
param(
  [Parameter(Mandatory = $true)][string]$Nombre,
  [string]$Version = ""
)

$raiz = Split-Path -Parent $PSScriptRoot
$fecha = Get-Date -Format "yyyy-MM-dd-HHmm"

if ($Version -eq "") {
  # Sigue la numeracion de la ultima carpeta vXX.YY que haya en respaldos\.
  #
  # TRAMPA YA PAGADA: hacer el `-match` en un `Where-Object` y leer `$Matches`
  # dentro del `Sort-Object` de al lado NO funciona -`$Matches` lo pisa la
  # ultima comparacion que se haya hecho, asi que el orden sale de cualquier
  # cosa-. La primera version de este script eligio "v3.75" teniendo "v3.99"
  # delante. Hay que extraer los numeros a un objeto propio primero.
  $versiones = Get-ChildItem (Join-Path $raiz "respaldos") -Directory -ErrorAction SilentlyContinue |
    ForEach-Object {
      if ($_.Name -match '^v(\d+)\.(\d+)') {
        [PSCustomObject]@{ Mayor = [int]$Matches[1]; Menor = [int]$Matches[2] }
      }
    } | Sort-Object Mayor, Menor -Descending
  if ($versiones) {
    $u = $versiones[0]
    # 99 es el tope de la serie: despues viene la mayor siguiente.
    if ($u.Menor -ge 99) { $Version = "v{0}.0" -f ($u.Mayor + 1) }
    else { $Version = "v{0}.{1}" -f $u.Mayor, ($u.Menor + 1) }
  } else {
    $Version = "v1.0"
  }
}

$destino = Join-Path $raiz ("respaldos\{0}-{1}-{2}" -f $Version, $fecha, $Nombre)
New-Item -ItemType Directory -Path $destino -Force | Out-Null

$excluidos = @(
  (Join-Path $raiz "dinastia-godot\.godot"),
  (Join-Path $raiz "herramientas\android"),
  (Join-Path $raiz "herramientas\godot"),
  (Join-Path $raiz "herramientas\rclone"),
  (Join-Path $raiz "herramientas\salida")
)

function Copiar($origen, $sub) {
  $destinoSub = Join-Path $destino $sub
  Get-ChildItem $origen -Recurse -File | ForEach-Object {
    $saltar = $false
    foreach ($ex in $excluidos) { if ($_.FullName.StartsWith($ex, 'OrdinalIgnoreCase')) { $saltar = $true } }
    if (-not $saltar) {
      $rel = $_.FullName.Substring($origen.Length).TrimStart('\')
      $final = Join-Path $destinoSub $rel
      New-Item -ItemType Directory -Path (Split-Path $final -Parent) -Force | Out-Null
      Copy-Item $_.FullName $final -Force
    }
  }
}

Copiar (Join-Path $raiz "dinastia-godot") "dinastia-godot"
Copiar (Join-Path $raiz "herramientas")  "herramientas"

$mb = (Get-ChildItem $destino -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host ("respaldo listo: {0}" -f $destino) -ForegroundColor Green

# ============================================================================
#  UN SOLO RESPALDO ACTIVO (22-9-2026, bug real encontrado por el usuario:
#  "el disco tiene tan poco, antes tenia cerca de 13 gigas").
#
#  Esta era la regla desde siempre ("un solo respaldo, no una pila de
#  copias" -ver ROADMAP.md, LEEME.md, la memoria del proyecto-), pero el
#  script NUNCA borro nada: solo creaba una carpeta nueva cada vez, y borrar
#  la anterior quedaba en manos de quien lo llamara, a mano, cada vez. Se
#  salto varias rondas seguidas (una sesion nocturna sola + esta misma
#  sesion, 12 respaldos en total) y el disco de 119 GB de esta maquina paso
#  de 13 GB libres a 5,6 GB sin que nadie lo notara hasta que el usuario
#  pregunto. Ahora el script mismo borra TODO lo demas en respaldos\ despues
#  de copiar el nuevo -no antes, para no quedarse sin ningun respaldo si la
#  copia fallara a mitad de camino-.
$carpetaRespaldos = Join-Path $raiz "respaldos"
$viejos = Get-ChildItem $carpetaRespaldos -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -ne $destino }
foreach ($v in $viejos) {
  Write-Host ("borrando respaldo anterior: {0}" -f $v.Name) -ForegroundColor DarkGray
  Remove-Item $v.FullName -Recurse -Force
}

Write-Host ("{0:N0} MB   (libre en C: {1:N1} GB)" -f $mb, ((Get-PSDrive C).Free / 1GB)) -ForegroundColor Cyan
