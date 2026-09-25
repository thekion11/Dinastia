# ============================================================================
#  QUE NECESITA UN BLOQUE PARA PODER SALIR DE SU FUNCION
# ============================================================================
#  Antes de extraer un trozo de una funcion larga hay que saber dos cosas, y las
#  dos hay que DEDUCIRLAS del codigo, no recordarlas:
#
#   1. QUE USA de fuera. Todo identificador que el bloque lee pero que se declara
#      en la funcion que lo contiene. Eso es lo que hay que pasarle.
#   2. QUE DEJA. Todo lo que el bloque declara y se sigue usando mas abajo. Eso
#      hay que devolverlo, o el bloque no se puede sacar.
#
#  POR QUE ESTA HERRAMIENTA EXISTE
#  Se intento hacer el punto 1 comprobando contra una LISTA ESCRITA A MANO de los
#  nombres del contexto. Fallo: la seccion de banderines usaba `finos`, que no
#  estaba en la lista, y el estadio dejo de dibujarse ("finos is not defined").
#  Una lista a mano solo encuentra lo que uno ya recuerda; esto encuentra lo que
#  hay.
#
#  Uso:
#    .\analizar_bloque.ps1 -Funcion estadio3D -Desde 13949 -Hasta 14110
# ============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Funcion,
  [Parameter(Mandatory=$true)][int]$Desde,
  [Parameter(Mandatory=$true)][int]$Hasta,
  [string]$Fichero = "js\juego.js"
)

$raiz = Split-Path -Parent $PSScriptRoot
$p = Join-Path $raiz $Fichero
$lineas = [IO.File]::ReadAllLines($p, [Text.Encoding]::UTF8)

# --- limites de la funcion anfitriona ---------------------------------------
$ini = -1
for ($i = 0; $i -lt $lineas.Count; $i++) {
  if ($lineas[$i] -match "^function\s+$([Regex]::Escape($Funcion))\s*\(") { $ini = $i; break }
}
if ($ini -lt 0) { throw "no encuentro la funcion $Funcion" }
$fin = -1
for ($i = $ini + 1; $i -lt $lineas.Count; $i++) { if ($lineas[$i] -eq "}") { $fin = $i; break } }
if ($fin -lt 0) { throw "no encuentro el final de $Funcion" }

$b0 = $Desde - 1; $b1 = $Hasta - 1
if ($b0 -lt $ini -or $b1 -gt $fin) { throw "el bloque no cae dentro de $Funcion ($($ini+1)-$($fin+1))" }

function Declarados([int]$a, [int]$b, [bool]$soloPrimerNivel = $false) {
  $s = New-Object 'System.Collections.Generic.HashSet[string]'
  for ($i = $a; $i -le $b; $i++) {
    $l = $lineas[$i]
    # Para saber QUE DEJA el bloque solo valen las declaraciones de su primer
    # nivel (dos espacios). Las de dentro de un bucle o un if son de ese ambito y
    # no las ve nadie fuera; contarlas llenaba el informe de contadores i, k, x
    # que ademas se repiten mas abajo en otros bucles y parecian escaparse.
    if ($soloPrimerNivel -and $l -notmatch '^  [A-Za-z_$({[]') { continue }
    # const/let/var, incluyendo desestructuracion: const{a,b}=x  y  const[a,b]=y
    foreach ($m in [Regex]::Matches($l, '\b(?:const|let|var)\s*\{([^}]*)\}')) {
      foreach ($n in $m.Groups[1].Value -split ',') {
        $n = ($n -split ':')[-1].Trim(); if ($n -match '^[A-Za-z_$][A-Za-z0-9_$]*$') { [void]$s.Add($n) }
      }
    }
    foreach ($m in [Regex]::Matches($l, '\b(?:const|let|var)\s*\[([^\]]*)\]')) {
      foreach ($n in $m.Groups[1].Value -split ',') {
        $n = $n.Trim(); if ($n -match '^[A-Za-z_$][A-Za-z0-9_$]*$') { [void]$s.Add($n) }
      }
    }
    # OJO: una sola declaracion puede traer VARIOS nombres separados por comas
    # (const p=..., h=alt[i]*k;). Capturar solo el primero hizo que `h` pasara por
    # variable del contexto siendo local del bloque, y el estadio dejo de
    # dibujarse con "h is not defined". Se recorre la lista entera y se coge el
    # nombre que hay antes de cada '=' al nivel superior de comas, saltandose las
    # que van dentro de parentesis, corchetes o llaves.
    foreach ($m in [Regex]::Matches($l, '\b(?:const|let|var)\s+([^;]+)')) {
      $cad = $m.Groups[1].Value
      $prof2 = 0; $act = ''
      foreach ($ch in $cad.ToCharArray()) {
        if ($ch -eq '(' -or $ch -eq '[' -or $ch -eq '{') { $prof2++ }
        elseif ($ch -eq ')' -or $ch -eq ']' -or $ch -eq '}') { $prof2-- }
        if ($ch -eq ',' -and $prof2 -le 0) {
          if ($act -match '^\s*([A-Za-z_$][A-Za-z0-9_$]*)') { [void]$s.Add($Matches[1]) }
          $act = ''
        } else { $act += $ch }
      }
      if ($act -match '^\s*([A-Za-z_$][A-Za-z0-9_$]*)') { [void]$s.Add($Matches[1]) }
    }
    # variables de bucle: for(const x of  /  for(let i=
    foreach ($m in [Regex]::Matches($l, 'for\s*\(\s*(?:const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)')) {
      [void]$s.Add($m.Groups[1].Value)
    }
  }
  # La coma no es un adorno: sin ella PowerShell DESENROLLA el conjunto al
  # devolverlo y lo deja en un array. Sobre un array, el .Add() con que mas
  # abajo se anaden los parametros de la anfitriona no hacia absolutamente nada,
  # y el fallo pasaba por un fallo del regex.
  return ,$s
}

