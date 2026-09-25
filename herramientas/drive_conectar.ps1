# ============================================================================
#  PASO 1 - CONECTAR EL DRIVE  (esto lo tiene que ejecutar el USUARIO, una vez)
# ============================================================================
#  Es el unico paso que no puede dar el asistente: hay que iniciar sesion con
#  la cuenta de Google, y eso son credenciales del usuario.
#
#  Al ejecutarlo se abre el navegador. Hay que:
#    1. elegir la cuenta  gustavonavarrete@liceomolinalavin.cl
#    2. pulsar "Continuar" / "Permitir"
#    3. cerrar la pestana cuando diga "Success!"
#
#  A partir de ahi queda guardado un remoto llamado "dinastia" y ya no vuelve a
#  pedir nada nunca mas: el asistente puede subir, bajar y listar por su cuenta.
# ============================================================================

$rclone = Join-Path $PSScriptRoot "rclone\rclone.exe"
if (-not (Test-Path $rclone)) { Write-Host "No encuentro rclone en $rclone" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "  Se va a abrir el navegador para autorizar el acceso a tu Drive." -ForegroundColor Cyan
Write-Host "  Elige la cuenta del liceo y pulsa Permitir." -ForegroundColor Cyan
Write-Host ""

& $rclone config create dinastia drive scope=drive

Write-Host ""
Write-Host "  --- comprobando ---" -ForegroundColor Cyan
& $rclone lsd dinastia: --max-depth 1
if ($LASTEXITCODE -eq 0) {
	Write-Host ""
	Write-Host "  LISTO. El Drive ya esta conectado. Diselo al asistente." -ForegroundColor Green
} else {
	Write-Host ""
	Write-Host "  No quedo conectado. Vuelve a ejecutarlo o avisa al asistente." -ForegroundColor Red
}
