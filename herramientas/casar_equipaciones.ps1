# ============================================================
#  Casa los nombres de club del juego con los ficheros de equipacion.
#  Los packs vienen nombrados como 'colo_colo_1.png', 'universidad_de_chile_2.png';
#  el juego los llama 'Colo-Colo', 'U. de Chile'. Hay que normalizar los dos lados
#  y ademas resolver las abreviaturas que usa el juego (U., D., Atl., Dep., R.).
#  Genera equipaciones.js con la tabla NOMBRE -> [ficheros].
# ============================================================
$ErrorActionPreference='Continue'
$raiz  = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$kits  = Join-Path $raiz 'recursos\equipaciones'
$utf8  = New-Object System.Text.UTF8Encoding($false)

# --- normalizador comun a los dos lados ---
function Norm([string]$s){
  if(-not $s){return ''}
  $s = $s.ToLowerInvariant()
  # quitar tildes descomponiendo en Unicode: 'Ñublense' y 'nublense' tienen que casar
  $n = $s.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach($c in $n.ToCharArray()){
    if([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark){ [void]$sb.Append($c) }
  }
  $s = $sb.ToString()
  # las abreviaturas del juego a su forma larga, que es como vienen los ficheros
  $s = $s -replace '\bu\.\s*','universidad '
  $s = $s -replace '\bd\.\s*','deportes '
  $s = $s -replace '\bdep\.\s*','deportivo '
  $s = $s -replace '\batl\.\s*','atletico '
  $s = $s -replace '\br\.\s*','real '
  $s = $s -replace '\bs\.\s*','santiago '
  $s = $s -replace '\bstgo\.\s*','santiago '
  $s = $s -replace '\bpto\.\s*','puerto '
  $s = $s -replace '\bgral\.\s*','general '
  $s = $s -replace '[^a-z0-9]+','_'
  $s = $s.Trim('_')
  return $s
}

# --- lado de los ficheros: colo_colo_1.png -> clave colo_colo ---
$porClave = @{}
foreach($f in Get-ChildItem $kits -Filter *.png){
  $b = [IO.Path]::GetFileNameWithoutExtension($f.Name)
  # OJO: cada pack numera a su manera. Chile trae 'colo_colo_1.png' (con guion) y
  # Espana trae 'barcelona1.png' (sin guion). Exigir el guion dejaba fuera media
  # Liga: 3 clubes de 16 casaban teniendo el pack entero delante.
  $clave = $b -replace '_?alt_?\d*$',''       # quitar el sufijo _alt / _alt_2 / Barcelona_alt
  $clave = $clave -replace '_?\d+$',''        # quitar el numero de equipacion, con o sin guion
  # La clave del FICHERO tambien pasa por Norm: si no, 'o-higgins' nunca casaria
  # con "O'Higgins", que normalizado es 'o_higgins'.
  $clave = Norm $clave
  if(-not $porClave.ContainsKey($clave)){ $porClave[$clave] = @() }
  $porClave[$clave] += $f.Name
}
Write-Host ("ficheros: " + (Get-ChildItem $kits -Filter *.png).Count + " en " + $porClave.Count + " clubes")

# --- lado del juego ---
$lineas = Get-Content (Join-Path $raiz 'herramientas\clubes.txt') -Encoding UTF8
$tabla = @{}
$sin = @()
foreach($l in $lineas){
  if(-not $l.Trim()){continue}
  $p = $l -split "`t"
  $nombre = $p[0].Trim()
  if(-not $nombre){continue}
  $n = Norm $nombre
  $hit = $null
  if($porClave.ContainsKey($n)){ $hit = $n }
  else{
    # Coincidencia por CONTENCION en cualquiera de los dos sentidos y en cualquier
    # posicion: el juego dice 'Palestino' y el fichero es 'deportivo_palestino';
    # el juego dice 'U. Catolica' -> 'universidad_catolica' y el fichero puede ser
    # 'universidad_catolica_de_chile'. Se exige que el trozo comun tenga al menos
    # 6 caracteres y caiga en frontera de palabra, para no casar 'union' con
    # 'union_deportiva_cualquier_cosa' por accidente.
    $mejor=$null; $mejorLen=0
    foreach($k in $porClave.Keys){
      if($n.Length -lt 6 -and $k -ne $n){continue}
      $casa = ($k -eq $n) -or
              $k.StartsWith($n+'_') -or $k.EndsWith('_'+$n) -or $k.Contains('_'+$n+'_') -or
              $n.StartsWith($k+'_') -or $n.EndsWith('_'+$k) -or $n.Contains('_'+$k+'_')
      # gana la coincidencia mas larga: 'universidad_catolica' antes que 'catolica'
      if($casa -and $k.Length -gt $mejorLen){ $mejor=$k; $mejorLen=$k.Length }
    }
    $hit=$mejor
  }
  if($hit){ $tabla[$nombre] = $porClave[$hit] | Sort-Object }
  else{ $sin += $nombre }
}

Write-Host ("CASADOS: " + $tabla.Count + "   sin equipacion: " + $sin.Count)
Write-Host ("sin casar (muestra): " + (($sin | Select-Object -First 12) -join ', '))

# --- generar la tabla para el juego ---
$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine('/* ============================================================')
[void]$sb.AppendLine('   EQUIPACIONES REALES · tabla generada por herramientas\casar_equipaciones.ps1')
[void]$sb.AppendLine('   NO editar a mano: se regenera al anadir packs nuevos a recursos\equipaciones\.')
[void]$sb.AppendLine('   Clave = nombre del club TAL COMO lo llama el juego (en texto claro).')
[void]$sb.AppendLine('   Valor = ficheros de camiseta, en orden: titular, visitante, tercera...')
[void]$sb.AppendLine('   ============================================================ */')
[void]$sb.Append('const EQUIP_REAL={')
$primero=$true
foreach($k in ($tabla.Keys | Sort-Object)){
  if(-not $primero){ [void]$sb.Append(',') }
  $primero=$false
  $vals = ($tabla[$k] | ForEach-Object { '"' + $_ + '"' }) -join ','
  [void]$sb.Append('"' + $k.Replace('"','\"') + '":[' + $vals + ']')
}
[void]$sb.AppendLine('};')
[IO.File]::WriteAllText((Join-Path $raiz 'herramientas\equipaciones.js'), $sb.ToString(), $utf8)
Write-Host "escrito herramientas\equipaciones.js"
