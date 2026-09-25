# ============================================================================
#  PARTIR heroPortada EN UNA FUNCION POR ESTILO
# ============================================================================
#  heroPortada son 210 lineas con NUEVE portadas encadenadas con if(k==='...').
#  Cada una es independiente: dibuja lo suyo y devuelve. Este script las saca
#  todas DE UNA SOLA PASADA.
#
#  POR QUE DE UNA PASADA Y NO UNA A UNA
#  Cada extraccion inserta la funcion nueva antes de la anfitriona y desplaza
#  todas las lineas de abajo. Sacando nueve bloques de uno en uno habria que
#  recalcular los limites nueve veces, y basta equivocarse en uno para cortar a
#  mitad de un if. Aqui se localizan los nueve limites PRIMERO, sobre el fichero
#  original, y luego se escribe el resultado una sola vez.
#
#  El contexto es el mismo para todas: los rotulos, el generador de numeros
#  estable y el envoltorio del SVG.
#
#  Uso:  .\extraer_portadas.ps1 [-Simular]
# ============================================================================
param([switch]$Simular)

$raiz = Split-Path -Parent $PSScriptRoot
$p = Join-Path $raiz "js\juego.js"
$lineas = [IO.File]::ReadAllLines($p, [Text.Encoding]::UTF8)

$CTX = "claim,CX,k,lienzo,rnd,S,T,W"

# --- limites de heroPortada --------------------------------------------------
$ini = -1
for ($i = 0; $i -lt $lineas.Count; $i++) { if ($lineas[$i] -match '^function\s+heroPortada\s*\(') { $ini = $i; break } }
if ($ini -lt 0) { throw "no encuentro heroPortada" }
$fin = -1
for ($i = $ini + 1; $i -lt $lineas.Count; $i++) { if ($lineas[$i] -eq "}") { $fin = $i; break } }
if ($fin -lt 0) { throw "no encuentro el final de heroPortada" }

# --- localizar cada bloque if(k==='estilo'){ ... } ---------------------------
$bloques = @()
for ($i = $ini; $i -le $fin; $i++) {
  if ($lineas[$i] -match "^\s{2}if\(k==='([a-zA-Z]+)'\)\{") {
    $estilo = $Matches[1]
    # el bloque acaba en la primera linea "  }" a dos espacios
    $b = -1
    for ($j = $i + 1; $j -le $fin; $j++) { if ($lineas[$j] -eq "  }") { $b = $j; break } }
    if ($b -lt 0) { throw "no encuentro el cierre del bloque $estilo" }
    $bloques += [PSCustomObject]@{ Estilo = $estilo; Ini = $i; Fin = $b }
    $i = $b
  }
}

Write-Host "heroPortada: lineas $($ini+1)-$($fin+1)"
Write-Host "bloques encontrados: $($bloques.Count)"
foreach ($b in $bloques) {
  $n = $b.Fin - $b.Ini + 1
  $abre = 0; $cierra = 0; $tildes = 0
  for ($i = $b.Ini; $i -le $b.Fin; $i++) {
    $abre   += ([Regex]::Matches($lineas[$i], '\{')).Count
    $cierra += ([Regex]::Matches($lineas[$i], '\}')).Count
    $tildes += ([Regex]::Matches($lineas[$i], '`')).Count
  }
  $ok = if ($abre -eq $cierra -and ($tildes % 2) -eq 0) { "OK" } else { "DESCUADRA ($abre/$cierra, acentos $tildes)" }
  Write-Host ("  {0,-10} lineas {1}-{2}  ({3,3})  {4}" -f $b.Estilo, ($b.Ini+1), ($b.Fin+1), $n, $ok)
  if ($ok -ne "OK") { throw "el bloque $($b.Estilo) no cuadra; no se toca nada" }
}
if ($Simular) { return }

# --- construir el fichero nuevo ---------------------------------------------
$nuevasFunciones = New-Object Collections.Generic.List[string]
$fuera = New-Object 'System.Collections.Generic.HashSet[int]'
$llamadaEn = @{}

foreach ($b in $bloques) {
  $nombre = "portada" + $b.Estilo.Substring(0,1).ToUpper() + $b.Estilo.Substring(1)
  $nuevasFunciones.Add("/* Portada del menu | estilo '$($b.Estilo)'.")
  $nuevasFunciones.Add("   Sale de heroPortada, que encadenaba las nueve en 210 lineas. Cada una")
  $nuevasFunciones.Add("   dibuja lo suyo y devuelve; el reparto lo sigue haciendo heroPortada. */")
  $nuevasFunciones.Add("function $nombre(x){ const{$CTX}=x;")
  for ($i = $b.Ini; $i -le $b.Fin; $i++) { $nuevasFunciones.Add($lineas[$i]) }
  $nuevasFunciones.Add("}")
  $nuevasFunciones.Add("")
  for ($i = $b.Ini; $i -le $b.Fin; $i++) { [void]$fuera.Add($i) }
  $llamadaEn[$b.Ini] = "  if(k==='$($b.Estilo)')return $nombre({$CTX});"
}

$salida = New-Object Collections.Generic.List[string]
for ($i = 0; $i -lt $lineas.Count; $i++) {
  if ($i -eq $ini) { foreach ($l in $nuevasFunciones) { $salida.Add($l) } }
  if ($llamadaEn.ContainsKey($i)) { $salida.Add($llamadaEn[$i]); continue }
  if ($fuera.Contains($i)) { continue }
  $salida.Add($lineas[$i])
}

[IO.File]::WriteAllLines($p, $salida, (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "extraidas $($bloques.Count) portadas"
