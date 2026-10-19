# Integración de la calibración 01

Base revisada: `development`, commit `7f531f1b104064a7a5b20373e33e1b3c5bfaa99f`. Los recursos actuales se preservan. Ninguno de estos PNG está asignado a una escena, SpriteFrames o TileSet por esta entrega.

## Pintora

Destino propuesto: textura de `Recursos/Personajes/boca_pintora.tres`. La hoja nueva está en `Assets/Produccion/Barrios/la_boca/v01/pintora.png`.

| Dirección | Rectángulo en píxeles |
|---|---|
| abajo | `(0, 0, 32, 32)` |
| arriba | `(0, 32, 32, 32)` |
| izquierda | `(0, 64, 32, 32)` |
| derecha | `(0, 96, 32, 32)` |

Conservar una pose por animación y `loop=false`. Las poses son estáticas; el valor 1 FPS del manifest describe el recurso de una pose, no un ciclo de movimiento. No cambiar el contrato del protagonista.

En `Escenas/Mapa.tscn`, `ChicaAna/AnimatedSprite2D` usa posición `(0,-7)`. Con una celda centrada de 32×32, el origen del nodo corresponde al punto `(16,23)` de la imagen. El apoyo visible es `y=31`. La colisión actual de 14×14 corresponde a `(9,16,14,14)` en la celda; no se alteró.

## Farol

Destino propuesto: textura del farol en `Escenas/DecoracionLaBoca.tscn`. Conservar 14×31, sprite centrado y `offset=(0,-7.5)`. El ancla del nodo en coordenadas de imagen es `(7,23)` y el apoyo visible termina en `y=30`.

La colisión existente es 16×16 centrada en el nodo. La sugerencia del manifest, `(4,24,6,7)`, describe únicamente el pie dibujado; no modifica esa colisión. Revisar caminabilidad y dibujo alrededor de cada farol durante la integración.

## Conventillo

Destino propuesto: `Escenas/Edificios/ConventilloAmarilloExterior.tscn`. El lienzo sigue siendo 80×64. Conservar `Fachada.position=(0,-24)` y sprite centrado. El ancla del nodo dentro del PNG es `(40,56)`.

La colisión actual es 80×48, centrada en `(0,-16)` respecto al nodo: corresponde a `(0,16,80,48)` dentro de la imagen. La huella ocupa cinco por tres celdas de 16×16, con centros locales `x=-32,-16,0,16,32` e `y=-32,-16,0`. El acceso dibujado ocupa `(30,46,12,16)`. No crea un warp ni una puerta funcional.

La imagen completa conserva el contrato de dimensiones. Verificar la nueva silueta y el acceso antes de sustituir la textura. Las capas alternativas tienen idéntico lienzo y origen. Para ordenar el techo de manera independiente se necesitan nodos y una política de orden de dibujo; esa modificación de escena queda pendiente. No añadir una segunda colisión al techo ni componer encima de la imagen completa.

## Calle y vereda

Importar `suelo_urbano.png` como una fuente **nueva** de atlas. Celdas 16×16, margen 0 y separación 0. No sustituye directamente a `pasto_variantes.png` ni a `entorno_provisional.png`: su disposición es diferente.

`atlas_regiones.json` proporciona los 52 rectángulos utilizables. Índices 0–46: conexiones de vereda; 47: adoquín; 48–49: variantes de adoquín; 50–51: variantes del centro de vereda. Índices 52–55: vacíos. Para las variantes de centro, mantener conexión de vereda completa.

Los bits de vecindad son `N=1, NE=2, E=4, SE=8, S=16, SW=32, W=64, NW=128`. El centro es vereda y el exterior es adoquín. Eliminar una diagonal si falta cualquiera de sus dos vecinos cardinales; buscar la máscara normalizada en la tabla. No usar el índice lineal como ID de una fuente activa.

El mapa contiene un TileSet embebido además del recurso `Recursos/tileset_mundo.tres`. `Scripts/la_boca_terreno.gd` asigna celdas mediante fuentes y coordenadas concretas al iniciar. La integración debe revisar ambos consumidores y ese pintado inicial; esta entrega no los modifica. Los suelos no activan encuentros ni cambian datos de hierba alta.

## Comprobación en el motor

Verificar importación sin suavizado, lectura a 256×192, anclas, puertas y orden de dibujo. Recorrer los dos lados de cada edificio y farol; girar el NPC en las cuatro direcciones. Revisar la calle después de que termine el pintado inicial del mapa. Registrar la prueba en Godot solamente después de ejecutarla y observarla.
