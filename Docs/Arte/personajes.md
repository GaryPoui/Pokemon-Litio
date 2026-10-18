# Personajes y Pokémon

## Base disponible

El relevamiento de `c84c115f` encontró 101 especies configuradas en `Datos/Especies/`, con sprites de frente y espalda. Hay especies de quinta generación, entre ellas Snivy, Tepig, Oshawott, Purrloin, Timburr, Drilbur y Audino. La estética de cuarta generación no limita por sí sola la selección de especies.

La biblioteca de imágenes es más amplia que los recursos configurados. Comprobar el `.tres`, sus texturas y el icono por ID antes de afirmar que una criatura está disponible.

## Candidatos por ciudad

Estas son propuestas de arte, no equipos definitivos ni tablas de encuentros:

| Tema | Bases existentes | Propuestas nuevas |
|---|---|---|
| La Boca | Pikachu, Shinx, Luxio, Luxray | Variante de hincha con acentos azules y amarillos; ave portuaria |
| Mugica | Purrloin, Liepard | Felino nocturno vinculado a terrazas |
| Constitución | Lucario, Excadrill | Criatura ferroviaria con remaches y formas de locomotora |
| Chacarita | Gastly, Haunter | Espíritu de florero o farol con motivos musicales |
| IPM | Pikachu, Raichu, Shinx, Blitzle, Zebstrika | Criatura de bobina o pequeño robot didáctico |
| Monumental | Gastly, Haunter | Aparición de bufanda y banda diagonal roja y blanca |
| Arenales | Sin familia gastronómica dedicada en la base relevada | Criaturas de empanada, fugazzeta y helado |
| Palermo | Bulbasaur, Chikorita, Treecko, Turtwig, Snivy y sus evoluciones configuradas | Criatura de rosal o semilla de árbol urbano |

## Diseño de criaturas

Definir una idea central y tres rasgos de silueta antes de agregar detalles. Fijar escala respecto de un humano, postura, paleta y lectura desde atrás. Una variante conserva la anatomía reconocible de su especie base; el vestuario y los motivos barriales deben funcionar también en el icono.

Para las criaturas de comida, distinguir forma, extremidades y comportamiento visual. La empanada puede trabajar la media luna y el repulgue; la pizza, el triángulo y el queso; el helado, el cono y los volúmenes blandos. Evitar que todas sean el mismo cuerpo con alimentos distintos pegados encima.

Mantener nombres e IDs provisionales separados de los actuales. No sobrescribir una especie base con una forma local ni decidir sus estadísticas, tipos o evoluciones jugables dentro de una entrega de arte.

## Paquete por criatura

Entregar frente, espalda e icono como conjunto. Documentar lienzo, cantidad de cuadros, FPS y ancla; conservar el contrato existente cuando se trate de un reemplazo. Acompañar animaciones con un preview del loop, separado de la tira PNG que consume el juego.

Overworld, shiny, retratos independientes y evoluciones se asignan a un lote específico. La presencia de hojas de seguidores en la biblioteca no implica que haya que implementar ese sistema.

## Personajes humanos

Los primeros rediseños son los cinco NPC de La Boca. Después priorizar oficios y actividades propias de cada lugar: ferroviarios y viajeros, floristas y cuidadores, docentes y estudiantes, cocineros y mozos, jardineros y deportistas, comerciantes y vecinos.

Usar postura, peinado, ropa y silueta para diferenciarlos. Mantener el punto de apoyo al girar y comprobar que los detalles sobrevivan al tamaño de juego. Los líderes y el rival pueden tener conceptos de apariencia sin fijar todavía historia, equipos ni diálogos.
