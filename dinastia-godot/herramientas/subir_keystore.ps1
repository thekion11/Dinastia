# Sube la keystore de Android a los SECRETOS de GitHub (2-11-2026), para que el CI firme el APK/AAB.
# Se ejecuta en TU computador (Windows, con `gh` instalado y `gh auth login` hecho). Nada se guarda en disco ni en el repo.
#   powershell -ExecutionPolicy Bypass -File herramientas\subir_keystore.ps1 -Keystore "C:\ruta\dinastia.keystore" -Alias dinastia
param(
  [Parameter(Mandatory = $true)][string]$Keystore,
  [string]$Alias = "dinastia",
  [string]$Repo = "thekion11/Dinastia"
)
if (-not (Test-Path $Keystore)) { Write-Error "No existe $Keystore"; exit 1 }
$clave = Read-Host "Contraseña de la keystore" -AsSecureString
$plano = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($clave))
[Convert]::ToBase64String([IO.File]::ReadAllBytes($Keystore)) | gh secret set ANDROID_KEYSTORE_BASE64 --repo $Repo
$Alias | gh secret set ANDROID_KEYSTORE_USER --repo $Repo
$plano | gh secret set ANDROID_KEYSTORE_PASSWORD --repo $Repo
$plano = $null
Write-Host "Listo: 3 secretos subidos a $Repo. Al lanzar el workflow, marca android_release."
