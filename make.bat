@echo off
rem Chase VIC-20 first pass build

echo [1/3] Extract TAP...
python tools\extract_tap.py
if errorlevel 1 exit /b 1

echo [2/3] Convert graphics...
python tools\convert_gfx.py
if errorlevel 1 exit /b 1

echo [3/3] Assemble...
\app\acme\acme -o chase.prg --vicelabels chase.lbl chase.asm
if errorlevel 1 exit /b 1
python tools\sort_lbl.py chase.lbl
if errorlevel 1 exit /b 1

echo Build OK: chase.prg
\app\vice3.10\bin\xvic -pal -memory 16k +basicload -autostart chase.prg
