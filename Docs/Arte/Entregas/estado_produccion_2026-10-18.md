# Estado de producción de assets · 18-10-2026

Este índice evita presentar una tanda como si ya completara el arte del juego. Se actualiza con los lotes de producción del repositorio.

| Zona / lote | Trabajo disponible | Estado comprobado |
|---|---|---|
| La Boca · calle y edificio | adoquín, vereda y transiciones; conventillo amarillo elegido; azul y rojo v07; Bombonera v08 | Los tres conventillos y el estadio conservan dimensiones y rutas que usa el mapa. Los NPC mantienen sus nodos y colisiones. |
| La Boca · NPC | pintora, guía, hincha, músico, tendera y Chica Ana en hojas detalladas de cuatro vistas | Recursos `SpriteFrames` conectados y escala 0,09 asignada en `Mapa.tscn`. Pendiente ejecutar Godot para confirmar la lectura visual. |
| La Boca · comercio/decoración v13 | comercio, banderines y mural de puerto | Assets con fuente y previews; pendientes de ubicar en el mapa. |
| Fondos de combate · revisión v02 | siete fondos redibujados; La Boca sirve de referencia | Lienzo 256×192, opacos y con plataformas compatibles; pendientes de integración y prueba en combate. |
| Fondos de combate · revisión v03 | ocho fondos ambientados en sus barrios con acabado pixel art detallado | Ocho PNG 256×192 con plataformas existentes preservadas; La Boca está conectado al mapa activo. Los otros lugares esperan sus mapas. |
| Estructuras profundidad v02 | anexo IPM, café Arenales, casa de guardaparque y vivienda Mugica | PNG con SVG y fichas; techo hacia el fondo, fachada frontal; pendientes de integración. |
| Props emblemáticos · 7 barrios | un prop cada uno para Constitución, Chacarita, IPM, Arenales, Palermo, Mugica y Monumental | Assets con fichas y fuentes; pendientes de integración. |
| Constitución v02 | fachada modular de estación con reloj y marquesina | Asset final pendiente de integración. |
| Constitución v03 | banco, valija y señal ferroviaria | Assets con fuentes, detalle revisado y anclas documentadas; pendientes de integración. |
| Chacarita v03 | pared de nichos, reja, florero y banco | Assets con detalle visual revisado, fuente y anclas; pendientes de integración. |
| IPM v02 | fachada, pizarra, mesa de taller y pupitre | Assets con fuentes, detalle revisado y fichas; pendientes de integración. |
| IPM v04 | fachada y fondo de combate rehechos con fotos reales del instituto | Fachada conectada a una escena exterior reutilizable; falta ubicarla en el mapa propio del IPM. Fondo de combate listo, pendiente de integración. NPC sin cambios. |
| IPM v05 | interior del taller escolar, versión limpia y versión de combate | Escena interior de 16×12 con jugador, límites y colisiones; fondo de combate seleccionado desde la escena. Falta conectarla al exterior del IPM. |
| Props de barrio v02 | ocho objetos nuevos, uno por cada lugar | PNG transparentes con SVG fuente, preview y ficha; pendientes de colocar en mapas. |
| Arenales v01 | fuente de plaza, mesas, sillas y macetón | Assets con detalle visual revisado, fuentes y fichas; pendientes de integración. |
| Palermo v02 | puente, parterre de rosas, farola y borde de lago | Assets con detalle visual revisado, fuentes y ficha de tile; pendientes de integración. |
| Chacarita v02–v03 | acceso de tres arcos, nichos, reja, florero y banco | Cinco piezas finales con fuente; pendientes de integración. |

## Pendientes según el encargo

Completar y revisar el kit de La Boca en contexto, incluyendo colocación de comercio y decoración. Seguir con los módulos restantes de ciudad e interiores: estación y viajeros; pórtico, galerías, mausoleos y cuidadores; exterior y taller del IPM conectado a su barrio; plaza y frentes gastronómicos de Arenales; lago, rosedal, puente y pérgola de Palermo; pasajes, viviendas y comercios de Mugica; fachada, museo y tribunas del Monumental.

No se crearon Pokémon, por la indicación previa del usuario. Los archivos marcados como pendientes todavía necesitan ubicarse en sus escenas.

## Verificación

Se verificaron dimensiones, transparencia y hojas de cuatro direcciones; los enlaces locales de las fichas están completos. Se comprobaron estáticamente las rutas de NPC en `Mapa.tscn` y las regiones 224×340 de `SpriteFrames`. No se encontró Godot en el entorno, así que no se afirma ejecución ni prueba del proyecto.
