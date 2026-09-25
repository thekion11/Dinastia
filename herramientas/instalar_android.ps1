# ============================================================================
#  INSTALAR DINASTIA EN EL CELULAR — un solo paso: compilar + enviar
# ============================================================================
#    .\instalar_android.ps1
#
#  Compila el APK mas reciente (con todos los cambios de hoy) y lo instala
#  DIRECTO en el telefono si esta conectado por USB con "depuracion USB"
#  activada. Si no hay telefono conectado, deja el APK listo en `entregas\
#  android\` y abre esa carpeta para copiarlo a mano (USB como disco, Drive,
#  WhatsApp Web, lo que sea mas comodo).
#
#  QUE HAY QUE ACTIVAR EN EL TELEFONO LA PRIMERA VEZ (una sola vez, no cada
#  partida): Ajustes -> Acerca del telefono -> tocar 7 veces "Numero de
#  compilacion" (activa "Opciones de desarrollador"), volver a Ajustes ->
#  Opciones de desarrollador -> activar "Depuracion USB". Sin esto ADB no ve
#  el telefono aunque este bien conectado por cable, y este script lo avisa
#  en vez de fallar en silencio.
# ============================================================================
param(
  [switch]$SoloCompilar
)

$ErrorActionPreference = "Stop"
$raiz = $PSScriptRoot
$adb  = Join-Path $raiz "android\sdk\platform-tools\adb.exe"
$apk  = Join-Path (Split-Path -Parent $raiz) "entregas\android\DINASTIA.apk"

Write-Host ""
Write-Host "  1/2 - Compilando el APK con los ultimos cambios..." -ForegroundColor Cyan
& (Join-Path $raiz "empaquetar.ps1") -Formato apk
if (-not (Test-Path $apk)) {
  throw "La compilacion no genero el APK. Revisa el mensaje de arriba."
}

if ($SoloCompilar) {
  Write-Host ""
  Write-Host "  Listo, solo se compilo. El APK esta en: $apk" -ForegroundColor Green
  exit 0
}

if (-not (Test-Path $adb)) {
  Write-Host ""
  Write-Host "  No encuentro adb.exe en $adb -abro la carpeta para copiarlo a mano." -ForegroundColor Yellow
  Start-Process (Split-Path -Parent $apk)
  exit 0
}

Write-Host ""
Write-Host "  2/2 - Buscando un telefono conectado por USB..." -ForegroundColor Cyan
# LA PRIMERA VEZ QUE SE LLAMA A ADB EN LA SESION, LEVANTA SU PROPIO SERVIDOR
# Y AVISA POR STDERR ("* daemon not running; starting now..."). No es un
# error -es informativo-, pero con `$ErrorActionPreference = "Stop"` (puesto
# arriba del todo) PowerShell 5.1 envuelve CUALQUIER linea de stderr de un
# .exe en un NativeCommandError y aborta el script entero. Se baja la
# politica solo para esta llamada y se restaura enseguida.
$prefAntes = $ErrorActionPreference
$ErrorActionPreference = "Continue"
# "adb devices" siempre imprime una linea de cabecera ("List of devices
# attached") antes de la lista real; hay que descartarla o un telefono
# "unauthorized" (el cable conectado pero sin aceptar el permiso en la
# pantalla del celular) se confunde con "no hay nada conectado".
$lineas = & $adb devices 2>$null | Select-Object -Skip 1 | Where-Object { $_.Trim() -ne "" }
$ErrorActionPreference = $prefAntes
$listos      = $lineas | Where-Object { $_ -match "\tdevice$" }
$sin_aceptar = $lineas | Where-Object { $_ -match "\tunauthorized$" }

if ($listos.Count -gt 0) {
  Write-Host "  telefono encontrado, instalando..." -ForegroundColor Green
  # Misma trampa que arriba: "adb install" tambien puede escribir avisos por
  # stderr aunque salga bien.
  $prefAntes = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  # "-r" reinstala ENCIMA de la partida guardada -misma firma, mismo
  # paquete- en vez de pedir desinstalar primero y perder el progreso.
  & $adb install -r $apk
  $ErrorActionPreference = $prefAntes
  if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "  LISTO. DINASTIA se instalo/actualizo en el telefono -abrela ahi mismo." -ForegroundColor Green
  } else {
    Write-Host ""
    Write-Host "  adb encontro un problema instalando. El APK sigue en: $apk" -ForegroundColor Red
    Write-Host "  (se puede copiar a mano y abrirlo desde el explorador de archivos del telefono)"
  }
} elseif ($sin_aceptar.Count -gt 0) {
  Write-Host ""
  Write-Host "  El telefono esta conectado pero PIDIO PERMISO en su propia pantalla" -ForegroundColor Yellow
  Write-Host "  ('Permitir depuracion USB?'). Acepta ahi y vuelve a correr este script."
} else {
  Write-Host ""
  Write-Host "  No hay ningun telefono conectado y autorizado por USB." -ForegroundColor Yellow
  Write-Host "  El APK ya esta listo en: $apk"
  Write-Host "  Abriendo la carpeta para copiarlo a mano (USB como disco, Drive, WhatsApp, etc.)"
  Start-Process (Split-Path -Parent $apk)
}
