# Guía visual y formatos

## Acabado

El arte debe sostener una misma dirección entre edificios, personajes, criaturas y suelos. Dibujar a resolución nativa, con píxeles intencionales, contornos moderados y grupos de color claros. El detalle tiene que ayudar a leer la forma y el material.

La referencia principal de arquitectura es el conventillo de La Boca aprobado por el usuario. En casas y edificios, el techo se extiende hacia la parte superior del cuadro para sugerir profundidad hacia atrás; la fachada ocupa el plano frontal. Resolver tejas, chapa, alero, remates, marcos y zócalos con grupos de píxeles visibles. Evitar que el volumen se exprese ensanchando una pared lateral.

Los objetos y fondos de combate necesitan variación de tono dentro de cada material: sombra bajo aleros y bases, luz en bordes superiores, textura en piedra, madera, metal y vegetación, y pequeños detalles funcionales. Mantener las agrupaciones de píxeles nítidas y evitar superficies grandes de un solo color cuando el material permite textura. La densidad debe acercarse al fondo de La Boca sin llenar cada espacio de ruido.

La cámara del mundo mira desde arriba y deja ver fachadas y profundidad de techos. Mantener los ejes de calle horizontales y verticales; evitar la isometría de rombos. Usar una dirección de luz común, propuesta desde arriba a la izquierda, con sombras discretas.

Revisar a 1× y 4× nearest. Corregir geometrías imposibles, letras deformadas, objetos fusionados, anatomías variables, sombras contradictorias y ruido de píxeles. Un filtro de pixelado o reducir una ilustración grande no resuelven esos problemas. Los carteles llevan el texto en una capa aparte y una variante sin letras.

Diamante, Perla, Platino y HGSS sirven de referencia para composición y escala. El juego actual también usa recursos de quinta generación; el arte nuevo debe convivir con ellos sin obligar a rehacer todas las pantallas.

## Medidas del proyecto

Medidas relevadas en `c84c115f`:

| Recurso o sistema | Formato |
|---|---|
| Vista lógica | 256×192; referencia de ventana 1024×768 |
| Escalado | Entero, `canvas_items`, filtro nearest y snap de transformaciones |
| Rejilla del mundo | 16×16 por defecto; revisar `tam_celda` en cada mapa |
| `pasto_variantes.png` | 128×96: 8×6 celdas de 16×16 |
| `entorno_provisional.png` | 128×64 |
| Conventillos activos | amarillo, azul y rojo 80×64 |
| `estadio_bombonera.png` | 256×208 |
| Banco y setos de La Boca | 16×16 |
| Farol de La Boca | 14×31 |
| NPC clásicos del proyecto | Hoja 32×128: cuatro celdas de 32×32 |
| NPC detallados de La Boca | Hoja 224×1360: cuatro celdas de 224×340; se reducen a escala 0,09 en el mapa |
| Protagonista | Hoja 880×440, celdas 40×40 |
| Fondo de batalla | 256×192 |
| Icono de Pikachu | 64×32: dos cuadros de 32×32 |

Las medidas de un lienzo no indican por sí solas el tamaño visible, la huella o la colisión. Revisar el recurso que lo consume antes de hacer un reemplazo.

## Suelos

Crear tiles de 16×16 en atlases con coordenadas documentadas. Por defecto, margen y separación son cero. No incluir títulos, guías ni cuadrículas de presentación dentro del atlas final.

Cada familia necesita centro, cuatro bordes, cuatro esquinas exteriores y cuatro interiores, además de variantes del centro. Diseñar las transiciones por par de materiales. Si se propone autotiling, documentar la vecindad y las conexiones que cubre el atlas.

Comprobar una repetición 4×4, una esquina, una T y un cruce. Diferenciar visualmente zonas transitables, escalones, orillas y hierba de encuentros. El dato `hierba_alta` pertenece al TileSet; dibujar pasto no activa encuentros.

`Mapa.tscn` tiene un TileSet embebido y existe también `Recursos/tileset_mundo.tres`. Además, `Scripts/la_boca_terreno.gd` modifica celdas en ejecución usando IDs y coordenadas concretos. No reordenar el atlas activo ni asumir que cambiar el recurso externo actualiza el mapa.