function Usados([int]$a, [int]$b) {
  $s = New-Object 'System.Collections.Generic.HashSet[string]'
  for ($i = $a; $i -le $b; $i++) {
    # se quitan cadenas y comentarios: dentro solo hay texto, no identificadores
    $l = $lineas[$i]
    $l = [Regex]::Replace($l, '//.*$', '')
    $l = [Regex]::Replace($l, '/\*.*?\*/', '')
    $l = [Regex]::Replace($l, "'(\\.|[^'\\])*'", "''")
    $l = [Regex]::Replace($l, '"(\\.|[^"\\])*"', '""')
    # en las plantillas SI hay codigo dentro de ${...}: se conserva eso y se tira el resto
    $l = [Regex]::Replace($l, '`([^`]*)`', { param($m)
      $trozos = [Regex]::Matches($m.Groups[1].Value, '\$\{([^}]*)\}')
      ($trozos | ForEach-Object { $_.Groups[1].Value }) -join ' '
    })
    foreach ($m in [Regex]::Matches($l, '(?<![.\w$])([A-Za-z_$][A-Za-z0-9_$]*)')) {
      [void]$s.Add($m.Groups[1].Value)
    }
  }
  # La coma no es un adorno: sin ella PowerShell DESENROLLA el conjunto al
  # devolverlo y lo deja en un array, que ya no admite .Add() ni compara igual.
  return ,$s
}

# Para saber que hay que PASARLE al bloque solo valen las variables del PRIMER
# NIVEL de la funcion anfitriona. Contando tambien las anidadas, nombres cortos
# como h, d o y -declarados dentro del bucle de OTRA seccion- pasaban por
# contexto, y al pasarlos como parametro el estadio moria con "h is not defined".
$decFuncion = Declarados $ini $fin $true

# Los PARAMETROS de la anfitriona tambien son contexto, y no son declaraciones
# const/let/var, asi que Declarados no los veia. Al sacar el bloque de mundo de
# resolverEvento(op) se quedo sin `op`: la primera linea del bloque reventaba con
# "op is not defined" y el banco de pruebas dio cero errores, porque esos eventos
# no siempre salen en tres temporadas. Un fallo silencioso, que es el peor.
if ($lineas[$ini] -match '^function\s+[^(]+\(([^)]*)\)') {
  foreach ($n in $Matches[1] -split ',') {
    $n = (($n -split '=')[0]).Trim().TrimStart('.')
    if ($n -match '^[A-Za-z_$][A-Za-z0-9_$]*$') { [void]$decFuncion.Add($n) }
  }
}

$decBloque  = Declarados $b0 $b1
$decBloqueTop = Declarados $b0 $b1 $true
$usaBloque  = Usados $b0 $b1

# --- 1) lo que hay que PASARLE ----------------------------------------------
$necesita = @()
foreach ($n in $usaBloque) {
  if ($decFuncion.Contains($n) -and -not $decBloque.Contains($n)) { $necesita += $n }
}
$necesita = $necesita | Sort-Object -Unique

# --- 2) lo que hay que DEVOLVER ---------------------------------------------
$usaDespues = Usados ($b1 + 1) $fin
$deja = @()
foreach ($n in $decBloqueTop) { if ($usaDespues.Contains($n)) { $deja += $n } }
# @() a la fuerza: en PowerShell, si una lista queda con UN solo elemento deja
# de ser lista y pasa a ser esa cadena, y entonces $deja[0] devuelve su primera
# LETRA. Salia "const s=" en vez de "const sky=".
$deja = @($deja | Sort-Object -Unique)
$necesita = @($necesita)

Write-Host ""
Write-Host "BLOQUE $($Desde)-$($Hasta) dentro de $Funcion ($($ini+1)-$($fin+1))" -ForegroundColor Cyan
Write-Host ""
Write-Host "  NECESITA del contexto ($($necesita.Count)):" -ForegroundColor Yellow
Write-Host "    $($necesita -join ',')"
Write-Host ""
Write-Host "  DEJA para despues ($($deja.Count)):" -ForegroundColor Yellow
Write-Host "    $(if ($deja.Count) { $deja -join ',' } else { '(nada: se puede sacar tal cual)' })"
Write-Host ""
Write-Host "  Firma sugerida:" -ForegroundColor Green
Write-Host "    -Firma `"NOMBRE(x){ const{$($necesita -join ',')}=x;`""
Write-Host "    -Llamada `"$(if ($deja.Count -eq 1) { "const $($deja[0])=NOMBRE({$($necesita -join ',')})" } else { "NOMBRE({$($necesita -join ',')})" })`""
if ($deja.Count -eq 1) { Write-Host "    -Epilogo `"return $($deja[0]);`"" }
elseif ($deja.Count -gt 1) { Write-Host "    OJO: deja mas de una cosa; hay que devolver un objeto y desestructurarlo." -ForegroundColor Red }
