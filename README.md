# Forest Chase for the VIC-20

A port of the classic Spectrum 3d forest chase game for the VIC-20 with 16K RAM expansion.

Working:
- tree map advancement and tree rendering (mostly)
- drawing the player bike
- raster split to change the background from sky to ground colour
- bike audio

## Running

Load `chase.prg` on a VIC-20 with 16K expansion (PAL). In VICE:

```text
xvic -pal -memory 16k +basicload -autostart chase.prg
```

Or run `make.bat` if you have ACME and VICE set up locally.
