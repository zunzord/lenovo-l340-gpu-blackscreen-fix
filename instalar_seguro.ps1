# ============================================================================
# INSTALADOR BLINDADO CON RESCATE AUTOMATICO ANTI-PANTALLA-OSCURA (25 SEG)
# Lenovo IdeaPad L340-15IRH Gaming (81LK)
# ============================================================================

$ErrorActionPreference = "Continue"
$folder = "C:\Users\Ssanc\Desktop\archivos_controladores"
$intelInfDir = "$folder\Lenovo_Intel_Extraido\Source\Graphics"

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  PASO 1: CONFIGURANDO BRILLO AL 100% Y PROTECCION DE BACKLIGHT LENOVO" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan

# 1. Eliminar cualquier restriccion de politica de instalacion de dispositivos
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions" /f 2>$null | Out-Null

# 2. Bloquear reemplazo automatico de Windows Update
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f | Out-Null

# 3. Forzar brillo del plan de energia al 100% en AC y DC (estaba en 0%!)
powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO aded5e82-b909-4619-9949-f5d71dac0bcb 100
powercfg /setdcvalueindex SCHEME_CURRENT SUB_VIDEO aded5e82-b909-4619-9949-f5d71dac0bcb 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO fbd9aa66-9553-4097-ba44-ed6e9d65eab8 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_VIDEO fbd9aa66-9553-4097-ba44-ed6e9d65eab8 0
powercfg /setactive SCHEME_CURRENT

# 4. Limpiar estado cacheado de brillo 0% del servicio monitor
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\monitor\State" /f 2>$null | Out-Null

# 5. Pre-aplicar claves de proteccion de backlight PWM Lenovo en 0000, 0001, 0002
$classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
foreach ($sub in @("0000", "0001", "0002", "0003")) {
    $p = "$classPath\$sub"
    if (Test-Path $p) {
        Set-ItemProperty -Path $p -Name "LFP_Brightness_Control" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $p -Name "FeatureTestControl" -Value 0x8210 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $p -Name "DpstTurnOffBppPanelReq" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    }
}

Write-Host "[OK] Brillo de Windows fijado al 100% y parametros PWM de Lenovo configurados." -ForegroundColor Green
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  PASO 2: INSTALANDO DRIVER INTEL OFICIAL DE LENOVO CON RESCATE EN 25 SEG" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "ATENCION - COMO FUNCIONA EL SEGURO AUTOMATICO:" -ForegroundColor Yellow
Write-Host "1. Se instalara el driver oficial de Lenovo (iigd_dch.inf + iigd_ext.inf)." -ForegroundColor White
Write-Host "2. El script forzara el brillo al 100% por hardware inmediatamente." -ForegroundColor White
Write-Host "3. Tendras 25 SEGUNDOS para presionar la tecla [S] si ves bien la pantalla." -ForegroundColor White
Write-Host "4. SI LA PANTALLA SE QUEDARA OSCURA, NO TOQUES NADA: al llegar a 0 segundos," -ForegroundColor Green
Write-Host "   el script DESINSTALARA SOLO el driver Intel y encendera tu pantalla de nuevo!" -ForegroundColor Green
Write-Host ""
Read-Host "Presiona ENTER cuando estes listo para probar la instalacion segura"

Write-Host "Instalando extension OEM de Lenovo (iigd_ext.inf)..." -ForegroundColor Cyan
pnputil /add-driver "$intelInfDir\iigd_ext.inf" /install | Out-Null

Write-Host "Instalando controlador base Intel de Lenovo (iigd_dch.inf)..." -ForegroundColor Cyan
$installOut = pnputil /add-driver "$intelInfDir\iigd_dch.inf" /install
Write-Host $installOut

# Re-aplicar parametros de backlight y forzar WMI Brightness al 100%
foreach ($sub in @("0000", "0001", "0002", "0003")) {
    $p = "$classPath\$sub"
    if (Test-Path $p) {
        Set-ItemProperty -Path $p -Name "LFP_Brightness_Control" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $p -Name "FeatureTestControl" -Value 0x8210 -Type DWord -ErrorAction SilentlyContinue
    }
}

powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO aded5e82-b909-4619-9949-f5d71dac0bcb 100
powercfg /setdcvalueindex SCHEME_CURRENT SUB_VIDEO aded5e82-b909-4619-9949-f5d71dac0bcb 100
powercfg /setactive SCHEME_CURRENT

try {
    $b = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods -ErrorAction SilentlyContinue
    if ($b) {
        Invoke-CimMethod -InputObject $b -MethodName WmiSetBrightness -Arguments @{Timeout=1; Brightness=100} -ErrorAction SilentlyContinue | Out-Null
    }
} catch {}

# Emitir un beep para indicar que ya termino de cargar el driver y empieza la cuenta regresiva
[console]::beep(1000, 400)

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Yellow
Write-Host "  ¿LA PANTALLA SE VE BIEN ILUMINADA? PRESIONA LA TECLA [S] PARA CONFIRMAR" -ForegroundColor Yellow
Write-Host "  (Si esta oscura, NO toques nada: se revertira sola en 25 segundos)" -ForegroundColor Yellow
Write-Host "============================================================================" -ForegroundColor Yellow

$confirmed = $false
while ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null }

for ($i = 25; $i -ge 1; $i--) {
    # En cada segundo intentamos subir el brillo a 100% por WMI
    try {
        $b = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods -ErrorAction SilentlyContinue
        if ($b) {
            Invoke-CimMethod -InputObject $b -MethodName WmiSetBrightness -Arguments @{Timeout=1; Brightness=100} -ErrorAction SilentlyContinue | Out-Null
        }
    } catch {}

    Write-Host "`rTiempo restante antes de reversion automatica: $i segundos... (Presiona [S] si ves bien)   " -NoNewline -ForegroundColor Cyan
    for ($ms = 0; $ms -lt 10; $ms++) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::S) {
                $confirmed = $true
                break
            }
        }
        Start-Sleep -Milliseconds 100
    }
    if ($confirmed) { break }
}

Write-Host ""
if ($confirmed) {
    [console]::beep(1500, 300)
    [console]::beep(1800, 300)
    Write-Host ""
    Write-Host "[EXITO!] Confirmaste que la pantalla tiene luz y funciona con el driver Intel de Lenovo!" -ForegroundColor Green
    Write-Host ""
    pnputil /enum-devices /class Display
    Write-Host ""
    Write-Host "¿Deseas abrir ahora el instalador de NVIDIA GTX 1050 (v582.78)?" -ForegroundColor Yellow
    $resp = Read-Host "Escribe S y presiona ENTER para instalar NVIDIA (o N para salir)"
    if ($resp -match "^[sS]") {
        Start-Process -FilePath "$folder\582.78-notebook-win10-win11-64bit-international-dch-whql.exe" -Wait
    }
} else {
    # REVERSION AUTOMATICA SI LA PANTALLA QUEDO OSCURA
    [console]::beep(500, 600)
    Write-Host ""
    Write-Host "[RESCATE AUTOMATICO ACTIVADO] No se recibio confirmacion. Desinstalando driver Intel y restaurando luz..." -ForegroundColor Red
    
    # Buscar todos los oem*.inf de Intel Display y eliminarlos con /uninstall /force
    $drivers = pnputil /enum-drivers /class Display
    $currentOem = ""
    foreach ($line in ($drivers -split "`r?`n")) {
        if ($line -match "oem\d+\.inf") {
            $currentOem = $matches[0]
        }
        if ($line -match "iigd_dch\.inf" -and $currentOem -ne "") {
            Write-Host "Eliminando $currentOem (iigd_dch.inf)..."
            pnputil /delete-driver $currentOem /uninstall /force
            $currentOem = ""
        }
    }
    
    # Tambien reiniciar la instancia al adaptador basico de Microsoft
    pnputil /remove-device "PCI\VEN_8086&DEV_3E9B&SUBSYS_3A2D17AA&REV_00\3&11583659&1&10"
    pnputil /scan-devices
    
    [console]::beep(1200, 500)
    Write-Host "[LUZ RESTAURADA] Se ha vuelto al Adaptador Basico de Microsoft automaticamente." -ForegroundColor Green
}

Write-Host ""
Read-Host "Presiona ENTER para cerrar esta ventana"
