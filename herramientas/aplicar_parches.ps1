# ============================================================
#  Aplica parches descritos en JSON sobre el HTML del juego.
#  Cada parche trae 'codigo_actual' y 'codigo_nuevo'. Antes de tocar nada se
#  comprueba que el fragmento a sustituir aparezca EXACTAMENTE UNA VEZ: si no
#  aparece, el parche esta obsoleto; si aparece varias, sustituir seria una
#  loteria. En ambos casos se salta y se avisa, en vez de romper el archivo.
#
#  Uso:  .\aplicar_parches.ps1 -Json ruta\wf_3.json [-Simular]
# ============================================================
param(
  [Parameter(Mandatory=$true)][string]$Json,
  [switch]$Simular   # con esto solo informa, no escribe
)

$ErrorActionPreference = 'Continue'
$raiz  = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$juego = Join-Path $raiz "dinastia-futbol-manager base.html"
$utf8  = New-Object System.Text.UTF8Encoding($false)

$html = [IO.File]::ReadAllText($juego, [Text.Encoding]::UTF8)
$orig = $html
$datos = Get-Content $Json -Raw -Encoding UTF8 | ConvertFrom-Json

$ok = 0; $fallos = @()
foreach ($c in $datos.cambios) {
  $viejo = $c.codigo_actual
  $nuevo = $c.codigo_nuevo
  if ([string]::IsNullOrEmpty($viejo)) { $fallos += "VACIO: $($c.titulo)"; continue }

  # Contar apariciones sin regex: el codigo esta lleno de $ ( ) [ ] que una
  # busqueda por patron interpretaria como metacaracteres.
  $n = 0; $pos = 0
  while (($pos = $html.IndexOf($viejo, $pos, [StringComparison]::Ordinal)) -ge 0) { $n++; $pos += $viejo.Length; if ($n -gt 5) { break } }

  if ($n -eq 0) { $fallos += "NO ESTA: $($c.titulo)"; continue }
  if ($n -gt 1) { $fallos += "AMBIGUO ($n veces): $($c.titulo)"; continue }

  $html = $html.Replace($viejo, $nuevo)
  $ok++
  Write-Host ("  OK  " + $c.titulo) -ForegroundColor Green
}

foreach ($f in $fallos) { Write-Host ("  --  " + $f) -ForegroundColor Yellow }

if (-not $Simular -and $ok -gt 0) {
  [IO.File]::WriteAllText($juego, $html, $utf8)
}
Write-Host ("aplicados $ok de " + $datos.cambios.Count + ($(if($Simular){"  (simulacion, no se escribio)"}else{""}))) -ForegroundColor Cyan