## Edificios y props

Separar cuerpo, techo o copa y sombra cuando necesiten distinto orden de dibujo. Documentar el ancla desde la esquina superior izquierda del PNG, el rectángulo visible, la huella, las puertas y la línea de apoyo. La colisión sugerida corresponde al cuerpo, no a todo el techo.

Por ejemplo, `ConventilloAmarilloExterior.tscn` coloca la fachada centrada en `(0,-24)` y una colisión 80×48 centrada en `(0,-16)`. El fondo del lienzo queda a y=8 respecto del nodo. No asumir que todos los edificios usan un ancla en el centro inferior.

El estadio actual supera la altura de una pantalla lógica. Diseñar la lectura de accesos y volumen por secciones; una textura nueva no necesita mostrar toda la cancha y la fachada en la misma pieza. Si cambia la estructura, entregar una propuesta modular y sus instrucciones de integración.

## Personajes

Tomar la pintora de La Boca aprobada por el usuario como referencia de acabado humano: proporciones chibi compactas, boina y pelo definidos por grupos de píxeles, contraste cálido, sombras agrupadas y detalles nítidos en la ropa. Mantener ese nivel de detalle y coherencia entre los NPC nuevos, cambiando peinado, silueta, vestuario y paleta para distinguir a cada persona. El atuendo de pintora sirve como guía de estilo, no como uniforme.

Las hojas detalladas de La Boca usan cuatro celdas verticales de 224×340 px, en orden **abajo, arriba, izquierda, derecha**. Los recursos `Recursos/Personajes/boca_*.tres` recortan una pose por dirección y usan las animaciones `abajo`, `arriba`, `izquierda` y `derecha`. En `Escenas/Mapa.tscn`, cada AnimatedSprite2D de estos NPC se escala a 0,09 para conservar el tamaño visual del mapa; el personaje clásico mantiene su contrato de 32×32 por cuadro.

Mantener centro y pie entre vistas. Si se crea un ciclo de caminar, entregar también las poses estáticas compatibles y documentar nuevos recortes, cantidad de cuadros y FPS. Una hoja de cuatro columnas no funciona automáticamente con el recurso actual.

El protagonista tiene celdas 40×40 y animaciones `caminar_*` y `correr_*`; su contrato es diferente.

## Pokémon de batalla

`Scripts/batalla/sprite_pokemon.gd` reproduce tiras horizontales. Cada especie define frente, espalda, número de cuadros y FPS en su `.tres`. No existe un lienzo único obligatorio para todas las especies.

| Ejemplo | Frente | Espalda | FPS |
|---|---|---|---:|
| Pikachu | 3050×46; 61 cuadros de 50×46 | 2400×47; 60 cuadros de 40×47 | 10,5 |
| Snivy | 3840×44; 80 cuadros de 48×44 | 3901×42; 83 cuadros de 47×42 | 9,18 |

El renderer ancla por centro horizontal y borde inferior del lienzo. Mantener el lienzo y el punto de apoyo constantes durante el loop. El frente y la espalda pueden tener cantidades distintas de cuadros. Revisar la espalda a la escala actual de presentación del jugador, 1,75, y el frente a 1,0.

Un reemplazo compatible conserva el contrato del `.tres`. Para una criatura nueva se puede proponer otra medida y un idle corto, registrando el contrato exacto. No cambiar una tira de 61 cuadros por una de cuatro manteniendo el mismo recurso.

Los iconos se cargan por ID desde `Assets/Pokemones/iconos/` y usan dos cuadros horizontales. Para criaturas nuevas, usar como punto de partida 64×32 con dos celdas 32×32 y comprobar su lectura en equipo y PC.

## Exportación e integración

PNG RGBA con alfa real para entidades; suelos y fondos pueden ser opacos. Evitar halos, damero pintado, píxeles sueltos y suavizado de bordes. Entregar una fuente editable real cuando exista y documentar las capas disponibles.

Una ficha de asset debe incluir ruta, medidas, recortes, ancla, paleta, animación, huella y estado de integración. Conservar IDs, rutas y créditos existentes hasta que se revise un reemplazo. Si cambian puertas, colisiones o recursos, registrar la necesidad por separado: el archivo de imagen y la integración son entregas distintas.
