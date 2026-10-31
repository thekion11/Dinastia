@echo off
rem MEDIR EL JUEGO EN ESTE PC (30-10-2026). Copiar junto a DINASTIA.exe y hacer doble clic.
rem Recorre solo el menu, el estadio (camara de TV) y la ciudad, ~1 minuto, y abre la carpeta
rem con el informe (FPS medios, 1% mas lento, peor fotograma y tiempos de carga).
rem Para medir la primera vez de verdad, borrar antes la carpeta cache de
rem %APPDATA%\Godot\app_userdata\DINASTIA
"%~dp0DINASTIA.exe" -- --medir
