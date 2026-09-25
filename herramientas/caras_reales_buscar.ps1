# Busca en Wikidata/Wikimedia Commons una foto con licencia libre para cada
# jugador real de datos/reales_lista.json (los nombres reales que ya usa
# REALES en el juego). Solo se aceptan fotos alojadas en Commons -Commons no
# admite "fair use", asi que si el archivo vive ahi ya tiene licencia libre
# por politica del sitio, pero igual se registra la licencia exacta que
# devuelve la API-. Nada de datos personales del usuario viaja a Wikimedia.
#
# Reanudable: si el reporte ya tiene un nombre, se salta -para poder cortar y
# seguir despues sin repetir trabajo ni golpear la API de mas-.
#
#   powershell -ExecutionPolicy Bypass -File herramientas\caras_reales_buscar.ps1

$raiz = "C:\Users\Alumno\Desktop\Proyecto x"
$listaPath = "$raiz\dinastia-godot\datos\reales_lista.json"
$reportePath = "$raiz\dinastia-godot\datos\caras_reales_reporte.json"
$carpetaFotos = "$raiz\dinastia-godot\recursos\caras_reales"
$logPath = "$raiz\herramientas\caras_reales_log.txt"

if (-not (Test-Path $carpetaFotos)) { New-Item -ItemType Directory -Path $carpetaFotos | Out-Null }

$ua = "DinastiaFutbolManagerBot/1.0 (proyecto personal de aficionado, uso no comercial)"
$headers = @{ "User-Agent" = $ua }

$paisWikidata = @{
    "CHI"="Q298"; "ARG"="Q414"; "ESP"="Q29"; "BRA"="Q155"; "FRA"="Q142";
    "ENG"="Q145"; "GER"="Q183"; "URU"="Q77"; "BEL"="Q31"; "NED"="Q55";
    "POL"="Q36"; "TUR"="Q43"; "SVN"="Q215"; "SVK"="Q214"; "NOR"="Q20";
    "GHA"="Q117"; "JPN"="Q17"; "CRO"="Q224"; "COL"="Q739"; "COD"="Q974";
    "PAR"="Q733"; "PER"="Q419"; "MEX"="Q96"; "ITA"="Q38"; "POR"="Q45";
    "USA"="Q30"; "CAN"="Q16"; "ECU"="Q736"; "BOL"="Q750"; "VEN"="Q717";
    "CRC"="Q800"; "SEN"="Q1041"; "MAR"="Q1028"; "NGA"="Q1033"; "CIV"="Q1008";
    "SUI"="Q39"; "AUT"="Q40"; "DEN"="Q35"; "SWE"="Q34"; "SCO"="Q22"
}

function Log($msg) {
    $linea = "$(Get-Date -Format 'HH:mm:ss')  $msg"
    Add-Content -Path $logPath -Value $linea
}

function Llamar($uri, $intentos = 5) {
    for ($i = 0; $i -lt $intentos; $i++) {
        try {
            return Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop
        } catch {
            $esperar = [Math]::Min(30, [Math]::Pow(2, $i + 1))
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 429) {
                Start-Sleep -Seconds $esperar
            } elseif ($i -eq $intentos - 1) {
                throw
            } else {
                Start-Sleep -Seconds 2
            }
        }
    }
}

# --- cargar lista de jugadores, deduplicada por nombre ----------------------
Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
$listaRaw = Get-Content -Raw -Path $listaPath -Encoding UTF8
$filas = $ser.DeserializeObject($listaRaw)
$vistos = New-Object 'System.Collections.Generic.HashSet[string]'
$jugadores = New-Object System.Collections.Generic.List[object]
foreach ($f in $filas) {
    if ($vistos.Add($f['nombre'])) {
        $jugadores.Add([PSCustomObject]@{ nombre = $f['nombre']; pais = $f['pais'] })
    }
}
Log "Cargados $($jugadores.Count) nombres unicos a procesar."

# --- reporte existente, para poder reanudar ----------------------------------
$reporte = New-Object System.Collections.Generic.List[object]
$yaHechos = New-Object 'System.Collections.Generic.HashSet[string]'
if (Test-Path $reportePath) {
    $raw = Get-Content -Raw -Path $reportePath -Encoding UTF8
    if ($raw.Trim().Length -gt 0) {
        $anteriores = $ser.DeserializeObject($raw)
        foreach ($r in $anteriores) {
            $reporte.Add([PSCustomObject]$r)
            $yaHechos.Add([string]$r['nombre']) | Out-Null
        }
    }
}
Log "Ya procesados antes: $($yaHechos.Count)."

