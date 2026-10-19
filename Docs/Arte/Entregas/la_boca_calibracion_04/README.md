# La Boca · calibración 04

El conventillo amarillo ya usa un techo a dos aguas con cumbrera diagonal hacia el fondo. Las dos superficies tienen líneas de chapa que siguen su perspectiva, y el alero se mantiene encima de las ventanas sin tapar la fachada.

La pintora del mapa usa la **segunda hoja aprobada por el usuario**, con cuatro vistas detalladas. Cada figura se conserva desde el PNG de referencia y se recorta sin reducir ni pixelar la ilustración; los cuatro apoyos quedan alineados. El atlas se muestra ampliado en [las cuatro vistas](pintora_vistas.png).

## Archivos

- Fuente editable del edificio: [SVG v04](../../../../ArteFuente/la_boca_calibracion_01/v04/conventillo_amarillo.svg).
- Recursos de producción del edificio y del atlas: [Assets/Produccion/Barrios/la_boca/v04](../../../../Assets/Produccion/Barrios/la_boca/v04/).
- Textura activa del edificio: `Assets/Overworld/LaBoca/conventillo_amarillo.png`.
- Hoja activa de la pintora: `Assets/Personajes/npc/LaBoca/pintora_detallada.png`, recortada por `Recursos/Personajes/boca_pintora_detallada.tres`.

`Escenas/Mapa.tscn` asigna la hoja detallada a `PintoraLaBoca`. `ChicaAna` conserva su recurso de guía y deja de mostrar la hoja simple descartada. Se mantienen el diálogo y la escena NPC existentes. La importación de PNG se completa al abrir el proyecto en Godot; el motor no estuvo disponible para ejecutar la escena en esta sesión.
