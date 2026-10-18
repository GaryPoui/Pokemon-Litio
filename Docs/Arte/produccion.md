# Producción de arte

## Primer lote

Empezar por una muestra de La Boca: familia de vereda y adoquín, un conventillo, un farol y un NPC. Revisarla junto al héroe y al Centro Pokémon existentes, a tamaño nativo y ampliada con nearest. Resolver escala, perspectiva y contraste antes de extender el kit.

El mapa actual tiene mucho pasto y senderos de tierra. La prioridad es construir una calle urbana con veredas, cordones, esquinas y frentes. Los conventillos necesitan variantes de estructura, volumen y material. El estadio necesita una lectura más clara de su exterior y accesos.

Las láminas grandes de concepto se conservan como referencia. Cada pieza final se dibuja y exporta por separado con su medida y su recorte.

## Orden de trabajo

El orden propuesto organiza la producción; no fija la progresión de gimnasios:

1. Muestra de La Boca y kit común de calle: superficies, transiciones, árboles y mobiliario.
2. La Boca completa: Bombonera, tres conventillos, comercio, decoración y cinco NPC.
3. Constitución: estación, andén, estructura de hierro y viajeros.
4. Chacarita: pórtico, galerías, mausoleos, flores y cuidadores.
5. IPM: fachada, aula, taller, laboratorio y comunidad educativa.
6. Arenales: plaza, centro monumental, gastronomía y vecinos.
7. Palermo: lago, Rosedal, pérgola, puente y actividades del parque.
8. Mugica y Retiro: frentes, pasajes, comercios, murales y espacios comunitarios.
9. Monumental: estadio, museo, tribunas, banderas y personajes futboleros.

Por ciudad, planificar un exterior reconocible, sus módulos secundarios, NPC propios y un fondo de batalla 256×192. Un interior piloto puede mostrar cómo se relacionan las piezas; no supone que la escena esté implementada.

Después de calibrar el entorno, trabajar las criaturas en tandas de tres: frente, espalda e icono. Las variantes de La Boca, un fantasma futbolero y una criatura gastronómica permiten comprobar estilos y necesidades distintas.

## Entrega de una pieza

- PNG final separado de conceptos y previews.
- Fuente editable, paleta y referencias utilizadas.
- Ficha con tamaño del lienzo, área visible, ancla, huella, puertas y capas.
- Para animaciones: medida de cuadro, cantidad, orden, FPS y loop.
- Para atlases: coordenadas, margen, separación y conexiones cubiertas.
- Ruta de destino, recurso que reemplaza y cambios de integración necesarios.
- Prueba de contexto identificada como montaje o captura del motor.

Para piezas nuevas se propone `Assets/Produccion/Barrios/<barrio>/` y `Assets/Produccion/Pokemon/<id>/`. Usar nombres descriptivos en `snake_case`. Mantener las fuentes y los documentos de entrega ordenados por lote. Las rutas actuales no se renombran solo para aplicar esta convención.

## Revisión

Comprobar transparencia, dimensiones y recortes; ver todas las direcciones y todos los cuadros; repetir los tiles; revisar el punto de apoyo y las puertas. Corregir saltos de volumen, deformaciones, costuras y perspectivas distintas antes de marcar una pieza como final.

El estado de cada archivo debe distinguir concepto, final pendiente de integración e integrado. Una captura del motor confirma la composición observada; un montaje permite evaluar el diseño, pero no demuestra integración. No modificar sistemas del juego para compensar un defecto del asset.

Conservar las fuentes y los créditos del material utilizado. El repositorio reúne archivos de producción y documentación útil para el equipo; las notas personales, instrucciones de trabajo, archivos temporales y utilidades de inspección permanecen locales.

## Ampliaciones

Cabildo, Obelisco y Casa Rosada para encuentros con el rival; ciudades de paso; tren y subte; y otros sistemas anotados en `Decisiones-A-Futuro.md` quedan para tandas posteriores. No desplazar la revisión del kit principal por ampliar el alcance.
