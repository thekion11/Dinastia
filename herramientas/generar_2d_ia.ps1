# ============================================================================
#  GENERAR O EDITAR UNA IMAGEN 2D CON GEMINI
# ============================================================================
#    .\generar_2d_ia.ps1 -Prompt "escudo de futbol dorado y negro, estilo aguila"
#    .\generar_2d_ia.ps1 -Prompt "ponle una bufanda azul" -ImagenBase "recursos\algo.png"
#
#  A diferencia de fal.ai (3D, tarda y hay que preguntar varias veces "¿ya
#  terminaste?"), Gemini genera la imagen y la devuelve en la MISMA respuesta:
#  no hace falta cola ni sondeo.
#
#  HACE FALTA LA API KEY -ya guardada como variable de entorno GEMINI_API_KEY
#  si seguiste los pasos de la sesion anterior (Google AI Studio -> "Create
#  API key")-. Si `echo $env:GEMINI_API_KEY` no muestra nada, hay que abrir
#  una terminal NUEVA -las variables de entorno solo las ve una terminal
#  abierta DESPUES de guardarlas con `setx`-.
# ============================================================================
param(
  [Parameter(Mandatory = $true)][string]$Prompt,
  # Ruta a una imagen existente para EDITAR en vez de crear desde cero. Vacio
  # = generar de cero.
  [string]$ImagenBase = "",
  [string]$Modelo = "gemini-3.1-flash-image",
  [string]$Salida = ""
)

$clave = $env:GEMINI_API_KEY
if (-not $clave) {
  Write-Host "Falta la API key de Gemini (GEMINI_API_KEY)." -ForegroundColor Red
  Write-Host "Si ya la guardaste con setx, cerra esta terminal y abri una nueva." -ForegroundColor Yellow
  exit 1
}

$raiz = Split-Path -Parent $PSScriptRoot
if (-not $Salida) {
  $carpeta = Join-Path $raiz "recursos\imagenes2d_ia"
  $nombre = ($Prompt -replace '[^a-zA-Z0-9]+', '_').Trim('_').ToLower()
  if ($nombre.Length -gt 40) { $nombre = $nombre.Substring(0, 40) }
  $Salida = Join-Path $carpeta "$nombre-$(Get-Date -Format 'yyyyMMdd-HHmmss').png"
} else {
  $carpeta = Split-Path -Parent $Salida
}
if ($carpeta -and -not (Test-Path $carpeta)) { New-Item -ItemType Directory -Force $carpeta | Out-Null }

# LAS PARTES DEL PEDIDO. Si hay imagen base, va como una parte mas -en
# base64, con su tipo MIME- ANTES del texto: es lo que la convierte en una
# edicion ("ponle una bufanda a ESTO") en vez de un dibujo desde cero.
$partes = @()
if ($ImagenBase -ne "") {
  if (-not (Test-Path $ImagenBase)) { throw "no encuentro la imagen: $ImagenBase" }
  $bytes = [System.IO.File]::ReadAllBytes($ImagenBase)
  $b64 = [System.Convert]::ToBase64String($bytes)
  $ext = [System.IO.Path]::GetExtension($ImagenBase).TrimStart('.').ToLower()
  $mime = switch ($ext) { "jpg" { "image/jpeg" }; "jpeg" { "image/jpeg" }; default { "image/png" } }
  $partes += @{ inlineData = @{ mimeType = $mime; data = $b64 } }
}
$partes += @{ text = $Prompt }

$body = @{
  contents = @(@{ parts = $partes })
  generationConfig = @{ responseModalities = @("TEXT", "IMAGE") }
} | ConvertTo-Json -Depth 10

$url = "https://generativelanguage.googleapis.com/v1/models/$Modelo`:generateContent"
$headers = @{ "x-goog-api-key" = $clave; "Content-Type" = "application/json" }

Write-Host "Pidiendo a Gemini ($Modelo): `"$Prompt`"$(if($ImagenBase){" (editando $ImagenBase)"})..." -ForegroundColor Cyan
$resp = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body

$parteImg = $resp.candidates[0].content.parts | Where-Object { $_.inlineData } | Select-Object -First 1
if (-not $parteImg) {
  Write-Host "Gemini no devolvio ninguna imagen. Respuesta completa:" -ForegroundColor Red
  $resp | ConvertTo-Json -Depth 10
  exit 2
}

$datos = [System.Convert]::FromBase64String($parteImg.inlineData.data)
[System.IO.File]::WriteAllBytes($Salida, $datos)
$peso = [math]::Round((Get-Item $Salida).Length / 1KB, 1)
Write-Host "Listo: $Salida ($peso KB)" -ForegroundColor Green

# Si Gemini tambien mando texto (a veces explica lo que hizo), se muestra.
$parteTxt = $resp.candidates[0].content.parts | Where-Object { $_.text } | Select-Object -First 1
if ($parteTxt) { Write-Host "Gemini dice: $($parteTxt.text)" -ForegroundColor DarkGray }
