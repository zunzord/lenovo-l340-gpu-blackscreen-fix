@echo off
chcp 65001 >nul
title Instalador Blindado con Rescate Automatico (25 seg)

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando permisos de Administrador...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Ssanc\Desktop\archivos_controladores\instalar_seguro.ps1"
