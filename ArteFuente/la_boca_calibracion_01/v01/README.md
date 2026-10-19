# Fuentes de la calibración 01

| Archivo | Edición disponible |
|---|---|
| `pintora.xpm` | Raster nativo 32×128, paleta indexada y transparencia; una capa |
| `farol.xpm` | Raster nativo 14×31; una capa |
| `suelo_urbano.xpm` | Raster nativo 128×112, con todos los recortes del atlas; una capa |
| `conventillo_amarillo.svg` | Geometría sobre grilla 80×64; grupos de cuerpo, ventanas, puerta, escalera, balcón, techo y zócalo |
| `adoquin.svg` | Diseño de la celda base 16×16 |
| `vereda.svg` | Diseño de la celda base 16×16 |
| `la_boca_lote_01.gpl` | Paleta completa de 50 colores; no incluye el transparente |

Los XPM son archivos de imagen editables, no hojas con capas ocultas ni archivos de animación. El símbolo `.` puede corresponder a un color de la paleta: consultar la tabla de cada archivo para identificar el transparente.

Exportar los SVG exactamente a sus medidas declaradas, sin interpolación ni suavizado. Los grupos del conventillo comparten origen; el techo puede exportarse solo en un lienzo 80×64 y el resto como cuerpo. Para el juego se entregan PNG; las fuentes permanecen fuera de las rutas activas.

Ver [ficha y manifest](../../../Docs/Arte/Entregas/la_boca_calibracion_01/README.md) antes de alterar recortes, anclas o colores.
