# Napkin Runbook

## Execution & Validation
1. **[2026-10-05] Keep map edits aligned to the 16 px grid**
   Do instead: inspect `Escenas/Mapa.tscn`, its TileMapLayers, and atlas source coordinates before moving scenery or changing terrain assets.

## Domain Behavior Guardrails
1. **[2026-10-05] Keep water and tall grass distinct**
   Do instead: preserve the water atlas tile and check `hierba_alta` custom data before enabling encounter checks on decoration tiles.
