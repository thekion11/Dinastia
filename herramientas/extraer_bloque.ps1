# ============================================================================
#  EXTRAER UN BLOQUE DE UNA FUNCION LARGA A SU PROPIA FUNCION
# ============================================================================
#  Saca las lineas [Desde..Hasta] de js\juego.js, las envuelve en una funcion
#  nueva con su comentario, y deja en su sitio una llamada.
#
#  POR QUE UNA HERRAMIENTA Y NO HACERLO A MANO
#  Copiar treinta lineas a mano y volver a escribirlas es la forma mas facil de
#  colar una errata que el banco de pruebas no siempre caza. Aqui las lineas se
#  COPIAN del propio fichero: el cuerpo de la funcion nueva es, byte a byte, el
#  que habia. Lo unico que se escribe a mano es el comentario y la firma.
#
#  ANTES DE USARLA hay que comprobar que ninguna variable declarada dentro del
#  bloque se use MAS ABAJO en la funcion original. Si se usa, no se puede sacar
#  el bloque sin devolverla, y el juego se rompe de forma silenciosa (la variable
#  queda undefined dentro de un if y nadie se entera). Se comprueba asi:
#     awk 'NR>=<Hasta+1> && NR<=<fin de la funcion>' js\juego.js | grep -o "\bvar\b"
#
#  Uso:
#    .\extraer_bloque.ps1 -Desde 2761 -Hasta 2790 -Nombre semEntrenamiento `
#                         -Comentario "Entrenamiento semanal" [-Simular]
# ============================================================================
param(
  [Parameter(Mandatory=$true)][int]$Desde,
  [Parameter(Mandatory=$true)][int]$Hasta,
  [Parameter(Mandatory=$true)][string]$Nombre,
  [string]$Comentario = "",
  [string]$Firma = "",
  [string]$Llamada = "",
  # Funcion de la que se saca el bloque. La nueva se coloca justo delante de
  # ella, para que se lea en el orden en que se usa.
  [string]$Anfitriona = "procesoSemanal",
  # Lineas de comentario adicionales, una por elemento.
  [string[]]$Notas = @(),
  # Linea que se anade al final del cuerpo, normalmente un return. Hace falta
  # cuando el bloque declara algo que los pasos siguientes siguen usando: en vez
  # de renunciar a extraerlo, se devuelve y el que llama lo recoge.
  [string]$Epilogo = "",
  [switch]$Simular
)

$raiz = Split-Path -Parent $PSScriptRoot
$p = Join-Path $raiz "js\juego.js"
$lineas = [IO.File]::ReadAllLines($p, [Text.Encoding]::UTF8)

if ($Desde -lt 1 -or $Hasta -gt $lineas.Count -or $Hasta -lt $Desde) { throw "rango fuera de sitio" }
$cuerpo = $lineas[($Desde-1)..($Hasta-1)]

# El bloque tiene que estar equilibrado por si solo: si abre mas llaves de las
# que cierra, el corte esta mal puesto y sacarlo destroza el fichero.
$abre = 0; $cierra = 0; $tildes = 0
foreach ($l in $cuerpo) {
  $abre   += ([Regex]::Matches($l, '\{')).Count
  $cierra += ([Regex]::Matches($l, '\}')).Count
  $tildes += ([Regex]::Matches($l, '`')).Count
}
if ($abre -ne $cierra) { throw "el bloque no cuadra: $abre llaves abiertas y $cierra cerradas" }
if (($tildes % 2) -ne 0) { throw "el bloque parte una plantilla de texto (acentos graves impares)" }

if ($Simular) {
  Write-Host "bloque de $($Hasta - $Desde + 1) lineas, llaves $abre/$cierra, acentos $tildes  -> OK"
  Write-Host "primera: $($cuerpo[0])"
  Write-Host "ultima : $($cuerpo[-1])"
  return
}

if ($Llamada -eq "") { $Llamada = "$Nombre()" }
if ($Firma -eq "")   { $Firma   = "$Nombre()" }

$nueva = @()
if ($Comentario -ne "") {
  $nueva += "/* $Comentario"
  foreach ($n in $Notas) { $nueva += "   $n" }
  $nueva += "   El orden de ejecucion no cambia: solo se le pone nombre a lo que ya hacia. */"
}
# Si la firma ya trae su propia llave de apertura (porque incluye un preludio
# como "e3Vallas(x){ const{...}=x;"), NO se le anade otra: eso abria un bloque
# que nadie cerraba y el fichero entero dejaba de compilar. Ya paso una vez.
if ($Firma.TrimEnd().EndsWith("{") -or $Firma.Contains("{")) { $nueva += "function $Firma" }
else { $nueva += "function $Firma{" }
$nueva += $cuerpo
if ($Epilogo -ne "") { $nueva += "  $Epilogo" }
$nueva += "}"

$resto = @()
$resto += $lineas[0..($Desde-2)]
$resto += "  $Llamada;"
$resto += $lineas[$Hasta..($lineas.Count-1)]

$txt = ($resto -join "`n")
# la funcion nueva se coloca justo delante de la que la contenia
$marca = "function $Anfitriona("
$iMarca = $txt.IndexOf($marca)
if ($iMarca -lt 0) { throw "no encuentro la funcion $Anfitriona" }
$marca = $txt.Substring($iMarca, $txt.IndexOf("{", $iMarca) - $iMarca + 1)
$txt = $txt.Replace($marca, (($nueva -join "`n") + "`n" + $marca))
[IO.File]::WriteAllText($p, $txt, (New-Object Text.UTF8Encoding($false)))

Write-Host "extraido $Nombre ($($Hasta - $Desde + 1) lineas)"
