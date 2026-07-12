@echo off
rem Chase VIC-20 first pass build

echo Assemble...
\app\acme\acme -o chase.prg --vicelabels chase.lbl chase.asm
if errorlevel 1 exit /b 1
python tools\sort_lbl.py chase.lbl
if errorlevel 1 exit /b 1

echo Build OK: chase.prg
\app\vice3.10\bin\xvic -pal -memory 8k +basicload -autostart chase.prg
