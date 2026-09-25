$p = "C:\Users\Alumno\Desktop\Proyecto x\dinastia-futbol-manager base.html"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$t = [System.IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
$antes = $t.Length

# Restos de la vieja sustitución letra→número que SÍ llegaban a la pantalla.
# Se arreglan en el origen: el juego debe mostrar los nombres en texto claro.
$map = [ordered]@{
  'liga:"Liga Argent1na"'              = 'liga:"Liga Argentina"'
  'liga:"Brasileirã0"'                 = 'liga:"Brasileirão"'
  'liga:"Primera de Urugu4y"'          = 'liga:"Primera de Uruguay"'
  'liga:"Primera de Paragu4y"'         = 'liga:"Primera de Paraguay"'
  'liga:"Liga de C0lombia"'            = 'liga:"Liga de Colombia"'
  'liga:"Liga de P3rú"'                = 'liga:"Liga de Perú"'
  'liga:"Liga de Ecuad0r"'             = 'liga:"Liga de Ecuador"'
  'liga:"La L1ga"'                     = 'liga:"La Liga"'
  'liga:"Prem1er League"'              = 'liga:"Premier League"'
  'liga:"Ser1e A"'                     = 'liga:"Serie A"'
  'liga:"Bundesl1ga"'                  = 'liga:"Bundesliga"'
  'liga:"L1gue 1"'                     = 'liga:"Ligue 1"'
  'liga:"Div. Profesional de B0livia"' = 'liga:"Div. Profesional de Bolivia"'
  'liga:"J-L1ga"'                      = 'liga:"J-Liga"'
  'liga:"K-L3ague"'                    = 'liga:"K-League"'
  'liga:"L1ga Saudí"'                  = 'liga:"Liga Saudí"'
  'liga:"L1ga de Egipt0"'              = 'liga:"Liga de Egipto"'
  'liga:"Botol4 de Marru3cos"'         = 'liga:"Botola de Marruecos"'
  'liga:"L1ga de Sudáfr1ca"'           = 'liga:"Liga de Sudáfrica"'
  'liga:"A-L3ague"'                    = 'liga:"A-League"'
  'liga:"L1ga MX"'                     = 'liga:"Liga MX"'
  'liga:"M4jor League"'                = 'liga:"Major League"'
  "n:'C0pa Libertador3s'"              = "n:'Copa Libertadores'"
  "n:'C0pa Sudamer1cana'"              = "n:'Copa Sudamericana'"
  "'Libertador3s'"                     = "'Libertadores'"
  "'Sudamer1cana'"                     = "'Sudamericana'"
  'Libertador3s: '                     = 'Libertadores: '
  'Sudamer1cana: '                     = 'Sudamericana: '
  'a Libertador3s y Sudamer1cana'      = 'a Libertadores y Sudamericana'
  'SELECCIÓN DE CH1LE'                 = 'SELECCIÓN DE CHILE'
}

$cambios = @()
foreach ($k in $map.Keys) {
  $n = ([regex]::Matches($t, [regex]::Escape($k))).Count
  if ($n -gt 0) {
    $t = $t.Replace($k, $map[$k])
    $cambios += "  $n x  $k"
  } else {
    $cambios += "  NO ENCONTRADO: $k"
  }
}
[System.IO.File]::WriteAllText($p, $t, $utf8)
Write-Output "bytes antes=$antes despues=$($t.Length)"
$cambios | ForEach-Object { Write-Output $_ }
