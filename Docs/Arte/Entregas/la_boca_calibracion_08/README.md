# La Boca · Bombonera v08

Rediseño exterior del estadio para recuperar una silueta asimétrica de tribuna alta y franjas azul y oro, con lectura clara a tamaño de juego.

- [PNG activo](../../../../Assets/Overworld/LaBoca/estadio_bombonera.png) · 256×208 px, transparente.
- [Fuente SVG editable](../../../../ArteFuente/la_boca_calibracion_01/v08/estadio_bombonera.svg).
- [Preview 2× nearest](bombonera_2x.png) · [manifest](manifest.json).

**Estado: integrado como textura activa.** `Escenas/Mapa.tscn` ya referencia este PNG en el nodo `TorreDesafio/Sprite`. Se conservan tamaño, posición, colisión y referencias de escena. El contenido anterior 256×208 mostraba un campo desde arriba; el nuevo recurso dibuja la fachada exterior definida por el kit de arte. No se cambiaron escenas ni scripts. La imagen se validó a 256×208 px y con transparencia; no hubo ejecución del motor Godot.
