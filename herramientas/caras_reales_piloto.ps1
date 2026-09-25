# Piloto: busca 15 jugadores reales conocidos en Wikidata/Commons para validar
# el metodo antes de lanzarlo sobre los ~2125 nombres unicos de REALES.
# No se manda ningun dato personal del usuario a Wikimedia: el User-Agent es
# generico, sin correo ni nombre real.

$ua = "DinastiaFutbolManagerBot/1.0 (proyecto personal de aficionado, uso no comercial)"
$headers = @{ "User-Agent" = $ua }

$paisWikidata = @{
    "CHI"="Q298"; "ARG"="Q414"; "ESP"="Q29"; "BRA"="Q155"; "FRA"="Q142";
    "ENG"="Q145"; "GER"="Q183"; "URU"="Q77"; "BEL"="Q31"; "NED"="Q55";
    "POL"="Q36"; "TUR"="Q43"; "SVN"="Q215"; "SVK"="Q214"; "NOR"="Q20";
    "GHA"="Q117"; "JPN"="Q17"; "CRO"="Q224"; "COL"="Q739"; "COD"="Q974"; "PAR"="Q733"
}

$pilotos = @(
    @{nombre="Arturo Vidal"; pais="CHI"},
    @{nombre="Kylian Mbappé"; pais="FRA"},
    @{nombre="Jude Bellingham"; pais="ENG"},
    @{nombre="Robert Lewandowski"; pais="POL"},
    @{nombre="Vinícius Júnior"; pais="BRA"},
    @{nombre="Antoine Griezmann"; pais="FRA"},
    @{nombre="Thibaut Courtois"; pais="BEL"},
    @{nombre="Julián Álvarez"; pais="ARG"},
    @{nombre="Charles Aránguiz"; pais="CHI"},
    @{nombre="Fernando Zampedri"; pais="ARG"},
    @{nombre="Eduardo Vargas"; pais="CHI"},
    @{nombre="Nicolás Guerra"; pais="CHI"},
    @{nombre="Nico Williams"; pais="ESP"},
    @{nombre="Unai Simón"; pais="ESP"},
    @{nombre="Diego Sánchez"; pais="CHI"}
)

$resultados = @()

foreach ($p in $pilotos) {
    $nombre = $p.nombre
    $pais = $p.pais
    $fila = [ordered]@{ nombre=$nombre; pais=$pais; encontrado=$false; qid=$null; ocupacion_ok=$false; pais_ok=$false; commons_file=$null; licencia=$null; ancho=$null; alto=$null; nota=$null }
    try {
        $buscar = Invoke-RestMethod -Uri "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=$([uri]::EscapeDataString($nombre))&language=es&format=json&type=item&limit=5" -Headers $headers -ErrorAction Stop
        Start-Sleep -Milliseconds 400
        if (-not $buscar.search -or $buscar.search.Count -eq 0) {
            $fila.nota = "sin resultados en wikidata"
            $resultados += [PSCustomObject]$fila
            continue
        }
        $qidElegido = $null
        foreach ($cand in $buscar.search) {
            $qid = $cand.id
            $ent = Invoke-RestMethod -Uri "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=$qid&props=claims&format=json" -Headers $headers -ErrorAction Stop
            Start-Sleep -Milliseconds 400
            $claims = $ent.entities.$qid.claims
            $esFutbolista = $false
            if ($claims.P106) {
                foreach ($c in $claims.P106) {
                    if ($c.mainsnak.datavalue.value.id -eq "Q937857") { $esFutbolista = $true }
                }
            }
            if (-not $esFutbolista) { continue }
            $paisOk = $false
            if ($claims.P27 -and $paisWikidata.ContainsKey($pais)) {
                foreach ($c in $claims.P27) {
                    if ($c.mainsnak.datavalue.value.id -eq $paisWikidata[$pais]) { $paisOk = $true }
                }
            }
            $qidElegido = $qid
            $fila.qid = $qid
            $fila.ocupacion_ok = $true
            $fila.pais_ok = $paisOk
            if ($claims.P18) {
                $fila.commons_file = $claims.P18[0].mainsnak.datavalue.value
            }
            break   # el primer candidato que sea futbolista de verdad, se queda
        }
        if (-not $qidElegido) {
            $fila.nota = "ningun candidato es futbolista (P106)"
            $resultados += [PSCustomObject]$fila
            continue
        }
        if (-not $fila.commons_file) {
            $fila.nota = "futbolista encontrado pero sin foto (P18) en wikidata"
            $resultados += [PSCustomObject]$fila
            continue
        }
        $fila.encontrado = $true
        $tituloArchivo = "File:" + $fila.commons_file
        $info = Invoke-RestMethod -Uri "https://commons.wikimedia.org/w/api.php?action=query&titles=$([uri]::EscapeDataString($tituloArchivo))&prop=imageinfo&iiprop=url|extmetadata|size&format=json" -Headers $headers -ErrorAction Stop
        Start-Sleep -Milliseconds 400
        $pagina = $info.query.pages.PSObject.Properties.Value | Select-Object -First 1
        if ($pagina.imageinfo) {
            $ii = $pagina.imageinfo[0]
            $fila.ancho = $ii.width
            $fila.alto = $ii.height
            $fila.licencia = $ii.extmetadata.LicenseShortName.value
        }
    } catch {
        $fila.nota = "error: $($_.Exception.Message)"
    }
    $resultados += [PSCustomObject]$fila
}

$resultados | Format-Table nombre, encontrado, ocupacion_ok, pais_ok, licencia, ancho, alto, nota -AutoSize
$resultados | ConvertTo-Json -Depth 3 | Set-Content -Path "C:\Users\Alumno\Desktop\Proyecto x\herramientas\caras_reales_piloto_resultado.json" -Encoding utf8
