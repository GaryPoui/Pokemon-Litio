# La Boca · conventillos v07

Rediseño de las fachadas azul y roja para que compartan el volumen hacia el fondo del conventillo amarillo seleccionado. Se retiraron las escaleras laterales dominantes y cada casa conserva un frente diferente: galería azul y contraventanas; balcón corrido rojo y acceso de comercio.

- [Vista conjunta ampliada 4×](conventillos_v07_4x.png) (izquierda: amarillo aprobado, centro: azul nuevo, derecha: rojo nuevo).
- Activos reemplazados en el proyecto: [conventillo_azul.png](../../../../Assets/Overworld/LaBoca/conventillo_azul.png) (64×64) y [conventillo_rojo.png](../../../../Assets/Overworld/LaBoca/conventillo_rojo.png) (80×64).
- Fuentes editables: [azul SVG](../../../../ArteFuente/la_boca_calibracion_01/v07/conventillo_azul.svg) · [rojo SVG](../../../../ArteFuente/la_boca_calibracion_01/v07/conventillo_rojo.svg).
- [Ficha del azul](conventillo_azul_manifest.json) · [ficha del rojo](conventillo_rojo_manifest.json).

**Estado: integrado como textura activa.** Las escenas `ConventilloAzulExterior.tscn` y `ConventilloRojoExterior.tscn` ya referencian esos PNG por nombre y conservan su huella y colisiones actuales. Se verificaron tamaño, alfa, recorte y lectura ampliada. Godot no está disponible en este entorno, así que no hay prueba de ejecución de escenas.

El techo mantiene dos faldones y cumbrera que se alejan hacia el fondo, con el costado del volumen visible a la derecha como plano secundario. La pieza amarilla elegida se conserva sin cambios en este lote.