function Guardar() {
    $reporte | ConvertTo-Json -Depth 4 | Set-Content -Path $reportePath -Encoding utf8
}

$n = 0
$encontrados = 0
foreach ($j in $jugadores) {
    $n++
    if ($yaHechos.Contains($j.nombre)) { continue }
    $nombre = $j.nombre
    $pais = $j.pais
    $fila = [ordered]@{
        nombre=$nombre; pais=$pais; encontrado=$false; qid=$null
        licencia=$null; autor=$null; ancho=$null; alto=$null
        archivo=$null; nota=$null
    }
    try {
        $q = [uri]::EscapeDataString($nombre)
        $buscar = Llamar "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=$q&language=es&format=json&type=item&limit=5"
        Start-Sleep -Milliseconds 1200
        if (-not $buscar.search -or $buscar.search.Count -eq 0) {
            $fila.nota = "sin resultados"
        } else {
            $qidElegido = $null
            $commonsFile = $null
            foreach ($cand in $buscar.search) {
                $qid = $cand.id
                $ent = Llamar "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=$qid&props=claims&format=json"
                Start-Sleep -Milliseconds 1200
                $claims = $ent.entities.$qid.claims
                $esFutbolista = $false
                if ($claims.P106) {
                    foreach ($c in $claims.P106) {
                        if ($c.mainsnak.datavalue.value.id -eq "Q937857") { $esFutbolista = $true }
                    }
                }
                if (-not $esFutbolista) { continue }
                $qidElegido = $qid
                if ($claims.P18) { $commonsFile = $claims.P18[0].mainsnak.datavalue.value }
                break
            }
            if (-not $qidElegido) {
                $fila.nota = "sin coincidencia futbolista"
            } elseif (-not $commonsFile) {
                $fila.qid = $qidElegido
                $fila.nota = "futbolista sin foto en wikidata"
            } else {
                $fila.qid = $qidElegido
                $tituloArchivo = "File:" + $commonsFile
                $qf = [uri]::EscapeDataString($tituloArchivo)
                $info = Llamar "https://commons.wikimedia.org/w/api.php?action=query&titles=$qf&prop=imageinfo&iiprop=url|extmetadata|size&iiurlwidth=400&format=json"
                Start-Sleep -Milliseconds 1200
                $pagina = $info.query.pages.PSObject.Properties.Value | Select-Object -First 1
                if ($pagina.imageinfo) {
                    $ii = $pagina.imageinfo[0]
                    $licencia = $ii.extmetadata.LicenseShortName.value
                    $libre = $licencia -match "^(CC |CC0|Public domain|PD)"
                    if ($libre) {
                        $urlDescarga = if ($ii.thumburl) { $ii.thumburl } else { $ii.url }
                        $ext = [System.IO.Path]::GetExtension($urlDescarga)
                        if ($ext.Length -eq 0 -or $ext.Length -gt 5) { $ext = ".jpg" }
                        $slug = ($nombre -replace '[^\w]+','_').Trim('_')
                        $destino = Join-Path $carpetaFotos "$slug$ext"
                        Invoke-WebRequest -Uri $urlDescarga -Headers $headers -OutFile $destino -ErrorAction Stop
                        Start-Sleep -Milliseconds 800
                        $fila.encontrado = $true
                        $fila.licencia = $licencia
                        $fila.autor = $ii.extmetadata.Artist.value -replace '<[^>]+>',''
                        $fila.ancho = $ii.width
                        $fila.alto = $ii.height
                        $fila.archivo = "recursos/caras_reales/$slug$ext"
                        $encontrados++
                    } else {
                        $fila.licencia = $licencia
                        $fila.nota = "licencia no libre, no se descarga"
                    }
                } else {
                    $fila.nota = "archivo P18 no resuelve en commons"
                }
            }
        }
    } catch {
        $fila.nota = "error: $($_.Exception.Message)"
    }
    $reporte.Add([PSCustomObject]$fila)
    if ($n % 20 -eq 0) {
        Guardar
        Log "$n / $($jugadores.Count) procesados. Encontrados con foto libre: $encontrados."
    }
}
Guardar
Log "TERMINADO. $n procesados, $encontrados con foto libre descargada."
