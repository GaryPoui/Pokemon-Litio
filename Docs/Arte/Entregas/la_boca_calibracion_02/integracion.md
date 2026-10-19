# Integración de la calibración 02

Esta revisión preserva los contratos descritos en [integración 01](../la_boca_calibracion_01/integracion.md). No cambia escenas, colisiones, orden de dibujo, animaciones ni TileSets.

## Pintora

`Assets/Produccion/Barrios/la_boca/v02/pintora.png`: hoja RGBA de 32×128 con cuatro celdas estáticas 32×32 en orden abajo, arriba, izquierda y derecha. Mantener posición, origen, colisión y apoyo definidos para la pintora actual.

## Conventillo

`conventillo_amarillo.png`, `conventillo_amarillo_cuerpo.png` y `conventillo_amarillo_techo.png` son lienzos RGBA de 80×64 con origen idéntico. Puede usarse el PNG completo o separar techo y cuerpo con política de orden de dibujo revisada en motor. No superponer el techo a la composición completa.

Mantener `Fachada.position=(0,-24)`, sprite centrado, ancla de imagen `(40,56)` y colisión actual 80×48 centrada en `(0,-16)`. La huella de juego no cambia. La escalera y el lateral pintados son parte visual del mismo sprite y no crean superficies caminables o interacción nuevas.

Antes de sustituir texturas, revisar las cuatro esquinas del edificio en la escena y el solapamiento con personajes y faroles. Esta entrega no ha sido ejecutada ni validada en Godot.
